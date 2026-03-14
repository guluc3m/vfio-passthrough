# Aislamiento de la tarjeta gráfica

## 1. Información

Para saber si la tarjeta gráfica está siendo usada ejecutamos
el siguiente comando:

```bash
sudo lsof /dev/nvidia* /dev/dri/cardX /dev/dri/renderDXXX
```

- Sustituir `/dev/nvidia*` si no queremos pasar una tarjeta
gráfica de NVIDIA
- `/dev/dri/cardX` y `/dev/dri/renderDXXX` deben referenciar a la tarjeta
gráfica que queremos pasar a la VM

Para encontrar `/dev/dri/cardX` y `/dev/dri/renderDXXX`:

```bash
for d in /dev/dri/card* /dev/dri/renderD*; do
  dev=$(basename $d)
  pci=$(readlink -f /sys/class/drm/$dev/device)
  name=$(lspci -s $(basename $pci) | cut -d' ' -f3-)
  echo "$d -> $name"
done
```

Para poder pasar la tarjeta gráfica en su totalidad a
la máquina virtual debemos evitar que esté en uso.

Para ello tenemos varios métodos, los cuales estarán explicados
con sus ventajas e inconveniencias.

### 1.1 Session Entry

La idea es en evitar el uso de la tarjeta gráfica en su totalidad,
desde Linux, y solamente darsela a la máquina virtual.

#### NVIDIA

Para **NVIDIA** esto se puede de una manera relativamente
sencilla con [nvidia-exec](https://github.com/pedro00dk/nvidia-exec)

Sencillamente lo instalamos (con el paquete `nvidia-exec` en AUR),
activamos el servicio con:

```bash
sudo systemctl enable nvx
sudo systemctl disable nvidia-powerd nvidia-persistenced
```

Finalmente hacemos nuestra `session entry`:

NOTA: Reemplazar XYZ por nuestra `Desktop Environment`, si no se sabe cual se
esta usando, se puede comprobar haciendo `ls /usr/share/wayland-sessions/`

```bash
cp /usr/share/wayland-sessions/XYZ.desktop /usr/share/wayland-sessions/XYZ-nvidia.desktop
```

Editamos `XYZ-nvidia.desktop` y modificamos lo siguiente:

De `Exec=XXX-session a Exec=nvx run XYZ-session`, también se debería
cambiar el nombre, con estas modificaciones nos acabaría quedando algo así:

```config
[Desktop Entry]
Name=XYZ (Nvidia)
Exec=nvx run XYZ-session
Type=Application
DesktopNames=XYZ
```

##### Ventajas

- Fácil de configurar
- Evitamos kernel panics por el vfio
- Podemos usar solamente los [hooks base de QEMU](./scripts_base/)

##### Desventajas

- `nvidia-exec` es inestable en algunos sistemas
- Debemos siempre ejecutar la sesión con `XYZ-nvidia` si queremos
usar la tarjeta gráfica dedicada en Linux
- Solo podemos encender la máquina virtual con la sesión `XYZ`

#### TODO: Otras GPUs

### 1.2 killall en las hooks

Este método es mucho mas complejo y **peligroso**, ya que cuando se
inicia la máquina virtual, matamos TODOS  los procesos que estén
usando la tarjeta gráfica, permitiendo así que la máquina virtual
pueda usarla sin problemas.

#### Vulkan

Por algun motivo cual desconozco, Vulkan mantiene una handle a todas
las tarjetas gráficas, incluso aunque no se estén usando.

Para evitar esto, debemos restringir que Vulkan acceda a nuestra `dGPU`,
haciendo uso del environment varible `VK_ICD_FILENAMES`,
el cual se encarga de decirle a Vulkan que tarjetas gráficas puede usar.

Primero hacemos una lista de las ICDs disponibles:

```bash
ls /usr/share/vulkan/icd.d/
```

En mi caso tengo una `iGPU` Intel y una `dGPU` NVIDIA,
por tanto la icd de intel es `intel_icd.x86_64.json`
y la de NVIDIA es `nvidia_icd.json`

Editamos `/etc/environment` y añadimos lo siguiente:

```bash
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.x86_64.json
```

NOTA: Reemplazar `intel_icd.x86_64.json` por la icd de nuestra `iGPU`

##### prime-run (NVIDIA)

Editamos `prime-run` para que Vulkan pueda seguir usando la `dGPU`:

NOTA: Para encontrar `prime-run` hacemos `which prime-run`

```bash
#!/bin/bash
__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"
```

Se debe agregar la parte de `VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json`
para que Vulkan vuelva a tener acceso a la `dGPU` cuando se ejecute con `prime-run`

##### AMD/Intel

AMD/Intel no tienen un script para ejecutar programas especificamente con la `dGPU`,
por lo que simplemente hacemos un script:

Por ejemplo, creamos `/usr/local/bin/vulkan-run` con el siguiente contenido
y lo hacemos ejecutable:

```bash
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json DRI_PRIME=1 "$@"
```

NOTA: Reemplazar `radeon_icd.x86_64.json` por la icd de nuestra `dGPU`

Cuando queramos ejecutar un programa con la `dGPU` simplemente hacemos

```bash
vulkan-run <programa>
```

#### Hooks "killall"

Estos hooks estan modificados a partir de los hooks base, con la ventaja que
mata a todos los procesos que estén usando la tarjeta gráfica

NOTA: No he encontrado ninguna manera de preguntar al usuario si
quiere matar los procesos o no, por lo que se matarán siempre

Están en [./hooks_killall/](./hooks_killall/), y reemplazan a los hooks base

```bash
cp /ruta/de/hooks_killall/* /etc/libvirt/hooks/
```

NOTA: Renombrar `/etc/libvirt/hooks/win11` por el nombre de nuestra máquina virtual

Luego, con la información del paso `1. Información`,
editamos los hooks `qemu` con los defines correctos.

##### En mi caso

[20-gpu-to-vfio](./hooks_killall/qemu.d/win11/prepare/begin/20-gpu-to-vfio.sh):

```bash
# Set these to your GPU / GPU audio
GPU="0000:01:00.0"
AUDIO="0000:01:00.1"

# Set to 1 for NVIDIA, 0 for AMD/other
USING_NVIDIA=1

# DRI nodes for the passthrough GPU
GPU_CARD="card0"
GPU_RENDER="renderD129"
```

[20-gpu-to-host](./hooks_killall/qemu.d/win11/release/end/20-gpu-to-host.sh)
(igual que antes):

```bash
# Set these to your GPU / GPU audio
GPU="0000:01:00.0"
AUDIO="0000:01:00.1"

# Set to 1 for NVIDIA, 0 for AMD/other
USING_NVIDIA=1
```

NOTA: Los valores de `GPU` y `AUDIO` deben ser los mismos en ambos hooks,
y deben estar en el mismo IOMMU, en [0-REQUISITOS.md](./0-REQUISITOS.md)
está explicado como comprobar esto y los valores correctos a poner
