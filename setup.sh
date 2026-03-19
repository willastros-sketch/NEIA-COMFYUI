#!/usr/bin/env bash
set -e

echo "[init] 🚀 NEIA-GERAR-VIDEOS-18 Complete Setup..."

WORKSPACE="${WORKSPACE:-/workspace}"
COMFY_DIR="${WORKSPACE}/ComfyUI"
MODELS_DIR="${COMFY_DIR}/models"

# Dirs padrão ComfyUI
mkdir -p "${MODELS_DIR}/"{checkpoints,loras,vae,controlnet,clip,text_encoder,animatediff_models}
mkdir -p "${COMFY_DIR}/workflows"

# Workflow
curl -fsSL "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA-GERAR-VIDEOS-18.json" \
  -o "${COMFY_DIR}/workflows/NEIA-GERAR-VIDEOS-18.json"

cd "${COMFY_DIR}/custom_nodes"

# === CUSTOM NODES OBRIGATÓRIOS (do seu workflow) ===
declare -a REQUIRED_NODES=(
  "Kosinkadink/ComfyUI-VideoHelperSuite.git"           # VHS_VideoCombine, LoadAudio
  "Kosinkadink/ComfyUI-AnimateDiff-Evolved.git"        # AnimateDiff (caso use)
  "Fannovel16/comfyui_controlnet_aux.git"              # ControlNet auxiliares
  "comfyanonymous/ComfyUI-Manager.git"                 # Model manager
  "rgthree/rgthree-comfy.git"                          # Fast Bypasser
  "yolanother/ComfyUI-Easy-Use.git"                    # easy int, easy showAnything
  "s9roll/ComfyUI-SimpleMath.git"                      # SimpleMath+
  "OnDemandLoRA/ComfyUI-OnDemandLoRA.git"              # OnDemand Lora Loader
  "pysssss/ComfyUI_pysssss.git"                        # MathExpression|pysssss
  "city96/ComfyUI-Model-Sampling.git"                  # ModelSamplingSD3
)

for NODE in "${REQUIRED_NODES[@]}"; do
  REPO_NAME=$(basename "$NODE" .git)
  if [ ! -d "$REPO_NAME" ]; then
    echo "[nodes] git clone $NODE"
    git clone -q "https://github.com/$NODE"
  fi
done

# Requirements (tolerante)
find . -name "requirements.txt" -maxdepth 2 | while read req; do
  pip install -q --no-cache-dir -r "$req" || echo "[warn] pip $req"
done

# === MODELOS BASE SD3 (compatível com ModelSamplingSD3) ===
cd "$MODELS_DIR/checkpoints"
echo "[models] SD3 base models..."

# SD3.5 Medium (recomendado pra workflows modernos)
wget -qnc --limit-rate=50m \
  "https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors" || \
  echo "[warn] SD3.5 medium"

cd ../vae
wget -qnc --limit-rate=50m \
  "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors" || \
  echo "[warn] VAE"

# === AUTOLOAD WORKFLOW ===
cat > "${COMFY_DIR}/autoload_neia.sh" << 'EOF'
#!/bin/bash
sleep 15
for i in {1..30}; do
  nc -z 127.0.0.1 8188 2>/dev/null && break || sleep 2
done
curl -fsS -X POST "http://127.0.0.1:8188/prompt" \
  -H "Content-Type: application/json" \
  --data-binary "@/workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json" >/dev/null 2>&1 || true
EOF

chmod +x "${COMFY_DIR}/autoload_neia.sh"

cat > /etc/supervisor/conf.d/neia-autoload.conf << EOF
[program:neia-autoload]
command=bash -c "sleep 25 && /workspace/ComfyUI/autoload_neia.sh"
autostart=true
priority=999
stderr_logfile=/var/log/neia.err
stdout_logfile=/var/log/neia.out
EOF

supervisorctl reread && supervisorctl update

echo "✅ NEIA-GERAR-VIDEOS-18 pronto! Porta 8188 + todos custom nodes."
echo "📁 Workflow: /workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json"
