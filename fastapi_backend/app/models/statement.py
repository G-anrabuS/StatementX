import uuid
from sqlalchemy import Column, String, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from app.core.database import Base


class Statement(Base):
    __tablename__ = "statements"

    statement_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    file_name = Column(
        String,
        nullable=False,
    )

    bank_name = Column(
        String,
        nullable=False,
    )

    uploaded_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )

    raw_ai_output = Column(
        JSONB,
        nullable=False,
    )
