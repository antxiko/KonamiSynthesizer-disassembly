"""La web, comprobada contra el listado: las cifras de la portada y el
barrido de nombres y ficheros de otros juegos de la serie."""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from test_listado import ASM, FILA, ROM      # noqa: E402

DOCS = os.path.join(RAIZ, "docs")

# Los demas juegos de la serie. Que el nombre de otro salga en una pagina de
# este es casi siempre un copia y pega.
OTROS_JUEGOS = (
    "Tennis", "Pitfall", "Temptations", "Stardust", "Ale Hop", "Colt 36",
    "Antarctic", "Athletic Land", "Monkey Academy", "F-1 Spirit", "Pippols",
    "Time Pilot", "Frogger", "Super Cobra", "Billiards", "Mahjong",
    "Hyper Rally", "Nemesis", "Demonia", "Cabbage", "Hole in One",
    "Casio World Open", "3D Golf", "Baseball", "Yie Ar Kung-Fu",
    "King's Valley", "Sky Jaguar", "Mopi Ranger", "Descubrimiento",
    "War in Middle Earth", "Ping Pong", "Soccer", "Football", "Road Fighter",
    "Hyper Sports", "Hyper Olympic", "Goonies", "Knightmare", "Twin Bee",
    "Penguin", "Bomber", "Circus Charlie", "Comic Bakery", "Magical Tree",
    "King Kong", "Vampire Killer", "Q*bert", "Qbert", "Gottlieb",
)

# La seccion del codigo compartido con los otros Konami de la serie los
# nombra a proposito: la escribe pon_en_webs.py, de MSX-disassembly-database.
_COMPARTIDO = re.compile(
    r"(?:^## |<h2[^>]*>)(?:Code shared with other Konami cartridges|"
    r"C\u00f3digo compartido con otros cartuchos de Konami)"
    r".*?(?=^## |<h2|</main>|<footer|\Z)", re.S | re.M)


def sin_compartido(texto):
    """El texto sin la seccion del codigo compartido."""
    return _COMPARTIDO.sub("", texto)


def lee_texto(ruta):
    with open(ruta, encoding="utf-8") as f:
        return f.read()


def bytes_de_datos_del_listado():
    """Cuantos bytes salen en filas defb/defw: los DATOS del cartucho."""
    n = 0
    for ln in lee_texto(ASM).splitlines():
        m = FILA.match(ln)
        if not m:
            continue
        toks = [t for t in m.group(2).split(",") if t.strip()]
        n += len(toks) * (1 if m.group(1) == "b" else 2)
    return n


class LasCifrasDeLaPortada(unittest.TestCase):
    def setUp(self):
        import contenido_web
        self.w = contenido_web

    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(self.w.CODIGO + self.w.DATOS, 32768)

    def test_las_cifras_de_bytes_son_las_de_este_listado(self):
        datos = bytes_de_datos_del_listado()
        self.assertEqual(self.w.DATOS, datos)
        self.assertEqual(self.w.CODIGO, 32768 - datos)

    def test_la_densidad_y_las_flojas_son_las_del_listado(self):
        """Se EJECUTA tools/densidad.py y se le lee la salida."""
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"(\d+) instrucciones, (\d+) comentarios", salida)
        self.assertIsNotNone(m, salida)
        self.assertEqual(self.w.INSTRUCCIONES, int(m.group(1)))
        self.assertEqual(self.w.COMENTARIOS, int(m.group(2)))
        m = re.search(r"(\d+) rutinas por debajo del 10 %", salida)
        self.assertEqual(int(m.group(1)), 0, "hay rutinas flojas")

    def test_las_rutinas_son_las_de_densidad(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "densidad.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        m = re.search(r"por debajo del 10 %, de (\d+)", salida)
        self.assertEqual(self.w.RUTINAS, int(m.group(1)))

    def test_ningun_call_sin_nombre(self):
        salida = subprocess.run(
            [sys.executable, os.path.join(RAIZ, "tools", "sin_bautizar.py"), ASM],
            capture_output=True, text=True, check=True).stdout
        self.assertTrue(salida.startswith("0 rutinas sin bautizar"), salida[:200])

    def test_la_ficha_dice_el_sha_y_el_rc(self):
        sha = None
        for linea in lee_texto(os.path.join(RAIZ, "Makefile")).splitlines():
            if linea.startswith("SHA"):
                sha = linea.split("=")[1].strip()
        self.assertIsNotNone(sha)
        for idioma in ("es", "en"):
            ficha = " ".join(self.w.PORTADA[idioma]["ficha"])
            self.assertIn(sha[:8], ficha)
            self.assertIn("RC-741", ficha)


class SinNombresDeOtroJuego(unittest.TestCase):
    def _revisa(self, ruta):
        texto = sin_compartido(lee_texto(ruta))
        fn = os.path.basename(ruta)
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, texto, "%s nombra a %s" % (fn, juego))

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        cabeza = "\n".join(lee_texto(ASM).splitlines()[:30])
        for juego in OTROS_JUEGOS:
            self.assertNotIn(juego, cabeza)

    def test_la_licencia_y_los_avisos_son_de_este_juego(self):
        for fn in ("LICENSE", "README.md", "README.es.md", "AVISO-LEGAL.md",
                   "LEGAL-NOTICE.md"):
            self._revisa(os.path.join(RAIZ, fn))

    OTROS_FICHEROS = ("soccer", "hypersports", "roadfighter", "pingpong",
                      "mopiranger", "tennis", "baseball", "nemesis",
                      "pippols", "antarctic", "golf", "frogger",
                      "kingsvalley", "yiearkungfu", "skyjaguar", "hyperrally",
                      "goonies", "knightmare", "twinbee", "circus", "comic",
                      "magicaltree", "kingkong", "vampirekiller", "penguin",
                      "qbert")

    def _sin_ficheros_de_otro(self, ruta):
        texto = lee_texto(ruta).lower()
        for otro in self.OTROS_FICHEROS:
            for pega in ("src/%s" % otro, "%s.asm" % otro, "%s.rom" % otro,
                         "%s.notes" % otro, "%s.trace" % otro):
                self.assertNotIn(pega, texto, "%s nombra %s"
                                 % (os.path.relpath(ruta, RAIZ), pega))

    def test_las_herramientas_no_apuntan_a_otro_juego(self):
        for fn in os.listdir(os.path.join(RAIZ, "tools")):
            if fn.endswith((".py", ".sh", ".tcl")):
                self._sin_ficheros_de_otro(os.path.join(RAIZ, "tools", fn))
        self._sin_ficheros_de_otro(os.path.join(RAIZ, "Makefile"))

    def test_ni_los_textos_publicados(self):
        for sitio in (RAIZ, DOCS, os.path.join(DOCS, "es")):
            for fn in os.listdir(sitio):
                ruta = os.path.join(sitio, fn)
                if os.path.isfile(ruta) and (
                        fn.endswith((".md", ".html")) or fn == "LICENSE"):
                    self._sin_ficheros_de_otro(ruta)

    def test_la_web_no_nombra_otro_juego(self):
        for raiz, _, ficheros in os.walk(DOCS):
            for fn in ficheros:
                if fn.endswith((".md", ".html")):
                    self._revisa(os.path.join(raiz, fn))


class LasImagenes(unittest.TestCase):
    def test_estan_todas_las_de_la_galeria(self):
        import contenido_web
        for fich, _, _ in contenido_web.GALERIA:
            self.assertTrue(os.path.exists(os.path.join(DOCS, "imagenes", fich)), fich)
        self.assertTrue(os.path.exists(os.path.join(DOCS, "imagenes",
                                                    contenido_web.LOGOTIPO)))

    def test_los_dieciseis_tone_edit(self):
        for n in range(1, 17):
            self.assertTrue(os.path.exists(
                os.path.join(DOCS, "imagenes", "tone-%02d.png" % n)), n)

    def test_el_rotulo_no_esta_recortado_a_ojo(self):
        """El recorte es el recuadro de las casillas con tile >= 0x40 de la
        tabla de nombres del titulo, mas el margen, a escala 3."""
        import struct
        import imagenes
        import pantallas
        rom = open(ROM, "rb").read()
        x, y, w, h = imagenes.recuadro_de_tiles(pantallas.titulo(rom))
        with open(os.path.join(DOCS, "imagenes", "rotulo.png"), "rb") as f:
            d = f.read()
        self.assertEqual(struct.unpack(">II", d[16:24]), (w * 3, h * 3))

    def test_las_imagenes_no_ejecutan_el_cartucho(self):
        for fn in ("pantallas.py", "imagenes.py", "flujos.py"):
            fuente = lee_texto(os.path.join(RAIZ, "tools", fn))
            self.assertNotIn("z80run", fuente)


if __name__ == "__main__":
    unittest.main()
