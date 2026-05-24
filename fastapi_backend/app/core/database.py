import os
import json
import uuid
import base64
import hashlib
import difflib
from cryptography.fernet import Fernet
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.types import TypeDecorator, CHAR, TEXT
from sqlalchemy.dialects.postgresql import UUID as pgUUID, JSONB as pgJSONB

from app.core.config import settings

# If using SQLite, we need to allow access across multiple threads in FastAPI
connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.DATABASE_URL,
    echo=True,  # optional, shows SQL queries in terminal
    connect_args=connect_args,
)


def sqlite_similarity(a, b):
    if a is None or b is None:
        return 0.0
    return difflib.SequenceMatcher(None, str(a), str(b)).ratio()


@event.listens_for(engine, "connect")
def setup_sqlite_connection(dbapi_connection, connection_record):
    if settings.DATABASE_URL.startswith("sqlite"):
        dbapi_connection.create_function("similarity", 2, sqlite_similarity)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()


# Resolution of Encryption Key
ENCRYPTION_KEY = os.getenv("ENCRYPTION_KEY", "")
if not ENCRYPTION_KEY:
    # Stable master seed key fallback
    seed = b"StatementX_SuperSecret_Symmetric_Master_Salt"
    ENCRYPTION_KEY = base64.urlsafe_b64encode(hashlib.sha256(seed).digest()).decode()
    print("WARNING: 'ENCRYPTION_KEY' not found in env. Using stable default seed key. Please configure this in .env for production!")

fernet = Fernet(ENCRYPTION_KEY.encode())


class EncryptedString(TypeDecorator):
    """Transparent column-level encryption for String values using AES-256 (Fernet)."""
    impl = TEXT
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        # Encrypt plaintext string to base64 ciphertext
        encrypted_bytes = fernet.encrypt(str(value).encode('utf-8'))
        return encrypted_bytes.decode('utf-8')

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        try:
            # Decrypt ciphertext back to plaintext
            decrypted_bytes = fernet.decrypt(value.encode('utf-8'))
            return decrypted_bytes.decode('utf-8')
        except Exception as e:
            # Safe local fallback to raw value if decryption fails (e.g. legacy plain text rows)
            return value


class EncryptedNumeric(TypeDecorator):
    """Transparent column-level encryption for Numeric/Decimal float values using AES-256."""
    impl = TEXT
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        # Convert numeric/Decimal to string and encrypt
        encrypted_bytes = fernet.encrypt(str(value).encode('utf-8'))
        return encrypted_bytes.decode('utf-8')

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        try:
            # Decrypt back to float
            decrypted_bytes = fernet.decrypt(value.encode('utf-8'))
            return float(decrypted_bytes.decode('utf-8'))
        except Exception as e:
            try:
                return float(value)
            except Exception:
                return 0.0


class GUID(TypeDecorator):
    """Platform-independent GUID/UUID type.
    Uses PostgreSQL's UUID type, otherwise CHAR(36), storing as stringified HEX values.
    """
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(pgUUID(as_uuid=True))
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        elif dialect.name == 'postgresql':
            return str(value)
        else:
            if not isinstance(value, uuid.UUID):
                try:
                    return str(uuid.UUID(value))
                except ValueError:
                    return str(value)
            else:
                return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        else:
            if not isinstance(value, uuid.UUID):
                try:
                    return uuid.UUID(value)
                except ValueError:
                    return value
            else:
                return value


class JSONB(TypeDecorator):
    """Platform-independent JSONB type.
    Uses PostgreSQL's JSONB type, otherwise TEXT on other engines.
    """
    impl = TEXT
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(pgJSONB())
        else:
            return dialect.type_descriptor(TEXT())

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        if dialect.name == 'postgresql':
            return value
        else:
            return json.dumps(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        if dialect.name == 'postgresql':
            return value
        else:
            try:
                return json.loads(value)
            except Exception:
                return value


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()