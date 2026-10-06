#!/usr/bin/env python3
"""Localiza en ESTE cartucho las rutinas que ya tienen nombre en otro.

comun_normalizado.py dice CUANTO comparten dos cartuchos y donde empiezan los
tramos comunes; lo que hace falta para aprovecharlo es la traduccion de
direcciones, una a una.

Aqui se trazan las dos ROM con su propio .trace.json, se normalizan -los
opcodes tal cual y los operandos de dieciseis bits a cero, que son los que
llevan las direcciones y cambian al reensamblar en otro sitio- y se buscan los
tramos comunes maximales. De cada tramo sale un MAPA de direcciones, y con ese
mapa se traducen las directivas L, C y B del .notes del donante.

Lo que sale es una propuesta con su medida -cuantos bytes tiene el tramo que la
sostiene-, no un nombre heredado a ciegas: hay que leer el codigo de AQUI antes
de quedarse con cada linea. Un comentario portado puede mentir, que ya ha
pasado.

Uso: porta_nombres.py <romA> <orgA> <trazaA> <romB> <orgB> <trazaB> <notesB>
                      [minimo_bytes_de_tramo]
     A = este cartucho (donde se busca)   B = el donante (de donde salen)
"""
import json
import os
import re
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80trace import Tracer                                   # noqa: E402

# Opcodes cuyos dos ultimos bytes son una direccion o un inmediato de 16 bits
# (la misma lista que comun_normalizado.py; copiada porque aquel modulo ejecuta
# su main() al importarlo).
ABS16 = ({0x01, 0x11, 0x21, 0x31, 0x22, 0x2A, 0x32, 0x3A, 0xC3, 0xCD}
         | {0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA}
         | {0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC})


def normaliza(rom, org, a, n):
    q = bytearray(rom[a - org:a - org + n])
    op = q[0]
    if op in ABS16 and n >= 3:
        q[-2] = q[-1] = 0
    elif op in (0xDD, 0xFD) and n >= 4 and q[1] in ABS16:
        q[-2] = q[-1] = 0
    elif op == 0xED and n == 4:
        q[-2] = q[-1] = 0
    return bytes(q)


def tira(rompath, org, trazapath):
    """(bytes normalizados, offset->direccion por cada byte del tramo)."""
    rom = open(rompath, "rb").read()
    t = Tracer(rom, org)
    out, dirs, inicio = bytearray(), [], []
    for k, a, b in json.load(open(trazapath, encoding="utf-8"))["blocks"]:
        if k != "c":
            continue
        p = a
        while p < b:
            n = t.ilen(p)
            if not n or p + n > b:
                break
            out += normaliza(rom, org, p, n)
            dirs += [p] * n                # todo byte apunta al inicio de SU instruccion
            inicio += [True] + [False] * (n - 1)
            p += n
    return bytes(out), dirs, inicio


def tramos(A, B, minimo):
    """Tramos comunes maximales [(largo, iA, iB)], sin solapes en B."""
    K = 12
    idx = defaultdict(list)
    for i in range(len(A) - K + 1):
        idx[A[i:i + K]].append(i)
    res, j = [], 0
    while j <= len(B) - K:
        cand = idx.get(B[j:j + K])
        if not cand:
            j += 1
            continue
        mejor = (0, 0, 0)
        for i0 in cand:
            i, k = i0, j
            while i > 0 and k > 0 and A[i - 1] == B[k - 1]:
                i -= 1
                k -= 1
            f1, f2 = i0 + K, j + K
            while f1 < len(A) and f2 < len(B) and A[f1] == B[f2]:
                f1 += 1
                f2 += 1
            if f1 - i > mejor[0]:
                mejor = (f1 - i, i, k)
        ln, i, k = mejor
        if ln >= minimo:
            res.append((ln, i, k))
        j = k + max(ln, 1)
    return res


def main():
    av = sys.argv[1:]
    if len(av) < 7:
        sys.exit(__doc__)
    romA, orgA, tzA, romB, orgB, tzB, notesB = av[:7]
    minimo = int(av[7]) if len(av) > 7 else 16
    A, dirA, inA = tira(romA, int(orgA, 0), tzA)
    B, dirB, inB = tira(romB, int(orgB, 0), tzB)

    # mapa direccionB -> (direccionA, largo del tramo que lo sostiene)
    mapa = {}
    for ln, i, k in tramos(A, B, minimo):
        for d in range(ln):
            # solo cuenta si el byte es el PRIMERO de su instruccion en las dos
            # ROM: al estirar un tramo hacia atras se pueden emparejar los
            # ultimos bytes de dos instrucciones DISTINTAS -en Goonies un
            # `ld sp,nn` y aqui un `ld (nn),hl`- y el nombre acabaria puesto en
            # la instruccion de al lado
            if not (inA[i + d] and inB[k + d]):
                continue
            db, da = dirB[k + d], dirA[i + d]
            if db not in mapa or mapa[db][1] < ln:
                mapa[db] = (da, ln)

    n = 0
    for linea in open(notesB, encoding="utf-8", errors="replace"):
        m = re.match(r"^([LCB])\s+0x([0-9A-Fa-f]{1,4})\s+(.*)$", linea.rstrip())
        if not m:
            continue
        ad = int(m.group(2), 16)
        if ad not in mapa:
            continue
        da, ln = mapa[ad]
        n += 1
        print("%s 0x%04X %s   ; %s 0x%04X, tramo de %d bytes"
              % (m.group(1), da, m.group(3), os.path.basename(romB), ad, ln))
    print("# ---- %d directivas traducidas (tramos de %d bytes o mas)"
          % (n, minimo), file=sys.stderr)


main()
