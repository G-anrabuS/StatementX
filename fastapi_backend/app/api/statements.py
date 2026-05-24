from fastapi import APIRouter, UploadFile, File, HTTPException, Depends, Form
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import List
from app.models.statement import Statement
from app.schemas.insights import (
    StatementInsightsResponse,
    AICoachResponse,
    ChatRequest,
    ChatResponse,
)
from app.schemas.visualization import VisualizationResponse
from app.services.insights_service import InsightsService
from app.services.chatbot_service import ChatbotService
from app.services.visualization_service import VisualizationService
from app.services.pdf_service import PDFReportService


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
    password: str = Form(None),  # <-- Add optional form parameter for password
    db: Session = Depends(get_db),
):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    filename_lower = file.filename.lower()
    is_pdf = filename_lower.endswith(".pdf")
    is_csv = filename_lower.endswith(".csv")

    if not (is_pdf or is_csv):
        raise HTTPException(
            status_code=400, detail="Only PDF and CSV files are allowed"
        )

    try:
        file_bytes = await file.read()

        if is_csv:
            parsed_result = CSVStatementService.parse_csv(
                csv_bytes=file_bytes,
                filename=file.filename,
            )
        else:
            # Pass the password field directly to your extractor service
            parsed_result = await extractor.execute_semantic_parse(
                file_bytes, password=password
            )

        enriched_transactions = enrich_transactions(db, parsed_result.transactions)

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

    # Catch specific password exceptions thrown from the extractor service
    except ValueError as val_err:
        err_msg = str(val_err).lower()
        if "password required" in err_msg:
            raise HTTPException(status_code=401, detail="PASSWORD_REQUIRED")
        elif "invalid password" in err_msg:
            raise HTTPException(status_code=401, detail="INVALID_PASSWORD")

        raise HTTPException(status_code=400, detail=str(val_err))

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
        insights = await InsightsService.generate_statement_insights(
            db, statement_id, include_ai_coach=False
        )
        return insights
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Insights engine failure: {str(e)}",
        )


@router.get("/{statement_id}/ai-coach", response_model=AICoachResponse)
async def get_statement_ai_coach(
    statement_id: str,
    db: Session = Depends(get_db),
):
    """
    Retrieves and generates ONLY the AI-powered financial summary and recommendations
    (narrative coach analysis and structured prioritized actions) for a specific statement ID.
    """
    try:
        insights = await InsightsService.generate_statement_insights(
            db, statement_id, include_ai_coach=True
        )
        return AICoachResponse(
            summary=insights.ai_summary,
            recommendations=insights.ai_recommendations,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"AI coach engine failure: {str(e)}",
        )


@router.post("/{statement_id}/chat", response_model=ChatResponse)
async def chat_with_statement(
    statement_id: str,
    payload: ChatRequest,
    db: Session = Depends(get_db),
):
    """
    RAG-based semantic chatbot to chat with a bank statement's transactions.
    Indexes narration descriptions into 768-dimension vectors and searches them semantically.
    """
    try:
        reply, sources = await ChatbotService.chat_with_statement(
            db=db,
            statement_id=statement_id,
            message=payload.message,
            chat_history=payload.chat_history,
        )
        return ChatResponse(response=reply, sources=sources)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Chatbot service failure: {str(e)}",
        )


@router.get("/{statement_id}/visualization", response_model=VisualizationResponse)
async def get_statement_visualization(
    statement_id: str,
    db: Session = Depends(get_db),
):
    """
    Retrieves personal finance intelligence, indicators, and charts visualization aggregates
    (Cash Flow timeline, 50/30/20 budget framework, weekday/weekend distribution, category breakdown)
    for a specific statement ID.
    """
    try:
        data = VisualizationService.calculate_visualization_data(db, statement_id)
        return data
    except ValueError as val_err:
        raise HTTPException(
            status_code=404,
            detail=str(val_err),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Visualization aggregator failure: {str(e)}",
        )


@router.get("/{statement_id}/export-pdf")
async def export_statement_pdf_report(
    statement_id: str,
    db: Session = Depends(get_db),
):
    """
    Generates and exports a premium 5-page financial health assessment and transaction breakdown
    PDF report for immediate download.
    """
    try:
        pdf_buffer = PDFReportService.generate_pdf_report(db, statement_id)

        # Build clean formatted filename
        filename = f"StatementX_Analysis_{statement_id[:8]}.pdf"

        return StreamingResponse(
            pdf_buffer,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"},
        )
    except ValueError as val_err:
        raise HTTPException(
            status_code=404,
            detail=str(val_err),
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"PDF report generation engine failure: {str(e)}",
        )
