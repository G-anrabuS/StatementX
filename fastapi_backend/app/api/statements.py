from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session

from app.schemas.statements import (
    StatementExtractionResponse,
    TransactionItem,
)
from app.services.extractor import BankExtractorService
from app.services.csv_service import CSVStatementService
from app.services.statement_service import StatementService
from app.services.onnx_categorizer import categorize_items
from app.services.merchant_cache import MerchantCacheService
from app.core.database import get_db

router = APIRouter()

extractor = BankExtractorService()


def enrich_transactions(db: Session, transactions):
    uncached_transactions = []
    uncached_descriptions = []

    enriched_transactions = []

    for txn in transactions:
        cached = MerchantCacheService.lookup(
            db,
            txn.narration,
        )

        if cached:
            enriched_transactions.append(
                TransactionItem(
                    date=txn.date,
                    narration=txn.narration,
                    debit=txn.debit,
                    credit=txn.credit,
                    balance=txn.balance,
                    category=cached["category"],
                    sub_category=cached["sub_category"],
                    confidence=cached["confidence"],
                )
            )
        else:
            uncached_transactions.append(txn)
            uncached_descriptions.append(txn.narration)

    if uncached_descriptions:
        category_results = categorize_items(uncached_descriptions)

        for txn, cat in zip(
            uncached_transactions,
            category_results,
        ):
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

            if cat["source"] == "rule":
                MerchantCacheService.insert(
                    db,
                    txn.narration,
                    cat["category"],
                    cat["sub_category"],
                )

    return enriched_transactions


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
            parsed_result = CSVStatementService.parse_csv(
                csv_bytes=file_bytes,
                filename=file.filename,
            )
        else:
            parsed_result = await extractor.execute_semantic_parse(file_bytes)

        enriched_transactions = enrich_transactions(
            db,
            parsed_result.transactions,
        )

        extracted_result = StatementExtractionResponse(
            bank_name=parsed_result.bank_name,
            total_transactions=parsed_result.total_transactions,
            transactions=enriched_transactions,
        )

        StatementService.save_statement(
            db=db,
            file_name=file.filename,
            extracted_data=extracted_result,
        )

        return extracted_result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Core extraction pipeline layer failure: {str(e)}",
        )
