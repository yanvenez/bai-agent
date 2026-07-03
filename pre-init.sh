#!/bin/bash
# Run BEFORE gateway starts — s6 init script
# Writes config so gateway picks it up on startup

CONF="/opt/data/provider.conf"
if [ -f "$CONF" ]; then
    export $(grep -v '^#' "$CONF" | grep -v '^$' | xargs)
fi

# Use env vars set by Railway
BASE_URL="${OPENAI_BASE_URL:-https://api.b.ai/v1}"
API_KEY="${OPENAI_API_KEY}"
MODEL="${HERMES_MODEL:-minimax-m3}"

# Write .env
mkdir -p /opt/data/.hermes
cat > /opt/data/.hermes/.env << EOF
OPENAI_API_KEY=$API_KEY
OPENAI_BASE_URL=$BASE_URL
HERMES_MODEL=$MODEL
EOF

# Write config.yaml
cat > /opt/data/config.yaml << EOF
model:
  provider: openai-api
  name: $MODEL
  base_url: $BASE_URL
  api_key: "$API_KEY"
EOF

echo "[pre-init] Config written: model=$MODEL base=$BASE_URL"
