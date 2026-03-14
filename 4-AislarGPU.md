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
gráfica que queremos pasar a la VM.

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

##### Desventajas

- `nvidia-exec` es inestable en algunos sistemas
- Debemos siempre ejecutar la sesión con `XYZ-nvidia` si queremos
usar la tarjeta gráfica dedicada en Linux
- Solo podemos encender la máquina virtual con la sesión `XYZ`

#### TODO: Otras GPUs

### 1.2 killall en las hooks
