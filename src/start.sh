#!/usr/bin/env bash

# Use libtcmalloc for better memory management
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# Handle RunPod serverless environment and network volume
if [ -d "/runpod-volume" ]; then
    echo "runpod-worker-comfy: Detected serverless environment with network volume"
    
    # Create directory structure if it doesn't exist
    mkdir -p /runpod-volume/models/{checkpoints,diffusion_models,text_encoders,vae,loras,clip,clip_vision,configs,controlnet,embeddings,upscale_models,unet}
    mkdir -p /runpod-volume/custom_nodes
    mkdir -p /runpod-volume/output
    
    # Create symlink between /runpod-volume and /workspace
    ln -sf /runpod-volume /workspace
    
    # Copy models if destination directories are empty
    for dir in diffusion_models text_encoders vae loras; do
        if [ -d "/comfyui/models/$dir" ] && [ "$(ls -A /comfyui/models/$dir 2>/dev/null)" ] && [ -z "$(ls -A /runpod-volume/models/$dir 2>/dev/null)" ]; then
            echo "runpod-worker-comfy: Copying $dir models to network volume..."
            cp -r /comfyui/models/$dir/* /runpod-volume/models/$dir/
        fi
    done
    
    # Copy custom nodes if destination is empty
    if [ -d "/comfyui/custom_nodes" ] && [ "$(ls -A /comfyui/custom_nodes 2>/dev/null)" ] && [ -z "$(ls -A /runpod-volume/custom_nodes 2>/dev/null)" ]; then
        echo "runpod-worker-comfy: Copying custom nodes to network volume..."
        cp -r /comfyui/custom_nodes/* /runpod-volume/custom_nodes/
    fi
    
    # Create symlinks from volume back to ComfyUI
    for dir in diffusion_models text_encoders vae loras; do
        if [ -d "/runpod-volume/models/$dir" ] && [ "$(ls -A /runpod-volume/models/$dir 2>/dev/null)" ]; then
            echo "runpod-worker-comfy: Creating symlinks for $dir models..."
            for file in /runpod-volume/models/$dir/*; do
                if [ -f "$file" ]; then
                    ln -sf "$file" "/comfyui/models/$dir/"
                fi
            done
        fi
    done
    
    # Create symlinks for custom nodes
    if [ -d "/runpod-volume/custom_nodes" ] && [ "$(ls -A /runpod-volume/custom_nodes 2>/dev/null)" ]; then
        echo "runpod-worker-comfy: Creating symlinks for custom nodes..."
        for dir in /runpod-volume/custom_nodes/*; do
            if [ -d "$dir" ]; then
                ln -sf "$dir" /comfyui/custom_nodes/
            fi
        done
    fi
fi

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    echo "runpod-worker-comfy: Starting ComfyUI"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --listen &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    echo "runpod-worker-comfy: Starting ComfyUI"
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata &

    echo "runpod-worker-comfy: Starting RunPod Handler"
    python3 -u /rp_handler.py
fi