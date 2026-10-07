# Legal notice and attribution

*(Tambien disponible [en castellano](AVISO-LEGAL.md).)*

## Who owns what

**The program is not ours.** *Konami's Synthesizer* was published by
**Konami** for the MSX in 1986; its catalogue number is **RC-741** and it is
32 KB with a DAC. All rights over the program, its graphics, its sounds and
its tones remain with their holders.

**What is ours** are the tools in this repository, the comments in the
listing, the analysis and the documentation. Those are published under the
licence in `LICENSE`.

## What is in this repository

The file `src/synth.asm` is the commented disassembly of the cartridge. It is
published for the **preservation, study and documentation** of a title that is
part of the history of MSX software.

The cartridge image (`.rom`) is **not** distributed here. Whoever wants to
rebuild the listing has to supply their own, and the `Makefile` checks its
sha256 before doing anything.

The pictures produced by `tools/pantallas.py` and `tools/imagenes.py` are not
illustrations brought in from elsewhere: they are drawn by reading the
cartridge's own blocks, at the addresses the listing gives. The sounds in
`docs/sonido` are made by `tools/motor.py`, the cartridge's synthesizer
written anew from the listing. They are part of the proof that the reading of
the binary is right: if it were wrong, noise would come out.

## What it relies on

On nothing from anyone. Everything stated here comes from reading this binary
or from measuring it running, and every statement carries its evidence next to
it: the instruction that reads a datum, the table that ends exactly where it
has to, or the measurement taken in the emulator. What is not settled is said
not to be.

This cartridge carries Konami's hidden mark in its last ten bytes:
`tools/marca_konami.py` reads it (シンセサイザー, RC-741). The format of that
mark was discovered by Manuel Pazos, and he is thanked for it.

## If you are one of the authors

If you worked on *Konami's Synthesizer* or hold rights over the program, and
you would rather this material were not published, **say so and it will be
taken down, no argument**. The intention of this work is the very opposite of
harming you: it is to leave a record of how it was made.
