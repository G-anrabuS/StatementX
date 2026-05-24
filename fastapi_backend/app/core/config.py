import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    PROJECT_NAME: str = "StatementX AI Core Engine"
    API_STR: str = "/api"

    GEMINI_API_KEY: str
    DATABASE_URL: str
    
    # JWT Configuration
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    
    # Google OAuth Configuration
    GOOGLE_WEB_CLIENT_ID: str
    GOOGLE_ANDROID_CLIENT_ID: str

    def __init__(self):
        self.GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
        self.DATABASE_URL = os.getenv("DATABASE_URL", "")
        
        self.SECRET_KEY = os.getenv("SECRET_KEY", "fallback_secret_for_dev_only_change_in_production")
        self.GOOGLE_WEB_CLIENT_ID = os.getenv("GOOGLE_WEB_CLIENT_ID", "")
        self.GOOGLE_ANDROID_CLIENT_ID = os.getenv("GOOGLE_ANDROID_CLIENT_ID", "")

        # Configuration Assertions & Validations
        if not self.GEMINI_API_KEY:
            raise ValueError(
                "[ERROR] System Configuration Error: GEMINI_API_KEY is missing from .env file!"
            )

        if not self.DATABASE_URL:
            print(
                "WARNING: DATABASE_URL is missing from .env file. Falling back to local SQLite database: 'sqlite:///./statementx.db'"
            )
            self.DATABASE_URL = "sqlite:///./statementx.db"

        # Resilient SQLite CWD Absolute Path Resolution
        if self.DATABASE_URL.startswith("sqlite:///./"):
            # Grandparent directory of app/core is fastapi_backend
            base_dir = os.path.dirname(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            )
            db_file = self.DATABASE_URL.replace("sqlite:///./", "")
            self.DATABASE_URL = f"sqlite:///{os.path.join(base_dir, db_file)}"


settings = Settings()
