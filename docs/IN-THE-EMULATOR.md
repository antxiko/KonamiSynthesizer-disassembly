# In the emulator

The pictures are built from the ROM, not captured. openMSX is for
**checking** those pictures against the real VRAM, and for **measuring** what
the code says about the sound.

All with openMSX and the `Philips_VG_8020` machine, one emulator at a time.

## Checking the screens

`tools/omsx_dibujo.tcl` follows a key script and dumps the VRAM, the RAM from
`0xC000` up and the VDP registers when told; `tools/omsx_tone16.tcl` does
not go by the clock: it waits for the intro to be at the title, starts the
program, opens TONE EDIT and dumps one screen per tone, going from one to the
next with INS. `tools/coteja_todo.py` builds every screen with
`tools/pantallas.py` and compares it with its dump, byte for byte in
everything it writes and dot for dot in the picture.

| screen | differences |
|---|---|
| Konami logo | 0 |
| title | 0 |
| TONE EDIT, all sixteen tones | 0 |
| WAVE EDIT | 0 |
| SYN | 0 |
| PLAY | 0 |
| FILE MODE | 0 |

Twenty-three screens. In seven of the TONE EDITs the dump catches the cursor
in the other phase of its blink (colour 12 instead of 8, `0xA5AA`): it is
the only different byte and it is accepted.

## The synthesizer

`tools/omsx_sintesis.tcl` notes every byte SYN writes at `0x57B0`;
`tests/test_motor.py` compares the sixteen tones with what `tools/motor.py`
gives: byte for byte the same.

## What reaches the DAC

`tools/omsx_dac.tcl` notes every byte the Z80 writes to `0x4000` with its
instant: it synthesizes tone 1, gives the Z key routine 9 and delay 11 (A3)
and holds it for half a second. `tools/coteja_dac.py` rebuilds what has to
arrive and compares:

| | |
|---|---|
| bytes to the DAC | 22,273: the rest value, the whole 16 KB and 23 more turns of loop page `0x84` |
| different from `motor.py` | 0 |
| period between writes | 254.37 cycles on average (254 and 255); `sonido.py` uses 254.4 |

`tools/omsx_ritmo.tcl` is the measurement the thirteen routines' cycles in
`sonido.py` come from: each one with D = 32 and D = 64, 3,000 samples.

## The sample in RAM

With a breakpoint after the write at `0x57B0`: during SYN the slot register
reads `0xF4` (page 2 is slot 3, the RAM) and the byte read back after writing
it is the one written.
