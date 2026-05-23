from google import genai
from google.genai import types
from app.schemas.statements import RawStatementExtractionResponse

from app.core.config import settings


class BankExtractorService:
    def __init__(self):
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)

    async def execute_semantic_parse(
        self, document_bytes: bytes
    ) -> RawStatementExtractionResponse:
        document_part = types.Part.from_bytes(
            data=document_bytes, mime_type="application/pdf"
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
        response = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=[document_part, prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=RawStatementExtractionResponse,
                temperature=0.1,  # Low temperature ensures high reliability, non-creative accuracy
            ),
        )

        # Hydrate JSON back cleanly directly into validated typing structures
        return RawStatementExtractionResponse.model_validate_json(response.text)
