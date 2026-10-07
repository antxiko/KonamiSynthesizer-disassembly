# En el emulador

Las imágenes se montan desde la ROM, no se capturan. openMSX sirve para
**cotejar** esas imágenes con la VRAM de verdad, y para **medir** lo que dice
el código del sonido.

Todo con openMSX y la máquina `Philips_VG_8020`, un emulador cada vez.

## El cotejo de las pantallas

`tools/omsx_dibujo.tcl` sigue un guion de teclas y vuelca la VRAM, la RAM de
`0xC000` en adelante y los registros del VDP cuando se le dice;
`tools/omsx_tone16.tcl` no va a tiempos: espera a que la intro esté en el
título, arranca el programa, abre TONE EDIT y vuelca una pantalla por timbre
pasando de uno a otro con INS. `tools/coteja_todo.py` monta cada pantalla con
`tools/pantallas.py` y la compara con su volcado, byte a byte en todo lo que
escribe y punto a punto en la imagen.

| pantalla | diferencias |
|---|---|
| logotipo de Konami | 0 |
| título | 0 |
| TONE EDIT, los dieciséis timbres | 0 |
| WAVE EDIT | 0 |
| SYN | 0 |
| PLAY | 0 |
| FILE MODE | 0 |

Veintitrés pantallas. En siete de los TONE EDIT el volcado pilla el cursor
en la otra fase de su parpadeo (color 12 en vez de 8, `0xA5AA`): es el único
byte distinto y se da por bueno.

## El sintetizador

`tools/omsx_sintesis.tcl` apunta cada byte que SYN escribe en `0x57B0`;
`tests/test_motor.py` compara los dieciséis timbres con lo que da
`tools/motor.py`: iguales byte a byte.

## Lo que llega al DAC

`tools/omsx_dac.tcl` apunta cada byte que el Z80 escribe en `0x4000` con su
instante: sintetiza el timbre 1, pone a la tecla Z la rutina 9 y el retardo
11 (LA3) y la tiene pulsada medio segundo. `tools/coteja_dac.py` reconstruye
lo que tiene que llegar y lo compara:

| | |
|---|---|
| bytes al DAC | 22.273: el reposo, los 16 KB enteros y 23 vueltas más de la página de bucle `0x84` |
| distintos de `motor.py` | 0 |
| periodo entre escrituras | 254,37 ciclos de media (254 y 255); `sonido.py` usa 254,4 |

`tools/omsx_ritmo.tcl` es la medida de la que salen los ciclos de las trece
rutinas que usa `sonido.py`: cada una con D = 32 y D = 64, 3.000 muestras.

## El sample en la RAM

Con un punto de parada tras la escritura de `0x57B0`: durante SYN el registro
de ranuras vale `0xF4` (la página 2 es la ranura 3, la RAM) y el byte leído
después de escribirlo es el escrito.
