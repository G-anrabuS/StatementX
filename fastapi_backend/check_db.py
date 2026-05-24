
import sqlite3

# 1. Establish direct database file connection
conn = sqlite3.connect('statementx.db')
cur = conn.cursor()

# 2. Query the raw database values directly (bypassing SQLAlchemy decryption)
cur.execute('SELECT raw_description, debit, credit, balance FROM transactions LIMIT 3')

print("==============================================")
print("===   RAW DATABASE DISK READ (LEAK TEST)   ===")
print("==============================================\n")

for idx, row in enumerate(cur.fetchall(), 1):
    print(f"🚨 TRANSACTION ROW {idx} ON DISK:")
    print(f"   Description Ciphertext:  {row[0][:50]}...")
    print(f"   Debit Ciphertext:        {row[1][:50]}...")
    print(f"   Balance Ciphertext:      {row[3][:50]}...\n")

conn.close()
