# El programa

*Konami's Synthesizer* no es un juego: es un sintetizador. El cartucho lleva
un convertidor digital-analógico de 8 bits que suena con cada byte que el Z80
escribe en `0x4000`, y el programa es un sintetizador sustractivo (oscilador,
filtro, amplificador, tres envolventes y un LFO) que **calcula la nota muestra
a muestra** en la RAM del ordenador y luego la toca por ese convertidor. Todo
lo que suena lo hace el Z80.

![El título](../imagenes/titulo.png)

Al encender, el logotipo de Konami se destapa línea a línea, el 新世SIZER se
pinta en siete pasadas, un byte de cada ocho en cada una, y el título espera
un SPACE. Si no
llega, la intro enseña durante 512 cuadros una de las cuatro pantallas del
programa (`0xBE5E`) y vuelve a empezar.

## Las pantallas

Cinco teclas de función, y con SHIFT otras cuatro (`0x4877`):

| tecla | pantalla |
|---|---|
| F1 | TONE EDIT: los 29 campos del timbre |
| F2 | WAVE EDIT: dibujar una onda a mano |
| F3 | SYN: sintetizar el timbre |
| F4 | PLAY: tocar |
| F5 | FILE: la cinta |
| SHIFT F1 | copiar un timbre, con su onda, en otro |
| SHIFT F2 | la lista de los dieciséis timbres |
| SHIFT F3 | la impresora |
| SHIFT F4 | LAYOUT: qué nota da cada tecla |

![TONE EDIT con el timbre 1](../imagenes/tone-01.png)

**TONE EDIT** (`0xA5AA`) edita los 25 parámetros del timbre y su nombre.
El oscilador (DCO) elige una de las catorce ondas de la ROM, la del usuario o
ruido, y su altura en pies; el filtro (DCF) tiene corte, resonancia de 0 a 8
y tres salidas, paso alto, paso banda y paso bajo; el amplificador (DCA)
tiene su envolvente, y cada una de las tres envolventes es ADSR. El LFO puede
mover al oscilador, al filtro y al amplificador, con su propia onda y, con
S/H, con ruido muestreado. Los cursores van de campo en campo, INS y DEL
suben y bajan, y las cifras escriben el valor.

![WAVE EDIT](../imagenes/wave.png)

**WAVE EDIT** (`0xADF7`) dibuja a mano la onda 15, la del usuario: 256
muestras con signo, un punto por muestra. Las dieciséis ondas del usuario
(una por timbre) arrancan como la onda 1, un seno (`0x55CF`). Izquierda y
derecha mueven el cursor de paso en paso (MODE, SELECT lo cambia), arriba y
abajo cambian la muestra y el tramo entre el cursor y su paso anterior se
rellena en línea recta (`0xB236`). Una tecla del teclado musical la hace
sonar; CTRL y HOME la ponen a cero.

![SYN](../imagenes/syn.png)

**SYN** (`0x55F0`) es el sintetizador: calcula la nota entera, muestra a
muestra, en los 16 KB de `0x8000` a `0xBFFF`, con la pantalla parada y las
interrupciones cerradas. Cuánto dura la calcula de las envolventes
(`0x5613`), y mientras trabaja un cursor avanza por la pantalla y, cada 16
tics, cambian dos tiles del dibujo (`0x4BD9`). Al acabar salta a PLAY; F1, F2, F4 y F5 la
cortan (`0x5767`).

![PLAY](../imagenes/play.png)

**PLAY** (`0x5D3A`) toca con el teclado del MSX como si fuera un piano: las
cuatro filas de letras y números son 48 teclas, blancas y negras, con la
nota de cada una escrita encima según el LAYOUT; el de fábrica da nota a 40
(`0x4B71`). Suena **una tecla cada
vez**: el programa lee el sample y lo manda al DAC byte a byte, y la altura
de la nota la pone cuánto tarda entre byte y byte ([Hallazgos](HALLAZGOS.md)).
Con el EG TYP del timbre en DEC, la nota se sostiene mientras se tiene la
tecla repitiendo una página del sample, y al soltar sigue hasta el final; en
DUR suena entera de una vez.

![FILE MODE](../imagenes/file.png)

**FILE** (`0xB5DB`) graba y carga en cinta tres clases de fichero: TONE
(los dieciséis timbres con sus dieciséis ondas, 4.608 bytes), LAYOUT (176
bytes) y SAMP (el sample sintetizado, hasta 16 KB, con su página de bucle).
El formato está en [El código](EL-CODIGO.md). La cinta que venía con el
cartucho trae en sus dos caras siete SAMP: PIANO, BRASS y ORCHE de 16.384
bytes, TRUMPET de 12.288, SAMISEN de 7.792, DOG de 3.072 y CRASH de 16.384.

## Los dieciséis timbres de fábrica

Están en la ROM, en `0xA3AA`, 32 bytes cada uno: 25 parámetros y el nombre.
Así los enseña TONE EDIT (los ADSR como ataque/caída/sostenido/relajación,
el filtro con su salida, `-` si la envolvente del filtro resta e `i` si la
del oscilador va invertida):

| n | nombre | onda | FEET | LFO DCO | ENV DCO | CUT | RES | LFO DCF | ENV DCF | LFO DCA | ADSR DCO | ADSR DCF | ADSR DCA | S/H | onda LFO | FEET LFO | filtro | EG |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | EBASS1 | 2 | 16' | 0 | 0 | 0 | 0 | 0 | 128 | 0 | 0/0/0/0 | 0/4/32/96 | 0/0/255/12 | 0 | 1 | 64.00' | LPF | DEC |
| 2 | EBASS2 | 14 | 32' | 0 | 0 | 0 | 0 | 0 | 128 | 0 | 0/0/0/0 | 0/4/32/96 | 0/0/255/12 | 0 | 1 | 64.00' | LPF | DEC |
| 3 | BRASS | 2 | 8' | 0 | 0 | 20 | 0 | 0 | 128 | 0 | 0/0/0/0 | 1/6/64/4 | 0/0/255/15 | 0 | 1 | 64.00' | LPF | DEC |
| 4 | TRUMPET | 12 | 8' | 0 | 0 | 20 | 0 | 0 | 128 | 0 | 0/0/0/0 | 1/6/64/4 | 0/0/255/15 | 0 | 1 | 64.00' | LPF | DEC |
| 5 | STRINGS | 2 | 4' | 0 | 0 | 180 | 0 | 0 | 75 | 0 | 0/0/0/0 | 0/4/100/10 | 3/4/220/6 | 0 | 1 | 64.00' | LPF | DEC |
| 6 | EORGAN | 9 | 8' | 0 | 0 | 255 | 0 | 0 | 0 | 0 | 0/0/0/0 | 0/0/0/0 | 0/0/255/1 | 0 | 1 | 64.00' | LPF | DEC |
| 7 | PORGAN | 6 | 8' | 0 | 0 | 255 | 0 | 0 | 0 | 0 | 0/0/0/0 | 0/0/0/0 | 0/0/255/1 | 0 | 1 | 64.00' | LPF | DEC |
| 8 | EPIANO | 8 | 8' | 0 | 0 | 255 | 0 | 0 | 0 | 0 | 0/0/0/0 | 0/0/0/0 | 0/0/255/20 | 0 | 1 | 64.00' | LPF | DUR |
| 9 | GLOCKEN | 7 | 16' | 0 | 0 | 100 | 0 | 0 | 100 | 0 | 0/0/0/0 | 0/4/0/0 | 0/0/255/20 | 0 | 1 | 64.00' | LPF | DUR |
| 10 | KOTO | 11 | 8' | 2 | 0 | 0 | 0 | 0 | 128 | 0 | 0/0/0/0 | 0/4/48/128 | 0/4/224/32 | 0 | 1 | 512.00' | LPF | DUR |
| 11 | CONGA | 1 | 16' | 0 | 128 | 255 | 0 | 0 | 0 | 0 | 0/1/0/0 | 0/0/0/0 | 0/1/239/8 | 0 | 1 | 64.00' | LPF | DUR |
| 12 | SYNDRUM | 1 | 8' | 0 | 255 | 255 | 0 | 0 | 0 | 0 | 0/1/192/20 | 0/0/0/0 | 0/1/192/20 | 0 | 1 | 64.00' | LPF | DUR |
| 13 | IMAGE | 1 | 8' | 255 | 255 | 255 | 0 | 0 | 0 | 0 | 32/0/255/32 | 0/0/0/0 | 2/0/255/64 | 0 | 1 | 8.00' | LPF | DUR |
| 14 | PARC1 | 4 | 2' | 96 | 0 | 255 | 0 | 0 | 0 | 0 | 0/0/0/0 | 0/0/0/0 | 0/4/224/32 | 4 | S/H | 64.00' | LPF | DUR |
| 15 | PARC2 | 1 | 4' | 255 | 0 | 255 | 0 | 0 | 0 | 0 | 0/0/0/0 | 0/0/0/0 | 0/4/240/32 | 0 | 1 | 8.00' | LPF | DUR |
| 16 | (sin nombre) | 1 | 8' | 0 | 0 | 255 | 0 | 0 | 0 | 0 | 0/0/0/0 | 0/0/0/0 | 0/0/255/0 | 0 | 1 | 64.00' | LPF | DEC |

![Los dieciséis TONE EDIT](../imagenes/tone-edit.png)

Y así suenan, sintetizados con `tools/motor.py` y tocados con
`tools/sonido.py` en LA3 con la tecla sostenida un segundo. Son los bytes que
el cartucho manda al DAC: el timbre 1 está cotejado contra openMSX, 22.273
bytes y 0 distintos ([En el emulador](EN-EL-EMULADOR.md)).

| timbre | | timbre | |
|---|---|---|---|
| 1 EBASS1 | [timbre-01.wav](../sonido/timbre-01.wav) | 9 GLOCKEN | [timbre-09.wav](../sonido/timbre-09.wav) |
| 2 EBASS2 | [timbre-02.wav](../sonido/timbre-02.wav) | 10 KOTO | [timbre-10.wav](../sonido/timbre-10.wav) |
| 3 BRASS | [timbre-03.wav](../sonido/timbre-03.wav) | 11 CONGA | [timbre-11.wav](../sonido/timbre-11.wav) |
| 4 TRUMPET | [timbre-04.wav](../sonido/timbre-04.wav) | 12 SYNDRUM | [timbre-12.wav](../sonido/timbre-12.wav) |
| 5 STRINGS | [timbre-05.wav](../sonido/timbre-05.wav) | 13 IMAGE | [timbre-13.wav](../sonido/timbre-13.wav) |
| 6 EORGAN | [timbre-06.wav](../sonido/timbre-06.wav) | 14 PARC1 | [timbre-14.wav](../sonido/timbre-14.wav) |
| 7 PORGAN | [timbre-07.wav](../sonido/timbre-07.wav) | 15 PARC2 | [timbre-15.wav](../sonido/timbre-15.wav) |
| 8 EPIANO | [timbre-08.wav](../sonido/timbre-08.wav) | 16 (sin nombre) | [timbre-16.wav](../sonido/timbre-16.wav) |

## Las catorce ondas

El oscilador lee una de las catorce ondas de `0x7200`, 256 muestras con
signo cada una, en la página `0x72` + onda (`0x56FF`). La 1 es el seno con
el que arrancan las ondas del usuario; la 15 es la del usuario, y la 16 es
ruido, que no es una tabla: sale de leer la BIOS ([Hallazgos](HALLAZGOS.md)).

![Las catorce ondas del oscilador](../imagenes/ondas.png)
