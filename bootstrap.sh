#!/bin/bash
# Bootstrap: setup provider and start hermes

CONF="/opt/data/provider.conf"

# Load config
if [ -f "$CONF" ]; then
    export $(grep -v '^#' "$CONF" | grep -v '^$' | xargs)
fi

PROVIDER="${PROVIDER_NAME:-bai-direct}"

echo "🚀 Starting with provider: $PROVIDER"

case "$PROVIDER" in
  bai)
    echo "📡 Starting B.AI proxy..."
    python3 /opt/bai_proxy.py &
    sleep 2
    OPENAI_API_KEY_VAL="not-needed"
    OPENAI_BASE_URL_VAL="http://localhost:4000/v1"
    HERMES_MODEL_VAL="${BAI_MODEL:-minimax-m3}"
    ;;
  bai-direct)
    OPENAI_API_KEY_VAL="${OPENAI_API_KEY}"
    OPENAI_BASE_URL_VAL="https://api.b.ai/v1"
    HERMES_MODEL_VAL="${HERMES_MODEL:-minimax-m3}"
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

# Write .env
mkdir -p /opt/data/.hermes
cat > /opt/data/.hermes/.env << EOF
OPENAI_API_KEY=$OPENAI_API_KEY_VAL
OPENAI_BASE_URL=$OPENAI_BASE_URL_VAL
HERMES_MODEL=$HERMES_MODEL_VAL
EOF

# Generate clean config.yaml
cat > /opt/data/config.yaml << YAML
provider:
  name: openai-api
  model: $HERMES_MODEL_VAL
  base_url: $OPENAI_BASE_URL_VAL
  api_key: $OPENAI_API_KEY_VAL
YAML

echo "✅ Config ready"

# Start Hermes
exec hermes gateway run
