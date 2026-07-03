#!/bin/bash
# Restart Railway service — call this after editing provider.conf
# Usage: bash restart_railway.sh
# Needs: RAILWAY_TOKEN env var

TOKEN="${RAILWAY_TOKEN}"
PROJECT_ID="${RAILWAY_PROJECT_ID}"
SERVICE_ID="${RAILWAY_SERVICE_ID}"

if [ -z "$TOKEN" ] || [ -z "$PROJECT_ID" ] || [ -z "$SERVICE_ID" ]; then
    echo "[!] Missing env vars. Set RAILWAY_TOKEN, RAILWAY_PROJECT_ID, RAILWAY_SERVICE_ID"
    exit 1
fi

echo "[*] Restarting Railway service..."
RESULT=$(curl -s -X POST https://backboard.railway.app/graphql/v2 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\":\"mutation { serviceInstanceRedeploy(serviceId: \\\"$SERVICE_ID\\\", projectId: \\\"$PROJECT_ID\\\") { id } }\"}")

echo "$RESULT"
echo "[+] Restart triggered!"
