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

# 2. Instalar Custom Nodes (Essenciais para o Workflow)
echo "🧩 Instalando Custom Nodes..."
cd "$COMFY_DIR/custom_nodes"

nodes=(
    "https://github.com/ltdrdata/ComfyUI-Manager.git"
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    "https://github.com/rgthree/rgthree-comfy.git"
    "https://github.com/stealthix/ComfyUI-OnDemand-Lora-Loader.git"
)

for repo in "${nodes[@]}"; do
    dir_name=$(basename "$repo" .git)
    if [ ! -d "$dir_name" ]; then
        echo "📥 Instalando $dir_name..."
        git clone "$repo"
    fi
done

# 3. Baixar os Modelos (Checkpoints)
# Nota: Verifique se o seu workflow usa o Juggernaut ou Wan2.1. 
# Vou deixar o Juggernaut XL como exemplo, que é muito comum.
echo "💾 Baixando Modelos..."
mkdir -p "$COMFY_DIR/models/checkpoints"
cd "$COMFY_DIR/models/checkpoints"
if [ ! -f "juggernautXL_v9.safetensors" ]; then
    wget -O "juggernautXL_v9.safetensors" "https://civitai.com/api/download/models/348913?type=Model&format=SafeTensor"
fi

# 4. CONFIGURAR O SEU WORKFLOW COMO PADRÃO
echo "📄 Baixando seu Workflow e definindo como padrão..."
# Criamos a pasta onde o ComfyUI busca o workflow inicial
mkdir -p "$COMFY_DIR/user/default/workflows"

# Link correto que você enviou (com tratamento para espaços)
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA%20GERAR%20VIDEOS%2018%20.json"

# Baixamos e salvamos como default.json para ele abrir automático na tela
curl -fsSL "$WORKFLOW_URL" -o "$COMFY_DIR/user/default/workflows/default.json"

# 5. Instalar dependências de Python
echo "📦 Instalando dependências..."
cd "$COMFY_DIR"
pip install -r requirements.txt
pip install opencv-python-headless ffmpeg-python

echo "=========================================="
echo "✅ TUDO PRONTO! O workflow NEIA vai carregar ao abrir."
echo "=========================================="

# 6. Inicia o ComfyUI
python main.py --listen --port 8188
