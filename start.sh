#!/bin/bash
set -e

# ============================================================
# NEIA COMFYUI - RunPod Start Script
# Workflow: NEIA GERAR VIDEOS 18
# ============================================================

COMFYUI_DIR="/workspace/ComfyUI"
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA%20GERAR%20VIDEOS%2018.json"
WORKFLOW_FILE="$COMFYUI_DIR/user/default/workflows/NEIA_GERAR_VIDEOS_18.json"

echo "============================================================"
echo " NEIA COMFYUI - Inicializando ambiente..."
echo "============================================================"

# ----- Função de download com retry -----
download_file() {
    local url="$1"
    local dest="$2"
    local name="$3"
    local max_attempts=3

    mkdir -p "$(dirname "$dest")"

    if [ -f "$dest" ]; then
        echo "[OK] $name já existe, pulando."
        return 0
    fi

    for attempt in $(seq 1 $max_attempts); do
        echo "[↓] Baixando $name (tentativa $attempt/$max_attempts)..."
        if wget -q --show-progress -c -O "$dest" "$url" 2>&1; then
            echo "[✓] $name baixado com sucesso."
            return 0
        else
            echo "[!] Falha na tentativa $attempt. Aguardando 5s..."
            rm -f "$dest"
            sleep 5
        fi
    done

    echo "[ERRO] Não foi possível baixar $name após $max_attempts tentativas."
    return 1
}

# ----- 1. Instalar ComfyUI (se não existir) -----
if [ ! -d "$COMFYUI_DIR" ]; then
    echo ""
    echo "[→] Clonando ComfyUI..."
    cd /workspace
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd "$COMFYUI_DIR"
    pip install -q -r requirements.txt
else
    echo "[OK] ComfyUI já instalado."
    cd "$COMFYUI_DIR"
    git pull --quiet
    pip install -q -r requirements.txt --quiet
fi

# ----- 2. Instalar Custom Nodes -----
echo ""
echo "============================================================"
echo " Instalando Custom Nodes..."
echo "============================================================"

CUSTOM_NODES_DIR="$COMFYUI_DIR/custom_nodes"
mkdir -p "$CUSTOM_NODES_DIR"

install_custom_node() {
    local repo_url="$1"
    local dir_name="$2"
    local node_dir="$CUSTOM_NODES_DIR/$dir_name"

    if [ -d "$node_dir" ]; then
        echo "[OK] $dir_name já instalado, atualizando..."
        cd "$node_dir" && git pull --quiet
    else
        echo "[↓] Instalando $dir_name..."
        cd "$CUSTOM_NODES_DIR"
        git clone --quiet "$repo_url" "$dir_name"
    fi

    if [ -f "$node_dir/requirements.txt" ]; then
        echo "    [pip] Instalando dependências de $dir_name..."
        pip install -q -r "$node_dir/requirements.txt"
    fi
    if [ -f "$node_dir/install.py" ]; then
        echo "    [py] Executando install.py de $dir_name..."
        cd "$node_dir" && python install.py 2>/dev/null || true
    fi
}

# ComfyUI-VideoHelperSuite (VHS_VideoCombine, VHS_SplitImages)
install_custom_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "ComfyUI-VideoHelperSuite"

# rgthree-comfy (Fast Bypasser)
install_custom_node "https://github.com/rgthree/rgthree-comfy.git" "rgthree-comfy"

# ComfyUI-Easy-Use (easy int, easy showAnything, easy cleanGpuUsed)
install_custom_node "https://github.com/yolain/ComfyUI-Easy-Use.git" "ComfyUI-Easy-Use"

# ComfyUI-Custom-Scripts (MathExpression|pysssss)
install_custom_node "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git" "ComfyUI-Custom-Scripts"

# ComfyUI-WanVideoWrapper (WanImageToVideo)
install_custom_node "https://github.com/kijai/ComfyUI-WanVideoWrapper.git" "ComfyUI-WanVideoWrapper"

# ComfyUI-Markdown-Notes (MarkdownNote)
install_custom_node "https://github.com/Extraltodeus/ComfyUI-Markdown-Notes.git" "ComfyUI-Markdown-Notes"

# ComfyUI-RIFE (RIFEInterpolation)
install_custom_node "https://github.com/Fannovel16/ComfyUI-RIFE.git" "ComfyUI-RIFE"

# comfyui-simpleMath (SimpleMath+)
install_custom_node "https://github.com/evanspearman/ComfyMath.git" "ComfyMath"

# ComfyUI-OnDemand-Lora-Loader (OnDemand Lora Loader)
install_custom_node "https://github.com/daxcay/ComfyUI-OnDemand-Lora-Loader.git" "ComfyUI-OnDemand-Lora-Loader"

# ----- 3. Baixar Modelos -----
echo ""
echo "============================================================"
echo " Baixando Modelos (isso pode demorar bastante)..."
echo "============================================================"

# Diffusion Models (UNet) - Wan 2.2 I2V 14B
DIFFUSION_DIR="$COMFYUI_DIR/models/diffusion_models"
mkdir -p "$DIFFUSION_DIR"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "wan2.2_i2v_low_noise_14B_fp8_scaled (LOW NOISE)"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "wan2.2_i2v_high_noise_14B_fp8_scaled (HIGH NOISE)"

# VAE
VAE_DIR="$COMFYUI_DIR/models/vae"
mkdir -p "$VAE_DIR"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "$VAE_DIR/wan_2.1_vae.safetensors" \
    "wan_2.1_vae (VAE)"

# Text Encoders (CLIP)
TEXT_ENCODERS_DIR="$COMFYUI_DIR/models/text_encoders"
mkdir -p "$TEXT_ENCODERS_DIR"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "umt5_xxl_fp8_e4m3fn_scaled (Text Encoder)"

# LoRAs - Lightning (4 steps) do Wan 2.2
LORA_DIR="$COMFYUI_DIR/models/loras"
mkdir -p "$LORA_DIR"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
    "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
    "wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise (LightX2V LOW)"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise (LightX2V HIGH)"

# LoRAs - Wan 2.2 Lightning (aliases usados no workflow)
# Estes são os mesmos arquivos acima com nomes diferentes conforme widgets_values do workflow
if [ ! -f "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" ]; then
    echo "[→] Criando symlink para Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16..."
    ln -sf "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
           "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors"
fi
if [ ! -f "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" ]; then
    echo "[→] Criando symlink para Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16..."
    ln -sf "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
           "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors"
fi

# ----- 4. Baixar Workflow -----
echo ""
echo "============================================================"
echo " Configurando Workflow..."
echo "============================================================"

mkdir -p "$(dirname "$WORKFLOW_FILE")"

echo "[↓] Baixando workflow NEIA GERAR VIDEOS 18..."
wget -q -O "$WORKFLOW_FILE" "$WORKFLOW_URL" && echo "[✓] Workflow salvo em: $WORKFLOW_FILE"

# ----- 5. Configurar extra_model_paths.yaml -----
cat > "$COMFYUI_DIR/extra_model_paths.yaml" << 'EOF'
comfyui:
    base_path: /workspace/ComfyUI/models
    checkpoints: checkpoints
    loras: loras
    vae: vae
    text_encoders: text_encoders
    diffusion_models: diffusion_models
    clip: text_encoders
    unet: diffusion_models
EOF
echo "[✓] extra_model_paths.yaml configurado."

# ----- 6. Iniciar ComfyUI -----
echo ""
echo "============================================================"
echo " Iniciando ComfyUI..."
echo "============================================================"

cd "$COMFYUI_DIR"

# Inicia ComfyUI em background para poder injetar o workflow depois
python main.py \
    --listen 0.0.0.0 \
    --port 3000 \
    --gpu-only \
    --highvram \
    --default-workflow "$WORKFLOW_FILE" &

COMFYUI_PID=$!
echo "[✓] ComfyUI iniciado (PID: $COMFYUI_PID)"
echo ""
echo "============================================================"
echo " NEIA ComfyUI está rodando na porta 3000"
echo " Acesse pelo link público do RunPod (porta 3000)"
echo "============================================================"

# Manter o processo vivo
wait $COMFYUI_PID
