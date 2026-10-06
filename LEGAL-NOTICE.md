# Legal notice and attribution

*(Tambien disponible [en castellano](AVISO-LEGAL.md).)*

## Who owns what

**The game is not ours.** *Q\*bert* was published by **Konami** for the MSX in 1986, under
licence of Gottlieb's original; its catalogue number is **RC-746** and it is 32 KB. All rights over the game
remain with their holders.

**What is ours** are this repository's tools, the comments in the listing, the
analysis and the documentation. That is published under the licence in
`LICENSE`.

## What is in this repository

The file `src/qbert.asm` is the commented disassembly of the cartridge. It is
published for the **preservation, study and documentation** of a title that is
part of MSX software history.

The cartridge image (`.rom`) is **not** distributed here. Anyone who wants to
rebuild the listing has to supply their own, and the `Makefile` checks its
sha256 before doing anything.

The pictures produced by `tools/pantallas.py` and `tools/imagenes.py` are not illustrations brought in
from outside: they are drawn by reading the cartridge's own blocks, at the
addresses the listing gives. They are part of the proof that the reading of the
binary is right: if it were wrong, they would come out as noise.

## What it rests on

Nobody else's work. Everything stated here comes from reading this binary or
from measuring it running, and each claim carries its evidence next to it: the
instruction that reads a datum, the table that ends exactly where it has to end,
or the measurement made in the emulator. What is not settled is said not to be.

This cartridge carries Konami's hidden mark in its last ten bytes:
`tools/marca_konami.py` reads it (キューバート, RC-746). The format of that mark
was discovered by Manuel Pazos, and he is thanked for it.

## If you are one of the authors

If you worked on *Q\*bert* or hold rights over the game, and you would rather this
material were not published, **say so and it comes down, no argument**. The
intent of this work is the opposite of harming you: it is to put on record how
it was made.
