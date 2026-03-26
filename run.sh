#!/usr/bin/env bash
# ============================================================
# run.sh - sensor_project 전체 자동 실행 스크립트
# ============================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${PROJECT_DIR}/.venv"
PYTHON="${VENV_DIR}/bin/python"
PIP="${VENV_DIR}/bin/pip"
REQUIREMENTS="${PROJECT_DIR}/requirements.txt"
INJECTOR="${PROJECT_DIR}/injector.py"
SETUP_SQL="${PROJECT_DIR}/setup_db.sql"
FLOWS_JSON="${PROJECT_DIR}/flows.json"
NODERED_FLOWS_DIR="${HOME}/.node-red"

# ── 색상 출력 헬퍼 ───────────────────────────────────────────
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*"; }
info() { echo -e "${YELLOW}[INFO]${NC} $*"; }

echo "========================================================"
echo "  Sensor Project — 자동 실행 스크립트"
echo "  작업 디렉토리: ${PROJECT_DIR}"
echo "========================================================"

# ── STEP 1: MySQL 서비스 시작 ─────────────────────────────────
info "STEP 1: MySQL 서비스 시작 중..."
if sudo systemctl start mysql 2>/dev/null || sudo service mysql start 2>/dev/null; then
    ok "MySQL 서비스 시작 완료"
else
    err "MySQL 서비스 시작 실패 — 수동으로 MySQL을 시작해주세요"
    exit 1
fi
sleep 2

# ── STEP 2: DB/테이블 초기화 ──────────────────────────────────
info "STEP 2: sensor_db 초기화 중 (setup_db.sql 실행)..."
if sudo mysql -u root < "${SETUP_SQL}" 2>/dev/null; then
    ok "sensor_db 초기화 완료"
else
    info "root 비밀번호가 설정된 경우 아래 명령을 직접 실행하세요:"
    info "  sudo mysql -u root -p < ${SETUP_SQL}"
fi

# ── STEP 3: Python 가상환경 생성 ──────────────────────────────
info "STEP 3: Python 가상환경 확인/생성 중..."
if [ ! -d "${VENV_DIR}" ]; then
    python3 -m venv "${VENV_DIR}"
    ok "가상환경 생성 완료: ${VENV_DIR}"
else
    ok "가상환경 이미 존재: ${VENV_DIR}"
fi

# ── STEP 4: pip install ───────────────────────────────────────
info "STEP 4: Python 패키지 설치 중 (requirements.txt)..."
if "${PIP}" install --upgrade pip -q && "${PIP}" install -r "${REQUIREMENTS}" -q; then
    ok "패키지 설치 완료"
else
    err "패키지 설치 실패"
    exit 1
fi

# ── STEP 5: Node-RED 설치 확인 및 패키지 설치 ────────────────
info "STEP 5: Node-RED 확인 중..."
if command -v node-red &>/dev/null; then
    ok "Node-RED 설치 확인됨: $(node-red --version 2>/dev/null | head -1)"
else
    info "Node-RED가 설치되지 않았습니다. 설치 중..."
    if sudo npm install -g --unsafe-perm node-red; then
        ok "Node-RED 설치 완료"
    else
        err "Node-RED 설치 실패 — 수동으로 설치해주세요: sudo npm install -g --unsafe-perm node-red"
    fi
fi

# Node-RED 추가 패키지 설치
info "  Node-RED 대시보드 패키지 설치 중..."
mkdir -p "${NODERED_FLOWS_DIR}"
cd "${NODERED_FLOWS_DIR}"
if [ ! -f package.json ]; then
    npm init -y -q 2>/dev/null || true
fi
if npm install node-red-dashboard node-red-node-mysql --save -q 2>/dev/null; then
    ok "  node-red-dashboard, node-red-node-mysql 설치 완료"
else
    info "  Node-RED 패키지 설치에 문제가 있을 수 있습니다 (Node-RED UI에서 수동 설치 가능)"
fi
cd "${PROJECT_DIR}"

# flows.json 복사
if [ -f "${FLOWS_JSON}" ]; then
    cp "${FLOWS_JSON}" "${NODERED_FLOWS_DIR}/flows.json"
    ok "  flows.json 복사 완료 → ${NODERED_FLOWS_DIR}/flows.json"
fi

# ── STEP 6: Node-RED 백그라운드 실행 ─────────────────────────
info "STEP 6: Node-RED 백그라운드 실행 중..."
pkill -f "node-red" 2>/dev/null || true
sleep 1
nohup node-red > "${PROJECT_DIR}/nodered.log" 2>&1 &
NODERED_PID=$!
echo "${NODERED_PID}" > "${PROJECT_DIR}/nodered.pid"
sleep 3
if kill -0 "${NODERED_PID}" 2>/dev/null; then
    ok "Node-RED 실행 중 (PID: ${NODERED_PID}) → http://localhost:1880"
else
    err "Node-RED 실행 실패 — nodered.log 파일을 확인하세요"
fi

# ── STEP 7: Grafana 서비스 시작 ───────────────────────────────
info "STEP 7: Grafana 서비스 시작 중..."
if sudo systemctl start grafana-server 2>/dev/null || sudo service grafana-server start 2>/dev/null; then
    ok "Grafana 서비스 시작 완료 → http://localhost:3000 (admin/admin)"
else
    info "Grafana가 설치되지 않았거나 서비스 시작 실패"
    info "설치: sudo apt-get install -y grafana"
    info "시작: sudo systemctl start grafana-server"
fi

# ── STEP 8: 접속 정보 출력 ────────────────────────────────────
echo ""
echo "========================================================"
echo "  접속 정보"
echo "========================================================"
echo "  Node-RED 에디터:    http://localhost:1880"
echo "  Node-RED 대시보드:  http://localhost:1880/ui"
echo "  Grafana:            http://localhost:3000"
echo "    (초기 계정: admin / admin)"
echo ""
echo "  Grafana 데이터소스 설정 (최초 1회):"
echo "    타입: MySQL"
echo "    Host: localhost:3306"
echo "    DB:   sensor_db"
echo "    User: sensor_user / Pass: sensor_pass"
echo ""
echo "  Grafana 대시보드 가져오기:"
echo "    Dashboards → Import → grafana_dashboard.json 업로드"
echo "========================================================"
echo ""

# ── STEP 9: injector.py 실행 (포그라운드) ────────────────────
info "STEP 9: injector.py 실행 시작 (Ctrl+C로 종료)"
echo ""
exec "${PYTHON}" "${INJECTOR}"
