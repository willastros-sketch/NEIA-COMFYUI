# ΝΞΙΔ COMMUNITY — RunPod Template
## Workflow: NEIA-GERAR-VIDEOS-18 (Wan2.1 I2V +18)

---

## 📦 O que este template instala automaticamente

### Custom Nodes
| Node | Uso no Workflow |
|------|----------------|
| `rgthree-comfy` | Fast Bypasser (ON/OFF LoRAs) |
| `ComfyUI-Easy-Use` | `easy int`, `easy showAnything` |
| `ComfyUI-VideoHelperSuite` | `VHS_VideoCombine`, `LoadAudio` |
| `ComfyUI-WanVideoWrapper` | `WanImageToVideo` |
| `ComfyUI-Custom-Scripts` | `MathExpression\|pysssss` |
| `was-node-suite-comfyui` | `SimpleMath+` |
| `ComfyUI-Inspire-Pack` | `MarkdownNote` |
| `ComfyUI-OnDemand-LoRA` | `OnDemand Lora Loader` |
| `ComfyUI-Manager` | Gerenciador de nodes |

### Modelos Wan2.1 (baixados do HuggingFace)
| Arquivo | Tipo | VRAM recomendada |
|---------|------|-----------------|
| `Wan2_1-I2V-14B-480P_fp8_e4m3fn.safetensors` | Diffusion Model | 12~16GB |
| `wan_2.1_vae.safetensors` | VAE | — |
| `umt5-xxl-enc-bf16.safetensors` | Text Encoder | — |

---

## 🚀 Como usar no RunPod

### Opção A — Template com Docker (recomendado)

1. No RunPod, vá em **Templates → New Template**
2. Preencha:
   - **Template Name:** `NEIA-ComfyUI-Wan21`
   - **Container Image:** `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
   - **Docker Command:** cole o conteúdo abaixo
   - **Container Disk:** `20 GB`
   - **Volume Disk:** `100 GB` (para modelos)
   - **Expose HTTP Ports:** `3000`

**Docker Command (cole no campo Container Start Command):**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/neia_runpod_setup.sh)"
```

> Se não tiver o script no GitHub, suba o arquivo `neia_runpod_setup.sh` e use a URL raw.

---

### Opção B — Script manual no terminal

1. Crie o pod com qualquer template PyTorch (RunPod oficial)
2. Abra o terminal JupyterLab ou SSH
3. Execute:

```bash
wget -O /start.sh https://raw.githubusercontent.com/willastros-sketch/NEIA-COMFYUI/refs/heads/main/neia_runpod_setup.sh
chmod +x /start.sh
/start.sh
```

---

## 🔑 LoRAs do Civitai (opcional)

Para baixar as LoRAs automaticamente, defina sua API key antes de rodar:

```bash
export CIVITAI_TOKEN="seu_token_aqui"
/start.sh
```

Pegue seu token em: https://civitai.com/user/account → API Keys

---

## 💻 Requisitos de GPU recomendados

| Resolução | VRAM | GPU sugerida no RunPod |
|-----------|------|------------------------|
| 480p (480x480) | 8~12 GB | RTX 3080 / RTX 4080 |
| 640p (640x640) | 12~16 GB | RTX 4080 / A40 |
| 720p (720x720) | 16~24 GB | RTX 4090 / A100 |

---

## 🌐 Acessar ComfyUI

Após o pod iniciar, clique em **Connect → HTTP Service (porta 3000)** no painel RunPod.

O workflow **NEIA-GERAR-VIDEOS-18** abrirá automaticamente.

---

## 📝 Uso do Workflow

1. **Foto da modelo** → Node `FOTO DA SUA MODELO` (canto esquerdo)
2. **Prompt positivo** → Node verde `PROMPT AQUI`
3. **Duração** → Node ciano `DURAÇÃO VIDEO [Segundos]` (ex: 5 = 5 segundos)
4. **FPS** → Node laranja `FPS` (máx 30, recomendado 5~15)
5. **Dimensões** → Nodes azuis `LARGURA` e `ALTURA`
6. **LoRAs** → Nodes vermelhos `LOAD LORAS` (ative apenas o que usar)
7. **Áudio (opcional)** → Upload no node verde `UPLOAD AUDIO`
8. Clique **Queue Prompt** → vídeo salvo em `ComfyUI/output/`

---

*ΝΞΙΔ Community — Template gerado para uso no RunPod*
