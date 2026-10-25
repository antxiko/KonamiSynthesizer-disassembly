# El código

8.637 instrucciones en 1.187 rutinas, todas con nombre o con comentario;
3.767 instrucciones llevan comentario, el 43,6 %. El listado se genera
desde `src/synth.notes` y reensambla la ROM byte a byte.

## Cada cuadro

`H.KEYI` (`0x4015`) lleva el programa: los efectos del PSG, las teclas
(`0x4817`: la primera pulsada como fila × 8 + bit + 1, con repetición a los
40 cuadros) y la fase de la pantalla. En la intro, `0xD800` es la fase y
`0xD801` el paso, y cada fase es una cadena de `djnz`; en el programa,
`0xD8F4` es la pantalla y `0x4805` la tabla de las nueve. SYN y PLAY cierran
las interrupciones y las abren al acabar.

## SYN, el sintetizador

`0x55F0` prepara y `0x5767` da una vuelta por muestra: el LFO, las tres
envolventes, el oscilador, el filtro, la amplitud, y el byte a la RAM.

- **La duración** (`0x5613`): la mayor de las tres envolventes en muestras,
  más la relajación del amplificador, redondeada a página; si pasa de 16 KB
  no se calcula. Cada 1/128 de esa duración hay un *tic* que mueve el cursor
  de la pantalla (`0x4BD9`).
- **Las envolventes** (`0x5829`, `0x58D5`, `0x5981`) son una misma máquina de
  estados, la fase en un puntero: el ataque sube el nivel de 1 en 1 cada A
  muestras hasta 255, la caída lo baja cada D hasta S, el sostenido espera a
  que las tres estén en el suyo, y la relajación baja cada R hasta 0. Un
  parámetro a cero salta la fase.
- **El oscilador** (`0x5A4B`) lleva una fase de 16 bits que avanza FEET × 256
  por muestra, más o menos lo que digan el LFO y la envolvente del oscilador,
  y lee la onda en su byte alto.
- **El filtro** (`0x5B1C`) son dos etapas de un polo con realimentación: el
  corte es CUT más lo que manden la envolvente y el LFO del filtro, y RES
  (0-8) elige en `0x5C12` y `0x5C1B` la realimentación y la ganancia. La
  salida es la segunda etapa (BPF), la primera (LPF) o lo que queda de la
  entrada menos la primera (HPF), según el byte 24 del timbre.
- **La amplitud** (`0x5C7E`): la muestra por el LFO del amplificador y por el
  nivel de su envolvente.
- **El bucle**: cuando el oscilador y el filtro han llegado a su sostenido y
  el puntero cae en principio de página, esa página se apunta en `0xDCFD`
  (`0x59D9`); PLAY la repetirá mientras se tenga la tecla. Con EG TYP en DUR
  no hay bucle.

`tools/motor.py` es este código escrito de nuevo en Python, con su
aritmética de 8 y 16 bits y sus redondeos; `tests/test_motor.py` comprueba
que los dieciséis timbres salen byte a byte iguales que lo que el Z80 escribe
en openMSX.

## PLAY, la altura de la nota

Tres tablas de trece rutinas (`0x5E8B` con página de bucle, `0x6709` sin
ella, `0x6EBB` para escuchar en WAVE EDIT). Cada tecla tiene en `0xD230` una
rutina r y un retardo D (`0x5DA9`, y `0x5E29` por nota), y la rutina es
siempre lo mismo: el byte al DAC, D vueltas de un bucle de espera, mirar si
la tecla sigue pulsada, y un relleno de instrucciones que no hacen nada
(`nop`, `cp 0`, `neg`, `inc ix`…).

Contado instrucción a instrucción, dentro de cada rutina todos los caminos
cuestan lo mismo por muestra, y **la rutina r tarda 59 + r + 14 × D ciclos**
de catálogo del Z80: las trece rutinas son un ajuste fino de un ciclo. En un
MSX cada búsqueda de instrucción lleva un estado de espera, y lo medido en
openMSX es 67 + 16 × D en la rutina 0 ([En el emulador](EN-EL-EMULADOR.md)).
Mientras suena la cola del sample se recorre el teclado fila a fila, y otra
tecla empieza otra nota: PLAY es monofónico.

## FILE: la cinta

En cinta (`0x4D04` graba, `0x4D8C` carga), cuatro bloques con la BIOS,
cada uno tras su cabecera:

1. dieciséis veces el tipo: `0x21` TONE, `0x22` LAYOUT, `0x23` SAMP;
2. las siete letras del nombre, en el código de la fuente (`0x21` = A);
3. la longitud en dos bytes y, solo en SAMP, la página de bucle;
4. los datos: TONE a `0xC000` (4.608 bytes), LAYOUT a `0xD200` (176), SAMP a
   `0x8000` (`0x4E7A`).

Al cargar, con el nombre en blanco vale cualquier fichero del tipo; si no,
busca el que se llama así.

La ROM lleva además rutinas para disco por la BDOS del Disk BASIC
(`0xF37D`: `NOMBRE.T`, `.K` y `.S`, y un directorio de hasta 35 nombres,
`0x4F4D`), y una opción DISK en el menú que solo se pinta si hay una unidad
(`H.PHYD`, `0x438F`). No están probadas.

La cinta que venía con el cartucho trae en sus dos caras siete SAMP: PIANO, BRASS y ORCHE de 16.384 bytes, TRUMPET de 12.288, SAMISEN
de 7.792, DOG de 3.072 y CRASH de 16.384.

## La impresora

SHIFT F3 (`0x52B7`) vuelca la pantalla en puntos por `LPTOUT`, en 64
franjas de cuatro filas y 192 columnas (`0x5419`), con las secuencias de
`0x54B6`; desde WAVE EDIT imprime además la tabla de la onda, 64 muestras con
signo en ocho filas (`0x5516`). Sale del código: no se ha probado con una
impresora.

## Código compartido con otros cartuchos de Konami

Este desensamblado se ha comparado, instrucción por instrucción, con
todos los demás de Konami de la serie. Cuenta un bloque cuando las
mismas instrucciones, al menos seis desde una etiqueta hasta su `ret`
o su salto sin condición, están en los dos cartuchos; las direcciones
no se miran, porque cambian de un cartucho a otro. De los otros 57,
**48** tienen al menos un bloque en común con este; estos son los
que más comparten:

| Cartucho | Bloques | Instrucciones | Por ejemplo (aquí = allí) |
|---|---:|---:|---|
| [Konami’s Game Master 2](https://antxiko.github.io/GameMaster2-disassembly/es/) | 18 | 206 | `escribe_lista` (0x4337) = `th_pinta_texto` |
| [Q*bert](https://antxiko.github.io/Qbert-disassembly/es/) | 18 | 195 | `rle_a_vram` (0x4352) = `guion_rle` |
| [Konami’s Game Master](https://antxiko.github.io/GameMaster-disassembly/es/) | 15 | 177 | `nombre_del_punto` (0x5405) = `posicion_a_vram` |
| [The Goonies](https://antxiko.github.io/Goonies-disassembly/es/) | 15 | 165 | `rle_a_vram` (0x4352) = `guion_rle` |
| [Yie Ar Kung-Fu II](https://antxiko.github.io/YieArKungFu2-disassembly/es/) | 15 | 180 | `byte_de_teclas` (0x42B7) = `lee_las_filas_7_y_8_del_teclado` |
| [Hyper Sports 3](https://antxiko.github.io/HyperSports3-disassembly/es/) | 14 | 176 | `byte_de_teclas` (0x42B7) = `teclado_del_jugador_1` |
| [The Maze of Galious](https://antxiko.github.io/MazeOfGalious-disassembly/es/) | 13 | 177 | `rle_a_vram` (0x4352) = `rle_con_destino` |
| [Konami's Ping Pong](https://antxiko.github.io/KonamisPingPong-disassembly/es/) | 13 | 159 | `byte_de_teclas` (0x42B7) = `lee_teclado_1` |
| [F-1 Spirit — The Way to Formula 1](https://antxiko.github.io/F1Spirit-disassembly/es/) | 12 | 128 | `rle_a_vram` (0x4352) = `RLE_SIGUE_PUNTERO` |
| [Nemesis / Gradius](https://antxiko.github.io/Nemesis-disassembly/es/) | 12 | 134 | `rle_a_vram` (0x4352) = `descomprime_con_destino` |

La matriz entera, los 58 cartuchos entre sí, está en
[Las rutinas](https://antxiko.github.io/MSX-disassembly-database/es/LAS-RUTINAS.html) de la base de datos de la
serie, con el método y el programa que la mide.
