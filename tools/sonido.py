#!/usr/bin/env python3
"""Los timbres de fabrica tocados como los toca PLAY, en WAV.

El sonido es el de tools/motor.py (SYN, igual byte a byte que el cartucho).
La reproduccion es la de PLAY:

  - una sola voz: PLAY lee el bufer de 0x8000 de uno en uno y escribe cada
    byte en el DAC (0x4000);
  - la altura la pone lo que dura cada muestra: por nota, 0x5E29 da una
    rutina r (0-12) y un retardo D, y la muestra dura c(r) + 16 * D ciclos
    del Z80 a 3,58 MHz. c(r) esta medido en openMSX con tools/omsx_ritmo.tcl
    (escrituras en 0x4000 con la tecla Z puesta a cada rutina, D = 0x20 y
    0x40): las trece rutinas son el mismo bucle con un ajuste fino;
  - con pagina de bucle (0xDCFD, rutinas de 0x5E8B) suena hasta entrar en
    ella, la repite mientras se tiene la tecla y al soltarla sigue hasta
    0xC000; sin ella (rutinas de 0x6709) suena entera hasta 0xC000. Detras
    de lo sintetizado el bufer es 0x80, silencio.

El WAV es de 8 bits sin signo, como el DAC: cada muestra se repite el tiempo
que la deja puesta el Z80.

Uso: sonido.py <rom> <timbre 1-16> <posicion de la nota 0-48> <salida.wav>
     [segundos con la tecla pulsada] [--bios bios.rom]
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor  # noqa: E402

ORG = 0x4000
RELOJ = 3579545
TASA = 44100
# c(r): ciclos de cada rutina fuera del retardo, medidos (media de 3000
# muestras; la fraccion sale de que el bucle va de ocho en ocho muestras)
CICLOS = [67.4, 68.4, 71.4, 71.4, 72.4, 72.4, 75.4, 75.4, 77.4, 78.4,
          79.4, 80.4, 82.4]
NOTAS = ["FA", "FA#", "SOL", "SOL#", "LA", "LA#", "SI", None,
         "DO", "DO#", "RE", "RE#", "MI", None]


def nota(rom, pos):
    """(rutina, retardo, ciclos por muestra, nombre) de la posicion pos de
    0x5E29 (la de la lista 0xBCCA: blanca, negra, blanca... desde FA1)."""
    a = 0x5E29 - ORG + 2 * pos
    r, d = rom[a], rom[a + 1]
    if r == 0xFF:
        return None
    nombre = NOTAS[pos % 14]
    octava = 1 + (pos + 6) // 14
    return r, d, CICLOS[r] + 16 * d, "%s%d" % (nombre, octava)


def reproduce(bufer, bucle, ciclos, sostener):
    """La secuencia de bytes que llega al DAC y lo que dura cada uno. Se
    corta donde acaba lo sintetizado: detras solo queda 0x80."""
    datos = bytes(bufer) + bytes([0x80]) * (0x4000 - len(bufer))
    pm = ciclos / RELOJ
    if not bucle:
        return list(datos[:len(bufer)]), pm
    inicio = (bucle - 0x80) * 0x100
    sale = list(datos[:inicio])
    t = inicio * pm
    j = 0
    while t < sostener:                    # 0x5EEC: la pagina, en bucle
        sale.append(datos[inicio + j])
        j = (j + 1) & 0xFF
        t += pm
    while j:                               # 0x5EFD: al soltar, hasta su final
        sale.append(datos[inicio + j])
        j = (j + 1) & 0xFF
    sale += datos[inicio + 0x100:max(len(bufer), inicio + 0x100)]
    return sale, pm


def wav(muestras, por_muestra, fich, cola=0.2):
    n = int(len(muestras) * por_muestra * TASA) + int(cola * TASA)
    pcm = bytearray(n)
    for k in range(n):
        j = int(k / TASA / por_muestra)
        pcm[k] = muestras[j] if j < len(muestras) else 0x80
    with open(fich, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 36 + n) + b"WAVEfmt "
                + struct.pack("<IHHIIHH", 16, 1, 1, TASA, TASA, 1, 8)
                + b"data" + struct.pack("<I", n) + bytes(pcm))
    return n / TASA


def main():
    bios = None
    if "--bios" in sys.argv:
        i = sys.argv.index("--bios")
        bios = open(sys.argv[i + 1], "rb").read()[:256]
        del sys.argv[i:i + 2]
    rom = open(sys.argv[1], "rb").read()
    n = int(sys.argv[2])
    pos = int(sys.argv[3])
    sostener = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0
    a = 0xA3AA - ORG + 32 * (n - 1)
    m = motor.Motor(rom, rom[a:a + 32], bios=bios)
    bufer = m.sintetiza()
    r, d, ciclos, nombre = nota(rom, pos)
    sale, pm = reproduce(bufer, m.bucle, ciclos, sostener)
    s = wav(sale, pm, sys.argv[4])
    print("timbre %d en %s (rutina %d, D = %d, %.0f muestras por segundo): %.2f s"
          % (n, nombre, r, d, 1 / pm, s))


if __name__ == "__main__":
    main()
