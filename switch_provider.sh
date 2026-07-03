#!/bin/bash
# Switch provider and restart
# Usage: bash switch_provider.sh <provider_name> [api_key] [model]
# Example: bash switch_provider.sh mimo tp-xxx mimo

PROVIDER="${1:-bai}"
API_KEY="${2:-}"
MODEL="${3:-}"
CONF="/opt/data/provider.conf"

echo "[*] Switching to provider: $PROVIDER"

# Update provider.conf
sed -i "s/^PROVIDER_NAME=.*/PROVIDER_NAME=$PROVIDER/" "$CONF"

case "$PROVIDER" in
  bai)
    echo "[+] B.AI mode — using rotating proxy with 5000+ keys"
    ;;
  mimo)
    if [ -n "$API_KEY" ]; then
        sed -i "s/^MIMO_API_KEY=.*/MIMO_API_KEY=$API_KEY/" "$CONF"
    fi
    if [ -n "$MODEL" ]; then
        sed -i "s/^MIMO_MODEL=.*/MIMO_MODEL=$MODEL/" "$CONF"
    fi
    echo "[+] MiMo mode — API key: ${API_KEY:0:10}..."
    ;;
  fireworks)
    if [ -n "$API_KEY" ]; then
        sed -i "s/^FIREWORKS_API_KEY=.*/FIREWORKS_API_KEY=$API_KEY/" "$CONF"
    fi
    if [ -n "$MODEL" ]; then
        sed -i "s/^FIREWORKS_MODEL=.*/FIREWORKS_MODEL=$MODEL/" "$CONF"
    fi
    echo "[+] Fireworks mode — API key: ${API_KEY:0:10}..."
    ;;
  *)
    echo "[!] Unknown provider: $PROVIDER (bai/mimo/fireworks)"
    exit 1
    ;;
esac

# Restart if RAILWAY_TOKEN is set
if [ -n "$RAILWAY_TOKEN" ]; then
    echo "[*] Restarting Railway..."
    bash /opt/data/restart_railway.sh
else
    echo "[!] No RAILWAY_TOKEN — restart manually or set the token"
fi
