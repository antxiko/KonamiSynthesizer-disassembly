# omsx_ritmo.tcl - A que ritmo saca PLAY las muestras. Un watchpoint de
# escritura en 0x4000 (el DAC) apunta "segundo HL" de cada escritura. En
# PLAY, con el timbre 1 ya sintetizado, a la tecla Z (fila 5, bit 7: (0xDC47)
# = 0x30, su pareja en 0xD22E + 2 * 0x30 = 0xD28E) se le pone cada rutina
# r de 0 a 12 con el retardo D de SY_RETARDOS y se pulsa medio segundo.
# Escribe SY_OUT/ritmo_RR_DD.txt.
set OUT $::env(SY_OUT)
file mkdir $OUT
set ::log ""
set ::graba 0
proc dac {} { if {$::graba} { append ::log [format "%.9f %04X\n" [machine_info time] [reg HL]] } }
debug set_watchpoint write_mem 0x4000 {} dac
set ::pruebas {}
foreach d $::env(SY_RETARDOS) { for {set r 0} {$r < 13} {incr r} { lappend ::pruebas [list $r $d] } }
set ::i 0
proc prueba {} {
    if {$::i >= [llength $::pruebas]} { exit }
    lassign [lindex $::pruebas $::i] r d
    debug write memory 0xD28E $r
    debug write memory 0xD28F $d
    set ::log ""
    set ::graba 1
    keymatrixdown 5 0x80
    after time 0.5 [list suelta $r $d]
}
proc suelta {r d} {
    keymatrixup 5 0x80
    after time 1 [list guarda $r $d]
}
proc guarda {r d} {
    set ::graba 0
    set f [open [format "%s/ritmo_%02d_%02X.txt" $::OUT $r $d] w]
    puts -nonewline $f $::log; close $f
    incr ::i
    after time 0.5 prueba
}
proc pulsa {fila bit} { keymatrixdown $fila $bit; after time 0.2 [list keymatrixup $fila $bit] }
proc espera_play {} {
    if {[debug read memory 0xD8F4] == 3 && [debug read memory 0xD8FA] > 0} {
        after time 2 prueba
    } else {
        after time 1 espera_play
    }
}
after time 20 { pulsa 8 0x01 }
after time 28 { pulsa 6 0x80; after time 3 espera_play }
set throttle off
