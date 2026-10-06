#!/usr/bin/env python3
"""Los dos formatos con que el cartucho escribe en la VRAM, leidos como los
lee el Z80.

RLE (0x4352 / 0x4358 / 0x4327):
    0x4352 empieza leyendo una direccion de VRAM de 16 bits; 0x4358 la recibe
    en HL. Luego, byte a byte:
        0x00        fin
        0x80        sigue una direccion nueva de 16 bits
        n < 0x80    el byte siguiente, n veces
        n > 0x80    n & 0x7F bytes tal cual
    0x4327 hace 0x4358 tres veces, sumando 0x800 a HL: los tres tercios de
    la tabla de patrones o de la de colores.

LISTA (0x4337 / 0x434E): una direccion de 16 bits y bytes sueltos que se
    escriben uno detras de otro con WRTVRM; 0xFE trae una direccion nueva y
    0xFF acaba. 0x4337 escribe el byte tal cual (AND 0xFF) y 0x434E escribe
    ceros (AND 0x00): borra lo que la misma lista dibuja.

Uso como programa: flujos.py <rom> <rle|rle3|lista> <direccion> [hl]
"""
import sys

ORG = 0x4000


def rle(rom, de, hl=None, vram=None):
    """Recorre un flujo RLE desde DE. Devuelve (fin_exclusivo, escrituras).
    Con hl=None la direccion sale del flujo (0x4352); si no, de HL (0x4358)."""
    b = lambda a: rom[a - ORG]
    escr = []
    a = de
    if hl is None:
        hl = b(a) | (b(a + 1) << 8)
        a += 2
    while True:
        n = b(a)
        a += 1
        if n == 0:
            return a, escr
        if n == 0x80:
            hl = b(a) | (b(a + 1) << 8)
            a += 2
            continue
        if n & 0x80:
            for _ in range(n & 0x7F):
                escr.append((hl & 0x3FFF, b(a)))
                hl += 1
                a += 1
        else:
            v = b(a)
            a += 1
            for _ in range(n):
                escr.append((hl & 0x3FFF, v))
                hl += 1


def rle3(rom, de, hl):
    """0x4327: el mismo flujo tres veces, cada vez 0x800 mas alla. Las tres
    pasadas leen los MISMOS bytes: los tres tercios salen iguales."""
    fin, escr = rle(rom, de, hl)
    todo = []
    for k in range(3):
        todo += [(v + 0x800 * k, x) for v, x in escr]
    return fin, todo


def lista(rom, de, borra=False):
    b = lambda a: rom[a - ORG]
    a = de
    hl = b(a) | (b(a + 1) << 8)
    a += 2
    escr = []
    while True:
        v = b(a)
        a += 1
        if v == 0xFF:
            return a, escr
        if v == 0xFE:
            hl = b(a) | (b(a + 1) << 8)
            a += 2
            continue
        escr.append((hl & 0x3FFF, 0 if borra else v))
        hl += 1


def main():
    rom = open(sys.argv[1], "rb").read()
    modo, de = sys.argv[2], int(sys.argv[3], 0)
    hl = int(sys.argv[4], 0) if len(sys.argv) > 4 else None
    if modo == "rle":
        fin, e = rle(rom, de, hl)
    elif modo == "rle3":
        fin, e = rle3(rom, de, hl)
    else:
        fin, e = lista(rom, de)
    print("0x%04X-0x%04X  %d bytes  %d escrituras  VRAM 0x%04X-0x%04X" % (
        de, fin, fin - de, len(e), min(v for v, _ in e), max(v for v, _ in e)))


if __name__ == "__main__":
    main()
