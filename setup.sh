#!/usr/bin/env bash
set -e

echo "🚀 NEIA-GERAR-VIDEOS-18 Setup Completo"

WORKSPACE="${WORKSPACE:-/workspace}"
COMFY="${WORKSPACE}/ComfyUI"

mkdir -p "${COMFY}/models/"{checkpoints,loras,vae} "${COMFY}/"{workflows,custom_nodes}

# Workflow
curl -fsSL "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA-GERAR-VIDEOS-18.json" -o "${COMFY}/workflows/NEIA-GERAR-VIDEOS-18.json"

# Custom Nodes (do seu workflow)
cd "${COMFY}/custom_nodes"
for repo in \
  "Kosinkadink/ComfyUI-VideoHelperSuite" \
  "rgthree/rgthree-comfy" \
  "yolanother/ComfyUI-Easy-Use" \
  "s9roll/ComfyUI-SimpleMath" \
  "OnDemandLoRA/ComfyUI-OnDemandLoRA" \
  "city96/ComfyUI-Impact-Pack"; do
  dir=$(basename $repo)
  [ -d "$dir" ] || git clone -q "https://github.com/$repo"
done

pip install -q --no-cache-dir -r */requirements*.txt || true

# Modelos base
cd "${COMFY}/models/checkpoints"
wget -qnc "https://huggingface.co/stabilityai/stable-diffusion-3.5-medium/resolve/main/sd3.5_medium.safetensors"

# Autoload
cat > "${COMFY}/autoload.sh" << 'EOF'
#!/bin/bash
sleep 20
nc -z 127.0.0.1 8188 2>/dev/null && curl -s -X POST http://127.0.0.1:8188/prompt -H "Content-Type: application/json" --data-binary "@/workspace/ComfyUI/workflows/NEIA-GERAR-VIDEOS-18.json"
EOF
chmod +x "${COMFY}/autoload.sh"

cat > /etc/supervisor/conf.d/neia.conf << EOF
[program:neia]
command=bash -c "sleep 25 && /workspace/ComfyUI/autoload.sh"
autostart=true
EOF
supervisorctl reread && supervisorctl update

echo "✅ NEIA pronto em 8188!"
