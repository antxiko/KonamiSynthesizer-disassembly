#!/usr/bin/env python3
"""Las maquinas de estados que el trazado no ve: variables de RAM que guardan
la direccion de la rutina siguiente.

El patron, en el codigo ya trazado:

    ld hl,(VAR) / jp (hl)          <- el salto: VAR es una variable de estado
    ld hl,RUTINA / ld (VAR),hl     <- cada sitio que la cambia

Las envolventes de los tres EG (0xDC25, 0xDC29, 0xDC2D) y el mezclador
(0xDC40) van asi: cada fase deja escrita la direccion de la siguiente.

Uso: estados.py <rom> <org> <blocks>
Escribe las direcciones RUTINA que caen fuera del codigo trazado, una por
linea con su VAR y el sitio que la pone, listas para el .entries.
"""
import sys


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    code = set()
    for ln in open(sys.argv[3]):
        a, t, c = ln.split()
        if t == "code":
            code.update(range(int(a, 16), int(c, 16) + 1))

    def b(a):
        return rom[a - org]

    def w(a):
        return b(a) | (b(a + 1) << 8)

    variables = {w(a + 1) for a in code
                 if a + 3 < org + len(rom) and b(a) == 0x2A and a + 3 in code
                 and b(a + 3) == 0xE9}
    vistos = set()
    for a in sorted(code):
        if a + 5 >= org + len(rom) or b(a) != 0x21 or b(a + 3) != 0x22:
            continue
        v, m = w(a + 1), w(a + 4)
        if m in variables and v not in code and v not in vistos:
            vistos.add(v)
            print("0x%04X   # (0x%04X), puesta en 0x%04X" % (v, m, a))


if __name__ == "__main__":
    main()
