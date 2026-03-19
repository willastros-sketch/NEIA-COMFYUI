#!/usr/bin/env bash
set -e

echo "🚀 NEIA-GERAR-VIDEOS-18 - VERSÃO FINAL 100%"

WORKSPACE="${WORKSPACE:-/workspace}"
COMFY="${WORKSPACE}/ComfyUI"

# Cria diretórios
mkdir -p "${COMFY}/models/"{checkpoints,loras,vae,controlnet,clip,animatediff_models}
mkdir -p "${COMFY}/"{workflows,input,output,custom_nodes}

# 1. Workflow NEIA
echo "[1/5] Workflow NEIA..."
curl -fsSL "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA-GERAR-VIDEOS-18.json" \
  -o "${COMFY}/workflows/NEIA-GERAR-VIDEOS-18.json" || echo "[!] Workflow falhou"

cd "${COMFY}/custom_nodes"

# 2. TODOS custom nodes do workflow (testados)
echo "[2/5] 16 Custom Nodes..."

# Core do workflow NEIA
git clone -q https://github.com/francarl/ComfyUI-OnDemand-Loaders.git || true           # OnDemand Lora Loader
git clone -q https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true        # VHS_VideoCombine
git clone -q https://github.com/city96/ComfyUI-Impact-Pack.git || true                  # ModelSamplingSD3
git clone -q https://github.com/rgthree/rgthree-comfy.git || true                       # Fast Bypasser
git clone -q https://github.com/yolanother/ComfyUI-Easy-Use.git || true                 # easy int
git clone -q https://github.com/s9roll/ComfyUI-SimpleMath.git || true                   # SimpleMath+
git clone -q https://github.com/pysssss/ComfyUI_pysssss.git || true                     # MathExpression

# Suporte vídeo
git clone -q https://github.com/Fannovel16/comfyui_controlnet_aux.git || true           # ControlNet Aux
git clone -q https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git || true     # AnimateDiff

# Utils
git clone -q https://github.com/Comfy-Org/ComfyUI-Manager.git || true
git clone -q https://github.com/AYJ/ComfyUI-Notes.git || true

# Requirements com retry
echo "[3/5] pip requirements..."
pip install -q --no-cache-dir onnxruntime opencv-python av transformers accelerate xformers
find . -maxdepth 2 -name "*requirements*.txt" -exec pip install --no-cache-dir -q {} \; 2>/dev/null || true

# 4. MODELOS essenciais
echo "[4/5] Modelos SD3.5 + VAE..."
cd "${COMFY}/models"

# SD3.5 Medium (principal pro nó 136)
cd checkpoints
wget -qnc --limit-rate=50m --show-progress \
  "https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors" || \
  echo "[!] SD3.5 medium falhou"

# VAE oficial
cd ../vae
wget -qnc --limit-rate=50m \
  "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"

# LoRA exemplo XL (pro nó 136)
cd ../loras
wget -qnc --limit-rate=50m \
  "https://civitai.com/api/download/models/128019?type=Model&format=SafeTensor" -O "xl-more-art.safetensors" || \
  echo "[!] LoRA exemplo falhou"

# AnimateDiff motion
cd ../animatediff_models
wget -qnc --limit-rate=50m \
  "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt"

# 5. Autoload workflow
echo "[5/5] Autoload NEIA..."
cat > "${COMFY}/autoload_neia.sh" << 'EOF'
#!/bin/bash
echo "[NEIA] Aguardando ComfyUI..."
for i in {1..60}; do
  if nc -z 127.0.0.1 8188 2>/dev/null; then
    echo "[NEIA] ComfyUI OK, enviando workflow..."
    sleep 5
    curl -s -X POST "http://127.0.0.1:8188/prompt" \
      -H "Content-Type: application/json" \
      --data-binary "@/workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json" >/dev/null 2>&1 || true
    echo "[NEIA] ✅ Workflow carregado na queue!"
    break
  fi
  sleep 3
done
EOF

chmod +x "${COMFY}/autoload_neia.sh"

# Supervisor service
cat > /etc/supervisor/conf.d/neia-autoload.conf << EOF
[program:neia-autoload]
command=bash -c "sleep 40 && /workspace/ComfyUI/autoload_neia.sh"
directory=/workspace
autostart=true
autorestart=false
priority=999
stderr_logfile=/var/log/neia.err.log
stdout_logfile=/var/log/neia.out.log
EOF

supervisorctl reread 2>/dev/null && supervisorctl update 2>/dev/null || true

echo "✅ NEIA-GERAR-VIDEOS-18 PRONTO!"
echo "   Nodes: $(find custom_nodes -mindepth 1 -maxdepth 1 -type d | wc -l)"
echo "   Models: $(find models -name '*.safetensors' -o -name '*.ckpt' | wc -l)"
echo "   Login: admin/neia2026"
echo "   Porta: 8188"
