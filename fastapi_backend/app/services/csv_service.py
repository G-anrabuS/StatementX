import polars as pl
from datetime import datetime
from typing import List, Dict, Optional
from app.schemas.statements import StatementExtractionResponse, TransactionItem

class CSVStatementService:
    @staticmethod
    def parse_csv(csv_bytes: bytes, filename: str) -> StatementExtractionResponse:
        """
        Parses arbitrary CSV bank statements using Polars.
        Fuzzy-maps messy headers, cleans currency strings/commas, 
        and normalizes everything into a unified 5-column schema.
        """
        # Load CSV using Polars
        # Polars handles bytes natively via a BytesIO stream
        import io
        csv_stream = io.BytesIO(csv_bytes)
        
        # Read with polars, trying to handle common separator types
        try:
            df = pl.read_csv(csv_stream, infer_schema_length=1000)
        except Exception as e:
            # Fallback if standard parsing fails (e.g., semicolons)
            csv_stream.seek(0)
            df = pl.read_csv(csv_stream, separator=";", infer_schema_length=1000)

        # Normalize column names to lowercase and strip whitespace
        df = df.rename({col: col.strip().lower() for col in df.columns})
        columns = df.columns

        # Define fuzzy-mapping dictionary
        header_map = {
            "date": ["date", "transaction date", "txn date", "value date", "post date", "booking date"],
            "narration": ["particulars", "description", "narration", "remarks", "txn description", "transaction description", "transaction details", "narration/particulars"],
            "debit": ["withdrawal", "debit", "debit amount", "dr", "withdrawal (dr)", "withdrawals", "amount (dr)", "payment"],
            "credit": ["deposit", "credit", "credit amount", "cr", "deposit (cr)", "deposits", "amount (cr)", "receipt"],
            "balance": ["balance", "running balance", "balance (inr)", "account balance", "bal", "available balance"]
        }

        # Find closest match for each predefined column
        mapped_cols: Dict[str, str] = {}
        for target, variations in header_map.items():
            for var in variations:
                if var in columns:
                    mapped_cols[target] = var
                    break
            # If no exact variation matches, check fuzzy substring matches
            if target not in mapped_cols:
                for col in columns:
                    if any(v in col for v in variations):
                        mapped_cols[target] = col
                        break

        # Validate that we found at least the core columns (date, narration, balance)
        required_keys = ["date", "narration", "balance"]
        for r_key in required_keys:
            if r_key not in mapped_cols:
                raise ValueError(f"Could not map required CSV column: '{r_key}'. Checked headers: {columns}")

        # If debit/credit columns are missing, we check if there is a single 'amount' column
        if "debit" not in mapped_cols and "credit" not in mapped_cols:
            amount_col = None
            for col in columns:
                if any(v in col for v in ["amount", "value", "txn amount"]):
                    amount_col = col
                    break
            if amount_col:
                # We split a single amount column into debit/credit
                df = df.with_columns([
                    pl.col(amount_col).cast(pl.Utf8).str.replace_all(",", "").str.strip_chars().cast(pl.Float64, strict=False).alias("_temp_amount")
                ])
                df = df.with_columns([
                    pl.when(pl.col("_temp_amount") < 0).then(-pl.col("_temp_amount")).otherwise(0.0).alias("debit"),
                    pl.when(pl.col("_temp_amount") >= 0).then(pl.col("_temp_amount")).otherwise(0.0).alias("credit")
                ])
                mapped_cols["debit"] = "debit"
                mapped_cols["credit"] = "credit"
            else:
                raise ValueError("Could not find debit/credit or a single transaction amount column.")

        # Ensure we have both debit and credit columns
        if "debit" not in mapped_cols:
            df = df.with_columns(pl.lit(0.0).alias("debit"))
            mapped_cols["debit"] = "debit"
        if "credit" not in mapped_cols:
            df = df.with_columns(pl.lit(0.0).alias("credit"))
            mapped_cols["credit"] = "credit"

        # Construct final cleaned Polars DataFrame with predefined 5 columns
        select_exprs = []
        for target, original in mapped_cols.items():
            select_exprs.append(pl.col(original).alias(target))
        
        df_cleaned = df.select(select_exprs)

        # Clean numerical columns (cast to string, strip symbols/commas, cast to float, fill nulls with 0.0)
        for col_name in ["debit", "credit", "balance"]:
            df_cleaned = df_cleaned.with_columns([
                pl.col(col_name)
                .cast(pl.Utf8)
                .str.replace_all("[^0-9.-]", "") # Strip currency signs, commas, whitespace
                .str.strip_chars()
                .cast(pl.Float64, strict=False)
                .fill_null(0.0)
                .alias(col_name)
            ])

        # Clean date column and normalize format to DD/MM/YYYY
        df_cleaned = df_cleaned.with_columns([
            pl.col("date").cast(pl.Utf8).str.strip_chars().alias("date")
        ])

        # Standardize date format output
        transactions: List[TransactionItem] = []
        for row in df_cleaned.iter_rows(named=True):
            raw_date = row["date"]
            parsed_date = CSVStatementService._normalize_date(raw_date)
            
            transactions.append(TransactionItem(
                date=parsed_date,
                narration=str(row["narration"]) if row["narration"] is not None else "UNKNOWN",
                debit=float(row["debit"]),
                credit=float(row["credit"]),
                balance=float(row["balance"])
            ))

        # Inferred bank name from filename or headers
        bank_name = "Imported CSV Statement"
        if "hdfc" in filename.lower():
            bank_name = "HDFC Bank (CSV)"
        elif "sbi" in filename.lower():
            bank_name = "State Bank of India (CSV)"
        elif "icici" in filename.lower():
            bank_name = "ICICI Bank (CSV)"
        elif "axis" in filename.lower():
            bank_name = "Axis Bank (CSV)"

        return StatementExtractionResponse(
            bank_name=bank_name,
            total_transactions=len(transactions),
            transactions=transactions
        )

    @staticmethod
    def _normalize_date(date_str: str) -> str:
        """
        Attempts to parse common bank date strings and standardizes to DD/MM/YYYY.
        """
        if not date_str:
            return datetime.now().strftime("%d/%m/%Y")
            
        for fmt in [
            "%d/%m/%Y", "%d-%m-%Y", "%d.%m.%Y",
            "%Y-%m-%d", "%Y/%m/%d",
            "%d %b %Y", "%d %B %Y",
            "%b %d, %Y", "%B %d, %Y"
        ]:
            try:
                dt = datetime.strptime(date_str, fmt)
                return dt.strftime("%d/%m/%Y")
            except ValueError:
                continue
                
        # If all else fails, return raw string to avoid losing historical date details
        return date_str
