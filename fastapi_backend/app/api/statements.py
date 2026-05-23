from fastapi import APIRouter, UploadFile, File, HTTPException, status
from app.schemas.statements import StatementExtractionResponse
from app.services.extractor import BankExtractorService

router = APIRouter()
extraction_service = BankExtractorService()

@router.post(
    "/extract", 
    response_model=StatementExtractionResponse,
    status_code=status.HTTP_200_OK,
    summary="Direct multipart gateway route parsing uploaded files via semantic AI modeling layers"
)
async def process_bank_statement_pdf(file: UploadFile = File(...)):
    # Block non-PDF uploads at the network rim level before expending compute energy
    if not file.filename.lower().endswith('.pdf'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported payload interface structure. This resource endpoint strictly handles (.pdf) documents."
        )
    
    try:
        pdf_raw_data = await file.read()
        extracted_payload = await extraction_service.execute_semantic_parse(pdf_raw_data)
        return extracted_payload
    except Exception as error:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Core extraction pipeline layer failure: {str(error)}"
        )