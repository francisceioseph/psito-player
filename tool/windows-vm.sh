#!/usr/bin/env bash
# A VM de Windows para testar o player. Ela só roda o app: quem compila é o CI.
#
#   tool/windows-vm.sh install <arquivo.iso>   instala o Windows num disco novo
#   tool/windows-vm.sh run                     liga a VM
#   tool/windows-vm.sh serve <pasta>           serve a pasta em http://10.0.2.2:8000
#                                              para o navegador da VM baixar
#
# Variáveis: VM_DIR (o disco, ~/vms/psito-player-windows), MEM (3G), SMP (4),
# AUDIO (pipewire, pa ou none) e DISK_SIZE (40G).
set -euo pipefail

VM_DIR="${VM_DIR:-$HOME/vms/psito-player-windows}"
MEM="${MEM:-3G}"
SMP="${SMP:-4}"
AUDIO="${AUDIO:-pipewire}"
DISK_SIZE="${DISK_SIZE:-40G}"
DISK="$VM_DIR/disk.qcow2"

boot() {
  qemu-system-x86_64 \
    -name "Psito Player - Windows" \
    -accel kvm \
    -cpu host,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_time \
    -m "$MEM" \
    -smp "$SMP" \
    -device ahci,id=ahci0 \
    -drive "id=disk0,if=none,format=qcow2,file=$DISK" \
    -device ide-hd,drive=disk0,bus=ahci0.0 \
    -nic user,model=e1000 \
    -vga std \
    -usb -device usb-tablet \
    -audiodev "$AUDIO,id=snd0" \
    -device ich9-intel-hda \
    -device hda-output,audiodev=snd0 \
    "$@"
}

case "${1:-}" in
  install)
    iso="${2:?diga o arquivo .iso do Windows}"
    if [[ -e "$DISK" ]]; then
      echo "Já existe um disco em $DISK. Use 'run', ou escolha outro VM_DIR." >&2
      exit 1
    fi
    mkdir -p "$VM_DIR"
    qemu-img create -q -f qcow2 "$DISK" "$DISK_SIZE"
    boot -cdrom "$iso" -boot once=d
    ;;
  run)
    if [[ ! -e "$DISK" ]]; then
      echo "Não há disco em $DISK. Comece com 'install'." >&2
      exit 1
    fi
    shift
    boot "$@"
    ;;
  serve)
    # Só no endereço local: a VM chega nele pelo 10.0.2.2
    exec python3 -m http.server 8000 --bind 127.0.0.1 \
      --directory "${2:?diga a pasta}"
    ;;
  *)
    sed -n '2,10p' "$0"
    exit 1
    ;;
esac
