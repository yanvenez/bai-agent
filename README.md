# B.AI Agent

Hermes Agent + B.AI rotating proxy (5000+ API keys).

## Features
- Auto-rotate API keys (401/429 → switch key)
- Provider switching via `provider.conf`
- Supports B.AI, MiMo, Fireworks
- Telegram bot included

## Quick Start

### Railway
1. Fork this repo
2. Deploy to Railway
3. Set `TELEGRAM_BOT_TOKEN` env var
4. Done

### Docker
```bash
docker build -t bai-agent .
docker run -e TELEGRAM_BOT_TOKEN=xxx bai-agent
```

## Switch Provider

Edit `provider.conf`:
```
PROVIDER_NAME=bai      # bai / mimo / fireworks
```

## API Key Status
Check `http://localhost:4000/health` for proxy status.

## Files
```
├── bai_proxy.py          ← Rotating proxy (5000+ keys)
├── bai_apikeys.txt       ← B.AI API keys
├── provider.conf         ← Provider config (editable)
├── bootstrap.sh          ← Startup script
├── AGENTS.md             ← Agent behavior prompt
├── Dockerfile            ← Railway/Docker build
├── docker-compose.yml    ← Local Docker setup
├── railway.toml          ← Railway config
└── requirements-proxy.txt
```
