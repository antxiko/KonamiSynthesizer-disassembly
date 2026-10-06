# omsx_dibujo.tcl - El orden en que se pinta cada pantalla: un breakpoint en
# cada rutina que escribe en la VRAM apunta "segundo rutina A BC DE HL
# pantalla(0xD8F4) llamante" en SY_OUT/dibujo.txt. Sigue el mismo guion que
# omsx_cobertura.tcl (tecla / foto / vuelca / fin).
set OUT $::env(SY_OUT)
file mkdir $OUT
set ::log ""
set RUTINAS {0x4327 0x4352 0x4358 0x4337 0x434E 0x4303 0x42FF 0x4316 0x0056 0x005C 0x004D 0x0047}
proc apunta {r} {
    set sp [reg SP]
    set ret [expr {[debug read memory $sp] | ([debug read memory [expr {$sp+1}]] << 8)}]
    append ::log [format "%.3f %04X A=%02X BC=%04X DE=%04X HL=%04X P=%02X desde=%04X\n" \
        [machine_info time] $r [expr {[reg AF] >> 8}] [reg BC] [reg DE] [reg HL] \
        [debug read memory 0xD8F4] $ret]
}
foreach r $RUTINAS { debug set_bp $r {} [list apunta $r] }
proc guarda {nom datos} {
    set f [open "$::OUT/$nom" wb]; puts -nonewline $f $datos; close $f
}
proc escribe {} { guarda dibujo.txt $::log }
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
proc cada {} { escribe; after time 2 cada }
after time 2 cada
set throttle on
set f [open $::env(SY_GUION) r]
while {[gets $f l] >= 0} {
    set l [string trim $l]
    if {$l eq "" || [string index $l 0] eq "#"} continue
    after time [lindex $l 0] [lrange $l 1 end]
}
close $f
