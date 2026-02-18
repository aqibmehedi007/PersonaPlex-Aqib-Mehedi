# ⚡ Optimization Guide

## GPU-Specific Settings

### RTX 3060 (12GB) — Recommended Settings
```python
CMD_ARGS = [
    "-c", "2500",       # Generous context, fits easily in 12GB
    "-t", "0.5",        # Balanced temperature
    "-g",               # GGUF caching (4s load vs 30s)
    "--threads", "8"    # Good for most systems
]
```

### RTX 3060 Ti / RTX 4060 (8GB)
```python
CMD_ARGS = [
    "-c", "2000",       # Reduced context to save VRAM
    "-t", "0.5",
    "-g",
    "--threads", "8"
]
```

### RTX 3070/3080/4070+ (12GB+)
```python
CMD_ARGS = [
    "-c", "3000",       # Maximum context
    "-t", "0.6",        # Can afford slightly more creativity
    "-g",
    "--threads", "8"
]
```

### GTX 1080 Ti / RTX 2070 (8GB) — Minimum Viable
```python
CMD_ARGS = [
    "-c", "1500",       # Lower context to fit in VRAM
    "-t", "0.4",        # Keep it stable
    "-g",
    "--threads", "6"
]
```

---

## Parameter Deep Dive

### Context Window (`-c`)

The most critical parameter for conversation quality.

| Value | Conversation Time | VRAM Impact | Use Case |
|-------|------------------|-------------|----------|
| 512 | ~41 seconds | Very low | ❌ Too short, causes hallucination |
| 1000 | ~80 seconds | Low | Minimum for basic testing |
| 1500 | ~2 minutes | Medium | Budget GPUs (8GB) |
| 2000 | ~2.5 minutes | Medium-High | Recommended for 8GB GPUs |
| 2500 | ~3.3 minutes | High | **Recommended for 12GB GPUs** |
| 3000 | ~4 minutes | Maximum | Max context, for 12GB+ GPUs |

> **Rule of thumb**: Higher context = longer coherent conversations, but more VRAM usage. Going above 3000 does NOT improve things (it's the model's max).

### Temperature (`-t`)

Controls how "creative" vs "consistent" the AI's responses are.

| Value | Behavior | Best For |
|-------|----------|----------|
| 0.1 | Very deterministic, robotic | Testing/debugging |
| 0.2-0.3 | Consistent but somewhat flat | Repetitive tasks |
| **0.4-0.6** | **Natural, balanced** | **Normal conversation** |
| 0.7-0.8 | Varied, more expressive | Creative interactions |
| 0.9-1.0 | Highly creative, may hallucinate | Experimental |

### CPU Threads (`--threads`)

Used for workloads that aren't on the GPU (tokenization, audio processing).

| CPU Cores | Recommended `--threads` |
|-----------|------------------------|
| 4 cores | 4 |
| 6 cores | 6 |
| 8+ cores | 8 |
| 12+ cores | 8-10 (diminishing returns) |

> **Note**: Setting threads too high can cause contention and actually slow things down.

### GGUF Caching (`-g`)

Always enable this. It converts the model to GGUF format on first run (takes a few extra seconds once) and then loads in ~4 seconds on subsequent runs instead of ~30 seconds.

---

## Performance Monitoring

### Check FPS During Conversation
The moshi-sts engine outputs frame timing information. Watch the server console for FPS metrics. You need **12.5 FPS or higher** for real-time conversation.

### Monitor VRAM Usage
```bash
# Open a PowerShell window while running
nvidia-smi -l 1
```

Look for:
- **Memory usage** — should be under your GPU's max (e.g., under 12GB for RTX 3060)
- **GPU utilization** — should be 50-90% during conversation
- **Temperature** — should stay under 85°C

### If Performance Is Low (<12.5 FPS)
1. **Lower context**: `-c 2000` → `-c 1500`
2. **Close other GPU apps** (games, video editing, other AI models)
3. **Ensure CUDA backend is active** (not Vulkan) — check server logs for `using device: "CUDA0"`
4. **Update drivers**: Latest NVIDIA drivers often improve inference performance

---

## Quantization Options

The PersonaPlex model can be quantized at different levels. The Q4_K quantization is pre-built, but you can experiment:

| Quantization | Model Size | VRAM | Quality | Speed |
|-------------|-----------|------|---------|-------|
| FP16 | ~14 GB | 16+ GB | Best | Slowest |
| Q8_0 | ~7.5 GB | 10+ GB | Very Good | Good |
| **Q4_K** | **~4.7 GB** | **8+ GB** | **Good** | **Fast** |
| Q4_0 | ~4.0 GB | 8+ GB | Acceptable | Fastest |

To quantize a model yourself:
```bash
moshi_bin\moshi-sts.exe -m <model_path> -q q4_k -g
```

---

## Audio Quality Tips

1. **Use a good microphone** — background noise confuses the model
2. **Speak clearly** — the model works best with clear, moderate-paced speech
3. **Minimize echo** — use headphones to prevent the AI's output from being picked back up by the mic
4. **Quiet environment** — fewer ambient sounds = better recognition
5. **Check audio device** — list devices with `moshi_bin\moshi-sts.exe -l` and select the right one with `-d "DeviceName"`
