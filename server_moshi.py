import asyncio
import subprocess
import threading
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
import uvicorn
import os
import sys

# Configuration
MOSHI_BIN = os.path.abspath(os.path.join("moshi_bin", "moshi-sts.exe"))
MODEL_ROOT = os.path.abspath("models").replace("\\", "/")
MODEL_DIR = os.path.abspath(os.path.join("models", "m")).replace("\\", "/")
VOICE_PATH = os.path.abspath(os.path.join("models", "m", "voice.gguf")).replace("\\", "/")

# Performance Tuning: Target 12.5 FPS for stable interaction.
# CRITICAL: -t is TEMPERATURE in moshi-sts. Use --threads for CPU allocation.
# FIX: Context 512 was WAY too low — fills up in ~40 seconds causing hallucination/noise.
# RTX 3060 12GB VRAM can handle context 2500 easily with q4_k quantization.
# Moshi default is 3000, moshi.cpp recommends 2000 for 8GB cards.
CMD_ARGS = [
    "-m", MODEL_DIR.replace("/", "\\"), 
    "-c", "2500",           # Context window: 2500 for RTX 3060 12GB (was 512 — caused hallucination!)
    "-v", VOICE_PATH.replace("/", "\\"), 
    "-g",                   # GGUF caching for fast loading
    "-t", "0.5",            # Temperature: balanced natural speech (0.2 was too robotic, 0.8 default too creative)
    "--threads", "8"        # CPU threads for mixed CPU/GPU workload
] 
app = FastAPI()
process = None

@app.get("/", response_class=HTMLResponse)
async def read_root():
    with open("index.html", "r") as f:
        return f.read()

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        stale = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception:
                stale.append(connection)
        for s in stale:
            if s in self.active_connections:
                self.active_connections.remove(s)

manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text() # Keep connection alive
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    finally:
        print("WebSocket closed")

def read_stream(stream, prefix):
    """Reads stream character-by-character to avoid newline blocking."""
    buffer = ""
    while True:
        char = stream.read(1)
        if not char:
            break
        char_str = char.decode('utf-8', errors='replace')
        buffer += char_str
        
        # Broadcast immediately if we see a newline or specific keywords
        if char_str == '\n' or len(buffer) > 100:
            msg = buffer.strip()
            if msg:
                print(f"[{prefix}] {msg}")
                asyncio.run_coroutine_threadsafe(manager.broadcast(f"[{prefix}] {msg}"), loop)
            buffer = ""
        elif "loading..." in buffer.lower() or "done loading" in buffer.lower():
            asyncio.run_coroutine_threadsafe(manager.broadcast(f"[{prefix}] {buffer.strip()}"), loop)
            # Don't clear buffer yet, let the newline handle it or it might repeat
    
loop = None

async def heartbeat():
    """Sends a periodic status update to the UI while Moshi is loading."""
    while process and process.poll() is None:
        await manager.broadcast("HEARTBEAT: Moshi engine is active...")
        await asyncio.sleep(5)

@app.post("/start")
async def start_bot():
    global process
    if process and process.poll() is None:
        return {"status": "already_running"}
    
    # Verify binary exists
    if not os.path.exists(MOSHI_BIN):
         return {"error": f"Binary {MOSHI_BIN} not found"}
    
    cmd = [MOSHI_BIN] + CMD_ARGS

    print(f"Starting: {' '.join(cmd)}")
    # Use bufsize=0 (unbuffered)
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0
    )
    
    # Start threads to read output
    t_out = threading.Thread(target=read_stream, args=(process.stdout, "OUT"))
    t_err = threading.Thread(target=read_stream, args=(process.stderr, "ERR"))
    t_out.daemon = True
    t_err.daemon = True
    t_out.start()
    t_err.start()

    # Start the async heartbeat
    asyncio.create_task(heartbeat())
    
    return {"status": "started"}

@app.post("/stop")
async def stop_bot():
    global process
    if process:
        try:
            # On Windows, taskkill is more reliable for tree termination
            subprocess.run(["taskkill", "/F", "/T", "/PID", str(process.pid)], capture_output=True)
        except Exception as e:
            print(f"Error killing process: {e}")
        process = None
    return {"status": "stopped"}

@app.on_event("startup")
async def startup_event():
    global loop
    loop = asyncio.get_event_loop()

@app.on_event("shutdown")
def shutdown_event():
    if process:
        try:
             subprocess.run(["taskkill", "/F", "/T", "/PID", str(process.pid)], capture_output=True)
        except:
             pass

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
