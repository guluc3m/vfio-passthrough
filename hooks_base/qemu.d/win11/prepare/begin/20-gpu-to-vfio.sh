#!/bin/bash
set -euo pipefail

# Set these to your GPU / GPU audio
GPU="0000:0X:00.0"
AUDIO="0000:0X:00.1"

# Set to 1 for NVIDIA, 0 for AMD/other
USING_NVIDIA=

GPU_VD="$(cat /sys/bus/pci/devices/${GPU}/vendor) $(cat /sys/bus/pci/devices/${GPU}/device)"
AUDIO_VD="$(cat /sys/bus/pci/devices/${AUDIO}/vendor) $(cat /sys/bus/pci/devices/${AUDIO}/device)"

bind_vfio() {
  echo "$GPU" > "/sys/bus/pci/devices/${GPU}/driver/unbind"
  echo "$AUDIO" > "/sys/bus/pci/devices/${AUDIO}/driver/unbind"
  echo "$GPU_VD" > /sys/bus/pci/drivers/vfio-pci/new_id
  echo "$AUDIO_VD" > /sys/bus/pci/drivers/vfio-pci/new_id
}

# Stop NVIDIA daemons that keep device nodes open
if [[ "$USING_NVIDIA" == "1" ]]; then
  systemctl stop nvidia-persistenced.service 2>/dev/null || true
  systemctl stop nvidia-powerd.service 2>/dev/null || true
fi

# Bind to vfio-pci
bind_vfio
