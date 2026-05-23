from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session

from app.schemas.statements import StatementExtractionResponse, RawStatementExtractionResponse, TransactionItem
from app.services.extractor import BankExtractorService
from app.services.csv_service import CSVStatementService
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

    filename_lower = file.filename.lower()
    is_pdf = filename_lower.endswith(".pdf")
    is_csv = filename_lower.endswith(".csv")

    if not (is_pdf or is_csv):
        raise HTTPException(
            status_code=400,
            detail="Only PDF and CSV files are allowed",
        )

    try:
        file_bytes = await file.read()

        if is_csv:
            # Bypass LLM: Parse CSV instantly via Polars
            csv_result = CSVStatementService.parse_csv(
                csv_bytes=file_bytes,
                filename=file.filename
            )
            
            # Enriched via NLP categorization
            descriptions = [txn.narration for txn in csv_result.transactions]
            category_results = transaction_categorizer.categorize_items(descriptions)
            
            enriched_transactions = []
            for txn, cat in zip(csv_result.transactions, category_results):
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
                bank_name=csv_result.bank_name,
                total_transactions=csv_result.total_transactions,
                transactions=enriched_transactions,
            )
        else:
            # Parse PDF (with automatic chunking if > 5 pages) via Gemini
            raw_result = await extractor.execute_semantic_parse(file_bytes)
            
            # Enriched via NLP categorization
            descriptions = [txn.narration for txn in raw_result.transactions]
            category_results = transaction_categorizer.categorize_items(descriptions)
            
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
