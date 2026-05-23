import re
from sqlalchemy import text
from app.models.merchant_cache import MerchantCache


class MerchantCacheService:
    @staticmethod
    def normalize(text_input: str) -> str:
        text_input = text_input.lower()
        text_input = re.sub(r"\d+", "", text_input)
        text_input = re.sub(r"[^\w\s]", " ", text_input)
        text_input = re.sub(r"\s+", " ", text_input)
        return text_input.strip()

    @staticmethod
    def lookup(db, merchant_name: str):
        normalized = MerchantCacheService.normalize(merchant_name)

        query = text("""
            SELECT category, sub_category
            FROM merchant_cache
            WHERE similarity(normalized_name, :name) > 0.75
            ORDER BY similarity(normalized_name, :name) DESC
            LIMIT 1
        """)

        result = db.execute(query, {"name": normalized}).fetchone()

        if result:
            return {
                "category": result.category,
                "sub_category": result.sub_category,
                "confidence": 1.0,
            }

        return None

    @staticmethod
    def insert(db, merchant_name, category, sub_category):
        normalized = MerchantCacheService.normalize(merchant_name)

        existing = (
            db.query(MerchantCache)
            .filter(MerchantCache.normalized_name == normalized)
            .first()
        )

        if existing:
            return

        db.add(
            MerchantCache(
                merchant_name=merchant_name,
                normalized_name=normalized,
                category=category,
                sub_category=sub_category,
            )
        )

        db.commit()
