import uuid
from sqlalchemy import Column, String, Date, Numeric, Float, ForeignKey, Boolean
from pgvector.sqlalchemy import Vector
from app.core.database import Base, GUID, EncryptedString, EncryptedNumeric


class Transaction(Base):
    __tablename__ = "transactions"

    transaction_id = Column(
        GUID,
        primary_key=True,
        default=uuid.uuid4,
    )

    statement_id = Column(
        GUID,
        ForeignKey("statements.statement_id"),
        nullable=False,
    )

    date = Column(Date, nullable=False)

    raw_description = Column(EncryptedString, nullable=False)

    debit = Column(EncryptedNumeric, nullable=False)

    credit = Column(EncryptedNumeric, nullable=False)

    balance = Column(EncryptedNumeric, nullable=False)

    category = Column(EncryptedString, nullable=True)

    sub_category = Column(EncryptedString, nullable=True)

    confidence = Column(Float, nullable=True)

    user_override_cat = Column(
        String,
        nullable=True,
    )
    
    is_reconciled = Column(
        Boolean,
        default=True,
        nullable=False,
    )
    
    reconciliation_error = Column(
        Numeric(12, 2),
        default=0.0,
        nullable=False,
    )
    
    # 768-dimension pgvector embedding for Gemini text-embedding-004
    embedding = Column(Vector(768), nullable=True)
