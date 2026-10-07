# Findings

Each one says where it comes from: the code, a table in the ROM or a
measurement in openMSX. The measurements are told in
[In the emulator](IN-THE-EMULATOR.md).

## A synthesizer inside the Z80

The cartridge carries no sound chip: it carries an 8-bit DAC at `0x4000`,
and the program is a subtractive synthesizer that computes the note sample
by sample (`0x5767`): an oscillator with fourteen waves, a two-stage
resonant filter, an amplifier, three ADSR envelopes and an LFO with sample
and hold. It writes it all into the 16 KB at `0x8000` and then plays it.

*Measured in openMSX*: `tools/motor.py`, the engine written anew, gives the
sixteen factory tones byte for byte the same as those the Z80 writes at
`0x57B0`.

## The pitch is a loop of cycles

PLAY does not change the frequency of anything: it sends the sample to the
DAC byte by byte and waits between one and the next. Every key has one of
thirteen routines and a delay D (`0x5DA9`), and the thirteen routines are
the same loop with different padding of instructions that do nothing.
Counted, routine r costs **59 + r + 14 × D** cycles per sample: the thirteen
are a one-cycle fine adjustment.

*Measured in openMSX*: with routine 9 and D = 11 (A3), 254.37 cycles on
average between writes to the DAC, 254 and 255; with the MSX's M1 wait state
that is 67 + 16 × D for routine 0. And it is monophonic: one key at a time
(`0x5EA5`).

## The sample lives in the computer's RAM

The cartridge has no RAM. Before synthesizing, playing or loading a SAMP,
`0x4105` puts at `0x8000`-`0xBFFF` the RAM slot it noted at start-up
(`0xD854`), and `0x410D` brings the cartridge back, which is where the
screens' graphics are. RAM at `0x8000` is needed: a 16 KB MSX has none.

*Measured in openMSX*: during SYN page 2 is slot 3 (`A8 = 0xF4`) and every
byte written stays.

## The noise comes from the BIOS

Oscillator wave 16 and the LFO's sample and hold are not a table: `0x5AD4`
reads from `0x0000` onwards, the BIOS ROM, rotates each byte and accumulates
it. **The noise depends on the computer**: tone 14 (PARC1) sounds different
on every machine, and `tools/sonido.py` needs the first 256 bytes of a BIOS
to make it.

## The DAC starts without a thump

The first interrupt routine (`0x4118`) only raises the DAC from 0 to `0x80`,
one step per interrupt, and at the 129th it hands the hook to the per-frame
one. From the code.

## TONE, LAYOUT and SAMP

Three tape files, with the length in front and, in SAMPs, the loop page:
TONE is the sixteen tones **with their sixteen waves** (4,608 bytes), LAYOUT
the note of every key with its routine and its delay (176), and SAMP the
whole sample (up to 16 KB). From the code, and the tape that came with the
cartridge confirms it: seven SAMPs, from 3,072 to 16,384 bytes. The ROM also
carries disk routines (`.T`, `.K` and `.S` through the BDOS) and a DISK
option that is only drawn if there is a drive (`H.PHYD`); they have not been
tested.

## The second page of the menu

SHIFT changes the bottom menu (`0x48B2`): F1 copies a tone and its wave onto
another, F2 lists the sixteen, F3 prints the screen, and F4 is LAYOUT, where
every key of the music keyboard gets the note you choose (`0xBBA4`); CTRL and
HOME bring back the factory one. From the code: these four screens are not
built from the ROM.

## The attack does not save its phase

In the three envelopes, on entering the step-by-step attack (`0x5849`,
`0x58F5`, `0x598F`), the program loads the phase's routine into HL and does
not store it in the pointer, unlike in the decay and the release. It works
the same, because it re-enters from the top every sample; they are three
three-byte `ld hl` that do nothing.

## What nobody calls, and the mark

Ten pieces of code nobody calls: a `jp` behind the header (`0x4012`), a
graphics loader driven by a six-byte table at `0x5800` that does not exist
(`0x49CD`), stray copies of FILE and printer routines (`0x520A`, `0x522A`,
`0x54A4`), a search in a list (`0xBCA2`)… And `0xB834`, which only runs from
its copy in RAM.

At `0xBF62` the ROM says `RC741 86 5 31`, and in its last ten bytes it
carries Konami's hidden mark: シンセサイザー, RC-741. The format of that mark
was discovered by **Manuel Pazos**, and he is thanked for it;
`tools/marca_konami.py` reads it.
