#!/bin/bash

# --- Configurações de Caminhos ---
WORKSPACE="/workspace"
COMFY_DIR="$WORKSPACE/ComfyUI"

echo "=========================================="
echo "🚀 INICIANDO SETUP COMPLETO NEIA-COMFYUI"
echo "=========================================="

# 1. Preparar o ambiente e clonar o ComfyUI
cd $WORKSPACE
if [ ! -d "$COMFY_DIR" ]; then
    echo "📥 Clonando ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd "$COMFY_DIR"

# 2. Instalar Custom Nodes (Baseado no seu JSON)
echo "🧩 Instalando Custom Nodes..."
mkdir -p "$COMFY_DIR/custom_nodes"
cd "$COMFY_DIR/custom_nodes"

nodes=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/kijai/ComfyUI-WanVideo.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    "https://github.com/stealthix/ComfyUI-OnDemand-Lora-Loader.git"
    "https://github.com/EllangoK/ComfyUI-Easy-Use.git"
)

for repo in "${nodes[@]}"; do
    dir_name=$(basename "$repo" .git)
    if [ ! -d "$dir_name" ]; then
        echo "📥 Instalando $dir_name..."
        git clone "$repo"
    fi
done

# 3. Baixar Modelos Necessários (Wan2.1)
echo "💾 Baixando Modelos (Wan2.1)..."
mkdir -p "$COMFY_DIR/models/checkpoints"
mkdir -p "$COMFY_DIR/models/vae"

# Checkpoint Wan2.1 14B (Necessário para o nó WanImageToVideo)
if [ ! -f "$COMFY_DIR/models/checkpoints/wan2.1_i2v_14b_720p.safetensors" ]; then
    wget -O "$COMFY_DIR/models/checkpoints/wan2.1_i2v_14b_720p.safetensors" "https://huggingface.co/Comfy-Org/Wan_Video_Config/resolve/main/wan2.1_i2v_14b_720p.safetensors"
fi

# VAE Wan2.1
if [ ! -f "$COMFY_DIR/models/vae/wan2.1_vae.safetensors" ]; then
    wget -O "$COMFY_DIR/models/vae/wan2.1_vae.safetensors" "https://huggingface.co/Comfy-Org/Wan_Video_Config/resolve/main/wan2.1_vae.safetensors"
fi

# 4. Configurar Workflow como Padrão
echo "📄 Configurando Workflow NEIA como inicial..."
mkdir -p "$COMFY_DIR/user/default/workflows"
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA%20GERAR%20VIDEOS%2018%20.json"
curl -fsSL "$WORKFLOW_URL" -o "$COMFY_DIR/user/default/workflows/default.json"

# 5. Instalar dependências de Python
echo "📦 Instalando dependências..."
cd "$COMFY_DIR"
pip install -r requirements.txt
pip install opencv-python-headless ffmpeg-python

echo "=========================================="
echo "✅ SETUP CONCLUÍDO! Iniciando ComfyUI..."
echo "=========================================="

python main.py --listen --port 8188
