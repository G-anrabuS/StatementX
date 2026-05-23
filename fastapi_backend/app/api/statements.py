from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session

from app.schemas.statements import StatementExtractionResponse, RawStatementExtractionResponse, TransactionItem
from app.services.extractor import BankExtractorService
from app.services.statement_service import StatementService
from app.services.categorizer import transaction_categorizer
from app.core.database import get_db

router = APIRouter()

extractor = BankExtractorService()


@router.post("/extract", response_model=StatementExtractionResponse)
async def extract_statement(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    if not file.filename:
        raise HTTPException(
            status_code=400,
            detail="No file uploaded",
        )

    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Only PDF files are allowed",
        )

    try:
        pdf_bytes = await file.read()

        # ── 1. Gemini extraction layer ────────────────────────────────────────
        raw_result: RawStatementExtractionResponse = (
            await extractor.execute_semantic_parse(pdf_bytes)
        )

        # ── 2. NLP categorization batch pass ─────────────────────────────────
        descriptions = [txn.narration for txn in raw_result.transactions]
        category_results = transaction_categorizer.categorize_items(descriptions)

        # Build enriched Pydantic structures for response formatting
        enriched_transactions = []
        for txn, cat in zip(raw_result.transactions, category_results):
            enriched_transactions.append(
                TransactionItem(
                    date=txn.date,
                    narration=txn.narration,
                    debit=txn.debit,
                    credit=txn.credit,
                    balance=txn.balance,
                    category=cat["category"],
                    sub_category=cat["sub_category"],
                    confidence=cat["confidence"],
                )
            )

        extracted_result = StatementExtractionResponse(
            bank_name=raw_result.bank_name,
            total_transactions=raw_result.total_transactions,
            transactions=enriched_transactions,
        )

        # ── 3. Database persistence ───────────────────────────────────────────
        StatementService.save_statement(
            db=db,
            file_name=file.filename,
            extracted_data=extracted_result,
        )

        # ── 4. Return enriched response to client ─────────────────────────────
        return extracted_result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Core extraction pipeline layer failure: {str(e)}",
        )
