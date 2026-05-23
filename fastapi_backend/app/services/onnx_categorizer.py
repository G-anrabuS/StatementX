import re
import numpy as np
import onnxruntime as ort
from transformers import AutoTokenizer

MODEL_PATH = "./onnx_model"

tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)

session = ort.InferenceSession(
    f"{MODEL_PATH}/model.onnx",
    providers=["CPUExecutionProvider"],
)

LABEL_MAP = {
    0: ("Charity & Donations", "Donations"),
    1: ("Entertainment & Recreation", "Entertainment"),
    2: ("Financial Services", "Banking"),
    3: ("Food & Dining", "Restaurants"),
    4: ("Government & Legal", "Government"),
    5: ("Healthcare & Medical", "Medical"),
    6: ("Income", "Salary"),
    7: ("Shopping & Retail", "Retail"),
    8: ("Transportation", "Transport"),
    9: ("Utilities & Services", "Utilities"),
}

RULES = {
    "zomato": ("Food & Dining", "Restaurants"),
    "swiggy": ("Food & Dining", "Restaurants"),
    "barbeque": ("Food & Dining", "Restaurants"),
    "restaurant": ("Food & Dining", "Restaurants"),
    "cafe": ("Food & Dining", "Cafe"),
    "bakery": ("Food & Dining", "Bakery"),
    "amazon": ("Shopping & Retail", "Retail"),
    "flipkart": ("Shopping & Retail", "Retail"),
    "nykaa": ("Shopping & Retail", "Beauty"),
    "h&m": ("Shopping & Retail", "Fashion"),
    "hm": ("Shopping & Retail", "Fashion"),
    "reliance fresh": ("Shopping & Retail", "Groceries"),
    "uber": ("Transportation", "Taxi"),
    "ola": ("Transportation", "Taxi"),
    "metro": ("Transportation", "Public Transit"),
    "petrol": ("Transportation", "Fuel"),
    "indian oil": ("Transportation", "Fuel"),
    "indane": ("Transportation", "Fuel"),
    "gas": ("Transportation", "Fuel"),
    "apollo pharmacy": ("Healthcare & Medical", "Pharmacy"),
    "fortis": ("Healthcare & Medical", "Hospital"),
    "pathlabs": ("Healthcare & Medical", "Diagnostics"),
    "hospital": ("Healthcare & Medical", "Hospital"),
    "pharmacy": ("Healthcare & Medical", "Pharmacy"),
    "netflix": ("Entertainment & Recreation", "Streaming"),
    "steam": ("Entertainment & Recreation", "Gaming"),
    "pvr": ("Entertainment & Recreation", "Movies"),
    "cinema": ("Entertainment & Recreation", "Movies"),
    "salary": ("Income", "Salary"),
    "payroll": ("Income", "Salary"),
    "upwork": ("Income", "Freelance"),
    "freelance": ("Income", "Freelance"),
    "rent": ("Financial Services", "Rent"),
    "emi": ("Financial Services", "Loan EMI"),
    "loan": ("Financial Services", "Loan"),
    "sip": ("Financial Services", "Investment"),
    "mutual fund": ("Financial Services", "Investment"),
    "transfer": ("Financial Services", "Transfer"),
    "neft": ("Financial Services", "Transfer"),
    "upi": ("Financial Services", "Transfer"),
    "electric": ("Utilities & Services", "Electricity"),
    "wbsedcl": ("Utilities & Services", "Electricity"),
    "water": ("Utilities & Services", "Water"),
    "municipal": ("Utilities & Services", "Water"),
    "airtel": ("Utilities & Services", "Telecom"),
    "jio": ("Utilities & Services", "Internet"),
    "fiber": ("Utilities & Services", "Internet"),
    "recharge": ("Utilities & Services", "Recharge"),
}


def normalize(text: str) -> str:
    text = text.lower()
    text = re.sub(r"\d+", "", text)
    text = re.sub(r"[^\w\s]", " ", text)
    return re.sub(r"\s+", " ", text).strip()


def softmax(x):
    exp = np.exp(x - np.max(x))
    return exp / exp.sum(axis=-1, keepdims=True)


def categorize_items(descriptions):
    results = []

    for desc in descriptions:
        cleaned = normalize(desc)

        rule_hit = False

        for keyword, mapping in RULES.items():
            if keyword in cleaned:
                results.append(
                    {
                        "category": mapping[0],
                        "sub_category": mapping[1],
                        "confidence": 1.0,
                        "source": "rule",
                    }
                )
                rule_hit = True
                break

        if rule_hit:
            continue

        inputs = tokenizer(
            cleaned,
            return_tensors="np",
            truncation=True,
            padding=True,
            max_length=128,
        )

        outputs = session.run(
            None,
            {
                "input_ids": inputs["input_ids"].astype(np.int64),
                "attention_mask": inputs["attention_mask"].astype(np.int64),
            },
        )

        logits = outputs[0]
        probs = softmax(logits)

        pred_idx = int(np.argmax(probs))
        confidence = float(np.max(probs))

        if confidence < 0.60:
            results.append(
                {
                    "category": "Unclassified_Miscellaneous",
                    "sub_category": "Unknown",
                    "confidence": confidence,
                }
            )
            continue

        category, sub = LABEL_MAP.get(
            pred_idx,
            ("Unclassified_Miscellaneous", "Unknown"),
        )

        results.append(
            {
                "category": category,
                "sub_category": sub,
                "confidence": confidence,
                "source": "model",
            }
        )

    return results
