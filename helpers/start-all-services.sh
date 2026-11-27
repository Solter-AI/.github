#!/bin/bash
###############################################################################
# Solter AI — Start All Frontend & Backend Services Locally (No Docker)
#
# Ports match solter-api-gateway/src/main/resources/application.properties:
#   8080  solter-api-gateway
#   8081  solter-tenant-service
#   8082  solter-rag-service
#   8083  solter-mcp-gateway
#   8084  solter-voice-orchestrator
#   8085  solter-telephony-bridge
#   8086  solter-analytics-service
#   8087  solter-billing-service
#   3000  solter-web (Vite dev server)
###############################################################################

set -e

ROOT_DIR="/Users/dharmaraj/Projects/SolterAI"
LOG_DIR="$ROOT_DIR/.solter-logs"
PID_DIR="$ROOT_DIR/.solter-pids"

mkdir -p "$LOG_DIR" "$PID_DIR"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC}   %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${NC} $1\n"; }

# Ensure Redis is running
if command -v brew >/dev/null 2>&1; then
  if ! redis-cli ping >/dev/null 2>&1; then
    info "Starting Redis via Homebrew..."
    brew services start redis >/dev/null 2>&1 || warn "Could not auto-start Redis"
  fi
fi

# Auto-detect PostgreSQL port (5432 or 5433)
if [ -z "$DB_PORT" ]; then
  if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
    DB_PORT=5432
  elif pg_isready -h localhost -p 5433 >/dev/null 2>&1; then
    DB_PORT=5433
  else
    DB_PORT=5432
    if command -v brew >/dev/null 2>&1; then
      info "Starting PostgreSQL@14 via Homebrew..."
      brew services start postgresql@14 >/dev/null 2>&1 || warn "Could not auto-start PostgreSQL"
      sleep 2
      pg_isready -h localhost -p 5433 >/dev/null 2>&1 && DB_PORT=5433
    fi
  fi
fi
export DB_PORT
info "Using PostgreSQL on port $DB_PORT"

# Create missing service databases if psql is reachable
if pg_isready -h localhost -p "$DB_PORT" >/dev/null 2>&1; then
  for db in soltertenantservice_db solterragservice_db soltermcpgateway_db soltervoiceorchestrator_db soltertelephonybridge_db solteranalyticsservice_db solterbillingservice_db; do
    if ! psql -h localhost -p "$DB_PORT" -U postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$db"; then
      psql -h localhost -p "$DB_PORT" -U postgres -c "CREATE DATABASE $db;" >/dev/null 2>&1 || \
      psql -h localhost -p "$DB_PORT" -d postgres -c "CREATE DATABASE $db;" >/dev/null 2>&1 || true
    fi
  done
  psql -h localhost -p "$DB_PORT" -U postgres -d solterragservice_db -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1 || \
  psql -h localhost -p "$DB_PORT" -d solterragservice_db -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1 || true
fi

start_bg() {
  local name="$1"
  local port="$2"
  local dir="$3"
  local cmd="$4"
  local pid_file="$PID_DIR/${name}.pid"
  local log_file="$LOG_DIR/${name}.log"

  if [ -n "$(lsof -ti :"$port" 2>/dev/null)" ]; then
    warn "$name port $port already in use (PID $(lsof -ti :"$port" | head -n 1))"
    return
  fi

  info "Starting $name on port $port..."
  (
    cd "$dir"
    nohup sh -c "$cmd" > "$log_file" 2>&1 </dev/null &
    echo $! > "$pid_file"
  )
  success "$name launched (PID $(cat "$pid_file"), log: .solter-logs/${name}.log)"
}

# Spring Boot Microservices
start_bg "solter-api-gateway"       8080 "$ROOT_DIR/solter-api-gateway"       "SERVER_PORT=8080 DB_PORT=$DB_PORT mvn spring-boot:run"
start_bg "solter-tenant-service"    8081 "$ROOT_DIR/solter-tenant-service"    "SERVER_PORT=8081 DB_PORT=$DB_PORT mvn spring-boot:run"
start_bg "solter-mcp-gateway"       8083 "$ROOT_DIR/solter-mcp-gateway"       "SERVER_PORT=8083 DB_PORT=$DB_PORT SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect SPRING_JPA_HIBERNATE_DDL_AUTO=update mvn spring-boot:run"
start_bg "solter-analytics-service" 8086 "$ROOT_DIR/solter-analytics-service" "SERVER_PORT=8086 DB_PORT=$DB_PORT SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect mvn spring-boot:run"
start_bg "solter-billing-service"   8087 "$ROOT_DIR/solter-billing-service"   "SERVER_PORT=8087 DB_PORT=$DB_PORT SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect SPRING_JPA_HIBERNATE_DDL_AUTO=update mvn spring-boot:run"

# Python FastAPI Microservices
RAG_UVICORN="$ROOT_DIR/solter-rag-service/.venv/bin/uvicorn"
[ -x "$RAG_UVICORN" ] || RAG_UVICORN="uvicorn"
start_bg "solter-rag-service" 8082 "$ROOT_DIR/solter-rag-service" "SERVER_PORT=8082 DB_PORT=$DB_PORT $RAG_UVICORN main:app --host 0.0.0.0 --port 8082"

VOICE_UVICORN="$ROOT_DIR/solter-voice-orchestrator/.venv/bin/uvicorn"
[ -x "$VOICE_UVICORN" ] || VOICE_UVICORN="uvicorn"
start_bg "solter-voice-orchestrator" 8084 "$ROOT_DIR/solter-voice-orchestrator" "SERVER_PORT=8084 DB_PORT=$DB_PORT $VOICE_UVICORN main:app --host 0.0.0.0 --port 8084"

# Node.js / TypeScript Microservice
start_bg "solter-telephony-bridge" 8085 "$ROOT_DIR/solter-telephony-bridge" "npm run build && SERVER_PORT=8085 DB_PORT=$DB_PORT node dist/index.js"

# React Frontend
start_bg "solter-web" 3000 "$ROOT_DIR/solter-web" "npm run dev -- --port 3000"

# Open frontend in default browser once Vite responds
(
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl -s -o /dev/null --max-time 1 "http://localhost:3000" 2>/dev/null; then
      break
    fi
    sleep 1
  done
  if command -v open >/dev/null 2>&1; then
    open "http://localhost:3000" >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:3000" >/dev/null 2>&1 || true
  fi
) &

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Solter AI Local Stack Launched (Logs: $LOG_DIR)"
echo "══════════════════════════════════════════════════════════════"
echo "  Frontend (solter-web):        http://localhost:3000"
echo "  API Gateway:                  http://localhost:8080"
echo "  Tenant Service:               http://localhost:8081"
echo "  RAG Service:                  http://localhost:8082"
echo "  MCP Gateway:                  http://localhost:8083"
echo "  Voice Orchestrator:           http://localhost:8084"
echo "  Telephony Bridge:             http://localhost:8085"
echo "  Analytics Service:            http://localhost:8086"
echo "  Billing Service:              http://localhost:8087"
echo ""
echo "  Check status: $ROOT_DIR/.github/helpers/status-all-services.sh"
echo "  Stop all:     $ROOT_DIR/.github/helpers/stop-all-services.sh"
echo "══════════════════════════════════════════════════════════════"
