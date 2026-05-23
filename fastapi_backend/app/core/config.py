import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    PROJECT_NAME: str = "StatementX AI Core Engine"
    API_STR: str = "/api"

    GEMINI_API_KEY: str
    DATABASE_URL: str

    def __init__(self):
        self.GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
        self.DATABASE_URL = os.getenv("DATABASE_URL", "")

        if not self.GEMINI_API_KEY:
            raise ValueError(
                "❌ System Configuration Error: GEMINI_API_KEY is missing from .env file!"
            )

        if not self.DATABASE_URL:
            raise ValueError(
                "❌ System Configuration Error: DATABASE_URL is missing from .env file!"
            )


settings = Settings()
