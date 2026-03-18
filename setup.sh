#!/bin/bash
# Script de setup para ComfyUI - Wan2.2 I2V (versão simplificada)
# Apenas instala custom nodes e baixa modelos. Workflow será importado manualmente.

set -e

echo "========================================="
echo "🚀 Iniciando setup do ambiente ComfyUI"
echo "========================================="

COMFY_DIR="/workspace/ComfyUI"
cd "$COMFY_DIR" || { echo "❌ Erro: $COMFY_DIR não encontrado!"; exit 1; }

# 1. Instalar custom nodes essenciais
echo "📦 Instalando custom nodes..."
cd custom_nodes || mkdir -p custom_nodes && cd custom_nodes

# Lista de repositórios de nodes
declare -A NODES=(
    ["rgthree-comfy"]="https://github.com/rgthree/rgthree-comfy.git"
    ["ComfyUI-Easy-Use"]="https://github.com/yolain/ComfyUI-Easy-Use.git"
    ["ComfyUI-Math"]="https://github.com/evanspearman/ComfyUI-Math.git"
    ["ComfyUI-VideoHelperSuite"]="https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
    ["ComfyUI-Custom-Scripts"]="https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git"
    ["ComfyUI-Manager"]="https://github.com/ltdrdata/ComfyUI-Manager.git"
)

for node in "${!NODES[@]}"; do
    if [ ! -d "$node" ]; then
        git clone "${NODES[$node]}" && echo "✅ $node instalado"
    else
        echo "⏩ $node já existe"
    fi
done

# ComfyUI-OnDemand-Loaders (requer pip)
if [ ! -d "ComfyUI-OnDemand-Loaders" ]; then
    git clone https://github.com/francarl/ComfyUI-OnDemand-Loaders.git
    cd ComfyUI-OnDemand-Loaders
    pip install -r requirements.txt
    cd ..
    echo "✅ ComfyUI-OnDemand-Loaders instalado"
fi

cd "$COMFY_DIR"

# 2. Criar pastas de modelos
echo "📁 Criando pastas para modelos..."
mkdir -p models/vae models/clip models/diffusion_models models/loras

# 3. Baixar modelos públicos com aria2c
echo "⬇️ Baixando modelos (pode levar alguns minutos)..."
command -v aria2c >/dev/null 2>&1 || { apt update && apt install -y aria2; }

# VAE
aria2c -x 4 -s 4 -c -d models/vae -o wan_2.1_vae.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# CLIP
aria2c -x 4 -s 4 -c -d models/clip -o umt5_xxl_fp8_e4m3fn_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# UNET Low Noise
aria2c -x 4 -s 4 -c -d models/diffusion_models -o wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors"

# UNET High Noise
aria2c -x 4 -s 4 -c -d models/diffusion_models -o wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors"

# LoRAS Lightning
aria2c -x 4 -s 4 -c -d models/loras -o "Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"

aria2c -x 4 -s 4 -c -d models/loras -o "Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"

# 4. Instalar FFmpeg
echo "🎬 Instalando FFmpeg..."
apt update && apt install -y ffmpeg

echo "========================================="
echo "✅ Setup concluído com sucesso!"
echo "🚀 Iniciando ComfyUI na porta 8188..."
echo "========================================="
echo "ℹ️  Workflow não foi baixado automaticamente."
echo "   Para importar manualmente:"
echo "   1. Acesse a interface web do ComfyUI (URL do pod na porta 8188)"
echo "   2. Clique em 'Load' (ou arraste o arquivo JSON para a janela)"
echo "   3. Selecione o arquivo do workflow que você tem localmente"
echo "========================================="

cd "$COMFY_DIR"
python main.py --listen --port 8188
