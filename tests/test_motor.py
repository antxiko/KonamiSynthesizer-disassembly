"""SYN escrito de nuevo en Python (tools/motor.py) contra lo que calcula el
cartucho.

Las huellas son de las muestras que el Z80 guarda en 0x57B0 para cada timbre
de fabrica, medidas en openMSX con tools/omsx_sintesis.tcl (Philips VG-8020).
El timbre 14 lleva el LFO en S/H, que lee ruido de la BIOS: su huella es con
la BIOS de la VG-8020, y sin ella ese caso se salta.
"""

import hashlib
import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

import motor  # noqa: E402

ROM = os.path.join(RAIZ, "synth.rom")
BIOS = os.path.join(os.environ.get("APPDATA", ""), "openMSX", "share", "systemroms",
                    "machines", "philips", "vg8020_basic-bios1.rom")

# timbre: (bytes, pagina del bucle, sha256 de las muestras, 16 cifras)
MEDIDO = {
    1: (4329, 0x84, "7afeca8715d60b63"),
    2: (4329, 0x84, "b54f091a0a90542d"),
    3: (5603, 0x86, "82d4e9de327214ff"),
    4: (5603, 0x86, "895da9545628622d"),
    5: (2598, 0x84, "8389d5b38e599165"),
    6: (767, 0x81, "6f7f68cd6e6c4d6e"),
    7: (767, 0x81, "1fb104fe6803f985"),
    8: (5593, 0x00, "bad96396cdfad48e"),
    9: (6361, 0x00, "7d7746f1b7a2f469"),
    10: (8420, 0x00, "dd21eb0a611c1450"),
    11: (2417, 0x00, "7d0cfd8f0ae9b336"),
    12: (4333, 0x00, "46c953449040bc51"),
    13: (16384, 0x00, "88313984a38e2cc2"),
    14: (7652, 0x00, "997724e1f92e232a"),
    15: (8164, 0x00, "2c9a99519e19a175"),
    16: (513, 0x81, "b014fdb2f395cc1c"),
}


class Sintesis(unittest.TestCase):
    def setUp(self):
        if not os.path.exists(ROM):
            self.skipTest("sin el cartucho")
        with open(ROM, "rb") as f:
            self.rom = f.read()

    def test_los_dieciseis_timbres_byte_a_byte(self):
        for n, (largo, bucle, huella) in MEDIDO.items():
            bios = None
            if n == 14:
                if not os.path.exists(BIOS):
                    continue
                with open(BIOS, "rb") as f:
                    bios = f.read()[:256]
            a = 0xA3AA - 0x4000 + 32 * (n - 1)
            m = motor.Motor(self.rom, self.rom[a:a + 32], bios=bios)
            s = m.sintetiza()
            self.assertEqual(len(s), largo, "timbre %d" % n)
            self.assertEqual(m.bucle, bucle, "timbre %d" % n)
            self.assertEqual(hashlib.sha256(s).hexdigest()[:16], huella, "timbre %d" % n)


if __name__ == "__main__":
    unittest.main()
