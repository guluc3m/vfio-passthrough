# Looking Glass

Esta herramienta es la que nos permite usar nuestra tarjeta gráfica dedicada
exclusivamente para la VM, sin darle la salida de video
directamente a la máquina virtual.

- Las ventajas de esto son
  - Tener la máquina virtual como una "ventana" de Linux.
  - Una latencia muy baja.
  - Posibilidad de cualquier resolución y frecuencia de refresco.

## [Configuración del host](https://looking-glass.io/docs/B7/ivshmem_kvmfr/)

Asumiendo que tenemos instalado el módulo de kernel
`looking-glass-module-dkms`:

Debemos determinar la memoria del buffer para pasar la "imagen"
del Guest al Host.

### Formula para calcular la memoria del buffer

La cantidad de memoria necesaria para almacenar un frame se calcula así:

$$
\text{Memoria (MB)} = \frac{(\text{Pixeles Ancho}
\times \text{Pixeles Alto} \times \text{Bytes por Pixel} \times 2)}{1024^2} + 10
$$

Luego, el resultado se redondea **hacia arriba a
la siguiente potencia de 2**, es decir:

$$
\text{Memoria reservada (MB)} = 2^{\lceil \log_2(\text{Memoria (MB)}) \rceil}
$$

---

#### Ejemplo: 1080p SDR (1920 × 1080, 4 bytes por píxel)

1. **Cálculo base:**

$$
\frac{(1920 \times 1080 \times 4 \times 2)}{1024^2}
$$

$$
1920 \times 1080 = 2,\!073,\!600
$$

$$
2,\!073,\!600 \times 4 \times 2 = 16,\!588,\!800
$$

$$
\frac{16,\!588,\!800}{1,\!048,\!576} \approx 15.83~\text{MB}
$$

1. **Sumar 10 MB:**

$$
15.83 + 10 = 25.83 ~\text{MB}
$$

1. **Redondear a la siguiente potencia de 2:**

$$
2^{\lceil \log_2(25.83) \rceil} = 2^{5} = 32~\text{MB}
$$

NOTA: Bytes por Pixel es 4 para SDR, y 8 para HDR.

---

### Implementando el buffer IVSHMEM

#### Configuración del módulo

Editamos el archivo `/etc/modprobe.d/kvmfr.conf` **con la cantidad
de memoria calculada**, por ejemplo para 32MB:

```bash
options kvmfr static_size_mb=32
```

#### Cargamos el módulo

Para cargar el módulo con la nueva configuración cada vez
que iniciamos el sistema, creamos el archivo `/etc/modules-load.f/kvmfr.conf`
con el siguiente contenido:

```bash
# KVMFR Looking Glass module
kvmfr
```

A continuación, recargamos el módulo o **reiniciamos el
sistema** para aplicar los cambios.

Para comprobar que el módulo se ha cargado correctamente,
podemos usar el siguiente comando:

```bash
ls -l /dev/kvmfr0
crw------- 1 root root 242, 0 Mar  5 05:53 /dev/kvmfr0
```

NOTA: Si no aparece el dispositivo `/dev/kvmfr0`, es posible que el módulo
no se haya cargado correctamente o que la configuración no sea correcta.
En ese caso, revisa los pasos anteriores y asegúrate de que el módulo
esté configurado y cargado correctamente.

### Permisos de /dev/kvmfr0

Asumiendo que el grupo usado para las máquines virtuales es `kvm`,
le damos permisos al dispositivo `/dev/kvmfr0` para que los usuarios del grupo
usando reglas de udev, para ello editamos el archivo
`/etc/udev/rules.d/99-kvmfr.rules` con el siguiente contenido:

```bash
SUBSYSTEM=="kvmfr", OWNER="user", GROUP="kvm", MODE="0660"
```

NOTA: **REEMPLAZA "user" CON TU NOMBRE DE USUARIO**.

---

### Configuración de la VM

Volviendo al XML de la máquina virtual, debemos reemplazar la
primera línea con:

```XML
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

A continuación, al final del documento, pegamos:

```XML
<qemu:commandline>
  <qemu:arg value="-device"/>
  <qemu:arg value="{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"/>
  <qemu:arg value="-object"/>
  <qemu:arg value="{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':33554432,'share':true}"/>
</qemu:commandline>
```

---

#### IMPORTANTE: Valor de 'size'

El valor del argumento `size` en el XML que pegamos anteriormente debe
ser igual a la cantidad de memoria, expresada en **bytes**,
calculada previamente para el buffer IVSHMEM.

Para convertir MB a bytes:

$$
\text{size} = \text{Memoria reservada (MB)} \times 1024 \times 1024
$$

**Ejemplo:**  
Si el cálculo anterior da 32 MB, entonces:

```
size = 32 * 1024 * 1024 = 33554432
```

---

Puedes continuar aquí
