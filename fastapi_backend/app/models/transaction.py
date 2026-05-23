import uuid
from sqlalchemy import Column, String, Date, Numeric, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class Transaction(Base):
    __tablename__ = "transactions"

    transaction_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    statement_id = Column(
        UUID(as_uuid=True),
        ForeignKey("statements.statement_id"),
        nullable=False,
    )

    date = Column(
        Date,
        nullable=False,
    )

    raw_description = Column(
        String,
        nullable=False,
    )

    debit = Column(
        Numeric(12, 2),
        nullable=False,
    )

    credit = Column(
        Numeric(12, 2),
        nullable=False,
    )

    balance = Column(
        Numeric(12, 2),
        nullable=False,
    )

    ai_category = Column(
        String,
        nullable=True,
    )

    ai_confidence = Column(
        Float,
        nullable=True,
    )

    user_override_cat = Column(
        String,
        nullable=True,
    )
