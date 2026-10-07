# Empezar

Para reproducir este desensamblado hace falta Python 3, GNU make y
[Pasmo](https://pasmo.speccy.org/). La imagen del cartucho **no viaja en este
repositorio**: cada cual pone la suya.

```
synth.rom    32.768 bytes
sha256       a2eea29f13662acea8d0cbe2b4e95201a29e82e0c3c38dd24e910e9325a90a0d
```

Con el fichero en la raíz del repositorio:

```
make            # listado, verificación, coherencia y tests
```

## Qué hace cada paso

| orden | qué hace |
|---|---|
| `make comprueba` | comprueba el sha256 de la ROM |
| `make listado` | traza el flujo y genera `src/synth.asm` desde el binario y las notas |
| `make verify` | reensambla el listado y compara el sha256 con el de la ROM |
| `make sanity` | comprueba que ningún dato sale como código y que no queda un byte sin asignar |
| `make test` | los tests |
| `make densidad` | cuántas instrucciones llevan comentario, rutina a rutina |
| `make imagenes` | dibuja las imágenes de la web desde la ROM |
| `make coteja` | coteja esas pantallas con los volcados de openMSX |
| `make web` | genera las páginas HTML y comprueba los enlaces |

`make verify` es el que decide: tiene que acabar con `OK: reproducible byte a
byte`.

## Dónde está cada cosa

| fichero | qué es |
|---|---|
| `src/synth.notes` | los nombres, los comentarios y los bloques de datos, anclados a dirección |
| `src/synth.entries` | los puntos de entrada que el trazado no puede deducir, cada uno con su porqué |
| `src/synth.nocode` | las zonas que no son código aunque el trazado pueda entrar |
| `src/synth.asm` | el listado comentado, generado |
| `tools/z80trace.py`, `tools/mkasm.py` | el trazador y el generador del listado |
| `tools/flujos.py` | el RLE con el que el cartucho escribe la VRAM |
| `tools/motor.py` | SYN escrito de nuevo: el sintetizador, muestra a muestra |
| `tools/sonido.py` | PLAY: los timbres tocados como los toca el cartucho, en WAV |
| `tools/timbres.py` | la tabla de los dieciséis timbres de fábrica |
| `tools/pantallas.py`, `tools/imagenes.py` | montan cada pantalla desde las tablas y la pintan |
| `tools/coteja_todo.py`, `tools/coteja_dac.py` | el cotejo con los volcados de openMSX y con lo que llega al DAC |
| `tools/omsx_*.tcl`, `tools/lanza_*.sh` | las sondas de openMSX: ver [En el emulador](EN-EL-EMULADOR.md) |

Las páginas: [El programa](EL-JUEGO.md), [El cartucho](EL-CARTUCHO.md),
[El código](EL-CODIGO.md), [Hallazgos](HALLAZGOS.md),
[En el emulador](EN-EL-EMULADOR.md) y [Preguntas abiertas](PREGUNTAS-ABIERTAS.md).
