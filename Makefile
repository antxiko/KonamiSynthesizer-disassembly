# Konami's Synthesizer (Konami RC-741, 1986, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como synth.rom, y
# `make comprueba` verifica su sha256.

ROM      = synth.rom
SHA      = 133eeec083f52e2a9fa8b06a63fec81edaddec8785a8d34de037bb3f9116cb4d
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = KONAMI'S SYNTHESIZER - Konami - MSX1 - cartucho RC-741 de 32 KB con DAC

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Konami's Synthesizer (Konami, RC-741) para MSX, 32768 bytes exactos,"
	@echo " el volcado [a] (sha1 73a40e7d6da2bc8489297fd57b7b93b2aa5a6440)."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/synth.trace.json: $(ROM) $(SRC)/synth.entries $(SRC)/synth.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/synth.entries \
	        $(WORK)/synth $(SRC)/synth.nocode

trace: $(WORK)/synth.trace.json

listado: $(WORK)/synth.trace.json $(SRC)/synth.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/synth.trace.json \
	        $(SRC)/synth.notes work/msx.sym $(SRC)/synth.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/synth.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/synth.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/synth.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/synth.trace.json $(SRC)/synth.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/synth.entries $(SRC)/synth.notes \
	        $(SRC)/synth.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/synth.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# LAS IMAGENES, montadas desde la ROM con tools/pantallas.py: ni una captura.
imagenes: $(ROM)
	python3 tools/imagenes.py $(ROM) docs/imagenes

# Y la prueba de que son las de verdad: cada pantalla contra un volcado de
# VRAM de openMSX, byte a byte (los volcados, en work/: ver coteja_todo.py).
coteja: $(ROM)
	@python3 tools/coteja_todo.py $(ROM)

# LA WEB. Bilingue: el ingles en docs/ y el castellano en docs/es/.
web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/synth.trace.json $(WORK)/synth.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes coteja web clean
