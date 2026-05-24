import io
import traceback
import requests

BASE_URL = "http://127.0.0.1:8000"

def run_test():
    print("==================================================")
    print("=== StatementX E2E REAL-TIME HTTP CLIENT TEST  ===")
    print("==================================================")
    
    # 1. GET Root Endpoint
    print("\n1. Testing GET / ...")
    try:
        res = requests.get(f"{BASE_URL}/")
        print(f"Status Code: {res.status_code}")
        print(f"Response: {res.json()}")
    except Exception as e:
        print("[FAIL] GET / crashed:")
        traceback.print_exc()
        return
    
    # 2. POST CSV Statement Extraction
    print("\n2. Testing POST /api/statements/extract with mock CSV ledger...")
    csv_data = (
        "Date,Particulars,Debit,Credit,Balance\n"
        "01/05/2026,UPI/SALARY/PAYROLL/CR,,50000.0,50000.0\n"
        "02/05/2026,TRANSFER/RENT PAYMENT/DR,15000.0,,35000.0\n"
        "03/05/2026,UPI/ZOMATO/FOOD,850.0,,34150.0\n"
        "03/05/2026,UPI/ZOMATO/FOOD,850.0,,33300.0\n"
        "10/04/2026,UPI/NETFLIX/STREAMING,199.0,,33101.0\n"
        "10/05/2026,UPI/NETFLIX/STREAMING,199.0,,32902.0\n"
        "15/05/2026,UPI/IMPS/LATE TRANSFER AT 02:45AM/DR,30000.0,,2902.0\n"
    )
    
    file_payload = {
        "file": ("test_statement_upload.csv", io.BytesIO(csv_data.encode("utf-8")), "text/csv")
    }
    
    try:
        res = requests.post(f"{BASE_URL}/api/statements/extract", files=file_payload)
        print(f"Status Code: {res.status_code}")
        if res.status_code != 200:
            print(f"[FAIL] POST /extract failed. Body: {res.text}")
            return
        
        extracted = res.json()
        statement_id = extracted.get("statement_id")
        print(f"[SUCCESS] Extracted statement! ID: {statement_id} | Bank: {extracted.get('bank_name')}")
        print(f"Total Transactions Indexed: {extracted.get('total_transactions')}")
    except Exception as e:
        print("[FAIL] POST /extract crashed:")
        traceback.print_exc()
        return

    # 3. GET Insights Endpoint
    print(f"\n3. Testing GET /api/statements/{statement_id}/insights ...")
    try:
        res = requests.get(f"{BASE_URL}/api/statements/{statement_id}/insights")
        print(f"Status Code: {res.status_code}")
        if res.status_code != 200:
            print(f"[FAIL] GET /insights failed. Body: {res.text}")
            return
        
        insights = res.json()
        print("\n=== FINANCIAL INSIGHTS METRICS ===")
        print(f"Income:  INR {insights.get('total_income')}")
        print(f"Expense: INR {insights.get('total_expense')}")
        print(f"Savings: INR {insights.get('net_savings')} ({insights.get('saving_rate')}%)")
        print(f"Top Category: {insights.get('highest_spending_category')}")
        
        print("\n=== DETECTED ANOMALIES ===")
        for a in insights.get('anomalies', []):
            print(f"- [{a.get('type')}] {a.get('date')}: INR {a.get('amount')} - {a.get('reason')}")
            
        print("\n=== DETECTED SUBSCRIPTIONS ===")
        for s in insights.get('subscriptions', []):
            print(f"- {s.get('vendor')}: INR {s.get('average_amount')} ({s.get('frequency')})")

        print("\n=== AI SUMMARY ===")
        print(insights.get("ai_summary", "").replace("₹", "INR"))
    except Exception as e:
        print("[FAIL] GET /insights crashed:")
        traceback.print_exc()
        return

    # 4. GET AI Coach Endpoint
    print(f"\n4. Testing GET /api/statements/{statement_id}/ai-coach ...")
    try:
        res = requests.get(f"{BASE_URL}/api/statements/{statement_id}/ai-coach")
        print(f"Status Code: {res.status_code}")
        if res.status_code != 200:
            print(f"[FAIL] GET /ai-coach failed. Body: {res.text}")
            return
        
        coach = res.json()
        print("\n=== AI RECOMMENDED ACTIONS ===")
        for r in coach.get("recommendations", []):
            print(f"- [{r.get('impact')} impact on {r.get('target_category')}] {r.get('title')}: {r.get('description')}")
            print(f"  Action item: {r.get('action_item')}")
    except Exception as e:
        print("[FAIL] GET /ai-coach crashed:")
        traceback.print_exc()
        return

    # 5. POST Chat Endpoint
    print(f"\n5. Testing POST /api/statements/{statement_id}/chat ...")
    try:
        chat_payload = {
            "message": "Do I have any Netflix streaming commitments?",
            "chat_history": []
        }
        res = requests.post(f"{BASE_URL}/api/statements/{statement_id}/chat", json=chat_payload)
        print(f"Status Code: {res.status_code}")
        if res.status_code != 200:
            print(f"[FAIL] POST /chat failed. Body: {res.text}")
            return
        
        chat = res.json()
        print("\n=== CHAT BOT REPLY ===")
        print(chat.get("response", "").replace("₹", "INR"))
        print("\n=== SEMANTIC SEARCH SOURCES ===")
        for s in chat.get("sources", []):
            print(f"- [{s.get('date')}] {s.get('description')} (Similarity Match Score: {s.get('similarity')})")
    except Exception as e:
        print("[FAIL] POST /chat crashed:")
        traceback.print_exc()
        return

    # 6. GET Visualization Endpoint
    print(f"\n6. Testing GET /api/statements/{statement_id}/visualization ...")
    try:
        res = requests.get(f"{BASE_URL}/api/statements/{statement_id}/visualization")
        print(f"Status Code: {res.status_code}")
        if res.status_code != 200:
            print(f"[FAIL] GET /visualization failed. Body: {res.text}")
            return
        
        vis = res.json()
        print("\n=== FINANCIAL HEALTH INDICATORS ===")
        hi = vis.get("health_indicators", {})
        print(f"Health Score:          {hi.get('health_score')}/100 ({hi.get('health_rating')})")
        print(f"Savings Rate:          {hi.get('savings_rate')}%")
        print(f"Burn Rate:             {hi.get('burn_rate')}%")
        print(f"Discretionary Ratio:   {hi.get('discretionary_spend_ratio')}%")
        print(f"Essential Ratio:       {hi.get('essential_spend_ratio')}%")
        print(f"Liquidity Coverage:    {hi.get('liquidity_ratio')} months")
        print(f"Avg Daily Expense:     INR {hi.get('average_daily_expense')}")
        print(f"Savings Consistency:   {hi.get('savings_consistency')}%")

        print("\n=== 50/30/20 BUDGET ANALYSIS ===")
        ba = vis.get("budget_allocation", {})
        print(f"Needs:                 INR {ba.get('needs_amount')} ({ba.get('needs_percentage')}%) vs Target: {ba.get('needs_target_percentage')}%")
        print(f"Wants:                 INR {ba.get('wants_amount')} ({ba.get('wants_percentage')}%) vs Target: {ba.get('wants_target_percentage')}%")
        print(f"Savings/Surplus:       INR {ba.get('savings_amount')} ({ba.get('savings_percentage')}%) vs Target: {ba.get('savings_target_percentage')}%")

        print("\n=== CASH FLOW TIMELINE (DAILY TRENDS) ===")
        timeline = vis.get("cash_flow_timeline", [])
        for pt in timeline[:3]:
            print(f"- {pt.get('date')}: Cumulative Income: INR {pt.get('cumulative_income')} | Cumulative Expense: INR {pt.get('cumulative_expense')} | Balance: INR {pt.get('balance')}")
        if len(timeline) > 3:
            print(f"... and {len(timeline) - 3} more days")

        print("\n=== CATEGORY VISUAL METADATA ===")
        for item in vis.get("category_breakdown", []):
            print(f"- {item.get('category')}: INR {item.get('amount')} ({item.get('percentage')}%) | Color Token: {item.get('color')} | {item.get('transaction_count')} txns")

        print("\n=== SPENDING ACTIVITY PATTERNS ===")
        sp = vis.get("spending_pattern", {})
        print(f"Weekday Spent:         INR {sp.get('weekday_total')} (Avg: INR {sp.get('weekday_average')} across {sp.get('weekday_count')} txns)")
        print(f"Weekend Spent:         INR {sp.get('weekend_total')} (Avg: INR {sp.get('weekend_average')} across {sp.get('weekend_count')} txns)")

    except Exception as e:
        print("[FAIL] GET /visualization crashed:")
        traceback.print_exc()
        return

    # 7. GET PDF Export Endpoint
    print(f"\n7. Testing GET /api/statements/{statement_id}/export-pdf ...")
    try:
        res = requests.get(f"{BASE_URL}/api/statements/{statement_id}/export-pdf")
        print(f"Status Code: {res.status_code}")
        if res.status_code != 200:
            print(f"[FAIL] GET /export-pdf failed. Body: {res.text}")
            return
        
        # Save the PDF file to workspace to allow user visual review
        pdf_path = "test_financial_report.pdf"
        with open(pdf_path, "wb") as f:
            f.write(res.content)
            
        print(f"[SUCCESS] Downloaded PDF Report successfully! Size: {len(res.content)} bytes.")
        print(f"Report saved locally as: {pdf_path}")
        
        print("\n==================================================")
        print("=== [SUCCESS] E2E INTEGRATION TEST COMPLETED!  ===")
        print("==================================================")
    except Exception as e:
        print("[FAIL] GET /export-pdf crashed:")
        traceback.print_exc()

if __name__ == "__main__":
    run_test()
