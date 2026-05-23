from pydantic import BaseModel, Field
from typing import List, Optional

class TransactionItem(BaseModel):
    date: str = Field(description="The transaction date exactly as parsed from the statement ledger (e.g., DD/MM/YYYY)")
    narration: str = Field(description="The complete raw description field including merchant info, UPI IDs, or transfer reference numbers")
    debit: Optional[float] = Field(default=0.0, description="Amount withdrawn or debited from the account. Must be 0.0 if empty.")
    credit: Optional[float] = Field(default=0.0, description="Amount deposited or credited into the account. Must be 0.0 if empty.")
    balance: float = Field(description="The running account balance directly following this specific transaction ledger line")

class StatementExtractionResponse(BaseModel):
    bank_name: str = Field(description="Identified corporate identity name of the Indian Bank (e.g., State Bank of India, HDFC Bank)")
    total_transactions: int = Field(description="The absolute total row count of individual transactional entries parsed")
    transactions: List[TransactionItem] = Field(description="Chronological sequential array list tracking individual operations")