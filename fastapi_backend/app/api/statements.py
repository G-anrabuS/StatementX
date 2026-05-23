from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session
from typing import List
from app.models.statement import Statement
from app.schemas.insights import StatementInsightsResponse
from app.services.insights_service import InsightsService

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

        statement_record = StatementService.save_statement(
            db=db,
            file_name=file.filename,
            extracted_data=extracted_result,
        )

        extracted_result.statement_id = str(statement_record.statement_id)
        return extracted_result

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Core extraction pipeline layer failure: {str(e)}",
        )


@router.get("", response_model=List[dict])
async def list_statements(db: Session = Depends(get_db)):
    """
    Retrieves and lists all uploaded bank statements with their metadata and database IDs.
    """
    statements = db.query(Statement).order_by(Statement.uploaded_at.desc()).all()
    return [
        {
            "statement_id": str(s.statement_id),
            "file_name": s.file_name,
            "bank_name": s.bank_name,
            "uploaded_at": s.uploaded_at.isoformat() if s.uploaded_at else None,
        }
        for s in statements
    ]


@router.get("/{statement_id}/insights", response_model=StatementInsightsResponse)
async def get_statement_insights(
    statement_id: str,
    db: Session = Depends(get_db),
):
    """
    Retrieves and generates dynamic aggregates, category spending breakdowns,
    recurring subscription checks, and suspicious transaction anomaly logs
    for a specific statement ID.
    """
    try:
        insights = InsightsService.generate_statement_insights(db, statement_id)
        return insights
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Insights engine failure: {str(e)}",
        )
