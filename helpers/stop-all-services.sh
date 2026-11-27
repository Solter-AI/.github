#!/bin/bash
###############################################################################
# Solter AI — Stop All Locally Running Services
###############################################################################

ROOT_DIR="/Users/dharmaraj/Projects/SolterAI"
PID_DIR="$ROOT_DIR/.solter-pids"

if [ -d "$PID_DIR" ]; then
  for pid_file in "$PID_DIR"/*.pid; do
    [ -e "$pid_file" ] || continue
    name=$(basename "$pid_file" .pid)
    pid=$(cat "$pid_file")
    if kill -0 "$pid" 2>/dev/null; then
      echo "Stopping $name (PID $pid)..."
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$pid_file"
  done
fi

# Also ensure no child/orphan listeners remain on service ports
for port in 3000 8080 8081 8082 8083 8084 8085 8086 8087; do
  pids=$(lsof -ti :"$port" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    echo "Stopping listener on port $port (PID $pids)..."
    kill $pids 2>/dev/null || true
  fi
done

echo "All tracked Solter AI services stopped."
