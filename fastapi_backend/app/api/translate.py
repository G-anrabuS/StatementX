import boto3
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.config import settings

# Setting up the router prefix matching your API version convention
router = APIRouter(prefix="/translate", tags=["Translation"])


# Pydantic schemas for request and response validation
class HTMLTranslationRequest(BaseModel):
    html_content: str
    target_lang: str
    source_lang: str = "auto"


class HTMLTranslationResponse(BaseModel):
    translated_html: str


@router.post("/html", response_model=HTMLTranslationResponse)
async def translate_html_content(request: HTMLTranslationRequest):
    try:
        # Initializing the Amazon Translate Boto3 client using validated settings credentials
        translate_client = boto3.client(
            "translate",
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
            region_name=settings.AWS_REGION,
        )

        # Executing the translation query
        response = translate_client.translate_text(
            Text=request.html_content,
            SourceLanguageCode=request.source_lang,
            TargetLanguageCode=request.target_lang,
        )

        return HTMLTranslationResponse(
            translated_html=response.get("TranslatedText", "")
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"[ERROR] Amazon Translate operational error: {str(e)}",
        )
