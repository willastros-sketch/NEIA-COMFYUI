# ============================================================
#  ΝΞΙΔ COMMUNITY — RunPod Template
#  Workflow: NEIA-GERAR-VIDEOS-18 (Wan2.1 I2V +18)
#  Base: RunPod PyTorch 2.4.0 + CUDA 12.4
# ============================================================

FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

LABEL maintainer="ΝΞΙΔ Community"
LABEL description="ComfyUI + Wan2.1 I2V + NEIA workflow auto-setup"

# ── Variáveis de ambiente ───────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_DIR=/workspace/ComfyUI

# ── Dependências do sistema ─────────────────────────────────
RUN apt-get update && apt-get install -y \
    git wget curl ffmpeg aria2 \
    libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ── Copiar o script de setup ────────────────────────────────
COPY neia_runpod_setup.sh /start.sh
RUN chmod +x /start.sh

# ── Porta do ComfyUI ────────────────────────────────────────
EXPOSE 3000

# ── Entrypoint ──────────────────────────────────────────────
CMD ["/start.sh"]
