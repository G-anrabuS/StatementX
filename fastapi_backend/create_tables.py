from sqlalchemy import text
from app.core.database import engine, Base
from app.models.statement import Statement
from app.models.transaction import Transaction
from app.models.merchant_cache import MerchantCache

# If using PostgreSQL, enable pg_trgm extension for fuzzy similarity support
if engine.url.drivername.startswith("postgresql") or "postgres" in str(engine.url):
    print("[DATABASE] Enabling pg_trgm extension for PostgreSQL fuzzy matching...")
    try:
        with engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm;"))
            conn.commit()
    except Exception as e:
        print(f"[WARNING] Could not enable pg_trgm extension directly: {e}")

Base.metadata.create_all(bind=engine)

print("[SUCCESS] StatementX tables created.")

