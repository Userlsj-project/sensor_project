#!/usr/bin/env python3
"""
injector.py - 랜덤 난수를 생성하여 MySQL sensor_data 테이블에 2초 간격으로 INSERT
"""

import random
import time
import signal
import sys
from datetime import datetime

import mysql.connector
from mysql.connector import Error

# ── DB 접속 설정 ──────────────────────────────────────────────
DB_CONFIG = {
    "host":     "localhost",
    "port":     3306,
    "database": "sensor_db",
    "user":     "sensor_user",
    "password": "sensor_pass",
    "autocommit": True,
}

INSERT_SQL = "INSERT INTO sensor_data (value) VALUES (%s)"
INTERVAL   = 2      # 삽입 간격 (초)
VALUE_MIN  = 0.0
VALUE_MAX  = 100.0

# ── 전역 변수 ─────────────────────────────────────────────────
_running = True
_conn    = None


def signal_handler(sig, frame):
    """Ctrl+C 수신 시 안전 종료"""
    global _running
    print("\n\n[종료] Ctrl+C 감지 — 안전하게 종료합니다...")
    _running = False


def connect_db():
    """MySQL 연결 및 연결 객체 반환"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        if conn.is_connected():
            print(f"[DB] MySQL 연결 성공 (sensor_db @ {DB_CONFIG['host']}:{DB_CONFIG['port']})")
        return conn
    except Error as e:
        print(f"[DB ERROR] 연결 실패: {e}")
        sys.exit(1)


def insert_value(cursor, value: float) -> None:
    """단일 값을 sensor_data 테이블에 INSERT"""
    cursor.execute(INSERT_SQL, (value,))


def main():
    global _conn, _running

    # Ctrl+C 핸들러 등록
    signal.signal(signal.SIGINT,  signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    print("=" * 55)
    print("  Sensor Injector  |  2초 간격 MySQL INSERT 시작")
    print("=" * 55)

    _conn = connect_db()
    cursor = _conn.cursor()

    try:
        while _running:
            value = round(random.uniform(VALUE_MIN, VALUE_MAX), 2)
            now   = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            try:
                insert_value(cursor, value)
                print(f"[{now}]  삽입값: {value:>6.2f}")
            except Error as e:
                print(f"[{now}]  INSERT 오류: {e}")
                # 연결이 끊겼으면 재연결 시도
                if not _conn.is_connected():
                    print("[DB] 재연결 시도...")
                    _conn   = connect_db()
                    cursor  = _conn.cursor()

            time.sleep(INTERVAL)

    finally:
        cursor.close()
        if _conn and _conn.is_connected():
            _conn.close()
            print("[DB] MySQL 연결 종료")
        print("[종료] injector.py 정상 종료 완료")


if __name__ == "__main__":
    main()
