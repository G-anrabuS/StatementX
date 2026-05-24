import uuid
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from pgvector.sqlalchemy import Vector
from app.core.database import Base, GUID, JSONB


class Statement(Base):
    __tablename__ = "statements"

    statement_id = Column(
        GUID,
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

    user_id = Column(
        GUID,
        ForeignKey("users.user_id"),
        nullable=True,  # Temporarily nullable for migration/legacy data
    )


class StatementThesisChunk(Base):
    __tablename__ = "statement_thesis_chunks"

    chunk_id = Column(
        GUID,
        primary_key=True,
        default=uuid.uuid4,
    )

    statement_id = Column(
        GUID,
        ForeignKey("statements.statement_id"),
        nullable=False,
    )

    section_title = Column(
        String,
        nullable=False,
    )

    content = Column(
        String,
        nullable=False,
    )

    # 768-dimension pgvector embedding for Gemini text-embedding-004
    embedding = Column(
        Vector(768),
        nullable=True,
    )


