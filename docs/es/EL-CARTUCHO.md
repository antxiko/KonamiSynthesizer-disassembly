# El cartucho

32 KB sin mapeador, en las páginas 1 y 2 (`0x4000`-`0xBFFF`), y el
convertidor digital-analógico: **el DAC es cualquier escritura en `0x4000`**,
8 bits sin signo con el reposo en `0x80`. El cartucho **no lleva RAM**: el
sample vive en la RAM del ordenador, en `0x8000`-`0xBFFF`, y el programa
cambia esa página entre la RAM (`0x4105`) y el cartucho (`0x410D`) con
ENASLT, según toque tocar o pintar.

## El arranque

`0x4000`: "AB" e INIT en `0x4054`. INIT apunta las ranuras de las páginas 1 y
2 (`0x40D4`) y copia a `H.STKE` un `rst 0x30` a `0x406E`: el programa
arranca cuando el BASIC termina de arrancar. Entonces borra las variables,
pone `H.KEYI` y, antes de dejar entrar interrupciones, llena el sample de
silencio.

La primera rutina de interrupción (`0x4118`) no hace más que subir el DAC de
0 a `0x80`, un paso por interrupción, 129 veces; luego cede el gancho a la
rutina de cada cuadro (`0x4015`). Así el altavoz no da el golpe del
encendido.

## El mapa de la ROM

| desde | hasta | qué |
|---|---|---|
| `0x4012` | `0x4D04` | el arranque, la intro, las pantallas, el teclado, los efectos del PSG |
| `0x4D04` | `0x55E8` | FILE: la cinta, el código de disco y la impresora |
| `0x55E8` | `0x5D3A` | SYN: el sintetizador |
| `0x5D3A` | `0x7135` | PLAY: las 39 rutinas que tocan el sample |
| `0x7200` | `0x8000` | las catorce ondas del oscilador, 256 bytes cada una |
| `0x8000` | `0xA3AA` | los gráficos de todas las pantallas, en RLE |
| `0xA3AA` | `0xA5AA` | los dieciséis timbres de fábrica, 32 bytes cada uno |
| `0xA5AA` | `0xBB6D` | TONE EDIT, WAVE EDIT, la copia, la lista y FILE |
| `0xBB6D` | `0xBEA6` | LAYOUT y la demo de la intro |
| `0xBEA6` | `0xBF62` | los efectos del PSG y sus listas |
| `0xBF62` | `0xC000` | `RC741 86 5 31`, relleno y la marca oculta de Konami |

El reparto entero, byte a byte, está en `src/synth.notes`: el código son
16.229 bytes y los datos 16.539, y no queda ninguno sin explicar.

## La RAM

| dirección | qué |
|---|---|
| `0x8000`-`0xBFFF` | el sample: 16 KB de muestras de 8 bits, silencio en `0x80` |
| `0xC000`-`0xCFFF` | las dieciséis ondas del usuario, 256 bytes cada una |
| `0xD000`-`0xD1FF` | los dieciséis timbres, 32 bytes cada uno |
| `0xD200`-`0xD22F` | el LAYOUT: la nota de cada una de las 48 teclas |
| `0xD230`-`0xD2AF` | por tecla, la rutina de PLAY y su retardo |
| `0xD800`-`0xDEFF` | las variables: la fase, las teclas, la pantalla, la copia de los sprites |
| `0xD854` / `0xD855` | las ranuras de la RAM y del cartucho en la página 2 |
| `0xDB00` | el timbre en curso |
| `0xDC00`-`0xDC18` | el timbre que SYN está sintetizando |
| `0xDC19` | el puntero de escritura de SYN |
| `0xDCFD` / `0xDCFE` | la página de bucle y la longitud del sample |
| `0xDD00`-`0xDDFF` | la onda del usuario preparada para escucharla |
| `0xDF00` | la pila, hacia abajo |

## La VRAM

SCREEN 2, con los registros de `0x4295`: colores en `0x0000`, patrones en
`0x2000`, nombres en `0x3800`, atributos de sprite en `0x3B00` y patrones de
sprite en `0x1800`. Los tiles 0 a 15 son cuadros lisos de los dieciséis
colores, la fuente va del `0x10` (las cifras) y del `0x21` (las letras), y
cada pantalla trae sus patrones, colores y nombres en RLE desde la página 2
del cartucho (`0x4358`): un byte de control menor que `0x80` repite el
siguiente, `0x80` + n copia n bytes, `0x80` trae otra dirección y 0 acaba.

## El PSG

Solo para los efectos: tres canales (`0xD810`, cinco bytes cada uno) con
listas de notas en `0xBEFE`. El cursor hace el efecto 1, una operación
acabada el 2, un cambio de pantalla el 5 y la intro el 8 (`0xBEBF`).
