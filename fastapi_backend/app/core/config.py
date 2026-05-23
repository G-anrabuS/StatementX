import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = "StatementX AI Core Engine"
    API_STR: str = "/api"
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    def __init__(self):
        if not self.GEMINI_API_KEY:
            raise ValueError("❌ System Configuration Error: GEMINI_API_KEY is missing from .env file!")

settings = Settings()