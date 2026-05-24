from app.core.database import engine
from sqlalchemy import text

with engine.connect() as conn:
    print("Adding user_id column to statements table...")
    try:
        conn.execute(text('ALTER TABLE statements ADD COLUMN user_id UUID REFERENCES users(user_id)'))
        conn.commit()
        print("Success.")
    except Exception as e:
        print(f"Error: {e}")
