import sqlite3
import random
import time

DB_PATH = "shkimdb2.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS sensor (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            humid REAL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()

def insert_humid(value):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO sensor (humid) VALUES (?)", (value,))
    conn.commit()
    conn.close()

if __name__ == "__main__":
    init_db()
    print("DB 초기화 완료. 5초마다 humid 값을 저장합니다. (종료: Ctrl+C)")
    try:
        while True:
            value = random.randint(0, 100)
            insert_humid(value)
            print(f"저장됨: humid = {value}")
            time.sleep(5)
    except KeyboardInterrupt:
        print("종료")
