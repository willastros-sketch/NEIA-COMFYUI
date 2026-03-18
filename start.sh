#!/bin/bash
# ================================================================
#  ΝΞΙΔ COMMUNITY — RunPod Template v2
#  Workflow: NEIA-GERAR-VIDEOS-18 (Wan2.1 I2V)
#  Todos os repos e URLs foram verificados manualmente
# ================================================================
set -euo pipefail

COMFY_DIR="/workspace/ComfyUI"
NODES_DIR="$COMFY_DIR/custom_nodes"
MODELS_DIR="$COMFY_DIR/models"
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA-GERAR-VIDEOS-18.json"
LOG="/workspace/setup.log"

echo "" | tee -a "$LOG"
echo "╔════════════════════════════════════════════════════╗" | tee -a "$LOG"
echo "║   ΝΞΙΔ COMMUNITY — Iniciando Setup RunPod v2      ║" | tee -a "$LOG"
echo "╚════════════════════════════════════════════════════╝" | tee -a "$LOG"
echo "" | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# FUNÇÃO: clonar ou atualizar um repositório git
# ──────────────────────────────────────────────────────────────
clone_or_update() {
    local DEST="$1"
    local URL="$2"
    local NAME
    NAME=$(basename "$DEST")
    if [ ! -d "$DEST/.git" ]; then
        echo "  → Clonando $NAME..." | tee -a "$LOG"
        git clone --depth=1 -q "$URL" "$DEST" 2>>"$LOG"
        echo "  ✔ $NAME clonado." | tee -a "$LOG"
    else
        echo "  ✔ $NAME já existe (pulando clone)." | tee -a "$LOG"
    fi
    # instalar requirements se existir
    if [ -f "$DEST/requirements.txt" ]; then
        pip install -q -r "$DEST/requirements.txt" >> "$LOG" 2>&1 || true
    fi
}

# ──────────────────────────────────────────────────────────────
# FUNÇÃO: baixar arquivo somente se não existir
# ──────────────────────────────────────────────────────────────
download_model() {
    local DEST_PATH="$1"
    local URL="$2"
    local FILENAME
    FILENAME=$(basename "$DEST_PATH")
    if [ -f "$DEST_PATH" ]; then
        echo "  ✔ $FILENAME já existe — pulando." | tee -a "$LOG"
        return 0
    fi
    echo "  → Baixando $FILENAME..." | tee -a "$LOG"
    mkdir -p "$(dirname "$DEST_PATH")"
    # wget com retry e timeout
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
# 3. CUSTOM NODES (URLs verificadas)
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [3/6] Instalando Custom Nodes..." | tee -a "$LOG"

# ✅ 1. ComfyUI Manager — gerenciador central
clone_or_update "$NODES_DIR/ComfyUI-Manager" \
    "https://github.com/ltdrdata/ComfyUI-Manager.git"

# ✅ 2. rgthree — Fast Bypasser (usado nos nodes ON/OFF de LoRA e Áudio)
clone_or_update "$NODES_DIR/rgthree-comfy" \
    "https://github.com/rgthree/rgthree-comfy.git"

# ✅ 3. ComfyUI-Easy-Use — easy int, easy showAnything
clone_or_update "$NODES_DIR/ComfyUI-Easy-Use" \
    "https://github.com/yolain/ComfyUI-Easy-Use.git"

# ✅ 4. ComfyUI-VideoHelperSuite — VHS_VideoCombine, LoadAudio
clone_or_update "$NODES_DIR/ComfyUI-VideoHelperSuite" \
    "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# ✅ 5. pysssss Custom Scripts — MathExpression|pysssss
clone_or_update "$NODES_DIR/ComfyUI-Custom-Scripts" \
    "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"

# ✅ 6. ComfyUI Impact Pack — SimpleMath+, MarkdownNote
clone_or_update "$NODES_DIR/ComfyUI-Impact-Pack" \
    "https://github.com/ltdrdata/ComfyUI-Impact-Pack.git"

# ✅ 7. OnDemand Loaders — "OnDemand Lora Loader" (URL verificada)
clone_or_update "$NODES_DIR/ComfyUI-OnDemand-Loaders" \
    "https://github.com/francarl/ComfyUI-OnDemand-Loaders.git"

# ✅ 8. ComfyUI Inspire Pack — nodes auxiliares e MarkdownNote
clone_or_update "$NODES_DIR/ComfyUI-Inspire-Pack" \
    "https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git"

# ✅ 9. was-node-suite — SimpleMath+
clone_or_update "$NODES_DIR/was-node-suite-comfyui" \
    "https://github.com/WASasquatch/was-node-suite-comfyui.git"

# NOTA: WanImageToVideo é NATIVO do ComfyUI (sem custom node necessário)

echo "✔ Custom Nodes instalados." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 4. MODELOS WAN 2.1 (URLs /resolve/main/ verificadas via Civitai)
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [4/6] Baixando Modelos Wan2.1..." | tee -a "$LOG"
echo "  ⚠ Modelos grandes (~17GB+). Isso pode levar 15-40 min." | tee -a "$LOG"

# ── Diffusion Model (FP8 480P — 17GB) ─────────────────────────
# URL verificada via Civitai guide e HF blob page
download_model \
    "$MODELS_DIR/diffusion_models/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors"

# ── Text Encoder UMT5 XXL BF16 (~10GB) ────────────────────────
download_model \
    "$MODELS_DIR/text_encoders/umt5-xxl-enc-bf16.safetensors" \
    "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/umt5-xxl-enc-bf16.safetensors"

# ── VAE Wan2.1 (~1.5GB) ───────────────────────────────────────
# Usando Comfy-Org repackaged (URL pública verificada)
download_model \
    "$MODELS_DIR/vae/wan_2.1_vae.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# ── CLIP Vision (~1.1GB) ──────────────────────────────────────
download_model \
    "$MODELS_DIR/clip_vision/clip_vision_h.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

echo "✔ Modelos baixados." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 5. LORAS (via CIVITAI_TOKEN — opcional)
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [5/6] LoRAs do Civitai..." | tee -a "$LOG"

CIVITAI_TOKEN="${CIVITAI_TOKEN:-}"

civitai_dl() {
    local FILENAME="$1"
    local VERSION_ID="$2"
    local DEST="$MODELS_DIR/loras/$FILENAME"
    if [ -z "$CIVITAI_TOKEN" ]; then
        echo "  ⚠ CIVITAI_TOKEN não definido — pulando $FILENAME" | tee -a "$LOG"
        return 0
    fi
    if [ -f "$DEST" ]; then
        echo "  ✔ $FILENAME já existe — pulando." | tee -a "$LOG"
        return 0
    fi
    echo "  → Baixando LoRA: $FILENAME..." | tee -a "$LOG"
    HTTP_STATUS=$(wget -q --server-response \
        --header="Authorization: Bearer $CIVITAI_TOKEN" \
        -O "$DEST" \
        "https://civitai.com/api/download/models/$VERSION_ID" 2>&1 | grep "HTTP/" | tail -1 | awk '{print $2}')
    if [ "$HTTP_STATUS" = "200" ] || [ -s "$DEST" ]; then
        echo "  ✔ $FILENAME baixado." | tee -a "$LOG"
    else
        echo "  ✗ Falha ao baixar $FILENAME (HTTP $HTTP_STATUS). Verifique o token." | tee -a "$LOG"
        rm -f "$DEST"
    fi
}

# LoRA Universal NSFW para Wan2.1 (modelVersionId=2073605)
civitai_dl "wan21_universal_nsfw.safetensors" "2073605"

if [ -z "$CIVITAI_TOKEN" ]; then
    echo "" | tee -a "$LOG"
    echo "  💡 DICA: Para baixar LoRAs automaticamente, defina a variável" | tee -a "$LOG"
    echo "     CIVITAI_TOKEN no painel Environment Variables do RunPod." | tee -a "$LOG"
    echo "     Token: https://civitai.com/user/account → API Keys" | tee -a "$LOG"
fi

echo "✔ Etapa LoRAs concluída." | tee -a "$LOG"

# ──────────────────────────────────────────────────────────────
# 6. WORKFLOW + CONFIG AUTO-ABERTURA
# ──────────────────────────────────────────────────────────────
echo "" | tee -a "$LOG"
echo "▶ [6/6] Configurando Workflow..." | tee -a "$LOG"

WORKFLOW_DEST="$COMFY_DIR/user/default/workflows/NEIA-GERAR-VIDEOS-18.json"

echo "  → Baixando workflow do GitHub..." | tee -a "$LOG"
wget -q -O "$WORKFLOW_DEST" "$WORKFLOW_URL" 2>>"$LOG" && \
    echo "  ✔ Workflow salvo." | tee -a "$LOG" || \
    echo "  ✗ ERRO ao baixar workflow — verifique a URL." | tee -a "$LOG"

# Configuração do ComfyUI para abrir o workflow automaticamente
mkdir -p "$COMFY_DIR/user/default"
cat > "$COMFY_DIR/user/default/comfy.settings.json" << 'SETTINGS_EOF'
{
  "Comfy.UseNewMenu": "Top",
  "Comfy.Sidebar.Location": "left",
  "Comfy.Workflow.ShowMissingModelsWarning": false,
  "Comfy.Workflow.ShowMissingNodesWarning": false,
  "Comfy.Server.ServerConfigValues": {}
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

# Iniciar em background um script que abre o workflow via API após o servidor subir
(
    sleep 20  # aguarda ComfyUI inicializar
    echo "  → Carregando workflow via API..." >> "$LOG"
    WORKFLOW_JSON=$(cat "$WORKFLOW_DEST" 2>/dev/null || echo "")
    if [ -n "$WORKFLOW_JSON" ]; then
        curl -s -X POST http://127.0.0.1:3000/api/userdata/workflows/NEIA-GERAR-VIDEOS-18.json \
            -H "Content-Type: application/json" \
            -d "$WORKFLOW_JSON" >> "$LOG" 2>&1 || true
        echo "  ✔ Workflow enviado para o servidor." >> "$LOG"
    fi
) &

# Iniciar ComfyUI com flags otimizadas para vídeo
exec python main.py \
    --listen 0.0.0.0 \
    --port 3000 \
    --enable-cors-header "*" \
    --preview-method auto \
    --fp8_e4m3fn-unet \
    2>&1 | tee -a "$LOG"
