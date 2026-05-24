from sqlalchemy import text
from app.core.database import engine, Base
from app.models.user import User
from app.models.statement import Statement, StatementThesisChunk
from app.models.transaction import Transaction
from app.models.merchant_cache import MerchantCache

# Self-healing: Automatically create the vector extension if running on PostgreSQL
try:
    with engine.connect() as conn:
        if engine.url.drivername.startswith("postgresql"):
            print("Ensuring pgvector extension is enabled...")
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()
except Exception as e:
    print(f"Note: Could not verify pgvector extension: {e}")

Base.metadata.create_all(bind=engine)

print("[SUCCESS] StatementX tables created.")
