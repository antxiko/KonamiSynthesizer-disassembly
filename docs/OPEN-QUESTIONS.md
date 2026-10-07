# Open questions

What comes from the code but has not been tried, and what is not settled.

- **The four SHIFT screens.** The tone copy, the list, the printer and LAYOUT
  come from the code; they are neither built from the ROM nor checked.
- **The printer.** The dot dump of the screen and the wave table (`0x5419`,
  `0x5516`) have not been tried on a printer, nor is it known which model the
  sequences at `0x54B6` are for.
- **The disk code.** The save, load and delete routines through the BDOS and
  the menu's DISK option come from the code; nothing has been tried with a
  drive.
- **`RC741 86 5 31`.** The thirteen bytes at `0xBF62` give the catalogue
  number and, by the look of it, a date, 31 May 1986. Which date it is is not
  known.
- **Fifteen tones with a name and one without.** Tone 16 is wave 1 with no
  envelopes and no filter: it may be the blank tone on purpose.
- **The padding at `0x7135`.** Between the last PLAY routine and the waves
  there are 203 bytes that are not code and nobody reads.
- **The cycles on a real machine.** What is measured (254 and 255 per sample,
  with the M1 wait state) is from openMSX; it has not been measured on a real
  MSX.
