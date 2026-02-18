<p align="center">
  <h1 align="center">🎙️ PersonaPlex Local</h1>
  <p align="center">
    <strong>Real-time voice conversation AI running entirely on your local GPU</strong>
  </p>
  <p align="center">
    Built on <a href="https://github.com/nvidia/personaplex">NVIDIA PersonaPlex</a> • Powered by <a href="https://github.com/Codes4Fun/moshi.cpp">moshi.cpp</a> • Runs on consumer GPUs (8GB+ VRAM)
  </p>
</p>

---

## ✨ What Is This?

PersonaPlex Local is a **fully local, real-time voice conversation AI** — you talk, it listens and responds with natural speech, all running on your own GPU. No cloud, no API keys, no internet required after setup.

It uses:
- **[NVIDIA PersonaPlex 7B](https://huggingface.co/nvidia/personaplex-7b-v1)** — a 7-billion parameter speech-to-speech model with persona control
- **[moshi.cpp](https://github.com/Codes4Fun/moshi.cpp)** — an efficient C++/GGML port that runs these models on consumer hardware
- **Q4_K quantization** — fits in ~5GB VRAM, enabling it to run on GPUs as small as 8GB

### Key Features
- 🎤 **Full-duplex conversation** — speak naturally, it responds in real-time (~200ms latency)
- 🖥️ **Runs 100% locally** — no cloud services, no data leaves your machine
- 🎭 **Voice personas** — choose from 18 different voice options
- ⚡ **Optimized for consumer GPUs** — tested on RTX 3060 12GB
- 🌐 **Web-based UI** — clean interface accessible at `localhost:8000`

---

## 📋 Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **GPU** | 8GB VRAM (NVIDIA) | 12GB+ VRAM (RTX 3060/3080/4060+) |
| **RAM** | 8GB | 16GB+ |
| **OS** | Windows 10/11 64-bit | Windows 11 |
| **Python** | 3.9+ | 3.10+ |
| **CUDA** | 11.x+ | 12.x |
| **Disk** | ~10GB free | ~15GB free |

> **Note:** AMD GPUs can use the Vulkan backend but performance may vary.

---

## 🚀 Quick Start

### Step 1: Clone This Repository
```bash
git clone https://github.com/aqibmehedi007/PersonaPlex-Aqib-Mehedi.git
cd PersonaPlex-Aqib-Mehedi
```

### Step 2: Install Python Dependencies
```bash
pip install -r requirements.txt
```

### Step 3: Download moshi.cpp Binaries
Download the latest Windows release from [moshi.cpp Releases](https://github.com/Codes4Fun/moshi.cpp/releases):

1. Download `moshi-bin-win-x64-v0.7.0-beta.zip` (or latest version)
2. Extract the zip file
3. Rename/move the extracted folder to `moshi_bin/` inside this project:
```
PersonaPlex-Aqib-Mehedi/
├── moshi_bin/          ← extracted moshi.cpp binaries go here
│   ├── moshi-sts.exe
│   ├── SDL2.dll
│   ├── ggml-cuda.dll
│   └── ... (other DLLs and tools)
```

### Step 4: Download the PersonaPlex Model
Using the `aria2c` tool included in `moshi_bin/`:

```bash
cd moshi_bin
.\aria2c --disable-ipv6 -i Codes4Fun_personaplex-7b-v1-q4_k-GGUF.txt
cd ..
```

This downloads ~5GB of model files into `moshi_bin/Codes4Fun/personaplex-7b-v1-q4_k-GGUF/`.

Now move/copy the model files to the expected directory structure:
```bash
# Create model directories
mkdir models\m
mkdir models\moshi-common

# Copy model files
copy moshi_bin\Codes4Fun\personaplex-7b-v1-q4_k-GGUF\model-q4_k.gguf models\m\model.gguf
copy moshi_bin\Codes4Fun\moshi-common\mimi-e351c8d8-125.gguf models\moshi-common\
copy moshi_bin\Codes4Fun\moshi-common\tokenizer_spm_32k_3.model models\moshi-common\
```

> **Voice File:** The `voice.gguf` is included in the PersonaPlex model download. Copy it to `models/m/voice.gguf`. If not present, the model will use a default voice.

### Step 5: Verify Model Config
Make sure `models/m/config.json` exists with the correct paths. A template is provided in `configs/model_config.json`.

### Step 6: Run!
```bash
python server_moshi.py
```

Open your browser to **http://127.0.0.1:8000** and click **"Start Conversation"**!

Or use the batch file:
```bash
start_moshi.bat
```

---

## 📁 Project Structure

```
PersonaPlex-Aqib-Mehedi/
├── server_moshi.py        # Main server - launches moshi-sts and serves web UI
├── index.html             # Web interface with visualizer
├── start_moshi.bat        # Quick launcher script
├── requirements.txt       # Python dependencies
├── configs/               # Configuration templates
│   └── model_config.json  # Model config template (copy to models/m/config.json)
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md    # How it works under the hood
│   ├── OPTIMIZATION.md    # GPU tuning and performance guide
│   └── TROUBLESHOOTING.md # Common issues and fixes
├── models/                # Model files (downloaded separately, git-ignored)
│   ├── m/                 # Active model directory
│   │   ├── config.json
│   │   ├── model.gguf     # PersonaPlex 7B Q4_K (~4.7GB)
│   │   └── voice.gguf     # Voice embedding
│   └── moshi-common/      # Shared tokenizer & audio codec
│       ├── mimi-e351c8d8-125.gguf
│       └── tokenizer_spm_32k_3.model
└── moshi_bin/             # moshi.cpp binaries (downloaded separately, git-ignored)
    ├── moshi-sts.exe      # Speech-to-Speech engine
    └── ... (DLLs, tools)
```

---

## ⚙️ Configuration

### Key Parameters in `server_moshi.py`

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-c` (context) | `2500` | Context window size. Higher = longer conversations. Use `2000` for 8GB GPUs, `2500-3000` for 12GB+ |
| `-t` (temperature) | `0.5` | Controls speech creativity. Lower = more consistent, higher = more natural variety |
| `-g` (GGUF caching) | enabled | Caches model in GGUF format for faster loading (~4 sec vs ~30 sec) |
| `--threads` | `8` | CPU threads for mixed CPU/GPU workload |

### Voice Options
PersonaPlex supports 18 different voice personas. Pass a voice name with `-v`:

| Natural Voices | Variable Voices |
|---------------|-----------------|
| NATF0, NATF1, NATF2, NATF3 (Female) | VARF0-VARF4 (Female) |
| NATM0, NATM1, NATM2, NATM3 (Male) | VARM0-VARM4 (Male) |

You can also use a custom voice file: `-v path/to/voice.gguf`

---

## 🔧 Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| **Hallucination / weird noise after 30-60 seconds** | Context window too small | Increase `-c` value (use 2000-3000) |
| **Garbled mumbling sounds** | Context overflow | Same as above — increase `-c` |
| **Model not found error** | Wrong model path | Check `models/m/` has `model.gguf` and `config.json` |
| **CUDA error / PTX unsupported** | Outdated GPU drivers | Update NVIDIA drivers to latest |
| **No audio input/output** | SDL2 can't find devices | Run `moshi_bin\moshi-sts.exe -l` to list devices |
| **Slow performance (<12.5 FPS)** | GPU VRAM pressure | Lower `-c` to 1500-2000, or use `-q q4_k` |
| **Process won't start** | Missing DLLs | Ensure all DLLs from moshi.cpp release are in `moshi_bin/` |

> For more details, see [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 🏗️ How It Works

```
┌──────────────────────────────────────────────────────┐
│                    Web Browser                        │
│              http://localhost:8000                     │
│    ┌──────────────────────────────────┐               │
│    │     PersonaPlex Web UI           │               │
│    │   (index.html + WebSocket)       │               │
│    └──────────────┬───────────────────┘               │
└───────────────────┼──────────────────────────────────┘
                    │ WebSocket (status/logs)
                    ▼
┌──────────────────────────────────────────────────────┐
│              server_moshi.py (FastAPI)                 │
│    - Serves web UI                                    │
│    - Manages moshi-sts subprocess                     │
│    - Streams stdout/stderr to browser via WebSocket   │
└───────────────────┬──────────────────────────────────┘
                    │ subprocess (stdin/stdout/stderr)
                    ▼
┌──────────────────────────────────────────────────────┐
│           moshi-sts.exe (moshi.cpp)                   │
│    - Loads PersonaPlex 7B Q4_K model                  │
│    - Processes audio via SDL2 (mic → AI → speakers)   │
│    - Runs inference on GPU (CUDA/Vulkan)              │
│    - Operates at 12.5 FPS (80ms per frame)            │
└──────────────────────────────────────────────────────┘
```

> For deep-dive architecture details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## 🛣️ Roadmap / Future Improvements

- [ ] **System text prompts** — define AI personality via text instructions
- [ ] **Voice cloning from audio** — use your own voice recordings as persona
- [ ] **Multi-turn memory** — persist conversation context across sessions
- [ ] **Linux support** — cross-platform launcher
- [ ] **Docker container** — one-command deployment
- [ ] **WebRTC integration** — browser-based audio instead of SDL2
- [ ] **Fine-tuned personas** — custom personality training

---

## 🙏 Credits & Acknowledgments

- **[Kyutai Labs](https://github.com/kyutai-labs/moshi)** — Original Moshi speech-to-speech model
- **[NVIDIA PersonaPlex](https://github.com/nvidia/personaplex)** — Persona-controllable extension of Moshi
- **[Codes4Fun/moshi.cpp](https://github.com/Codes4Fun/moshi.cpp)** — C++/GGML port enabling local execution on consumer GPUs
- **[GGML](https://github.com/ggerganov/ggml)** — Tensor library powering efficient inference

---

## 📄 License

This project is a wrapper/launcher for PersonaPlex and moshi.cpp. Please refer to the respective licenses:
- [moshi.cpp License](https://github.com/Codes4Fun/moshi.cpp/blob/main/LICENSE)
- [PersonaPlex License](https://github.com/nvidia/personaplex)
- [Moshi License](https://github.com/kyutai-labs/moshi)

---

<p align="center">
  <strong>Built with ❤️ by <a href="https://github.com/aqibmehedi007">Aqib Mehedi</a></strong>
</p>
