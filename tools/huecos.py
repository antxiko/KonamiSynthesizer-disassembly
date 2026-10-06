#!/usr/bin/env python3
"""Imprime un tramo del listado marcando con > las instrucciones SIN comentar.

Al comentar una segunda pasada, la mitad del trabajo es no volver a escribir lo
que ya esta escrito: los repetidos se tiran a la basura y el rato tambien.

Uso: huecos.py <asm> <desde 0x> <hasta 0x>
"""
import re
import sys


def main():
    a = int(sys.argv[2], 16)
    b = int(sys.argv[3], 16)
    pendiente = []
    for ln in open(sys.argv[1], encoding="utf-8").read().splitlines():
        m = re.match(r"^\t.*;([0-9a-f]{4})(.*)$", ln)
        if not m:
            if re.match(r"^[A-Za-z_][A-Za-z_0-9]*:", ln) or ln.startswith("; "):
                pendiente.append(ln)
            continue
        d = int(m.group(1), 16)
        if not (a <= d < b):
            pendiente = []
            continue
        for p in pendiente[-3:]:
            print(p)
        pendiente = []
        print(("> " if ";" not in m.group(2) else "  ") + ln)


main()
