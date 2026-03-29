#!/bin/bash

# Vai para o volume persistente
cd /workspace

# 1. Garante o ComfyUI
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi
cd ComfyUI
pip install -r requirements.txt

# 2. Garante o Manager (Obrigatório para o próximo passo)
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
fi
pip install -r custom_nodes/ComfyUI-Manager/requirements.txt

# 3. Baixa o Workflow
wget -O workflow_neia.json "https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA%20GERAR%20VIDEOS%2018.json"

# 4. INSTALA TUDO (Nós + Modelos + LoRAs)
# Esse comando é o que faz a mágica de baixar os checkpoints automaticamente
python custom_nodes/ComfyUI-Manager/cm-cli.py restore-dependencies --install-models workflow_neia.json

# 5. Configura o Auto-Load (Versão segura para não quebrar o JS)
echo -n "export const defaultGraph = " > web/scripts/defaultGraph.js
cat workflow_neia.json >> web/scripts/defaultGraph.js
echo ";" >> web/scripts/defaultGraph.js

# 6. Inicia o ComfyUI
python main.py --listen 0.0.0.0 --port 8188
