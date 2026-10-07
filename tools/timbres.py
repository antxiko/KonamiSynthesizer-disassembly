#!/usr/bin/env python3
"""Los dieciseis timbres de fabrica (0xA3AA, 32 bytes cada uno), en una tabla
Markdown con los valores tal como los ensena TONE EDIT.

Cada timbre: 0 onda del DCO, 1 FEET del DCO (0xA6C3: 64 / byte en pies),
2 LFO del DCO, 3 ENV del DCO, 4 CUT, 5 RES, 6 LFO del DCF, 7 ENV del DCF,
8 LFO del DCA, 9-12 ADSR del DCO, 13-16 ADSR del DCF, 17-20 ADSR del DCA,
21 retencion del LFO (S/H), 22 onda del LFO, 23 FEET del LFO (0xA660:
1024 / byte), 24 conmutadores (bits 0-1 el filtro: 0 HPF, 1 BPF, 2 LPF;
bit 2 ENV del DCF restando; bit 3 ENV del DCO invertida; bit 7 EG TYP), y
el nombre en siete letras (0x21 = A, 0x41 = 1).

Uso: timbres.py <rom> [es|en]
"""
import sys

ORG = 0x4000
FILTRO = ("HPF", "BPF", "LPF", "?")


def letra(c):
    if 0x21 <= c <= 0x3A:
        return chr(ord("A") + c - 0x21)
    if 0x40 <= c <= 0x49:
        return chr(ord("0") + c - 0x40)
    return " "


def timbre(rom, n):
    a = 0xA3AA - ORG + 32 * n
    t = rom[a:a + 32]
    return t, "".join(letra(c) for c in t[25:32]).strip()


def onda(v):
    return "15 (ruido)" if v >= 15 else "15 (usuario)" if v == 14 else "%d" % (v + 1)


def main():
    rom = open(sys.argv[1], "rb").read()
    idioma = sys.argv[2] if len(sys.argv) > 2 else "es"
    if idioma == "es":
        cab = ("n", "nombre", "onda", "FEET", "LFO DCO", "ENV DCO", "CUT", "RES",
               "LFO DCF", "ENV DCF", "LFO DCA", "ADSR DCO", "ADSR DCF", "ADSR DCA",
               "S/H", "onda LFO", "FEET LFO", "filtro", "EG")
    else:
        cab = ("n", "name", "wave", "FEET", "LFO DCO", "ENV DCO", "CUT", "RES",
               "LFO DCF", "ENV DCF", "LFO DCA", "ADSR DCO", "ADSR DCF", "ADSR DCA",
               "S/H", "LFO wave", "LFO FEET", "filter", "EG")
    print("| " + " | ".join(cab) + " |")
    print("|" + "---|" * len(cab))
    for n in range(16):
        t, nombre = timbre(rom, n)
        adsr = lambda i: "/".join(str(x) for x in t[i:i + 4])
        fila = [str(n + 1), nombre or ("(sin nombre)" if idioma == "es" else "(no name)"),
                onda(t[0]), "%d'" % (64 // t[1]) if t[1] else "-",
                str(t[2]), str(t[3]), str(t[4]), str(t[5]), str(t[6]), str(t[7]), str(t[8]),
                adsr(9), adsr(13), adsr(17), str(t[21]),
                "%s" % ("S/H" if t[22] >= 15 else t[22] + 1),
                "%.2f'" % (1024 / t[23]) if t[23] else "-",
                FILTRO[t[24] & 3] + ("-" if t[24] & 4 else "") + ("i" if t[24] & 8 else ""),
                "DUR" if t[24] & 0x80 else "DEC"]
        print("| " + " | ".join(fila) + " |")


if __name__ == "__main__":
    main()
