#!/bin/bash
set -euo pipefail

# Set these to your GPU / GPU audio
GPU="0000:0X:00.0"
AUDIO="0000:0X:00.1"

# Set to 1 for NVIDIA, 0 for AMD/other
USING_NVIDIA=

# DRI nodes for the passthrough GPU
GPU_CARD="cardX"
GPU_RENDER="renderDXXX"

GPU_VD="$(cat /sys/bus/pci/devices/${GPU}/vendor) $(cat /sys/bus/pci/devices/${GPU}/device)"
AUDIO_VD="$(cat /sys/bus/pci/devices/${AUDIO}/vendor) $(cat /sys/bus/pci/devices/${AUDIO}/device)"

KILLALL_BIN="/usr/bin/killall"
LSOF_BIN="/usr/bin/lsof"

gpu_device_nodes() {
  # Always check DRI nodes; add /dev/nvidia* when NVIDIA is used.
  local nodes=("/dev/dri/${GPU_CARD}" "/dev/dri/${GPU_RENDER}")
  if [[ "$USING_NVIDIA" == "1" ]]; then
    nodes+=(/dev/nvidia*)
  fi
  for n in "${nodes[@]}"; do
    if [[ -e "$n" ]]; then
      echo "$n"
    fi
  done
}

gpu_holders_pids() {
  # Print PIDs holding GPU device nodes (empty if none).
  local nodes
  nodes="$(gpu_device_nodes)"
  [[ -z "$nodes" ]] && return 0
  "$LSOF_BIN" -t $nodes 2>/dev/null | sort -u || true
}

gpu_holders_names() {
  # Print COMMAND names holding GPU device nodes (empty if none), WITHOUT truncation.
  # Using lsof's machine-readable format avoids process truncation.
  local nodes
  nodes="$(gpu_device_nodes)"
  [[ -z "$nodes" ]] && return 0
  "$LSOF_BIN" -F c $nodes 2>/dev/null \
    | sed -n 's/^c//p' \
    | awk 'NF' \
    | sort -u || true
}

is_name_still_holding_gpu() {
  local name="$1"
  local nodes
  nodes="$(gpu_device_nodes)"
  [[ -z "$nodes" ]] && return 1
  "$LSOF_BIN" -nP $nodes 2>/dev/null | awk -v n="$name" 'NR>1 && $1==n {found=1} END{exit found?0:1}'
}

kill_by_name() {
  local name="$1"
  [[ -z "$name" ]] && return 0

  "$KILLALL_BIN" -TERM "$name" 2>/dev/null || true

  # Wait up to ~1s for THIS NAME to stop holding
  for _ in {1..20}; do
    if ! is_name_still_holding_gpu "$name"; then
      return 0
    fi
    sleep 0.05
  done

  "$KILLALL_BIN" -KILL "$name" 2>/dev/null || true

  # Wait up to ~1s more after SIGKILL
  for _ in {1..20}; do
    if ! is_name_still_holding_gpu "$name"; then
      return 0
    fi
    sleep 0.05
  done

  return 1
}

kill_gpu_holders_with_killall() {
  local passes="${1:-8}"
  local pass names pids

  for pass in $(seq 1 "$passes"); do
    pids="$(gpu_holders_pids)"
    if [[ -z "$pids" ]]; then
      return 0
    fi

    "$LSOF_BIN" $(gpu_device_nodes) 2>/dev/null || true

    mapfile -t names < <(gpu_holders_names)
    if ((${#names[@]} == 0)); then
      sleep 0.2
      continue
    fi

    for n in "${names[@]}"; do
      kill_by_name "$n" || true
    done

    sleep 0.2
  done

  # Final check
  pids="$(gpu_holders_pids)"
  if [[ -n "$pids" ]]; then
    "$LSOF_BIN" $(gpu_device_nodes) 2>/dev/null || true
    return 1
  fi
  return 0
}

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

# Kill everything currently holding GPU device nodes (by NAME via killall)
kill_gpu_holders_with_killall 10

# Refuse to continue if something still holds GPU device nodes
if [[ -n "$(gpu_holders_pids)" ]]; then
  "$LSOF_BIN" $(gpu_device_nodes) 2>/dev/null || true
  exit 1
fi

# Bind to vfio-pci
bind_vfio
