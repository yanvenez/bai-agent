#!/bin/bash
# Bootstrap: setup provider and start hermes

CONF="/opt/data/provider.conf"
if [ -f "$CONF" ]; then
    export $(grep -v '^#' "$CONF" | grep -v '^$' | xargs)
fi

PROVIDER="${PROVIDER_NAME:-bai-direct}"
echo "🚀 Starting with provider: $PROVIDER"

case "$PROVIDER" in
  bai)
    python3 /opt/bai_proxy.py &
    sleep 2
    API_KEY_VAL="not-needed"
    BASE_URL_VAL="http://localhost:4000/v1"
    MODEL_VAL="${BAI_MODEL:-minimax-m3}"
    ;;
  bai-direct)
    API_KEY_VAL="${OPENAI_API_KEY}"
    BASE_URL_VAL="https://api.b.ai/v1"
    MODEL_VAL="${HERMES_MODEL:-minimax-m3}"
    ;;
  mimo)
    API_KEY_VAL="${MIMO_API_KEY}"
    BASE_URL_VAL="${MIMO_BASE_URL}"
    MODEL_VAL="${MIMO_MODEL:-mimo}"
    ;;
  *)
    API_KEY_VAL="${OPENAI_API_KEY}"
    BASE_URL_VAL="${OPENAI_BASE_URL}"
    MODEL_VAL="${HERMES_MODEL}"
    ;;
esac

echo "📡 Base URL: $BASE_URL_VAL"
echo "🤖 Model: $MODEL_VAL"

# Write .env
mkdir -p /opt/data/.hermes
cat > /opt/data/.hermes/.env << EOF
OPENAI_API_KEY=$API_KEY_VAL
OPENAI_BASE_URL=$BASE_URL_VAL
HERMES_MODEL=$MODEL_VAL
EOF

# Write correct config.yaml format
cat > /opt/data/config.yaml << EOF
model:
  default: $MODEL_VAL
  provider: openai-api
  base_url: $BASE_URL_VAL
  api_key: "$API_KEY_VAL"
EOF

# Unset Railway env vars that override our config
unset OPENAI_BASE_URL
unset OPENAI_API_KEY
unset HERMES_MODEL

echo "✅ Config ready"
exec hermes gateway run
