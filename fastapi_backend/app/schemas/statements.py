from pydantic import BaseModel, Field, field_validator
from typing import List, Optional

# ──────────────────────────────────────────────────────────────────────────────
# RAW SCHEMAS FOR GEMINI (No Default Values Allowed by Google GenAI API)
# ──────────────────────────────────────────────────────────────────────────────

class RawTransactionItem(BaseModel):
    date: str = Field(
        description="Transaction date exactly as parsed from the statement ledger (e.g., DD/MM/YYYY)"
    )

    narration: str = Field(
        description="Complete raw transaction description including merchant info, UPI IDs, or transfer references"
    )

    debit: float = Field(
        description="Amount debited from the account. Use 0.0 if no debit exists."
    )

    credit: float = Field(
        description="Amount credited into the account. Use 0.0 if no credit exists."
    )

    balance: float = Field(description="Running account balance after this transaction")

    @field_validator("debit", "credit", "balance", mode="before")
    @classmethod
    def clean_numeric_value(cls, v):
        """Sanitizes dirty numeric strings (with commas, spaces, currency symbols) from raw text."""
        if isinstance(v, str):
            cleaned = v.replace(",", "").replace("₹", "").replace("$", "").replace(" ", "").strip()
            if not cleaned:
                return 0.0
            try:
                return float(cleaned)
            except ValueError:
                return 0.0
        if v is None:
            return 0.0
        return v


class RawStatementExtractionResponse(BaseModel):
    bank_name: str = Field(
        description="Identified bank name (e.g., State Bank of India, HDFC Bank)"
    )

    total_transactions: int = Field(
        description="Total number of parsed transaction entries"
    )

    transactions: List[RawTransactionItem] = Field(
        description="Chronological list of extracted transactions"
    )


# ──────────────────────────────────────────────────────────────────────────────
# ENRICHED SCHEMAS FOR API & FLUTTER CLIENT (Allows default NLP metadata fields)
# ──────────────────────────────────────────────────────────────────────────────

class TransactionItem(BaseModel):
    date: str
    narration: str
    debit: float
    credit: float
    balance: float
    category: Optional[str] = "Unclassified_Miscellaneous"
    sub_category: Optional[str] = "Unknown"
    confidence: Optional[float] = 0.00


class StatementExtractionResponse(BaseModel):
    bank_name: str
    total_transactions: int
    transactions: List[TransactionItem]
