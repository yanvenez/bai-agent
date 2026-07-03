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
    echo "📡 Starting B.AI proxy..."
    python3 /opt/bai_proxy.py &
    sleep 2
    OPENAI_API_KEY_VAL="not-needed"
    OPENAI_BASE_URL_VAL="http://localhost:4000/v1"
    HERMES_MODEL_VAL="${BAI_MODEL:-gpt-5.4}"
    ;;
  mimo)
    OPENAI_API_KEY_VAL="${MIMO_API_KEY}"
    OPENAI_BASE_URL_VAL="${MIMO_BASE_URL}"
    HERMES_MODEL_VAL="${MIMO_MODEL:-mimo}"
    ;;
  fireworks)
    OPENAI_API_KEY_VAL="${FIREWORKS_API_KEY}"
    OPENAI_BASE_URL_VAL="${FIREWORKS_BASE_URL}"
    HERMES_MODEL_VAL="${FIREWORKS_MODEL}"
    ;;
  *)
    echo "Unknown provider: $PROVIDER"
    OPENAI_API_KEY_VAL="${OPENAI_API_KEY}"
    OPENAI_BASE_URL_VAL="${OPENAI_BASE_URL}"
    HERMES_MODEL_VAL="${HERMES_MODEL}"
    ;;
esac

export OPENAI_API_KEY="$OPENAI_API_KEY_VAL"
export OPENAI_BASE_URL="$OPENAI_BASE_URL_VAL"
export HERMES_MODEL="$HERMES_MODEL_VAL"

echo "📡 Base URL: $OPENAI_BASE_URL"
echo "🤖 Model: $HERMES_MODEL"

# Write to ~/.hermes/.env so hermes picks it up
mkdir -p /opt/data/.hermes
cat > /opt/data/.hermes/.env << EOF
OPENAI_API_KEY=$OPENAI_API_KEY_VAL
OPENAI_BASE_URL=$OPENAI_BASE_URL_VAL
HERMES_MODEL=$HERMES_MODEL_VAL
EOF

# Also set via hermes config
hermes config set provider.base_url "$OPENAI_BASE_URL_VAL" 2>/dev/null || true
hermes config set provider.api_key "$OPENAI_API_KEY_VAL" 2>/dev/null || true
hermes config set provider.model "$HERMES_MODEL_VAL" 2>/dev/null || true

echo "✅ Config written to ~/.hermes/.env"

# Start Hermes
exec hermes gateway run
