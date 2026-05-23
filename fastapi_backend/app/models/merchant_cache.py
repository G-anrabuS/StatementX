import uuid
from sqlalchemy import Column, String
from sqlalchemy.dialects.postgresql import UUID
from app.core.database import Base


class MerchantCache(Base):
    __tablename__ = "merchant_cache"

    merchant_id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    merchant_name = Column(String, nullable=False)

    normalized_name = Column(
        String,
        nullable=False,
        unique=True,
    )

    category = Column(String, nullable=False)

    sub_category = Column(String, nullable=False)
