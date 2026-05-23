from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.orm import Session

from app.schemas.statements import StatementExtractionResponse
from app.services.extractor import BankExtractorService
from app.services.statement_service import StatementService
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

        extracted_result = await extractor.execute_semantic_parse(pdf_bytes)

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
