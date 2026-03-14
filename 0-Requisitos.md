# Requisitos de software

## Archivos

- Obviamente se necesita una ISO de Windows, recomiendo Windows 11 IoT LTSC.
- Drivers de [virtio](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/)

NOTA: El driver para el Virtual Display NO funciona en Windows 10 IoT LTSC.

## Paquetes necesarios (Arch Linux)

- ```dkms```
- ```virt-manager```
- ```qemu-desktop```
- `edk2-ovmf`
- ```dmidecode``` (Para los anticheat)
- Un kernel con soporte para ```VFIO``` (para el tutorial usamos ```linux-zen```)
  - Nota: Se tiene que editar el bootloader (```GRUB, systemd-boot, ...```)
- ```looking-glass-module-dkms-git``` (AUR, está en [chaotic-aur](https://aur.chaotic.cx/))
- ```looking-glass-git``` (AUR, está en [chaotic-aur](https://aur.chaotic.cx/))

## Opciones de la BIOS

- Tarjeta gráfica dedicada activada
- ```VT-d``` y ```VT-x``` activado (Intel)
- ```IOMMU``` y ```NX``` activado (AMD)

## [Parametros de kernel](https://wiki.archlinux.org/title/Kernel_parameters_(Espa%C3%B1ol))

[IOMMU](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Enabling_IOMMU):

- Para AMD:
  - Se activa automaticamente con la opción de la BIOS
- Para Intel:
  - Agrega ```intel_iommu=on```
- Despues de estos cambios, reinicia

## Grupos de IOMMU

Ejecuta este script en una terminal:

```bash
#!/bin/bash
shopt -s nullglob
for g in /sys/kernel/iommu_groups/*; do
    echo "IOMMU Group ${g##*/}:"
    for d in $g/devices/*; do
        echo -e "\t$(lspci -nns ${d##*/})"
    done;
done;
```

Deberías ver una serie de grupos, aquí tienes que identificar tu dGPU.

A la maquina virtual deberás pasar TODOS los elementos del grupo. Por ejemplo:

```bash
IOMMU Group 20:
 01:00.0 VGA compatible controller [0300]: NVIDIA Corporation AD107GLM [RTX 2000 Ada Generation Laptop GPU] [10de:28b8] (rev a1)
 01:00.1 Audio device [0403]: NVIDIA Corporation AD107 High Definition Audio Controller [10de:22be] (rev a1)
```

Aquí tengo que pasar tanto el ```01:00.0``` (La tarjeta gráfica)
cómo ```01:00.1``` (Su dispositivo de audio).

NOTA IMPORTANTE: NO PASAR LOS ```Bridge```, (incluye los ```PCI Bridge```).

Puedes continuar [aquí](./1-VM.md)
