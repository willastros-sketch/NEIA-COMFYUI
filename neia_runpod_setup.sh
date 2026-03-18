#!/bin/bash
# ============================================================
#  ΝΞΙΔ COMMUNITY — RunPod Setup Script
#  Workflow: NEIA-GERAR-VIDEOS-18
#  Auto-instala custom nodes, modelos, LoRAs e abre o workflow
# ============================================================

set -e

COMFYUI_DIR="/workspace/ComfyUI"
CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
MODELS_DIR="$COMFYUI_DIR/models"
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA-GERAR-VIDEOS-18.json"
WORKFLOW_FILE="$COMFYUI_DIR/user/default/workflows/NEIA-GERAR-VIDEOS-18.json"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║        ΝΞΙΔ COMMUNITY — Setup Iniciando...           ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ─────────────────────────────────────────────
# 1. INSTALAR DEPENDÊNCIAS DO SISTEMA
# ─────────────────────────────────────────────
echo "▶ [1/6] Instalando dependências do sistema..."
apt-get update -qq
apt-get install -y -qq git wget curl ffmpeg aria2 python3-pip > /dev/null 2>&1
pip install -q huggingface_hub > /dev/null 2>&1
echo "✔ Dependências instaladas."

# ─────────────────────────────────────────────
# 2. INSTALAR / ATUALIZAR COMFYUI
# ─────────────────────────────────────────────
echo ""
echo "▶ [2/6] Verificando ComfyUI..."
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "   Clonando ComfyUI..."
    git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_DIR"
    cd "$COMFYUI_DIR" && pip install -q -r requirements.txt
else
    echo "   ComfyUI já existe. Atualizando..."
    cd "$COMFYUI_DIR" && git pull -q
fi
mkdir -p "$CUSTOM_NODES_DIR"
mkdir -p "$COMFYUI_DIR/user/default/workflows"
echo "✔ ComfyUI pronto."

# ─────────────────────────────────────────────
# 3. INSTALAR CUSTOM NODES
# ─────────────────────────────────────────────
echo ""
echo "▶ [3/6] Instalando Custom Nodes..."

install_node() {
    local NAME="$1"
    local REPO="$2"
    local DIR="$CUSTOM_NODES_DIR/$NAME"
    if [ ! -d "$DIR" ]; then
        echo "   → Instalando $NAME..."
        git clone --depth=1 "$REPO" "$DIR" -q
        if [ -f "$DIR/requirements.txt" ]; then
            pip install -q -r "$DIR/requirements.txt" > /dev/null 2>&1
        fi
        if [ -f "$DIR/install.py" ]; then
            cd "$DIR" && python install.py > /dev/null 2>&1
        fi
        echo "   ✔ $NAME instalado."
    else
        echo "   ✔ $NAME já instalado — pulando."
    fi
}

# rgthree — Fast Bypasser
install_node "rgthree-comfy" \
    "https://github.com/rgthree/rgthree-comfy.git"

# ComfyUI Easy Use — easy int, easy showAnything
install_node "ComfyUI-Easy-Use" \
    "https://github.com/yolain/ComfyUI-Easy-Use.git"

# Video Helper Suite — VHS_VideoCombine, LoadAudio
install_node "ComfyUI-VideoHelperSuite" \
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# WanVideo Wrapper — WanImageToVideo
install_node "ComfyUI-WanVideoWrapper" \
    "https://github.com/kijai/ComfyUI-WanVideoWrapper.git"

# pysssss CustomScripts — MathExpression|pysssss
install_node "ComfyUI-Custom-Scripts" \
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"

# SimpleMath+ — SimpleMath+
install_node "was-node-suite-comfyui" \
    "https://github.com/WASasquatch/was-node-suite-comfyui.git"

# ComfyUI Manager (recomendado para gerenciar nodes)
install_node "ComfyUI-Manager" \
    "https://github.com/ltdrdata/ComfyUI-Manager.git"

# MarkdownNote
install_node "ComfyUI-Inspire-Pack" \
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git"

# OnDemand Lora Loader
install_node "ComfyUI-OnDemand-LoRA" \
    "https://github.com/JettHays/ComfyUI-OnDemand-LoRA.git"

echo "✔ Todos os Custom Nodes instalados."

# ─────────────────────────────────────────────
# 4. BAIXAR MODELOS
# ─────────────────────────────────────────────
echo ""
echo "▶ [4/6] Baixando Modelos Wan2.1..."

mkdir -p "$MODELS_DIR/diffusion_models"
mkdir -p "$MODELS_DIR/vae"
mkdir -p "$MODELS_DIR/clip"
mkdir -p "$MODELS_DIR/loras"
mkdir -p "$MODELS_DIR/text_encoders"

download_if_missing() {
    local DEST="$1"
    local URL="$2"
    local FILENAME=$(basename "$DEST")
    if [ ! -f "$DEST" ]; then
        echo "   → Baixando $FILENAME..."
        aria2c -x 8 -s 8 -q --dir "$(dirname "$DEST")" --out "$FILENAME" "$URL"
        echo "   ✔ $FILENAME baixado."
    else
        echo "   ✔ $FILENAME já existe — pulando."
    fi
}

# ── Wan2.1 I2V 14B (modelo principal) ──────────────────────
# Modelo Wan2.1-I2V-14B-480P (recomendado para 12~16GB VRAM)
download_if_missing \
    "$MODELS_DIR/diffusion_models/wan2.1-i2v-14b-480p-fp8-e4m3fn.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors"

# ── VAE Wan2.1 ─────────────────────────────────────────────
download_if_missing \
    "$MODELS_DIR/vae/wan_2.1_vae.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# ── CLIP / Text Encoder ────────────────────────────────────
download_if_missing \
    "$MODELS_DIR/text_encoders/umt5-xxl-enc-bf16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors"

echo "✔ Modelos baixados."

# ─────────────────────────────────────────────
# 5. BAIXAR LORAS RECOMENDADAS
# ─────────────────────────────────────────────
echo ""
echo "▶ [5/6] Baixando LoRAs NSFW recomendadas..."
echo "   ⚠ As LoRAs do Civitai requerem API Token."
echo "   → Para usar LoRAs do Civitai, configure a variável: CIVITAI_TOKEN"
echo ""

CIVITAI_TOKEN="${CIVITAI_TOKEN:-}"

civitai_download() {
    local FILENAME="$1"
    local MODEL_VERSION_ID="$2"
    local DEST="$MODELS_DIR/loras/$FILENAME"
    if [ -n "$CIVITAI_TOKEN" ]; then
        if [ ! -f "$DEST" ]; then
            echo "   → Baixando LoRA: $FILENAME..."
            wget -q --header="Authorization: Bearer $CIVITAI_TOKEN" \
                -O "$DEST" \
                "https://civitai.com/api/download/models/$MODEL_VERSION_ID"
            echo "   ✔ $FILENAME baixado."
        else
            echo "   ✔ $FILENAME já existe — pulando."
        fi
    else
        echo "   ⚠ CIVITAI_TOKEN não definido — pulando $FILENAME"
    fi
}

# LoRAs populares do workflow (IDs de versão do Civitai)
# Nota: troque os IDs de versão conforme necessidade
civitai_download "wan_oral_insertion.safetensors"        "2073605"   # Universal NSFW
civitai_download "wan_pov_cowgirl_i2v.safetensors"       "2120000"   # POV Cowgirl (aproximado)
civitai_download "wan_pov_missionary.safetensors"        "2240000"   # POV Missionary (aproximado)

echo "✔ Etapa LoRAs concluída."

# ─────────────────────────────────────────────
# 6. BAIXAR E CONFIGURAR WORKFLOW
# ─────────────────────────────────────────────
echo ""
echo "▶ [6/6] Configurando Workflow..."

# Criar diretório de workflows default
mkdir -p "$(dirname "$WORKFLOW_FILE")"

# Baixar o workflow
wget -q -O "$WORKFLOW_FILE" "$WORKFLOW_URL"
echo "   ✔ Workflow salvo em: $WORKFLOW_FILE"

# Criar arquivo de configuração para carregar o workflow automaticamente
cat > "$COMFYUI_DIR/user/default/comfy.settings.json" << 'EOF'
{
  "Comfy.UseNewMenu": "Top",
  "Comfy.Workflow.WorkflowTabsPosition": "Sidebar",
  "Comfy.Sidebar.Location": "left",
  "Comfy.NodeLibrary.Bookmarks.V2": [],
  "Comfy.NodeLibrary.BookmarksCustomization": {},
  "Comfy.Server.ServerConfigValues": {},
  "Comfy.Workflow.ShowMissingModelsWarning": true,
  "Comfy.Workflow.ShowMissingNodesWarning": true,
  "Comfy.Workflow.OpenWorkflowOnLoad": "NEIA-GERAR-VIDEOS-18.json"
}
EOF
echo "   ✔ Configuração de auto-abertura do workflow criada."

# ─────────────────────────────────────────────
# INICIAR COMFYUI
# ─────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       Setup concluído! Iniciando ComfyUI...          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  🌐 Acesse: http://0.0.0.0:3000"
echo "  📁 Modelos: $MODELS_DIR"
echo "  🎬 Workflow: NEIA-GERAR-VIDEOS-18.json (carregado automaticamente)"
echo ""

cd "$COMFYUI_DIR"
python main.py \
    --listen 0.0.0.0 \
    --port 3000 \
    --enable-cors-header \
    --preview-method auto \
    --cuda-malloc \
    --fp8_e4m3fn-unet \
    2>&1 | tee /workspace/comfyui.log
