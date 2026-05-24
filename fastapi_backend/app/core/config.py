import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    PROJECT_NAME: str = "StatementX AI Core Engine"
    API_STR: str = "/api"

    GEMINI_API_KEY: str
    DATABASE_URL: str

    # AWS Translate Configurations
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_REGION: str

    def __init__(self):
        self.GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
        self.DATABASE_URL = os.getenv("DATABASE_URL", "")

        # Pulling AWS Keys from .env environment variables
        self.AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "")
        self.AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "")
        self.AWS_REGION = os.getenv("AWS_REGION", "ap-south-1")

        # Configuration Assertions & Validations
        if not self.GEMINI_API_KEY:
            raise ValueError(
                "[ERROR] System Configuration Error: GEMINI_API_KEY is missing from .env file!"
            )

        if not self.AWS_ACCESS_KEY_ID or not self.AWS_SECRET_ACCESS_KEY:
            raise ValueError(
                "[ERROR] System Configuration Error: AWS credentials (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY) are missing from .env file!"
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
