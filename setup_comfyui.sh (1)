#!/bin/bash
# Script de setup para ComfyUI - Wan2.2 I2V (público)
# Inclui ComfyUI-Manager e OnDemand Loaders para download fácil de LoRAs
# Executado automaticamente ao iniciar o pod no RunPod

set -e  # interrompe o script se algum comando falhar

echo "========================================="
echo "🚀 Iniciando setup do ambiente ComfyUI"
echo "========================================="

# Diretório do ComfyUI (padrão no RunPod)
COMFY_DIR="/workspace/ComfyUI"
cd "$COMFY_DIR" || { echo "❌ Erro: $COMFY_DIR não encontrado!"; exit 1; }

# 1. Instalar nós customizados
echo "📦 Instalando custom nodes..."
cd custom_nodes || mkdir -p custom_nodes && cd custom_nodes

# rgthree-comfy
if [ ! -d "rgthree-comfy" ]; then
    git clone https://github.com/rgthree/rgthree-comfy.git
    echo "✅ rgthree-comfy instalado"
else
    echo "⏩ rgthree-comfy já existe"
fi

# ComfyUI-Easy-Use
if [ ! -d "ComfyUI-Easy-Use" ]; then
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git
    echo "✅ ComfyUI-Easy-Use instalado"
else
    echo "⏩ ComfyUI-Easy-Use já existe"
fi

# ComfyUI-Math
if [ ! -d "ComfyUI-Math" ]; then
    git clone https://github.com/evanspearman/ComfyUI-Math.git
    echo "✅ ComfyUI-Math instalado"
else
    echo "⏩ ComfyUI-Math já existe"
fi

# ComfyUI-VideoHelperSuite (VHS)
if [ ! -d "ComfyUI-VideoHelperSuite" ]; then
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
    echo "✅ ComfyUI-VideoHelperSuite instalado"
else
    echo "⏩ ComfyUI-VideoHelperSuite já existe"
fi

# ComfyUI-Custom-Scripts (pysssss)
if [ ! -d "ComfyUI-Custom-Scripts" ]; then
    git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git
    echo "✅ ComfyUI-Custom-Scripts instalado"
else
    echo "⏩ ComfyUI-Custom-Scripts já existe"
fi

# ComfyUI-Manager (instalação de nós com 1 clique)
if [ ! -d "ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git
    echo "✅ ComfyUI-Manager instalado"
else
    echo "⏩ ComfyUI-Manager já existe"
fi

# ComfyUI-OnDemand-Loaders (baixa LoRAs por URL automaticamente)
if [ ! -d "ComfyUI-OnDemand-Loaders" ]; then
    git clone https://github.com/francarl/ComfyUI-OnDemand-Loaders.git
    cd ComfyUI-OnDemand-Loaders
    pip install -r requirements.txt
    cd ..
    echo "✅ ComfyUI-OnDemand-Loaders instalado"
else
    echo "⏩ ComfyUI-OnDemand-Loaders já existe"
fi

cd "$COMFY_DIR"

# 2. Criar pastas de modelos
echo "📁 Criando pastas para modelos..."
mkdir -p models/vae models/clip models/diffusion_models models/loras

# 3. Baixar modelos públicos com aria2c (download paralelo)
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

# LoRAS Lightning (públicas)
aria2c -x 4 -s 4 -c -d models/loras -o "Wan2.2-Lightning_I2V-A14B-4steps-lora_LOW_fp16.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_low_noise.safetensors"

aria2c -x 4 -s 4 -c -d models/loras -o "Wan2.2-Lightning_I2V-A14B-4steps-lora_HIGH_fp16.safetensors" \
    "https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/loras/wan2.2_i2v_lightx2v_4steps_lora_v1_high_noise.safetensors"

# 4. Aviso sobre LoRAs privadas (apenas informativo)
echo "========================================="
echo "ℹ️  DICA: Para baixar LoRAS do CivitAI facilmente:"
echo "   - Use o nó 'OnDemand Lora Loader' (já instalado)"
echo "   - Ou use o ComfyUI-Manager para buscar modelos"
echo "========================================="

# 5. Instalar FFmpeg (necessário para VHS_VideoCombine)
echo "🎬 Instalando FFmpeg..."
apt update && apt install -y ffmpeg

echo "========================================="
echo "✅ Setup concluído com sucesso!"
echo "🚀 Iniciando ComfyUI..."
echo "========================================="

# Inicia o ComfyUI (se este script for usado no comando de inicialização)
cd "$COMFY_DIR"
python main.py --listen
