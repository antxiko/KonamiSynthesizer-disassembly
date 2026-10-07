# The code

8,637 instructions in 1,187 routines, all with a name or a comment; 3,767
instructions carry a comment, 43.6%. The listing is generated from
`src/synth.notes` and reassembles the ROM byte for byte.

## Every frame

`H.KEYI` (`0x4015`) drives the program: the PSG effects, the keys (`0x4817`:
the first one pressed as row × 8 + bit + 1, with repeat after 40 frames) and
the screen's phase. In the intro, `0xD800` is the phase and `0xD801` the
step, and every phase is a chain of `djnz`; in the program, `0xD8F4` is the
screen and `0x4805` the table of the nine. SYN and PLAY disable interrupts
and enable them when they finish.

## SYN, the synthesizer

`0x55F0` prepares and `0x5767` takes one turn per sample: the LFO, the three
envelopes, the oscillator, the filter, the amplitude, and the byte to RAM.

- **The duration** (`0x5613`): the longest of the three envelopes in samples,
  plus the amplifier's release, rounded up to a page; over 16 KB it is not
  computed. Every 1/128 of that duration there is a *tick* that moves the
  on-screen cursor (`0x4BD9`).
- **The envelopes** (`0x5829`, `0x58D5`, `0x5981`) are one and the same state
  machine, the phase in a pointer: attack raises the level by 1 every A
  samples up to 255, decay lowers it every D down to S, sustain waits for all
  three to be in theirs, and release lowers it every R down to 0. A parameter
  at zero skips the phase.
- **The oscillator** (`0x5A4B`) keeps a 16-bit phase that advances FEET × 256
  per sample, plus or minus what the LFO and the oscillator's envelope say,
  and reads the wave at its high byte.
- **The filter** (`0x5B1C`) is two one-pole stages with feedback: the cutoff
  is CUT plus what the filter's envelope and LFO add, and RES (0-8) picks the
  feedback and the gain in `0x5C12` and `0x5C1B`. The output is the second
  stage (BPF), the first (LPF) or what is left of the input minus the first
  (HPF), according to byte 24 of the tone.
- **The amplitude** (`0x5C7E`): the sample times the amplifier's LFO and
  times its envelope level.
- **The loop**: when the oscillator and the filter have reached their sustain
  and the pointer falls on the start of a page, that page is noted in
  `0xDCFD` (`0x59D9`); PLAY will repeat it while the key is held. With EG TYP
  on DUR there is no loop.

`tools/motor.py` is this code written anew in Python, with its 8- and
16-bit arithmetic and its roundings; `tests/test_motor.py` checks that the
sixteen tones come out byte for byte the same as what the Z80 writes in
openMSX.

## PLAY, the pitch

Three tables of thirteen routines (`0x5E8B` with a loop page, `0x6709`
without, `0x6EBB` for listening in WAVE EDIT). Every key has in `0xD230` a
routine r and a delay D (`0x5DA9`, and `0x5E29` per note), and the routine is
always the same thing: the byte to the DAC, D turns of a wait loop, a look at
whether the key is still down, and padding of instructions that do nothing
(`nop`, `cp 0`, `neg`, `inc ix`…).

Counted instruction by instruction, within each routine every path costs the
same per sample, and **routine r takes 59 + r + 14 × D cycles** of the Z80's
data sheet: the thirteen routines are a one-cycle fine adjustment. On an MSX
every opcode fetch carries a wait state, and what is measured in openMSX is
67 + 16 × D for routine 0 ([In the emulator](IN-THE-EMULATOR.md)). While the
tail of the sample plays, the keyboard is scanned row by row, and another key
starts another note: PLAY is monophonic.

## FILE: the tape

On tape (`0x4D04` saves, `0x4D8C` loads), four blocks through the BIOS, each
after its header:

1. the type sixteen times: `0x21` TONE, `0x22` LAYOUT, `0x23` SAMP;
2. the seven letters of the name, in the font's code (`0x21` = A);
3. the length in two bytes and, only in SAMP, the loop page;
4. the data: TONE to `0xC000` (4,608 bytes), LAYOUT to `0xD200` (176), SAMP to
   `0x8000` (`0x4E7A`).

When loading, with a blank name any file of the type will do; otherwise it
looks for the one with that name.

The ROM also carries disk routines through the Disk BASIC's BDOS
(`0xF37D`: `NAME.T`, `.K` and `.S`, and a directory of up to 35 names,
`0x4F4D`), and a DISK option in the menu that is only drawn if there is a
drive (`H.PHYD`, `0x438F`). They have not been tested.

The tape that came with the cartridge carries seven SAMPs on its two sides:
PIANO, BRASS and ORCHE of 16,384 bytes, TRUMPET of 12,288, SAMISEN of 7,792,
DOG of 3,072 and CRASH of 16,384.

## The printer

SHIFT F3 (`0x52B7`) dumps the screen as dots through `LPTOUT`, in 64 bands
of four rows and 192 columns (`0x5419`), with the sequences at `0x54B6`; from
WAVE EDIT it also prints the table of the wave, 64 signed samples in eight
rows (`0x5516`). From the code: it has not been tried on a printer.
