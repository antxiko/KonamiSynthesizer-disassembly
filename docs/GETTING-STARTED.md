# Getting started

To reproduce this disassembly you need Python 3, GNU make and
[Pasmo](https://pasmo.speccy.org/). The cartridge image **does not travel in
this repository**: everyone supplies their own.

```
synth.rom    32,768 bytes
sha256       a2eea29f13662acea8d0cbe2b4e95201a29e82e0c3c38dd24e910e9325a90a0d
```

With the file in the root of the repository:

```
make            # listing, verification, consistency and tests
```

## What each step does

| command | what it does |
|---|---|
| `make comprueba` | checks the ROM's sha256 |
| `make listado` | traces the flow and generates `src/synth.asm` from the binary and the notes |
| `make verify` | reassembles the listing and compares its sha256 with the ROM's |
| `make sanity` | checks that no data comes out as code and that not a byte is left unassigned |
| `make test` | the tests |
| `make densidad` | how many instructions carry a comment, routine by routine |
| `make imagenes` | draws the website's pictures from the ROM |
| `make coteja` | checks those screens against the openMSX dumps |
| `make web` | generates the HTML pages and checks the links |

`make verify` is the one that decides: it has to end with `OK: reproducible
byte a byte`.

## Where everything is

| file | what it is |
|---|---|
| `src/synth.notes` | the names, the comments and the data blocks, anchored to addresses |
| `src/synth.entries` | the entry points the trace cannot deduce, each with its reason |
| `src/synth.nocode` | the areas that are not code even if the trace could enter them |
| `src/synth.asm` | the commented listing, generated |
| `tools/z80trace.py`, `tools/mkasm.py` | the tracer and the listing generator |
| `tools/flujos.py` | the RLE the cartridge writes the VRAM with |
| `tools/motor.py` | SYN written anew: the synthesizer, sample by sample |
| `tools/sonido.py` | PLAY: the tones played the way the cartridge plays them, as WAV |
| `tools/timbres.py` | the table of the sixteen factory tones |
| `tools/pantallas.py`, `tools/imagenes.py` | build every screen from the tables and draw it |
| `tools/coteja_todo.py`, `tools/coteja_dac.py` | the check against the openMSX dumps and against what reaches the DAC |
| `tools/omsx_*.tcl`, `tools/lanza_*.sh` | the openMSX probes: see [In the emulator](IN-THE-EMULATOR.md) |

The pages: [The program](THE-GAME.md), [The cartridge](THE-CARTRIDGE.md),
[The code](THE-CODE.md), [Findings](FINDINGS.md),
[In the emulator](IN-THE-EMULATOR.md) and [Open questions](OPEN-QUESTIONS.md).
