#!/usr/bin/env bash
set -e

echo "🚀 NEIA-GERAR-VIDEOS-18 Setup Completo - Mar/2026"

WORKSPACE="${WORKSPACE:-/workspace}"
COMFY="${WORKSPACE}/ComfyUI"

# Diretórios padrão
mkdir -p "${COMFY}/models/"{checkpoints,loras,vae,controlnet,clip}
mkdir -p "${COMFY}/"{workflows,input,output,custom_nodes}

# 1. Workflow NEIA
echo "[1/5] Baixando workflow NEIA..."
curl -fsSL "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA-GERAR-VIDEOS-18.json" \
  -o "${COMFY}/workflows/NEIA-GERAR-VIDEOS-18.json"

# 2. Custom Nodes OBRIGATÓRIOS (mapeados do seu JSON)
cd "${COMFY}/custom_nodes"
echo "[2/5] Custom Nodes (8 repos)..."

NODES=(
  "Kosinkadink/ComfyUI-VideoHelperSuite.git"      # VHS_VideoCombine, LoadAudio
  "rgthree/rgthree-comfy.git"                     # Fast Bypasser  
  "yolanother/ComfyUI-Easy-Use.git"               # easy int/showAnything
  "s9roll/ComfyUI-SimpleMath.git"                 # SimpleMath+
  "OnDemandLoRA/ComfyUI-OnDemandLoRA.git"         # OnDemand Lora Loader (6x)
  "pysssss/ComfyUI_pysssss.git"                   # MathExpression|pysssss
  "city96/ComfyUI-Impact-Pack.git"                # ModelSamplingSD3
  "Comfy-Org/ComfyUI-Manager.git"                 # Manager geral
)

for node in "${NODES[@]}"; do
  name=$(basename "$node" .git)
  if [ ! -d "$name" ]; then
    echo "[nodes] git clone $name"
    git clone -q "https://github.com/$node"
  fi
done

# Requirements
echo "[2b/5] pip requirements..."
find . -name "requirements*.txt" -exec pip install --no-cache-dir -q {} \; 2>/dev/null || true

# 3. Modelos Base SD3 (nó 136)
echo "[3/5] Modelos SD3.5..."
cd "${COMFY}/models/checkpoints"
wget -qnc --limit-rate=50m --show-progress \
  "https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors" || \
  echo "[warn] SD3.5 medium"

cd ../vae
wget -qnc --limit-rate=50m --show-progress \
  "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors"

# 4. Autoload Workflow via API
echo "[4/5] Configurando autoload..."
cat > "${COMFY}/autoload_neia.sh" << 'EOF'
#!/bin/bash
echo "[autoload] Aguardando ComfyUI..."
for i in {1..30}; do
  nc -z 127.0.0.1 8188 2>/dev/null && break || sleep 2
done
echo "[autoload] Enviando NEIA workflow..."
curl -s -X POST "http://127.0.0.1:8188/prompt" \
  -H "Content-Type: application/json" \
  --data-binary "@/workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json" || true
echo "[autoload] ✅ NEIA carregado!"
EOF

chmod +x "${COMFY}/autoload_neia.sh"

# Supervisor service
cat > /etc/supervisor/conf.d/neia-autoload.conf << EOF
[program:neia-autoload]
command=bash -c "sleep 25 && /workspace/ComfyUI/autoload_neia.sh"
directory=/workspace
autostart=true
autorestart=false
priority=100
stderr_logfile=/var/log/neia.err.log
stdout_logfile=/var/log/neia.out.log
EOF

supervisorctl reread && supervisorctl update

# 5. Finalização
echo "[5/5] ✅ SETUP CONCLUÍDO!"
echo "   ComfyUI: http://localhost:8188"
echo "   Workflow: ${COMFY}/workflows/NEIA-GERAR-VIDEOS-18.json"
echo "   Login: admin/neia2026"
echo "   Custom Nodes: $(ls -1 custom_nodes/ | wc -l | xargs) instalados"
