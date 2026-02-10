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

NOTA: se pueden activar módulos por separado (mirar ```virtqemud*```)

Vamos a ```File > New Virtual Machine``` y seleccionamos las siguientes opciones:
