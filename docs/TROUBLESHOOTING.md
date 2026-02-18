# 🔧 Troubleshooting Guide

## Common Issues & Solutions

---

### 1. Hallucination / Weird Noise After 30-60 Seconds

**Symptoms:**
- Conversation starts normally but after 1-3 exchanges, the AI starts:
  - Making random mumbling/singing sounds
  - Generating garbled, incoherent speech
  - Producing repetitive noise patterns

**Root Cause:** The context window (`-c`) is set too low. At 12.5 FPS, a context of 512 fills up in ~41 seconds. Once full, the model loses coherence.

**Fix:** Increase the context window in `server_moshi.py`:
```python
"-c", "2500"  # For 12GB VRAM GPUs (RTX 3060, 3080, 4060 Ti)
"-c", "2000"  # For 8GB VRAM GPUs (RTX 3060 8GB, 4060)
"-c", "1500"  # For tight VRAM situations
```

---

### 2. Model Not Found Error

**Symptoms:**
```
Binary D:\...\moshi_bin\moshi-sts.exe not found
```
or model fails to load.

**Fix:**
1. Ensure `moshi_bin/` directory exists with `moshi-sts.exe` inside
2. Ensure model files exist in `models/m/`:
   - `model.gguf` (~4.7 GB)
   - `config.json`
   - `voice.gguf` (~440 KB)
3. Ensure shared models in `models/moshi-common/`:
   - `mimi-e351c8d8-125.gguf` (~330 MB)
   - `tokenizer_spm_32k_3.model` (~540 KB)

---

### 3. CUDA Error / PTX Unsupported Toolchain

**Symptoms:**
```
error: PTX was compiled by an unsupported toolchain
```

**Fix:** Update your NVIDIA GPU drivers to the latest version:
- Download from: https://www.nvidia.com/drivers
- Or use GeForce Experience to update

---

### 4. No Audio / Microphone Not Working

**Symptoms:**
- The model loads but no voice interaction happens
- You speak but the AI doesn't respond

**Fix:**
1. **List available audio devices:**
   ```bash
   moshi_bin\moshi-sts.exe -l
   ```
2. **Check Windows microphone permissions:**
   - Settings → Privacy → Microphone → Allow desktop apps to access microphone
3. **Select a specific device:** Add `-d "DeviceName"` to `CMD_ARGS` in `server_moshi.py`
4. **Test your microphone** in Windows Sound Settings to confirm it's working

---

### 5. Slow Performance / Audio Lag

**Symptoms:**
- AI responds very slowly
- Audio is choppy or distorted
- FPS is below 12.5

**Fixes:**
1. Lower context window: `-c 2000` or `-c 1500`
2. Ensure CUDA is being used (not Vulkan or CPU fallback) — check server logs
3. Close other GPU-intensive applications
4. Ensure `ggml-cuda.dll` is present in `moshi_bin/`
5. Try quantizing further: `-q q4_k -g`

---

### 6. WebSocket Connection Issues

**Symptoms:**
- Web UI shows "Connection Lost"
- Log shows "WS Closed, retrying..."

**Fix:**
1. Ensure the server is running (check terminal for errors)
2. Only one browser tab should be connected
3. Try refreshing the page
4. Check that port 8000 isn't blocked by firewall

---

### 7. Server Won't Start / Port Already in Use

**Symptoms:**
```
[Errno 10048] error while attempting to bind on address
```

**Fix:**
1. Kill any existing Python processes:
   ```bash
   taskkill /F /IM python.exe
   ```
2. Kill any existing moshi processes:
   ```bash
   taskkill /F /IM moshi-sts.exe
   ```
3. Or change the port in `server_moshi.py`:
   ```python
   uvicorn.run(app, host="127.0.0.1", port=8001)  # Use a different port
   ```

---

### 8. Missing DLL Errors

**Symptoms:**
```
The code execution cannot proceed because XXXX.dll was not found
```

**Fix:** Ensure ALL files from the moshi.cpp release zip are extracted to `moshi_bin/`. Key DLLs:
- `SDL2.dll` — Audio I/O
- `ggml-cuda.dll` — CUDA inference
- `cublas64_12.dll`, `cublasLt64_12.dll` — CUDA math
- `cudart64_12.dll` — CUDA runtime
- `moshi.dll` — Core moshi library

---

## Checking System Readiness

Run this checklist to verify everything is set up:

```bash
# 1. Check GPU is detected
moshi_bin\moshi-sts.exe -l

# 2. Check model files exist
dir models\m\
# Should show: config.json, model.gguf, voice.gguf

# 3. Check shared models
dir models\moshi-common\
# Should show: mimi-e351c8d8-125.gguf, tokenizer_spm_32k_3.model

# 4. Check Python dependencies
pip list | findstr "fastapi uvicorn"
# Should show: fastapi and uvicorn installed

# 5. Test the server
python server_moshi.py
# Should start without errors on http://127.0.0.1:8000
```

---

## Getting Help

If none of the above solves your issue:
1. Check the [moshi.cpp GitHub Issues](https://github.com/Codes4Fun/moshi.cpp/issues)
2. Check the [NVIDIA PersonaPlex repo](https://github.com/nvidia/personaplex)
3. Open an issue in this repository with:
   - Your GPU model and VRAM
   - The error message or description of behavior
   - Your `server_moshi.py` configuration (CMD_ARGS)
