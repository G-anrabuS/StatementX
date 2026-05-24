from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.statements import router as statements_router
from app.api.auth import router as auth_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Flat scalable transaction parsing engine optimized for multi-bank structural variation handling",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(
    statements_router,
    prefix=f"{settings.API_STR}/statements",
    tags=["Statement Processing Services Framework"],
)

app.include_router(
    auth_router,
    prefix=f"{settings.API_STR}/auth",
    tags=["Authentication Services Framework"],
)


@app.get("/", tags=["Root"])
async def root():
    return {
        "service": settings.PROJECT_NAME,
        "version": "1.0.0",
        "status": "running",
        "framework": "FastAPI",
        "docs": "/docs",
        "redoc": "/redoc",
        "api_base": settings.API_STR,
        "statement_extract_endpoint": f"{settings.API_STR}/statements/extract",
        "description": "AI-powered bank statement transaction extraction backend",
    }
