from transformers import pipeline
import re


class TransactionCategorizer:
    _instance = None

    CUSTOM_LABELS = [
        "Food",
        "Shopping",
        "Travel",
        "Utilities",
        "Income",
        "Transfer",
        "Entertainment",
        "Medical",
        "Subscriptions",
        "Auto",
    ]

    LABEL_MAP = {
        "Food": ("Food", "Dining_Restaurants"),
        "Shopping": ("Shopping", "General_Merchandise"),
        "Travel": ("Travel", "Ride_Sharing"),
        "Utilities": ("Utilities_Recurring_Bills", "Electric"),
        "Income": ("Income_Credits", "Payroll_Income"),
        "Transfer": ("Transfers_Internal_Movement", "External_Transfer"),
        "Entertainment": ("Entertainment", "Movies_TV"),
        "Medical": ("Medical", "Health_Wellness"),
        "Subscriptions": ("Subscriptions_Memberships", "Entertainment"),
        "Auto": ("Auto", "Gas"),
    }

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)

            cls._instance.classifier = pipeline(
                "zero-shot-classification",
                model="MoritzLaurer/deberta-v3-base-zeroshot-v1",
                device=-1,
            )

        return cls._instance

    def _clean_narration(self, text):
        text = re.sub(r"\d+", " ", text)
        text = re.sub(r"[^\w\s]", " ", text)
        return re.sub(r"\s+", " ", text).strip()

    def categorize_items(self, descriptions):
        results = []

        for desc in descriptions:
            pred = self.classifier(
                self._clean_narration(desc),
                self.CUSTOM_LABELS,
            )

            label = pred["labels"][0]
            score = pred["scores"][0]

            if score < 0.60:
                results.append(
                    {
                        "category": "Unclassified_Miscellaneous",
                        "sub_category": "Unknown",
                        "confidence": score,
                    }
                )
                continue

            category, sub = self.LABEL_MAP[label]

            results.append(
                {
                    "category": category,
                    "sub_category": sub,
                    "confidence": score,
                }
            )

        return results
