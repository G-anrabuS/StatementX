from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="StatementX API",
    description="Backend engine for bank statement extraction, categorization, and insights.",
    version="0.1.0"
)

# Enable CORS for Flutter development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "project": "StatementX",
        "status": "Online",
        "message": "Welcome to the Bank Statement Analyzer API"
    }
