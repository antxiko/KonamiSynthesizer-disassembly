# Preguntas abiertas

Lo que sale del código pero no se ha probado, y lo que no está cerrado.

- **Las cuatro pantallas de SHIFT.** La copia de timbres, la lista, la
  impresora y LAYOUT salen del código; no están montadas desde la ROM ni
  cotejadas.
- **La impresora.** El volcado de la pantalla en puntos y la tabla de la onda
  (`0x5419`, `0x5516`) no se han probado con una impresora, ni se sabe para
  qué modelo son las secuencias de `0x54B6`.
- **El código de disco.** Las rutinas de grabar, cargar y borrar por la BDOS
  y la opción DISK del menú salen del código; no se ha probado nada con una
  unidad.
- **`RC741 86 5 31`.** Los trece bytes de `0xBF62` dicen el catálogo y, por
  la pinta, una fecha, 31 de mayo de 1986. No se sabe qué fecha es.
- **Los quince timbres con nombre y uno sin él.** El timbre 16 es una onda
  1 sin nada más: puede ser el timbre en blanco a propósito.
- **El relleno de `0x7135`.** Entre la última rutina de PLAY y las ondas hay
  203 bytes que no son código ni los lee nadie.
- **Los ciclos en una máquina real.** Lo medido (254 y 255 por muestra, con
  la espera M1) es de openMSX; en un MSX de verdad no se ha medido.
