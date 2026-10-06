"""Lo que se afirma del cartucho, comprobado contra sus bytes.

Corre con el cartucho delante y sin el: cuando no esta, la imagen se rehace
desde las filas defb/defw del listado, que si viaja con el repositorio. Sin el
cartucho solo se comprueba lo que cae en datos.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

import flujos  # noqa: E402

ROM = os.path.join(RAIZ, "synth.rom")
ASM = os.path.join(RAIZ, "src", "synth.asm")
NOTAS = os.path.join(RAIZ, "src", "synth.notes")
ORG = 0x4000
TAM = 32768

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def rangos_d():
    r = {}
    with open(NOTAS, encoding="utf-8") as f:
        lineas = f.readlines()
    for ln in lineas:
        p = ln.split()
        if len(p) >= 4 and p[0] == "D":
            r[p[3]] = (int(p[1], 16), int(p[2], 16))
    return r


class Cabecera(unittest.TestCase):
    def test_es_un_cartucho_msx_de_32k(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(len(rom), TAM)

    def test_init_es_4054(self):
        rom = lee()
        self.assertEqual(rom[2] | (rom[3] << 8), 0x4054)

    def test_el_gancho_de_h_stke_salta_a_406e(self):
        """`rst 0x30`, el slot (a cero en la ROM), 0x406E y `ret`."""
        self.assertEqual(lee()[0x69:0x6E], bytes([0xF7, 0x00, 0x6E, 0x40, 0xC9]))


class Flujos(unittest.TestCase):
    """Cada flujo de graficos, recorrido como lo recorre el descompresor,
    acaba justo donde la nota dice: ni un byte de menos ni de mas."""

    CASOS = [
        ("rle", 0x8000, None, "titulo_nombres"),
        ("rle3", 0x82A5, 0x2200, "marco_colores"),
        ("rle3", 0x84EB, 0x0008, "marco_patrones_1"),
        ("rle3", 0x8531, 0x00D8, "marco_patrones_2"),
        ("rle3", 0x8552, 0x01D8, "marco_patrones_3"),
        ("rle", 0x874D, None, "wave_edit_1"),
        ("rle", 0x87DB, None, "cabecera_nombres"),
        ("rle", 0x8815, None, "wave_edit_nombres"),
        ("rle3", 0x8AC1, 0x2458, "tone_edit_colores"),
        ("rle3", 0x8DB6, 0x0458, "tone_edit_patrones"),
        ("rle", 0x9087, None, "tone_edit_nombres"),
        ("rle3", 0x925A, 0x2080, "teclado_colores_1"),
        ("rle", 0x9988, None, "teclado_nombres"),
        ("rle3", 0x9AC5, 0x2458, "file_colores"),
        ("rle", 0x9D74, None, "file_nombres"),
        ("rle3", 0xA2BF, 0x0200, "titulo_patrones"),
        ("rle", 0xA2E5, None, "titulo_nombres_logo"),
        ("rle3", 0x4414, 0x2080, "logo_konami_rle"),
        ("rle", 0x45B9, None, "logo_konami_nombres"),
        ("lista", 0xBE75, None, "rotulo_push_space_key"),
    ]

    def test_cada_flujo_cierra_en_su_nota(self):
        if not os.path.exists(ROM):
            self.skipTest("sin el cartucho")
        rom = lee()
        d = rangos_d()
        for modo, de, hl, nombre in self.CASOS:
            if modo == "rle":
                fin, _ = flujos.rle(rom, de, hl)
            elif modo == "rle3":
                fin, _ = flujos.rle3(rom, de, hl)
            else:
                fin, _ = flujos.lista(rom, de)
            if nombre == "rotulo_push_space_key":
                fin += 0x11  # la segunda linea, 0xBE84, cierra en 0xBEA6
            por_inicio = {v[0]: v for v in d.values()}
            self.assertEqual((de, fin), por_inicio[de], nombre)

    def test_la_pagina_2_encadena_sin_huecos(self):
        """De 0x8000 a 0xA5AA, cada rango D empieza donde acaba el anterior."""
        r = sorted(v for v in rangos_d().values() if 0x8000 <= v[0] < 0xA5AA)
        self.assertEqual(r[0][0], 0x8000)
        self.assertEqual(r[-1][1], 0xA5AA)
        for (a, b), (c, _) in zip(r, r[1:]):
            self.assertEqual(b, c, "hueco entre 0x%04X y 0x%04X" % (b, c))


class Timbres(unittest.TestCase):
    NOMBRES = ["EBASS1", "EBASS2", "BRASS", "TRUMPET", "STRINGS", "EORGAN",
               "PORGAN", "EPIANO", "GLOCKEN", "KOTO", "CONGA", "SYNDRUM",
               "IMAGE", "PARC1", "PARC2", ""]

    def test_los_dieciseis_nombres(self):
        rom = lee()

        def letra(c):
            if 0x21 <= c <= 0x3A:
                return chr(ord("A") + c - 0x21)
            if 0x41 <= c <= 0x49:
                return chr(ord("1") + c - 0x41)
            return " "

        for i, nombre in enumerate(self.NOMBRES):
            a = 0xA3AA - ORG + 32 * i
            leido = "".join(letra(c) for c in rom[a + 24:a + 32]).strip()
            self.assertEqual(leido, nombre, "timbre %d" % (i + 1))


class Presupuesto(unittest.TestCase):
    def test_reensambla_y_todo_explicado(self):
        if not os.path.exists(ROM):
            self.skipTest("sin el cartucho")
        r = subprocess.run([sys.executable, "tools/presupuesto.py", "work", "src"],
                           cwd=RAIZ, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("100.00 %", r.stdout)


if __name__ == "__main__":
    unittest.main()
