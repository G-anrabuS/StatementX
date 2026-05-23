from pydantic import BaseModel, Field
from typing import List, Dict


class SubscriptionItem(BaseModel):
    vendor: str = Field(description="Name of the subscription vendor or merchant")
    average_amount: float = Field(description="Average billing amount for this recurring subscription")
    frequency: str = Field(description="Billing frequency: e.g., 'monthly', 'weekly', or 'irregular'")
    last_transaction_date: str = Field(description="The date of the most recent billing charge (DD/MM/YYYY)")


class AnomalyItem(BaseModel):
    transaction_id: str = Field(description="UUID string of the anomalous transaction")
    date: str = Field(description="Date of the anomaly (DD/MM/YYYY)")
    narration: str = Field(description="Raw narration description of the transaction")
    amount: float = Field(description="Debit amount of the anomalous transaction")
    type: str = Field(description="Category type of anomaly: e.g., 'high_value', 'duplicate', 'late_night'")
    reason: str = Field(description="Natural language explanation of why it was flagged")


class StatementInsightsResponse(BaseModel):
    total_income: float = Field(description="Sum of all credit deposits in the statement")
    total_expense: float = Field(description="Sum of all debit withdrawals in the statement")
    net_savings: float = Field(description="Net cash savings flow: Income - Expenses")
    saving_rate: float = Field(description="Savings percentage velocity relative to total income")
    highest_spending_category: str = Field(description="The category name where the user spent the most money")
    category_breakdown: Dict[str, float] = Field(description="Summarized totals spent per transaction category")
    subscriptions: List[SubscriptionItem] = Field(description="Detected recurring subscriptions and bills")
    anomalies: List[AnomalyItem] = Field(description="Detected anomalous, suspicious, or duplicate transactions")
