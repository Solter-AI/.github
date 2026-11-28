#!/usr/bin/env bash
###############################################################################
# Solter AI — Smart Service Restarter (Hash-Based)
# Compares each service's current git HEAD + working tree hash against the
# last-started hash in /tmp/solter-service-hashes/ and restarts only changed
# or down services. Pass --force to restart all services.
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="/tmp/solter-logs"
HASH_DIR="/tmp/solter-service-hashes"
DB_PORT="${DB_PORT:-5433}"
FORCE=false

if [ "${1:-}" = "--force" ]; then
  FORCE=true
fi

mkdir -p "$LOG_DIR" "$HASH_DIR"

compute_hash() {
  local dir="$1"
  if [ -d "$dir/.git" ]; then
    local head dirty
    head=$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo "none")
    dirty=$(git -C "$dir" status --porcelain 2>/dev/null | md5 -q 2>/dev/null || git -C "$dir" status --porcelain 2>/dev/null | md5sum | awk '{print $1}')
    echo "${head}-${dirty}"
  else
    echo "no-git"
  fi
}

restart_if_needed() {
  local name="$1"
  local port="$2"
  local dir="$3"
  local cmd="$4"

  if [ ! -d "$dir" ]; then
    echo "⚠️  Skipping $name (directory not found: $dir)"
    return
  fi

  local current_hash prev_hash=""
  current_hash=$(compute_hash "$dir")
  if [ -f "$HASH_DIR/$name.hash" ]; then
    prev_hash=$(cat "$HASH_DIR/$name.hash")
  fi

  local pid_running=false
  if lsof -ti :"$port" >/dev/null 2>&1; then
    pid_running=true
  fi

  if [ "$FORCE" = false ] && [ "$pid_running" = true ] && [ "$current_hash" = "$prev_hash" ]; then
    echo "✓  $name (port $port) unchanged — skipping"
    return
  fi

  echo "↻  Restarting $name on port $port..."
  local pids
  pids=$(lsof -ti :"$port" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    kill $pids 2>/dev/null || true
    sleep 1
    pids=$(lsof -ti :"$port" 2>/dev/null || true)
    [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
  fi

  (
    cd "$dir"
    nohup bash -c "$cmd" < /dev/null > "$LOG_DIR/$name.log" 2>&1 &
    echo $! > "$LOG_DIR/$name.pid"
  )
  echo "$current_hash" > "$HASH_DIR/$name.hash"
}

echo "══════════════════════════════════════════════════════════════"
echo "  Solter AI — Checking & Restarting Changed Services"
echo "══════════════════════════════════════════════════════════════"

restart_if_needed "solter-api-gateway"          8080 "$ROOT_DIR/solter-api-gateway"          "SERVER_PORT=8080 DB_PORT=$DB_PORT mvn spring-boot:run"
restart_if_needed "solter-tenant-service"       8081 "$ROOT_DIR/solter-tenant-service"       "SERVER_PORT=8081 DB_PORT=$DB_PORT mvn spring-boot:run"
restart_if_needed "solter-mcp-gateway"          8083 "$ROOT_DIR/solter-mcp-gateway"          "SERVER_PORT=8083 DB_PORT=$DB_PORT SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect SPRING_JPA_HIBERNATE_DDL_AUTO=update mvn spring-boot:run"
restart_if_needed "solter-analytics-service"    8086 "$ROOT_DIR/solter-analytics-service"    "SERVER_PORT=8086 DB_PORT=$DB_PORT SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect mvn spring-boot:run"
restart_if_needed "solter-billing-service"      8087 "$ROOT_DIR/solter-billing-service"      "SERVER_PORT=8087 DB_PORT=$DB_PORT SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect SPRING_JPA_HIBERNATE_DDL_AUTO=update mvn spring-boot:run"
restart_if_needed "solter-notification-service" 8088 "$ROOT_DIR/solter-notification-service" "[ -f .env ] && set -a && . ./.env && set +a; SERVER_PORT=8088 DB_PORT=$DB_PORT SPRING_JPA_HIBERNATE_DDL_AUTO=update mvn spring-boot:run"

RAG_UVICORN="$ROOT_DIR/solter-rag-service/.venv/bin/uvicorn"
[ -x "$RAG_UVICORN" ] || RAG_UVICORN="uvicorn"
restart_if_needed "solter-rag-service"          8082 "$ROOT_DIR/solter-rag-service"          "SERVER_PORT=8082 DB_PORT=$DB_PORT $RAG_UVICORN main:app --host 0.0.0.0 --port 8082"

VOICE_UVICORN="$ROOT_DIR/solter-voice-orchestrator/.venv/bin/uvicorn"
[ -x "$VOICE_UVICORN" ] || VOICE_UVICORN="uvicorn"
restart_if_needed "solter-voice-orchestrator"   8084 "$ROOT_DIR/solter-voice-orchestrator"   "SERVER_PORT=8084 DB_PORT=$DB_PORT $VOICE_UVICORN main:app --host 0.0.0.0 --port 8084"

restart_if_needed "solter-telephony-bridge"     8085 "$ROOT_DIR/solter-telephony-bridge"     "SERVER_PORT=8085 DB_PORT=$DB_PORT npm run dev"

restart_if_needed "solter-web"                  3000 "$ROOT_DIR/solter-web"                  "npm run dev"

echo ""
echo "  Check status: $ROOT_DIR/.github/helpers/status-all-services.sh"
echo "══════════════════════════════════════════════════════════════"
