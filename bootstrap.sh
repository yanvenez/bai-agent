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

# Write config.yaml
cat > /opt/data/config.yaml << EOF
model:
  default: $MODEL_VAL
  provider: openai-api
  base_url: $BASE_URL_VAL
  api_key: "$API_KEY_VAL"
EOF

# Force override ALL env vars (nuclear option)
# Docker/s6 env vars persist, so we must override them explicitly
export OPENAI_BASE_URL="$BASE_URL_VAL"
export OPENAI_API_KEY="$API_KEY_VAL"
export HERMES_MODEL="$MODEL_VAL"

# Also set via hermes CLI (writes to config directly)
HERMES_BIN="/opt/hermes/.venv/bin/hermes"
if [ -x "$HERMES_BIN" ]; then
    $HERMES_BIN config set model.base_url "$BASE_URL_VAL" 2>/dev/null
    $HERMES_BIN config set model.api_key "$API_KEY_VAL" 2>/dev/null
    $HERMES_BIN config set model.default "$MODEL_VAL" 2>/dev/null
    $HERMES_BIN config set model.provider openai-api 2>/dev/null
fi

echo "✅ Config ready"
echo "🔑 OPENAI_BASE_URL=$OPENAI_BASE_URL"

exec /opt/hermes/.venv/bin/hermes gateway run
