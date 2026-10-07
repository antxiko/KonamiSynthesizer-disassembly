# The cartridge

32 KB with no mapper, in pages 1 and 2 (`0x4000`-`0xBFFF`), and the
digital-to-analogue converter: **the DAC is any write to `0x4000`**, 8 bits
unsigned with rest at `0x80`. The cartridge **has no RAM**: the sample lives
in the computer's RAM, at `0x8000`-`0xBFFF`, and the program switches that
page between the RAM (`0x4105`) and the cartridge (`0x410D`) with ENASLT,
depending on whether it has to play or to draw.

## Start-up

`0x4000`: "AB" and INIT at `0x4054`. INIT notes the slots of pages 1 and 2
(`0x40D4`) and copies to `H.STKE` an `rst 0x30` to `0x406E`: the program
starts when BASIC has finished starting. Then it clears the variables, sets
`H.KEYI` and, before letting interrupts in, fills the sample with silence.

The first interrupt routine (`0x4118`) does nothing but raise the DAC from 0
to `0x80`, one step per interrupt, 129 times; then it hands the hook to the
per-frame routine (`0x4015`). That way the speaker does not give the power-on
thump.

## The ROM map

| from | to | what |
|---|---|---|
| `0x4012` | `0x4D04` | start-up, the intro, the screens, the keyboard, the PSG effects |
| `0x4D04` | `0x55E8` | FILE: the tape, the disk code and the printer |
| `0x55E8` | `0x5D3A` | SYN: the synthesizer |
| `0x5D3A` | `0x7135` | PLAY: the 39 routines that play the sample |
| `0x7200` | `0x8000` | the fourteen oscillator waves, 256 bytes each |
| `0x8000` | `0xA3AA` | the graphics of every screen, in RLE |
| `0xA3AA` | `0xA5AA` | the sixteen factory tones, 32 bytes each |
| `0xA5AA` | `0xBB6D` | TONE EDIT, WAVE EDIT, the copy, the list and FILE |
| `0xBB6D` | `0xBEA6` | LAYOUT and the intro's demo |
| `0xBEA6` | `0xBF62` | the PSG effects and their lists |
| `0xBF62` | `0xC000` | `RC741 86 5 31`, padding and Konami's hidden mark |

The whole split, byte by byte, is in `src/synth.notes`: the code is 16,229
bytes and the data 16,539, and none is left unexplained.

## The RAM

| address | what |
|---|---|
| `0x8000`-`0xBFFF` | the sample: 16 KB of 8-bit samples, silence at `0x80` |
| `0xC000`-`0xCFFF` | the sixteen user waves, 256 bytes each |
| `0xD000`-`0xD1FF` | the sixteen tones, 32 bytes each |
| `0xD200`-`0xD22F` | the LAYOUT: the note of each of the 48 keys |
| `0xD230`-`0xD2AF` | per key, the PLAY routine and its delay |
| `0xD800`-`0xDEFF` | the variables: the phase, the keys, the screen, the sprite copy |
| `0xD854` / `0xD855` | the slots of the RAM and of the cartridge in page 2 |
| `0xDB00` | the current tone |
| `0xDC00`-`0xDC18` | the tone SYN is synthesizing |
| `0xDC19` | SYN's write pointer |
| `0xDCFD` / `0xDCFE` | the loop page and the length of the sample |
| `0xDD00`-`0xDDFF` | the user wave prepared for listening |
| `0xDF00` | the stack, downwards |

## The VRAM

SCREEN 2, with the registers at `0x4295`: colours at `0x0000`, patterns at
`0x2000`, names at `0x3800`, sprite attributes at `0x3B00` and sprite
patterns at `0x1800`. Tiles 0 to 15 are flat squares of the sixteen colours,
the font runs from `0x10` (the digits) and from `0x21` (the letters), and
every screen brings its patterns, colours and names in RLE from page 2 of the
cartridge (`0x4358`): a control byte below `0x80` repeats the next one,
`0x80` + n copies n bytes, `0x80` brings another address and 0 ends.

## The PSG

Only for the effects: three channels (`0xD810`, five bytes each) with note
lists at `0xBEFE`. The cursor makes effect 1, a finished operation 2, a
screen change 5 and the intro 8 (`0xBEBF`).
