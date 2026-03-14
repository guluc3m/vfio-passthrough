# QEMU Hooks

## Información

Un Hook de QEMU permite ejecutar un script en el `Host`
en base a algún cambio del estado de la `VM`
(encendido, apagado, etc)

Lo vamos a usar para "darle" la tarjeta gráfica a la `VM`,
y luego al apagarse devolversela a Linux.

También sirve para arreglar ciertos fallos que pueden surgir
si la tarjeta gráfica está siendo usada mientras
se intenta "bindear" a la `VM`

## Hooks Básicos

En [esta carpeta](./hooks_base/) están los scripts base,
para usarlos, se debe copiar los contenidos a
`/etc/libvirt/hooks/`:

```bash
sudo cp /ruta/a/hooks_base/* /etc/libvirt/hooks
```

### ¿Qué hacen los scripts?

#### [hooks_base/qemu](hooks_base/qemu)

[hooks_base/qemu](hooks_base/qemu) simplemente permite organizar
mejor los scripts en sus propias carpetas,
debido a esto se debe seguir la siguiente estructura:

```bash
/etc/libvirt/hooks/qemu.d/<domain>/<op>/<subop>/*.sh
```

Por ejemplo, esto es una `tree` válida:

```bash
❯ tree
.
├── qemu
└── qemu.d
    └── win11
        ├── prepare
        │   └── begin
        │       ├── 10-acl-libvirt.sh
        │       └── 20-gpu-to-vfio.sh
        └── release
            └── end
                └── 20-gpu-to-host.sh
```

- `win11` es el nombre de la VM
- `prepare/begin` es "antes de arrancar la VM"
- `release/end` es "despues de apagar la VM"

NOTA: Si la VM NO se llama `win11`, cambiar el
nombre de la carpeta

#### gpu-to/from-vfio.sh

[20-gpu-to-vfio.sh](hooks_base/qemu.d/win11/prepare/begin/20-gpu-to-vfio.sh)
le da la tarjeta gráfica a la VM

[20-gpu-to-host.sh](hooks_base/qemu.d/win11/release/end/20-gpu-to-host.sh)
le devuelve la tarjeta gráfica al host

Estos 2 scripts se deben modificar para que funcionen con tu tarjeta gráfica,
para eso, se deben cambiar las variables `GPU` y `AUDIO`

Editamos ambos scripts, y en el principio agregamos nuestros datos, en mi caso:

```bash
# Set these to your GPU / GPU audio
GPU="0000:01:00.0"
AUDIO="0000:01:00.1"

# Set to 1 for NVIDIA, 0 for AMD/other
USING_NVIDIA=1
```

NOTA: Los valores de `GPU` y `AUDIO` deben ser los mismos en ambos hooks,
y deben estar en el mismo IOMMU, en [0-Requisitos.md](./0-Requisitos.md)
está explicado como comprobar esto y los valores correctos a poner

Para hacer que los scripts funcionen debes completar
el siguiente paso, que está [aquí](./4-AislarGPU.md)
