import uuid
from sqlalchemy import Column, String, Date, Numeric, Float, ForeignKey, Boolean
from app.core.database import Base, GUID


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

    raw_description = Column(String, nullable=False)

    debit = Column(Numeric(12, 2), nullable=False)

    credit = Column(Numeric(12, 2), nullable=False)

    balance = Column(Numeric(12, 2), nullable=False)

    category = Column(String, nullable=True)

    sub_category = Column(String, nullable=True)

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
