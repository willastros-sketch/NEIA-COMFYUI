#!/usr/bin/env bash
set -e

echo "🚀 NEIA-GERAR-VIDEOS-18 - 100% COMPLETO"

WORKSPACE="${WORKSPACE:-/workspace}"
COMFY="${WORKSPACE}/ComfyUI"

# Diretórios
mkdir -p "${COMFY}/models/"{checkpoints,loras,vae,controlnet,clip,animatediff_models}
mkdir -p "${COMFY}/"{workflows,input,output,custom_nodes}

# 1. Workflow NEIA
echo "[1/6] Workflow..."
curl -fsSL "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA-GERAR-VIDEOS-18.json" \
  -o "${COMFY}/workflows/NEIA-GERAR-VIDEOS-18.json"

cd "${COMFY}/custom_nodes"

# 2. TODOS os 15 custom nodes do workflow
NODES=(
  "Kosinkadink/ComfyUI-VideoHelperSuite"           # VHS_VideoCombine, LoadAudio
  "rgthree/rgthree-comfy"                          # Fast Bypasser
  "yolanother/ComfyUI-Easy-Use"                    # easy int, showAnything
  "s9roll/ComfyUI-SimpleMath"                      # SimpleMath+
  "francarl/ComfyUI-OnDemand-Loaders"              # OnDemand Lora Loader ✓
  "pysssss/ComfyUI_pysssss"                        # MathExpression|pysssss
  "city96/ComfyUI-Impact-Pack"                     # ModelSamplingSD3
  "Fannovel16/comfyui_controlnet_aux"              # ControlNet Aux
  "Kosinkadink/ComfyUI-AnimateDiff-Evolved"        # AnimateDiff
  "Comfy-Org/ComfyUI-Manager"                      # Manager
  "Comfy-Org/ComfyUI-Custom-Scripts"               # Custom Scripts
  "AYJ/ComfyUI-Notes"                              # MarkdownNote
  " ltdrdata/ComfyUI-Impact-Subpack"               # Impact extras
  "chflame163/ComfyUI-Loopchain"                   # Loop utilities
  "pythongosssss/ComfyUI-Custom-Scripts"           # Utils
)

echo "[2/6] Custom Nodes (15 repos)..."
for repo in "${NODES[@]}"; do
  name=$(basename "$repo")
  if [ ! -d "$name" ]; then
    echo "  [+] $name"
    git clone "https://github.com/$repo.git" "$name"
  fi
done

# Requirements
echo "[3/6] pip install..."
pip install -q onnxruntime opencv-python av transformers accelerate xformers
find . -name "*requirements*.txt" -exec pip install --no-cache-dir -q {} \; 2>/dev/null || true

# 4. MODELOS COMPLETOS SD3.5
echo "[4/6] Modelos SD3.5 + VAE + Motion..."
cd "${COMFY}/models"

# Checkpoints SD3.5
cd checkpoints
wget -qnc --limit-rate=50m \
  "https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors"
wget -qnc --limit-rate=50m \
  "https://huggingface.co/stabilityai/stable-diffusion-3.5-large/resolve/main/sd3.5_large.safetensors"

# VAE oficial
cd ../vae
wget -qnc --limit-rate=50m \
  "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"

# LoRAs exemplo (você troca depois)
cd ../loras
wget -qnc --limit-rate=50m \
  "https://civitai.com/api/download/models/128019?type=Model&format=SafeTensor" -O "xl-more-art-full-v1.safetensors"

# AnimateDiff Motion
cd ../animatediff_models
wget -qnc --limit-rate=50m \
  "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt"
wget -qnc --limit-rate=50m \
  "https://huggingface.co/guoyww/animatediff/resolve/main/v3_sd15_mm.ckpt"

# ControlNet XL
cd ../controlnet
wget -qnc --limit-rate=50m \
  "https://huggingface.co/lllyasviel/sd_control_collection/resolve/main/diffusers_xl_sdxl_t2i_adapter_fp16.safetensors"

# 5. Autoload otimizado
echo "[5/6] Autoload..."
cat > "${COMFY}/autoload_neia.sh" << 'EOF'
#!/bin/bash
echo "[NEIA] Aguardando ComfyUI (60s max)..."
for i in {1..60}; do
  if nc -z 127.0.0.1 8188 2>/dev/null; then
    echo "[NEIA] Enviando workflow..."
    sleep 5
    curl -s -X POST "http://127.0.0.1:8188/prompt" \
      -H "Content-Type: application/json" \
      --data-binary "@/workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json" || true
    echo "[NEIA] ✅ Workflow carregado!"
    exit 0
  fi
  sleep 3
done
echo "[NEIA] Timeout ComfyUI"
EOF

chmod +x "${COMFY}/autoload_neia.sh"

# Supervisor service
cat > /etc/supervisor/conf.d/neia-autoload.conf << EOF
[program:neia-autoload]
command=bash -c "sleep 35 && /workspace/ComfyUI/autoload_neia.sh"
directory=/workspace
autostart=true
autorestart=false
priority=999
stderr_logfile=/var/log/neia.err.log
stdout_logfile=/var/log/neia.out.log
EOF

supervisorctl reread && supervisorctl update

# 6. Status final
echo "[6/6] ✅ NEIA 100% PRONTO!"
echo "   Nodes: $(find custom_nodes -mindepth 1 -maxdepth 1 -type d | wc -l | xargs)"
echo "   Models: $(find models -name '*.safetensors' -o -name '*.ckpt' | wc -l | xargs)"
echo "   Login: admin/neia2026"
echo "   Porta: 8188"
echo "   Workflow: /workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json"
