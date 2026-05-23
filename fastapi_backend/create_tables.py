from app.core.database import engine, Base
from app.models.statement import Statement
from app.models.transaction import Transaction
from app.models.merchant_cache import MerchantCache

Base.metadata.create_all(bind=engine)

print("✅ StatementX tables created.")
