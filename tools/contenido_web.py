#!/usr/bin/env python3
"""EL CONTENIDO de la web de este cartucho: lo unico que es de este programa.

md2html.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Las cifras estan medidas sobre este cartucho: CODIGO y DATOS los imprime
tools/presupuesto.py (make sanity); INSTRUCCIONES y COMENTARIOS, tools/
densidad.py (make densidad), que da tambien RUTINAS.
"""

NOMBRE = "Konami's Synthesizer"
CATALOGO = "RC-741"
ANIO = 1986
REPOSITORIO = "https://github.com/antxiko/KonamiSynthesizer-disassembly"

CODIGO = 16229
DATOS = 16539
RUTINAS = 1187
INSTRUCCIONES = 8637
COMENTARIOS = 3767


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Konami's Synthesizer</em> lo public&oacute; Konami para MSX en "
          "1986; su n&uacute;mero de cat&aacute;logo es RC-741 y son 32 KB con "
          "un DAC. Todos los derechos sobre el programa siguen siendo de sus "
          "titulares. Este trabajo es de preservaci&oacute;n, estudio y "
          "documentaci&oacute;n, y la imagen del cartucho no se distribuye.",
    "en": "<em>Konami's Synthesizer</em> was published by Konami for the MSX in "
          "1986; its catalogue number is RC-741 and it is 32 KB with a DAC. All "
          "rights in the program remain with their holders. This is "
          "preservation, study and documentation work, and the cartridge image "
          "is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Konami's Synthesizer (MSX) - desensamblado comentado",
        claim="Un sintetizador que calcula cada nota muestra a muestra en el "
              "Z80 y la toca por un DAC de 8 bits: catorce ondas, "
              "diecis&eacute;is timbres, tres envolventes, un filtro con "
              "resonancia y un teclado de 48 teclas. Todo dibujado desde la ROM, "
              "y el sonido reconstruido byte a byte.",
        ficha=["Konami - <b>(c) Konami 1986</b>",
               "Cartucho <b>RC-741</b> de 32 KB con DAC", "<b>MSX</b>",
               "Volcado <b>a2eea29f...</b>"],
        aviso="<b>Aqu&iacute; no hay ninguna captura.</b> Todas las "
              "im&aacute;genes est&aacute;n <b>dibujadas desde los bytes de la "
              "ROM</b> con las tablas del propio cartucho: los logotipos, el "
              "t&iacute;tulo, las siete pantallas y los diecis&eacute;is TONE "
              "EDIT, y las catorce ondas. Veintitr&eacute;s pantallas est&aacute;n "
              "<b>cotejadas contra openMSX</b> byte a byte, con 0 diferencias. "
              "El sonido sale de un motor escrito de nuevo que da los "
              "diecis&eacute;is timbres iguales a los del cartucho, y lo que "
              "llega al DAC est&aacute; cotejado: 22.273 bytes, 0 distintos. El "
              "listado y las cifras se reproducen con <code>make</code>, y el "
              "reensamblado devuelve la ROM <b>byte a byte</b>.",
    ),
    "en": dict(
        titulo="Konami's Synthesizer (MSX) - a commented disassembly",
        claim="A synthesizer that computes every note sample by sample on the "
              "Z80 and plays it through an 8-bit DAC: fourteen waves, sixteen "
              "tones, three envelopes, a resonant filter and a 48-key "
              "keyboard. All drawn from the ROM, and the sound rebuilt byte for "
              "byte.",
        ficha=["Konami - <b>(c) Konami 1986</b>",
               "An <b>RC-741</b> 32 KB cartridge with a DAC", "<b>MSX</b>",
               "Dump <b>a2eea29f...</b>"],
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b> with the cartridge's own tables: the "
              "logos, the title, the seven screens and the sixteen TONE EDITs, "
              "and the fourteen waves. Twenty-three screens are <b>checked "
              "against openMSX</b> byte for byte, with 0 differences. The sound "
              "comes from a rewritten engine that gives the sixteen tones "
              "identical to the cartridge's, and what reaches the DAC is "
              "checked: 22,273 bytes, 0 different. The listing and the numbers "
              "are reproducible with <code>make</code>, and reassembling gives "
              "back the ROM <b>byte for byte</b>.",
    ),
}

HALLAZGOS = {
    "es": [
        ("Un sintetizador dentro del Z80",
         "<p>El cartucho no lleva chip de sonido: lleva un DAC de 8 bits en "
         "<code>0x4000</code>, y el programa calcula la nota muestra a muestra "
         "(<code>0x5767</code>): oscilador, filtro de dos etapas con "
         "resonancia, amplificador, tres envolventes ADSR y LFO.</p><p>Medido "
         "en openMSX: el motor escrito de nuevo da los diecis&eacute;is timbres "
         "byte a byte iguales.</p>"),
        ("La altura de la nota es un bucle de ciclos",
         "<p>PLAY manda el sample al DAC byte a byte y espera entre uno y otro: "
         "cada tecla tiene una rutina de trece y un retardo D "
         "(<code>0x5DA9</code>), y la rutina r cuesta 59 + r + 14 &times; D "
         "ciclos. Una tecla cada vez.</p><p>Medido: 254,37 ciclos de media en "
         "LA3, 254 y 255.</p>"),
        ("El sample vive en la RAM del ordenador",
         "<p>El cartucho no tiene RAM: <code>0x4105</code> pone la RAM del "
         "ordenador en <code>0x8000</code>-<code>0xBFFF</code> para sintetizar "
         "y tocar, y <code>0x410D</code> devuelve el cartucho para pintar.</p>"
         "<p>Medido: A8 = 0xF4 durante SYN.</p>"),
        ("El ruido viene de la BIOS",
         "<p>La onda 16 y el muestreo y retenci&oacute;n del LFO leen la ROM de "
         "la BIOS desde <code>0x0000</code> (<code>0x5AD4</code>): el timbre 14 "
         "suena distinto en cada ordenador.</p><p>Sale del c&oacute;digo.</p>"),
        ("El DAC arranca sin golpe",
         "<p>La primera interrupci&oacute;n (<code>0x4118</code>) solo sube el "
         "DAC de 0 a <code>0x80</code>, un paso por vez, 129 veces, y luego "
         "cede el gancho.</p><p>Sale del c&oacute;digo.</p>"),
        ("TONE, LAYOUT y SAMP",
         "<p>Tres ficheros de cinta: los diecis&eacute;is timbres con sus "
         "diecis&eacute;is ondas (4.608 bytes), la nota de cada tecla (176) y "
         "el sample con su p&aacute;gina de bucle (hasta 16 KB).</p><p>Sale del "
         "c&oacute;digo, y la cinta que ven&iacute;a con el cartucho lo "
         "confirma: siete SAMP.</p>"),
        ("La segunda p&aacute;gina del men&uacute;",
         "<p>SHIFT cambia el men&uacute;: copiar un timbre con su onda, la "
         "lista de los diecis&eacute;is, imprimir la pantalla y LAYOUT, donde "
         "cada tecla recibe su nota.</p><p>Sale del c&oacute;digo; estas "
         "pantallas no est&aacute;n montadas.</p>"),
        ("Lo que nadie llama, y la marca",
         "<p>Diez trozos de c&oacute;digo sin nadie que los llame, entre ellos "
         "un cargador de gr&aacute;ficos por una tabla que no existe "
         "(<code>0x49CD</code>) y tres <code>ld hl</code> que no sirven en las "
         "envolventes; <code>RC741 86 5 31</code> en <code>0xBF62</code>, y la "
         "marca oculta de Konami al final: "
         "&#12471;&#12531;&#12475;&#12469;&#12452;&#12470;&#12540;, RC-741 "
         "(formato de Manuel Pazos).</p>"),
    ],
    "en": [
        ("A synthesizer inside the Z80",
         "<p>The cartridge has no sound chip: it has an 8-bit DAC at "
         "<code>0x4000</code>, and the program computes the note sample by "
         "sample (<code>0x5767</code>): oscillator, two-stage resonant filter, "
         "amplifier, three ADSR envelopes and an LFO.</p><p>Measured in "
         "openMSX: the rewritten engine gives the sixteen tones byte for byte."
         "</p>"),
        ("The pitch is a loop of cycles",
         "<p>PLAY sends the sample to the DAC byte by byte and waits between "
         "them: every key has one of thirteen routines and a delay D "
         "(<code>0x5DA9</code>), and routine r costs 59 + r + 14 &times; D "
         "cycles. One key at a time.</p><p>Measured: 254.37 cycles on average "
         "at A3, 254 and 255.</p>"),
        ("The sample lives in the computer's RAM",
         "<p>The cartridge has no RAM: <code>0x4105</code> puts the computer's "
         "RAM at <code>0x8000</code>-<code>0xBFFF</code> to synthesize and "
         "play, and <code>0x410D</code> brings the cartridge back to draw.</p>"
         "<p>Measured: A8 = 0xF4 during SYN.</p>"),
        ("The noise comes from the BIOS",
         "<p>Wave 16 and the LFO's sample and hold read the BIOS ROM from "
         "<code>0x0000</code> (<code>0x5AD4</code>): tone 14 sounds different "
         "on every computer.</p><p>From the code.</p>"),
        ("The DAC starts without a thump",
         "<p>The first interrupt routine (<code>0x4118</code>) only raises the "
         "DAC from 0 to <code>0x80</code>, one step at a time, 129 times, and "
         "then hands over the hook.</p><p>From the code.</p>"),
        ("TONE, LAYOUT and SAMP",
         "<p>Three tape files: the sixteen tones with their sixteen waves "
         "(4,608 bytes), the note of every key (176) and the sample with its "
         "loop page (up to 16 KB).</p><p>From the code, and the tape that came "
         "with the cartridge confirms it: seven SAMPs.</p>"),
        ("The second page of the menu",
         "<p>SHIFT changes the menu: copy a tone with its wave, list the "
         "sixteen, print the screen and LAYOUT, where every key gets its note."
         "</p><p>From the code; these screens are not built.</p>"),
        ("What nobody calls, and the mark",
         "<p>Ten pieces of code nobody calls, among them a graphics loader "
         "driven by a table that does not exist (<code>0x49CD</code>) and three "
         "useless <code>ld hl</code> in the envelopes; <code>RC741 86 5 31</code> "
         "at <code>0xBF62</code>, and Konami's hidden mark at the end: "
         "&#12471;&#12531;&#12475;&#12469;&#12452;&#12470;&#12540;, RC-741 "
         "(Manuel Pazos's format).</p>"),
    ],
}

# La cabecera: el rotulo 新世SIZER, dibujado desde la ROM (tools/imagenes.py)
LOGOTIPO = "rotulo.png"
GALERIA = [
    ("titulo.png",
     "El t&iacute;tulo: el r&oacute;tulo (133 tiles de <code>0x9E97</code>, "
     "pintados a pinceladas), PUSH SPACE KEY y el (c) KONAMI 1986 de "
     "<code>0xBE75</code>. Cotejado contra openMSX: 0 diferencias.",
     "The title: the logo (133 tiles from <code>0x9E97</code>, painted in "
     "strokes), PUSH SPACE KEY and the (c) KONAMI 1986 from "
     "<code>0xBE75</code>. Checked against openMSX: 0 differences."),
    ("tone-01.png",
     "TONE EDIT con el timbre 1, EBASS1: los 29 campos pintados desde los 32 "
     "bytes de <code>0xA3AA</code>, las cifras, las barras y los conmutadores. "
     "Cotejado: 0 diferencias.",
     "TONE EDIT with tone 1, EBASS1: the 29 fields drawn from the 32 bytes at "
     "<code>0xA3AA</code>, the digits, the bars and the switches. Checked: 0 "
     "differences."),
    ("tone-edit.png",
     "Los diecis&eacute;is TONE EDIT, uno por timbre de f&aacute;brica. Los "
     "diecis&eacute;is cotejados: 0 diferencias.",
     "The sixteen TONE EDITs, one per factory tone. All sixteen checked: 0 "
     "differences."),
    ("wave.png",
     "WAVE EDIT con la onda del usuario del timbre 1, el seno de "
     "<code>0x7200</code> trazado columna a columna como lo traza "
     "<code>0xB0AB</code>. Cotejado: 0 diferencias.",
     "WAVE EDIT with tone 1's user wave, the sine from <code>0x7200</code> "
     "traced column by column the way <code>0xB0AB</code> traces it. Checked: "
     "0 differences."),
    ("syn.png",
     "SYN: el teclado dibujado (<code>0x925A</code>), la nota de cada tecla "
     "seg&uacute;n el LAYOUT y el cursor de la s&iacute;ntesis. Cotejado: 0 "
     "diferencias.",
     "SYN: the drawn keyboard (<code>0x925A</code>), each key's note from the "
     "LAYOUT and the synthesis cursor. Checked: 0 differences."),
    ("play.png",
     "PLAY: el mismo teclado con la mano. Cotejado: 0 diferencias.",
     "PLAY: the same keyboard with the hand. Checked: 0 differences."),
    ("file.png",
     "FILE MODE con las opciones de f&aacute;brica, TAPE, SAVE y TONE, y la "
     "flecha en OK. Cotejado: 0 diferencias.",
     "FILE MODE with the factory options, TAPE, SAVE and TONE, and the arrow on "
     "OK. Checked: 0 differences."),
    ("ondas.png",
     "Las catorce ondas del oscilador, 256 muestras con signo cada una, de "
     "<code>0x7200</code> a <code>0x8000</code>.",
     "The fourteen oscillator waves, 256 signed samples each, from "
     "<code>0x7200</code> to <code>0x8000</code>."),
    ("logotipo-konami.png",
     "El logotipo de Konami que se destapa l&iacute;nea a l&iacute;nea al "
     "encender (<code>0x45B9</code>, <code>0x4585</code>). Cotejado: 0 "
     "diferencias.",
     "The Konami logo uncovered line by line at power-on (<code>0x45B9</code>,"
     " <code>0x4585</code>). Checked: 0 differences."),
]
