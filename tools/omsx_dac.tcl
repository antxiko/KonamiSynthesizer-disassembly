# omsx_dac.tcl - Lo que llega al DAC. Un watchpoint de escritura en 0x4000
# apunta "segundo valor" de cada byte que el Z80 escribe ahi. Se deja que la
# intro llegue al titulo, SPACE arranca, F3 sintetiza el timbre 1 (SYN acaba
# en PLAY) y a la tecla Z (fila 5, bit 7; (0xDC47) = 0x30, su pareja en
# 0xD22E + 2 * 0x30 = 0xD28E) se le pone la nota de SY_RUTINA / SY_RETARDO y
# se pulsa SY_SOSTENER segundos. Escribe SY_OUT/dac.txt.
set OUT $::env(SY_OUT)
file mkdir $OUT
set ::log ""
set ::graba 0
proc dac {} { if {$::graba} { append ::log [format "%.9f %02X\n" [machine_info time] $::wp_last_value] } }
debug set_watchpoint write_mem 0x4000 {} dac
proc toca {} {
    debug write memory 0xD28E $::env(SY_RUTINA)
    debug write memory 0xD28F $::env(SY_RETARDO)
    set ::graba 1
    keymatrixdown 5 0x80
    after time $::env(SY_SOSTENER) { keymatrixup 5 0x80; after time 12 guarda }
}
proc guarda {} {
    set ::graba 0
    set f [open "$::OUT/dac.txt" w]; puts -nonewline $f $::log; close $f
    exit
}
proc pulsa {fila bit} { keymatrixdown $fila $bit; after time 0.2 [list keymatrixup $fila $bit] }
proc espera_play {} {
    if {[debug read memory 0xD8F4] == 3 && [debug read memory 0xD8FA] > 0} {
        after time 2 toca
    } else {
        after time 1 espera_play
    }
}
after time 20 { pulsa 8 0x01 }
after time 28 { pulsa 6 0x80; after time 3 espera_play }
set throttle off
