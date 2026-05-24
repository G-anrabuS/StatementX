from sqlalchemy.orm import Session
from datetime import datetime
from collections import defaultdict
from typing import List, Dict

from app.models.statement import Statement
from app.models.transaction import Transaction
from app.services.insights_service import InsightsService
from app.schemas.visualization import (
    VisualizationResponse,
    HealthIndicators,
    CashFlowDataPoint,
    BudgetAllocation,
    CategoryVisualItem,
    SpendingPattern,
)

class VisualizationService:
    @staticmethod
    def get_category_color(category_name: str) -> str:
        """
        Returns a premium hex color code for each category to ensure visual consistency in the frontend.
        """
        cat_lower = category_name.lower()
        if "food" in cat_lower or "dining" in cat_lower:
            return "#E65100"  # Vibrant Orange
        elif "shopping" in cat_lower or "merchandise" in cat_lower:
            return "#6A1B9A"  # Royal Purple
        elif "travel" in cat_lower or "ride" in cat_lower:
            return "#1565C0"  # Deep Blue
        elif "utilities" in cat_lower or "bill" in cat_lower:
            return "#C2185B"  # Rose Red
        elif "entertainment" in cat_lower or "movie" in cat_lower or "recreation" in cat_lower:
            return "#00838F"  # Rich Teal
        elif "medical" in cat_lower or "health" in cat_lower or "wellness" in cat_lower:
            return "#2E7D32"  # Forest Green
        elif "subscription" in cat_lower:
            return "#D84315"  # Burnt Orange
        elif "auto" in cat_lower or "gas" in cat_lower or "fuel" in cat_lower:
            return "#0288D1"  # Sky Blue
        elif "transfer" in cat_lower:
            return "#37474F"  # Blue Grey
        elif "income" in cat_lower or "salary" in cat_lower:
            return "#2E7D32"  # Rich Emerald Green
        else:
            return "#757575"  # Medium Grey

    @staticmethod
    def calculate_visualization_data(db: Session, statement_id: str) -> VisualizationResponse:
        # 1. Fetch the statement metadata
        statement = db.query(Statement).filter(Statement.statement_id == statement_id).first()
        if not statement:
            raise ValueError(f"Statement with ID {statement_id} not found in database.")

        # 2. Fetch all transactions chronologically
        transactions = (
            db.query(Transaction)
            .filter(Transaction.statement_id == statement_id)
            .order_by(Transaction.date.asc())
            .all()
        )

        if not transactions:
            return VisualizationResponse(
                statement_id=statement_id,
                bank_name=statement.bank_name,
                health_indicators=HealthIndicators(
                    savings_rate=0.0,
                    burn_rate=0.0,
                    discretionary_spend_ratio=0.0,
                    essential_spend_ratio=0.0,
                    health_score=0.0,
                    health_rating="Critical",
                    liquidity_ratio=0.0,
                    average_daily_expense=0.0,
                    savings_consistency=0.0,
                ),
                cash_flow_timeline=[],
                budget_allocation=BudgetAllocation(
                    needs_amount=0.0,
                    needs_percentage=0.0,
                    wants_amount=0.0,
                    wants_percentage=0.0,
                    savings_amount=0.0,
                    savings_percentage=0.0,
                ),
                category_breakdown=[],
                spending_pattern=SpendingPattern(
                    weekday_total=0.0,
                    weekend_total=0.0,
                    weekday_average=0.0,
                    weekend_average=0.0,
                    weekday_count=0,
                    weekend_count=0,
                ),
            )

        # 3. Determine timeline grouping interval dynamically based on statement duration
        min_date = transactions[0].date
        max_date = transactions[-1].date
        days_in_period = (max_date - min_date).days + 1

        if days_in_period > 180:
            get_bucket_key = lambda d: d.strftime("%Y-%m")
        elif days_in_period > 45:
            get_bucket_key = lambda d: f"{d.year}-W{d.isocalendar()[1]:02d}"
        else:
            get_bucket_key = lambda d: d.strftime("%Y-%m-%d")

        # Basic aggregates and categorization groupings
        total_income = 0.0
        total_expense = 0.0
        needs_amount = 0.0
        wants_amount = 0.0

        debit_transactions = []
        debit_amounts = []
        credit_count = 0

        # Category aggregates helper
        category_totals = defaultdict(float)
        category_counts = defaultdict(int)

        # Dynamic time-bucketed cash flow aggregation helper
        timeline_groups = defaultdict(lambda: {"income": 0.0, "expense": 0.0, "last_balance": 0.0})

        # Weekday/weekend analysis helper
        weekday_total = 0.0
        weekend_total = 0.0
        weekday_count = 0
        weekend_count = 0

        # Classify categories into Essential Needs vs. Discretionary Wants
        essential_categories = {"utilities_recurring_bills", "utilities", "travel", "auto", "medical"}
        discretionary_categories = {"food", "shopping", "entertainment", "subscriptions", "subscriptions_memberships"}

        for txn in transactions:
            bucket_key = get_bucket_key(txn.date)
            debit_val = float(txn.debit)
            credit_val = float(txn.credit)
            balance_val = float(txn.balance)

            # Accumulate credits / debits
            if credit_val > 0:
                total_income += credit_val
                credit_count += 1
                timeline_groups[bucket_key]["income"] += credit_val

            if debit_val > 0:
                total_expense += debit_val
                debit_transactions.append(txn)
                debit_amounts.append(debit_val)
                timeline_groups[bucket_key]["expense"] += debit_val

                # Category mapping
                cat = txn.category or "Unclassified_Miscellaneous"
                cat_lower = cat.lower()
                category_totals[cat] += debit_val
                category_counts[cat] += 1

                # Segment spending into Needs vs Wants
                is_essential = False
                for ess in essential_categories:
                    if ess in cat_lower:
                        is_essential = True
                        break

                if is_essential:
                    needs_amount += debit_val
                else:
                    wants_amount += debit_val

                # Weekday vs Weekend Analysis
                # Python's weekday(): Mon=0, Tue=1, Wed=2, Thu=3, Fri=4, Sat=5, Sun=6
                wday = txn.date.weekday()
                if wday < 5:
                    weekday_total += debit_val
                    weekday_count += 1
                else:
                    weekend_total += debit_val
                    weekend_count += 1

            # Update final balance of the bucket (chronological sequence guarantees ending balance)
            timeline_groups[bucket_key]["last_balance"] = balance_val

        # 4. Generate Chronological Cash Flow Timeline
        cash_flow_timeline = []
        cumulative_income = 0.0
        cumulative_expense = 0.0

        sorted_buckets = sorted(timeline_groups.keys())
        for b_key in sorted_buckets:
            bucket_data = timeline_groups[b_key]
            cumulative_income += bucket_data["income"]
            cumulative_expense += bucket_data["expense"]

            cash_flow_timeline.append(
                CashFlowDataPoint(
                    date=b_key,
                    income=round(bucket_data["income"], 2),
                    expense=round(bucket_data["expense"], 2),
                    cumulative_income=round(cumulative_income, 2),
                    cumulative_expense=round(cumulative_expense, 2),
                    net_cash_flow=round(cumulative_income - cumulative_expense, 2),
                    balance=round(bucket_data["last_balance"], 2),
                )
            )

        # 5. Calculate Budget Allocations (50/30/20 Rule)
        savings_amount = total_income - total_expense
        needs_pct = (needs_amount / total_income * 100) if total_income > 0 else 0.0
        wants_pct = (wants_amount / total_income * 100) if total_income > 0 else 0.0
        savings_pct = (savings_amount / total_income * 100) if total_income > 0 else 0.0

        budget_allocation = BudgetAllocation(
            needs_amount=round(needs_amount, 2),
            needs_percentage=round(needs_pct, 2),
            wants_amount=round(wants_amount, 2),
            wants_percentage=round(wants_pct, 2),
            savings_amount=round(savings_amount, 2),
            savings_percentage=round(savings_pct, 2),
        )

        # 6. Generate Category Visual Breakdown (Top 5 + "Other Spending" Aggregation)
        category_breakdown = []
        raw_category_list = [(cat, amt) for cat, amt in category_totals.items()]
        # Sort descending by spent amount
        raw_category_list.sort(key=lambda x: x[1], reverse=True)

        top_n = raw_category_list[:5]
        others = raw_category_list[5:]

        for cat, amt in top_n:
            pct = (amt / total_expense * 100) if total_expense > 0 else 0.0
            category_breakdown.append(
                CategoryVisualItem(
                    category=cat,
                    amount=round(amt, 2),
                    percentage=round(pct, 2),
                    transaction_count=category_counts[cat],
                    color=VisualizationService.get_category_color(cat),
                )
            )

        if others:
            others_amount = sum(x[1] for x in others)
            others_count = sum(category_counts[x[0]] for x in others)
            others_pct = (others_amount / total_expense * 100) if total_expense > 0 else 0.0
            category_breakdown.append(
                CategoryVisualItem(
                    category="Other Spending",
                    amount=round(others_amount, 2),
                    percentage=round(others_pct, 2),
                    transaction_count=others_count,
                    color="#9E9E9E",  # Neutral grey for merged small categories
                )
            )

        # 7. Weekday vs Weekend Spending
        weekday_avg = (weekday_total / weekday_count) if weekday_count > 0 else 0.0
        weekend_avg = (weekend_total / weekend_count) if weekend_count > 0 else 0.0

        spending_pattern = SpendingPattern(
            weekday_total=round(weekday_total, 2),
            weekend_total=round(weekend_total, 2),
            weekday_average=round(weekday_avg, 2),
            weekend_average=round(weekend_avg, 2),
            weekday_count=weekday_count,
            weekend_count=weekend_count,
        )

        # 8. Financial Health Indicators Calculations
        savings_rate = (savings_amount / total_income * 100) if total_income > 0 else 0.0
        burn_rate = (total_expense / total_income * 100) if total_income > 0 else 0.0
        discretionary_spend_ratio = (wants_amount / total_income * 100) if total_income > 0 else 0.0
        essential_spend_ratio = (needs_amount / total_income * 100) if total_income > 0 else 0.0

        # Retrieve anomalies and subscriptions for penalties using standard insights helpers
        subscriptions = InsightsService._detect_subscriptions(transactions)
        anomalies = InsightsService._detect_anomalies(debit_transactions, debit_amounts)

        # Calculate Financial Health Score [0 - 100]
        health_score = 60.0

        # Savings rate impact: Surplus yields positive weight up to +20, deficit yields negative weight up to -30
        if savings_rate > 0:
            health_score += min(20.0, savings_rate * 0.5)
        else:
            health_score -= min(30.0, abs(savings_rate) * 0.75)

        # Burn rate threshold check
        if burn_rate <= 80.0:
            health_score += 10.0
        elif burn_rate > 100.0:
            health_score -= 20.0

        # Discretionary budget compliance
        if discretionary_spend_ratio <= 30.0:
            health_score += 5.0
        elif discretionary_spend_ratio > 50.0:
            health_score -= 10.0

        # Anomalies penalty
        if anomalies:
            health_score -= min(15.0, len(anomalies) * 3.0)

        # Subscription drain index
        if subscriptions and total_income > 0:
            sub_total_amt = sum(sub.average_amount for sub in subscriptions)
            sub_pct_income = (sub_total_amt / total_income * 100)
            health_score -= min(10.0, sub_pct_income * 0.5)

        # Cap within strictly verified bounds [0, 100]
        health_score = max(0.0, min(100.0, health_score))

        # Set human-friendly ratings
        if health_score >= 85.0:
            health_rating = "Excellent"
        elif health_score >= 70.0:
            health_rating = "Good"
        elif health_score >= 50.0:
            health_rating = "Fair"
        else:
            health_rating = "Critical"

        # Calculate liquidity ratio coverage (months of runway)
        ending_balance = float(transactions[-1].balance)
        liquidity_ratio = (ending_balance / total_expense) if total_expense > 0 else 0.0

        # Calculate average daily expense
        min_date = transactions[0].date
        max_date = transactions[-1].date
        days_in_period = (max_date - min_date).days + 1
        average_daily_expense = (total_expense / days_in_period) if days_in_period > 0 else 0.0

        # Calculate savings consistency score
        savings_consistency = (credit_count / len(transactions) * 100) if transactions else 0.0

        health_indicators = HealthIndicators(
            savings_rate=round(savings_rate, 2),
            burn_rate=round(burn_rate, 2),
            discretionary_spend_ratio=round(discretionary_spend_ratio, 2),
            essential_spend_ratio=round(essential_spend_ratio, 2),
            health_score=round(health_score, 2),
            health_rating=health_rating,
            liquidity_ratio=round(liquidity_ratio, 2),
            average_daily_expense=round(average_daily_expense, 2),
            savings_consistency=round(savings_consistency, 2),
        )

        return VisualizationResponse(
            statement_id=statement_id,
            bank_name=statement.bank_name,
            health_indicators=health_indicators,
            cash_flow_timeline=cash_flow_timeline,
            budget_allocation=budget_allocation,
            category_breakdown=category_breakdown,
            spending_pattern=spending_pattern,
        )
