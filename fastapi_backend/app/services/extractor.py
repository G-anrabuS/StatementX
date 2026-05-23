import io
import asyncio
from typing import List
from pypdf import PdfReader, PdfWriter
from google import genai
from google.genai import types

from app.schemas.statements import (
    StatementExtractionResponse,
    TransactionItem,
    RawStatementExtractionResponse,
    RawTransactionItem
)
from app.core.config import settings


class BankExtractorService:
    def __init__(self):
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)

    async def execute_semantic_parse(
        self, document_bytes: bytes
    ) -> RawStatementExtractionResponse:
        """
        Parses bank statement PDFs. If a document exceeds 5 pages, it is automatically
        partitioned into 5-page segments, processed in parallel asynchronously,
        and consolidated to avoid token context bloat and speed up processing.
        """
        # Count PDF pages in memory using pypdf
        try:
            reader = PdfReader(io.BytesIO(document_bytes))
            num_pages = len(reader.pages)
        except Exception as e:
            # Fallback to standard parse if reader fails (corrupt metadata etc)
            return await self._parse_chunk(document_bytes)

        # Standard processing if PDF is small (5 pages or fewer)
        if num_pages <= 5:
            return await self._parse_chunk(document_bytes)

        # Chunk the PDF in segments of 5 pages
        chunk_size = 5
        tasks = []
        
        for start_idx in range(0, num_pages, chunk_size):
            end_idx = min(start_idx + chunk_size, num_pages)
            writer = PdfWriter()
            for page_num in range(start_idx, end_idx):
                writer.add_page(reader.pages[page_num])
                
            chunk_io = io.BytesIO()
            writer.write(chunk_io)
            chunk_bytes = chunk_io.getvalue()
            
            # Append parsing task
            tasks.append(self._parse_chunk(chunk_bytes))
            
        # Run all chunk parsing tasks concurrently in parallel
        chunk_responses = await asyncio.gather(*tasks)

        # Consolidate results
        consolidated_transactions: List[RawTransactionItem] = []
        bank_name = "Imported PDF Statement"
        
        for idx, resp in enumerate(chunk_responses):
            if idx == 0:
                bank_name = resp.bank_name
            consolidated_transactions.extend(resp.transactions)
            
        return RawStatementExtractionResponse(
            bank_name=bank_name,
            total_transactions=len(consolidated_transactions),
            transactions=consolidated_transactions
        )

    async def _parse_chunk(self, chunk_bytes: bytes) -> RawStatementExtractionResponse:
        """
        Runs semantic parsing on a single PDF chunk bytes buffer using Gemini 2.5 Flash.
        """
        # Create bytes part
        document_part = types.Part.from_bytes(
            data=chunk_bytes, mime_type="application/pdf"
        )

        prompt = """
        You are an elite financial data extraction engine fine-tuned for Indian bank statement structures.
        Carefully analyze this document and perform the following tasks:
        1. Identify the name of the commercial Indian bank.
        2. Isolate the main transaction table grid boundary.
        3. Map messy native column headings cleanly to our specific target schema names:
           - Map 'Particulars' / 'Description' / 'Remarks' / 'Narration' -> narration
           - Map 'Withdrawal' / 'Dr' / 'Debit Amount' -> debit
           - Map 'Deposit' / 'Cr' / 'Credit Amount' -> credit
           - Map 'Balance' / 'Running Balance' -> balance
        4. Sequentially extract every single itemized transaction row.
        5. Calculate the absolute total count of operations successfully indexed.

        Ensure numbers are completely stripped of commas or notation artifacts before processing into floats.
        """

        # Leverage native JSON-Schema structural constraints to force output matching our exact datatypes
        # Run inside an executor thread since the GenAI synchronous SDK blocks IO
        loop = asyncio.get_running_loop()
        response = await loop.run_in_executor(
            None,
            lambda: self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=[document_part, prompt],
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                    response_schema=RawStatementExtractionResponse,
                    temperature=0.1,  # Low temperature ensures high reliability, non-creative accuracy
                ),
            )
        )

        # Hydrate JSON back cleanly directly into validated typing structures
        return RawStatementExtractionResponse.model_validate_json(response.text)
