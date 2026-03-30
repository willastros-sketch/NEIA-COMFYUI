#!/bin/bash
# NÃO usar set -e — o RunPod reinicia o container se o script sair com erro

COMFYUI_DIR="/workspace/ComfyUI"
WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA%20GERAR%20VIDEOS%2018.json"
WORKFLOW_FILE="$COMFYUI_DIR/user/default/workflows/NEIA_GERAR_VIDEOS_18.json"

echo "============================================================"
echo " NEIA COMFYUI - Inicializando ambiente..."
echo "============================================================"

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

    echo "[AVISO] Não foi possível baixar $name. Continuando..."
    return 0
}

# ----- 1. ComfyUI -----
if [ ! -d "$COMFYUI_DIR" ]; then
    echo "[→] Clonando ComfyUI..."
    cd /workspace
    git clone https://github.com/comfyanonymous/ComfyUI.git
    cd "$COMFYUI_DIR"
    pip install -q -r requirements.txt
else
    echo "[OK] ComfyUI já instalado."
    cd "$COMFYUI_DIR"
    git pull --quiet 2>/dev/null || true
    pip install -q -r requirements.txt --quiet 2>/dev/null || true
fi

# ----- 2. Custom Nodes -----
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
        echo "[OK] $dir_name já instalado."
        cd "$node_dir" && git pull --quiet 2>/dev/null || true
    else
        echo "[↓] Instalando $dir_name..."
        cd "$CUSTOM_NODES_DIR"
        if ! git clone --quiet "$repo_url" "$dir_name" 2>/dev/null; then
            echo "[AVISO] Falha ao clonar $dir_name — pulando."
            return 0
        fi
    fi

    if [ -f "$node_dir/requirements.txt" ]; then
        pip install -q -r "$node_dir/requirements.txt" 2>/dev/null || true
    fi
    if [ -f "$node_dir/install.py" ]; then
        cd "$node_dir" && python install.py 2>/dev/null || true
    fi
}

install_custom_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git" "ComfyUI-VideoHelperSuite"
install_custom_node "https://github.com/rgthree/rgthree-comfy.git" "rgthree-comfy"
install_custom_node "https://github.com/yolain/ComfyUI-Easy-Use.git" "ComfyUI-Easy-Use"
install_custom_node "https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git" "ComfyUI-Custom-Scripts"
install_custom_node "https://github.com/kijai/ComfyUI-WanVideoWrapper.git" "ComfyUI-WanVideoWrapper"
install_custom_node "https://github.com/Fannovel16/ComfyUI-RIFE.git" "ComfyUI-RIFE"
install_custom_node "https://github.com/evanspearman/ComfyMath.git" "ComfyMath"
install_custom_node "https://github.com/daxcay/ComfyUI-OnDemand-Lora-Loader.git" "ComfyUI-OnDemand-Lora-Loader"

# MarkdownNote - repo correto
install_custom_node "https://github.com/ssitu/ComfyUI_MarkdownNote.git" "ComfyUI_MarkdownNote"

# ----- 3. Modelos -----
echo ""
echo "============================================================"
echo " Baixando Modelos..."
echo "============================================================"

DIFFUSION_DIR="$COMFYUI_DIR/models/diffusion_models"
mkdir -p "$DIFFUSION_DIR"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors" \
    "wan2.2 LOW NOISE"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "$DIFFUSION_DIR/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors" \
    "wan2.2 HIGH NOISE"

VAE_DIR="$COMFYUI_DIR/models/vae"
mkdir -p "$VAE_DIR"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" \
    "$VAE_DIR/wan_2.1_vae.safetensors" \
    "wan_2.1_vae"

TEXT_ENCODERS_DIR="$COMFYUI_DIR/models/text_encoders"
mkdir -p "$TEXT_ENCODERS_DIR"
download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "$TEXT_ENCODERS_DIR/umt5_xxl_fp8_e4m3fn_scaled.safetensors" \
    "umt5_xxl text encoder"

LORA_DIR="$COMFYUI_DIR/models/loras"
mkdir -p "$LORA_DIR"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
    "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
    "LightX2V LoRA LOW"

download_file \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
    "LightX2V LoRA HIGH"

# Symlinks com nomes exatos do workflow
[ ! -f "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" ] && \
    ln -sf "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors" \
           "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" 2>/dev/null || true

[ ! -f "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" ] && \
    ln -sf "$LORA_DIR/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors" \
           "$LORA_DIR/Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" 2>/dev/null || true

# ----- 4. Workflow -----
echo ""
echo "[↓] Baixando workflow..."
mkdir -p "$(dirname "$WORKFLOW_FILE")"
wget -q -O "$WORKFLOW_FILE" "$WORKFLOW_URL" 2>/dev/null && echo "[✓] Workflow OK." || echo "[AVISO] Falha no workflow."

# ----- 5. extra_model_paths -----
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

# ----- 6. Iniciar ComfyUI -----
echo ""
echo "============================================================"
echo " Iniciando ComfyUI na porta 3000..."
echo "============================================================"

cd "$COMFYUI_DIR"
exec python main.py \
    --listen 0.0.0.0 \
    --port 3000 \
    --gpu-only \
    --highvram \
    --default-workflow "$WORKFLOW_FILE"
