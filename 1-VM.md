# Configuración de la VM (Guest)

## Recopilando información

NOTA IMPORTANTE: ESTE PASO ES OPCIONAL, Y SIRVE SOLAMENTE PARA QUE LA MAQUINA VIRTUAL
NO SEA DETECTADA POR ANTICHEATS, ESTO PUEDE DEJAR DE FUNCIONAR EN CUALQUIER
MOMENTO, NO NOS HACEMOS RESPOSABLES DE CUALQUIER BAN CAUSADO POR ESTO.

Ejecutamos el siguiente comando:

```bash
sudo dmidecode
```

O si es demasiado texto:

```bash
sudo dmidecode --type <tipo>
```

Con la información, edita el siguiente "molde" con tu
información y agrega llaves si es necesario:

```xml
<sysinfo type="smbios">
  <bios>
    <entry name="vendor">LENOVO</entry>
  </bios>
  <system>
    <entry name="manufacturer">Microslop</entry>
    <entry name="product">Windows10</entry>
    <entry name="version">10.11345</entry>
  </system>
  <baseBoard>
    <entry name="manufacturer">LENOVO</entry>
    <entry name="product">20BE0061MC</entry>
    <entry name="version">0B98401 Pro</entry>
    <entry name="serial">W1KS427111E</entry>
  </baseBoard>
  <chassis>
    <entry name="manufacturer">Dell Inc.</entry>
    <entry name="version">2.12</entry>
    <entry name="serial">65X0XF2</entry>
    <entry name="asset">40000101</entry>
    <entry name="sku">Type3Sku1</entry>
  </chassis>
  <oemStrings>
    <entry>myappname:some arbitrary data</entry>
    <entry>otherappname:more arbitrary data</entry>
  </oemStrings>
</sysinfo>
```

NOTA: Si has decidido agregar la clave de UUID, guárdala, la necesitaras luego.

## Creando la máquina virtual

Ejecutamos ```virt-manager```

Si aparece ```QEMU/KVM Not Connected```, se debe activar el servicio de ```systemd```:

```bash
sudo systemctl enable --now libvirtd
```

NOTA: se pueden activar módulos por separado (mirar ```virtqemud*```), si se decide
activar módulos por separado, desactivar `libvirtd` para evitar conflictos.

### Opciones de virt-manager

Vamos a Edit > Preferences > General > Enable XML editing activado

### Opciones de creación de la VM

Vamos a ```File > New Virtual Machine``` y seleccionamos las siguientes opciones:

#### Step 1 of 5

- `Local install media (ISO image or CDROM)`
- Architecture options > Architecture: `x86_64`

#### Step 2 of 5

- `Browse > Local > Buscar la imagen ISO de Windows`
- NOTA: Si no se detecta automaticamente el sistema operativo, desactivar
`Automatically detect operating system` y seleccionar la versión de Windows
que se va a instalar.

#### Step 3 of 5

En la pestaña `Memory and CPU`, asignar la cantidad de memoria RAM y
núcleos de CPU que se le va a asignar a la máquina virtual.

Recomendamos la mitad de los nucleos de la CPU y la mitad de la RAM.

#### Step 4 of 5

- `Enable storage for this virtual machine` activado
- `Create a disk image for the virtual machine` seleccionado
  - Aquí ponemos la cantidad de almacenamiento que se le va a asignar
  a la máquina virtual, recomendamos al menos 50GB.

#### Step 5 of 5

- Activamos "Customize configuration before install"
- Si sale "Virtual network is not active." entonces se debe activar la red
virtual con el comando:

```bash
sudo virsh net-autostart --network default
```

### Opciones de la VM

#### NOTA: Seguir los pasos con MUCHO cuidado

#### 1. Overview

- Chipset: `Q35`
- Firmware: `UEFI x86_64: OVMF_CODE_secboot.fd` para Windows 11
- `UEFI x86_64: OVMF_CODE.fd` para Windows 10
  - NOTA: Si NO sale, se debe instalar el paquete `edk2-ovmf`
  y reiniciar `virt-manager`

#### 2. CPUs

- Activar `Copy host CPU configuration (host-passthrough)`

##### Para procesadores Intel de 12ava en adelante

Ejecutamos el comando: ```lscpu -e=CPU,MAXMHZ```

```bash
❯ lscpu -e=CPU,MAXMHZ
CPU    MAXMHZ
  0 5200.0000
  1 5200.0000
  2 5200.0000
  3 5200.0000
  4 5400.0000
  5 5400.0000
  6 5400.0000
  7 5400.0000
  8 5200.0000
  9 5200.0000
 10 5200.0000
 11 5200.0000
 12 4100.0000
 13 4100.0000
 14 4100.0000
 15 4100.0000
 16 4100.0000
 17 4100.0000
 18 4100.0000
 19 4100.0000
```

Aquí observamos 2 grupos marcados, del nucleo 0-12 tenemos una
frecuencia de 5200-5400MHz, y del nucleo 12-19 tenemos una frecuencia de 4100MHz,
esto se debe a que los nucleos 0-12 son nucleos de rendimiento,
y los nucleos 12-19 son nucleos de eficiencia,
por lo tanto, se deben asignar los nucleos de rendimiento a
la máquina virtual, en este caso, los nucleos 0-11.

Para estar completamente seguros, se puede hacer lo siguiente:

```bash
❯ lscpu | grep 'Model name' | cut -f 2 -d ":" | awk '{$1=$1}1'
13th Gen Intel(R) Core(TM) i9-13900H
```

Con el modelo de la CPU, lo buscamos online para ver las características

- En mi caso:
  - Tengo 20 hilos, 6 P-cores (cada uno tiene 2 hilos) y 8 E-cores
  - A la maquina virtual le asigno los 6 P-cores, es decir, los hilos 0-11

Por tanto mi configuración de CPU quedaría así:

```xml
<vcpu placement="static">12</vcpu>
<cputune>
  <vcpupin vcpu="0" cpuset="0"/>
  <vcpupin vcpu="1" cpuset="1"/>
  <vcpupin vcpu="2" cpuset="2"/>
  <vcpupin vcpu="3" cpuset="3"/>
  <vcpupin vcpu="4" cpuset="4"/>
  <vcpupin vcpu="5" cpuset="5"/>
  <vcpupin vcpu="6" cpuset="6"/>
  <vcpupin vcpu="7" cpuset="7"/>
  <vcpupin vcpu="8" cpuset="8"/>
  <vcpupin vcpu="9" cpuset="9"/>
  <vcpupin vcpu="10" cpuset="10"/>
  <vcpupin vcpu="11" cpuset="11"/>
  <emulatorpin cpuset="12-19"/>
</cputune>
```

Esto va en el XML de la máquina virtual. Para editar el XML,
vamos a `Overview > XML` y metemos este trozo de código dentro de la etiqueta `<domain>`.

#### Para otros procesadores

- Asignar los nucleos deseados, se recomienda un mínimo de 4.

#### 3. SMBIOS (OPCIONAL)

Este paso complementa el apartado de `Recopilando información`,
  en caso que no se siga, este paso se puede omitir.

- Cogemos el XML que guardamos del apartado `Recopilando información`
  y lo pegamos dentro del XML de la máquina virtual.
  Para editar el XML, vamos a `Overview > XML`
  y metemos este trozo de código dentro de la etiqueta `<domain>`.
- Cambiamos el valor de `uuid` al valor que guardamos
  del apartado `Recopilando información`.

#### 4. Hardware añadido

Para agregar hardware, le damos a la pestaña `Add Hardware` y
seleccionamos el hardware que queremos agregar.

Debemos agregar:

- VirtIO Keyboard
- VirtIO Mouse / Tablet
- Storage
  - Device type: `CDROM device`
  - Bus type: `SATA`
  - Seleccionamos la imagen ISO de VirtIO

#### 5. Hardware modificado

Cambiamos parte del hardware para mejorar el rendimiento.

- SATA Disk 1
  - Disk bus: `VirtIO`
- NIC
  - Device model: `virtio`
- Video
  - Video model: `VGA`

#### Le damos a `Begin Installation` y seguimos los pasos para instalar Windows

- Cuando tengamos que seleccionar el disco para instalar Windows,
  no aparecerá ningún disco, para solucionarlo, le damos a `Load driver`
  y seleccionamos el CD con la ISO del VirtIO que agregamos anteriormente,
  luego navegamos a amd64/w11 en Windows 11 o amd64/w10 en Windows 10
  y seleccionamos el archivo `viostor.inf`

Puedes continuar con el tutorial [aquí](2-HOST.md)
