#!/bin/bash
set -euo pipefail

# Set these to your GPU / GPU audio
GPU="0000:0X:00.0"
AUDIO="0000:0X:00.1"

# Set to 1 for NVIDIA, 0 for AMD/other
USING_NVIDIA=

GPU_VD="$(cat /sys/bus/pci/devices/${GPU}/vendor) $(cat /sys/bus/pci/devices/${GPU}/device)"
AUDIO_VD="$(cat /sys/bus/pci/devices/${AUDIO}/vendor) $(cat /sys/bus/pci/devices/${AUDIO}/device)"

unbind_vfio() {
  echo "$GPU_VD" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  echo "$AUDIO_VD" > "/sys/bus/pci/drivers/vfio-pci/remove_id"
  echo 1 > "/sys/bus/pci/devices/${GPU}/remove"
  echo 1 > "/sys/bus/pci/devices/${AUDIO}/remove"
  echo 1 > "/sys/bus/pci/rescan"
}

# Unbind from vfio-pci
unbind_vfio

# Restart NVIDIA daemons
if [[ "$USING_NVIDIA" == "1" ]]; then
  systemctl start nvidia-persistenced.service 2>/dev/null || true
  systemctl start nvidia-powerd.service 2>/dev/null || true
fi