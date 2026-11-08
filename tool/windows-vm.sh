#!/usr/bin/env bash
# A VM de Windows para testar o player. Ela só roda o app: quem compila é o CI.
#
#   tool/windows-vm.sh install <arquivo.iso>   instala o Windows num disco novo
#   tool/windows-vm.sh run                     liga a VM
#   tool/windows-vm.sh serve [pasta]           serve a pasta (share/ da VM, se não
#                                              disser) em http://10.0.2.2:8000
#   tool/windows-vm.sh ssh-setup               cria a chave e o script que liga o SSH
#   tool/windows-vm.sh ssh [comando]           entra na VM, como VM_USER
#   tool/windows-vm.sh screenshot|click|move|scroll|key|type ...
#                                              tela, mouse e teclado da VM ligada
#
# Variáveis: VM_DIR (o disco, ~/vms/psito-player-windows), MEM (3G), SMP (4),
# AUDIO (pipewire, pa, none ou wav, que grava em AUDIO_FILE), DISK_SIZE (40G),
# SSH_PORT (2224) e VM_USER.
set -euo pipefail

VM_DIR="${VM_DIR:-$HOME/vms/psito-player-windows}"
MEM="${MEM:-3G}"
SMP="${SMP:-4}"
AUDIO="${AUDIO:-pipewire}"
DISK_SIZE="${DISK_SIZE:-40G}"
SSH_PORT="${SSH_PORT:-2224}"
DISK="$VM_DIR/disk.qcow2"
QMP="$VM_DIR/qmp.sock"
KEY="$VM_DIR/ssh_key"
SHARE="$VM_DIR/share"
AUDIO_FILE="${AUDIO_FILE:-$VM_DIR/audio.wav}"
HERE="$(cd "$(dirname "$0")" && pwd)"

boot() {
  local audiodev="$AUDIO,id=snd0"
  if [[ "$AUDIO" == wav ]]; then audiodev+=",path=$AUDIO_FILE"; fi
  qemu-system-x86_64 \
    -name "Psito Player - Windows" \
    -accel kvm \
    -cpu host,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_time \
    -m "$MEM" \
    -smp "$SMP" \
    -device ahci,id=ahci0 \
    -drive "id=disk0,if=none,format=qcow2,file=$DISK" \
    -device ide-hd,drive=disk0,bus=ahci0.0 \
    -nic "user,model=e1000,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22" \
    -qmp "unix:$QMP,server=on,wait=off" \
    -vga std \
    -usb -device usb-tablet \
    -audiodev "$audiodev" \
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
      --directory "${2:-$SHARE}"
    ;;
  ssh-setup)
    mkdir -p "$SHARE"
    [[ -e "$KEY" ]] || ssh-keygen -q -t ed25519 -N '' -C psito-player-vm -f "$KEY"
    # Como .txt: o .ps1 chega ao PowerShell como bytes, e o iex recusa
    # Por SID, porque o nome do grupo muda com o idioma do Windows
    cat > "$SHARE/ssh.txt" <<PS1
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service sshd -StartupType Automatic
Start-Service sshd
\$keys = "\$env:ProgramData\\ssh\\administrators_authorized_keys"
Set-Content -Path \$keys -Encoding ascii -Value '$(cat "$KEY.pub")'
icacls \$keys /inheritance:r /grant '*S-1-5-18:F' /grant '*S-1-5-32-544:F'
Write-Output "SSH pronto para \$env:USERNAME"
PS1
    echo "Na VM, no PowerShell de administrador, com o 'serve' ligado:"
    echo "  iex (iwr -UseBasicParsing http://10.0.2.2:8000/ssh.txt).Content"
    ;;
  ssh)
    shift
    exec ssh -i "$KEY" -p "$SSH_PORT" -o IdentitiesOnly=yes \
      -o StrictHostKeyChecking=accept-new \
      -o "UserKnownHostsFile=$VM_DIR/known_hosts" \
      "${VM_USER:?diga o usuário do Windows em VM_USER}@127.0.0.1" "$@"
    ;;
  screenshot|click|move|scroll|key|type)
    exec python3 "$HERE/windows_vm_ctl.py" "$QMP" "$@"
    ;;
  *)
    sed -n '2,17p' "$0"
    exit 1
    ;;
esac
