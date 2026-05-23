from datetime import datetime

from app.models.statement import Statement
from app.models.transaction import Transaction


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
            transaction = Transaction(
                statement_id=statement.statement_id,
                date=datetime.strptime(txn.date, "%d/%m/%Y").date(),
                raw_description=txn.narration,
                debit=txn.debit,
                credit=txn.credit,
                balance=txn.balance,
            )

            db.add(transaction)

        db.commit()
        db.refresh(statement)

        return statement
