import uuid
from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from app.core.database import Base, GUID

class User(Base):
    __tablename__ = "users"

    user_id = Column(
        GUID,
        primary_key=True,
        default=uuid.uuid4,
    )
    
    google_id = Column(
        String,
        unique=True,
        nullable=False,
    )
    
    email = Column(
        String,
        unique=True,
        nullable=False,
    )
    
    name = Column(
        String,
        nullable=False,
    )
    
    profile_picture = Column(
        String,
        nullable=True,
    )
    
    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
    )
