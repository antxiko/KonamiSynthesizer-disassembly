#!/usr/bin/env python3
"""Las imagenes de la web, todas desde la ROM con pantallas.py.

Ni una captura: cada pantalla se monta con las tablas del cartucho y se pinta
con vram.py; las que tienen volcado de openMSX se cotejan en coteja_todo.py.
Los recortes (el logotipo de Konami, el rotulo) no se ponen a ojo: se miden
sobre la tabla de nombres que escribe el propio cartucho.

Uso: imagenes.py <rom> <directorio>
"""
import os
import struct
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import flujos                                           # noqa: E402
import pantallas                                        # noqa: E402
import vram                                             # noqa: E402

ORG = 0x4000
PAL = vram.PALETA


# ----------------------------------------------------------------- lienzos
class Lienzo:
    def __init__(self, w, h, fondo=(0, 0, 0)):
        self.w, self.h = w, h
        self.px = bytearray(bytes(fondo) * (w * h))

    @classmethod
    def de_pantalla(cls, v, con_sprites=True):
        c = cls(256, 192)
        c.px = bytearray(v.imagen(con_sprites))
        return c

    def punto(self, x, y, rgb):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 3
            self.px[i:i + 3] = bytes(rgb)

    def recorta(self, x, y, w, h):
        c = Lienzo(w, h)
        for j in range(h):
            i = ((y + j) * self.w + x) * 3
            c.px[j * w * 3:(j + 1) * w * 3] = self.px[i:i + w * 3]
        return c

    def pega(self, otro, x, y):
        for j in range(otro.h):
            if 0 <= y + j < self.h:
                i = ((y + j) * self.w + x) * 3
                self.px[i:i + otro.w * 3] = otro.px[j * otro.w * 3:(j + 1) * otro.w * 3]

    def escala(self, k):
        c = Lienzo(self.w * k, self.h * k)
        for y in range(c.h):
            fila = self.px[(y // k) * self.w * 3:(y // k + 1) * self.w * 3]
            out = bytearray()
            for x in range(self.w):
                out += fila[x * 3:x * 3 + 3] * k
            c.px[y * c.w * 3:(y + 1) * c.w * 3] = out
        return c

    def guarda(self, fn):
        raw = b"".join(b"\0" + bytes(self.px[y * self.w * 3:(y + 1) * self.w * 3])
                       for y in range(self.h))

        def trozo(t, d):
            return (struct.pack(">I", len(d)) + t + d
                    + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
        with open(fn, "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n")
            f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 2, 0, 0, 0)))
            f.write(trozo(b"IDAT", zlib.compress(raw, 9)))
            f.write(trozo(b"IEND", b""))


def recuadro_de_tiles(v, minimo=0x40, margen=8):
    """El rectangulo de pantalla que ocupan las casillas de la tabla de
    nombres (0x3800) con tile >= minimo: filas y columnas medidas, no a ojo."""
    casillas = [(i // 32, i % 32) for i in range(0x300) if v.m[0x3800 + i] >= minimo]
    f0, f1 = min(f for f, c in casillas), max(f for f, c in casillas)
    c0, c1 = min(c for f, c in casillas), max(c for f, c in casillas)
    x, y = c0 * 8 - margen, f0 * 8 - margen
    w, h = (c1 - c0 + 1) * 8 + 2 * margen, (f1 - f0 + 1) * 8 + 2 * margen
    return max(x, 0), max(y, 0), min(w, 256 - max(x, 0)), min(h, 192 - max(y, 0))


# ------------------------------------------------------------- las letras
def letra(rom, t, tinta=(255, 255, 255)):
    """Un caracter de la fuente de 0x4414 (tile t: 0x10-0x19 cifras,
    0x21-0x3A letras)."""
    pats = dict(flujos.rle3(rom, 0x4414, 0x2080)[1])
    c = Lienzo(8, 8)
    for y in range(8):
        v = pats.get(0x2000 + 8 * t + y, 0)
        for x in range(8):
            if v & (0x80 >> x):
                c.punto(x, y, tinta)
    return c


def texto(rom, s):
    tiles = [0x10 + int(ch) if ch.isdigit() else None if ch == " "
             else 0x21 + ord(ch.upper()) - ord("A") for ch in s]
    c = Lienzo(8 * len(tiles), 8)
    for i, t in enumerate(tiles):
        if t is not None:
            c.pega(letra(rom, t), 8 * i, 0)
    return c


# --------------------------------------------------------------- las ondas
def onda(muestras, w=256, h=64, fondo=(16, 16, 24), tinta=(255, 220, 80)):
    """Una onda de 256 muestras con signo, una columna por muestra, con la
    linea del cero."""
    c = Lienzo(w, h, fondo)
    for x in range(w):
        c.punto(x, h // 2, (60, 60, 80))
    for x, s in enumerate(muestras):
        s = s - 256 if s & 0x80 else s
        y = h // 2 - (s * (h // 2 - 2)) // 128
        c.punto(x, y, tinta)
        c.punto(x, y - 1, tinta)
    return c


# ------------------------------------------------------------------ todo
def main():
    rom = open(sys.argv[1], "rb").read()
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)

    # el logotipo de Konami: la pantalla y el recorte de sus 20 x 6 tiles
    k = Lienzo.de_pantalla(pantallas.logo_konami(rom))
    k.escala(2).guarda(os.path.join(out, "konami.png"))
    k.recorta(*recuadro_de_tiles(pantallas.logo_konami(rom))).escala(3).guarda(
        os.path.join(out, "logotipo-konami.png"))

    # el titulo: el logotipo 新世SIZER (tiles 0x40 en adelante) y el rotulo
    t = pantallas.titulo(rom)
    tl = Lienzo.de_pantalla(t)
    tl.escala(2).guarda(os.path.join(out, "titulo.png"))
    tl.recorta(*recuadro_de_tiles(t)).escala(3).guarda(os.path.join(out, "rotulo.png"))

    # TONE EDIT con cada timbre de fabrica, y la lamina de los dieciseis
    L = Lienzo(4 * 256 + 5 * 8, 4 * (192 + 12) + 5 * 8, (16, 16, 24))
    for n in range(16):
        c = Lienzo.de_pantalla(pantallas.tone_edit(rom, n))
        c.escala(2).guarda(os.path.join(out, "tone-%02d.png" % (n + 1)))
        x, y = 8 + (n % 4) * (256 + 8), 8 + (n // 4) * (192 + 12 + 8)
        L.pega(texto(rom, "%2d" % (n + 1)), x, y)
        L.pega(c, x, y + 12)
    L.guarda(os.path.join(out, "tone-edit.png"))

    # WAVE EDIT, SYN, PLAY y FILE MODE
    for nombre, monta in (("wave", pantallas.wave_edit), ("syn", pantallas.syn),
                          ("play", pantallas.play), ("file", pantallas.file_mode)):
        Lienzo.de_pantalla(monta(rom)).escala(2).guarda(os.path.join(out, nombre + ".png"))

    # las catorce ondas del oscilador: la pagina 0x72 + n de la ROM (0x56FF)
    H = Lienzo(2 * 256 + 3 * 8, 7 * (64 + 12) + 8 * 8, (16, 16, 24))
    for n in range(14):
        a = 0x7200 - ORG + 0x100 * n
        x, y = 8 + (n // 7) * (256 + 8), 8 + (n % 7) * (64 + 12 + 8)
        H.pega(texto(rom, "%2d" % (n + 1)), x, y)
        H.pega(onda(rom[a:a + 0x100]), x, y + 12)
    H.escala(2).guarda(os.path.join(out, "ondas.png"))
    print("imagenes en", out)


if __name__ == "__main__":
    main()
