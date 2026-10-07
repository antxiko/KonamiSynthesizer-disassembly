# Konami's Synthesizer (MSX) — a commented disassembly

*(También disponible [en castellano](README.es.md).)*

A commented disassembly of ***Konami's Synthesizer*** (新世SIZER, シンセサイザー),
Konami, 1986, cartridge **RC-741** for the **MSX**: 32 KB with no mapper in
pages 1 and 2, and an 8-bit DAC at `0x4000`.

**The website**: https://antxiko.github.io/KonamiSynthesizer-disassembly/

| | |
|---|---|
| explained | 100% (16,229 bytes of code, 16,539 of data) |
| commented | 43.6% of the instructions |
| routines | 1,187, none below 10% |
| reassembly | the ROM, byte for byte |
| pictures | drawn from the ROM; twenty-three screens checked against openMSX, 0 differences |
| sound | the rewritten engine gives the sixteen tones byte for byte; what reaches the DAC, checked: 0 different |

## What is here

- The listing (`src/synth.asm`), generated from the binary and the notes, which
  reassembles the exact ROM.
- The synthesizer written anew (`tools/motor.py`) and the sixteen tones played
  the way the cartridge plays them (`tools/sonido.py`, `docs/sonido/`).
- The seven screens, the sixteen TONE EDITs and the fourteen waves, built from
  the ROM's tables.
- How it works: the note is computed sample by sample in the computer's RAM,
  the pitch is a loop of cycles with thirteen paddings, the noise comes from
  the BIOS, and the TONE, LAYOUT and SAMP tape files.

## How to reproduce it

You need Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) and **your own
cartridge image** as `synth.rom` in the root:

```
sha256  a2eea29f13662acea8d0cbe2b4e95201a29e82e0c3c38dd24e910e9325a90a0d
make
```

The details are in [Getting started](docs/GETTING-STARTED.md).

## Notice

The program belongs to Konami; only the analysis, the comments and the tools
are here. The ROM is not distributed. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
