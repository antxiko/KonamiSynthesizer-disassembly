#!/usr/bin/env python3
"""Encaja cuantas entradas tiene cada tabla pegada detras de un `call` al
despachador de Konami.

El armazon es el mismo en todos estos cartuchos:

    pop hl / add a,a / hl += a / ld e,(hl) / inc hl / ld d,(hl) / ex de,hl / jp (hl)

El `pop hl` recoge la direccion de retorno, que es donde empieza la tabla,
porque la tabla va PEGADA detras del `call`. Cuantas entradas tiene no lo dice
nadie: hay que encajarlo. Dos reglas, y las dos se comprueban byte a byte:

  1. toda entrada cae dentro del cartucho, 0x4000..0xBFFF;
  2. NINGUNA entrada apunta dentro de la propia tabla.

La segunda es la que decide. Si la entrada mas baja cae a mitad de la tabla, la
tabla acaba antes: ese word es a la vez la ultima entrada y el sitio donde
sigue el codigo.

Uso: encaja_tablas.py <rom> <org> <opcode-del-despachador-en-hex>
"""
import sys


def main():
    rom = open(sys.argv[1], "rb").read()
    org = int(sys.argv[2], 0)
    disp = int(sys.argv[3], 0)
    top = org + len(rom)

    lo, hi = disp & 0xFF, disp >> 8
    sitios = [i + org for i in range(len(rom) - 2)
              if rom[i] == 0xCD and rom[i + 1] == lo and rom[i + 2] == hi]

    def word(a):
        i = a - org
        return rom[i] | (rom[i + 1] << 8)

    print("# %d llamadas a 0x%04X" % (len(sitios), disp))
    for s in sitios:
        t = s + 3
        ent = []
        while True:
            a = t + 2 * len(ent)
            if a + 1 >= top:
                break
            e = word(a)
            if not (org <= e < top):
                break
            # regla 2: con esta entrada de mas, la tabla llegaria hasta fin
            fin = t + 2 * (len(ent) + 1)
            if any(t <= x < fin for x in ent + [e]):
                break
            ent.append(e)
        techo = len(ent)

        # LA PRUEBA QUE MANDA: casi todas estas llamadas van precedidas de
        # `ld hl,<nnnn> / push hl`, que fabrica la direccion de retorno de la
        # escena. Y esa direccion es justo el byte que sigue a la tabla, porque
        # el codigo continua ahi. Si aparece, no hay nada que estimar.
        fijo = None
        for k in range(4, 24):
            if s - k < org:
                break
            i = s - k - org
            # el `push hl` no siempre va pegado al `ld hl`: a veces se cuela un
            # `push bc` entre medias (0x6DB5, por ejemplo). Basta con que haya
            # un `push hl` entre el `ld hl` y el `call`.
            if rom[i] == 0x21 and 0xE5 in rom[i + 3:s - org]:
                v = rom[i + 1] | (rom[i + 2] << 8)
                if t < v <= t + 2 * techo and (v - t) % 2 == 0:
                    fijo = (v - t) // 2
                    origen = s - k
                    break

        n = fijo if fijo is not None else techo
        ent = ent[:n]
        fin = t + 2 * n
        if fijo is not None:
            porque = ("el `ld hl,0%04xh / push hl` de 0x%04X lo cierra"
                      % (fin, origen))
        elif ent and min(ent) == fin:
            porque = "la entrada mas baja ES el final"
        else:
            porque = "SIN CERRAR: ni push ni entrada que tope; %d es el techo" % techo
        print("!tabla 0x%04x %3d   # desde 0x%04X; sigue en 0x%04X, %s"
              % (t, n, s, fin, porque))
        print("#   " + " ".join("%04X" % e for e in ent))


main()
