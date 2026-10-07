#!/usr/bin/env python3
"""Las pantallas del cartucho montadas desde la ROM, con codigo nuestro.

Cada funcion repite, en el mismo orden, lo que hace la rutina del cartucho
que pinta esa pantalla: los flujos de graficos se leen con tools/flujos.py y
los rellenos y copias son los de 0x4316 (FILVRM en los tres tercios), 0x4303
(LDIRVM en los tres tercios) y 0x42FF (LDIRVM). Nada sale del emulador: el
volcado de openMSX solo sirve para cotejar (`coteja`).

El reparto de la VRAM lo ponen los registros de 0x4295 (R3 = 0x7F,
R4 = 0x07): COLORES en 0x0000, PATRONES en 0x2000, nombres en 0x3800,
atributos de sprite en 0x3B00 y patrones de sprite en 0x1800.

Uso: pantallas.py <rom> coteja <pantalla> <volcado.vram>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import flujos  # noqa: E402
import vram as render  # noqa: E402

ORG = 0x4000
REGS = [0x02, 0xE2, 0x0E, 0x7F, 0x07, 0x76, 0x03, 0xE4]   # 0x4295


class VRAM:
    def __init__(self):
        self.m = bytearray(0x4000)
        self.escrito = set()
        self.regs = list(REGS)

    def pon(self, a, v):
        a &= 0x3FFF
        self.m[a] = v
        self.escrito.add(a)

    def aplica(self, escrituras):
        for a, v in escrituras:
            self.pon(a, v)

    def rellena(self, a, n, v):            # FILVRM
        for i in range(n):
            self.pon(a + i, v)

    def rellena3(self, a, n, v):           # 0x4316
        for k in range(3):
            self.rellena(a + 0x800 * k, n, v)

    def copia(self, rom, origen, a, n):    # 0x42FF: LDIRVM desde la ROM
        for i in range(n):
            self.pon(a + i, rom[origen - ORG + i])

    def copia3(self, rom, origen, a, n):   # 0x4303
        for k in range(3):
            self.copia(rom, origen, a + 0x800 * k, n)

    def imagen(self, sprites=True):
        return render.pantalla(self.m, self.regs, sprites)


def comun(v, rom):
    """0x42DC y 0x43FD: lo que se repite al empezar cada pantalla.

    0x42DC: los sprites fuera (0xD0 en 0x3B00) y la tabla de nombres a cero.
    0x43FD -> 0x4536: los patrones de los tiles 0-15 a cero y el color de
    cada uno igual a su numero, o sea dieciseis cuadros lisos de los dieciseis
    colores; luego la fuente (0x4414) desde el tile 0x10 y su color, 0xF0.
    """
    v.pon(0x3B00, 0xD0)
    v.rellena(0x3800, 0x300, 0)
    v.rellena3(0x2000, 0x80, 0)
    for n in range(16):
        v.rellena3(n * 8, 8, n)
    v.aplica(flujos.rle3(rom, 0x4414, 0x2080)[1])
    v.rellena3(0x0080, 0x158, 0xF0)


def logo_konami(rom, v=None):
    """0x41C5: registros, 0x42DC, 0x43FD y 0x4557, que pinta el logotipo.

    0x45B9 trae los 120 tiles en 0x2A00; 0x4563 pone su color a cero y
    0x456D escribe en la tabla de nombres 20 x 6 tiles seguidos desde el 0x40.
    La cortina de 0x4585 pinta el color 0xF0 fila a fila, 960 bytes: al
    acabar, todo el bloque 0x0A00-0x0DBF es 0xF0.
    """
    v = v or VRAM()
    comun(v, rom)
    v.aplica(flujos.rle(rom, 0x45B9)[1])
    v.rellena(0x0A00, 0x3C0, 0)
    t = 0x40
    for f in range(6):
        for c in range(20):
            v.pon(0x3907 + f * 32 + c, t)
            t += 1
    for f in range(6):
        for linea in range(8):
            for c in range(20):
                v.pon(0x0A00 + (f * 20 + c) * 8 + linea, 0xF0)
    return v


def titulo(rom, v=None, rotulo=True):
    """0x416A -> 0x4714 y lo que sigue: el logotipo 新世SIZER.

    0x4714 cambia R7 a 0xE0, repite 0x42DC y 0x43FD y rellena los colores
    de la zona del logotipo (0x0248, 0x0620 y 0x05B0); 0x473E trae los
    colores del logotipo (0xA2BF) y 0x416D pone sus patrones a 0xFF. La
    pincelada (0x418A) copia los 0x428 bytes de 0x9E97 de ocho en ocho
    pasadas; al acabar estan todos. 0x4754 pinta la tabla de nombres
    (0xA2E5) y 0x41BB el rotulo de 0xBE75. La segunda linea (0xBE84)
    parpadea: 0x420D la escribe y 0x4212 la borra.
    """
    v = v or logo_konami(rom)
    v.regs[7] = 0xE0
    comun(v, rom)
    v.rellena3(0x0248, 0x368, 0x70)
    v.rellena3(0x0620, 0x08, 0x70)
    v.rellena3(0x05B0, 0x70, 0xE0)
    v.aplica(flujos.rle3(rom, 0xA2BF, 0x0200)[1])
    v.rellena3(0x2200, 0x428, 0xFF)
    v.copia3(rom, 0x9E97, 0x2200, 0x428)
    v.aplica(flujos.rle(rom, 0xA2E5)[1])
    v.aplica(flujos.lista(rom, 0xBE75)[1])
    if not rotulo:
        v.aplica(flujos.lista(rom, 0xBE84, borra=True)[1])
    return v


def marco_y_cabecera(rom, v, pantalla):
    marco(rom, v, pantalla)


def marco(rom, v, pantalla):
    """0xB335: lo comun de las pantallas de trabajo, con la pantalla apagada
    (0xB32E pone R1 = 0xA2).

    La franja de arriba (0x87DB), la fuente desde la A (0xB392: 0x446E y su
    color 0xF0), el menu de abajo (0x48C4: 0x8A41, o 0x8A81 si (0xD8F0) no
    es cero), los diez digitos (0x9E37) con su color (0x9E87 en TONE EDIT,
    0x9E8F en las demas) y el marco (0x82A5, 0x84EB, 0x8531, 0x8552).
    """
    v.aplica(flujos.rle(rom, 0x87DB)[1])
    v.aplica(flujos.rle3(rom, 0x446E, 0x2100)[1])
    v.rellena3(0x0100, 0xB8, 0xF0)
    v.copia(rom, 0x8A41, 0x3AC0, 0x40)
    v.copia3(rom, 0x9E37, 0x2080, 0x50)
    for i in range(10):
        v.copia3(rom, 0x9E87 if pantalla == 0 else 0x9E8F, 0x0080 + 8 * i, 8)
    v.aplica(flujos.rle3(rom, 0x82A5, 0x2200)[1])
    v.aplica(flujos.rle3(rom, 0x84EB, 0x0008)[1])
    v.aplica(flujos.rle3(rom, 0x8531, 0x00D8)[1])
    v.aplica(flujos.rle3(rom, 0x8552, 0x01D8)[1])


def salida_del_titulo(rom, v):
    """0x4BA1 -> 0x437D al pulsar ESPACIO: los patrones de los sprites
    (0x8000) y la cortina de 0x43B0, que borra la tabla de nombres columna a
    columna; 0x43C9 saca los sprites (0xD0 en 0x3B00)."""
    v.aplica(flujos.rle(rom, 0x8000)[1])
    v.rellena(0x3800, 0x300, 0)
    v.pon(0x3B00, 0xD0)


def tone_edit_fijo(rom, v=None):
    """0xAD5A: TONE EDIT sin los valores del timbre."""
    v = v or titulo(rom)
    salida_del_titulo(rom, v)
    marco(rom, v, 0)
    v.aplica(flujos.rle3(rom, 0x8AC1, 0x2458)[1])
    v.aplica(flujos.rle3(rom, 0x8DB6, 0x0458)[1])
    v.aplica(flujos.rle(rom, 0x8FCD)[1])
    v.rellena(0x0900, 0xB8, 0x30)
    v.aplica(flujos.rle(rom, 0x9087)[1])
    v.regs[7] = 0xE0
    return v


def w(rom, a):
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def timbre_de_fabrica(rom, n):
    """Los 32 bytes del timbre n (0-15) de 0xA3AA, que 0x55BC copia a
    0xD000 al arrancar."""
    a = 0xA3AA - ORG + 32 * n
    return bytes(rom[a:a + 32])


def digitos(v, a, valor, n=3, base=0x10):
    """0x43DC (base 0x10) y 0x43E0 (base 0x40): n cifras decimales escritas
    de derecha a izquierda desde `a`, el tile de cada una es base + cifra."""
    for _ in range(n):
        v.pon(a, base + valor % 10)
        valor //= 10
        a -= 1


def campos_1_a_20(rom, v, t):
    """0xA7D7: los veinte campos de valor, bytes 2 a 21 del timbre.

    Tres cifras en la direccion de 0xA9C7 y una barra de cuatro tiles en la
    de 0xA9EF; la barra es la entrada (valor >> 0xA99F[i]) de 0xAA17, como
    poco la 1 si el valor no es cero (0xA8FC); si 0xA99F[i] es 0, valor * 2 y
    como poco la 1 aunque el valor sea cero.
    Los campos de la lista 0xA947 (1, 10, 11 y 20) con valor 0 dicen OFF
    (los tres tiles de 0xA92A delante de las cifras) solo con (0xDB04) = 1,
    que 0xAAA5 pone cuando el bit 7 del byte 24 (EG TYP) esta a cero; con
    el bit a uno pintan 000 (0xA7E9). Cotejado con los dieciseis timbres.
    """
    apagables = []
    a = 0xA947
    while rom[a - ORG] != 0xFF:
        apagables.append(rom[a - ORG])
        a += 1
    dice_off = not (t[24] & 0x80)
    for f in range(1, 21):
        valor = t[1 + f]
        cifras = w(rom, 0xA9C7 + 2 * (f - 1))
        barra = w(rom, 0xA9EF + 2 * (f - 1))
        if f in apagables and valor == 0 and dice_off:
            v.copia(rom, 0xA92A, cifras - 2, 3)
        else:
            digitos(v, cifras, valor)
        corre = rom[0xA99F - ORG + f - 1]
        if corre == 0:
            i = max(1, valor * 2)            # 0xA8F0: aqui ni el 0 baja de 1
        else:
            i = max(1, valor >> corre) if valor else 0
        v.copia(rom, 0xAA17 + 4 * i, barra, 4)


def digitos_bcd(v, a, bcd, n):
    """0x43DC con DE apuntando a BCD: n cifras desde `a` hacia la izquierda,
    dos por byte, la baja primero. Devuelve donde se queda HL."""
    for k in range(n):
        byte = bcd[k // 2]
        v.pon(a, 0x10 + ((byte >> 4) if k % 2 else (byte & 0x0F)))
        a -= 1
    return a - (1 if n % 2 == 0 else 0)


def pies(dividendo, valor):
    """0xA6FB: cociente de 24 bits (0xADC0), a BCD (0xAD9C), redondeado a la
    decena (0xA711) y con la ultima cifra fuera (0xA72B). Devuelve los
    cuatro bytes BCD de 0xDBF0, el bajo primero."""
    q = dividendo // valor if valor else 0
    q = (q + 5) // 10
    return [int("%02d" % ((q // 100 ** k) % 100), 16) for k in range(4)]


def campos_21_a_28(rom, v, t):
    """Los conmutadores (bits del byte 24), las dos ondas y los dos FEET."""
    # 21-24, 0xAA5B: mascara en 0xAB31, (desplazamiento, direccion) en
    # 0xAB35; tres tiles en vertical sacados de 0xAB41 (un bit) o de 0xAB47
    # (los bits 0-1: HPF, BPF, LPF).
    for k in range(4):
        corre = rom[0xAB35 - ORG + 3 * k]
        a = w(rom, 0xAB35 + 3 * k + 1)
        if corre == 0:
            tabla, i = 0xAB47, t[24] & 3
        else:
            tabla, i = 0xAB41, (t[24] >> corre) & 1
        for f in range(3):
            v.pon(a + 0x20 * f, rom[tabla - ORG + 3 * i + f])
    # 25 y 26, 0xAB58: la onda del DCO (byte 0) en 0x3905 y la del LFO
    # (byte 22) en 0x3977, mas uno; detras, su dibujo de tres tiles (0xABD8).
    for byte, a in ((0, 0x3905), (22, 0x3977)):
        n = t[byte] + 1
        digitos(v, a, n, 2)
        v.copia(rom, 0xABD8 + 3 * t[byte], a + 2, 3)
    # 27, 0xA6C3: FEET del DCO, 64000 / byte 1, dos cifras en 0x38C5.
    digitos_bcd(v, 0x38C5, pies(0x00FA00, t[1])[1:], 2)
    # 28, 0xA660: FEET del LFO, 1024000 / byte 23: dos cifras en 0x393C y
    # cuatro en 0x3939; el punto de en medio es del marco.
    b = pies(0x0FA000, t[23])
    a = digitos_bcd(v, 0x393C, b, 2)
    digitos_bcd(v, a, b[1:], 4)


def cabecera(rom, v, n):
    """0xACEA: el numero del timbre (0x40 + cifra, dos cifras en 0x384B) y
    las siete letras del nombre (bytes 25-31) en 0x384E, con el espacio
    (0x20) como tile 0. Sale en TONE EDIT y en WAVE EDIT."""
    t = timbre_de_fabrica(rom, n)
    digitos(v, 0x384C, n + 1, 2, 0x40)
    for i in range(7):
        c = t[25 + i]
        v.pon(0x384E + i, 0 if c == 0x20 else c)


def tone_edit(rom, n=0, v=None):
    """TONE EDIT con el timbre n."""
    v = tone_edit_fijo(rom, v)
    t = timbre_de_fabrica(rom, n)
    cabecera(rom, v, n)
    campos_1_a_20(rom, v, t)
    campos_21_a_28(rom, v, t)
    # Los sprites: 0xACDD copia los cinco de 0xAC12 a 0xD870 (el resto de la
    # copia, a cero por 0x43C9) y 0x402E la vuelca entera a 0x3B00 cada
    # cuadro. Los sprites 0 y 1 son la flecha roja del cursor, que empieza
    # en el campo del timbre; los 2, 3 y 4 vienen con color 0 (0xA629 los
    # vuelve a apagar al pintar cada campo).
    spr = bytearray(0x80)
    spr[:0x14] = rom[0xAC12 - ORG:0xAC12 - ORG + 0x14]
    for i, b in enumerate(spr):
        v.pon(0x3B00 + i, b)
    return v


def ondas_del_usuario(rom):
    """0x55CF: las 16 ondas del usuario (0xC000-0xCFFF) arrancan todas como
    copia de la onda 0 de la ROM, el seno de 0x7200."""
    return [bytes(rom[0x7200 - ORG:0x7300 - ORG])] * 16


def altura(s):
    """0xB207: la muestra (con signo) a fila del grafico, de 0x20 a 0xA0."""
    if s < 0x80:
        return 0x60 - (s >> 1)
    return 0x60 + (((-s) & 0xFF) >> 1)


def traza_onda(v, onda):
    """0xB0AB, una columna por cuadro: x = indice / 2 (0-127), con el
    indice de dos en dos. Toma la altura de la muestra siguiente, la actual y
    la anterior (la anterior es la actual en la columna 0; el indice da la
    vuelta dentro de la pagina), las ordena como 0xB0EA y enciende, en el
    bit de 0xB1D9 de esa columna, max(1, alto - bajo) puntos desde el bajo.
    El grafico son 16 x 16 tiles: el tile de arriba de cada columna sale de
    la tabla de nombres (fila 4) y los de debajo, 16 tiles mas alla."""
    for idx in range(0, 256, 2):
        x = idx // 2
        e = altura(onda[(idx + 2) & 0xFF])
        d = altura(onda[idx])
        c = d if idx == 0 else altura(onda[(idx - 2) & 0xFF])
        if c < d:
            if c < e:
                bajo, alto = c, max(d, e)
            else:
                bajo, alto = e, d
        else:
            if d < e:
                bajo, alto = d, (e if c < e else c)
            else:
                bajo, alto = e, c
        col = (0x40 + x) >> 3
        bit = 0x80 >> (x & 7)
        tiles = []
        for fila in range(16):
            n = v.m[0x3880 + col + 0x20 * fila]
            tercio = (4 + fila) // 8
            tiles.append(0x2000 + 0x800 * tercio + n * 8)
        filas = []
        for t in tiles:
            filas += [t + i for i in range(8)]
        for a in filas:
            v.pon(a, v.m[a] & ~bit & 0xFF)
        cuenta = max(1, alto - bajo)
        for k in range(cuenta):
            a = filas[bajo - 0x20 + k]
            v.pon(a, v.m[a] | bit)


def wave_edit(rom, n=0, v=None):
    """0xB00C: WAVE EDIT con la onda n del usuario."""
    v = v or tone_edit(rom)
    v.pon(0x3B00, 0xD0)
    marco(rom, v, 1)
    v.aplica(flujos.rle(rom, 0x874D)[1])
    v.aplica(flujos.rle(rom, 0x8799)[1])
    v.aplica(flujos.rle(rom, 0x87A0)[1])
    v.rellena3(0x2600, 0x200, 0)
    v.rellena(0x2C00, 0x200, 0)
    v.aplica(flujos.rle(rom, 0x8815)[1])
    v.rellena3(0x0600, 0x200, 0x81)
    v.rellena(0x0C00, 0x200, 0x81)
    for i in range(16):
        v.pon(0x0E00 + 8 * i, 0x8C)       # la linea del cero, en verde
    a = 0x3888
    p = 0xB1E4
    while rom[p - ORG] != 0xFF:
        t = rom[p - ORG]
        while True:
            for i in range(16):
                v.pon(a + i, t)
                t = (t + 1) & 0xFF
            a += 0x20
            if t == 0:
                break
        p += 1
    onda = ondas_del_usuario(rom)[n]
    traza_onda(v, onda)
    # 0xAFA0 y 0xAF60: el cursor en la muestra 0. TIME = indice / 4 en
    # 0x38C4; RANGE = la muestra con su signo (0x4D +, 0x4C -) en 0x3962 y
    # tres cifras en 0x3965; MODE = 2 << 3 = 16 (0xAEB4 con (0xDA86) = 3)
    # en 0x38DC.
    cabecera(rom, v, n)
    digitos(v, 0x38C4, 0)
    s0 = onda[0]
    v.pon(0x3962, 0x4C if s0 & 0x80 else 0x4D)
    digitos(v, 0x3965, (-s0) & 0xFF if s0 & 0x80 else s0)
    digitos(v, 0x38DC, 2 << 3)
    # Los sprites: los tres de 0xB1CD (0xB016), el resto a cero (0xB3A6);
    # el 2 es el cursor, a la altura de la muestra menos 4 (0xB21B).
    spr = bytearray(0x80)
    spr[:12] = rom[0xB1CD - ORG:0xB1CD - ORG + 12]
    spr[1] = spr[5] = 0x38
    spr[8], spr[9] = altura(s0) - 4, 0x3C
    for i, b in enumerate(spr):
        v.pon(0x3B00 + i, b)
    return v


def disposicion_inicial(rom):
    """0x4B21: la disposicion de fabrica, tecla -> nota, 0x30 bytes de 0x4B71
    que van a 0xD200 (lo que FILE guarda como LAYOUT)."""
    return bytes(rom[0x4B71 - ORG:0x4BA1 - ORG])


def teclas(rom, v, disp):
    """0x4997: cada tecla del teclado dibujado, de la 1 a la 0x30 sin la
    0x16. 0xBC3D da su direccion (0xBDE1) y su nota (0xD200); con nota 0 se
    pintan los tiles en blanco de 0xBDD9 arriba (0xBBF4). Si no, la
    posicion de la nota en la lista 0xBCCA (0x49A3) elige la tabla de su
    octava (0xBD5F, por los topes de 0xBDDD) y, dentro, la pareja de tiles
    (posicion mod 14); debajo va la pareja de 0xBDD7."""
    for k in range(1, 0x31):
        if k == 0x16:
            continue
        nota = disp[k - 1]
        pos = 0
        while rom[0xBCCA - ORG + pos] != nota:
            pos += 1
        a = w(rom, 0xBDE1 + 2 * (k - 1))
        if nota == 0:
            # 0xBBF4 pone DE = 0xBDD9 para la mitad de arriba, pero la de
            # abajo (0xBBFE, `jp L_BC37`) usa el DE que deja LDIRVM, y la
            # BIOS lo devuelve dos bytes mas alla: 0xBDDB.
            v.copia(rom, 0xBDD9, a, 2)
            v.copia(rom, 0xBDDB, a + 0x20, 2)
            continue
        b = 0
        while pos >= rom[0xBDDD - ORG + b]:
            b += 1
        tabla = w(rom, 0xBD5F + 2 * b) + 2 * (pos % 14)
        v.copia(rom, tabla, a, 2)
        v.copia(rom, 0xBDD7, a + 0x20, 2)


def teclado(rom, v, internacional=True):
    """0x494E: el teclado de SYN y PLAY. El marco sin la franja de arriba
    (0xB33E), el piano y el teclado del MSX (0x925A, 0x92F4, 0x9559,
    0x95EA), y si (0x002C) & 0x0F no es cero -un MSX que no es japones-
    los rotulos de las teclas de 0x97FD y 0x98DF; la tabla de nombres
    (0x9988) y las teclas con su nota."""
    v.copia(rom, 0x8A41, 0x3AC0, 0x40)
    v.copia3(rom, 0x9E37, 0x2080, 0x50)
    for i in range(10):
        v.copia3(rom, 0x9E8F, 0x0080 + 8 * i, 8)
    v.aplica(flujos.rle3(rom, 0x82A5, 0x2200)[1])
    v.aplica(flujos.rle3(rom, 0x84EB, 0x0008)[1])
    v.aplica(flujos.rle3(rom, 0x8531, 0x00D8)[1])
    v.aplica(flujos.rle3(rom, 0x8552, 0x01D8)[1])
    v.aplica(flujos.rle3(rom, 0x925A, 0x2080)[1])
    v.aplica(flujos.rle3(rom, 0x92F4, 0x2458)[1])
    v.aplica(flujos.rle3(rom, 0x9559, 0x0080)[1])
    v.aplica(flujos.rle3(rom, 0x95EA, 0x0458)[1])
    if internacional:
        v.aplica(flujos.rle3(rom, 0x97FD, 0x2600)[1])
        v.aplica(flujos.rle3(rom, 0x98DF, 0x0600)[1])
    v.aplica(flujos.rle(rom, 0x9988)[1])
    teclas(rom, v, disposicion_inicial(rom))


def sprites(rom, v, origen, n):
    spr = bytearray(0x80)
    spr[:n] = rom[origen - ORG:origen - ORG + n]
    for i, b in enumerate(spr):
        v.pon(0x3B00 + i, b)


def syn(rom, v=None, internacional=True):
    """0x48D9: SYN, al empezar la sintesis. El teclado, el pentagrama de
    abajo (0x48F4 en 0x3AC0) y los cuatro sprites de 0x4CD4: el pajaro
    verde que recorre el pentagrama mientras se calcula el sonido, y lo que
    le espera al final. Por defecto llega desde TONE EDIT (F3)."""
    v = v or tone_edit(rom)
    v.pon(0x3B00, 0xD0)
    teclado(rom, v, internacional)
    v.aplica(flujos.rle(rom, 0x48F4)[1])
    sprites(rom, v, 0x4CD4, 0x10)
    return v


def play(rom, v=None, internacional=True):
    """0x491B: PLAY. El teclado, la fuente otra vez (0xB392) y los dos
    sprites de 0x4946."""
    v = v or syn(rom, wave_edit(rom))
    v.pon(0x3B00, 0xD0)
    teclado(rom, v, internacional)
    v.aplica(flujos.rle3(rom, 0x446E, 0x2100)[1])
    v.rellena3(0x0100, 0xB8, 0xF0)
    sprites(rom, v, 0x4946, 8)
    return v


def opcion_de_file(rom, v, estado, a):
    """0xB6A0: marca la opcion a del menu de FILE. Pone sus bits en 0xDB0E
    (mascara y valor en 0xB733), y si es del primer grupo (0 o 1) repinta
    el rotulo de 0x3978-0x399F (0xB747, o 0xB74D y 0xB753). Luego borra con
    el tile 0x97 los marcadores de su grupo (0-1, 2-5 o 6-8, direcciones en
    0xB75A) y pone el 0x98 en el suyo."""
    estado = (estado & rom[0xB733 - ORG + 2 * a]) | rom[0xB733 - ORG + 2 * a + 1]
    if a == 0:
        v.aplica(flujos.rle(rom, 0xB747, 0x3978)[1])
        v.aplica(flujos.rle(rom, 0xB747, 0x3998)[1])
    elif a == 1:
        v.aplica(flujos.rle(rom, 0xB74D, 0x3979)[1])
        v.aplica(flujos.rle(rom, 0xB753, 0x3999)[1])
    if a >= 9:
        return estado
    filas, desde = (3, 6) if a >= 6 else (4, 2) if a >= 2 else (2, 0)
    d = w(rom, 0xB75A + 2 * desde)
    for _ in range(filas):
        v.pon(d, 0x97)
        d += 0x20
    v.pon(w(rom, 0xB75A + 2 * a), 0x98)
    return estado


def file_mode(rom, v=None, estado=0, sin_disco=True):
    """0xB771: FILE MODE. Los dos sprites de 0xBA6C, el marco, el cuadro de
    FILE (0x9AC5, 0x9C63, 0x9D74, 0xB841) y las tres opciones marcadas
    segun 0xDB0E (0xB80D): bit 0 cinta o disco, bits 1-2 la operacion, bits
    3-4 que se guarda (TONE, LAYOUT, SAMP)."""
    v = v or play(rom)
    v.pon(0x3B00, 0xD0)
    marco_y_cabecera(rom, v, 4)
    v.aplica(flujos.rle3(rom, 0x9AC5, 0x2458)[1])
    v.aplica(flujos.rle3(rom, 0x9C63, 0x0458)[1])
    v.aplica(flujos.rle(rom, 0x9D74)[1])
    v.aplica(flujos.rle(rom, 0xB841)[1])
    for a in (estado & 1, 2 + ((estado >> 1) & 3), 6 + ((estado >> 3) & 3)):
        estado = opcion_de_file(rom, v, estado, a)
    if sin_disco:
        # (0xD9DE) = 1 si H.PHYD (0xFFA7) es un `ret`: no hay disco. 0xB7C2
        # borra el rotulo DISK (0xB70B) y la linea de 0x38F8.
        v.aplica(flujos.rle(rom, 0xB747, 0x3978)[1])
        v.aplica(flujos.rle(rom, 0xB747, 0x3998)[1])
        v.aplica(flujos.rle(rom, 0xB747, 0x38F8)[1])
    sprites(rom, v, 0xBA6C, 8)
    return v


PANTALLAS = {"konami": logo_konami, "titulo": titulo, "tone": tone_edit,
             "wave": wave_edit, "syn": syn, "play": play, "file": file_mode}


def coteja(v, volcado, regs=None):
    """Cuantos bytes de lo que escribimos difieren del volcado, y cuantos
    puntos difieren en la imagen."""
    malos = [a for a in sorted(v.escrito) if v.m[a] != volcado[a]]
    a = v.imagen()
    b = render.pantalla(volcado, regs or v.regs)
    puntos = sum(1 for i in range(0, len(a), 3) if a[i:i + 3] != b[i:i + 3])
    return malos, puntos


def main():
    rom = open(sys.argv[1], "rb").read()
    if sys.argv[2] == "coteja":
        nombre, fich = sys.argv[3], sys.argv[4]
        volcado = open(fich, "rb").read()
        regs = list(open(fich[:-5] + ".regs", "rb").read())
        mejores = []
        for var in ({}, {"rotulo": False}) if nombre == "titulo" else ({},):
            v = PANTALLAS[nombre](rom, **var)
            malos, puntos = coteja(v, volcado, regs)
            mejores.append((len(malos) + puntos, malos, puntos, var))
        _, malos, puntos, var = min(mejores, key=lambda x: x[0])
        print("%s %s: %d bytes escritos, %d distintos; %d puntos distintos" % (
            nombre, var or "", len(v.escrito), len(malos), puntos))
        for a in malos[:20]:
            print("  0x%04X nuestro %02X volcado %02X" % (a, v.m[a], volcado[a]))
        print("  registros del volcado:", " ".join("%02X" % r for r in regs))


if __name__ == "__main__":
    main()
