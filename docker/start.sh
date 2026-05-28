#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /app/config.json ]; then
  echo "Missing /app/config.json. Copy config.example.json to config.json and mount it with Docker Compose." >&2
  exit 1
fi

pids=()

stop_children() {
  if [ "${#pids[@]}" -gt 0 ]; then
    kill "${pids[@]}" 2>/dev/null || true
    wait "${pids[@]}" 2>/dev/null || true
  fi
}

trap stop_children INT TERM EXIT

(cd /app/plus_gopay_links && python payment_server.py --config /app/config.json --listen :50051) &
payment_pid=$!
pids+=("$payment_pid")

(cd /app && python orchestrator.py) &
orchestrator_pid=$!
pids+=("$orchestrator_pid")

whatsapp_pid=""
if [ "${START_WHATSAPP:-false}" = "true" ]; then
  (cd /app/to_whatsapp && node index.js) &
  whatsapp_pid=$!
  pids+=("$whatsapp_pid")
fi

while true; do
  wait -n || true

  if ! kill -0 "$payment_pid" 2>/dev/null; then
    echo "payment_server exited" >&2
    exit 1
  fi

  if ! kill -0 "$orchestrator_pid" 2>/dev/null; then
    echo "orchestrator exited" >&2
    exit 1
  fi

  if [ -n "$whatsapp_pid" ] && ! kill -0 "$whatsapp_pid" 2>/dev/null; then
    echo "whatsapp_relay exited" >&2
    exit 1
  fi
done
