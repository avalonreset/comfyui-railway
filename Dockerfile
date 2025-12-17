# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_ROOT_USER_ACTION=ignore

# ComfyUI config
ENV COMFYUI_DIR=/root/ComfyUI
ENV PORT=8188
# Preferred: CLI_ARGS. COMFYUI_ARGS is supported for backwards-compat.
ENV CLI_ARGS=
ENV COMFYUI_ARGS=

# Ollama (used by Ollama-related custom nodes)
ENV OLLAMA_API_URL=

# Pin refs for reproducible builds (override with --build-arg)
ARG COMFYUI_REF=master
ARG COMFYUI_MANAGER_REF=main

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    tini \
    python3.11 \
    python3.11-venv \
    python3.11-distutils \
    build-essential \
    libgl1 \
    libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
  && python3.11 /tmp/get-pip.py \
  && rm -f /tmp/get-pip.py

RUN git clone --depth 1 --branch "${COMFYUI_REF}" https://github.com/comfyanonymous/ComfyUI.git "${COMFYUI_DIR}"

WORKDIR ${COMFYUI_DIR}

# Ensure mount points exist
RUN mkdir -p "${COMFYUI_DIR}/models" "${COMFYUI_DIR}/input" "${COMFYUI_DIR}/output" "${COMFYUI_DIR}/user"

# CPU-only PyTorch wheels + ComfyUI requirements (no CUDA/GPU libs)
RUN python3.11 -m pip install --upgrade pip setuptools wheel \
  && python3.11 -m pip install --index-url https://download.pytorch.org/whl/cpu torch torchvision torchaudio \
  && python3.11 -m pip install -r requirements.txt \
  && apt-get purge -y --auto-remove build-essential \
  && rm -rf /var/lib/apt/lists/*

# Pre-install ComfyUI-Manager (YanWenKun CPU approach)
RUN mkdir -p "${COMFYUI_DIR}/custom_nodes" \
  && git clone --depth 1 --branch "${COMFYUI_MANAGER_REF}" https://github.com/ltdrdata/ComfyUI-Manager.git "${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager"

# Storage paths (do NOT declare Docker VOLUME here; Railway bans VOLUME instructions):
# - Models:    /root/ComfyUI/models
# - Inputs:    /root/ComfyUI/input
# - Outputs:   /root/ComfyUI/output
# - Workflows: /root/ComfyUI/user/default/workflows

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD python3.11 -c "import socket; s = socket.socket(); s.settimeout(5); s.connect(('127.0.0.1', 8188)); s.close()"

ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["python3.11", "/root/ComfyUI/main.py", "--cpu", "--listen", "0.0.0.0"]
