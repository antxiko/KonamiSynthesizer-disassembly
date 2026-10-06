# omsx_cobertura.tcl - Que bytes de unos rangos se EJECUTAN y cuales se LEEN.
# Lee SY_RANGOS ("ini fin" en hex, uno por linea) y pone un watchpoint de
# lectura en cada uno: si el PC es la direccion leida, es una instruccion que
# se ejecuta (se apunta el PC); si no, es un dato que lee el PC que se apunta.
# Sigue el guion SY_GUION ("segundos accion args"):
#   tecla FILA BIT [DURACION]   pulsa esa tecla de la matriz
#   foto NOMBRE                 captura en SY_OUT/NOMBRE.png
#   vuelca NOMBRE               VRAM, RAM 0xC000-0xFFFF y registros del VDP
#   cinta                       mete una cinta nueva que graba en SY_OUT/cinta.wav
#   fin                         escribe y sale
# Escribe SY_OUT/ejecuta.txt (PC) y SY_OUT/lee.txt (direccion PC) y
# SY_OUT/pantalla.txt (el byte 0xD8F4 cada segundo).
set OUT $::env(SY_OUT)
file mkdir $OUT
set ::ej [dict create]
set ::le [dict create]
proc pasa {} {
    set a $::wp_last_address
    set pc [reg PC]
    if {$pc == $a} { dict set ::ej $pc 1 } else { dict set ::le [format "%04X %04X" $a $pc] 1 }
}
set f [open $::env(SY_RANGOS) r]
while {[gets $f l] >= 0} {
    if {[string trim $l] eq ""} continue
    lassign $l ini fin
    debug set_watchpoint read_mem [list 0x$ini 0x$fin] {} pasa
}
close $f
proc guarda {nom datos} {
    set f [open "$::OUT/$nom" wb]; puts -nonewline $f $datos; close $f
}
proc escribe {} {
    set f [open "$::OUT/ejecuta.txt" w]
    foreach k [lsort -integer [dict keys $::ej]] { puts $f [format %04X $k] }
    close $f
    set f [open "$::OUT/lee.txt" w]
    foreach k [lsort [dict keys $::le]] { puts $f $k }
    close $f
}
set ::pant ""
proc mira {} {
    append ::pant [format "%.0f %02X\n" [machine_info time] [debug read memory 0xD8F4]]
    set f [open "$::OUT/pantalla.txt" w]; puts -nonewline $f $::pant; close $f
    escribe
    after time 1 mira
}
after time 1 mira
proc tecla {fila bit {dur 0.15}} {
    keymatrixdown $fila $bit
    after time $dur [list keymatrixup $fila $bit]
}
proc foto {nom} { screenshot -raw "$::OUT/$nom.png" }
proc vuelca {nom} {
    guarda $nom.vram [debug read_block VRAM 0 16384]
    guarda $nom.ram [debug read_block memory 0xC000 0x4000]
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    guarda $nom.regs $r
}
proc cinta {} { cassetteplayer new [file join $::OUT cinta.wav] }
proc fin {} { escribe; exit }
set throttle [expr {[info exists ::env(SY_RAPIDO)] ? "off" : "on"}]
set f [open $::env(SY_GUION) r]
while {[gets $f l] >= 0} {
    set l [string trim $l]
    if {$l eq "" || [string index $l 0] eq "#"} continue
    set t [lindex $l 0]
    after time $t [lrange $l 1 end]
}
close $f
