#!/usr/bin/env bash
set -e

echo "[init] Provisioning NEIA ComfyUI environment..."

# --- Variáveis básicas ---
WORKSPACE="${WORKSPACE:-/workspace}"
COMFY_DIR="${WORKSPACE}/ComfyUI"
CUSTOM_NODES_DIR="${COMFY_DIR}/custom_nodes"
MODELS_DIR="${COMFY_DIR}/models"
INPUT_DIR="${COMFY_DIR}/input"
OUTPUT_DIR="${COMFY_DIR}/output"
WORKFLOWS_DIR="${COMFY_DIR}/workflows"

WORKFLOW_URL="https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/NEIA-GERAR-VIDEOS-18.json"
WORKFLOW_FILE="${WORKFLOWS_DIR}/NEIA-GERAR-VIDEOS-18.json"

mkdir -p "${CUSTOM_NODES_DIR}" "${MODELS_DIR}" "${INPUT_DIR}" "${OUTPUT_DIR}" "${WORKFLOWS_DIR}"

echo "[init] Clonando alguns custom nodes básicos..."
cd "${CUSTOM_NODES_DIR}"

# Exemplo – ajuste conforme o que seu workflow realmente usa
if [ ! -d "ComfyUI-VideoHelperSuite" ]; then
  git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
fi

if [ ! -d "ComfyUI-AnimateDiff-Evolved" ]; then
  git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git
fi

if [ ! -d "comfyui_controlnet_aux" ]; then
  git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git
fi

# Instalar requisitos dos custom nodes (best effort, sem quebrar se um falhar)
echo "[init] Instalando requirements dos custom nodes..."
for REQ in $(find "${CUSTOM_NODES_DIR}" -maxdepth 2 -name "requirements.txt"); do
  echo "[init] pip install -r ${REQ}"
  pip install -r "${REQ}" || echo "[warn] falhou requirements em ${REQ}, seguindo..."
done

# --- Modelos e Loras (EXEMPLOS, ajuste para os que seu workflow realmente referencia) ---

echo "[init] Baixando alguns modelos/lora de exemplo..."
cd "${MODELS_DIR}"

# Checkpoint principal – troque para o que seu workflow usa
if [ ! -f "sd_xl_base_1.0.safetensors" ]; then
  wget -O sd_xl_base_1.0.safetensors \
    https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors || \
    echo "[warn] falha ao baixar sd_xl_base_1.0"
fi

mkdir -p "${MODELS_DIR}/loras"
cd "${MODELS_DIR}/loras"

# Exemplo de Lora – ajuste / adicione
if [ ! -f "example_lora.safetensors" ]; then
  wget -O example_lora.safetensors \
    https://huggingface.co/latent-consult/example-lora/resolve/main/example_lora.safetensors || \
    echo "[warn] falha ao baixar example_lora"
fi

# --- Baixar e registrar o workflow ---
echo "[init] Baixando workflow NEIA..."
cd "${WORKFLOWS_DIR}"
curl -L "${WORKFLOW_URL}" -o "${WORKFLOW_FILE}"

# --- Configurar auto-carregamento do workflow via API on-start ---
# Cria script que será chamado no boot para enviar o workflow via API
AUTOLOAD_SCRIPT="${COMFY_DIR}/autoload_neia_workflow.sh"

cat > "${AUTOLOAD_SCRIPT}" << 'EOF'
#!/usr/bin/env bash
set -e

COMFY_HOST="127.0.0.1"
COMFY_PORT="${COMFYUI_PORT:-8188}"
WORKSPACE="${WORKSPACE:-/workspace}"
COMFY_DIR="${WORKSPACE}/ComfyUI"
WORKFLOWS_DIR="${COMFY_DIR}/workflows"
WORKFLOW_FILE="${WORKFLOWS_DIR}/NEIA-GERAR-VIDEOS-18.json"

echo "[autoload] Aguardando ComfyUI subir em ${COMFY_HOST}:${COMFY_PORT}..."

# espera porta ficar disponível
for i in {1..60}; do
  if nc -z "${COMFY_HOST}" "${COMFY_PORT}" 2>/dev/null; then
    echo "[autoload] ComfyUI está no ar, enviando workflow..."
    break
  fi
  sleep 2
done

if ! nc -z "${COMFY_HOST}" "${COMFY_PORT}" 2>/dev/null; then
  echo "[autoload] Timeout esperando ComfyUI, abortando autoload."
  exit 0
fi

if [ ! -f "${WORKFLOW_FILE}" ]; then
  echo "[autoload] Workflow não encontrado em ${WORKFLOW_FILE}"
  exit 0
fi

# Envia workflow para a API (create empty prompt com workflow)
curl -X POST "http://${COMFY_HOST}:${COMFY_PORT}/prompt" \
  -H "Content-Type: application/json" \
  --data-binary @"${WORKFLOW_FILE}" || echo "[autoload] falha ao enviar workflow"

echo "[autoload] Workflow NEIA enviado para a sessão atual."
EOF

chmod +x "${AUTOLOAD_SCRIPT}"

# Cria um serviço supervisord simples para rodar o autoload script depois que o comfyui estiver no ar
SUP_CONF="/etc/supervisor/conf.d/neia_autoload.conf"
if [ ! -f "${SUP_CONF}" ]; then
  cat > "${SUP_CONF}" <<EOF
[program:neia_autoload]
command=/bin/bash -c "sleep 20 && ${AUTOLOAD_SCRIPT}"
priority=20
autostart=true
autorestart=false
stderr_logfile=/var/log/supervisor/neia_autoload.err.log
stdout_logfile=/var/log/supervisor/neia_autoload.out.log
EOF
fi

echo "[init] Provisioning NEIA finalizado."
