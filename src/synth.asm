; ==========================================================================
; KONAMI'S SYNTHESIZER - Konami - MSX1 - cartucho RC-741 de 32 KB con DAC
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l584ch:	equ 0x0584c
l587dh:	equ 0x0587d
l58d0h:	equ 0x058d0
l58f8h:	equ 0x058f8
l5929h:	equ 0x05929
l597ch:	equ 0x0597c
l5992h:	equ 0x05992
l59c3h:	equ 0x059c3

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x4054);
;   STATEMENT, DEVICE y TEXT a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,04054h,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ----------------------------------------------------------------------
; DATOS ceros_tras_la_cabecera: dos ceros antes del `jp` de 0x4012
;   0x4010..0x4012  (2 bytes)
DATA_ceros_tras_la_cabecera:
	defb 000h,000h	; 4010

; ======================================================================
; CODIGO 0x4012..0x4069  (87 bytes)
; ======================================================================


salto_sin_uso:		; `jp` a 0x455D detras de la cabecera; nadie salta aqui
	jp logo_konami_tiles		;4012
interrupcion:		; la rutina de cada cuadro, por H.KEYI (0xFD9A) desde que 0x4118 acaba
	call 0013eh		;4015   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP: lo borra
	call 0fd9fh		;4018   ; y llama el mismo a H.TIMI
	di			;401b   ; sin interrupciones mientras suenan los efectos
	call efectos_por_cuadro		;401c   ; los efectos de sonido del PSG, cada cuadro
	ld hl,0d805h		;401f   ; 0xD805: ocupado (bit 0)
	bit 0,(hl)		;4022   ; ocupado?
	jr nz,L_4033		;4024   ; si el cuadro anterior no ha acabado, solo los efectos
	inc (hl)			;4026   ; marca ocupado y deja entrar otra interrupcion
	ei			;4027
	call lee_teclas		;4028   ; las teclas
	call fase_de_pantalla		;402b   ; la fase de la pantalla
	ld a,000h		;402e   ; libre
	ld (0d805h),a		;4030   ; libre
L_4033:
	call 0013eh		;4033   ; BIOS RDVDP - Reads VDP status register | si ha llegado otro cuadro mientras tanto (bit 7)...
	or a			;4036   ; el bit 7, al signo
	di			;4037
	call m,efectos_por_cuadro		;4038   ; ...otra vuelta de los efectos
	ei			;403b   ; y se dejan entrar otra vez
	ret			;403c
escribe_registro_vdp:		; WRTVDP: registro C, valor B
	jp 00047h		;403d   ; BIOS WRTVDP - Writes data in the VDP-register
hl_mas_a:		; HL = HL + A
	add a,l			;4040   ; L + A...
	ld l,a			;4041
	ret nc			;4042
	inc h			;4043   ; ...con el acarreo a H
	ret			;4044
de_mas_a:		; DE = DE + A
	add a,e			;4045   ; E + A...
	ld e,a			;4046
	ret nc			;4047
	inc d			;4048   ; ...con el acarreo a D
	ret			;4049
salta_por_tabla:		; salta a la entrada A de la tabla de palabras que sigue al `call`
	pop hl			;404a   ; HL = la tabla, detras del `call`
	add a,a			;404b   ; dos bytes por entrada
	call hl_mas_a		;404c
	ld e,(hl)			;404f   ; DE = la entrada A
	inc hl			;4050
	ld d,(hl)			;4051
	ex de,hl			;4052   ; HL = el destino
	jp (hl)			;4053   ; y alli
init:		; INIT: la llama la BIOS al encontrar el cartucho; deja el arranque para cuando el BASIC termine
	call apunta_slots		;4054   ; 0xD854/0xD855: los slots de las paginas 2 y 1
	ld hl,04069h		;4057   ; los 5 bytes de 0x4069...
	ld de,0fedah		;405a   ; ...a H.STKE (0xFEDA)
	ld bc,00005h		;405d   ; 5 bytes
	ldir		;4060
	ld a,(0d855h)		;4062   ; el slot del cartucho...
	ld (0fedbh),a		;4065   ; ...en el `rst 0x30` del gancho
	ret			;4068

; ----------------------------------------------------------------------
; DATOS gancho_para_h_stke: `rst 0x30`, slot (lo pone INIT), 0x406E y `ret`
;   0x4069..0x406e  (5 bytes)
DATA_gancho_para_h_stke:
	defb 0f7h,000h,06eh,040h,0c9h	; 4069

; ======================================================================
; CODIGO 0x406e..0x4142  (212 bytes)
; ======================================================================


arranque:		; el arranque de verdad: H.STKE salta aqui cuando el BASIC ha terminado de arrancar
	di			;406e   ; sin interrupciones
	im 1		;406f   ; modo 1: las interrupciones van a 0x0038
	call apunta_slots		;4071   ; los slots otra vez: ahora la pagina 2 es la RAM del ordenador
	ld a,0f7h		;4074   ; H.KEYI (0xFD9A) = `rst 0x30`...
	ld (0fd9ah),a		;4076
	ld a,(0d855h)		;4079   ; ...el slot del cartucho...
	ld (0fd9bh),a		;407c
	ld hl,interrupcion_sube_el_dac		;407f   ; ...0x4118...
	ld (0fd9ch),hl		;4082
	ld a,0c9h		;4085   ; ...y `ret`
	ld (0fd9eh),a		;4087
	ld sp,0df00h		;408a   ; la pila, bajo 0xDF00
	ld hl,0d800h		;408d   ; borra las variables, 0xD800-0xDEFF
	ld de,0d801h		;4090   ; 0x6FF bytes mas
	ld bc,006ffh		;4093
	ld (hl),000h		;4096
	ldir		;4098
	call apunta_slots		;409a   ; A = el slot del cartucho...
	ld h,080h		;409d   ; ...tambien en la pagina 2, donde siguen sus graficos
	call 00024h		;409f   ; BIOS ENASLT - Switches to specified slot and page definitively
	ld a,001h		;40a2   ; ocupado: la interrupcion no toca nada
	ld (0d805h),a		;40a4
	call prepara_vdp_y_psg		;40a7   ; VDP, PSG y la VRAM en blanco
	xor a			;40aa   ; libre
	ld (0d805h),a		;40ab
	call ram_en_la_pagina_2		;40ae   ; la RAM en la pagina 2...
	call llena_de_silencio		;40b1   ; ...llena de silencio (0x80)...
	call cartucho_en_la_pagina_2		;40b4   ; ...y vuelve el cartucho
	xor a			;40b7   ; 0xDCFD = 0
	ld (0dcfdh),a		;40b8
	ld hl,00001h		;40bb   ; 0xDCFE: el sample mide 1 byte
	ld (0dcfeh),hl		;40be
	call 0013eh		;40c1   ; BIOS RDVDP - Reads VDP status register | borra el estado del VDP antes de dejar entrar interrupciones
	ei			;40c4
bucle_principal:		; espera a que la pantalla pida trabajo en 0xD8F6 (0x48F0) y llama a 0x4BA1
	ld a,(0d8f6h)		;40c5   ; 0xD8F6: SYN pedido?
	or a			;40c8
	jr z,bucle_principal		;40c9
	call hace_syn		;40cb   ; la sintesis
	xor a			;40ce   ; hecho
	ld (0d8f6h),a		;40cf
	jr bucle_principal		;40d2
apunta_slots:		; 0xD854 = slot de la pagina 2, 0xD855 = slot de la pagina 1 (el cartucho); vuelve con A = 0xD855
	ld de,0d854h		;40d4   ; DE = donde se guardan
	call 00138h		;40d7   ; BIOS RSLREG - Reads the primary slot register | A = registro de slots primarios (RSLREG)
	push af			;40da   ; el registro, para la pagina 1
	rrca			;40db   ; bits 2-3, la pagina 1, a 0-1
	rrca			;40dc
	call slot_de_la_pagina		;40dd   ; C = slot primario de la pagina 2 y A = su registro secundario
	rrca			;40e0   ; el secundario de la pagina 2 a los bits 2-3
	rrca			;40e1
	call guarda_slot		;40e2   ; 0xD854
	inc de			;40e5   ; 0xD855
	pop af			;40e6   ; la pagina 1
	call slot_de_la_pagina		;40e7   ; C = slot primario y A = secundario de la pagina 1: 0xD855
guarda_slot:		; (DE) = C con el secundario de los bits 2-3 de A: el formato de slot de ENASLT
	and 00ch		;40ea   ; el secundario de los bits 2-3...
	or c			;40ec   ; ...con el primario y el bit de expandido
	ld (de),a			;40ed
	ret			;40ee
slot_de_la_pagina:		; de los bits 2-3 de A: C = slot primario (+0x80 si esta expandido, 0xFCC1) y A = su registro secundario (0xFCC5)
	rrca			;40ef   ; los bits de la pagina a 0-1
	rrca			;40f0
	and 003h		;40f1
	ld c,a			;40f3   ; C = el slot primario
	ld b,000h		;40f4
	ld hl,0fcc1h		;40f6   ; EXPTBL (0xFCC1)
	add hl,bc			;40f9
	ld a,(hl)			;40fa
	and 080h		;40fb   ; bit 7: expandido
	or c			;40fd
	ld c,a			;40fe
	inc hl			;40ff   ; SLTTBL (0xFCC5), cuatro mas alla
	inc hl			;4100
	inc hl			;4101
	inc hl			;4102
	ld a,(hl)			;4103   ; A = su registro secundario
	ret			;4104
ram_en_la_pagina_2:		; pone en 0x8000-0xBFFF la RAM del ordenador: el slot que 0x40D4 guarda en 0xD854
	ld h,080h		;4105   ; la pagina 2...
	ld a,(0d854h)		;4107   ; ...el slot de la RAM, y ENASLT
	jp 00024h		;410a   ; BIOS ENASLT - Switches to specified slot and page definitively
cartucho_en_la_pagina_2:		; vuelve a poner el cartucho en 0x8000-0xBFFF (0xD855)
	ld h,080h		;410d   ; la pagina 2...
	ld a,(0d855h)		;410f   ; ...el slot del cartucho, y ENASLT
	jp 00024h		;4112   ; BIOS ENASLT - Switches to specified slot and page definitively
efecto_de_sonido:		; arranca el efecto A en el PSG (0xBEB1)
	jp efecto		;4115
interrupcion_sube_el_dac:		; la primera rutina de H.KEYI: lleva el DAC de 0 a 0x80 (el reposo) de uno en uno, un paso por interrupcion
	ld hl,0d856h		;4118   ; 0xD856: el valor que toca (las variables empiezan a 0)
	ld a,(hl)			;411b
	ld (04000h),a		;411c   ; al DAC
	inc a			;411f   ; el siguiente
	ld (hl),a			;4120
	cp 081h		;4121   ; al llegar a 0x80...
	ret nz			;4123
	ld hl,04015h		;4124   ; ...H.KEYI pasa a 0x4015
	ld (0fd9ch),hl		;4127   ; H.KEYI apunta a 0x4015
	ret			;412a
fase_de_pantalla:		; cada cuadro: 0xD803 cuenta cuadros y salta a la fase 0xD800, con B = el paso 0xD801
	ld hl,0d803h		;412b   ; 0xD803: contador de cuadros
	inc (hl)			;412e
	ld a,(0d800h)		;412f   ; la fase
	cp 003h		;4132   ; menor que 3?
	jr nc,L_413A		;4134   ; en las fases 0, 1 y 2...
	ld hl,04242h		;4136   ; ...vuelve por 0x4242
	push hl			;4139
L_413A:
	ld bc,(0d800h)		;413a   ; C = fase (0xD800), B = paso (0xD801)
	ld a,c			;413e   ; A = la fase
	call salta_por_tabla		;413f   ; a su rutina

; ----------------------------------------------------------------------
; DATOS saltos_del_arranque: 9 destinos por la fase (0xD800); la tabla cierra
;   en 0x4154, su entrada mas baja
;   0x4142..0x4154  (18 bytes)
DATA_saltos_del_arranque:
	defw 04154h,041d3h,041dbh,04201h,04227h,0423fh,04242h,04242h	; 4142
	defw 04242h	; 4152  -> tecla_en_la_intro

; ======================================================================
; CODIGO 0x4154..0x4295  (321 bytes)
; ======================================================================


fase_0:		; paso 1: la cortina del logotipo de Konami, un tramo cada dos cuadros
	djnz fase_0_paso_2		;4154   ; paso 1 aqui; los demas, mas abajo
	ld a,(0d803h)		;4156   ; cuadros impares nada
	rra			;4159   ; bit 0 al acarreo
	ret nc			;415a
	call cortina_logo_konami		;415b   ; la cortina; Z al acabar las seis filas
	ret nz			;415e
	xor a			;415f   ; 0xD804 = 0 y el paso siguiente
	jp siguiente_paso_con_cuenta		;4160
fase_0_paso_2:		; espera 256 cuadros y prepara el logotipo 新世SIZER
	djnz fase_0_paso_3		;4163   ; paso 2 aqui; paso 3 y 0 mas abajo
	ld hl,0d804h		;4165   ; 0xD804: cuenta atras
	dec (hl)			;4168   ; un cuadro menos
	ret nz			;4169
	call logo_sizer_pantalla		;416a   ; colores del logotipo y pantalla
	ld hl,02200h		;416d   ; sus patrones, 0x428 bytes desde 0x2200...
	ld bc,00428h		;4170   ; 0x428 bytes
	ld a,0ffh		;4173   ; ...a 0xFF en los tres tercios
	call rellena_vram_x3		;4175
	call logo_sizer_nombres		;4178   ; la tabla de nombres del logotipo
	ld a,007h		;417b   ; siete pasadas de pincel
	ld (0d910h),a		;417d   ; 0xD910: las pasadas que quedan
	jr siguiente_paso		;4180
fase_0_paso_3:		; cada 16 cuadros una pasada de pincel: los patrones de 0x9E97, de ocho en ocho
	djnz fase_0_paso_0		;4182   ; paso 3 aqui; paso 0 mas abajo
	ld a,(0d803h)		;4184   ; solo uno de cada 16 cuadros
	and 00fh		;4187
	ret nz			;4189
	ld hl,02200h		;418a   ; destino: los patrones de 0x2200...
	ld de,09e97h		;418d   ; ...origen: 0x9E97...
	ld a,(0d910h)		;4190   ; ...los dos mas la pasada (0xD910)
	push af			;4193
	call de_mas_a		;4194   ; el origen mas la pasada...
	pop af			;4197
	call hl_mas_a		;4198   ; ...y el destino
	ld bc,08500h		;419b   ; 0x85 bytes, uno de cada ocho
L_419E:
	push bc			;419e   ; 0x85 vueltas
	ld bc,00001h		;419f   ; un byte...
	push de			;41a2
	push hl			;41a3
	call copia_a_vram_x3		;41a4   ; ...en los tres tercios
	pop hl			;41a7
	pop de			;41a8
	ld a,008h		;41a9   ; ocho mas alla
	call hl_mas_a		;41ab   ; ocho bytes mas alla...
	ld a,008h		;41ae
	call de_mas_a		;41b0   ; ...en los dos
	pop bc			;41b3
	djnz L_419E		;41b4
	ld hl,0d910h		;41b6   ; la pasada siguiente
	dec (hl)			;41b9   ; una pasada menos
	ret p			;41ba   ; quedan pasadas
	ld de,0be75h		;41bb   ; el rotulo de 0xBE75
	call escribe_lista		;41be   ; el rotulo
	xor a			;41c1   ; fase 1 con 0xD804 = 0
	jp siguiente_fase_con_cuenta		;41c2
fase_0_paso_0:		; registros del VDP, pantalla en blanco, la fuente y el logotipo de Konami
	call pon_registros_vdp		;41c5   ; los 8 registros
	call limpia_pantalla		;41c8   ; sprites fuera y nombres a cero
	call fuente		;41cb   ; la fuente
	call logo_konami		;41ce   ; el logotipo de Konami
	jr siguiente_paso		;41d1
fase_1:		; el titulo: espera 256 cuadros y pasa a la fase 2
	ld hl,0d804h		;41d3
	dec (hl)			;41d6   ; un cuadro menos
	ret nz			;41d7
	jp siguiente_fase		;41d8   ; a la fase 2
fase_2:		; paso 1: espera a 0xD863 y vuelve a la fase 0
	djnz fase_2_paso_0		;41db   ; paso 1 aqui; paso 0 mas abajo
	call demo		;41dd   ; 0xBE62
	ld a,(0d863h)		;41e0   ; 0xD863 sin acabar: espera
	or a			;41e3
	ret nz			;41e4
	xor a			;41e5   ; otra vez el logotipo de Konami
	ld (0d800h),a		;41e6   ; fase 0
	ld a,020h		;41e9   ; 0xD804 = 0x20
	ld (0d804h),a		;41eb
	jr paso_0		;41ee
fase_2_paso_0:		; la cortina que borra la tabla de nombres, columna a columna
	call cortina_de_salida		;41f0   ; una columna; P mientras quedan
	ret p			;41f3   ; quedan columnas
	call empieza_demo		;41f4   ; 0xBE41
	ld a,020h		;41f7   ; 0xD804 = 0x20
siguiente_paso_con_cuenta:		; 0xD804 = A y 0xD801 + 1
	ld (0d804h),a		;41f9
siguiente_paso:		; 0xD801 + 1
	ld hl,0d801h		;41fc
	inc (hl)			;41ff
	ret			;4200
fase_3:		; paso 1: la segunda linea del rotulo (0xBE84) parpadea, 4 cuadros escrita y 4 borrada
	djnz fase_3_paso_2		;4201   ; paso 1 aqui; los demas, mas abajo
	ld de,0be84h		;4203   ; la segunda linea del rotulo
	ld a,(0d804h)		;4206   ; bit 2 de la cuenta:
	and 004h		;4209
	jr z,L_4212		;420b
	call escribe_lista		;420d   ; escrita...
	jr L_4215		;4210
L_4212:
	call borra_lista		;4212   ; ...o borrada
L_4215:
	ld hl,0d804h		;4215   ; 0x50 cuadros
	dec (hl)			;4218   ; un cuadro menos
	jr z,siguiente_paso		;4219
	ret			;421b
fase_3_paso_2:		; prepara el programa y pasa a la fase 4
	djnz fase_3_paso_0		;421c
	call prepara_el_programa		;421e   ; timbres, ondas, LAYOUT y sprites
	jr siguiente_fase		;4221
fase_3_paso_0:		; 0xD804 = 0x50 cuadros de parpadeo
	ld a,050h		;4223   ; 0x50 cuadros
	jr siguiente_paso_con_cuenta		;4225
fase_4:		; paso 1: a la fase 5
	djnz fase_4_paso_0		;4227
siguiente_fase:		; 0xD804 = 0x20
	ld a,020h		;4229
siguiente_fase_con_cuenta:		; 0xD804 = A, 0xD800 + 1 y el paso a 0
	ld (0d804h),a		;422b
	ld hl,0d800h		;422e   ; la fase siguiente
	inc (hl)			;4231
paso_0:		; 0xD801 = 0
	xor a			;4232
	ld (0d801h),a		;4233   ; el paso a 0
	ret			;4236
fase_4_paso_0:		; 0xD804 = 0x78
	ld a,078h		;4237   ; 0x78 cuadros
	ld (0d804h),a		;4239
	jp siguiente_paso		;423c
fase_5:		; el programa (0x47DB)
	jp fase_programa		;423f
tecla_en_la_intro:		; tras las fases 0-2: una tecla salta al titulo, y ESPACIO o SELECT en el titulo arrancan
	call byte_de_teclas		;4242   ; el byte de teclas
	ld hl,0d852h		;4245   ; 0xD852 ahora, 0xD851 las recien pulsadas
	call flancos		;4248   ; las recien pulsadas
	or a			;424b
	ret z			;424c   ; ninguna nueva: nada
	ld hl,0d804h		;424d   ; 0xD804 = 0
	ld (hl),000h		;4250   ; 0xD804 = 0
	ld hl,0d800h		;4252
	ld b,(hl)			;4255   ; B = la fase
	djnz L_4266		;4256   ; en la fase 1 (el titulo)...
	and 030h		;4258   ; ...ESPACIO o SELECT (bits 4 y 5)...
	ret z			;425a
	ld a,040h		;425b   ; ...0xD802 = 0x40...
	ld (0d802h),a		;425d
	ld (hl),003h		;4260   ; ...fase 3, paso 0
	inc hl			;4262   ; 0xD801 = 0
	ld (hl),000h		;4263
	ret			;4265
L_4266:
	ld (hl),001h		;4266   ; en las fases 0 y 2: al titulo (fase 1)...
	ld a,008h		;4268   ; ...con el efecto 8...
	call efecto_si_en_marcha		;426a   ; el efecto 8 si el programa esta en marcha
	jp titulo_de_golpe		;426d   ; ...y el logotipo entero de golpe
prepara_vdp_y_psg:		; mezclador del PSG, efecto 8, la VRAM a cero y los 8 registros del VDP
	ld a,0b8h		;4270   ; R7 del PSG = 0xB8: los tres canales de tono
	call mezclador_psg		;4272   ; el mezclador
	ld a,008h		;4275   ; el efecto 8
	call efecto_de_sonido		;4277
	ld hl,00000h		;427a   ; los 16 KB de la VRAM a cero
	ld bc,04000h		;427d   ; 16 KB
	xor a			;4280
	call 00056h		;4281   ; BIOS FILVRM - Fills VRAM with value
pon_registros_vdp:		; los 8 registros del VDP de 0x4295, del R0 al R7
	ld hl,04295h		;4284   ; desde 0x4295...
	ld d,008h		;4287   ; ...8 registros, del R0
	ld c,000h		;4289   ; desde el R0
L_428B:
	ld b,(hl)			;428b   ; el valor
	call 00047h		;428c   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP: registro C, valor B
	inc hl			;428f
	inc c			;4290   ; el registro siguiente
	dec d			;4291
	jr nz,L_428B		;4292
	ret			;4294

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: los 8 registros del VDP, del R0 al R7, que escribe
;   0x4284: SCREEN 2, colores en 0x0000 y patrones en 0x2000
;   0x4295..0x429d  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h	; 4295
	defb 00eh,07fh	; 4297
	defb 007h,076h	; 4299
	defb 003h,0e4h	; 429b

; ======================================================================
; CODIGO 0x429d..0x4414  (375 bytes)
; ======================================================================


color_de_borde:		; R7 del VDP = B
	ld c,007h		;429d
	jp escribe_registro_vdp		;429f   ; WRTVDP
lee_teclas:		; 0xD807 = teclas pulsadas ahora, 0xD806 = las recien pulsadas
	call byte_de_teclas		;42a2   ; A = el byte de teclas
	ld hl,0d807h		;42a5   ; 0xD807 las de ahora, 0xD806 las recien pulsadas
flancos:		; (HL) = A; (HL - 1) = las que no estaban antes; vuelve con ellas en A
	ld c,(hl)			;42a8   ; las de antes
	ld (hl),a			;42a9   ; las de ahora
	xor c			;42aa   ; las que han cambiado...
	and (hl)			;42ab   ; ...y estan pulsadas
	dec hl			;42ac
	ld (hl),a			;42ad   ; las nuevas
	push af			;42ae
	ld de,0d8ffh		;42af   ; 0xD8FF
	call repeticion		;42b2   ; con repeticion en (HL + 2)
	pop af			;42b5
	ret			;42b6
byte_de_teclas:		; bit 0 arriba, 1 abajo, 2 izquierda, 3 derecha, 4 ESPACIO, 5 SELECT
	ld a,007h		;42b7   ; fila 7
	call 00141h		;42b9   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42bc   ; SELECT (bit 6) al bit 5
	rrca			;42bd   ; SELECT del bit 6...
	and 020h		;42be   ; ...al 5
	ld e,a			;42c0
	ld a,008h		;42c1   ; fila 8
	call 00141h		;42c3   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42c6   ; izquierda (bit 4) al bit 2
	rrca			;42c7
	rrca			;42c8
	ld b,a			;42c9   ; B = la fila 8 girada dos veces
	and 004h		;42ca   ; izquierda
	or e			;42cc
	ld c,a			;42cd
	ld a,b			;42ce   ; derecha y ESPACIO a los bits 3 y 4
	rrca			;42cf   ; girada cuatro veces
	rrca			;42d0
	ld b,a			;42d1
	and 018h		;42d2   ; derecha y ESPACIO
	or c			;42d4
	ld c,a			;42d5
	ld a,b			;42d6   ; arriba y abajo a los bits 0 y 1
	rrca			;42d7   ; girada cinco veces
	and 003h		;42d8   ; arriba y abajo
	or c			;42da
	ret			;42db
limpia_pantalla:		; sprites fuera y la tabla de nombres (0x3800) a cero
	call sprites_fuera		;42dc   ; sprites fuera
	ld hl,03800h		;42df   ; 0x300 nombres a cero
	ld bc,00300h		;42e2   ; 0x300 nombres
	xor a			;42e5
	jp 00056h		;42e6   ; BIOS FILVRM - Fills VRAM with value
vram_escribe_desde:		; SETWRT en HL y en C' el puerto de escritura del VDP (0x0007)
	ex af,af'			;42e9   ; guarda A
	call 00053h		;42ea   ; BIOS SETWRT - Enables VDP to write | SETWRT
	exx			;42ed   ; en los registros alternativos...
	ld a,(00007h)		;42ee   ; el puerto de la BIOS
	ld c,a			;42f1   ; ...C' = el puerto
	exx			;42f2
	ex af,af'			;42f3
	ret			;42f4
vram_lee_desde:		; SETRD en HL y en C' el puerto de lectura del VDP (0x0006)
	call 00050h		;42f5   ; BIOS SETRD - Enables VDP to read
	exx			;42f8   ; en los alternativos...
	ld a,(00006h)		;42f9   ; ...el puerto de lectura de la BIOS...
	ld c,a			;42fc   ; ...en C'
	exx			;42fd
	ret			;42fe
copia_a_vram:		; LDIRVM de DE a la VRAM de HL, BC bytes
	ex de,hl			;42ff   ; HL = origen, DE = destino
	jp 0005ch		;4300   ; BIOS LDIRVM - Block transfers to VRAM from memory
copia_a_vram_x3:		; lo mismo en los tres tercios de la pantalla (0x800 de distancia)
	exx			;4303
	ld b,003h		;4304   ; tres tercios
L_4306:
	exx			;4306
	push bc			;4307
	push de			;4308
	call copia_a_vram		;4309   ; un tercio
	ld de,00800h		;430c   ; el siguiente
	add hl,de			;430f   ; 0x800 mas alla
	pop de			;4310
	pop bc			;4311
	exx			;4312
	djnz L_4306		;4313
	ret			;4315
rellena_vram_x3:		; FILVRM de A en HL, BC bytes, en los tres tercios
	ld d,003h		;4316   ; tres tercios
L_4318:
	push bc			;4318
	push de			;4319
	call 00056h		;431a   ; BIOS FILVRM - Fills VRAM with value | un tercio
	ld de,00800h		;431d   ; el siguiente
	add hl,de			;4320   ; 0x800 mas alla
	pop de			;4321
	pop bc			;4322
	dec d			;4323
	jr nz,L_4318		;4324
	ret			;4326
rle_a_vram_x3:		; el flujo RLE de DE en HL, en los tres tercios
	ld b,003h		;4327   ; tres tercios
L_4329:
	push bc			;4329
	push de			;432a
	call rle_a_vram_en_hl		;432b   ; un tercio
	ld de,00800h		;432e   ; el siguiente
	add hl,de			;4331   ; 0x800 mas alla
	pop de			;4332
	pop bc			;4333
	djnz L_4329		;4334
	ret			;4336
escribe_lista:		; escribe la lista de DE: palabra = direccion de VRAM, bytes hasta 0xFF; 0xFE trae otra direccion
	ld c,0ffh		;4337   ; C = 0xFF: tal cual
escribe_lista_and_c:		; la lista con cada byte AND C (C = 0: la borra)
	ex de,hl			;4339   ; HL = la direccion...
	ld e,(hl)			;433a   ; la palabra...
	inc hl			;433b
	ld d,(hl)			;433c
	ex de,hl			;433d   ; ...a HL
	inc de			;433e   ; ...DE = el primer byte
escribe_desde_hl:		; los bytes de DE en la VRAM de HL, AND C, hasta 0xFF; 0xFE trae otra direccion
	ld a,(de)			;433f   ; el byte
	inc de			;4340
	ld b,a			;4341
	inc b			;4342   ; 0xFF: se acabo
	ret z			;4343   ; 0xFF + 1 = 0
	inc b			;4344   ; 0xFE: otra direccion
	jr z,escribe_lista_and_c		;4345   ; 0xFE + 2 = 0
	and c			;4347   ; AND C...
	call 0004dh		;4348   ; BIOS WRTVRM - Writes data in VRAM | ...a la VRAM
	inc hl			;434b   ; la siguiente posicion
	jr escribe_desde_hl		;434c
borra_lista:		; la lista de DE con ceros
	ld c,000h		;434e   ; C = 0: ceros
	jr escribe_lista_and_c		;4350
rle_a_vram:		; el flujo RLE de DE: palabra = direccion de VRAM y luego los tramos
	ex de,hl			;4352   ; HL = la direccion
	ld e,(hl)			;4353   ; la palabra...
	inc hl			;4354
	ld d,(hl)			;4355
	ex de,hl			;4356   ; ...a HL
	inc de			;4357   ; DE = el primer tramo
rle_a_vram_en_hl:		; los tramos desde HL: n < 0x80 repite el byte siguiente n veces, 0x80 + n copia n bytes, 0x80 trae otra direccion, 0 acaba
	call vram_escribe_desde		;4358   ; SETWRT en HL, el puerto en C'
L_435B:
	ld a,(de)			;435b   ; el byte de control
	and a			;435c   ; 0: se acabo
	ret z			;435d
	inc de			;435e   ; el siguiente
	ld b,a			;435f
	and 07fh		;4360   ; bit 7 a cero:
	cp b			;4362
	jr z,L_4373		;4363   ; repeticion
	and a			;4365   ; 0x80:
	jr z,rle_a_vram		;4366   ; otra direccion
	ld b,a			;4368   ; 0x80 + n: n bytes tal cual
L_4369:
	ld a,(de)			;4369   ; un byte...
	inc de			;436a
	exx			;436b
	out (c),a		;436c   ; al VDP
	exx			;436e
	djnz L_4369		;436f   ; ...n veces
	jr L_435B		;4371
L_4373:
	ld a,(de)			;4373   ; el byte que se repite
	inc de			;4374   ; el siguiente
L_4375:
	exx			;4375
	out (c),a		;4376   ; al VDP
	exx			;4378
	djnz L_4375		;4379   ; n veces
	jr L_435B		;437b
prepara_el_programa:		; al salir del titulo: borra la RAM del programa, mira si hay disco, copia timbres y ondas de fabrica y trae los sprites
	ld hl,0c000h		;437d   ; 0xC000-0xD7FF a cero: ondas, timbres, LAYOUT
	ld bc,017ffh		;4380   ; 0x1800 bytes
	call borra_memoria		;4383
	ld hl,0d856h		;4386   ; 0xD856-0xDBFF a cero
	ld bc,003a9h		;4389   ; 0x3AA bytes
	call borra_memoria		;438c
	ld a,(0ffa7h)		;438f   ; H.PHYD (0xFFA7) todavia `ret`...
	cp 0c9h		;4392   ; `ret`: sin disco
	jr nz,L_439B		;4394
	ld a,001h		;4396   ; ...no hay disco: 0xD9DE = 1
	ld (0d9deh),a		;4398
L_439B:
	call timbres_y_ondas_de_fabrica		;439b   ; los 16 timbres de fabrica y las ondas
	call layout_de_fabrica		;439e   ; 0x4B21
	ld de,08000h		;43a1   ; los patrones de los sprites (0x8000)
	call rle_a_vram		;43a4   ; los patrones de los sprites (0x8000)
	ret			;43a7
borra_memoria:		; HL a HL + BC a cero
	ld d,h			;43a8   ; DE = HL + 1...
	ld e,l			;43a9
	inc e			;43aa
	ld (hl),000h		;43ab   ; ...el primero a cero...
	ldir		;43ad   ; ...y se arrastra
	ret			;43af
cortina_de_salida:		; borra una columna de la tabla de nombres por cuadro; M al acabar
	ld hl,0d804h		;43b0   ; la columna, contando hacia atras
	dec (hl)			;43b3   ; una columna menos
	ret m			;43b4   ; se acabo: M
	ld a,(hl)			;43b5   ; 0x3800 + (columna XOR 0x1F)
	ld h,038h		;43b6   ; la tabla de nombres
	xor 01fh		;43b8
	add a,000h		;43ba
	ld l,a			;43bc
	ld b,018h		;43bd   ; las 24 filas...
	xor a			;43bf
	ld de,00020h		;43c0   ; ...de 32 en 32
L_43C3:
	call 0004dh		;43c3   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;43c6
	djnz L_43C3		;43c7
sprites_fuera:		; la copia de los atributos (0xD870) a cero y 0xD0 en 0x3B00: no se ve ninguno
	ld hl,0d870h		;43c9   ; 0xD870-0xD8EF a cero
	ld bc,0007fh		;43cc   ; 0x80 bytes
	call borra_memoria		;43cf
	ld hl,03b00h		;43d2   ; 0xD0 en el primer sprite: corta la lista
	ld a,0d0h		;43d5   ; 0xD0: fin de la lista de sprites
	call 0004dh		;43d7   ; BIOS WRTVRM - Writes data in VRAM
	xor a			;43da
	ret			;43db
cifras:		; B cifras de DE hacia la izquierda desde HL, dos por byte (BCD), tile 0x10 + cifra
	ld c,010h		;43dc   ; tiles 0x10 + cifra
	jr L_43E2		;43de
cifras_40:		; igual con el tile 0x40 + cifra
	ld c,040h		;43e0   ; tiles 0x40 + cifra
L_43E2:
	ld a,(de)			;43e2   ; la cifra baja
	and 00fh		;43e3
	add a,c			;43e5
	call 0004dh		;43e6   ; BIOS WRTVRM - Writes data in VRAM
	dec b			;43e9   ; B cifras
	ret z			;43ea   ; la ultima
	dec hl			;43eb   ; a la izquierda
	ld a,(de)			;43ec   ; la alta
	rra			;43ed
	rra			;43ee
	rra			;43ef
	rra			;43f0
	and 00fh		;43f1
	add a,010h		;43f3   ; la alta siempre con 0x10
	call 0004dh		;43f5   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;43f8   ; el siguiente byte
	dec hl			;43f9
	djnz L_43E2		;43fa
	ret			;43fc
fuente:		; los tiles 0-15 a cero, la fuente de 0x4414 desde el tile 0x10 y su color 0xF0
	call tiles_0_15		;43fd   ; los tiles 0-15
	ld de,04414h		;4400   ; la fuente, patrones desde 0x2080
	ld hl,02080h		;4403   ; desde el tile 0x10
	call rle_a_vram_x3		;4406
	ld a,0f0h		;4409   ; su color, blanco sobre negro
	ld hl,00080h		;440b   ; los colores desde el tile 0x10
	ld bc,00158h		;440e   ; 0x158 bytes
	jp rellena_vram_x3		;4411

; ----------------------------------------------------------------------
; DATOS fuente_rle: la fuente: flujo RLE de 0x4327 hacia 0x2080 (tiles 0x10 en
;   adelante); 0x446E es una segunda entrada en el mismo flujo, desde la A
;   (tile 0x21), que usa 0xB392
;   0x4414..0x4536  (290 bytes)
DATA_fuente_rle:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,004h,018h,0c9h,07eh	; 4414  ..."ccc"...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh	; 4424  .>c..<p..>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h,003h,063h,03eh	; 4434  ...6ff....`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,006h,00ch,018h,018h,018h	; 4444  .>c`~cc>..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh	; 4454  .>cc>cc>.>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,028h,000h,004h,000h,001h,07eh,004h,000h	; 4464  <B....B<(....~..
	defb 0c1h,01ch,036h,063h,063h,07fh,063h,063h,000h,07eh,063h,063h,07eh,063h,063h,07eh	; 4474  ..6cc.cc.~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh,000h,07ch,066h,063h,063h,063h,066h,07ch	; 4484  .>c```c>.|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07fh,060h,060h,07eh,060h,060h,060h	; 4494  ..``~``...``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh,000h,063h,063h,063h,07fh,063h,063h,063h	; 44a4  .>c`gcc?.ccc.ccc
	defb 000h,03ch,005h,018h,083h,03ch,000h,01fh,004h,006h,08bh,066h,03ch,000h,063h,066h	; 44b4  .<...<.....f<.cf
	defb 06ch,078h,07ch,06eh,067h,000h,006h,060h,093h,07fh,000h,063h,077h,07fh,07fh,06bh	; 44c4  lx|ng..`...cw..k
	defb 063h,063h,000h,063h,073h,07bh,07fh,06fh,067h,063h,000h,03eh,005h,063h,0a3h,03eh	; 44d4  cc.cs{.ogc.>.c.>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h,000h,03eh,063h,063h,063h,06fh,066h,03dh	; 44e4  .~ccc~``.>cccof=
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh	; 44f4  .~ccb|fc.>c`>.c>
	defb 000h,07eh,006h,018h,001h,000h,006h,063h,082h,03eh,000h,004h,063h,0a3h,036h,01ch	; 4504  .~.....c.>..c.6.
	defb 008h,000h,063h,063h,06bh,06bh,07fh,077h,022h,000h,063h,076h,03ch,01ch,01eh,037h	; 4514  ..cckk.w".cv<..7
	defb 063h,000h,066h,066h,07eh,03ch,018h,018h,018h,000h,07fh,007h,00eh,01ch,038h,070h	; 4524  c.ff~<........8p
	defb 07fh,000h	; 4534

; ======================================================================
; CODIGO 0x4536..0x45b9  (131 bytes)
; ======================================================================


tiles_0_15:		; patrones de los tiles 0-15 a cero y sus colores 0x00, 0x01... uno por tile
	ld hl,02000h		;4536   ; patrones a cero
	ld bc,00080h		;4539   ; 16 tiles
	xor a			;453c
	call rellena_vram_x3		;453d
	ld hl,00000h		;4540   ; los colores: 16 tiles de 8 bytes
	ld de,00008h		;4543   ; de 8 en 8
	ld b,010h		;4546   ; 16 tiles
L_4548:
	push bc			;4548
	ld bc,00008h		;4549   ; un tile
	push hl			;454c
	call rellena_vram_x3		;454d
	pop hl			;4550
	add hl,de			;4551   ; el siguiente
	inc a			;4552   ; el siguiente color
	pop bc			;4553
	djnz L_4548		;4554
	ret			;4556
logo_konami:		; el logotipo de Konami: 0xD80E = 0 para su cortina
	ld hl,00000h		;4557   ; linea 0, fila 0
	ld (0d80eh),hl		;455a
logo_konami_tiles:		; los 120 tiles del logotipo (0x45B9), su color a cero y 20 x 6 nombres seguidos desde el 0x40
	ld de,045b9h		;455d   ; los patrones
	call rle_a_vram		;4560
	ld hl,00a00h		;4563   ; los colores a cero: no se ve
	ld bc,003c0h		;4566   ; 0x3C0 bytes
	xor a			;4569
	call 00056h		;456a   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03907h		;456d   ; en la tabla de nombres, desde 0x3907...
	ld a,040h		;4570   ; ...los tiles 0x40 en adelante...
	ld c,006h		;4572   ; ...6 filas...
	ld de,0000ch		;4574   ; al final de la fila, 12 mas
L_4577:
	ld b,014h		;4577   ; ...de 20
L_4579:
	call 0004dh		;4579   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;457c   ; el tile siguiente...
	inc a			;457d   ; ...con el numero siguiente
	djnz L_4579		;457e
	add hl,de			;4580   ; la fila siguiente
	dec c			;4581   ; la fila siguiente
	jr nz,L_4577		;4582
	ret			;4584
cortina_logo_konami:		; pinta 0xF0 en una linea de los 20 tiles de la fila 0xD80F; Z al acabar las seis filas
	ld bc,(0d80eh)		;4585   ; C = linea, B = fila
	ld a,0ech		;4589   ; A = 20 * fila
	inc b			;458b
L_458C:
	add a,014h		;458c   ; 20 por fila
	djnz L_458C		;458e
	ld l,a			;4590   ; por 8, desde los colores 0x0A00
	ld h,b			;4591
	add hl,hl			;4592   ; por 8
	add hl,hl			;4593
	add hl,hl			;4594
	ld de,00a00h		;4595   ; desde 0x0A00
	add hl,de			;4598
	ld a,c			;4599   ; mas la linea
	call hl_mas_a		;459a
	ld b,014h		;459d   ; 20 tiles...
	ld de,00008h		;459f   ; de 8 en 8: la misma linea de cada tile
	ld a,0f0h		;45a2   ; ...en blanco sobre negro
L_45A4:
	call 0004dh		;45a4   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;45a7
	djnz L_45A4		;45a8
	ld hl,0d80eh		;45aa   ; la linea siguiente
	ld a,(hl)			;45ad   ; la linea siguiente...
	inc a			;45ae
	and 007h		;45af   ; ...de 0 a 7
	ld (hl),a			;45b1
	ret nz			;45b2
	inc hl			;45b3   ; y la fila
	inc (hl)			;45b4   ; la fila siguiente
	ld a,(hl)			;45b5
	cp 006h		;45b6   ; 6 filas
	ret			;45b8

; ----------------------------------------------------------------------
; DATOS logo_konami_patrones: flujo RLE de 0x4352 hacia 0x2A00: los 120 tiles
;   (20 x 6) del logotipo de Konami
;   0x45b9..0x4708  (335 bytes)
DATA_logo_konami_patrones:
	defb 000h,02ah,018h,000h,002h,007h,003h,00fh,002h,01fh,081h,03fh,008h,0ffh,002h,0f8h	; 45b9  .*.........?....
	defb 003h,0f0h,003h,0e0h,07fh,000h,005h,000h,087h,001h,003h,00fh,07fh,03fh,07fh,07fh	; 45c9  .............?..
	defb 00ah,0ffh,082h,0fch,0f0h,003h,0c0h,002h,080h,077h,000h,083h,001h,003h,007h,003h	; 45d9  .........w......
	defb 00fh,081h,03fh,009h,0ffh,087h,0feh,0fch,0f8h,0f8h,0f0h,0f8h,0c0h,00bh,000h,002h	; 45e9  ..?.............
	defb 001h,083h,003h,07fh,07fh,00bh,0ffh,002h,0feh,083h,0fch,080h,080h,006h,000h,002h	; 45f9  ................
	defb 03ch,002h,078h,092h,079h,0f3h,0f7h,0ffh,01fh,03eh,07ch,0f9h,0f3h,0e3h,0c3h,087h	; 4609  <.x.y....>|.....
	defb 01fh,07fh,0f8h,0f0h,0e0h,0e0h,003h,0c0h,084h,0f0h,0f8h,078h,078h,003h,079h,002h	; 4619  ...........xx.y.
	defb 07fh,083h,0ffh,0f7h,0f7h,003h,0e7h,002h,00fh,003h,01eh,003h,03ch,088h,003h,007h	; 4629  ............<...
	defb 00fh,00eh,01eh,03ch,038h,078h,005h,0e0h,003h,0e1h,002h,07eh,083h,0feh,0f6h,0f6h	; 4639  ...<8x.....~....
	defb 003h,0eeh,002h,00fh,088h,01fh,01dh,03dh,03bh,07bh,073h,0f1h,0f1h,003h,0e3h,003h	; 4649  .......=;{s.....
	defb 0c7h,002h,0e0h,003h,0c0h,003h,080h,003h,01fh,003h,03fh,002h,07fh,008h,0ffh,083h	; 4659  ..........?.....
	defb 0f0h,0e0h,0e0h,003h,0c0h,002h,080h,007h,000h,087h,007h,003h,007h,007h,00fh,01fh	; 4669  ................
	defb 03fh,009h,0ffh,089h,0f8h,0fch,0f8h,0f8h,0f0h,0e0h,0c0h,000h,000h,003h,001h,003h	; 4679  ?...............
	defb 003h,002h,007h,088h,0efh,0e7h,0e7h,0c7h,0c7h,0c3h,083h,083h,003h,087h,003h,0c7h	; 4689  ................
	defb 092h,0e3h,0e0h,080h,080h,081h,081h,083h,0c7h,0ffh,0feh,0fbh,0f3h,0f3h,0f7h,0e7h	; 4699  ................
	defb 0c7h,08fh,00fh,003h,0c7h,003h,087h,002h,007h,002h,078h,088h,079h,0f1h,0f3h,0f7h	; 46a9  ..........x.y...
	defb 0e7h,0efh,070h,0f0h,003h,0ffh,002h,081h,081h,001h,003h,0e3h,003h,0e7h,002h,0efh	; 46b9  ..p.............
	defb 002h,0ceh,081h,0cfh,003h,08fh,002h,00fh,088h,0f7h,0e7h,0c7h,0cfh,08fh,08fh,01eh	; 46c9  ................
	defb 01eh,003h,08fh,003h,01eh,002h,03ch,019h,000h,085h,003h,00fh,01fh,03fh,07fh,00bh	; 46d9  ......<......?..
	defb 0ffh,086h,0fch,0f0h,0e0h,0c0h,080h,080h,07fh,000h,002h,000h,003h,001h,003h,003h	; 46e9  ................
	defb 002h,007h,009h,0ffh,002h,0feh,003h,0fch,002h,0f8h,07fh,000h,081h,000h,000h	; 46f9  ...............

; ======================================================================
; CODIGO 0x4708..0x4805  (253 bytes)
; ======================================================================


logo_sizer_entero:		; los patrones del logotipo 新世SIZER (0x9E97) de una vez
	ld de,09e97h		;4708   ; 0x428 bytes de 0x9E97...
	ld hl,02200h		;470b   ; ...a los patrones de 0x2200
	ld bc,00428h		;470e   ; 0x428 bytes en los tres tercios
	call copia_a_vram_x3		;4711
logo_sizer_pantalla:		; borde 0xE0, pantalla limpia, la fuente y los colores del logotipo (0xA2BF)
	ld b,0e0h		;4714   ; R7 = 0xE0
	call color_de_borde		;4716
	call limpia_pantalla		;4719   ; sprites fuera y nombres a cero
	call fuente		;471c   ; la fuente
	ld a,070h		;471f   ; 0x70 en los colores de la zona del logotipo
	ld hl,00248h		;4721   ; desde 0x0248...
	ld bc,00368h		;4724   ; ...0x368 bytes
	call rellena_vram_x3		;4727
	ld hl,00620h		;472a   ; 0x0620...
	ld bc,00008h		;472d   ; ...8 bytes
	call rellena_vram_x3		;4730
	ld a,0e0h		;4733   ; y 0xE0 en otra franja
	ld hl,005b0h		;4735   ; 0x05B0...
	ld bc,00070h		;4738   ; ...0x70 bytes
	call rellena_vram_x3		;473b
	ld de,0a2bfh		;473e   ; los colores del logotipo, en RLE
	ld hl,00200h		;4741   ; desde 0x0200
	jp rle_a_vram_x3		;4744
titulo_de_golpe:		; el logotipo entero, sus nombres y el rotulo, sin pinceladas
	call logo_sizer_entero		;4747   ; los patrones
	call logo_sizer_nombres		;474a   ; los nombres
	ld de,0be75h		;474d   ; el rotulo de 0xBE75
	call escribe_lista		;4750   ; el rotulo
	ret			;4753
logo_sizer_nombres:		; la tabla de nombres del logotipo (0xA2E5)
	ld de,0a2e5h		;4754   ; el flujo de los nombres
	jp rle_a_vram		;4757
efectos_por_cuadro:		; los efectos de sonido: R7 = 0xB8 y los tres canales de 0xD810, 5 bytes cada uno
	ld e,0b8h		;475a   ; R7 = 0xB8...
	ld a,007h		;475c   ; ...los tres tonos, sin ruido
	call 00093h		;475e   ; BIOS WRTPSG - Writes data to PSG-register
	ld c,001h		;4761   ; C = 1: el registro de tono grueso del canal A
	ld ix,0d810h		;4763   ; los tres canales, 5 bytes cada uno
	exx			;4767
	ld b,003h		;4768   ; tres canales
	ld de,00005h		;476a   ; de 5 en 5 bytes
L_476D:
	exx			;476d
	ld a,(ix+002h)		;476e   ; (IX+2): canal activo
	or a			;4771
	call nz,efecto_canal		;4772   ; activo: su nota
	inc c			;4775   ; los registros del canal siguiente
	inc c			;4776
	exx			;4777
	add ix,de		;4778   ; el canal siguiente
	djnz L_476D		;477a
	ret			;477c
mezclador_psg:		; R7 del PSG = A (y copia en 0xD81F)
	ld (0d81fh),a		;477d
	ld e,a			;4780   ; R7 del PSG...
	ld a,007h		;4781
	jp 00093h		;4783   ; BIOS WRTPSG - Writes data to PSG-register
efecto_canal:		; un canal: cuando acaba la cuenta (IX+0), la nota siguiente de la lista (IX+3)
	ld a,(ix+002h)		;4786   ; (sin uso)
	dec (ix+000h)		;4789   ; la cuenta de la nota
	ret nz			;478c   ; quedan cuadros
	ld l,(ix+003h)		;478d   ; HL = la lista
	ld h,(ix+004h)		;4790
	ld a,(hl)			;4793   ; el byte de la lista
	cp 0ffh		;4794   ; 0xFF: se acabo
	jr z,efecto_acabado		;4796
	and 0f0h		;4798   ; 0x2n: n = duracion de las notas (IX+1)
	cp 020h		;479a   ; 0x2n?
	jr nz,L_47A5		;479c
	ld a,(hl)			;479e
	and 00fh		;479f   ; n...
	ld (ix+001h),a		;47a1   ; ...duracion de cada nota
	inc hl			;47a4
L_47A5:
	ld a,(hl)			;47a5   ; alto: volumen; bajo: tono grueso...
	and 0f0h		;47a6
	ld b,a			;47a8   ; B = volumen << 4
	xor (hl)			;47a9   ; D = tono grueso
	ld d,a			;47aa
	inc hl			;47ab   ; E = tono fino
	ld e,(hl)			;47ac   ; ...y el byte siguiente, el fino
	inc hl			;47ad
	ld (ix+003h),l		;47ae   ; la lista avanza
	ld (ix+004h),h		;47b1   ; la lista avanza
	ex de,hl			;47b4   ; H = grueso, L = fino
	ld a,c			;47b5   ; tono grueso en el registro C
	ld e,h			;47b6   ; E = grueso
	call 00093h		;47b7   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;47ba   ; y el fino en C - 1
	dec a			;47bb   ; C - 1: el registro fino
	ld e,l			;47bc   ; E = fino
	call 00093h		;47bd   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,b			;47c0   ; el volumen al nibble bajo
	rrca			;47c1   ; el volumen...
	rrca			;47c2
	rrca			;47c3
	rrca			;47c4
	ld h,a			;47c5   ; ...a H
	ld a,(ix+001h)		;47c6   ; la cuenta, otra vez la duracion
	ld (ix+000h),a		;47c9   ; la cuenta = la duracion
	jr volumen_del_canal		;47cc
efecto_acabado:		; canal inactivo y volumen a cero
	xor a			;47ce
	ld (ix+002h),a		;47cf   ; inactivo
	ld h,a			;47d2   ; volumen 0
volumen_del_canal:		; registro 8 + C / 2 = H
	ld a,c			;47d3
	rrca			;47d4   ; C = 1, 3, 5 -> registros 8, 9, 10
	add a,088h		;47d5   ; el registro de volumen
	ld e,h			;47d7   ; E = el volumen
	jp 00093h		;47d8   ; BIOS WRTPSG - Writes data to PSG-register
fase_programa:		; cada cuadro del programa: la pantalla en curso y los sprites a la VRAM
	call pantalla_en_curso		;47db   ; la pantalla en curso
sprites_a_vram:		; la copia de los atributos (0xD870) a 0x3B00, 128 bytes
	ld hl,03b00h		;47de   ; destino 0x3B00...
	ld de,0d870h		;47e1   ; ...origen 0xD870...
	ld bc,00080h		;47e4   ; ...128 bytes
	ex de,hl			;47e7
	jp 0005ch		;47e8   ; BIOS LDIRVM - Block transfers to VRAM from memory
pantalla_en_curso:		; lee el teclado, cambia de pantalla con F1-F5 y SHIFT, y salta a la de 0xD8F4
	ld a,(0d904h)		;47eb   ; 0xD904: SYN en marcha, nada
	or a			;47ee
	ret nz			;47ef   ; ocupado
	call tecla_de_la_matriz		;47f0   ; la tecla
	ld a,(0d901h)		;47f3   ; 0xD901: cambiando de pantalla
	or a			;47f6
	jr nz,L_47FF		;47f7   ; sin cambiar de pantalla
	call shift_cambia_menu		;47f9   ; SHIFT: la otra pagina del menu
	call cambio_de_pantalla		;47fc   ; F1-F5: otra pantalla
L_47FF:
	ld a,(0d8f4h)		;47ff   ; la pantalla
	call salta_por_tabla		;4802   ; a la pantalla 0xD8F4

; ----------------------------------------------------------------------
; DATOS saltos_por_pantalla: 9 destinos por (0xD8F4), la pantalla en curso;
;   cierra en 0x4817, que llama 0x47F0
;   0x4805..0x4817  (18 bytes)
DATA_saltos_por_pantalla:
	defw 0a5aah,0adf7h,048d9h,0490bh,0b5dbh,0b3afh,0b5c8h,052b7h	; 4805
	defw 0bb6dh	; 4815  -> pantalla_layout

; ======================================================================
; CODIGO 0x4817..0x48f4  (221 bytes)
; ======================================================================


tecla_de_la_matriz:		; la primera tecla pulsada como fila * 8 + bit + 1 en 0xD8F2; 0xD8F1 = la nueva; 0xD8F3 con repeticion
	ld a,(0d802h)		;4817   ; solo con el programa en marcha
	and 040h		;481a   ; el programa en marcha?
	ret z			;481c
	ld b,000h		;481d   ; las filas 0 a 8
L_481F:
	ld a,b			;481f   ; la fila B
	call 00141h		;4820   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4823   ; pulsadas a 1
	or 000h		;4824
	jr nz,L_4831		;4826   ; una tecla en esta fila
	inc b			;4828   ; la fila siguiente
	ld a,b			;4829
	cp 009h		;482a   ; hasta la 8
	jr c,L_481F		;482c
	xor a			;482e   ; ninguna: 0
	jr L_4842		;482f
L_4831:
	ld d,b			;4831   ; D = la fila
	ld b,008h		;4832   ; 8 bits
	ld c,000h		;4834
L_4836:
	inc c			;4836   ; C = bit + 1
	rrca			;4837   ; el bit siguiente al acarreo
	jr c,L_483D		;4838
	djnz L_4836		;483a
	ret			;483c
L_483D:
	ld a,d			;483d   ; fila * 8 + C
	rlca			;483e   ; la fila * 8
	rlca			;483f
	rlca			;4840
	add a,c			;4841   ; + bit + 1
L_4842:
	ld hl,0d8f2h		;4842   ; 0xD8F2: la de ahora
	ld b,a			;4845
	ld c,(hl)			;4846   ; la de antes
	ld (hl),a			;4847   ; la de ahora
	cp c			;4848   ; la misma que antes:
	jr nz,L_484C		;4849
	xor a			;484b   ; no es nueva
L_484C:
	dec hl			;484c   ; 0xD8F1: la nueva
	ld (hl),a			;484d   ; la nueva (o 0)
	ld de,0d8fdh		;484e   ; 0xD8FD: la que se repite y su cuenta
repeticion:		; (HL + 2) = la tecla nueva o, tenida mas de 0x28 cuadros, la de ahora en cada cuadro
	ld c,a			;4851   ; C = la nueva
	inc hl			;4852   ; la de ahora
	cp (hl)			;4853   ; nueva?
	ld b,(hl)			;4854
	inc hl			;4855   ; donde va la repetida
	jr z,L_4866		;4856
	ld a,(de)			;4858   ; la misma que se tenia...
	cp b			;4859   ; la que se repite?
	jr nz,L_4866		;485a
	inc de			;485c   ; su cuenta
	ld a,(de)			;485d   ; ...mas de 0x28 cuadros:
	cp 028h		;485e   ; 0x28 cuadros?
	jr nc,L_486B		;4860   ; repite
	inc a			;4862   ; cuenta un cuadro
	ld (de),a			;4863   ; uno mas
	ld (hl),c			;4864   ; todavia: la nueva (0)
	ret			;4865
L_4866:
	ld a,b			;4866   ; otra tecla: la apunta y la cuenta a cero
	ld (de),a			;4867   ; la apunta
	inc de			;4868
	xor a			;4869   ; cuenta a cero
	ld (de),a			;486a
L_486B:
	ld (hl),b			;486b   ; repite la de ahora
	ret			;486c
cambio_de_pantalla:		; F1-F5 (0x36-0x3A) en 0xD8F1
	ld a,(0d802h)		;486d   ; el programa en marcha?
	and 040h		;4870
	ret z			;4872
	ld hl,0d8f1h		;4873   ; la tecla nueva
	ld a,(hl)			;4876
pantalla_por_tecla:		; A = codigo de F1-F5: la pantalla 0-4, o 5-8 en la segunda pagina del menu
	cp 036h		;4877   ; antes de F1...
	ret c			;4879   ; antes de F1
	cp 03bh		;487a   ; ...o despues de F5: nada
	ret nc			;487c   ; despues de F5
	sub 036h		;487d   ; 0 a 4
	ld c,a			;487f
	ld a,(0d8f0h)		;4880   ; la segunda pagina...
	or a			;4883   ; la primera pagina del menu
	jr z,L_488D		;4884
	ld a,005h		;4886   ; ...suma 5, hasta la 8
	add a,c			;4888
	ld c,a			;4889
	cp 009h		;488a   ; como mucho la 8
	ret nc			;488c
L_488D:
	ld a,(0d8f4h)		;488d   ; 0xD8FB: la de antes
	ld (0d8fbh),a		;4890
	ld a,(0d8fah)		;4893   ; 0xD8F5: su estado
	ld (0d8f5h),a		;4896
	ld a,c			;4899   ; 0xD8F4: la nueva
	ld (0d8f4h),a		;489a
	xor a			;489d   ; estado 0
	ld (0d8fah),a		;489e
	ld a,020h		;48a1   ; 0xD804 = 0x20
	ld (0d804h),a		;48a3
	ld a,005h		;48a6   ; el efecto 5
	call efecto		;48a8   ; el efecto 5
	ret			;48ab
shift_cambia_menu:		; SHIFT (0x31) recien pulsada
	ld a,(0d8f1h)		;48ac
	cp 031h		;48af   ; SHIFT?
	ret nz			;48b1
cambia_menu:		; 0xD8F0 pasa de 0 a 1 o de 1 a 0
	ld a,(0d802h)		;48b2
	and 040h		;48b5   ; el programa en marcha?
	ret z			;48b7
	ld hl,0d8f0h		;48b8
	ld a,(hl)			;48bb   ; la pagina del menu
	or a			;48bc
	jr nz,L_48C2		;48bd
	inc a			;48bf   ; 0 -> 1
	jr L_48C3		;48c0
L_48C2:
	xor a			;48c2   ; 1 -> 0
L_48C3:
	ld (hl),a			;48c3
pinta_menu:		; las dos filas de abajo (0x3AC0): el menu 0x8A41, o 0x8A81 en la segunda pagina
	ld a,(0d8f0h)		;48c4
	ld de,08a41h		;48c7   ; el menu de la primera pagina...
	and a			;48ca
	jr z,L_48D0		;48cb
	ld de,08a81h		;48cd   ; ...o de la segunda
L_48D0:
	ld hl,03ac0h		;48d0   ; en las filas 22 y 23
	ld bc,00040h		;48d3   ; 64 bytes
	jp copia_a_vram		;48d6
pantalla_syn:		; SYN: la cortina, el teclado, y 0xD8F6 = 2 para que el bucle principal sintetice (0x4BA1)
	call cortina_y_teclado		;48d9   ; la cortina; M al acabar
	ret p			;48dc   ; sin acabar
	ld de,048f4h		;48dd   ; el rotulo de SYN (0x48F4)
	call rle_a_vram		;48e0
	ld hl,04cd4h		;48e3   ; sus sprites (0x4CD4) a la copia
	ld de,0d870h		;48e6   ; a la copia de los atributos
	ld bc,00010h		;48e9   ; 16 bytes
	ldir		;48ec
	ld a,002h		;48ee   ; pide la sintesis
	ld (0d8f6h),a		;48f0
	ret			;48f3

; ----------------------------------------------------------------------
; DATOS menu_de_abajo_syn: flujo RLE de 0x4352 hacia 0x3AC0: las dos filas de
;   abajo en SYN
;   0x48f4..0x490b  (23 bytes)
DATA_menu_de_abajo_syn:
	defb 0c0h,03ah,007h,000h,082h,014h,015h,00eh,01ah,081h,02bh,00fh,000h,082h,024h,025h	; 48f4  .:........+...$%
	defb 00eh,02ah,081h,02ch,008h,000h,000h	; 4904

; ======================================================================
; CODIGO 0x490b..0x4946  (59 bytes)
; ======================================================================


pantalla_play:		; PLAY: la primera vez prepara la pantalla; luego, si el programa esta en marcha, toca (0x5D3A)
	ld a,(0d8fah)		;490b   ; 0xD8FA: estado de la pantalla
	dec a			;490e   ; 0: preparar
	jp m,play_prepara		;490f
	ld a,(0d802h)		;4912   ; el programa en marcha?
	and 040h		;4915
	ret z			;4917
	jp play		;4918   ; a tocar
play_prepara:		; la cortina, el teclado y los sprites de PLAY (0x4946)
	call cortina_y_teclado		;491b
	ret p			;491e   ; sin acabar
	call fuente_letras		;491f   ; 0xB392
	ld hl,04946h		;4922   ; los sprites
	ld de,0d870h		;4925   ; a la copia
	ld bc,00008h		;4928
	ldir		;492b
	xor a			;492d   ; 0xD907 = 0
	ld (0d907h),a		;492e
	ld hl,0d8fah		;4931   ; estado 1
	inc (hl)			;4934
	ret			;4935
cortina_y_teclado:		; la cortina de salida y, al acabar, la pantalla del teclado; M al acabar
	call empieza_cambio		;4936   ; cambiando de pantalla
	call cortina_de_salida		;4939   ; una columna
	ret p			;493c   ; quedan columnas
	call pantalla_teclado		;493d   ; la pantalla nueva
	call fin_de_cambio		;4940   ; ya no se esta cambiando
	xor a			;4943   ; M
	dec a			;4944   ; A = 0xFF: M
	ret			;4945

; ----------------------------------------------------------------------
; DATOS sprite_cursor: dos sprites de 4 bytes (y, x, patron, color) que copia
;   0x4922
;   0x4946..0x494e  (8 bytes)
DATA_sprite_cursor:
	defb 056h,019h,060h,000h	; 4946
	defb 056h,019h,064h,000h	; 494a

; ======================================================================
; CODIGO 0x494e..0x4b00  (434 bytes)
; ======================================================================


pantalla_teclado:		; el teclado de PLAY y SYN, y en cada tecla el nombre de su timbre segun el LAYOUT (0xD200)
	call pantalla_apagada		;494e   ; pantalla apagada
	call menu_cifras_y_marco		;4951   ; lo comun
	ld de,0925ah		;4954   ; patrones y colores del teclado
	ld hl,02080h		;4957   ; los patrones del teclado...
	call rle_a_vram_x3		;495a
	ld de,092f4h		;495d   ; ...otros...
	ld hl,02458h		;4960
	call rle_a_vram_x3		;4963
	ld de,09559h		;4966   ; ...los colores...
	ld hl,00080h		;4969
	call rle_a_vram_x3		;496c
	ld de,095eah		;496f   ; ...y mas colores
	ld hl,00458h		;4972
	call rle_a_vram_x3		;4975
	ld a,(0002ch)		;4978   ; (0x002C) de la BIOS: el juego de caracteres
	and 00fh		;497b   ; el juego de caracteres
	jr z,L_4991		;497d   ; japones (0): sin el dibujo de 0x97FD
	ld de,097fdh		;497f   ; el dibujo para los teclados no japoneses
	ld hl,02600h		;4982
	call rle_a_vram_x3		;4985
	ld de,098dfh		;4988
	ld hl,00600h		;498b
	call rle_a_vram_x3		;498e
L_4991:
	ld de,09988h		;4991   ; los nombres del teclado
	call rle_a_vram		;4994   ; los nombres
	ld hl,0d200h		;4997   ; el LAYOUT, una entrada por tecla
	ld a,001h		;499a   ; las teclas 1 a 0x30
L_499C:
	push af			;499c
	ld b,0ffh		;499d   ; la entrada en 0xBCCA...
	ld de,0bccah		;499f   ; busca la entrada en 0xBCCA...
L_49A2:
	inc b			;49a2
	ld a,(de)			;49a3
	inc de			;49a4
	cp (hl)			;49a5   ; ...que es la del LAYOUT
	jr nz,L_49A2		;49a6
	ld a,b			;49a8   ; ...su indice a 0xD905
	ld (0d905h),a		;49a9   ; 0xD905
	pop af			;49ac
	push af			;49ad
	push hl			;49ae
	call nombre_de_nota		;49af   ; la escribe en su tecla
	pop hl			;49b2
	pop af			;49b3
	inc a			;49b4   ; la tecla siguiente
	cp 016h		;49b5   ; la 0x16 no esta
	jr nz,L_49BB		;49b7
	inc a			;49b9   ; la 0x16 se salta...
	inc hl			;49ba   ; ...y su entrada
L_49BB:
	inc hl			;49bb
	cp 031h		;49bc   ; hasta la 0x30
	jr c,L_499C		;49be
	call pantalla_encendida		;49c0   ; pantalla encendida
	ret			;49c3
fin_de_cambio:		; 0xD901 = 0
	xor a			;49c4
	jr L_49C9		;49c5
empieza_cambio:		; 0xD901 = 1
	ld a,001h		;49c7
L_49C9:
	ld (0d901h),a		;49c9   ; 0xD901
	ret			;49cc
L_49CD:
	exx			;49cd
	push af			;49ce
	ld de,00000h		;49cf   ; el registro A del cargador: 6 bytes por entrada
	ld hl,05800h		;49d2   ; la tabla de 0x5800
	ld c,a			;49d5
	and 03fh		;49d6   ; la entrada
	ld b,a			;49d8
	or a			;49d9
	jr z,L_49E0		;49da
L_49DC:
	ld e,006h		;49dc   ; por 6
	djnz L_49DC		;49de
L_49E0:
	add hl,de			;49e0
	ld e,(hl)			;49e1   ; origen, destino y longitud
	inc hl			;49e2   ; DE = origen
	ld d,(hl)			;49e3
	push de			;49e4
	inc hl			;49e5
	ld e,(hl)			;49e6   ; destino...
	inc hl			;49e7
	ld d,(hl)			;49e8
	inc hl			;49e9
	ld c,(hl)			;49ea   ; ...y longitud
	inc hl			;49eb
	ld b,(hl)			;49ec
	pop hl			;49ed
	ld a,c			;49ee   ; los dos bits altos de la longitud dicen como:
	and 0c0h		;49ef
	jr z,L_49FF		;49f1
	cp 040h		;49f3
	jr c,L_4A04		;49f5
	cp 080h		;49f7
	jr c,L_4A09		;49f9
	cp 0c0h		;49fb
	jr c,L_4A0E		;49fd
L_49FF:
	call copia_a_vram		;49ff   ; copia
	jr L_4A11		;4a02
L_4A04:
	call rle_a_vram		;4a04   ; RLE
	jr L_4A11		;4a07
L_4A09:
	call copia_a_vram_x3		;4a09   ; copia en los tres tercios
	jr L_4A11		;4a0c
L_4A0E:
	call rellena_vram_x3		;4a0e   ; relleno en los tres tercios
L_4A11:
	pop af			;4a11
	exx			;4a12
	ret			;4a13
tecla_pulsada:		; la tecla 0xDC47 se pinta hundida en el teclado (0xD8F8 = 1)
	ld a,00ah		;4a14   ; colores de la tecla hundida...
	ld (0d873h),a		;4a16
	ld a,001h		;4a19   ; ...en los sprites 0 y 1
	ld (0d877h),a		;4a1b
	ld a,001h		;4a1e   ; pulsada
	jr L_4A2A		;4a20
tecla_soltada:		; la tecla 0xDC47 vuelve a su dibujo (0xD8F8 = 0)
	xor a			;4a22   ; sin color
	ld (0d873h),a		;4a23
	ld (0d877h),a		;4a26
	xor a			;4a29   ; soltada
L_4A2A:
	ld (0d8f8h),a		;4a2a
	call entrada_del_layout		;4a2d   ; su entrada del LAYOUT
	ld a,(hl)			;4a30   ; la entrada
	or a			;4a31   ; ninguna: nada
	ret z			;4a32
	cp 013h		;4a33   ; 0x13 o mas: tecla negra
	jr c,L_4A9C		;4a35
	sub 013h		;4a37   ; la tecla negra...
	add a,044h		;4a39   ; ...su columna...
	ld e,a			;4a3b
	ld d,039h		;4a3c   ; ...en la fila 0x39xx
	ex de,hl			;4a3e
	call vram_para_escribir		;4a3f   ; direccion de VRAM
	ld b,001h		;4a42   ; un byte...
	ld de,04b63h		;4a44   ; ...de 0x4B63 o 0x4B64
	ld a,(0d8f8h)		;4a47
	or a			;4a4a
	jr nz,L_4A4E		;4a4b
	inc de			;4a4d
L_4A4E:
	ld a,(00007h)		;4a4e   ; el puerto de escritura
	ld c,a			;4a51
L_4A52:
	ld a,(de)			;4a52
	out (c),a		;4a53   ; a la VRAM
	inc de			;4a55
	djnz L_4A52		;4a56
	ld a,(0d8f8h)		;4a58   ; soltada: el nombre otra vez
	or a			;4a5b   ; soltada
	jr z,nombre_en_la_tecla		;4a5c
	call tapa_nombre		;4a5e   ; pulsada: lo tapa
	call entrada_del_layout		;4a61   ; la entrada
	ld de,0d870h		;4a64   ; y los sprites de la tecla en la copia
	ld a,(hl)			;4a67
	cp 013h		;4a68
	jr c,L_4A85		;4a6a
	sub 013h		;4a6c   ; negra: X = 0x19 + 7 * n
	jr z,L_4A75		;4a6e
	ld b,a			;4a70
L_4A71:
	add a,007h		;4a71
	djnz L_4A71		;4a73
L_4A75:
	ex de,hl			;4a75
	ld (hl),056h		;4a76   ; Y = 0x56...
	inc hl			;4a78
	add a,019h		;4a79
	ld (hl),a			;4a7b   ; ...X
	inc hl			;4a7c
	inc hl			;4a7d
	inc hl			;4a7e
	ld (hl),056h		;4a7f   ; el segundo sprite igual
	inc hl			;4a81
	ld (hl),a			;4a82
	jr L_4A99		;4a83
L_4A85:
	ex de,hl			;4a85
	ld (hl),041h		;4a86   ; blanca: Y = 0x41...
	dec a			;4a88
	ld de,04b2dh		;4a89   ; ...X de 0x4B2D
	call de_mas_a		;4a8c
	inc hl			;4a8f
	ld a,(de)			;4a90
	ld (hl),a			;4a91
	inc hl			;4a92
	inc hl			;4a93
	inc hl			;4a94
	ld (hl),041h		;4a95   ; el segundo sprite igual
	inc hl			;4a97
	ld (hl),a			;4a98
L_4A99:
	jp sprites_a_vram		;4a99   ; a la VRAM
L_4A9C:
	dec a			;4a9c   ; tecla blanca: su sitio en 0x4B3F
	add a,a			;4a9d
	ld hl,04b3fh		;4a9e   ; dos bytes por tecla
	call hl_mas_a		;4aa1
	ld d,038h		;4aa4   ; la fila 0x38xx...
	ld e,(hl)			;4aa6   ; ...y la columna
	inc hl			;4aa7
	ld a,(0d8f8h)		;4aa8   ; pulsada o suelta
	or a			;4aab   ; soltada:
	jr nz,L_4AB3		;4aac
	ld a,(hl)			;4aae   ; ...el dibujo de 6 mas alla
	add a,006h		;4aaf
	jr L_4AB4		;4ab1
L_4AB3:
	ld a,(hl)			;4ab3   ; pulsada
L_4AB4:
	ld hl,04b65h		;4ab4   ; los tiles de 0x4B65
	call hl_mas_a		;4ab7
	ex de,hl			;4aba
	call vram_para_escribir		;4abb   ; la direccion al VDP
	ld b,002h		;4abe   ; dos tiles
	jr L_4A4E		;4ac0
nombre_en_la_tecla:		; escribe en la tecla el nombre de su timbre, con el cartucho en la pagina 2 mientras tanto
	call cartucho_en_la_pagina_2		;4ac2   ; los graficos estan en el cartucho
	ld a,(0dc47h)		;4ac5   ; la tecla
	call sitio_de_tecla		;4ac8
	ld a,(de)			;4acb   ; su entrada del LAYOUT
	or a			;4acc
	ret z			;4acd   ; sin nota: nada
	push hl			;4ace
	ld hl,0bccah		;4acf   ; su indice en 0xBCCA
	ld b,0ffh		;4ad2
L_4AD4:
	inc b			;4ad4   ; su indice...
	cp (hl)			;4ad5
	inc hl			;4ad6
	jr nz,L_4AD4		;4ad7
	ld a,b			;4ad9
	ld (0d905h),a		;4ada   ; ...a 0xD905
	pop hl			;4add
	call nombre_de_nota_d905		;4ade   ; la escribe
	jp ram_en_la_pagina_2		;4ae1   ; la RAM otra vez
tapa_nombre:		; tapa el nombre de la tecla con los tiles de 0x4B00 y 0x4B02
	call cartucho_en_la_pagina_2		;4ae4
	ld a,(0dc47h)		;4ae7   ; la tecla
	call sitio_de_tecla		;4aea
	ld de,04b00h		;4aed   ; dos tiles arriba...
	call dos_tiles		;4af0
	ld de,00020h		;4af3   ; ...y dos debajo
	add hl,de			;4af6
	ld de,04b02h		;4af7
	call dos_tiles		;4afa
	jp ram_en_la_pagina_2		;4afd

; ----------------------------------------------------------------------
; DATOS tiles_marcador: dos pares de tiles que escribe 0xBC37 (0x4AED y
;   0x4AF7)
;   0x4b00..0x4b04  (4 bytes)
DATA_tiles_marcador:
	defb 010h,011h	; 4b00
	defb 012h,013h	; 4b02

; ======================================================================
; CODIGO 0x4b04..0x4b2d  (41 bytes)
; ======================================================================


entrada_del_layout:		; HL = 0xD200 + tecla 0xDC47 - 1
	ld a,(0dc47h)		;4b04
	dec a			;4b07   ; de 1 a 0
	ld hl,0d200h		;4b08
	call hl_mas_a		;4b0b
	ret			;4b0e
vram_para_escribir:		; la direccion de escritura del VDP = HL
	push af			;4b0f
	ld a,(00007h)		;4b10   ; el puerto de control
	inc a			;4b13   ; el puerto de control
	ld c,a			;4b14
	ld a,l			;4b15   ; la parte baja...
	out (c),a		;4b16
	ld a,h			;4b18   ; ...y la alta
	and 03fh		;4b19   ; bit 6: escritura
	or 040h		;4b1b
	out (c),a		;4b1d
	pop af			;4b1f
	ret			;4b20
layout_de_fabrica:		; los 0x30 bytes de 0x4B71 al LAYOUT (0xD200)
	ld hl,04b71h		;4b21
	ld de,0d200h		;4b24   ; a 0xD200
	ld bc,00030h		;4b27   ; 0x30 teclas
	ldir		;4b2a
	ret			;4b2c

; ----------------------------------------------------------------------
; DATOS tablas_del_teclado_dibujado: posiciones y tiles de las teclas que se
;   iluminan (0x4A44-0x4B2B)
;   0x4b2d..0x4ba1  (116 bytes)
DATA_tablas_del_teclado_dibujado:
	defb 01eh,026h,02eh,03eh,046h,056h,05eh,066h,076h,07eh,08eh,096h,09eh,0aeh,0b6h,0c6h	; 4b2d  .&.>FV^fv~......
	defb 0ceh,0d6h,0e4h,000h,0e5h,002h,0e6h,004h,0e8h,000h,0e9h,004h,0ebh,000h,0ech,002h	; 4b3d  ................
	defb 0edh,004h,0efh,000h,0f0h,004h,0f2h,000h,0f3h,002h,0f4h,004h,0f6h,000h,0f7h,004h	; 4b4d  ................
	defb 0f9h,000h,0fah,002h,0fbh,004h,0b0h,0b1h,0a3h,0a4h,0a1h,0a4h,0a1h,0a2h,0a6h,0a7h	; 4b5d  ................
	defb 0a7h,0a7h,0a7h,0a8h,00fh,000h,009h,00ah,000h,00bh,00ch,00dh,000h,00eh,000h,010h	; 4b6d  ................
	defb 011h,028h,029h,008h,000h,000h,01bh,01ch,01dh,01eh,001h,018h,016h,003h,020h,000h	; 4b7d  .()........... .
	defb 004h,005h,025h,000h,006h,007h,01ah,019h,026h,027h,01eh,021h,002h,022h,024h,017h	; 4b8d  ..%.....&'.!."$.
	defb 01fh,015h,023h,014h	; 4b9d

; ======================================================================
; CODIGO 0x4ba1..0x4c5b  (186 bytes)
; ======================================================================


hace_syn:		; SYN pedido por la pantalla: copia el timbre en curso a 0xDC00, sintetiza y salta a la pantalla de la tecla que corto o acabo
	ld a,(0d81ch)		;4ba1   ; espera a que acabe el efecto del canal C
	or a			;4ba4   ; el efecto sigue
	jr nz,hace_syn		;4ba5
	ld a,001h		;4ba7   ; 0xD904: ocupado
	ld (0d904h),a		;4ba9   ; 0xD904 = 1
	call timbre_en_curso		;4bac   ; HL = el timbre en curso
	ld de,0dc00h		;4baf   ; sus 25 bytes a 0xDC00
	ld bc,00019h		;4bb2   ; 25 bytes
	ldir		;4bb5
	call syn		;4bb7   ; la sintesis
	xor a			;4bba   ; borra las dos filas del menu
	ld hl,03ac0h		;4bbb   ; las filas 22 y 23...
	ld bc,00040h		;4bbe   ; ...64 tiles a cero
	call 00056h		;4bc1   ; BIOS FILVRM - Fills VRAM with value
	ld a,(0dc47h)		;4bc4   ; la tecla que dejo SYN: F4 al acabar
	call pantalla_por_tecla		;4bc7   ; la pantalla de esa tecla
	xor a			;4bca   ; todo a cero
	ld (0d903h),a		;4bcb   ; los contadores del tic a cero
	ld (0d907h),a		;4bce
	ld (0d902h),a		;4bd1
	ld (0d904h),a		;4bd4
	ei			;4bd7   ; interrupciones otra vez
	ret			;4bd8
animacion_del_tic:		; cada tic de SYN: dos cambios en la VRAM (0x4C61) cada 16 tics y el sprite que avanza y cambia de dibujo
	ei			;4bd9   ; deja entrar interrupciones
	ld hl,0d907h		;4bda   ; 0xD907: cuenta de tics
	ld a,(hl)			;4bdd   ; el nibble bajo
	and 00fh		;4bde
	jr nz,L_4C1A		;4be0   ; no es el momento
	ld a,(hl)			;4be2
	or a			;4be3
	jr z,L_4BF6		;4be4
	and 0f0h		;4be6   ; el alto...
	rrca			;4be8
	rrca			;4be9
	rrca			;4bea
	rrca			;4beb
	cp 005h		;4bec   ; ...menor que 5
	jr nc,L_4C1A		;4bee
	ld b,a			;4bf0
	xor a			;4bf1
L_4BF2:
	add a,008h		;4bf2   ; 8 bytes por entrada
	djnz L_4BF2		;4bf4
L_4BF6:
	ld de,04c61h		;4bf6   ; dos cambios en la VRAM de la tabla 0x4C61
	call de_mas_a		;4bf9   ; su entrada en 0x4C61
	di			;4bfc
	ld b,002h		;4bfd   ; dos cambios
L_4BFF:
	ld a,(de)			;4bff   ; la direccion, baja...
	out (099h),a		;4c00   ; direccion
	inc de			;4c02
	ld a,(de)			;4c03   ; ...y alta, para escribir
	and 03fh		;4c04
	or 040h		;4c06
	out (099h),a		;4c08
	ld a,(00006h)		;4c0a   ; el puerto de datos
	ld c,a			;4c0d
	inc de			;4c0e
	ld a,(de)			;4c0f   ; dos bytes
	out (c),a		;4c10
	inc de			;4c12
	ld a,(de)			;4c13
	out (c),a		;4c14   ; dos bytes
	inc de			;4c16
	djnz L_4BFF		;4c17
	ei			;4c19   ; interrupciones otra vez
L_4C1A:
	ld hl,0d907h		;4c1a   ; un tic mas
	inc (hl)			;4c1d
	ld de,0d903h		;4c1e   ; el dibujo en curso
	ld a,(0d902h)		;4c21   ; 0xD902: la fase de la animacion
	ld b,a			;4c24
	or a			;4c25
	jr nz,$+99		;4c26   ; la otra fase
	ld hl,0d871h		;4c28   ; el sprite avanza en X...
	inc (hl)			;4c2b   ; X + 1
	ld a,(hl)			;4c2c
	cp 098h		;4c2d   ; ...hasta 0x98
	jr c,L_4C37		;4c2f   ; hasta 0x98
	xor a			;4c31   ; al llegar, dibujo 0...
	ld (de),a			;4c32
	inc a			;4c33   ; ...y fase 1
	jp L_4CA7		;4c34
L_4C37:
	and 001h		;4c37   ; cada dos tics...
	jr nz,L_4C43		;4c39
	ld a,(de)			;4c3b   ; ...el dibujo siguiente de tres
	inc a			;4c3c   ; el dibujo siguiente...
	cp 003h		;4c3d   ; ...de tres
	jr c,L_4C42		;4c3f
	xor a			;4c41
L_4C42:
	ld (de),a			;4c42
L_4C43:
	ld a,(de)			;4c43   ; los patrones de 0x4C5B
	add a,a			;4c44   ; dos bytes por dibujo
	ld de,04c5bh		;4c45
	call de_mas_a		;4c48
	ex de,hl			;4c4b
	ld c,(hl)			;4c4c   ; los patrones de los dos sprites
	inc hl			;4c4d
	ld b,(hl)			;4c4e
	ex de,hl			;4c4f
	ld a,(hl)			;4c50   ; Y del primero
	inc hl			;4c51
	ld (hl),c			;4c52   ; su patron
	inc hl			;4c53
	inc hl			;4c54
	inc hl			;4c55
	ld (hl),a			;4c56   ; la misma Y para el segundo...
	inc hl			;4c57
	ld (hl),b			;4c58   ; ...y su patron
	di			;4c59
	ret			;4c5a

; ----------------------------------------------------------------------
; DATOS tablas_del_cursor_syn: tiles del cursor y del marco que lee
;   0x4BFF-0x4C4E
;   0x4c5b..0x4c89  (46 bytes)
DATA_tablas_del_cursor_syn:
	defb 020h,024h,028h,02ch,030h,034h,0c9h,03ah,016h,01ah,0e9h,03ah,026h,02ah,0cbh,03ah	; 4c5b   $(,04.:...:&*.:
	defb 017h,018h,0ebh,03ah,027h,028h,0cdh,03ah,016h,01ah,0edh,03ah,026h,02ah,0cfh,03ah	; 4c6b  ...:'(.:...:&*.:
	defb 020h,021h,0efh,03ah,022h,023h,0d1h,03ah,017h,019h,0f1h,03ah,027h,029h	; 4c7b   !.:"#.:...:')

; ======================================================================
; CODIGO 0x4c89..0x4cd4  (75 bytes)
; ======================================================================


L_4C89:
	djnz L_4CBD		;4c89   ; fase 1 aqui; la 2 mas abajo
	ld hl,04ce4h		;4c8b   ; parpadeo: 0x4CE4 o 0x4CF4
	ld a,(de)			;4c8e   ; una vez mas
	inc a			;4c8f
	ld (de),a			;4c90
	cp 014h		;4c91   ; 0x14 veces
	jr nc,L_4CA5		;4c93   ; se acabo: fase 2
	bit 2,a		;4c95   ; bit 2: un dibujo u otro
	jr nz,L_4C9C		;4c97
	ld hl,04cf4h		;4c99
L_4C9C:
	ld de,0d870h		;4c9c   ; a la copia de los atributos
	ld bc,00010h		;4c9f
	ldir		;4ca2
	ret			;4ca4
L_4CA5:
	ld a,002h		;4ca5   ; fase 2
L_4CA7:
	ld (0d902h),a		;4ca7   ; 0xD902
	xor a			;4caa   ; el tile 0
	ld hl,03ad4h		;4cab   ; borra dos tiles en 0x3AD4...
	ld bc,00002h		;4cae
	call 00056h		;4cb1   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03af4h		;4cb4   ; ...y en 0x3AF4
	ld bc,00002h		;4cb7
	jp 00056h		;4cba   ; BIOS FILVRM - Fills VRAM with value
L_4CBD:
	ld hl,0d872h		;4cbd   ; el patron del primer sprite
	ex de,hl			;4cc0
	inc (hl)			;4cc1   ; una vez mas
	ld bc,0383ch		;4cc2   ; los patrones 0x38 y 0x3C...
	bit 3,(hl)		;4cc5   ; cada 8 tics...
	jr z,L_4CCC		;4cc7
	ld bc,04044h		;4cc9   ; ...o 0x40 y 0x44
L_4CCC:
	ex de,hl			;4ccc
	ld (hl),b			;4ccd   ; ...cambia el dibujo
	inc hl			;4cce   ; el segundo sprite
	inc hl			;4ccf
	inc hl			;4cd0
	inc hl			;4cd1
	ld (hl),c			;4cd2
	ret			;4cd3

; ----------------------------------------------------------------------
; DATOS sprites_de_la_mano: 12 sprites de 4 bytes que lee 0x48ED y 0x4CA3
;   0x4cd4..0x4d04  (48 bytes)
DATA_sprites_de_la_mano:
	defb 0b0h,04ah,022h,00ch	; 4cd4
	defb 0b0h,04ah,024h,00eh	; 4cd8
	defb 0b0h,0aah,050h,00dh	; 4cdc
	defb 0b0h,0aah,054h,00eh	; 4ce0
	defb 0b0h,09ch,030h,00ch	; 4ce4
	defb 0b0h,09ch,034h,00eh	; 4ce8
	defb 0b0h,0aah,048h,00dh	; 4cec
	defb 0b0h,0aah,04ch,00eh	; 4cf0
	defb 0b0h,09ch,030h,00ch	; 4cf4
	defb 0b0h,09ch,034h,00eh	; 4cf8
	defb 0b0h,0aah,050h,00dh	; 4cfc
	defb 0b0h,0aah,054h,00eh	; 4d00

; ======================================================================
; CODIGO 0x4d04..0x4e7a  (374 bytes)
; ======================================================================


graba_en_cinta:		; graba el fichero del tipo 0xDB18 en cinta
	call ram_en_la_pagina_2		;4d04   ; la RAM en la pagina 2
	di			;4d07   ; sin interrupciones
	ld a,0ffh		;4d08   ; cabecera larga
	call 000eah		;4d0a   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jr c,error_de_cinta		;4d0d   ; fallo
	ld a,(0db18h)		;4d0f   ; 0xDBF0 = la direccion de los datos
	call direccion_de_carga		;4d12
	ld b,010h		;4d15   ; 16 veces el tipo
L_4D17:
	ld a,(0db18h)		;4d17   ; el tipo
	call byte_a_cinta		;4d1a
	djnz L_4D17		;4d1d   ; 16 veces
	xor a			;4d1f   ; cabecera corta...
	call 000eah		;4d20   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jr c,error_de_cinta		;4d23   ; fallo
	ld hl,0db0fh		;4d25   ; ...y las 7 letras del nombre
	ld b,007h		;4d28   ; 7 letras
L_4D2A:
	ld a,(hl)			;4d2a   ; una letra
	call byte_a_cinta		;4d2b
	inc hl			;4d2e
	djnz L_4D2A		;4d2f
	xor a			;4d31   ; cabecera corta...
	call 000eah		;4d32   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jr c,error_de_cinta		;4d35   ; fallo
	ld hl,0dcfeh		;4d37   ; ...y la longitud, 0xDCFE
	ld b,002h		;4d3a   ; dos bytes
L_4D3C:
	ld a,(hl)			;4d3c
	call byte_a_cinta		;4d3d
	inc hl			;4d40
	djnz L_4D3C		;4d41
	dec hl			;4d43   ; BC = la longitud
	ld b,(hl)			;4d44   ; BC = la longitud
	dec hl			;4d45
	ld c,(hl)			;4d46
	ld a,(0db18h)		;4d47   ; SAMP: tambien la pagina de bucle
	cp 023h		;4d4a   ; SAMP?
	jr nz,L_4D54		;4d4c
	ld a,(0dcfdh)		;4d4e
	call byte_a_cinta		;4d51
L_4D54:
	push bc			;4d54
	xor a			;4d55   ; cabecera corta...
	call 000eah		;4d56   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	pop bc			;4d59
	jr c,error_de_cinta		;4d5a   ; fallo
	ld hl,(0dbf0h)		;4d5c   ; ...y los datos
L_4D5F:
	ld a,(hl)			;4d5f   ; un byte
	call byte_a_cinta		;4d60
	jr c,error_de_cinta		;4d63
	inc hl			;4d65   ; el siguiente
	dec bc			;4d66   ; hasta la longitud
	ld a,b			;4d67
	or c			;4d68
	jr nz,L_4D5F		;4d69
	ld b,005h		;4d6b   ; una pausa
	call pausa		;4d6d
	call 000f0h		;4d70   ; BIOS TAPOOF - Stops writing on the tape | fin de la grabacion
	call cartucho_en_la_pagina_2		;4d73   ; el cartucho otra vez
	ei			;4d76
	ret			;4d77
error_de_cinta:		; para el motor, vuelve el cartucho y sale con acarreo
	xor a			;4d78   ; el motor parado
	call 000f3h		;4d79   ; BIOS STMOTR - Sets the cassette motor action
	call cartucho_en_la_pagina_2		;4d7c
	scf			;4d7f   ; acarreo: fallo
	ei			;4d80
	ret			;4d81
byte_a_cinta:		; TAPOUT de A
	push hl			;4d82
	push bc			;4d83
	call 000edh		;4d84   ; BIOS TAPOUT - Writes data on the tape | TAPOUT
	pop bc			;4d87
	pop hl			;4d88
	ret			;4d89
busca_otra_vez:		; otro fichero en la cinta
	jr L_4D8F		;4d8a
carga_de_cinta:		; busca en la cinta un fichero del tipo 0xDB18 (y del nombre de 0xDB0F, si lo hay) y lo carga
	call ram_en_la_pagina_2		;4d8c   ; la RAM en la pagina 2
L_4D8F:
	di			;4d8f   ; sin interrupciones
	ld a,(0db18h)		;4d90   ; el tipo
	cp 023h		;4d93   ; SAMP: el sample en blanco antes
	jr nz,L_4D9A		;4d95
	call llena_de_silencio		;4d97
L_4D9A:
	call 000e1h		;4d9a   ; BIOS TAPION - Reads the header block after turning the cassette motor on | una cabecera
	jr c,error_de_cinta		;4d9d   ; fallo
	ld a,(0db18h)		;4d9f   ; 16 bytes, todos del tipo
	ld c,a			;4da2   ; C = el tipo
	ld b,010h		;4da3
L_4DA5:
	call byte_de_cinta		;4da5   ; un byte
	jr c,error_de_cinta		;4da8
	cp c			;4daa   ; el tipo?
	jr nz,busca_otra_vez		;4dab   ; otro tipo: a buscar otra vez
	djnz L_4DA5		;4dad
	ld bc,00700h		;4daf   ; el nombre todo espacios...
L_4DB2:
	ld hl,0db0fh		;4db2
	ld a,(hl)			;4db5   ; la letra
	cp 020h		;4db6   ; espacio?
	jr nz,L_4DBF		;4db8
	inc hl			;4dba
	djnz L_4DB2		;4dbb
	ld c,001h		;4dbd   ; ...vale cualquiera (C = 1)
L_4DBF:
	push bc			;4dbf   ; la cabecera del nombre
	call 000e1h		;4dc0   ; BIOS TAPION - Reads the header block after turning the cassette motor on | la cabecera del nombre
	pop bc			;4dc3
	jr c,error_de_cinta		;4dc4
	ld hl,0db0fh		;4dc6
	ld b,007h		;4dc9
L_4DCB:
	call byte_de_cinta		;4dcb   ; 7 letras
	jr c,error_de_cinta		;4dce
	bit 0,c		;4dd0   ; cualquiera, o...
	jr nz,L_4DD7		;4dd2   ; el nombre que llega
	cp (hl)			;4dd4   ; ...la misma
	jr nz,busca_otra_vez		;4dd5   ; otro nombre: a buscar otra vez
L_4DD7:
	ld (hl),a			;4dd7   ; se queda con la que llega
	inc hl			;4dd8
	djnz L_4DCB		;4dd9
	call cartucho_en_la_pagina_2		;4ddb   ; el cartucho, para escribir en pantalla
	call borra_mensajes		;4dde
	ld de,04e80h		;4de1   ; "FOUND"...
	call escribe_lista		;4de4   ; "FOUND"
	ld de,0db0fh		;4de7   ; ...y el nombre
	ld hl,03a0dh		;4dea   ; en 0x3A0D...
	call siete_letras		;4ded   ; ...las siete letras
	call ram_en_la_pagina_2		;4df0   ; la RAM otra vez
	call 000e1h		;4df3   ; BIOS TAPION - Reads the header block after turning the cassette motor on | la cabecera de la longitud
	jp c,error_de_cinta		;4df6
	ld hl,0dcfeh		;4df9   ; 0xDCFE
	ld b,002h		;4dfc
L_4DFE:
	call byte_de_cinta		;4dfe   ; un byte de la longitud
	jp c,error_de_cinta		;4e01
	ld (hl),a			;4e04
	inc hl			;4e05
	djnz L_4DFE		;4e06
	ld a,(0db18h)		;4e08   ; SAMP: la pagina de bucle
	cp 023h		;4e0b   ; SAMP?
	jr nz,L_4E18		;4e0d
	call byte_de_cinta		;4e0f
	jp c,error_de_cinta		;4e12
	ld (0dcfdh),a		;4e15
L_4E18:
	call 000e1h		;4e18   ; BIOS TAPION - Reads the header block after turning the cassette motor on | la cabecera de los datos
	jp c,error_de_cinta		;4e1b
	call direccion_de_carga		;4e1e   ; 0xDBF0 = su direccion
	ld hl,0dcfeh		;4e21   ; BC = la longitud
	ld c,(hl)			;4e24   ; BC = la longitud
	inc hl			;4e25
	ld b,(hl)			;4e26
	ld hl,(0dbf0h)		;4e27   ; HL = la direccion
L_4E2A:
	call byte_de_cinta		;4e2a   ; un byte...
	jp c,error_de_cinta		;4e2d
	ld (hl),a			;4e30   ; ...a su sitio
	inc hl			;4e31
	dec bc			;4e32   ; hasta la longitud
	ld a,b			;4e33
	or c			;4e34
	jr nz,L_4E2A		;4e35
	ld b,001h		;4e37   ; una pausa
	call pausa		;4e39
	call 000e7h		;4e3c   ; BIOS TAPIOF - Stops reading from the tape | fin de la lectura
	call cartucho_en_la_pagina_2		;4e3f
	ei			;4e42
	ret			;4e43
llena_de_silencio:		; 0x8000-0xBFFF a 0x80, el reposo del DAC: el sample en blanco
	ld hl,08000h		;4e44   ; 0x80 desde 0x8000...
	ld bc,03fffh		;4e47   ; ...0x3FFF bytes mas
	ld d,h			;4e4a
	ld e,l			;4e4b
	inc e			;4e4c
	ld (hl),080h		;4e4d   ; 0x80...
	ldir		;4e4f   ; ...en todo
	ret			;4e51
byte_de_cinta:		; TAPIN a A; acarreo si falla
	push hl			;4e52
	push bc			;4e53
	call 000e4h		;4e54   ; BIOS TAPIN - Reads data from the tape | TAPIN
	pop bc			;4e57
	pop hl			;4e58
	ret			;4e59
direccion_de_carga:		; 0xDBF0 = la direccion del tipo 0xDB18 (0x4E7A)
	ld a,(0db18h)		;4e5a   ; el tipo, de 0 a 2...
	sub 021h		;4e5d   ; 0, 1 o 2
	add a,a			;4e5f   ; ...por dos
	ld hl,04e7ah		;4e60   ; la tabla...
	ld de,0dbf0h		;4e63   ; ...a 0xDBF0
	ld bc,00002h		;4e66
	call hl_mas_a		;4e69   ; la entrada
	ldir		;4e6c
	ret			;4e6e
pausa:		; B vueltas de 65536
	ld de,00000h		;4e6f   ; 65536 vueltas...
L_4E72:
	dec de			;4e72
	ld a,d			;4e73
	or e			;4e74
	jr nz,L_4E72		;4e75
	djnz L_4E72		;4e77   ; ...B veces
	ret			;4e79

; ----------------------------------------------------------------------
; DATOS direcciones_de_carga: las tres direcciones de RAM donde se carga TONE,
;   LAYOUT y SAMP (0x4E5A, por 0xDB18)
;   0x4e7a..0x4e80  (6 bytes)
DATA_direcciones_de_carga:
	defw 0c000h,0d200h,08000h	; 4e7a  -> 0xc000 0xd200 DATA_sprites_patrones

; ----------------------------------------------------------------------
; DATOS rotulo_found: lista de 0x4337: "FOUND" en 0x3A07
;   0x4e80..0x4e89  (9 bytes)
DATA_rotulo_found:
	defb 007h,03ah,026h,02fh,035h,02eh,024h,000h,0ffh	; 4e80  .:&/5.$..

; ======================================================================
; CODIGO 0x4e89..0x4fde  (341 bytes)
; ======================================================================


graba_en_disco:		; NOMBRE.ext con la longitud (y el bucle en SAMP) delante de los datos
	ld (0d972h),sp		;4e89   ; para volver si hay error (0x5119)
	call cambiando_pantalla		;4e8d   ; cambiando de pantalla
	call ram_en_la_pagina_2		;4e90   ; la RAM en la pagina 2
	ld de,0d980h		;4e93   ; el FCB en 0xD980
	ld hl,0db0fh		;4e96   ; el nombre
	call fcb		;4e99
	call crea		;4e9c   ; crea el fichero
	call fcb_a_cero		;4e9f   ; el FCB listo
	ld hl,(0dcfeh)		;4ea2   ; la longitud, 2 bytes
	call escribe_palabra		;4ea5   ; la longitud
	ld a,(0db18h)		;4ea8
	cp 023h		;4eab
	jr nz,L_4EB5		;4ead
	ld a,(0dcfdh)		;4eaf   ; SAMP: la pagina de bucle
	call escribe_byte		;4eb2   ; la pagina de bucle
L_4EB5:
	call direccion_de_carga		;4eb5   ; la direccion de los datos
	ld de,(0dbf0h)		;4eb8   ; la direccion de los datos...
	ld c,01ah		;4ebc   ; ...a la DMA
	call 0f37dh		;4ebe   ; BDOS 0x1A: la DMA
	ld hl,(0dcfeh)		;4ec1   ; los datos, de un tiron
	call escribe_bloque		;4ec4   ; la longitud en registros de 1 byte
	call cierra		;4ec7   ; cierra
	call cartucho_en_la_pagina_2		;4eca
	call pantalla_quieta		;4ecd
	ret			;4ed0
carga_de_disco:		; abre NOMBRE.ext, lee la longitud (y el bucle) y los datos
	ld (0d972h),sp		;4ed1   ; la pila, para los errores
	call cambiando_pantalla		;4ed5
	call ram_en_la_pagina_2		;4ed8
	ld de,0d980h		;4edb   ; el FCB...
	ld hl,0db0fh		;4ede   ; ...con el nombre
	call fcb		;4ee1
	ld a,(0db18h)		;4ee4
	cp 023h		;4ee7
	jr nz,L_4EEE		;4ee9
	call llena_de_silencio		;4eeb   ; SAMP: el sample en blanco antes
L_4EEE:
	call abre		;4eee   ; abre
	call fcb_a_cero		;4ef1   ; el FCB listo
	call lee_palabra		;4ef4   ; la longitud
	ld (0dcfeh),hl		;4ef7   ; 0xDCFE
	ld a,(0db18h)		;4efa
	cp 023h		;4efd
	jr nz,L_4F07		;4eff
	call lee_byte		;4f01   ; SAMP: la pagina de bucle
	ld (0dcfdh),a		;4f04   ; 0xDCFD
L_4F07:
	call direccion_de_carga		;4f07
	ld de,(0dbf0h)		;4f0a   ; la DMA
	ld c,01ah		;4f0e
	call 0f37dh		;4f10   ; BDOS 0x1A: la DMA
	ld hl,(0dcfeh)		;4f13   ; los datos
	call lee_bloque		;4f16   ; la longitud en registros
	call cierra		;4f19   ; cierra
	call cartucho_en_la_pagina_2		;4f1c
	call pantalla_quieta		;4f1f
	ret			;4f22
borra_de_disco:		; borra NOMBRE.ext
	ld (0d972h),sp		;4f23   ; la pila, para los errores
	call cambiando_pantalla		;4f27
	call ram_en_la_pagina_2		;4f2a
	ld de,0d980h		;4f2d   ; el FCB...
	ld hl,0db0fh		;4f30   ; ...con el nombre
	call fcb		;4f33
	call fcb_a_cero		;4f36
	ld de,0d980h		;4f39   ; BDOS 0x13: borrar
	ld c,013h		;4f3c
	call 0f37dh		;4f3e
	ld c,001h		;4f41
	or a			;4f43   ; error?
	jp nz,mensaje_de_error		;4f44   ; error 1
	call cartucho_en_la_pagina_2		;4f47
	jp pantalla_quieta		;4f4a
directorio:		; busca los ficheros del tipo 0xDB18: hasta 0x23 nombres en 0xD2E1, 11 bytes cada uno
	ld (0d972h),sp		;4f4d   ; la pila, para los errores
	call cambiando_pantalla		;4f51
	call ram_en_la_pagina_2		;4f54
	ld hl,0d2c0h		;4f57   ; la lista, a espacios
	ld de,0d2c1h		;4f5a   ; 0x1A1 bytes mas
	ld (hl),020h		;4f5d
	ld bc,001a1h		;4f5f
	ldir		;4f62
	ld hl,0d9b8h		;4f64   ; un FCB...
	ld de,0d9b9h		;4f67   ; el FCB de busqueda a cero
	ld (hl),000h		;4f6a
	ld bc,00024h		;4f6c
	ldir		;4f6f
	ld hl,0d9b9h		;4f71   ; ...con ???????? de nombre
	ld de,0d9bah		;4f74   ; el nombre...
	ld (hl),03fh		;4f77   ; ...todo '?'
	ld bc,0000ah		;4f79
	ldir		;4f7c
	xor a			;4f7e   ; ninguno todavia
	ld (0d9b5h),a		;4f7f   ; ninguno encontrado
	ld (0d9b6h),a		;4f82   ; la lista desde el 0
	ld de,0d2c0h		;4f85   ; la DMA en 0xD2C0
	ld c,01ah		;4f88
	call 0f37dh		;4f8a
	ld de,0d9b8h		;4f8d   ; BDOS 0x11: el primero
	ld c,011h		;4f90
	call 0f37dh		;4f92   ; BDOS 0x11
	inc a			;4f95   ; ninguno
	jr z,L_4FC4		;4f96
L_4F98:
	call letra_del_tipo		;4f98   ; la letra de la extension del tipo...
	ld hl,0d2c9h		;4f9b   ; la extension del encontrado
	cp (hl)			;4f9e   ; ...y dos espacios detras
	jr nz,L_4FB9		;4f9f
	ld b,002h		;4fa1
L_4FA3:
	inc hl			;4fa3   ; las otras dos letras...
	ld a,020h		;4fa4   ; ...espacios?
	cp (hl)			;4fa6
	jr nz,L_4FB9		;4fa7
	djnz L_4FA3		;4fa9
	ld hl,0d9b5h		;4fab   ; uno mas
	inc (hl)			;4fae   ; uno mas
	push hl			;4faf
	call al_directorio		;4fb0   ; a la lista
	pop hl			;4fb3
	ld a,(hl)			;4fb4   ; cuantos
	cp 023h		;4fb5   ; 0x23: no caben mas
	jr z,L_4FC4		;4fb7   ; 0x23: lleno
L_4FB9:
	ld de,0d9b8h		;4fb9   ; BDOS 0x12: el siguiente
	ld c,012h		;4fbc
	call 0f37dh		;4fbe   ; BDOS 0x12
	inc a			;4fc1   ; no hay mas
	jr nz,L_4F98		;4fc2
L_4FC4:
	ld de,04fe9h		;4fc4   ; "END" si hay alguno...
	ld hl,0d9b5h		;4fc7   ; alguno?
	ld a,(hl)			;4fca
	or a			;4fcb
	jr z,L_4FD1		;4fcc
	ld de,04fdeh		;4fce   ; ...o "NO FILE"
L_4FD1:
	call copia_entrada		;4fd1   ; el rotulo a la lista
	call cartucho_en_la_pagina_2		;4fd4
	ld a,002h		;4fd7   ; el efecto 2
	call efecto		;4fd9   ; el efecto 2
	jr $+75		;4fdc

; ----------------------------------------------------------------------
; DATOS rotulos_end_y_no_file: "END" y "NO FILE", con los tiles de borde 0x40
;   y 0x96
;   0x4fde..0x4ff4  (22 bytes)
DATA_rotulos_end_y_no_file:
	defb 040h,040h,096h,096h,045h,04eh,044h,096h,096h,040h,040h,040h,040h,04eh,04fh,020h	; 4fde  @@..END..@@@@NO 
	defb 046h,049h,04ch,045h,040h,040h	; 4fee

; ======================================================================
; CODIGO 0x4ff4..0x511f  (299 bytes)
; ======================================================================


directorio_teclas:		; arriba y abajo mueven la lista de diez; RETURN (0x40) sale con acarreo
	call cambiando_pantalla		;4ff4
	ld a,(0d808h)		;4ff7   ; el byte de teclas con repeticion
	ld de,0d9b6h		;4ffa   ; la primera fila de la lista
	cp 001h		;4ffd   ; 1: arriba
	jr z,L_501A		;4fff
	cp 002h		;5001   ; 2: abajo
	jr z,L_5011		;5003
	ld a,(0d8f3h)		;5005   ; RETURN
	cp 040h		;5008   ; RETURN?
	jr nz,L_502A		;500a
	call pantalla_quieta		;500c   ; RETURN: fuera...
	scf			;500f   ; ...con acarreo
	ret			;5010
L_5011:
	ld a,(de)			;5011   ; sube si no esta arriba
	or a			;5012   ; en la primera:
	jr z,L_502A		;5013   ; nada
	ex de,hl			;5015
	dec (hl)			;5016   ; una arriba
	ex de,hl			;5017
	jr L_5027		;5018
L_501A:
	ld a,(0d9b5h)		;501a   ; baja si quedan mas de diez
	ex de,hl			;501d
	sub (hl)			;501e   ; cuantos quedan por debajo
	ex de,hl			;501f
	cp 00ah		;5020   ; diez o menos: nada
	jr c,L_502A		;5022
	ex de,hl			;5024
	inc (hl)			;5025   ; una abajo
	ex de,hl			;5026
L_5027:
	call lista_de_diez		;5027   ; la lista otra vez
L_502A:
	call pantalla_quieta		;502a
	or a			;502d   ; sin acarreo
	ret			;502e
cambiando_pantalla:		; 0xD901 = 1
	ld a,001h		;502f
	jr L_5034		;5031
pantalla_quieta:		; 0xD901 = 0
	xor a			;5033
L_5034:
	ld (0d901h),a		;5034   ; 0xD901
	ret			;5037
lista_de_diez:		; diez nombres desde el 0xD9B6, uno por fila desde 0x38E8
	ld hl,038e8h		;5038
	ld a,(0d9b6h)		;503b
	ld c,a			;503e
	ld b,00ah		;503f
L_5041:
	push bc			;5041
	push hl			;5042
	ld a,c			;5043   ; la entrada C
	call entrada_en_de		;5044
	call un_nombre		;5047   ; a la pantalla
	pop hl			;504a
	ld bc,00020h		;504b   ; la fila siguiente
	add hl,bc			;504e
	pop bc			;504f
	inc c			;5050
	djnz L_5041		;5051
	xor a			;5053
	ld (0d9b7h),a		;5054
	ret			;5057
un_nombre:		; escribe un nombre de la lista, con su punto, o la marca de fin
	ld a,(0d9b7h)		;5058
	or a			;505b
	ret nz			;505c
	ld a,(de)			;505d
	cp 020h		;505e   ; vacia: nada
	ret z			;5060
	cp 096h		;5061   ; 0x96: el final
	jr z,L_507D		;5063
	cp 040h		;5065   ; 0x40: "END"
	jr z,L_5078		;5067
	ld b,007h		;5069   ; 7 letras...
	call letras_a_vram		;506b
	ld a,096h		;506e   ; ...el punto...
	call 0004dh		;5070   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5073
	ld b,003h		;5074   ; ...y 3 mas
	jr letras_a_vram		;5076
L_5078:
	ld a,001h		;5078
	ld (0d9b7h),a		;507a
L_507D:
	ld b,00bh		;507d
	call letras_a_vram		;507f
	xor a			;5082
	jp 0004dh		;5083   ; BIOS WRTVRM - Writes data in VRAM
letras_a_vram:		; B caracteres ASCII de DE a la VRAM de HL, convertidos a tiles
	ld a,(de)			;5086
	cp 096h		;5087
	jr z,L_50A1		;5089
	cp 020h		;508b   ; espacio y @: tile 0
	jr z,L_5093		;508d
	cp 040h		;508f
	jr nz,L_5097		;5091
L_5093:
	ld a,000h		;5093
	jr L_50A1		;5095
L_5097:
	cp 03ah		;5097   ; cifras: + 0x10
	jr nc,L_509F		;5099
	add a,010h		;509b
	jr L_50A1		;509d
L_509F:
	sub 020h		;509f   ; letras: - 0x20
L_50A1:
	call 0004dh		;50a1   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;50a4
	inc hl			;50a5
	djnz letras_a_vram		;50a6
	ret			;50a8
al_directorio:		; la entrada 0xD2C1 del FCB encontrado a la lista
	ld de,0d2c1h		;50a9
	ld a,(0d9b5h)		;50ac
	dec a			;50af
copia_entrada:		; 11 bytes de DE a la entrada A de la lista
	call entrada_de_la_lista		;50b0
	ex de,hl			;50b3
	ld bc,0000bh		;50b4
	ldir		;50b7
	ret			;50b9
entrada_de_la_lista:		; HL = 0xD2E1 + 11 * A
	ld l,a			;50ba
	ld h,000h		;50bb
	ld b,h			;50bd
	ld c,l			;50be
	add hl,hl			;50bf   ; A * 3...
	add hl,bc			;50c0
	add hl,hl			;50c1   ; ...* 4 - A = A * 11
	add hl,hl			;50c2
	and a			;50c3
	sbc hl,bc		;50c4
	ld bc,0d2e1h		;50c6
	add hl,bc			;50c9
	ret			;50ca
entrada_en_de:		; DE = 0xD2E1 + 11 * A
	ex de,hl			;50cb
	ld l,a			;50cc   ; A...
	ld h,000h		;50cd
	ld b,h			;50cf
	ld c,l			;50d0
	add hl,hl			;50d1   ; ...por 3...
	add hl,bc			;50d2
	add hl,hl			;50d3   ; ...por 4, menos A: por 11
	add hl,hl			;50d4
	and a			;50d5
	sbc hl,bc		;50d6
	ld bc,0d2e1h		;50d8   ; desde la lista
	add hl,bc			;50db
	ex de,hl			;50dc
	ret			;50dd
error_de_disco:		; el codigo de error de la BIOS del disco (C) a uno de los mensajes
	ld a,c			;50de   ; el codigo de error...
	and 00eh		;50df
	rrca			;50e1   ; ...de 0 a 7
	cp 002h		;50e2
	jr c,L_50EC		;50e4   ; 0 y 1: los mensajes 4 y 3
	cp 006h		;50e6   ; 2 a 5: el mensaje 0; de 6 en adelante, el 3
	jr c,L_50F5		;50e8
	jr L_50F1		;50ea
L_50EC:
	ld c,004h		;50ec
	rrca			;50ee
	jr nc,mensaje_de_error		;50ef
L_50F1:
	ld c,003h		;50f1
	jr mensaje_de_error		;50f3
L_50F5:
	ld c,000h		;50f5
mensaje_de_error:		; el mensaje C de 0x511F en 0x3A06, y vuelve por la pila guardada en 0xD972 con acarreo
	push bc			;50f7
	call cartucho_en_la_pagina_2		;50f8   ; el cartucho para la pantalla
	call borra_mensajes		;50fb
	call pantalla_quieta		;50fe
	pop bc			;5101
	ld b,000h		;5102
	ld a,c			;5104
	add a,a			;5105
	ld c,a			;5106
	ld hl,0511fh		;5107   ; el mensaje
	add hl,bc			;510a
	ld e,(hl)			;510b
	inc hl			;510c
	ld d,(hl)			;510d
	ld hl,03a06h		;510e
	ld c,0ffh		;5111
	call escribe_desde_hl		;5113
	call file_reposo		;5116   ; 0xB8F8
	ld sp,(0d972h)		;5119   ; la pila de antes de la operacion
	scf			;511d
	ret			;511e

; ----------------------------------------------------------------------
; DATOS mensajes_de_disco_punteros: 7 punteros a los mensajes de error de
;   disco
;   0x511f..0x512d  (14 bytes)
DATA_mensajes_de_disco_punteros:
	defw 0512dh,0513bh,0514ah,05154h,05163h,05173h,05183h	; 511f

; ----------------------------------------------------------------------
; DATOS mensajes_de_disco: 7 mensajes acabados en 0xFF: DISK I/O ERROR, FILE
;   NOT FOUND, DISK FULL, DISK NOT READY, WRITE PROTECTED, TOO MANY FILES, BAD
;   FILE NAME
;   0x512d..0x5191  (100 bytes)
DATA_mensajes_de_disco:
	defb 024h,029h,033h,02bh,000h,029h,02fh,000h,025h,032h,032h,02fh,032h,0ffh,026h,029h	; 512d  $)3+.)/.%22/2.&)
	defb 02ch,025h,000h,02eh,02fh,034h,000h,026h,02fh,035h,02eh,024h,0ffh,024h,029h,033h	; 513d  ,%../4.&/5.$.$)3
	defb 02bh,000h,026h,035h,02ch,02ch,0ffh,024h,029h,033h,02bh,000h,02eh,02fh,034h,000h	; 514d  +.&5,,.$)3+../4.
	defb 032h,025h,021h,024h,039h,0ffh,037h,032h,029h,034h,025h,000h,030h,032h,02fh,034h	; 515d  2%!$9.72)4%.02/4
	defb 025h,023h,034h,025h,024h,0ffh,034h,02fh,02fh,000h,02dh,021h,02eh,039h,000h,026h	; 516d  %#4%$.4//.-!.9.&
	defb 029h,02ch,025h,033h,000h,0ffh,022h,021h,024h,000h,026h,029h,02ch,025h,000h,02eh	; 517d  ),%3.."!$.&),%..
	defb 021h,02dh,025h,0ffh	; 518d

; ======================================================================
; CODIGO 0x5191..0x51d8  (71 bytes)
; ======================================================================


fcb:		; arma el FCB en DE con el nombre 0xDB0F (los tiles a ASCII) y la letra del tipo
	call nombre_valido		;5191   ; nombre todo espacios o con huecos: error 6
	ld c,006h		;5194
	jp c,mensaje_de_error		;5196
	ld (0d970h),de		;5199
	xor a			;519d   ; unidad 0: la de siempre
	ld (de),a			;519e
	inc de			;519f
	ld b,007h		;51a0   ; 7 letras
L_51A2:
	ld a,(hl)			;51a2
	cp 040h		;51a3   ; tiles 0x21-0x3F: letras, + 0x20
	jr nc,L_51AB		;51a5
	add a,020h		;51a7
	jr L_51AD		;51a9
L_51AB:
	sub 010h		;51ab   ; 0x40 en adelante: cifras, - 0x10
L_51AD:
	ld (de),a			;51ad
	inc hl			;51ae
	inc de			;51af
	djnz L_51A2		;51b0
	ld a,020h		;51b2   ; la octava, un espacio
	ld (de),a			;51b4
	inc de			;51b5
	call letra_del_tipo		;51b6   ; la extension: T, K o S...
	ld (de),a			;51b9
	inc de			;51ba
	ld a,020h		;51bb   ; ...y dos espacios
	ld b,002h		;51bd
L_51BF:
	ld (de),a			;51bf
	inc de			;51c0
	djnz L_51BF		;51c1
	xor a			;51c3   ; el resto del FCB a cero
	ld b,019h		;51c4
L_51C6:
	ld (de),a			;51c6
	inc de			;51c7
	djnz L_51C6		;51c8
	ret			;51ca
letra_del_tipo:		; A = T, K o S segun 0xDB18
	ld a,(0db18h)		;51cb
	sub 021h		;51ce   ; el tipo, de 0 a 2
	ld hl,051d8h		;51d0   ; la letra en 0x51D8
	call hl_mas_a		;51d3
	ld a,(hl)			;51d6
	ret			;51d7

; ----------------------------------------------------------------------
; DATOS extension_tks: "TKS", la extension de los ficheros en disco
;   0x51d8..0x51db  (3 bytes)
DATA_extension_tks:
	defb 054h,04bh,053h	; 51d8

; ======================================================================
; CODIGO 0x51db..0x534d  (370 bytes)
; ======================================================================


nombre_valido:		; acarreo si el nombre empieza por espacio o tiene un hueco entre letras
	push hl			;51db
	push de			;51dc
	ld de,0d9dfh		;51dd   ; 0xD9DF: ya vino un espacio
	ld hl,0db0fh		;51e0
	ld a,(hl)			;51e3   ; la primera letra...
	cp 020h		;51e4   ; ...no puede ser espacio
	jr z,L_5203		;51e6
	ld b,006h		;51e8   ; las otras seis
L_51EA:
	inc hl			;51ea
	ld a,(de)			;51eb   ; tras un espacio...
	or a			;51ec
	jr z,L_51F6		;51ed
	ld a,(hl)			;51ef   ; ...no puede haber letra
	cp 020h		;51f0
	jr nz,L_5203		;51f2
	jr L_51FE		;51f4
L_51F6:
	ld a,(hl)			;51f6
	cp 020h		;51f7
	jr nz,L_51FE		;51f9
	ld a,001h		;51fb
	ld (de),a			;51fd
L_51FE:
	djnz L_51EA		;51fe
	xor a			;5200
	jr L_5204		;5201
L_5203:
	scf			;5203
L_5204:
	ld a,000h		;5204
	ld (de),a			;5206
	pop de			;5207
	pop hl			;5208
	ret			;5209
fcb_hl:		; 0xD970 = HL
	ld (0d970h),hl		;520a
fcb_a_cero:		; bloque 0, registro de 1 byte y registro aleatorio 0
	ld hl,(0d970h)		;520d
	ld bc,0000ch		;5210   ; bloque actual = 0
	add hl,bc			;5213
	ld (hl),b			;5214
	inc hl			;5215
	ld (hl),b			;5216
	inc hl			;5217
	ld bc,00001h		;5218   ; tamano de registro = 1
	ld (hl),c			;521b
	inc hl			;521c
	ld (hl),b			;521d
	ld bc,00011h		;521e
	add hl,bc			;5221
	ld b,005h		;5222   ; el registro aleatorio a cero
	xor a			;5224
L_5225:
	ld (hl),a			;5225
	inc hl			;5226
	djnz L_5225		;5227
	ret			;5229
registro_aleatorio:		; (FCB + 0x21) = HL, con el FCB en DE
	ld (0d970h),de		;522a
	jr L_5234		;522e
L_5230:
	ld de,(0d970h)		;5230
L_5234:
	ex de,hl			;5234
	ld bc,00021h		;5235   ; el registro aleatorio, FCB + 0x21
	add hl,bc			;5238
	ld (hl),e			;5239   ; el bajo...
	inc hl			;523a
	ld (hl),d			;523b   ; ...y el alto
	ret			;523c
abre:		; BDOS 0x0F; error 1
	ld de,(0d970h)		;523d
	ld c,00fh		;5241
	call 0f37dh		;5243
	ld c,001h		;5246
si_falla:		; A = 0xFF: el mensaje de error C
	inc a			;5248
	ret nz			;5249
	jp mensaje_de_error		;524a
crea:		; BDOS 0x16; error 5
	ld de,(0d970h)		;524d
	ld c,016h		;5251
	call 0f37dh		;5253
	ld c,005h		;5256
	jr si_falla		;5258
cierra:		; BDOS 0x10; error 2
	ld de,(0d970h)		;525a
	ld c,010h		;525e
	call 0f37dh		;5260
	ld c,002h		;5263
	jr si_falla		;5265
lee_bloque:		; BDOS 0x27, HL registros; error 0
	ld de,(0d970h)		;5267
	ld c,027h		;526b
	call 0f37dh		;526d
	ld c,000h		;5270
si_no_cero:		; A distinto de 0: el mensaje de error C
	and a			;5272
	ret z			;5273
	jp mensaje_de_error		;5274
escribe_bloque:		; BDOS 0x26, HL registros; error 2
	ld de,(0d970h)		;5277
	ld c,026h		;527b
	call 0f37dh		;527d
	ld c,002h		;5280
	jr si_no_cero		;5282
lee_byte:		; un byte del fichero a A, por la pila
	ld bc,lee_bloque		;5284
	jr L_528C		;5287
escribe_byte:		; A al fichero, por la pila
	ld bc,escribe_bloque		;5289
L_528C:
	push af			;528c   ; A en la pila...
	ld hl,00001h		;528d
	add hl,sp			;5290
	push bc			;5291
	ex de,hl			;5292   ; ...es la DMA
	ld c,01ah		;5293
	call 0f37dh		;5295
	pop bc			;5298
	call un_registro		;5299
	pop af			;529c
	ret			;529d
un_registro:		; HL = 1 y salta a BC
	ld hl,00001h		;529e
	push bc			;52a1
	ret			;52a2
escribe_palabra:		; HL al fichero, el bajo primero
	push hl			;52a3
	ld a,l			;52a4   ; el bajo...
	call escribe_byte		;52a5
	pop hl			;52a8
	ld a,h			;52a9   ; ...y el alto
	jr escribe_byte		;52aa
lee_palabra:		; HL del fichero
	call lee_byte		;52ac   ; el bajo...
	ld l,a			;52af
	push hl			;52b0
	call lee_byte		;52b1   ; ...y el alto
	pop hl			;52b4
	ld h,a			;52b5
	ret			;52b6
pantalla_imprime:		; la pantalla 7: imprime y vuelve a la pantalla de antes
	ld a,070h		;52b7
	ld (0d930h),a		;52b9
	call impresora_lista		;52bc   ; espera a la impresora; acarreo si no esta
	jr c,L_52CC		;52bf
	ld a,(0d8fbh)		;52c1   ; desde WAVE EDIT...
	cp 001h		;52c4
	call z,imprime_onda		;52c6   ; ...la onda
	call cuatro_lineas		;52c9   ; y lo demas
L_52CC:
	ld a,(0d8f5h)		;52cc   ; vuelve a la pantalla de antes
	ld (0d8fah),a		;52cf
	ld a,(0d8fbh)		;52d2
	ld (0d8f4h),a		;52d5
	ret			;52d8
impresora_lista:		; espera a que la impresora este lista y empieza
	ld (0d931h),sp		;52d9   ; la pila, para salir si falla
	ld a,071h		;52dd
	ld (0d930h),a		;52df
	ld a,001h		;52e2   ; RAWPRT = 1: sin traducir los codigos
	ld (0f418h),a		;52e4
	call espera_impresora		;52e7
	jp vuelca_pantalla		;52ea
espera_impresora:		; LPTSTT hasta que conteste, con limite
	ld h,001h		;52ed
L_52EF:
	ld c,000h		;52ef
L_52F1:
	ld b,000h		;52f1
L_52F3:
	call 000a8h		;52f3   ; BIOS LPTSTT - Tests printer status | lista?
	jr z,L_52FB		;52f6
	cp 0ffh		;52f8   ; 0xFF: no hay
	ret z			;52fa
L_52FB:
	djnz L_52F3		;52fb
	dec c			;52fd   ; 256 x 256 x H intentos
	jr nz,L_52F1		;52fe
	dec h			;5300
	jr nz,L_52EF		;5301
	jr no_hay_impresora		;5303
impresora_falla:		; manda 0x200 ceros y ocho saltos de linea, y vuelve por la pila guardada con acarreo
	xor a			;5305
	ld (0d938h),a		;5306
	ld hl,00200h		;5309   ; 0x200 ceros
L_530C:
	push hl			;530c
	call espera_impresora		;530d
	pop hl			;5310
	xor a			;5311
	call 000a5h		;5312   ; BIOS LPTOUT - Sends one character to printer
	jr c,L_530C		;5315
	dec hl			;5317
	ld a,h			;5318
	or l			;5319
	jr nz,L_530C		;531a
	ld b,008h		;531c   ; 8 veces CR + LF
L_531E:
	ld a,00dh		;531e
	call 000a5h		;5320   ; BIOS LPTOUT - Sends one character to printer
	jr c,L_531E		;5323
L_5325:
	ld a,00ah		;5325
	call 000a5h		;5327   ; BIOS LPTOUT - Sends one character to printer
	jr c,L_5325		;532a
	djnz L_531E		;532c
sale_de_imprimir:		; la pila de 0xD931 y acarreo
	ld sp,(0d931h)		;532e
	scf			;5332
	ret			;5333
no_hay_impresora:		; el rotulo de 0x534D, una espera y el menu otra vez
	ld de,0534dh		;5334
	call escribe_lista		;5337
	ld h,00fh		;533a   ; la espera, 15 x 65536 vueltas
L_533C:
	ld c,000h		;533c
L_533E:
	ld b,000h		;533e
L_5340:
	djnz L_5340		;5340   ; 256 vueltas...
	dec c			;5342   ; ...por 256...
	jr nz,L_533E		;5343
	dec h			;5345   ; ...por H
	jr nz,L_533C		;5346
	call cambia_menu		;5348   ; el menu otra vez
	jr sale_de_imprimir		;534b

; ----------------------------------------------------------------------
; DATOS rotulo_printer_not_ready: lista de 0x4337: "PRINTER NOT READY"
;   0x534d..0x5361  (20 bytes)
DATA_rotulo_printer_not_ready:
	defb 0c7h,03ah,030h,032h,029h,02eh,034h,025h,032h,000h,02eh,02fh,034h,000h,032h,025h	; 534d  .:02).4%2../4.2%
	defb 021h,024h,039h,0ffh	; 535d

; ======================================================================
; CODIGO 0x5361..0x54b6  (341 bytes)
; ======================================================================


imprime:		; A a la impresora en cuanto este lista; 0xD938 = 1 si falla
	push ix		;5361   ; guarda todo
	push hl			;5363
	push de			;5364
	push bc			;5365
	push af			;5366
	push af			;5367   ; A, dos veces
L_5368:
	call 000a8h		;5368   ; BIOS LPTSTT - Tests printer status | espera...
	jr z,L_5368		;536b
	cp 0ffh		;536d   ; ...a 0xFF
	jr nz,L_5368		;536f
	pop af			;5371
	call 000a5h		;5372   ; BIOS LPTOUT - Sends one character to printer | LPTOUT
	jr nc,L_537C		;5375
	ld a,001h		;5377
	ld (0d938h),a		;5379
L_537C:
	pop af			;537c   ; A, que se imprimio
	pop bc			;537d
	pop de			;537e
	pop hl			;537f
	pop ix		;5380
	ret			;5382
cuatro_lineas:		; cuatro veces CR + LF
	ld b,004h		;5383
L_5385:
	call nueva_linea		;5385
	djnz L_5385		;5388
	ret			;538a
nueva_linea:		; CR + LF
	ld a,00dh		;538b
	call imprime		;538d
	ld a,00ah		;5390
	jp imprime		;5392
punto_con_tinta:		; A distinto de 0 si el punto de 0xD933 lleva tinta
	call color_del_punto		;5395
	or a			;5398
	ret nz			;5399
	call comparar_color		;539a
	ret			;539d
comparar_color:		; 0 si el color es 4
	ld a,(0f3e6h)		;539e   ; (0xF3E6)
	and 00fh		;53a1
	cp 004h		;53a3   ; 4: 0
	ret z			;53a5
	ld a,001h		;53a6   ; si no, 1
	ret			;53a8
color_del_punto:		; el color del punto (X, Y) de 0xD933 en SCREEN 2: el tile de la tabla de nombres, su patron y su color
	ld hl,(0d933h)		;53a9   ; la direccion de su nombre
	call nombre_del_punto		;53ac
	call 0004ah		;53af   ; BIOS RDVRM - Reads the content of VRAM | el tile...
	ld h,000h		;53b2   ; ...por 8...
	ld l,a			;53b4
	add hl,hl			;53b5
	add hl,hl			;53b6
	add hl,hl			;53b7
	ld de,(0d933h)		;53b8   ; ...mas la linea dentro del tile
	ld a,e			;53bc
	and 007h		;53bd
	ld e,a			;53bf
	ld d,000h		;53c0
	add hl,de			;53c2
	ld de,(0d933h)		;53c3   ; y el tercio de la pantalla
	ld a,e			;53c7
	ld de,00000h		;53c8
	cp 040h		;53cb
	jr c,L_53D8		;53cd
	ld d,008h		;53cf
	cp 080h		;53d1
	jr c,L_53D7		;53d3
	ld d,010h		;53d5
L_53D7:
	add hl,de			;53d7
L_53D8:
	ld de,(0d933h)		;53d8   ; el bit del punto
	ld a,d			;53dc
	push hl			;53dd
	ld de,02000h		;53de   ; en los patrones (0x2000)
	add hl,de			;53e1
	and 007h		;53e2
	inc a			;53e4
	ld b,a			;53e5
	call 0004ah		;53e6   ; BIOS RDVRM - Reads the content of VRAM
L_53E9:
	add a,a			;53e9   ; al acarreo
	djnz L_53E9		;53ea
	pop hl			;53ec
	push af			;53ed
	ld de,00000h		;53ee   ; y el color (0x0000)
	add hl,de			;53f1
	call 0004ah		;53f2   ; BIOS RDVRM - Reads the content of VRAM
	ld b,a			;53f5
	pop af			;53f6
	jr c,L_53FD		;53f7   ; bit a 1: la tinta (nibble alto)...
	ld a,b			;53f9   ; ...a 0: el fondo (bajo)
	and 00fh		;53fa
	ret			;53fc
L_53FD:
	ld a,b			;53fd   ; el nibble alto...
	and 0f0h		;53fe
	rrca			;5400   ; ...al bajo
	rrca			;5401
	rrca			;5402
	rrca			;5403
	ret			;5404
nombre_del_punto:		; HL = 0x3800 + (Y / 8) * 32 + X / 8
	ld a,l			;5405   ; Y / 8...
	rra			;5406
	rra			;5407
	rra			;5408
	rra			;5409
	rr h		;540a   ; ...con los bits de X
	rra			;540c
	rr h		;540d
	rra			;540f
	rr h		;5410
	ld l,h			;5412   ; L = (Y / 8) * 32 + X / 8 bajo
	and 003h		;5413
	add a,038h		;5415   ; H = 0x38 + lo alto
	ld h,a			;5417
	ret			;5418
vuelca_pantalla:		; la pantalla en puntos: 0x40 franjas de cuatro filas, 0xC0 columnas cada una
	call secuencia_inicial		;5419   ; la secuencia de arranque (0x54B6)
	ld b,040h		;541c   ; 0x40 franjas
	ld h,000h		;541e
L_5420:
	push bc			;5420
	ld de,054bdh		;5421   ; la secuencia de cada franja: 0x54BD o 0x54C4
	ld a,(0d930h)		;5424
	cp 071h		;5427
	jr z,L_542E		;5429
	ld de,054c4h		;542b
L_542E:
	call imprime_lista		;542e
	ld b,0c0h		;5431   ; 0xC0 columnas
L_5433:
	push bc			;5433
	push hl			;5434
	ld l,b			;5435
	dec l			;5436
	ld (0d933h),hl		;5437   ; el punto de arriba de la columna
	ld ix,0d935h		;543a   ; dos bytes que se arman en 0xD935
	xor a			;543e
	ld (ix+000h),a		;543f
	ld (ix+001h),a		;5442
	ld bc,00403h		;5445   ; cuatro puntos, dos bits cada uno
L_5448:
	push bc			;5448
	call punto_con_tinta		;5449   ; el color del punto...
	call trama		;544c   ; ...a su trama de 0x54F6
	pop bc			;544f
	ld a,d			;5450   ; los dos bits de este punto
	and c			;5451
	or (ix+000h)		;5452
	ld (ix+000h),a		;5455
	ld a,e			;5458
	and c			;5459
	or (ix+001h)		;545a
	ld (ix+001h),a		;545d
	rlc c		;5460   ; los dos siguientes
	rlc c		;5462
	ld hl,(0d933h)		;5464   ; el punto de debajo
	inc h			;5467
	ld (0d933h),hl		;5468
	djnz L_5448		;546b
	ld a,(ix+000h)		;546d   ; los dos bytes a la impresora
	call imprime		;5470
	call segundo_byte		;5473
	ld a,(ix+001h)		;5476
	call imprime		;5479
	call segundo_byte		;547c
	pop hl			;547f
	pop bc			;5480
	djnz L_5433		;5481
	call nueva_linea		;5483   ; fin de la franja
	ld a,(0d938h)		;5486   ; si fallo, a 0x5305
	or a			;5489
	jp nz,impresora_falla		;548a
	ld a,004h		;548d   ; la franja siguiente
	add a,h			;548f
	ld h,a			;5490
	pop bc			;5491
	djnz L_5420		;5492
	call cuatro_lineas		;5494
	xor a			;5497
	ret			;5498
segundo_byte:		; en el modo 0x72 cada byte va dos veces
	ld b,a			;5499   ; el byte
	ld a,(0d930h)		;549a
	cp 072h		;549d   ; modo 0x72?
	ld a,b			;549f
	jp z,imprime		;54a0   ; si: otra vez
	ret			;54a3
secuencia_54cb:		; la secuencia de 0x54CB
	ld de,054cbh		;54a4
	jr imprime_lista		;54a7
secuencia_inicial:		; la secuencia de 0x54B6
	ld de,054b6h		;54a9
imprime_lista:		; los bytes de DE hasta 0xFF
	ld a,(de)			;54ac   ; el byte
	inc a			;54ad
	ret z			;54ae   ; 0xFF: se acabo
	dec a			;54af
	call imprime		;54b0   ; a la impresora
	inc de			;54b3
	jr imprime_lista		;54b4

; ----------------------------------------------------------------------
; DATOS ordenes_de_impresora: secuencias ESC de la impresora MSX: ESC T16, ESC
;   S0384, ESC S0768, ESC S0240, ESC A, "TIME" y "WAVE FORM DATA", acabadas en
;   0xFF
;   0x54b6..0x54e9  (51 bytes)
DATA_ordenes_de_impresora:
	defb 01bh,054h,031h,036h,00dh,00ah,0ffh,01bh,053h,030h,033h,038h,034h,0ffh,01bh,053h	; 54b6  .T16....S0384..S
	defb 030h,037h,036h,038h,0ffh,01bh,053h,030h,032h,034h,030h,0ffh,01bh,041h,0ffh,054h	; 54c6  0768..S0240..A.T
	defb 049h,04dh,045h,0ffh,057h,041h,056h,045h,020h,046h,04fh,052h,04dh,020h,044h,041h	; 54d6  IME.WAVE FORM DA
	defb 054h,041h,0ffh	; 54e6

; ======================================================================
; CODIGO 0x54e9..0x54f6  (13 bytes)
; ======================================================================


trama:		; DE = la trama del color A (0x54F6)
	push hl			;54e9
	ld hl,054f6h		;54ea   ; las tramas de 0x54F6
	add a,a			;54ed   ; dos bytes por color
	call hl_mas_a		;54ee
	ld d,(hl)			;54f1   ; D y E
	inc hl			;54f2
	ld e,(hl)			;54f3
	pop hl			;54f4
	ret			;54f5

; ----------------------------------------------------------------------
; DATOS tramas_de_impresora: 32 bytes de tramado que se mandan a la impresora
;   para dibujar la onda
;   0x54f6..0x5516  (32 bytes)
DATA_tramas_de_impresora:
	defb 0ffh,0ffh,0ffh,0ffh,055h,0aah,000h,055h,0aah,0ffh,0aah,0aah,0ffh,0aah,000h,0aah	; 54f6  ....U..U........
	defb 0aah,055h,0aah,000h,0ffh,000h,000h,055h,0ffh,055h,000h,0ffh,055h,000h,000h,000h	; 5506  .U.....U.U..U...

; ======================================================================
; CODIGO 0x5516..0x5c12  (1788 bytes)
; ======================================================================


imprime_onda:		; desde WAVE EDIT: cabecera, columnas del 0 al 7 y 8 filas de 8 muestras, una de cada cuatro, con signo y tres cifras
	call nueva_linea		;5516
	ld de,054d2h		;5519   ; los rotulos de 0x54D2...
	call imprime_lista		;551c
	ld b,002h		;551f
	call espacios		;5521
	ld de,054dah		;5524   ; ...y 0x54DA
	call imprime_lista		;5527
	call nueva_linea		;552a
	ld b,002h		;552d
	call espacios		;552f
	ld c,030h		;5532   ; las cifras 0 a 7 de las columnas
L_5534:
	ld b,005h		;5534   ; cinco espacios
	call espacios		;5536
	ld a,c			;5539   ; la cifra en ASCII
	cp 038h		;553a   ; hasta el 7
	jr z,L_5544		;553c
	call imprime		;553e   ; a la impresora
	inc c			;5541
	jr L_5534		;5542
L_5544:
	ld de,054d5h		;5544   ; 0x54D5
	call imprime_lista		;5547
	call nueva_linea		;554a
	ld b,03ah		;554d   ; una raya de 0x3A guiones
L_554F:
	ld a,02dh		;554f
	call imprime		;5551
	djnz L_554F		;5554
	call nueva_linea		;5556
	xor a			;5559   ; HL = la onda
	call muestra_a		;555a
	ld b,008h		;555d   ; 8 filas
L_555F:
	push bc			;555f
	ld b,004h		;5560
	call espacios		;5562
	ld b,008h		;5565   ; 8 muestras
L_5567:
	push bc			;5567
	ld a,(hl)			;5568   ; la muestra
	ld c,a			;5569
	ld a,020h		;556a
	bit 7,c		;556c   ; negativa: el guion y su valor absoluto
	jr z,L_5576		;556e
	ld a,c			;5570
	neg		;5571
	ld c,a			;5573
	ld a,02dh		;5574
L_5576:
	call imprime		;5576
	push hl			;5579
	ld l,c			;557a
	call a_decimal		;557b   ; a decimal (0xA978)
	ld hl,0dbf0h		;557e   ; las tres cifras en 0xDBF0
	ld a,e			;5581
	and 00fh		;5582
	ld (hl),a			;5584
	ld a,e			;5585
	and 0f0h		;5586
	rrca			;5588
	rrca			;5589
	rrca			;558a
	rrca			;558b
	inc hl			;558c
	ld (hl),a			;558d
	ld a,d			;558e
	and 00fh		;558f
	inc hl			;5591
	ld (hl),a			;5592
	ld b,003h		;5593   ; en ASCII, la alta primero
L_5595:
	ld a,(hl)			;5595   ; la cifra...
	or 030h		;5596   ; ...en ASCII...
	call imprime		;5598   ; ...a la impresora
	dec hl			;559b
	djnz L_5595		;559c
	ld b,002h		;559e   ; dos espacios
	call espacios		;55a0
	pop hl			;55a3
	inc hl			;55a4   ; cuatro muestras mas alla
	inc hl			;55a5
	inc hl			;55a6
	inc hl			;55a7
	pop bc			;55a8   ; la muestra siguiente
	djnz L_5567		;55a9
	call nueva_linea		;55ab   ; fin de la fila
	pop bc			;55ae
	djnz L_555F		;55af   ; la fila siguiente
	jp cuatro_lineas		;55b1
espacios:		; B espacios
	ld a,020h		;55b4
	call imprime		;55b6
	djnz espacios		;55b9
	ret			;55bb
timbres_y_ondas_de_fabrica:		; los 16 timbres de 0xA3AA a 0xD000, la tabla de teclas y las 16 ondas del usuario como el seno de 0x7200
	ld hl,0a3aah		;55bc   ; 16 timbres de 32 bytes
	ld de,0d000h		;55bf
	ld bc,00200h		;55c2
	ldir		;55c5
	call teclas_de_fabrica		;55c7   ; la tabla de teclas
	ld b,010h		;55ca   ; las 16 ondas...
	ld de,0c000h		;55cc
L_55CF:
	push bc			;55cf
	ld hl,07200h		;55d0   ; ...todas el seno de 0x7200
	ld bc,00100h		;55d3
	ldir		;55d6
	pop bc			;55d8
	djnz L_55CF		;55d9
	ret			;55db
teclas_de_fabrica:		; los 0x80 bytes de 0x5DA9 a 0xD230: rutina y retardo de cada tecla
	ld hl,05da9h		;55dc
	ld de,0d230h		;55df
	ld bc,00080h		;55e2
	ldir		;55e5
	ret			;55e7

; ----------------------------------------------------------------------
; =====  SYN: la sintesis del timbre en la RAM de 0x8000  =====
; ----------------------------------------------------------------------
tic_de_sintesis:		; cada 0xDC22 muestras: 0x4BD9 y 0xDC24 + 1
	call animacion_del_tic		;55e8   ; el tic (0x4BD9)
	ld hl,0dc24h		;55eb   ; y 0xDC24 + 1
	inc (hl)			;55ee
	ret			;55ef
syn:		; SYN: fabrica el timbre de 0xDC00 muestra a muestra en 0x8000-0xBFFF, la RAM del ordenador
	di			;55f0   ; sin interrupciones durante la sintesis
	xor a			;55f1
	ld (0dc24h),a		;55f2   ; 0xDC24 = 0
	call ram_en_la_pagina_2		;55f5   ; la RAM en 0x8000
	ld a,(0dc03h)		;55f8   ; ENV del DCO a cero: su envolvente no cuenta
	or a			;55fb
	jp nz,L_5605		;55fc
	ld hl,00000h		;55ff   ; HL = 0 muestras
	jp L_5613		;5602
L_5605:
	ld a,(0dc09h)		;5605   ; B, C, A = ataque, caida y sostenido del DCO
	ld b,a			;5608
	ld a,(0dc0ah)		;5609   ; C = D
	ld c,a			;560c
	ld a,(0dc0bh)		;560d   ; A = S
	call muestras_ataque_y_caida		;5610   ; HL = muestras de ataque y caida
L_5613:
	ld (0dc1ch),hl		;5613   ; 0xDC1C: las del DCO
	ld a,h			;5616   ; la parte alta
	cp 040h		;5617   ; 16 KB o mas: no se calcula
	jp nc,L_5695		;5619
	ld a,(0dc07h)		;561c   ; ENV del DCF a cero: no cuenta
	or a			;561f
	jp nz,L_5629		;5620
	ld hl,00000h		;5623   ; HL = 0 muestras
	jp L_5637		;5626
L_5629:
	ld a,(0dc0dh)		;5629   ; ataque, caida y sostenido del DCF
	ld b,a			;562c
	ld a,(0dc0eh)		;562d   ; C = D
	ld c,a			;5630
	ld a,(0dc0fh)		;5631   ; A = S
	call muestras_ataque_y_caida		;5634   ; HL = muestras de ataque y caida
L_5637:
	ld (0dc1eh),hl		;5637   ; 0xDC1E: las del DCF
	ld a,h			;563a
	cp 040h		;563b   ; 16 KB o mas: no se calcula
	jp nc,L_5695		;563d
	ld a,(0dc11h)		;5640   ; ataque, caida y sostenido del DCA
	ld b,a			;5643
	ld a,(0dc12h)		;5644   ; C = D
	ld c,a			;5647
	ld a,(0dc13h)		;5648   ; A = S
	call muestras_ataque_y_caida		;564b   ; HL = muestras de ataque y caida
	ld (0dc20h),hl		;564e   ; 0xDC20: las del DCA
	ld a,h			;5651
	cp 040h		;5652   ; 16 KB o mas: no se calcula
	jp nc,L_5695		;5654
	ld de,(0dc1eh)		;5657   ; la mayor de las tres...
	scf			;565b
	ccf			;565c
	sbc hl,de		;565d   ; DCA - DCF
	jp c,L_5669		;565f
	ld de,(0dc20h)		;5662   ; el DCA es mayor
	jp L_566A		;5666
L_5669:
	ccf			;5669
L_566A:
	ld hl,(0dc1ch)		;566a   ; el DCO...
	sbc hl,de		;566d   ; ...contra la mayor de las otras
	jp c,L_5676		;566f
	ld de,(0dc1ch)		;5672   ; el DCO es mayor
L_5676:
	ex de,hl			;5676   ; ...redondeada a pagina entera
	ld de,001ffh		;5677   ; + 0x1FF...
	add hl,de			;567a
	ld l,000h		;567b   ; ...y la pagina entera
	push hl			;567d
	ld a,(0dc13h)		;567e   ; mas la relajacion del DCA: sostenido x R
	ld e,a			;5681   ; E = S del DCA
	ld a,(0dc14h)		;5682   ; C = R del DCA
	ld c,a			;5685
	call multiplica_c_por_e		;5686   ; HL = S * R
	pop de			;5689
	add hl,de			;568a   ; mas lo anterior
	ld de,00040h		;568b   ; mas 0x40
	add hl,de			;568e
	ld a,h			;568f   ; 16 KB o mas?
	cp 040h		;5690
	jp c,L_569A		;5692
L_5695:
	ld a,080h		;5695   ; si pasa de 16 KB, 0x80
	jp L_569F		;5697   ; 0xDC22 = 0x80
L_569A:
	sla l		;569a   ; 0xDC22 = la duracion calculada / 128
	rl h		;569c   ; HL * 2: la parte alta es HL / 128
	ld a,h			;569e
L_569F:
	ld (0dc22h),a		;569f   ; 0xDC22: cada cuantas muestras un tic
	ld (0dc23h),a		;56a2   ; 0xDC23: cuenta atras hasta el siguiente tic
	xor a			;56a5
	ld (0dcfdh),a		;56a6   ; 0xDCFD: sin pagina de bucle
	ld hl,08000h		;56a9   ; el sample entero a 0x80, el silencio
L_56AC:
	ld (hl),080h		;56ac   ; 0x80...
	inc hl			;56ae
	ld a,h			;56af
	cp 0c0h		;56b0   ; ...hasta 0xC000
	jp nz,L_56AC		;56b2
	ld hl,08000h		;56b5   ; 0xDC19: el puntero de escritura, desde 0x8000
	ld (0dc19h),hl		;56b8   ; 0xDC19 = 0x8000
	xor a			;56bb   ; 0xDC1B: ninguna envolvente en su sostenido
	ld (0dc1bh),a		;56bc   ; 0xDC1B = 0
	ld hl,dco_ataque		;56bf   ; las tres envolventes empiezan por el ataque: rutina, cuenta 1 y nivel 0
	ld (0dc25h),hl		;56c2   ; la fase del DCO: el ataque
	ld hl,0dc27h		;56c5   ; su cuenta = 1...
	ld (hl),001h		;56c8
	inc hl			;56ca
	ld (hl),000h		;56cb   ; ...y su nivel = 0
	ld hl,dcf_ataque		;56cd   ; la fase del DCF: el ataque
	ld (0dc29h),hl		;56d0
	ld hl,0dc2bh		;56d3   ; su cuenta = 1...
	ld (hl),001h		;56d6
	inc hl			;56d8
	ld (hl),000h		;56d9   ; ...y su nivel = 0
	ld hl,dca_ataque		;56db   ; la fase del DCA: el ataque
	ld (0dc2dh),hl		;56de
	ld hl,0dc2fh		;56e1   ; su cuenta = 1...
	ld (hl),001h		;56e4
	inc hl			;56e6
	ld (hl),000h		;56e7   ; ...y su nivel = 0
	ld hl,00000h		;56e9   ; 0xDC31: la fase del oscilador
	ld (0dc31h),hl		;56ec
	ld a,(0dc00h)		;56ef   ; la onda 14 es la del usuario...
	cp 00eh		;56f2   ; la 14?
	jp nz,L_56FF		;56f4
	ld a,(0db00h)		;56f7   ; ...en 0xC000 + 0x100 * (0xDB00)
	add a,0c0h		;56fa   ; 0xC0 + onda del usuario
	jp L_5701		;56fc
L_56FF:
	add a,072h		;56ff   ; las de la ROM, en la pagina 0x72 + onda
L_5701:
	ld (0dc33h),a		;5701   ; 0xDC33: la pagina de la onda
	ld hl,00000h		;5704   ; 0xDC35: el puntero del ruido, de 0x0000 en adelante
	ld (0dc35h),hl		;5707   ; 0xDC35 = 0
	ld a,(0dc05h)		;570a   ; RES...
	ld e,a			;570d
	ld d,000h		;570e
	ld hl,05c12h		;5710   ; 0x5C12[RES]
	add hl,de			;5713
	ld a,(hl)			;5714
	ld (0dc38h),a		;5715   ; ...da la realimentacion (0xDC38)...
	ld hl,05c1bh		;5718   ; 0x5C1B[RES]
	add hl,de			;571b
	ld a,(hl)			;571c
	ld (0dc39h),a		;571d   ; ...y la ganancia (0xDC39)
	ld hl,00000h		;5720   ; los estados del filtro a cero
	ld (0dc3ah),hl		;5723   ; primera etapa = 0
	ld (0dc3ch),hl		;5726   ; segunda etapa = 0
	ld hl,00000h		;5729   ; 0xDC42: la fase del LFO
	ld (0dc42h),hl		;572c
	ld a,(0dc16h)		;572f   ; la onda del LFO, igual que la del DCO
	cp 00eh		;5732   ; la 14?
	jp nz,L_573F		;5734
	ld a,(0db00h)		;5737   ; la del usuario...
	add a,0c0h		;573a   ; ...en 0xC0 + onda
	jp L_5741		;573c
L_573F:
	add a,072h		;573f   ; las de la ROM: 0x72 + onda
L_5741:
	ld (0dc44h),a		;5741   ; 0xDC44
	xor a			;5744   ; 0xDC46 = 0
	ld (0dc46h),a		;5745   ; 0xDC46: la cuenta de la retencion
	ld a,(0dc02h)		;5748   ; si algun LFO esta puesto (DCO, DCF o DCA)...
	ld b,a			;574b
	ld a,(0dc06h)		;574c   ; LFO del DCF...
	or b			;574f
	ld b,a			;5750
	ld a,(0dc08h)		;5751   ; ...LFO del DCA...
	or b			;5754
	jp z,L_5761		;5755   ; ...ninguno: 0x5D39
	ld hl,05cceh		;5758   ; ...0xDC40 = 0x5CCE
	ld (0dc40h),hl		;575b
	jp bucle_de_sintesis		;575e
L_5761:
	ld hl,05d39h		;5761   ; si no, 0x5D39 (un `ret`)
	ld (0dc40h),hl		;5764
bucle_de_sintesis:		; una muestra por vuelta, hasta 0xC000 o el fin de la envolvente del DCA
	in a,(0aah)		;5767   ; fila 6 del teclado
	and 0f0h		;5769   ; la fila 6 en el PPI
	or 006h		;576b
	out (0aah),a		;576d
	ld c,a			;576f
	in a,(0a9h)		;5770   ; F1 o F2 cortan la sintesis
	or 09fh		;5772   ; F1 y F2 (bits 5 y 6)
	cp 0ffh		;5774
	jp nz,syn_cortado_fila_6		;5776
	inc c			;5779   ; la fila 7
	ld a,c			;577a
	out (0aah),a		;577b   ; fila 7
	in a,(0a9h)		;577d   ; F4 o F5 tambien
	or 0fch		;577f   ; F4 y F5 (bits 0 y 1)
	cp 0ffh		;5781
	jp nz,syn_cortado_fila_7		;5783
	ld hl,0dc23h		;5786   ; 0xDC23: el tic, cada 0xDC22 muestras
	dec (hl)			;5789   ; una muestra menos
	jp nz,L_5796		;578a
	call tic_de_sintesis		;578d   ; el tic
	ld a,(0dc22h)		;5790   ; y la cuenta otra vez
	ld (0dc23h),a		;5793
L_5796:
	call lfo		;5796   ; el LFO
	call envolvente_dco		;5799   ; la envolvente del DCO
	call envolvente_dcf		;579c   ; la del DCF
	call envolvente_dca		;579f   ; la del DCA
	call oscilador		;57a2   ; el oscilador: la muestra
	call filtro		;57a5   ; el filtro
	call amplitud		;57a8   ; la amplitud
	add a,080h		;57ab   ; con signo a 0x80 = cero...
	ld hl,(0dc19h)		;57ad   ; el puntero de escritura
	ld (hl),a			;57b0   ; ...a la RAM
	inc hl			;57b1   ; la siguiente
	ld (0dc19h),hl		;57b2
	ld a,h			;57b5
	cp 0c0h		;57b6   ; la memoria llena: se acabo
	jp z,fin_de_sintesis		;57b8
	ld a,(0dc1bh)		;57bb   ; la envolvente del DCA ha acabado (bit 7)?
	bit 7,a		;57be
	jp z,bucle_de_sintesis		;57c0
fin_de_sintesis:		; 0xDCFE = bytes escritos; 0xDC47 = 0x39, el codigo de F4; vuelve el cartucho
	ld hl,(0dc19h)		;57c3
	ld de,08000h		;57c6   ; desde 0x8000
	scf			;57c9
	ccf			;57ca
	sbc hl,de		;57cb
	ld (0dcfeh),hl		;57cd   ; 0xDCFE: la longitud del sample
	ld a,039h		;57d0   ; F4
L_57D2:
	ld (0dc47h),a		;57d2   ; 0xDC47 = la tecla
	call cartucho_en_la_pagina_2		;57d5   ; el cartucho en la pagina 2
	ret			;57d8
syn_cortado_fila_6:		; F1 (0x36) o F2 (0x37) a 0xDC47
	bit 5,a		;57d9   ; F1 (bit 5) pulsada?
	jp nz,L_57E3		;57db
	ld a,036h		;57de   ; F1
	jp L_57D2		;57e0
L_57E3:
	ld a,037h		;57e3   ; F2
	jp L_57D2		;57e5
syn_cortado_fila_7:		; F4 (0x39) o F5 (0x3A) a 0xDC47
	bit 0,a		;57e8   ; F4 (bit 0) pulsada?
	jp nz,L_57F2		;57ea
	ld a,039h		;57ed   ; F4
	jp L_57D2		;57ef
L_57F2:
	ld a,03ah		;57f2   ; F5
	jp L_57D2		;57f4
muestras_ataque_y_caida:		; HL = B * 255 + C * (255 - A): ataque B, caida C, sostenido A
	neg		;57f7   ; 255 - S...
	dec a			;57f9
	ld e,a			;57fa   ; ...en E
	ld a,b			;57fb   ; B = el ataque
	call multiplica_c_por_e		;57fc   ; HL = C (la caida) * (255 - S)
	ex de,hl			;57ff   ; DE = eso
	ld h,a			;5800   ; HL = ataque * 256
	ld l,000h		;5801
	or a			;5803
	jp nz,L_580B		;5804   ; ataque distinto de 0: * 255
	inc l			;5807   ; ataque 0: una muestra
	jp L_5810		;5808
L_580B:
	ld b,000h		;580b
	ld c,a			;580d
	sbc hl,bc		;580e
L_5810:
	add hl,de			;5810
	ret			;5811
multiplica_c_por_e:		; HL = C * E
	ld hl,00000h		;5812   ; HL = 0
	ld d,h			;5815   ; D = 0: DE = E
	ld b,008h		;5816   ; 8 bits de C
L_5818:
	rrc c		;5818   ; el bit bajo de C
	jp nc,L_581E		;581a
	add hl,de			;581d   ; suma E desplazado
L_581E:
	sla e		;581e   ; E por dos
	rl d		;5820
	djnz L_5818		;5822
	ret			;5824
envolvente_dco:		; salta a la fase en curso (0xDC25); cuenta en 0xDC27, nivel en 0xDC28
	ld hl,(0dc25h)		;5825   ; la fase en curso
	jp (hl)			;5828   ; a ella
dco_ataque:		; sube el nivel de 1 en 1 cada A muestras hasta 0xFF; con A = 0, de golpe
	ld a,(0dc03h)		;5829   ; sin ENV del DCO no hay envolvente:
	or a			;582c
	jp nz,L_583B		;582d   ; con ENV, la envolvente
	ld a,(0dc1bh)		;5830   ; marca el sostenido y acaba
	set 0,a		;5833
	ld (0dc1bh),a		;5835
	jp dco_fin		;5838   ; y se acaba
L_583B:
	ld a,(0dc09h)		;583b   ; A, el ataque
	or a			;583e
	jp nz,L_5849		;583f   ; A = 0:
	dec a			;5842   ; nivel 0xFF de golpe
	ld (0dc28h),a		;5843
	jp L_585B		;5846   ; a la caida
L_5849:
	ld hl,l584ch		;5849   ; carga 0x584C en HL y no lo guarda: la fase sigue en 0x5829, que vuelve aqui cada muestra
L_584C:
	ld hl,0dc27h		;584c   ; la cuenta
	dec (hl)			;584f   ; una muestra menos
	ret nz			;5850
	ld a,(0dc09h)		;5851   ; se acabo: A otra vez
	ld (hl),a			;5854
	inc hl			;5855   ; el nivel
	inc (hl)			;5856   ; sube uno
	ld a,0ffh		;5857   ; hasta 0xFF
	cp (hl)			;5859
	ret nz			;585a
L_585B:
	ld hl,dco_caida		;585b   ; la fase siguiente, la caida
	ld (0dc25h),hl		;585e
	ret			;5861
dco_caida:		; baja el nivel cada D muestras hasta S; con D = 0 o S = 0xFF, de golpe
	ld a,(0dc0ah)		;5862   ; D, la caida
	or a			;5865
	ld a,(0dc0bh)		;5866   ; S, el sostenido
	jp z,L_5871		;5869   ; D = 0: S de golpe
	cp 0ffh		;586c   ; S = 0xFF: tambien
	jp nz,L_5877		;586e
L_5871:
	ld (0dc28h),a		;5871   ; el nivel = S
	jp dco_llega_al_sostenido		;5874
L_5877:
	ld hl,l587dh		;5877   ; la fase pasa a la caida paso a paso
	ld (0dc25h),hl		;587a
L_587D:
	ld hl,0dc27h		;587d   ; la cuenta
	dec (hl)			;5880   ; una muestra menos
	ret nz			;5881
	ld a,(0dc0ah)		;5882   ; se acabo: D otra vez
	ld (hl),a			;5885
	inc hl			;5886   ; el nivel
	dec (hl)			;5887   ; baja uno
	ld a,(0dc0bh)		;5888   ; hasta S
	cp (hl)			;588b
	ret nz			;588c
dco_llega_al_sostenido:		; bit 0 de 0xDC1B; con S = 0 la envolvente acaba
	ld a,(0dc1bh)		;588d   ; bit 0 de 0xDC1B: el DCO en su sostenido
	set 0,a		;5890
	ld (0dc1bh),a		;5892
	ld a,(0dc0bh)		;5895   ; S = 0:
	or a			;5898
	jp z,dco_fin		;5899   ; se acaba
	ld hl,dco_sostenido		;589c   ; la fase siguiente, el sostenido
	ld (0dc25h),hl		;589f
	ret			;58a2
dco_sostenido:		; espera a que las tres envolventes esten en su sostenido (0xDC1B = 7)
	ld a,(0dc1bh)		;58a3   ; las tres en su sostenido?
	cp 007h		;58a6
	ret nz			;58a8
	ld a,(0dc0ch)		;58a9   ; R, la relajacion
	or a			;58ac
	jp nz,L_58B6		;58ad   ; R distinto de 0: paso a paso
	ld (0dc28h),a		;58b0   ; R = 0: el nivel a 0 de golpe
	jp dco_fin		;58b3
L_58B6:
	ld hl,dco_relajacion		;58b6   ; la fase siguiente, la relajacion
	ld (0dc25h),hl		;58b9
dco_relajacion:		; baja el nivel cada R muestras hasta 0
	ld hl,0dc27h		;58bc   ; la cuenta
	dec (hl)			;58bf   ; una muestra menos
	ret nz			;58c0
	ld a,(0dc0ch)		;58c1   ; se acabo: R otra vez
	ld (hl),a			;58c4
	inc hl			;58c5   ; el nivel
	dec (hl)			;58c6   ; baja uno
	xor a			;58c7   ; hasta 0
	cp (hl)			;58c8
	ret nz			;58c9
dco_fin:		; la fase pasa a un `ret`
	ld hl,l58d0h		;58ca   ; la fase, un `ret`
	ld (0dc25h),hl		;58cd
L_58D0:
	ret			;58d0
envolvente_dcf:		; la misma maquina para el DCF: fase en 0xDC29, cuenta 0xDC2B, nivel 0xDC2C
	ld hl,(0dc29h)		;58d1   ; la fase en curso
	jp (hl)			;58d4   ; a ella
dcf_ataque:		; como 0x5829, con ENV del DCF y bit 1
	ld a,(0dc07h)		;58d5
	or a			;58d8
	jp nz,L_58E7		;58d9   ; con ENV, la envolvente
	ld a,(0dc1bh)		;58dc
	set 1,a		;58df
	ld (0dc1bh),a		;58e1
	jp dcf_fin		;58e4   ; y se acaba
L_58E7:
	ld a,(0dc0dh)		;58e7   ; A, el ataque
	or a			;58ea
	jp nz,L_58F5		;58eb   ; A = 0:
	dec a			;58ee   ; nivel 0xFF de golpe
	ld (0dc2ch),a		;58ef
	jp L_5907		;58f2   ; a la caida
L_58F5:
	ld hl,l58f8h		;58f5   ; como en 0x5849: HL sin guardar
L_58F8:
	ld hl,0dc2bh		;58f8   ; la cuenta
	dec (hl)			;58fb   ; una muestra menos
	ret nz			;58fc
	ld a,(0dc0dh)		;58fd   ; se acabo: A otra vez
	ld (hl),a			;5900
	inc hl			;5901   ; el nivel
	inc (hl)			;5902   ; sube uno
	ld a,0ffh		;5903   ; hasta 0xFF
	cp (hl)			;5905
	ret nz			;5906
L_5907:
	ld hl,dcf_caida		;5907   ; la fase siguiente, la caida
	ld (0dc29h),hl		;590a
	ret			;590d
dcf_caida:		; como 0x5862
	ld a,(0dc0eh)		;590e   ; D, la caida
	or a			;5911
	ld a,(0dc0fh)		;5912   ; S, el sostenido
	jp z,L_591D		;5915   ; D = 0: S de golpe
	cp 0ffh		;5918   ; S = 0xFF: tambien
	jp nz,L_5923		;591a
L_591D:
	ld (0dc2ch),a		;591d   ; el nivel = S
	jp dcf_llega_al_sostenido		;5920
L_5923:
	ld hl,l5929h		;5923   ; la fase pasa a la caida paso a paso
	ld (0dc29h),hl		;5926
L_5929:
	ld hl,0dc2bh		;5929   ; la cuenta
	dec (hl)			;592c   ; una muestra menos
	ret nz			;592d
	ld a,(0dc0eh)		;592e   ; se acabo: D otra vez
	ld (hl),a			;5931
	inc hl			;5932   ; el nivel
	dec (hl)			;5933   ; baja uno
	ld a,(0dc0fh)		;5934   ; hasta S
	cp (hl)			;5937
	ret nz			;5938
dcf_llega_al_sostenido:		; bit 1 de 0xDC1B
	ld a,(0dc1bh)		;5939   ; bit 1 de 0xDC1B: el DCF en su sostenido
	set 1,a		;593c
	ld (0dc1bh),a		;593e
	ld a,(0dc0fh)		;5941   ; S = 0:
	or a			;5944
	jp z,dcf_fin		;5945   ; se acaba
	ld hl,dcf_sostenido		;5948   ; la fase siguiente, el sostenido
	ld (0dc29h),hl		;594b
	ret			;594e
dcf_sostenido:		; como 0x58A3
	ld a,(0dc1bh)		;594f   ; las tres en su sostenido?
	cp 007h		;5952
	ret nz			;5954
	ld a,(0dc10h)		;5955   ; R, la relajacion
	or a			;5958
	jp nz,L_5962		;5959   ; R distinto de 0: paso a paso
	ld (0dc2ch),a		;595c   ; R = 0: el nivel a 0 de golpe
	jp dcf_fin		;595f
L_5962:
	ld hl,dcf_relajacion		;5962   ; la fase siguiente, la relajacion
	ld (0dc29h),hl		;5965
dcf_relajacion:		; como 0x58BC
	ld hl,0dc2bh		;5968   ; la cuenta
	dec (hl)			;596b   ; una muestra menos
	ret nz			;596c
	ld a,(0dc10h)		;596d   ; se acabo: R otra vez
	ld (hl),a			;5970
	inc hl			;5971   ; el nivel
	dec (hl)			;5972   ; baja uno
	xor a			;5973   ; hasta 0
	cp (hl)			;5974
	ret nz			;5975
dcf_fin:		; la fase pasa a un `ret`
	ld hl,l597ch		;5976   ; la fase, un `ret`
	ld (0dc29h),hl		;5979
L_597C:
	ret			;597c
envolvente_dca:		; la del volumen: fase en 0xDC2D, cuenta 0xDC2F, nivel 0xDC30
	ld hl,(0dc2dh)		;597d
	jp (hl)			;5980
dca_ataque:		; como 0x5829, sin poder apagarse
	ld a,(0dc11h)		;5981   ; A, el ataque del DCA
	or a			;5984
	jp nz,L_598F		;5985   ; A = 0:
	dec a			;5988   ; nivel 0xFF de golpe
	ld (0dc30h),a		;5989
	jp L_59A1		;598c   ; a la caida
L_598F:
	ld hl,l5992h		;598f   ; como en 0x5849: HL sin guardar
L_5992:
	ld hl,0dc2fh		;5992   ; la cuenta
	dec (hl)			;5995   ; una muestra menos
	ret nz			;5996
	ld a,(0dc11h)		;5997   ; se acabo: A otra vez
	ld (hl),a			;599a
	inc hl			;599b   ; el nivel
	inc (hl)			;599c   ; sube uno
	ld a,0ffh		;599d   ; hasta 0xFF
	cp (hl)			;599f
	ret nz			;59a0
L_59A1:
	ld hl,dca_caida		;59a1   ; la fase siguiente, la caida
	ld (0dc2dh),hl		;59a4
	ret			;59a7
dca_caida:		; como 0x5862
	ld a,(0dc12h)		;59a8   ; D, la caida
	or a			;59ab
	ld a,(0dc13h)		;59ac   ; S, el sostenido
	jp z,L_59B7		;59af   ; D = 0: S de golpe
	cp 0ffh		;59b2   ; S = 0xFF: tambien
	jp nz,L_59BD		;59b4
L_59B7:
	ld (0dc30h),a		;59b7   ; el nivel = S
	jp dca_llega_al_sostenido		;59ba
L_59BD:
	ld hl,l59c3h		;59bd   ; la fase pasa a la caida paso a paso
	ld (0dc2dh),hl		;59c0
L_59C3:
	ld hl,0dc2fh		;59c3   ; la cuenta
	dec (hl)			;59c6   ; una muestra menos
	ret nz			;59c7
	ld a,(0dc12h)		;59c8   ; se acabo: D otra vez
	ld (hl),a			;59cb
	inc hl			;59cc   ; el nivel
	dec (hl)			;59cd   ; baja uno
	ld a,(0dc13h)		;59ce   ; hasta S
	cp (hl)			;59d1
	ret nz			;59d2
dca_llega_al_sostenido:		; pasa a 0x59D9
	ld hl,dca_sostenido		;59d3   ; la fase pasa al sostenido
	ld (0dc2dh),hl		;59d6
dca_sostenido:		; con el DCO y el DCF en su sostenido y el puntero a principio de pagina, apunta esa pagina en 0xDCFD
	ld a,(0dc1bh)		;59d9   ; DCO y DCF en su sostenido?
	cp 003h		;59dc
	ret nz			;59de
	ld a,(0dc19h)		;59df   ; el puntero a principio de pagina?
	or a			;59e2
	ret nz			;59e3
	ld a,(0dc18h)		;59e4   ; EG TYP (bit 7 de los conmutadores): sin bucle
	bit 7,a		;59e7
	jp nz,L_59F7		;59e9
	ld a,(0dc1ah)		;59ec   ; ni en la ultima pagina
	cp 0bfh		;59ef
	jp z,L_59F7		;59f1
	ld (0dcfdh),a		;59f4   ; 0xDCFD: la pagina que PLAY repite mientras se tiene la tecla
L_59F7:
	ld hl,dca_espera_pagina		;59f7   ; la fase siguiente: espera a principio de pagina
	ld (0dc2dh),hl		;59fa
	ret			;59fd
dca_espera_pagina:		; en el siguiente principio de pagina empieza la relajacion
	ld a,(0dc19h)		;59fe
	or a			;5a01
	ret nz			;5a02
	ld a,(0dc1bh)		;5a03   ; bit 2: el DCA en su sostenido
	set 2,a		;5a06
	ld (0dc1bh),a		;5a08
	ld a,(0dc13h)		;5a0b   ; S = 0: acaba ya
	or a			;5a0e
	jp z,dca_fin		;5a0f
	ld a,(0dc14h)		;5a12   ; R, la relajacion
	or a			;5a15
	jp nz,L_5A1F		;5a16   ; R distinto de 0: paso a paso
	ld (0dc30h),a		;5a19   ; R = 0: el nivel a 0 de golpe
	jp dca_fin		;5a1c
L_5A1F:
	ld hl,dca_relajacion		;5a1f   ; la fase pasa a la relajacion
	ld (0dc2dh),hl		;5a22
dca_relajacion:		; como 0x58BC
	ld hl,0dc2fh		;5a25   ; la cuenta
	dec (hl)			;5a28   ; una muestra menos
	ret nz			;5a29
	ld a,(0dc14h)		;5a2a   ; se acabo: R otra vez
	ld (hl),a			;5a2d
	inc hl			;5a2e   ; el nivel
	dec (hl)			;5a2f   ; baja uno
	xor a			;5a30   ; hasta 0
	cp (hl)			;5a31
	ret nz			;5a32
dca_fin:		; bit 7 de 0xDC1B: la sintesis acaba
	ld a,(0dc1bh)		;5a33   ; bit 7: el sample se acaba
	set 7,a		;5a36
	ld (0dc1bh),a		;5a38
	ret			;5a3b
multiplica_8:		; A = suma de E >> k por cada bit de C, del 7 al 0
	ld e,a			;5a3c   ; E = el multiplicando
	ld b,008h		;5a3d   ; 8 bits de C
	xor a			;5a3f
L_5A40:
	rlc c		;5a40   ; el bit alto de C
	jp nc,L_5A46		;5a42
	add a,e			;5a45   ; suma E desplazado
L_5A46:
	srl e		;5a46   ; E a la mitad
	djnz L_5A40		;5a48
	ret			;5a4a
oscilador:		; devuelve en A la muestra de la onda en la fase 0xDC31 y avanza la fase
	ld a,(0dc00h)		;5a4b   ; la onda 15 o mas: ruido
	cp 00fh		;5a4e
	jp nc,ruido		;5a50
	ld hl,(0dc32h)		;5a53   ; la muestra en la fase
	ld a,(hl)			;5a56
	push af			;5a57   ; la muestra, guardada para el final
	ld a,(0dc02h)		;5a58   ; sin LFO del DCO, el paso es FEET * 256
	or a			;5a5b
	jp nz,L_5A68		;5a5c
	ld a,(0dc01h)		;5a5f   ; FEET...
	ld h,a			;5a62   ; ...por 256
	ld l,000h		;5a63
	jp L_5A9B		;5a65
L_5A68:
	ld c,a			;5a68   ; con LFO: el paso, FEET por 1 + LFO
	ld a,(0dc45h)		;5a69   ; el valor del LFO...
	bit 7,a		;5a6c   ; el LFO negativo...
	jp z,L_5A73		;5a6e
	neg		;5a71   ; ...en valor absoluto
L_5A73:
	ld e,a			;5a73
	ld d,000h		;5a74
	call multiplica_16		;5a76   ; HL = LFO del DCO por |LFO|
	ld a,(0dc45h)		;5a79   ; el signo otra vez
	bit 7,a		;5a7c
	jp z,L_5A91		;5a7e
	inc hl			;5a81   ; ...resta: 1 - LFO / 2
	srl h		;5a82   ; la mitad...
	rr l		;5a84
	ex de,hl			;5a86
	ld hl,00100h		;5a87   ; ...restada de 1.0 (0x100)
	scf			;5a8a
	ccf			;5a8b
	sbc hl,de		;5a8c
	jp L_5A92		;5a8e
L_5A91:
	inc h			;5a91   ; positivo: 1.0 + lo calculado
L_5A92:
	ld a,(0dc01h)		;5a92   ; DE = FEET * 256
	ld e,000h		;5a95
	ld d,a			;5a97
	call multiplica_8_8		;5a98   ; HL = FEET por el factor
L_5A9B:
	ld a,(0dc03h)		;5a9b   ; y si hay ENV del DCO...
	or a			;5a9e   ; ENV del DCO a cero: sin envolvente
	jp z,L_5ACA		;5a9f
	push hl			;5aa2
	ld c,a			;5aa3   ; C = ENV
	ld a,(0dc28h)		;5aa4   ; ...por el nivel de su envolvente
	ld e,a			;5aa7   ; E = el nivel de la envolvente del DCO
	ld d,000h		;5aa8
	call multiplica_16		;5aaa   ; HL = ENV por el nivel
	ld a,(0dc18h)		;5aad   ; invertida con el bit 3 de los conmutadores
	bit 3,a		;5ab0
	jp z,L_5AC5		;5ab2
	inc hl			;5ab5   ; invertida: la mitad...
	srl h		;5ab6
	rr l		;5ab8
	ex de,hl			;5aba
	ld hl,00100h		;5abb   ; ...restada de 1.0
	scf			;5abe
	ccf			;5abf
	sbc hl,de		;5ac0
	jp L_5AC6		;5ac2
L_5AC5:
	inc h			;5ac5   ; normal: 1.0 + lo calculado
L_5AC6:
	pop de			;5ac6   ; DE = el paso de antes
	call multiplica_8_8		;5ac7   ; HL = paso por el factor
L_5ACA:
	ld de,(0dc31h)		;5aca   ; la fase avanza el paso
	add hl,de			;5ace   ; la fase + el paso
	ld (0dc31h),hl		;5acf
	pop af			;5ad2   ; A = la muestra
	ret			;5ad3
ruido:		; lee la memoria de 0x0000 en adelante (la BIOS) con 0xDC35, girada y acumulada en 0xDC34
	ld hl,(0dc35h)		;5ad4
	inc l			;5ad7   ; solo el byte bajo: de 0x0000 a 0x00FF
	ld (0dc35h),hl		;5ad8
	ld a,(hl)			;5adb   ; el byte de la BIOS
	ld hl,0dc34h		;5adc
	rlc a		;5adf   ; girado...
	add a,(hl)			;5ae1   ; ...y acumulado
	ld (hl),a			;5ae2
	ret			;5ae3
multiplica_16:		; HL = suma de DE >> k por cada bit de C, del 7 al 0
	ld b,008h		;5ae4   ; 8 bits de C
	ld hl,00000h		;5ae6
L_5AE9:
	rlc c		;5ae9   ; el bit alto de C
	jp nc,L_5AEF		;5aeb
	add hl,de			;5aee   ; suma DE desplazado
L_5AEF:
	srl d		;5aef   ; DE a la mitad
	rr e		;5af1
	djnz L_5AE9		;5af3
	ret			;5af5
multiplica_8_8:		; HL (8.8) por DE: la parte baja contra DE a la derecha, la alta contra DE a la izquierda
	push de			;5af6
	push hl			;5af7
	ld c,l			;5af8   ; C = la parte baja (fraccion)
	ld hl,00000h		;5af9
	ld b,008h		;5afc
L_5AFE:
	srl d		;5afe   ; DE a la mitad...
	rr e		;5b00
	rlc c		;5b02   ; ...por cada bit de la fraccion
	jp nc,L_5B08		;5b04
	add hl,de			;5b07
L_5B08:
	djnz L_5AFE		;5b08
	pop de			;5b0a
	ld c,d			;5b0b   ; C = la parte alta (entera)
	pop de			;5b0c
	ld b,008h		;5b0d
L_5B0F:
	rrc c		;5b0f   ; del bit bajo...
	jp nc,L_5B15		;5b11
	add hl,de			;5b14   ; ...suma DE...
L_5B15:
	sla e		;5b15   ; ...que se dobla cada vez
	rl d		;5b17
	djnz L_5B0F		;5b19
	ret			;5b1b
filtro:		; filtro de dos etapas con resonancia sobre la muestra L; devuelve A
	ld l,a			;5b1c   ; L = la muestra del oscilador
	ld a,(0dc07h)		;5b1d   ; sin ENV del DCF, el corte es CUT
	or a			;5b20
	jp nz,L_5B2A		;5b21
	ld a,(0dc04h)		;5b24   ; CUT
	jp L_5B4B		;5b27
L_5B2A:
	ld c,a			;5b2a   ; con ENV: CUT mas o menos ENV por el nivel de su envolvente
	ld a,(0dc2ch)		;5b2b   ; el nivel de la envolvente del DCF...
	call multiplica_8		;5b2e   ; ...por ENV
	ld b,a			;5b31
	ld a,(0dc18h)		;5b32   ; bit 2 de los conmutadores: resta
	bit 2,a		;5b35
	ld a,(0dc04h)		;5b37
	jp nz,L_5B46		;5b3a
	add a,b			;5b3d   ; suma, como mucho 0xFF
	jp nc,L_5B4B		;5b3e
	ld a,0ffh		;5b41
	jp L_5B4B		;5b43
L_5B46:
	sub b			;5b46   ; resta, como poco 0
	jp nc,L_5B4B		;5b47
	xor a			;5b4a
L_5B4B:
	ld h,a			;5b4b   ; y el LFO del DCF lo mueve arriba o abajo
	ld a,(0dc06h)		;5b4c   ; LFO del DCF
	or a			;5b4f
	jp nz,L_5B57		;5b50
	ld a,h			;5b53
	jp L_5B75		;5b54
L_5B57:
	ld c,a			;5b57
	ld a,(0dc45h)		;5b58   ; el valor del LFO por LFO del DCF
	call multiplica_con_signo		;5b5b
	bit 7,a		;5b5e   ; positivo: suma...
	jp nz,L_5B6C		;5b60
	add a,h			;5b63
	jp nc,L_5B75		;5b64
	ld a,0ffh		;5b67   ; ...como mucho 0xFF
	jp L_5B75		;5b69
L_5B6C:
	neg		;5b6c   ; negativo: resta...
	ld b,a			;5b6e
	ld a,h			;5b6f
	sub b			;5b70
	jp nc,L_5B75		;5b71
	xor a			;5b74   ; ...como poco 0
L_5B75:
	ld (0dc37h),a		;5b75   ; 0xDC37: el corte
	ld h,000h		;5b78   ; la muestra con signo a 16 bits
	bit 7,l		;5b7a
	jp z,L_5B80		;5b7c
	dec h			;5b7f   ; extiende el signo
L_5B80:
	ld a,(0dc38h)		;5b80   ; con realimentacion...
	or a			;5b83
	jp z,L_5B99		;5b84
	push hl			;5b87
	ld a,(0dc37h)		;5b88   ; ...mas la salida de la segunda etapa por corte y realimentacion
	ld hl,(0dc3ch)		;5b8b   ; la segunda etapa...
	call por_a_entre_128		;5b8e   ; ...por el corte / 128...
	ld a,(0dc38h)		;5b91
	call por_a_bit7_doble		;5b94   ; ...por la realimentacion
	pop de			;5b97
	add hl,de			;5b98   ; sumada a la entrada
L_5B99:
	push hl			;5b99   ; la primera etapa: 0xDC3A += (x - 0xDC3A) * (corte + 1) / 256
	ld de,(0dc3ah)		;5b9a
	scf			;5b9e
	ccf			;5b9f
	sbc hl,de		;5ba0   ; x - primera etapa
	ld a,(0dc37h)		;5ba2
	inc a			;5ba5   ; con corte 0xFF no multiplica
	jp z,L_5BAC		;5ba6
	call por_a_entre_256		;5ba9   ; por (corte + 1) / 256
L_5BAC:
	ld de,(0dc3ah)		;5bac
	add hl,de			;5bb0
	ld (0dc3ah),hl		;5bb1   ; la primera etapa nueva
	ex de,hl			;5bb4   ; 0xDC3E: lo que queda, x - 0xDC3A
	pop hl			;5bb5
	scf			;5bb6
	ccf			;5bb7
	sbc hl,de		;5bb8   ; x - primera etapa
	ld (0dc3eh),hl		;5bba
	ld a,(0dc18h)		;5bbd   ; la segunda etapa solo con el bit 0 o con realimentacion
	bit 0,a		;5bc0
	jp nz,L_5BCC		;5bc2
	ld a,(0dc38h)		;5bc5
	or a			;5bc8
	jp z,L_5BE6		;5bc9
L_5BCC:
	ld de,(0dc3ch)		;5bcc   ; 0xDC3C += (0xDC3E - 0xDC3C) * (corte + 1) / 256
	scf			;5bd0
	ccf			;5bd1
	sbc hl,de		;5bd2   ; 0xDC3E - segunda etapa
	ld a,(0dc37h)		;5bd4
	inc a			;5bd7
	jp z,L_5BDE		;5bd8
	call por_a_entre_256		;5bdb   ; por (corte + 1) / 256
L_5BDE:
	ld de,(0dc3ch)		;5bde
	add hl,de			;5be2
	ld (0dc3ch),hl		;5be3   ; la segunda etapa nueva
L_5BE6:
	ld a,(0dc18h)		;5be6   ; la salida: bit 0, la segunda etapa...
	bit 0,a		;5be9
	jp nz,L_5C06		;5beb
	bit 1,a		;5bee   ; ...bit 1, la primera...
	jp nz,L_5C03		;5bf0
	ld hl,(0dc3eh)		;5bf3   ; ...y si no, 0xDC3E / 2
	bit 7,h		;5bf6
	jp z,L_5BFC		;5bf8
	inc hl			;5bfb
L_5BFC:
	sra h		;5bfc   ; la mitad, con signo
	rr l		;5bfe
	jp L_5C06		;5c00
L_5C03:
	ld hl,(0dc3ah)		;5c03   ; la primera etapa
L_5C06:
	ld a,(0dc39h)		;5c06   ; por la ganancia de RES
	or a			;5c09
	jp z,L_5C10		;5c0a
	call por_a_entre_256		;5c0d
L_5C10:
	ld a,l			;5c10   ; el byte bajo
	ret			;5c11

; ----------------------------------------------------------------------
; DATOS realimentacion_por_res: la realimentacion del filtro por RES (0xDC05,
;   de 0 a 8): 0x5710 la copia a 0xDC38
;   0x5c12..0x5c1b  (9 bytes)
DATA_realimentacion_por_res:
	defb 000h,030h,050h,070h,090h,0a0h,0a8h,0b0h,0b8h	; 5c12  .0Pp.....

; ----------------------------------------------------------------------
; DATOS ganancia_por_res: la ganancia de salida del filtro por RES (0xDC05):
;   0x5718 la copia a 0xDC39
;   0x5c1b..0x5c24  (9 bytes)
DATA_ganancia_por_res:
	defb 000h,0cfh,09bh,071h,04dh,03ah,028h,022h,00eh	; 5c1b  ...qM:(".

; ======================================================================
; CODIGO 0x5c24..0x5da9  (389 bytes)
; ======================================================================


por_a_entre_256:		; HL con signo por A / 256: primero la mitad, luego suma
	ld b,008h		;5c24   ; 8 bits de A
	ld c,a			;5c26
	ex de,hl			;5c27   ; DE = el valor
	ld hl,00000h		;5c28
L_5C2B:
	bit 7,d		;5c2b   ; negativo: redondea hacia el cero
	jp z,L_5C31		;5c2d
	inc de			;5c30
L_5C31:
	sra d		;5c31   ; DE a la mitad...
	rr e		;5c33
	rlc c		;5c35   ; ...y por cada bit de A, del alto...
	jp nc,L_5C3B		;5c37
	add hl,de			;5c3a   ; ...suma
L_5C3B:
	djnz L_5C2B		;5c3b
	ret			;5c3d
por_a_entre_128:		; HL con signo por A / 128: suma antes de dividir
	ld b,008h		;5c3e   ; 8 bits de A
	ld c,a			;5c40
	ex de,hl			;5c41   ; DE = el valor
	ld hl,00000h		;5c42
L_5C45:
	rlc c		;5c45   ; por cada bit de A, del alto...
	jp nc,L_5C4B		;5c47
	add hl,de			;5c4a   ; ...suma...
L_5C4B:
	bit 7,d		;5c4b   ; ...y luego DE a la mitad
	jp z,L_5C51		;5c4d
	inc de			;5c50
L_5C51:
	sra d		;5c51
	rr e		;5c53
	djnz L_5C45		;5c55
	ret			;5c57
por_a_bit7_doble:		; como 0x5C3E, con el bit 7 de A valiendo el doble
	ld c,a			;5c58
	ex de,hl			;5c59   ; DE = el valor
	ld hl,00000h		;5c5a
	rlc c		;5c5d   ; el bit 7...
	jp nc,L_5C69		;5c5f
	push de			;5c62
	sla e		;5c63   ; ...vale DE * 2
	rl d		;5c65
	add hl,de			;5c67
	pop de			;5c68
L_5C69:
	ld b,007h		;5c69   ; los otros siete
L_5C6B:
	rlc c		;5c6b   ; del alto...
	jp nc,L_5C71		;5c6d
	add hl,de			;5c70   ; ...suma...
L_5C71:
	bit 7,d		;5c71   ; ...y luego DE a la mitad
	jp z,L_5C77		;5c73
	inc de			;5c76
L_5C77:
	sra d		;5c77
	rr e		;5c79
	djnz L_5C6B		;5c7b
	ret			;5c7d
amplitud:		; la muestra por el LFO del DCA y por el nivel de la envolvente del DCA
	push af			;5c7e   ; la muestra
	ld a,(0dc08h)		;5c7f   ; sin LFO del DCA, directo al volumen
	or a			;5c82
	jp z,L_5CB1		;5c83
	ld d,a			;5c86   ; D y C = LFO del DCA
	ld c,a			;5c87
	ld a,(0dc45h)		;5c88   ; el factor: 0x80 - LFO + LFO por la onda del LFO
	call multiplica_con_signo		;5c8b   ; el valor del LFO por LFO del DCA
	ld c,a			;5c8e
	ld a,080h		;5c8f
	sub d			;5c91
	add a,c			;5c92
	ld c,a			;5c93
	pop af			;5c94
	call multiplica_con_signo		;5c95   ; la muestra por el factor
por_el_dca:		; A = E con signo por el nivel 0xDC30 / 128
	ld e,a			;5c98   ; E = la muestra
	ld a,(0dc30h)		;5c99   ; C = el nivel del DCA
	ld c,a			;5c9c
	ld b,007h		;5c9d   ; 7 bits
	xor a			;5c9f
L_5CA0:
	bit 7,e		;5ca0   ; E a la mitad, redondeando hacia el cero...
	jp z,L_5CA6		;5ca2
	inc e			;5ca5
L_5CA6:
	sra e		;5ca6
	rlc c		;5ca8   ; ...y por cada bit del nivel...
	jp nc,L_5CAE		;5caa
	add a,e			;5cad   ; ...suma
L_5CAE:
	djnz L_5CA0		;5cae
	ret			;5cb0
L_5CB1:
	pop af			;5cb1   ; sin LFO, la muestra tal cual
	jp por_el_dca		;5cb2
multiplica_con_signo:		; A = suma de E >> k (E con signo) por cada bit de C
	ld e,a			;5cb5   ; E = el valor con signo
	ld b,008h		;5cb6
	xor a			;5cb8
L_5CB9:
	rlc c		;5cb9   ; por cada bit de C, del alto...
	jp nc,L_5CBF		;5cbb
	add a,e			;5cbe   ; ...suma...
L_5CBF:
	bit 7,e		;5cbf   ; ...y E a la mitad con signo
	jp z,L_5CC5		;5cc1
	inc e			;5cc4
L_5CC5:
	sra e		;5cc5
	djnz L_5CB9		;5cc7
	ret			;5cc9
lfo:		; salta por 0xDC40: 0x5CCE o 0x5D39
	ld hl,(0dc40h)		;5cca   ; la rutina del LFO
	jp (hl)			;5ccd
lfo_paso:		; cada (retencion + 1) muestras toma el valor de la onda del LFO; la fase avanza FEET * 16
	ld a,(0dc02h)		;5cce   ; algun LFO puesto?
	ld b,a			;5cd1
	ld a,(0dc06h)		;5cd2
	or b			;5cd5
	ld b,a			;5cd6
	ld a,(0dc08h)		;5cd7
	or b			;5cda
	ret z			;5cdb   ; ninguno: nada
	ld a,(0dc16h)		;5cdc   ; onda 15 o mas: muestreo y retencion
	cp 00fh		;5cdf
	jp nc,lfo_ruido		;5ce1
	ld a,(0dc46h)		;5ce4   ; 0xDC46: la cuenta de la retencion
	dec a			;5ce7   ; una muestra menos
	cp 0ffh		;5ce8
	jp nz,L_5CF7		;5cea
	ld hl,(0dc43h)		;5ced   ; se acabo la cuenta: el valor nuevo, 0xDC45
	ld a,(hl)			;5cf0   ; el valor de la onda en la fase
	ld (0dc45h),a		;5cf1
	ld a,(0dc15h)		;5cf4   ; la retencion otra vez
L_5CF7:
	ld (0dc46h),a		;5cf7
	ld hl,(0dc42h)		;5cfa   ; la fase del LFO avanza FEET del LFO * 16
	ld a,(0dc17h)		;5cfd   ; FEET del LFO...
	ld e,a			;5d00
	ld d,000h		;5d01
	sla e		;5d03   ; ...por 16
	rl d		;5d05
	sla e		;5d07
	rl d		;5d09
	sla e		;5d0b
	rl d		;5d0d
	sla e		;5d0f
	rl d		;5d11
	add hl,de			;5d13   ; a la fase
	ld (0dc42h),hl		;5d14
	ret			;5d17
lfo_ruido:		; muestreo y retencion: el valor nuevo sale del ruido (como 0x5AD4)
	ld a,(0dc46h)		;5d18   ; la cuenta
	dec a			;5d1b
	cp 0ffh		;5d1c
	jp nz,L_5D36		;5d1e
	ld hl,(0dc35h)		;5d21   ; el ruido, como en 0x5AD4
	inc l			;5d24
	ld (0dc35h),hl		;5d25
	ld a,(hl)			;5d28
	ld hl,0dc34h		;5d29
	rlc a		;5d2c
	add a,(hl)			;5d2e
	ld (hl),a			;5d2f
	ld (0dc45h),a		;5d30   ; el valor nuevo
	ld a,(0dc15h)		;5d33   ; la retencion otra vez
L_5D36:
	ld (0dc46h),a		;5d36
lfo_apagado:		; sin LFO: nada
	ret			;5d39
play:		; PLAY: sin pagina de bucle (0xDCFD = 0) las rutinas de 0x6709; con bucle, las de 0x5E8B
	di			;5d3a
	ld a,(0dcfdh)		;5d3b   ; pagina de bucle?
	or a			;5d3e
	jp z,play_sin_bucle		;5d3f   ; no
	jp play_con_bucle		;5d42   ; si
busca_tecla:		; recorre las filas 0 a 7 hasta una con alguna tecla pulsada: NZ y A = la fila + 1; Z si no hay ninguna
	in a,(0aah)		;5d45   ; desde la fila 0
	and 0f0h		;5d47
	out (0aah),a		;5d49
L_5D4B:
	in a,(0a9h)		;5d4b   ; alguna pulsada en esta fila?
	inc a			;5d4d
	ret nz			;5d4e
	in a,(0aah)		;5d4f   ; la fila siguiente
	inc a			;5d51
	out (0aah),a		;5d52
	and 00fh		;5d54
	cp 008h		;5d56   ; hasta la 7
	jp c,L_5D4B		;5d58
	xor a			;5d5b
	ret			;5d5c
codigo_de_tecla:		; 0xDC47 = fila * 8 + bit + 1 de la tecla; C = la mascara de su bit
	push af			;5d5d
	ld a,080h		;5d5e   ; el DAC al reposo
	ld (04000h),a		;5d60
	pop af			;5d63
	dec a			;5d64   ; la fila menos uno...
	push af			;5d65
	cpl			;5d66   ; ...negada: el bit de la tecla
	ld c,a			;5d67
	pop af			;5d68
	ld e,0ffh		;5d69   ; E = el numero del bit
L_5D6B:
	inc e			;5d6b
	rrc a		;5d6c
	jp c,L_5D6B		;5d6e
	in a,(0aah)		;5d71   ; la fila
	and 007h		;5d73
	sla a		;5d75
	sla a		;5d77
	sla a		;5d79
	add a,e			;5d7b
	inc a			;5d7c
	ld (0dc47h),a		;5d7d   ; el codigo
	ret			;5d80
rutina_de_la_tecla:		; A = su rutina y D = su retardo (0xD22E + 2 * codigo); Z si la tecla no tiene nota (0xFF)
	sla a		;5d81   ; dos bytes por codigo
	ld e,a			;5d83
	ld d,000h		;5d84
	ld hl,0d22eh		;5d86   ; la tabla de teclas (0xD230 - 2)
	add hl,de			;5d89
	ld a,(hl)			;5d8a   ; A = la rutina
	inc hl			;5d8b
	ld d,(hl)			;5d8c   ; D = el retardo
	cp 0ffh		;5d8d   ; 0xFF: sin nota
	ret			;5d8f
pinta_tecla_pulsada:		; 0x4A14 guardando los registros
	push af			;5d90   ; guarda AF, BC y DE
	push bc			;5d91
	push de			;5d92
	call tecla_pulsada		;5d93   ; la tecla hundida
	pop de			;5d96
	pop bc			;5d97
	pop af			;5d98
	ret			;5d99
rutina_en_ix:		; IX = la palabra A de la tabla HL
	push de			;5d9a
	sla a		;5d9b   ; dos bytes por rutina
	ld e,a			;5d9d
	ld d,000h		;5d9e
	add hl,de			;5da0   ; la entrada A
	ld e,(hl)			;5da1   ; DE = la rutina
	inc hl			;5da2
	ld d,(hl)			;5da3
	push de			;5da4   ; a IX
	pop ix		;5da5
	pop de			;5da7
	ret			;5da8

; ----------------------------------------------------------------------
; DATOS teclas_de_fabrica: 0x80 bytes que 0x55DC copia a 0xD230: por tecla de
;   la matriz (fila * 8 + bit + 1, 0x5D5D), la rutina y el retardo D de su
;   nota; 0xFFFF sin nota
;   0x5da9..0x5e29  (128 bytes)
DATA_teclas_de_fabrica:
	defb 001h,007h	; 5da9
	defb 0ffh,0ffh	; 5dab
	defb 001h,015h	; 5dad
	defb 004h,012h	; 5daf
	defb 0ffh,0ffh	; 5db1
	defb 009h,00eh	; 5db3
	defb 008h,00ch	; 5db5
	defb 00bh,00ah	; 5db7
	defb 0ffh,0ffh	; 5db9
	defb 007h,008h	; 5dbb
	defb 0ffh,0ffh	; 5dbd
	defb 002h,005h	; 5dbf
	defb 002h,004h	; 5dc1
	defb 00bh,005h	; 5dc3
	defb 00ah,004h	; 5dc5
	defb 00bh,019h	; 5dc7
	defb 0ffh,0ffh	; 5dc9
	defb 0ffh,0ffh	; 5dcb
	defb 006h,01fh	; 5dcd
	defb 007h,01bh	; 5dcf
	defb 001h,018h	; 5dd1
	defb 0ffh,0ffh	; 5dd3
	defb 005h,047h	; 5dd5
	defb 007h,02bh	; 5dd7
	defb 007h,034h	; 5dd9
	defb 00bh,037h	; 5ddb
	defb 000h,011h	; 5ddd
	defb 0ffh,0ffh	; 5ddf
	defb 003h,02eh	; 5de1
	defb 00ah,028h	; 5de3
	defb 002h,009h	; 5de5
	defb 0ffh,0ffh	; 5de7
	defb 008h,021h	; 5de9
	defb 006h,01dh	; 5deb
	defb 00ch,023h	; 5ded
	defb 002h,026h	; 5def
	defb 009h,007h	; 5df1
	defb 006h,006h	; 5df3
	defb 007h,016h	; 5df5
	defb 00bh,00fh	; 5df7
	defb 000h,03fh	; 5df9
	defb 008h,00dh	; 5dfb
	defb 00ch,009h	; 5dfd
	defb 003h,031h	; 5dff
	defb 008h,013h	; 5e01
	defb 004h,03bh	; 5e03
	defb 009h,00bh	; 5e05
	defb 001h,043h	; 5e07
	defb 0ffh,0ffh	; 5e09
	defb 0ffh,0ffh	; 5e0b
	defb 0ffh,0ffh	; 5e0d
	defb 0ffh,0ffh	; 5e0f
	defb 0ffh,0ffh	; 5e11
	defb 0ffh,0ffh	; 5e13
	defb 0ffh,0ffh	; 5e15
	defb 0ffh,0ffh	; 5e17
	defb 0ffh,0ffh	; 5e19
	defb 0ffh,0ffh	; 5e1b
	defb 0ffh,0ffh	; 5e1d
	defb 0ffh,0ffh	; 5e1f
	defb 0ffh,0ffh	; 5e21
	defb 0ffh,0ffh	; 5e23
	defb 0ffh,0ffh	; 5e25
	defb 0ffh,0ffh	; 5e27

; ----------------------------------------------------------------------
; DATOS rutina_y_retardo_por_nota: las 49 posiciones de 0xBCCA, de FA1 a SI4:
;   rutina (0-12) y retardo D; la muestra dura c(rutina) + 16 * D ciclos.
;   0xBBDA la copia a la tecla al cambiar la disposicion; 0xFFFF en los huecos
;   sin negra
;   0x5e29..0x5e8b  (98 bytes)
DATA_rutina_y_retardo_por_nota:
	defb 000h,04ch	; 5e29
	defb 005h,047h	; 5e2b
	defb 001h,043h	; 5e2d
	defb 000h,03fh	; 5e2f
	defb 004h,03bh	; 5e31
	defb 00bh,037h	; 5e33
	defb 007h,034h	; 5e35
	defb 0ffh,0ffh	; 5e37
	defb 003h,031h	; 5e39
	defb 003h,02eh	; 5e3b
	defb 007h,02bh	; 5e3d
	defb 00ah,028h	; 5e3f
	defb 002h,026h	; 5e41
	defb 0ffh,0ffh	; 5e43
	defb 00ch,023h	; 5e45
	defb 008h,021h	; 5e47
	defb 006h,01fh	; 5e49
	defb 006h,01dh	; 5e4b
	defb 007h,01bh	; 5e4d
	defb 00bh,019h	; 5e4f
	defb 001h,018h	; 5e51
	defb 0ffh,0ffh	; 5e53
	defb 007h,016h	; 5e55
	defb 001h,015h	; 5e57
	defb 008h,013h	; 5e59
	defb 004h,012h	; 5e5b
	defb 000h,011h	; 5e5d
	defb 0ffh,0ffh	; 5e5f
	defb 00bh,00fh	; 5e61
	defb 009h,00eh	; 5e63
	defb 008h,00dh	; 5e65
	defb 008h,00ch	; 5e67
	defb 009h,00bh	; 5e69
	defb 00bh,00ah	; 5e6b
	defb 00ch,009h	; 5e6d
	defb 0ffh,0ffh	; 5e6f
	defb 002h,009h	; 5e71
	defb 007h,008h	; 5e73
	defb 009h,007h	; 5e75
	defb 001h,007h	; 5e77
	defb 006h,006h	; 5e79
	defb 0ffh,0ffh	; 5e7b
	defb 00bh,005h	; 5e7d
	defb 002h,005h	; 5e7f
	defb 00ah,004h	; 5e81
	defb 002h,004h	; 5e83
	defb 00ah,003h	; 5e85
	defb 005h,003h	; 5e87
	defb 00bh,002h	; 5e89

; ----------------------------------------------------------------------
; DATOS reproduce_con_bucle: 13 rutinas de PLAY, el mismo bucle con 67 a 82
;   ciclos fuera del retardo: el ajuste fino de la afinacion. La nota (0x5E29)
;   elige una y 0x5D9A la carga en IX. Con pagina de bucle (0xDCFD)
;   0x5e8b..0x5ea5  (26 bytes)
DATA_reproduce_con_bucle:
	defw 05ec9h,05f56h,05ff4h,060a2h,06150h,061e5h,0628bh,06339h	; 5e8b
	defw 063d6h,06473h,06510h,065adh,06652h	; 5e9b

; ======================================================================
; CODIGO 0x5ea5..0x6709  (2148 bytes)
; ======================================================================


play_con_bucle:		; PLAY con pagina de bucle: espera tecla y toca con la tabla 0x5E8B
	call busca_tecla		;5ea5   ; ninguna tecla: vuelve
	ret z			;5ea8
nota_con_bucle:		; la nota de la tecla pulsada
	call codigo_de_tecla		;5ea9   ; 0xDC47 y la mascara
	call rutina_de_la_tecla		;5eac   ; su rutina y su retardo
	ret z			;5eaf
	call pinta_tecla_pulsada		;5eb0   ; la tecla hundida en pantalla
	ld hl,05e8bh		;5eb3   ; IX = la rutina
	call rutina_en_ix		;5eb6
	push bc			;5eb9
	push de			;5eba
	call ram_en_la_pagina_2		;5ebb   ; la RAM del sample
	pop de			;5ebe
	pop bc			;5ebf
	ld hl,08000h		;5ec0   ; desde 0x8000...
	ld a,(0dcfdh)		;5ec3   ; ...hasta la pagina de bucle (E)
	ld e,a			;5ec6
	jp (ix)		;5ec7   ; a la rutina
con_bucle_01:		; rutina 1 de 0x5E8B: hasta la pagina de bucle; en ella mientras se tiene la tecla; al soltar, hasta 0xC000 mirando si hay otra
	ld a,(hl)			;5ec9   ; la muestra...
	ld (04000h),a		;5eca   ; ...al DAC
	inc hl			;5ecd
	ld a,d			;5ece   ; el retardo D
L_5ECF:
	dec a			;5ecf
	jp nz,L_5ECF		;5ed0
	nop			;5ed3   ; relleno: iguala los ciclos
	in a,(0a9h)		;5ed4   ; la fila de la tecla:
	and c			;5ed6   ; su bit a 1, suelta
	jp nz,con_bucle_01_suelta		;5ed7
	ld a,(hl)			;5eda   ; la muestra...
	ld (04000h),a		;5edb   ; ...al DAC
	inc hl			;5ede
	ld a,d			;5edf   ; el retardo D
L_5EE0:
	dec a			;5ee0
	jp nz,L_5EE0		;5ee1
	cp 000h		;5ee4   ; relleno: iguala los ciclos
	nop			;5ee6   ; relleno: iguala los ciclos
	ld a,e			;5ee7   ; en la pagina de bucle?
	cp h			;5ee8
	jp nz,con_bucle_01		;5ee9
con_bucle_01_repite:		; la pagina de bucle una y otra vez mientras la tecla sigue pulsada
	ld a,(hl)			;5eec   ; la muestra...
	ld (04000h),a		;5eed   ; ...al DAC
	inc hl			;5ef0
	ld a,d			;5ef1   ; el retardo D
L_5EF2:
	dec a			;5ef2
	jp nz,L_5EF2		;5ef3
	ld h,e			;5ef6   ; se queda en la pagina de bucle
	in a,(0a9h)		;5ef7   ; la fila de la tecla:
	and c			;5ef9   ; su bit a 1, suelta
	jp z,con_bucle_01_repite		;5efa
con_bucle_01_suelta:		; tecla suelta: acaba la pagina en curso
	ld a,(hl)			;5efd   ; la muestra...
	ld (04000h),a		;5efe   ; ...al DAC
	inc hl			;5f01
	ld a,d			;5f02   ; el retardo D
L_5F03:
	dec a			;5f03
	jp nz,L_5F03		;5f04
	cp 000h		;5f07   ; relleno: iguala los ciclos
	nop			;5f09   ; relleno: iguala los ciclos
	ld a,l			;5f0a   ; hasta acabar la pagina
	or a			;5f0b
	jp nz,con_bucle_01_suelta		;5f0c
con_bucle_01_cola:		; el resto del sample hasta 0xC000, mirando una fila del teclado cada cuatro muestras
	ld a,(hl)			;5f0f   ; la muestra...
	ld (04000h),a		;5f10   ; ...al DAC
	inc hl			;5f13
	ld a,d			;5f14   ; el retardo D
L_5F15:
	dec a			;5f15
	jp nz,L_5F15		;5f16
	inc ix		;5f19   ; relleno: iguala los ciclos
	in a,(0aah)		;5f1b   ; la fila siguiente...
	inc a			;5f1d
	ld e,a			;5f1e
	ld a,(hl)			;5f1f   ; la muestra...
	ld (04000h),a		;5f20   ; ...al DAC
	inc hl			;5f23
	ld a,d			;5f24   ; el retardo D
L_5F25:
	dec a			;5f25
	jp nz,L_5F25		;5f26
	cp 000h		;5f29   ; relleno: iguala los ciclos
	ld a,e			;5f2b
	and 0f7h		;5f2c   ; ...de la 0 a la 7
	out (0aah),a		;5f2e
	ld a,(hl)			;5f30   ; la muestra...
	ld (04000h),a		;5f31   ; ...al DAC
	inc hl			;5f34
	ld a,d			;5f35   ; el retardo D
L_5F36:
	dec a			;5f36
	jp nz,L_5F36		;5f37
	nop			;5f3a   ; relleno: iguala los ciclos
	in a,(0a9h)		;5f3b   ; alguna tecla en esta fila?
	inc a			;5f3d
	jp nz,otra_nota_con_bucle		;5f3e
	ld a,(hl)			;5f41   ; la muestra...
	ld (04000h),a		;5f42   ; ...al DAC
	inc hl			;5f45
	ld a,d			;5f46   ; el retardo D
L_5F47:
	dec a			;5f47
	jp nz,L_5F47		;5f48
	neg		;5f4b   ; relleno: iguala los ciclos
	ld a,0c0h		;5f4d   ; hasta el final del sample
	cp h			;5f4f
	jp nz,con_bucle_01_cola		;5f50
	jp fin_de_nota		;5f53
con_bucle_02:		; rutina 2 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	dec d			;5f56   ; D - 1 para esta rutina
L_5F57:
	ld a,(hl)			;5f57   ; la muestra...
	ld (04000h),a		;5f58   ; ...al DAC
	inc hl			;5f5b
	ld a,d			;5f5c   ; el retardo D
L_5F5D:
	dec a			;5f5d
	jp nz,L_5F5D		;5f5e
	add ix,ix		;5f61   ; relleno: iguala los ciclos
	nop			;5f63   ; relleno: iguala los ciclos
	in a,(0a9h)		;5f64   ; la fila de la tecla:
	and c			;5f66   ; su bit a 1, suelta
	jp nz,L_5F91		;5f67
	ld a,(hl)			;5f6a   ; la muestra...
	ld (04000h),a		;5f6b   ; ...al DAC
	inc hl			;5f6e
	ld a,d			;5f6f   ; el retardo D
L_5F70:
	dec a			;5f70
	jp nz,L_5F70		;5f71
	add ix,ix		;5f74   ; relleno: iguala los ciclos
	cp 000h		;5f76   ; relleno: iguala los ciclos
	nop			;5f78   ; relleno: iguala los ciclos
	ld a,e			;5f79   ; en la pagina de bucle?
	cp h			;5f7a
	jp nz,L_5F57		;5f7b
L_5F7E:
	ld a,(hl)			;5f7e   ; la muestra...
	ld (04000h),a		;5f7f   ; ...al DAC
	inc hl			;5f82
	ld a,d			;5f83   ; el retardo D
L_5F84:
	dec a			;5f84
	jp nz,L_5F84		;5f85
	add ix,ix		;5f88   ; relleno: iguala los ciclos
	ld h,e			;5f8a   ; se queda en la pagina de bucle
	in a,(0a9h)		;5f8b   ; la fila de la tecla:
	and c			;5f8d   ; su bit a 1, suelta
	jp z,L_5F7E		;5f8e
L_5F91:
	ld a,(hl)			;5f91   ; la muestra...
	ld (04000h),a		;5f92   ; ...al DAC
	inc hl			;5f95
	ld a,d			;5f96   ; el retardo D
L_5F97:
	dec a			;5f97
	jp nz,L_5F97		;5f98
	add ix,ix		;5f9b   ; relleno: iguala los ciclos
	cp 000h		;5f9d   ; relleno: iguala los ciclos
	nop			;5f9f   ; relleno: iguala los ciclos
	ld a,l			;5fa0   ; hasta acabar la pagina
	or a			;5fa1
	jp nz,L_5F91		;5fa2
L_5FA5:
	ld a,(hl)			;5fa5   ; la muestra...
	ld (04000h),a		;5fa6   ; ...al DAC
	inc hl			;5fa9
	ld a,d			;5faa   ; el retardo D
L_5FAB:
	dec a			;5fab
	jp nz,L_5FAB		;5fac
	add ix,ix		;5faf   ; relleno: iguala los ciclos
	inc ix		;5fb1   ; relleno: iguala los ciclos
	in a,(0aah)		;5fb3   ; la fila siguiente...
	inc a			;5fb5
	ld e,a			;5fb6
	ld a,(hl)			;5fb7   ; la muestra...
	ld (04000h),a		;5fb8   ; ...al DAC
	inc hl			;5fbb
	ld a,d			;5fbc   ; el retardo D
L_5FBD:
	dec a			;5fbd
	jp nz,L_5FBD		;5fbe
	add ix,ix		;5fc1   ; relleno: iguala los ciclos
	cp 000h		;5fc3   ; relleno: iguala los ciclos
	ld a,e			;5fc5
	and 0f7h		;5fc6   ; ...de la 0 a la 7
	out (0aah),a		;5fc8
	ld a,(hl)			;5fca   ; la muestra...
	ld (04000h),a		;5fcb   ; ...al DAC
	inc hl			;5fce
	ld a,d			;5fcf   ; el retardo D
L_5FD0:
	dec a			;5fd0
	jp nz,L_5FD0		;5fd1
	add ix,ix		;5fd4   ; relleno: iguala los ciclos
	nop			;5fd6   ; relleno: iguala los ciclos
	in a,(0a9h)		;5fd7   ; alguna tecla en esta fila?
	inc a			;5fd9
	jp nz,otra_nota_con_bucle		;5fda
	ld a,(hl)			;5fdd   ; la muestra...
	ld (04000h),a		;5fde   ; ...al DAC
	inc hl			;5fe1
	ld a,d			;5fe2   ; el retardo D
L_5FE3:
	dec a			;5fe3
	jp nz,L_5FE3		;5fe4
	add ix,ix		;5fe7   ; relleno: iguala los ciclos
	neg		;5fe9   ; relleno: iguala los ciclos
	ld a,0c0h		;5feb   ; hasta el final del sample
	cp h			;5fed
	jp nz,L_5FA5		;5fee
	jp fin_de_nota		;5ff1
con_bucle_03:		; rutina 3 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	dec d			;5ff4   ; D - 1 para esta rutina
L_5FF5:
	ld a,(hl)			;5ff5   ; la muestra...
	ld (04000h),a		;5ff6   ; ...al DAC
	inc hl			;5ff9
	ld a,d			;5ffa   ; el retardo D
L_5FFB:
	dec a			;5ffb
	jp nz,L_5FFB		;5ffc
	neg		;5fff   ; relleno: iguala los ciclos
	neg		;6001   ; relleno: iguala los ciclos
	nop			;6003   ; relleno: iguala los ciclos
	in a,(0a9h)		;6004   ; la fila de la tecla:
	and c			;6006   ; su bit a 1, suelta
	jp nz,L_6035		;6007
	ld a,(hl)			;600a   ; la muestra...
	ld (04000h),a		;600b   ; ...al DAC
	inc hl			;600e
	ld a,d			;600f   ; el retardo D
L_6010:
	dec a			;6010
	jp nz,L_6010		;6011
	neg		;6014   ; relleno: iguala los ciclos
	neg		;6016   ; relleno: iguala los ciclos
	cp 000h		;6018   ; relleno: iguala los ciclos
	nop			;601a   ; relleno: iguala los ciclos
	ld a,e			;601b   ; en la pagina de bucle?
	cp h			;601c
	jp nz,L_5FF5		;601d
L_6020:
	ld a,(hl)			;6020   ; la muestra...
	ld (04000h),a		;6021   ; ...al DAC
	inc hl			;6024
	ld a,d			;6025   ; el retardo D
L_6026:
	dec a			;6026
	jp nz,L_6026		;6027
	neg		;602a   ; relleno: iguala los ciclos
	neg		;602c   ; relleno: iguala los ciclos
	ld h,e			;602e   ; se queda en la pagina de bucle
	in a,(0a9h)		;602f   ; la fila de la tecla:
	and c			;6031   ; su bit a 1, suelta
	jp z,L_6020		;6032
L_6035:
	ld a,(hl)			;6035   ; la muestra...
	ld (04000h),a		;6036   ; ...al DAC
	inc hl			;6039
	ld a,d			;603a   ; el retardo D
L_603B:
	dec a			;603b
	jp nz,L_603B		;603c
	neg		;603f   ; relleno: iguala los ciclos
	neg		;6041   ; relleno: iguala los ciclos
	cp 000h		;6043   ; relleno: iguala los ciclos
	nop			;6045   ; relleno: iguala los ciclos
	ld a,l			;6046   ; hasta acabar la pagina
	or a			;6047
	jp nz,L_6035		;6048
L_604B:
	ld a,(hl)			;604b   ; la muestra...
	ld (04000h),a		;604c   ; ...al DAC
	inc hl			;604f
	ld a,d			;6050   ; el retardo D
L_6051:
	dec a			;6051
	jp nz,L_6051		;6052
	neg		;6055   ; relleno: iguala los ciclos
	neg		;6057   ; relleno: iguala los ciclos
	inc ix		;6059   ; relleno: iguala los ciclos
	in a,(0aah)		;605b   ; la fila siguiente...
	inc a			;605d
	ld e,a			;605e
	ld a,(hl)			;605f   ; la muestra...
	ld (04000h),a		;6060   ; ...al DAC
	inc hl			;6063
	ld a,d			;6064   ; el retardo D
L_6065:
	dec a			;6065
	jp nz,L_6065		;6066
	neg		;6069   ; relleno: iguala los ciclos
	neg		;606b   ; relleno: iguala los ciclos
	cp 000h		;606d   ; relleno: iguala los ciclos
	ld a,e			;606f
	and 0f7h		;6070   ; ...de la 0 a la 7
	out (0aah),a		;6072
	ld a,(hl)			;6074   ; la muestra...
	ld (04000h),a		;6075   ; ...al DAC
	inc hl			;6078
	ld a,d			;6079   ; el retardo D
L_607A:
	dec a			;607a
	jp nz,L_607A		;607b
	neg		;607e   ; relleno: iguala los ciclos
	neg		;6080   ; relleno: iguala los ciclos
	nop			;6082   ; relleno: iguala los ciclos
	in a,(0a9h)		;6083   ; alguna tecla en esta fila?
	inc a			;6085
	jp nz,otra_nota_con_bucle		;6086
	ld a,(hl)			;6089   ; la muestra...
	ld (04000h),a		;608a   ; ...al DAC
	inc hl			;608d
	ld a,d			;608e   ; el retardo D
L_608F:
	dec a			;608f
	jp nz,L_608F		;6090
	neg		;6093   ; relleno: iguala los ciclos
	neg		;6095   ; relleno: iguala los ciclos
	neg		;6097   ; relleno: iguala los ciclos
	ld a,0c0h		;6099   ; hasta el final del sample
	cp h			;609b
	jp nz,L_604B		;609c
	jp fin_de_nota		;609f
con_bucle_04:		; rutina 4 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	dec d			;60a2   ; D - 1 para esta rutina
L_60A3:
	ld a,(hl)			;60a3   ; la muestra...
	ld (04000h),a		;60a4   ; ...al DAC
	inc hl			;60a7
	ld a,d			;60a8   ; el retardo D
L_60A9:
	dec a			;60a9
	jp nz,L_60A9		;60aa
	inc ix		;60ad   ; relleno: iguala los ciclos
	cp 000h		;60af   ; relleno: iguala los ciclos
	nop			;60b1   ; relleno: iguala los ciclos
	in a,(0a9h)		;60b2   ; la fila de la tecla:
	and c			;60b4   ; su bit a 1, suelta
	jp nz,L_60E3		;60b5
	ld a,(hl)			;60b8   ; la muestra...
	ld (04000h),a		;60b9   ; ...al DAC
	inc hl			;60bc
	ld a,d			;60bd   ; el retardo D
L_60BE:
	dec a			;60be
	jp nz,L_60BE		;60bf
	inc ix		;60c2   ; relleno: iguala los ciclos
	cp 000h		;60c4   ; relleno: iguala los ciclos
	cp 000h		;60c6   ; relleno: iguala los ciclos
	nop			;60c8   ; relleno: iguala los ciclos
	ld a,e			;60c9   ; en la pagina de bucle?
	cp h			;60ca
	jp nz,L_60A3		;60cb
L_60CE:
	ld a,(hl)			;60ce   ; la muestra...
	ld (04000h),a		;60cf   ; ...al DAC
	inc hl			;60d2
	ld a,d			;60d3   ; el retardo D
L_60D4:
	dec a			;60d4
	jp nz,L_60D4		;60d5
	inc ix		;60d8   ; relleno: iguala los ciclos
	cp 000h		;60da   ; relleno: iguala los ciclos
	ld h,e			;60dc   ; se queda en la pagina de bucle
	in a,(0a9h)		;60dd   ; la fila de la tecla:
	and c			;60df   ; su bit a 1, suelta
	jp z,L_60CE		;60e0
L_60E3:
	ld a,(hl)			;60e3   ; la muestra...
	ld (04000h),a		;60e4   ; ...al DAC
	inc hl			;60e7
	ld a,d			;60e8   ; el retardo D
L_60E9:
	dec a			;60e9
	jp nz,L_60E9		;60ea
	inc ix		;60ed   ; relleno: iguala los ciclos
	cp 000h		;60ef   ; relleno: iguala los ciclos
	cp 000h		;60f1   ; relleno: iguala los ciclos
	nop			;60f3   ; relleno: iguala los ciclos
	ld a,l			;60f4   ; hasta acabar la pagina
	or a			;60f5
	jp nz,L_60E3		;60f6
L_60F9:
	ld a,(hl)			;60f9   ; la muestra...
	ld (04000h),a		;60fa   ; ...al DAC
	inc hl			;60fd
	ld a,d			;60fe   ; el retardo D
L_60FF:
	dec a			;60ff
	jp nz,L_60FF		;6100
	inc ix		;6103   ; relleno: iguala los ciclos
	cp 000h		;6105   ; relleno: iguala los ciclos
	inc ix		;6107   ; relleno: iguala los ciclos
	in a,(0aah)		;6109   ; la fila siguiente...
	inc a			;610b
	ld e,a			;610c
	ld a,(hl)			;610d   ; la muestra...
	ld (04000h),a		;610e   ; ...al DAC
	inc hl			;6111
	ld a,d			;6112   ; el retardo D
L_6113:
	dec a			;6113
	jp nz,L_6113		;6114
	inc ix		;6117   ; relleno: iguala los ciclos
	cp 000h		;6119   ; relleno: iguala los ciclos
	cp 000h		;611b   ; relleno: iguala los ciclos
	ld a,e			;611d
	and 0f7h		;611e   ; ...de la 0 a la 7
	out (0aah),a		;6120
	ld a,(hl)			;6122   ; la muestra...
	ld (04000h),a		;6123   ; ...al DAC
	inc hl			;6126
	ld a,d			;6127   ; el retardo D
L_6128:
	dec a			;6128
	jp nz,L_6128		;6129
	inc ix		;612c   ; relleno: iguala los ciclos
	cp 000h		;612e   ; relleno: iguala los ciclos
	nop			;6130   ; relleno: iguala los ciclos
	in a,(0a9h)		;6131   ; alguna tecla en esta fila?
	inc a			;6133
	jp nz,otra_nota_con_bucle		;6134
	ld a,(hl)			;6137   ; la muestra...
	ld (04000h),a		;6138   ; ...al DAC
	inc hl			;613b
	ld a,d			;613c   ; el retardo D
L_613D:
	dec a			;613d
	jp nz,L_613D		;613e
	inc ix		;6141   ; relleno: iguala los ciclos
	cp 000h		;6143   ; relleno: iguala los ciclos
	neg		;6145   ; relleno: iguala los ciclos
	ld a,0c0h		;6147   ; hasta el final del sample
	cp h			;6149
	jp nz,L_60F9		;614a
	jp fin_de_nota		;614d
con_bucle_05:		; rutina 5 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;6150   ; la muestra...
	ld (04000h),a		;6151   ; ...al DAC
	inc hl			;6154
	ld a,d			;6155   ; el retardo D
L_6156:
	dec a			;6156
	jp nz,L_6156		;6157
	nop			;615a   ; relleno: iguala los ciclos
	nop			;615b   ; relleno: iguala los ciclos
	in a,(0a9h)		;615c   ; la fila de la tecla:
	and c			;615e   ; su bit a 1, suelta
	jp nz,L_6187		;615f
	ld a,(hl)			;6162   ; la muestra...
	ld (04000h),a		;6163   ; ...al DAC
	inc hl			;6166
	ld a,d			;6167   ; el retardo D
L_6168:
	dec a			;6168
	jp nz,L_6168		;6169
	nop			;616c   ; relleno: iguala los ciclos
	cp 000h		;616d   ; relleno: iguala los ciclos
	nop			;616f   ; relleno: iguala los ciclos
	ld a,e			;6170   ; en la pagina de bucle?
	cp h			;6171
	jp nz,con_bucle_05		;6172
L_6175:
	ld a,(hl)			;6175   ; la muestra...
	ld (04000h),a		;6176   ; ...al DAC
	inc hl			;6179
	ld a,d			;617a   ; el retardo D
L_617B:
	dec a			;617b
	jp nz,L_617B		;617c
	nop			;617f   ; relleno: iguala los ciclos
	ld h,e			;6180   ; se queda en la pagina de bucle
	in a,(0a9h)		;6181   ; la fila de la tecla:
	and c			;6183   ; su bit a 1, suelta
	jp z,L_6175		;6184
L_6187:
	ld a,(hl)			;6187   ; la muestra...
	ld (04000h),a		;6188   ; ...al DAC
	inc hl			;618b
	ld a,d			;618c   ; el retardo D
L_618D:
	dec a			;618d
	jp nz,L_618D		;618e
	nop			;6191   ; relleno: iguala los ciclos
	cp 000h		;6192   ; relleno: iguala los ciclos
	nop			;6194   ; relleno: iguala los ciclos
	ld a,l			;6195   ; hasta acabar la pagina
	or a			;6196
	jp nz,L_6187		;6197
L_619A:
	ld a,(hl)			;619a   ; la muestra...
	ld (04000h),a		;619b   ; ...al DAC
	inc hl			;619e
	ld a,d			;619f   ; el retardo D
L_61A0:
	dec a			;61a0
	jp nz,L_61A0		;61a1
	nop			;61a4   ; relleno: iguala los ciclos
	inc ix		;61a5   ; relleno: iguala los ciclos
	in a,(0aah)		;61a7   ; la fila siguiente...
	inc a			;61a9
	ld e,a			;61aa
	ld a,(hl)			;61ab   ; la muestra...
	ld (04000h),a		;61ac   ; ...al DAC
	inc hl			;61af
	ld a,d			;61b0   ; el retardo D
L_61B1:
	dec a			;61b1
	jp nz,L_61B1		;61b2
	nop			;61b5   ; relleno: iguala los ciclos
	cp 000h		;61b6   ; relleno: iguala los ciclos
	ld a,e			;61b8
	and 0f7h		;61b9   ; ...de la 0 a la 7
	out (0aah),a		;61bb
	ld a,(hl)			;61bd   ; la muestra...
	ld (04000h),a		;61be   ; ...al DAC
	inc hl			;61c1
	ld a,d			;61c2   ; el retardo D
L_61C3:
	dec a			;61c3
	jp nz,L_61C3		;61c4
	nop			;61c7   ; relleno: iguala los ciclos
	nop			;61c8   ; relleno: iguala los ciclos
	in a,(0a9h)		;61c9   ; alguna tecla en esta fila?
	inc a			;61cb
	jp nz,otra_nota_con_bucle		;61cc
	ld a,(hl)			;61cf   ; la muestra...
	ld (04000h),a		;61d0   ; ...al DAC
	inc hl			;61d3
	ld a,d			;61d4   ; el retardo D
L_61D5:
	dec a			;61d5
	jp nz,L_61D5		;61d6
	nop			;61d9   ; relleno: iguala los ciclos
	neg		;61da   ; relleno: iguala los ciclos
	ld a,0c0h		;61dc   ; hasta el final del sample
	cp h			;61de
	jp nz,L_619A		;61df
	jp fin_de_nota		;61e2
con_bucle_06:		; rutina 6 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	dec d			;61e5   ; D - 1 para esta rutina
L_61E6:
	ld a,(hl)			;61e6   ; la muestra...
	ld (04000h),a		;61e7   ; ...al DAC
	inc hl			;61ea
	ld a,d			;61eb   ; el retardo D
L_61EC:
	dec a			;61ec
	jp nz,L_61EC		;61ed
	add a,(ix+000h)		;61f0
	nop			;61f3   ; relleno: iguala los ciclos
	in a,(0a9h)		;61f4   ; la fila de la tecla:
	and c			;61f6   ; su bit a 1, suelta
	jp nz,L_6223		;61f7
	ld a,(hl)			;61fa   ; la muestra...
	ld (04000h),a		;61fb   ; ...al DAC
	inc hl			;61fe
	ld a,d			;61ff   ; el retardo D
L_6200:
	dec a			;6200
	jp nz,L_6200		;6201
	add a,(ix+000h)		;6204
	cp 000h		;6207   ; relleno: iguala los ciclos
	nop			;6209   ; relleno: iguala los ciclos
	ld a,e			;620a   ; en la pagina de bucle?
	cp h			;620b
	jp nz,L_61E6		;620c
L_620F:
	ld a,(hl)			;620f   ; la muestra...
	ld (04000h),a		;6210   ; ...al DAC
	inc hl			;6213
	ld a,d			;6214   ; el retardo D
L_6215:
	dec a			;6215
	jp nz,L_6215		;6216
	add a,(ix+000h)		;6219
	ld h,e			;621c   ; se queda en la pagina de bucle
	in a,(0a9h)		;621d   ; la fila de la tecla:
	and c			;621f   ; su bit a 1, suelta
	jp z,L_620F		;6220
L_6223:
	ld a,(hl)			;6223   ; la muestra...
	ld (04000h),a		;6224   ; ...al DAC
	inc hl			;6227
	ld a,d			;6228   ; el retardo D
L_6229:
	dec a			;6229
	jp nz,L_6229		;622a
	add a,(ix+000h)		;622d
	cp 000h		;6230   ; relleno: iguala los ciclos
	nop			;6232   ; relleno: iguala los ciclos
	ld a,l			;6233   ; hasta acabar la pagina
	or a			;6234
	jp nz,L_6223		;6235
L_6238:
	ld a,(hl)			;6238   ; la muestra...
	ld (04000h),a		;6239   ; ...al DAC
	inc hl			;623c
	ld a,d			;623d   ; el retardo D
L_623E:
	dec a			;623e
	jp nz,L_623E		;623f
	add a,(ix+000h)		;6242
	inc ix		;6245   ; relleno: iguala los ciclos
	in a,(0aah)		;6247   ; la fila siguiente...
	inc a			;6249
	ld e,a			;624a
	ld a,(hl)			;624b   ; la muestra...
	ld (04000h),a		;624c   ; ...al DAC
	inc hl			;624f
	ld a,d			;6250   ; el retardo D
L_6251:
	dec a			;6251
	jp nz,L_6251		;6252
	add a,(ix+000h)		;6255
	cp 000h		;6258   ; relleno: iguala los ciclos
	ld a,e			;625a
	and 0f7h		;625b   ; ...de la 0 a la 7
	out (0aah),a		;625d
	ld a,(hl)			;625f   ; la muestra...
	ld (04000h),a		;6260   ; ...al DAC
	inc hl			;6263
	ld a,d			;6264   ; el retardo D
L_6265:
	dec a			;6265
	jp nz,L_6265		;6266
	add a,(ix+000h)		;6269
	nop			;626c   ; relleno: iguala los ciclos
	in a,(0a9h)		;626d   ; alguna tecla en esta fila?
	inc a			;626f
	jp nz,otra_nota_con_bucle		;6270
	ld a,(hl)			;6273   ; la muestra...
	ld (04000h),a		;6274   ; ...al DAC
	inc hl			;6277
	ld a,d			;6278   ; el retardo D
L_6279:
	dec a			;6279
	jp nz,L_6279		;627a
	add a,(ix+000h)		;627d
	neg		;6280   ; relleno: iguala los ciclos
	ld a,0c0h		;6282   ; hasta el final del sample
	cp h			;6284
	jp nz,L_6238		;6285
	jp fin_de_nota		;6288
con_bucle_07:		; rutina 7 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	dec d			;628b   ; D - 1 para esta rutina
L_628C:
	ld a,(hl)			;628c   ; la muestra...
	ld (04000h),a		;628d   ; ...al DAC
	inc hl			;6290
	ld a,d			;6291   ; el retardo D
L_6292:
	dec a			;6292
	jp nz,L_6292		;6293
	inc ix		;6296   ; relleno: iguala los ciclos
	inc ix		;6298   ; relleno: iguala los ciclos
	nop			;629a   ; relleno: iguala los ciclos
	in a,(0a9h)		;629b   ; la fila de la tecla:
	and c			;629d   ; su bit a 1, suelta
	jp nz,L_62CC		;629e
	ld a,(hl)			;62a1   ; la muestra...
	ld (04000h),a		;62a2   ; ...al DAC
	inc hl			;62a5
	ld a,d			;62a6   ; el retardo D
L_62A7:
	dec a			;62a7
	jp nz,L_62A7		;62a8
	inc ix		;62ab   ; relleno: iguala los ciclos
	inc ix		;62ad   ; relleno: iguala los ciclos
	cp 000h		;62af   ; relleno: iguala los ciclos
	nop			;62b1   ; relleno: iguala los ciclos
	ld a,e			;62b2   ; en la pagina de bucle?
	cp h			;62b3
	jp nz,L_628C		;62b4
L_62B7:
	ld a,(hl)			;62b7   ; la muestra...
	ld (04000h),a		;62b8   ; ...al DAC
	inc hl			;62bb
	ld a,d			;62bc   ; el retardo D
L_62BD:
	dec a			;62bd
	jp nz,L_62BD		;62be
	inc ix		;62c1   ; relleno: iguala los ciclos
	inc ix		;62c3   ; relleno: iguala los ciclos
	ld h,e			;62c5   ; se queda en la pagina de bucle
	in a,(0a9h)		;62c6   ; la fila de la tecla:
	and c			;62c8   ; su bit a 1, suelta
	jp z,L_62B7		;62c9
L_62CC:
	ld a,(hl)			;62cc   ; la muestra...
	ld (04000h),a		;62cd   ; ...al DAC
	inc hl			;62d0
	ld a,d			;62d1   ; el retardo D
L_62D2:
	dec a			;62d2
	jp nz,L_62D2		;62d3
	inc ix		;62d6   ; relleno: iguala los ciclos
	inc ix		;62d8   ; relleno: iguala los ciclos
	cp 000h		;62da   ; relleno: iguala los ciclos
	nop			;62dc   ; relleno: iguala los ciclos
	ld a,l			;62dd   ; hasta acabar la pagina
	or a			;62de
	jp nz,L_62CC		;62df
L_62E2:
	ld a,(hl)			;62e2   ; la muestra...
	ld (04000h),a		;62e3   ; ...al DAC
	inc hl			;62e6
	ld a,d			;62e7   ; el retardo D
L_62E8:
	dec a			;62e8
	jp nz,L_62E8		;62e9
	inc ix		;62ec   ; relleno: iguala los ciclos
	inc ix		;62ee   ; relleno: iguala los ciclos
	inc ix		;62f0   ; relleno: iguala los ciclos
	in a,(0aah)		;62f2   ; la fila siguiente...
	inc a			;62f4
	ld e,a			;62f5
	ld a,(hl)			;62f6   ; la muestra...
	ld (04000h),a		;62f7   ; ...al DAC
	inc hl			;62fa
	ld a,d			;62fb   ; el retardo D
L_62FC:
	dec a			;62fc
	jp nz,L_62FC		;62fd
	inc ix		;6300   ; relleno: iguala los ciclos
	inc ix		;6302   ; relleno: iguala los ciclos
	cp 000h		;6304   ; relleno: iguala los ciclos
	ld a,e			;6306
	and 0f7h		;6307   ; ...de la 0 a la 7
	out (0aah),a		;6309
	ld a,(hl)			;630b   ; la muestra...
	ld (04000h),a		;630c   ; ...al DAC
	inc hl			;630f
	ld a,d			;6310   ; el retardo D
L_6311:
	dec a			;6311
	jp nz,L_6311		;6312
	inc ix		;6315   ; relleno: iguala los ciclos
	inc ix		;6317   ; relleno: iguala los ciclos
	nop			;6319   ; relleno: iguala los ciclos
	in a,(0a9h)		;631a   ; alguna tecla en esta fila?
	inc a			;631c
	jp nz,otra_nota_con_bucle		;631d
	ld a,(hl)			;6320   ; la muestra...
	ld (04000h),a		;6321   ; ...al DAC
	inc hl			;6324
	ld a,d			;6325   ; el retardo D
L_6326:
	dec a			;6326
	jp nz,L_6326		;6327
	inc ix		;632a   ; relleno: iguala los ciclos
	inc ix		;632c   ; relleno: iguala los ciclos
	neg		;632e   ; relleno: iguala los ciclos
	ld a,0c0h		;6330   ; hasta el final del sample
	cp h			;6332
	jp nz,L_62E2		;6333
	jp fin_de_nota		;6336
con_bucle_08:		; rutina 8 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;6339   ; la muestra...
	ld (04000h),a		;633a   ; ...al DAC
	inc hl			;633d
	ld a,d			;633e   ; el retardo D
L_633F:
	dec a			;633f
	jp nz,L_633F		;6340
	cp 000h		;6343   ; relleno: iguala los ciclos
	nop			;6345   ; relleno: iguala los ciclos
	in a,(0a9h)		;6346   ; la fila de la tecla:
	and c			;6348   ; su bit a 1, suelta
	jp nz,L_6373		;6349
	ld a,(hl)			;634c   ; la muestra...
	ld (04000h),a		;634d   ; ...al DAC
	inc hl			;6350
	ld a,d			;6351   ; el retardo D
L_6352:
	dec a			;6352
	jp nz,L_6352		;6353
	cp 000h		;6356   ; relleno: iguala los ciclos
	cp 000h		;6358   ; relleno: iguala los ciclos
	nop			;635a   ; relleno: iguala los ciclos
	ld a,e			;635b   ; en la pagina de bucle?
	cp h			;635c
	jp nz,con_bucle_08		;635d
L_6360:
	ld a,(hl)			;6360   ; la muestra...
	ld (04000h),a		;6361   ; ...al DAC
	inc hl			;6364
	ld a,d			;6365   ; el retardo D
L_6366:
	dec a			;6366
	jp nz,L_6366		;6367
	cp 000h		;636a   ; relleno: iguala los ciclos
	ld h,e			;636c   ; se queda en la pagina de bucle
	in a,(0a9h)		;636d   ; la fila de la tecla:
	and c			;636f   ; su bit a 1, suelta
	jp z,L_6360		;6370
L_6373:
	ld a,(hl)			;6373   ; la muestra...
	ld (04000h),a		;6374   ; ...al DAC
	inc hl			;6377
	ld a,d			;6378   ; el retardo D
L_6379:
	dec a			;6379
	jp nz,L_6379		;637a
	cp 000h		;637d   ; relleno: iguala los ciclos
	cp 000h		;637f   ; relleno: iguala los ciclos
	nop			;6381   ; relleno: iguala los ciclos
	ld a,l			;6382   ; hasta acabar la pagina
	or a			;6383
	jp nz,L_6373		;6384
L_6387:
	ld a,(hl)			;6387   ; la muestra...
	ld (04000h),a		;6388   ; ...al DAC
	inc hl			;638b
	ld a,d			;638c   ; el retardo D
L_638D:
	dec a			;638d
	jp nz,L_638D		;638e
	cp 000h		;6391   ; relleno: iguala los ciclos
	inc ix		;6393   ; relleno: iguala los ciclos
	in a,(0aah)		;6395   ; la fila siguiente...
	inc a			;6397
	ld e,a			;6398
	ld a,(hl)			;6399   ; la muestra...
	ld (04000h),a		;639a   ; ...al DAC
	inc hl			;639d
	ld a,d			;639e   ; el retardo D
L_639F:
	dec a			;639f
	jp nz,L_639F		;63a0
	cp 000h		;63a3   ; relleno: iguala los ciclos
	cp 000h		;63a5   ; relleno: iguala los ciclos
	ld a,e			;63a7
	and 0f7h		;63a8   ; ...de la 0 a la 7
	out (0aah),a		;63aa
	ld a,(hl)			;63ac   ; la muestra...
	ld (04000h),a		;63ad   ; ...al DAC
	inc hl			;63b0
	ld a,d			;63b1   ; el retardo D
L_63B2:
	dec a			;63b2
	jp nz,L_63B2		;63b3
	cp 000h		;63b6   ; relleno: iguala los ciclos
	nop			;63b8   ; relleno: iguala los ciclos
	in a,(0a9h)		;63b9   ; alguna tecla en esta fila?
	inc a			;63bb
	jp nz,otra_nota_con_bucle		;63bc
	ld a,(hl)			;63bf   ; la muestra...
	ld (04000h),a		;63c0   ; ...al DAC
	inc hl			;63c3
	ld a,d			;63c4   ; el retardo D
L_63C5:
	dec a			;63c5
	jp nz,L_63C5		;63c6
	cp 000h		;63c9   ; relleno: iguala los ciclos
	neg		;63cb   ; relleno: iguala los ciclos
	ld a,0c0h		;63cd   ; hasta el final del sample
	cp h			;63cf
	jp nz,L_6387		;63d0
	jp fin_de_nota		;63d3
con_bucle_09:		; rutina 9 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;63d6   ; la muestra...
	ld (04000h),a		;63d7   ; ...al DAC
	inc hl			;63da
	ld a,d			;63db   ; el retardo D
L_63DC:
	dec a			;63dc
	jp nz,L_63DC		;63dd
	neg		;63e0   ; relleno: iguala los ciclos
	nop			;63e2   ; relleno: iguala los ciclos
	in a,(0a9h)		;63e3   ; la fila de la tecla:
	and c			;63e5   ; su bit a 1, suelta
	jp nz,L_6410		;63e6
	ld a,(hl)			;63e9   ; la muestra...
	ld (04000h),a		;63ea   ; ...al DAC
	inc hl			;63ed
	ld a,d			;63ee   ; el retardo D
L_63EF:
	dec a			;63ef
	jp nz,L_63EF		;63f0
	neg		;63f3   ; relleno: iguala los ciclos
	cp 000h		;63f5   ; relleno: iguala los ciclos
	nop			;63f7   ; relleno: iguala los ciclos
	ld a,e			;63f8   ; en la pagina de bucle?
	cp h			;63f9
	jp nz,con_bucle_09		;63fa
L_63FD:
	ld a,(hl)			;63fd   ; la muestra...
	ld (04000h),a		;63fe   ; ...al DAC
	inc hl			;6401
	ld a,d			;6402   ; el retardo D
L_6403:
	dec a			;6403
	jp nz,L_6403		;6404
	neg		;6407   ; relleno: iguala los ciclos
	ld h,e			;6409   ; se queda en la pagina de bucle
	in a,(0a9h)		;640a   ; la fila de la tecla:
	and c			;640c   ; su bit a 1, suelta
	jp z,L_63FD		;640d
L_6410:
	ld a,(hl)			;6410   ; la muestra...
	ld (04000h),a		;6411   ; ...al DAC
	inc hl			;6414
	ld a,d			;6415   ; el retardo D
L_6416:
	dec a			;6416
	jp nz,L_6416		;6417
	neg		;641a   ; relleno: iguala los ciclos
	cp 000h		;641c   ; relleno: iguala los ciclos
	nop			;641e   ; relleno: iguala los ciclos
	ld a,l			;641f   ; hasta acabar la pagina
	or a			;6420
	jp nz,L_6410		;6421
L_6424:
	ld a,(hl)			;6424   ; la muestra...
	ld (04000h),a		;6425   ; ...al DAC
	inc hl			;6428
	ld a,d			;6429   ; el retardo D
L_642A:
	dec a			;642a
	jp nz,L_642A		;642b
	neg		;642e   ; relleno: iguala los ciclos
	inc ix		;6430   ; relleno: iguala los ciclos
	in a,(0aah)		;6432   ; la fila siguiente...
	inc a			;6434
	ld e,a			;6435
	ld a,(hl)			;6436   ; la muestra...
	ld (04000h),a		;6437   ; ...al DAC
	inc hl			;643a
	ld a,d			;643b   ; el retardo D
L_643C:
	dec a			;643c
	jp nz,L_643C		;643d
	neg		;6440   ; relleno: iguala los ciclos
	cp 000h		;6442   ; relleno: iguala los ciclos
	ld a,e			;6444
	and 0f7h		;6445   ; ...de la 0 a la 7
	out (0aah),a		;6447
	ld a,(hl)			;6449   ; la muestra...
	ld (04000h),a		;644a   ; ...al DAC
	inc hl			;644d
	ld a,d			;644e   ; el retardo D
L_644F:
	dec a			;644f
	jp nz,L_644F		;6450
	neg		;6453   ; relleno: iguala los ciclos
	nop			;6455   ; relleno: iguala los ciclos
	in a,(0a9h)		;6456   ; alguna tecla en esta fila?
	inc a			;6458
	jp nz,otra_nota_con_bucle		;6459
	ld a,(hl)			;645c   ; la muestra...
	ld (04000h),a		;645d   ; ...al DAC
	inc hl			;6460
	ld a,d			;6461   ; el retardo D
L_6462:
	dec a			;6462
	jp nz,L_6462		;6463
	neg		;6466   ; relleno: iguala los ciclos
	neg		;6468   ; relleno: iguala los ciclos
	ld a,0c0h		;646a   ; hasta el final del sample
	cp h			;646c
	jp nz,L_6424		;646d
	jp fin_de_nota		;6470
con_bucle_10:		; rutina 10 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;6473   ; la muestra...
	ld (04000h),a		;6474   ; ...al DAC
	inc hl			;6477
	ld a,d			;6478   ; el retardo D
L_6479:
	dec a			;6479
	jp nz,L_6479		;647a
	ld a,i		;647d
	nop			;647f   ; relleno: iguala los ciclos
	in a,(0a9h)		;6480   ; la fila de la tecla:
	and c			;6482   ; su bit a 1, suelta
	jp nz,L_64AD		;6483
	ld a,(hl)			;6486   ; la muestra...
	ld (04000h),a		;6487   ; ...al DAC
	inc hl			;648a
	ld a,d			;648b   ; el retardo D
L_648C:
	dec a			;648c
	jp nz,L_648C		;648d
	ld a,i		;6490
	cp 000h		;6492   ; relleno: iguala los ciclos
	nop			;6494   ; relleno: iguala los ciclos
	ld a,e			;6495   ; en la pagina de bucle?
	cp h			;6496
	jp nz,con_bucle_10		;6497
L_649A:
	ld a,(hl)			;649a   ; la muestra...
	ld (04000h),a		;649b   ; ...al DAC
	inc hl			;649e
	ld a,d			;649f   ; el retardo D
L_64A0:
	dec a			;64a0
	jp nz,L_64A0		;64a1
	ld a,i		;64a4
	ld h,e			;64a6   ; se queda en la pagina de bucle
	in a,(0a9h)		;64a7   ; la fila de la tecla:
	and c			;64a9   ; su bit a 1, suelta
	jp z,L_649A		;64aa
L_64AD:
	ld a,(hl)			;64ad   ; la muestra...
	ld (04000h),a		;64ae   ; ...al DAC
	inc hl			;64b1
	ld a,d			;64b2   ; el retardo D
L_64B3:
	dec a			;64b3
	jp nz,L_64B3		;64b4
	ld a,i		;64b7
	cp 000h		;64b9   ; relleno: iguala los ciclos
	nop			;64bb   ; relleno: iguala los ciclos
	ld a,l			;64bc   ; hasta acabar la pagina
	or a			;64bd
	jp nz,L_64AD		;64be
L_64C1:
	ld a,(hl)			;64c1   ; la muestra...
	ld (04000h),a		;64c2   ; ...al DAC
	inc hl			;64c5
	ld a,d			;64c6   ; el retardo D
L_64C7:
	dec a			;64c7
	jp nz,L_64C7		;64c8
	ld a,i		;64cb
	inc ix		;64cd   ; relleno: iguala los ciclos
	in a,(0aah)		;64cf   ; la fila siguiente...
	inc a			;64d1
	ld e,a			;64d2
	ld a,(hl)			;64d3   ; la muestra...
	ld (04000h),a		;64d4   ; ...al DAC
	inc hl			;64d7
	ld a,d			;64d8   ; el retardo D
L_64D9:
	dec a			;64d9
	jp nz,L_64D9		;64da
	ld a,i		;64dd
	cp 000h		;64df   ; relleno: iguala los ciclos
	ld a,e			;64e1
	and 0f7h		;64e2   ; ...de la 0 a la 7
	out (0aah),a		;64e4
	ld a,(hl)			;64e6   ; la muestra...
	ld (04000h),a		;64e7   ; ...al DAC
	inc hl			;64ea
	ld a,d			;64eb   ; el retardo D
L_64EC:
	dec a			;64ec
	jp nz,L_64EC		;64ed
	ld a,i		;64f0
	nop			;64f2   ; relleno: iguala los ciclos
	in a,(0a9h)		;64f3   ; alguna tecla en esta fila?
	inc a			;64f5
	jp nz,otra_nota_con_bucle		;64f6
	ld a,(hl)			;64f9   ; la muestra...
	ld (04000h),a		;64fa   ; ...al DAC
	inc hl			;64fd
	ld a,d			;64fe   ; el retardo D
L_64FF:
	dec a			;64ff
	jp nz,L_64FF		;6500
	ld a,i		;6503
	neg		;6505   ; relleno: iguala los ciclos
	ld a,0c0h		;6507   ; hasta el final del sample
	cp h			;6509
	jp nz,L_64C1		;650a
	jp fin_de_nota		;650d
con_bucle_11:		; rutina 11 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;6510   ; la muestra...
	ld (04000h),a		;6511   ; ...al DAC
	inc hl			;6514
	ld a,d			;6515   ; el retardo D
L_6516:
	dec a			;6516
	jp nz,L_6516		;6517
	inc ix		;651a   ; relleno: iguala los ciclos
	nop			;651c   ; relleno: iguala los ciclos
	in a,(0a9h)		;651d   ; la fila de la tecla:
	and c			;651f   ; su bit a 1, suelta
	jp nz,L_654A		;6520
	ld a,(hl)			;6523   ; la muestra...
	ld (04000h),a		;6524   ; ...al DAC
	inc hl			;6527
	ld a,d			;6528   ; el retardo D
L_6529:
	dec a			;6529
	jp nz,L_6529		;652a
	inc ix		;652d   ; relleno: iguala los ciclos
	cp 000h		;652f   ; relleno: iguala los ciclos
	nop			;6531   ; relleno: iguala los ciclos
	ld a,e			;6532   ; en la pagina de bucle?
	cp h			;6533
	jp nz,con_bucle_11		;6534
L_6537:
	ld a,(hl)			;6537   ; la muestra...
	ld (04000h),a		;6538   ; ...al DAC
	inc hl			;653b
	ld a,d			;653c   ; el retardo D
L_653D:
	dec a			;653d
	jp nz,L_653D		;653e
	inc ix		;6541   ; relleno: iguala los ciclos
	ld h,e			;6543   ; se queda en la pagina de bucle
	in a,(0a9h)		;6544   ; la fila de la tecla:
	and c			;6546   ; su bit a 1, suelta
	jp z,L_6537		;6547
L_654A:
	ld a,(hl)			;654a   ; la muestra...
	ld (04000h),a		;654b   ; ...al DAC
	inc hl			;654e
	ld a,d			;654f   ; el retardo D
L_6550:
	dec a			;6550
	jp nz,L_6550		;6551
	inc ix		;6554   ; relleno: iguala los ciclos
	cp 000h		;6556   ; relleno: iguala los ciclos
	nop			;6558   ; relleno: iguala los ciclos
	ld a,l			;6559   ; hasta acabar la pagina
	or a			;655a
	jp nz,L_654A		;655b
L_655E:
	ld a,(hl)			;655e   ; la muestra...
	ld (04000h),a		;655f   ; ...al DAC
	inc hl			;6562
	ld a,d			;6563   ; el retardo D
L_6564:
	dec a			;6564
	jp nz,L_6564		;6565
	inc ix		;6568   ; relleno: iguala los ciclos
	inc ix		;656a   ; relleno: iguala los ciclos
	in a,(0aah)		;656c   ; la fila siguiente...
	inc a			;656e
	ld e,a			;656f
	ld a,(hl)			;6570   ; la muestra...
	ld (04000h),a		;6571   ; ...al DAC
	inc hl			;6574
	ld a,d			;6575   ; el retardo D
L_6576:
	dec a			;6576
	jp nz,L_6576		;6577
	inc ix		;657a   ; relleno: iguala los ciclos
	cp 000h		;657c   ; relleno: iguala los ciclos
	ld a,e			;657e
	and 0f7h		;657f   ; ...de la 0 a la 7
	out (0aah),a		;6581
	ld a,(hl)			;6583   ; la muestra...
	ld (04000h),a		;6584   ; ...al DAC
	inc hl			;6587
	ld a,d			;6588   ; el retardo D
L_6589:
	dec a			;6589
	jp nz,L_6589		;658a
	inc ix		;658d   ; relleno: iguala los ciclos
	nop			;658f   ; relleno: iguala los ciclos
	in a,(0a9h)		;6590   ; alguna tecla en esta fila?
	inc a			;6592
	jp nz,otra_nota_con_bucle		;6593
	ld a,(hl)			;6596   ; la muestra...
	ld (04000h),a		;6597   ; ...al DAC
	inc hl			;659a
	ld a,d			;659b   ; el retardo D
L_659C:
	dec a			;659c
	jp nz,L_659C		;659d
	inc ix		;65a0   ; relleno: iguala los ciclos
	neg		;65a2   ; relleno: iguala los ciclos
	ld a,0c0h		;65a4   ; hasta el final del sample
	cp h			;65a6
	jp nz,L_655E		;65a7
	jp fin_de_nota		;65aa
con_bucle_12:		; rutina 12 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;65ad   ; la muestra...
	ld (04000h),a		;65ae   ; ...al DAC
	inc hl			;65b1
	ld a,d			;65b2   ; el retardo D
L_65B3:
	dec a			;65b3
	jp nz,L_65B3		;65b4
	cp 000h		;65b7   ; relleno: iguala los ciclos
	nop			;65b9   ; relleno: iguala los ciclos
	nop			;65ba   ; relleno: iguala los ciclos
	in a,(0a9h)		;65bb   ; la fila de la tecla:
	and c			;65bd   ; su bit a 1, suelta
	jp nz,L_65EA		;65be
	ld a,(hl)			;65c1   ; la muestra...
	ld (04000h),a		;65c2   ; ...al DAC
	inc hl			;65c5
	ld a,d			;65c6   ; el retardo D
L_65C7:
	dec a			;65c7
	jp nz,L_65C7		;65c8
	cp 000h		;65cb   ; relleno: iguala los ciclos
	nop			;65cd   ; relleno: iguala los ciclos
	cp 000h		;65ce   ; relleno: iguala los ciclos
	nop			;65d0   ; relleno: iguala los ciclos
	ld a,e			;65d1   ; en la pagina de bucle?
	cp h			;65d2
	jp nz,con_bucle_12		;65d3
L_65D6:
	ld a,(hl)			;65d6   ; la muestra...
	ld (04000h),a		;65d7   ; ...al DAC
	inc hl			;65da
	ld a,d			;65db   ; el retardo D
L_65DC:
	dec a			;65dc
	jp nz,L_65DC		;65dd
	cp 000h		;65e0   ; relleno: iguala los ciclos
	nop			;65e2   ; relleno: iguala los ciclos
	ld h,e			;65e3   ; se queda en la pagina de bucle
	in a,(0a9h)		;65e4   ; la fila de la tecla:
	and c			;65e6   ; su bit a 1, suelta
	jp z,L_65D6		;65e7
L_65EA:
	ld a,(hl)			;65ea   ; la muestra...
	ld (04000h),a		;65eb   ; ...al DAC
	inc hl			;65ee
	ld a,d			;65ef   ; el retardo D
L_65F0:
	dec a			;65f0
	jp nz,L_65F0		;65f1
	cp 000h		;65f4   ; relleno: iguala los ciclos
	nop			;65f6   ; relleno: iguala los ciclos
	cp 000h		;65f7   ; relleno: iguala los ciclos
	nop			;65f9   ; relleno: iguala los ciclos
	ld a,l			;65fa   ; hasta acabar la pagina
	or a			;65fb
	jp nz,L_65EA		;65fc
L_65FF:
	ld a,(hl)			;65ff   ; la muestra...
	ld (04000h),a		;6600   ; ...al DAC
	inc hl			;6603
	ld a,d			;6604   ; el retardo D
L_6605:
	dec a			;6605
	jp nz,L_6605		;6606
	cp 000h		;6609   ; relleno: iguala los ciclos
	nop			;660b   ; relleno: iguala los ciclos
	inc ix		;660c   ; relleno: iguala los ciclos
	in a,(0aah)		;660e   ; la fila siguiente...
	inc a			;6610
	ld e,a			;6611
	ld a,(hl)			;6612   ; la muestra...
	ld (04000h),a		;6613   ; ...al DAC
	inc hl			;6616
	ld a,d			;6617   ; el retardo D
L_6618:
	dec a			;6618
	jp nz,L_6618		;6619
	cp 000h		;661c   ; relleno: iguala los ciclos
	nop			;661e   ; relleno: iguala los ciclos
	cp 000h		;661f   ; relleno: iguala los ciclos
	ld a,e			;6621
	and 0f7h		;6622   ; ...de la 0 a la 7
	out (0aah),a		;6624
	ld a,(hl)			;6626   ; la muestra...
	ld (04000h),a		;6627   ; ...al DAC
	inc hl			;662a
	ld a,d			;662b   ; el retardo D
L_662C:
	dec a			;662c
	jp nz,L_662C		;662d
	cp 000h		;6630   ; relleno: iguala los ciclos
	nop			;6632   ; relleno: iguala los ciclos
	nop			;6633   ; relleno: iguala los ciclos
	in a,(0a9h)		;6634   ; alguna tecla en esta fila?
	inc a			;6636
	jp nz,otra_nota_con_bucle		;6637
	ld a,(hl)			;663a   ; la muestra...
	ld (04000h),a		;663b   ; ...al DAC
	inc hl			;663e
	ld a,d			;663f   ; el retardo D
L_6640:
	dec a			;6640
	jp nz,L_6640		;6641
	cp 000h		;6644   ; relleno: iguala los ciclos
	nop			;6646   ; relleno: iguala los ciclos
	neg		;6647   ; relleno: iguala los ciclos
	ld a,0c0h		;6649   ; hasta el final del sample
	cp h			;664b
	jp nz,L_65FF		;664c
	jp fin_de_nota		;664f
con_bucle_13:		; rutina 13 de 0x5E8B: como 0x5EC9, con otro relleno de ciclos
	ld a,(hl)			;6652   ; la muestra...
	ld (04000h),a		;6653   ; ...al DAC
	inc hl			;6656
	ld a,d			;6657   ; el retardo D
L_6658:
	dec a			;6658
	jp nz,L_6658		;6659
	neg		;665c   ; relleno: iguala los ciclos
	nop			;665e   ; relleno: iguala los ciclos
	nop			;665f   ; relleno: iguala los ciclos
	in a,(0a9h)		;6660   ; la fila de la tecla:
	and c			;6662   ; su bit a 1, suelta
	jp nz,L_668F		;6663
	ld a,(hl)			;6666   ; la muestra...
	ld (04000h),a		;6667   ; ...al DAC
	inc hl			;666a
	ld a,d			;666b   ; el retardo D
L_666C:
	dec a			;666c
	jp nz,L_666C		;666d
	neg		;6670   ; relleno: iguala los ciclos
	nop			;6672   ; relleno: iguala los ciclos
	cp 000h		;6673   ; relleno: iguala los ciclos
	nop			;6675   ; relleno: iguala los ciclos
	ld a,e			;6676   ; en la pagina de bucle?
	cp h			;6677
	jp nz,con_bucle_13		;6678
L_667B:
	ld a,(hl)			;667b   ; la muestra...
	ld (04000h),a		;667c   ; ...al DAC
	inc hl			;667f
	ld a,d			;6680   ; el retardo D
L_6681:
	dec a			;6681
	jp nz,L_6681		;6682
	neg		;6685   ; relleno: iguala los ciclos
	nop			;6687   ; relleno: iguala los ciclos
	ld h,e			;6688   ; se queda en la pagina de bucle
	in a,(0a9h)		;6689   ; la fila de la tecla:
	and c			;668b   ; su bit a 1, suelta
	jp z,L_667B		;668c
L_668F:
	ld a,(hl)			;668f   ; la muestra...
	ld (04000h),a		;6690   ; ...al DAC
	inc hl			;6693
	ld a,d			;6694   ; el retardo D
L_6695:
	dec a			;6695
	jp nz,L_6695		;6696
	neg		;6699   ; relleno: iguala los ciclos
	nop			;669b   ; relleno: iguala los ciclos
	cp 000h		;669c   ; relleno: iguala los ciclos
	nop			;669e   ; relleno: iguala los ciclos
	ld a,l			;669f   ; hasta acabar la pagina
	or a			;66a0
	jp nz,L_668F		;66a1
L_66A4:
	ld a,(hl)			;66a4   ; la muestra...
	ld (04000h),a		;66a5   ; ...al DAC
	inc hl			;66a8
	ld a,d			;66a9   ; el retardo D
L_66AA:
	dec a			;66aa
	jp nz,L_66AA		;66ab
	neg		;66ae   ; relleno: iguala los ciclos
	nop			;66b0   ; relleno: iguala los ciclos
	inc ix		;66b1   ; relleno: iguala los ciclos
	in a,(0aah)		;66b3   ; la fila siguiente...
	inc a			;66b5
	ld e,a			;66b6
	ld a,(hl)			;66b7   ; la muestra...
	ld (04000h),a		;66b8   ; ...al DAC
	inc hl			;66bb
	ld a,d			;66bc   ; el retardo D
L_66BD:
	dec a			;66bd
	jp nz,L_66BD		;66be
	neg		;66c1   ; relleno: iguala los ciclos
	nop			;66c3   ; relleno: iguala los ciclos
	cp 000h		;66c4   ; relleno: iguala los ciclos
	ld a,e			;66c6
	and 0f7h		;66c7   ; ...de la 0 a la 7
	out (0aah),a		;66c9
	ld a,(hl)			;66cb   ; la muestra...
	ld (04000h),a		;66cc   ; ...al DAC
	inc hl			;66cf
	ld a,d			;66d0   ; el retardo D
L_66D1:
	dec a			;66d1
	jp nz,L_66D1		;66d2
	neg		;66d5   ; relleno: iguala los ciclos
	nop			;66d7   ; relleno: iguala los ciclos
	nop			;66d8   ; relleno: iguala los ciclos
	in a,(0a9h)		;66d9   ; alguna tecla en esta fila?
	inc a			;66db
	jp nz,otra_nota_con_bucle		;66dc
	ld a,(hl)			;66df   ; la muestra...
	ld (04000h),a		;66e0   ; ...al DAC
	inc hl			;66e3
	ld a,d			;66e4   ; el retardo D
L_66E5:
	dec a			;66e5
	jp nz,L_66E5		;66e6
	neg		;66e9   ; relleno: iguala los ciclos
	nop			;66eb   ; relleno: iguala los ciclos
	neg		;66ec   ; relleno: iguala los ciclos
	ld a,0c0h		;66ee   ; hasta el final del sample
	cp h			;66f0
	jp nz,L_66A4		;66f1
	jp fin_de_nota		;66f4
fin_de_nota:		; la tecla vuelve a su dibujo y el cartucho a la pagina 2
	call tecla_soltada		;66f7
	call cartucho_en_la_pagina_2		;66fa
	ret			;66fd
otra_nota_con_bucle:		; otra tecla pulsada durante la cola: la nota nueva
	push af			;66fe
	call tecla_soltada		;66ff
	call cartucho_en_la_pagina_2		;6702
	pop af			;6705
	jp nota_con_bucle		;6706

; ----------------------------------------------------------------------
; DATOS reproduce_sin_bucle: las mismas 13 rutinas para los timbres sin pagina
;   de bucle: suenan hasta 0xC000
;   0x6709..0x6723  (26 bytes)
DATA_reproduce_sin_bucle:
	defw 06743h,067c2h,06850h,068ech,06988h,06a0eh,06aa3h,06b3fh	; 6709
	defw 06bcch,06c59h,06ce6h,06d73h,06e07h	; 6719

; ======================================================================
; CODIGO 0x6723..0x6ebb  (1944 bytes)
; ======================================================================


play_sin_bucle:		; PLAY sin pagina de bucle: espera tecla y toca con la tabla 0x6709
	call busca_tecla		;6723
	ret z			;6726
nota_sin_bucle:		; la nota de la tecla pulsada
	call codigo_de_tecla		;6727   ; 0xDC47 y la mascara
	call rutina_de_la_tecla		;672a   ; su rutina y su retardo
	ret z			;672d
	call pinta_tecla_pulsada		;672e   ; la tecla hundida
	ld hl,06709h		;6731   ; IX = la rutina de 0x6709
	call rutina_en_ix		;6734
	push bc			;6737
	push de			;6738
	call ram_en_la_pagina_2		;6739   ; la RAM del sample
	pop de			;673c
	pop bc			;673d
	ld hl,08000h		;673e   ; desde 0x8000
	jp (ix)		;6741   ; a la rutina
sin_bucle_01:		; rutina 1 de 0x6709: de corrido hasta 0xC000; al soltar, mirando si hay otra tecla
	ld a,(hl)			;6743   ; la muestra...
	ld (04000h),a		;6744   ; ...al DAC
	inc hl			;6747
	ld a,d			;6748   ; el retardo D
L_6749:
	dec a			;6749
	jp nz,L_6749		;674a
	nop			;674d   ; relleno: iguala los ciclos
	in a,(0a9h)		;674e   ; la fila de la tecla:
	and c			;6750   ; su bit a 1, suelta
	jp nz,sin_bucle_01_suelta		;6751
	ld a,(hl)			;6754   ; la muestra...
	ld (04000h),a		;6755   ; ...al DAC
	inc hl			;6758
	ld a,d			;6759   ; el retardo D
L_675A:
	dec a			;675a
	jp nz,L_675A		;675b
	neg		;675e   ; relleno: iguala los ciclos
	ld a,0c0h		;6760   ; hasta el final del sample
	cp h			;6762
	jp nz,sin_bucle_01		;6763
	jp final_del_sample		;6766
sin_bucle_01_suelta:		; tecla suelta: acaba la pagina en curso
	ld a,(hl)			;6769   ; la muestra...
	ld (04000h),a		;676a   ; ...al DAC
	inc hl			;676d
	ld a,d			;676e   ; el retardo D
L_676F:
	dec a			;676f
	jp nz,L_676F		;6770
	cp 000h		;6773   ; relleno: iguala los ciclos
	nop			;6775   ; relleno: iguala los ciclos
	ld a,l			;6776   ; hasta acabar la pagina
	or a			;6777
	jp nz,sin_bucle_01_suelta		;6778
sin_bucle_01_cola:		; el resto hasta 0xC000, mirando el teclado
	ld a,(hl)			;677b   ; la muestra...
	ld (04000h),a		;677c   ; ...al DAC
	inc hl			;677f
	ld a,d			;6780   ; el retardo D
L_6781:
	dec a			;6781
	jp nz,L_6781		;6782
	inc ix		;6785   ; relleno: iguala los ciclos
	in a,(0aah)		;6787   ; la fila siguiente...
	inc a			;6789
	ld e,a			;678a
	ld a,(hl)			;678b   ; la muestra...
	ld (04000h),a		;678c   ; ...al DAC
	inc hl			;678f
	ld a,d			;6790   ; el retardo D
L_6791:
	dec a			;6791
	jp nz,L_6791		;6792
	cp 000h		;6795   ; relleno: iguala los ciclos
	ld a,e			;6797
	and 0f7h		;6798   ; ...de la 0 a la 7
	out (0aah),a		;679a
	ld a,(hl)			;679c   ; la muestra...
	ld (04000h),a		;679d   ; ...al DAC
	inc hl			;67a0
	ld a,d			;67a1   ; el retardo D
L_67A2:
	dec a			;67a2
	jp nz,L_67A2		;67a3
	nop			;67a6   ; relleno: iguala los ciclos
	in a,(0a9h)		;67a7   ; alguna tecla en esta fila?
	inc a			;67a9
	jp nz,otra_nota_sin_bucle		;67aa
	ld a,(hl)			;67ad   ; la muestra...
	ld (04000h),a		;67ae   ; ...al DAC
	inc hl			;67b1
	ld a,d			;67b2   ; el retardo D
L_67B3:
	dec a			;67b3
	jp nz,L_67B3		;67b4
	neg		;67b7   ; relleno: iguala los ciclos
	ld a,0c0h		;67b9   ; hasta el final del sample
	cp h			;67bb
	jp nz,sin_bucle_01_cola		;67bc
	jp fin_de_nota_sin_bucle		;67bf
sin_bucle_02:		; rutina 2 de 0x6709: como 0x6743, con otro relleno de ciclos
	dec d			;67c2   ; D - 1 para esta rutina
L_67C3:
	ld a,(hl)			;67c3   ; la muestra...
	ld (04000h),a		;67c4   ; ...al DAC
	inc hl			;67c7
	ld a,d			;67c8   ; el retardo D
L_67C9:
	dec a			;67c9
	jp nz,L_67C9		;67ca
	add ix,ix		;67cd   ; relleno: iguala los ciclos
	nop			;67cf   ; relleno: iguala los ciclos
	in a,(0a9h)		;67d0   ; la fila de la tecla:
	and c			;67d2   ; su bit a 1, suelta
	jp nz,L_67ED		;67d3
	ld a,(hl)			;67d6   ; la muestra...
	ld (04000h),a		;67d7   ; ...al DAC
	inc hl			;67da
	ld a,d			;67db   ; el retardo D
L_67DC:
	dec a			;67dc
	jp nz,L_67DC		;67dd
	add ix,ix		;67e0   ; relleno: iguala los ciclos
	neg		;67e2   ; relleno: iguala los ciclos
	ld a,0c0h		;67e4   ; hasta el final del sample
	cp h			;67e6
	jp nz,L_67C3		;67e7
	jp final_del_sample		;67ea
L_67ED:
	ld a,(hl)			;67ed   ; la muestra...
	ld (04000h),a		;67ee   ; ...al DAC
	inc hl			;67f1
	ld a,d			;67f2   ; el retardo D
L_67F3:
	dec a			;67f3
	jp nz,L_67F3		;67f4
	add ix,ix		;67f7   ; relleno: iguala los ciclos
	cp 000h		;67f9   ; relleno: iguala los ciclos
	nop			;67fb   ; relleno: iguala los ciclos
	ld a,l			;67fc   ; hasta acabar la pagina
	or a			;67fd
	jp nz,L_67ED		;67fe
L_6801:
	ld a,(hl)			;6801   ; la muestra...
	ld (04000h),a		;6802   ; ...al DAC
	inc hl			;6805
	ld a,d			;6806   ; el retardo D
L_6807:
	dec a			;6807
	jp nz,L_6807		;6808
	add ix,ix		;680b   ; relleno: iguala los ciclos
	inc ix		;680d   ; relleno: iguala los ciclos
	in a,(0aah)		;680f   ; la fila siguiente...
	inc a			;6811
	ld e,a			;6812
	ld a,(hl)			;6813   ; la muestra...
	ld (04000h),a		;6814   ; ...al DAC
	inc hl			;6817
	ld a,d			;6818   ; el retardo D
L_6819:
	dec a			;6819
	jp nz,L_6819		;681a
	add ix,ix		;681d   ; relleno: iguala los ciclos
	cp 000h		;681f   ; relleno: iguala los ciclos
	ld a,e			;6821
	and 0f7h		;6822   ; ...de la 0 a la 7
	out (0aah),a		;6824
	ld a,(hl)			;6826   ; la muestra...
	ld (04000h),a		;6827   ; ...al DAC
	inc hl			;682a
	ld a,d			;682b   ; el retardo D
L_682C:
	dec a			;682c
	jp nz,L_682C		;682d
	add ix,ix		;6830   ; relleno: iguala los ciclos
	nop			;6832   ; relleno: iguala los ciclos
	in a,(0a9h)		;6833   ; alguna tecla en esta fila?
	inc a			;6835
	jp nz,otra_nota_sin_bucle		;6836
	ld a,(hl)			;6839   ; la muestra...
	ld (04000h),a		;683a   ; ...al DAC
	inc hl			;683d
	ld a,d			;683e   ; el retardo D
L_683F:
	dec a			;683f
	jp nz,L_683F		;6840
	add ix,ix		;6843   ; relleno: iguala los ciclos
	neg		;6845   ; relleno: iguala los ciclos
	ld a,0c0h		;6847   ; hasta el final del sample
	cp h			;6849
	jp nz,L_6801		;684a
	jp fin_de_nota_sin_bucle		;684d
sin_bucle_03:		; rutina 3 de 0x6709: como 0x6743, con otro relleno de ciclos
	dec d			;6850   ; D - 1 para esta rutina
L_6851:
	ld a,(hl)			;6851   ; la muestra...
	ld (04000h),a		;6852   ; ...al DAC
	inc hl			;6855
	ld a,d			;6856   ; el retardo D
L_6857:
	dec a			;6857
	jp nz,L_6857		;6858
	neg		;685b   ; relleno: iguala los ciclos
	neg		;685d   ; relleno: iguala los ciclos
	nop			;685f   ; relleno: iguala los ciclos
	in a,(0a9h)		;6860   ; la fila de la tecla:
	and c			;6862   ; su bit a 1, suelta
	jp nz,L_687F		;6863
	ld a,(hl)			;6866   ; la muestra...
	ld (04000h),a		;6867   ; ...al DAC
	inc hl			;686a
	ld a,d			;686b   ; el retardo D
L_686C:
	dec a			;686c
	jp nz,L_686C		;686d
	neg		;6870   ; relleno: iguala los ciclos
	neg		;6872   ; relleno: iguala los ciclos
	neg		;6874   ; relleno: iguala los ciclos
	ld a,0c0h		;6876   ; hasta el final del sample
	cp h			;6878
	jp nz,L_6851		;6879
	jp final_del_sample		;687c
L_687F:
	ld a,(hl)			;687f   ; la muestra...
	ld (04000h),a		;6880   ; ...al DAC
	inc hl			;6883
	ld a,d			;6884   ; el retardo D
L_6885:
	dec a			;6885
	jp nz,L_6885		;6886
	neg		;6889   ; relleno: iguala los ciclos
	neg		;688b   ; relleno: iguala los ciclos
	cp 000h		;688d   ; relleno: iguala los ciclos
	nop			;688f   ; relleno: iguala los ciclos
	ld a,l			;6890   ; hasta acabar la pagina
	or a			;6891
	jp nz,L_687F		;6892
L_6895:
	ld a,(hl)			;6895   ; la muestra...
	ld (04000h),a		;6896   ; ...al DAC
	inc hl			;6899
	ld a,d			;689a   ; el retardo D
L_689B:
	dec a			;689b
	jp nz,L_689B		;689c
	neg		;689f   ; relleno: iguala los ciclos
	neg		;68a1   ; relleno: iguala los ciclos
	inc ix		;68a3   ; relleno: iguala los ciclos
	in a,(0aah)		;68a5   ; la fila siguiente...
	inc a			;68a7
	ld e,a			;68a8
	ld a,(hl)			;68a9   ; la muestra...
	ld (04000h),a		;68aa   ; ...al DAC
	inc hl			;68ad
	ld a,d			;68ae   ; el retardo D
L_68AF:
	dec a			;68af
	jp nz,L_68AF		;68b0
	neg		;68b3   ; relleno: iguala los ciclos
	neg		;68b5   ; relleno: iguala los ciclos
	cp 000h		;68b7   ; relleno: iguala los ciclos
	ld a,e			;68b9
	and 0f7h		;68ba   ; ...de la 0 a la 7
	out (0aah),a		;68bc
	ld a,(hl)			;68be   ; la muestra...
	ld (04000h),a		;68bf   ; ...al DAC
	inc hl			;68c2
	ld a,d			;68c3   ; el retardo D
L_68C4:
	dec a			;68c4
	jp nz,L_68C4		;68c5
	neg		;68c8   ; relleno: iguala los ciclos
	neg		;68ca   ; relleno: iguala los ciclos
	nop			;68cc   ; relleno: iguala los ciclos
	in a,(0a9h)		;68cd   ; alguna tecla en esta fila?
	inc a			;68cf
	jp nz,otra_nota_sin_bucle		;68d0
	ld a,(hl)			;68d3   ; la muestra...
	ld (04000h),a		;68d4   ; ...al DAC
	inc hl			;68d7
	ld a,d			;68d8   ; el retardo D
L_68D9:
	dec a			;68d9
	jp nz,L_68D9		;68da
	neg		;68dd   ; relleno: iguala los ciclos
	neg		;68df   ; relleno: iguala los ciclos
	neg		;68e1   ; relleno: iguala los ciclos
	ld a,0c0h		;68e3   ; hasta el final del sample
	cp h			;68e5
	jp nz,L_6895		;68e6
	jp fin_de_nota_sin_bucle		;68e9
sin_bucle_04:		; rutina 4 de 0x6709: como 0x6743, con otro relleno de ciclos
	dec d			;68ec   ; D - 1 para esta rutina
L_68ED:
	ld a,(hl)			;68ed   ; la muestra...
	ld (04000h),a		;68ee   ; ...al DAC
	inc hl			;68f1
	ld a,d			;68f2   ; el retardo D
L_68F3:
	dec a			;68f3
	jp nz,L_68F3		;68f4
	inc ix		;68f7   ; relleno: iguala los ciclos
	cp 000h		;68f9   ; relleno: iguala los ciclos
	nop			;68fb   ; relleno: iguala los ciclos
	in a,(0a9h)		;68fc   ; la fila de la tecla:
	and c			;68fe   ; su bit a 1, suelta
	jp nz,L_691B		;68ff
	ld a,(hl)			;6902   ; la muestra...
	ld (04000h),a		;6903   ; ...al DAC
	inc hl			;6906
	ld a,d			;6907   ; el retardo D
L_6908:
	dec a			;6908
	jp nz,L_6908		;6909
	inc ix		;690c   ; relleno: iguala los ciclos
	cp 000h		;690e   ; relleno: iguala los ciclos
	neg		;6910   ; relleno: iguala los ciclos
	ld a,0c0h		;6912   ; hasta el final del sample
	cp h			;6914
	jp nz,L_68ED		;6915
	jp final_del_sample		;6918
L_691B:
	ld a,(hl)			;691b   ; la muestra...
	ld (04000h),a		;691c   ; ...al DAC
	inc hl			;691f
	ld a,d			;6920   ; el retardo D
L_6921:
	dec a			;6921
	jp nz,L_6921		;6922
	inc ix		;6925   ; relleno: iguala los ciclos
	cp 000h		;6927   ; relleno: iguala los ciclos
	cp 000h		;6929   ; relleno: iguala los ciclos
	nop			;692b   ; relleno: iguala los ciclos
	ld a,l			;692c   ; hasta acabar la pagina
	or a			;692d
	jp nz,L_691B		;692e
L_6931:
	ld a,(hl)			;6931   ; la muestra...
	ld (04000h),a		;6932   ; ...al DAC
	inc hl			;6935
	ld a,d			;6936   ; el retardo D
L_6937:
	dec a			;6937
	jp nz,L_6937		;6938
	inc ix		;693b   ; relleno: iguala los ciclos
	cp 000h		;693d   ; relleno: iguala los ciclos
	inc ix		;693f   ; relleno: iguala los ciclos
	in a,(0aah)		;6941   ; la fila siguiente...
	inc a			;6943
	ld e,a			;6944
	ld a,(hl)			;6945   ; la muestra...
	ld (04000h),a		;6946   ; ...al DAC
	inc hl			;6949
	ld a,d			;694a   ; el retardo D
L_694B:
	dec a			;694b
	jp nz,L_694B		;694c
	inc ix		;694f   ; relleno: iguala los ciclos
	cp 000h		;6951   ; relleno: iguala los ciclos
	cp 000h		;6953   ; relleno: iguala los ciclos
	ld a,e			;6955
	and 0f7h		;6956   ; ...de la 0 a la 7
	out (0aah),a		;6958
	ld a,(hl)			;695a   ; la muestra...
	ld (04000h),a		;695b   ; ...al DAC
	inc hl			;695e
	ld a,d			;695f   ; el retardo D
L_6960:
	dec a			;6960
	jp nz,L_6960		;6961
	inc ix		;6964   ; relleno: iguala los ciclos
	cp 000h		;6966   ; relleno: iguala los ciclos
	nop			;6968   ; relleno: iguala los ciclos
	in a,(0a9h)		;6969   ; alguna tecla en esta fila?
	inc a			;696b
	jp nz,otra_nota_sin_bucle		;696c
	ld a,(hl)			;696f   ; la muestra...
	ld (04000h),a		;6970   ; ...al DAC
	inc hl			;6973
	ld a,d			;6974   ; el retardo D
L_6975:
	dec a			;6975
	jp nz,L_6975		;6976
	inc ix		;6979   ; relleno: iguala los ciclos
	cp 000h		;697b   ; relleno: iguala los ciclos
	neg		;697d   ; relleno: iguala los ciclos
	ld a,0c0h		;697f   ; hasta el final del sample
	cp h			;6981
	jp nz,L_6931		;6982
	jp fin_de_nota_sin_bucle		;6985
sin_bucle_05:		; rutina 5 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6988   ; la muestra...
	ld (04000h),a		;6989   ; ...al DAC
	inc hl			;698c
	ld a,d			;698d   ; el retardo D
L_698E:
	dec a			;698e
	jp nz,L_698E		;698f
	nop			;6992   ; relleno: iguala los ciclos
	nop			;6993   ; relleno: iguala los ciclos
	in a,(0a9h)		;6994   ; la fila de la tecla:
	and c			;6996   ; su bit a 1, suelta
	jp nz,L_69B0		;6997
	ld a,(hl)			;699a   ; la muestra...
	ld (04000h),a		;699b   ; ...al DAC
	inc hl			;699e
	ld a,d			;699f   ; el retardo D
L_69A0:
	dec a			;69a0
	jp nz,L_69A0		;69a1
	nop			;69a4   ; relleno: iguala los ciclos
	neg		;69a5   ; relleno: iguala los ciclos
	ld a,0c0h		;69a7   ; hasta el final del sample
	cp h			;69a9
	jp nz,sin_bucle_05		;69aa
	jp final_del_sample		;69ad
L_69B0:
	ld a,(hl)			;69b0   ; la muestra...
	ld (04000h),a		;69b1   ; ...al DAC
	inc hl			;69b4
	ld a,d			;69b5   ; el retardo D
L_69B6:
	dec a			;69b6
	jp nz,L_69B6		;69b7
	nop			;69ba   ; relleno: iguala los ciclos
	cp 000h		;69bb   ; relleno: iguala los ciclos
	nop			;69bd   ; relleno: iguala los ciclos
	ld a,l			;69be   ; hasta acabar la pagina
	or a			;69bf
	jp nz,L_69B0		;69c0
L_69C3:
	ld a,(hl)			;69c3   ; la muestra...
	ld (04000h),a		;69c4   ; ...al DAC
	inc hl			;69c7
	ld a,d			;69c8   ; el retardo D
L_69C9:
	dec a			;69c9
	jp nz,L_69C9		;69ca
	nop			;69cd   ; relleno: iguala los ciclos
	inc ix		;69ce   ; relleno: iguala los ciclos
	in a,(0aah)		;69d0   ; la fila siguiente...
	inc a			;69d2
	ld e,a			;69d3
	ld a,(hl)			;69d4   ; la muestra...
	ld (04000h),a		;69d5   ; ...al DAC
	inc hl			;69d8
	ld a,d			;69d9   ; el retardo D
L_69DA:
	dec a			;69da
	jp nz,L_69DA		;69db
	nop			;69de   ; relleno: iguala los ciclos
	cp 000h		;69df   ; relleno: iguala los ciclos
	ld a,e			;69e1
	and 0f7h		;69e2   ; ...de la 0 a la 7
	out (0aah),a		;69e4
	ld a,(hl)			;69e6   ; la muestra...
	ld (04000h),a		;69e7   ; ...al DAC
	inc hl			;69ea
	ld a,d			;69eb   ; el retardo D
L_69EC:
	dec a			;69ec
	jp nz,L_69EC		;69ed
	nop			;69f0   ; relleno: iguala los ciclos
	nop			;69f1   ; relleno: iguala los ciclos
	in a,(0a9h)		;69f2   ; alguna tecla en esta fila?
	inc a			;69f4
	jp nz,otra_nota_sin_bucle		;69f5
	ld a,(hl)			;69f8   ; la muestra...
	ld (04000h),a		;69f9   ; ...al DAC
	inc hl			;69fc
	ld a,d			;69fd   ; el retardo D
L_69FE:
	dec a			;69fe
	jp nz,L_69FE		;69ff
	nop			;6a02   ; relleno: iguala los ciclos
	neg		;6a03   ; relleno: iguala los ciclos
	ld a,0c0h		;6a05   ; hasta el final del sample
	cp h			;6a07
	jp nz,L_69C3		;6a08
	jp fin_de_nota_sin_bucle		;6a0b
sin_bucle_06:		; rutina 6 de 0x6709: como 0x6743, con otro relleno de ciclos
	dec d			;6a0e   ; D - 1 para esta rutina
L_6A0F:
	ld a,(hl)			;6a0f   ; la muestra...
	ld (04000h),a		;6a10   ; ...al DAC
	inc hl			;6a13
	ld a,d			;6a14   ; el retardo D
L_6A15:
	dec a			;6a15
	jp nz,L_6A15		;6a16
	add a,(ix+000h)		;6a19
	nop			;6a1c   ; relleno: iguala los ciclos
	in a,(0a9h)		;6a1d   ; la fila de la tecla:
	and c			;6a1f   ; su bit a 1, suelta
	jp nz,L_6A3B		;6a20
	ld a,(hl)			;6a23   ; la muestra...
	ld (04000h),a		;6a24   ; ...al DAC
	inc hl			;6a27
	ld a,d			;6a28   ; el retardo D
L_6A29:
	dec a			;6a29
	jp nz,L_6A29		;6a2a
	add a,(ix+000h)		;6a2d
	neg		;6a30   ; relleno: iguala los ciclos
	ld a,0c0h		;6a32   ; hasta el final del sample
	cp h			;6a34
	jp nz,L_6A0F		;6a35
	jp final_del_sample		;6a38
L_6A3B:
	ld a,(hl)			;6a3b   ; la muestra...
	ld (04000h),a		;6a3c   ; ...al DAC
	inc hl			;6a3f
	ld a,d			;6a40   ; el retardo D
L_6A41:
	dec a			;6a41
	jp nz,L_6A41		;6a42
	add a,(ix+000h)		;6a45
	cp 000h		;6a48   ; relleno: iguala los ciclos
	nop			;6a4a   ; relleno: iguala los ciclos
	ld a,l			;6a4b   ; hasta acabar la pagina
	or a			;6a4c
	jp nz,L_6A3B		;6a4d
L_6A50:
	ld a,(hl)			;6a50   ; la muestra...
	ld (04000h),a		;6a51   ; ...al DAC
	inc hl			;6a54
	ld a,d			;6a55   ; el retardo D
L_6A56:
	dec a			;6a56
	jp nz,L_6A56		;6a57
	add a,(ix+000h)		;6a5a
	inc ix		;6a5d   ; relleno: iguala los ciclos
	in a,(0aah)		;6a5f   ; la fila siguiente...
	inc a			;6a61
	ld e,a			;6a62
	ld a,(hl)			;6a63   ; la muestra...
	ld (04000h),a		;6a64   ; ...al DAC
	inc hl			;6a67
	ld a,d			;6a68   ; el retardo D
L_6A69:
	dec a			;6a69
	jp nz,L_6A69		;6a6a
	add a,(ix+000h)		;6a6d
	cp 000h		;6a70   ; relleno: iguala los ciclos
	ld a,e			;6a72
	and 0f7h		;6a73   ; ...de la 0 a la 7
	out (0aah),a		;6a75
	ld a,(hl)			;6a77   ; la muestra...
	ld (04000h),a		;6a78   ; ...al DAC
	inc hl			;6a7b
	ld a,d			;6a7c   ; el retardo D
L_6A7D:
	dec a			;6a7d
	jp nz,L_6A7D		;6a7e
	add a,(ix+000h)		;6a81
	nop			;6a84   ; relleno: iguala los ciclos
	in a,(0a9h)		;6a85   ; alguna tecla en esta fila?
	inc a			;6a87
	jp nz,otra_nota_sin_bucle		;6a88
	ld a,(hl)			;6a8b   ; la muestra...
	ld (04000h),a		;6a8c   ; ...al DAC
	inc hl			;6a8f
	ld a,d			;6a90   ; el retardo D
L_6A91:
	dec a			;6a91
	jp nz,L_6A91		;6a92
	add a,(ix+000h)		;6a95
	neg		;6a98   ; relleno: iguala los ciclos
	ld a,0c0h		;6a9a   ; hasta el final del sample
	cp h			;6a9c
	jp nz,L_6A50		;6a9d
	jp fin_de_nota_sin_bucle		;6aa0
sin_bucle_07:		; rutina 7 de 0x6709: como 0x6743, con otro relleno de ciclos
	dec d			;6aa3   ; D - 1 para esta rutina
L_6AA4:
	ld a,(hl)			;6aa4   ; la muestra...
	ld (04000h),a		;6aa5   ; ...al DAC
	inc hl			;6aa8
	ld a,d			;6aa9   ; el retardo D
L_6AAA:
	dec a			;6aaa
	jp nz,L_6AAA		;6aab
	inc ix		;6aae   ; relleno: iguala los ciclos
	inc ix		;6ab0   ; relleno: iguala los ciclos
	nop			;6ab2   ; relleno: iguala los ciclos
	in a,(0a9h)		;6ab3   ; la fila de la tecla:
	and c			;6ab5   ; su bit a 1, suelta
	jp nz,L_6AD2		;6ab6
	ld a,(hl)			;6ab9   ; la muestra...
	ld (04000h),a		;6aba   ; ...al DAC
	inc hl			;6abd
	ld a,d			;6abe   ; el retardo D
L_6ABF:
	dec a			;6abf
	jp nz,L_6ABF		;6ac0
	inc ix		;6ac3   ; relleno: iguala los ciclos
	inc ix		;6ac5   ; relleno: iguala los ciclos
	neg		;6ac7   ; relleno: iguala los ciclos
	ld a,0c0h		;6ac9   ; hasta el final del sample
	cp h			;6acb
	jp nz,L_6AA4		;6acc
	jp final_del_sample		;6acf
L_6AD2:
	ld a,(hl)			;6ad2   ; la muestra...
	ld (04000h),a		;6ad3   ; ...al DAC
	inc hl			;6ad6
	ld a,d			;6ad7   ; el retardo D
L_6AD8:
	dec a			;6ad8
	jp nz,L_6AD8		;6ad9
	inc ix		;6adc   ; relleno: iguala los ciclos
	inc ix		;6ade   ; relleno: iguala los ciclos
	cp 000h		;6ae0   ; relleno: iguala los ciclos
	nop			;6ae2   ; relleno: iguala los ciclos
	ld a,l			;6ae3   ; hasta acabar la pagina
	or a			;6ae4
	jp nz,L_6AD2		;6ae5
L_6AE8:
	ld a,(hl)			;6ae8   ; la muestra...
	ld (04000h),a		;6ae9   ; ...al DAC
	inc hl			;6aec
	ld a,d			;6aed   ; el retardo D
L_6AEE:
	dec a			;6aee
	jp nz,L_6AEE		;6aef
	inc ix		;6af2   ; relleno: iguala los ciclos
	inc ix		;6af4   ; relleno: iguala los ciclos
	inc ix		;6af6   ; relleno: iguala los ciclos
	in a,(0aah)		;6af8   ; la fila siguiente...
	inc a			;6afa
	ld e,a			;6afb
	ld a,(hl)			;6afc   ; la muestra...
	ld (04000h),a		;6afd   ; ...al DAC
	inc hl			;6b00
	ld a,d			;6b01   ; el retardo D
L_6B02:
	dec a			;6b02
	jp nz,L_6B02		;6b03
	inc ix		;6b06   ; relleno: iguala los ciclos
	inc ix		;6b08   ; relleno: iguala los ciclos
	cp 000h		;6b0a   ; relleno: iguala los ciclos
	ld a,e			;6b0c
	and 0f7h		;6b0d   ; ...de la 0 a la 7
	out (0aah),a		;6b0f
	ld a,(hl)			;6b11   ; la muestra...
	ld (04000h),a		;6b12   ; ...al DAC
	inc hl			;6b15
	ld a,d			;6b16   ; el retardo D
L_6B17:
	dec a			;6b17
	jp nz,L_6B17		;6b18
	inc ix		;6b1b   ; relleno: iguala los ciclos
	inc ix		;6b1d   ; relleno: iguala los ciclos
	nop			;6b1f   ; relleno: iguala los ciclos
	in a,(0a9h)		;6b20   ; alguna tecla en esta fila?
	inc a			;6b22
	jp nz,otra_nota_sin_bucle		;6b23
	ld a,(hl)			;6b26   ; la muestra...
	ld (04000h),a		;6b27   ; ...al DAC
	inc hl			;6b2a
	ld a,d			;6b2b   ; el retardo D
L_6B2C:
	dec a			;6b2c
	jp nz,L_6B2C		;6b2d
	inc ix		;6b30   ; relleno: iguala los ciclos
	inc ix		;6b32   ; relleno: iguala los ciclos
	neg		;6b34   ; relleno: iguala los ciclos
	ld a,0c0h		;6b36   ; hasta el final del sample
	cp h			;6b38
	jp nz,L_6AE8		;6b39
	jp fin_de_nota_sin_bucle		;6b3c
sin_bucle_08:		; rutina 8 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6b3f   ; la muestra...
	ld (04000h),a		;6b40   ; ...al DAC
	inc hl			;6b43
	ld a,d			;6b44   ; el retardo D
L_6B45:
	dec a			;6b45
	jp nz,L_6B45		;6b46
	cp 000h		;6b49   ; relleno: iguala los ciclos
	nop			;6b4b   ; relleno: iguala los ciclos
	in a,(0a9h)		;6b4c   ; la fila de la tecla:
	and c			;6b4e   ; su bit a 1, suelta
	jp nz,L_6B69		;6b4f
	ld a,(hl)			;6b52   ; la muestra...
	ld (04000h),a		;6b53   ; ...al DAC
	inc hl			;6b56
	ld a,d			;6b57   ; el retardo D
L_6B58:
	dec a			;6b58
	jp nz,L_6B58		;6b59
	cp 000h		;6b5c   ; relleno: iguala los ciclos
	neg		;6b5e   ; relleno: iguala los ciclos
	ld a,0c0h		;6b60   ; hasta el final del sample
	cp h			;6b62
	jp nz,sin_bucle_08		;6b63
	jp final_del_sample		;6b66
L_6B69:
	ld a,(hl)			;6b69   ; la muestra...
	ld (04000h),a		;6b6a   ; ...al DAC
	inc hl			;6b6d
	ld a,d			;6b6e   ; el retardo D
L_6B6F:
	dec a			;6b6f
	jp nz,L_6B6F		;6b70
	cp 000h		;6b73   ; relleno: iguala los ciclos
	cp 000h		;6b75   ; relleno: iguala los ciclos
	nop			;6b77   ; relleno: iguala los ciclos
	ld a,l			;6b78   ; hasta acabar la pagina
	or a			;6b79
	jp nz,L_6B69		;6b7a
L_6B7D:
	ld a,(hl)			;6b7d   ; la muestra...
	ld (04000h),a		;6b7e   ; ...al DAC
	inc hl			;6b81
	ld a,d			;6b82   ; el retardo D
L_6B83:
	dec a			;6b83
	jp nz,L_6B83		;6b84
	cp 000h		;6b87   ; relleno: iguala los ciclos
	inc ix		;6b89   ; relleno: iguala los ciclos
	in a,(0aah)		;6b8b   ; la fila siguiente...
	inc a			;6b8d
	ld e,a			;6b8e
	ld a,(hl)			;6b8f   ; la muestra...
	ld (04000h),a		;6b90   ; ...al DAC
	inc hl			;6b93
	ld a,d			;6b94   ; el retardo D
L_6B95:
	dec a			;6b95
	jp nz,L_6B95		;6b96
	cp 000h		;6b99   ; relleno: iguala los ciclos
	cp 000h		;6b9b   ; relleno: iguala los ciclos
	ld a,e			;6b9d
	and 0f7h		;6b9e   ; ...de la 0 a la 7
	out (0aah),a		;6ba0
	ld a,(hl)			;6ba2   ; la muestra...
	ld (04000h),a		;6ba3   ; ...al DAC
	inc hl			;6ba6
	ld a,d			;6ba7   ; el retardo D
L_6BA8:
	dec a			;6ba8
	jp nz,L_6BA8		;6ba9
	cp 000h		;6bac   ; relleno: iguala los ciclos
	nop			;6bae   ; relleno: iguala los ciclos
	in a,(0a9h)		;6baf   ; alguna tecla en esta fila?
	inc a			;6bb1
	jp nz,otra_nota_sin_bucle		;6bb2
	ld a,(hl)			;6bb5   ; la muestra...
	ld (04000h),a		;6bb6   ; ...al DAC
	inc hl			;6bb9
	ld a,d			;6bba   ; el retardo D
L_6BBB:
	dec a			;6bbb
	jp nz,L_6BBB		;6bbc
	cp 000h		;6bbf   ; relleno: iguala los ciclos
	neg		;6bc1   ; relleno: iguala los ciclos
	ld a,0c0h		;6bc3   ; hasta el final del sample
	cp h			;6bc5
	jp nz,L_6B7D		;6bc6
	jp fin_de_nota_sin_bucle		;6bc9
sin_bucle_09:		; rutina 9 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6bcc   ; la muestra...
	ld (04000h),a		;6bcd   ; ...al DAC
	inc hl			;6bd0
	ld a,d			;6bd1   ; el retardo D
L_6BD2:
	dec a			;6bd2
	jp nz,L_6BD2		;6bd3
	neg		;6bd6   ; relleno: iguala los ciclos
	nop			;6bd8   ; relleno: iguala los ciclos
	in a,(0a9h)		;6bd9   ; la fila de la tecla:
	and c			;6bdb   ; su bit a 1, suelta
	jp nz,L_6BF6		;6bdc
	ld a,(hl)			;6bdf   ; la muestra...
	ld (04000h),a		;6be0   ; ...al DAC
	inc hl			;6be3
	ld a,d			;6be4   ; el retardo D
L_6BE5:
	dec a			;6be5
	jp nz,L_6BE5		;6be6
	neg		;6be9   ; relleno: iguala los ciclos
	neg		;6beb   ; relleno: iguala los ciclos
	ld a,0c0h		;6bed   ; hasta el final del sample
	cp h			;6bef
	jp nz,sin_bucle_09		;6bf0
	jp final_del_sample		;6bf3
L_6BF6:
	ld a,(hl)			;6bf6   ; la muestra...
	ld (04000h),a		;6bf7   ; ...al DAC
	inc hl			;6bfa
	ld a,d			;6bfb   ; el retardo D
L_6BFC:
	dec a			;6bfc
	jp nz,L_6BFC		;6bfd
	neg		;6c00   ; relleno: iguala los ciclos
	cp 000h		;6c02   ; relleno: iguala los ciclos
	nop			;6c04   ; relleno: iguala los ciclos
	ld a,l			;6c05   ; hasta acabar la pagina
	or a			;6c06
	jp nz,L_6BF6		;6c07
L_6C0A:
	ld a,(hl)			;6c0a   ; la muestra...
	ld (04000h),a		;6c0b   ; ...al DAC
	inc hl			;6c0e
	ld a,d			;6c0f   ; el retardo D
L_6C10:
	dec a			;6c10
	jp nz,L_6C10		;6c11
	neg		;6c14   ; relleno: iguala los ciclos
	inc ix		;6c16   ; relleno: iguala los ciclos
	in a,(0aah)		;6c18   ; la fila siguiente...
	inc a			;6c1a
	ld e,a			;6c1b
	ld a,(hl)			;6c1c   ; la muestra...
	ld (04000h),a		;6c1d   ; ...al DAC
	inc hl			;6c20
	ld a,d			;6c21   ; el retardo D
L_6C22:
	dec a			;6c22
	jp nz,L_6C22		;6c23
	neg		;6c26   ; relleno: iguala los ciclos
	cp 000h		;6c28   ; relleno: iguala los ciclos
	ld a,e			;6c2a
	and 0f7h		;6c2b   ; ...de la 0 a la 7
	out (0aah),a		;6c2d
	ld a,(hl)			;6c2f   ; la muestra...
	ld (04000h),a		;6c30   ; ...al DAC
	inc hl			;6c33
	ld a,d			;6c34   ; el retardo D
L_6C35:
	dec a			;6c35
	jp nz,L_6C35		;6c36
	neg		;6c39   ; relleno: iguala los ciclos
	nop			;6c3b   ; relleno: iguala los ciclos
	in a,(0a9h)		;6c3c   ; alguna tecla en esta fila?
	inc a			;6c3e
	jp nz,otra_nota_sin_bucle		;6c3f
	ld a,(hl)			;6c42   ; la muestra...
	ld (04000h),a		;6c43   ; ...al DAC
	inc hl			;6c46
	ld a,d			;6c47   ; el retardo D
L_6C48:
	dec a			;6c48
	jp nz,L_6C48		;6c49
	neg		;6c4c   ; relleno: iguala los ciclos
	neg		;6c4e   ; relleno: iguala los ciclos
	ld a,0c0h		;6c50   ; hasta el final del sample
	cp h			;6c52
	jp nz,L_6C0A		;6c53
	jp fin_de_nota_sin_bucle		;6c56
sin_bucle_10:		; rutina 10 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6c59   ; la muestra...
	ld (04000h),a		;6c5a   ; ...al DAC
	inc hl			;6c5d
	ld a,d			;6c5e   ; el retardo D
L_6C5F:
	dec a			;6c5f
	jp nz,L_6C5F		;6c60
	ld a,i		;6c63
	nop			;6c65   ; relleno: iguala los ciclos
	in a,(0a9h)		;6c66   ; la fila de la tecla:
	and c			;6c68   ; su bit a 1, suelta
	jp nz,L_6C83		;6c69
	ld a,(hl)			;6c6c   ; la muestra...
	ld (04000h),a		;6c6d   ; ...al DAC
	inc hl			;6c70
	ld a,d			;6c71   ; el retardo D
L_6C72:
	dec a			;6c72
	jp nz,L_6C72		;6c73
	ld a,i		;6c76
	neg		;6c78   ; relleno: iguala los ciclos
	ld a,0c0h		;6c7a   ; hasta el final del sample
	cp h			;6c7c
	jp nz,sin_bucle_10		;6c7d
	jp final_del_sample		;6c80
L_6C83:
	ld a,(hl)			;6c83   ; la muestra...
	ld (04000h),a		;6c84   ; ...al DAC
	inc hl			;6c87
	ld a,d			;6c88   ; el retardo D
L_6C89:
	dec a			;6c89
	jp nz,L_6C89		;6c8a
	ld a,i		;6c8d
	cp 000h		;6c8f   ; relleno: iguala los ciclos
	nop			;6c91   ; relleno: iguala los ciclos
	ld a,l			;6c92   ; hasta acabar la pagina
	or a			;6c93
	jp nz,L_6C83		;6c94
L_6C97:
	ld a,(hl)			;6c97   ; la muestra...
	ld (04000h),a		;6c98   ; ...al DAC
	inc hl			;6c9b
	ld a,d			;6c9c   ; el retardo D
L_6C9D:
	dec a			;6c9d
	jp nz,L_6C9D		;6c9e
	ld a,i		;6ca1
	inc ix		;6ca3   ; relleno: iguala los ciclos
	in a,(0aah)		;6ca5   ; la fila siguiente...
	inc a			;6ca7
	ld e,a			;6ca8
	ld a,(hl)			;6ca9   ; la muestra...
	ld (04000h),a		;6caa   ; ...al DAC
	inc hl			;6cad
	ld a,d			;6cae   ; el retardo D
L_6CAF:
	dec a			;6caf
	jp nz,L_6CAF		;6cb0
	ld a,i		;6cb3
	cp 000h		;6cb5   ; relleno: iguala los ciclos
	ld a,e			;6cb7
	and 0f7h		;6cb8   ; ...de la 0 a la 7
	out (0aah),a		;6cba
	ld a,(hl)			;6cbc   ; la muestra...
	ld (04000h),a		;6cbd   ; ...al DAC
	inc hl			;6cc0
	ld a,d			;6cc1   ; el retardo D
L_6CC2:
	dec a			;6cc2
	jp nz,L_6CC2		;6cc3
	ld a,i		;6cc6
	nop			;6cc8   ; relleno: iguala los ciclos
	in a,(0a9h)		;6cc9   ; alguna tecla en esta fila?
	inc a			;6ccb
	jp nz,otra_nota_sin_bucle		;6ccc
	ld a,(hl)			;6ccf   ; la muestra...
	ld (04000h),a		;6cd0   ; ...al DAC
	inc hl			;6cd3
	ld a,d			;6cd4   ; el retardo D
L_6CD5:
	dec a			;6cd5
	jp nz,L_6CD5		;6cd6
	ld a,i		;6cd9
	neg		;6cdb   ; relleno: iguala los ciclos
	ld a,0c0h		;6cdd   ; hasta el final del sample
	cp h			;6cdf
	jp nz,L_6C97		;6ce0
	jp fin_de_nota_sin_bucle		;6ce3
sin_bucle_11:		; rutina 11 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6ce6   ; la muestra...
	ld (04000h),a		;6ce7   ; ...al DAC
	inc hl			;6cea
	ld a,d			;6ceb   ; el retardo D
L_6CEC:
	dec a			;6cec
	jp nz,L_6CEC		;6ced
	inc ix		;6cf0   ; relleno: iguala los ciclos
	nop			;6cf2   ; relleno: iguala los ciclos
	in a,(0a9h)		;6cf3   ; la fila de la tecla:
	and c			;6cf5   ; su bit a 1, suelta
	jp nz,L_6D10		;6cf6
	ld a,(hl)			;6cf9   ; la muestra...
	ld (04000h),a		;6cfa   ; ...al DAC
	inc hl			;6cfd
	ld a,d			;6cfe   ; el retardo D
L_6CFF:
	dec a			;6cff
	jp nz,L_6CFF		;6d00
	inc ix		;6d03   ; relleno: iguala los ciclos
	neg		;6d05   ; relleno: iguala los ciclos
	ld a,0c0h		;6d07   ; hasta el final del sample
	cp h			;6d09
	jp nz,sin_bucle_11		;6d0a
	jp final_del_sample		;6d0d
L_6D10:
	ld a,(hl)			;6d10   ; la muestra...
	ld (04000h),a		;6d11   ; ...al DAC
	inc hl			;6d14
	ld a,d			;6d15   ; el retardo D
L_6D16:
	dec a			;6d16
	jp nz,L_6D16		;6d17
	inc ix		;6d1a   ; relleno: iguala los ciclos
	cp 000h		;6d1c   ; relleno: iguala los ciclos
	nop			;6d1e   ; relleno: iguala los ciclos
	ld a,l			;6d1f   ; hasta acabar la pagina
	or a			;6d20
	jp nz,L_6D10		;6d21
L_6D24:
	ld a,(hl)			;6d24   ; la muestra...
	ld (04000h),a		;6d25   ; ...al DAC
	inc hl			;6d28
	ld a,d			;6d29   ; el retardo D
L_6D2A:
	dec a			;6d2a
	jp nz,L_6D2A		;6d2b
	inc ix		;6d2e   ; relleno: iguala los ciclos
	inc ix		;6d30   ; relleno: iguala los ciclos
	in a,(0aah)		;6d32   ; la fila siguiente...
	inc a			;6d34
	ld e,a			;6d35
	ld a,(hl)			;6d36   ; la muestra...
	ld (04000h),a		;6d37   ; ...al DAC
	inc hl			;6d3a
	ld a,d			;6d3b   ; el retardo D
L_6D3C:
	dec a			;6d3c
	jp nz,L_6D3C		;6d3d
	inc ix		;6d40   ; relleno: iguala los ciclos
	cp 000h		;6d42   ; relleno: iguala los ciclos
	ld a,e			;6d44
	and 0f7h		;6d45   ; ...de la 0 a la 7
	out (0aah),a		;6d47
	ld a,(hl)			;6d49   ; la muestra...
	ld (04000h),a		;6d4a   ; ...al DAC
	inc hl			;6d4d
	ld a,d			;6d4e   ; el retardo D
L_6D4F:
	dec a			;6d4f
	jp nz,L_6D4F		;6d50
	inc ix		;6d53   ; relleno: iguala los ciclos
	nop			;6d55   ; relleno: iguala los ciclos
	in a,(0a9h)		;6d56   ; alguna tecla en esta fila?
	inc a			;6d58
	jp nz,otra_nota_sin_bucle		;6d59
	ld a,(hl)			;6d5c   ; la muestra...
	ld (04000h),a		;6d5d   ; ...al DAC
	inc hl			;6d60
	ld a,d			;6d61   ; el retardo D
L_6D62:
	dec a			;6d62
	jp nz,L_6D62		;6d63
	inc ix		;6d66   ; relleno: iguala los ciclos
	neg		;6d68   ; relleno: iguala los ciclos
	ld a,0c0h		;6d6a   ; hasta el final del sample
	cp h			;6d6c
	jp nz,L_6D24		;6d6d
	jp fin_de_nota_sin_bucle		;6d70
sin_bucle_12:		; rutina 12 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6d73   ; la muestra...
	ld (04000h),a		;6d74   ; ...al DAC
	inc hl			;6d77
	ld a,d			;6d78   ; el retardo D
L_6D79:
	dec a			;6d79
	jp nz,L_6D79		;6d7a
	cp 000h		;6d7d   ; relleno: iguala los ciclos
	nop			;6d7f   ; relleno: iguala los ciclos
	nop			;6d80   ; relleno: iguala los ciclos
	in a,(0a9h)		;6d81   ; la fila de la tecla:
	and c			;6d83   ; su bit a 1, suelta
	jp nz,L_6D9F		;6d84
	ld a,(hl)			;6d87   ; la muestra...
	ld (04000h),a		;6d88   ; ...al DAC
	inc hl			;6d8b
	ld a,d			;6d8c   ; el retardo D
L_6D8D:
	dec a			;6d8d
	jp nz,L_6D8D		;6d8e
	cp 000h		;6d91   ; relleno: iguala los ciclos
	nop			;6d93   ; relleno: iguala los ciclos
	neg		;6d94   ; relleno: iguala los ciclos
	ld a,0c0h		;6d96   ; hasta el final del sample
	cp h			;6d98
	jp nz,sin_bucle_12		;6d99
	jp final_del_sample		;6d9c
L_6D9F:
	ld a,(hl)			;6d9f   ; la muestra...
	ld (04000h),a		;6da0   ; ...al DAC
	inc hl			;6da3
	ld a,d			;6da4   ; el retardo D
L_6DA5:
	dec a			;6da5
	jp nz,L_6DA5		;6da6
	cp 000h		;6da9   ; relleno: iguala los ciclos
	nop			;6dab   ; relleno: iguala los ciclos
	cp 000h		;6dac   ; relleno: iguala los ciclos
	nop			;6dae   ; relleno: iguala los ciclos
	ld a,l			;6daf   ; hasta acabar la pagina
	or a			;6db0
	jp nz,L_6D9F		;6db1
L_6DB4:
	ld a,(hl)			;6db4   ; la muestra...
	ld (04000h),a		;6db5   ; ...al DAC
	inc hl			;6db8
	ld a,d			;6db9   ; el retardo D
L_6DBA:
	dec a			;6dba
	jp nz,L_6DBA		;6dbb
	cp 000h		;6dbe   ; relleno: iguala los ciclos
	nop			;6dc0   ; relleno: iguala los ciclos
	inc ix		;6dc1   ; relleno: iguala los ciclos
	in a,(0aah)		;6dc3   ; la fila siguiente...
	inc a			;6dc5
	ld e,a			;6dc6
	ld a,(hl)			;6dc7   ; la muestra...
	ld (04000h),a		;6dc8   ; ...al DAC
	inc hl			;6dcb
	ld a,d			;6dcc   ; el retardo D
L_6DCD:
	dec a			;6dcd
	jp nz,L_6DCD		;6dce
	cp 000h		;6dd1   ; relleno: iguala los ciclos
	nop			;6dd3   ; relleno: iguala los ciclos
	cp 000h		;6dd4   ; relleno: iguala los ciclos
	ld a,e			;6dd6
	and 0f7h		;6dd7   ; ...de la 0 a la 7
	out (0aah),a		;6dd9
	ld a,(hl)			;6ddb   ; la muestra...
	ld (04000h),a		;6ddc   ; ...al DAC
	inc hl			;6ddf
	ld a,d			;6de0   ; el retardo D
L_6DE1:
	dec a			;6de1
	jp nz,L_6DE1		;6de2
	cp 000h		;6de5   ; relleno: iguala los ciclos
	nop			;6de7   ; relleno: iguala los ciclos
	nop			;6de8   ; relleno: iguala los ciclos
	in a,(0a9h)		;6de9   ; alguna tecla en esta fila?
	inc a			;6deb
	jp nz,otra_nota_sin_bucle		;6dec
	ld a,(hl)			;6def   ; la muestra...
	ld (04000h),a		;6df0   ; ...al DAC
	inc hl			;6df3
	ld a,d			;6df4   ; el retardo D
L_6DF5:
	dec a			;6df5
	jp nz,L_6DF5		;6df6
	cp 000h		;6df9   ; relleno: iguala los ciclos
	nop			;6dfb   ; relleno: iguala los ciclos
	neg		;6dfc   ; relleno: iguala los ciclos
	ld a,0c0h		;6dfe   ; hasta el final del sample
	cp h			;6e00
	jp nz,L_6DB4		;6e01
	jp fin_de_nota_sin_bucle		;6e04
sin_bucle_13:		; rutina 13 de 0x6709: como 0x6743, con otro relleno de ciclos
	ld a,(hl)			;6e07   ; la muestra...
	ld (04000h),a		;6e08   ; ...al DAC
	inc hl			;6e0b
	ld a,d			;6e0c   ; el retardo D
L_6E0D:
	dec a			;6e0d
	jp nz,L_6E0D		;6e0e
	neg		;6e11   ; relleno: iguala los ciclos
	nop			;6e13   ; relleno: iguala los ciclos
	nop			;6e14   ; relleno: iguala los ciclos
	in a,(0a9h)		;6e15   ; la fila de la tecla:
	and c			;6e17   ; su bit a 1, suelta
	jp nz,L_6E33		;6e18
	ld a,(hl)			;6e1b   ; la muestra...
	ld (04000h),a		;6e1c   ; ...al DAC
	inc hl			;6e1f
	ld a,d			;6e20   ; el retardo D
L_6E21:
	dec a			;6e21
	jp nz,L_6E21		;6e22
	neg		;6e25   ; relleno: iguala los ciclos
	nop			;6e27   ; relleno: iguala los ciclos
	neg		;6e28   ; relleno: iguala los ciclos
	ld a,0c0h		;6e2a   ; hasta el final del sample
	cp h			;6e2c
	jp nz,sin_bucle_13		;6e2d
	jp final_del_sample		;6e30
L_6E33:
	ld a,(hl)			;6e33   ; la muestra...
	ld (04000h),a		;6e34   ; ...al DAC
	inc hl			;6e37
	ld a,d			;6e38   ; el retardo D
L_6E39:
	dec a			;6e39
	jp nz,L_6E39		;6e3a
	neg		;6e3d   ; relleno: iguala los ciclos
	nop			;6e3f   ; relleno: iguala los ciclos
	cp 000h		;6e40   ; relleno: iguala los ciclos
	nop			;6e42   ; relleno: iguala los ciclos
	ld a,l			;6e43   ; hasta acabar la pagina
	or a			;6e44
	jp nz,L_6E33		;6e45
L_6E48:
	ld a,(hl)			;6e48   ; la muestra...
	ld (04000h),a		;6e49   ; ...al DAC
	inc hl			;6e4c
	ld a,d			;6e4d   ; el retardo D
L_6E4E:
	dec a			;6e4e
	jp nz,L_6E4E		;6e4f
	neg		;6e52   ; relleno: iguala los ciclos
	nop			;6e54   ; relleno: iguala los ciclos
	inc ix		;6e55   ; relleno: iguala los ciclos
	in a,(0aah)		;6e57   ; la fila siguiente...
	inc a			;6e59
	ld e,a			;6e5a
	ld a,(hl)			;6e5b   ; la muestra...
	ld (04000h),a		;6e5c   ; ...al DAC
	inc hl			;6e5f
	ld a,d			;6e60   ; el retardo D
L_6E61:
	dec a			;6e61
	jp nz,L_6E61		;6e62
	neg		;6e65   ; relleno: iguala los ciclos
	nop			;6e67   ; relleno: iguala los ciclos
	cp 000h		;6e68   ; relleno: iguala los ciclos
	ld a,e			;6e6a
	and 0f7h		;6e6b   ; ...de la 0 a la 7
	out (0aah),a		;6e6d
	ld a,(hl)			;6e6f   ; la muestra...
	ld (04000h),a		;6e70   ; ...al DAC
	inc hl			;6e73
	ld a,d			;6e74   ; el retardo D
L_6E75:
	dec a			;6e75
	jp nz,L_6E75		;6e76
	neg		;6e79   ; relleno: iguala los ciclos
	nop			;6e7b   ; relleno: iguala los ciclos
	nop			;6e7c   ; relleno: iguala los ciclos
	in a,(0a9h)		;6e7d   ; alguna tecla en esta fila?
	inc a			;6e7f
	jp nz,otra_nota_sin_bucle		;6e80
	ld a,(hl)			;6e83   ; la muestra...
	ld (04000h),a		;6e84   ; ...al DAC
	inc hl			;6e87
	ld a,d			;6e88   ; el retardo D
L_6E89:
	dec a			;6e89
	jp nz,L_6E89		;6e8a
	neg		;6e8d   ; relleno: iguala los ciclos
	nop			;6e8f   ; relleno: iguala los ciclos
	neg		;6e90   ; relleno: iguala los ciclos
	ld a,0c0h		;6e92   ; hasta el final del sample
	cp h			;6e94
	jp nz,L_6E48		;6e95
	jp fin_de_nota_sin_bucle		;6e98
fin_de_nota_sin_bucle:		; la tecla vuelve a su dibujo y el cartucho a la pagina 2
	call tecla_soltada		;6e9b
	call cartucho_en_la_pagina_2		;6e9e
	ret			;6ea1
otra_nota_sin_bucle:		; otra tecla durante la cola: la nota nueva
	push af			;6ea2
	call tecla_soltada		;6ea3
	call cartucho_en_la_pagina_2		;6ea6
	pop af			;6ea9
	jp nota_sin_bucle		;6eaa
final_del_sample:		; el DAC al reposo y espera a que no haya ninguna tecla
	ld a,080h		;6ead
	ld (04000h),a		;6eaf
L_6EB2:
	in a,(0a9h)		;6eb2
	inc a			;6eb4
	jp nz,L_6EB2		;6eb5
	jp fin_de_nota_sin_bucle		;6eb8

; ----------------------------------------------------------------------
; DATOS reproduce_samp: las 13 rutinas para la muestra cargada de cinta (SAMP)
;   0x6ebb..0x6ed5  (26 bytes)
DATA_reproduce_samp:
	defw 06f1ch,06f40h,06f69h,06f96h,06fc3h,06fe9h,07014h,07041h	; 6ebb
	defw 07069h,07091h,070b9h,070e1h,0710bh	; 6ecb

; ======================================================================
; CODIGO 0x6ed5..0x7135  (608 bytes)
; ======================================================================


escucha_onda:		; WAVE EDIT: la onda del usuario, con el paso de FEET, en 0xDD00, y suena en bucle mientras se tiene la tecla 0xDC47
	di			;6ed5
	ld de,0dd00h		;6ed6   ; destino 0xDD00
	ld a,(0db00h)		;6ed9   ; la onda del usuario 0xDB00...
	add a,0c0h		;6edc
	ld h,a			;6ede   ; ...en 0xC000 + 0x100 * onda
	ld l,e			;6edf
	ld a,(0dc01h)		;6ee0   ; el paso: FEET (0xDC01)
	ld b,a			;6ee3
L_6EE4:
	ld a,(hl)			;6ee4   ; la muestra...
	add a,080h		;6ee5   ; ...sin signo...
	ld (de),a			;6ee7   ; ...a 0xDD00
	ld a,b			;6ee8   ; la fase avanza FEET
	add a,l			;6ee9
	ld l,a			;6eea
	inc e			;6eeb
	jp nz,L_6EE4		;6eec
	ld a,(0dc47h)		;6eef   ; la fila y el bit de la tecla 0xDC47
	dec a			;6ef2
L_6EF3:
	ld b,a			;6ef3
	sub 008h		;6ef4
	jp nc,L_6EF3		;6ef6
	ld c,080h		;6ef9   ; C = la mascara del bit
	inc b			;6efb
L_6EFC:
	rlc c		;6efc
	djnz L_6EFC		;6efe
	ld a,(0dc47h)		;6f00   ; su rutina y su retardo
	call rutina_de_la_tecla		;6f03
	ret z			;6f06
	ld hl,06ebbh		;6f07   ; la rutina de 0x6EBB
	call rutina_en_ix		;6f0a
	ld hl,0dd00h		;6f0d   ; la pagina 0xDD
	ld e,h			;6f10
	call salta_ix		;6f11
	ld a,080h		;6f14   ; el DAC al reposo
	ld (04000h),a		;6f16
	ret			;6f19
salta_ix:		; `jp (ix)`
	jp (ix)		;6f1a
escucha_01:		; rutina 1 de 0x6EBB: la pagina 0xDD una y otra vez mientras se tiene la tecla
	ld a,(hl)			;6f1c   ; la muestra...
	ld (04000h),a		;6f1d   ; ...al DAC
	inc hl			;6f20
	ld a,d			;6f21   ; el retardo D
L_6F22:
	dec a			;6f22
	jp nz,L_6F22		;6f23
	ld h,e			;6f26   ; se queda en la pagina de bucle
	in a,(0a9h)		;6f27   ; la fila de la tecla:
	and c			;6f29   ; su bit a 1, suelta
	jp z,escucha_01		;6f2a
L_6F2D:
	ld a,(hl)			;6f2d   ; la muestra...
	ld (04000h),a		;6f2e   ; ...al DAC
	inc hl			;6f31
	ld a,d			;6f32   ; el retardo D
L_6F33:
	dec a			;6f33
	jp nz,L_6F33		;6f34
	cp 000h		;6f37   ; relleno: iguala los ciclos
	nop			;6f39   ; relleno: iguala los ciclos
	ld a,l			;6f3a   ; hasta acabar la pagina
	or a			;6f3b
	jp nz,L_6F2D		;6f3c
	ret			;6f3f
escucha_02:		; rutina 2 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	dec d			;6f40   ; D - 1 para esta rutina
L_6F41:
	ld a,(hl)			;6f41   ; la muestra...
	ld (04000h),a		;6f42   ; ...al DAC
	inc hl			;6f45
	ld a,d			;6f46   ; el retardo D
L_6F47:
	dec a			;6f47
	jp nz,L_6F47		;6f48
	add ix,ix		;6f4b   ; relleno: iguala los ciclos
	ld h,e			;6f4d   ; se queda en la pagina de bucle
	in a,(0a9h)		;6f4e   ; la fila de la tecla:
	and c			;6f50   ; su bit a 1, suelta
	jp z,L_6F41		;6f51
L_6F54:
	ld a,(hl)			;6f54   ; la muestra...
	ld (04000h),a		;6f55   ; ...al DAC
	inc hl			;6f58
	ld a,d			;6f59   ; el retardo D
L_6F5A:
	dec a			;6f5a
	jp nz,L_6F5A		;6f5b
	add ix,ix		;6f5e   ; relleno: iguala los ciclos
	cp 000h		;6f60   ; relleno: iguala los ciclos
	nop			;6f62   ; relleno: iguala los ciclos
	ld a,l			;6f63   ; hasta acabar la pagina
	or a			;6f64
	jp nz,L_6F54		;6f65
	ret			;6f68
escucha_03:		; rutina 3 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	dec d			;6f69   ; D - 1 para esta rutina
L_6F6A:
	ld a,(hl)			;6f6a   ; la muestra...
	ld (04000h),a		;6f6b   ; ...al DAC
	inc hl			;6f6e
	ld a,d			;6f6f   ; el retardo D
L_6F70:
	dec a			;6f70
	jp nz,L_6F70		;6f71
	neg		;6f74   ; relleno: iguala los ciclos
	neg		;6f76   ; relleno: iguala los ciclos
	ld h,e			;6f78   ; se queda en la pagina de bucle
	in a,(0a9h)		;6f79   ; la fila de la tecla:
	and c			;6f7b   ; su bit a 1, suelta
	jp z,L_6F6A		;6f7c
L_6F7F:
	ld a,(hl)			;6f7f   ; la muestra...
	ld (04000h),a		;6f80   ; ...al DAC
	inc hl			;6f83
	ld a,d			;6f84   ; el retardo D
L_6F85:
	dec a			;6f85
	jp nz,L_6F85		;6f86
	neg		;6f89   ; relleno: iguala los ciclos
	neg		;6f8b   ; relleno: iguala los ciclos
	cp 000h		;6f8d   ; relleno: iguala los ciclos
	nop			;6f8f   ; relleno: iguala los ciclos
	ld a,l			;6f90   ; hasta acabar la pagina
	or a			;6f91
	jp nz,L_6F7F		;6f92
	ret			;6f95
escucha_04:		; rutina 4 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	dec d			;6f96   ; D - 1 para esta rutina
L_6F97:
	ld a,(hl)			;6f97   ; la muestra...
	ld (04000h),a		;6f98   ; ...al DAC
	inc hl			;6f9b
	ld a,d			;6f9c   ; el retardo D
L_6F9D:
	dec a			;6f9d
	jp nz,L_6F9D		;6f9e
	inc ix		;6fa1   ; relleno: iguala los ciclos
	cp 000h		;6fa3   ; relleno: iguala los ciclos
	ld h,e			;6fa5   ; se queda en la pagina de bucle
	in a,(0a9h)		;6fa6   ; la fila de la tecla:
	and c			;6fa8   ; su bit a 1, suelta
	jp z,L_6F97		;6fa9
L_6FAC:
	ld a,(hl)			;6fac   ; la muestra...
	ld (04000h),a		;6fad   ; ...al DAC
	inc hl			;6fb0
	ld a,d			;6fb1   ; el retardo D
L_6FB2:
	dec a			;6fb2
	jp nz,L_6FB2		;6fb3
	inc ix		;6fb6   ; relleno: iguala los ciclos
	cp 000h		;6fb8   ; relleno: iguala los ciclos
	cp 000h		;6fba   ; relleno: iguala los ciclos
	nop			;6fbc   ; relleno: iguala los ciclos
	ld a,l			;6fbd   ; hasta acabar la pagina
	or a			;6fbe
	jp nz,L_6FAC		;6fbf
	ret			;6fc2
escucha_05:		; rutina 5 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;6fc3   ; la muestra...
	ld (04000h),a		;6fc4   ; ...al DAC
	inc hl			;6fc7
	ld a,d			;6fc8   ; el retardo D
L_6FC9:
	dec a			;6fc9
	jp nz,L_6FC9		;6fca
	nop			;6fcd   ; relleno: iguala los ciclos
	ld h,e			;6fce   ; se queda en la pagina de bucle
	in a,(0a9h)		;6fcf   ; la fila de la tecla:
	and c			;6fd1   ; su bit a 1, suelta
	jp z,escucha_05		;6fd2
L_6FD5:
	ld a,(hl)			;6fd5   ; la muestra...
	ld (04000h),a		;6fd6   ; ...al DAC
	inc hl			;6fd9
	ld a,d			;6fda   ; el retardo D
L_6FDB:
	dec a			;6fdb
	jp nz,L_6FDB		;6fdc
	nop			;6fdf   ; relleno: iguala los ciclos
	cp 000h		;6fe0   ; relleno: iguala los ciclos
	nop			;6fe2   ; relleno: iguala los ciclos
	ld a,l			;6fe3   ; hasta acabar la pagina
	or a			;6fe4
	jp nz,L_6FD5		;6fe5
	ret			;6fe8
escucha_06:		; rutina 6 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	dec d			;6fe9   ; D - 1 para esta rutina
L_6FEA:
	ld a,(hl)			;6fea   ; la muestra...
	ld (04000h),a		;6feb   ; ...al DAC
	inc hl			;6fee
	ld a,d			;6fef   ; el retardo D
L_6FF0:
	dec a			;6ff0
	jp nz,L_6FF0		;6ff1
	add a,(ix+000h)		;6ff4
	ld h,e			;6ff7   ; se queda en la pagina de bucle
	in a,(0a9h)		;6ff8   ; la fila de la tecla:
	and c			;6ffa   ; su bit a 1, suelta
	jp z,L_6FEA		;6ffb
L_6FFE:
	ld a,(hl)			;6ffe   ; la muestra...
	ld (04000h),a		;6fff   ; ...al DAC
	inc hl			;7002
	ld a,d			;7003   ; el retardo D
L_7004:
	dec a			;7004
	jp nz,L_7004		;7005
	add a,(ix+000h)		;7008
	cp 000h		;700b   ; relleno: iguala los ciclos
	nop			;700d   ; relleno: iguala los ciclos
	ld a,l			;700e   ; hasta acabar la pagina
	or a			;700f
	jp nz,L_6FFE		;7010
	ret			;7013
escucha_07:		; rutina 7 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	dec d			;7014   ; D - 1 para esta rutina
L_7015:
	ld a,(hl)			;7015   ; la muestra...
	ld (04000h),a		;7016   ; ...al DAC
	inc hl			;7019
	ld a,d			;701a   ; el retardo D
L_701B:
	dec a			;701b
	jp nz,L_701B		;701c
	inc ix		;701f   ; relleno: iguala los ciclos
	inc ix		;7021   ; relleno: iguala los ciclos
	ld h,e			;7023   ; se queda en la pagina de bucle
	in a,(0a9h)		;7024   ; la fila de la tecla:
	and c			;7026   ; su bit a 1, suelta
	jp z,L_7015		;7027
L_702A:
	ld a,(hl)			;702a   ; la muestra...
	ld (04000h),a		;702b   ; ...al DAC
	inc hl			;702e
	ld a,d			;702f   ; el retardo D
L_7030:
	dec a			;7030
	jp nz,L_7030		;7031
	inc ix		;7034   ; relleno: iguala los ciclos
	inc ix		;7036   ; relleno: iguala los ciclos
	cp 000h		;7038   ; relleno: iguala los ciclos
	nop			;703a   ; relleno: iguala los ciclos
	ld a,l			;703b   ; hasta acabar la pagina
	or a			;703c
	jp nz,L_702A		;703d
	ret			;7040
escucha_08:		; rutina 8 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;7041   ; la muestra...
	ld (04000h),a		;7042   ; ...al DAC
	inc hl			;7045
	ld a,d			;7046   ; el retardo D
L_7047:
	dec a			;7047
	jp nz,L_7047		;7048
	cp 000h		;704b   ; relleno: iguala los ciclos
	ld h,e			;704d   ; se queda en la pagina de bucle
	in a,(0a9h)		;704e   ; la fila de la tecla:
	and c			;7050   ; su bit a 1, suelta
	jp z,escucha_08		;7051
L_7054:
	ld a,(hl)			;7054   ; la muestra...
	ld (04000h),a		;7055   ; ...al DAC
	inc hl			;7058
	ld a,d			;7059   ; el retardo D
L_705A:
	dec a			;705a
	jp nz,L_705A		;705b
	cp 000h		;705e   ; relleno: iguala los ciclos
	cp 000h		;7060   ; relleno: iguala los ciclos
	nop			;7062   ; relleno: iguala los ciclos
	ld a,l			;7063   ; hasta acabar la pagina
	or a			;7064
	jp nz,L_7054		;7065
	ret			;7068
escucha_09:		; rutina 9 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;7069   ; la muestra...
	ld (04000h),a		;706a   ; ...al DAC
	inc hl			;706d
	ld a,d			;706e   ; el retardo D
L_706F:
	dec a			;706f
	jp nz,L_706F		;7070
	neg		;7073   ; relleno: iguala los ciclos
	ld h,e			;7075   ; se queda en la pagina de bucle
	in a,(0a9h)		;7076   ; la fila de la tecla:
	and c			;7078   ; su bit a 1, suelta
	jp z,escucha_09		;7079
L_707C:
	ld a,(hl)			;707c   ; la muestra...
	ld (04000h),a		;707d   ; ...al DAC
	inc hl			;7080
	ld a,d			;7081   ; el retardo D
L_7082:
	dec a			;7082
	jp nz,L_7082		;7083
	neg		;7086   ; relleno: iguala los ciclos
	cp 000h		;7088   ; relleno: iguala los ciclos
	nop			;708a   ; relleno: iguala los ciclos
	ld a,l			;708b   ; hasta acabar la pagina
	or a			;708c
	jp nz,L_707C		;708d
	ret			;7090
escucha_10:		; rutina 10 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;7091   ; la muestra...
	ld (04000h),a		;7092   ; ...al DAC
	inc hl			;7095
	ld a,d			;7096   ; el retardo D
L_7097:
	dec a			;7097
	jp nz,L_7097		;7098
	ld a,i		;709b
	ld h,e			;709d   ; se queda en la pagina de bucle
	in a,(0a9h)		;709e   ; la fila de la tecla:
	and c			;70a0   ; su bit a 1, suelta
	jp z,escucha_10		;70a1
L_70A4:
	ld a,(hl)			;70a4   ; la muestra...
	ld (04000h),a		;70a5   ; ...al DAC
	inc hl			;70a8
	ld a,d			;70a9   ; el retardo D
L_70AA:
	dec a			;70aa
	jp nz,L_70AA		;70ab
	ld a,i		;70ae
	cp 000h		;70b0   ; relleno: iguala los ciclos
	nop			;70b2   ; relleno: iguala los ciclos
	ld a,l			;70b3   ; hasta acabar la pagina
	or a			;70b4
	jp nz,L_70A4		;70b5
	ret			;70b8
escucha_11:		; rutina 11 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;70b9   ; la muestra...
	ld (04000h),a		;70ba   ; ...al DAC
	inc hl			;70bd
	ld a,d			;70be   ; el retardo D
L_70BF:
	dec a			;70bf
	jp nz,L_70BF		;70c0
	inc ix		;70c3   ; relleno: iguala los ciclos
	ld h,e			;70c5   ; se queda en la pagina de bucle
	in a,(0a9h)		;70c6   ; la fila de la tecla:
	and c			;70c8   ; su bit a 1, suelta
	jp z,escucha_11		;70c9
L_70CC:
	ld a,(hl)			;70cc   ; la muestra...
	ld (04000h),a		;70cd   ; ...al DAC
	inc hl			;70d0
	ld a,d			;70d1   ; el retardo D
L_70D2:
	dec a			;70d2
	jp nz,L_70D2		;70d3
	inc ix		;70d6   ; relleno: iguala los ciclos
	cp 000h		;70d8   ; relleno: iguala los ciclos
	nop			;70da   ; relleno: iguala los ciclos
	ld a,l			;70db   ; hasta acabar la pagina
	or a			;70dc
	jp nz,L_70CC		;70dd
	ret			;70e0
escucha_12:		; rutina 12 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;70e1   ; la muestra...
	ld (04000h),a		;70e2   ; ...al DAC
	inc hl			;70e5
	ld a,d			;70e6   ; el retardo D
L_70E7:
	dec a			;70e7
	jp nz,L_70E7		;70e8
	cp 000h		;70eb   ; relleno: iguala los ciclos
	nop			;70ed   ; relleno: iguala los ciclos
	ld h,e			;70ee   ; se queda en la pagina de bucle
	in a,(0a9h)		;70ef   ; la fila de la tecla:
	and c			;70f1   ; su bit a 1, suelta
	jp z,escucha_12		;70f2
L_70F5:
	ld a,(hl)			;70f5   ; la muestra...
	ld (04000h),a		;70f6   ; ...al DAC
	inc hl			;70f9
	ld a,d			;70fa   ; el retardo D
L_70FB:
	dec a			;70fb
	jp nz,L_70FB		;70fc
	cp 000h		;70ff   ; relleno: iguala los ciclos
	nop			;7101   ; relleno: iguala los ciclos
	cp 000h		;7102   ; relleno: iguala los ciclos
	nop			;7104   ; relleno: iguala los ciclos
	ld a,l			;7105   ; hasta acabar la pagina
	or a			;7106
	jp nz,L_70F5		;7107
	ret			;710a
escucha_13:		; rutina 13 de 0x6EBB: como 0x6F1C, con otro relleno de ciclos
	ld a,(hl)			;710b   ; la muestra...
	ld (04000h),a		;710c   ; ...al DAC
	inc hl			;710f
	ld a,d			;7110   ; el retardo D
L_7111:
	dec a			;7111
	jp nz,L_7111		;7112
	neg		;7115   ; relleno: iguala los ciclos
	nop			;7117   ; relleno: iguala los ciclos
	ld h,e			;7118   ; se queda en la pagina de bucle
	in a,(0a9h)		;7119   ; la fila de la tecla:
	and c			;711b   ; su bit a 1, suelta
	jp z,escucha_13		;711c
L_711F:
	ld a,(hl)			;711f   ; la muestra...
	ld (04000h),a		;7120   ; ...al DAC
	inc hl			;7123
	ld a,d			;7124   ; el retardo D
L_7125:
	dec a			;7125
	jp nz,L_7125		;7126
	neg		;7129   ; relleno: iguala los ciclos
	nop			;712b   ; relleno: iguala los ciclos
	cp 000h		;712c   ; relleno: iguala los ciclos
	nop			;712e   ; relleno: iguala los ciclos
	ld a,l			;712f   ; hasta acabar la pagina
	or a			;7130
	jp nz,L_711F		;7131
	ret			;7134

; ----------------------------------------------------------------------
; DATOS relleno_0x7135: 0xFF hasta el principio de las ondas
;   0x7135..0x7200  (203 bytes)
DATA_relleno_0x7135:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7135  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7145  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7155  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7165  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7175  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7185  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7195  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71a5  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71b5  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71c5  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71d5  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71e5  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 71f5  ...........

; ----------------------------------------------------------------------
; DATOS onda_00: seno
;   0x7200..0x7300  (256 bytes)
DATA_onda_00:
	defb 000h,003h,006h,009h,00ch,010h,013h,016h,019h,01ch,01fh,022h,025h,028h,02bh,02eh	; 7200  ..........."%(+.
	defb 031h,033h,036h,039h,03ch,03fh,041h,044h,047h,049h,04ch,04eh,051h,053h,055h,058h	; 7210  1369<?ADGILNQSUX
	defb 05ah,05ch,05eh,060h,062h,064h,066h,068h,06ah,06bh,06dh,06fh,070h,071h,073h,074h	; 7220  Z\^`bdfhjkmopqst
	defb 075h,076h,078h,079h,07ah,07ah,07bh,07ch,07dh,07dh,07eh,07eh,07eh,07fh,07fh,07fh	; 7230  uvxyzz{|}}~~~...
	defb 07fh,07fh,07fh,07fh,07eh,07eh,07eh,07dh,07dh,07ch,07bh,07ah,07ah,079h,078h,076h	; 7240  ....~~~}}|{zzyxv
	defb 075h,074h,073h,071h,070h,06fh,06dh,06bh,06ah,068h,066h,064h,062h,060h,05eh,05ch	; 7250  utsqpomkjhfdb`^\
	defb 05ah,058h,055h,053h,051h,04eh,04ch,049h,047h,044h,041h,03fh,03ch,039h,036h,033h	; 7260  ZXUSQNLIGDA?<963
	defb 031h,02eh,02bh,028h,025h,022h,01fh,01ch,019h,016h,013h,010h,00ch,009h,006h,003h	; 7270  1.+(%"..........
	defb 000h,0fdh,0fah,0f7h,0f4h,0f0h,0edh,0eah,0e7h,0e4h,0e1h,0deh,0dbh,0d8h,0d5h,0d2h	; 7280  ................
	defb 0cfh,0cdh,0cah,0c7h,0c4h,0c1h,0bfh,0bch,0b9h,0b7h,0b4h,0b2h,0afh,0adh,0abh,0a8h	; 7290  ................
	defb 0a6h,0a4h,0a2h,0a0h,09eh,09ch,09ah,098h,096h,095h,093h,092h,090h,08fh,08dh,08ch	; 72a0  ................
	defb 08bh,08ah,088h,087h,086h,086h,085h,084h,083h,083h,082h,082h,082h,081h,081h,081h	; 72b0  ................
	defb 081h,081h,081h,081h,082h,082h,082h,083h,083h,084h,085h,086h,086h,087h,088h,089h	; 72c0  ................
	defb 08bh,08ch,08dh,08fh,090h,091h,093h,095h,096h,098h,09ah,09ch,09eh,0a0h,0a2h,0a4h	; 72d0  ................
	defb 0a6h,0a8h,0abh,0adh,0afh,0b2h,0b4h,0b7h,0b9h,0bch,0bfh,0c1h,0c4h,0c7h,0cah,0cch	; 72e0  ................
	defb 0cfh,0d2h,0d5h,0d8h,0dbh,0deh,0e1h,0e4h,0e7h,0eah,0edh,0f0h,0f3h,0f7h,0fah,0fdh	; 72f0  ................

; ----------------------------------------------------------------------
; DATOS onda_01: sierra descendente
;   0x7300..0x7400  (256 bytes)
DATA_onda_01:
	defb 07fh,07eh,07dh,07ch,07bh,07ah,079h,078h,077h,076h,075h,074h,073h,072h,071h,070h	; 7300  .~}|{zyxwvutsrqp
	defb 06fh,06eh,06dh,06ch,06bh,06ah,069h,068h,067h,066h,065h,064h,063h,062h,061h,060h	; 7310  onmlkjihgfedcba`
	defb 05fh,05eh,05dh,05ch,05bh,05ah,059h,058h,057h,056h,055h,054h,053h,052h,051h,050h	; 7320  _^]\[ZYXWVUTSRQP
	defb 04fh,04eh,04dh,04ch,04bh,04ah,049h,048h,047h,046h,045h,044h,043h,042h,041h,040h	; 7330  ONMLKJIHGFEDCBA@
	defb 03fh,03eh,03dh,03ch,03bh,03ah,039h,038h,037h,036h,035h,034h,033h,032h,031h,030h	; 7340  ?>=<;:9876543210
	defb 02fh,02eh,02dh,02ch,02bh,02ah,029h,028h,027h,026h,025h,024h,023h,022h,021h,020h	; 7350  /.-,+*)('&%$#"! 
	defb 01fh,01eh,01dh,01ch,01bh,01ah,019h,018h,017h,016h,015h,014h,013h,012h,011h,010h	; 7360  ................
	defb 00fh,00eh,00dh,00ch,00bh,00ah,009h,008h,007h,006h,005h,004h,003h,002h,001h,000h	; 7370  ................
	defb 0ffh,0feh,0fdh,0fch,0fbh,0fah,0f9h,0f8h,0f7h,0f6h,0f5h,0f4h,0f3h,0f2h,0f1h,0f0h	; 7380  ................
	defb 0efh,0eeh,0edh,0ech,0ebh,0eah,0e9h,0e8h,0e7h,0e6h,0e5h,0e4h,0e3h,0e2h,0e1h,0e0h	; 7390  ................
	defb 0dfh,0deh,0ddh,0dch,0dbh,0dah,0d9h,0d8h,0d7h,0d6h,0d5h,0d4h,0d3h,0d2h,0d1h,0d0h	; 73a0  ................
	defb 0cfh,0ceh,0cdh,0cch,0cbh,0cah,0c9h,0c8h,0c7h,0c6h,0c5h,0c4h,0c3h,0c2h,0c1h,0c0h	; 73b0  ................
	defb 0bfh,0beh,0bdh,0bch,0bbh,0bah,0b9h,0b8h,0b7h,0b6h,0b5h,0b4h,0b3h,0b2h,0b1h,0b0h	; 73c0  ................
	defb 0afh,0aeh,0adh,0ach,0abh,0aah,0a9h,0a8h,0a7h,0a6h,0a5h,0a4h,0a3h,0a2h,0a1h,0a0h	; 73d0  ................
	defb 09fh,09eh,09dh,09ch,09bh,09ah,099h,098h,097h,096h,095h,094h,093h,092h,091h,090h	; 73e0  ................
	defb 08fh,08eh,08dh,08ch,08bh,08ah,089h,088h,087h,086h,085h,084h,083h,082h,081h,080h	; 73f0  ................

; ----------------------------------------------------------------------
; DATOS onda_02: sierra ascendente
;   0x7400..0x7500  (256 bytes)
DATA_onda_02:
	defb 080h,081h,082h,083h,084h,085h,086h,087h,088h,089h,08ah,08bh,08ch,08dh,08eh,08fh	; 7400  ................
	defb 090h,091h,092h,093h,094h,095h,096h,097h,098h,099h,09ah,09bh,09ch,09dh,09eh,09fh	; 7410  ................
	defb 0a0h,0a1h,0a2h,0a3h,0a4h,0a5h,0a6h,0a7h,0a8h,0a9h,0aah,0abh,0ach,0adh,0aeh,0afh	; 7420  ................
	defb 0b0h,0b1h,0b2h,0b3h,0b4h,0b5h,0b6h,0b7h,0b8h,0b9h,0bah,0bbh,0bch,0bdh,0beh,0bfh	; 7430  ................
	defb 0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh	; 7440  ................
	defb 0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch,0ddh,0deh,0dfh	; 7450  ................
	defb 0e0h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h,0eah,0ebh,0ech,0edh,0eeh,0efh	; 7460  ................
	defb 0f0h,0f1h,0f2h,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh	; 7470  ................
	defb 000h,001h,002h,003h,004h,005h,006h,007h,008h,009h,00ah,00bh,00ch,00dh,00eh,00fh	; 7480  ................
	defb 010h,011h,012h,013h,014h,015h,016h,017h,018h,019h,01ah,01bh,01ch,01dh,01eh,01fh	; 7490  ................
	defb 020h,021h,022h,023h,024h,025h,026h,027h,028h,029h,02ah,02bh,02ch,02dh,02eh,02fh	; 74a0   !"#$%&'()*+,-./
	defb 030h,031h,032h,033h,034h,035h,036h,037h,038h,039h,03ah,03bh,03ch,03dh,03eh,03fh	; 74b0  0123456789:;<=>?
	defb 040h,041h,042h,043h,044h,045h,046h,047h,048h,049h,04ah,04bh,04ch,04dh,04eh,04fh	; 74c0  @ABCDEFGHIJKLMNO
	defb 050h,051h,052h,053h,054h,055h,056h,057h,058h,059h,05ah,05bh,05ch,05dh,05eh,05fh	; 74d0  PQRSTUVWXYZ[\]^_
	defb 060h,061h,062h,063h,064h,065h,066h,067h,068h,069h,06ah,06bh,06ch,06dh,06eh,06fh	; 74e0  `abcdefghijklmno
	defb 070h,071h,072h,073h,074h,075h,076h,077h,078h,079h,07ah,07bh,07ch,07dh,07eh,07fh	; 74f0  pqrstuvwxyz{|}~.

; ----------------------------------------------------------------------
; DATOS onda_03: cuadrada
;   0x7500..0x7600  (256 bytes)
DATA_onda_03:
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7500  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7510  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7520  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7530  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7540  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7550  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7560  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7570  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7580  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7590  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 75a0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 75b0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 75c0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 75d0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 75e0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 75f0  ................

; ----------------------------------------------------------------------
; DATOS onda_04: pulso
;   0x7600..0x7700  (256 bytes)
DATA_onda_04:
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7600  ................
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh	; 7610  ................
	defb 07fh,07fh,07fh,07fh,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7620  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7630  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7640  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7650  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7660  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7670  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7680  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 7690  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 76a0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 76b0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 76c0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 76d0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 76e0  ................
	defb 080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h,080h	; 76f0  ................

; ----------------------------------------------------------------------
; DATOS onda_05: onda muestreada
;   0x7700..0x7800  (256 bytes)
DATA_onda_05:
	defb 079h,079h,076h,070h,068h,05eh,054h,047h,03ah,02eh,01fh,014h,008h,0feh,0f5h,0eeh	; 7700  yyvph^TG:.......
	defb 0ebh,0e8h,0e7h,0e8h,0ech,0f1h,0f6h,0fdh,005h,00ch,014h,01ah,021h,027h,029h,02ch	; 7710  ............!'),
	defb 02bh,02bh,027h,022h,01ch,013h,00dh,003h,0fbh,0f3h,0eah,0e3h,0ddh,0d8h,0d6h,0d5h	; 7720  ++'"............
	defb 0d8h,0dah,0dfh,0e8h,0f1h,0fch,005h,013h,01eh,02ah,036h,040h,049h,050h,055h,057h	; 7730  .........*6@IPUW
	defb 057h,057h,053h,04ch,043h,038h,02eh,020h,012h,005h,0f7h,0eah,0ddh,0d2h,0c9h,0c2h	; 7740  WWSLC8. ........
	defb 0beh,0bbh,0bah,0bah,0bdh,0c3h,0c6h,0cdh,0d5h,0dbh,0e3h,0e9h,0f0h,0f6h,0f9h,0fbh	; 7750  ................
	defb 0fbh,0fah,0f7h,0f1h,0ebh,0e2h,0dch,0d2h,0cbh,0c3h,0bah,0b5h,0aeh,0aah,0a9h,0a8h	; 7760  ................
	defb 0abh,0aeh,0b3h,0bch,0c6h,0d2h,0ddh,0eah,0f6h,003h,010h,01ah,024h,02ch,032h,035h	; 7770  ............$,25
	defb 035h,035h,032h,02ch,024h,01ah,010h,003h,0f6h,0eah,0ddh,0d2h,0c6h,0bch,0b3h,0aeh	; 7780  552,$...........
	defb 0abh,0a8h,0a9h,0aah,0aeh,0b5h,0bah,0c3h,0cbh,0d2h,0dch,0e2h,0ebh,0f1h,0f7h,0fah	; 7790  ................
	defb 0fbh,0fbh,0f9h,0f6h,0f0h,0e9h,0e3h,0dbh,0d5h,0cdh,0c6h,0c3h,0bdh,0bah,0bah,0bah	; 77a0  ................
	defb 0beh,0c2h,0c9h,0d2h,0ddh,0eah,0f7h,005h,012h,020h,02eh,038h,043h,04ch,053h,057h	; 77b0  ......... .8CLSW
	defb 057h,057h,055h,050h,049h,040h,036h,02ah,01eh,013h,005h,0fch,0f1h,0e8h,0dfh,0dah	; 77c0  WWUPI@6*........
	defb 0d8h,0d5h,0d6h,0d8h,0ddh,0e3h,0eah,0f3h,0fbh,003h,00dh,013h,01ch,022h,027h,02bh	; 77d0  ............."'+
	defb 02bh,02ch,029h,027h,021h,01ah,014h,00ch,005h,0fdh,0f6h,0f1h,0ech,0e8h,0e7h,0e8h	; 77e0  +,)'!...........
	defb 0ebh,0eeh,0f5h,0feh,008h,014h,01fh,02eh,03ah,047h,054h,05eh,068h,070h,076h,079h	; 77f0  ........:GT^hpvy

; ----------------------------------------------------------------------
; DATOS onda_06: onda muestreada
;   0x7800..0x7900  (256 bytes)
DATA_onda_06:
	defb 05dh,05bh,052h,045h,035h,023h,014h,007h,0feh,0f9h,0fah,0feh,004h,00bh,011h,015h	; 7800  ][RE5#..........
	defb 016h,013h,00dh,005h,0fbh,0f3h,0edh,0eah,0edh,0f3h,0ffh,00ch,01ch,02ah,036h,03dh	; 7810  .............*6=
	defb 03eh,03bh,030h,022h,010h,0feh,0edh,0dfh,0d5h,0d0h,0cfh,0d3h,0d9h,0dfh,0e5h,0e9h	; 7820  >;0"............
	defb 0eah,0e7h,0e1h,0d9h,0d0h,0c8h,0c2h,0c1h,0c4h,0cbh,0d8h,0e7h,0f7h,007h,014h,01dh	; 7830  ................
	defb 01fh,01dh,014h,007h,0f7h,0e7h,0d8h,0cbh,0c4h,0c1h,0c2h,0c8h,0d0h,0d9h,0e1h,0e7h	; 7840  ................
	defb 0eah,0e9h,0e5h,0dfh,0d9h,0d3h,0cfh,0d0h,0d5h,0dfh,0edh,0feh,010h,022h,030h,03bh	; 7850  ............."0;
	defb 03eh,03dh,036h,02ah,01ch,00ch,0ffh,0f3h,0edh,0eah,0edh,0f3h,0fbh,005h,00dh,013h	; 7860  >=6*............
	defb 016h,015h,011h,00bh,004h,0feh,0fah,0f9h,0feh,007h,014h,023h,035h,045h,052h,05bh	; 7870  ...........#5ER[
	defb 05dh,05bh,052h,045h,035h,023h,014h,007h,0feh,0f9h,0fah,0feh,004h,00bh,011h,015h	; 7880  ][RE5#..........
	defb 016h,013h,00dh,005h,0fbh,0f3h,0edh,0eah,0edh,0f3h,0ffh,00ch,01ch,02ah,036h,03dh	; 7890  .............*6=
	defb 03eh,03bh,030h,022h,010h,0feh,0edh,0dfh,0d5h,0d0h,0cfh,0d3h,0d9h,0dfh,0e5h,0e9h	; 78a0  >;0"............
	defb 0eah,0e7h,0e1h,0d9h,0d0h,0c8h,0c2h,0c1h,0c4h,0cbh,0d8h,0e7h,0f7h,007h,014h,01dh	; 78b0  ................
	defb 01fh,01dh,014h,007h,0f7h,0e7h,0d8h,0cbh,0c4h,0c1h,0c2h,0c8h,0d0h,0d9h,0e1h,0e7h	; 78c0  ................
	defb 0eah,0e9h,0e5h,0dfh,0d9h,0d3h,0cfh,0d0h,0d5h,0dfh,0edh,0feh,010h,022h,030h,03bh	; 78d0  ............."0;
	defb 03eh,03dh,036h,02ah,01ch,00ch,0ffh,0f3h,0edh,0eah,0edh,0f3h,0fbh,005h,00dh,013h	; 78e0  >=6*............
	defb 016h,015h,011h,00bh,004h,0feh,0fah,0f9h,0feh,007h,014h,023h,035h,045h,052h,05bh	; 78f0  ...........#5ER[

; ----------------------------------------------------------------------
; DATOS onda_07: onda muestreada
;   0x7900..0x7a00  (256 bytes)
DATA_onda_07:
	defb 032h,036h,039h,03ch,03dh,03eh,03fh,040h,043h,045h,048h,04ah,04bh,04ch,04ch,04dh	; 7900  269<=>?@CEHJKLLM
	defb 04ch,04ch,04ch,04ch,04dh,04dh,04dh,04dh,04ch,04bh,04bh,04ah,04ah,04ah,04bh,04ch	; 7910  LLLLMMMMLKKJJJKL
	defb 04dh,04eh,04eh,04dh,04ch,04ah,048h,045h,043h,041h,040h,040h,03fh,03eh,03ch,03ah	; 7920  MNNMLJHECA@@?><:
	defb 038h,038h,037h,037h,038h,038h,039h,038h,038h,035h,033h,030h,02dh,02bh,029h,028h	; 7930  887788988530-+)(
	defb 028h,026h,025h,023h,020h,01eh,01ch,01ah,018h,016h,015h,014h,013h,012h,011h,00fh	; 7940  (&%# ...........
	defb 00eh,00dh,00ch,00ch,00dh,00eh,00eh,00eh,00fh,00eh,00dh,00bh,008h,006h,003h,000h	; 7950  ................
	defb 0feh,0fbh,0f6h,0f1h,0ebh,0e5h,0dfh,0dah,0d5h,0d2h,0cfh,0cch,0c9h,0c5h,0c1h,0bdh	; 7960  ................
	defb 0b9h,0b6h,0b4h,0b1h,0b0h,0aeh,0ach,0a9h,0a7h,0a5h,0a3h,0a2h,0a2h,0a2h,0a3h,0a4h	; 7970  ................
	defb 0a5h,0a7h,0a9h,0ach,0afh,0b2h,0b6h,0bah,0bfh,0c4h,0cah,0d0h,0d6h,0dch,0e2h,0e8h	; 7980  ................
	defb 0edh,0f2h,0f8h,0feh,005h,00bh,011h,016h,01bh,01eh,021h,024h,028h,02dh,031h,036h	; 7990  ..........!$(-16
	defb 03ah,03eh,041h,044h,046h,047h,049h,04bh,04dh,04fh,051h,052h,052h,050h,04eh,04ah	; 79a0  :>ADFGIKMOQRRPNJ
	defb 046h,042h,03fh,03dh,03ah,038h,035h,032h,030h,02ch,029h,026h,023h,021h,01fh,01dh	; 79b0  FB?=:8520,)&#!..
	defb 01bh,018h,013h,00eh,008h,001h,0fbh,0f4h,0eeh,0e8h,0e1h,0dbh,0d4h,0ceh,0c8h,0c2h	; 79c0  ................
	defb 0bdh,0b8h,0b4h,0b0h,0ach,0a9h,0a6h,0a4h,0a0h,09eh,09ch,09bh,09bh,09ch,09eh,0a1h	; 79d0  ................
	defb 0a4h,0a8h,0ach,0b0h,0b4h,0b8h,0bch,0c1h,0c7h,0cch,0d2h,0d7h,0dch,0e0h,0e3h,0e6h	; 79e0  ................
	defb 0eah,0eeh,0f3h,0f8h,0feh,004h,00bh,00fh,014h,018h,01bh,01fh,022h,027h,02ch,030h	; 79f0  ............"',0

; ----------------------------------------------------------------------
; DATOS onda_08: onda muestreada
;   0x7a00..0x7b00  (256 bytes)
DATA_onda_08:
	defb 07bh,07bh,07bh,07bh,07ah,077h,076h,074h,072h,06fh,06bh,069h,065h,061h,05dh,057h	; 7a00  {{{{zwvtrokiea]W
	defb 053h,04fh,048h,044h,03fh,038h,036h,02eh,02ah,025h,01fh,01ah,014h,00fh,009h,005h	; 7a10  SOHD?86.*%......
	defb 000h,0fch,0f7h,0f3h,0eeh,0eah,0e6h,0e4h,0dfh,0deh,0dbh,0d8h,0d7h,0d4h,0d2h,0d0h	; 7a20  ................
	defb 0d1h,0cfh,0cfh,0cfh,0cfh,0cfh,0cfh,0d2h,0d3h,0d3h,0d5h,0d8h,0d8h,0dah,0dch,0deh	; 7a30  ................
	defb 0e1h,0e4h,0e6h,0e8h,0eah,0ech,0efh,0f1h,0f3h,0f6h,0f9h,0fbh,0fdh,0ffh,001h,003h	; 7a40  ................
	defb 003h,006h,006h,006h,007h,008h,007h,008h,009h,008h,008h,008h,006h,005h,003h,002h	; 7a50  ................
	defb 000h,0fdh,0fdh,0f9h,0f8h,0f4h,0f3h,0efh,0eeh,0ech,0e8h,0e8h,0e3h,0e2h,0e0h,0dbh	; 7a60  ................
	defb 0d9h,0d7h,0d3h,0d1h,0cfh,0cdh,0cdh,0c9h,0c8h,0c8h,0c6h,0c5h,0c4h,0c3h,0c3h,0c3h	; 7a70  ................
	defb 0c3h,0c3h,0c3h,0c3h,0c4h,0c5h,0c6h,0c8h,0c8h,0c9h,0cdh,0cdh,0cfh,0d1h,0d3h,0d7h	; 7a80  ................
	defb 0d9h,0dbh,0e0h,0e2h,0e3h,0e8h,0e8h,0ech,0eeh,0efh,0f3h,0f4h,0f8h,0f9h,0fdh,0fdh	; 7a90  ................
	defb 000h,002h,003h,005h,006h,008h,008h,008h,009h,008h,007h,008h,007h,006h,006h,005h	; 7aa0  ................
	defb 003h,003h,001h,0ffh,0fdh,0fbh,0f9h,0f6h,0f3h,0f1h,0efh,0ech,0eah,0e8h,0e6h,0e4h	; 7ab0  ................
	defb 0e1h,0deh,0dch,0dah,0d8h,0d8h,0d5h,0d3h,0d3h,0d2h,0cfh,0cfh,0cfh,0cfh,0cfh,0cfh	; 7ac0  ................
	defb 0d1h,0d0h,0d2h,0d4h,0d7h,0d8h,0dbh,0deh,0dfh,0e4h,0e6h,0eah,0eeh,0f3h,0f7h,0fch	; 7ad0  ................
	defb 000h,005h,009h,00fh,014h,019h,01fh,025h,02ah,02eh,036h,038h,03fh,044h,048h,04fh	; 7ae0  .......%*.68?DHO
	defb 053h,057h,05dh,061h,065h,069h,06bh,06fh,072h,074h,076h,077h,07ah,07bh,07bh,07bh	; 7af0  SW]aeikortvwz{{{

; ----------------------------------------------------------------------
; DATOS onda_09: onda muestreada
;   0x7b00..0x7c00  (256 bytes)
DATA_onda_09:
	defb 07eh,07dh,078h,071h,067h,05bh,04eh,03fh,032h,025h,017h,00dh,005h,0ffh,0fdh,0fdh	; 7b00  ~}xqg[N?2%......
	defb 000h,006h,00fh,019h,026h,033h,03fh,04ch,058h,062h,069h,06eh,070h,06fh,06bh,063h	; 7b10  ....&3?LXbinpokc
	defb 05ah,04eh,03fh,031h,022h,013h,006h,0f8h,0eeh,0e7h,0e1h,0e0h,0e1h,0e5h,0ech,0f5h	; 7b20  ZN?1"...........
	defb 000h,00ch,018h,025h,030h,03ah,042h,048h,04ah,04ah,046h,040h,037h,02bh,01eh,00fh	; 7b30  ...%0:BHJJF@7+..
	defb 000h,0f1h,0e2h,0d5h,0c9h,0c0h,0bah,0b6h,0b6h,0b8h,0beh,0c6h,0d0h,0dbh,0e8h,0f4h	; 7b40  ................
	defb 000h,00bh,014h,01bh,01fh,020h,01fh,019h,012h,008h,0fah,0edh,0deh,0cfh,0c1h,0b2h	; 7b50  ..... ..........
	defb 0a6h,09dh,095h,091h,090h,092h,097h,09eh,0a8h,0b4h,0c1h,0cdh,0dah,0e7h,0f1h,0fah	; 7b60  ................
	defb 000h,003h,003h,001h,0fbh,0f3h,0e9h,0dbh,0ceh,0c1h,0b2h,0a5h,099h,08fh,088h,083h	; 7b70  ................
	defb 082h,083h,088h,08fh,099h,0a5h,0b2h,0c1h,0ceh,0dbh,0e9h,0f3h,0fbh,001h,003h,003h	; 7b80  ................
	defb 000h,0fah,0f1h,0e7h,0dah,0cdh,0c1h,0b4h,0a8h,09eh,097h,092h,090h,091h,095h,09dh	; 7b90  ................
	defb 0a6h,0b2h,0c1h,0cfh,0deh,0edh,0fah,008h,012h,019h,01fh,020h,01fh,01bh,014h,00ah	; 7ba0  ........... ....
	defb 000h,0f4h,0e8h,0dbh,0d0h,0c6h,0beh,0b8h,0b6h,0b6h,0bah,0c0h,0c9h,0d5h,0e2h,0f1h	; 7bb0  ................
	defb 000h,00fh,01eh,02bh,037h,040h,046h,04ah,04ah,048h,042h,03ah,030h,025h,018h,00ch	; 7bc0  ...+7@FJJHB:0%..
	defb 000h,0f5h,0ech,0e5h,0e1h,0e0h,0e1h,0e7h,0eeh,0f8h,006h,013h,022h,031h,03fh,04eh	; 7bd0  ............"1?N
	defb 05ah,063h,06bh,06fh,070h,06eh,069h,062h,058h,04ch,03fh,033h,026h,019h,00fh,006h	; 7be0  ZckopnibXL?3&...
	defb 000h,0fdh,0fdh,0ffh,005h,00dh,017h,024h,032h,03fh,04eh,05bh,067h,071h,078h,07dh	; 7bf0  .......$2?N[gqx}

; ----------------------------------------------------------------------
; DATOS onda_10: onda muestreada
;   0x7c00..0x7d00  (256 bytes)
DATA_onda_10:
	defb 0beh,0c6h,0c4h,0c8h,0cfh,0d4h,0deh,0ech,0f9h,00bh,022h,030h,042h,050h,058h,062h	; 7c00  .........."0BPXb
	defb 068h,069h,06dh,06eh,06fh,073h,06fh,06bh,071h,06bh,06ch,06dh,06bh,06ah,068h,067h	; 7c10  himnosokqklmkjhg
	defb 064h,067h,060h,065h,061h,05dh,05eh,05dh,060h,05bh,058h,058h,057h,057h,056h,055h	; 7c20  dg`ea]^]`[XXWWVU
	defb 053h,054h,056h,051h,054h,054h,04fh,052h,052h,04fh,04fh,04fh,04ch,04eh,04ch,048h	; 7c30  STVQTTORROOOLNLH
	defb 04ah,048h,044h,042h,03eh,03ah,039h,032h,02eh,02ch,024h,020h,01ah,016h,010h,00dh	; 7c40  JHDB>:92.,$ ....
	defb 006h,005h,005h,002h,006h,00bh,00bh,010h,014h,01ch,020h,020h,022h,027h,024h,025h	; 7c50  ..........  "'$%
	defb 020h,019h,013h,006h,0fch,0f2h,0e7h,0deh,0d7h,0d2h,0cch,0c6h,0c3h,0c2h,0c1h,0bah	; 7c60   ...............
	defb 0b6h,0b7h,0b7h,0b4h,0b4h,0afh,0afh,0b0h,0b2h,0aeh,0afh,0ach,0aeh,0b2h,0b1h,0b4h	; 7c70  ................
	defb 0b7h,0b8h,0bdh,0bfh,0c2h,0c8h,0cfh,0cfh,0d6h,0dch,0dfh,0e6h,0eah,0efh,0f4h,0fah	; 7c80  ................
	defb 0fdh,002h,006h,00ah,00ah,00ch,012h,012h,011h,017h,017h,016h,014h,014h,014h,012h	; 7c90  ................
	defb 00eh,00ch,00fh,00ah,007h,006h,001h,0ffh,0fch,0fch,0fah,0f7h,0f1h,0eeh,0ech,0e2h	; 7ca0  ................
	defb 0dch,0d5h,0cch,0c3h,0b7h,0adh,0a8h,0a4h,09eh,09dh,09bh,09ah,09fh,0a0h,0a9h,0afh	; 7cb0  ................
	defb 0b3h,0b8h,0bfh,0bfh,0c2h,0c3h,0c1h,0bfh,0bch,0b8h,0b6h,0b4h,0b0h,0aah,0a8h,0a1h	; 7cc0  ................
	defb 0a0h,09fh,09eh,09bh,09ah,099h,09ah,096h,098h,09bh,09ah,09bh,09ch,09bh,09fh,0a3h	; 7cd0  ................
	defb 0a0h,0a4h,0a5h,0a4h,0abh,0a6h,0a8h,0adh,0adh,0afh,0aeh,0afh,0afh,0b2h,0b2h,0b3h	; 7ce0  ................
	defb 0b3h,0b0h,0b3h,0b6h,0b1h,0b4h,0b5h,0b6h,0b7h,0b5h,0b4h,0b8h,0b9h,0bbh,0bbh,0bah	; 7cf0  ................

; ----------------------------------------------------------------------
; DATOS onda_11: onda muestreada
;   0x7d00..0x7e00  (256 bytes)
DATA_onda_11:
	defb 088h,086h,089h,08ch,092h,09ch,0ach,0c4h,0e7h,00fh,03ch,060h,074h,07ah,078h,074h	; 7d00  ..........<`tzxt
	defb 06ch,064h,05fh,059h,050h,04ah,045h,03dh,036h,032h,02ch,026h,022h,01ch,016h,011h	; 7d10  ld_YPJE=62,&"...
	defb 00eh,008h,004h,002h,0fch,0f8h,0f6h,0f2h,0efh,0edh,0ech,0e8h,0e6h,0e4h,0e1h,0dfh	; 7d20  ................
	defb 0dfh,0deh,0dbh,0dah,0d8h,0d7h,0d5h,0d7h,0d5h,0d4h,0d4h,0d3h,0d2h,0d2h,0d2h,0d1h	; 7d30  ................
	defb 0d2h,0d3h,0d2h,0d1h,0d1h,0d2h,0d1h,0d2h,0d3h,0d3h,0d2h,0d3h,0d4h,0d4h,0d4h,0d8h	; 7d40  ................
	defb 0d7h,0d8h,0d8h,0d9h,0dah,0dbh,0ddh,0deh,0dfh,0e0h,0e0h,0e2h,0e3h,0e4h,0e5h,0e7h	; 7d50  ................
	defb 0e8h,0eah,0ebh,0ech,0edh,0f0h,0f2h,0f3h,0f4h,0f6h,0f8h,0f8h,0fah,0feh,0ffh,000h	; 7d60  ................
	defb 002h,004h,005h,008h,00ah,00ah,00dh,00eh,010h,011h,013h,015h,017h,01ah,01ah,01ch	; 7d70  ................
	defb 01eh,01fh,020h,022h,025h,025h,026h,029h,028h,02bh,02dh,02fh,02fh,031h,033h,035h	; 7d80  .. "%%&)(+-//135
	defb 034h,036h,038h,039h,039h,03bh,03bh,03ch,03fh,03eh,03fh,040h,041h,043h,043h,043h	; 7d90  46899;;<?>?@ACCC
	defb 042h,044h,044h,044h,044h,047h,046h,046h,045h,048h,044h,047h,047h,046h,046h,047h	; 7da0  BDDDDGFFEHDGGFFG
	defb 047h,046h,044h,045h,044h,044h,042h,042h,042h,042h,040h,040h,03eh,03fh,03ch,03ch	; 7db0  GFDEDDBBBB@@>?<<
	defb 03ch,03ah,039h,038h,037h,035h,033h,034h,031h,030h,02eh,02bh,02ah,028h,026h,024h	; 7dc0  <:98753410.+*(&$
	defb 023h,020h,01dh,01ah,01ah,016h,014h,013h,00fh,00dh,008h,007h,003h,001h,0ffh,0fah	; 7dd0  # ..............
	defb 0f6h,0f5h,0f0h,0ech,0e9h,0e7h,0e4h,0ddh,0dbh,0d6h,0d2h,0cfh,0cah,0c5h,0c3h,0bdh	; 7de0  ................
	defb 0b7h,0b8h,0b0h,0abh,0a8h,0a4h,09fh,099h,096h,091h,08eh,08ch,08ah,088h,087h,08ah	; 7df0  ................

; ----------------------------------------------------------------------
; DATOS onda_12: onda muestreada
;   0x7e00..0x7f00  (256 bytes)
DATA_onda_12:
	defb 081h,08ah,096h,0abh,0c5h,0e5h,005h,028h,044h,05ch,067h,069h,068h,065h,05fh,05bh	; 7e00  .......(D\gihe_[
	defb 054h,050h,04ah,042h,03eh,036h,030h,02ch,028h,023h,022h,01fh,022h,023h,023h,023h	; 7e10  TPJB>60,(#"."###
	defb 026h,026h,029h,026h,026h,023h,027h,023h,021h,021h,01ah,01bh,017h,010h,00bh,004h	; 7e20  &&)&&#'#!!......
	defb 0ffh,0f8h,0efh,0e6h,0e1h,0d9h,0d4h,0d3h,0d1h,0d0h,0d3h,0d3h,0d8h,0dch,0e0h,0e4h	; 7e30  ................
	defb 0e5h,0e7h,0eah,0eah,0e8h,0eah,0e8h,0e6h,0e1h,0ddh,0dch,0d4h,0cfh,0cch,0c6h,0c1h	; 7e40  ................
	defb 0bfh,0bfh,0bch,0bdh,0beh,0bfh,0c3h,0c3h,0c7h,0c9h,0cah,0cbh,0cbh,0cbh,0cbh,0c9h	; 7e50  ................
	defb 0c6h,0c5h,0c2h,0beh,0bch,0bbh,0b8h,0bch,0bbh,0bfh,0c6h,0cbh,0d1h,0dah,0deh,0e4h	; 7e60  ................
	defb 0eah,0ech,0f0h,0f2h,0f3h,0f4h,0f6h,0f4h,0f4h,0f4h,0f3h,0f2h,0f1h,0efh,0eeh,0ech	; 7e70  ................
	defb 0e6h,0e4h,0ddh,0d7h,0d2h,0cbh,0c5h,0c0h,0bch,0b8h,0b6h,0b3h,0b2h,0b1h,0b0h,0b0h	; 7e80  ................
	defb 0b0h,0afh,0b1h,0b2h,0b1h,0b4h,0b6h,0b8h,0bch,0c0h,0c6h,0cfh,0d4h,0dch,0e3h,0e7h	; 7e90  ................
	defb 0ebh,0edh,0edh,0edh,0ebh,0e7h,0e6h,0e4h,0deh,0deh,0dah,0d9h,0d8h,0d7h,0d8h,0dah	; 7ea0  ................
	defb 0dch,0ddh,0e1h,0e2h,0e4h,0e5h,0e5h,0e4h,0e4h,0dfh,0dch,0dah,0d2h,0cfh,0c9h,0c4h	; 7eb0  ................
	defb 0c1h,0beh,0bah,0b9h,0b9h,0b7h,0b8h,0b8h,0bah,0bdh,0c0h,0c4h,0c8h,0cch,0cfh,0d3h	; 7ec0  ................
	defb 0d3h,0d3h,0d0h,0cch,0c8h,0c1h,0b9h,0b4h,0afh,0a7h,0a2h,09eh,09ah,097h,094h,092h	; 7ed0  ................
	defb 092h,091h,090h,092h,091h,092h,093h,096h,098h,09bh,09ch,0a0h,0a4h,0a4h,0a4h,0a5h	; 7ee0  ................
	defb 0a4h,0a3h,0a0h,09ch,09ah,098h,093h,090h,08ch,08bh,088h,085h,082h,080h,080h,080h	; 7ef0  ................

; ----------------------------------------------------------------------
; DATOS onda_13: onda muestreada
;   0x7f00..0x8000  (256 bytes)
DATA_onda_13:
	defb 03fh,052h,05eh,063h,06ah,06dh,072h,076h,077h,07ah,07ch,078h,077h,074h,06fh,06dh	; 7f00  ?R^cjmrvwz|xwtom
	defb 068h,065h,062h,05dh,050h,041h,02bh,015h,002h,0f4h,0e7h,0dch,0d4h,0cah,0c1h,0bbh	; 7f10  heb]PA+.........
	defb 0b3h,0aeh,0a7h,0a3h,0a0h,09fh,09fh,09eh,09fh,0a1h,0a1h,0a0h,0a0h,0a0h,0a2h,0a4h	; 7f20  ................
	defb 0a9h,0abh,0b2h,0b4h,0bbh,0bfh,0c4h,0cch,0d0h,0d7h,0dch,0e0h,0e7h,0ech,0f1h,0f6h	; 7f30  ................
	defb 0feh,003h,008h,00fh,013h,018h,01eh,021h,028h,02ah,02eh,032h,035h,037h,03ah,03ah	; 7f40  .......!(*.257::
	defb 037h,034h,030h,02fh,034h,03bh,042h,04ch,053h,056h,057h,059h,058h,059h,056h,058h	; 7f50  740/4;BLSVWYXYVX
	defb 056h,055h,057h,054h,051h,04dh,046h,03bh,02eh,01fh,018h,019h,01eh,027h,030h,034h	; 7f60  VUWTQMF;.....'04
	defb 038h,038h,037h,037h,032h,030h,02fh,02dh,02ch,02eh,030h,031h,030h,027h,016h,004h	; 7f70  887720/-,.010'..
	defb 0f2h,0e9h,0e5h,0e6h,0ebh,0edh,0efh,0f0h,0f0h,0efh,0edh,0ech,0ech,0eeh,0f0h,0f5h	; 7f80  ................
	defb 0fdh,007h,010h,013h,00dh,004h,0f6h,0ebh,0e4h,0e0h,0e0h,0e1h,0e2h,0e4h,0e7h,0e7h	; 7f90  ................
	defb 0e9h,0ebh,0ech,0eeh,0f3h,0f6h,0fdh,004h,00fh,019h,01eh,01fh,01dh,01ah,018h,018h	; 7fa0  ................
	defb 019h,01ah,01fh,022h,026h,02bh,02eh,034h,038h,03ch,040h,044h,049h,04eh,050h,054h	; 7fb0  ..."&+.48<@DINPT
	defb 05ah,05ch,05eh,062h,065h,068h,06bh,06ch,06fh,072h,074h,073h,074h,074h,075h,074h	; 7fc0  Z\^behklortsttut
	defb 06fh,06eh,067h,060h,05dh,058h,056h,054h,04eh,04bh,044h,03ch,033h,02bh,021h,018h	; 7fd0  ong`]XVTNKD<3+!.
	defb 00dh,002h,0f9h,0edh,0e2h,0d5h,0c5h,0b3h,0a1h,092h,08bh,088h,088h,089h,08bh,08bh	; 7fe0  ................
	defb 08dh,08eh,090h,094h,099h,09fh,0a5h,0ach,0b4h,0bch,0c4h,0cch,0d8h,0eah,004h,022h	; 7ff0  ..............."

; ----------------------------------------------------------------------
; DATOS sprites_patrones: flujo RLE de 0x4352 hacia 0x1800 (0x43A1): los
;   patrones de los sprites de 16x16
;   0x8000..0x82a5  (677 bytes)
DATA_sprites_patrones:
	defb 000h,018h,081h,000h,003h,003h,084h,00fh,007h,003h,001h,009h,000h,003h,0c0h,084h	; 8000  ................
	defb 0f0h,0e0h,0c0h,080h,008h,000h,089h,007h,004h,004h,01ch,010h,008h,004h,002h,001h	; 8010  ................
	defb 007h,000h,089h,0e0h,020h,020h,038h,008h,010h,020h,040h,080h,008h,000h,088h,008h	; 8020  ....  8.. @.....
	defb 018h,03fh,07fh,07fh,03fh,018h,008h,017h,000h,08ah,00ch,014h,027h,040h,080h,080h	; 8030  .?..?.......'@..
	defb 040h,027h,014h,00ch,008h,000h,006h,080h,008h,000h,003h,010h,081h,0feh,003h,010h	; 8040  @'..............
	defb 019h,000h,002h,0ffh,008h,0c0h,002h,0ffh,004h,000h,002h,0e0h,008h,060h,002h,0e0h	; 8050  .............`..
	defb 005h,000h,088h,008h,00ch,07eh,07fh,07fh,07eh,00ch,008h,017h,000h,08ah,018h,014h	; 8060  .....~..~.......
	defb 0f2h,081h,080h,080h,081h,0f2h,014h,018h,00ah,000h,002h,080h,00ah,000h,084h,003h	; 8070  ................
	defb 007h,00fh,00fh,003h,01fh,002h,01bh,08ch,01ch,03fh,01fh,03fh,03fh,077h,0e7h,0e0h	; 8080  .........?.??w..
	defb 0f0h,0f8h,0fch,01ch,003h,0fch,083h,074h,0e0h,080h,003h,0e0h,08eh,0f0h,068h,004h	; 8090  .......t......h.
	defb 018h,010h,000h,020h,020h,000h,024h,004h,023h,000h,020h,004h,000h,085h,006h,00eh	; 80a0  ...  .$.#. .....
	defb 004h,000h,0e0h,003h,000h,08dh,088h,018h,078h,018h,010h,000h,000h,090h,000h,003h	; 80b0  ........x.......
	defb 007h,00fh,00fh,003h,01fh,093h,01bh,03ch,03fh,03fh,0ffh,07fh,00fh,00eh,000h,0e0h	; 80c0  .......<??......
	defb 0f0h,098h,01ch,01ch,0fch,0f0h,0fch,0f0h,0a0h,003h,0c0h,08dh,080h,0a0h,000h,004h	; 80d0  ................
	defb 018h,010h,000h,020h,020h,000h,024h,003h,040h,004h,000h,0abh,001h,000h,006h,00eh	; 80e0  ...  .$.@.......
	defb 064h,0c0h,0e0h,000h,00ch,000h,008h,058h,038h,030h,000h,000h,040h,003h,007h,00fh	; 80f0  d......X80..@...
	defb 00fh,01fh,01fh,01dh,01bh,037h,0b1h,0bfh,0ffh,07fh,01fh,03fh,03ah,0e0h,0f0h,098h	; 8100  .....7.....?:...
	defb 01ch,01ch,0fch,080h,0fch,0e0h,040h,004h,080h,08ch,018h,090h,004h,018h,010h,000h	; 8110  ......@.........
	defb 020h,020h,002h,024h,008h,04eh,005h,000h,0dch,005h,006h,00eh,064h,0c0h,0e0h,000h	; 8120    .$.N......d...
	defb 07ch,000h,018h,0b8h,078h,070h,070h,060h,000h,008h,000h,007h,00ah,012h,013h,01fh	; 8130  |...xpp`........
	defb 01fh,030h,03fh,070h,07ch,018h,018h,03ch,038h,028h,000h,0e0h,050h,048h,0c8h,0f8h	; 8140  .0?p|..<8(..PH..
	defb 0f8h,00ch,0fch,00eh,03eh,018h,018h,03ch,01ch,014h,001h,000h,005h,009h,00ch,000h	; 8150  ....>..<........
	defb 000h,004h,000h,000h,003h,007h,007h,003h,003h,054h,080h,000h,0a0h,090h,030h,000h	; 8160  .........T....0.
	defb 000h,020h,000h,000h,0c0h,0e0h,0e0h,0c0h,0c0h,02ah,003h,003h,01fh,018h,0d0h,0d0h	; 8170  . .......*......
	defb 068h,07ch,03bh,01ch,01ch,003h,018h,096h,00ch,00ah,0c0h,0c0h,0f8h,018h,00bh,00bh	; 8180  h|;.............
	defb 016h,03eh,0dch,038h,038h,018h,018h,01ch,034h,068h,004h,008h,000h,004h,006h,000h	; 8190  .>.88...4h......
	defb 08ah,003h,007h,007h,003h,000h,015h,020h,010h,000h,020h,006h,000h,096h,0c0h,0e0h	; 81a0  ....... .. .....
	defb 0e0h,0c0h,008h,010h,000h,000h,03fh,07fh,0ffh,0e7h,0ffh,07fh,0fah,01ch,007h,007h	; 81b0  ......?.........
	defb 00fh,00fh,007h,004h,003h,000h,083h,080h,0c0h,0c0h,006h,0e0h,002h,0f0h,08eh,0f8h	; 81c0  ................
	defb 0ceh,000h,01ch,0c0h,080h,000h,018h,000h,000h,005h,063h,078h,038h,003h,000h,08fh	; 81d0  ..........cx8...
	defb 00bh,000h,000h,0c0h,040h,030h,030h,000h,010h,000h,010h,000h,010h,000h,008h,004h	; 81e0  ....@00.........
	defb 000h,094h,007h,00fh,019h,038h,039h,03fh,007h,006h,007h,003h,000h,003h,007h,002h	; 81f0  .....89?........
	defb 000h,000h,0c0h,0e0h,0f0h,0f0h,003h,0f8h,0a4h,0b8h,078h,0f8h,0f9h,0feh,0fch,0e0h	; 8200  ..........x.....
	defb 000h,003h,018h,010h,006h,003h,006h,000h,008h,019h,018h,01ch,00fh,004h,000h,005h	; 8210  ................
	defb 000h,000h,030h,010h,000h,00ch,004h,000h,004h,040h,084h,000h,004h,004h,000h,084h	; 8220  ..0......@......
	defb 001h,003h,007h,00fh,003h,003h,009h,000h,084h,080h,0c0h,0e0h,0f0h,003h,0c0h,008h	; 8230  ................
	defb 000h,089h,001h,002h,004h,008h,010h,01ch,004h,004h,007h,007h,000h,089h,080h,040h	; 8240  ...............@
	defb 020h,010h,008h,038h,020h,020h,0e0h,00eh,000h,081h,003h,005h,00fh,002h,007h,002h	; 8250   ..8  ..........
	defb 000h,006h,060h,088h,0e0h,0e8h,0e8h,0f8h,0f0h,0e0h,0c0h,0c0h,007h,000h,082h,003h	; 8260  ..`.............
	defb 00ch,005h,010h,002h,008h,082h,007h,060h,006h,090h,08bh,018h,014h,014h,004h,008h	; 8270  .......`........
	defb 010h,020h,020h,0c0h,0ffh,0ffh,008h,0c0h,002h,0ffh,004h,000h,002h,0ffh,008h,000h	; 8280  .  .............
	defb 002h,0ffh,004h,000h,002h,0ffh,008h,000h,002h,0ffh,004h,000h,002h,0f0h,008h,030h	; 8290  ...............0
	defb 002h,0f0h,004h,000h,000h	; 82a0

; ----------------------------------------------------------------------
; DATOS marco_patrones: flujo RLE de 0x4327 hacia 0x2200: patrones del marco
;   comun
;   0x82a5..0x84eb  (582 bytes)
DATA_marco_patrones:
	defb 08bh,000h,03eh,063h,067h,06bh,073h,063h,03eh,000h,018h,038h,005h,018h,0adh,000h	; 82a5  ..>cgksc>..8....
	defb 03eh,063h,003h,00eh,038h,060h,07fh,000h,03eh,063h,003h,00eh,003h,063h,03eh,000h	; 82b5  >c..8`..>c...c>.
	defb 006h,00eh,01eh,036h,066h,07fh,006h,000h,07eh,060h,060h,07eh,003h,043h,03eh,000h	; 82c5  ...6f...~``~.C>.
	defb 03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,002h,006h,003h,00ch,090h,000h	; 82d5  >c`~cc>..c......
	defb 03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh,003h,063h,03eh,008h	; 82e5  >cc>cc>.>cc?.c>.
	defb 07fh,026h,000h,002h,0f0h,00eh,000h,002h,00fh,018h,000h,008h,0feh,081h,0e6h,003h	; 82f5  .&..............
	defb 049h,081h,046h,003h,000h,085h,04bh,06ah,06bh,05ah,04bh,003h,000h,085h,087h,004h	; 8305  I.F...KjkZK.....
	defb 0b7h,004h,087h,003h,000h,085h,093h,094h,097h,0f4h,094h,003h,000h,085h,02bh,0aah	; 8315  ..............+.
	defb 0abh,0aah,093h,003h,000h,085h,087h,004h,0b7h,004h,087h,003h,000h,085h,031h,041h	; 8325  ..............1A
	defb 030h,008h,070h,003h,000h,085h,044h,046h,087h,085h,084h,003h,000h,005h,080h,003h	; 8335  0.p...DF........
	defb 000h,085h,038h,024h,038h,020h,020h,003h,000h,085h,081h,082h,083h,082h,0f2h,003h	; 8345  ..8$8  .........
	defb 000h,085h,08ah,04ah,0c4h,044h,044h,003h,000h,004h,020h,081h,03ch,003h,000h,085h	; 8355  ...J.DD... .<...
	defb 0e3h,044h,043h,040h,0e7h,003h,000h,085h,01ch,008h,088h,088h,008h,003h,000h,085h	; 8365  .DC@............
	defb 018h,024h,020h,024h,018h,003h,000h,085h,063h,092h,093h,092h,062h,003h,000h,085h	; 8375  .$ $....c...b...
	defb 08ah,04ah,084h,004h,004h,003h,000h,085h,01ch,010h,01ch,010h,010h,003h,000h,081h	; 8385  .J..............
	defb 0e4h,003h,044h,081h,0e7h,003h,000h,085h,01ch,010h,01ch,010h,09ch,003h,000h,085h	; 8395  ..D.............
	defb 007h,004h,007h,004h,004h,003h,000h,085h,039h,0a4h,038h,028h,025h,003h,000h,085h	; 83a5  ........9.8(%...
	defb 0d2h,09ah,09eh,096h,0d2h,003h,000h,081h,070h,004h,020h,003h,000h,085h,084h,08ah	; 83b5  ........p. .....
	defb 08eh,08ah,0eah,003h,000h,085h,0a4h,0aah,04ah,04ah,044h,003h,000h,081h,0aeh,003h	; 83c5  ........JJD.....
	defb 0a4h,081h,044h,01dh,000h,006h,003h,008h,0fbh,081h,0f8h,007h,0fbh,006h,00fh,081h	; 83d5  ..D.............
	defb 0f0h,006h,000h,013h,07fh,007h,0f0h,082h,00fh,000h,00fh,07fh,008h,003h,002h,000h	; 83e5  ................
	defb 006h,0c0h,008h,0dfh,081h,01fh,007h,0dfh,006h,0f0h,081h,00fh,006h,000h,013h,0feh	; 83f5  ................
	defb 007h,00fh,082h,0f0h,000h,00fh,0feh,008h,0c0h,020h,000h,097h,03ch,07eh,008h,012h	; 8405  ......... ..<~..
	defb 026h,00eh,09dh,0c3h,000h,006h,006h,007h,007h,006h,006h,000h,030h,060h,0c1h,09bh	; 8415  &...........0`..
	defb 09bh,0fbh,071h,003h,000h,085h,0cdh,06fh,06ch,06ch,0cch,003h,000h,085h,08eh,0d3h	; 8425  ..q....oll......
	defb 0cfh,0dbh,0dfh,003h,000h,082h,06dh,07fh,003h,066h,085h,000h,00ch,00ch,080h,0ech	; 8435  ......m..f......
	defb 003h,06ch,003h,000h,081h,07dh,003h,010h,081h,011h,003h,000h,085h,0c9h,08fh,089h	; 8445  .l...}..........
	defb 089h,0c9h,003h,000h,096h,03ch,020h,038h,020h,03ch,000h,063h,063h,06bh,07fh,07fh	; 8455  .....< 8 <.cck..
	defb 036h,022h,000h,01ch,036h,063h,063h,07fh,063h,063h,000h,003h,063h,08fh,077h,03eh	; 8465  6"..6cc.cc..c.w>
	defb 01ch,008h,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07ch,066h,003h,063h,084h	; 8475  ....``~``..|f.c.
	defb 066h,07ch,000h,03fh,005h,00ch,083h,03fh,000h,03fh,006h,00ch,082h,000h,0e0h,003h	; 8485  f|.?...?.?......
	defb 000h,081h,0e0h,005h,000h,003h,011h,002h,001h,003h,000h,003h,011h,004h,000h,085h	; 8495  ................
	defb 048h,079h,049h,049h,048h,003h,000h,081h,0c7h,003h,024h,081h,0c7h,003h,000h,087h	; 84a5  HyIIH.....$.....
	defb 01eh,090h,09ch,090h,01eh,000h,000h,00fh,0f3h,081h,0f8h,008h,0f3h,002h,000h,08eh	; 84b5  ................
	defb 003h,007h,00fh,01fh,03fh,07fh,07fh,03fh,01fh,00fh,007h,003h,000h,0feh,00fh,0cfh	; 84c5  ....?..?........
	defb 081h,01fh,008h,0cfh,002h,000h,08eh,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0feh,0fch,0f8h	; 84d5  ................
	defb 0f0h,0e0h,0c0h,000h,07fh,000h	; 84e5

; ----------------------------------------------------------------------
; DATOS marco_colores_1: flujo RLE de 0x4327 hacia 0x0008
;   0x84eb..0x8531  (70 bytes)
DATA_marco_colores_1:
	defb 008h,044h,008h,055h,008h,0eeh,083h,0ffh,0eeh,011h,005h,0cch,081h,0ffh,007h,0eeh	; 84eb  .D.U............
	defb 003h,044h,081h,0ffh,006h,0eeh,082h,066h,0eeh,008h,011h,083h,0ffh,0eeh,066h,004h	; 84fb  .D.....f......f.
	defb 0eeh,002h,044h,084h,011h,0ffh,0eeh,0ffh,003h,0eeh,088h,0ffh,011h,0ffh,0eeh,044h	; 850b  ..D............D
	defb 044h,011h,0ffh,004h,0eeh,007h,055h,082h,077h,055h,00bh,044h,081h,011h,003h,055h	; 851b  D.....U.wU.D...U
	defb 006h,044h,082h,055h,011h,000h	; 852b

; ----------------------------------------------------------------------
; DATOS marco_colores_2: flujo RLE de 0x4327 hacia 0x00D8
;   0x8531..0x8552  (33 bytes)
DATA_marco_colores_2:
	defb 003h,044h,089h,0ffh,077h,044h,011h,055h,044h,044h,077h,055h,005h,011h,003h,044h	; 8531  .D..wD.UDDwU...D
	defb 084h,011h,044h,011h,044h,004h,055h,086h,011h,055h,011h,055h,0ffh,0ffh,006h,0eeh	; 8541  ..D.D.U..U.U....
	defb 000h	; 8551

; ----------------------------------------------------------------------
; DATOS marco_colores_3: flujo RLE de 0x4327 hacia 0x01D8
;   0x8552..0x874d  (507 bytes)
DATA_marco_colores_3:
	defb 088h,0ffh,0eeh,011h,0cch,0cch,022h,011h,011h,007h,0eeh,081h,011h,00dh,0cch,081h	; 8552  ......".........
	defb 022h,003h,011h,081h,022h,006h,0cch,081h,000h,007h,0f0h,081h,000h,007h,0f0h,081h	; 8562  "..."...........
	defb 000h,007h,0f0h,081h,000h,007h,0f0h,081h,000h,007h,0f0h,081h,000h,007h,0f0h,081h	; 8572  ................
	defb 000h,007h,0f0h,081h,000h,007h,0f0h,081h,000h,007h,0f0h,081h,000h,007h,0f0h,008h	; 8582  ................
	defb 051h,081h,011h,00dh,044h,002h,055h,007h,044h,083h,011h,055h,055h,006h,044h,0a0h	; 8592  Q...D.U.D..UU.D.
	defb 0ffh,0eeh,011h,0cch,0ffh,0ffh,0e1h,0e1h,0ffh,0eeh,011h,0cch,0ffh,0ffh,011h,011h	; 85a2  ................
	defb 0ffh,0eeh,011h,0cch,0ffh,0ffh,0e1h,0e1h,0ffh,0eeh,011h,0cch,0ffh,0ffh,0eeh,0eeh	; 85b2  ................
	defb 006h,011h,082h,0ffh,0eeh,007h,011h,081h,0ffh,008h,051h,005h,091h,083h,011h,0ffh	; 85c2  ..........Q.....
	defb 0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h	; 85d2  ................
	defb 011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h	; 85e2  ................
	defb 091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh	; 85f2  ................
	defb 0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h	; 8602  ................
	defb 011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h	; 8612  ................
	defb 091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh	; 8622  ................
	defb 0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h	; 8632  ................
	defb 011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h	; 8642  ................
	defb 091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh	; 8652  ................
	defb 0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,083h,011h,0ffh,0eeh,005h,091h,08bh	; 8662  ................
	defb 011h,0ffh,0eeh,0ffh,0eeh,011h,0cch,0ffh,0ffh,0eeh,0eeh,010h,000h,083h,0ffh,0eeh	; 8672  ................
	defb 0e1h,005h,0ech,008h,0e1h,081h,0feh,00dh,0e1h,087h,0feh,0eeh,0eeh,0ffh,0ffh,0eeh	; 8682  ................
	defb 0eeh,003h,0e1h,081h,0f1h,016h,0e1h,082h,0feh,011h,00fh,041h,081h,0f1h,007h,0e4h	; 8692  ...........A....
	defb 083h,0ffh,0eeh,0e1h,005h,0ech,008h,0e1h,081h,0feh,00dh,0e1h,087h,0feh,0eeh,0eeh	; 86a2  ................
	defb 0ffh,0ffh,0eeh,0eeh,003h,0e1h,081h,0f1h,016h,0e1h,082h,0feh,011h,00fh,041h,081h	; 86b2  ..............A.
	defb 0f1h,007h,0e4h,008h,000h,010h,011h,081h,055h,007h,011h,002h,054h,002h,075h,004h	; 86c2  ........U...T.u.
	defb 041h,081h,044h,006h,0f4h,081h,011h,007h,0f4h,083h,011h,044h,044h,005h,0f4h,083h	; 86d2  A.D........DD...
	defb 011h,044h,044h,005h,0f4h,083h,011h,044h,044h,005h,0f4h,081h,011h,007h,0f4h,083h	; 86e2  .DD....DD.......
	defb 011h,044h,044h,005h,0f4h,003h,044h,005h,0f4h,003h,044h,005h,0f4h,081h,044h,007h	; 86f2  .DD...D...D...D.
	defb 031h,081h,0ffh,007h,031h,081h,0ffh,007h,031h,081h,0ffh,007h,031h,081h,0ffh,007h	; 8702  1...1...1...1...
	defb 031h,081h,0ffh,007h,031h,081h,0ffh,007h,031h,082h,0ffh,0e5h,003h,055h,081h,0e5h	; 8712  1...1...1....U..
	defb 005h,055h,005h,0e4h,083h,044h,055h,055h,003h,0e4h,004h,044h,005h,0f4h,003h,044h	; 8722  .U...DUU...D...D
	defb 005h,0f4h,003h,044h,005h,0f4h,002h,044h,018h,041h,002h,055h,00ch,054h,082h,055h	; 8732  ...D...D.A.U.T.U
	defb 054h,018h,041h,002h,055h,00ch,054h,082h,055h,054h,000h	; 8742  T.A.U.T.UT.

; ----------------------------------------------------------------------
; DATOS wave_edit_1: flujo RLE de 0x4352 (WAVE EDIT, 0xB02A)
;   0x874d..0x8799  (76 bytes)
DATA_wave_edit_1:
	defb 000h,02ah,002h,000h,085h,0e1h,092h,0e3h,0a2h,092h,003h,000h,085h,089h,04dh,0cfh	; 874d  .*............M.
	defb 04bh,049h,003h,000h,085h,018h,020h,02ch,024h,018h,003h,000h,087h,0e0h,080h,0e0h	; 875d  KI.... ,$.......
	defb 080h,0e0h,000h,0fch,003h,000h,081h,0e0h,003h,000h,081h,0e0h,003h,000h,081h,0e0h	; 876d  ................
	defb 003h,000h,008h,0fbh,008h,0feh,008h,0cfh,008h,0dfh,008h,07fh,008h,0f3h,004h,000h	; 877d  ................
	defb 081h,07ch,005h,000h,002h,010h,084h,07ch,010h,010h,000h,000h	; 878d  .|.....|....

; ----------------------------------------------------------------------
; DATOS wave_edit_2: flujo RLE de 0x4352 (0xB030)
;   0x8799..0x87a0  (7 bytes)
DATA_wave_edit_2:
	defb 008h,008h,008h,044h,008h,055h,000h	; 8799

; ----------------------------------------------------------------------
; DATOS wave_edit_3: flujo RLE de 0x4352 (0xB036)
;   0x87a0..0x87db  (59 bytes)
DATA_wave_edit_3:
	defb 000h,00ah,002h,044h,005h,0f4h,003h,044h,005h,0f4h,003h,044h,005h,0f4h,003h,044h	; 87a0  ...D...D...D...D
	defb 005h,0f4h,082h,044h,0e5h,003h,055h,081h,0e5h,003h,055h,081h,0e5h,003h,055h,081h	; 87b0  ...D..U...U...U.
	defb 0e5h,003h,055h,008h,0e1h,010h,041h,008h,0e1h,010h,041h,081h,055h,003h,000h,081h	; 87c0  ..U...A...A.U...
	defb 0e0h,003h,000h,082h,055h,000h,005h,0e0h,081h,000h,000h	; 87d0  ....U......

; ----------------------------------------------------------------------
; DATOS cabecera_nombres: flujo RLE de 0x4352 hacia 0x3800: la franja de
;   arriba de las pantallas de edicion
;   0x87db..0x8815  (58 bytes)
DATA_cabecera_nombres:
	defb 000h,038h,081h,080h,006h,004h,081h,04fh,010h,050h,081h,051h,006h,004h,082h,075h	; 87db  .8.....O.P.Q...u
	defb 082h,006h,005h,092h,07ch,099h,054h,09ah,054h,09bh,054h,09ch,054h,054h,09ch,054h	; 87eb  ....|.T.T.T.TT.T
	defb 09dh,054h,09eh,054h,09fh,087h,006h,005h,083h,077h,081h,07dh,008h,04bh,081h,07fh	; 87fb  .T.T.....w.}.K..
	defb 00ah,000h,081h,08ah,008h,04bh,082h,088h,076h,000h	; 880b  .....K..v.

; ----------------------------------------------------------------------
; DATOS wave_edit_nombres: flujo RLE de 0x4352 hacia 0x3860 (0xB052)
;   0x8815..0x8a41  (556 bytes)
DATA_wave_edit_nombres:
	defb 060h,038h,083h,081h,07eh,08fh,003h,001h,082h,0a6h,0aeh,007h,0a2h,081h,0a1h,008h	; 8815  `8..~...........
	defb 0a2h,082h,0a9h,0abh,003h,001h,085h,08fh,089h,076h,081h,07eh,004h,001h,094h,0a6h	; 8825  .........v.~....
	defb 0a0h,0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch,0cdh,0ceh	; 8835  ................
	defb 0cfh,002h,0abh,004h,001h,0a4h,089h,076h,081h,07eh,096h,097h,098h,001h,0a6h,0a0h	; 8845  .......v.~......
	defb 0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch,0ddh,0deh,0dfh	; 8855  ................
	defb 002h,0abh,0a3h,0a4h,0a5h,001h,089h,076h,081h,07eh,003h,000h,095h,001h,0a6h,0a0h	; 8865  .......v.~......
	defb 0e0h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h,0eah,0ebh,0ech,0edh,0eeh,0efh	; 8875  ................
	defb 002h,0abh,003h,000h,085h,001h,089h,076h,081h,07eh,004h,001h,094h,0a6h,0a0h,0f0h	; 8885  .......v.~......
	defb 0f1h,0f2h,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh,002h	; 8895  ................
	defb 0abh,004h,001h,084h,089h,076h,049h,04ah,004h,001h,094h,04bh,045h,080h,081h,082h	; 88a5  .....vIJ...KE...
	defb 083h,084h,085h,086h,087h,088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,002h,048h,004h	; 88b5  ..............H.
	defb 001h,084h,047h,046h,049h,04ah,004h,001h,094h,04bh,045h,090h,091h,092h,093h,094h	; 88c5  ..GFIJ...KE.....
	defb 095h,096h,097h,098h,099h,09ah,09bh,09ch,09dh,09eh,09fh,002h,048h,004h,001h,09ch	; 88d5  ............H...
	defb 047h,046h,049h,04ah,040h,041h,042h,043h,04bh,045h,0a0h,0a1h,0a2h,0a3h,0a4h,0a5h	; 88e5  GFIJ@ABCKE......
	defb 0a6h,0a7h,0a8h,0a9h,0aah,0abh,0ach,0adh,0aeh,0afh,002h,048h,004h,001h,085h,047h	; 88f5  ...........H...G
	defb 046h,049h,04ah,08eh,003h,000h,094h,04bh,045h,0b0h,0b1h,0b2h,0b3h,0b4h,0b5h,0b6h	; 8905  FIJ....KE.......
	defb 0b7h,0b8h,0b9h,0bah,0bbh,0bch,0bdh,0beh,0bfh,002h,048h,004h,001h,084h,047h,046h	; 8915  ..........H...GF
	defb 049h,04ah,004h,001h,094h,04bh,044h,0c0h,0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h	; 8925  IJ...KD.........
	defb 0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh,002h,048h,004h,001h,084h,047h,046h,049h,04ah	; 8935  ........H...GFIJ
	defb 004h,001h,094h,04bh,045h,0d0h,0d1h,0d2h,0d3h,0d4h,0d5h,0d6h,0d7h,0d8h,0d9h,0dah	; 8945  ...KE...........
	defb 0dbh,0dch,0ddh,0deh,0dfh,002h,048h,004h,001h,084h,047h,046h,049h,04ah,004h,001h	; 8955  ......H...GFIJ..
	defb 094h,04bh,045h,0e0h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h,0eah,0ebh,0ech	; 8965  .KE.............
	defb 0edh,0eeh,0efh,002h,048h,004h,001h,084h,047h,046h,049h,04ah,004h,001h,094h,04bh	; 8975  ....H...GFIJ...K
	defb 045h,0f0h,0f1h,0f2h,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh	; 8985  E...............
	defb 0ffh,002h,048h,004h,001h,084h,047h,046h,081h,07eh,004h,001h,094h,0a6h,0a0h,0c0h	; 8995  ..H...GF.~......
	defb 0c1h,0c2h,0c3h,0c4h,0c5h,0c6h,0c7h,0c8h,0c9h,0cah,0cbh,0cch,0cdh,0ceh,0cfh,002h	; 89a5  ................
	defb 0abh,004h,001h,084h,089h,076h,081h,07eh,004h,001h,094h,0a6h,0a0h,0d0h,0d1h,0d2h	; 89b5  .....v.~........
	defb 0d3h,0d4h,0d5h,0d6h,0d7h,0d8h,0d9h,0dah,0dbh,0dch,0ddh,0deh,0dfh,002h,0abh,004h	; 89c5  ................
	defb 001h,084h,089h,076h,081h,07eh,004h,001h,094h,0a6h,0a0h,0e0h,0e1h,0e2h,0e3h,0e4h	; 89d5  ...v.~..........
	defb 0e5h,0e6h,0e7h,0e8h,0e9h,0eah,0ebh,0ech,0edh,0eeh,0efh,002h,0abh,004h,001h,084h	; 89e5  ................
	defb 089h,076h,081h,07eh,004h,001h,094h,0a6h,0a0h,0f0h,0f1h,0f2h,0f3h,0f4h,0f5h,0f6h	; 89f5  .v.~............
	defb 0f7h,0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh,002h,0abh,004h,001h,085h,089h,076h	; 8a05  ...............v
	defb 081h,07eh,08fh,003h,001h,082h,0a6h,0afh,010h,04ch,082h,0aah,0abh,003h,001h,085h	; 8a15  .~.......L......
	defb 08fh,089h,076h,081h,07eh,004h,001h,081h,0a7h,006h,04dh,086h,090h,091h,092h,093h	; 8a25  ..v.~.....M.....
	defb 094h,095h,006h,04dh,081h,0ach,004h,001h,082h,089h,076h,000h	; 8a35  ...M......v.

; ----------------------------------------------------------------------
; DATOS menu_de_abajo_a: 0x40 bytes de la tabla de nombres que 0x48C4 copia a
;   0x3AC0: las dos filas de abajo, TONE-E WAVE-E SYN PLAY FILE
;   0x8a41..0x8a81  (64 bytes)
DATA_menu_de_abajo_a:
	defb 081h,04fh,050h,050h,050h,051h,052h,04fh,050h,050h,050h,051h,052h,04fh,050h,050h	; 8a41  .OPPPQROPPPQROPP
	defb 050h,050h,051h,052h,04fh,050h,050h,050h,051h,052h,04fh,050h,050h,050h,051h,076h	; 8a51  PPQROPPPQROPPPQv
	defb 081h,083h,056h,057h,058h,078h,003h,083h,059h,05ah,05bh,078h,003h,083h,053h,05ch	; 8a61  ..VWXx..YZ[x..S\
	defb 05dh,05eh,078h,003h,083h,05fh,060h,061h,078h,003h,083h,068h,069h,06ah,078h,076h	; 8a71  ]^x.._`ax..hijxv

; ----------------------------------------------------------------------
; DATOS menu_de_abajo_b: la otra variante, por (0xD8F0)
;   0x8a81..0x8ac1  (64 bytes)
DATA_menu_de_abajo_b:
	defb 081h,04fh,050h,050h,050h,051h,052h,04fh,050h,050h,050h,051h,052h,04fh,050h,050h	; 8a81  .OPPPQROPPPQROPP
	defb 050h,050h,051h,052h,04fh,050h,050h,050h,051h,052h,072h,072h,072h,072h,072h,076h	; 8a91  PPQROPPPQRrrrrrv
	defb 081h,083h,065h,066h,067h,078h,003h,083h,062h,063h,064h,078h,003h,083h,06bh,06ch	; 8aa1  ..efgx..bcdx..kl
	defb 06dh,06eh,078h,003h,083h,06fh,070h,071h,078h,003h,003h,003h,003h,003h,003h,076h	; 8ab1  mnx..opqx......v

; ----------------------------------------------------------------------
; DATOS tone_edit_patrones: flujo RLE de 0x4327 hacia 0x2458
;   0x8ac1..0x8db6  (757 bytes)
DATA_tone_edit_patrones:
	defb 002h,000h,085h,011h,077h,011h,077h,011h,008h,000h,083h,0aah,000h,000h,004h,03fh	; 8ac1  ....w.w........?
	defb 084h,000h,0aah,000h,000h,004h,00fh,084h,000h,0aah,000h,000h,004h,003h,082h,000h	; 8ad1  ................
	defb 0aah,007h,000h,081h,0aah,003h,000h,002h,07eh,008h,000h,002h,07eh,002h,000h,002h	; 8ae1  ........~...~...
	defb 07eh,008h,000h,002h,018h,004h,000h,082h,018h,03ch,004h,066h,08fh,03ch,000h,000h	; 8af1  ~........<.f.<..
	defb 03eh,030h,030h,03ch,030h,030h,000h,000h,060h,060h,040h,080h,004h,000h,087h,0f1h	; 8b01  >00<00..``@.....
	defb 0f7h,0f1h,0f7h,0f7h,000h,03fh,006h,00ch,082h,000h,03eh,005h,063h,094h,03eh,000h	; 8b11  .....?....>.c.>.
	defb 063h,073h,07bh,07fh,06fh,067h,063h,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h	; 8b21  cs{.ogc..``~``..
	defb 07ch,066h,003h,063h,084h,066h,07ch,000h,03fh,005h,00ch,083h,03fh,000h,03fh,006h	; 8b31  |f.c.f|.?...?.?.
	defb 00ch,003h,000h,081h,01fh,004h,0bfh,003h,000h,003h,0f6h,082h,0f0h,0f6h,003h,000h	; 8b41  ................
	defb 085h,0dah,0aah,0aah,08dh,0adh,003h,000h,089h,08fh,0bfh,08fh,0bfh,08fh,000h,000h	; 8b51  ................
	defb 083h,099h,003h,09ch,085h,099h,083h,000h,0e1h,0cch,003h,09fh,089h,0cch,0e1h,000h	; 8b61  ................
	defb 000h,0dah,0aah,0aah,08dh,0adh,003h,000h,08ah,08fh,0bfh,08fh,0bfh,08fh,000h,000h	; 8b71  ................
	defb 0dch,0ebh,0f7h,004h,000h,082h,0ddh,03dh,004h,0fdh,081h,003h,005h,000h,083h,0f7h	; 8b81  .......=........
	defb 0ebh,0dch,003h,000h,081h,003h,003h,0fdh,085h,03dh,0ddh,000h,000h,080h,003h,0bfh	; 8b91  .........=......
	defb 004h,000h,081h,001h,003h,0fdh,004h,000h,085h,0e7h,0dbh,0c3h,0dbh,0dbh,003h,000h	; 8ba1  ................
	defb 081h,0c7h,003h,0dbh,081h,0c7h,003h,000h,085h,0e7h,0dfh,0e7h,0fbh,0c7h,003h,000h	; 8bb1  ................
	defb 086h,0c7h,0dbh,0c7h,0d7h,0dbh,000h,005h,0feh,003h,000h,085h,039h,0d6h,0d7h,0d6h	; 8bc1  ............9...
	defb 039h,003h,000h,085h,019h,077h,014h,076h,019h,005h,000h,004h,0f7h,081h,0f1h,003h	; 8bd1  9....w.v........
	defb 000h,085h,019h,076h,016h,076h,079h,003h,000h,085h,0b8h,0bbh,0b8h,0bbh,08bh,003h	; 8be1  ...v.vy.........
	defb 000h,081h,0cfh,003h,0b7h,084h,0cfh,000h,000h,0c1h,005h,09ch,002h,0c1h,005h,09ch	; 8bf1  ................
	defb 082h,0c1h,000h,008h,0fdh,002h,000h,081h,0feh,00bh,0fdh,091h,0feh,000h,000h,0f9h	; 8c01  ................
	defb 0f9h,0f8h,0f8h,0f9h,0f9h,000h,0cfh,09fh,03eh,064h,064h,004h,08eh,003h,000h,085h	; 8c11  ........>dd.....
	defb 032h,090h,093h,093h,033h,003h,000h,085h,071h,02ch,030h,024h,020h,003h,000h,082h	; 8c21  2...3...q,0$ ...
	defb 092h,080h,003h,099h,085h,000h,0f3h,0f3h,07fh,013h,003h,093h,01bh,000h,002h,0dfh	; 8c31  ................
	defb 084h,01fh,0dfh,0dfh,000h,008h,0f7h,008h,0efh,003h,000h,005h,0feh,006h,000h,002h	; 8c41  ................
	defb 0feh,008h,0efh,008h,0f7h,003h,000h,005h,07fh,006h,000h,002h,07fh,081h,0cfh,003h	; 8c51  ................
	defb 0b7h,081h,0cfh,003h,000h,085h,08fh,0bfh,08fh,0bfh,0bfh,003h,000h,085h,0cfh,0b7h	; 8c61  ................
	defb 087h,0b7h,0b7h,006h,000h,081h,09ah,003h,0aah,08eh,09dh,000h,000h,003h,09dh,0adh	; 8c71  ................
	defb 09dh,0adh,0adh,098h,0abh,0a8h,0abh,098h,003h,000h,087h,0ddh,0adh,0bdh,0adh,0ddh	; 8c81  ................
	defb 0fdh,003h,005h,000h,002h,0dah,09ah,0c2h,0dah,000h,000h,001h,0feh,062h,0aeh,062h	; 8c91  .............b.b
	defb 0eeh,0dah,000h,0c6h,0dah,0c6h,0dah,0c6h,000h,0eeh,0feh,062h,0aeh,062h,0eeh,0eeh	; 8ca1  ...........b.b..
	defb 0feh,004h,0deh,081h,0c2h,003h,000h,087h,062h,0aeh,062h,0eeh,0eeh,0feh,001h,003h	; 8cb1  ........b.b.....
	defb 000h,085h,08bh,0b9h,088h,0bah,08bh,003h,000h,003h,057h,002h,06fh,09ch,000h,07fh	; 8cc1  ..........W.o...
	defb 07fh,062h,06eh,062h,06eh,062h,07fh,000h,000h,0d5h,055h,015h,09bh,0dbh,000h,07fh	; 8cd1  .bnbnb....U.....
	defb 07fh,073h,06dh,06fh,06dh,073h,07fh,000h,000h,051h,003h,05bh,094h,0bbh,000h,07fh	; 8ce1  .smoms...Q.[....
	defb 07fh,063h,06dh,063h,06bh,06dh,07fh,000h,000h,018h,077h,019h,07eh,011h,000h,07fh	; 8cf1  .cmckm....w.~...
	defb 07fh,004h,06eh,089h,062h,07fh,000h,000h,033h,0edh,02dh,0edh,0f3h,003h,000h,085h	; 8d01  ..n.b...3.-.....
	defb 0f9h,0f7h,0f9h,0feh,0f1h,003h,000h,085h,0fah,0f6h,0eeh,0deh,0beh,003h,000h,081h	; 8d11  ................
	defb 0f1h,004h,0fbh,003h,000h,002h,0d7h,003h,0efh,003h,000h,092h,03fh,05fh,03fh,07fh	; 8d21  ............?_?.
	defb 07fh,000h,000h,0e3h,0c9h,09ch,09ch,080h,09ch,09ch,080h,09fh,09fh,081h,003h,09fh	; 8d31  ................
	defb 081h,000h,006h,09fh,083h,080h,000h,0f0h,005h,0f3h,084h,0f0h,000h,07ch,039h,003h	; 8d41  .............|9.
	defb 093h,08fh,039h,07ch,000h,030h,093h,0f3h,0f0h,0f3h,093h,033h,000h,01fh,000h,000h	; 8d51  ..9|.0.....3....
	defb 03fh,004h,000h,094h,080h,09fh,09fh,081h,09fh,09fh,080h,000h,0e0h,0cfh,09fh,098h	; 8d61  ?...............
	defb 09ch,0cch,0e0h,000h,00ch,012h,021h,021h,008h,000h,002h,084h,087h,048h,030h,000h	; 8d71  ......!!.....H0.
	defb 040h,070h,04ch,043h,003h,040h,005h,000h,086h,0c0h,030h,00ch,000h,00eh,03fh,005h	; 8d81  @pLC.@....0...?.
	defb 021h,002h,000h,005h,008h,084h,0f8h,000h,000h,01eh,004h,012h,081h,013h,007h,000h	; 8d91  !...............
	defb 088h,0f8h,000h,000h,0a4h,0aah,0eah,0aah,0a4h,003h,000h,086h,0bbh,0a2h,0bbh,08ah	; 8da1  ................
	defb 0bbh,000h,008h,0c0h,000h	; 8db1

; ----------------------------------------------------------------------
; DATOS tone_edit_colores: flujo RLE de 0x4327 hacia 0x0458
;   0x8db6..0x8fcd  (535 bytes)
DATA_tone_edit_colores:
	defb 002h,0eeh,005h,0e1h,002h,0eeh,081h,011h,004h,077h,084h,011h,0e1h,0eeh,011h,004h	; 8db6  .........w......
	defb 076h,084h,011h,0e1h,0eeh,011h,004h,076h,084h,011h,0e1h,0eeh,011h,004h,076h,084h	; 8dc6  v......v......v.
	defb 011h,0e1h,0eeh,011h,004h,066h,082h,011h,0e1h,003h,011h,082h,031h,0c1h,003h,011h	; 8dd6  .....f......1...
	defb 002h,0eeh,093h,066h,0eeh,011h,031h,0c1h,011h,011h,031h,0c1h,011h,0ffh,0eeh,066h	; 8de6  ...f..1...1....f
	defb 0eeh,0eeh,011h,011h,071h,071h,003h,011h,082h,0eeh,010h,004h,070h,084h,071h,070h	; 8df6  ....qq......p.qp
	defb 0eeh,011h,006h,071h,082h,0eeh,011h,004h,071h,002h,011h,002h,0eeh,005h,0e1h,081h	; 8e06  ...q....q.......
	defb 0eeh,007h,071h,081h,0ffh,007h,071h,081h,0ffh,007h,071h,081h,0ffh,007h,071h,081h	; 8e16  ..q...q...q...q.
	defb 0ffh,007h,071h,081h,0ffh,007h,071h,081h,0ffh,007h,071h,083h,0ffh,0eeh,0eeh,005h	; 8e26  ..q...q...q.....
	defb 0e1h,003h,0eeh,005h,0e1h,083h,0eeh,0ffh,0eeh,005h,0e1h,083h,0eeh,0ffh,0eeh,005h	; 8e36  ................
	defb 0e1h,082h,0eeh,0ffh,007h,0e4h,081h,0ffh,007h,0e4h,002h,0eeh,005h,0e1h,003h,0eeh	; 8e46  ................
	defb 005h,0e1h,002h,0eeh,003h,0e6h,002h,0eeh,082h,066h,0eeh,007h,0e6h,003h,0eeh,082h	; 8e56  .........f......
	defb 066h,0eeh,003h,0e6h,003h,0eeh,006h,0e6h,002h,0eeh,004h,0e6h,004h,0eeh,004h,0e6h	; 8e66  f...............
	defb 004h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h	; 8e76  ................
	defb 081h,0eeh,005h,0e6h,003h,0eeh,005h,0e6h,003h,0eeh,005h,0e6h,005h,0eeh,005h,0e1h	; 8e86  ................
	defb 003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,082h,0eeh,0ffh,00eh	; 8e96  ................
	defb 0e4h,081h,0eeh,008h,0e6h,002h,0eeh,00dh,0e6h,002h,0eeh,006h,0e8h,081h,0eeh,007h	; 8ea6  ................
	defb 0e8h,003h,0eeh,005h,0e8h,003h,0eeh,005h,0e8h,003h,0eeh,005h,0e8h,081h,0eeh,007h	; 8eb6  ................
	defb 0e8h,08bh,0eeh,0ffh,0eeh,0eeh,044h,044h,011h,0ffh,0eeh,0ffh,011h,003h,044h,084h	; 8ec6  ......DD......D.
	defb 011h,0ffh,0eeh,011h,006h,044h,002h,0ffh,081h,0eeh,005h,0e1h,081h,0eeh,010h,0e1h	; 8ed6  .....D..........
	defb 002h,044h,082h,011h,0f1h,004h,0e1h,082h,0ffh,011h,003h,044h,082h,011h,0f1h,011h	; 8ee6  .D.........D....
	defb 0e1h,002h,044h,082h,011h,0f1h,004h,0e1h,082h,0ffh,011h,003h,044h,083h,011h,0f1h	; 8ef6  ..D.........D...
	defb 0e1h,005h,0e6h,003h,0eeh,005h,0e6h,003h,0eeh,005h,0e6h,005h,0eeh,081h,066h,005h	; 8f06  ..............f.
	defb 0e6h,002h,0eeh,00bh,0e6h,083h,0eeh,066h,0eeh,007h,0e6h,003h,0eeh,082h,066h,0eeh	; 8f16  .......f......f.
	defb 004h,0e6h,002h,0eeh,007h,0e6h,081h,0eeh,005h,0e6h,081h,0eeh,00dh,0e6h,083h,0eeh	; 8f26  ................
	defb 066h,0eeh,007h,0e6h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,081h,0eeh,008h,0e1h	; 8f36  f...............
	defb 002h,0eeh,005h,0e1h,081h,0eeh,008h,0e1h,002h,0eeh,005h,0e1h,081h,0eeh,008h,0e1h	; 8f46  ................
	defb 002h,0eeh,005h,0e1h,083h,0eeh,0e0h,0e0h,005h,0e1h,083h,0e0h,0eeh,0eeh,005h,0e1h	; 8f56  ................
	defb 003h,0eeh,005h,0e1h,083h,0eeh,0ffh,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh	; 8f66  ................
	defb 005h,0e1h,003h,0eeh,005h,0e0h,082h,0eeh,0ffh,00eh,0e4h,081h,0eeh,007h,0e4h,081h	; 8f76  ................
	defb 0eeh,007h,0e4h,081h,0eeh,007h,0e4h,081h,0eeh,007h,0e4h,085h,0eeh,0e4h,0eeh,0eeh	; 8f86  ................
	defb 0e4h,004h,0eeh,007h,0e4h,081h,0eeh,007h,0e4h,081h,0eeh,004h,030h,008h,000h,004h	; 8f96  ............0...
	defb 030h,081h,000h,007h,030h,005h,000h,003h,030h,082h,000h,010h,006h,030h,002h,000h	; 8fa6  0...0...0....0..
	defb 006h,030h,002h,000h,006h,030h,007h,000h,083h,030h,000h,000h,005h,030h,003h,000h	; 8fb6  .0...0...0...0..
	defb 005h,030h,081h,000h,008h,0e0h,000h	; 8fc6

; ----------------------------------------------------------------------
; DATOS tone_edit_extra: flujo RLE de 0x4352 hacia 0x2900
;   0x8fcd..0x9087  (186 bytes)
DATA_tone_edit_extra:
	defb 000h,029h,081h,000h,003h,040h,088h,043h,04ch,070h,040h,000h,00ch,030h,0c0h,004h	; 8fcd  .)...@.CLp@..0..
	defb 000h,002h,080h,002h,090h,0a6h,0a9h,04ah,00ah,004h,002h,002h,012h,012h,02ah,0a4h	; 8fdd  .......J......*.
	defb 0a0h,040h,001h,041h,041h,045h,055h,055h,036h,008h,000h,004h,004h,044h,054h,054h	; 8fed  .@.AAEUU6....DTT
	defb 0d8h,020h,060h,090h,008h,004h,004h,005h,005h,002h,040h,040h,003h,0a4h,002h,014h	; 8ffd  . `.......@@....
	defb 082h,008h,080h,003h,040h,085h,024h,02ah,012h,001h,002h,003h,004h,099h,048h,0a8h	; 900d  ....@.$*......H.
	defb 090h,000h,028h,054h,044h,085h,083h,001h,001h,000h,001h,005h,006h,014h,018h,050h	; 901d  ..(TD..........P
	defb 060h,0c0h,040h,0a0h,0a4h,09ah,083h,003h,080h,003h,000h,08dh,080h,060h,054h,00bh	; 902d  `.@..........`T.
	defb 000h,040h,0a4h,0aah,0aah,092h,082h,081h,080h,003h,000h,09dh,040h,0a0h,0a8h,015h	; 903d  .@..........@...
	defb 002h,080h,0c0h,0c0h,0a1h,092h,08ch,080h,080h,001h,061h,091h,009h,009h,005h,005h	; 904d  ..........a.....
	defb 002h,030h,048h,048h,08ah,086h,002h,002h,001h,003h,000h,08ch,040h,0a0h,0a5h,096h	; 905d  .0HH........@...
	defb 008h,000h,000h,04ch,0aah,0ach,0a8h,048h,003h,000h,081h,0e9h,003h,04ah,081h,049h	; 906d  ...L...H.....J.I
	defb 003h,000h,086h,028h,0b8h,0b8h,0a8h,028h,000h,000h	; 907d  ...(...(..

; ----------------------------------------------------------------------
; DATOS tone_edit_nombres: flujo RLE de 0x4352 hacia 0x3860
;   0x9087..0x925a  (467 bytes)
DATA_tone_edit_nombres:
	defb 060h,038h,081h,082h,003h,005h,083h,0a4h,0a5h,0b9h,004h,005h,081h,0cfh,008h,0c5h	; 9087  `8..............
	defb 081h,0cbh,004h,005h,083h,0a4h,0a5h,0ech,003h,005h,082h,077h,081h,00ah,003h,08ch	; 9097  ...........w....
	defb 07bh,003h,0beh,0bfh,0c0h,0c1h,0c2h,0c3h,003h,086h,0b5h,0b6h,008h,003h,082h,076h	; 90a7  {..............v
	defb 081h,00ah,003h,081h,0ceh,008h,00bh,082h,0cah,003h,003h,000h,004h,08ch,002h,003h	; 90b7  ................
	defb 088h,076h,081h,098h,08bh,0a0h,000h,000h,097h,004h,003h,08bh,07bh,003h,003h,0efh	; 90c7  .v..........{...
	defb 0f0h,0f1h,0f2h,003h,003h,086h,009h,007h,0c4h,002h,009h,082h,076h,081h,003h,003h	; 90d7  ............v...
	defb 003h,005h,004h,003h,08ah,07bh,0bch,007h,0d7h,0d8h,0bch,007h,0aah,0abh,086h,004h	; 90e7  .....{..........
	defb 003h,083h,0eeh,0edh,0bah,003h,003h,088h,076h,081h,0a1h,0a6h,0a7h,000h,000h,0ffh	; 90f7  ........v.......
	defb 003h,000h,08eh,003h,07bh,0bbh,000h,0d9h,0dah,0bbh,000h,003h,0bbh,086h,098h,08bh	; 9107  ....{...........
	defb 0a0h,007h,003h,082h,076h,081h,003h,003h,084h,0bch,007h,0aah,0abh,003h,003h,08bh	; 9117  ....v...........
	defb 07bh,0bdh,093h,0dbh,0dch,0bdh,093h,0a8h,0a9h,086h,003h,004h,000h,083h,094h,000h	; 9127  {...............
	defb 000h,084h,097h,003h,076h,081h,003h,003h,084h,0bbh,000h,003h,0bbh,003h,003h,082h	; 9137  ....v...........
	defb 0e1h,0e2h,003h,000h,004h,08ch,084h,086h,0a1h,0a2h,0a3h,006h,005h,083h,003h,076h	; 9147  ...............v
	defb 081h,003h,003h,084h,0bdh,093h,0a8h,0a9h,003h,003h,082h,0e3h,0e4h,003h,000h,004h	; 9157  ................
	defb 08ch,085h,086h,003h,000h,000h,0ffh,003h,000h,003h,003h,084h,076h,081h,0b7h,0b8h	; 9167  ............v...
	defb 003h,000h,004h,08ch,083h,003h,0e5h,0e6h,003h,000h,004h,08ch,084h,086h,0e7h,0e8h	; 9177  ................
	defb 0c7h,004h,005h,003h,003h,084h,076h,081h,0ddh,0deh,003h,000h,004h,08ch,083h,003h	; 9187  ......v.........
	defb 0dfh,0e0h,003h,000h,004h,08ch,082h,086h,003h,003h,000h,004h,08ch,002h,003h,084h	; 9197  ................
	defb 076h,081h,003h,003h,007h,005h,083h,003h,07bh,003h,007h,005h,082h,086h,003h,007h	; 91a7  v.......{.......
	defb 005h,002h,003h,082h,076h,081h,01eh,00bh,0a3h,076h,081h,003h,0ach,0b2h,0b3h,0d0h	; 91b7  ....v....v......
	defb 0b4h,003h,0adh,003h,003h,0ach,0b2h,0b3h,0d1h,0b4h,003h,0adh,003h,003h,0ach,0b2h	; 91c7  ................
	defb 0b3h,0d2h,0b4h,003h,0adh,003h,0f3h,0f4h,003h,076h,081h,0aeh,003h,000h,004h,08ch	; 91d7  .........v......
	defb 082h,003h,0aeh,003h,000h,004h,08ch,082h,003h,0aeh,003h,000h,004h,08ch,004h,003h	; 91e7  ................
	defb 083h,076h,081h,0afh,003h,000h,004h,08ch,082h,003h,0afh,003h,000h,004h,08ch,082h	; 91f7  .v..............
	defb 003h,0afh,003h,000h,004h,08ch,087h,0bch,007h,0d3h,0d4h,076h,081h,0b0h,003h,000h	; 9207  ...........v....
	defb 004h,08ch,082h,003h,0b0h,003h,000h,004h,08ch,082h,003h,0b0h,003h,000h,004h,08ch	; 9217  ................
	defb 087h,0bbh,000h,003h,0bbh,076h,081h,0b1h,003h,000h,004h,08ch,082h,003h,0b1h,003h	; 9227  .....v..........
	defb 000h,004h,08ch,082h,003h,0b1h,003h,000h,004h,08ch,087h,0bdh,093h,0d5h,0d6h,076h	; 9237  ...............v
	defb 081h,003h,007h,005h,002h,003h,007h,005h,002h,003h,007h,005h,085h,0e9h,0eah,0ebh	; 9247  ................
	defb 003h,076h,000h	; 9257

; ----------------------------------------------------------------------
; DATOS teclado_patrones_1: flujo RLE de 0x4327 hacia 0x2080 (SYN y PLAY)
;   0x925a..0x92f4  (154 bytes)
DATA_teclado_patrones_1:
	defb 002h,000h,006h,07fh,002h,000h,081h,0feh,005h,0fch,005h,07fh,083h,040h,0bfh,000h	; 925a  .............@..
	defb 005h,0fch,084h,002h,000h,000h,001h,003h,002h,085h,0f9h,003h,0f5h,009h,000h,003h	; 926a  ................
	defb 080h,083h,07fh,000h,07fh,007h,000h,09ah,0d7h,010h,000h,000h,030h,038h,0abh,024h	; 927a  ............08.$
	defb 0b3h,038h,010h,018h,01ch,014h,0d2h,010h,0d7h,030h,000h,000h,008h,008h,0fbh,008h	; 928a  .8.......0......
	defb 0fbh,008h,031h,000h,094h,01fh,010h,010h,0d7h,010h,0d7h,010h,000h,0fch,084h,084h	; 929a  ..1.............
	defb 0b5h,084h,0b5h,08ch,0d5h,033h,075h,020h,0dfh,003h,000h,083h,09dh,088h,077h,005h	; 92aa  .....3u ......w.
	defb 000h,0a3h,0d3h,014h,0d2h,008h,0f7h,000h,001h,001h,0dfh,0a0h,0afh,0a0h,0dfh,080h	; 92ba  ................
	defb 080h,000h,0d7h,010h,0d7h,010h,0d7h,030h,070h,020h,0abh,024h,0abh,020h,06fh,0e0h	; 92ca  .......0p .$. o.
	defb 040h,000h,077h,020h,0dfh,005h,000h,085h,0ebh,018h,0bbh,010h,0efh,010h,000h,087h	; 92da  @.w ............
	defb 00bh,000h,00bh,000h,00bh,000h,00bh,004h,000h,000h	; 92ea  ..........

; ----------------------------------------------------------------------
; DATOS teclado_patrones_2: flujo RLE de 0x4327 hacia 0x2458
;   0x92f4..0x9559  (613 bytes)
DATA_teclado_patrones_2:
	defb 010h,000h,083h,01fh,03fh,038h,005h,037h,008h,0fbh,083h,0f0h,0f8h,018h,005h,0d8h	; 92f4  ....?8.7........
	defb 008h,0feh,002h,000h,002h,006h,002h,007h,002h,006h,088h,000h,030h,060h,0c1h,09bh	; 9304  ............0`..
	defb 09bh,0fbh,071h,003h,000h,085h,0cdh,06fh,06ch,06ch,0cch,003h,000h,085h,08eh,0d3h	; 9314  ..q....oll......
	defb 0cfh,0dbh,0cfh,003h,000h,082h,06dh,07fh,003h,066h,085h,000h,00ch,00ch,080h,0ech	; 9324  ......m..f......
	defb 003h,06ch,008h,07fh,008h,000h,085h,007h,0f7h,0f7h,037h,077h,00bh,0f7h,081h,0f8h	; 9334  .l........7w....
	defb 003h,000h,085h,0e0h,0c0h,080h,000h,007h,007h,000h,084h,038h,03fh,03fh,020h,005h	; 9344  ...........8?? .
	defb 000h,082h,07fh,03fh,005h,000h,088h,0feh,0fch,0f8h,0a8h,000h,0a8h,000h,0a8h,004h	; 9354  ...?............
	defb 0f8h,081h,0f9h,003h,0f8h,004h,058h,084h,0d8h,058h,018h,018h,007h,05eh,081h,01eh	; 9364  ......X..X...^..
	defb 008h,0f8h,004h,058h,084h,059h,058h,058h,018h,004h,05eh,084h,0deh,05eh,01eh,01eh	; 9374  ...X.YXX..^..^..
	defb 004h,0f8h,081h,0f9h,003h,0f8h,004h,058h,084h,0d9h,058h,018h,018h,004h,05eh,085h	; 9384  .......X..X...^.
	defb 0deh,05eh,01eh,01eh,000h,007h,0f8h,082h,000h,018h,006h,058h,082h,000h,01eh,006h	; 9394  .^.........X....
	defb 05eh,008h,0f8h,008h,058h,008h,05eh,082h,0feh,0fch,006h,0f8h,007h,0feh,081h,000h	; 93a4  ^...X.^.........
	defb 004h,0feh,082h,000h,0fch,006h,000h,084h,0c0h,080h,000h,000h,004h,0f8h,082h,004h	; 93b4  ................
	defb 002h,003h,000h,082h,07fh,03fh,005h,000h,082h,0feh,0fch,006h,0f8h,004h,000h,084h	; 93c4  .....?..........
	defb 0c0h,080h,000h,000h,004h,0f8h,082h,004h,002h,033h,000h,082h,0feh,004h,007h,0f4h	; 93d4  .........3......
	defb 084h,004h,0fch,002h,001h,003h,000h,0ffh,07fh,03fh,0eah,0efh,0e7h,0ebh,0efh,000h	; 93e4  .........?......
	defb 07fh,03fh,0efh,0efh,0edh,0edh,0e3h,000h,07fh,03fh,0e1h,000h,0e1h,000h,0e1h,000h	; 93f4  .?.......?......
	defb 07fh,03fh,087h,0f0h,0eeh,0ddh,0fdh,000h,07fh,03fh,000h,0e9h,0edh,0fdh,0e3h,000h	; 9404  .?.......?......
	defb 07fh,03fh,0c3h,000h,0c3h,0fbh,0c7h,000h,07fh,03fh,0cdh,0fdh,0cdh,0fbh,0c7h,000h	; 9414  .?.......?......
	defb 07fh,03fh,0eah,0efh,0e7h,0ebh,0efh,000h,07fh,03fh,0efh,0efh,0edh,0edh,0e3h,000h	; 9424  .?.......?......
	defb 07fh,03fh,0e1h,000h,0e1h,000h,0e1h,000h,07fh,03fh,087h,0f0h,0eeh,0ddh,0fdh,000h	; 9434  .?.......?......
	defb 07fh,03fh,000h,0e9h,0edh,0fdh,0e3h,000h,07fh,03fh,0c3h,000h,0c3h,0fbh,0c7h,000h	; 9444  .?.......?......
	defb 07fh,03fh,0cdh,0fdh,0cdh,0fbh,0c7h,000h,07fh,03fh,0eah,0efh,0e7h,0ebh,0efh,000h	; 9454  .?.......?......
	defb 07fh,03fh,0efh,0efh,0edh,0edh,0e3h,0e0h,000h,07fh,03fh,0e1h,000h,0e1h,000h,0e1h	; 9464  .?........?.....
	defb 000h,07fh,03fh,087h,0f0h,0eeh,0ddh,0fdh,000h,07fh,03fh,000h,0e9h,0edh,0fdh,0e3h	; 9474  ..?.......?.....
	defb 000h,07fh,03fh,0c3h,000h,0c3h,0fbh,0c7h,000h,07fh,03fh,0cdh,0fdh,0cdh,0fbh,0c7h	; 9484  ..?.......?.....
	defb 000h,07fh,03fh,0eah,0efh,0e7h,0ebh,0efh,000h,07fh,03fh,0efh,0efh,0edh,0edh,0e3h	; 9494  ..?.......?.....
	defb 000h,07fh,03fh,0e1h,000h,0e1h,000h,0e1h,000h,07fh,03fh,087h,0f0h,0eeh,0ddh,0fdh	; 94a4  ..?.......?.....
	defb 000h,07fh,03fh,000h,0e9h,0edh,0fdh,0e3h,000h,07fh,03fh,0c3h,000h,0c3h,0fbh,0c7h	; 94b4  ..?.......?.....
	defb 000h,07fh,03fh,0cdh,0fdh,0cdh,0fbh,0c7h,008h,000h,002h,0dfh,084h,0c0h,000h,0c0h	; 94c4  ..?.............
	defb 080h,003h,000h,005h,001h,082h,0feh,001h,007h,0feh,084h,000h,07fh,000h,0c0h,005h	; 94d4  ................
	defb 0dfh,005h,0fch,081h,0f8h,008h,000h,081h,0feh,009h,0fch,081h,0feh,007h,000h,004h	; 94e4  ................
	defb 020h,081h,0c0h,003h,000h,008h,020h,005h,000h,083h,0c0h,020h,020h,008h,0c0h,002h	; 94f4   ..... ....  ...
	defb 0d8h,08ah,018h,0f8h,004h,002h,000h,000h,0fbh,0fbh,003h,0feh,00ah,000h,082h,07fh	; 9504  ................
	defb 03fh,009h,000h,002h,0aah,012h,000h,086h,0c3h,024h,024h,0feh,000h,003h,005h,0fbh	; 9514  ?........$$.....
	defb 005h,03fh,081h,01fh,008h,000h,081h,07fh,009h,03fh,081h,07fh,007h,000h,004h,004h	; 9524  .?.......?......
	defb 081h,003h,003h,000h,008h,004h,005h,000h,083h,003h,004h,004h,008h,003h,00ch,024h	; 9534  ...............$
	defb 081h,0c3h,003h,000h,008h,0feh,008h,0fch,004h,0feh,004h,07eh,081h,000h,006h,077h	; 9544  ...........~...w
	defb 081h,000h,008h,0fch,000h	; 9554

; ----------------------------------------------------------------------
; DATOS teclado_colores_1: flujo RLE de 0x4327 hacia 0x0080
;   0x9559..0x95ea  (145 bytes)
DATA_teclado_colores_1:
	defb 084h,000h,011h,0f1h,0f1h,004h,0a1h,084h,000h,011h,0f1h,0f1h,00ah,0a1h,082h,010h	; 9559  ................
	defb 011h,006h,0a1h,002h,011h,008h,050h,081h,000h,004h,050h,082h,000h,050h,005h,000h	; 9569  ......P...P..P..
	defb 086h,055h,000h,050h,050h,000h,000h,00eh,050h,002h,000h,006h,050h,004h,000h,084h	; 9579  .U.PP...P...P...
	defb 055h,000h,055h,000h,003h,044h,089h,0ffh,077h,044h,011h,055h,044h,044h,077h,055h	; 9589  U.U..D..wD.UDDwU
	defb 005h,011h,003h,044h,084h,011h,044h,011h,044h,004h,055h,086h,011h,055h,011h,055h	; 9599  ...D..D.D.U..U.U
	defb 0ffh,0ffh,006h,0eeh,081h,000h,007h,050h,081h,000h,00ch,050h,003h,000h,003h,050h	; 95a9  .......P...P...P
	defb 082h,000h,055h,003h,000h,005h,050h,081h,000h,009h,050h,081h,000h,00fh,050h,081h	; 95b9  ..U...P...P...P.
	defb 000h,003h,050h,082h,000h,055h,003h,000h,005h,050h,003h,000h,085h,055h,000h,055h	; 95c9  ..P..U...P...U.U
	defb 000h,055h,007h,000h,089h,055h,050h,055h,050h,055h,050h,055h,050h,055h,003h,000h	; 95d9  .U...UPUPUPUPU..
	defb 000h	; 95e9

; ----------------------------------------------------------------------
; DATOS teclado_colores_2: flujo RLE de 0x4327 hacia 0x0458
;   0x95ea..0x97fd  (531 bytes)
DATA_teclado_colores_2:
	defb 002h,055h,082h,011h,055h,004h,011h,002h,055h,081h,011h,005h,055h,018h,051h,008h	; 95ea  .U..U...U...U.Q.
	defb 041h,002h,055h,006h,0f5h,081h,055h,007h,0f5h,003h,055h,005h,0f5h,003h,055h,005h	; 95fa  A.U...U...U...U.
	defb 0f5h,003h,055h,005h,0f5h,081h,055h,007h,0f5h,006h,051h,085h,0f1h,071h,0ffh,0eeh	; 960a  ..U...U...Q..q..
	defb 011h,005h,0cch,011h,051h,003h,055h,003h,051h,082h,011h,051h,003h,055h,004h,011h	; 961a  ....Q.U.Q..Q.U..
	defb 004h,051h,004h,011h,083h,0ffh,0feh,0feh,005h,0eeh,003h,0f1h,084h,0e1h,011h,0e1h	; 962a  .Q..............
	defb 011h,049h,0e1h,081h,011h,007h,0e1h,081h,011h,007h,0e1h,081h,011h,01fh,0e1h,003h	; 963a  .I..............
	defb 0f1h,005h,0e1h,004h,0e0h,08ch,0f0h,0e0h,010h,044h,0e1h,0e1h,0f1h,0e1h,011h,0e1h	; 964a  .........D......
	defb 011h,044h,004h,0eeh,002h,0e1h,002h,011h,006h,0e1h,002h,011h,083h,099h,096h,096h	; 965a  .D..............
	defb 005h,066h,003h,091h,005h,061h,004h,066h,002h,061h,002h,011h,006h,061h,002h,011h	; 966a  .f...a.f.a...a..
	defb 002h,055h,084h,011h,088h,088h,011h,004h,055h,084h,011h,0cch,0cch,011h,004h,055h	; 967a  .U......U......U
	defb 084h,011h,0ddh,0ddh,011h,004h,055h,091h,011h,044h,044h,011h,055h,055h,011h,055h	; 968a  ......U..DD.UU.U
	defb 011h,055h,011h,055h,011h,055h,011h,055h,011h,004h,055h,082h,077h,055h,00dh,051h	; 969a  .U.U.U.U..U.wU.Q
	defb 002h,011h,083h,0ffh,0feh,0feh,005h,0e6h,083h,0ffh,0feh,0feh,005h,0e6h,08bh,0ffh	; 96aa  ................
	defb 0feh,0feh,0e6h,0eeh,0e6h,0eeh,0e6h,0ffh,0feh,0feh,005h,0e6h,084h,0ffh,0feh,0feh	; 96ba  ................
	defb 0eeh,004h,0e6h,085h,0ffh,0feh,0feh,0e6h,0eeh,003h,0e6h,083h,0ffh,0feh,0feh,005h	; 96ca  ................
	defb 0e6h,083h,0ffh,0feh,0feh,005h,0ech,083h,0ffh,0feh,0feh,005h,0ech,08bh,0ffh,0feh	; 96da  ................
	defb 0feh,0ech,0eeh,0ech,0eeh,0ech,0ffh,0feh,0feh,005h,0ech,084h,0ffh,0feh,0feh,0eeh	; 96ea  ................
	defb 004h,0ech,085h,0ffh,0feh,0feh,0ech,0eeh,003h,0ech,083h,0ffh,0feh,0feh,005h,0ech	; 96fa  ................
	defb 083h,0ffh,0feh,0feh,005h,0edh,083h,0ffh,0feh,0feh,005h,0edh,08bh,0ffh,0feh,0feh	; 970a  ................
	defb 0edh,0eeh,0edh,0eeh,0edh,0ffh,0feh,0feh,005h,0edh,084h,0ffh,0feh,0feh,0eeh,004h	; 971a  ................
	defb 0edh,085h,0ffh,0feh,0feh,0edh,0eeh,003h,0edh,083h,0ffh,0feh,0feh,005h,0edh,083h	; 972a  ................
	defb 0ffh,0feh,0feh,005h,0e4h,083h,0ffh,0feh,0feh,005h,0e4h,08bh,0ffh,0feh,0feh,0e4h	; 973a  ................
	defb 0eeh,0e4h,0eeh,0e4h,0ffh,0feh,0feh,005h,0e4h,084h,0ffh,0feh,0feh,0eeh,004h,0e4h	; 974a  ................
	defb 085h,0ffh,0feh,0feh,0e4h,0eeh,003h,0e4h,083h,0ffh,0feh,0feh,005h,0e4h,006h,055h	; 975a  ...............U
	defb 082h,0ffh,077h,003h,051h,086h,055h,051h,051h,011h,011h,055h,005h,051h,082h,0e5h	; 976a  ..w.Q.UQQ..U.Q..
	defb 051h,005h,081h,085h,091h,081h,011h,051h,055h,006h,051h,005h,0c1h,083h,021h,011h	; 977a  Q......QU.Q...!.
	defb 011h,006h,0cch,00bh,0c1h,007h,0cch,005h,0e5h,002h,055h,081h,077h,008h,0e5h,005h	; 978a  ..........U.w...
	defb 055h,003h,0e5h,008h,0ech,006h,051h,002h,011h,004h,051h,004h,011h,083h,0ffh,0eeh	; 979a  U.....Q...Q.....
	defb 011h,003h,0cch,002h,0c1h,008h,000h,088h,055h,051h,051h,055h,0eeh,055h,055h,077h	; 97aa  ........UQQU.UUw
	defb 005h,055h,081h,0eeh,007h,055h,003h,0e5h,082h,051h,055h,006h,051h,005h,0c1h,083h	; 97ba  .U...U...QU.Q...
	defb 021h,011h,011h,006h,0cch,00bh,0c1h,007h,0cch,005h,0e5h,002h,055h,081h,077h,008h	; 97ca  !...........U.w.
	defb 0e5h,005h,055h,003h,0e5h,008h,0ech,00dh,0e5h,002h,055h,081h,077h,007h,050h,081h	; 97da  ..U.......U.w.P.
	defb 070h,008h,051h,008h,041h,081h,000h,004h,040h,083h,0f0h,040h,000h,006h,051h,082h	; 97ea  p.Q.A...@..@..Q.
	defb 0f1h,071h,000h	; 97fa

; ----------------------------------------------------------------------
; DATOS rotulos_internacionales_patrones: flujo RLE de 0x4327 hacia 0x2600:
;   solo si (0x002C) & 0x0F no es cero, o sea en un MSX que no es japones
;   0x97fd..0x98df  (226 bytes)
DATA_rotulos_internacionales_patrones:
	defb 08ch,000h,07fh,03fh,0f3h,0edh,0efh,0edh,0f3h,000h,07fh,03fh,0e3h,003h,0edh,0b5h	; 97fd  ...?.......?....
	defb 0e3h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh,0e1h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh	; 980d  ...?.......?....
	defb 0efh,000h,07fh,03fh,0f1h,0efh,0e9h,0edh,0f3h,000h,07fh,03fh,0f3h,0edh,0e1h,0edh	; 981d  ...?.......?....
	defb 0edh,000h,07fh,03fh,0e3h,0edh,0e3h,0edh,0e3h,000h,07fh,03fh,0f3h,0edh,0efh,0edh	; 982d  ...?.......?....
	defb 0f3h,000h,07fh,03fh,0e3h,003h,0edh,0b5h,0e3h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh	; 983d  ...?.......?....
	defb 0e1h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh,0efh,000h,07fh,03fh,0f1h,0efh,0e9h,0edh	; 984d  ...?.......?....
	defb 0f3h,000h,07fh,03fh,0f3h,0edh,0e1h,0edh,0edh,000h,07fh,03fh,0e3h,0edh,0e3h,0edh	; 985d  ...?.......?....
	defb 0e3h,000h,07fh,03fh,0f3h,0edh,0efh,0edh,0f3h,000h,07fh,03fh,0e3h,003h,0edh,0b5h	; 986d  ...?.......?....
	defb 0e3h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh,0e1h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh	; 987d  ...?.......?....
	defb 0efh,000h,07fh,03fh,0f1h,0efh,0e9h,0edh,0f3h,000h,07fh,03fh,0f3h,0edh,0e1h,0edh	; 988d  ...?.......?....
	defb 0edh,000h,07fh,03fh,0e3h,0edh,0e3h,0edh,0e3h,000h,07fh,03fh,0f3h,0edh,0efh,0edh	; 989d  ...?.......?....
	defb 0f3h,000h,07fh,03fh,0e3h,003h,0edh,0a9h,0e3h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh	; 98ad  ...?.......?....
	defb 0e1h,000h,07fh,03fh,0e1h,0efh,0e1h,0efh,0efh,000h,07fh,03fh,0f1h,0efh,0e9h,0edh	; 98bd  ...?.......?....
	defb 0f3h,000h,07fh,03fh,0f3h,0edh,0e1h,0edh,0edh,000h,07fh,03fh,0e3h,0edh,0e3h,0edh	; 98cd  ...?.......?....
	defb 0e3h,000h	; 98dd

; ----------------------------------------------------------------------
; DATOS rotulos_internacionales_colores: flujo RLE de 0x4327 hacia 0x0600: lo
;   mismo
;   0x98df..0x9988  (169 bytes)
DATA_rotulos_internacionales_colores:
	defb 083h,0ffh,0feh,0feh,005h,0e6h,083h,0ffh,0feh,0feh,005h,0e6h,083h,0ffh,0feh,0feh	; 98df  ................
	defb 005h,0e6h,083h,0ffh,0feh,0feh,005h,0e6h,083h,0ffh,0feh,0feh,005h,0e6h,083h,0ffh	; 98ef  ................
	defb 0feh,0feh,005h,0e6h,083h,0ffh,0feh,0feh,005h,0e6h,083h,0ffh,0feh,0feh,005h,0ech	; 98ff  ................
	defb 083h,0ffh,0feh,0feh,005h,0ech,083h,0ffh,0feh,0feh,005h,0ech,083h,0ffh,0feh,0feh	; 990f  ................
	defb 005h,0ech,083h,0ffh,0feh,0feh,005h,0ech,083h,0ffh,0feh,0feh,005h,0ech,083h,0ffh	; 991f  ................
	defb 0feh,0feh,005h,0ech,083h,0ffh,0feh,0feh,005h,0edh,083h,0ffh,0feh,0feh,005h,0edh	; 992f  ................
	defb 083h,0ffh,0feh,0feh,005h,0edh,083h,0ffh,0feh,0feh,005h,0edh,083h,0ffh,0feh,0feh	; 993f  ................
	defb 005h,0edh,083h,0ffh,0feh,0feh,005h,0edh,083h,0ffh,0feh,0feh,005h,0edh,083h,0ffh	; 994f  ................
	defb 0feh,0feh,005h,0e4h,083h,0ffh,0feh,0feh,005h,0e4h,083h,0ffh,0feh,0feh,005h,0e4h	; 995f  ................
	defb 083h,0ffh,0feh,0feh,005h,0e4h,083h,0ffh,0feh,0feh,005h,0e4h,083h,0ffh,0feh,0feh	; 996f  ................
	defb 005h,0e4h,083h,0ffh,0feh,0feh,005h,0e4h,000h	; 997f  .........

; ----------------------------------------------------------------------
; DATOS teclado_nombres: flujo RLE de 0x4352 hacia 0x3800
;   0x9988..0x9ac5  (317 bytes)
DATA_teclado_nombres:
	defb 000h,038h,089h,000h,055h,0f7h,091h,092h,093h,094h,095h,096h,009h,0eeh,084h,0efh	; 9988  .8..U...........
	defb 0eeh,0eeh,0e7h,008h,01eh,085h,002h,04ah,000h,055h,0f6h,00bh,0deh,004h,0dfh,084h	; 9998  .......J.U......
	defb 0f9h,0feh,0feh,0e6h,008h,0bch,085h,002h,04ah,000h,055h,0f5h,00fh,0edh,084h,0fah	; 99a8  ........J.U.....
	defb 0edh,0edh,0e5h,008h,0bdh,084h,00ch,04ah,000h,055h,01dh,00eh,085h,04ah,000h,090h	; 99b8  .......J.U...J..
	defb 002h,002h,004h,0bbh,007h,0b8h,007h,0b9h,007h,0bah,002h,002h,0e5h,07eh,000h,090h	; 99c8  .............~..
	defb 0bch,0fch,0a9h,0aah,0aah,0abh,0a9h,0aah,0abh,0a9h,0aah,0aah,0abh,0a9h,0aah,0abh	; 99d8  ................
	defb 0a9h,0aah,0aah,0abh,0a9h,0aah,0abh,0a9h,0aah,0aah,0abh,002h,0bch,07eh,000h,090h	; 99e8  .............~..
	defb 0bch,0fch,0ach,0adh,0adh,0aeh,0ach,0adh,0aeh,0ach,0adh,0adh,0aeh,0ach,0adh,0aeh	; 99f8  ................
	defb 0ach,0adh,0adh,0aeh,0ach,0adh,0aeh,0ach,0adh,0adh,0aeh,002h,0bch,07eh,000h,090h	; 9a08  .............~..
	defb 0bch,0fch,0a6h,0a7h,0a7h,0a8h,0a6h,0a7h,0a8h,0a6h,0a7h,0a7h,0a8h,0a6h,0a7h,0a8h	; 9a18  ................
	defb 0a6h,0a7h,0a7h,0a8h,0a6h,0a7h,0a8h,0a6h,0a7h,0a7h,0a8h,002h,0bch,07eh,000h,090h	; 9a28  .............~..
	defb 0bch,0fch,019h,086h,087h,002h,0bch,07eh,000h,090h,0bch,0fch,019h,086h,087h,002h	; 9a38  .......~........
	defb 0bch,07eh,000h,090h,0dch,0ffh,019h,0b1h,002h,0dch,082h,07eh,000h,01fh,01ch,082h	; 9a48  .~.........~....
	defb 080h,098h,01ah,03bh,086h,0ebh,098h,098h,075h,0e8h,0e3h,01ah,000h,086h,0f3h,03dh	; 9a58  ...;....u......=
	defb 03dh,0f8h,0e8h,0e3h,01ah,000h,087h,0f1h,03eh,0f2h,0f8h,0e8h,03dh,0e3h,018h,000h	; 9a68  =.......>...=...
	defb 088h,08dh,08ch,0f0h,0f3h,0f8h,0e8h,03dh,0e3h,018h,000h,089h,09dh,099h,08eh,0f3h	; 9a78  .......=........
	defb 0f8h,0e8h,03dh,03dh,0e3h,018h,000h,088h,09ah,08eh,0f3h,0f8h,0e8h,0e2h,03eh,0e1h	; 9a88  ..==..........>.
	defb 018h,000h,089h,09bh,09ch,0f3h,0f8h,0e8h,0e3h,0e0h,08ch,08fh,014h,000h,08ch,0e0h	; 9a98  ................
	defb 0beh,0e0h,08ch,0f0h,0f3h,0f8h,0e8h,0e3h,0ddh,08bh,0e9h,014h,000h,089h,0ddh,0bfh	; 9aa8  ................
	defb 0ddh,08bh,0eah,0f3h,0f8h,0e8h,0e4h,01ch,03fh,082h,0f4h,0f8h,000h	; 9ab8  ........?....

; ----------------------------------------------------------------------
; DATOS file_patrones: flujo RLE de 0x4327 hacia 0x2458
;   0x9ac5..0x9c63  (414 bytes)
DATA_file_patrones:
	defb 028h,000h,082h,03eh,063h,003h,060h,087h,063h,03eh,000h,07ch,062h,062h,07ch,003h	; 9ac5  (..>c.`.c>.|bb|.
	defb 060h,085h,000h,066h,066h,03ch,03ch,003h,018h,08bh,000h,07eh,066h,060h,07eh,006h	; 9ad5  `..ff<<....~f`~.
	defb 066h,07eh,000h,07eh,07eh,005h,018h,00ch,000h,002h,018h,005h,000h,084h,0e7h,0c3h	; 9ae5  f~.~~...........
	defb 0c3h,0e7h,004h,000h,08ah,0e7h,0c3h,0c3h,0e7h,000h,000h,07eh,060h,060h,07eh,003h	; 9af5  ...........~``~.
	defb 060h,081h,000h,007h,018h,081h,000h,006h,060h,093h,07eh,000h,07eh,060h,060h,07eh	; 9b05  `.......`.~.~``~
	defb 060h,060h,07eh,000h,061h,073h,073h,06dh,06dh,061h,061h,000h,03eh,005h,063h,083h	; 9b15  ``~.assmmaa.>.c.
	defb 03eh,000h,07ch,005h,063h,083h,07ch,000h,000h,005h,0cfh,003h,000h,085h,006h,03eh	; 9b25  >.|.c.|........>
	defb 006h,0e6h,006h,003h,000h,096h,04fh,01fh,03fh,01fh,04fh,000h,000h,07fh,07fh,041h	; 9b35  ......O.?.O....A
	defb 04fh,041h,079h,041h,07fh,000h,000h,0c7h,09bh,083h,09bh,09bh,003h,000h,004h,036h	; 9b45  OAyA...........6
	defb 084h,08eh,000h,07fh,07fh,004h,04fh,085h,041h,07fh,000h,000h,083h,003h,09bh,081h	; 9b55  ......O.A.......
	defb 083h,003h,000h,085h,08eh,036h,006h,036h,036h,011h,000h,002h,07fh,081h,041h,004h	; 9b65  .....6.66.....A.
	defb 073h,088h,07fh,000h,000h,0c7h,09bh,083h,09bh,09bh,003h,000h,085h,00eh,036h,00eh	; 9b75  s.............6.
	defb 03eh,03eh,003h,000h,088h,00fh,07fh,00fh,07fh,00fh,000h,07fh,043h,003h,04dh,089h	; 9b85  >>..........C.M.
	defb 043h,07fh,07fh,000h,01fh,000h,01fh,09fh,01fh,004h,000h,081h,00ch,003h,06ch,081h	; 9b95  C.............l.
	defb 00ch,003h,000h,085h,036h,016h,016h,026h,026h,003h,000h,081h,0b0h,003h,0b9h,081h	; 9ba5  ....6..&&.......
	defb 039h,003h,000h,002h,036h,083h,006h,0ceh,0ceh,003h,000h,094h,083h,09fh,083h,09fh	; 9bb5  9...6...........
	defb 083h,000h,07fh,041h,04fh,041h,079h,041h,07fh,07fh,000h,0c7h,09bh,083h,09bh,09bh	; 9bc5  ...AOAyA........
	defb 003h,000h,082h,036h,006h,003h,036h,003h,000h,085h,00fh,06fh,00fh,07fh,07fh,004h	; 9bd5  ...6..6....o....
	defb 000h,005h,0cfh,019h,000h,082h,07fh,041h,003h,04dh,089h,041h,07fh,07fh,000h,083h	; 9be5  .......A.M.A....
	defb 09fh,083h,09fh,083h,003h,000h,085h,093h,087h,08fh,087h,093h,004h,000h,081h,01fh	; 9bf5  ................
	defb 003h,06fh,081h,01fh,003h,000h,081h,083h,003h,09bh,081h,083h,003h,000h,085h,083h	; 9c05  .o..............
	defb 09fh,083h,09fh,083h,003h,000h,004h,03fh,08bh,007h,000h,07fh,041h,04fh,041h,04fh	; 9c15  .......?....AOAO
	defb 04fh,07fh,07fh,000h,004h,03eh,081h,006h,003h,000h,090h,00ch,07ch,00ch,07fh,00ch	; 9c25  O....>......|...
	defb 000h,000h,07fh,049h,043h,047h,043h,049h,07fh,07fh,000h,004h,09fh,081h,083h,038h	; 9c35  ...ICGCI.......8
	defb 000h,004h,0feh,006h,000h,008h,006h,081h,0f0h,006h,0c0h,081h,0f0h,066h,000h,004h	; 9c45  .............f..
	defb 07fh,006h,000h,008h,060h,081h,00fh,006h,003h,081h,00fh,060h,000h,000h	; 9c55  ....`......`..

; ----------------------------------------------------------------------
; DATOS file_colores: flujo RLE de 0x4327 hacia 0x0458
;   0x9c63..0x9d74  (273 bytes)
DATA_file_colores:
	defb 028h,000h,007h,091h,081h,0ffh,007h,091h,081h,0ffh,007h,091h,081h,0ffh,007h,091h	; 9c63  (...............
	defb 081h,0ffh,007h,091h,081h,0ffh,008h,000h,003h,011h,002h,0f1h,003h,011h,002h,0eeh	; 9c73  ................
	defb 004h,0e1h,004h,0eeh,004h,0e8h,002h,0eeh,007h,091h,081h,0ffh,007h,091h,081h,0ffh	; 9c83  ................
	defb 007h,091h,081h,0ffh,007h,091h,081h,0ffh,007h,091h,081h,0ffh,007h,091h,081h,0ffh	; 9c93  ................
	defb 007h,091h,082h,0ffh,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,002h	; 9ca3  ................
	defb 0eeh,008h,0e1h,002h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,081h,0eeh,008h,0e1h,002h	; 9cb3  ................
	defb 0eeh,005h,0e1h,003h,0eeh,005h,0e1h,081h,0eeh,005h,044h,086h,011h,0cch,033h,033h	; 9cc3  ..........D...33
	defb 0cch,011h,005h,044h,008h,0e1h,002h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh	; 9cd3  ...D............
	defb 005h,0e1h,081h,0eeh,008h,0e1h,083h,0eeh,0e1h,0eeh,003h,0e1h,004h,0eeh,005h,0e1h	; 9ce3  ................
	defb 003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h	; 9cf3  ................
	defb 081h,0eeh,008h,0e1h,081h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h	; 9d03  ................
	defb 004h,0eeh,005h,0e1h,081h,0eeh,018h,000h,008h,0e1h,081h,0eeh,005h,0e1h,003h,0eeh	; 9d13  ................
	defb 005h,0e1h,004h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,003h,0eeh	; 9d23  ................
	defb 005h,0e1h,081h,0eeh,008h,0e1h,081h,0eeh,005h,0e1h,003h,0eeh,005h,0e1h,002h,0eeh	; 9d33  ................
	defb 081h,0e0h,005h,0e1h,002h,0e0h,081h,0eeh,005h,0e1h,002h,0eeh,030h,000h,005h,044h	; 9d43  ............0..D
	defb 086h,011h,0c1h,031h,031h,0c1h,011h,005h,044h,008h,030h,008h,0f0h,060h,000h,005h	; 9d53  ...11...D.0..`..
	defb 044h,086h,011h,0c1h,031h,031h,0c1h,011h,005h,044h,008h,030h,008h,0f0h,060h,000h	; 9d63  D...11...D.0..`.
	defb 000h	; 9d73

; ----------------------------------------------------------------------
; DATOS file_nombres: flujo RLE de 0x4352 hacia 0x3860
;   0x9d74..0x9e37  (195 bytes)
DATA_file_nombres:
	defb 060h,038h,082h,081h,0e0h,01ch,0a9h,084h,0d0h,076h,081h,0e2h,01ch,000h,084h,0d2h	; 9d74  `8.......v......
	defb 076h,081h,0e2h,01ch,000h,084h,0d2h,076h,081h,0e2h,016h,000h,08ah,098h,0abh,0ach	; 9d84  v......v........
	defb 0adh,0aeh,003h,0d2h,076h,081h,0e2h,016h,000h,08ah,097h,0afh,0a0h,0a1h,0a2h,003h	; 9d94  ....v...........
	defb 0d2h,076h,081h,0e2h,01ch,000h,084h,0d2h,076h,081h,0e2h,016h,000h,08ah,098h,0a3h	; 9da4  .v......v.......
	defb 0a4h,0a5h,0aeh,003h,0d2h,076h,081h,0e2h,016h,000h,08ah,097h,0a6h,0a7h,0a8h,0c1h	; 9db4  .....v..........
	defb 003h,0d2h,076h,081h,0e2h,016h,000h,082h,097h,07bh,004h,003h,084h,0d2h,076h,081h	; 9dc4  ..v......{....v.
	defb 0e2h,016h,000h,082h,097h,07bh,004h,003h,084h,0d2h,076h,081h,0e2h,01ch,000h,084h	; 9dd4  .....{....v.....
	defb 0d2h,076h,081h,0e2h,016h,000h,08ah,098h,0abh,0c2h,0b2h,0aeh,003h,0d2h,076h,081h	; 9de4  .v............v.
	defb 0e2h,016h,000h,08ah,097h,0a6h,0a4h,0b4h,0b1h,0b3h,0d2h,076h,081h,0e2h,016h,000h	; 9df4  ...........v....
	defb 08ah,097h,0b6h,0b7h,0b8h,0b9h,003h,0d2h,076h,081h,0e2h,01ch,000h,084h,0d2h,076h	; 9e04  ........v......v
	defb 081h,0e2h,016h,000h,083h,097h,0beh,0c0h,003h,003h,084h,0d2h,076h,081h,0e2h,01ch	; 9e14  ............v...
	defb 000h,084h,0d2h,076h,081h,0e2h,01ch,000h,084h,0d2h,076h,081h,0e1h,01ch,0aah,082h	; 9e24  ...v......v.....
	defb 0d1h,076h,000h	; 9e34

; ----------------------------------------------------------------------
; DATOS digitos_patrones: 0x50 bytes que 0xB34A copia a 0x2080 en los tres
;   tercios: los patrones de los diez digitos (tiles 0x10-0x19)
;   0x9e37..0x9e87  (80 bytes)
DATA_digitos_patrones:
	defb 000h,000h,018h,024h,024h,024h,018h,000h,000h,000h,008h,018h,008h,008h,008h,000h	; 9e37  ...$$$..........
	defb 000h,000h,018h,024h,008h,010h,03ch,000h,000h,000h,018h,024h,008h,024h,018h,000h	; 9e47  ...$..<....$.$..
	defb 000h,000h,008h,018h,028h,03ch,008h,000h,000h,000h,038h,020h,038h,004h,038h,000h	; 9e57  ....(<....8 8.8.
	defb 000h,000h,038h,040h,078h,044h,038h,000h,000h,000h,03ch,024h,008h,010h,010h,000h	; 9e67  ..8@xD8...<$....
	defb 000h,000h,018h,024h,018h,024h,018h,000h,000h,000h,018h,024h,01ch,004h,018h,000h	; 9e77  ...$.$.....$....

; ----------------------------------------------------------------------
; DATOS rotulo_colores_a: 8 bytes de color que 0xB363 copia a los diez digitos
;   (TONE EDIT)
;   0x9e87..0x9e8f  (8 bytes)
DATA_rotulo_colores_a:
	defb 0eeh,000h,070h,070h,070h,070h,070h,000h	; 9e87  ..ppppp.

; ----------------------------------------------------------------------
; DATOS rotulo_colores_b: 8 bytes de color para las demas pantallas
;   0x9e8f..0x9e97  (8 bytes)
DATA_rotulo_colores_b:
	defb 005h,000h,070h,070h,070h,070h,070h,000h	; 9e8f  ..ppppp.

; ----------------------------------------------------------------------
; DATOS titulo_patrones: 0x428 bytes de patrones del logotipo 新世SIZER: 0x4708
;   los copia de golpe a 0x2200 y 0x418A de byte en byte, que es la animacion
;   de la pincelada
;   0x9e97..0xa2bf  (1064 bytes)
DATA_titulo_patrones:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0e0h,000h,000h	; 9e97  ................
	defb 000h,000h,000h,000h,000h,03fh,0e0h,000h,000h,000h,000h,000h,000h,000h,00fh,0f8h	; 9ea7  .....?..........
	defb 000h,000h,000h,000h,000h,000h,000h,001h,080h,000h,000h,000h,000h,000h,000h,000h	; 9eb7  ................
	defb 01fh,0f8h,0c0h,000h,000h,000h,000h,000h,000h,000h,00fh,0feh,0f0h,080h,000h,000h	; 9ec7  ................
	defb 000h,000h,000h,000h,007h,07fh,0feh,0f0h,000h,000h,000h,000h,000h,000h,003h,01fh	; 9ed7  ................
	defb 080h,000h,000h,000h,000h,000h,000h,000h,0ffh,0feh,0f0h,0c0h,000h,000h,000h,000h	; 9ee7  ................
	defb 000h,007h,01fh,0ffh,0feh,0f8h,0e0h,080h,000h,000h,000h,000h,003h,01fh,07fh,0ffh	; 9ef7  ................
	defb 000h,000h,000h,000h,000h,000h,000h,001h,000h,000h,000h,000h,000h,000h,001h,01fh	; 9f07  ................
	defb 000h,000h,018h,03ch,03ch,018h,0fch,0ffh,000h,000h,000h,000h,003h,00fh,03fh,0feh	; 9f17  ...<<.........?.
	defb 003h,00ch,038h,0f0h,0e0h,0c0h,000h,000h,080h,000h,000h,001h,003h,006h,00eh,01ch	; 9f27  ..8.............
	defb 000h,000h,000h,000h,002h,006h,004h,00ch,000h,000h,002h,002h,006h,00ch,00ch,018h	; 9f37  ................
	defb 000h,000h,000h,000h,001h,003h,00fh,01fh,007h,00fh,03fh,07fh,0ffh,0feh,0fch,0f0h	; 9f47  ..........?.....
	defb 0feh,0f8h,0f0h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,00ch,030h	; 9f57  ...............0
	defb 000h,000h,000h,000h,000h,000h,000h,002h,000h,000h,000h,000h,000h,003h,000h,000h	; 9f67  ................
	defb 07fh,001h,003h,007h,07fh,0ffh,01fh,001h,000h,084h,00ch,01ch,0ffh,0ffh,0fch,080h	; 9f77  ................
	defb 0e3h,00fh,018h,020h,0f0h,03bh,03fh,079h,0fch,0f0h,000h,000h,07fh,0ffh,0ffh,0ffh	; 9f87  ... .;?y........
	defb 000h,000h,000h,01fh,0c3h,0fch,0f1h,081h,01ch,03ch,07ch,0ffh,0ffh,0ffh,0ffh,0f0h	; 9f97  .........<|.....
	defb 01ch,018h,038h,0ffh,0ffh,0ffh,0f8h,0e1h,038h,038h,070h,0ffh,0ffh,0f0h,0e0h,0e0h	; 9fa7  ..8.....88p.....
	defb 000h,000h,000h,0fdh,003h,003h,003h,007h,03fh,07fh,0ffh,0ffh,0feh,0feh,0fch,0fch	; 9fb7  ........?.......
	defb 0e0h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,03fh	; 9fc7  ...............?
	defb 000h,000h,000h,000h,003h,03fh,0ffh,0ffh,000h,000h,000h,000h,0fch,0ffh,0ffh,0ffh	; 9fd7  .....?..........
	defb 000h,000h,000h,000h,000h,0c0h,0f0h,0f8h,000h,001h,003h,007h,007h,00fh,01fh,01fh	; 9fe7  ................
	defb 060h,0c0h,0c0h,080h,080h,081h,000h,000h,003h,000h,000h,000h,000h,000h,000h,000h	; 9ff7  `...............
	defb 000h,000h,000h,007h,07fh,0ffh,01fh,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh	; a007  ................
	defb 000h,000h,000h,000h,0e0h,0fch,0f8h,0e1h,004h,00ch,018h,038h,07fh,0ffh,0ffh,0ffh	; a017  ...........8....
	defb 000h,000h,000h,000h,0feh,0ffh,0ffh,0e0h,000h,000h,000h,000h,000h,0feh,0e0h,000h	; a027  ................
	defb 008h,018h,039h,03bh,07ch,078h,0f0h,0f0h,000h,03eh,0ffh,0ffh,01fh,00fh,00fh,01fh	; a037  ..9;|x...>......
	defb 000h,000h,080h,0c0h,0c0h,0c0h,0c0h,080h,000h,001h,001h,000h,000h,000h,001h,003h	; a047  ................
	defb 003h,0ffh,0ffh,03fh,03fh,0f7h,0efh,0ceh,080h,0feh,0feh,0c0h,0e0h,071h,039h,03dh	; a057  ...??........q9=
	defb 078h,0f8h,0f8h,0f8h,0f0h,0f0h,0e1h,0e1h,07ch,030h,078h,078h,0f8h,0f0h,0f0h,0f0h	; a067  x.......|0xx....
	defb 003h,003h,003h,003h,007h,007h,007h,00fh,0e1h,0e1h,0c1h,0c3h,083h,080h,000h,000h	; a077  ................
	defb 0c1h,083h,083h,0e7h,076h,004h,000h,000h,0c0h,080h,000h,000h,000h,000h,000h,000h	; a087  ....v...........
	defb 007h,003h,003h,001h,000h,000h,000h,000h,0fch,0feh,0ffh,0ffh,07fh,000h,000h,000h	; a097  ................
	defb 003h,01fh,0ffh,0f0h,000h,000h,000h,000h,0ffh,0f8h,000h,000h,000h,000h,000h,000h	; a0a7  ................
	defb 0e0h,000h,000h,000h,000h,000h,000h,001h,03fh,00fh,007h,007h,007h,00fh,01fh,0ffh	; a0b7  ........?.......
	defb 0fch,0fch,0feh,0feh,0feh,0feh,0fch,0fch,03fh,03fh,07fh,07fh,07fh,07fh,07fh,03fh	; a0c7  ........??.....?
	defb 000h,080h,080h,0c0h,0e0h,0fch,0f8h,0f0h,000h,000h,000h,003h,00fh,03fh,07fh,0feh	; a0d7  .............?..
	defb 01fh,03fh,0feh,0fch,0f0h,0c0h,000h,000h,0c3h,083h,007h,007h,00fh,00fh,00fh,01fh	; a0e7  .?..............
	defb 0f0h,0e0h,0e0h,0dfh,0ffh,080h,080h,000h,000h,000h,000h,0fch,0ffh,000h,000h,000h	; a0f7  ................
	defb 001h,001h,003h,003h,0e7h,00fh,00fh,01fh,0f0h,0e0h,0e1h,0e7h,0ffh,0c1h,080h,000h	; a107  ................
	defb 03fh,07ch,0f0h,080h,0c0h,0f0h,0f8h,07ch,007h,00fh,01ch,030h,040h,000h,000h,000h	; a117  ?|.....|...0@...
	defb 09eh,01ch,018h,038h,030h,030h,060h,040h,01fh,007h,003h,007h,006h,00ch,00ch,018h	; a127  ...800`@........
	defb 0c1h,083h,0c3h,003h,003h,007h,007h,007h,0e0h,0e0h,0e0h,0c0h,0c0h,0c0h,080h,080h	; a137  ................
	defb 00eh,00eh,01ch,01fh,010h,030h,020h,000h,000h,003h,07fh,0ffh,00fh,000h,000h,000h	; a147  .....0 .........
	defb 000h,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0e0h,0ffh,0fch,080h,000h,000h,000h	; a157  ................
	defb 000h,000h,0f8h,000h,000h,000h,007h,01fh,000h,000h,000h,000h,00fh,07fh,0ffh,0ffh	; a167  ................
	defb 000h,000h,003h,0ffh,0ffh,0ffh,0ffh,080h,000h,00fh,0ffh,0ffh,0ffh,0ffh,080h,000h	; a177  ................
	defb 03fh,0ffh,0ffh,0ffh,0ffh,0feh,000h,000h,0ffh,0ffh,0ffh,0ffh,0fch,000h,000h,000h	; a187  ?...............
	defb 0f8h,0f0h,0e0h,080h,000h,000h,000h,000h,03fh,03fh,01fh,01fh,00eh,004h,000h,000h	; a197  ........??......
	defb 0e1h,0c3h,087h,00fh,01fh,000h,000h,000h,0fch,0ffh,0ffh,0ffh,0f0h,000h,000h,000h	; a1a7  ................
	defb 000h,0f0h,0feh,0ffh,07fh,007h,000h,000h,01fh,019h,010h,0c0h,0feh,0ffh,07fh,000h	; a1b7  ................
	defb 0ffh,0ffh,07fh,000h,000h,0e0h,0ffh,07fh,0ffh,0ffh,0f0h,000h,000h,000h,000h,0ffh	; a1c7  ................
	defb 0feh,03eh,03ch,070h,040h,000h,000h,0e0h,07eh,03fh,01fh,00fh,007h,001h,000h,000h	; a1d7  .><p@...~?......
	defb 000h,000h,080h,0c0h,0e0h,0f0h,0fch,01fh,000h,000h,000h,001h,001h,000h,000h,000h	; a1e7  ................
	defb 0c0h,080h,080h,000h,000h,000h,000h,000h,010h,020h,000h,000h,000h,000h,000h,000h	; a1f7  ......... ......
	defb 007h,00fh,00ch,00ch,008h,018h,010h,010h,0e0h,000h,000h,000h,000h,000h,000h,000h	; a207  ................
	defb 000h,000h,000h,000h,007h,018h,060h,080h,000h,007h,01fh,0f0h,000h,000h,000h,000h	; a217  ......`.........
	defb 0ffh,0f0h,000h,000h,000h,000h,000h,000h,0ffh,000h,000h,000h,000h,000h,000h,000h	; a227  ................
	defb 030h,020h,020h,000h,000h,000h,000h,000h,006h,00ch,030h,060h,000h,000h,000h,000h	; a237  0  .......0`....
	defb 000h,024h,024h,028h,030h,028h,024h,024h,000h,018h,024h,024h,024h,024h,024h,018h	; a247  .$$(0($$..$$$$$.
	defb 000h,024h,034h,034h,02ch,02ch,024h,024h,000h,018h,024h,024h,03ch,024h,024h,024h	; a257  .$44,,$$..$$<$$$
	defb 000h,024h,024h,03ch,024h,024h,024h,024h,003h,013h,011h,012h,010h,010h,010h,010h	; a267  .$$<$$$$........
	defb 000h,018h,024h,020h,018h,004h,024h,018h,000h,022h,022h,014h,008h,008h,008h,008h	; a277  ..$ ..$.."".....
	defb 000h,03eh,008h,008h,008h,008h,008h,008h,000h,024h,024h,024h,03ch,024h,024h,024h	; a287  .>.......$$$<$$$
	defb 000h,010h,010h,010h,010h,010h,010h,010h,000h,03ch,004h,008h,018h,010h,020h,03ch	; a297  .........<.... <
	defb 000h,03ch,020h,020h,038h,020h,020h,03ch,000h,038h,024h,024h,038h,024h,024h,024h	; a2a7  .<  8  <.8$$8$$$
	defb 00fh,000h,000h,000h,000h,000h,000h,000h	; a2b7  ........

; ----------------------------------------------------------------------
; DATOS titulo_colores: flujo RLE de 0x4327 hacia 0x0200, los colores del
;   logotipo
;   0xa2bf..0xa2e5  (38 bytes)
DATA_titulo_colores:
	defb 00dh,000h,081h,060h,007h,000h,082h,060h,080h,007h,000h,082h,080h,090h,007h,000h	; a2bf  ...`...`........
	defb 082h,090h,0a0h,007h,000h,083h,0a0h,0b0h,0f0h,007h,000h,081h,0f0h,003h,070h,006h	; a2cf  ..............p.
	defb 000h,002h,070h,002h,070h,000h	; a2df

; ----------------------------------------------------------------------
; DATOS titulo_nombres_logo: flujo RLE de 0x4352 hacia 0x3840
;   0xa2e5..0xa3aa  (197 bytes)
DATA_titulo_nombres_logo:
	defb 040h,038h,014h,000h,084h,044h,043h,042h,041h,019h,000h,085h,049h,048h,047h,046h	; a2e5  @8...DCBA...IHGF
	defb 045h,018h,000h,085h,04eh,04dh,04ch,04bh,04ah,011h,000h,08ch,04fh,050h,000h,051h	; a2f5  E...NMLKJ...OP.Q
	defb 052h,053h,054h,055h,000h,056h,057h,058h,004h,000h,081h,059h,003h,000h,081h,05ah	; a305  RSTU.VWX...Y...Z
	defb 00ah,000h,09bh,05bh,05ch,05dh,05eh,05fh,060h,061h,062h,063h,064h,065h,066h,067h	; a315  ...[\]^_`abcdefg
	defb 068h,069h,06ah,06bh,06ch,06eh,06fh,070h,071h,072h,073h,074h,075h,076h,005h,000h	; a325  hijklnopqrstuv..
	defb 09ah,077h,078h,079h,07ah,07bh,07ch,07dh,07eh,07fh,080h,081h,082h,083h,084h,085h	; a335  .wxyz{|}~.......
	defb 086h,087h,088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h,006h,000h,09bh,091h,092h	; a345  ................
	defb 093h,094h,095h,096h,097h,098h,099h,09ah,09bh,09ch,09dh,09eh,09fh,0a0h,0a1h,0a2h	; a355  ................
	defb 0a3h,0a4h,0a5h,0a6h,0a7h,0a8h,000h,0a9h,0aah,005h,000h,08ah,0abh,0ach,0adh,0aeh	; a365  ................
	defb 000h,000h,04eh,0b0h,0b1h,0b2h,00ch,000h,086h,0c4h,0b3h,0afh,000h,06dh,0b3h,004h	; a375  ..N..........m..
	defb 000h,003h,0b3h,085h,0b4h,0b3h,0b3h,0b5h,000h,014h,0b3h,008h,000h,094h,0b6h,0b7h	; a385  ................
	defb 0b8h,0b9h,0bah,0bbh,0bch,000h,000h,0bch,0bdh,0b8h,0beh,0bfh,0c2h,0bch,0c0h,0c1h	; a395  ................
	defb 0c2h,0c3h,006h,000h,000h	; a3a5

; ----------------------------------------------------------------------
; DATOS timbres_de_fabrica: 16 timbres de 32 bytes: parametros y nombre de 8
;   letras (0x21 = A, 0x41 = 1)
;   0xa3aa..0xa5aa  (512 bytes)
DATA_timbres_de_fabrica:
	defb 001h,004h,000h,000h,000h,000h,000h,080h,000h,000h,000h,000h,000h,000h,004h,020h,060h,000h,000h,0ffh,00ch,000h,000h,010h	; a3aa  ............... `.......
	defb 002h,025h,022h,021h,033h,033h,041h,000h	; a3c2  .%"!33A.
	defb 00dh,002h,000h,000h,000h,000h,000h,080h	; a3ca  ........
	defb 000h,000h,000h,000h,000h,000h,004h,020h	; a3d2  ....... 
	defb 060h,000h,000h,0ffh,00ch,000h,000h,010h	; a3da  `.......
	defb 002h,025h,022h,021h,033h,033h,042h,000h	; a3e2  .%"!33B.
	defb 001h,008h,000h,000h,014h,000h,000h,080h	; a3ea  ........
	defb 000h,000h,000h,000h,000h,001h,006h,040h	; a3f2  .......@
	defb 004h,000h,000h,0ffh,00fh,000h,000h,010h	; a3fa  ........
	defb 002h,022h,032h,021h,033h,033h,000h,000h	; a402  ."2!33..
	defb 00bh,008h,000h,000h,014h,000h,000h,080h	; a40a  ........
	defb 000h,000h,000h,000h,000h,001h,006h,040h	; a412  .......@
	defb 004h,000h,000h,0ffh,00fh,000h,000h,010h	; a41a  ........
	defb 002h,034h,032h,035h,02dh,030h,025h,034h	; a422  .425-0%4
	defb 001h,010h,000h,000h,0b4h,000h,000h,04bh	; a42a  .......K
	defb 000h,000h,000h,000h,000h,000h,004h,064h	; a432  .......d
	defb 00ah,003h,004h,0dch,006h,000h,000h,010h	; a43a  ........
	defb 002h,033h,034h,032h,029h,02eh,027h,033h	; a442  .342).'3
	defb 008h,008h,000h,000h,0ffh,000h,000h,000h	; a44a  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a452  ........
	defb 000h,000h,000h,0ffh,001h,000h,000h,010h	; a45a  ........
	defb 002h,025h,02fh,032h,027h,021h,02eh,000h	; a462  .%/2'!..
	defb 005h,008h,000h,000h,0ffh,000h,000h,000h	; a46a  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a472  ........
	defb 000h,000h,000h,0ffh,001h,000h,000h,010h	; a47a  ........
	defb 002h,030h,02fh,032h,027h,021h,02eh,000h	; a482  .0/2'!..
	defb 007h,008h,000h,000h,0ffh,000h,000h,000h	; a48a  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a492  ........
	defb 000h,000h,000h,0ffh,014h,000h,000h,010h	; a49a  ........
	defb 082h,025h,030h,029h,021h,02eh,02fh,000h	; a4a2  .%0)!./.
	defb 006h,004h,000h,000h,064h,000h,000h,064h	; a4aa  ....d..d
	defb 000h,000h,000h,000h,000h,000h,004h,000h	; a4b2  ........
	defb 000h,000h,000h,0ffh,014h,000h,000h,010h	; a4ba  ........
	defb 082h,027h,02ch,02fh,023h,02bh,025h,02eh	; a4c2  .',/#+%.
	defb 00ah,008h,002h,000h,000h,000h,000h,080h	; a4ca  ........
	defb 000h,000h,000h,000h,000h,000h,004h,030h	; a4d2  .......0
	defb 080h,000h,004h,0e0h,020h,000h,000h,002h	; a4da  .... ...
	defb 082h,02bh,02fh,034h,02fh,000h,000h,000h	; a4e2  .+/4/...
	defb 000h,004h,000h,080h,0ffh,000h,000h,000h	; a4ea  ........
	defb 000h,000h,001h,000h,000h,000h,000h,000h	; a4f2  ........
	defb 000h,000h,001h,0efh,008h,000h,000h,010h	; a4fa  ........
	defb 082h,023h,02fh,02eh,027h,021h,000h,000h	; a502  .#/.'!..
	defb 000h,008h,000h,0ffh,0ffh,000h,000h,000h	; a50a  ........
	defb 000h,000h,001h,0c0h,014h,000h,000h,000h	; a512  ........
	defb 000h,000h,001h,0c0h,014h,000h,000h,010h	; a51a  ........
	defb 082h,033h,039h,02eh,024h,032h,035h,02dh	; a522  .39.$25-
	defb 000h,008h,0ffh,0ffh,0ffh,000h,000h,000h	; a52a  ........
	defb 000h,020h,000h,0ffh,020h,000h,000h,000h	; a532  . .. ...
	defb 000h,002h,000h,0ffh,040h,000h,000h,080h	; a53a  ....@...
	defb 082h,029h,02dh,021h,027h,025h,000h,000h	; a542  .)-!'%..
	defb 003h,020h,060h,000h,0ffh,000h,000h,000h	; a54a  . `.....
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a552  ........
	defb 000h,000h,004h,0e0h,020h,004h,00fh,010h	; a55a  .... ...
	defb 082h,030h,021h,032h,023h,041h,000h,000h	; a562  .0!2#A..
	defb 000h,010h,0ffh,000h,0ffh,000h,000h,000h	; a56a  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a572  ........
	defb 000h,000h,004h,0f0h,020h,000h,000h,080h	; a57a  .... ...
	defb 082h,030h,021h,032h,023h,042h,000h,000h	; a582  .0!2#B..
	defb 000h,008h,000h,000h,0ffh,000h,000h,000h	; a58a  ........
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; a592  ........
	defb 000h,000h,000h,0ffh,000h,000h,000h,010h	; a59a  ........
	defb 002h,000h,000h,000h,000h,000h,000h,000h	; a5a2  ........

; ======================================================================
; CODIGO 0xa5aa..0xa92a  (896 bytes)
; ======================================================================


pantalla_tone_edit:		; TONE EDIT: el cursor parpadea; segun 0xD8FA prepara la pantalla o edita el campo de 0xDB01
	ld b,008h		;a5aa   ; color 8 del cursor...
	ld a,(0d803h)		;a5ac   ; ...o 12, cada 16 cuadros
	and 010h		;a5af
	jr nz,L_A5B5		;a5b1
	ld b,00ch		;a5b3
L_A5B5:
	ld a,b			;a5b5
	ld (0d873h),a		;a5b6   ; al sprite del cursor
	ld a,(0d8fah)		;a5b9   ; el estado de la pantalla:
	dec a			;a5bc
	jp z,tone_edit_estado_1		;a5bd   ; 1: 0xACDA
	jp m,tone_edit_estado_0		;a5c0   ; 0: la pantalla fija
	cp 001h		;a5c3
	jp z,tone_edit_estado_2		;a5c5   ; 2: 0xAD31
	ld a,(0d802h)		;a5c8   ; solo con el programa en marcha
	and 040h		;a5cb
	ret z			;a5cd
	ld b,000h		;a5ce
	ld a,(0d808h)		;a5d0   ; el byte de teclas con repeticion
	rra			;a5d3   ; arriba: B = 0
	jr nc,L_A5D9		;a5d4
	ld a,b			;a5d6
	jr L_A5EA		;a5d7
L_A5D9:
	inc b			;a5d9
	rra			;a5da   ; abajo: 1
	jr c,L_A5E5		;a5db
	inc b			;a5dd
	rra			;a5de   ; izquierda: 2
	jr c,L_A5E5		;a5df
	inc b			;a5e1
	rra			;a5e2   ; derecha: 3; ninguna, a editar
	jr nc,edita_campo		;a5e3
L_A5E5:
	xor a			;a5e5
L_A5E6:
	add a,01eh		;a5e6   ; 0x1E entradas por direccion
	djnz L_A5E6		;a5e8
L_A5EA:
	ld hl,0db01h		;a5ea   ; mas el campo
	ld b,(hl)			;a5ed
	add a,b			;a5ee
	ld de,0ac26h		;a5ef   ; el campo vecino en 0xAC26
	call de_mas_a		;a5f2
	ld a,(de)			;a5f5
	cp (hl)			;a5f6   ; el mismo: no se mueve
	jr z,edita_campo		;a5f7
	ld (hl),a			;a5f9   ; el campo nuevo
	sla a		;a5fa   ; su sitio para el cursor en 0xAC9E
	ld de,0ac9eh		;a5fc
	call de_mas_a		;a5ff
	ld b,002h		;a602   ; los dos sprites del cursor
	ld hl,0d870h		;a604
L_A607:
	ld a,(de)			;a607   ; Y...
	ld (hl),a			;a608
	inc de			;a609
	inc hl			;a60a
	ld a,(de)			;a60b   ; ...y X
	ld (hl),a			;a60c
	dec de			;a60d
	inc hl			;a60e
	inc hl			;a60f
	inc hl			;a610
	djnz L_A607		;a611
	ld a,001h		;a613   ; el efecto 1
	call efecto		;a615
	ld hl,0a9b3h		;a618   ; el modo de escritura del campo (0xA9B3)...
	ld a,(0db01h)		;a61b
	dec a			;a61e
	call hl_mas_a		;a61f
	ld a,(hl)			;a622
	ld de,0db06h		;a623   ; ...a 0xDB06 y 0xDB07
	ld (de),a			;a626
	inc de			;a627
	ld (de),a			;a628
edita_campo:		; edita el campo 0xDB01 del timbre en curso
	xor a			;a629   ; los sprites 2, 3 y 4 sin color
	ld (0d87bh),a		;a62a
	ld (0d87fh),a		;a62d
	ld (0d883h),a		;a630
	call timbre_en_curso		;a633   ; HL = el timbre en curso
	ld a,(0d808h)		;a636   ; C = las teclas
	ld c,a			;a639
	ld a,(0db01h)		;a63a
	cp 001h		;a63d   ; campo 0: el nombre
	jp c,campo_nombre		;a63f
	push af			;a642
	xor a			;a643   ; 0xDB03 = 0
	ld (0db03h),a		;a644
	pop af			;a647
	cp 015h		;a648   ; campos 1-20: valores
	jp c,campo_valor		;a64a
	cp 019h		;a64d   ; 21-24: conmutadores
	jp c,campo_conmutador		;a64f
	cp 01bh		;a652   ; 25-26: las ondas
	jp c,campo_onda		;a654
	cp 01ch		;a657   ; 27: FEET del DCO
	jr c,campo_feet_dco		;a659
	cp 01dh		;a65b   ; 29: 0xAC08
	jp z,campo_29		;a65d
	ld a,017h		;a660   ; 28: FEET del LFO, el byte 23
	call hl_mas_a		;a662
	ld a,(0db02h)		;a665   ; sin escribir cifras...
	or a			;a668
	jr nz,L_A693		;a669
	ld a,(0db08h)		;a66b
	or a			;a66e
	jr nz,L_A693		;a66f
	ld c,001h		;a671   ; ...el paso es 1...
	ld a,(0db04h)		;a673
	or a			;a676
	jr z,L_A67B		;a677
	ld c,010h		;a679   ; ...o 0x10 con 0xDB04
L_A67B:
	ld a,(0d8f3h)		;a67b   ; INS o DEL
	cp 044h		;a67e
	jr z,L_A68D		;a680
	cp 043h		;a682
	jr nz,L_A693		;a684
	ld a,(hl)			;a686   ; INS: suma...
	add a,c			;a687
	jr nz,L_A692		;a688   ; ...sin llegar a 0
	sub c			;a68a
	jr L_A692		;a68b
L_A68D:
	ld a,(hl)			;a68d   ; DEL: resta...
	sub c			;a68e
	jr nz,L_A692		;a68f   ; ...sin llegar a 0
	add a,c			;a691
L_A692:
	ld (hl),a			;a692
L_A693:
	ld a,(0db04h)		;a693   ; con 0xDB04 solo el nibble alto, al menos 0x10
	or a			;a696
	jr z,L_A6A3		;a697
	ld a,(hl)			;a699
	and 0f0h		;a69a
	jr nz,L_A6A0		;a69c
	ld a,010h		;a69e
L_A6A0:
	ld (hl),a			;a6a0
	jr L_A6A4		;a6a1
L_A6A3:
	ld a,(hl)			;a6a3
L_A6A4:
	ld c,a			;a6a4   ; 1024000 / el valor (0x0FA000)...
	ld b,000h		;a6a5
	ld de,0a000h		;a6a7
	ld a,00fh		;a6aa
	call pies		;a6ac
	ld hl,0393ch		;a6af   ; ...dos cifras en 0x393C...
	ld b,002h		;a6b2
	ld de,0dbf0h		;a6b4
	call cifras		;a6b7
	dec hl			;a6ba   ; ...y cuatro delante
	ld b,004h		;a6bb
	ld de,0dbf1h		;a6bd
	jp cifras		;a6c0
campo_feet_dco:		; FEET del DCO (byte 1): INS lo dobla hasta 0x20, DEL lo parte hasta 1; 64000 / valor en 0x38C5
	inc hl			;a6c3   ; el byte 1
	ld a,(0db02h)		;a6c4
	or a			;a6c7
	jr nz,L_A6E5		;a6c8
	ld a,(0d8f3h)		;a6ca   ; INS o DEL
	cp 044h		;a6cd
	jr z,L_A6DE		;a6cf
	cp 043h		;a6d1
	ret nz			;a6d3
	ld a,(hl)			;a6d4   ; INS: por dos...
	add a,a			;a6d5
	cp 040h		;a6d6   ; ...como mucho 0x20
	jr c,L_A6E4		;a6d8
	ld a,020h		;a6da
	jr L_A6E4		;a6dc
L_A6DE:
	ld a,(hl)			;a6de   ; DEL: la mitad...
	rra			;a6df
	jr nc,L_A6E4		;a6e0   ; ...como poco 1
	ld a,001h		;a6e2
L_A6E4:
	ld (hl),a			;a6e4
L_A6E5:
	ld a,(hl)			;a6e5   ; 64000 / el valor...
	ld c,a			;a6e6
	ld b,000h		;a6e7
	ld de,0fa00h		;a6e9
	xor a			;a6ec
	call pies		;a6ed
	ld hl,038c5h		;a6f0   ; ...dos cifras en 0x38C5
	ld b,002h		;a6f3
	ld de,0dbf1h		;a6f5
	jp cifras		;a6f8
pies:		; 0xDBF0-0xDBF3 = el cociente de A:DE entre BC en BCD, redondeado a la decena y sin la ultima cifra
	call divide_24		;a6fb   ; la division de 24 bits
	ld l,e			;a6fe
	ld h,d			;a6ff
	ld e,a			;a700
	call a_bcd_24		;a701   ; a BCD
	ld hl,0dbf4h		;a704   ; los cuatro bytes, el bajo primero
	ld (hl),000h		;a707
	dec hl			;a709
	ld (hl),b			;a70a
	dec hl			;a70b
	ld (hl),c			;a70c
	dec hl			;a70d
	ld (hl),d			;a70e
	dec hl			;a70f
	ld (hl),e			;a710
	ld a,e			;a711   ; la ultima cifra 5 o mas...
	and 00fh		;a712
	cp 005h		;a714
	jr c,L_A72B		;a716
	ld a,010h		;a718   ; ...sube una decena...
	add a,(hl)			;a71a
	daa			;a71b
	ld (hl),a			;a71c
	jr nc,L_A72B		;a71d
	ld b,003h		;a71f   ; ...con el acarreo
L_A721:
	inc hl			;a721   ; la cifra siguiente...
	ld a,001h		;a722   ; ...+ 1...
	add a,(hl)			;a724
	daa			;a725   ; ...en BCD
	ld (hl),a			;a726
	jr nc,L_A72B		;a727
	djnz L_A721		;a729
L_A72B:
	ld hl,0dbf0h		;a72b   ; y se quita la ultima cifra
	ld b,004h		;a72e
L_A730:
	inc hl			;a730   ; cada byte...
	ld a,(hl)			;a731
	dec hl			;a732
	rrd		;a733   ; ...una cifra a la derecha
	inc hl			;a735
	djnz L_A730		;a736
	ret			;a738
campo_nombre:		; el nombre, siete letras: letras y cifras escriben, ESPACIO pone un espacio, BS vuelve atras
	ld a,(0db02h)		;a739
	or a			;a73c
	ret nz			;a73d
	ld b,06fh		;a73e   ; el sprite del cursor de letra...
	jr L_A744		;a740
cursor_de_letra_67:		; lo mismo con X base 0x67
	ld b,067h		;a742
L_A744:
	ld de,0db03h		;a744   ; 0xDB03 = la letra en curso
	ld a,(de)			;a747
	add a,a			;a748   ; X = base + 8 * letra
	add a,a			;a749
	add a,a			;a74a
	add a,b			;a74b
	ld (0d881h),a		;a74c
	ld a,(0d870h)		;a74f   ; Y del cursor
	ld (0d880h),a		;a752
	ld a,(0db17h)		;a755   ; 0xDB17: el nombre del fichero en vez del timbre
	or a			;a758
	jr z,L_A766		;a759
	ld a,05dh		;a75b
	ld (0d880h),a		;a75d
	ld hl,0db0fh		;a760   ; HL = 0xDB0F
	ld a,(de)			;a763
	jr L_A76E		;a764
L_A766:
	ld a,008h		;a766   ; el del timbre: bytes 25-31
	ld (0d883h),a		;a768
	ld a,(de)			;a76b
	add a,019h		;a76c
L_A76E:
	call hl_mas_a		;a76e
	ld a,(0d8f1h)		;a771   ; la tecla nueva
	or a			;a774
	jr z,L_A792		;a775
	cp 031h		;a777   ; de 0x31 en adelante, no
	jr nc,L_A792		;a779
	cp 017h		;a77b   ; letras (0x17-0x30)...
	jr nc,L_A788		;a77d
	cp 00bh		;a77f   ; ...cifras (1-10)...
	jr nc,L_A792		;a781
	dec a			;a783   ; ...a los tiles 0x40-0x49
	add a,040h		;a784
	jr L_A78C		;a786
L_A788:
	sub 017h		;a788   ; las letras a los tiles 0x21-0x3A
	add a,021h		;a78a
L_A78C:
	ld (hl),a			;a78c   ; a la letra en curso...
	call letra_siguiente		;a78d   ; ...y a la siguiente
	jr L_A7B8		;a790
L_A792:
	ld a,(0d8f3h)		;a792   ; BS (0x3E): atras
	cp 03eh		;a795
	jr z,letra_anterior		;a797
	ld a,(0d806h)		;a799   ; ESPACIO...
	and 010h		;a79c
	jr z,L_A7B7		;a79e
	ld (hl),020h		;a7a0   ; ...un espacio
	call letra_siguiente		;a7a2
	jr L_A7B8		;a7a5
letra_siguiente:		; 0xDB03 + 1, de 0 a 6
	ex de,hl			;a7a7
	inc (hl)			;a7a8   ; la letra siguiente
	ld a,(hl)			;a7a9
	cp 007h		;a7aa   ; hasta la 6
	jr c,L_A7B0		;a7ac
	ld (hl),000h		;a7ae   ; y vuelta a la 0
L_A7B0:
	ex de,hl			;a7b0
	ret			;a7b1
letra_anterior:		; 0xDB03 - 1, de 6 a 0
	ex de,hl			;a7b2
	dec (hl)			;a7b3
	ret p			;a7b4
	ld (hl),006h		;a7b5
L_A7B7:
	ret			;a7b7
L_A7B8:
	jp nombre_del_timbre		;a7b8
suma_cifra:		; el valor + cifra * E
	dec a			;a7bb   ; la cifra
	push de			;a7bc
	push hl			;a7bd
	call por_e		;a7be   ; L = cifra * E
	pop hl			;a7c1
	pop de			;a7c2
	push de			;a7c3
	push hl			;a7c4
	call suma_con_maximo		;a7c5   ; a lo que habia
	pop hl			;a7c8
	pop de			;a7c9
	ret			;a7ca
por_e:		; L = A * E, 0xFF si pasa de un byte
	ld h,a			;a7cb
	call por_8		;a7cc   ; HL = A * E
	ld a,h			;a7cf
	or a			;a7d0   ; pasa de 255?
	jr z,L_A7D5		;a7d1
	ld l,0ffh		;a7d3   ; si: 0xFF
L_A7D5:
	ld a,l			;a7d5
	ret			;a7d6
campo_valor:		; campos 1-20: la cifra tecleada o INS/DEL, con el maximo de 0xA98B, y el valor en pantalla
	inc hl			;a7d7   ; HL = el byte 2 + campo - 1
	inc hl			;a7d8
	ld a,(0db01h)		;a7d9
	ld b,a			;a7dc
	dec a			;a7dd
	call hl_mas_a		;a7de
	ld c,000h		;a7e1
	ld a,b			;a7e3
	call campo_con_off		;a7e4   ; el campo admite OFF? (0xA92D)
	jr nc,L_A7F0		;a7e7
	ld a,(0db04h)		;a7e9
	or a			;a7ec
	jp nz,campo_off		;a7ed
L_A7F0:
	ld a,(0db02h)		;a7f0   ; sin escribir cifras
	or a			;a7f3
	jp nz,campo_en_pantalla		;a7f4
	call cursor_de_valor		;a7f7   ; 0xA94C
	ld a,(0db01h)		;a7fa   ; el maximo del campo (0xA98B)...
	dec a			;a7fd
	ld de,0a98bh		;a7fe
	call de_mas_a		;a801
	ld a,(de)			;a804
	ld c,a			;a805
	ld (0db1bh),a		;a806   ; ...en 0xDB1B; 0 = 0xFF
	ld a,(0d8f1h)		;a809   ; una cifra (codigos 1-10)?
	or a			;a80c
	jr z,campo_ins_del		;a80d
	cp 00bh		;a80f
	jr nc,campo_ins_del		;a811
	ld a,(0db06h)		;a813   ; 0xDB06: cuantas cifras faltan
	ld (hl),000h		;a816   ; la primera borra el valor
	ld de,0db19h		;a818
	dec a			;a81b
	jr z,L_A858		;a81c
	jp p,L_A864		;a81e
	ld a,(de)			;a821   ; centenas pendientes...
	or a			;a822
	jr z,L_A82C		;a823
	push de			;a825
	ld e,064h		;a826   ; ...por 100
	call suma_cifra		;a828
	pop de			;a82b
L_A82C:
	inc de			;a82c
	ld a,(de)			;a82d   ; decenas pendientes...
	or a			;a82e
	jr z,L_A838		;a82f
	push de			;a831
	ld e,00ah		;a832   ; ...por 10
	call suma_cifra		;a834
	pop de			;a837
L_A838:
	ld a,(0d8f1h)		;a838   ; y las unidades
L_A83B:
	dec a			;a83b
	call suma_con_maximo		;a83c
	ld de,0db06h		;a83f   ; una cifra menos
	ld a,(de)			;a842
	dec a			;a843
	jp p,L_A854		;a844
	ld b,002h		;a847   ; la ultima: las pendientes a cero...
	ld hl,0db19h		;a849
L_A84C:
	ld (hl),000h		;a84c
	inc hl			;a84e
	djnz L_A84C		;a84f
	inc de			;a851   ; ...y vuelve a empezar
	ld a,(de)			;a852
	dec de			;a853
L_A854:
	ld (de),a			;a854
	jp cursor_de_valor		;a855
L_A858:
	ld a,(de)			;a858   ; decenas pendientes
	or a			;a859
	jr z,L_A863		;a85a
	push de			;a85c
	ld e,00ah		;a85d
	call suma_cifra		;a85f
	pop de			;a862
L_A863:
	inc de			;a863
L_A864:
	ld a,(0d8f1h)		;a864   ; apunta la cifra
	ld (de),a			;a867
	jr L_A83B		;a868
suma_con_maximo:		; (HL) + A, como mucho el maximo C (o 0xFF)
	ex af,af'			;a86a
	ld a,(0db1bh)		;a86b   ; el maximo
	ld c,a			;a86e
	or a			;a86f   ; sin maximo:
	jr nz,L_A87A		;a870
	ex af,af'			;a872
	add a,(hl)			;a873   ; suma...
	jr nc,L_A880		;a874
	ld a,0ffh		;a876   ; ...como mucho 0xFF
	jr L_A880		;a878
L_A87A:
	ex af,af'			;a87a
	add a,(hl)			;a87b
	cp c			;a87c
	jr c,L_A880		;a87d
	ld a,c			;a87f
L_A880:
	ld (hl),a			;a880
	jr campo_en_pantalla		;a881
campo_ins_del:		; INS suma 1 hasta el maximo; DEL resta 1 hasta 0
	ld a,(0db1bh)		;a883
	ld c,a			;a886
	ld a,(0d8f3h)		;a887   ; INS o DEL
	cp 043h		;a88a
	jr z,L_A8A6		;a88c
	cp 044h		;a88e
	jr nz,campo_en_pantalla		;a890
	ld a,c			;a892
	or a			;a893
	jr z,L_A89D		;a894
	dec (hl)			;a896   ; DEL con maximo
	jp p,campo_en_pantalla		;a897
	inc (hl)			;a89a
	jr campo_en_pantalla		;a89b
L_A89D:
	dec (hl)			;a89d   ; DEL sin maximo
	ld a,(hl)			;a89e
	cp 0ffh		;a89f
	jr nz,campo_en_pantalla		;a8a1
	inc (hl)			;a8a3
	jr campo_en_pantalla		;a8a4
L_A8A6:
	ld a,c			;a8a6   ; INS con maximo
	or a			;a8a7
	jr z,L_A8B1		;a8a8
	ld a,(hl)			;a8aa
	cp c			;a8ab
	jr nc,campo_en_pantalla		;a8ac
	inc (hl)			;a8ae
	jr campo_en_pantalla		;a8af
L_A8B1:
	inc (hl)			;a8b1   ; INS sin maximo
	jr nz,campo_en_pantalla		;a8b2
	dec (hl)			;a8b4
	jr campo_en_pantalla		;a8b5
campo_off:		; con 0xDB04, OFF
	push hl			;a8b7
	ld a,(0db04h)		;a8b8
	or a			;a8bb
	jr nz,pinta_off		;a8bc
	jr L_A8C1		;a8be
campo_en_pantalla:		; el valor en tres cifras (0xA9C7) y su barra (0xA9EF)
	push hl			;a8c0
L_A8C1:
	ld l,(hl)			;a8c1   ; a decimal
	call a_decimal		;a8c2
	ld hl,0dbf0h		;a8c5   ; a 0xDBF0
	push hl			;a8c8
	ld (hl),e			;a8c9
	inc hl			;a8ca
	ld (hl),d			;a8cb
	ld hl,0a9c7h		;a8cc   ; la direccion de las cifras del campo
	call palabra_del_campo		;a8cf
	ex de,hl			;a8d2
	pop de			;a8d3
	ld b,003h		;a8d4   ; tres cifras
	call cifras		;a8d6
L_A8D9:
	ld hl,0a9efh		;a8d9   ; la direccion de su barra
	call palabra_del_campo		;a8dc
	ld a,(0db01h)		;a8df   ; cuanto se corre el valor (0xA99F)
	dec a			;a8e2
	ld hl,0a99fh		;a8e3
	call hl_mas_a		;a8e6
	ld b,(hl)			;a8e9
	ld a,b			;a8ea
	or a			;a8eb
	jr nz,L_A8F3		;a8ec   ; 0: el valor por dos
	pop hl			;a8ee
	ld a,(hl)			;a8ef
	add a,a			;a8f0
	jr L_A8FC		;a8f1
L_A8F3:
	pop hl			;a8f3
	ld a,(hl)			;a8f4
	or a			;a8f5
	jr z,L_A900		;a8f6
L_A8F8:
	srl a		;a8f8   ; el valor corrido B veces
	djnz L_A8F8		;a8fa
L_A8FC:
	or a			;a8fc   ; si no es cero, al menos 1
	jr nz,L_A900		;a8fd
	inc a			;a8ff
L_A900:
	ld hl,0aa17h		;a900   ; la barra de cuatro tiles de 0xAA17...
	ld bc,00004h		;a903
	or a			;a906
	jr z,L_A90D		;a907
L_A909:
	add hl,bc			;a909   ; ...la entrada A
	dec a			;a90a
	jr nz,L_A909		;a90b
L_A90D:
	ex de,hl			;a90d   ; a la VRAM
	ld bc,00004h		;a90e
	jp copia_a_vram		;a911
pinta_off:		; valor 0 y los tres tiles de OFF (0xA92A) delante de las cifras
	ld (hl),000h		;a914   ; el valor a cero
	ld hl,0a9c7h		;a916   ; donde van sus cifras
	call palabra_del_campo		;a919
	ex de,hl			;a91c
	ld de,0a92ah		;a91d   ; los tres tiles de OFF...
	ld bc,00003h		;a920
	dec hl			;a923   ; ...dos tiles antes
	dec hl			;a924
	call copia_a_vram		;a925
	jr L_A8D9		;a928   ; y la barra

; ----------------------------------------------------------------------
; DATOS tiles_flecha: 3 tiles que copia 0xA928
;   0xa92a..0xa92d  (3 bytes)
DATA_tiles_flecha:
	defb 095h,096h,096h	; a92a

; ======================================================================
; CODIGO 0xa92d..0xa947  (26 bytes)
; ======================================================================


campo_con_off:		; acarreo si el campo A esta en la lista de 0xA947 (los que dicen OFF con 0)
	push bc			;a92d
	exx			;a92e   ; en los alternativos
	pop bc			;a92f
	ld b,a			;a930   ; B = el campo
	ld a,c			;a931
	ld hl,0a947h		;a932   ; la lista de 0xA947
	call hl_mas_a		;a935
L_A938:
	ld a,(hl)			;a938   ; la lista, hasta 0xFF
	inc a			;a939
	jr z,L_A944		;a93a
	inc hl			;a93c
	dec a			;a93d
	cp b			;a93e
	jr nz,L_A938		;a93f
	scf			;a941   ; esta: acarreo
	exx			;a942
	ret			;a943
L_A944:
	xor a			;a944   ; no esta
	exx			;a945
	ret			;a946

; ----------------------------------------------------------------------
; DATOS limites_del_cursor: 4 valores acabados en 0xFF (0xA932)
;   0xa947..0xa94c  (5 bytes)
DATA_limites_del_cursor:
	defb 001h,00ah,00bh,014h,0ffh	; a947

; ======================================================================
; CODIGO 0xa94c..0xa98b  (63 bytes)
; ======================================================================


cursor_de_valor:		; los sprites 2 y 3 junto al campo, con color 8
	ld a,(0d870h)		;a94c   ; Y del cursor - 1
	dec a			;a94f
	ld (0d878h),a		;a950
	ld (0d87ch),a		;a953
	ld a,(0d871h)		;a956   ; X - 0x3A...
	sub 03ah		;a959
	ld (0d879h),a		;a95b
	add a,010h		;a95e   ; ...y 0x10 mas alla
	ld (0d87dh),a		;a960
	ld a,008h		;a963   ; color 8
	ld (0d87bh),a		;a965
	ld (0d87fh),a		;a968
	ret			;a96b
palabra_del_campo:		; DE = la palabra (0xDB01 - 1) de la tabla HL
	ld a,(0db01h)		;a96c   ; el campo...
	dec a			;a96f
	rlca			;a970   ; ...por dos
	call hl_mas_a		;a971
	ld e,(hl)			;a974   ; DE = su palabra
	inc hl			;a975
	ld d,(hl)			;a976
	ret			;a977
a_decimal:		; DE = L en BCD
	ld bc,00800h		;a978   ; 8 bits
	ld de,00000h		;a97b
L_A97E:
	sla l		;a97e   ; el bit alto de L...
	ld a,e			;a980   ; ...entra en E por la derecha, en BCD...
	adc a,a			;a981
	daa			;a982
	ld e,a			;a983
	ld a,d			;a984   ; ...con el acarreo a D
	adc a,a			;a985
	daa			;a986
	ld d,a			;a987
	djnz L_A97E		;a988
	ret			;a98a

; ----------------------------------------------------------------------
; DATOS tablas_de_tone_edit: posiciones y valores de los campos de TONE EDIT
;   (0xA5F5-0xAB1F)
;   0xa98b..0xaa5b  (208 bytes)
DATA_tablas_de_tone_edit:
	defb 000h,000h,000h,008h,080h,080h,040h,080h,080h,000h,080h,080h,080h,000h,080h,080h	; a98b  ......@.........
	defb 080h,000h,080h,000h,004h,004h,004h,000h,003h,003h,002h,003h,003h,004h,003h,003h	; a99b  ................
	defb 003h,004h,003h,003h,003h,004h,003h,004h,002h,002h,002h,000h,002h,002h,001h,002h	; a9ab  ................
	defb 002h,002h,002h,002h,002h,002h,002h,002h,002h,002h,002h,002h,085h,039h,0a5h,039h	; a9bb  .............9.9
	defb 04fh,039h,06fh,039h,08fh,039h,0afh,039h,0b8h,038h,024h,03ah,044h,03ah,064h,03ah	; a9cb  O9o9.9.9.8$:D:d:
	defb 084h,03ah,02dh,03ah,04dh,03ah,06dh,03ah,08dh,03ah,036h,03ah,056h,03ah,076h,03ah	; a9db  .:-:M:m:.:6:V:v:
	defb 096h,03ah,0b8h,039h,086h,039h,0a6h,039h,050h,039h,070h,039h,090h,039h,0b0h,039h	; a9eb  .:.9.9.9P9p9.9.9
	defb 0b9h,038h,025h,03ah,045h,03ah,065h,03ah,085h,03ah,02eh,03ah,04eh,03ah,06eh,03ah	; a9fb  .8%:E:e:.:.:N:n:
	defb 08eh,03ah,037h,03ah,057h,03ah,077h,03ah,097h,03ah,0b9h,039h,08ch,08ch,08ch,08ch	; aa0b  .:7:W:w:.:.9....
	defb 08dh,08ch,08ch,08ch,08eh,08ch,08ch,08ch,08fh,08ch,08ch,08ch,090h,08ch,08ch,08ch	; aa1b  ................
	defb 090h,08dh,08ch,08ch,090h,08eh,08ch,08ch,090h,08fh,08ch,08ch,090h,090h,08ch,08ch	; aa2b  ................
	defb 090h,090h,08dh,08ch,090h,090h,08eh,08ch,090h,090h,08fh,08ch,090h,090h,090h,08ch	; aa3b  ................
	defb 090h,090h,090h,08dh,090h,090h,090h,08eh,090h,090h,090h,090h,090h,090h,090h,090h	; aa4b  ................

; ======================================================================
; CODIGO 0xaa5b..0xab31  (214 bytes)
; ======================================================================


campo_conmutador:		; campos 21-24: los bits del byte 24; INS los apaga, DEL los enciende (el 21 tiene tres posiciones)
	ld a,018h		;aa5b   ; el byte 24
	call hl_mas_a		;aa5d
	ld a,(0db01h)		;aa60   ; conmutador 0-3
	sub 015h		;aa63
	ld b,a			;aa65
	push bc			;aa66
	ld de,0ab31h		;aa67   ; su mascara en 0xAB31
	call de_mas_a		;aa6a
	ld a,(0db02h)		;aa6d   ; solo pintar?
	or a			;aa70
	jr nz,L_AAA5		;aa71
	ld a,(de)			;aa73
	ld c,a			;aa74
	ld a,(0d8f3h)		;aa75   ; INS o DEL
	cp 044h		;aa78
	jr z,L_AA94		;aa7a
	cp 043h		;aa7c
	jr z,L_AA82		;aa7e
	pop bc			;aa80
	ret			;aa81
L_AA82:
	ld a,c			;aa82   ; INS: 0xFF es el de tres posiciones...
	cp 0ffh		;aa83
	jr z,L_AA8C		;aa85
	cpl			;aa87   ; ...si no, apaga el bit
	and (hl)			;aa88
	ld (hl),a			;aa89
	jr L_AAA5		;aa8a
L_AA8C:
	ld a,(hl)			;aa8c   ; el de tres: baja
	and 003h		;aa8d
	jr z,L_AAA5		;aa8f
	dec (hl)			;aa91
	jr L_AAA5		;aa92
L_AA94:
	ld a,c			;aa94   ; DEL: enciende el bit...
	cp 0ffh		;aa95
	jr z,L_AA9D		;aa97
	or (hl)			;aa99
	ld (hl),a			;aa9a
	jr L_AAA5		;aa9b
L_AA9D:
	ld a,(hl)			;aa9d   ; ...o sube el de tres, hasta 2
	and 003h		;aa9e
	cp 002h		;aaa0
	jr z,L_AAA5		;aaa2
	inc (hl)			;aaa4
L_AAA5:
	ld a,(0db01h)		;aaa5   ; el campo 24, el bit 7...
	cp 018h		;aaa8
	jr nz,L_AACA		;aaaa
	ld a,(0db04h)		;aaac
	or a			;aaaf
	jr z,L_AABC		;aab0
	bit 7,(hl)		;aab2   ; ...cambia 0xDB04...
	jr z,L_AACA		;aab4
	xor a			;aab6
	ld (0db04h),a		;aab7
	jr L_AAC5		;aaba
L_AABC:
	bit 7,(hl)		;aabc
	jr nz,L_AACA		;aabe
	ld a,001h		;aac0
	ld (0db04h),a		;aac2
L_AAC5:
	push hl			;aac5
	call repinta_campos		;aac6   ; ...y repinta los campos de 0xAB50
	pop hl			;aac9
L_AACA:
	pop bc			;aaca   ; su entrada de 0xAB35: cuanto se corre y donde va
	ld a,b			;aacb   ; el conmutador...
	add a,a			;aacc
	add a,b			;aacd   ; ...por 3
	exx			;aace
	ld hl,0ab35h		;aacf   ; su entrada de 0xAB35
	call hl_mas_a		;aad2
	ld a,(hl)			;aad5   ; cuanto se corre...
	inc hl			;aad6
	ld e,(hl)			;aad7   ; ...y donde va
	inc hl			;aad8
	ld d,(hl)			;aad9
	exx			;aada
	ld b,a			;aadb
	or a			;aadc   ; 0: el de tres posiciones (0xAB47)
	ld a,(hl)			;aadd
	jr nz,L_AAE8		;aade
	exx			;aae0
	ld hl,0ab47h		;aae1   ; tres posiciones
	and 003h		;aae4   ; los bits 0-1
	jr L_AAF1		;aae6
L_AAE8:
	rrca			;aae8   ; el bit (0xAB41)
	djnz L_AAE8		;aae9
	exx			;aaeb
	ld hl,0ab41h		;aaec
	and 001h		;aaef
L_AAF1:
	ld b,a			;aaf1   ; tres tiles por posicion
	add a,a			;aaf2
	add a,b			;aaf3
	call hl_mas_a		;aaf4
	ex de,hl			;aaf7
	exx			;aaf8
	ld b,003h		;aaf9   ; tres tiles en vertical
L_AAFB:
	exx			;aafb
	ld a,(de)			;aafc
	call 0004dh		;aafd   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;ab00
	ld bc,00020h		;ab01   ; una fila mas abajo
	add hl,bc			;ab04
	exx			;ab05
	djnz L_AAFB		;ab06
	ret			;ab08
repinta_campos:		; vuelve a pintar los campos de la lista 0xAB50 y deja el campo como estaba
	ld a,001h		;ab09   ; repintando
	ld (0db08h),a		;ab0b
	ld a,(0db01h)		;ab0e   ; guarda el campo
	ld (0db05h),a		;ab11
	ld hl,0ab50h		;ab14
	ld a,(hl)			;ab17
L_AB18:
	ld (0db01h),a		;ab18   ; uno de la lista
	push hl			;ab1b
	call edita_campo		;ab1c
	pop hl			;ab1f
	inc hl			;ab20
	ld a,(hl)			;ab21
	cp 0ffh		;ab22
	jr nz,L_AB18		;ab24
	ld a,(0db05h)		;ab26   ; el campo de antes
	ld (0db01h),a		;ab29
	xor a			;ab2c
	ld (0db08h),a		;ab2d
	ret			;ab30

; ----------------------------------------------------------------------
; DATOS tablas_de_tone_edit_2: lo que leen 0xAA67-0xAB14
;   0xab31..0xab58  (39 bytes)
DATA_tablas_de_tone_edit_2:
	defb 008h,0ffh,004h,080h,003h,025h,039h,000h,0edh,038h,002h,0f1h,038h,007h,05ch,03ah	; ab31  .....%9..8..8.\:
	defb 092h,000h,008h,007h,000h,093h,092h,000h,008h,007h,091h,008h,007h,000h,093h,001h	; ab41  ................
	defb 00ah,00bh,014h,019h,01ah,01ch,0ffh	; ab51

; ======================================================================
; CODIGO 0xab58..0xabd8  (128 bytes)
; ======================================================================


campo_onda:		; campos 25-26: la onda del DCO (byte 0, en 0x3905) o la del LFO (byte 22, en 0x3977); INS y DEL dan la vuelta
	ld de,03905h		;ab58   ; el DCO
	ld a,(0db01h)		;ab5b
	cp 019h		;ab5e
	jr z,L_AB6A		;ab60
	ld de,03977h		;ab62   ; el LFO, byte 22
	ld a,016h		;ab65
	call hl_mas_a		;ab67
L_AB6A:
	ld a,(0db02h)		;ab6a
	or a			;ab6d
	jr nz,L_AB9E		;ab6e
	ld a,(0db08h)		;ab70
	or a			;ab73
	jr nz,L_AB9E		;ab74
	ld b,010h		;ab76   ; 16 ondas...
	ld a,(0db04h)		;ab78
	or a			;ab7b
	jr z,L_AB80		;ab7c
	ld b,00fh		;ab7e   ; ...o 15 con 0xDB04
L_AB80:
	ld a,(0d8f1h)		;ab80   ; INS o DEL
	cp 044h		;ab83
	jr z,L_AB94		;ab85
	cp 043h		;ab87
	jr nz,L_AB9E		;ab89
	ld a,(hl)			;ab8b   ; INS: la siguiente...
	inc a			;ab8c
	cp b			;ab8d
	jr c,L_AB91		;ab8e
	xor a			;ab90   ; ...y de la ultima a la 0
L_AB91:
	ld (hl),a			;ab91
	jr L_AB9E		;ab92
L_AB94:
	ld a,(hl)			;ab94   ; DEL: la anterior...
	dec a			;ab95
	jp p,L_AB9B		;ab96
	ld a,b			;ab99   ; ...y de la 0 a la ultima
	dec a			;ab9a
L_AB9B:
	ld (hl),a			;ab9b
	jr L_ABAB		;ab9c
L_AB9E:
	ld a,(0db04h)		;ab9e   ; con 0xDB04 la 15 no vale
	or a			;aba1
	jr z,L_ABAB		;aba2
	ld a,(hl)			;aba4
	cp 00fh		;aba5
	jr nz,L_ABAB		;aba7
	ld (hl),000h		;aba9
L_ABAB:
	ex de,hl			;abab
	ld a,(de)			;abac   ; el numero mas uno
	inc a			;abad
	push de			;abae
	cp 00ah		;abaf   ; de 10 en adelante...
	jr c,L_ABBA		;abb1
	push hl			;abb3
	ld l,a			;abb4
	call a_decimal		;abb5   ; ...a decimal
	ld a,e			;abb8
	pop hl			;abb9
L_ABBA:
	ld de,0dbf0h		;abba   ; dos cifras
	ld (de),a			;abbd
	ld b,002h		;abbe
	call cifras		;abc0
	pop de			;abc3
	inc hl			;abc4   ; cuatro tiles mas alla...
	inc hl			;abc5
	inc hl			;abc6
	inc hl			;abc7
	ld a,(de)			;abc8   ; ...el dibujo de la onda, tres tiles de 0xABD8
	ld b,a			;abc9
	add a,a			;abca
	add a,b			;abcb
	ld de,0abd8h		;abcc
	call de_mas_a		;abcf
	ld bc,00003h		;abd2
	jp copia_a_vram		;abd5

; ----------------------------------------------------------------------
; DATOS tiles_de_los_conmutadores: tiles de los conmutadores dibujados
;   (0xABCC)
;   0xabd8..0xac08  (48 bytes)
DATA_tiles_de_los_conmutadores:
	defb 0f5h,0f6h,000h,0f7h,0f8h,000h,020h,021h,000h,0f9h,0fah,000h,0fbh,0fch,000h,022h	; abd8  ...... !......."
	defb 023h,000h,024h,025h,000h,026h,027h,000h,028h,029h,000h,02ah,02bh,000h,032h,033h	; abe8  #.$%.&'.().*+.23
	defb 000h,030h,031h,000h,02ch,02dh,000h,02eh,02fh,000h,034h,035h,036h,0fdh,0feh,000h	; abf8  .01.,-../.456...

; ======================================================================
; CODIGO 0xac08..0xac12  (10 bytes)
; ======================================================================


campo_29:		; 0xB1E8; con acarreo, la pantalla se prepara otra vez (0xD8FA = 1)
	call otra_onda		;ac08
	ret nc			;ac0b
	ld a,001h		;ac0c
	ld (0d8fah),a		;ac0e
	ret			;ac11

; ----------------------------------------------------------------------
; DATOS tablas_de_campos: 0xACE0, 0xA5EF y 0xA5FC
;   0xac12..0xacda  (200 bytes)
DATA_tablas_de_campos:
	defb 00eh,068h,008h,008h,00eh,068h,00ch,001h,01ch,06fh,068h,000h,01ch,07fh,06ch,000h	; ac12  .h...h...oh...l.
	defb 01ch,06fh,014h,000h,000h,015h,001h,017h,003h,004h,005h,000h,002h,008h,009h,00ah	; ac22  .o..............
	defb 006h,00ch,00dh,00eh,014h,010h,011h,012h,01ah,019h,01dh,000h,014h,01bh,01ch,01dh	; ac32  ................
	defb 007h,01dh,017h,002h,008h,004h,005h,006h,00ch,01ch,009h,00ah,00bh,00bh,00dh,00eh	; ac42  ................
	defb 00fh,00fh,011h,012h,013h,013h,010h,001h,003h,003h,018h,015h,014h,019h,01ah,016h	; ac52  ................
	defb 01dh,001h,002h,015h,015h,001h,002h,017h,008h,009h,00ah,00bh,008h,009h,00ah,00bh	; ac62  ................
	defb 00ch,00dh,00eh,00fh,006h,015h,01bh,016h,010h,019h,004h,01bh,003h,01bh,007h,005h	; ac72  ................
	defb 006h,01ch,01ah,01ah,014h,007h,00ch,00dh,00eh,00fh,010h,011h,012h,013h,018h,018h	; ac82  ................
	defb 018h,018h,014h,003h,017h,007h,018h,016h,01ah,016h,01ch,000h,00eh,0a9h,05fh,050h	; ac92  .............._P
	defb 066h,050h,04eh,0a1h,056h,0a1h,05eh,0a1h,066h,0a1h,026h,0e9h,086h,048h,08eh,048h	; aca2  fPN.V.^.f.&..H.H
	defb 096h,048h,09eh,048h,086h,090h,08eh,090h,096h,090h,09eh,090h,086h,0d8h,08eh,0d8h	; acb2  .H.H............
	defb 096h,0d8h,09eh,0d8h,066h,0e9h,04eh,03fh,03eh,080h,03eh,09fh,097h,0f7h,03eh,051h	; acc2  ....f.N?>.>...>Q
	defb 056h,0e1h,02eh,039h,046h,0f1h,00eh,068h	; acd2  V..9F..h

; ======================================================================
; CODIGO 0xacda..0xaedd  (515 bytes)
; ======================================================================


tone_edit_estado_1:		; la cabecera y los cinco sprites de 0xAC12
	call cabecera_del_timbre		;acda
	ld de,0d870h		;acdd   ; los sprites del cursor...
	ld hl,0ac12h		;ace0
	ld bc,00014h		;ace3   ; ...0x14 bytes
	ldir		;ace6
	jr estado_siguiente		;ace8
cabecera_del_timbre:		; el numero del timbre (0xDB00 + 1, dos cifras en 0x384B) y su nombre
	ld a,(0db00h)		;acea   ; el numero, de 1 a 16...
	inc a			;aced
	ld l,a			;acee
	call a_decimal		;acef   ; ...en decimal
	ld a,e			;acf2   ; las unidades...
	and 00fh		;acf3
	or 040h		;acf5
	ld hl,0384ch		;acf7   ; ...en 0x384C
	call 0004dh		;acfa   ; BIOS WRTVRM - Writes data in VRAM
	dec hl			;acfd
	ld a,e			;acfe   ; las decenas, delante
	and 0f0h		;acff
	rrca			;ad01
	rrca			;ad02
	rrca			;ad03
	rrca			;ad04
	or 040h		;ad05
	call 0004dh		;ad07   ; BIOS WRTVRM - Writes data in VRAM
nombre_del_timbre:		; las siete letras: del timbre en 0x384E, o del fichero (0xDB0F) en 0x398D si 0xDB17
	ld de,0db0fh		;ad0a
	ld hl,0398dh		;ad0d
	ld a,(0db17h)		;ad10
	or a			;ad13
	jr nz,siete_letras		;ad14
	call timbre_en_curso		;ad16   ; el timbre en curso...
	ld de,00019h		;ad19   ; ...bytes 25-31
	add hl,de			;ad1c
	ex de,hl			;ad1d
	ld hl,0384eh		;ad1e
siete_letras:		; siete tiles de DE en HL; el espacio es el tile 0
	ld b,007h		;ad21
L_AD23:
	ld a,(de)			;ad23
	cp 020h		;ad24
	jr nz,L_AD29		;ad26
	xor a			;ad28
L_AD29:
	call 0004dh		;ad29   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;ad2c
	inc de			;ad2d
	djnz L_AD23		;ad2e
	ret			;ad30
tone_edit_estado_2:		; pinta todos los campos y deja el cursor en el 29
	ld a,001h		;ad31   ; solo pintar
	ld (0db02h),a		;ad33
	ld a,018h		;ad36   ; el 24 primero (0xDB04)
	ld (0db01h),a		;ad38
	call edita_campo		;ad3b
	xor a			;ad3e   ; y del 0 al 0x20
	ld (0db01h),a		;ad3f
L_AD42:
	call edita_campo		;ad42
	ld hl,0db01h		;ad45
	inc (hl)			;ad48
	ld a,(hl)			;ad49
	cp 021h		;ad4a
	jr c,L_AD42		;ad4c
	xor a			;ad4e   ; se acabo pintar
	ld (0db02h),a		;ad4f
	ld a,01dh		;ad52   ; el cursor en el 29
	ld (hl),a			;ad54
estado_siguiente:		; 0xD8FA + 1
	ld hl,0d8fah		;ad55
	inc (hl)			;ad58
	ret			;ad59
tone_edit_estado_0:		; la pantalla fija de TONE EDIT tras la cortina
	call empieza_cambio		;ad5a   ; cambiando de pantalla
	call cortina_de_salida		;ad5d   ; una columna; P mientras quedan
	ret p			;ad60
	xor a			;ad61   ; el nombre del timbre, no el del fichero
	ld (0db17h),a		;ad62
	call pantalla_apagada		;ad65   ; pantalla apagada
	call comun_de_trabajo		;ad68   ; lo comun
	ld de,08ac1h		;ad6b   ; patrones...
	ld hl,02458h		;ad6e
	call rle_a_vram_x3		;ad71
	ld de,08db6h		;ad74   ; ...colores...
	ld hl,00458h		;ad77
	call rle_a_vram_x3		;ad7a
	ld de,08fcdh		;ad7d   ; ...y nombres
	call rle_a_vram		;ad80
	ld hl,00900h		;ad83   ; 0x30 en los colores de 0x0900
	ld a,030h		;ad86
	ld bc,000b8h		;ad88
	call 00056h		;ad8b   ; BIOS FILVRM - Fills VRAM with value
	ld de,09087h		;ad8e   ; los rotulos
	call rle_a_vram		;ad91
	call pantalla_encendida		;ad94   ; pantalla encendida
	call fin_de_cambio		;ad97
	jr estado_siguiente		;ad9a
a_bcd_24:		; BCDE = HL:E' de 24 bits en BCD
	exx			;ad9c
	ld bc,00000h		;ad9d
	ld de,00000h		;ada0
	ld a,018h		;ada3   ; 24 bits
L_ADA5:
	ex af,af'			;ada5
	exx			;ada6   ; el siguiente bit de HL:E'...
	add hl,hl			;ada7   ; el bit alto...
	rl e		;ada8
	exx			;adaa
	ld a,e			;adab   ; ...entra por abajo, en BCD, byte a byte
	adc a,a			;adac   ; ...entra en E...
	daa			;adad
	ld e,a			;adae
	ld a,d			;adaf
	adc a,a			;adb0   ; ...D...
	daa			;adb1
	ld d,a			;adb2
	ld a,c			;adb3
	adc a,a			;adb4   ; ...C...
	daa			;adb5
	ld c,a			;adb6
	ld a,b			;adb7
	adc a,a			;adb8   ; ...y B, todos en BCD
	daa			;adb9
	ld b,a			;adba
	ex af,af'			;adbb
	dec a			;adbc   ; un bit menos
	jr nz,L_ADA5		;adbd
	ret			;adbf
divide_24:		; A:DE / BC por restas: el cociente en A:DE
	ld hl,00000h		;adc0
	exx			;adc3
	ld b,018h		;adc4   ; 24 bits
L_ADC6:
	exx			;adc6
	sla e		;adc7   ; el dividendo a la izquierda...
	rl d		;adc9
	rla			;adcb
	adc hl,hl		;adcc   ; ...al resto
	sbc hl,bc		;adce   ; cabe el divisor?
	jr c,L_ADD5		;add0
	inc e			;add2   ; si: un 1 en el cociente
	jr L_ADD6		;add3
L_ADD5:
	add hl,bc			;add5   ; no: deshace
L_ADD6:
	exx			;add6
	djnz L_ADC6		;add7
	exx			;add9
	ret			;adda
timbre_en_curso:		; HL = 0xD000 + 0x20 * (0xDB00)
	ld hl,0d000h		;addb   ; desde 0xD000
	ld a,(0db00h)		;adde
	or a			;ade1   ; el 0: ya esta
	ret z			;ade2
	ld b,a			;ade3
	ld de,00020h		;ade4   ; 0x20 por timbre
L_ADE7:
	add hl,de			;ade7
	djnz L_ADE7		;ade8
	ret			;adea
por_8:		; HL = H * E
	ld d,000h		;adeb
	ld l,d			;aded
	ld b,008h		;adee
L_ADF0:
	add hl,hl			;adf0
	jr nc,L_ADF4		;adf1
	add hl,de			;adf3
L_ADF4:
	djnz L_ADF0		;adf4
	ret			;adf6
pantalla_wave_edit:		; WAVE EDIT: segun 0xD8FA prepara la pantalla o edita la onda
	call otra_onda		;adf7   ; un numero de onda tecleado: otra vez la cabecera
	jr nc,L_AE01		;adfa
	ld a,001h		;adfc
	ld (0d8fah),a		;adfe
L_AE01:
	ld a,(0d8fah)		;ae01   ; el estado:
	dec a			;ae04
	jp z,wave_edit_estado_1		;ae05   ; 1: 0xAFA0
	jp m,wave_edit_estado_0		;ae08   ; 0: la pantalla
	cp 001h		;ae0b
	jp z,wave_edit_estado_2		;ae0d   ; 2: 0xAFC7, dibuja la onda
	ld a,(0d812h)		;ae10   ; con el canal A del PSG sonando, nada
	or a			;ae13
	ret nz			;ae14
	ld a,(0d8f2h)		;ae15   ; la tecla tenida
	or a			;ae18
	jr z,wave_edit_teclas		;ae19
	cp 031h		;ae1b   ; una del teclado musical...
	jr nc,wave_edit_teclas		;ae1d
	ld (0dc47h),a		;ae1f   ; ...suena la onda con su nota
	call escucha_onda		;ae22
	ei			;ae25
wave_edit_teclas:		; repinta si hace falta y atiende las teclas
	call repinta_onda		;ae26   ; repinta
	call muestra_del_cursor		;ae29   ; HL = la muestra del cursor
	ld a,(0d8f2h)		;ae2c   ; CTRL (0x32)...
	cp 032h		;ae2f
	jr nz,wave_edit_cursores		;ae31
	ld a,008h		;ae33   ; ...y HOME (fila 8, bit 1)...
	call 00141h		;ae35   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 1,a		;ae38
	ret nz			;ae3a
	xor a			;ae3b   ; ...la onda entera a cero
	ld (0da80h),a		;ae3c
	call muestra_a		;ae3f
	ld b,000h		;ae42
L_AE44:
	ld (hl),000h		;ae44
	inc hl			;ae46
	djnz L_AE44		;ae47
	ld a,001h		;ae49   ; y se dibuja otra vez
	ld (0d8fah),a		;ae4b
	ret			;ae4e
wave_edit_cursores:		; SELECT cambia el modo; izquierda y derecha mueven el cursor; arriba y abajo cambian la muestra
	ld a,(0d8f1h)		;ae4f   ; SELECT (0x3F)
	cp 03fh		;ae52
	jp z,modo_siguiente		;ae54
	ld a,(0d808h)		;ae57   ; las teclas con repeticion
	ld b,a			;ae5a
	and 00ch		;ae5b   ; izquierda o derecha
	jp nz,mueve_cursor		;ae5d
	ld a,b			;ae60   ; arriba o abajo
	and 003h		;ae61
	ret z			;ae63
	bit 0,a		;ae64
	ld a,(hl)			;ae66   ; la muestra
	jr z,L_AE73		;ae67
	bit 7,a		;ae69   ; arriba: sube...
	jr nz,L_AE70		;ae6b
	cp 07fh		;ae6d   ; ...hasta 0x7F
	ret nc			;ae6f
L_AE70:
	inc (hl)			;ae70
	jr L_AE7B		;ae71
L_AE73:
	bit 7,a		;ae73   ; abajo: baja...
	jr z,L_AE7A		;ae75
	cp 082h		;ae77   ; ...hasta 0x82 (-126)
	ret c			;ae79
L_AE7A:
	dec (hl)			;ae7a
L_AE7B:
	call cursor_a_la_muestra		;ae7b   ; los puntos de esa muestra
	ld c,(hl)			;ae7e
	call range		;ae7f   ; RANGE en pantalla
	ld a,001h		;ae82   ; a repintar
	ld (0da8dh),a		;ae84
	ret			;ae87
repinta_onda:		; las columnas del tramo del cursor, de dos en dos muestras
	ld a,(0da8dh)		;ae88
	or a			;ae8b
	ret z			;ae8c
	call relleno_de_tramo		;ae8d   ; 0xB236
	ld hl,0da8bh		;ae90
	ld de,0da80h		;ae93
	ld a,(0da87h)		;ae96   ; el paso...
	ld c,a			;ae99
	ld (hl),a			;ae9a
	ld a,(de)			;ae9b   ; ...desde el cursor
	inc (hl)			;ae9c
	ld a,(de)			;ae9d
	sub c			;ae9e
	dec hl			;ae9f
	ld (hl),a			;aea0
L_AEA1:
	push bc			;aea1
	push hl			;aea2
	call columna_de_la_onda		;aea3   ; una columna
	pop hl			;aea6
	pop bc			;aea7
	inc (hl)			;aea8   ; dos muestras mas alla
	inc (hl)			;aea9
	inc hl			;aeaa
	dec (hl)			;aeab
	dec hl			;aeac
	jr nz,L_AEA1		;aead
	xor a			;aeaf   ; hecho
	ld (0da8dh),a		;aeb0
	ret			;aeb3
modo_siguiente:		; 0xDA86 baja de 3 a 0 y vuelta; el paso 0xDA87 = 2 << modo; MODE en 0x38DC
	ld a,(0da8dh)		;aeb4
	or a			;aeb7
	ret nz			;aeb8
	ld hl,0da86h		;aeb9   ; la cuenta del modo
	ld a,(hl)			;aebc
	dec (hl)			;aebd
	and 003h		;aebe
	jr nz,L_AEC5		;aec0
	ld a,003h		;aec2
	dec (hl)			;aec4
L_AEC5:
	ld c,a			;aec5   ; el paso: 2 << modo
	ld b,a			;aec6
	ld a,002h		;aec7
L_AEC9:
	add a,a			;aec9
	djnz L_AEC9		;aeca
	inc hl			;aecc
	ld (hl),a			;aecd
	ld hl,038dch		;aece   ; MODE en pantalla...
	push hl			;aed1
	ld a,c			;aed2
	ld hl,0aeddh		;aed3   ; ...con el valor de 0xAEDD
	call hl_mas_a		;aed6
	ld l,(hl)			;aed9
	jp tres_cifras		;aeda

; ----------------------------------------------------------------------
; DATOS bits_80_40_20_10: mascaras de bit que lee 0xAED9
;   0xaedd..0xaee1  (4 bytes)
DATA_bits_80_40_20_10:
	defb 080h,040h,020h,010h	; aedd

; ======================================================================
; CODIGO 0xaee1..0xb1cd  (748 bytes)
; ======================================================================


mueve_cursor:		; izquierda o derecha, de paso en paso (0xDA87); el sprite le sigue
	ld a,(0da8dh)		;aee1
	or a			;aee4
	ret nz			;aee5
	ld a,(0da87h)		;aee6   ; el paso
	ld c,a			;aee9
	dec a			;aeea
	cpl			;aeeb
	ld b,a			;aeec
	ld de,0d871h		;aeed   ; X del sprite
	ld hl,0da80h		;aef0   ; la muestra del cursor
	ld a,(0d808h)		;aef3
	bit 3,a		;aef6   ; derecha?
	ld a,(hl)			;aef8
	jr nz,L_AF25		;aef9
	or a			;aefb   ; izquierda: en la 0, nada
	jr z,cursor_en_pantalla		;aefc
	cp 0ffh		;aefe
	jr nz,L_AF03		;af00
	inc a			;af02
L_AF03:
	sub c			;af03   ; atras un paso, alineado
	and b			;af04
	ld (hl),a			;af05
	ex de,hl			;af06
	ld a,c			;af07   ; el sprite medio paso
	srl a		;af08
	ld c,a			;af0a
	dec a			;af0b
	cpl			;af0c
	ld b,a			;af0d
	ld a,(hl)			;af0e
	sub c			;af0f
	and b			;af10
	cp 038h		;af11   ; sin bajar de 0x38
	jr nc,L_AF19		;af13
	xor a			;af15
	ld (de),a			;af16
	ld a,038h		;af17
L_AF19:
	ld (hl),a			;af19   ; los sprites del cursor
	ld (0d875h),a		;af1a
	add a,004h		;af1d
	ld (0d879h),a		;af1f
	ex de,hl			;af22
	jr cursor_en_pantalla		;af23
L_AF25:
	ld a,(0da87h)		;af25   ; derecha: hasta la ultima
	neg		;af28
	cp (hl)			;af2a
	jr z,cursor_en_pantalla		;af2b
	jr nc,L_AF32		;af2d
	ld (hl),a			;af2f
	jr L_AF36		;af30
L_AF32:
	ld a,(hl)			;af32   ; adelante un paso, alineado
	add a,c			;af33
	and b			;af34
	ld (hl),a			;af35
L_AF36:
	ex de,hl			;af36
	ld a,c			;af37   ; el sprite medio paso
	srl a		;af38
	ld c,a			;af3a
	dec a			;af3b
	cpl			;af3c
	ld b,a			;af3d
	ld a,(hl)			;af3e
	add a,c			;af3f
	and b			;af40
	ld b,a			;af41
	ld a,(0da87h)		;af42   ; sin pasar del final
	neg		;af45
	srl a		;af47
	add a,038h		;af49
	cp b			;af4b
	jr c,L_AF4F		;af4c
	ld a,b			;af4e
L_AF4F:
	ld (hl),a			;af4f   ; los sprites del cursor
	ld (0d875h),a		;af50
	add a,004h		;af53
	ld (0d879h),a		;af55
	ex de,hl			;af58
	ld a,(hl)			;af59
	or a			;af5a
	jr nz,cursor_en_pantalla		;af5b
	ld a,0ffh		;af5d
	ld (hl),a			;af5f
cursor_en_pantalla:		; la muestra del cursor, RANGE y TIME (0xDA80 / 4, en 0x38C4)
	call muestra_del_cursor		;af60
	call cursor_a_la_muestra		;af63   ; los puntos de la muestra
	ld c,(hl)			;af66   ; RANGE
	call range		;af67
	ld hl,038c4h		;af6a   ; TIME en 0x38C4...
	push hl			;af6d
	ld hl,0da80h		;af6e
	ld a,(hl)			;af71   ; ...el cursor / 4
	and 0fch		;af72
	rrca			;af74
	rrca			;af75
	ld l,a			;af76
tres_cifras:		; L en tres cifras decimales en la direccion de la pila
	call a_decimal		;af77   ; L a BCD
	pop hl			;af7a
	ld (0dbf0h),de		;af7b   ; a 0xDBF0
	ld de,0dbf0h		;af7f
	ld b,003h		;af82   ; tres cifras
	jp cifras		;af84
range:		; la muestra C con su signo (0x4D +, 0x4C -) en 0x3962 y tres cifras en 0x3965
	ld a,04dh		;af87   ; el signo +
	bit 7,c		;af89
	jr z,L_AF93		;af8b
	ld a,c			;af8d   ; negativa: el valor absoluto...
	neg		;af8e
	ld c,a			;af90
	ld a,04ch		;af91   ; ...y el signo -
L_AF93:
	ld hl,03962h		;af93
	call 0004dh		;af96   ; BIOS WRTVRM - Writes data in VRAM
	ld hl,03965h		;af99
	push hl			;af9c
	ld l,c			;af9d
	jr tres_cifras		;af9e
wave_edit_estado_1:		; la cabecera, el cursor en la muestra 0 y el modo 3
	call cabecera_del_timbre		;afa0
	xor a			;afa3   ; el cursor a 0
	ld (0da80h),a		;afa4
	call muestra_del_cursor		;afa7
	call cursor_a_la_muestra		;afaa
	ld a,038h		;afad   ; los sprites del cursor en X = 0x38
	ld (0d871h),a		;afaf
	ld (0d875h),a		;afb2
	add a,004h		;afb5
	ld (0d879h),a		;afb7
	ld hl,0da86h		;afba   ; modo 3...
	ld (hl),003h		;afbd
	call modo_siguiente		;afbf   ; ...y en pantalla
estado_siguiente_2:		; 0xD8FA + 1
	ld hl,0d8fah		;afc2
	inc (hl)			;afc5
	ret			;afc6
wave_edit_estado_2:		; dibuja la onda dos muestras por cuadro, con el cursor detras
	ld a,(0da80h)		;afc7   ; la columna de esta muestra
	ld (0da8ah),a		;afca
	call columna_de_la_onda		;afcd
	ld hl,0da80h		;afd0   ; dos muestras mas alla
	inc (hl)			;afd3
	inc (hl)			;afd4
	jr z,onda_dibujada		;afd5   ; la vuelta entera: se acabo
	ld a,002h		;afd7   ; el cursor avanza con el dibujo
	ld c,a			;afd9
	dec a			;afda
	cpl			;afdb
	ld b,a			;afdc
	ld de,0d871h		;afdd
	ld hl,0da80h		;afe0
	jp L_AF36		;afe3
onda_dibujada:		; el cursor en su sitio, el efecto 2 y a editar
	call cursor_en_pantalla		;afe6
	ld a,002h		;afe9   ; el efecto 2
	call efecto		;afeb
	call wave_edit_estado_1		;afee
	ld hl,0da86h		;aff1
	ld (hl),003h		;aff4
	jp modo_siguiente		;aff6
wave_edit_estado_0:		; la pantalla de WAVE EDIT tras la cortina; FEET del timbre en curso a 0xDC01 para escuchar
	xor a			;aff9   ; el nombre del timbre
	ld (0db17h),a		;affa
	call timbre_en_curso		;affd   ; el byte 1 del timbre, FEET...
	inc hl			;b000
	ld a,(hl)			;b001
	ld (0dc01h),a		;b002   ; ...a 0xDC01
	call empieza_cambio		;b005   ; la cortina
	call cortina_de_salida		;b008
	ret p			;b00b
	call pantalla_apagada		;b00c   ; pantalla apagada
	call sprites_a_cero		;b00f
	xor a			;b012   ; los sprites de 0xB1CD
	ld (0d870h),a		;b013
	ld hl,0b1cdh		;b016
	ld de,0d870h		;b019
	ld bc,0000ch		;b01c
	ldir		;b01f
	call comun_de_trabajo		;b021   ; lo comun
	ld de,0874dh		;b024   ; los rotulos y el marco
	call rle_a_vram		;b027
	ld de,08799h		;b02a
	call rle_a_vram		;b02d
	ld de,087a0h		;b030
	call rle_a_vram		;b033
	ld hl,02600h		;b036   ; los patrones del grafico a cero
	ld a,000h		;b039
	ld bc,00200h		;b03b
	call rellena_vram_x3		;b03e
	ld hl,02c00h		;b041
	ld a,000h		;b044
	ld bc,00200h		;b046
	call 00056h		;b049   ; BIOS FILVRM - Fills VRAM with value
	ld de,08815h		;b04c   ; 0x8815
	call rle_a_vram		;b04f
	ld hl,00600h		;b052   ; los colores del grafico: 0x81
	ld bc,00200h		;b055
	ld a,081h		;b058
	call rellena_vram_x3		;b05a
	ld hl,00c00h		;b05d
	ld bc,00200h		;b060
	ld a,081h		;b063
	call 00056h		;b065   ; BIOS FILVRM - Fills VRAM with value
	ld hl,00e00h		;b068   ; una linea 0x8C en 16 tiles: el eje
	ld a,08ch		;b06b
	ld de,00008h		;b06d
	ld b,010h		;b070
L_B072:
	push bc			;b072
	ld bc,00001h		;b073
	call 00056h		;b076   ; BIOS FILVRM - Fills VRAM with value
	add hl,de			;b079
	pop bc			;b07a
	djnz L_B072		;b07b
	ld hl,03888h		;b07d   ; la tabla de nombres del grafico...
	ld de,0b1e4h		;b080   ; ...por la lista de 0xB1E4
L_B083:
	ld a,(de)			;b083
	cp 0ffh		;b084
	jr z,L_B0A2		;b086
	push de			;b088
L_B089:
	ld b,010h		;b089   ; 16 tiles seguidos por fila
L_B08B:
	push bc			;b08b
	ld bc,00001h		;b08c
	call 00056h		;b08f   ; BIOS FILVRM - Fills VRAM with value
	inc hl			;b092
	inc a			;b093
	pop bc			;b094
	djnz L_B08B		;b095
	ld de,00010h		;b097   ; la fila siguiente
	add hl,de			;b09a
	or a			;b09b
	jr nz,L_B089		;b09c
	pop de			;b09e
	inc de			;b09f
	jr L_B083		;b0a0
L_B0A2:
	call pantalla_encendida		;b0a2   ; pantalla encendida
	call fin_de_cambio		;b0a5
	jp estado_siguiente_2		;b0a8
columna_de_la_onda:		; repinta la columna de la muestra 0xDA8A: lee sus 16 tiles de la VRAM, borra su bit y pinta los puntos de la mas baja a la mas alta de sus vecinas
	ld a,(0da8ah)		;b0ab   ; DE = la muestra
	call muestra_a		;b0ae
	ex de,hl			;b0b1
	ld a,(0da8ah)		;b0b2   ; x = muestra / 2
	srl a		;b0b5
	ld c,a			;b0b7
	and 007h		;b0b8   ; el bit de x dentro del tile (0xB1D9)
	ld hl,0b1d9h		;b0ba
	call hl_mas_a		;b0bd
	ld a,(hl)			;b0c0
	ld hl,0da81h		;b0c1   ; 0xDA81 = el bit, 0xDA82 = 0x40 + x
	ld (hl),a			;b0c4
	inc hl			;b0c5
	ld a,040h		;b0c6
	add a,c			;b0c8
	ld (hl),a			;b0c9
	ld b,003h		;b0ca   ; tres alturas: la siguiente, esta y la anterior
	inc e			;b0cc
	inc e			;b0cd
L_B0CE:
	ld a,(de)			;b0ce
	call altura		;b0cf   ; a fila del grafico
	inc hl			;b0d2
	ld (hl),a			;b0d3
	dec e			;b0d4
	dec e			;b0d5
	djnz L_B0CE		;b0d6
	ld c,(hl)			;b0d8
	dec hl			;b0d9
	ld d,(hl)			;b0da
	dec hl			;b0db
	ld e,(hl)			;b0dc
	ld a,(0da8ah)		;b0dd   ; en la primera y la ultima muestra...
	or a			;b0e0
	jr z,L_B0E9		;b0e1
	inc a			;b0e3
	jr nz,L_B0EA		;b0e4
	ld e,d			;b0e6   ; ...falta una vecina
	jr L_B0EA		;b0e7
L_B0E9:
	ld c,d			;b0e9
L_B0EA:
	ld a,c			;b0ea   ; ordena: la mas baja y la mas alta
	cp d			;b0eb   ; C contra D
	jr nc,L_B0FE		;b0ec
	cp e			;b0ee   ; C contra E
	jr nc,L_B0F9		;b0ef
	ld (hl),a			;b0f1   ; la mas baja
	inc hl			;b0f2
	ld a,d			;b0f3   ; D contra E
	cp e			;b0f4
	jr c,L_B10B		;b0f5
	jr L_B108		;b0f7
L_B0F9:
	ld (hl),e			;b0f9
	inc hl			;b0fa
	ld (hl),d			;b0fb
	jr L_B111		;b0fc
L_B0FE:
	ld a,d			;b0fe   ; D contra E
	cp e			;b0ff
	jr nc,L_B10E		;b100
	ld (hl),a			;b102   ; la mas baja
	inc hl			;b103
	ld a,c			;b104   ; C contra E
	cp e			;b105
	jr c,L_B10B		;b106
L_B108:
	ld (hl),a			;b108
	jr L_B111		;b109
L_B10B:
	ld (hl),e			;b10b
	jr L_B111		;b10c
L_B10E:
	ld (hl),e			;b10e
	inc hl			;b10f
	ld (hl),c			;b110
L_B111:
	ld a,(hl)			;b111   ; cuantos puntos: alta - baja
	dec hl			;b112
	ld c,(hl)			;b113
	sub c			;b114
	inc hl			;b115
	ld (hl),a			;b116
	dec hl			;b117
	dec hl			;b118
	ld a,(hl)			;b119   ; el tile de la columna en la tabla de nombres
	and 0f8h		;b11a
	rrca			;b11c
	rrca			;b11d
	rrca			;b11e
	add a,080h		;b11f
	ld l,a			;b121
	ld h,038h		;b122
	call 00050h		;b124   ; BIOS SETRD - Enables VDP to read | SETRD
	ld a,h			;b127   ; el tercio
	and 003h		;b128
	ld de,0b1e1h		;b12a
	call de_mas_a		;b12d   ; la direccion de sus patrones
	ld a,(de)			;b130
	ld h,a			;b131
	ld l,000h		;b132
	ld d,l			;b134
	ld a,(00006h)		;b135
	ld c,a			;b138
	in e,(c)		;b139   ; el tile
	ld b,003h		;b13b
L_B13D:
	sla e		;b13d   ; por 8
	rl d		;b13f
	djnz L_B13D		;b141
	add hl,de			;b143
	push hl			;b144
	ld b,010h		;b145   ; 16 tiles de alto...
	ld de,0da00h		;b147   ; ...a 0xDA00
L_B14A:
	call 00050h		;b14a   ; BIOS SETRD - Enables VDP to read
	push bc			;b14d
	ld b,008h		;b14e
L_B150:
	in a,(c)		;b150   ; sus 8 lineas
	ld (de),a			;b152
	inc de			;b153
	djnz L_B150		;b154
	call tile_de_debajo		;b156   ; el tile de debajo
	pop bc			;b159
	djnz L_B14A		;b15a
	ld hl,0da00h		;b15c   ; borra el bit de la columna en las 128 lineas
	ld de,0da81h		;b15f
	ld b,080h		;b162
L_B164:
	ld a,(de)			;b164
	cpl			;b165
	and (hl)			;b166
	ld (hl),a			;b167
	inc hl			;b168
	djnz L_B164		;b169
	ex de,hl			;b16b   ; B = el bit, C = cuantos puntos
	ld b,(hl)			;b16c
	inc hl			;b16d
	inc hl			;b16e
	inc hl			;b16f
	ld c,(hl)			;b170
	dec hl			;b171
	ld de,0da00h		;b172
	push de			;b175
	ld a,(hl)			;b176   ; desde la mas baja
	sub 020h		;b177
	call de_mas_a		;b179
L_B17C:
	ld a,(de)			;b17c   ; un punto
	or b			;b17d   ; el bit de la columna
	ld (de),a			;b17e
	ld a,c			;b17f   ; quedan puntos?
	or a			;b180
	jr z,L_B18B		;b181
	dec c			;b183   ; uno menos
	ld a,c			;b184
	or a			;b185
	jr z,L_B18B		;b186
	inc de			;b188   ; la linea siguiente
	jr L_B17C		;b189
L_B18B:
	pop de			;b18b   ; y los 16 tiles a la VRAM
	pop hl			;b18c
	ld b,010h		;b18d
L_B18F:
	push bc			;b18f
	ld bc,00008h		;b190   ; un tile...
	call copia_a_vram		;b193   ; ...a la VRAM
	call tile_de_debajo		;b196   ; el de debajo
	pop bc			;b199
	djnz L_B18F		;b19a
	ret			;b19c
muestra_del_cursor:		; HL = la muestra 0xDA80 de la onda 0xDB00
	ld a,(0da80h)		;b19d
muestra_a:		; HL = la muestra A de la onda 0xDB00
	ld b,a			;b1a0
	ld a,(0db00h)		;b1a1
muestra_a_de_onda:		; HL = 0xC000 + 0x100 * onda + B
	ld hl,0c000h		;b1a4   ; 0xC000...
	add a,h			;b1a7   ; ...+ 0x100 * onda
	ld h,a			;b1a8
	ld a,b			;b1a9   ; + la muestra
	call hl_mas_a		;b1aa
	ret			;b1ad
tile_de_debajo:		; HL = los patrones del tile de la fila siguiente (0x80 mas, o salta de tercio)
	push de			;b1ae
	ld a,l			;b1af   ; en la mitad de abajo del tile...
	cp 080h		;b1b0
	jr c,L_B1C7		;b1b2
	ld a,h			;b1b4   ; ...al final de un tercio salta al siguiente
	cp 027h		;b1b5
	jr z,L_B1C2		;b1b7
	cp 02fh		;b1b9
	jr nz,L_B1C7		;b1bb
	ld de,00680h		;b1bd
	jr L_B1CA		;b1c0
L_B1C2:
	ld de,00480h		;b1c2
	jr L_B1CA		;b1c5
L_B1C7:
	ld de,00080h		;b1c7
L_B1CA:
	add hl,de			;b1ca
	pop de			;b1cb
	ret			;b1cc

; ----------------------------------------------------------------------
; DATOS tablas_de_wave_edit: lo que leen 0xB016-0xB12A
;   0xb1cd..0xb1e8  (27 bytes)
DATA_tablas_de_wave_edit:
	defb 017h,038h,000h,00fh,017h,038h,004h,001h,053h,038h,010h,00fh,080h,040h,020h,010h	; b1cd  .8...8..S8...@ .
	defb 008h,004h,002h,001h,020h,028h,030h,0c0h,080h,0c0h,0ffh	; b1dd  .... (0....

; ======================================================================
; CODIGO 0xb1e8..0xb555  (877 bytes)
; ======================================================================


otra_onda:		; INS o DEL cambian la onda o el timbre 0xDB00 (0-15); acarreo si cambia
	ld a,(0da8dh)		;b1e8   ; repintando: nada
	or a			;b1eb
	ret nz			;b1ec
	ld hl,0db00h		;b1ed
	ld a,(0d8f1h)		;b1f0   ; INS: la siguiente
	cp 043h		;b1f3
	jr z,L_B1FE		;b1f5
	cp 044h		;b1f7   ; DEL: la anterior
	jr nz,L_B205		;b1f9
	dec (hl)			;b1fb
	jr L_B1FF		;b1fc
L_B1FE:
	inc (hl)			;b1fe
L_B1FF:
	ld a,(hl)			;b1ff   ; de 0 a 15
	and 00fh		;b200
	ld (hl),a			;b202
	scf			;b203
	ret			;b204
L_B205:
	xor a			;b205
	ret			;b206
altura:		; la muestra A a fila del grafico: 0x60 - A / 2 si es positiva, 0x60 + |A| / 2 si es negativa
	or a			;b207   ; negativa?
	jp m,L_B214		;b208
	srl a		;b20b   ; 0x60 - A / 2
	ld c,a			;b20d
	ld a,040h		;b20e
	sub c			;b210
	add a,020h		;b211
	ret			;b213
L_B214:
	neg		;b214   ; 0x60 + |A| / 2
	srl a		;b216
	add a,060h		;b218
	ret			;b21a
cursor_a_la_muestra:		; la Y del sprite del cursor = altura - 4
	ld a,(hl)			;b21b
	call altura		;b21c
	sub 004h		;b21f
	ld (0d878h),a		;b221
	ret			;b224
relleno_siguiente:		; el siguiente tramo del relleno
	ld hl,0da88h		;b225   ; la posicion del tramo...
	ld a,(0da87h)		;b228   ; ...avanza un paso
	add a,(hl)			;b22b
	ld (hl),a			;b22c
	inc hl			;b22d   ; tramos que quedan
	dec (hl)			;b22e
	jp nz,L_B241		;b22f
	ei			;b232   ; hecho
	ret			;b233
relleno_cortado:		; vuelve dos niveles: el relleno se corta
	pop hl			;b234
	ret			;b235
relleno_de_tramo:		; rellena en linea recta las muestras entre el cursor y un paso atras (el paso, 0xDA87)
	ld a,002h		;b236   ; dos tramos
	ld (0da89h),a		;b238
	ld a,(0da80h)		;b23b
	ld (0da88h),a		;b23e
L_B241:
	ld a,(0da87h)		;b241   ; el paso
	ld (0da8eh),a		;b244
	inc a			;b247
	ld (0dbf0h),a		;b248
relleno_bucle:		; muestra a muestra; arriba o abajo cortan
	call lee_teclas		;b24b   ; las teclas
	di			;b24e
	ld a,(0d807h)		;b24f   ; arriba o abajo: se corta
	and 003h		;b252
	jr nz,relleno_cortado		;b254
	ld a,(0da88h)		;b256   ; la muestra del tramo
	call muestra_a		;b259
	ld de,0dbf0h		;b25c
	ex de,hl			;b25f
	dec (hl)			;b260   ; quedan muestras?
	jr z,relleno_siguiente		;b261
	ld a,(hl)			;b263
	ld b,a			;b264
	ld a,(0da8eh)		;b265
	ld c,a			;b268
	ld a,(0da88h)		;b269
	add a,040h		;b26c
	push af			;b26e
	sub c			;b26f
	inc hl			;b270
	ld (hl),a			;b271
	pop af			;b272
	inc hl			;b273
	ld (hl),a			;b274
	sub b			;b275
	ld b,a			;b276
	ld a,(hl)			;b277
	sub b			;b278
	exx			;b279
	ld bc,00010h		;b27a
	ld e,a			;b27d
	ld d,b			;b27e
	call por_16		;b27f   ; diferencia * 16 (0xB308)...
	ld (0dbf4h),hl		;b282
	exx			;b285
	ld a,(hl)			;b286
	dec hl			;b287
	sub (hl)			;b288
	exx			;b289
	ld c,a			;b28a
	xor a			;b28b
	ld b,a			;b28c
	ld de,(0dbf4h)		;b28d
	call divide_24		;b291   ; ...entre el paso: la pendiente
	ld (0dbf6h),de		;b294
	exx			;b298
	ex de,hl			;b299
	ld a,(hl)			;b29a
	call sin_signo		;b29b   ; las dos muestras sin signo
	ld (de),a			;b29e
	ld a,(0da8eh)		;b29f
	ld c,a			;b2a2
	ld a,l			;b2a3
	sub c			;b2a4
	ld l,a			;b2a5
	ld a,(hl)			;b2a6
	call sin_signo		;b2a7
	ex de,hl			;b2aa
	ld b,000h		;b2ab
	cp (hl)			;b2ad   ; la diferencia y su signo (0xDA8C)
	jr nc,L_B2B5		;b2ae
	ld c,a			;b2b0
	ld a,(hl)			;b2b1
	inc b			;b2b2
	jr L_B2B6		;b2b3
L_B2B5:
	ld c,(hl)			;b2b5
L_B2B6:
	sub c			;b2b6
	ld c,(hl)			;b2b7
	ld (hl),a			;b2b8
	inc hl			;b2b9
	ld (hl),c			;b2ba
	ex af,af'			;b2bb
	ld a,b			;b2bc
	ld (0da8ch),a		;b2bd
	ex af,af'			;b2c0
	exx			;b2c1
	ld de,(0dbf6h)		;b2c2
	ld b,000h		;b2c6
	ld c,a			;b2c8
	call por_16		;b2c9   ; por la posicion...
	ld a,e			;b2cc
	ex de,hl			;b2cd
	ld bc,00010h		;b2ce
	call divide_24		;b2d1   ; ...entre 16
	ld a,e			;b2d4
	exx			;b2d5
	ld c,a			;b2d6
	ld a,(0da8ch)		;b2d7   ; sube o baja
	or a			;b2da
	jr nz,L_B2E1		;b2db
	ld a,c			;b2dd
	add a,(hl)			;b2de
	jr L_B2E4		;b2df
L_B2E1:
	ld b,c			;b2e1
	ld a,(hl)			;b2e2
	sub b			;b2e3
L_B2E4:
	ld (hl),a			;b2e4   ; la muestra intermedia
	ex af,af'			;b2e5
	dec hl			;b2e6   ; la posicion...
	dec hl			;b2e7
	ld c,(hl)			;b2e8
	ld a,(0da8eh)		;b2e9   ; ...dentro del paso
	sub c			;b2ec
	ex de,hl			;b2ed
	add a,l			;b2ee
	ld l,a			;b2ef
	ex af,af'			;b2f0
	ld b,a			;b2f1
	cp 080h		;b2f2   ; otra vez con signo
	jr nc,L_B2FB		;b2f4
	ld a,080h		;b2f6   ; 0x80 - valor
	sub b			;b2f8
	jr L_B2FF		;b2f9
L_B2FB:
	sub 080h		;b2fb
	neg		;b2fd
L_B2FF:
	cp 080h		;b2ff   ; -128 no: -127
	jr nz,L_B304		;b301
	inc a			;b303
L_B304:
	ld (hl),a			;b304   ; la muestra rellenada
	jp relleno_bucle		;b305
por_16:		; DE:HL = DE * BC, 16 por 16 bits
	ld hl,00000h		;b308
	ld a,010h		;b30b
L_B30D:
	add hl,hl			;b30d   ; DE:HL * 2...
	ex de,hl			;b30e
	adc hl,hl		;b30f
	ex de,hl			;b311
	jr nc,L_B318		;b312   ; ...si sale un bit, suma BC
	add hl,bc			;b314
	jr nc,L_B318		;b315
	inc de			;b317   ; con acarreo a DE
L_B318:
	dec a			;b318
	jr nz,L_B30D		;b319
	ret			;b31b
sin_signo:		; la muestra con signo a 0x80 = cero
	or a			;b31c
	jp m,L_B325		;b31d   ; negativa?
	ld c,a			;b320
	ld a,080h		;b321   ; 0x80 - A
	sub c			;b323
	ret			;b324
L_B325:
	neg		;b325
	add a,080h		;b327
	ret			;b329
pantalla_encendida:		; R1 = 0xE2
	ld b,0e2h		;b32a
	jr L_B330		;b32c
pantalla_apagada:		; R1 = 0xA2
	ld b,0a2h		;b32e
L_B330:
	ld c,001h		;b330
	jp 00047h		;b332   ; BIOS WRTVDP - Writes data in the VDP-register
comun_de_trabajo:		; lo comun de las pantallas de trabajo: la franja de arriba, la fuente, el menu, las cifras y el marco
	ld de,087dbh		;b335   ; la franja de arriba
	call rle_a_vram		;b338
	call fuente_letras		;b33b   ; la fuente desde la A
menu_cifras_y_marco:		; el menu de abajo, los diez digitos con su color y el marco
	call pinta_menu		;b33e
	ld de,09e37h		;b341   ; los diez digitos
	ld hl,02080h		;b344
	ld bc,00050h		;b347
	call copia_a_vram_x3		;b34a
	ld b,00ah		;b34d   ; su color, uno por digito...
	ld hl,00080h		;b34f
L_B352:
	push bc			;b352
	ld de,09e87h		;b353   ; ...0x9E87 en TONE EDIT...
	ld a,(0d8f4h)		;b356
	or a			;b359
	jr z,L_B35F		;b35a
	ld de,09e8fh		;b35c   ; ...0x9E8F en las demas
L_B35F:
	ld bc,00008h		;b35f
	push hl			;b362
	call copia_a_vram_x3		;b363
	pop hl			;b366
	ld de,00008h		;b367
	add hl,de			;b36a
	pop bc			;b36b
	djnz L_B352		;b36c
	ld hl,02200h		;b36e   ; el marco: 0x82A5...
	ld de,082a5h		;b371
	call rle_a_vram_x3		;b374
	ld de,084ebh		;b377   ; ...0x84EB...
	ld hl,00008h		;b37a
	call rle_a_vram_x3		;b37d
	ld de,08531h		;b380   ; ...0x8531...
	ld hl,000d8h		;b383
	call rle_a_vram_x3		;b386
	ld de,08552h		;b389   ; ...y 0x8552
	ld hl,001d8h		;b38c
	jp rle_a_vram_x3		;b38f
fuente_letras:		; la fuente desde la A (0x446E en 0x2100) y su color 0xF0
	ld de,0446eh		;b392   ; la fuente desde la A
	ld hl,02100h		;b395   ; en el tile 0x20
	call rle_a_vram_x3		;b398
	ld hl,00100h		;b39b   ; su color, desde 0x0100
	ld a,0f0h		;b39e   ; blanco sobre negro
	ld bc,000b8h		;b3a0
	jp rellena_vram_x3		;b3a3
sprites_a_cero:		; la copia de los atributos, 0x20 bytes, a cero
	ld hl,0d870h		;b3a6
	ld bc,00020h		;b3a9
	jp borra_memoria		;b3ac
pantalla_copia:		; la pantalla 5: elige con arriba/abajo un timbre de origen y otro de destino, cada uno con RETURN, y copia timbre y onda
	ld b,008h		;b3af   ; color 8 del cursor...
	ld a,(0d803h)		;b3b1
	and 010h		;b3b4
	jr nz,L_B3BA		;b3b6
	ld b,004h		;b3b8   ; ...o 4, cada 16 cuadros
L_B3BA:
	ld a,b			;b3ba
	ld (0d873h),a		;b3bb
	ld a,(0d8fah)		;b3be   ; el estado de la pantalla:
	dec a			;b3c1
	jp z,lista_de_timbres		;b3c2   ; 1: la lista
	jp m,lista_estado_0		;b3c5   ; 0: la pantalla
	cp 001h		;b3c8
	jp z,copia_estado_2		;b3ca   ; 2: 0xB4C1
	ld a,(0d8f1h)		;b3cd   ; RETURN (0x40)?
	cp 040h		;b3d0
	jp nz,copia_cursor		;b3d2
	ld hl,0d922h		;b3d5   ; cuantos elegidos
	ld de,0d923h		;b3d8
	push hl			;b3db
	ld a,(hl)			;b3dc
	inc de			;b3dd
	ld hl,0397ch		;b3de
	or a			;b3e1   ; el primero...
	jr nz,L_B3F0		;b3e2
	push de			;b3e4   ; ...su rotulo de 0xB5C3
	ld de,0b5c3h		;b3e5
	call escribe_lista		;b3e8
	pop de			;b3eb
	dec de			;b3ec
	ld hl,03938h		;b3ed
L_B3F0:
	ld a,(0d921h)		;b3f0   ; el numero elegido, a 0xD923 o 0xD924
	ld (de),a			;b3f3
	ld a,(0d920h)		;b3f4   ; y en pantalla
	call dos_cifras_bcd		;b3f7
	pop hl			;b3fa
	inc (hl)			;b3fb   ; uno mas
	ld a,(hl)			;b3fc
	cp 002h		;b3fd   ; faltan: espera al otro
	ret nz			;b3ff
	ld hl,0d000h		;b400   ; el timbre de origen...
	dec de			;b403
	ld a,(de)			;b404
	or a			;b405
	jr z,L_B413		;b406
	ld b,a			;b408
	push de			;b409
	ld de,00020h		;b40a
	xor a			;b40d
L_B40E:
	adc hl,de		;b40e
	djnz L_B40E		;b410
	pop de			;b412
L_B413:
	push hl			;b413
	ld hl,0d000h		;b414   ; ...y el de destino
	inc de			;b417
	ld a,(de)			;b418
	or a			;b419
	jr z,L_B427		;b41a
	ld b,a			;b41c
	push de			;b41d
	ld de,00020h		;b41e
	xor a			;b421
L_B422:
	adc hl,de		;b422
	djnz L_B422		;b424
	pop de			;b426
L_B427:
	ex de,hl			;b427
	pop hl			;b428
	ld bc,00020h		;b429   ; los 32 bytes
	ldir		;b42c
	ld b,000h		;b42e   ; y su onda: origen...
	ld de,0d923h		;b430
	ld a,(de)			;b433
	call muestra_a_de_onda		;b434
	push hl			;b437
	inc de			;b438   ; ...destino
	ld a,(de)			;b439
	call muestra_a_de_onda		;b43a
	ex de,hl			;b43d
	pop hl			;b43e
	ld bc,00100h		;b43f   ; 256 bytes
	ldir		;b442
	ld a,002h		;b444   ; el efecto 2
	call efecto		;b446
	ld hl,0d922h		;b449   ; todo a cero
	ld b,003h		;b44c
L_B44E:
	ld (hl),000h		;b44e
	inc hl			;b450
	djnz L_B44E		;b451
	call lista_de_timbres		;b453   ; la lista otra vez
	dec (hl)			;b456
	ret			;b457
copia_cursor:		; arriba o abajo cambian el numero (1-16, en BCD y en binario) y el sprite le sigue
	ld de,0d921h		;b458
	ld a,(0d808h)		;b45b   ; arriba o abajo
	and 003h		;b45e
	ret z			;b460
	and 001h		;b461   ; arriba?
	jr z,L_B47B		;b463
	ld b,0f0h		;b465   ; el sprite 0x10 mas arriba
	ld a,(de)			;b467
	or a			;b468
	ret z			;b469   ; en el 1, nada
	push af			;b46a
	ld a,001h		;b46b   ; el efecto 1
	call efecto		;b46d
	pop af			;b470
	dec a			;b471   ; uno menos...
	ld (de),a			;b472
	dec de			;b473   ; ...tambien en BCD
	ld a,(de)			;b474
	sub 001h		;b475
	daa			;b477
	ld (de),a			;b478
	jr L_B499		;b479
L_B47B:
	ld a,(de)			;b47b   ; abajo: hasta el 16
	cp 00fh		;b47c
	ret nc			;b47e
	push af			;b47f
	ld a,001h		;b480   ; el efecto 1
	call efecto		;b482
	pop af			;b485
	inc a			;b486   ; uno mas...
	ld (de),a			;b487
	dec de			;b488   ; ...tambien en BCD
	ld a,(de)			;b489
	add a,001h		;b48a
	daa			;b48c
	ld (de),a			;b48d
	ld b,010h		;b48e   ; el sprite 0x10 mas abajo
	cp 009h		;b490   ; del 8 al 9: a la otra columna (0xB565)
	jr nz,L_B4A8		;b492
	ld hl,0b565h		;b494
	jr L_B4A0		;b497
L_B499:
	cp 008h		;b499   ; del 9 al 8: a la primera (0xB55D)
	jr nz,L_B4A8		;b49b
	ld hl,0b55dh		;b49d
L_B4A0:
	ld de,0d870h		;b4a0
	ld bc,00008h		;b4a3
	ldir		;b4a6
L_B4A8:
	ld hl,0d870h		;b4a8   ; la Y de los dos sprites
	ld a,b			;b4ab
	add a,(hl)			;b4ac
	ld (hl),a			;b4ad
	inc hl			;b4ae
	inc hl			;b4af
	inc hl			;b4b0
	inc hl			;b4b1
	ld (hl),a			;b4b2
	ret			;b4b3
timbre_a_hl:		; HL = 0xD000 + 0x20 * A
	ld b,a			;b4b4
	ld hl,0d000h		;b4b5
	ld bc,00020h		;b4b8
	xor a			;b4bb
L_B4BC:
	adc hl,bc		;b4bc
	djnz L_B4BC		;b4be
	ret			;b4c0
copia_estado_2:		; los sprites de 0xB555 y el rotulo de 0xB5A1
	ld hl,0b555h		;b4c1   ; los sprites de 0xB555
	ld de,0d870h		;b4c4
	ld bc,00008h		;b4c7   ; 8 bytes
	ldir		;b4ca
	ld de,0b5a1h		;b4cc   ; el rotulo de 0xB5A1
	call escribe_lista		;b4cf
	jr lista_hecha		;b4d2
lista_estado_0:		; la pantalla de las pantallas 5 y 6 tras la cortina
	call file_estado_0		;b4d4   ; la cortina y la pantalla de FILE
	ret p			;b4d7
	xor a			;b4d8   ; borra un recuadro de 13 filas de 6 tiles
	ld b,00dh		;b4d9
	ld hl,038d8h		;b4db
L_B4DE:
	push bc			;b4de
	ld bc,00006h		;b4df
	call 00056h		;b4e2   ; BIOS FILVRM - Fills VRAM with value
	ld de,00020h		;b4e5
	add hl,de			;b4e8
	pop bc			;b4e9
	djnz L_B4DE		;b4ea
	ld de,0b587h		;b4ec   ; la cabecera: 0xB587 en la 5...
	ld a,(0d8f4h)		;b4ef
	cp 006h		;b4f2
	jr nz,L_B4F9		;b4f4
	ld de,0b56dh		;b4f6   ; ...0xB56D en la 6
L_B4F9:
	call rle_a_vram		;b4f9
	ld hl,0d920h		;b4fc   ; 0xD920 = 1 y lo demas a cero
	ld b,004h		;b4ff
	ld (hl),001h		;b501
L_B503:
	inc hl			;b503
	ld (hl),000h		;b504
	djnz L_B503		;b506
	ret			;b508
lista_de_timbres:		; los 16 timbres: numero, punto y nombre, en dos columnas de ocho
	xor a			;b509
	inc a			;b50a   ; del 1...
	ld de,0d019h		;b50b   ; ...con el nombre del timbre 0
	ld hl,038a2h		;b50e
L_B511:
	push af			;b511
	call dos_cifras_bcd		;b512   ; el numero
	inc hl			;b515
	ld a,096h		;b516   ; el punto
	call 0004dh		;b518   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;b51b
	call siete_letras		;b51c   ; las siete letras
	ld a,019h		;b51f   ; el timbre siguiente
	call de_mas_a		;b521
	ld a,036h		;b524   ; la fila siguiente
	call hl_mas_a		;b526
	pop af			;b529
	add a,001h		;b52a   ; en BCD
	daa			;b52c
	cp 009h		;b52d   ; el 9, a la segunda columna
	jr nz,L_B534		;b52f
	ld hl,038adh		;b531
L_B534:
	cp 017h		;b534   ; hasta el 16
	jr c,L_B511		;b536
lista_hecha:		; 0xD8FA + 1
	ld hl,0d8fah		;b538
	inc (hl)			;b53b
	ret			;b53c
dos_cifras_bcd:		; el BCD A en dos cifras; sin decena, el tile 0
	ld c,a			;b53d   ; A en C
	and 0f0h		;b53e
	jr z,L_B548		;b540   ; sin decena: el tile 0
	rrca			;b542   ; la decena...
	rrca			;b543
	rrca			;b544
	rrca			;b545
	add a,040h		;b546   ; ...en tile
L_B548:
	call 0004dh		;b548   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;b54b
	ld a,c			;b54c
	and 00fh		;b54d
	add a,040h		;b54f
	call 0004dh		;b551   ; BIOS WRTVRM - Writes data in VRAM
	ret			;b554

; ----------------------------------------------------------------------
; DATOS tablas_de_file: listas de 0x4337 y RLE de FILE MODE (0xB494-0xB4F6)
;   0xb555..0xb5c8  (115 bytes)
DATA_tablas_de_file:
	defb 026h,00eh,018h,008h,026h,00eh,01ch,00fh,096h,00eh,018h,008h,096h,00eh,01ch,00fh	; b555  &...&...........
	defb 026h,060h,018h,008h,026h,060h,01ch,00fh,028h,038h,08fh,09bh,054h,09ah,054h,093h	; b565  &`..&`..(8..T.T.
	defb 054h,094h,054h,054h,09dh,054h,09eh,054h,09fh,054h,081h,09ch,080h,04ah,038h,00ch	; b575  T.TT.T.T.T...J8.
	defb 04bh,000h,028h,038h,08fh,090h,054h,09eh,054h,091h,054h,092h,054h,054h,09dh,054h	; b585  K.(8..T.T.T.TT.T
	defb 09eh,054h,09fh,054h,081h,09ch,080h,04ah,038h,00ch,04bh,000h,0b8h,038h,023h,02fh	; b595  .T.T...J8.K..8#/
	defb 030h,039h,000h,0feh,0d8h,038h,024h,021h,034h,021h,0feh,0f8h,038h,02eh,035h,02dh	; b5a5  09...8$!4!..8.5-
	defb 022h,025h,032h,0feh,038h,039h,020h,020h,0feh,05ah,039h,034h,02fh,0feh,07ch,039h	; b5b5  "%2.89  .Z94/.|9
	defb 020h,020h,0ffh	; b5c5

; ======================================================================
; CODIGO 0xb5c8..0xb729  (353 bytes)
; ======================================================================


pantalla_lista:		; la pantalla 6: los sprites fuera y la lista de timbres
	ld a,0d0h		;b5c8   ; sin sprites
	ld (0d870h),a		;b5ca
	ld (0d874h),a		;b5cd
	ld a,(0d8fah)		;b5d0
	dec a			;b5d3
	jp z,lista_de_timbres		;b5d4
	jp m,lista_estado_0		;b5d7
	ret			;b5da
pantalla_file:		; FILE (pantalla 4): el menu de opciones; RETURN elige; la opcion 9 hace la operacion
	ld b,008h		;b5db   ; el cursor parpadea...
	ld a,(0d803h)		;b5dd
	and 010h		;b5e0
	jr nz,L_B5E6		;b5e2
	ld b,000h		;b5e4
L_B5E6:
	ld a,(0db16h)		;b5e6   ; ...en el menu o en el nombre (0xDB16)
	dec a			;b5e9
	jr z,L_B5FB		;b5ea
	ld a,b			;b5ec
	ld (0d873h),a		;b5ed
	ld a,00fh		;b5f0
	ld (0d877h),a		;b5f2
	xor a			;b5f5
	ld (0d883h),a		;b5f6
	jr file_menu		;b5f9
L_B5FB:
	ld a,b			;b5fb
	ld (0d883h),a		;b5fc
	xor a			;b5ff
	ld (0d873h),a		;b600
	ld (0d877h),a		;b603
file_menu:		; arriba y abajo mueven por las opciones; RETURN elige
	ld a,(0d8fah)		;b606   ; 0: la pantalla
	dec a			;b609
	jp m,file_estado_0		;b60a
	ld a,(0d812h)		;b60d   ; con el canal A sonando, nada
	or a			;b610
	ret nz			;b611
	ld a,(0db0bh)		;b612   ; 0xDB0B: una operacion en marcha
	or a			;b615
	jp nz,file_operacion		;b616
	ld hl,0db0ch		;b619
	ld a,(hl)			;b61c
	ld a,(0d806h)		;b61d   ; las teclas recien pulsadas
	ld b,a			;b620
	and 003h		;b621
	jr nz,file_mueve		;b623
	ld a,(0d8f1h)		;b625   ; RETURN?
	cp 040h		;b628
	jr z,file_elige		;b62a
	ret			;b62c
file_mueve:		; la opcion siguiente o la anterior, saltando el disco si no hay y las que no tocan
	ld a,001h		;b62d   ; el efecto 1
	call efecto		;b62f
	ld a,(0db0eh)		;b632   ; las opciones elegidas
	ld c,a			;b635
	ld a,b			;b636
	and 002h		;b637   ; abajo:
	jr z,L_B65B		;b639
	inc (hl)			;b63b   ; la siguiente
	ld a,(hl)			;b63c
	cp 001h		;b63d
	jr nz,L_B648		;b63f
	ld a,(0d9deh)		;b641   ; sin disco, salta la 1
	or a			;b644
	jr z,L_B648		;b645
	inc (hl)			;b647
L_B648:
	ld a,(hl)			;b648
	cp 004h		;b649
	jr nz,L_B653		;b64b
	bit 0,c		;b64d   ; 4 y 5 solo con el bit 0
	jr nz,L_B653		;b64f
	ld (hl),006h		;b651
L_B653:
	cp 00ah		;b653   ; de la 9 a la 0
	jr c,L_B67C		;b655
	ld (hl),000h		;b657
	jr L_B67C		;b659
L_B65B:
	dec (hl)			;b65b   ; arriba: la anterior...
	jp p,L_B663		;b65c
	ld (hl),009h		;b65f   ; ...de la 0 a la 9
	jr L_B67C		;b661
L_B663:
	ld a,(hl)			;b663
	cp 001h		;b664
	jr nz,L_B671		;b666
	ld a,(0d9deh)		;b668   ; sin disco, salta la 1
	or a			;b66b
	jr z,L_B671		;b66c
	dec (hl)			;b66e
	jr L_B67C		;b66f
L_B671:
	ld a,(hl)			;b671
	cp 005h		;b672
	jr nz,L_B67C		;b674
	bit 0,c		;b676   ; 4 y 5 solo con el bit 0
	jr nz,L_B67C		;b678
	ld (hl),003h		;b67a
L_B67C:
	ld a,(hl)			;b67c   ; el sprite a la opcion (0xB729)
	ld b,a			;b67d
	ld de,0b729h		;b67e   ; la Y del cursor de cada opcion (0xB729)
	call de_mas_a		;b681
	ld a,(de)			;b684
	ld hl,0d870h		;b685   ; los dos sprites
	ld (hl),a			;b688
	inc hl			;b689
	inc hl			;b68a
	inc hl			;b68b
	inc hl			;b68c
	ld (hl),a			;b68d
	ret			;b68e
file_elige:		; RETURN: marca la opcion en 0xDB0E y la pinta; la 9 (o mas) arranca la operacion
	ld hl,0db0ch		;b68f
	ld a,(hl)			;b692
	or a			;b693
	jr nz,file_marca		;b694
	ld a,002h		;b696   ; la 0 tambien pinta la 2
	ld (hl),a			;b698
	call file_marca		;b699
	xor a			;b69c
	ld (0db0ch),a		;b69d
file_marca:		; 0xDB0E con la mascara y el bit de la opcion (0xB733) y la marca en pantalla
	ld b,a			;b6a0   ; B = la opcion
	add a,a			;b6a1
	ld hl,0b733h		;b6a2   ; su mascara y su bit en 0xB733
	call hl_mas_a		;b6a5
	ld de,0db0eh		;b6a8
	ld a,(de)			;b6ab   ; borra el grupo...
	and (hl)			;b6ac
	inc hl			;b6ad
	or (hl)			;b6ae   ; ...y pone la opcion
	ld (de),a			;b6af
	ld a,b			;b6b0
	cp 002h		;b6b1   ; 0 o 1: el aparato
	jr nc,L_B6CF		;b6b3
	or a			;b6b5   ; la 0: cinta
	jr nz,L_B6BD		;b6b6
	call marca_cinta		;b6b8
	jr L_B6CF		;b6bb
L_B6BD:
	ld hl,03979h		;b6bd   ; la 1: disco
	ld de,0b74dh		;b6c0
	call rle_a_vram_en_hl		;b6c3
	ld hl,03999h		;b6c6
	ld de,0b753h		;b6c9
	call rle_a_vram_en_hl		;b6cc
L_B6CF:
	ld c,009h		;b6cf   ; la 9 o mas: la operacion...
	ld a,(0db0ch)		;b6d1
	cp c			;b6d4
	jr c,L_B6E1		;b6d5
	ld a,001h		;b6d7   ; ...0xDB0B = 1
	ld (0db0bh),a		;b6d9
	dec a			;b6dc
	ld (0db16h),a		;b6dd
	ret			;b6e0
L_B6E1:
	ld bc,00306h		;b6e1   ; el grupo de la opcion: 6-8, 2-3 o 0-1
	cp c			;b6e4
	jr nc,L_B6F0		;b6e5
	ld bc,00402h		;b6e7
	cp c			;b6ea
	jr nc,L_B6F0		;b6eb
	ld bc,00200h		;b6ed
L_B6F0:
	ld a,c			;b6f0   ; borra las marcas del grupo
	call sitio_de_opcion		;b6f1
	ld a,097h		;b6f4
L_B6F6:
	call 0004dh		;b6f6   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;b6f9
	add hl,de			;b6fc
	djnz L_B6F6		;b6fd
	ld a,(0db0ch)		;b6ff   ; y marca la elegida
	call sitio_de_opcion		;b702
	ld a,098h		;b705
	call 0004dh		;b707   ; BIOS WRTVRM - Writes data in VRAM
	ret			;b70a
marca_cinta:		; las marcas de cinta
	ld hl,03978h		;b70b
	call marca_0xb747		;b70e
	ld hl,03998h		;b711
	jr marca_0xb747		;b714
sitio_de_opcion:		; HL = la direccion de pantalla de la opcion A (0xB75A)
	add a,a			;b716   ; dos bytes por opcion
	ld hl,0b75ah		;b717
	call hl_mas_a		;b71a
	ld e,(hl)			;b71d   ; DE = su direccion
	inc hl			;b71e
	ld d,(hl)			;b71f
	ex de,hl			;b720
	ret			;b721
marca_0xb747:		; la marca de 0xB747 en HL
	ld de,0b747h		;b722
	call rle_a_vram_en_hl		;b725
	ret			;b728

; ----------------------------------------------------------------------
; DATOS tablas_del_menu_file: posiciones y flujos RLE cortos del menu de FILE
;   (0xB67E-0xB728)
;   0xb729..0xb76e  (69 bytes)
DATA_tablas_del_menu_file:
	defb 02eh,036h,046h,04eh,056h,05eh,06eh,076h,07eh,08eh,0feh,000h,0feh,001h,0f9h,000h	; b729  .6FNV^nv~.......
	defb 0f9h,002h,0f9h,004h,0f9h,006h,0e7h,000h,0e7h,008h,0e7h,010h,0dfh,020h,082h,097h	; b739  ............. ..
	defb 07bh,004h,003h,000h,084h,0c8h,0a0h,0c9h,0c9h,000h,085h,0c5h,0a0h,0c6h,0c7h,0b0h	; b749  {...............
	defb 000h,0d8h,038h,0f8h,038h,038h,039h,058h,039h,078h,039h,098h,039h,0d8h,039h,0f8h	; b759  ..8.889X9x9.9.9.
	defb 039h,018h,03ah,058h,03ah	; b769

; ======================================================================
; CODIGO 0xb76e..0xb832  (196 bytes)
; ======================================================================


file_estado_0:		; la pantalla de FILE tras la cortina; el vector de errores del disco a 0x50DE
	call empieza_cambio		;b76e
	call cortina_de_salida		;b771
	ret p			;b774
	call pantalla_apagada		;b775
	ld a,(0d8f4h)		;b778   ; en las pantallas 5 y 6...
	cp 005h		;b77b
	jr z,L_B783		;b77d
	cp 006h		;b77f
	jr nz,L_B78D		;b781
L_B783:
	ld a,0d0h		;b783   ; ...sin sprites
	ld (0d870h),a		;b785
	ld (0d874h),a		;b788
	jr L_B798		;b78b
L_B78D:
	ld hl,0ba6ch		;b78d   ; en FILE el cursor de 0xBA6C
	ld de,0d870h		;b790
	ld bc,00008h		;b793
	ldir		;b796
L_B798:
	call comun_de_trabajo		;b798   ; lo comun
	ld de,09ac5h		;b79b   ; patrones, colores y nombres de FILE
	ld hl,02458h		;b79e
	call rle_a_vram_x3		;b7a1
	ld de,09c63h		;b7a4
	ld hl,00458h		;b7a7
	call rle_a_vram_x3		;b7aa
	ld de,09d74h		;b7ad
	call rle_a_vram		;b7b0
	ld de,0b841h		;b7b3   ; la flecha
	call rle_a_vram		;b7b6
	call file_marcas		;b7b9   ; 0xB80D
	ld a,(0d9deh)		;b7bc   ; sin disco: las marcas de cinta
	or a			;b7bf
	jr z,L_B7CB		;b7c0
	call marca_cinta		;b7c2
	ld hl,038f8h		;b7c5
	call marca_0xb747		;b7c8
L_B7CB:
	call pantalla_encendida		;b7cb
	call fin_de_cambio		;b7ce
	ld hl,0db0fh		;b7d1   ; el nombre del fichero a espacios
	ld bc,00006h		;b7d4
	ld d,h			;b7d7
	ld e,l			;b7d8
	inc e			;b7d9
	ld (hl),020h		;b7da
	ldir		;b7dc
	xor a			;b7de   ; nada en marcha
	ld (0db0bh),a		;b7df
	ld (0db16h),a		;b7e2
	ld (0db03h),a		;b7e5
	inc a			;b7e8   ; 0xDB17: se edita el nombre del fichero
	ld (0db17h),a		;b7e9
	ld a,009h		;b7ec   ; la opcion 9
	ld (0db0ch),a		;b7ee
	ld hl,0b832h		;b7f1   ; el codigo de 0xB832 a 0xD9A6...
	ld de,0d9a6h		;b7f4
	ld bc,0000fh		;b7f7
	ldir		;b7fa
	ld hl,0d9a6h		;b7fc   ; ...y DISKVE (0xF323) apunta ahi
	ld (0f323h),hl		;b7ff
	call file_estado_siguiente		;b802
	xor a			;b805
	dec a			;b806
	ret			;b807
file_estado_siguiente:		; 0xD8FA + 1
	ld hl,0d8fah		;b808
	inc (hl)			;b80b
	ret			;b80c
file_marcas:		; pinta las marcas de lo elegido en 0xDB0E: aparato, operacion y tipo
	ld a,(0db0eh)		;b80d   ; el aparato
	and 001h		;b810
	call marca_opcion		;b812
	ld a,(0db0eh)		;b815   ; la operacion
	ld c,002h		;b818
	call grupo_de_opciones		;b81a
	ld c,006h		;b81d   ; el tipo
	ld a,(0db0eh)		;b81f
	srl a		;b822
	srl a		;b824
grupo_de_opciones:		; la opcion C + bits 1-2 de A
	srl a		;b826
	and 003h		;b828
	add a,c			;b82a
marca_opcion:		; 0xDB0C = A y su marca
	ld (0db0ch),a		;b82b
	call file_marca		;b82e
	ret			;b831

; ----------------------------------------------------------------------
; DATOS dos_bytes_0xB832: 0xA8 0xD9 delante del codigo que nadie llama de
;   0xB834
;   0xb832..0xb834  (2 bytes)
DATA_dos_bytes_0xB832:
	defb 0a8h,0d9h	; b832

; ======================================================================
; CODIGO 0xb834..0xb841  (13 bytes)
; ======================================================================


error_del_disco:		; DISKVE: el cartucho otra vez en la pagina 1 y el mensaje de 0x50DE
	ld h,040h		;b834   ; el cartucho en 0x4000...
	ld a,(0d855h)		;b836
	push bc			;b839
	call 00024h		;b83a   ; BIOS ENASLT - Switches to specified slot and page definitively
	pop bc			;b83d
	jp error_de_disco		;b83e   ; ...y el mensaje

; ----------------------------------------------------------------------
; DATOS file_flecha: flujo RLE de 0x4352 (0xB7B6)
;   0xb841..0xb851  (16 bytes)
DATA_file_flecha:
	defb 031h,038h,087h,09dh,054h,09eh,054h,09fh,054h,09ch,080h,04ah,038h,00ch,04bh,000h	; b841  18..T.T.T..J8.K.

; ======================================================================
; CODIGO 0xb851..0xba6c  (539 bytes)
; ======================================================================


file_operacion:		; hace lo elegido en 0xDB0E, paso a paso (0xDB16)
	ld hl,0db16h		;b851
	ld a,(0db0eh)		;b854   ; el tipo
	rrca			;b857
	rrca			;b858
	rrca			;b859
	and 003h		;b85a
	ld c,a			;b85c
	dec a			;b85d
	jr z,L_B868		;b85e   ; LAYOUT: 0xB0 bytes
	jp p,L_B873		;b860   ; SAMP: la longitud que tiene
	ld de,01200h		;b863   ; TONE: 0x1200 bytes, las 16 ondas y los 16 timbres
	jr L_B86B		;b866
L_B868:
	ld de,000b0h		;b868
L_B86B:
	ld a,e			;b86b   ; a 0xDCFE
	ld (0dcfeh),a		;b86c
	ld a,d			;b86f
	ld (0dcffh),a		;b870
L_B873:
	ld a,(0db0eh)		;b873   ; disco?
	bit 0,a		;b876
	jp nz,file_disco		;b878
	srl a		;b87b   ; cinta: carga o graba
	bit 0,a		;b87d
	jr z,graba_cinta_paso		;b87f
	ld a,(hl)			;b881   ; el paso
	dec a			;b882
	jr z,escribe_nombre		;b883
	jp m,pide_nombre_carga		;b885
	call borra_mensajes		;b888   ; carga de cinta: borra la linea de mensajes...
	ld de,0bb47h		;b88b   ; ...y pone el rotulo de 0xBB47
	call escribe_lista		;b88e
	ld b,007h		;b891   ; sin nombre vale cualquiera
	ld hl,0db0fh		;b893
L_B896:
	ld a,(hl)			;b896   ; la letra
	cp 020h		;b897   ; espacio?
	jr nz,L_B8A0		;b899
	inc hl			;b89b
	djnz L_B896		;b89c   ; las siete
	jr L_B8A5		;b89e   ; todo espacios: cualquier nombre
L_B8A0:
	call nombre_valido		;b8a0   ; con nombre: que sea valido
	jr c,nombre_malo		;b8a3
L_B8A5:
	call carga_de_cinta		;b8a5   ; a cargar
	jp c,fallo_de_cinta		;b8a8   ; fallo: 0xBA4E
	jr operacion_hecha		;b8ab
escribe_nombre:		; el nombre del fichero letra a letra hasta RETURN
	ld a,(0d8f1h)		;b8ad
	cp 040h		;b8b0
	jr z,paso_siguiente		;b8b2
	jp cursor_de_letra_67		;b8b4
pide_nombre_carga:		; el rotulo de 0xBAFA
	call pide_nombre		;b8b7
	ld de,0bafah		;b8ba
	call escribe_lista		;b8bd
	jr paso_siguiente		;b8c0
nombre_malo:		; el mensaje 0x5183 en 0x3A06
	ld de,05183h		;b8c2
	ld hl,03a06h		;b8c5
	ld c,0ffh		;b8c8
	call escribe_desde_hl		;b8ca
	jr file_reposo		;b8cd
graba_cinta_paso:		; graba en cinta: pide el nombre y graba
	ld a,(hl)			;b8cf
	dec a			;b8d0
	jr z,escribe_nombre		;b8d1
	jp m,pide_nombre_graba		;b8d3
	call borra_mensajes		;b8d6   ; el rotulo de 0xBB3B
	ld de,0bb3bh		;b8d9
	call escribe_lista		;b8dc
	call nombre_valido		;b8df   ; nombre valido?
	jr c,nombre_malo		;b8e2
	call graba_en_cinta		;b8e4   ; a grabar
	jp c,fallo_de_cinta		;b8e7
operacion_hecha:		; el rotulo de 0xBB54 y el efecto 2
	call borra_mensajes		;b8ea
	ld de,0bb54h		;b8ed
	call escribe_lista		;b8f0
	ld a,002h		;b8f3
	call efecto		;b8f5
file_reposo:		; nada en marcha y el cursor en la opcion 9
	xor a			;b8f8
	ld (0db0bh),a		;b8f9   ; sin operacion
	ld (0db16h),a		;b8fc   ; paso 0
	ld (0db03h),a		;b8ff   ; la letra 0
	ld a,009h		;b902   ; el cursor en la opcion 9
	ld (0db0ch),a		;b904
	ret			;b907
pide_nombre_graba:		; el rotulo de 0xBB06
	call pide_nombre		;b908
	ld de,0bb06h		;b90b
	call escribe_lista		;b90e
paso_siguiente:		; 0xDB16 + 1
	ld hl,0db16h		;b911
	inc (hl)			;b914
	ret			;b915
file_disco:		; la operacion en disco
	rrca			;b916
	and 003h		;b917
	cp 001h		;b919   ; 1: carga
	jr z,carga_disco_paso		;b91b
	jp c,graba_disco_paso		;b91d   ; 0: graba
	cp 002h		;b920   ; 2: borra
	jp z,borra_disco_paso		;b922
	ld a,(hl)			;b925   ; 3: el directorio; en el paso 1, las teclas de la lista
	dec a			;b926
	jr nz,directorio_paso_0		;b927
	call directorio_teclas		;b929
	jr c,L_B92F		;b92c   ; RETURN: fuera
	ret			;b92e
L_B92F:
	call cursor_de_file		;b92f
	call limpia_recuadro		;b932
	jp operacion_hecha		;b935
directorio_paso_0:		; limpia, pone los rotulos y busca los ficheros
	ld a,c			;b938   ; el tipo
	add a,021h		;b939
	ld (0db18h),a		;b93b
	call limpia_recuadro		;b93e   ; limpia el recuadro
	ld de,0ba86h		;b941
	call borra_lista		;b944
	ld de,0bb1eh		;b947
	call borra_lista		;b94a
	ld de,0bb31h		;b94d
	call escribe_lista		;b950
	call borra_mensajes		;b953
	ld de,0bae6h		;b956
	call escribe_lista		;b959
	call cursor_de_file		;b95c
	ld a,0d0h		;b95f   ; sin el sprite del nombre
	ld (0d880h),a		;b961
	call directorio		;b964   ; el directorio
	jp c,directorio_fallo		;b967
	jp paso_siguiente		;b96a
directorio_fallo:		; borra el rotulo y el fallo
	ld de,0bae6h		;b96d
	call borra_lista		;b970
	jp operacion_acabada		;b973
limpia_recuadro:		; 12 filas de 0x11 tiles a cero desde 0x38E5
	ld b,00ch		;b976
	ld hl,038e5h		;b978
L_B97B:
	push bc			;b97b
	ld bc,00011h		;b97c
	xor a			;b97f
	call 00056h		;b980   ; BIOS FILVRM - Fills VRAM with value
	ld de,00020h		;b983
	add hl,de			;b986
	pop bc			;b987
	djnz L_B97B		;b988
	ret			;b98a
carga_disco_paso:		; carga de disco: pide el nombre y carga
	ld a,(hl)			;b98b   ; el paso
	dec a			;b98c
	jr z,escribe_nombre_disco		;b98d   ; 1: el nombre
	jp m,pide_nombre_disco		;b98f   ; 0: pedirlo
	call borra_mensajes		;b992   ; 2: a cargar
	ld de,0bb47h		;b995
	call escribe_lista		;b998
	call carga_de_disco		;b99b   ; la carga
	jp c,operacion_acabada		;b99e
	jp operacion_hecha		;b9a1
escribe_nombre_disco:		; el nombre letra a letra hasta RETURN
	ld a,(0d8f1h)		;b9a4
	cp 040h		;b9a7
	jp z,paso_siguiente		;b9a9
	jp cursor_de_letra_67		;b9ac
pide_nombre_disco:		; el rotulo de 0xBB12
	call pide_nombre		;b9af
	ld de,0bb12h		;b9b2
	call escribe_lista		;b9b5
	jp paso_siguiente		;b9b8
graba_disco_paso:		; graba en disco: pide el nombre y graba
	ld a,(hl)			;b9bb   ; el paso
	dec a			;b9bc
	jr z,escribe_nombre_disco		;b9bd   ; 1: el nombre
	jp m,pide_nombre_graba_disco		;b9bf   ; 0: pedirlo
	call borra_mensajes		;b9c2   ; 2: a grabar
	ld de,0bb3bh		;b9c5
	call escribe_lista		;b9c8
	call graba_en_disco		;b9cb   ; la grabacion
	jp c,operacion_acabada		;b9ce
	jp operacion_hecha		;b9d1
pide_nombre_graba_disco:		; el rotulo de 0xBB1E
	call pide_nombre		;b9d4
	ld de,0bb1eh		;b9d7
	call escribe_lista		;b9da
	jp paso_siguiente		;b9dd
borra_disco_paso:		; borra de disco: pide el nombre y borra
	ld a,(hl)			;b9e0   ; el paso
	dec a			;b9e1
	jr z,escribe_nombre_borra		;b9e2   ; 1: el nombre
	jp m,pide_nombre_borra		;b9e4   ; 0: pedirlo
	call borra_mensajes		;b9e7
	call borra_de_disco		;b9ea   ; el borrado
	jp c,operacion_acabada		;b9ed
	jp operacion_hecha		;b9f0
escribe_nombre_borra:		; el nombre letra a letra hasta RETURN
	ld a,(0d8f1h)		;b9f3
	cp 040h		;b9f6
	jp z,paso_siguiente		;b9f8
	jp cursor_de_letra_67		;b9fb
pide_nombre_borra:		; el rotulo de 0xBB2A
	call pide_nombre		;b9fe   ; el tipo y el nombre
	ld de,0bb1eh		;ba01   ; borra el rotulo de 0xBB1E
	call borra_lista		;ba04
	ld de,0bb2ah		;ba07   ; y pone el de 0xBB2A
	call escribe_lista		;ba0a
	jp paso_siguiente		;ba0d
pide_nombre:		; el tipo a 0xDB18, su rotulo (0xBA80) y el de 0xBABB, el nombre, el FCB a cero y el cursor
	push bc			;ba10
	ld de,0ba86h		;ba11   ; borra el rotulo anterior
	call borra_lista		;ba14
	pop bc			;ba17
	ld a,c			;ba18   ; el tipo, de 0x21 a 0x23
	add a,021h		;ba19
	ld (0db18h),a		;ba1b
	ld a,c			;ba1e   ; su rotulo
	add a,a			;ba1f
	ld hl,0ba80h		;ba20
	call hl_mas_a		;ba23
	ld e,(hl)			;ba26
	inc hl			;ba27
	ld d,(hl)			;ba28
	call escribe_lista		;ba29
	ld de,0babbh		;ba2c
	call escribe_lista		;ba2f
	call nombre_del_timbre		;ba32   ; el nombre
	ld hl,0d980h		;ba35   ; el FCB a cero
	ld bc,00025h		;ba38
	ld d,h			;ba3b
	ld e,l			;ba3c
	inc e			;ba3d
	ld (hl),000h		;ba3e
	ldir		;ba40
cursor_de_file:		; los sprites de 0xBA6C
	ld de,0d870h		;ba42
	ld hl,0ba6ch		;ba45
	ld bc,00014h		;ba48
	ldir		;ba4b
	ret			;ba4d
fallo_de_cinta:		; el rotulo de 0xBB5B y a reposo
	ld de,0bb5bh		;ba4e   ; el rotulo de fallo
	push de			;ba51
	call borra_mensajes		;ba52   ; la linea en blanco
	pop de			;ba55
	call escribe_lista		;ba56   ; el rotulo
	call file_reposo		;ba59   ; a reposo
operacion_acabada:		; el efecto 2 y nada en marcha
	ld a,002h		;ba5c
	call efecto		;ba5e
	xor a			;ba61
	ld (0db0bh),a		;ba62
	ret			;ba65
borra_mensajes:		; la linea de mensajes (0xBAD0) en blanco
	ld de,0bad0h		;ba66
	jp borra_lista		;ba69

; ----------------------------------------------------------------------
; DATOS listas_de_file: listas de 0x4337 del menu de cinta y disco
;   (0xB88E-0xBA66)
;   0xba6c..0xbb6d  (257 bytes)
DATA_listas_de_file:
	defb 08eh,0b6h,018h,008h,08eh,0b6h,01ch,00fh,000h,000h,000h,000h,000h,000h,000h,000h	; ba6c  ................
	defb 05dh,067h,014h,000h,086h,0bah,099h,0bah,0a9h,0bah,085h,038h,020h,034h,02fh,02eh	; ba7c  ]g.........8 4/.
	defb 025h,000h,030h,021h,032h,021h,02dh,025h,034h,025h,032h,020h,0ffh,086h,038h,000h	; ba8c  %.0!2!-%4%2 ..8.
	defb 020h,02bh,025h,039h,000h,02ch,021h,039h,02fh,035h,034h,020h,0ffh,085h,038h,020h	; ba9c   +%9.,!9/54 ..8 
	defb 033h,021h,02dh,030h,02ch,029h,02eh,027h,000h,024h,021h,034h,021h,020h,0ffh,047h	; baac  3!-0,).'.$!4! .G
	defb 039h,026h,029h,02ch,025h,000h,02eh,021h,02dh,025h,000h,0feh,08ch,039h,0d3h,0feh	; babc  9&),%..!-%...9..
	defb 094h,039h,0e3h,0feh,003h,03ah,033h,034h,021h,032h,034h,020h,020h,020h,030h,035h	; bacc  .9...:34!24   05
	defb 033h,028h,000h,032h,025h,034h,035h,032h,02eh,0ffh,045h,03ah,025h,02eh,024h,020h	; badc  3(.2%452..E:%.$ 
	defb 020h,020h,030h,035h,033h,028h,000h,032h,025h,034h,035h,032h,02eh,0ffh,0c9h,038h	; baec    053(.2%452...8
	defb 034h,021h,030h,025h,000h,02ch,02fh,021h,024h,0ffh,0c9h,038h,034h,021h,030h,025h	; bafc  4!0%.,/!$..84!0%
	defb 000h,033h,021h,036h,025h,0ffh,0c9h,038h,024h,029h,033h,02bh,000h,02ch,02fh,021h	; bb0c  .3!6%..8$)3+.,/!
	defb 024h,0ffh,0c9h,038h,024h,029h,033h,02bh,000h,033h,021h,036h,025h,0ffh,0cch,038h	; bb1c  $..8$)3+.3!6%..8
	defb 02bh,029h,02ch,02ch,0ffh,08ah,038h,020h,026h,029h,02ch,025h,033h,020h,0ffh,009h	; bb2c  +),,..8 &),%3 ..
	defb 03ah,033h,021h,036h,029h,02eh,027h,020h,020h,020h,0ffh,009h,03ah,02ch,02fh,021h	; bb3c  :3!6).'   ..:,/!
	defb 024h,029h,02eh,027h,020h,020h,020h,0ffh,00ch,03ah,020h,02fh,02bh,020h,0ffh,005h	; bb4c  $).'   ..: /+ ..
	defb 03ah,024h,025h,036h,029h,023h,025h,000h,029h,02fh,000h,025h,032h,032h,02fh,032h	; bb5c  :$%6)#%.)/.%22/2
	defb 0ffh	; bb6c

; ======================================================================
; CODIGO 0xbb6d..0xbcb6  (329 bytes)
; ======================================================================


pantalla_layout:		; la pantalla 8: izquierda/derecha eligen nota, una tecla la recibe; CTRL + HOME vuelve al de fabrica
	ld b,008h		;bb6d   ; color 8 del cursor...
	ld a,(0d803h)		;bb6f
	and 010h		;bb72
	jr nz,L_BB78		;bb74
	ld b,00fh		;bb76   ; ...o 15, cada 16 cuadros
L_BB78:
	ld a,b			;bb78
	ld (0d873h),a		;bb79
	ld a,(0d8fah)		;bb7c   ; 0: la pantalla
	dec a			;bb7f
	jp m,layout_estado_0		;bb80
	ld a,(0d8f2h)		;bb83   ; CTRL (0x32)...
	cp 032h		;bb86
	jr nz,layout_tecla		;bb88
	ld a,008h		;bb8a   ; ...y HOME
	call 00141h		;bb8c   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 1,a		;bb8f
	ret nz			;bb91
	call layout_de_fabrica		;bb92   ; el LAYOUT y las teclas de fabrica
	call teclas_de_fabrica		;bb95
	call layout_pantalla		;bb98   ; el teclado otra vez
	ld hl,0d8fah		;bb9b
	dec (hl)			;bb9e
	ld a,002h		;bb9f   ; el efecto 2
	jp efecto		;bba1
layout_tecla:		; una tecla del teclado musical (1-0x30, menos la 0x16) recibe la nota elegida
	ld a,(0d8f1h)		;bba4   ; la tecla nueva
	or a			;bba7
	jp z,layout_cursor		;bba8
	cp 016h		;bbab
	jp z,layout_cursor		;bbad
	cp 031h		;bbb0
	jp nc,layout_cursor		;bbb2
	dec a			;bbb5   ; su entrada del LAYOUT...
	ld de,0d200h		;bbb6
	call de_mas_a		;bbb9
	ld a,(0d906h)		;bbbc   ; ...el byte de la nota
	ld (de),a			;bbbf
	ld a,(0d8f1h)		;bbc0   ; su entrada de 0xD230
	dec a			;bbc3
	sla a		;bbc4
	ld de,0d230h		;bbc6
	call de_mas_a		;bbc9
	ld hl,0bd5dh		;bbcc   ; sin nota: 0xBD5D
	ld a,(0d906h)		;bbcf
	or a			;bbd2
	jr z,L_BBE0		;bbd3
	ld a,(0d905h)		;bbd5   ; la rutina y el retardo de la nota (0x5E29)
	sla a		;bbd8
	ld hl,05e29h		;bbda
	call hl_mas_a		;bbdd
L_BBE0:
	ld bc,00002h		;bbe0   ; a 0xD230
	ldir		;bbe3
	ld a,002h		;bbe5   ; el efecto 2
	call efecto		;bbe7
	ld a,(0d8f1h)		;bbea   ; y el nombre en la tecla
nombre_de_nota:		; escribe en la tecla A el nombre de su nota, o la tapa si no tiene
	call sitio_de_tecla		;bbed   ; HL = su sitio, DE = su entrada
	ld a,(de)			;bbf0
	or a			;bbf1
	jr nz,nombre_de_nota_d905		;bbf2
	ld de,0bdd9h		;bbf4   ; sin nota: los tiles de 0xBDD9
	call dos_tiles		;bbf7
	ld bc,00020h		;bbfa
	add hl,bc			;bbfd
	jp dos_tiles		;bbfe
nombre_de_nota_d905:		; el nombre de la nota 0xD905: la octava (0xBDDD) y la nota dentro de ella
	ld a,(0d905h)		;bc01
	ld b,0ffh		;bc04
	ld de,0bdddh		;bc06   ; la octava: cuantos limites de 0xBDDD pasa
	ex de,hl			;bc09
L_BC0A:
	inc b			;bc0a
	cp (hl)			;bc0b
	inc hl			;bc0c
	jr nc,L_BC0A		;bc0d
	ex de,hl			;bc0f
	ld a,b			;bc10   ; su tabla de nombres (0xBD5F)
	add a,a			;bc11
	push hl			;bc12
	ld hl,0bd5fh		;bc13
	call hl_mas_a		;bc16
	ld e,(hl)			;bc19
	inc hl			;bc1a
	ld d,(hl)			;bc1b
	pop hl			;bc1c
	ld a,(0d905h)		;bc1d   ; la nota dentro de la octava...
L_BC20:
	cp 00eh		;bc20   ; ...de 14 en 14
	jr c,L_BC28		;bc22
	sub 00eh		;bc24
	jr L_BC20		;bc26
L_BC28:
	sla a		;bc28
	call de_mas_a		;bc2a
	call dos_tiles		;bc2d   ; dos tiles...
	ld de,00020h		;bc30
	add hl,de			;bc33
	ld de,0bdd7h		;bc34   ; ...y debajo los de 0xBDD7
dos_tiles:		; dos bytes de DE a la VRAM de HL
	ld bc,00002h		;bc37
	jp copia_a_vram		;bc3a
sitio_de_tecla:		; HL = la direccion de la tecla A (0xBDE1); DE = su entrada del LAYOUT
	dec a			;bc3d   ; de 1 a 0
	push af			;bc3e
	sla a		;bc3f
	ld hl,0bde1h		;bc41   ; la direccion de la tecla en 0xBDE1
	call hl_mas_a		;bc44
	ld e,(hl)			;bc47
	inc hl			;bc48
	ld d,(hl)			;bc49
	ex de,hl			;bc4a   ; HL = la direccion
	pop af			;bc4b
	ld de,0d200h		;bc4c   ; DE = su entrada del LAYOUT
	call de_mas_a		;bc4f
	ret			;bc52
layout_cursor:		; izquierda o derecha: la nota anterior o la siguiente, y el cursor la sigue
	ld hl,0d905h		;bc53
	ld a,(0d808h)		;bc56   ; izquierda o derecha
	and 00ch		;bc59
	ret z			;bc5b
	and 004h		;bc5c   ; izquierda?
	jr nz,L_BC82		;bc5e
	ld a,030h		;bc60   ; derecha: hasta la 0x30
	cp (hl)			;bc62
	ret z			;bc63
	ld a,001h		;bc64   ; el efecto 1
	call efecto		;bc66
	inc (hl)			;bc69
	ld a,(hl)			;bc6a
	call byte_de_nota		;bc6b   ; su byte de LAYOUT
	ld a,(hl)			;bc6e   ; el cursor, distinto en las pares y las impares
	bit 0,a		;bc6f
	jr nz,L_BC7B		;bc71
	ld c,056h		;bc73
	ld de,0585ch		;bc75
	jp cursor_derecha		;bc78
L_BC7B:
	ld c,01eh		;bc7b
	ld de,00004h		;bc7d
	jr $+123		;bc80
L_BC82:
	ld a,(hl)			;bc82   ; izquierda: hasta la 0
	or a			;bc83
	ret z			;bc84
	ld a,001h		;bc85   ; el efecto 1
	call efecto		;bc87
	dec (hl)			;bc8a
	ld a,(hl)			;bc8b
	call byte_de_nota		;bc8c   ; su byte de LAYOUT
	ld a,(hl)			;bc8f
	bit 0,a		;bc90
	jr nz,L_BC9B		;bc92
	ld c,056h		;bc94
	ld de,0585ch		;bc96
	jr $+120		;bc99
L_BC9B:
	ld c,01eh		;bc9b
	ld de,00004h		;bc9d
	jr $+113		;bca0
en_lista_bcb6:		; acarreo si A esta en la lista de 0xBCB6
	push hl			;bca2
	ld b,a			;bca3
	ld hl,0bcb6h		;bca4
L_BCA7:
	ld a,(hl)			;bca7   ; de la lista
	inc hl			;bca8
	cp 0ffh		;bca9   ; 0xFF: se acabo
	jr z,L_BCB3		;bcab
	cp b			;bcad   ; esta?
	jr nz,L_BCA7		;bcae
	pop hl			;bcb0
	scf			;bcb1   ; acarreo: esta
	ret			;bcb2
L_BCB3:
	pop hl			;bcb3
	xor a			;bcb4
	ret			;bcb5

; ----------------------------------------------------------------------
; DATOS lista_0xBCB6: 6 valores acabados en 0xFF que recorre 0xBCA2
;   0xbcb6..0xbcbd  (7 bytes)
DATA_lista_0xBCB6:
	defb 007h,00dh,015h,01bh,023h,029h,0ffh	; bcb6

; ======================================================================
; CODIGO 0xbcbd..0xbcca  (13 bytes)
; ======================================================================


byte_de_nota:		; 0xD906 = 0xBCCA[A]
	push hl			;bcbd
	ld hl,0bccah		;bcbe   ; la tabla de 0xBCCA
	call hl_mas_a		;bcc1
	ld a,(hl)			;bcc4   ; el byte de la nota...
	ld (0d906h),a		;bcc5   ; ...a 0xD906
	pop hl			;bcc8
	ret			;bcc9

; ----------------------------------------------------------------------
; DATOS notas_del_teclado: nota -> tecla dibujada, que recorre 0x49A3
;   0xbcca..0xbcfb  (49 bytes)
DATA_notas_del_teclado:
	defb 013h,001h	; bcca
	defb 014h,002h	; bccc
	defb 015h,003h	; bcce
	defb 016h,000h	; bcd0
	defb 017h,004h	; bcd2
	defb 018h,005h	; bcd4
	defb 019h,000h	; bcd6
	defb 01ah,006h	; bcd8
	defb 01bh,007h	; bcda
	defb 01ch,008h	; bcdc
	defb 01dh,000h	; bcde
	defb 01eh,009h	; bce0
	defb 01fh,00ah	; bce2
	defb 020h,000h	; bce4
	defb 021h,00bh	; bce6
	defb 022h,00ch	; bce8
	defb 023h,00dh	; bcea
	defb 024h,000h	; bcec
	defb 025h,00eh	; bcee
	defb 026h,00fh	; bcf0
	defb 027h,000h	; bcf2
	defb 028h,010h	; bcf4
	defb 029h,011h	; bcf6
	defb 02ah,012h	; bcf8
	defb 02bh	; bcfa

; ======================================================================
; CODIGO 0xbcfb..0xbd55  (90 bytes)
; ======================================================================


cursor_derecha:		; los dos sprites del cursor 4 puntos a la derecha, con Y = C y patrones D, E
	ld b,002h		;bcfb
	push hl			;bcfd
	ld hl,0d870h		;bcfe
L_BD01:
	ld (hl),c			;bd01   ; Y = C
	inc hl			;bd02
	ld a,(hl)			;bd03   ; X + 4
	add a,004h		;bd04
	ld (hl),a			;bd06
	inc hl			;bd07
	ld (hl),d			;bd08   ; el patron
	inc hl			;bd09
	inc hl			;bd0a
	ld a,e			;bd0b   ; el segundo sprite, patron E
	ld d,a			;bd0c
	djnz L_BD01		;bd0d
	pop hl			;bd0f
	ret			;bd10
cursor_izquierda:		; lo mismo 4 puntos a la izquierda
	ld b,002h		;bd11
	push hl			;bd13
	ld hl,0d870h		;bd14
L_BD17:
	ld (hl),c			;bd17   ; Y = C
	inc hl			;bd18
	ld a,(hl)			;bd19   ; X - 4
	sub 004h		;bd1a
	ld (hl),a			;bd1c
	inc hl			;bd1d
	ld (hl),d			;bd1e   ; el patron
	inc hl			;bd1f
	inc hl			;bd20
	ld a,e			;bd21   ; el segundo sprite, patron E
	ld d,a			;bd22
	djnz L_BD17		;bd23
	pop hl			;bd25
	ret			;bd26
layout_estado_0:		; la cortina y la pantalla del teclado
	ld a,(0d8f6h)		;bd27   ; con SYN pedido, nada
	or a			;bd2a
	ret nz			;bd2b
	call empieza_cambio		;bd2c
	call cortina_de_salida		;bd2f
	ret p			;bd32
layout_pantalla:		; el teclado, la fuente, los sprites de 0xBD55 y la nota 0
	call pantalla_teclado		;bd33
	call fuente_letras		;bd36
	call fin_de_cambio		;bd39
	ld hl,0bd55h		;bd3c   ; el cursor
	ld de,0d870h		;bd3f
	ld bc,00008h		;bd42
	ldir		;bd45
	xor a			;bd47   ; la nota 0, byte 0x13
	ld (0d905h),a		;bd48
	ld a,013h		;bd4b
	ld (0d906h),a		;bd4d
	ld hl,0d8fah		;bd50
	inc (hl)			;bd53
	ret			;bd54

; ----------------------------------------------------------------------
; DATOS tablas_del_teclado: lo que leen 0xBC0B-0xBC49
;   0xbd55..0xbe41  (236 bytes)
DATA_tablas_del_teclado:
	defb 056h,01ch,058h,008h,056h,01ch,05ch,001h,0ffh,0ffh,067h,0bdh,083h,0bdh,09fh,0bdh	; bd55  V.X.V.\...g.....
	defb 0bbh,0bdh,0d8h,0afh,0d8h,09fh,0d9h,0afh,0d9h,09fh,0dah,0afh,0dah,09fh,0dbh,0afh	; bd65  ................
	defb 0b4h,0b5h,0d5h,0afh,0d5h,09fh,0d6h,0afh,0d6h,09fh,0d7h,0afh,0b4h,0b5h,0c3h,0afh	; bd75  ................
	defb 0c3h,09fh,0c4h,0afh,0c4h,09fh,0c5h,0afh,0c5h,09fh,0c6h,0afh,0b4h,0b5h,0c0h,0afh	; bd85  ................
	defb 0c0h,09fh,0c1h,0afh,0c1h,09fh,0c2h,0afh,0b4h,0b5h,0cah,0afh,0cah,09fh,0cbh,0afh	; bd95  ................
	defb 0cbh,09fh,0cch,0afh,0cch,09fh,0cdh,0afh,0b4h,0b5h,0c7h,0afh,0c7h,09fh,0c8h,0afh	; bda5  ................
	defb 0c8h,09fh,0c9h,0afh,0b4h,0b5h,0d1h,0afh,0d1h,09fh,0d2h,0afh,0d2h,09fh,0d3h,0afh	; bdb5  ................
	defb 0d3h,09fh,0d4h,0afh,0b4h,0b5h,0ceh,0afh,0ceh,09fh,0cfh,0afh,0cfh,09fh,0d0h,0afh	; bdc5  ................
	defb 0b4h,0b5h,0b2h,0b3h,0b4h,0b5h,0b6h,0b7h,008h,016h,024h,031h,0b4h,039h,0a2h,039h	; bdd5  ..........$1.9.9
	defb 0a4h,039h,0a6h,039h,0a8h,039h,0aah,039h,0ach,039h,0aeh,039h,0b0h,039h,0b2h,039h	; bde5  .9.9.9.9.9.9.9.9
	defb 0b6h,039h,0b8h,039h,0bah,039h,0f7h,039h,0f9h,039h,036h,03ah,038h,03ah,03ah,03ah	; bdf5  .9.9.9.9.96:8:::
	defb 073h,03ah,075h,03ah,077h,03ah,079h,03ah,024h,03ah,06dh,03ah,069h,03ah,028h,03ah	; be05  s:u:w:y:$:m:i:(:
	defb 0e7h,039h,02ah,03ah,02ch,03ah,02eh,03ah,0f1h,039h,030h,03ah,032h,03ah,034h,03ah	; be15  .9*:,:.:.90:2:4:
	defb 071h,03ah,06fh,03ah,0f3h,039h,0f5h,039h,0e3h,039h,0e9h,039h,026h,03ah,0ebh,039h	; be25  q:o:.9.9.9.9&:.9
	defb 0efh,039h,06bh,03ah,0e5h,039h,067h,03ah,0edh,039h,065h,03ah	; be35  .9k:.9g:.9e:

; ======================================================================
; CODIGO 0xbe41..0xbe5e  (29 bytes)
; ======================================================================


empieza_demo:		; la intro ensena una pantalla del programa: prepara el programa y elige la siguiente de 0xBE5E
	call prepara_el_programa		;be41   ; timbres, ondas y LAYOUT de fabrica
	ld hl,0d80bh		;be44   ; la demo siguiente...
	inc (hl)			;be47
	ld a,(hl)			;be48
	and 003h		;be49
	ld de,0be5eh		;be4b   ; ...de cuatro (0xBE5E)
	call de_mas_a		;be4e
	ld a,(de)			;be51
	ld (0d8f4h),a		;be52
	xor a			;be55   ; estado 0
	ld (0d8fah),a		;be56
	inc a			;be59   ; 0xD863 = 1: demo en marcha
	ld (0d863h),a		;be5a
	ret			;be5d

; ----------------------------------------------------------------------
; DATOS pantalla_inicial: 0, 1, 3 y 6: la pantalla con que se arranca, por
;   (0xD80B) & 3
;   0xbe5e..0xbe62  (4 bytes)
DATA_pantalla_inicial:
	defb 000h,001h,003h,006h	; be5e

; ======================================================================
; CODIGO 0xbe62..0xbe75  (19 bytes)
; ======================================================================


demo:		; cada cuadro de la demo: la pantalla, y 0xD863 = 0 a los 512 cuadros
	call fase_programa		;be62   ; la pantalla
	ld a,(0d803h)		;be65   ; cada dos cuadros...
	bit 0,a		;be68
	ret z			;be6a
	ld hl,0d80ch		;be6b   ; ...cuenta hasta 256
	inc (hl)			;be6e
	ret nz			;be6f
	xor a			;be70   ; se acabo la demo
	ld (0d863h),a		;be71
	ret			;be74

; ----------------------------------------------------------------------
; DATOS rotulo_push_space_key: lista de 0x4337 hacia 0x3A29: "PUSH SPACE KEY"
;   y "(C)KONAMI 1986"; 0xBE84 es la segunda linea, que parpadea
;   0xbe75..0xbea6  (49 bytes)
DATA_rotulo_push_space_key:
	defb 0aah,03ah,01ah,02bh,02fh,02eh,021h,02dh,029h,000h,011h,019h,018h,016h,0feh,029h	; be75  .:.+/.!-)......)
	defb 03ah,030h,035h,033h,028h,000h,033h,030h,021h,023h,025h,000h,02bh,025h,039h,0ffh	; be85  :053(.30!#%.+%9.
	defb 029h,03ah,000h,000h,030h,02ch,021h,039h,000h,033h,034h,021h,032h,034h,000h,000h	; be95  ):..0,!9.34!24..
	defb 0ffh	; bea5

; ======================================================================
; CODIGO 0xbea6..0xbf00  (90 bytes)
; ======================================================================


efecto_si_en_marcha:		; el efecto A solo con el programa en marcha (bit 6 de 0xD802)
	di			;bea6   ; sin interrupciones
	push hl			;bea7
	ld hl,0d802h		;bea8   ; el programa en marcha?
	bit 6,(hl)		;beab
	jr z,L_BEBC		;bead   ; no: nada
	jr L_BEB3		;beaf
efecto:		; arranca el efecto A en el PSG sin tocar registros
	di			;beb1
	push hl			;beb2
L_BEB3:
	push de			;beb3   ; guarda los registros
	push bc			;beb4
	push af			;beb5
	call arranca_efecto		;beb6   ; arranca el efecto
	pop af			;beb9
	pop bc			;beba
	pop de			;bebb
L_BEBC:
	pop hl			;bebc
	ei			;bebd
	ret			;bebe
arranca_efecto:		; los efectos 0 y 1 van al canal C; los demas a A y B; uno de numero menor no corta al que suena
	ld c,a			;bebf   ; C = el efecto
	ld b,002h		;bec0   ; dos canales desde el A...
	ld hl,0d812h		;bec2
	and 03fh		;bec5
	cp 002h		;bec7   ; ...los efectos 2 en adelante
	jr c,L_BECE		;bec9
	inc b			;becb
	jr L_BED2		;becc
L_BECE:
	dec b			;bece   ; ...o uno, el C
	ld hl,0d81ch		;becf
L_BED2:
	ld a,(hl)			;bed2   ; el que suena
	and 03fh		;bed3
	ld e,a			;bed5
	ld a,c			;bed6
	and 03fh		;bed7
	cp e			;bed9   ; el nuevo es menor: nada
	ret c			;beda
	cp 001h		;bedb   ; el 1 no se corta a si mismo
	jr nz,L_BEE3		;bedd
	ld a,e			;bedf
	cp 001h		;bee0
	ret z			;bee2
L_BEE3:
	ld a,c			;bee3   ; sus listas en 0xBEFE
	add a,a			;bee4
	ld de,0befeh		;bee5
	add a,e			;bee8
	ld e,a			;bee9
	jr nc,L_BEED		;beea
	inc d			;beec
L_BEED:
	dec hl			;beed   ; la cuenta a 1...
	dec hl			;beee
L_BEEF:
	ld (hl),001h		;beef
	inc hl			;bef1
	inc hl			;bef2
	ld (hl),c			;bef3   ; ...el efecto activo...
	inc hl			;bef4
	ld a,(de)			;bef5   ; ...y el puntero a su lista
	ld (hl),a			;bef6
	inc hl			;bef7
	inc de			;bef8
	ld a,(de)			;bef9
	ld (hl),a			;befa
	inc hl			;befb
	inc de			;befc
	djnz L_BEEF		;befd
	ret			;beff

; ----------------------------------------------------------------------
; DATOS tablas_del_final: punteros y datos que leen 0x4793-0x47AC y
;   0xBEF5-0xBEF9
;   0xbf00..0xc000  (256 bytes)
DATA_tablas_del_final:
	defb 03dh,0bfh,014h,0bfh,028h,0bfh,03ch,0bfh,043h,0bfh,04dh,0bfh,057h,0bfh,061h,0bfh	; bf00  =...(.<.C.M.W.a.
	defb 061h,0bfh,061h,0bfh,022h,0c0h,036h,0a0h,036h,090h,036h,080h,036h,070h,036h,060h	; bf10  a.a.".6.6.6.6p6`
	defb 036h,050h,036h,040h,036h,030h,036h,0ffh,022h,0c0h,037h,0a0h,037h,090h,037h,080h	; bf20  6P6@606.".7.7.7.
	defb 037h,070h,037h,060h,037h,050h,037h,040h,037h,030h,037h,0ffh,0ffh,021h,090h,047h	; bf30  7p7`7P7@707..!.G
	defb 070h,047h,0ffh,021h,0c0h,07fh,0a0h,07fh,070h,07fh,060h,07fh,0ffh,021h,0c0h,080h	; bf40  pG.!....p.`..!..
	defb 0a0h,080h,080h,080h,070h,080h,0ffh,021h,0c0h,081h,0a0h,081h,060h,081h,050h,081h	; bf50  ....p..!....`.P.
	defb 0ffh,0ffh,052h,043h,037h,034h,031h,020h,038h,036h,020h,035h,020h,033h,031h,0ffh	; bf60  ..RC741 86 5 31.
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf70  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf80  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bf90  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfa0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfb0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfc0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfd0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfe0  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0bah,0b7h,08ah,081h,08ah,08dh,0ach,08bh,008h,041h,0aah	; bff0  ..............A.
