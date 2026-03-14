#!/usr/bin/env bash
set -euo pipefail

# ====== Configuration ========================================================
VM_NAME="${VM_NAME:-win11}"                  # libvirt domain name as seen by virsh
LIBVIRT_URI="${LIBVIRT_URI:-qemu:///system}" # try qemu:///session if you use user-session VMs
LG_BIN="${LG_BIN:-looking-glass-client}"     # or full path
LG_ARGS=(${LG_ARGS:-})                       # e.g. LG_ARGS="-F -S"
# ============================================================================

log() { printf '[%s] %s\n' "$(date +'%F %T')" "$*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "Missing required command: $1"
    exit 127
  }
}

require_cmd virsh
require_cmd "$LG_BIN"

VIRSH=(virsh -c "$LIBVIRT_URI")

cleanup() {
  if "${VIRSH[@]}" domstate "$VM_NAME" 2>/dev/null | grep -qi 'running'; then
    log "Shutting down VM: $VM_NAME"
    "${VIRSH[@]}" shutdown "$VM_NAME" >/dev/null 2>&1 || true

    for _ in {1..30}; do
      if ! "${VIRSH[@]}" domstate "$VM_NAME" 2>/dev/null | grep -qi 'running'; then
        log "VM stopped."
        return 0
      fi
      sleep 1
    done

    log "VM did not shut down in time; forcing power off."
    "${VIRSH[@]}" destroy "$VM_NAME" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT INT TERM

# Validate that the domain exists for the chosen URI
if ! "${VIRSH[@]}" dominfo "$VM_NAME" >/dev/null 2>&1; then
  log "Domain '$VM_NAME' not found using LIBVIRT_URI='$LIBVIRT_URI'."
  log "Try one of these to discover the right name/URI:"
  log "  virsh -c qemu:///system list --all"
  log "  virsh -c qemu:///session list --all"
  exit 1
fi

# Start VM if not already running.
if ! "${VIRSH[@]}" domstate "$VM_NAME" 2>/dev/null | grep -qi 'running'; then
  log "Starting VM in background: $VM_NAME"
  "${VIRSH[@]}" start "$VM_NAME" >/dev/null
else
  log "VM already running: $VM_NAME"
fi

log "Launching Looking Glass client..."
"$LG_BIN" "${LG_ARGS[@]}"

log "Looking Glass client exited; VM will be shut down."
# cleanup trap handles shutdown
