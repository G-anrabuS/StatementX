import re
import logging
from datetime import datetime, date
from collections import defaultdict
from typing import List, Dict, Tuple
from sqlalchemy.orm import Session

from app.models.transaction import Transaction
from app.services.ai_coach_service import AICoachService
from app.schemas.insights import (
    StatementInsightsResponse,
    SubscriptionItem,
    AnomalyItem,
)

logger = logging.getLogger(__name__)


class InsightsService:
    @staticmethod
    async def generate_statement_insights(db: Session, statement_id: str, include_ai_coach: bool = False) -> StatementInsightsResponse:
        """
        Processes database records for a specific statement to calculate aggregates,
        identify recurring subscriptions, flag potential transaction anomalies, and
        optionally generate AI-powered cash flow summaries and recommendations.
        """
        # 1. Fetch transactions chronologically
        transactions = (
            db.query(Transaction)
            .filter(Transaction.statement_id == statement_id)
            .order_by(Transaction.date.asc())
            .all()
        )

        if not transactions:
            return StatementInsightsResponse(
                total_income=0.0,
                total_expense=0.0,
                net_savings=0.0,
                saving_rate=0.0,
                highest_spending_category="None",
                category_breakdown={},
                subscriptions=[],
                anomalies=[],
                ai_summary="No transaction data available.",
                ai_recommendations=[]
            )

        # 2. Basic Aggregations
        total_income = 0.0
        total_expense = 0.0
        category_breakdown = defaultdict(float)

        debit_amounts = []
        debit_transactions = []

        for txn in transactions:
            debit_val = float(txn.debit)
            credit_val = float(txn.credit)

            if credit_val > 0:
                total_income += credit_val
            
            if debit_val > 0:
                total_expense += debit_val
                debit_amounts.append(debit_val)
                debit_transactions.append(txn)
                
                # Map category
                cat = txn.category or "Unclassified_Miscellaneous"
                category_breakdown[cat] += debit_val

        net_savings = total_income - total_expense
        saving_rate = (net_savings / total_income * 100) if total_income > 0 else 0.0

        # Find highest spending category
        highest_spending_category = "None"
        if category_breakdown:
            highest_spending_category = max(category_breakdown, key=category_breakdown.get)

        # 3. Detect Recurring Payments (Subscriptions)
        subscriptions = InsightsService._detect_subscriptions(transactions)

        # 4. Detect Unusual Transactions (Anomalies)
        anomalies = InsightsService._detect_anomalies(debit_transactions, debit_amounts)

        ai_summary = ""
        ai_recommendations = []

        # 5. Persistent Caching & AI Generation Layer (Decoupled & Modularized)
        if include_ai_coach:
            ai_summary, ai_recommendations = await AICoachService.get_or_generate_coach_insights(
                db=db,
                statement_id=statement_id,
                debit_transactions=debit_transactions,
                total_income=total_income,
                total_expense=total_expense,
                net_savings=net_savings,
                saving_rate=saving_rate,
                highest_spending_category=highest_spending_category,
                category_breakdown=category_breakdown,
                subscriptions=subscriptions,
                anomalies=anomalies
            )

        return StatementInsightsResponse(
            total_income=round(total_income, 2),
            total_expense=round(total_expense, 2),
            net_savings=round(net_savings, 2),
            saving_rate=round(saving_rate, 2),
            highest_spending_category=highest_spending_category,
            category_breakdown={k: round(v, 2) for k, v in category_breakdown.items()},
            subscriptions=subscriptions,
            anomalies=anomalies,
            ai_summary=ai_summary,
            ai_recommendations=ai_recommendations
        )




    @staticmethod
    def _detect_subscriptions(transactions: List[Transaction]) -> List[SubscriptionItem]:
        """
        Runs interval delta frequency checks to automatically classify periodic subscriptions.
        """
        merchant_groups = defaultdict(list)
        
        # Group transactions by cleaned vendor narration string
        for txn in transactions:
            # We focus on expenses (debit transactions) for subscription audits
            if float(txn.debit) <= 0:
                continue
                
            cleaned_vendor = InsightsService._clean_vendor_name(txn.raw_description)
            merchant_groups[cleaned_vendor].append(txn)

        subscriptions = []
        
        for vendor, txns in merchant_groups.items():
            # Subscriptions must have occurred at least twice to establish periodicity
            if len(txns) < 2:
                continue

            # Sort chronologically
            txns_sorted = sorted(txns, key=lambda t: t.date)
            
            # Calculate time intervals (deltas) in days
            deltas = []
            amounts = []
            for i in range(1, len(txns_sorted)):
                delta_days = (txns_sorted[i].date - txns_sorted[i-1].date).days
                deltas.append(delta_days)
                amounts.append(float(txns_sorted[i].debit))
            # Include first item's amount
            amounts.append(float(txns_sorted[0].debit))

            avg_delta = sum(deltas) / len(deltas)
            avg_amount = sum(amounts) / len(amounts)

            # Monthly subscription signature: avg delta is ~30 days (bounds: 25 - 35)
            # Weekly subscription signature: avg delta is ~7 days (bounds: 5 - 9)
            frequency = None
            if 25 <= avg_delta <= 35:
                frequency = "monthly"
            elif 5 <= avg_delta <= 9:
                frequency = "weekly"
            elif 80 <= avg_delta <= 100:
                frequency = "quarterly"

            if frequency:
                last_txn = txns_sorted[-1]
                subscriptions.append(SubscriptionItem(
                    vendor=vendor.title(),
                    average_amount=round(avg_amount, 2),
                    frequency=frequency,
                    last_transaction_date=last_txn.date.strftime("%d/%m/%Y")
                ))

        return subscriptions

    @staticmethod
    def _detect_anomalies(debit_transactions: List[Transaction], debit_amounts: List[float]) -> List[AnomalyItem]:
        """
        Audits transaction logs to identify high-value outliers, duplicates, and late-night activity.
        """
        anomalies = []
        if not debit_transactions:
            return anomalies

        # Math calculations for standard Z-score deviations
        n = len(debit_amounts)
        avg = sum(debit_amounts) / n if n > 0 else 0
        
        # Calculate standard deviation
        variance = sum((x - avg) ** 2 for x in debit_amounts) / n if n > 0 else 0
        std_dev = variance ** 0.5

        # Check for anomalies
        seen_hashes = defaultdict(list)

        for txn in debit_transactions:
            amount = float(txn.debit)
            
            # 1. High Value Outliers:
            # If transaction is > 3 * average, OR matches standard deviation boundary when std_dev is significant
            is_high_value = False
            reason = ""
            
            if std_dev > 50 and amount > (avg + 2.5 * std_dev):
                is_high_value = True
                reason = f"Outlier transaction: amount exceeds statistical standard deviation boundary (average is {round(avg, 2)})"
            elif amount > max(5000.0, avg * 4): # Absolute high threshold fallback
                is_high_value = True
                reason = f"Unusually large transaction: amount is 4x greater than typical user average"

            if is_high_value:
                anomalies.append(AnomalyItem(
                    transaction_id=str(txn.transaction_id),
                    date=txn.date.strftime("%d/%m/%Y"),
                    narration=txn.raw_description,
                    amount=amount,
                    type="high_value",
                    reason=reason
                ))

            # 2. Duplicate Charges:
            # Same date, same amount, same cleaned narration string
            cleaned_vendor = InsightsService._clean_vendor_name(txn.raw_description)
            date_str = txn.date.strftime("%Y-%m-%d")
            dup_hash = f"{date_str}_{amount:.2f}_{cleaned_vendor}"
            
            seen_hashes[dup_hash].append(txn)

            # 3. Late Night Payments:
            # Look for late-night time stamps in transaction narration if present (23:00 - 05:00)
            time_match = re.search(r"(\d{2}):(\d{2})(?::\d{2})?", txn.raw_description)
            if time_match:
                hour = int(time_match.group(1))
                if hour >= 23 or hour <= 5:
                    anomalies.append(AnomalyItem(
                        transaction_id=str(txn.transaction_id),
                        date=txn.date.strftime("%d/%m/%Y"),
                        narration=txn.raw_description,
                        amount=amount,
                        type="late_night",
                        reason=f"Suspicious activity: transaction posted late at night ({time_match.group(0)})"
                    ))

        # Check grouped duplicate transactions and add to anomaly logs
        for hash_key, dup_txns in seen_hashes.items():
            if len(dup_txns) >= 2:
                for txn in dup_txns:
                    anomalies.append(AnomalyItem(
                        transaction_id=str(txn.transaction_id),
                        date=txn.date.strftime("%d/%m/%Y"),
                        narration=txn.raw_description,
                        amount=float(txn.debit),
                        type="duplicate",
                        reason="Multiple identical charges posted on the same calendar date"
                    ))

        return anomalies

    @staticmethod
    def _clean_vendor_name(raw_desc: str) -> str:
        """
        Cleans cryptic UPI codes and digits from descriptions to isolate core merchant signatures.
        """
        # Convert to lowercase
        desc = raw_desc.lower().strip()
        
        # If it's a UPI transaction, extract the merchant tag
        # e.g., UPI/Netflix/39420... -> netflix
        if "upi" in desc or "/" in desc:
            parts = desc.split("/")
            for part in parts:
                part = part.strip()
                if part and not part.isdigit() and part not in ["upi", "dr", "cr", "xx"]:
                    # Clean out trailing digits/VPA handles (e.g. bharatpe902@ybl -> bharatpe)
                    part = re.sub(r"\d+", "", part)
                    part = part.split("@")[0].strip()
                    if len(part) > 2:
                        return part
                        
        # General regex cleanup: strip numbers, transaction IDs, specific dates
        desc = re.sub(r"\d+", "", desc)
        desc = re.sub(r"[\-/\\_*]", " ", desc)
        desc = re.sub(r"\s+", " ", desc).strip()
        
        return desc if len(desc) > 2 else "miscellaneous_vendor"
