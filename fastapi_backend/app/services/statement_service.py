import re
import logging
from datetime import datetime, date

from app.models.statement import Statement
from app.models.transaction import Transaction

logger = logging.getLogger(__name__)


def parse_robust_date(date_str: str) -> date:
    """Robust parser trying multiple date formats commonly seen in bank statements."""
    date_str = date_str.strip()
    
    # Common formats to try sequentially
    formats = [
        "%d/%m/%Y", "%d-%m-%Y", "%d %m %Y",
        "%d/%m/%y", "%d-%m-%y", "%d %m %y",
        "%Y-%m-%d", "%Y/%m/%d",
        "%d %b %Y", "%d-%b-%Y", "%d/%b/%Y",
        "%d %B %Y", "%d-%B-%Y", "%d/%B/%Y",
        "%b %d, %Y", "%B %d, %Y",
        "%d %b, %Y", "%d %B, %Y"
    ]
    
    for fmt in formats:
        try:
            return datetime.strptime(date_str, fmt).date()
        except ValueError:
            continue
            
    # Try cleaning extra whitespace and tabs
    cleaned_date = re.sub(r"\s+", " ", date_str).strip()
    for fmt in formats:
        try:
            return datetime.strptime(cleaned_date, fmt).date()
        except ValueError:
            continue
            
    # If all formats fail, log and fallback to today to prevent pipeline crashes
    logger.error(f"Failed to parse date string '{date_str}', falling back to today's date.")
    return datetime.today().date()


class StatementService:
    @staticmethod
    def save_statement(db, file_name, extracted_data):
        statement = Statement(
            file_name=file_name,
            bank_name=extracted_data.bank_name,
            raw_ai_output=extracted_data.model_dump(),
        )

        db.add(statement)
        db.flush()

        for txn in extracted_data.transactions:
            # Robust date parsing fallback to prevent database write crashes
            parsed_date = None
            for fmt in ["%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"]:
                try:
                    parsed_date = datetime.strptime(txn.date, fmt).date()
                    break
                except ValueError:
                    continue
            
            if parsed_date is None:
                # Default to today's date if completely unparseable
                parsed_date = datetime.now().date()

            transaction = Transaction(
                statement_id=statement.statement_id,
                date=parse_robust_date(txn.date),
                raw_description=txn.narration,
                debit=txn.debit,
                credit=txn.credit,
                balance=txn.balance,
                # NLP categorization fields
                category=txn.category,
                sub_category=txn.sub_category,
                confidence=txn.confidence,
            )

            db.add(transaction)

        db.commit()
        db.refresh(statement)

        return statement

