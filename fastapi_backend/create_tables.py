from app.core.database import engine, Base

# Import models so SQLAlchemy registers them
from app.models.statement import Statement
from app.models.transaction import Transaction

Base.metadata.create_all(bind=engine)

print("[SUCCESS] StatementX database tables created successfully.")
