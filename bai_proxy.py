#!/usr/bin/env python3
"""BAI API Key Rotating Proxy — auto-switches keys on 401/429."""
import os, time, threading, itertools
from fastapi import FastAPI, Request, Response
from fastapi.responses import StreamingResponse
import httpx, uvicorn

# === CONFIG ===
KEYS_FILE = os.environ.get("BAI_KEYS_FILE", "bai_apikeys.txt")
BAI_BASE = os.environ.get("BAI_BASE_URL", "https://api.b.ai/v1")
PORT = int(os.environ.get("PROXY_PORT", "4000"))
# === END CONFIG ===

app = FastAPI(title="BAI Key Rotator")

class KeyRotator:
    def __init__(self, keys_file):
        self.keys = []
        self.lock = threading.Lock()
        self.current_idx = 0
        self.disabled = {}  # key -> disabled_until_timestamp
        self.stats = {"total": 0, "rotated": 0, "errors": 0}
        self._load_keys(keys_file)
    
    def _load_keys(self, path):
        if not os.path.exists(path):
            print(f"[!] Keys file not found: {path}")
            return
        with open(path) as f:
            self.keys = [line.strip() for line in f if line.strip() and line.strip().startswith("sk-")]
        print(f"[+] Loaded {len(self.keys)} API keys")
    
    def get_key(self):
        """Get next available key, skipping disabled ones."""
        with self.lock:
            now = time.time()
            # Re-enable keys that passed cooldown
            self.disabled = {k: v for k, v in self.disabled.items() if v > now}
            
            available = [k for k in self.keys if k not in self.disabled]
            if not available:
                # All disabled — reset oldest
                if self.disabled:
                    oldest = min(self.disabled, key=self.disabled.get)
                    del self.disabled[oldest]
                    available = [oldest]
                else:
                    return None
            
            # Round-robin through available
            key = available[self.current_idx % len(available)]
            self.current_idx = (self.current_idx + 1) % len(available)
            self.stats["total"] += 1
            return key
    
    def disable_key(self, key, seconds=300):
        """Temporarily disable a key."""
        with self.lock:
            self.disabled[key] = time.time() + seconds
            self.stats["rotated"] += 1
            masked = f"{key[:10]}...{key[-4:]}" if len(key) > 14 else key
            print(f"[!] Disabled key {masked} for {seconds}s ({len(self.disabled)} disabled now)")
    
    def status(self):
        with self.lock:
            return {
                "total_keys": len(self.keys),
                "available": len(self.keys) - len(self.disabled),
                "disabled": len(self.disabled),
                "requests_served": self.stats["total"],
                "rotations": self.stats["rotated"],
            }

rotator = KeyRotator(KEYS_FILE)

@app.get("/health")
async def health():
    return {"status": "ok", **rotator.status()}

@app.get("/status")
async def status():
    return rotator.status()

@app.api_route("/{path:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"])
async def proxy(request: Request, path: str):
    """Forward request to B.AI with auto-rotating API key."""
    max_retries = 3
    
    for attempt in range(max_retries):
        key = rotator.get_key()
        if not key:
            return Response(content='{"error":"no keys available"}', status_code=503)
        
        # Build headers
        headers = {}
        for h in ["content-type", "accept", "accept-language", "user-agent"]:
            if h in request.headers:
                headers[h] = request.headers[h]
        headers["Authorization"] = f"Bearer {key}"
        
        # Get body
        body = await request.body()
        
        # Forward to B.AI
        url = f"{BAI_BASE}/{path}"
        try:
            async with httpx.AsyncClient(timeout=120.0) as client:
                if request.method == "GET":
                    resp = await client.get(url, headers=headers, params=dict(request.query_params))
                else:
                    resp = await client.post(url, headers=headers, content=body)
            
            # If 401/429 — key bad, rotate and retry
            if resp.status_code in (401, 429):
                rotator.disable_key(key, seconds=600 if resp.status_code == 401 else 60)
                rotator.stats["errors"] += 1
                print(f"[{attempt+1}/{max_retries}] Key failed ({resp.status_code}), rotating...")
                continue
            
            # Streaming response
            if "text/event-stream" in resp.headers.get("content-type", ""):
                async def stream():
                    async with httpx.AsyncClient(timeout=120.0) as client:
                        async with client.stream("POST" if body else "GET", url, headers=headers, content=body or None, params=dict(request.query_params) if not body else None) as r:
                            async for chunk in r.aiter_bytes():
                                yield chunk
                return StreamingResponse(stream(), media_type="text/event-stream")
            
            return Response(
                content=resp.content,
                status_code=resp.status_code,
                headers={k: v for k, v in resp.headers.items() if k.lower() in ("content-type", "x-request-id")},
            )
        except Exception as e:
            rotator.stats["errors"] += 1
            if attempt < max_retries - 1:
                continue
            return Response(content=f'{{"error":"proxy error: {e}"}}', status_code=502)
    
    return Response(content='{"error":"all keys exhausted"}', status_code=503)

if __name__ == "__main__":
    print(f"🚀 BAI Key Rotator Proxy")
    print(f"📡 BAI Base: {BAI_BASE}")
    print(f"🔑 Keys: {len(rotator.keys)}")
    print(f"🌐 Port: {PORT}")
    uvicorn.run(app, host="0.0.0.0", port=PORT)
