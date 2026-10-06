#!/usr/bin/env python3
"""Quien apunta a cada hueco, buscando la palabra en TODA la ROM.

quien_lee.py mira el listado, o sea solo lo que el trazado dio por codigo. Aqui
se busca la palabra de 16 bits en los 16.384 bytes, este donde este: asi salen
tambien los punteros escritos DENTRO de una tabla de datos, que son justo los
que hacen falta cuando lo que se quiere saber es quien usa un bloque que nadie
carga con un `ld`.

De cada acierto se dice si cae en codigo trazado o en datos, para poder separar
la referencia de verdad de la coincidencia de dos bytes cualesquiera.

Uso: apunta_a.py <rom> <traza.json> <ini> <fin> [<ini> <fin> ...]
     apunta_a.py <rom> <traza.json> --huecos <presupuesto.txt>
"""
import json
import sys

ORG = 0x4000


def mapa_de_codigo(traza):
    """Un byte por posicion: 1 si el trazado lo dio por codigo."""
    m = bytearray(0x4000)
    for tipo, a, b in json.load(open(traza))["blocks"]:
        if tipo == "c":
            for i in range(max(0, a - ORG), min(0x4000, b - ORG)):
                m[i] = 1
    return m


def arranques_de_instruccion(traza):
    """Las direcciones donde empieza una instruccion, si la traza las trae."""
    d = json.load(open(traza))
    return set(d.get("starts", []))


def main():
    rom = open(sys.argv[1], "rb").read()
    cod = mapa_de_codigo(sys.argv[2])
    args = sys.argv[3:]
    rangos = [(int(args[i], 0), int(args[i + 1], 0)) for i in range(0, len(args), 2)]

    for ini, fin in rangos:
        print(f"\n{'=' * 66}\n0x{ini:04X}..0x{fin:04X}  ({fin - ini} bytes)\n{'=' * 66}")
        hallados = []
        for a in range(ORG, ORG + 0x4000 - 1):
            p = rom[a - ORG] | (rom[a + 1 - ORG] << 8)
            if ini <= p < fin:
                donde = "codigo" if cod[a - ORG] else "datos "
                hallados.append((a, p, donde))
        if not hallados:
            print("  nadie apunta aqui")
        for a, p, donde in hallados[:40]:
            print(f"  0x{a:04X} ({donde}) -> 0x{p:04X}")
        if len(hallados) > 40:
            print(f"  ... y {len(hallados) - 40} mas")


if __name__ == "__main__":
    main()
