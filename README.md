# vfio-passthrough

Tutorial (en proceso) de cómo hacer una máquina virtual con la GPU en Linux.

<video controls src="./media/gpu_passthrough.mp4"></video>

## ATENCIÓN! ESTE TUTORIAL NO ES PARA PRINCIPIANTES

Para poder seguir este tutorial debes estar familiarizado con estos conceptos:

- [Parametros de kernel](https://wiki.archlinux.org/title/Kernel_parameters_(Espa%C3%B1ol))
- [Módulos DKMS](https://wiki.archlinux.org/title/Dynamic_Kernel_Module_Support_(Espa%C3%B1ol))
- Scripting en Bash
- Permisos de archivos
- La estructura de archivos en linux (``/dev, /etc, ...``)
- Permisos de usuarios
- Editores de archivos en terminal (``nano, nvim, ...``)

Este tutorial requiere de (hardware):

- 2 tarjetas gráficas
- Cantidad aceptable de RAM (subjetivo, recomiendo 16GB o más)
- Procesador ```x86_64``` compatible con aceleración virtual
- Placa base con soporte para ```UEFI```
- NOTA: NO hace falta un MUX switch, y se puede hacer en portátiles

Si tienes solamente 1 tarjeta gráfica:

- Revisa [esta guia](https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/home).
- Puedes usar ```SR-IOV``` para algunas tarjetas gráficas de Intel.
  - ```SR-IOV``` sirve para "particionar" la tarjeta y poder usar solo una parte de ella.

Esta guía se ha testeado en un portátil con las siguientes características:

- Dell Precision 5680
- Intel Core i9 13900H
- RTX 2000 Ada Generation (Mobile)
- 32GB RAM DDR5
- Sin MUX switch

En el siguiente software:

- Arch Linux
- ```linux-zen``` Kernel
- ```systemd-boot```
- pipewire

Términos:

- ```VM``` Máquina virtual
- ```Host``` La instancia actual (En mi caso el Arch Linux)
- ```Guest``` La instancia de la maquina virtual (En mi caso el Windows)
- ```iGPU``` La tarjeta gráfica que estará en el Host
- ```dGPU``` La tarjeta gráfica que vamos a pasar la VM / Guest

Entendiendo todo esto, puedes empezar [aquí](./0-Requisitos.md).
