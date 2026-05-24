from pydantic import BaseModel, Field
from typing import List

class CashFlowDataPoint(BaseModel):
    date: str = Field(description="Date of transaction aggregates (YYYY-MM-DD)")
    income: float = Field(description="Total income credits on this date")
    expense: float = Field(description="Total expense debits on this date")
    cumulative_income: float = Field(description="Running cumulative income up to this date")
    cumulative_expense: float = Field(description="Running cumulative expense up to this date")
    net_cash_flow: float = Field(description="Cumulative net cash flow (cumulative_income - cumulative_expense)")
    balance: float = Field(description="The final account balance on this date")

class BudgetAllocation(BaseModel):
    needs_amount: float = Field(description="Actual amount spent on essentials (needs)")
    needs_percentage: float = Field(description="Actual percentage of income spent on essentials")
    needs_target_percentage: float = Field(default=50.0, description="Recommended benchmark percentage for needs")
    
    wants_amount: float = Field(description="Actual amount spent on discretionary items (wants)")
    wants_percentage: float = Field(description="Actual percentage of income spent on discretionary items")
    wants_target_percentage: float = Field(default=30.0, description="Recommended benchmark percentage for wants")
    
    savings_amount: float = Field(description="Calculated net savings/surplus cash flow")
    savings_percentage: float = Field(description="Savings percentage velocity relative to total income")
    savings_target_percentage: float = Field(default=20.0, description="Recommended benchmark percentage for savings")

class CategoryVisualItem(BaseModel):
    category: str = Field(description="Transaction category label")
    amount: float = Field(description="Total amount spent under this category")
    percentage: float = Field(description="Percentage share relative to total expenses")
    transaction_count: int = Field(description="Number of transactions associated with this category")
    color: str = Field(description="Hex color code associated with this category for premium UI visualization")

class SpendingPattern(BaseModel):
    weekday_total: float = Field(description="Sum of all debits spent during weekdays (Monday to Friday)")
    weekend_total: float = Field(description="Sum of all debits spent during weekends (Saturday and Sunday)")
    weekday_average: float = Field(description="Average spent per weekday transaction")
    weekend_average: float = Field(description="Average spent per weekend transaction")
    weekday_count: int = Field(description="Number of weekday transactions")
    weekend_count: int = Field(description="Number of weekend transactions")

class HealthIndicators(BaseModel):
    savings_rate: float = Field(description="Net savings velocity percentage relative to total income")
    burn_rate: float = Field(description="Debt/expense-to-income percentage burn rate")
    discretionary_spend_ratio: float = Field(description="Total discretionary wants as percentage of income")
    essential_spend_ratio: float = Field(description="Total essential needs as percentage of income")
    health_score: float = Field(description="Calculated overall personal financial health score [0 to 100]")
    health_rating: str = Field(description="Human readable health rating: e.g., 'Excellent', 'Good', 'Fair', 'Critical'")
    liquidity_ratio: float = Field(description="Months of expense coverage: ending_balance / total_expenses")
    average_daily_expense: float = Field(description="Average amount debited per calendar day in statement period")
    savings_consistency: float = Field(description="Savings consistency index percentage based on cash inflow frequency")

class VisualizationResponse(BaseModel):
    statement_id: str = Field(description="Unique UUID reference of parsed bank statement")
    bank_name: str = Field(description="Source bank institution name")
    health_indicators: HealthIndicators = Field(description="High-fidelity personal financial health indicators")
    cash_flow_timeline: List[CashFlowDataPoint] = Field(description="Daily grouped cumulative income and expense trends")
    budget_allocation: BudgetAllocation = Field(description="Actual vs. target budget framework (50/30/20 rule)")
    category_breakdown: List[CategoryVisualItem] = Field(description="Visual styling aggregates for debit categories")
    spending_pattern: SpendingPattern = Field(description="Weekday vs. weekend transactional activity metrics")
