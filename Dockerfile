# 1. Use the official PyTorch production base pre-compiled for CUDA 12.8
FROM pytorch/pytorch:2.11.0-cuda12.8-cudnn9-runtime

# 2. Establish non-root environmental variables for QuickPod & Blackwell compatibility
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    LM_BACKEND=pt \
    CPU_OFFLOAD=false \
    MAX_CUDA_VRAM=24000 \
    DIT_MODEL=base \
    ENABLE_LLM=true \
    HF_HUB_ENABLE_HF_TRANSFER=0 \
    PIP_EXTRA_INDEX_URL="https://pytorch.org"

# 3. Install core system audio utilities and compilers
RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl nano \
    ffmpeg python3.12-venv \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 4. Set up an isolated working directory inside user space
WORKDIR /workspace

# 5. HARDENED LAYER: Lock down modern package tools and NumPy 2.x compat layers
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip3 install --upgrade pip "setuptools==75.3.4" "wheel==0.47.0"
RUN pip3 install "pybind11>=2.12.0" "cython>=3.0.0"
RUN pip3 install numpy==1.26.4 scipy pandas huggingface_hub transformers accelerate hf_transfer
RUN pip3 install urllib3==2.7.0 pillow==12.2.0 filelock==3.20.3

# 6. Pull the official repository into the environment root directory
RUN git clone https://github.com/ace-step/ACE-Step-1.5.git

# 7. Force-recompile any local C-extensions to adhere to the hardened NumPy 2.x ABI
RUN if [ -f setup.py ]; then python3 setup.py build_ext --inplace; fi

# Expose the Gradio web service port for QuickPod templates
EXPOSE 7860

# Default execution command to launch the server natively via PyTorch backend
CMD ["python3", "-m", "acestep.serve.gradio_app"]
