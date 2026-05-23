import logging
import asyncio
from typing import List, Dict, Tuple
from sqlalchemy.orm import Session

from google import genai
from google.genai import types

from app.core.config import settings
from app.models.statement import Statement
from app.models.transaction import Transaction
from app.schemas.insights import (
    AIRecommendationItem,
    AICoachResponse,
    FinancialThesisResponse,
)

logger = logging.getLogger(__name__)


class AICoachService:
    @staticmethod
    async def get_or_generate_coach_insights(
        db: Session,
        statement_id: str,
        debit_transactions: List[Transaction],
        total_income: float,
        total_expense: float,
        net_savings: float,
        saving_rate: float,
        highest_spending_category: str,
        category_breakdown: Dict[str, float],
        subscriptions: list,
        anomalies: list
    ) -> Tuple[str, List[AIRecommendationItem]]:
        """
        Retrieves cached AI insights from the database, or generates an extensive set
        of static financial recommendations and summaries in Python, optionally using
        the Gemini API to refine the tone while keeping a 100% resilient static fallback.
        """
        ai_summary = None
        ai_recommendations = []

        # 1. Check Database Caching and Vector Thesis Chunks
        statement = db.query(Statement).filter(Statement.statement_id == statement_id).first()
        
        from app.models.statement import StatementThesisChunk
        existing_chunks = 0
        if statement:
            existing_chunks = db.query(StatementThesisChunk).filter(StatementThesisChunk.statement_id == statement_id).count()

        if statement and isinstance(statement.raw_ai_output, dict):
            cached_insights = statement.raw_ai_output.get("ai_insights")
            if cached_insights and isinstance(cached_insights, dict):
                ai_summary = cached_insights.get("summary")
                cached_recs = cached_insights.get("recommendations", [])
                try:
                    ai_recommendations = [AIRecommendationItem(**rec) for rec in cached_recs]
                except Exception as parse_err:
                    logger.error(f"Failed to parse cached recommendations: {parse_err}")
                    ai_recommendations = []

        # Return early ONLY if both AI insights summary AND vector thesis chunks are cached/present
        if ai_summary and existing_chunks > 0:
            return ai_summary, ai_recommendations

        # 2. RUN STATIC FINANCIAL RULES ENGINE AND LLM REFINEMENT IF NOT CACHED
        if not ai_summary:
            # 2a. Multi-Type Static Summary Generation
            cf_summary = f"Your total income for this statement period was INR {total_income:.2f}, while total expenses stood at INR {total_expense:.2f}, resulting in a net cash flow of INR {net_savings:.2f}."
            
            if saving_rate <= 0:
                sv_summary = f"Your savings rate is in a critical deficit (-{abs(saving_rate):.2f}%). You are currently living beyond your income, which requires immediate corrective budget cuts."
            elif saving_rate < 10:
                sv_summary = f"Your savings rate is low ({saving_rate:.2f}%). Wealth advisors recommend maintaining a savings rate of at least 20% to secure long-term financial health and compound interest opportunities."
            elif saving_rate < 30:
                sv_summary = f"Your savings rate is healthy ({saving_rate:.2f}%). You are demonstrating disciplined saving habits and building cash reserves successfully."
            else:
                sv_summary = f"Your savings rate is exceptional ({saving_rate:.2f}%). This represents a highly efficient cash flow layout, allowing you to maximize investment velocities."

            cc_summary = ""
            if highest_spending_category != "None" and highest_spending_category != "Unclassified_Miscellaneous":
                highest_amount = category_breakdown.get(highest_spending_category, 0)
                pct_of_expense = (highest_amount / total_expense * 100) if total_expense > 0 else 0
                cc_summary = f"Your primary spending concentrated under '{highest_spending_category}', representing {pct_of_expense:.1f}% of your total outflow (INR {highest_amount:.2f})."

            sub_summary = ""
            if subscriptions:
                sub_total = sum(sub.average_amount for sub in subscriptions)
                sub_pct = (sub_total / total_income * 100) if total_income > 0 else 0
                sub_summary = f"We detected {len(subscriptions)} recurring subscription streams draining a total of INR {sub_total:.2f} periodically ({sub_pct:.1f}% of your monthly income)."

            anom_summary = ""
            if anomalies:
                anom_summary = f"Security scans flagged {len(anomalies)} transaction anomalies (including duplicate charges, outliers, or late-night activities) that require immediate review."

            # Compile rich segmented static summary
            static_summary = f"### Cash Flow Dynamics\n{cf_summary}\n\n### Savings Velocity & Health\n{sv_summary}"
            if cc_summary:
                static_summary += f"\n\n### Expense Concentration\n{cc_summary}"
            if sub_summary:
                static_summary += f"\n\n### Recurring Commitments\n{sub_summary}"
            if anom_summary:
                static_summary += f"\n\n### Security & Operational Risk\n{anom_summary}"

            # 2b. Multi-Type Static Recommendations Generation
            static_recommendations: List[AIRecommendationItem] = []

            # Rec Type 1: Category Budgeting Cap
            if highest_spending_category != "None" and highest_spending_category != "Unclassified_Miscellaneous":
                highest_amount = category_breakdown.get(highest_spending_category, 0)
                target_cut = highest_amount * 0.15
                impact = "High" if highest_amount > total_expense * 0.25 else "Medium"
                static_recommendations.append(AIRecommendationItem(
                    title=f"Set spending cap on {highest_spending_category}",
                    description=f"You spent INR {highest_amount:.2f} on '{highest_spending_category}'. Setting a 15% reduction goal would yield INR {target_cut:.2f} in immediate savings.",
                    impact=impact,
                    action_item=f"Limit next month's spending in '{highest_spending_category}' to INR {highest_amount * 0.85:.2f}.",
                    target_category=highest_spending_category
                ))

            # Rec Type 2: Subscriptions Cleanup Audit
            for sub in subscriptions:
                impact = "Medium" if sub.average_amount > 500 else "Low"
                static_recommendations.append(AIRecommendationItem(
                    title=f"Audit {sub.vendor} subscription validity",
                    description=f"We detected a recurring {sub.frequency} billing of INR {sub.average_amount:.2f} from {sub.vendor}. If this subscription is underutilized, canceling it will permanently stop this cash drain.",
                    impact=impact,
                    action_item=f"Verify if you used {sub.vendor} in the last 30 days. If not, cancel the subscription today.",
                    target_category="Entertainment & Recreation" if "netflix" in sub.vendor.lower() or "steam" in sub.vendor.lower() else "Utilities & Services"
                ))

            # Rec Type 3: Security & Anomaly Audit Action
            for anom in anomalies:
                impact = "High" if anom.type == "high_value" or anom.type == "duplicate" and anom.amount > 1000 else "Medium"
                static_recommendations.append(AIRecommendationItem(
                    title=f"Resolve flagged {anom.type.replace('_', ' ')} anomaly",
                    description=f"A transaction on {anom.date} for INR {anom.amount:.2f} ('{anom.narration}') was flagged due to: {anom.reason}.",
                    impact=impact,
                    action_item=f"Verify the validity of this transaction. If duplicate or unauthorized, contact your bank or the vendor to file a dispute.",
                    target_category="Financial Services"
                ))

            # Rec Type 4: Emergency Fund Planning
            monthly_burn = total_expense
            if monthly_burn > 0:
                three_month_target = monthly_burn * 3
                impact = "High" if saving_rate < 15 else "Medium"
                static_recommendations.append(AIRecommendationItem(
                    title="Establish 3-Month Emergency Reserve",
                    description=f"Based on your current monthly outflow of INR {monthly_burn:.2f}, wealth advisors recommend securing a highly-liquid emergency cache of INR {three_month_target:.2f} to cover unexpected expenses.",
                    impact=impact,
                    action_item=f"Open a separate high-yield savings account or liquid fund and automate a monthly transfer to build towards the target.",
                    target_category="Financial Services"
                ))

            # Rec Type 5: Savings Benchmark Target
            if saving_rate < 20:
                target_savings = total_income * 0.20
                shortfall = target_savings - net_savings
                static_recommendations.append(AIRecommendationItem(
                    title="Accelerate Savings to 20% benchmark",
                    description=f"Your current savings rate of {saving_rate:.2f}% falls short of the standard 20% financial wellness benchmark (INR {target_savings:.2f}). You need to identify a savings acceleration of INR {shortfall:.2f} monthly.",
                    impact="High",
                    action_item=f"Implement a 50/30/20 budget framework: allocate 50% to needs, 30% to wants, and instantly save the remaining 20% upon income deposit.",
                    target_category="Financial Services"
                ))

            # 3. ATTEMPT LLM REFINEMENT (GEMINI AS DYNAMIC OVERLAY & FALLBACK ENGINE)
            ai_summary = static_summary
            ai_recommendations = static_recommendations

            if settings.GEMINI_API_KEY:
                try:
                    # Sort debit transactions by value descending and pull top 10
                    debit_transactions_sorted = sorted(debit_transactions, key=lambda t: float(t.debit), reverse=True)
                    top_debits = debit_transactions_sorted[:10]
                    top_expenses_text = "\n".join([
                        f"- {t.date.strftime('%d/%m/%Y')} | {t.raw_description} | Amount: INR {float(t.debit):.2f} | Category: {t.category or 'Others'}"
                        for t in top_debits
                    ])

                    prompt = f"""
                    You are an expert AI financial coach and wealth advisor.
                    Analyze the following financial summary, recurring subscriptions, anomalies, top expenditures, and statically compiled outlines:

                    ### Financial Metrics
                    - Bank Name: {statement.bank_name if statement else "Unknown Bank"}
                    - Total Income: INR {total_income:.2f}
                    - Total Expense: INR {total_expense:.2f}
                    - Net Savings: INR {net_savings:.2f}
                    - Saving Rate: {saving_rate:.2f}%
                    - Highest Spending Category: {highest_spending_category}
                    - Spending by Category: {dict(category_breakdown)}

                    ### Top Expenditures
                    {top_expenses_text}

                    ### Statically Compiled Summary Draft
                    {static_summary}

                    ### Statically Compiled Recommendations Draft
                    {[rec.model_dump() for rec in static_recommendations]}

                    Provide:
                    1. A refined, narrative, and engaging financial coach summary. It must structure the overview into clear sections: '### Cash Flow Dynamics', '### Savings Velocity & Health', and '### Fixed Commitments & Security'. Embellish the text to sound empathetic, data-driven, and supportive.
                    2. Refined recommendations mapping all statically compiled drafts. Enhance their titles, descriptions, and action items to sound highly customized, precise, and professional.

                    Ensure numbers are formatted clearly and recommendations are highly actionable.
                    """

                    client = genai.Client(api_key=settings.GEMINI_API_KEY)
                    loop = asyncio.get_running_loop()
                    response = await loop.run_in_executor(
                        None,
                        lambda: client.models.generate_content(
                            model="gemini-2.5-flash",
                            contents=prompt,
                            config=types.GenerateContentConfig(
                                response_mime_type="application/json",
                                response_schema=AICoachResponse,
                                temperature=0.2,
                            )
                        )
                    )

                    coach_data = AICoachResponse.model_validate_json(response.text)
                    ai_summary = coach_data.summary
                    ai_recommendations = coach_data.recommendations

                except Exception as e:
                    logger.error(f"Gemini AI coach refinement failed (using static fallback): {e}")
                    # Rollback to statically generated metrics (100% resilient fallback)
                    ai_summary = static_summary
                    ai_recommendations = static_recommendations

            # 4. Cache final generated insights in the database
            if statement and ai_summary and ai_recommendations:
                try:
                    recs_dicts = [rec.model_dump() for rec in ai_recommendations]
                    statement.raw_ai_output = {
                        **statement.raw_ai_output,
                        "ai_insights": {
                            "summary": ai_summary,
                            "recommendations": recs_dicts
                        }
                    }
                    db.commit()
                except Exception as commit_err:
                    logger.error(f"Failed to cache AI insights in database: {commit_err}")
                    db.rollback()

        # 5. GENERATE COMPREHENSIVE FINANCIAL THESIS IF VECTOR CHUNKS ARE MISSING
        if statement and existing_chunks == 0 and settings.GEMINI_API_KEY:
            try:
                logger.info(f"Generating comprehensive financial thesis for statement {statement_id}...")
                
                # Fetch ALL transactions to get the complete extract endpoint data
                all_txns = (
                    db.query(Transaction)
                    .filter(Transaction.statement_id == statement_id)
                    .order_by(Transaction.date.asc())
                    .all()
                )
                
                # 1. Format raw extracted transactions list (Extract Endpoint Data)
                txns_list_text = []
                for idx, t in enumerate(all_txns, 1):
                    debit_str = f"Debit: INR {float(t.debit):.2f}" if float(t.debit) > 0 else "Debit: 0.00"
                    credit_str = f"Credit: INR {float(t.credit):.2f}" if float(t.credit) > 0 else "Credit: 0.00"
                    txns_list_text.append(
                        f"{idx}. Date: {t.date.strftime('%d/%m/%Y')} | Narration: {t.raw_description} | "
                        f"{debit_str} | {credit_str} | Balance: INR {float(t.balance):.2f} | "
                        f"Category: {t.category or 'Unclassified'} | Sub-Category: {t.sub_category or 'None'} | "
                        f"Confidence: {t.confidence or 0.0}"
                    )
                all_txns_text = "\n".join(txns_list_text)
                
                # 2. Format computed insights (Insights Endpoint Data)
                category_breakdown_text = "\n".join([f"- {cat}: INR {amt:.2f}" for cat, amt in category_breakdown.items()])
                
                subscriptions_text = "None"
                if subscriptions:
                    subscriptions_text = "\n".join([
                        f"- Vendor: {sub.vendor} | Avg Amount: INR {sub.average_amount:.2f} | Frequency: {sub.frequency} | Last Date: {sub.last_transaction_date}"
                        for sub in subscriptions
                    ])
                    
                anomalies_text = "None"
                if anomalies:
                    anomalies_text = "\n".join([
                        f"- [{anom.type}] {anom.date} | Amount: INR {anom.amount:.2f} | Narration: {anom.narration} | Reason: {anom.reason}"
                        for anom in anomalies
                    ])

                # 3. Format AI Coach Summary and Recommendations (AI-Coach / Insights Endpoint Data)
                recs_list_text = []
                for idx, rec in enumerate(ai_recommendations, 1):
                    recs_list_text.append(
                        f"{idx}. Title: {rec.title}\n"
                        f"   Description: {rec.description}\n"
                        f"   Impact: {rec.impact} | Target Category: {rec.target_category}\n"
                        f"   Action Item: {rec.action_item}"
                    )
                recommendations_text = "\n\n".join(recs_list_text)

                thesis_prompt = f"""
                You are an elite senior wealth strategist, forensic accountant, and expert financial advisor.
                Write an exhaustive, extremely detailed, and highly descriptive financial analysis thesis for a user based on their COMPLETE bank statement transaction logs and analyzed insights.
                
                This thesis will be stored in a Vector DB and retrieved via semantic search to answer the user's chatbot queries. Therefore, it must be incredibly thorough, explicit, analytical, and highly structured, containing maximum context, specific examples, patterns, and concrete guidance.
                
                The thesis MUST consist of exactly 5 sections:
                1. Cash Flow Dynamics (In-depth analysis of overall cash flow, liquidity health, income streams, deposit stability, and daily balances)
                2. Savings Strategy (Thorough review of savings rates, wealth building speed, long-term projections, compounding opportunities, and investment advice)
                3. Fixed Commitments (Detailed audit of recurring subscriptions, utility drains, fixed monthly costs, unnecessary services, and optimization plans)
                4. Security Risk Audit (Forensic review of flagged anomalies, potential duplicate charges, high-value outliers, late-night payments, and risk prevention advice)
                5. Tactical Roadmap (A concrete 30-60-90 day tactical financial blueprint, precise category budget allocations, wealth building steps, and specific habits to build)

                ### TECHNICAL RULES FOR WRITING:
                - Make each section extremely comprehensive, highly analytical, and descriptive (minimum 350-400 words per section).
                - Ground the analysis deeply in the user's ACTUAL transaction history. Reference specific dates, vendors, transaction counts, and exact cash values.
                - Format all money figures in INR (use '₹' or 'INR').
                
                ========================================
                SOURCE DATA A: COMPLETE TRANSACTION LEDGER (Extract Endpoint Output)
                ========================================
                {all_txns_text}
                
                ========================================
                SOURCE DATA B: COMPUTED AGGREGATES & INSIGHTS (Insights Endpoint Output)
                ========================================
                - Total Income (Deposits): INR {total_income:.2f}
                - Total Expense (Withdrawals): INR {total_expense:.2f}
                - Net Savings: INR {net_savings:.2f}
                - Saving Rate: {saving_rate:.2f}%
                - Highest Spending Category: {highest_spending_category}
                
                - Category Spending Breakdown:
                {category_breakdown_text}
                
                - Detected Recurring Subscriptions:
                {subscriptions_text}
                
                - Flagged Transaction Anomalies:
                {anomalies_text}
                
                ========================================
                SOURCE DATA C: AI FINANCIAL COACH PREVIEW & ACTIONS
                ========================================
                Preview Summary:
                {ai_summary}
                
                Compiled Recommendation Action Items:
                {recommendations_text}
                """

                client = genai.Client(api_key=settings.GEMINI_API_KEY)
                loop = asyncio.get_running_loop()
                thesis_res = await loop.run_in_executor(
                    None,
                    lambda: client.models.generate_content(
                        model="gemini-2.5-flash",
                        contents=thesis_prompt,
                        config=types.GenerateContentConfig(
                            response_mime_type="application/json",
                            response_schema=FinancialThesisResponse,
                            temperature=0.3,
                        )
                    )
                )

                thesis_data = FinancialThesisResponse.model_validate_json(thesis_res.text)
                sections_texts = [sec.content for sec in thesis_data.sections]

                # Try embedding chunks, fall back to None if API fails
                embeddings_list = [None] * len(thesis_data.sections)
                try:
                    embed_res = await loop.run_in_executor(
                        None,
                        lambda: client.models.embed_content(
                            model="text-embedding-004",
                            contents=sections_texts
                        )
                    )
                    embeddings_list = [emb.values for emb in embed_res.embeddings]
                except Exception as emb_err:
                    logger.warning(f"Failed to embed thesis sections (will fallback to fuzzy local search): {emb_err}")

                for sec, emb_val in zip(thesis_data.sections, embeddings_list):
                    db.add(StatementThesisChunk(
                        statement_id=statement.statement_id,
                        section_title=sec.title,
                        content=sec.content,
                        embedding=emb_val
                    ))
                db.commit()
                logger.info(f"[SUCCESS] Financial thesis generated and indexed into vector DB for statement {statement_id}!")
            except Exception as thesis_err:
                logger.error(f"Failed to generate and cache financial thesis: {thesis_err}")
                db.rollback()

        return ai_summary, ai_recommendations
