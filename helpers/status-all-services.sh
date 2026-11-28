#!/bin/bash
###############################################################################
# Solter AI — Check Status of All Local Frontend & Backend Services
###############################################################################

ROOT_DIR="/Users/dharmaraj/Projects/SolterAI"
PID_DIR="$ROOT_DIR/.solter-pids"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "\n"
printf "${BLUE}══════════════════════════════════════════════════════════════════${NC}\n"
printf "${BLUE}  Solter AI — Local Stack Status${NC}\n"
printf "${BLUE}══════════════════════════════════════════════════════════════════${NC}\n"

if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
  printf "  PostgreSQL (5432)     : ${GREEN}UP${NC}\n"
elif pg_isready -h localhost -p 5433 >/dev/null 2>&1; then
  printf "  PostgreSQL (5433)     : ${GREEN}UP${NC}\n"
else
  printf "  PostgreSQL (5432/5433): ${RED}DOWN${NC}\n"
fi

if [ "$(redis-cli ping 2>/dev/null)" = "PONG" ]; then
  printf "  Redis (6379)          : ${GREEN}UP${NC}\n"
else
  printf "  Redis (6379)          : ${RED}DOWN${NC}\n"
fi

printf "──────────────────────────────────────────────────────────────────\n"
printf "  %-26s %-7s %-14s %-12s\n" "SERVICE" "PORT" "PROCESS" "HTTP"
printf "──────────────────────────────────────────────────────────────────\n"

check_service() {
  local name="$1"
  local port="$2"
  local health_path="$3"
  local pid_file="$PID_DIR/${name}.pid"

  local port_pid
  port_pid=$(lsof -ti :"$port" 2>/dev/null | head -n 1)
  local proc_status="${RED}STOPPED${NC}"
  if [ -n "$port_pid" ]; then
    proc_status="${GREEN}PID $port_pid${NC}"
  elif [ -f "$pid_file" ]; then
    local pid
    pid=$(cat "$pid_file")
    if kill -0 "$pid" 2>/dev/null; then
      proc_status="${GREEN}PID $pid${NC}"
    else
      proc_status="${YELLOW}STALE${NC}"
    fi
  fi

  local http_status="${RED}DOWN${NC}"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 -H "X-Tenant-Id: health-check" "http://localhost:${port}${health_path}" 2>/dev/null)
  if [ -n "$code" ] && [ "$code" != "000" ] && [ "$code" -lt 500 ] 2>/dev/null; then
    http_status="${GREEN}HTTP $code${NC}"
  elif [ -n "$code" ] && [ "$code" != "000" ]; then
    http_status="${YELLOW}HTTP $code${NC}"
  fi

  printf "  %-26s %-7s %-25b %-20b\n" "$name" "$port" "$proc_status" "$http_status"
}

check_service "solter-web"                3000 "/"
check_service "solter-api-gateway"        8080 "/actuator/health"
check_service "solter-tenant-service"     8081 "/api/actuator/health"
check_service "solter-rag-service"        8082 "/health"
check_service "solter-mcp-gateway"        8083 "/api/v1/mcp/packs"
check_service "solter-voice-orchestrator" 8084 "/api/health"
check_service "solter-telephony-bridge"   8085 "/api/health"
check_service "solter-analytics-service"  8086 "/api/v1/calls"
check_service "solter-billing-service"    8087 "/api/v1/billing/plans"
check_service "solter-notification-service" 8088 "/api/v1/notifications/dlq"

printf "${BLUE}══════════════════════════════════════════════════════════════════${NC}\n\n"
