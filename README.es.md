# Konami's Synthesizer (MSX) — desensamblado comentado

*(Also available [in English](README.md).)*

Desensamblado comentado de ***Konami's Synthesizer*** (新世SIZER, シンセサイザー),
Konami, 1986, cartucho **RC-741** para **MSX**: 32 KB sin mapeador en las
páginas 1 y 2 y un DAC de 8 bits en `0x4000`.

**La web**: https://antxiko.github.io/KonamiSynthesizer-disassembly/es/

| | |
|---|---|
| explicado | 100 % (16.229 bytes de código, 16.539 de datos) |
| comentado | 43,6 % de las instrucciones |
| rutinas | 1.187, ninguna por debajo del 10 % |
| reensamblado | la ROM, byte a byte |
| imágenes | dibujadas desde la ROM; veintitrés pantallas cotejadas contra openMSX, 0 diferencias |
| sonido | el motor escrito de nuevo da los dieciséis timbres byte a byte; lo que llega al DAC, cotejado: 0 distintos |

## Qué hay

- El listado (`src/synth.asm`), que se genera desde el binario y las notas y
  reensambla la ROM exacta.
- El sintetizador escrito de nuevo (`tools/motor.py`) y los dieciséis timbres
  tocados como los toca el cartucho (`tools/sonido.py`, `docs/sonido/`).
- Las siete pantallas, los dieciséis TONE EDIT y las catorce ondas, montados
  desde las tablas de la ROM.
- Cómo funciona: la nota se calcula muestra a muestra en la RAM del
  ordenador, la altura es un bucle de ciclos con trece rellenos, el ruido
  sale de la BIOS, y los ficheros TONE, LAYOUT y SAMP de la cinta.

## Cómo reproducirlo

Hace falta Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) y **tu propia
imagen del cartucho** como `synth.rom` en la raíz:

```
sha256  a2eea29f13662acea8d0cbe2b4e95201a29e82e0c3c38dd24e910e9325a90a0d
make
```

Los detalles, en [Empezar](docs/es/EMPEZAR.md).

## Aviso

El programa es de Konami; aquí solo están el análisis, los comentarios y las
herramientas. La ROM no se distribuye. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
