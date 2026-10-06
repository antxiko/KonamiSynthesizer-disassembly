#!/bin/sh
# lanza_dibujo.sh <dir> <guion>: UN openMSX con tools/omsx_dibujo.tcl
# sobre los rangos de work/rangos.txt; deja <dir>/fin.txt al acabar.
R=$(cd "$(dirname "$0")/.." && pwd)
D=$R/$1
mkdir -p $D
cd $R && SY_OUT=$D SY_GUION=$R/$2 SY_RANGOS=$R/work/rangos.txt timeout 900 "/c/Program Files/openMSX/openmsx.exe" -machine ${SY_MAQUINA:-C-BIOS_MSX1_JP} -cart synth.rom -script tools/omsx_dibujo.tcl > $D/log.txt 2>&1
echo hecho > $D/fin.txt
