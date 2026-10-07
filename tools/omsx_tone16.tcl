# omsx_tone16.tcl - TONE EDIT con los dieciseis timbres de fabrica, un
# volcado de VRAM por timbre. No va a tiempos fijos: espera a que la intro
# este en el titulo ((0xD800) = 1), pulsa SPACE, espera al programa en marcha
# (bit 6 de 0xD802), pulsa F1 y, con TONE EDIT en su estado de edicion
# ((0xD8F4) = 0 y (0xD8FA) = 3, con el cursor en el campo del numero de
# timbre), vuelca; INS pasa al timbre siguiente. Escribe SY_OUT/toneNN.*
set OUT $::env(SY_OUT)
file mkdir $OUT
proc guarda {nom datos} { set f [open "$::OUT/$nom" wb]; puts -nonewline $f $datos; close $f }
proc vuelca {nom} {
    guarda $nom.vram [debug read_block VRAM 0 16384]
    guarda $nom.ram [debug read_block memory 0xC000 0x4000]
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    guarda $nom.regs $r
}
proc tecla {fila bit {dur 0.15}} { keymatrixdown $fila $bit; after time $dur [list keymatrixup $fila $bit] }
set ::n 1
proc espera_titulo {} {
    if {[debug read memory 0xD800] == 1} { tecla 8 0x01; after time 2 espera_programa } else { after time 0.3 espera_titulo }
}
proc espera_programa {} {
    if {[debug read memory 0xD802] & 0x40} { tecla 6 0x20; after time 3 siguiente } else { after time 0.3 espera_programa }
}
proc siguiente {} {
    if {[debug read memory 0xD8F4] == 0 && [debug read memory 0xD8FA] == 3} {
        vuelca [format tone%02d $::n]
        if {$::n == 16} { exit }
        incr ::n
        tecla 8 0x04
        after time 2 siguiente
    } else { after time 0.5 siguiente }
}
after time 3 espera_titulo
after time 400 exit
set throttle off
