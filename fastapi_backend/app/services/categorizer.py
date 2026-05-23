"""
Thread-safe singleton wrapper around the jonngan/distilbert-transaction-classifier
model. Outputs are mapped to our strict two-tiered local category taxonomy.
"""

import re
import threading
import logging
from typing import Optional

logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────────
# Full two-tier taxonomy (used for validation)
# ──────────────────────────────────────────────────────────────────────────────
CATEGORY_TAXONOMY: dict[str, list[str]] = {
    "Transfers_Internal_Movement": [
        "Bank_Transfer_To_Checking",
        "Bank_Transfer_From_Checking",
        "Bank_Transfer_To_Savings",
        "Bank_Transfer_From_Savings",
        "External_Transfer",
        "Keep_the_Change_Transfer",
        "Overdraft_Protection",
    ],
    "P2P_Digital_Wallets": ["Cash_App", "Zelle", "Venmo"],
    "Investments_Crypto": ["Brokerage_Investments", "Crypto_Exchange"],
    "Income_Credits": [
        "Payroll_Income",
        "Cashback_Statement_Credits",
        "Zelle_P2P_Received",
        "Deposit",
    ],
    "Fees_Interest": [
        "Bank_Fees",
        "Interest_Charged_Purchases",
        "Interest_Charged_Cash_Advance",
    ],
    "Credit_Card_Loan_Payments": [
        "Credit_Card_Payment",
        "Auto_Loan_Payment",
        "BNPL",
        "Installment_Loan",
    ],
    "Utilities_Recurring_Bills": ["Electric", "Insurance", "Phone_Internet"],
    "Legal_Government": ["Court_Ticket_Payments", "Tax_Payments_Refunds"],
    "Food": ["Groceries", "Dining_Restaurants", "Fast_Food", "Food_Delivery"],
    "Auto": ["Gas", "Auto_Maintenance", "Other_Auto"],
    "Travel": ["Activities", "Car_Rental", "Flights", "Hotels", "Ride_Sharing"],
    "Electronics": [
        "Accessories",
        "Computer",
        "Electronics_misc",
        "TV",
        "Tablet_Watch",
    ],
    "Entertainment": [
        "Arts_Crafts",
        "Games",
        "Guns",
        "Entertainment_Sports_Outdoors",
        "Books",
        "DateNights",
        "E_Other",
        "Movies_TV",
    ],
    "Clothes": ["Clothes_Clothes", "Bags_Accessories", "Jewelry", "Shoes"],
    "Personal_Care": [
        "Beauty",
        "Makeup_Nails",
        "PC_Other",
        "Personal_Care_Sports_Outdoors",
        "Vitamins_Supplements",
        "Hair",
        "Massage",
    ],
    "Baby": ["Baby_Clothes", "Diapers", "Formula", "Other_Baby", "Toys"],
    "Home": [
        "Decor",
        "Furniture_Appliances",
        "Home_Gym",
        "Home_Essentials",
        "Hygiene",
        "Kitchen",
        "Home_Maintenance",
        "Security",
        "Tools",
        "Yard_Garden",
    ],
    "Medical": ["Health_Wellness"],
    "Kids": ["K_Toys"],
    "Pets": ["Pet_Food", "Pet_Grooming", "Pet_Med", "Pet_Other", "Pet_Toys"],
    "Subscriptions_Memberships": [
        "Entertainment",
        "Subscriptions_Memberships_Gym",
        "Sub_Other",
    ],
    "Shopping": ["General_Merchandise"],
    "Unclassified_Miscellaneous": ["Unknown", "Other_Services"],
}

_DEFAULT_CATEGORY = "Unclassified_Miscellaneous"
_DEFAULT_SUB_CATEGORY = "Unknown"
_CONFIDENCE_THRESHOLD = 0.60

# ──────────────────────────────────────────────────────────────────────────────
# MODEL → CUSTOM TAXONOMY MAPPING
# Maps raw label strings the model may produce → (category, sub_category).
# Covers: standard finance labels, common ML label styles, and
#         the user-defined taxonomy labels themselves (identity mapping).
# ──────────────────────────────────────────────────────────────────────────────
MODEL_TO_CUSTOM_MAP: dict[str, tuple[str, str]] = {
    # ── Food ──────────────────────────────────────────────────────────────────
    "Groceries": ("Food", "Groceries"),
    "Grocery": ("Food", "Groceries"),
    "Supermarket": ("Food", "Groceries"),
    "Dining": ("Food", "Dining_Restaurants"),
    "Restaurant": ("Food", "Dining_Restaurants"),
    "Restaurants": ("Food", "Dining_Restaurants"),
    "Fast Food": ("Food", "Fast_Food"),
    "FastFood": ("Food", "Fast_Food"),
    "Food Delivery": ("Food", "Food_Delivery"),
    "FoodDelivery": ("Food", "Food_Delivery"),
    "Food": ("Food", "Dining_Restaurants"),
    # ── Shopping / Retail ─────────────────────────────────────────────────────
    "Shopping": ("Shopping", "General_Merchandise"),
    "General Merchandise": ("Shopping", "General_Merchandise"),
    "Retail": ("Shopping", "General_Merchandise"),
    "Department Store": ("Shopping", "General_Merchandise"),
    # ── Transfers ─────────────────────────────────────────────────────────────
    "Transfer": ("Transfers_Internal_Movement", "Bank_Transfer_To_Checking"),
    "Transfers": ("Transfers_Internal_Movement", "Bank_Transfer_To_Checking"),
    "Internal Transfer": ("Transfers_Internal_Movement", "Bank_Transfer_To_Checking"),
    "Bank Transfer": ("Transfers_Internal_Movement", "Bank_Transfer_To_Checking"),
    "External Transfer": ("Transfers_Internal_Movement", "External_Transfer"),
    # ── P2P / Digital Wallets ─────────────────────────────────────────────────
    "P2P": ("P2P_Digital_Wallets", "Zelle"),
    "Venmo": ("P2P_Digital_Wallets", "Venmo"),
    "Zelle": ("P2P_Digital_Wallets", "Zelle"),
    "Cash App": ("P2P_Digital_Wallets", "Cash_App"),
    "CashApp": ("P2P_Digital_Wallets", "Cash_App"),
    # ── Utilities ─────────────────────────────────────────────────────────────
    "Utilities": ("Utilities_Recurring_Bills", "Electric"),
    "Utility": ("Utilities_Recurring_Bills", "Electric"),
    "Electric": ("Utilities_Recurring_Bills", "Electric"),
    "Phone": ("Utilities_Recurring_Bills", "Phone_Internet"),
    "Internet": ("Utilities_Recurring_Bills", "Phone_Internet"),
    "Phone & Internet": ("Utilities_Recurring_Bills", "Phone_Internet"),
    "Insurance": ("Utilities_Recurring_Bills", "Insurance"),
    # ── Subscriptions ─────────────────────────────────────────────────────────
    "Subscription": ("Subscriptions_Memberships", "Sub_Other"),
    "Subscriptions": ("Subscriptions_Memberships", "Sub_Other"),
    "Membership": ("Subscriptions_Memberships", "Sub_Other"),
    "Streaming": ("Subscriptions_Memberships", "Entertainment"),
    "Entertainment": ("Entertainment", "E_Other"),
    # ── Income / Credits ──────────────────────────────────────────────────────
    "Income": ("Income_Credits", "Payroll_Income"),
    "Payroll": ("Income_Credits", "Payroll_Income"),
    "Salary": ("Income_Credits", "Payroll_Income"),
    "Deposit": ("Income_Credits", "Deposit"),
    "Credit": ("Income_Credits", "Cashback_Statement_Credits"),
    "Cashback": ("Income_Credits", "Cashback_Statement_Credits"),
    "Refund": ("Income_Credits", "Cashback_Statement_Credits"),
    # ── Fees / Interest ───────────────────────────────────────────────────────
    "Fee": ("Fees_Interest", "Bank_Fees"),
    "Fees": ("Fees_Interest", "Bank_Fees"),
    "Bank Fee": ("Fees_Interest", "Bank_Fees"),
    "Interest": ("Fees_Interest", "Interest_Charged_Purchases"),
    "Finance Charge": ("Fees_Interest", "Interest_Charged_Purchases"),
    # ── Credit Card / Loans ───────────────────────────────────────────────────
    "Credit Card Payment": ("Credit_Card_Loan_Payments", "Credit_Card_Payment"),
    "CreditCard": ("Credit_Card_Loan_Payments", "Credit_Card_Payment"),
    "Loan Payment": ("Credit_Card_Loan_Payments", "Installment_Loan"),
    "Auto Loan": ("Credit_Card_Loan_Payments", "Auto_Loan_Payment"),
    "BNPL": ("Credit_Card_Loan_Payments", "BNPL"),
    "Buy Now Pay Later": ("Credit_Card_Loan_Payments", "BNPL"),
    # ── Travel ────────────────────────────────────────────────────────────────
    "Travel": ("Travel", "Activities"),
    "Flight": ("Travel", "Flights"),
    "Flights": ("Travel", "Flights"),
    "Hotel": ("Travel", "Hotels"),
    "Hotels": ("Travel", "Hotels"),
    "Ride Share": ("Travel", "Ride_Sharing"),
    "RideShare": ("Travel", "Ride_Sharing"),
    "Rideshare": ("Travel", "Ride_Sharing"),
    "Uber": ("Travel", "Ride_Sharing"),
    "Lyft": ("Travel", "Ride_Sharing"),
    "Car Rental": ("Travel", "Car_Rental"),
    # ── Auto ──────────────────────────────────────────────────────────────────
    "Gas": ("Auto", "Gas"),
    "Fuel": ("Auto", "Gas"),
    "Automotive": ("Auto", "Other_Auto"),
    "Auto": ("Auto", "Other_Auto"),
    "Auto Maintenance": ("Auto", "Auto_Maintenance"),
    # ── Electronics ───────────────────────────────────────────────────────────
    "Electronics": ("Electronics", "Electronics_misc"),
    "Computer": ("Electronics", "Computer"),
    "TV": ("Electronics", "TV"),
    # ── Clothes ───────────────────────────────────────────────────────────────
    "Clothing": ("Clothes", "Clothes_Clothes"),
    "Clothes": ("Clothes", "Clothes_Clothes"),
    "Apparel": ("Clothes", "Clothes_Clothes"),
    "Shoes": ("Clothes", "Shoes"),
    "Jewelry": ("Clothes", "Jewelry"),
    # ── Personal Care ─────────────────────────────────────────────────────────
    "Personal Care": ("Personal_Care", "PC_Other"),
    "PersonalCare": ("Personal_Care", "PC_Other"),
    "Beauty": ("Personal_Care", "Beauty"),
    "Hair": ("Personal_Care", "Hair"),
    "Massage": ("Personal_Care", "Massage"),
    # ── Health / Medical ──────────────────────────────────────────────────────
    "Medical": ("Medical", "Health_Wellness"),
    "Health": ("Medical", "Health_Wellness"),
    "Healthcare": ("Medical", "Health_Wellness"),
    "Pharmacy": ("Medical", "Health_Wellness"),
    "Wellness": ("Medical", "Health_Wellness"),
    # ── Home ──────────────────────────────────────────────────────────────────
    "Home": ("Home", "Home_Essentials"),
    "Home Improvement": ("Home", "Home_Maintenance"),
    "Furniture": ("Home", "Furniture_Appliances"),
    "Appliances": ("Home", "Furniture_Appliances"),
    "Garden": ("Home", "Yard_Garden"),
    # ── Pets ──────────────────────────────────────────────────────────────────
    "Pet": ("Pets", "Pet_Other"),
    "Pets": ("Pets", "Pet_Other"),
    "Pet Food": ("Pets", "Pet_Food"),
    "Veterinary": ("Pets", "Pet_Med"),
    # ── Investments / Crypto ──────────────────────────────────────────────────
    "Investment": ("Investments_Crypto", "Brokerage_Investments"),
    "Investments": ("Investments_Crypto", "Brokerage_Investments"),
    "Crypto": ("Investments_Crypto", "Crypto_Exchange"),
    "Cryptocurrency": ("Investments_Crypto", "Crypto_Exchange"),
    # ── Legal / Government ────────────────────────────────────────────────────
    "Tax": ("Legal_Government", "Tax_Payments_Refunds"),
    "Government": ("Legal_Government", "Tax_Payments_Refunds"),
    "Court": ("Legal_Government", "Court_Ticket_Payments"),
    # ── Kids / Baby ───────────────────────────────────────────────────────────
    "Baby": ("Baby", "Other_Baby"),
    "Kids": ("Kids", "K_Toys"),
    # ── Catch-all ─────────────────────────────────────────────────────────────
    "Other": (_DEFAULT_CATEGORY, _DEFAULT_SUB_CATEGORY),
    "Unknown": (_DEFAULT_CATEGORY, _DEFAULT_SUB_CATEGORY),
    "Miscellaneous": (_DEFAULT_CATEGORY, "Other_Services"),
}

# Build normalised (lower-case, strip) version for case-insensitive lookup
_NORMALISED_MAP: dict[str, tuple[str, str]] = {
    k.lower().strip(): v for k, v in MODEL_TO_CUSTOM_MAP.items()
}


class TransactionCategorizer:
    """
    Thread-safe singleton that wraps the HuggingFace NLP transaction
    classification pipeline and maps its output to the local two-tier taxonomy.
    """

    _instance: Optional["TransactionCategorizer"] = None
    _lock: threading.Lock = threading.Lock()
    _pipeline_ready: bool = False

    def __new__(cls) -> "TransactionCategorizer":
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self) -> None:
        if self._pipeline_ready:
            return
        with self._lock:
            if self._pipeline_ready:
                return
            self._load_pipeline()
            self.__class__._pipeline_ready = True

    # ──────────────────────────────────────────────────────────────────────────
    # Internal helpers
    # ──────────────────────────────────────────────────────────────────────────

    def _load_pipeline(self) -> None:
        """Load the HuggingFace pipeline. Falls back to a keyword-only mode if
        the custom model architecture cannot be resolved by the local registry."""
        from transformers import pipeline as hf_pipeline

        model_id = "jonngan/distilbert-transaction-classifier"
        try:
            self._clf = hf_pipeline(
                "text-classification",
                model=model_id,
                device=-1,  # CPU-only
                top_k=1,
                trust_remote_code=True,
            )
            logger.info("TransactionCategorizer: HuggingFace pipeline loaded ✅")
            self._use_pipeline = True
        except Exception as exc:
            logger.warning(
                "TransactionCategorizer: Pipeline load failed (%s). "
                "Falling back to keyword-only mapping.",
                exc,
            )
            self._clf = None
            self._use_pipeline = False

    @staticmethod
    def _clean_narration(text: str) -> str:
        """Strip reference numbers, dates, and noisy punctuation from narration."""
        # Remove common reference/transaction ID patterns (e.g. "Ref#12345", "TXN-ABCD")
        text = re.sub(
            r"\b(ref|txn|utr|rrn|imps|neft|rtgs|upi)[#:\-]?\s*\w+",
            "",
            text,
            flags=re.IGNORECASE,
        )
        # Remove standalone numeric codes (6+ digits)
        text = re.sub(r"\b\d{6,}\b", "", text)
        # Remove dates in common formats: DD/MM/YYYY, DD-MM-YY, YYYY-MM-DD, etc.
        text = re.sub(r"\b\d{1,4}[\/\-]\d{1,2}[\/\-]\d{2,4}\b", "", text)
        # Remove email-like patterns / UPI IDs (retain only the first part)
        text = re.sub(r"[\w.\-]+@[\w.\-]+", lambda m: m.group().split("@")[0], text)
        # Remove excessive punctuation (keep alphanumeric + spaces)
        text = re.sub(r"[^\w\s\-&/]", " ", text)
        # Collapse whitespace
        text = re.sub(r"\s{2,}", " ", text).strip()
        return text

    def _map_label(self, raw_label: str) -> tuple[str, str]:
        """Map a raw model label string to (category, sub_category)."""
        # 1. Exact match
        if raw_label in MODEL_TO_CUSTOM_MAP:
            return MODEL_TO_CUSTOM_MAP[raw_label]
        # 2. Case-insensitive normalised match
        normalised = raw_label.lower().strip()
        if normalised in _NORMALISED_MAP:
            return _NORMALISED_MAP[normalised]
        # 3. Partial / substring match (first hit wins)
        for key, val in _NORMALISED_MAP.items():
            if key in normalised or normalised in key:
                return val
        # 4. Default fallback
        return (_DEFAULT_CATEGORY, _DEFAULT_SUB_CATEGORY)

    # ──────────────────────────────────────────────────────────────────────────
    # Public API
    # ──────────────────────────────────────────────────────────────────────────

    def categorize_items(self, descriptions: list[str]) -> list[dict]:
        """
        Batch-classify a list of transaction description strings.

        Args:
            descriptions: Raw narration strings from extracted transactions.

        Returns:
            A list of dicts, one per input, each containing:
              {"category": str, "sub_category": str, "confidence": float}
        """
        results: list[dict] = []

        if not descriptions:
            return results

        # Clean narrations before inference
        cleaned = [self._clean_narration(d) for d in descriptions]

        if self._use_pipeline and self._clf is not None:
            try:
                # Batch inference
                raw_outputs = self._clf(cleaned, batch_size=32, truncation=True)
                # The pipeline with top_k=1 returns list[list[dict]]
                for output in raw_outputs:
                    if isinstance(output, list):
                        hit = output[0]
                    else:
                        hit = output

                    label: str = hit.get("label", "Unknown")
                    score: float = float(hit.get("score", 0.0))

                    if score >= _CONFIDENCE_THRESHOLD:
                        category, sub_category = self._map_label(label)
                    else:
                        category, sub_category = (
                            _DEFAULT_CATEGORY,
                            _DEFAULT_SUB_CATEGORY,
                        )

                    results.append(
                        {
                            "category": category,
                            "sub_category": sub_category,
                            "confidence": score,
                        }
                    )
                return results
            except Exception as exc:
                logger.error("TransactionCategorizer inference error: %s", exc)
                # Fall through to keyword fallback

        # ── Keyword-only fallback (no pipeline available) ──────────────────
        print(
            f"TransactionCategorizer: Using keyword-only fallback for {len(cleaned)} items"
        )
        for text in cleaned:
            category, sub_category = self._keyword_fallback(text)
            results.append(
                {
                    "category": category,
                    "sub_category": sub_category,
                    "confidence": 0.0,
                }
            )
        return results

    def _keyword_fallback(self, text: str) -> tuple[str, str]:
        """Simple keyword scan used when the NLP pipeline is unavailable."""
        lower = text.lower()
        keyword_rules = [
            (
                ["salary", "payroll", "direct deposit"],
                ("Income_Credits", "Payroll_Income"),
            ),
            (
                ["refund", "cashback", "credit"],
                ("Income_Credits", "Cashback_Statement_Credits"),
            ),
            (
                [
                    "grocery",
                    "supermarket",
                    "walmart",
                    "whole foods",
                    "dmart",
                    "bigbasket",
                ],
                ("Food", "Groceries"),
            ),
            (
                ["restaurant", "dining", "cafe", "coffee", "swiggy", "zomato"],
                ("Food", "Dining_Restaurants"),
            ),
            (
                ["mcdonald", "burger", "kfc", "subway", "pizza", "fast food"],
                ("Food", "Fast_Food"),
            ),
            (
                ["transfer", "neft", "rtgs", "imps"],
                ("Transfers_Internal_Movement", "Bank_Transfer_To_Checking"),
            ),
            (["venmo"], ("P2P_Digital_Wallets", "Venmo")),
            (["zelle"], ("P2P_Digital_Wallets", "Zelle")),
            (["cash app", "cashapp"], ("P2P_Digital_Wallets", "Cash_App")),
            (["uber", "lyft", "ola", "rapido"], ("Travel", "Ride_Sharing")),
            (
                ["flight", "airline", "airfare", "indigo", "air india"],
                ("Travel", "Flights"),
            ),
            (["hotel", "airbnb", "oyo", "booking.com"], ("Travel", "Hotels")),
            (["gas", "fuel", "petrol", "pump"], ("Auto", "Gas")),
            (
                ["netflix", "spotify", "amazon prime", "subscription"],
                ("Subscriptions_Memberships", "Sub_Other"),
            ),
            (
                ["electricity", "electric", "power bill"],
                ("Utilities_Recurring_Bills", "Electric"),
            ),
            (
                ["phone", "mobile", "internet", "broadband"],
                ("Utilities_Recurring_Bills", "Phone_Internet"),
            ),
            (["insurance"], ("Utilities_Recurring_Bills", "Insurance")),
            (
                ["credit card", "card payment"],
                ("Credit_Card_Loan_Payments", "Credit_Card_Payment"),
            ),
            (["loan"], ("Credit_Card_Loan_Payments", "Installment_Loan")),
            (["fee", "bank fee", "charge"], ("Fees_Interest", "Bank_Fees")),
            (["interest"], ("Fees_Interest", "Interest_Charged_Purchases")),
            (["tax"], ("Legal_Government", "Tax_Payments_Refunds")),
            (
                ["amazon", "flipkart", "myntra", "ebay", "shopping"],
                ("Shopping", "General_Merchandise"),
            ),
            (
                ["medical", "hospital", "clinic", "doctor", "pharmacy"],
                ("Medical", "Health_Wellness"),
            ),
            (["pet food", "veterinary", "vet"], ("Pets", "Pet_Med")),
        ]
        for keywords, mapping in keyword_rules:
            if any(kw in lower for kw in keywords):
                return mapping
        return (_DEFAULT_CATEGORY, _DEFAULT_SUB_CATEGORY)


# Module-level singleton — import this in other modules
transaction_categorizer = TransactionCategorizer()
