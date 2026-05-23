from pydantic import BaseModel, Field
from typing import List


class TransactionItem(BaseModel):
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


class StatementExtractionResponse(BaseModel):
    bank_name: str = Field(
        description="Identified bank name (e.g., State Bank of India, HDFC Bank)"
    )

    total_transactions: int = Field(
        description="Total number of parsed transaction entries"
    )

    transactions: List[TransactionItem] = Field(
        description="Chronological list of extracted transactions"
    )
