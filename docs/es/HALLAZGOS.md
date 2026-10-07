# Hallazgos

Cada uno dice de dónde sale: del código, de una tabla de la ROM o de una
medida en openMSX. Las medidas se cuentan en [En el emulador](EN-EL-EMULADOR.md).

## Un sintetizador dentro del Z80

El cartucho no lleva ningún chip de sonido: lleva un DAC de 8 bits en
`0x4000`, y el programa es un sintetizador sustractivo que calcula la nota
muestra a muestra (`0x5767`): oscilador con catorce ondas, filtro de dos
etapas con resonancia, amplificador, tres envolventes ADSR y un LFO con
muestreo y retención. Lo escribe todo en los 16 KB de `0x8000` y luego lo
toca.

*Medido en openMSX*: `tools/motor.py`, el motor escrito de nuevo, da los
dieciséis timbres de fábrica byte a byte iguales que los que el Z80 escribe
en `0x57B0`.

## La altura de la nota es un bucle de ciclos

PLAY no cambia la frecuencia de nada: manda el sample al DAC byte a byte y
espera entre uno y otro. Cada tecla tiene una rutina de trece y un retardo D
(`0x5DA9`), y las trece rutinas son el mismo bucle con distinto relleno de
instrucciones que no hacen nada. Contadas, la rutina r cuesta **59 + r + 14
× D** ciclos por muestra: las trece son un ajuste fino de un ciclo.

*Medido en openMSX*: con la rutina 9 y D = 11 (LA3), 254,37 ciclos de media
entre escrituras al DAC, 254 y 255; con la espera M1 del MSX son 67 + 16 × D
en la rutina 0. Y es monofónico: una tecla cada vez (`0x5EA5`).

## El sample vive en la RAM del ordenador

El cartucho no tiene RAM. Antes de sintetizar, tocar o cargar un SAMP, `0x4105`
pone en `0x8000`-`0xBFFF` la ranura de la RAM que apuntó al arrancar
(`0xD854`), y `0x410D` devuelve el cartucho, que es donde están los gráficos
de las pantallas. Hace falta RAM en `0x8000`: un MSX de 16 KB no la tiene.

*Medido en openMSX*: durante SYN la página 2 es la ranura 3 (`A8 = 0xF4`) y
cada byte escrito se queda.

## El ruido viene de la BIOS

La onda 15 del oscilador y el muestreo y retención del LFO no son una tabla:
`0x5AD4` lee de `0x0000` en adelante, la ROM de la BIOS, gira cada byte y lo
acumula. **El ruido depende del ordenador**: el timbre 14 (PARC1) suena
distinto en cada máquina, y `tools/sonido.py` necesita los 256 primeros
bytes de una BIOS para fabricarlo.

## El DAC arranca sin golpe

La primera rutina de interrupción (`0x4118`) solo sube el DAC de 0 a `0x80`,
un paso por interrupción, y a las 129 le pasa el gancho a la de cada cuadro.
Sale del código.

## TONE, LAYOUT y SAMP

Tres ficheros para cinta y disco, con la longitud delante y, en los SAMP, la
página de bucle: TONE son los dieciséis timbres **con sus dieciséis ondas**
(4.608 bytes), LAYOUT la nota de cada tecla con su rutina y su retardo (176),
y SAMP el sample entero (hasta 16 KB). Sale del código, y la cinta que
venía con el cartucho lo confirma: siete SAMP, de 3.072 a 16.384 bytes. La
ROM lleva también rutinas para disco (`.T`, `.K` y `.S` por la BDOS) y una
opción DISK que solo se pinta si hay una unidad (`H.PHYD`); no están
probadas.

## La segunda página del menú

SHIFT cambia el menú de abajo (`0x48B2`): F1 copia un timbre y su onda en
otro, F2 lista los dieciséis, F3 imprime la pantalla, y F4 es LAYOUT, donde
cada tecla del teclado musical recibe la nota que se elija (`0xBBA4`); CTRL
y HOME vuelven al de fábrica. Sale del código: estas cuatro pantallas no
están montadas desde la ROM.

## El ataque no guarda su fase

En las tres envolventes, al entrar en el ataque paso a paso (`0x5849`,
`0x58F5`, `0x598F`), el programa carga en HL la rutina de la fase y no la
guarda en el puntero, al revés que en la caída y la relajación. Funciona
igual, porque vuelve a entrar por el principio cada muestra; son tres `ld
hl` de tres bytes que no sirven para nada.

## Lo que nadie llama, y la marca

Diez trozos de código que no llama nadie: un `jp` detrás de la cabecera
(`0x4012`), un cargador de gráficos por tabla de seis bytes en `0x5800` que
no existe (`0x49CD`), copias sueltas de rutinas de FILE y de la impresora
(`0x520A`, `0x522A`, `0x54A4`), una búsqueda en una lista (`0xBCA2`)… Y
`0xB834`, que solo corre desde su copia en RAM.

En `0xBF62` la ROM dice `RC741 86 5 31`, y en sus diez últimos bytes lleva la
marca oculta de Konami: シンセサイザー, RC-741. El formato de esa marca lo
descubrió **Manuel Pazos**, y a él se le dan las gracias; `tools/marca_konami.py`
la lee.
