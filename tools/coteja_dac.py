#!/usr/bin/env python3
"""Lo que PLAY manda al DAC en openMSX, contra lo que sintetiza motor.py.

tools/omsx_dac.tcl apunta cada byte que el Z80 escribe en 0x4000 con su
instante (SY_OUT/dac.txt), tocando con la tecla Z una nota de rutina r y
retardo D sobre el timbre que SYN acaba de sintetizar. Aqui se reconstruye
lo que tendria que haber llegado -el byte de reposo, el sample hasta la
pagina de bucle, esa pagina tantas veces como se tuvo la tecla y la cola
hasta 0xC000- y se compara byte a byte; y se mide el periodo entre
escrituras, en ciclos del Z80, contra el que usa tools/sonido.py.

Uso: coteja_dac.py <rom> <dac.txt> <timbre 1-16> <rutina> <retardo> [--bios bios.rom]
"""
import collections
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor   # noqa: E402
import sonido  # noqa: E402

ORG = 0x4000


def main():
    args = sys.argv[1:]
    bios = None
    if "--bios" in args:
        i = args.index("--bios")
        bios = open(args[i + 1], "rb").read()[:256]
        del args[i:i + 2]
    rom = open(args[0], "rb").read()
    timbre, r, d = int(args[2]) - 1, int(args[3]), int(args[4])
    a = 0xA3AA - ORG + 32 * timbre
    m = motor.Motor(rom, rom[a:a + 32], bios=bios)
    buf = m.sintetiza()
    lleno = bytes(buf) + bytes([0x80]) * (0x4000 - len(buf))
    ts, vs = [], []
    for ln in open(args[1]):
        t, v = ln.split()
        ts.append(float(t))
        vs.append(int(v, 16))
    n = len(vs)
    print("timbre %d: %d bytes sintetizados, pagina de bucle 0x%02X; %d bytes al DAC"
          % (timbre + 1, len(buf), m.bucle, n))
    if m.bucle:
        p0 = (m.bucle - 0x80) * 256
        vueltas, resto = divmod(n - 1 - 0x4000, 256)
        esperado = (bytes([0x80]) + lleno[:p0] + lleno[p0:p0 + 256] * (1 + vueltas)
                    + lleno[p0 + 256:])
        print("  1 de reposo + 16384 + %d vueltas x 256 (resto %d)" % (vueltas, resto))
    else:
        esperado = bytes([0x80]) + lleno + bytes([0x80])
    dist = sum(1 for x, y in zip(vs, esperado) if x != y) + abs(len(vs) - len(esperado))
    print("  esperados %d, distintos %d" % (len(esperado), dist))
    for i, (x, y) in enumerate(zip(vs, esperado)):
        if x != y:
            print("  el primero en %d: %02X y tendria que ser %02X" % (i, x, y))
            break
    ciclos = [round((ts[i] - ts[i - 1]) * sonido.RELOJ) for i in range(2, n)]
    c = collections.Counter(ciclos)
    print("  periodo medido: media %.2f ciclos, min %d, max %d; los mas frecuentes %s"
          % (sum(ciclos) / len(ciclos), min(ciclos), max(ciclos), c.most_common(3)))
    print("  periodo de sonido.py: CICLOS[%d] + 16 * %d = %.1f" % (r, d, sonido.CICLOS[r] + 16 * d))
    sys.exit(1 if dist else 0)


if __name__ == "__main__":
    main()
