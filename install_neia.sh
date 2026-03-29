#!/bin/bash

# Direciona para o volume persistente do RunPod
cd /workspace

# 1. Instalação do ComfyUI
if [ ! -d "ComfyUI" ]; then
    echo "--- Clonando ComfyUI ---"
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ComfyUI
pip install -r requirements.txt

# 2. Instalação do ComfyUI-Manager (O cérebro da automação)
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    echo "--- Instalando ComfyUI-Manager ---"
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

# 3. Baixa o seu Workflow NEIA
echo "--- Baixando Workflow NEIA v18 ---"
wget -O workflow_neia.json "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA%20GERAR%20VIDEOS%2018.json"

# 4. DOWNLOAD AUTOMÁTICO DE TUDO (Nós, Modelos, Checkpoints, LoRAs)
# Este comando tenta identificar os modelos pelo hash/nome e baixar do Civitai/HuggingFace
echo "--- Restaurando Nodes e Modelos (Aguarde, isso pode demorar...) ---"
python custom_nodes/ComfyUI-Manager/cm-cli.py restore-dependencies --install-models workflow_neia.json

# 5. Configura o Auto-Load do Workflow na interface
echo "--- Configurando Inicialização Automática ---"
echo "export const defaultGraph = $(cat workflow_neia.json);" > web/scripts/defaultGraph.js

# 6. Inicia o ComfyUI liberando o acesso externo
echo "--- Engine Pronta! Iniciando Servidor ---"
python main.py --listen 0.0.0.0 --port 8188
