#!/usr/bin/env python3
"""Para cada bloque de datos, quien lo carga y desde donde.

Identificar un bloque por su aspecto es adivinar. Lo que lo identifica de
verdad es el codigo que lo lee: la instruccion que carga su direccion y, sobre
todo, lo que hace despues con ella.

Asi que esto recorre el listado buscando toda instruccion que cargue una
constante de 16 bits (`ld hl,NNNN`, `ld de,NNNN`, `ld bc,NNNN`, `ld ix/iy,NNNN`)
o que salte/llame a una direccion, y reune las que caen dentro del rango que se
le pide. Se apoya en el .asm ya generado, no en el binario: asi las direcciones
son las que el trazado dio por buenas.

Uso: quien_lee.py <listado.asm> <ini> <fin> [<ini> <fin> ...]
     quien_lee.py <listado.asm> --lista        (rangos por la entrada, "ini fin")
"""
import re
import sys

# `ld rr,0NNNNh` con la constante en hexadecimal del estilo de mkasm.py, y los
# saltos y llamadas a direccion absoluta (que mkasm escribe como etiqueta
# L_NNNN cuando el trazado la alcanzo, y como numero cuando no).
CARGA = re.compile(r"\bld\s+(hl|de|bc|ix|iy|sp),\s*0([0-9a-f]{4})h\b", re.I)
SALTO = re.compile(r"\b(jp|jr|call)\s+(?:[a-z]{1,2},\s*)?0?([0-9a-f]{4})h\b", re.I)
ETIQ = re.compile(r"\b(jp|jr|call)\s+(?:[a-z]{1,2},\s*)?L_([0-9A-F]{4})\b")
DIREC = re.compile(r";\s*([0-9a-f]{4})\s*$")


def lee_listado(ruta):
    """Devuelve [(direccion, texto)] de cada linea de instruccion del listado."""
    fuera = []
    with open(ruta, encoding="utf-8") as f:
        for linea in f:
            m = DIREC.search(linea.rstrip())
            if not m:
                # mkasm pone la direccion al final, pero las lineas con
                # comentario de BIOS la llevan antes del comentario.
                m = re.search(r";\s*([0-9a-f]{4})\s+;", linea)
                if not m:
                    continue
            fuera.append((int(m.group(1), 16), linea.rstrip()))
    return fuera


def referencias(lineas, ini, fin):
    """Toda carga o salto cuyo destino caiga en [ini, fin)."""
    fuera = []
    for dir_, texto in lineas:
        for rx, cual in ((CARGA, "carga"), (SALTO, "salto"), (ETIQ, "salto")):
            for m in rx.finditer(texto):
                val = int(m.group(2), 16)
                if ini <= val < fin:
                    fuera.append((dir_, val, cual, texto.split(";")[0].strip()))
    return fuera


def main():
    if len(sys.argv) < 3:
        print(__doc__.strip())
        return 2
    lineas = lee_listado(sys.argv[1])

    if sys.argv[2] == "--lista":
        rangos = []
        for linea in sys.stdin:
            partes = linea.split()
            if len(partes) >= 2:
                rangos.append((int(partes[0], 16), int(partes[1], 16)))
    else:
        nums = [int(x, 16) for x in sys.argv[2:]]
        rangos = list(zip(nums[0::2], nums[1::2]))

    for ini, fin in rangos:
        refs = referencias(lineas, ini, fin)
        print("=" * 70)
        print("0x%04X..0x%04X  (%d bytes)  %d referencias"
              % (ini, fin, fin - ini, len(refs)))
        print("=" * 70)
        if not refs:
            print("  NADIE lo carga con una constante: o entra por indice, o")
            print("  es continuacion de un bloque anterior, o no lo lee nadie.")
        for desde, val, cual, texto in sorted(refs, key=lambda r: (r[1], r[0])):
            print("  0x%04X -> 0x%04X  %-5s  %s" % (desde, val, cual, texto))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
