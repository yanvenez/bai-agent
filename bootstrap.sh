#!/bin/bash
# Bootstrap: baca provider.conf, setenv, jalankan proxy + hermes

CONF="/opt/data/provider.conf"

# Load config
if [ -f "$CONF" ]; then
    export $(grep -v '^#' "$CONF" | grep -v '^$' | xargs)
fi

PROVIDER="${PROVIDER_NAME:-bai}"

echo "🚀 Starting with provider: $PROVIDER"

case "$PROVIDER" in
  bai)
    # Start rotating proxy
    echo "📡 Starting B.AI proxy..."
    python3 /opt/bai_proxy.py &
    sleep 2
    export OPENAI_API_KEY="not-needed"
    export OPENAI_BASE_URL="http://localhost:4000/v1"
    export HERMES_MODEL="${BAI_MODEL:-gpt-5.4}"
    ;;
  mimo)
    export OPENAI_API_KEY="${MIMO_API_KEY}"
    export OPENAI_BASE_URL="${MIMO_BASE_URL}"
    export HERMES_MODEL="${MIMO_MODEL:-mimo}"
    ;;
  fireworks)
    export OPENAI_API_KEY="${FIREWORKS_API_KEY}"
    export OPENAI_BASE_URL="${FIREWORKS_BASE_URL}"
    export HERMES_MODEL="${FIREWORKS_MODEL}"
    ;;
  *)
    echo "Unknown provider: $PROVIDER, using env vars as-is"
    ;;
esac

echo "📡 Base URL: $OPENAI_BASE_URL"
echo "🤖 Model: $HERMES_MODEL"

# Start Hermes
exec hermes gateway run
