import re
import difflib
import logging
import asyncio
import numpy as np
from typing import List, Dict, Tuple
from sqlalchemy.orm import Session

from google import genai
from google.genai import types

from app.core.config import settings
from app.models.statement import Statement, StatementThesisChunk
from app.models.transaction import Transaction

logger = logging.getLogger(__name__)


class ChatbotService:
    @staticmethod
    async def chat_with_statement(
        db: Session,
        statement_id: str,
        message: str,
        chat_history: List[Dict[str, str]] = None
    ) -> Tuple[str, List[Dict]]:
        """
        Executes an advanced hybrid structured/unstructured RAG semantic chatbot:
        1. Dynamically batch embeds transaction narrations if missing.
        2. Retrieves the most relevant raw Transaction logs via Vector/Fuzzy search.
        3. Retrieves the most relevant sections of the in-depth Financial Thesis via Vector/Fuzzy search.
        4. Ground conversation strictly using matching contexts, delivering complete financial coaching.
        """
        if chat_history is None:
            chat_history = []

        # Fetch bank statement metadata
        statement = db.query(Statement).filter(Statement.statement_id == statement_id).first()
        if not statement:
            return "Bank statement not found in the database.", []

        # Fetch transactions
        transactions = (
            db.query(Transaction)
            .filter(Transaction.statement_id == statement_id)
            .all()
        )

        if not transactions:
            return "No transaction logs exist for this bank statement.", []

        # Fetch thesis chunks
        thesis_chunks = (
            db.query(StatementThesisChunk)
            .filter(StatementThesisChunk.statement_id == statement_id)
            .all()
        )

        client = genai.Client(api_key=settings.GEMINI_API_KEY)
        top_txns = []
        top_thesis = []
        embedding_failed = False

        # 1. VECTOR SEARCH PIPELINE
        if settings.GEMINI_API_KEY and not embedding_failed:
            try:
                # 1a. Dynamic batch embedding for missing transaction vectors
                unembedded = [t for t in transactions if t.embedding is None]
                if unembedded:
                    logger.info(f"Dynamically embedding {len(unembedded)} transactions for statement {statement_id}...")
                    descriptions = [t.raw_description for t in unembedded]
                    
                    batch_size = 100
                    for idx in range(0, len(descriptions), batch_size):
                        batch_txns = unembedded[idx : idx + batch_size]
                        batch_texts = descriptions[idx : idx + batch_size]
                        
                        loop = asyncio.get_running_loop()
                        embed_result = await loop.run_in_executor(
                            None,
                            lambda: client.models.embed_content(
                                model="text-embedding-004",
                                contents=batch_texts
                            )
                        )
                        
                        for t, emb in zip(batch_txns, embed_result.embeddings):
                            t.embedding = emb.values
                    
                    db.commit()
                    logger.info("[SUCCESS] Dynamic transaction vector indexing completed.")

                # 1b. Embed user query
                loop = asyncio.get_running_loop()
                query_embed_res = await loop.run_in_executor(
                    None,
                    lambda: client.models.embed_content(
                        model="text-embedding-004",
                        contents=message
                    )
                )
                query_vector = query_embed_res.embeddings[0].values
                query_arr = np.array(query_vector)

                # 1c. Cosine Similarity Calculations on Transactions
                scored_txns = []
                for t in transactions:
                    if t.embedding is not None:
                        t_arr = np.array(t.embedding)
                        dot_product = np.dot(query_arr, t_arr)
                        norm_q = np.linalg.norm(query_arr)
                        norm_t = np.linalg.norm(t_arr)
                        similarity = dot_product / (norm_q * norm_t) if norm_q > 0 and norm_t > 0 else 0.0
                        scored_txns.append((t, float(similarity)))

                scored_txns.sort(key=lambda x: x[1], reverse=True)
                top_txns = scored_txns[:5]

                # 1d. Cosine Similarity Calculations on Thesis Chunks
                scored_thesis = []
                for chunk in thesis_chunks:
                    if chunk.embedding is not None:
                        c_arr = np.array(chunk.embedding)
                        dot_product = np.dot(query_arr, c_arr)
                        norm_q = np.linalg.norm(query_arr)
                        norm_c = np.linalg.norm(c_arr)
                        similarity = dot_product / (norm_q * norm_c) if norm_q > 0 and norm_c > 0 else 0.0
                        scored_thesis.append((chunk, float(similarity)))

                scored_thesis.sort(key=lambda x: x[1], reverse=True)
                top_thesis = scored_thesis[:2]  # Pull top 2 highly relevant thesis paragraphs

            except Exception as vector_err:
                logger.warning(f"Vector search failed (falling back to fuzzy keyword engine): {vector_err}")
                embedding_failed = True

        # 2. FUZZY LOCAL SEARCH PIPELINE (Pure-Python Resilient Fallback)
        if embedding_failed or not top_txns:
            top_txns = ChatbotService._fuzzy_semantic_search_txns(message, transactions)[:5]
            top_thesis = ChatbotService._fuzzy_semantic_search_thesis(message, thesis_chunks)[:2]

        # 3. COMPILE CONTEXT SOURCES & NARRATIVES
        sources = []
        txn_context_items = []
        thesis_context_items = []

        # Transaction Matches
        for t, score in top_txns:
            if score > 0.15:
                sources.append({
                    "type": "transaction",
                    "date": t.date.strftime("%d/%m/%Y"),
                    "description": t.raw_description,
                    "debit": float(t.debit),
                    "credit": float(t.credit),
                    "balance": float(t.balance),
                    "category": t.category or "Others",
                    "similarity": round(score, 3)
                })
                txn_context_items.append(
                    f"- Date: {t.date.strftime('%d/%m/%Y')} | Narration: {t.raw_description} | "
                    f"Debit: INR {float(t.debit):.2f} | Credit: INR {float(t.credit):.2f} | "
                    f"Balance: INR {float(t.balance):.2f} | Category: {t.category or 'Others'} | "
                    f"Similarity score: {score:.3f}"
                )

        # Thesis Chunk Matches
        for chunk, score in top_thesis:
            if score > 0.15:
                sources.append({
                    "type": "thesis_chunk",
                    "title": chunk.section_title,
                    "content_snippet": chunk.content[:200] + "...",
                    "similarity": round(score, 3)
                })
                thesis_context_items.append(
                    f"### In-Depth Analysis on {chunk.section_title} (Relevance Score: {score:.3f})\n"
                    f"{chunk.content}\n"
                )

        # Calculate key statement aggregates for absolute accuracy
        total_income = 0.0
        total_expense = 0.0
        for t in transactions:
            total_income += float(t.credit or 0.0)
            total_expense += float(t.debit or 0.0)
        net_savings = total_income - total_expense
        saving_rate = (net_savings / total_income * 100) if total_income > 0 else 0.0

        global_insights_context = ""
        if statement and isinstance(statement.raw_ai_output, dict):
            cached_insights = statement.raw_ai_output.get("ai_insights")
            if cached_insights and isinstance(cached_insights, dict):
                cached_summary = cached_insights.get("summary", "")
                global_insights_context = (
                    f"### Global AI Coach Insights\n"
                    f"{cached_summary}\n\n"
                )

        txn_grounding = "\n".join(txn_context_items) if txn_context_items else "No matching transactions found."
        thesis_grounding = "\n\n".join(thesis_context_items) if thesis_context_items else "No matching financial coach thesis sections found."

        history_context = ""
        if chat_history:
            history_context = "### Previous Conversation History\n" + "\n".join([
                f"{h.get('role', 'user').capitalize()}: {h.get('content', '')}"
                for h in chat_history[-5:]
            ]) + "\n\n"

        prompt = f"""
        You are StatementX-Bot, an elite financial coach and wealth chat assistant. Your goal is to provide exceptional, professional, highly accurate, and empathetic financial coaching.
        You are answering a query strictly grounded in the user's bank statement records, calculated insights, and the in-depth strategist thesis.

        {history_context}### Statement High-Level Summary (Global Context)
        - Bank Name: {statement.bank_name if statement else "Unknown Bank"}
        - Total Income (Deposits): INR {total_income:.2f}
        - Total Expense (Withdrawals): INR {total_expense:.2f}
        - Net Savings: INR {net_savings:.2f}
        - Saving Rate: {saving_rate:.2f}%
        - Total Transactions: {len(transactions)}

        {global_insights_context}### Section A: Semantically Retrieved Transactions (Raw Data)
        {txn_grounding}

        ### Section B: Semantically Retrieved Wealth Strategy Thesis Chunks
        {thesis_grounding}

        ### User Query
        {message}

        ### Instructions
        1. Synthesize your answer using BOTH the raw transaction logs in Section A, the overall statement summary, and the strategic thesis chunks in Section B.
        2. Answer the user's specific query with extreme accuracy and rich financial intelligence.
        3. If the user asks for high-level advice, behavioral analysis, expense optimizations, or tactical roadmap directions, ground your answer deeply in the wealth coach strategy (Section B) and Global Insights.
        4. If the user asks about specific amounts, transactions, vendors, or dates, perform precise mathematical sums/filters of the debits and credits in Section A.
        5. Keep your response structured, friendly, and highly professional. Format money figures in INR (₹) or 'INR '.
        """

        # 4. GENERATE ANSWER
        try:
            loop = asyncio.get_running_loop()
            model_response = await loop.run_in_executor(
                None,
                lambda: client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt,
                    config=types.GenerateContentConfig(
                        temperature=0.2,
                    )
                )
            )
            response_text = model_response.text
        except Exception as gen_err:
            logger.error(f"Gemini chatbot answer generation failed: {gen_err}")
            response_text = "I ran into an issue formulating my answer from the retrieved transactions. Please try again in a moment."

        return response_text, sources

    @staticmethod
    def _fuzzy_semantic_search_txns(query: str, transactions: List[Transaction]) -> List[Tuple[Transaction, float]]:
        """
        Pure-Python fallback fuzzy semantic keyword-overlap search for raw transactions.
        """
        stop_words = {
            "how", "much", "did", "i", "spend", "on", "the", "a", "an", "is", "there",
            "any", "find", "my", "show", "me", "what", "was", "were", "of", "in",
            "for", "to", "with", "at", "transaction", "transactions", "orders", "history"
        }
        
        query_clean = query.lower().strip()
        query_words = [w for w in re.sub(r"[^\w\s]", " ", query_clean).split() if w not in stop_words]
        if not query_words:
            query_words = query_clean.split()
            
        scored = []
        for t in transactions:
            desc_clean = t.raw_description.lower()
            matches = sum(1 for qw in query_words if qw in desc_clean)
            overlap_score = matches / len(query_words) if query_words else 0.0
            
            fuzzy_score = difflib.SequenceMatcher(None, query_clean, desc_clean).ratio()
            combined_score = overlap_score * 0.80 + fuzzy_score * 0.20
            
            if t.category and t.category.lower() in query_clean:
                combined_score = min(1.0, combined_score + 0.15)
                
            scored.append((t, combined_score))
            
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored

    @staticmethod
    def _fuzzy_semantic_search_thesis(query: str, chunks: List[StatementThesisChunk]) -> List[Tuple[StatementThesisChunk, float]]:
        """
        Pure-Python fallback fuzzy semantic keyword-overlap search for thesis text segments.
        """
        query_clean = query.lower().strip()
        query_words = re.sub(r"[^\w\s]", " ", query_clean).split()
        if not query_words:
            query_words = query_clean.split()

        scored = []
        for chunk in chunks:
            text_clean = chunk.content.lower()
            title_clean = chunk.section_title.lower()
            
            # Match word count overlaps
            matches = sum(1 for qw in query_words if qw in text_clean)
            overlap_score = matches / len(query_words) if query_words else 0.0
            
            # Boost score if keywords match the section title exactly
            title_matches = sum(1 for qw in query_words if qw in title_clean)
            title_score = title_matches / len(query_words) if query_words else 0.0
            
            combined_score = overlap_score * 0.60 + title_score * 0.40
            scored.append((chunk, combined_score))

        scored.sort(key=lambda x: x[1], reverse=True)
        return scored
