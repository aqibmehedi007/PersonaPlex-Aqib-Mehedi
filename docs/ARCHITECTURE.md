# 🏗️ Architecture

## System Overview

PersonaPlex Local is a three-layer system that enables real-time voice conversation with an AI, running entirely on your local machine.

```
┌─────────────────────────────┐
│    Layer 1: Web Frontend    │  → index.html (browser UI)
├─────────────────────────────┤
│  Layer 2: Python Server     │  → server_moshi.py (FastAPI)
├─────────────────────────────┤
│  Layer 3: AI Engine         │  → moshi-sts.exe (moshi.cpp)
└─────────────────────────────┘
```

---

## Layer 1: Web Frontend (`index.html`)

A single-page web application that provides:

- **Visual feedback** — animated SVG circle that pulses when the AI is listening
- **Status display** — shows current state (Ready → Loading → Listening)
- **Start/Stop controls** — buttons to manage the conversation session
- **Live log feed** — real-time display of engine output via WebSocket

The frontend communicates with the server via:
- **HTTP POST** to `/start` and `/stop` — manages the AI engine lifecycle
- **WebSocket** at `/ws` — receives real-time status updates and engine logs

### Important: No Browser Audio
Unlike typical web-based voice AIs, **the browser does NOT handle audio**. Audio input (microphone) and output (speakers) are handled directly by the moshi-sts engine via SDL2. This means:
- No browser microphone permission needed
- No WebRTC or MediaStream API
- Audio latency is much lower (~200ms vs ~500ms+ typical)

---

## Layer 2: Python Server (`server_moshi.py`)

A FastAPI application that acts as a bridge between the web UI and the AI engine.

### Responsibilities:
1. **Serve the web UI** — serves `index.html` at the root `/` endpoint
2. **Manage subprocess** — launches/kills `moshi-sts.exe` as a child process
3. **Stream logs** — reads stdout/stderr from the engine character-by-character and broadcasts to connected WebSocket clients
4. **Heartbeat** — sends periodic status updates while the engine loads

### Key Components:
- `ConnectionManager` — manages active WebSocket connections for broadcasting
- `read_stream()` — threaded function that reads engine output byte-by-byte (to avoid buffering delays)
- `/start` endpoint — launches the moshi-sts engine with configured parameters
- `/stop` endpoint — terminates the engine process using `taskkill`

### Configuration Flow:
```python
CMD_ARGS = [
    "-m", MODEL_DIR,      # Path to model directory (models/m/)
    "-c", "2500",         # Context window (frames of conversation)
    "-v", VOICE_PATH,     # Voice embedding file
    "-g",                 # Enable GGUF caching
    "-t", "0.5",          # Temperature (creativity vs consistency)
    "--threads", "8"      # CPU threads for non-GPU work
]
```

---

## Layer 3: AI Engine (`moshi-sts.exe` from moshi.cpp)

The core speech-to-speech engine. This is a compiled C++ application from the [moshi.cpp](https://github.com/Codes4Fun/moshi.cpp) project.

### How It Works:

1. **Audio Input**: SDL2 captures microphone audio at 24kHz
2. **Audio Encoding**: The Mimi neural audio codec encodes audio into discrete tokens
3. **Transformer Inference**: PersonaPlex 7B processes both:
   - Your speech tokens (what you said)
   - Its own previous speech tokens (what it was saying)
4. **Token Generation**: The model generates response tokens in real-time at 12.5 FPS
5. **Audio Decoding**: Mimi decodes tokens back to audio waveform
6. **Audio Output**: SDL2 plays the response through your speakers

### Full-Duplex Architecture:
```
                    ┌─────────────────────┐
 Microphone ──────→ │   Mimi Encoder      │ ──→ User Audio Tokens ──┐
                    └─────────────────────┘                         │
                                                                    ▼
                                                    ┌──────────────────────┐
                                                    │   PersonaPlex 7B     │
                                                    │   Transformer        │
                                                    │   (CUDA/Vulkan)      │
                                                    └──────────┬───────────┘
                                                               │
                    ┌─────────────────────┐                    │
 Speakers ◄──────── │   Mimi Decoder      │ ◄── AI Audio Tokens┘
                    └─────────────────────┘
```

The model simultaneously processes your speech AND generates its own speech — true **full-duplex** conversation.

### Model Components:
| File | Size | Purpose |
|------|------|---------|
| `model.gguf` | ~4.7 GB | PersonaPlex 7B Q4_K quantized weights |
| `voice.gguf` | ~440 KB | Voice embedding (persona identity) |
| `mimi-e351c8d8-125.gguf` | ~330 MB | Mimi neural audio codec |
| `tokenizer_spm_32k_3.model` | ~540 KB | SentencePiece text tokenizer |

### Frame Rate:
Moshi operates at **12.5 frames per second** (80ms per frame). This means:
- The model must generate one frame of audio every 80ms
- If inference is slower than 80ms/frame, audio will lag and distort
- The context parameter (`-c`) determines how many frames of conversation history the model remembers

### Context Window Math:
```
Context 512  → 512 / 12.5  = ~41 seconds  (too short!)
Context 2000 → 2000 / 12.5 = ~160 seconds (2.5 minutes)
Context 2500 → 2500 / 12.5 = ~200 seconds (3.3 minutes)
Context 3000 → 3000 / 12.5 = ~240 seconds (4 minutes, max)
```

---

## VRAM Usage (Approximate)

| Component | VRAM |
|-----------|------|
| PersonaPlex 7B Q4_K model | ~4.0 GB |
| Mimi audio codec | ~0.3 GB |
| KV cache (context 2500) | ~1.5 GB |
| CUDA/working memory | ~0.5 GB |
| **Total** | **~6.3 GB** |

This fits comfortably within an RTX 3060's 12GB VRAM, leaving headroom for Windows and other applications.

---

## Data Flow Summary

```
User speaks → Microphone → SDL2 → Mimi Encoder → Audio Tokens
                                                      │
                                           PersonaPlex 7B Transformer
                                           (runs on GPU at 12.5 FPS)
                                                      │
                                        Response Audio Tokens
                                                      │
AI responds ← Speakers ← SDL2 ← Mimi Decoder ← ─────┘
```

All processing happens **locally on your GPU**. No data leaves your machine.
