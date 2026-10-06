#!/usr/bin/env python3
"""SYN: la sintesis de un timbre, escrita de nuevo en Python a partir del
listado. Cada funcion es una rutina del cartucho, con su aritmetica de 8 y 16
bits y sus redondeos; la salida son los bytes que 0x5767 deja en 0x8000+.

El orden por muestra es el de 0x5796-0x57B0:

    0x5CCA  LFO           (0xDC40: 0x5CCE si algun LFO esta puesto)
    0x5825  envolvente del DCO   (estado en 0xDC25, nivel 0xDC28)
    0x58D1  envolvente del DCF   (estado en 0xDC29, nivel 0xDC2C)
    0x597D  envolvente del DCA   (estado en 0xDC2D, nivel 0xDC30)
    0x5A4B  oscilador: la muestra de la onda y el avance de la fase
    0x5B1C  filtro de dos etapas con resonancia
    0x5C7E  amplitud
    + 0x80 y a la memoria, hasta 0xC000 o hasta que acaba la envolvente

Los bytes del timbre (0xDC00-0xDC18) son los 25 primeros del timbre de
fabrica: 0 onda, 1 FEET del DCO, 2 LFO del DCO, 3 ENV del DCO, 4 CUT,
5 RES, 6 LFO del DCF, 7 ENV del DCF, 8 LFO del DCA, 9-12 ADSR del DCO,
13-16 ADSR del DCF, 17-20 ADSR del DCA, 21 retencion del LFO (S/H),
22 onda del LFO, 23 FEET del LFO, 24 conmutadores.

El ruido (onda 15 del DCO, o del LFO en S/H) sale de leer la memoria de
0x0000 en adelante, que es la BIOS de la maquina: para reproducirlo hace
falta su primera pagina (`--bios`). Sin ella se toma a ceros.

Uso: motor.py <rom> <timbre 1-16> [salida.bin] [--bios bios.rom]
"""
import sys

ORG = 0x4000


def rlc(c):
    return ((c << 1) | (c >> 7)) & 0xFF, c >> 7


def rrc(c):
    return ((c >> 1) | ((c & 1) << 7)) & 0xFF, c & 1


def sra16(de):
    """`bit 7,d / jr z / inc de` y `sra d / rr e`: la mitad, redondeando
    hacia el cero los negativos."""
    if de & 0x8000:
        de = (de + 1) & 0xFFFF
    return ((de >> 1) | (de & 0x8000)) & 0xFFFF


def sra8(e):
    if e & 0x80:
        e = (e + 1) & 0xFF
    return ((e >> 1) | (e & 0x80)) & 0xFF


def mul_5ae4(c, de):
    """0x5AE4: HL = suma de DE >> k por cada bit de C, del 7 al 0."""
    hl = 0
    for _ in range(8):
        c, cy = rlc(c)
        if cy:
            hl = (hl + de) & 0xFFFF
        de >>= 1
    return hl


def mul_5af6(hl, de):
    """0x5AF6: HL (8.8) por DE: la parte baja de HL bit a bit contra DE
    desplazado a la derecha, y la alta contra DE desplazado a la izquierda."""
    h, l = hl >> 8, hl & 0xFF
    acc = 0
    d = de
    c = l
    for _ in range(8):
        d >>= 1
        c, cy = rlc(c)
        if cy:
            acc = (acc + d) & 0xFFFF
    c = h
    d = de
    for _ in range(8):
        c, cy = rrc(c)
        if cy:
            acc = (acc + d) & 0xFFFF
        d = (d << 1) & 0xFFFF
    return acc


def mul_5a3c(c, a):
    """0x5A3C: A = suma de E >> k por cada bit de C (8 bits, sin signo)."""
    e, a = a, 0
    for _ in range(8):
        c, cy = rlc(c)
        if cy:
            a = (a + e) & 0xFF
        e >>= 1
    return a


def mul_5cb5(c, a):
    """0x5CB5: lo mismo con E con signo (sra con redondeo)."""
    e, a = a, 0
    for _ in range(8):
        c, cy = rlc(c)
        if cy:
            a = (a + e) & 0xFF
        e = sra8(e)
    return a


def mul_5c24(a, hl):
    """0x5C24: HL con signo por A/256: primero la mitad, luego suma."""
    c, de, hl = a, hl, 0
    for _ in range(8):
        de = sra16(de)
        c, cy = rlc(c)
        if cy:
            hl = (hl + de) & 0xFFFF
    return hl


def mul_5c3e(a, hl):
    """0x5C3E: como 0x5C24 pero suma antes de dividir: HL por A/128."""
    c, de, hl = a, hl, 0
    for _ in range(8):
        c, cy = rlc(c)
        if cy:
            hl = (hl + de) & 0xFFFF
        de = sra16(de)
    return hl


def mul_5c58(a, hl):
    """0x5C58: el bit 7 de A vale el doble de DE; los otros siete, como
    0x5C3E."""
    c, de, hl = a, hl, 0
    c, cy = rlc(c)
    if cy:
        hl = (hl + ((de << 1) & 0xFFFF)) & 0xFFFF
    for _ in range(7):
        c, cy = rlc(c)
        if cy:
            hl = (hl + de) & 0xFFFF
        de = sra16(de)
    return hl


class Envolvente:
    """Las tres envolventes (0x5829, 0x58D5, 0x5981) son la misma maquina:
    ataque que sube el nivel de 1 en 1 cada A muestras hasta 0xFF, caida que
    lo baja cada D muestras hasta S, sostenido y relajacion cada R muestras
    hasta 0. Un parametro a cero salta la fase. `bit` es el bit de 0xDC1B
    que cada una pone al llegar al sostenido."""

    def __init__(self, a, d, s, r, bit, activa=True):
        self.a, self.d, self.s, self.r = a, d, s, r
        self.bit = bit
        self.activa = activa
        self.cuenta = 1
        self.nivel = 0
        self.estado = "ataque"


class Motor:
    def __init__(self, rom, timbre, ondas_usuario=None, bios=None,
                 onda_usuario=0):
        self.rom = rom
        self.t = list(timbre[:25])
        self.bios = bios or bytes(256)
        self.usuario = ondas_usuario or [bytes(rom[0x7200 - ORG:0x7300 - ORG])] * 16
        self.n_usuario = onda_usuario
        t = self.t
        self.flags = 0                                    # 0xDC1B
        self.ptr = 0x8000                                 # 0xDC19
        self.bucle = 0                                    # 0xDCFD
        self.dco = Envolvente(t[9], t[10], t[11], t[12], 0, t[3] != 0)
        self.dcf = Envolvente(t[13], t[14], t[15], t[16], 1, t[7] != 0)
        self.dca = Envolvente(t[17], t[18], t[19], t[20], 2)
        self.fase = 0                                     # 0xDC31-0xDC32
        self.onda = self.pagina(t[0])                     # 0xDC33
        self.ruido_ptr = 0                                # 0xDC35
        self.ruido = 0                                    # 0xDC34
        self.fb = rom[0x5C12 - ORG + t[5]]                # 0xDC38
        self.ganancia = rom[0x5C1B - ORG + t[5]]          # 0xDC39
        self.lp = 0                                       # 0xDC3A
        self.bp = 0                                       # 0xDC3C
        self.hp = 0                                       # 0xDC3E
        self.lfo_fase = 0                                 # 0xDC42-0xDC43
        self.lfo_onda = self.pagina(t[22])                # 0xDC44
        self.lfo = 0                                      # 0xDC45
        self.lfo_cuenta = 0                               # 0xDC46
        self.lfo_activo = (t[2] | t[6] | t[8]) != 0      # 0xDC40
        self.corte = 0                                    # 0xDC37

    def pagina(self, n):
        """0x56FF: la onda n de la ROM esta en la pagina 0x72 + n; la 14
        (0x0E) es la onda del usuario de 0xC000 + 0x100 * (0xDB00)."""
        if n == 0x0E:
            return self.usuario[self.n_usuario]
        if n >= 0x0F:
            return None
        a = 0x7200 - ORG + 0x100 * n
        return bytes(self.rom[a:a + 0x100])

    def lee_ruido(self):
        """0x5AD4 / 0x5D21: el ruido sale de leer de 0x0000 en adelante (la
        BIOS) con el puntero de 0xDC35, girado y acumulado en 0xDC34."""
        self.ruido_ptr = (self.ruido_ptr & 0xFF00) | ((self.ruido_ptr + 1) & 0xFF)
        a, _ = rlc(self.bios[self.ruido_ptr & 0xFF])
        self.ruido = (a + self.ruido) & 0xFF
        return self.ruido

    # ------------------------------------------------------------------ LFO
    def paso_lfo(self):
        if not self.lfo_activo:
            return
        t = self.t
        if t[22] >= 0x0F:                                 # 0x5D18: S/H
            a = (self.lfo_cuenta - 1) & 0xFF
            if a == 0xFF:
                self.lfo = self.lee_ruido()
                a = t[21]
            self.lfo_cuenta = a
            return
        a = (self.lfo_cuenta - 1) & 0xFF
        if a == 0xFF:
            self.lfo = self.lfo_onda[self.lfo_fase >> 8]
            a = t[21]
        self.lfo_cuenta = a
        self.lfo_fase = (self.lfo_fase + ((t[23] << 4) & 0xFFFF)) & 0xFFFF

    # ---------------------------------------------------------- envolventes
    def paso_envolvente(self, e, es_dca=False):
        if e.estado == "fin":
            return
        if e.estado == "ataque":
            if not e.activa:                              # 0x5830 / 0x58DC
                self.flags |= 1 << e.bit
                e.estado = "fin"
                return
            if e.a == 0:
                e.nivel = 0xFF
                e.estado = "caida"
                return
            e.cuenta = (e.cuenta - 1) & 0xFF
            if e.cuenta:
                return
            e.cuenta = e.a
            e.nivel = (e.nivel + 1) & 0xFF
            if e.nivel == 0xFF:
                e.estado = "caida"
            return
        if e.estado == "caida":
            if e.d == 0 or e.s == 0xFF:
                e.nivel = e.s
                self.llega_al_sostenido(e, es_dca)
                return
            e.estado = "caida2"
        if e.estado == "caida2":
            e.cuenta = (e.cuenta - 1) & 0xFF
            if e.cuenta:
                return
            e.cuenta = e.d
            e.nivel = (e.nivel - 1) & 0xFF
            if e.nivel != e.s:
                return
            self.llega_al_sostenido(e, es_dca)
            return
        if e.estado == "sostenido":
            if es_dca:
                return self.sostenido_dca(e)
            if self.flags != 7:                           # 0x58A3
                return
            if e.r == 0:
                e.nivel = 0
                e.estado = "fin"
                return
            e.estado = "relajacion"
        if e.estado == "espera_pagina":
            if self.ptr & 0xFF:                           # 0x59FE
                return
            self.flags |= 4
            if e.s == 0:
                self.flags |= 0x80
                e.estado = "fin"
                return
            if e.r == 0:
                e.nivel = 0
                self.flags |= 0x80
                e.estado = "fin"
                return
            e.estado = "relajacion"
        if e.estado == "relajacion":
            e.cuenta = (e.cuenta - 1) & 0xFF
            if e.cuenta:
                return
            e.cuenta = e.r
            e.nivel = (e.nivel - 1) & 0xFF
            if e.nivel:
                return
            if es_dca:
                self.flags |= 0x80
            e.estado = "fin"

    def llega_al_sostenido(self, e, es_dca):
        if es_dca:                                        # 0x59D3 -> 0x59D9
            e.estado = "sostenido"
            self.sostenido_dca(e)
            return
        self.flags |= 1 << e.bit                          # 0x588D
        e.estado = "sostenido" if e.s else "fin"

    def sostenido_dca(self, e):
        """0x59D9: espera a que el DCO y el DCF esten en su sostenido y a
        que el puntero caiga en principio de pagina; apunta esa pagina en
        0xDCFD (el bucle que repite PLAY mientras se tiene la tecla) salvo
        con EG TYP (bit 7 del byte 24) o en la ultima pagina."""
        if self.flags != 3 or (self.ptr & 0xFF):
            return
        if not (self.t[24] & 0x80) and (self.ptr >> 8) != 0xBF:
            self.bucle = self.ptr >> 8
        e.estado = "espera_pagina"

    # ----------------------------------------------------------- oscilador
    def oscilador(self):
        t = self.t
        if t[0] >= 0x0F:
            return self.lee_ruido()
        muestra = self.onda[self.fase >> 8]
        if t[2] == 0:
            hl = t[1] << 8
        else:
            lfo = self.lfo
            e = (-lfo) & 0xFF if lfo & 0x80 else lfo
            hl = mul_5ae4(t[2], e)
            if lfo & 0x80:
                hl = (0x100 - (((hl + 1) & 0xFFFF) >> 1)) & 0xFFFF
            else:
                hl = (hl + 0x100) & 0xFFFF
            hl = mul_5af6(hl, t[1] << 8)
        if t[3]:
            de = hl
            hl = mul_5ae4(t[3], self.dco.nivel)
            if t[24] & 0x08:
                hl = (0x100 - (((hl + 1) & 0xFFFF) >> 1)) & 0xFFFF
            else:
                hl = (hl + 0x100) & 0xFFFF
            hl = mul_5af6(hl, de)
        self.fase = (self.fase + hl) & 0xFFFF
        return muestra

    # -------------------------------------------------------------- filtro
    def filtro(self, l):
        t = self.t
        if t[7] == 0:
            a = t[4]
        else:
            b = mul_5a3c(t[7], self.dcf.nivel)
            a = t[4]
            if t[24] & 0x04:
                a = a - b if a >= b else 0
            else:
                a = a + b if a + b <= 0xFF else 0xFF
        h = a
        if t[6] == 0:
            a = h
        else:
            a = mul_5cb5(t[6], self.lfo)
            if not (a & 0x80):
                a = h + a if h + a <= 0xFF else 0xFF
            else:
                b = (-a) & 0xFF
                a = h - b if h >= b else 0
        self.corte = a
        x = l | (0xFF00 if l & 0x80 else 0)
        if self.fb:
            x = (x + mul_5c58(self.fb, mul_5c3e(self.corte, self.bp))) & 0xFFFF
        # 0x5BA2 y 0x5BD4: `inc a` antes de multiplicar: el factor es
        # corte + 1, y con 0xFF (0x100) no se multiplica.
        hl = (x - self.lp) & 0xFFFF
        if self.corte != 0xFF:
            hl = mul_5c24(self.corte + 1, hl)
        self.lp = (self.lp + hl) & 0xFFFF
        hl = (x - self.lp) & 0xFFFF
        self.hp = hl
        if (t[24] & 0x01) or self.fb:
            hl = (hl - self.bp) & 0xFFFF
            if self.corte != 0xFF:
                hl = mul_5c24(self.corte + 1, hl)
            self.bp = (self.bp + hl) & 0xFFFF
            hl = self.bp
        if t[24] & 0x01:
            pass
        elif t[24] & 0x02:
            hl = self.lp
        else:
            hl = sra16(self.hp)
        if self.ganancia:
            hl = mul_5c24(self.ganancia, hl)
        return hl & 0xFF

    # ------------------------------------------------------------ amplitud
    def amplitud(self, a):
        t = self.t
        if t[8]:
            c = mul_5cb5(t[8], self.lfo)
            c = (0x80 - t[8] + c) & 0xFF
            a = mul_5cb5(c, a)
        e, c, a2 = a, self.dca.nivel, 0
        for _ in range(7):
            e = sra8(e)
            c, cy = rlc(c)
            if cy:
                a2 = (a2 + e) & 0xFF
        return a2

    def sintetiza(self):
        sale = bytearray()
        while True:
            self.paso_lfo()
            self.paso_envolvente(self.dco)
            self.paso_envolvente(self.dcf)
            self.paso_envolvente(self.dca, es_dca=True)
            m = self.oscilador()
            m = self.filtro(m)
            m = self.amplitud(m)
            sale.append((m + 0x80) & 0xFF)
            self.ptr += 1
            if self.ptr == 0xC000 or (self.flags & 0x80):
                break
        return bytes(sale)


def main():
    args = sys.argv[1:]
    bios = None
    if "--bios" in args:
        i = args.index("--bios")
        bios = open(args[i + 1], "rb").read()[:256]
        del args[i:i + 2]
    rom = open(args[0], "rb").read()
    n = int(args[1]) - 1
    a = 0xA3AA - ORG + 32 * n
    m = Motor(rom, rom[a:a + 32], bios=bios)
    s = m.sintetiza()
    print("timbre %d: %d bytes, bucle en la pagina 0x%02X" % (n + 1, len(s), m.bucle))
    if len(args) > 2:
        open(args[2], "wb").write(s)


if __name__ == "__main__":
    main()
