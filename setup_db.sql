-- ============================================================
-- setup_db.sql - sensor_db 데이터베이스 및 테이블 생성
-- ============================================================

-- 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS sensor_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- 사용자 생성 및 권한 부여
CREATE USER IF NOT EXISTS 'sensor_user'@'localhost' IDENTIFIED BY 'sensor_pass';
GRANT ALL PRIVILEGES ON sensor_db.* TO 'sensor_user'@'localhost';
FLUSH PRIVILEGES;

-- sensor_db 사용
USE sensor_db;

-- sensor_data 테이블 생성
CREATE TABLE IF NOT EXISTS sensor_data (
    id        INT AUTO_INCREMENT PRIMARY KEY,
    value     FLOAT        NOT NULL,
    timestamp DATETIME     DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 확인 메시지
SELECT 'sensor_db 및 sensor_data 테이블이 성공적으로 생성되었습니다.' AS 결과;
