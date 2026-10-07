#!/usr/bin/env python3
"""Cada pantalla montada desde la ROM, contra su volcado de VRAM de openMSX.

Los volcados viven en work/ (no viajan en el repositorio): work/vol1 trae
una pantalla de cada (konami, titulo, tone = TONE EDIT con el timbre 1,
wave, syn, play, file) y work/tone16 los dieciseis TONE EDIT, uno por
timbre. Se imprime, por pantalla, cuantos bytes de los que escribimos son
distintos del volcado y cuantos puntos difieren en la imagen; termina con
error si alguna no queda a cero.

El cursor de TONE EDIT parpadea (0xA5AA: color 8 o 12 cada 16 cuadros) y el
volcado lo pilla en una de las dos fases: ese byte, 0x3B03, se da por bueno
si vale 8 o 12 y se dice cual.

Uso: coteja_todo.py <rom>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pantallas  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CURSOR = 0x3B03


def volcado(carpeta, nombre):
    fich = os.path.join(RAIZ, "work", carpeta, nombre + ".vram")
    if not os.path.exists(fich):
        return None, None
    regs = list(open(fich[:-5] + ".regs", "rb").read())
    return open(fich, "rb").read(), regs


def main():
    rom = open(sys.argv[1], "rb").read()
    # SYN: el volcado bueno es work/syn1/s1 (el de vol1 es otro instante,
    # con la fuente ya cambiada por la cortina de salida)
    tareas = [("vol1", "konami", lambda: pantallas.logo_konami(rom)),
              ("vol1", "titulo", lambda: pantallas.titulo(rom)),
              ("vol1", "wave", lambda: pantallas.wave_edit(rom)),
              ("syn1", "s1", lambda: pantallas.syn(rom)),
              ("vol1", "play", lambda: pantallas.play(rom)),
              ("vol1", "file", lambda: pantallas.file_mode(rom)),
              ("vol1", "tone", lambda: pantallas.tone_edit(rom, 0))]
    for n in range(16):
        tareas.append(("tone16", "tone%02d" % (n + 1),
                       (lambda n=n: pantallas.tone_edit(rom, n))))
    fallos, hechas = 0, 0
    for carpeta, nombre, monta in tareas:
        vol, regs = volcado(carpeta, nombre)
        if vol is None:
            print("%-8s sin volcado (work/%s)" % (nombre, carpeta))
            continue
        if carpeta == "tone16":
            # el volcado de RAM dice que timbre estaba puesto (0xDB00)
            ram = open(os.path.join(RAIZ, "work", carpeta, nombre + ".ram"), "rb").read()
            if ram[0xDB00 - 0xC000] != int(nombre[4:]) - 1:
                print("%-8s el volcado tiene el timbre %d, no el %s"
                      % (nombre, ram[0xDB00 - 0xC000] + 1, nombre[4:]))
                fallos += 1
                continue
        v = monta()
        malos, puntos = pantallas.coteja(v, vol, regs)
        nota = ""
        if malos == [CURSOR] and vol[CURSOR] in (8, 12) and v.m[CURSOR] in (8, 12):
            nota = "  (solo el color del cursor, que parpadea: %d en el volcado)" % vol[CURSOR]
            malos, puntos = [], 0
        hechas += 1
        print("%-8s %5d bytes escritos, %d distintos, %d puntos distintos%s"
              % (nombre, len(v.escrito), len(malos), puntos, nota))
        for a in malos[:10]:
            print("         0x%04X nuestro %02X volcado %02X" % (a, v.m[a], vol[a]))
        if malos or puntos:
            fallos += 1
    print("%d pantallas cotejadas, %d con diferencias" % (hechas, fallos))
    sys.exit(1 if fallos else 0)


if __name__ == "__main__":
    main()
