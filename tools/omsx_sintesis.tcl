# omsx_sintesis.tcl - Lo que calcula SYN para cada timbre de fabrica: un
# breakpoint en 0x57B0 (`ld (hl),a`, la muestra que se guarda) apunta A.
# El bufer no se puede leer despues: en openMSX la pagina 2 es la ROM del
# cartucho y las escrituras no quedan. Para cada timbre n de SY_TIMBRES
# (1-16): con TONE EDIT ya pintado ((0xD8FA) > 0), 0xDB00 = n - 1 (el timbre
# que 0x4BAC copia a 0xDC00) y F3; cuando la pantalla pasa a PLAY
# (0xD8F4 = 3) se guarda SY_OUT/sintesis_NN.bin con las muestras y
# SY_OUT/sintesis_NN.txt con 0xDCFE (longitud) y 0xDCFD (pagina del bucle).
set OUT $::env(SY_OUT)
file mkdir $OUT
set ::muestras ""
set ::n 0
set ::i 0
set ::lista [expr {[info exists ::env(SY_TIMBRES)] ? $::env(SY_TIMBRES) : "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16"}]
set ::fase espera
proc apunta {} { append ::muestras [format %c [expr {[reg AF] >> 8}]] }
debug set_bp 0x57B0 {} apunta
proc pulsa {fila bit} { keymatrixdown $fila $bit; after time 0.2 [list keymatrixup $fila $bit] }
proc guarda {} {
    set f [open [format "%s/sintesis_%02d.bin" $::OUT [expr {$::n + 1}]] wb]
    puts -nonewline $f $::muestras; close $f
    set f [open [format "%s/sintesis_%02d.txt" $::OUT [expr {$::n + 1}]] w]
    puts $f [format "longitud %04X bucle %02X" [expr {[debug read memory 0xDCFE] | ([debug read memory 0xDCFF] << 8)}] [debug read memory 0xDCFD]]
    close $f
}
proc mira {} {
    switch $::fase {
        a_tone {
            if {[debug read memory 0xD8F4] == 0 && [debug read memory 0xD8FA] > 0} {
                debug write memory 0xDB00 [expr {[lindex $::lista $::i] - 1}]
                set ::muestras ""
                pulsa 6 0x80
                set ::fase sintesis
            } elseif {[debug read memory 0xD8F4] != 0} {
                pulsa 6 0x20
            }
        }
        sintesis {
            if {[debug read memory 0xD8F4] == 3} {
                set ::n [expr {[lindex $::lista $::i] - 1}]
                guarda
                incr ::i
                if {$::i >= [llength $::lista]} { exit }
                set ::fase a_tone
            }
        }
    }
    after time 1 mira
}
after time 20 { pulsa 8 0x01 }
after time 28 { set ::fase a_tone; mira }
set throttle off
