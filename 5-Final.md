# Retoques Finales

En este punto la máquina virtual ya debería funcionar,
solamente queda configurar, instalar drivers y facilitar el
uso de la `VM`

## Software del Guest

### Drivers GPU

Instalamos los drivers de nuestra tarjeta gráfica
cómo en un ordenador normal dentro del `Guest`

### Virtual Display

Si queremos una resolución custom, modificamos (dentro del `Guest`) el archivo
`C:\VirtualDisplayDriver\vdd_settings.xml` y agregamos la resolución que queremos

## Comprobación

Con los Drivers instalados y el Virtual Display configurado, abrimos en el `Host`
el programa `looking-glass-client`

Se debería abrir una ventana con la pantalla del `Guest` y poder interactuar con ella

## Limpieza de Hardware

Apagamos la `VM`, vamos a la configuración de la `VM` y
eliminamos el hardware que ya no necesitamos:

- Serial Port
- Controller(s)
- etc

## Audio

Para que el audio funcione con Looking Glass, debemos pasarlo
directamente al PipeWire / PulseAudio del `Host`

### PipeWire

Debajo de `<\sound>` agregamos:

```xml
<audio id="1" type="pipewire" runtimeDir="/run/user/1000"/>
```

Creamos el hook
`/etc/libvirt/hooks/qemu.d/win11/prepare/begin/10-acl-libvirt.sh`
con este contenido:

```bash
#!/bin/bash
setfacl -m u:libvirt-qemu:x /run/user/1000
setfacl -m u:libvirt-qemu:rw /run/user/1000/pipewire-0
```

NOTA: Cambiamos `1000` por el UID del usuario que va a usar la `VM`
tanto en el hook como en el XML, `1000` es el default del primer
usuario creado en el sistema

### PulseAudio

Dentro de la sección `<qemu:commandline>` agregamos:

```xml
<qemu:arg value='-device'/>
<qemu:arg value='ich9-intel-hda,bus=pcie.0,addr=0x1b'/>
<qemu:arg value='-device'/>
<qemu:arg value='hda-micro,audiodev=hda'/>
<qemu:arg value='-audiodev'/>
<qemu:arg value='pa,id=hda,server=unix:/run/user/1000/pulse/native'/>
```

NOTA: Igual que arriba, en un equipo con múltiples usuarios,
el `server` debe apuntar al socket del usuario que va a usar la `VM`

Creamos el hook
`/etc/libvirt/hooks/qemu.d/win11/prepare/begin/10-acl-libvirt.sh`
con este contenido:

```bash
#!/bin/bash
setfacl -m u:libvirt-qemu:x /run/user/1000
setfacl -m u:libvirt-qemu:rw /run/user/1000/pulse/native
```

## Script para iniciar la VM

Para que sea más fácil iniciar la `VM`, he proporcionado [aquí](./vm-entry/)
archivos relevantes para hacer un script de inicio rápido

Para agregar la desktop entry, ejecutamos:

```bash
cp ./vm-entry/win11-looking-glass.desktop ~/.local/share/applications/
cp ./vm-entry/run-win11-vm.sh ~/.local/bin/
cp ./vm-entry/windows-color-icon.png ~/.local/share/icons/hicolor/256x256/apps/
chmod +x ~/.local/bin/run-win11-vm.sh
```

Y ya estaría, ahora podemos buscar `Windows 11` en el menú de
aplicaciones y abrir la `VM` con un click

NOTA: Cuando se cierra looking glass, la `VM` se apaga,
si queremos cambiar este comportamiento se debe editar el script `run-win11-vm.sh`.
