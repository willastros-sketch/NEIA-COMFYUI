#!/bin/bash
# ================================================================
#  ΝΞΙΔ COMMUNITY — RunPod Setup Script v3
#  Workflow: NEIA-GERAR-VIDEOS-18 (Wan2.1 I2V)
#  Instala todos os custom nodes identificados no workflow
# ================================================================
set -euo pipefail

COMFY_DIR="/workspace/ComfyUI"
NODES_DIR="$COMFY_DIR/custom_nodes"
MODELS_DIR="$COMFY_DIR/models"
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/main/NEIA-GERAR-VIDEOS-18.json"
LOG="/workspace/setup.log"

echo "" | tee -a "$LOG"
echo "╔════════════════════════════════════════════════════╗" | tee -a "$LOG"
echo "║   ΝΞΙΔ COMMUNITY — Setup RunPod v3                ║" | tee -a "$LOG"
echo "╚════════════════════════════════════════════════════╝" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# FUNÇÃO: clonar ou atualizar um repositório git
# ──────────────────────────────────────────────────────────────
clone_or_update() {
    local DEST="$1"
    local URL="$2"
    local NAME=$(basename "$DEST")
    if [ ! -d "$DEST/.git" ]; then
        echo "  → Clonando $NAME..." | tee -a "$LOG"
        if git clone --depth=1 -q "$URL" "$DEST" 2>>"$LOG"; then
            echo "  ✔ $NAME clonado." | tee -a "$LOG"
        else
            echo "  ✗ Falha ao clonar $NAME. Continuando..." | tee -a "$LOG"
            return 1
        fi
    else
        echo "  ✔ $NAME já existe (pulando clone)." | tee -a "$LOG"
    fi
    # Instalar requirements se existir
    if [ -f "$DEST/requirements.txt" ]; then
        pip install -q -r "$DEST/requirements.txt" >> "$LOG" 2>&1 || true
    fi
}

# ──────────────────────────────────────────────────────────────
# FUNÇÃO: baixar modelo somente se não existir
# ──────────────────────────────────────────────────────────────
download_model() {
    local DEST_PATH="$1"
    local URL="$2"
    local FILENAME=$(basename "$DEST_PATH")
    if [ -f "$DEST_PATH" ]; then
        echo "  ✔ $FILENAME já existe — pulando." | tee -a "$LOG"
        return 0
    fi
    echo "  → Baixando $FILENAME..." | tee -a "$LOG"
    mkdir -p "$(dirname "$DEST_PATH")"
    wget -q --show-progress \
        --retry-connrefused \
        --tries=5 \
        --timeout=60 \
        -O "$DEST_PATH" \
        "$URL" 2>>"$LOG" || {
            echo "  ✗ ERRO ao baixar $FILENAME — verifique o log." | tee -a "$LOG"
            rm -f "$DEST_PATH"
            return 1
        }
    echo "  ✔ $FILENAME baixado com sucesso." | tee -a "$LOG"
}

# ──────────────────────────────────────────────────────────────
# 1. DEPENDÊNCIAS DO SISTEMA
# ──────────────────────────────────────────────────────────────
echo "▶ [1/6] Instalando dependências..." | tee -a "$LOG"
apt-get update -qq >> "$LOG" 2>&1
apt-get install -y -qq git wget curl ffmpeg libgl1 libglib2.0-0 aria2 >> "$LOG" 2>&1
pip install -q --upgrade pip huggingface_hub >> "$LOG" 2>&1
echo "✔ Dependências OK." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 2. COMFYUI
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [2/6] Configurando ComfyUI..." | tee -a "$LOG"

if [ ! -d "$COMFY_DIR/.git" ]; then
    echo "  → Clonando ComfyUI..." | tee -a "$LOG"
    git clone --depth=1 -q https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR" 2>>"$LOG"
    pip install -q -r "$COMFY_DIR/requirements.txt" >> "$LOG" 2>&1
    echo "  ✔ ComfyUI instalado." | tee -a "$LOG"
else
    echo "  ✔ ComfyUI já existe." | tee -a "$LOG"
fi

mkdir -p "$NODES_DIR"
mkdir -p "$COMFY_DIR/user/default/workflows"
mkdir -p "$MODELS_DIR/diffusion_models"
mkdir -p "$MODELS_DIR/vae"
mkdir -p "$MODELS_DIR/text_encoders"
mkdir -p "$MODELS_DIR/clip_vision"
mkdir -p "$MODELS_DIR/loras"

echo "✔ ComfyUI OK." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 3. CUSTOM NODES (lista completa baseada no workflow)
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [3/6] Instalando Custom Nodes..." | tee -a "$LOG"

# 1. rgthree — Fast Bypasser (usado nos ON/OFF)
clone_or_update "$NODES_DIR/rgthree-comfy" \
    "https://github.com/rgthree/rgthree-comfy.git"

# 2. ComfyUI-Easy-Use — easy int, easy showAnything
clone_or_update "$NODES_DIR/ComfyUI-Easy-Use" \
    "https://github.com/yolain/ComfyUI-Easy-Use.git"

# 3. ComfyUI-VideoHelperSuite — VHS_VideoCombine, LoadAudio
clone_or_update "$NODES_DIR/ComfyUI-VideoHelperSuite" \
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# 4. ComfyUI-WanVideoWrapper — WanImageToVideo (nó essencial)
clone_or_update "$NODES_DIR/ComfyUI-WanVideoWrapper" \
    "https://github.com/kijai/ComfyUI-WanVideoWrapper.git"

# 5. ComfyUI-Custom-Scripts — MathExpression|pysssss
clone_or_update "$NODES_DIR/ComfyUI-Custom-Scripts" \
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"

# 6. was-node-suite-comfyui — SimpleMath+
clone_or_update "$NODES_DIR/was-node-suite-comfyui" \
    "https://github.com/WASasquatch/was-node-suite-comfyui.git"

# 7. ComfyUI-Manager — (recomendado, não obrigatório)
clone_or_update "$NODES_DIR/ComfyUI-Manager" \
    "https://github.com/ltdrdata/ComfyUI-Manager.git"

# 8. ComfyUI-Inspire-Pack — MarkdownNote
clone_or_update "$NODES_DIR/ComfyUI-Inspire-Pack" \
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git"

# 9. ComfyUI-OnDemand-Loaders — OnDemand Lora Loader
clone_or_update "$NODES_DIR/ComfyUI-OnDemand-Loaders" \
    "https://github.com/francarl/ComfyUI-OnDemand-Loaders.git"

# 10. ComfyUI-Impact-Pack — (opcional, alguns nodes podem precisar)
# clone_or_update "$NODES_DIR/ComfyUI-Impact-Pack" \
#     "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"

echo "✔ Custom Nodes instalados." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 4. MODELOS WAN 2.1 (obrigatórios)
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [4/6] Baixando Modelos Wan2.1..." | tee -a "$LOG"
echo "  ⚠ Modelos grandes (~17GB+). Isso pode levar 15-40 min." | tee -a "$LOG"

# Diffusion Model (FP8 480P)
download_model \
    "$MODELS_DIR/diffusion_models/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors"

# Text Encoder UMT5 XXL BF16
download_model \
    "$MODELS_DIR/text_encoders/umt5-xxl-enc-bf16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors"

# VAE Wan2.1
download_model \
    "$MODELS_DIR/vae/wan_2.1_vae.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# CLIP Vision
download_model \
    "$MODELS_DIR/clip_vision/clip_vision_h.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

echo "✔ Modelos baixados." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 5. CONFIGURAÇÃO DO ONDEMAND LOADERS (para LoRAs do Civitai)
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [5/6] Configurando OnDemand Loaders..." | tee -a "$LOG"

LOADER_CONFIG_DIR="$NODES_DIR/ComfyUI-OnDemand-Loaders"
if [ -d "$LOADER_CONFIG_DIR" ]; then
    # Cria um config.json com exemplos de LoRAs (você pode editar depois)
    cat > "$LOADER_CONFIG_DIR/config.json" << 'CONFIG_EOF'
{
    "loras": [
        {
            "name": "Oral Insertion (Wan2.2)",
            "url": "https://civitai.com/api/download/models/2073605"
        },
        {
            "name": "POV Cowgirl (Wan2.2)",
            "url": "https://civitai.com/api/download/models/2120000"
        },
        {
            "name": "POV Missionary (Wan2.2)",
            "url": "https://civitai.com/api/download/models/2240000"
        }
    ]
}
CONFIG_EOF
    echo "  ✔ config.json criado com LoRAs de exemplo." | tee -a "$LOG"
else
    echo "  ⚠ Pasta do OnDemand Loaders não encontrada." | tee -a "$LOG"
fi

# ──────────────────────────────────────────────────────────────
# 6. WORKFLOW + CONFIGURAÇÃO DE AUTO-ABERTURA
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [6/6] Configurando Workflow..." | tee -a "$LOG"

WORKFLOW_DEST="$COMFY_DIR/user/default/workflows/NEIA-GERAR-VIDEOS-18.json"

echo "  → Baixando workflow do GitHub..." | tee -a "$LOG"
if wget -q -O "$WORKFLOW_DEST" "$WORKFLOW_URL" 2>>"$LOG"; then
    echo "  ✔ Workflow salvo." | tee -a "$LOG"
else
    echo "  ✗ ERRO ao baixar workflow — verifique a URL." | tee -a "$LOG"
fi

# Configuração do ComfyUI para abrir o workflow automaticamente
cat > "$COMFY_DIR/user/default/comfy.settings.json" << 'SETTINGS_EOF'
{
  "Comfy.UseNewMenu": "Top",
  "Comfy.Sidebar.Location": "left",
  "Comfy.Workflow.ShowMissingModelsWarning": false,
  "Comfy.Workflow.ShowMissingNodesWarning": false,
  "Comfy.Server.ServerConfigValues": {},
  "Comfy.Workflow.OpenWorkflowOnLoad": "NEIA-GERAR-VIDEOS-18.json"
}
SETTINGS_EOF

echo "  ✔ Configurações salvas." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# INICIAR COMFYUI
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "╔════════════════════════════════════════════════════╗" | tee -a "$LOG"
echo "║    ✅ Setup concluído! Iniciando ComfyUI...        ║" | tee -a "$LOG"
echo "╚════════════════════════════════════════════════════╝" | tee -a "$LOG"
echo "" | tee -a "$LOG"
echo "  🌐 Acesse via: RunPod → Connect → HTTP Port 3000" | tee -a "$LOG"
echo "  📁 Log completo: $LOG" | tee -a "$LOG"
echo "" | tee -a "$LOG"

cd "$COMFY_DIR"

# Inicia o ComfyUI
exec python main.py \
    --listen 0.0.0.0 \
    --port 3000 \
    --enable-cors-header "*" \
    --preview-method auto \
    --fp8_e4m3fn-unet \
    2>&1 | tee -a "$LOG"
