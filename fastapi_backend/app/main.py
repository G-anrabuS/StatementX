from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.statements import router as statements_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Flat scalable transaction parsing engine optimized for multi-bank structural variation handling"
)

# Crucial CORS configuration blocks. Without this, Flutter Web builds or mobile emulators will refuse incoming streams.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Swap to your explicit origin domain bounds during production hardening phases
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount our route cleanly combining the explicit configuration endpoint values
app.include_router(
    statements_router, 
    prefix=f"{settings.API_STR}/statements", 
    tags=["Statement Processing Services Framework"]
)