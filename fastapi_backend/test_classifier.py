import sys
import os

# Ensure the app directory is in the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from app.services.categorizer import transaction_categorizer
    print("[INFO] NLP Transaction Classifier loaded successfully.\n")

    # Sample transaction descriptions (mix of UPI, merchant names, salaries, etc.)
    sample_descriptions = [
        "UPI-SWIGGY-RESTAURANT-BANGALORE-291039",
        "SALARY FOR THE MONTH OF MAY 2026",
        "REFUND FROM AMAZON IN-PAY-30129",
        "NEFT TRANSFER FROM SAVINGS AC TO CHECKING",
        "ZELLE TRANSFER FROM JOHN DOE",
        "INTERNET BILL CHARGES AIRTEL BROADBAND",
        "AUTOMOTIVE GAS PUMP INDIAN OIL CORP",
        "MONTHLY NETFLIX ENTERTAINMENT SUBSCRIPTION",
        "HDFC CREDIT CARD PAYMENT RECEIVED",
        "APOLLO PHARMACY MEDICAL STORE",
        "PET SUPPLIES STORE DOG FOOD",
        "MCDONALDS BURGER KING FAST FOOD OUTLET"
    ]

    print(f"Testing local classification on {len(sample_descriptions)} sample transactions...\n")
    print(f"{'Raw Description':<45} | {'Mapped Category':<30} | {'Sub-Category':<25} | {'Conf'}")
    print("-" * 115)

    results = transaction_categorizer.categorize_items(sample_descriptions)

    for desc, res in zip(sample_descriptions, results):
        print(f"{desc:<45} | {res['category']:<30} | {res['sub_category']:<25} | {res['confidence']:.2f}")

    print("\n[SUCCESS] Local NLP classification engine test completed successfully!")

except Exception as e:
    print(f"[ERROR] Error testing classifier: {str(e)}")
