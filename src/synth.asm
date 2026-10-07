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
l58bch:	equ 0x058bc
l58d0h:	equ 0x058d0
l58f8h:	equ 0x058f8
l5929h:	equ 0x05929
l5968h:	equ 0x05968
l597ch:	equ 0x0597c
l5992h:	equ 0x05992
l59c3h:	equ 0x059c3
l59d9h:	equ 0x059d9
l5a25h:	equ 0x05a25

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
	jp L_455D		;4012
interrupcion:		; la rutina de cada cuadro, por H.KEYI (0xFD9A) desde que 0x4118 acaba
	call 0013eh		;4015   ; BIOS RDVDP - Reads VDP status register | lee el estado del VDP: lo borra
	call 0fd9fh		;4018   ; y llama el mismo a H.TIMI
	di			;401b
	call efectos_por_cuadro		;401c   ; los efectos de sonido del PSG, cada cuadro
	ld hl,0d805h		;401f   ; 0xD805: ocupado (bit 0)
	bit 0,(hl)		;4022
	jr nz,L_4033		;4024   ; si el cuadro anterior no ha acabado, solo los efectos
	inc (hl)			;4026   ; marca ocupado y deja entrar otra interrupcion
	ei			;4027
	call lee_teclas		;4028   ; las teclas
	call fase_de_pantalla		;402b   ; la fase de la pantalla
	ld a,000h		;402e   ; libre
	ld (0d805h),a		;4030
L_4033:
	call 0013eh		;4033   ; BIOS RDVDP - Reads VDP status register | si ha llegado otro cuadro mientras tanto (bit 7)...
	or a			;4036
	di			;4037
	call m,efectos_por_cuadro		;4038   ; ...otra vuelta de los efectos
	ei			;403b
	ret			;403c
escribe_registro_vdp:		; WRTVDP: registro C, valor B
	jp 00047h		;403d   ; BIOS WRTVDP - Writes data in the VDP-register
hl_mas_a:		; HL = HL + A
	add a,l			;4040
	ld l,a			;4041
	ret nc			;4042
	inc h			;4043
	ret			;4044
de_mas_a:		; DE = DE + A
	add a,e			;4045
	ld e,a			;4046
	ret nc			;4047
	inc d			;4048
	ret			;4049
salta_por_tabla:		; salta a la entrada A de la tabla de palabras que sigue al `call`
	pop hl			;404a   ; HL = la tabla, detras del `call`
	add a,a			;404b
	call hl_mas_a		;404c
	ld e,(hl)			;404f   ; DE = la entrada A
	inc hl			;4050
	ld d,(hl)			;4051
	ex de,hl			;4052
	jp (hl)			;4053   ; y alli
init:		; INIT: la llama la BIOS al encontrar el cartucho; deja el arranque para cuando el BASIC termine
	call apunta_slots		;4054   ; 0xD854/0xD855: los slots de las paginas 2 y 1
	ld hl,04069h		;4057   ; los 5 bytes de 0x4069...
	ld de,0fedah		;405a   ; ...a H.STKE (0xFEDA)
	ld bc,00005h		;405d
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
	di			;406e
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
	ld de,0d801h		;4090
	ld bc,006ffh		;4093
	ld (hl),000h		;4096
	ldir		;4098
	call apunta_slots		;409a   ; A = el slot del cartucho...
	ld h,080h		;409d   ; ...tambien en la pagina 2, donde siguen sus graficos
	call 00024h		;409f   ; BIOS ENASLT - Switches to specified slot and page definitively
	ld a,001h		;40a2   ; ocupado: la interrupcion no toca nada
	ld (0d805h),a		;40a4
	call prepara_vdp_y_psg		;40a7   ; VDP, PSG y la VRAM en blanco
	xor a			;40aa
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
	ld a,(0d8f6h)		;40c5
	or a			;40c8
	jr z,bucle_principal		;40c9
	call L_4BA1		;40cb
	xor a			;40ce
	ld (0d8f6h),a		;40cf
	jr bucle_principal		;40d2
apunta_slots:		; 0xD854 = slot de la pagina 2, 0xD855 = slot de la pagina 1 (el cartucho); vuelve con A = 0xD855
	ld de,0d854h		;40d4
	call 00138h		;40d7   ; BIOS RSLREG - Reads the primary slot register | A = registro de slots primarios (RSLREG)
	push af			;40da
	rrca			;40db   ; bits 2-3, la pagina 1, a 0-1
	rrca			;40dc
	call slot_de_la_pagina		;40dd   ; C = slot primario de la pagina 2 y A = su registro secundario
	rrca			;40e0   ; el secundario de la pagina 2 a los bits 2-3
	rrca			;40e1
	call guarda_slot		;40e2   ; 0xD854
	inc de			;40e5
	pop af			;40e6   ; la pagina 1
	call slot_de_la_pagina		;40e7   ; C = slot primario y A = secundario de la pagina 1: 0xD855
guarda_slot:		; (DE) = C con el secundario de los bits 2-3 de A: el formato de slot de ENASLT
	and 00ch		;40ea
	or c			;40ec
	ld (de),a			;40ed
	ret			;40ee
slot_de_la_pagina:		; de los bits 2-3 de A: C = slot primario (+0x80 si esta expandido, 0xFCC1) y A = su registro secundario (0xFCC5)
	rrca			;40ef
	rrca			;40f0
	and 003h		;40f1
	ld c,a			;40f3
	ld b,000h		;40f4
	ld hl,0fcc1h		;40f6
	add hl,bc			;40f9
	ld a,(hl)			;40fa
	and 080h		;40fb
	or c			;40fd
	ld c,a			;40fe
	inc hl			;40ff
	inc hl			;4100
	inc hl			;4101
	inc hl			;4102
	ld a,(hl)			;4103
	ret			;4104
ram_en_la_pagina_2:		; pone en 0x8000-0xBFFF la RAM del ordenador: el slot que 0x40D4 guarda en 0xD854
	ld h,080h		;4105
	ld a,(0d854h)		;4107
	jp 00024h		;410a   ; BIOS ENASLT - Switches to specified slot and page definitively
cartucho_en_la_pagina_2:		; vuelve a poner el cartucho en 0x8000-0xBFFF (0xD855)
	ld h,080h		;410d
	ld a,(0d855h)		;410f
	jp 00024h		;4112   ; BIOS ENASLT - Switches to specified slot and page definitively
efecto_de_sonido:		; arranca el efecto A en el PSG (0xBEB1)
	jp L_BEB1		;4115
interrupcion_sube_el_dac:		; la primera rutina de H.KEYI: lleva el DAC de 0 a 0x80 (el reposo) de uno en uno, un paso por interrupcion
	ld hl,0d856h		;4118   ; 0xD856: el valor que toca (las variables empiezan a 0)
	ld a,(hl)			;411b
	ld (04000h),a		;411c   ; al DAC
	inc a			;411f
	ld (hl),a			;4120
	cp 081h		;4121   ; al llegar a 0x80...
	ret nz			;4123
	ld hl,04015h		;4124   ; ...H.KEYI pasa a 0x4015
	ld (0fd9ch),hl		;4127
	ret			;412a
fase_de_pantalla:		; cada cuadro: 0xD803 cuenta cuadros y salta a la fase 0xD800, con B = el paso 0xD801
	ld hl,0d803h		;412b   ; 0xD803: contador de cuadros
	inc (hl)			;412e
	ld a,(0d800h)		;412f
	cp 003h		;4132
	jr nc,L_413A		;4134   ; en las fases 0, 1 y 2...
	ld hl,04242h		;4136   ; ...vuelve por 0x4242
	push hl			;4139
L_413A:
	ld bc,(0d800h)		;413a   ; C = fase (0xD800), B = paso (0xD801)
	ld a,c			;413e
	call salta_por_tabla		;413f

; ----------------------------------------------------------------------
; DATOS saltos_del_arranque: 9 destinos por la fase (0xD800); la tabla cierra
;   en 0x4154, su entrada mas baja
;   0x4142..0x4154  (18 bytes)
DATA_saltos_del_arranque:
	defw 04154h,041d3h,041dbh,04201h,04227h,0423fh,04242h,04242h	; 4142
	defw 04242h	; 4152  -> L_4242

; ======================================================================
; CODIGO 0x4154..0x4295  (321 bytes)
; ======================================================================


L_4154:
	djnz L_4163		;4154
	ld a,(0d803h)		;4156
	rra			;4159
	ret nc			;415a
	call L_4585		;415b
	ret nz			;415e
	xor a			;415f
	jp L_41F9		;4160
L_4163:
	djnz L_4182		;4163
	ld hl,0d804h		;4165
	dec (hl)			;4168
	ret nz			;4169
	call L_4714		;416a
	ld hl,02200h		;416d
	ld bc,00428h		;4170
	ld a,0ffh		;4173
	call L_4316		;4175
	call L_4754		;4178
	ld a,007h		;417b
	ld (0d910h),a		;417d
	jr L_41FC		;4180
L_4182:
	djnz L_41C5		;4182
	ld a,(0d803h)		;4184
	and 00fh		;4187
	ret nz			;4189
	ld hl,02200h		;418a
	ld de,09e97h		;418d
	ld a,(0d910h)		;4190
	push af			;4193
	call de_mas_a		;4194
	pop af			;4197
	call hl_mas_a		;4198
	ld bc,08500h		;419b
L_419E:
	push bc			;419e
	ld bc,00001h		;419f
	push de			;41a2
	push hl			;41a3
	call L_4303		;41a4
	pop hl			;41a7
	pop de			;41a8
	ld a,008h		;41a9
	call hl_mas_a		;41ab
	ld a,008h		;41ae
	call de_mas_a		;41b0
	pop bc			;41b3
	djnz L_419E		;41b4
	ld hl,0d910h		;41b6
	dec (hl)			;41b9
	ret p			;41ba
	ld de,0be75h		;41bb
	call L_4337		;41be
	xor a			;41c1
	jp L_422B		;41c2
L_41C5:
	call pon_registros_vdp		;41c5
	call L_42DC		;41c8
	call L_43FD		;41cb
	call L_4557		;41ce
	jr L_41FC		;41d1
L_41D3:
	ld hl,0d804h		;41d3
	dec (hl)			;41d6
	ret nz			;41d7
	jp L_4229		;41d8
L_41DB:
	djnz L_41F0		;41db
	call L_BE62		;41dd
	ld a,(0d863h)		;41e0
	or a			;41e3
	ret nz			;41e4
	xor a			;41e5
	ld (0d800h),a		;41e6
	ld a,020h		;41e9
	ld (0d804h),a		;41eb
	jr L_4232		;41ee
L_41F0:
	call L_43B0		;41f0
	ret p			;41f3
	call L_BE41		;41f4
	ld a,020h		;41f7
L_41F9:
	ld (0d804h),a		;41f9
L_41FC:
	ld hl,0d801h		;41fc
	inc (hl)			;41ff
	ret			;4200
L_4201:
	djnz L_421C		;4201
	ld de,0be84h		;4203
	ld a,(0d804h)		;4206
	and 004h		;4209
	jr z,L_4212		;420b
	call L_4337		;420d
	jr L_4215		;4210
L_4212:
	call L_434E		;4212
L_4215:
	ld hl,0d804h		;4215
	dec (hl)			;4218
	jr z,L_41FC		;4219
	ret			;421b
L_421C:
	djnz L_4223		;421c
	call L_437D		;421e
	jr L_4229		;4221
L_4223:
	ld a,050h		;4223
	jr L_41F9		;4225
L_4227:
	djnz L_4237		;4227
L_4229:
	ld a,020h		;4229
L_422B:
	ld (0d804h),a		;422b
	ld hl,0d800h		;422e
	inc (hl)			;4231
L_4232:
	xor a			;4232
	ld (0d801h),a		;4233
	ret			;4236
L_4237:
	ld a,078h		;4237
	ld (0d804h),a		;4239
	jp L_41FC		;423c
L_423F:
	jp L_47DB		;423f
L_4242:
	call L_42B7		;4242
	ld hl,0d852h		;4245
	call L_42A8		;4248
	or a			;424b
	ret z			;424c
	ld hl,0d804h		;424d
	ld (hl),000h		;4250
	ld hl,0d800h		;4252
	ld b,(hl)			;4255
	djnz L_4266		;4256
	and 030h		;4258
	ret z			;425a
	ld a,040h		;425b
	ld (0d802h),a		;425d
	ld (hl),003h		;4260
	inc hl			;4262
	ld (hl),000h		;4263
	ret			;4265
L_4266:
	ld (hl),001h		;4266
	ld a,008h		;4268
	call L_BEA6		;426a
	jp L_4747		;426d
prepara_vdp_y_psg:		; mezclador del PSG, efecto 8, la VRAM a cero y los 8 registros del VDP
	ld a,0b8h		;4270
	call mezclador_psg		;4272
	ld a,008h		;4275
	call efecto_de_sonido		;4277
	ld hl,00000h		;427a
	ld bc,04000h		;427d
	xor a			;4280
	call 00056h		;4281   ; BIOS FILVRM - Fills VRAM with value
pon_registros_vdp:		; los 8 registros del VDP de 0x4295, del R0 al R7
	ld hl,04295h		;4284
	ld d,008h		;4287
	ld c,000h		;4289
L_428B:
	ld b,(hl)			;428b
	call 00047h		;428c   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;428f
	inc c			;4290
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


L_429D:
	ld c,007h		;429d
	jp escribe_registro_vdp		;429f
lee_teclas:		; 0xD807 = teclas pulsadas ahora, 0xD806 = las recien pulsadas
	call L_42B7		;42a2
	ld hl,0d807h		;42a5
L_42A8:
	ld c,(hl)			;42a8
	ld (hl),a			;42a9
	xor c			;42aa
	and (hl)			;42ab
	dec hl			;42ac
	ld (hl),a			;42ad
	push af			;42ae
	ld de,0d8ffh		;42af
	call L_4851		;42b2
	pop af			;42b5
	ret			;42b6
L_42B7:
	ld a,007h		;42b7
	call 00141h		;42b9   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42bc
	rrca			;42bd
	and 020h		;42be
	ld e,a			;42c0
	ld a,008h		;42c1
	call 00141h		;42c3   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;42c6
	rrca			;42c7
	rrca			;42c8
	ld b,a			;42c9
	and 004h		;42ca
	or e			;42cc
	ld c,a			;42cd
	ld a,b			;42ce
	rrca			;42cf
	rrca			;42d0
	ld b,a			;42d1
	and 018h		;42d2
	or c			;42d4
	ld c,a			;42d5
	ld a,b			;42d6
	rrca			;42d7
	and 003h		;42d8
	or c			;42da
	ret			;42db
L_42DC:
	call L_43C9		;42dc
	ld hl,03800h		;42df
	ld bc,00300h		;42e2
	xor a			;42e5
	jp 00056h		;42e6   ; BIOS FILVRM - Fills VRAM with value
L_42E9:
	ex af,af'			;42e9
	call 00053h		;42ea   ; BIOS SETWRT - Enables VDP to write
	exx			;42ed
	ld a,(00007h)		;42ee
	ld c,a			;42f1
	exx			;42f2
	ex af,af'			;42f3
	ret			;42f4
L_42F5:
	call 00050h		;42f5   ; BIOS SETRD - Enables VDP to read
	exx			;42f8
	ld a,(00006h)		;42f9
	ld c,a			;42fc
	exx			;42fd
	ret			;42fe
L_42FF:
	ex de,hl			;42ff
	jp 0005ch		;4300   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_4303:
	exx			;4303
	ld b,003h		;4304
L_4306:
	exx			;4306
	push bc			;4307
	push de			;4308
	call L_42FF		;4309
	ld de,00800h		;430c
	add hl,de			;430f
	pop de			;4310
	pop bc			;4311
	exx			;4312
	djnz L_4306		;4313
	ret			;4315
L_4316:
	ld d,003h		;4316
L_4318:
	push bc			;4318
	push de			;4319
	call 00056h		;431a   ; BIOS FILVRM - Fills VRAM with value
	ld de,00800h		;431d
	add hl,de			;4320
	pop de			;4321
	pop bc			;4322
	dec d			;4323
	jr nz,L_4318		;4324
	ret			;4326
L_4327:
	ld b,003h		;4327
L_4329:
	push bc			;4329
	push de			;432a
	call L_4358		;432b
	ld de,00800h		;432e
	add hl,de			;4331
	pop de			;4332
	pop bc			;4333
	djnz L_4329		;4334
	ret			;4336
L_4337:
	ld c,0ffh		;4337
L_4339:
	ex de,hl			;4339
	ld e,(hl)			;433a
	inc hl			;433b
	ld d,(hl)			;433c
	ex de,hl			;433d
	inc de			;433e
L_433F:
	ld a,(de)			;433f
	inc de			;4340
	ld b,a			;4341
	inc b			;4342
	ret z			;4343
	inc b			;4344
	jr z,L_4339		;4345
	and c			;4347
	call 0004dh		;4348   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;434b
	jr L_433F		;434c
L_434E:
	ld c,000h		;434e
	jr L_4339		;4350
L_4352:
	ex de,hl			;4352
	ld e,(hl)			;4353
	inc hl			;4354
	ld d,(hl)			;4355
	ex de,hl			;4356
	inc de			;4357
L_4358:
	call L_42E9		;4358
L_435B:
	ld a,(de)			;435b
	and a			;435c
	ret z			;435d
	inc de			;435e
	ld b,a			;435f
	and 07fh		;4360
	cp b			;4362
	jr z,L_4373		;4363
	and a			;4365
	jr z,L_4352		;4366
	ld b,a			;4368
L_4369:
	ld a,(de)			;4369
	inc de			;436a
	exx			;436b
	out (c),a		;436c
	exx			;436e
	djnz L_4369		;436f
	jr L_435B		;4371
L_4373:
	ld a,(de)			;4373
	inc de			;4374
L_4375:
	exx			;4375
	out (c),a		;4376
	exx			;4378
	djnz L_4375		;4379
	jr L_435B		;437b
L_437D:
	ld hl,0c000h		;437d
	ld bc,017ffh		;4380
	call L_43A8		;4383
	ld hl,0d856h		;4386
	ld bc,003a9h		;4389
	call L_43A8		;438c
	ld a,(0ffa7h)		;438f
	cp 0c9h		;4392
	jr nz,L_439B		;4394
	ld a,001h		;4396
	ld (0d9deh),a		;4398
L_439B:
	call L_55BC		;439b
	call L_4B21		;439e
	ld de,08000h		;43a1
	call L_4352		;43a4
	ret			;43a7
L_43A8:
	ld d,h			;43a8
	ld e,l			;43a9
	inc e			;43aa
	ld (hl),000h		;43ab
	ldir		;43ad
	ret			;43af
L_43B0:
	ld hl,0d804h		;43b0
	dec (hl)			;43b3
	ret m			;43b4
	ld a,(hl)			;43b5
	ld h,038h		;43b6
	xor 01fh		;43b8
	add a,000h		;43ba
	ld l,a			;43bc
	ld b,018h		;43bd
	xor a			;43bf
	ld de,00020h		;43c0
L_43C3:
	call 0004dh		;43c3   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;43c6
	djnz L_43C3		;43c7
L_43C9:
	ld hl,0d870h		;43c9
	ld bc,0007fh		;43cc
	call L_43A8		;43cf
	ld hl,03b00h		;43d2
	ld a,0d0h		;43d5
	call 0004dh		;43d7   ; BIOS WRTVRM - Writes data in VRAM
	xor a			;43da
	ret			;43db
L_43DC:
	ld c,010h		;43dc
	jr L_43E2		;43de
L_43E0:
	ld c,040h		;43e0
L_43E2:
	ld a,(de)			;43e2
	and 00fh		;43e3
	add a,c			;43e5
	call 0004dh		;43e6   ; BIOS WRTVRM - Writes data in VRAM
	dec b			;43e9
	ret z			;43ea
	dec hl			;43eb
	ld a,(de)			;43ec
	rra			;43ed
	rra			;43ee
	rra			;43ef
	rra			;43f0
	and 00fh		;43f1
	add a,010h		;43f3
	call 0004dh		;43f5   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;43f8
	dec hl			;43f9
	djnz L_43E2		;43fa
	ret			;43fc
L_43FD:
	call L_4536		;43fd
	ld de,04414h		;4400
	ld hl,02080h		;4403
	call L_4327		;4406
	ld a,0f0h		;4409
	ld hl,00080h		;440b
	ld bc,00158h		;440e
	jp L_4316		;4411

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


L_4536:
	ld hl,02000h		;4536
	ld bc,00080h		;4539
	xor a			;453c
	call L_4316		;453d
	ld hl,00000h		;4540
	ld de,00008h		;4543
	ld b,010h		;4546
L_4548:
	push bc			;4548
	ld bc,00008h		;4549
	push hl			;454c
	call L_4316		;454d
	pop hl			;4550
	add hl,de			;4551
	inc a			;4552
	pop bc			;4553
	djnz L_4548		;4554
	ret			;4556
L_4557:
	ld hl,00000h		;4557
	ld (0d80eh),hl		;455a
L_455D:
	ld de,045b9h		;455d
	call L_4352		;4560
	ld hl,00a00h		;4563
	ld bc,003c0h		;4566
	xor a			;4569
	call 00056h		;456a   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03907h		;456d
	ld a,040h		;4570
	ld c,006h		;4572
	ld de,0000ch		;4574
L_4577:
	ld b,014h		;4577
L_4579:
	call 0004dh		;4579   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;457c
	inc a			;457d
	djnz L_4579		;457e
	add hl,de			;4580
	dec c			;4581
	jr nz,L_4577		;4582
	ret			;4584
L_4585:
	ld bc,(0d80eh)		;4585
	ld a,0ech		;4589
	inc b			;458b
L_458C:
	add a,014h		;458c
	djnz L_458C		;458e
	ld l,a			;4590
	ld h,b			;4591
	add hl,hl			;4592
	add hl,hl			;4593
	add hl,hl			;4594
	ld de,00a00h		;4595
	add hl,de			;4598
	ld a,c			;4599
	call hl_mas_a		;459a
	ld b,014h		;459d
	ld de,00008h		;459f
	ld a,0f0h		;45a2
L_45A4:
	call 0004dh		;45a4   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;45a7
	djnz L_45A4		;45a8
	ld hl,0d80eh		;45aa
	ld a,(hl)			;45ad
	inc a			;45ae
	and 007h		;45af
	ld (hl),a			;45b1
	ret nz			;45b2
	inc hl			;45b3
	inc (hl)			;45b4
	ld a,(hl)			;45b5
	cp 006h		;45b6
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


L_4708:
	ld de,09e97h		;4708
	ld hl,02200h		;470b
	ld bc,00428h		;470e
	call L_4303		;4711
L_4714:
	ld b,0e0h		;4714
	call L_429D		;4716
	call L_42DC		;4719
	call L_43FD		;471c
	ld a,070h		;471f
	ld hl,00248h		;4721
	ld bc,00368h		;4724
	call L_4316		;4727
	ld hl,00620h		;472a
	ld bc,00008h		;472d
	call L_4316		;4730
	ld a,0e0h		;4733
	ld hl,005b0h		;4735
	ld bc,00070h		;4738
	call L_4316		;473b
	ld de,0a2bfh		;473e
	ld hl,00200h		;4741
	jp L_4327		;4744
L_4747:
	call L_4708		;4747
	call L_4754		;474a
	ld de,0be75h		;474d
	call L_4337		;4750
	ret			;4753
L_4754:
	ld de,0a2e5h		;4754
	jp L_4352		;4757
efectos_por_cuadro:		; los efectos de sonido: R7 = 0xB8 y los tres canales de 0xD810, 5 bytes cada uno
	ld e,0b8h		;475a
	ld a,007h		;475c
	call 00093h		;475e   ; BIOS WRTPSG - Writes data to PSG-register
	ld c,001h		;4761
	ld ix,0d810h		;4763
	exx			;4767
	ld b,003h		;4768
	ld de,00005h		;476a
L_476D:
	exx			;476d
	ld a,(ix+002h)		;476e
	or a			;4771
	call nz,L_4786		;4772
	inc c			;4775
	inc c			;4776
	exx			;4777
	add ix,de		;4778
	djnz L_476D		;477a
	ret			;477c
mezclador_psg:		; R7 del PSG = A (y copia en 0xD81F)
	ld (0d81fh),a		;477d
	ld e,a			;4780
	ld a,007h		;4781
	jp 00093h		;4783   ; BIOS WRTPSG - Writes data to PSG-register
L_4786:
	ld a,(ix+002h)		;4786
	dec (ix+000h)		;4789
	ret nz			;478c
	ld l,(ix+003h)		;478d
	ld h,(ix+004h)		;4790
	ld a,(hl)			;4793
	cp 0ffh		;4794
	jr z,L_47CE		;4796
	and 0f0h		;4798
	cp 020h		;479a
	jr nz,L_47A5		;479c
	ld a,(hl)			;479e
	and 00fh		;479f
	ld (ix+001h),a		;47a1
	inc hl			;47a4
L_47A5:
	ld a,(hl)			;47a5
	and 0f0h		;47a6
	ld b,a			;47a8
	xor (hl)			;47a9
	ld d,a			;47aa
	inc hl			;47ab
	ld e,(hl)			;47ac
	inc hl			;47ad
	ld (ix+003h),l		;47ae
	ld (ix+004h),h		;47b1
	ex de,hl			;47b4
	ld a,c			;47b5
	ld e,h			;47b6
	call 00093h		;47b7   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;47ba
	dec a			;47bb
	ld e,l			;47bc
	call 00093h		;47bd   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,b			;47c0
	rrca			;47c1
	rrca			;47c2
	rrca			;47c3
	rrca			;47c4
	ld h,a			;47c5
	ld a,(ix+001h)		;47c6
	ld (ix+000h),a		;47c9
	jr L_47D3		;47cc
L_47CE:
	xor a			;47ce
	ld (ix+002h),a		;47cf
	ld h,a			;47d2
L_47D3:
	ld a,c			;47d3
	rrca			;47d4
	add a,088h		;47d5
	ld e,h			;47d7
	jp 00093h		;47d8   ; BIOS WRTPSG - Writes data to PSG-register
L_47DB:
	call L_47EB		;47db
L_47DE:
	ld hl,03b00h		;47de
	ld de,0d870h		;47e1
	ld bc,00080h		;47e4
	ex de,hl			;47e7
	jp 0005ch		;47e8   ; BIOS LDIRVM - Block transfers to VRAM from memory
L_47EB:
	ld a,(0d904h)		;47eb
	or a			;47ee
	ret nz			;47ef
	call L_4817		;47f0
	ld a,(0d901h)		;47f3
	or a			;47f6
	jr nz,L_47FF		;47f7
	call L_48AC		;47f9
	call L_486D		;47fc
L_47FF:
	ld a,(0d8f4h)		;47ff
	call salta_por_tabla		;4802

; ----------------------------------------------------------------------
; DATOS saltos_por_pantalla: 9 destinos por (0xD8F4), la pantalla en curso;
;   cierra en 0x4817, que llama 0x47F0
;   0x4805..0x4817  (18 bytes)
DATA_saltos_por_pantalla:
	defw 0a5aah,0adf7h,048d9h,0490bh,0b5dbh,0b3afh,0b5c8h,052b7h	; 4805
	defw 0bb6dh	; 4815  -> L_BB6D

; ======================================================================
; CODIGO 0x4817..0x48f4  (221 bytes)
; ======================================================================


L_4817:
	ld a,(0d802h)		;4817
	and 040h		;481a
	ret z			;481c
	ld b,000h		;481d
L_481F:
	ld a,b			;481f
	call 00141h		;4820   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4823
	or 000h		;4824
	jr nz,L_4831		;4826
	inc b			;4828
	ld a,b			;4829
	cp 009h		;482a
	jr c,L_481F		;482c
	xor a			;482e
	jr L_4842		;482f
L_4831:
	ld d,b			;4831
	ld b,008h		;4832
	ld c,000h		;4834
L_4836:
	inc c			;4836
	rrca			;4837
	jr c,L_483D		;4838
	djnz L_4836		;483a
	ret			;483c
L_483D:
	ld a,d			;483d
	rlca			;483e
	rlca			;483f
	rlca			;4840
	add a,c			;4841
L_4842:
	ld hl,0d8f2h		;4842
	ld b,a			;4845
	ld c,(hl)			;4846
	ld (hl),a			;4847
	cp c			;4848
	jr nz,L_484C		;4849
	xor a			;484b
L_484C:
	dec hl			;484c
	ld (hl),a			;484d
	ld de,0d8fdh		;484e
L_4851:
	ld c,a			;4851
	inc hl			;4852
	cp (hl)			;4853
	ld b,(hl)			;4854
	inc hl			;4855
	jr z,L_4866		;4856
	ld a,(de)			;4858
	cp b			;4859
	jr nz,L_4866		;485a
	inc de			;485c
	ld a,(de)			;485d
	cp 028h		;485e
	jr nc,L_486B		;4860
	inc a			;4862
	ld (de),a			;4863
	ld (hl),c			;4864
	ret			;4865
L_4866:
	ld a,b			;4866
	ld (de),a			;4867
	inc de			;4868
	xor a			;4869
	ld (de),a			;486a
L_486B:
	ld (hl),b			;486b
	ret			;486c
L_486D:
	ld a,(0d802h)		;486d
	and 040h		;4870
	ret z			;4872
	ld hl,0d8f1h		;4873
	ld a,(hl)			;4876
L_4877:
	cp 036h		;4877
	ret c			;4879
	cp 03bh		;487a
	ret nc			;487c
	sub 036h		;487d
	ld c,a			;487f
	ld a,(0d8f0h)		;4880
	or a			;4883
	jr z,L_488D		;4884
	ld a,005h		;4886
	add a,c			;4888
	ld c,a			;4889
	cp 009h		;488a
	ret nc			;488c
L_488D:
	ld a,(0d8f4h)		;488d
	ld (0d8fbh),a		;4890
	ld a,(0d8fah)		;4893
	ld (0d8f5h),a		;4896
	ld a,c			;4899
	ld (0d8f4h),a		;489a
	xor a			;489d
	ld (0d8fah),a		;489e
	ld a,020h		;48a1
	ld (0d804h),a		;48a3
	ld a,005h		;48a6
	call L_BEB1		;48a8
	ret			;48ab
L_48AC:
	ld a,(0d8f1h)		;48ac
	cp 031h		;48af
	ret nz			;48b1
L_48B2:
	ld a,(0d802h)		;48b2
	and 040h		;48b5
	ret z			;48b7
	ld hl,0d8f0h		;48b8
	ld a,(hl)			;48bb
	or a			;48bc
	jr nz,L_48C2		;48bd
	inc a			;48bf
	jr L_48C3		;48c0
L_48C2:
	xor a			;48c2
L_48C3:
	ld (hl),a			;48c3
L_48C4:
	ld a,(0d8f0h)		;48c4
	ld de,08a41h		;48c7
	and a			;48ca
	jr z,L_48D0		;48cb
	ld de,08a81h		;48cd
L_48D0:
	ld hl,03ac0h		;48d0
	ld bc,00040h		;48d3
	jp L_42FF		;48d6
L_48D9:
	call L_4936		;48d9
	ret p			;48dc
	ld de,048f4h		;48dd
	call L_4352		;48e0
	ld hl,04cd4h		;48e3
	ld de,0d870h		;48e6
	ld bc,00010h		;48e9
	ldir		;48ec
	ld a,002h		;48ee
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


L_490B:
	ld a,(0d8fah)		;490b
	dec a			;490e
	jp m,L_491B		;490f
	ld a,(0d802h)		;4912
	and 040h		;4915
	ret z			;4917
	jp L_5D3A		;4918
L_491B:
	call L_4936		;491b
	ret p			;491e
	call L_B392		;491f
	ld hl,04946h		;4922
	ld de,0d870h		;4925
	ld bc,00008h		;4928
	ldir		;492b
	xor a			;492d
	ld (0d907h),a		;492e
	ld hl,0d8fah		;4931
	inc (hl)			;4934
	ret			;4935
L_4936:
	call L_49C7		;4936
	call L_43B0		;4939
	ret p			;493c
	call L_494E		;493d
	call L_49C4		;4940
	xor a			;4943
	dec a			;4944
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


L_494E:
	call L_B32E		;494e
	call L_B33E		;4951
	ld de,0925ah		;4954
	ld hl,02080h		;4957
	call L_4327		;495a
	ld de,092f4h		;495d
	ld hl,02458h		;4960
	call L_4327		;4963
	ld de,09559h		;4966
	ld hl,00080h		;4969
	call L_4327		;496c
	ld de,095eah		;496f
	ld hl,00458h		;4972
	call L_4327		;4975
	ld a,(0002ch)		;4978
	and 00fh		;497b
	jr z,L_4991		;497d
	ld de,097fdh		;497f
	ld hl,02600h		;4982
	call L_4327		;4985
	ld de,098dfh		;4988
	ld hl,00600h		;498b
	call L_4327		;498e
L_4991:
	ld de,09988h		;4991
	call L_4352		;4994
	ld hl,0d200h		;4997
	ld a,001h		;499a
L_499C:
	push af			;499c
	ld b,0ffh		;499d
	ld de,0bccah		;499f
L_49A2:
	inc b			;49a2
	ld a,(de)			;49a3
	inc de			;49a4
	cp (hl)			;49a5
	jr nz,L_49A2		;49a6
	ld a,b			;49a8
	ld (0d905h),a		;49a9
	pop af			;49ac
	push af			;49ad
	push hl			;49ae
	call L_BBED		;49af
	pop hl			;49b2
	pop af			;49b3
	inc a			;49b4
	cp 016h		;49b5
	jr nz,L_49BB		;49b7
	inc a			;49b9
	inc hl			;49ba
L_49BB:
	inc hl			;49bb
	cp 031h		;49bc
	jr c,L_499C		;49be
	call L_B32A		;49c0
	ret			;49c3
L_49C4:
	xor a			;49c4
	jr L_49C9		;49c5
L_49C7:
	ld a,001h		;49c7
L_49C9:
	ld (0d901h),a		;49c9
	ret			;49cc
L_49CD:
	exx			;49cd
	push af			;49ce
	ld de,00000h		;49cf
	ld hl,05800h		;49d2
	ld c,a			;49d5
	and 03fh		;49d6
	ld b,a			;49d8
	or a			;49d9
	jr z,L_49E0		;49da
L_49DC:
	ld e,006h		;49dc
	djnz L_49DC		;49de
L_49E0:
	add hl,de			;49e0
	ld e,(hl)			;49e1
	inc hl			;49e2
	ld d,(hl)			;49e3
	push de			;49e4
	inc hl			;49e5
	ld e,(hl)			;49e6
	inc hl			;49e7
	ld d,(hl)			;49e8
	inc hl			;49e9
	ld c,(hl)			;49ea
	inc hl			;49eb
	ld b,(hl)			;49ec
	pop hl			;49ed
	ld a,c			;49ee
	and 0c0h		;49ef
	jr z,L_49FF		;49f1
	cp 040h		;49f3
	jr c,L_4A04		;49f5
	cp 080h		;49f7
	jr c,L_4A09		;49f9
	cp 0c0h		;49fb
	jr c,L_4A0E		;49fd
L_49FF:
	call L_42FF		;49ff
	jr L_4A11		;4a02
L_4A04:
	call L_4352		;4a04
	jr L_4A11		;4a07
L_4A09:
	call L_4303		;4a09
	jr L_4A11		;4a0c
L_4A0E:
	call L_4316		;4a0e
L_4A11:
	pop af			;4a11
	exx			;4a12
	ret			;4a13
L_4A14:
	ld a,00ah		;4a14
	ld (0d873h),a		;4a16
	ld a,001h		;4a19
	ld (0d877h),a		;4a1b
	ld a,001h		;4a1e
	jr L_4A2A		;4a20
L_4A22:
	xor a			;4a22
	ld (0d873h),a		;4a23
	ld (0d877h),a		;4a26
	xor a			;4a29
L_4A2A:
	ld (0d8f8h),a		;4a2a
	call L_4B04		;4a2d
	ld a,(hl)			;4a30
	or a			;4a31
	ret z			;4a32
	cp 013h		;4a33
	jr c,L_4A9C		;4a35
	sub 013h		;4a37
	add a,044h		;4a39
	ld e,a			;4a3b
	ld d,039h		;4a3c
	ex de,hl			;4a3e
	call L_4B0F		;4a3f
	ld b,001h		;4a42
	ld de,04b63h		;4a44
	ld a,(0d8f8h)		;4a47
	or a			;4a4a
	jr nz,L_4A4E		;4a4b
	inc de			;4a4d
L_4A4E:
	ld a,(00007h)		;4a4e
	ld c,a			;4a51
L_4A52:
	ld a,(de)			;4a52
	out (c),a		;4a53
	inc de			;4a55
	djnz L_4A52		;4a56
	ld a,(0d8f8h)		;4a58
	or a			;4a5b
	jr z,L_4AC2		;4a5c
	call L_4AE4		;4a5e
	call L_4B04		;4a61
	ld de,0d870h		;4a64
	ld a,(hl)			;4a67
	cp 013h		;4a68
	jr c,L_4A85		;4a6a
	sub 013h		;4a6c
	jr z,L_4A75		;4a6e
	ld b,a			;4a70
L_4A71:
	add a,007h		;4a71
	djnz L_4A71		;4a73
L_4A75:
	ex de,hl			;4a75
	ld (hl),056h		;4a76
	inc hl			;4a78
	add a,019h		;4a79
	ld (hl),a			;4a7b
	inc hl			;4a7c
	inc hl			;4a7d
	inc hl			;4a7e
	ld (hl),056h		;4a7f
	inc hl			;4a81
	ld (hl),a			;4a82
	jr L_4A99		;4a83
L_4A85:
	ex de,hl			;4a85
	ld (hl),041h		;4a86
	dec a			;4a88
	ld de,04b2dh		;4a89
	call de_mas_a		;4a8c
	inc hl			;4a8f
	ld a,(de)			;4a90
	ld (hl),a			;4a91
	inc hl			;4a92
	inc hl			;4a93
	inc hl			;4a94
	ld (hl),041h		;4a95
	inc hl			;4a97
	ld (hl),a			;4a98
L_4A99:
	jp L_47DE		;4a99
L_4A9C:
	dec a			;4a9c
	add a,a			;4a9d
	ld hl,04b3fh		;4a9e
	call hl_mas_a		;4aa1
	ld d,038h		;4aa4
	ld e,(hl)			;4aa6
	inc hl			;4aa7
	ld a,(0d8f8h)		;4aa8
	or a			;4aab
	jr nz,L_4AB3		;4aac
	ld a,(hl)			;4aae
	add a,006h		;4aaf
	jr L_4AB4		;4ab1
L_4AB3:
	ld a,(hl)			;4ab3
L_4AB4:
	ld hl,04b65h		;4ab4
	call hl_mas_a		;4ab7
	ex de,hl			;4aba
	call L_4B0F		;4abb
	ld b,002h		;4abe
	jr L_4A4E		;4ac0
L_4AC2:
	call cartucho_en_la_pagina_2		;4ac2
	ld a,(0dc47h)		;4ac5
	call L_BC3D		;4ac8
	ld a,(de)			;4acb
	or a			;4acc
	ret z			;4acd
	push hl			;4ace
	ld hl,0bccah		;4acf
	ld b,0ffh		;4ad2
L_4AD4:
	inc b			;4ad4
	cp (hl)			;4ad5
	inc hl			;4ad6
	jr nz,L_4AD4		;4ad7
	ld a,b			;4ad9
	ld (0d905h),a		;4ada
	pop hl			;4add
	call L_BC01		;4ade
	jp ram_en_la_pagina_2		;4ae1
L_4AE4:
	call cartucho_en_la_pagina_2		;4ae4
	ld a,(0dc47h)		;4ae7
	call L_BC3D		;4aea
	ld de,04b00h		;4aed
	call L_BC37		;4af0
	ld de,00020h		;4af3
	add hl,de			;4af6
	ld de,04b02h		;4af7
	call L_BC37		;4afa
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


L_4B04:
	ld a,(0dc47h)		;4b04
	dec a			;4b07
	ld hl,0d200h		;4b08
	call hl_mas_a		;4b0b
	ret			;4b0e
L_4B0F:
	push af			;4b0f
	ld a,(00007h)		;4b10
	inc a			;4b13
	ld c,a			;4b14
	ld a,l			;4b15
	out (c),a		;4b16
	ld a,h			;4b18
	and 03fh		;4b19
	or 040h		;4b1b
	out (c),a		;4b1d
	pop af			;4b1f
	ret			;4b20
L_4B21:
	ld hl,04b71h		;4b21
	ld de,0d200h		;4b24
	ld bc,00030h		;4b27
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


L_4BA1:
	ld a,(0d81ch)		;4ba1
	or a			;4ba4
	jr nz,L_4BA1		;4ba5
	ld a,001h		;4ba7
	ld (0d904h),a		;4ba9
	call L_ADDB		;4bac
	ld de,0dc00h		;4baf
	ld bc,00019h		;4bb2
	ldir		;4bb5
	call L_55F0		;4bb7
	xor a			;4bba
	ld hl,03ac0h		;4bbb
	ld bc,00040h		;4bbe
	call 00056h		;4bc1   ; BIOS FILVRM - Fills VRAM with value
	ld a,(0dc47h)		;4bc4
	call L_4877		;4bc7
	xor a			;4bca
	ld (0d903h),a		;4bcb
	ld (0d907h),a		;4bce
	ld (0d902h),a		;4bd1
	ld (0d904h),a		;4bd4
	ei			;4bd7
	ret			;4bd8
L_4BD9:
	ei			;4bd9
	ld hl,0d907h		;4bda
	ld a,(hl)			;4bdd
	and 00fh		;4bde
	jr nz,L_4C1A		;4be0
	ld a,(hl)			;4be2
	or a			;4be3
	jr z,L_4BF6		;4be4
	and 0f0h		;4be6
	rrca			;4be8
	rrca			;4be9
	rrca			;4bea
	rrca			;4beb
	cp 005h		;4bec
	jr nc,L_4C1A		;4bee
	ld b,a			;4bf0
	xor a			;4bf1
L_4BF2:
	add a,008h		;4bf2
	djnz L_4BF2		;4bf4
L_4BF6:
	ld de,04c61h		;4bf6
	call de_mas_a		;4bf9
	di			;4bfc
	ld b,002h		;4bfd
L_4BFF:
	ld a,(de)			;4bff
	out (099h),a		;4c00
	inc de			;4c02
	ld a,(de)			;4c03
	and 03fh		;4c04
	or 040h		;4c06
	out (099h),a		;4c08
	ld a,(00006h)		;4c0a
	ld c,a			;4c0d
	inc de			;4c0e
	ld a,(de)			;4c0f
	out (c),a		;4c10
	inc de			;4c12
	ld a,(de)			;4c13
	out (c),a		;4c14
	inc de			;4c16
	djnz L_4BFF		;4c17
	ei			;4c19
L_4C1A:
	ld hl,0d907h		;4c1a
	inc (hl)			;4c1d
	ld de,0d903h		;4c1e
	ld a,(0d902h)		;4c21
	ld b,a			;4c24
	or a			;4c25
	jr nz,$+99		;4c26
	ld hl,0d871h		;4c28
	inc (hl)			;4c2b
	ld a,(hl)			;4c2c
	cp 098h		;4c2d
	jr c,L_4C37		;4c2f
	xor a			;4c31
	ld (de),a			;4c32
	inc a			;4c33
	jp L_4CA7		;4c34
L_4C37:
	and 001h		;4c37
	jr nz,L_4C43		;4c39
	ld a,(de)			;4c3b
	inc a			;4c3c
	cp 003h		;4c3d
	jr c,L_4C42		;4c3f
	xor a			;4c41
L_4C42:
	ld (de),a			;4c42
L_4C43:
	ld a,(de)			;4c43
	add a,a			;4c44
	ld de,04c5bh		;4c45
	call de_mas_a		;4c48
	ex de,hl			;4c4b
	ld c,(hl)			;4c4c
	inc hl			;4c4d
	ld b,(hl)			;4c4e
	ex de,hl			;4c4f
	ld a,(hl)			;4c50
	inc hl			;4c51
	ld (hl),c			;4c52
	inc hl			;4c53
	inc hl			;4c54
	inc hl			;4c55
	ld (hl),a			;4c56
	inc hl			;4c57
	ld (hl),b			;4c58
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
	djnz L_4CBD		;4c89
	ld hl,04ce4h		;4c8b
	ld a,(de)			;4c8e
	inc a			;4c8f
	ld (de),a			;4c90
	cp 014h		;4c91
	jr nc,L_4CA5		;4c93
	bit 2,a		;4c95
	jr nz,L_4C9C		;4c97
	ld hl,04cf4h		;4c99
L_4C9C:
	ld de,0d870h		;4c9c
	ld bc,00010h		;4c9f
	ldir		;4ca2
	ret			;4ca4
L_4CA5:
	ld a,002h		;4ca5
L_4CA7:
	ld (0d902h),a		;4ca7
	xor a			;4caa
	ld hl,03ad4h		;4cab
	ld bc,00002h		;4cae
	call 00056h		;4cb1   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03af4h		;4cb4
	ld bc,00002h		;4cb7
	jp 00056h		;4cba   ; BIOS FILVRM - Fills VRAM with value
L_4CBD:
	ld hl,0d872h		;4cbd
	ex de,hl			;4cc0
	inc (hl)			;4cc1
	ld bc,0383ch		;4cc2
	bit 3,(hl)		;4cc5
	jr z,L_4CCC		;4cc7
	ld bc,04044h		;4cc9
L_4CCC:
	ex de,hl			;4ccc
	ld (hl),b			;4ccd
	inc hl			;4cce
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


L_4D04:
	call ram_en_la_pagina_2		;4d04
	di			;4d07
	ld a,0ffh		;4d08
	call 000eah		;4d0a   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jr c,L_4D78		;4d0d
	ld a,(0db18h)		;4d0f
	call L_4E5A		;4d12
	ld b,010h		;4d15
L_4D17:
	ld a,(0db18h)		;4d17
	call L_4D82		;4d1a
	djnz L_4D17		;4d1d
	xor a			;4d1f
	call 000eah		;4d20   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jr c,L_4D78		;4d23
	ld hl,0db0fh		;4d25
	ld b,007h		;4d28
L_4D2A:
	ld a,(hl)			;4d2a
	call L_4D82		;4d2b
	inc hl			;4d2e
	djnz L_4D2A		;4d2f
	xor a			;4d31
	call 000eah		;4d32   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	jr c,L_4D78		;4d35
	ld hl,0dcfeh		;4d37
	ld b,002h		;4d3a
L_4D3C:
	ld a,(hl)			;4d3c
	call L_4D82		;4d3d
	inc hl			;4d40
	djnz L_4D3C		;4d41
	dec hl			;4d43
	ld b,(hl)			;4d44
	dec hl			;4d45
	ld c,(hl)			;4d46
	ld a,(0db18h)		;4d47
	cp 023h		;4d4a
	jr nz,L_4D54		;4d4c
	ld a,(0dcfdh)		;4d4e
	call L_4D82		;4d51
L_4D54:
	push bc			;4d54
	xor a			;4d55
	call 000eah		;4d56   ; BIOS TAPOON - Turns on the cassette motor and writes the header
	pop bc			;4d59
	jr c,L_4D78		;4d5a
	ld hl,(0dbf0h)		;4d5c
L_4D5F:
	ld a,(hl)			;4d5f
	call L_4D82		;4d60
	jr c,L_4D78		;4d63
	inc hl			;4d65
	dec bc			;4d66
	ld a,b			;4d67
	or c			;4d68
	jr nz,L_4D5F		;4d69
	ld b,005h		;4d6b
	call L_4E6F		;4d6d
	call 000f0h		;4d70   ; BIOS TAPOOF - Stops writing on the tape
	call cartucho_en_la_pagina_2		;4d73
	ei			;4d76
	ret			;4d77
L_4D78:
	xor a			;4d78
	call 000f3h		;4d79   ; BIOS STMOTR - Sets the cassette motor action
	call cartucho_en_la_pagina_2		;4d7c
	scf			;4d7f
	ei			;4d80
	ret			;4d81
L_4D82:
	push hl			;4d82
	push bc			;4d83
	call 000edh		;4d84   ; BIOS TAPOUT - Writes data on the tape
	pop bc			;4d87
	pop hl			;4d88
	ret			;4d89
L_4D8A:
	jr L_4D8F		;4d8a
L_4D8C:
	call ram_en_la_pagina_2		;4d8c
L_4D8F:
	di			;4d8f
	ld a,(0db18h)		;4d90
	cp 023h		;4d93
	jr nz,L_4D9A		;4d95
	call llena_de_silencio		;4d97
L_4D9A:
	call 000e1h		;4d9a   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	jr c,L_4D78		;4d9d
	ld a,(0db18h)		;4d9f
	ld c,a			;4da2
	ld b,010h		;4da3
L_4DA5:
	call L_4E52		;4da5
	jr c,L_4D78		;4da8
	cp c			;4daa
	jr nz,L_4D8A		;4dab
	djnz L_4DA5		;4dad
	ld bc,00700h		;4daf
L_4DB2:
	ld hl,0db0fh		;4db2
	ld a,(hl)			;4db5
	cp 020h		;4db6
	jr nz,L_4DBF		;4db8
	inc hl			;4dba
	djnz L_4DB2		;4dbb
	ld c,001h		;4dbd
L_4DBF:
	push bc			;4dbf
	call 000e1h		;4dc0   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	pop bc			;4dc3
	jr c,L_4D78		;4dc4
	ld hl,0db0fh		;4dc6
	ld b,007h		;4dc9
L_4DCB:
	call L_4E52		;4dcb
	jr c,L_4D78		;4dce
	bit 0,c		;4dd0
	jr nz,L_4DD7		;4dd2
	cp (hl)			;4dd4
	jr nz,L_4D8A		;4dd5
L_4DD7:
	ld (hl),a			;4dd7
	inc hl			;4dd8
	djnz L_4DCB		;4dd9
	call cartucho_en_la_pagina_2		;4ddb
	call L_BA66		;4dde
	ld de,04e80h		;4de1
	call L_4337		;4de4
	ld de,0db0fh		;4de7
	ld hl,03a0dh		;4dea
	call L_AD21		;4ded
	call ram_en_la_pagina_2		;4df0
	call 000e1h		;4df3   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	jp c,L_4D78		;4df6
	ld hl,0dcfeh		;4df9
	ld b,002h		;4dfc
L_4DFE:
	call L_4E52		;4dfe
	jp c,L_4D78		;4e01
	ld (hl),a			;4e04
	inc hl			;4e05
	djnz L_4DFE		;4e06
	ld a,(0db18h)		;4e08
	cp 023h		;4e0b
	jr nz,L_4E18		;4e0d
	call L_4E52		;4e0f
	jp c,L_4D78		;4e12
	ld (0dcfdh),a		;4e15
L_4E18:
	call 000e1h		;4e18   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	jp c,L_4D78		;4e1b
	call L_4E5A		;4e1e
	ld hl,0dcfeh		;4e21
	ld c,(hl)			;4e24
	inc hl			;4e25
	ld b,(hl)			;4e26
	ld hl,(0dbf0h)		;4e27
L_4E2A:
	call L_4E52		;4e2a
	jp c,L_4D78		;4e2d
	ld (hl),a			;4e30
	inc hl			;4e31
	dec bc			;4e32
	ld a,b			;4e33
	or c			;4e34
	jr nz,L_4E2A		;4e35
	ld b,001h		;4e37
	call L_4E6F		;4e39
	call 000e7h		;4e3c   ; BIOS TAPIOF - Stops reading from the tape
	call cartucho_en_la_pagina_2		;4e3f
	ei			;4e42
	ret			;4e43
llena_de_silencio:		; 0x8000-0xBFFF a 0x80, el reposo del DAC: el sample en blanco
	ld hl,08000h		;4e44
	ld bc,03fffh		;4e47
	ld d,h			;4e4a
	ld e,l			;4e4b
	inc e			;4e4c
	ld (hl),080h		;4e4d
	ldir		;4e4f
	ret			;4e51
L_4E52:
	push hl			;4e52
	push bc			;4e53
	call 000e4h		;4e54   ; BIOS TAPIN - Reads data from the tape
	pop bc			;4e57
	pop hl			;4e58
	ret			;4e59
L_4E5A:
	ld a,(0db18h)		;4e5a
	sub 021h		;4e5d
	add a,a			;4e5f
	ld hl,04e7ah		;4e60
	ld de,0dbf0h		;4e63
	ld bc,00002h		;4e66
	call hl_mas_a		;4e69
	ldir		;4e6c
	ret			;4e6e
L_4E6F:
	ld de,00000h		;4e6f
L_4E72:
	dec de			;4e72
	ld a,d			;4e73
	or e			;4e74
	jr nz,L_4E72		;4e75
	djnz L_4E72		;4e77
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


L_4E89:
	ld (0d972h),sp		;4e89
	call L_502F		;4e8d
	call ram_en_la_pagina_2		;4e90
	ld de,0d980h		;4e93
	ld hl,0db0fh		;4e96
	call L_5191		;4e99
	call L_524D		;4e9c
	call L_520D		;4e9f
	ld hl,(0dcfeh)		;4ea2
	call L_52A3		;4ea5
	ld a,(0db18h)		;4ea8
	cp 023h		;4eab
	jr nz,L_4EB5		;4ead
	ld a,(0dcfdh)		;4eaf
	call L_5289		;4eb2
L_4EB5:
	call L_4E5A		;4eb5
	ld de,(0dbf0h)		;4eb8
	ld c,01ah		;4ebc
	call 0f37dh		;4ebe
	ld hl,(0dcfeh)		;4ec1
	call L_5277		;4ec4
	call L_525A		;4ec7
	call cartucho_en_la_pagina_2		;4eca
	call L_5033		;4ecd
	ret			;4ed0
L_4ED1:
	ld (0d972h),sp		;4ed1
	call L_502F		;4ed5
	call ram_en_la_pagina_2		;4ed8
	ld de,0d980h		;4edb
	ld hl,0db0fh		;4ede
	call L_5191		;4ee1
	ld a,(0db18h)		;4ee4
	cp 023h		;4ee7
	jr nz,L_4EEE		;4ee9
	call llena_de_silencio		;4eeb
L_4EEE:
	call L_523D		;4eee
	call L_520D		;4ef1
	call L_52AC		;4ef4
	ld (0dcfeh),hl		;4ef7
	ld a,(0db18h)		;4efa
	cp 023h		;4efd
	jr nz,L_4F07		;4eff
	call L_5284		;4f01
	ld (0dcfdh),a		;4f04
L_4F07:
	call L_4E5A		;4f07
	ld de,(0dbf0h)		;4f0a
	ld c,01ah		;4f0e
	call 0f37dh		;4f10
	ld hl,(0dcfeh)		;4f13
	call L_5267		;4f16
	call L_525A		;4f19
	call cartucho_en_la_pagina_2		;4f1c
	call L_5033		;4f1f
	ret			;4f22
L_4F23:
	ld (0d972h),sp		;4f23
	call L_502F		;4f27
	call ram_en_la_pagina_2		;4f2a
	ld de,0d980h		;4f2d
	ld hl,0db0fh		;4f30
	call L_5191		;4f33
	call L_520D		;4f36
	ld de,0d980h		;4f39
	ld c,013h		;4f3c
	call 0f37dh		;4f3e
	ld c,001h		;4f41
	or a			;4f43
	jp nz,L_50F7		;4f44
	call cartucho_en_la_pagina_2		;4f47
	jp L_5033		;4f4a
L_4F4D:
	ld (0d972h),sp		;4f4d
	call L_502F		;4f51
	call ram_en_la_pagina_2		;4f54
	ld hl,0d2c0h		;4f57
	ld de,0d2c1h		;4f5a
	ld (hl),020h		;4f5d
	ld bc,001a1h		;4f5f
	ldir		;4f62
	ld hl,0d9b8h		;4f64
	ld de,0d9b9h		;4f67
	ld (hl),000h		;4f6a
	ld bc,00024h		;4f6c
	ldir		;4f6f
	ld hl,0d9b9h		;4f71
	ld de,0d9bah		;4f74
	ld (hl),03fh		;4f77
	ld bc,0000ah		;4f79
	ldir		;4f7c
	xor a			;4f7e
	ld (0d9b5h),a		;4f7f
	ld (0d9b6h),a		;4f82
	ld de,0d2c0h		;4f85
	ld c,01ah		;4f88
	call 0f37dh		;4f8a
	ld de,0d9b8h		;4f8d
	ld c,011h		;4f90
	call 0f37dh		;4f92
	inc a			;4f95
	jr z,L_4FC4		;4f96
L_4F98:
	call L_51CB		;4f98
	ld hl,0d2c9h		;4f9b
	cp (hl)			;4f9e
	jr nz,L_4FB9		;4f9f
	ld b,002h		;4fa1
L_4FA3:
	inc hl			;4fa3
	ld a,020h		;4fa4
	cp (hl)			;4fa6
	jr nz,L_4FB9		;4fa7
	djnz L_4FA3		;4fa9
	ld hl,0d9b5h		;4fab
	inc (hl)			;4fae
	push hl			;4faf
	call L_50A9		;4fb0
	pop hl			;4fb3
	ld a,(hl)			;4fb4
	cp 023h		;4fb5
	jr z,L_4FC4		;4fb7
L_4FB9:
	ld de,0d9b8h		;4fb9
	ld c,012h		;4fbc
	call 0f37dh		;4fbe
	inc a			;4fc1
	jr nz,L_4F98		;4fc2
L_4FC4:
	ld de,04fe9h		;4fc4
	ld hl,0d9b5h		;4fc7
	ld a,(hl)			;4fca
	or a			;4fcb
	jr z,L_4FD1		;4fcc
	ld de,04fdeh		;4fce
L_4FD1:
	call L_50B0		;4fd1
	call cartucho_en_la_pagina_2		;4fd4
	ld a,002h		;4fd7
	call L_BEB1		;4fd9
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


L_4FF4:
	call L_502F		;4ff4
	ld a,(0d808h)		;4ff7
	ld de,0d9b6h		;4ffa
	cp 001h		;4ffd
	jr z,L_501A		;4fff
	cp 002h		;5001
	jr z,L_5011		;5003
	ld a,(0d8f3h)		;5005
	cp 040h		;5008
	jr nz,L_502A		;500a
	call L_5033		;500c
	scf			;500f
	ret			;5010
L_5011:
	ld a,(de)			;5011
	or a			;5012
	jr z,L_502A		;5013
	ex de,hl			;5015
	dec (hl)			;5016
	ex de,hl			;5017
	jr L_5027		;5018
L_501A:
	ld a,(0d9b5h)		;501a
	ex de,hl			;501d
	sub (hl)			;501e
	ex de,hl			;501f
	cp 00ah		;5020
	jr c,L_502A		;5022
	ex de,hl			;5024
	inc (hl)			;5025
	ex de,hl			;5026
L_5027:
	call L_5038		;5027
L_502A:
	call L_5033		;502a
	or a			;502d
	ret			;502e
L_502F:
	ld a,001h		;502f
	jr L_5034		;5031
L_5033:
	xor a			;5033
L_5034:
	ld (0d901h),a		;5034
	ret			;5037
L_5038:
	ld hl,038e8h		;5038
	ld a,(0d9b6h)		;503b
	ld c,a			;503e
	ld b,00ah		;503f
L_5041:
	push bc			;5041
	push hl			;5042
	ld a,c			;5043
	call L_50CB		;5044
	call L_5058		;5047
	pop hl			;504a
	ld bc,00020h		;504b
	add hl,bc			;504e
	pop bc			;504f
	inc c			;5050
	djnz L_5041		;5051
	xor a			;5053
	ld (0d9b7h),a		;5054
	ret			;5057
L_5058:
	ld a,(0d9b7h)		;5058
	or a			;505b
	ret nz			;505c
	ld a,(de)			;505d
	cp 020h		;505e
	ret z			;5060
	cp 096h		;5061
	jr z,L_507D		;5063
	cp 040h		;5065
	jr z,L_5078		;5067
	ld b,007h		;5069
	call L_5086		;506b
	ld a,096h		;506e
	call 0004dh		;5070   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;5073
	ld b,003h		;5074
	jr L_5086		;5076
L_5078:
	ld a,001h		;5078
	ld (0d9b7h),a		;507a
L_507D:
	ld b,00bh		;507d
	call L_5086		;507f
	xor a			;5082
	jp 0004dh		;5083   ; BIOS WRTVRM - Writes data in VRAM
L_5086:
	ld a,(de)			;5086
	cp 096h		;5087
	jr z,L_50A1		;5089
	cp 020h		;508b
	jr z,L_5093		;508d
	cp 040h		;508f
	jr nz,L_5097		;5091
L_5093:
	ld a,000h		;5093
	jr L_50A1		;5095
L_5097:
	cp 03ah		;5097
	jr nc,L_509F		;5099
	add a,010h		;509b
	jr L_50A1		;509d
L_509F:
	sub 020h		;509f
L_50A1:
	call 0004dh		;50a1   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;50a4
	inc hl			;50a5
	djnz L_5086		;50a6
	ret			;50a8
L_50A9:
	ld de,0d2c1h		;50a9
	ld a,(0d9b5h)		;50ac
	dec a			;50af
L_50B0:
	call L_50BA		;50b0
	ex de,hl			;50b3
	ld bc,0000bh		;50b4
	ldir		;50b7
	ret			;50b9
L_50BA:
	ld l,a			;50ba
	ld h,000h		;50bb
	ld b,h			;50bd
	ld c,l			;50be
	add hl,hl			;50bf
	add hl,bc			;50c0
	add hl,hl			;50c1
	add hl,hl			;50c2
	and a			;50c3
	sbc hl,bc		;50c4
	ld bc,0d2e1h		;50c6
	add hl,bc			;50c9
	ret			;50ca
L_50CB:
	ex de,hl			;50cb
	ld l,a			;50cc
	ld h,000h		;50cd
	ld b,h			;50cf
	ld c,l			;50d0
	add hl,hl			;50d1
	add hl,bc			;50d2
	add hl,hl			;50d3
	add hl,hl			;50d4
	and a			;50d5
	sbc hl,bc		;50d6
	ld bc,0d2e1h		;50d8
	add hl,bc			;50db
	ex de,hl			;50dc
	ret			;50dd
L_50DE:
	ld a,c			;50de
	and 00eh		;50df
	rrca			;50e1
	cp 002h		;50e2
	jr c,L_50EC		;50e4
	cp 006h		;50e6
	jr c,L_50F5		;50e8
	jr L_50F1		;50ea
L_50EC:
	ld c,004h		;50ec
	rrca			;50ee
	jr nc,L_50F7		;50ef
L_50F1:
	ld c,003h		;50f1
	jr L_50F7		;50f3
L_50F5:
	ld c,000h		;50f5
L_50F7:
	push bc			;50f7
	call cartucho_en_la_pagina_2		;50f8
	call L_BA66		;50fb
	call L_5033		;50fe
	pop bc			;5101
	ld b,000h		;5102
	ld a,c			;5104
	add a,a			;5105
	ld c,a			;5106
	ld hl,0511fh		;5107
	add hl,bc			;510a
	ld e,(hl)			;510b
	inc hl			;510c
	ld d,(hl)			;510d
	ld hl,03a06h		;510e
	ld c,0ffh		;5111
	call L_433F		;5113
	call L_B8F8		;5116
	ld sp,(0d972h)		;5119
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


L_5191:
	call L_51DB		;5191
	ld c,006h		;5194
	jp c,L_50F7		;5196
	ld (0d970h),de		;5199
	xor a			;519d
	ld (de),a			;519e
	inc de			;519f
	ld b,007h		;51a0
L_51A2:
	ld a,(hl)			;51a2
	cp 040h		;51a3
	jr nc,L_51AB		;51a5
	add a,020h		;51a7
	jr L_51AD		;51a9
L_51AB:
	sub 010h		;51ab
L_51AD:
	ld (de),a			;51ad
	inc hl			;51ae
	inc de			;51af
	djnz L_51A2		;51b0
	ld a,020h		;51b2
	ld (de),a			;51b4
	inc de			;51b5
	call L_51CB		;51b6
	ld (de),a			;51b9
	inc de			;51ba
	ld a,020h		;51bb
	ld b,002h		;51bd
L_51BF:
	ld (de),a			;51bf
	inc de			;51c0
	djnz L_51BF		;51c1
	xor a			;51c3
	ld b,019h		;51c4
L_51C6:
	ld (de),a			;51c6
	inc de			;51c7
	djnz L_51C6		;51c8
	ret			;51ca
L_51CB:
	ld a,(0db18h)		;51cb
	sub 021h		;51ce
	ld hl,051d8h		;51d0
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


L_51DB:
	push hl			;51db
	push de			;51dc
	ld de,0d9dfh		;51dd
	ld hl,0db0fh		;51e0
	ld a,(hl)			;51e3
	cp 020h		;51e4
	jr z,L_5203		;51e6
	ld b,006h		;51e8
L_51EA:
	inc hl			;51ea
	ld a,(de)			;51eb
	or a			;51ec
	jr z,L_51F6		;51ed
	ld a,(hl)			;51ef
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
L_520A:
	ld (0d970h),hl		;520a
L_520D:
	ld hl,(0d970h)		;520d
	ld bc,0000ch		;5210
	add hl,bc			;5213
	ld (hl),b			;5214
	inc hl			;5215
	ld (hl),b			;5216
	inc hl			;5217
	ld bc,00001h		;5218
	ld (hl),c			;521b
	inc hl			;521c
	ld (hl),b			;521d
	ld bc,00011h		;521e
	add hl,bc			;5221
	ld b,005h		;5222
	xor a			;5224
L_5225:
	ld (hl),a			;5225
	inc hl			;5226
	djnz L_5225		;5227
	ret			;5229
L_522A:
	ld (0d970h),de		;522a
	jr L_5234		;522e
L_5230:
	ld de,(0d970h)		;5230
L_5234:
	ex de,hl			;5234
	ld bc,00021h		;5235
	add hl,bc			;5238
	ld (hl),e			;5239
	inc hl			;523a
	ld (hl),d			;523b
	ret			;523c
L_523D:
	ld de,(0d970h)		;523d
	ld c,00fh		;5241
	call 0f37dh		;5243
	ld c,001h		;5246
L_5248:
	inc a			;5248
	ret nz			;5249
	jp L_50F7		;524a
L_524D:
	ld de,(0d970h)		;524d
	ld c,016h		;5251
	call 0f37dh		;5253
	ld c,005h		;5256
	jr L_5248		;5258
L_525A:
	ld de,(0d970h)		;525a
	ld c,010h		;525e
	call 0f37dh		;5260
	ld c,002h		;5263
	jr L_5248		;5265
L_5267:
	ld de,(0d970h)		;5267
	ld c,027h		;526b
	call 0f37dh		;526d
	ld c,000h		;5270
L_5272:
	and a			;5272
	ret z			;5273
	jp L_50F7		;5274
L_5277:
	ld de,(0d970h)		;5277
	ld c,026h		;527b
	call 0f37dh		;527d
	ld c,002h		;5280
	jr L_5272		;5282
L_5284:
	ld bc,L_5267		;5284
	jr L_528C		;5287
L_5289:
	ld bc,L_5277		;5289
L_528C:
	push af			;528c
	ld hl,00001h		;528d
	add hl,sp			;5290
	push bc			;5291
	ex de,hl			;5292
	ld c,01ah		;5293
	call 0f37dh		;5295
	pop bc			;5298
	call L_529E		;5299
	pop af			;529c
	ret			;529d
L_529E:
	ld hl,00001h		;529e
	push bc			;52a1
	ret			;52a2
L_52A3:
	push hl			;52a3
	ld a,l			;52a4
	call L_5289		;52a5
	pop hl			;52a8
	ld a,h			;52a9
	jr L_5289		;52aa
L_52AC:
	call L_5284		;52ac
	ld l,a			;52af
	push hl			;52b0
	call L_5284		;52b1
	pop hl			;52b4
	ld h,a			;52b5
	ret			;52b6
L_52B7:
	ld a,070h		;52b7
	ld (0d930h),a		;52b9
	call L_52D9		;52bc
	jr c,L_52CC		;52bf
	ld a,(0d8fbh)		;52c1
	cp 001h		;52c4
	call z,L_5516		;52c6
	call L_5383		;52c9
L_52CC:
	ld a,(0d8f5h)		;52cc
	ld (0d8fah),a		;52cf
	ld a,(0d8fbh)		;52d2
	ld (0d8f4h),a		;52d5
	ret			;52d8
L_52D9:
	ld (0d931h),sp		;52d9
	ld a,071h		;52dd
	ld (0d930h),a		;52df
	ld a,001h		;52e2
	ld (0f418h),a		;52e4
	call L_52ED		;52e7
	jp L_5419		;52ea
L_52ED:
	ld h,001h		;52ed
L_52EF:
	ld c,000h		;52ef
L_52F1:
	ld b,000h		;52f1
L_52F3:
	call 000a8h		;52f3   ; BIOS LPTSTT - Tests printer status
	jr z,L_52FB		;52f6
	cp 0ffh		;52f8
	ret z			;52fa
L_52FB:
	djnz L_52F3		;52fb
	dec c			;52fd
	jr nz,L_52F1		;52fe
	dec h			;5300
	jr nz,L_52EF		;5301
	jr L_5334		;5303
L_5305:
	xor a			;5305
	ld (0d938h),a		;5306
	ld hl,00200h		;5309
L_530C:
	push hl			;530c
	call L_52ED		;530d
	pop hl			;5310
	xor a			;5311
	call 000a5h		;5312   ; BIOS LPTOUT - Sends one character to printer
	jr c,L_530C		;5315
	dec hl			;5317
	ld a,h			;5318
	or l			;5319
	jr nz,L_530C		;531a
	ld b,008h		;531c
L_531E:
	ld a,00dh		;531e
	call 000a5h		;5320   ; BIOS LPTOUT - Sends one character to printer
	jr c,L_531E		;5323
L_5325:
	ld a,00ah		;5325
	call 000a5h		;5327   ; BIOS LPTOUT - Sends one character to printer
	jr c,L_5325		;532a
	djnz L_531E		;532c
L_532E:
	ld sp,(0d931h)		;532e
	scf			;5332
	ret			;5333
L_5334:
	ld de,0534dh		;5334
	call L_4337		;5337
	ld h,00fh		;533a
L_533C:
	ld c,000h		;533c
L_533E:
	ld b,000h		;533e
L_5340:
	djnz L_5340		;5340
	dec c			;5342
	jr nz,L_533E		;5343
	dec h			;5345
	jr nz,L_533C		;5346
	call L_48B2		;5348
	jr L_532E		;534b

; ----------------------------------------------------------------------
; DATOS rotulo_printer_not_ready: lista de 0x4337: "PRINTER NOT READY"
;   0x534d..0x5361  (20 bytes)
DATA_rotulo_printer_not_ready:
	defb 0c7h,03ah,030h,032h,029h,02eh,034h,025h,032h,000h,02eh,02fh,034h,000h,032h,025h	; 534d  .:02).4%2../4.2%
	defb 021h,024h,039h,0ffh	; 535d

; ======================================================================
; CODIGO 0x5361..0x54b6  (341 bytes)
; ======================================================================


L_5361:
	push ix		;5361
	push hl			;5363
	push de			;5364
	push bc			;5365
	push af			;5366
	push af			;5367
L_5368:
	call 000a8h		;5368   ; BIOS LPTSTT - Tests printer status
	jr z,L_5368		;536b
	cp 0ffh		;536d
	jr nz,L_5368		;536f
	pop af			;5371
	call 000a5h		;5372   ; BIOS LPTOUT - Sends one character to printer
	jr nc,L_537C		;5375
	ld a,001h		;5377
	ld (0d938h),a		;5379
L_537C:
	pop af			;537c
	pop bc			;537d
	pop de			;537e
	pop hl			;537f
	pop ix		;5380
	ret			;5382
L_5383:
	ld b,004h		;5383
L_5385:
	call L_538B		;5385
	djnz L_5385		;5388
	ret			;538a
L_538B:
	ld a,00dh		;538b
	call L_5361		;538d
	ld a,00ah		;5390
	jp L_5361		;5392
L_5395:
	call L_53A9		;5395
	or a			;5398
	ret nz			;5399
	call L_539E		;539a
	ret			;539d
L_539E:
	ld a,(0f3e6h)		;539e
	and 00fh		;53a1
	cp 004h		;53a3
	ret z			;53a5
	ld a,001h		;53a6
	ret			;53a8
L_53A9:
	ld hl,(0d933h)		;53a9
	call L_5405		;53ac
	call 0004ah		;53af   ; BIOS RDVRM - Reads the content of VRAM
	ld h,000h		;53b2
	ld l,a			;53b4
	add hl,hl			;53b5
	add hl,hl			;53b6
	add hl,hl			;53b7
	ld de,(0d933h)		;53b8
	ld a,e			;53bc
	and 007h		;53bd
	ld e,a			;53bf
	ld d,000h		;53c0
	add hl,de			;53c2
	ld de,(0d933h)		;53c3
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
	ld de,(0d933h)		;53d8
	ld a,d			;53dc
	push hl			;53dd
	ld de,02000h		;53de
	add hl,de			;53e1
	and 007h		;53e2
	inc a			;53e4
	ld b,a			;53e5
	call 0004ah		;53e6   ; BIOS RDVRM - Reads the content of VRAM
L_53E9:
	add a,a			;53e9
	djnz L_53E9		;53ea
	pop hl			;53ec
	push af			;53ed
	ld de,00000h		;53ee
	add hl,de			;53f1
	call 0004ah		;53f2   ; BIOS RDVRM - Reads the content of VRAM
	ld b,a			;53f5
	pop af			;53f6
	jr c,L_53FD		;53f7
	ld a,b			;53f9
	and 00fh		;53fa
	ret			;53fc
L_53FD:
	ld a,b			;53fd
	and 0f0h		;53fe
	rrca			;5400
	rrca			;5401
	rrca			;5402
	rrca			;5403
	ret			;5404
L_5405:
	ld a,l			;5405
	rra			;5406
	rra			;5407
	rra			;5408
	rra			;5409
	rr h		;540a
	rra			;540c
	rr h		;540d
	rra			;540f
	rr h		;5410
	ld l,h			;5412
	and 003h		;5413
	add a,038h		;5415
	ld h,a			;5417
	ret			;5418
L_5419:
	call L_54A9		;5419
	ld b,040h		;541c
	ld h,000h		;541e
L_5420:
	push bc			;5420
	ld de,054bdh		;5421
	ld a,(0d930h)		;5424
	cp 071h		;5427
	jr z,L_542E		;5429
	ld de,054c4h		;542b
L_542E:
	call L_54AC		;542e
	ld b,0c0h		;5431
L_5433:
	push bc			;5433
	push hl			;5434
	ld l,b			;5435
	dec l			;5436
	ld (0d933h),hl		;5437
	ld ix,0d935h		;543a
	xor a			;543e
	ld (ix+000h),a		;543f
	ld (ix+001h),a		;5442
	ld bc,00403h		;5445
L_5448:
	push bc			;5448
	call L_5395		;5449
	call L_54E9		;544c
	pop bc			;544f
	ld a,d			;5450
	and c			;5451
	or (ix+000h)		;5452
	ld (ix+000h),a		;5455
	ld a,e			;5458
	and c			;5459
	or (ix+001h)		;545a
	ld (ix+001h),a		;545d
	rlc c		;5460
	rlc c		;5462
	ld hl,(0d933h)		;5464
	inc h			;5467
	ld (0d933h),hl		;5468
	djnz L_5448		;546b
	ld a,(ix+000h)		;546d
	call L_5361		;5470
	call L_5499		;5473
	ld a,(ix+001h)		;5476
	call L_5361		;5479
	call L_5499		;547c
	pop hl			;547f
	pop bc			;5480
	djnz L_5433		;5481
	call L_538B		;5483
	ld a,(0d938h)		;5486
	or a			;5489
	jp nz,L_5305		;548a
	ld a,004h		;548d
	add a,h			;548f
	ld h,a			;5490
	pop bc			;5491
	djnz L_5420		;5492
	call L_5383		;5494
	xor a			;5497
	ret			;5498
L_5499:
	ld b,a			;5499
	ld a,(0d930h)		;549a
	cp 072h		;549d
	ld a,b			;549f
	jp z,L_5361		;54a0
	ret			;54a3
L_54A4:
	ld de,054cbh		;54a4
	jr L_54AC		;54a7
L_54A9:
	ld de,054b6h		;54a9
L_54AC:
	ld a,(de)			;54ac
	inc a			;54ad
	ret z			;54ae
	dec a			;54af
	call L_5361		;54b0
	inc de			;54b3
	jr L_54AC		;54b4

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


L_54E9:
	push hl			;54e9
	ld hl,054f6h		;54ea
	add a,a			;54ed
	call hl_mas_a		;54ee
	ld d,(hl)			;54f1
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


L_5516:
	call L_538B		;5516
	ld de,054d2h		;5519
	call L_54AC		;551c
	ld b,002h		;551f
	call L_55B4		;5521
	ld de,054dah		;5524
	call L_54AC		;5527
	call L_538B		;552a
	ld b,002h		;552d
	call L_55B4		;552f
	ld c,030h		;5532
L_5534:
	ld b,005h		;5534
	call L_55B4		;5536
	ld a,c			;5539
	cp 038h		;553a
	jr z,L_5544		;553c
	call L_5361		;553e
	inc c			;5541
	jr L_5534		;5542
L_5544:
	ld de,054d5h		;5544
	call L_54AC		;5547
	call L_538B		;554a
	ld b,03ah		;554d
L_554F:
	ld a,02dh		;554f
	call L_5361		;5551
	djnz L_554F		;5554
	call L_538B		;5556
	xor a			;5559
	call L_B1A0		;555a
	ld b,008h		;555d
L_555F:
	push bc			;555f
	ld b,004h		;5560
	call L_55B4		;5562
	ld b,008h		;5565
L_5567:
	push bc			;5567
	ld a,(hl)			;5568
	ld c,a			;5569
	ld a,020h		;556a
	bit 7,c		;556c
	jr z,L_5576		;556e
	ld a,c			;5570
	neg		;5571
	ld c,a			;5573
	ld a,02dh		;5574
L_5576:
	call L_5361		;5576
	push hl			;5579
	ld l,c			;557a
	call L_A978		;557b
	ld hl,0dbf0h		;557e
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
	ld b,003h		;5593
L_5595:
	ld a,(hl)			;5595
	or 030h		;5596
	call L_5361		;5598
	dec hl			;559b
	djnz L_5595		;559c
	ld b,002h		;559e
	call L_55B4		;55a0
	pop hl			;55a3
	inc hl			;55a4
	inc hl			;55a5
	inc hl			;55a6
	inc hl			;55a7
	pop bc			;55a8
	djnz L_5567		;55a9
	call L_538B		;55ab
	pop bc			;55ae
	djnz L_555F		;55af
	jp L_5383		;55b1
L_55B4:
	ld a,020h		;55b4
	call L_5361		;55b6
	djnz L_55B4		;55b9
	ret			;55bb
L_55BC:
	ld hl,0a3aah		;55bc
	ld de,0d000h		;55bf
	ld bc,00200h		;55c2
	ldir		;55c5
	call L_55DC		;55c7
	ld b,010h		;55ca
	ld de,0c000h		;55cc
L_55CF:
	push bc			;55cf
	ld hl,07200h		;55d0
	ld bc,00100h		;55d3
	ldir		;55d6
	pop bc			;55d8
	djnz L_55CF		;55d9
	ret			;55db
L_55DC:
	ld hl,05da9h		;55dc
	ld de,0d230h		;55df
	ld bc,00080h		;55e2
	ldir		;55e5
	ret			;55e7
L_55E8:
	call L_4BD9		;55e8
	ld hl,0dc24h		;55eb
	inc (hl)			;55ee
	ret			;55ef
L_55F0:
	di			;55f0
	xor a			;55f1
	ld (0dc24h),a		;55f2
	call ram_en_la_pagina_2		;55f5
	ld a,(0dc03h)		;55f8
	or a			;55fb
	jp nz,L_5605		;55fc
	ld hl,00000h		;55ff
	jp L_5613		;5602
L_5605:
	ld a,(0dc09h)		;5605
	ld b,a			;5608
	ld a,(0dc0ah)		;5609
	ld c,a			;560c
	ld a,(0dc0bh)		;560d
	call L_57F7		;5610
L_5613:
	ld (0dc1ch),hl		;5613
	ld a,h			;5616
	cp 040h		;5617
	jp nc,L_5695		;5619
	ld a,(0dc07h)		;561c
	or a			;561f
	jp nz,L_5629		;5620
	ld hl,00000h		;5623
	jp L_5637		;5626
L_5629:
	ld a,(0dc0dh)		;5629
	ld b,a			;562c
	ld a,(0dc0eh)		;562d
	ld c,a			;5630
	ld a,(0dc0fh)		;5631
	call L_57F7		;5634
L_5637:
	ld (0dc1eh),hl		;5637
	ld a,h			;563a
	cp 040h		;563b
	jp nc,L_5695		;563d
	ld a,(0dc11h)		;5640
	ld b,a			;5643
	ld a,(0dc12h)		;5644
	ld c,a			;5647
	ld a,(0dc13h)		;5648
	call L_57F7		;564b
	ld (0dc20h),hl		;564e
	ld a,h			;5651
	cp 040h		;5652
	jp nc,L_5695		;5654
	ld de,(0dc1eh)		;5657
	scf			;565b
	ccf			;565c
	sbc hl,de		;565d
	jp c,L_5669		;565f
	ld de,(0dc20h)		;5662
	jp L_566A		;5666
L_5669:
	ccf			;5669
L_566A:
	ld hl,(0dc1ch)		;566a
	sbc hl,de		;566d
	jp c,L_5676		;566f
	ld de,(0dc1ch)		;5672
L_5676:
	ex de,hl			;5676
	ld de,001ffh		;5677
	add hl,de			;567a
	ld l,000h		;567b
	push hl			;567d
	ld a,(0dc13h)		;567e
	ld e,a			;5681
	ld a,(0dc14h)		;5682
	ld c,a			;5685
	call L_5812		;5686
	pop de			;5689
	add hl,de			;568a
	ld de,00040h		;568b
	add hl,de			;568e
	ld a,h			;568f
	cp 040h		;5690
	jp c,L_569A		;5692
L_5695:
	ld a,080h		;5695
	jp L_569F		;5697
L_569A:
	sla l		;569a
	rl h		;569c
	ld a,h			;569e
L_569F:
	ld (0dc22h),a		;569f
	ld (0dc23h),a		;56a2
	xor a			;56a5
	ld (0dcfdh),a		;56a6
	ld hl,08000h		;56a9
L_56AC:
	ld (hl),080h		;56ac
	inc hl			;56ae
	ld a,h			;56af
	cp 0c0h		;56b0
	jp nz,L_56AC		;56b2
	ld hl,08000h		;56b5
	ld (0dc19h),hl		;56b8
	xor a			;56bb
	ld (0dc1bh),a		;56bc
	ld hl,L_5829		;56bf
	ld (0dc25h),hl		;56c2
	ld hl,0dc27h		;56c5
	ld (hl),001h		;56c8
	inc hl			;56ca
	ld (hl),000h		;56cb
	ld hl,L_58D5		;56cd
	ld (0dc29h),hl		;56d0
	ld hl,0dc2bh		;56d3
	ld (hl),001h		;56d6
	inc hl			;56d8
	ld (hl),000h		;56d9
	ld hl,L_5981		;56db
	ld (0dc2dh),hl		;56de
	ld hl,0dc2fh		;56e1
	ld (hl),001h		;56e4
	inc hl			;56e6
	ld (hl),000h		;56e7
	ld hl,00000h		;56e9
	ld (0dc31h),hl		;56ec
	ld a,(0dc00h)		;56ef
	cp 00eh		;56f2
	jp nz,L_56FF		;56f4
	ld a,(0db00h)		;56f7
	add a,0c0h		;56fa
	jp L_5701		;56fc
L_56FF:
	add a,072h		;56ff
L_5701:
	ld (0dc33h),a		;5701
	ld hl,00000h		;5704
	ld (0dc35h),hl		;5707
	ld a,(0dc05h)		;570a
	ld e,a			;570d
	ld d,000h		;570e
	ld hl,05c12h		;5710
	add hl,de			;5713
	ld a,(hl)			;5714
	ld (0dc38h),a		;5715
	ld hl,05c1bh		;5718
	add hl,de			;571b
	ld a,(hl)			;571c
	ld (0dc39h),a		;571d
	ld hl,00000h		;5720
	ld (0dc3ah),hl		;5723
	ld (0dc3ch),hl		;5726
	ld hl,00000h		;5729
	ld (0dc42h),hl		;572c
	ld a,(0dc16h)		;572f
	cp 00eh		;5732
	jp nz,L_573F		;5734
	ld a,(0db00h)		;5737
	add a,0c0h		;573a
	jp L_5741		;573c
L_573F:
	add a,072h		;573f
L_5741:
	ld (0dc44h),a		;5741
	xor a			;5744
	ld (0dc46h),a		;5745
	ld a,(0dc02h)		;5748
	ld b,a			;574b
	ld a,(0dc06h)		;574c
	or b			;574f
	ld b,a			;5750
	ld a,(0dc08h)		;5751
	or b			;5754
	jp z,L_5761		;5755
	ld hl,05cceh		;5758
	ld (0dc40h),hl		;575b
	jp L_5767		;575e
L_5761:
	ld hl,05d39h		;5761
	ld (0dc40h),hl		;5764
L_5767:
	in a,(0aah)		;5767
	and 0f0h		;5769
	or 006h		;576b
	out (0aah),a		;576d
	ld c,a			;576f
	in a,(0a9h)		;5770
	or 09fh		;5772
	cp 0ffh		;5774
	jp nz,L_57D9		;5776
	inc c			;5779
	ld a,c			;577a
	out (0aah),a		;577b
	in a,(0a9h)		;577d
	or 0fch		;577f
	cp 0ffh		;5781
	jp nz,L_57E8		;5783
	ld hl,0dc23h		;5786
	dec (hl)			;5789
	jp nz,L_5796		;578a
	call L_55E8		;578d
	ld a,(0dc22h)		;5790
	ld (0dc23h),a		;5793
L_5796:
	call L_5CCA		;5796
	call L_5825		;5799
	call L_58D1		;579c
	call L_597D		;579f
	call L_5A4B		;57a2
	call L_5B1C		;57a5
	call L_5C7E		;57a8
	add a,080h		;57ab
	ld hl,(0dc19h)		;57ad
	ld (hl),a			;57b0
	inc hl			;57b1
	ld (0dc19h),hl		;57b2
	ld a,h			;57b5
	cp 0c0h		;57b6
	jp z,L_57C3		;57b8
	ld a,(0dc1bh)		;57bb
	bit 7,a		;57be
	jp z,L_5767		;57c0
L_57C3:
	ld hl,(0dc19h)		;57c3
	ld de,08000h		;57c6
	scf			;57c9
	ccf			;57ca
	sbc hl,de		;57cb
	ld (0dcfeh),hl		;57cd
	ld a,039h		;57d0
L_57D2:
	ld (0dc47h),a		;57d2
	call cartucho_en_la_pagina_2		;57d5
	ret			;57d8
L_57D9:
	bit 5,a		;57d9
	jp nz,L_57E3		;57db
	ld a,036h		;57de
	jp L_57D2		;57e0
L_57E3:
	ld a,037h		;57e3
	jp L_57D2		;57e5
L_57E8:
	bit 0,a		;57e8
	jp nz,L_57F2		;57ea
	ld a,039h		;57ed
	jp L_57D2		;57ef
L_57F2:
	ld a,03ah		;57f2
	jp L_57D2		;57f4
L_57F7:
	neg		;57f7
	dec a			;57f9
	ld e,a			;57fa
	ld a,b			;57fb
	call L_5812		;57fc
	ex de,hl			;57ff
	ld h,a			;5800
	ld l,000h		;5801
	or a			;5803
	jp nz,L_580B		;5804
	inc l			;5807
	jp L_5810		;5808
L_580B:
	ld b,000h		;580b
	ld c,a			;580d
	sbc hl,bc		;580e
L_5810:
	add hl,de			;5810
	ret			;5811
L_5812:
	ld hl,00000h		;5812
	ld d,h			;5815
	ld b,008h		;5816
L_5818:
	rrc c		;5818
	jp nc,L_581E		;581a
	add hl,de			;581d
L_581E:
	sla e		;581e
	rl d		;5820
	djnz L_5818		;5822
	ret			;5824
L_5825:
	ld hl,(0dc25h)		;5825
	jp (hl)			;5828
L_5829:
	ld a,(0dc03h)		;5829
	or a			;582c
	jp nz,L_583B		;582d
	ld a,(0dc1bh)		;5830
	set 0,a		;5833
	ld (0dc1bh),a		;5835
	jp L_58CA		;5838
L_583B:
	ld a,(0dc09h)		;583b
	or a			;583e
	jp nz,L_5849		;583f
	dec a			;5842
	ld (0dc28h),a		;5843
	jp L_585B		;5846
L_5849:
	ld hl,l584ch		;5849
L_584C:
	ld hl,0dc27h		;584c
	dec (hl)			;584f
	ret nz			;5850
	ld a,(0dc09h)		;5851
	ld (hl),a			;5854
	inc hl			;5855
	inc (hl)			;5856
	ld a,0ffh		;5857
	cp (hl)			;5859
	ret nz			;585a
L_585B:
	ld hl,L_5862		;585b
	ld (0dc25h),hl		;585e
	ret			;5861
L_5862:
	ld a,(0dc0ah)		;5862
	or a			;5865
	ld a,(0dc0bh)		;5866
	jp z,L_5871		;5869
	cp 0ffh		;586c
	jp nz,L_5877		;586e
L_5871:
	ld (0dc28h),a		;5871
	jp L_588D		;5874
L_5877:
	ld hl,l587dh		;5877
	ld (0dc25h),hl		;587a
L_587D:
	ld hl,0dc27h		;587d
	dec (hl)			;5880
	ret nz			;5881
	ld a,(0dc0ah)		;5882
	ld (hl),a			;5885
	inc hl			;5886
	dec (hl)			;5887
	ld a,(0dc0bh)		;5888
	cp (hl)			;588b
	ret nz			;588c
L_588D:
	ld a,(0dc1bh)		;588d
	set 0,a		;5890
	ld (0dc1bh),a		;5892
	ld a,(0dc0bh)		;5895
	or a			;5898
	jp z,L_58CA		;5899
	ld hl,L_58A3		;589c
	ld (0dc25h),hl		;589f
	ret			;58a2
L_58A3:
	ld a,(0dc1bh)		;58a3
	cp 007h		;58a6
	ret nz			;58a8
	ld a,(0dc0ch)		;58a9
	or a			;58ac
	jp nz,L_58B6		;58ad
	ld (0dc28h),a		;58b0
	jp L_58CA		;58b3
L_58B6:
	ld hl,l58bch		;58b6
	ld (0dc25h),hl		;58b9
L_58BC:
	ld hl,0dc27h		;58bc
	dec (hl)			;58bf
	ret nz			;58c0
	ld a,(0dc0ch)		;58c1
	ld (hl),a			;58c4
	inc hl			;58c5
	dec (hl)			;58c6
	xor a			;58c7
	cp (hl)			;58c8
	ret nz			;58c9
L_58CA:
	ld hl,l58d0h		;58ca
	ld (0dc25h),hl		;58cd
L_58D0:
	ret			;58d0
L_58D1:
	ld hl,(0dc29h)		;58d1
	jp (hl)			;58d4
L_58D5:
	ld a,(0dc07h)		;58d5
	or a			;58d8
	jp nz,L_58E7		;58d9
	ld a,(0dc1bh)		;58dc
	set 1,a		;58df
	ld (0dc1bh),a		;58e1
	jp L_5976		;58e4
L_58E7:
	ld a,(0dc0dh)		;58e7
	or a			;58ea
	jp nz,L_58F5		;58eb
	dec a			;58ee
	ld (0dc2ch),a		;58ef
	jp L_5907		;58f2
L_58F5:
	ld hl,l58f8h		;58f5
L_58F8:
	ld hl,0dc2bh		;58f8
	dec (hl)			;58fb
	ret nz			;58fc
	ld a,(0dc0dh)		;58fd
	ld (hl),a			;5900
	inc hl			;5901
	inc (hl)			;5902
	ld a,0ffh		;5903
	cp (hl)			;5905
	ret nz			;5906
L_5907:
	ld hl,L_590E		;5907
	ld (0dc29h),hl		;590a
	ret			;590d
L_590E:
	ld a,(0dc0eh)		;590e
	or a			;5911
	ld a,(0dc0fh)		;5912
	jp z,L_591D		;5915
	cp 0ffh		;5918
	jp nz,L_5923		;591a
L_591D:
	ld (0dc2ch),a		;591d
	jp L_5939		;5920
L_5923:
	ld hl,l5929h		;5923
	ld (0dc29h),hl		;5926
L_5929:
	ld hl,0dc2bh		;5929
	dec (hl)			;592c
	ret nz			;592d
	ld a,(0dc0eh)		;592e
	ld (hl),a			;5931
	inc hl			;5932
	dec (hl)			;5933
	ld a,(0dc0fh)		;5934
	cp (hl)			;5937
	ret nz			;5938
L_5939:
	ld a,(0dc1bh)		;5939
	set 1,a		;593c
	ld (0dc1bh),a		;593e
	ld a,(0dc0fh)		;5941
	or a			;5944
	jp z,L_5976		;5945
	ld hl,L_594F		;5948
	ld (0dc29h),hl		;594b
	ret			;594e
L_594F:
	ld a,(0dc1bh)		;594f
	cp 007h		;5952
	ret nz			;5954
	ld a,(0dc10h)		;5955
	or a			;5958
	jp nz,L_5962		;5959
	ld (0dc2ch),a		;595c
	jp L_5976		;595f
L_5962:
	ld hl,l5968h		;5962
	ld (0dc29h),hl		;5965
L_5968:
	ld hl,0dc2bh		;5968
	dec (hl)			;596b
	ret nz			;596c
	ld a,(0dc10h)		;596d
	ld (hl),a			;5970
	inc hl			;5971
	dec (hl)			;5972
	xor a			;5973
	cp (hl)			;5974
	ret nz			;5975
L_5976:
	ld hl,l597ch		;5976
	ld (0dc29h),hl		;5979
L_597C:
	ret			;597c
L_597D:
	ld hl,(0dc2dh)		;597d
	jp (hl)			;5980
L_5981:
	ld a,(0dc11h)		;5981
	or a			;5984
	jp nz,L_598F		;5985
	dec a			;5988
	ld (0dc30h),a		;5989
	jp L_59A1		;598c
L_598F:
	ld hl,l5992h		;598f
L_5992:
	ld hl,0dc2fh		;5992
	dec (hl)			;5995
	ret nz			;5996
	ld a,(0dc11h)		;5997
	ld (hl),a			;599a
	inc hl			;599b
	inc (hl)			;599c
	ld a,0ffh		;599d
	cp (hl)			;599f
	ret nz			;59a0
L_59A1:
	ld hl,L_59A8		;59a1
	ld (0dc2dh),hl		;59a4
	ret			;59a7
L_59A8:
	ld a,(0dc12h)		;59a8
	or a			;59ab
	ld a,(0dc13h)		;59ac
	jp z,L_59B7		;59af
	cp 0ffh		;59b2
	jp nz,L_59BD		;59b4
L_59B7:
	ld (0dc30h),a		;59b7
	jp L_59D3		;59ba
L_59BD:
	ld hl,l59c3h		;59bd
	ld (0dc2dh),hl		;59c0
L_59C3:
	ld hl,0dc2fh		;59c3
	dec (hl)			;59c6
	ret nz			;59c7
	ld a,(0dc12h)		;59c8
	ld (hl),a			;59cb
	inc hl			;59cc
	dec (hl)			;59cd
	ld a,(0dc13h)		;59ce
	cp (hl)			;59d1
	ret nz			;59d2
L_59D3:
	ld hl,l59d9h		;59d3
	ld (0dc2dh),hl		;59d6
L_59D9:
	ld a,(0dc1bh)		;59d9
	cp 003h		;59dc
	ret nz			;59de
	ld a,(0dc19h)		;59df
	or a			;59e2
	ret nz			;59e3
	ld a,(0dc18h)		;59e4
	bit 7,a		;59e7
	jp nz,L_59F7		;59e9
	ld a,(0dc1ah)		;59ec
	cp 0bfh		;59ef
	jp z,L_59F7		;59f1
	ld (0dcfdh),a		;59f4
L_59F7:
	ld hl,L_59FE		;59f7
	ld (0dc2dh),hl		;59fa
	ret			;59fd
L_59FE:
	ld a,(0dc19h)		;59fe
	or a			;5a01
	ret nz			;5a02
	ld a,(0dc1bh)		;5a03
	set 2,a		;5a06
	ld (0dc1bh),a		;5a08
	ld a,(0dc13h)		;5a0b
	or a			;5a0e
	jp z,L_5A33		;5a0f
	ld a,(0dc14h)		;5a12
	or a			;5a15
	jp nz,L_5A1F		;5a16
	ld (0dc30h),a		;5a19
	jp L_5A33		;5a1c
L_5A1F:
	ld hl,l5a25h		;5a1f
	ld (0dc2dh),hl		;5a22
L_5A25:
	ld hl,0dc2fh		;5a25
	dec (hl)			;5a28
	ret nz			;5a29
	ld a,(0dc14h)		;5a2a
	ld (hl),a			;5a2d
	inc hl			;5a2e
	dec (hl)			;5a2f
	xor a			;5a30
	cp (hl)			;5a31
	ret nz			;5a32
L_5A33:
	ld a,(0dc1bh)		;5a33
	set 7,a		;5a36
	ld (0dc1bh),a		;5a38
	ret			;5a3b
L_5A3C:
	ld e,a			;5a3c
	ld b,008h		;5a3d
	xor a			;5a3f
L_5A40:
	rlc c		;5a40
	jp nc,L_5A46		;5a42
	add a,e			;5a45
L_5A46:
	srl e		;5a46
	djnz L_5A40		;5a48
	ret			;5a4a
L_5A4B:
	ld a,(0dc00h)		;5a4b
	cp 00fh		;5a4e
	jp nc,L_5AD4		;5a50
	ld hl,(0dc32h)		;5a53
	ld a,(hl)			;5a56
	push af			;5a57
	ld a,(0dc02h)		;5a58
	or a			;5a5b
	jp nz,L_5A68		;5a5c
	ld a,(0dc01h)		;5a5f
	ld h,a			;5a62
	ld l,000h		;5a63
	jp L_5A9B		;5a65
L_5A68:
	ld c,a			;5a68
	ld a,(0dc45h)		;5a69
	bit 7,a		;5a6c
	jp z,L_5A73		;5a6e
	neg		;5a71
L_5A73:
	ld e,a			;5a73
	ld d,000h		;5a74
	call L_5AE4		;5a76
	ld a,(0dc45h)		;5a79
	bit 7,a		;5a7c
	jp z,L_5A91		;5a7e
	inc hl			;5a81
	srl h		;5a82
	rr l		;5a84
	ex de,hl			;5a86
	ld hl,00100h		;5a87
	scf			;5a8a
	ccf			;5a8b
	sbc hl,de		;5a8c
	jp L_5A92		;5a8e
L_5A91:
	inc h			;5a91
L_5A92:
	ld a,(0dc01h)		;5a92
	ld e,000h		;5a95
	ld d,a			;5a97
	call L_5AF6		;5a98
L_5A9B:
	ld a,(0dc03h)		;5a9b
	or a			;5a9e
	jp z,L_5ACA		;5a9f
	push hl			;5aa2
	ld c,a			;5aa3
	ld a,(0dc28h)		;5aa4
	ld e,a			;5aa7
	ld d,000h		;5aa8
	call L_5AE4		;5aaa
	ld a,(0dc18h)		;5aad
	bit 3,a		;5ab0
	jp z,L_5AC5		;5ab2
	inc hl			;5ab5
	srl h		;5ab6
	rr l		;5ab8
	ex de,hl			;5aba
	ld hl,00100h		;5abb
	scf			;5abe
	ccf			;5abf
	sbc hl,de		;5ac0
	jp L_5AC6		;5ac2
L_5AC5:
	inc h			;5ac5
L_5AC6:
	pop de			;5ac6
	call L_5AF6		;5ac7
L_5ACA:
	ld de,(0dc31h)		;5aca
	add hl,de			;5ace
	ld (0dc31h),hl		;5acf
	pop af			;5ad2
	ret			;5ad3
L_5AD4:
	ld hl,(0dc35h)		;5ad4
	inc l			;5ad7
	ld (0dc35h),hl		;5ad8
	ld a,(hl)			;5adb
	ld hl,0dc34h		;5adc
	rlc a		;5adf
	add a,(hl)			;5ae1
	ld (hl),a			;5ae2
	ret			;5ae3
L_5AE4:
	ld b,008h		;5ae4
	ld hl,00000h		;5ae6
L_5AE9:
	rlc c		;5ae9
	jp nc,L_5AEF		;5aeb
	add hl,de			;5aee
L_5AEF:
	srl d		;5aef
	rr e		;5af1
	djnz L_5AE9		;5af3
	ret			;5af5
L_5AF6:
	push de			;5af6
	push hl			;5af7
	ld c,l			;5af8
	ld hl,00000h		;5af9
	ld b,008h		;5afc
L_5AFE:
	srl d		;5afe
	rr e		;5b00
	rlc c		;5b02
	jp nc,L_5B08		;5b04
	add hl,de			;5b07
L_5B08:
	djnz L_5AFE		;5b08
	pop de			;5b0a
	ld c,d			;5b0b
	pop de			;5b0c
	ld b,008h		;5b0d
L_5B0F:
	rrc c		;5b0f
	jp nc,L_5B15		;5b11
	add hl,de			;5b14
L_5B15:
	sla e		;5b15
	rl d		;5b17
	djnz L_5B0F		;5b19
	ret			;5b1b
L_5B1C:
	ld l,a			;5b1c
	ld a,(0dc07h)		;5b1d
	or a			;5b20
	jp nz,L_5B2A		;5b21
	ld a,(0dc04h)		;5b24
	jp L_5B4B		;5b27
L_5B2A:
	ld c,a			;5b2a
	ld a,(0dc2ch)		;5b2b
	call L_5A3C		;5b2e
	ld b,a			;5b31
	ld a,(0dc18h)		;5b32
	bit 2,a		;5b35
	ld a,(0dc04h)		;5b37
	jp nz,L_5B46		;5b3a
	add a,b			;5b3d
	jp nc,L_5B4B		;5b3e
	ld a,0ffh		;5b41
	jp L_5B4B		;5b43
L_5B46:
	sub b			;5b46
	jp nc,L_5B4B		;5b47
	xor a			;5b4a
L_5B4B:
	ld h,a			;5b4b
	ld a,(0dc06h)		;5b4c
	or a			;5b4f
	jp nz,L_5B57		;5b50
	ld a,h			;5b53
	jp L_5B75		;5b54
L_5B57:
	ld c,a			;5b57
	ld a,(0dc45h)		;5b58
	call L_5CB5		;5b5b
	bit 7,a		;5b5e
	jp nz,L_5B6C		;5b60
	add a,h			;5b63
	jp nc,L_5B75		;5b64
	ld a,0ffh		;5b67
	jp L_5B75		;5b69
L_5B6C:
	neg		;5b6c
	ld b,a			;5b6e
	ld a,h			;5b6f
	sub b			;5b70
	jp nc,L_5B75		;5b71
	xor a			;5b74
L_5B75:
	ld (0dc37h),a		;5b75
	ld h,000h		;5b78
	bit 7,l		;5b7a
	jp z,L_5B80		;5b7c
	dec h			;5b7f
L_5B80:
	ld a,(0dc38h)		;5b80
	or a			;5b83
	jp z,L_5B99		;5b84
	push hl			;5b87
	ld a,(0dc37h)		;5b88
	ld hl,(0dc3ch)		;5b8b
	call L_5C3E		;5b8e
	ld a,(0dc38h)		;5b91
	call L_5C58		;5b94
	pop de			;5b97
	add hl,de			;5b98
L_5B99:
	push hl			;5b99
	ld de,(0dc3ah)		;5b9a
	scf			;5b9e
	ccf			;5b9f
	sbc hl,de		;5ba0
	ld a,(0dc37h)		;5ba2
	inc a			;5ba5
	jp z,L_5BAC		;5ba6
	call L_5C24		;5ba9
L_5BAC:
	ld de,(0dc3ah)		;5bac
	add hl,de			;5bb0
	ld (0dc3ah),hl		;5bb1
	ex de,hl			;5bb4
	pop hl			;5bb5
	scf			;5bb6
	ccf			;5bb7
	sbc hl,de		;5bb8
	ld (0dc3eh),hl		;5bba
	ld a,(0dc18h)		;5bbd
	bit 0,a		;5bc0
	jp nz,L_5BCC		;5bc2
	ld a,(0dc38h)		;5bc5
	or a			;5bc8
	jp z,L_5BE6		;5bc9
L_5BCC:
	ld de,(0dc3ch)		;5bcc
	scf			;5bd0
	ccf			;5bd1
	sbc hl,de		;5bd2
	ld a,(0dc37h)		;5bd4
	inc a			;5bd7
	jp z,L_5BDE		;5bd8
	call L_5C24		;5bdb
L_5BDE:
	ld de,(0dc3ch)		;5bde
	add hl,de			;5be2
	ld (0dc3ch),hl		;5be3
L_5BE6:
	ld a,(0dc18h)		;5be6
	bit 0,a		;5be9
	jp nz,L_5C06		;5beb
	bit 1,a		;5bee
	jp nz,L_5C03		;5bf0
	ld hl,(0dc3eh)		;5bf3
	bit 7,h		;5bf6
	jp z,L_5BFC		;5bf8
	inc hl			;5bfb
L_5BFC:
	sra h		;5bfc
	rr l		;5bfe
	jp L_5C06		;5c00
L_5C03:
	ld hl,(0dc3ah)		;5c03
L_5C06:
	ld a,(0dc39h)		;5c06
	or a			;5c09
	jp z,L_5C10		;5c0a
	call L_5C24		;5c0d
L_5C10:
	ld a,l			;5c10
	ret			;5c11

; ----------------------------------------------------------------------
; DATOS pasos_del_lfo: 9 valores por (0xDC05) que 0x5710 copia a 0xDC38
;   0x5c12..0x5c1b  (9 bytes)
DATA_pasos_del_lfo:
	defb 000h,030h,050h,070h,090h,0a0h,0a8h,0b0h,0b8h	; 5c12  .0Pp.....

; ----------------------------------------------------------------------
; DATOS pasos_del_lfo_2: 9 valores por (0xDC05) que 0x5718 copia a 0xDC39
;   0x5c1b..0x5c24  (9 bytes)
DATA_pasos_del_lfo_2:
	defb 000h,0cfh,09bh,071h,04dh,03ah,028h,022h,00eh	; 5c1b  ...qM:(".

; ======================================================================
; CODIGO 0x5c24..0x5da9  (389 bytes)
; ======================================================================


L_5C24:
	ld b,008h		;5c24
	ld c,a			;5c26
	ex de,hl			;5c27
	ld hl,00000h		;5c28
L_5C2B:
	bit 7,d		;5c2b
	jp z,L_5C31		;5c2d
	inc de			;5c30
L_5C31:
	sra d		;5c31
	rr e		;5c33
	rlc c		;5c35
	jp nc,L_5C3B		;5c37
	add hl,de			;5c3a
L_5C3B:
	djnz L_5C2B		;5c3b
	ret			;5c3d
L_5C3E:
	ld b,008h		;5c3e
	ld c,a			;5c40
	ex de,hl			;5c41
	ld hl,00000h		;5c42
L_5C45:
	rlc c		;5c45
	jp nc,L_5C4B		;5c47
	add hl,de			;5c4a
L_5C4B:
	bit 7,d		;5c4b
	jp z,L_5C51		;5c4d
	inc de			;5c50
L_5C51:
	sra d		;5c51
	rr e		;5c53
	djnz L_5C45		;5c55
	ret			;5c57
L_5C58:
	ld c,a			;5c58
	ex de,hl			;5c59
	ld hl,00000h		;5c5a
	rlc c		;5c5d
	jp nc,L_5C69		;5c5f
	push de			;5c62
	sla e		;5c63
	rl d		;5c65
	add hl,de			;5c67
	pop de			;5c68
L_5C69:
	ld b,007h		;5c69
L_5C6B:
	rlc c		;5c6b
	jp nc,L_5C71		;5c6d
	add hl,de			;5c70
L_5C71:
	bit 7,d		;5c71
	jp z,L_5C77		;5c73
	inc de			;5c76
L_5C77:
	sra d		;5c77
	rr e		;5c79
	djnz L_5C6B		;5c7b
	ret			;5c7d
L_5C7E:
	push af			;5c7e
	ld a,(0dc08h)		;5c7f
	or a			;5c82
	jp z,L_5CB1		;5c83
	ld d,a			;5c86
	ld c,a			;5c87
	ld a,(0dc45h)		;5c88
	call L_5CB5		;5c8b
	ld c,a			;5c8e
	ld a,080h		;5c8f
	sub d			;5c91
	add a,c			;5c92
	ld c,a			;5c93
	pop af			;5c94
	call L_5CB5		;5c95
L_5C98:
	ld e,a			;5c98
	ld a,(0dc30h)		;5c99
	ld c,a			;5c9c
	ld b,007h		;5c9d
	xor a			;5c9f
L_5CA0:
	bit 7,e		;5ca0
	jp z,L_5CA6		;5ca2
	inc e			;5ca5
L_5CA6:
	sra e		;5ca6
	rlc c		;5ca8
	jp nc,L_5CAE		;5caa
	add a,e			;5cad
L_5CAE:
	djnz L_5CA0		;5cae
	ret			;5cb0
L_5CB1:
	pop af			;5cb1
	jp L_5C98		;5cb2
L_5CB5:
	ld e,a			;5cb5
	ld b,008h		;5cb6
	xor a			;5cb8
L_5CB9:
	rlc c		;5cb9
	jp nc,L_5CBF		;5cbb
	add a,e			;5cbe
L_5CBF:
	bit 7,e		;5cbf
	jp z,L_5CC5		;5cc1
	inc e			;5cc4
L_5CC5:
	sra e		;5cc5
	djnz L_5CB9		;5cc7
	ret			;5cc9
L_5CCA:
	ld hl,(0dc40h)		;5cca
	jp (hl)			;5ccd
L_5CCE:
	ld a,(0dc02h)		;5cce
	ld b,a			;5cd1
	ld a,(0dc06h)		;5cd2
	or b			;5cd5
	ld b,a			;5cd6
	ld a,(0dc08h)		;5cd7
	or b			;5cda
	ret z			;5cdb
	ld a,(0dc16h)		;5cdc
	cp 00fh		;5cdf
	jp nc,L_5D18		;5ce1
	ld a,(0dc46h)		;5ce4
	dec a			;5ce7
	cp 0ffh		;5ce8
	jp nz,L_5CF7		;5cea
	ld hl,(0dc43h)		;5ced
	ld a,(hl)			;5cf0
	ld (0dc45h),a		;5cf1
	ld a,(0dc15h)		;5cf4
L_5CF7:
	ld (0dc46h),a		;5cf7
	ld hl,(0dc42h)		;5cfa
	ld a,(0dc17h)		;5cfd
	ld e,a			;5d00
	ld d,000h		;5d01
	sla e		;5d03
	rl d		;5d05
	sla e		;5d07
	rl d		;5d09
	sla e		;5d0b
	rl d		;5d0d
	sla e		;5d0f
	rl d		;5d11
	add hl,de			;5d13
	ld (0dc42h),hl		;5d14
	ret			;5d17
L_5D18:
	ld a,(0dc46h)		;5d18
	dec a			;5d1b
	cp 0ffh		;5d1c
	jp nz,L_5D36		;5d1e
	ld hl,(0dc35h)		;5d21
	inc l			;5d24
	ld (0dc35h),hl		;5d25
	ld a,(hl)			;5d28
	ld hl,0dc34h		;5d29
	rlc a		;5d2c
	add a,(hl)			;5d2e
	ld (hl),a			;5d2f
	ld (0dc45h),a		;5d30
	ld a,(0dc15h)		;5d33
L_5D36:
	ld (0dc46h),a		;5d36
L_5D39:
	ret			;5d39
L_5D3A:
	di			;5d3a
	ld a,(0dcfdh)		;5d3b
	or a			;5d3e
	jp z,L_6723		;5d3f
	jp L_5EA5		;5d42
L_5D45:
	in a,(0aah)		;5d45
	and 0f0h		;5d47
	out (0aah),a		;5d49
L_5D4B:
	in a,(0a9h)		;5d4b
	inc a			;5d4d
	ret nz			;5d4e
	in a,(0aah)		;5d4f
	inc a			;5d51
	out (0aah),a		;5d52
	and 00fh		;5d54
	cp 008h		;5d56
	jp c,L_5D4B		;5d58
	xor a			;5d5b
	ret			;5d5c
L_5D5D:
	push af			;5d5d
	ld a,080h		;5d5e
	ld (04000h),a		;5d60
	pop af			;5d63
	dec a			;5d64
	push af			;5d65
	cpl			;5d66
	ld c,a			;5d67
	pop af			;5d68
	ld e,0ffh		;5d69
L_5D6B:
	inc e			;5d6b
	rrc a		;5d6c
	jp c,L_5D6B		;5d6e
	in a,(0aah)		;5d71
	and 007h		;5d73
	sla a		;5d75
	sla a		;5d77
	sla a		;5d79
	add a,e			;5d7b
	inc a			;5d7c
	ld (0dc47h),a		;5d7d
	ret			;5d80
L_5D81:
	sla a		;5d81
	ld e,a			;5d83
	ld d,000h		;5d84
	ld hl,0d22eh		;5d86
	add hl,de			;5d89
	ld a,(hl)			;5d8a
	inc hl			;5d8b
	ld d,(hl)			;5d8c
	cp 0ffh		;5d8d
	ret			;5d8f
L_5D90:
	push af			;5d90
	push bc			;5d91
	push de			;5d92
	call L_4A14		;5d93
	pop de			;5d96
	pop bc			;5d97
	pop af			;5d98
	ret			;5d99
L_5D9A:
	push de			;5d9a
	sla a		;5d9b
	ld e,a			;5d9d
	ld d,000h		;5d9e
	add hl,de			;5da0
	ld e,(hl)			;5da1
	inc hl			;5da2
	ld d,(hl)			;5da3
	push de			;5da4
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


L_5EA5:
	call L_5D45		;5ea5
	ret z			;5ea8
L_5EA9:
	call L_5D5D		;5ea9
	call L_5D81		;5eac
	ret z			;5eaf
	call L_5D90		;5eb0
	ld hl,05e8bh		;5eb3
	call L_5D9A		;5eb6
	push bc			;5eb9
	push de			;5eba
	call ram_en_la_pagina_2		;5ebb
	pop de			;5ebe
	pop bc			;5ebf
	ld hl,08000h		;5ec0
	ld a,(0dcfdh)		;5ec3
	ld e,a			;5ec6
	jp (ix)		;5ec7
L_5EC9:
	ld a,(hl)			;5ec9
	ld (04000h),a		;5eca
	inc hl			;5ecd
	ld a,d			;5ece
L_5ECF:
	dec a			;5ecf
	jp nz,L_5ECF		;5ed0
	nop			;5ed3
	in a,(0a9h)		;5ed4
	and c			;5ed6
	jp nz,L_5EFD		;5ed7
	ld a,(hl)			;5eda
	ld (04000h),a		;5edb
	inc hl			;5ede
	ld a,d			;5edf
L_5EE0:
	dec a			;5ee0
	jp nz,L_5EE0		;5ee1
	cp 000h		;5ee4
	nop			;5ee6
	ld a,e			;5ee7
	cp h			;5ee8
	jp nz,L_5EC9		;5ee9
L_5EEC:
	ld a,(hl)			;5eec
	ld (04000h),a		;5eed
	inc hl			;5ef0
	ld a,d			;5ef1
L_5EF2:
	dec a			;5ef2
	jp nz,L_5EF2		;5ef3
	ld h,e			;5ef6
	in a,(0a9h)		;5ef7
	and c			;5ef9
	jp z,L_5EEC		;5efa
L_5EFD:
	ld a,(hl)			;5efd
	ld (04000h),a		;5efe
	inc hl			;5f01
	ld a,d			;5f02
L_5F03:
	dec a			;5f03
	jp nz,L_5F03		;5f04
	cp 000h		;5f07
	nop			;5f09
	ld a,l			;5f0a
	or a			;5f0b
	jp nz,L_5EFD		;5f0c
L_5F0F:
	ld a,(hl)			;5f0f
	ld (04000h),a		;5f10
	inc hl			;5f13
	ld a,d			;5f14
L_5F15:
	dec a			;5f15
	jp nz,L_5F15		;5f16
	inc ix		;5f19
	in a,(0aah)		;5f1b
	inc a			;5f1d
	ld e,a			;5f1e
	ld a,(hl)			;5f1f
	ld (04000h),a		;5f20
	inc hl			;5f23
	ld a,d			;5f24
L_5F25:
	dec a			;5f25
	jp nz,L_5F25		;5f26
	cp 000h		;5f29
	ld a,e			;5f2b
	and 0f7h		;5f2c
	out (0aah),a		;5f2e
	ld a,(hl)			;5f30
	ld (04000h),a		;5f31
	inc hl			;5f34
	ld a,d			;5f35
L_5F36:
	dec a			;5f36
	jp nz,L_5F36		;5f37
	nop			;5f3a
	in a,(0a9h)		;5f3b
	inc a			;5f3d
	jp nz,L_66FE		;5f3e
	ld a,(hl)			;5f41
	ld (04000h),a		;5f42
	inc hl			;5f45
	ld a,d			;5f46
L_5F47:
	dec a			;5f47
	jp nz,L_5F47		;5f48
	neg		;5f4b
	ld a,0c0h		;5f4d
	cp h			;5f4f
	jp nz,L_5F0F		;5f50
	jp L_66F7		;5f53
L_5F56:
	dec d			;5f56
L_5F57:
	ld a,(hl)			;5f57
	ld (04000h),a		;5f58
	inc hl			;5f5b
	ld a,d			;5f5c
L_5F5D:
	dec a			;5f5d
	jp nz,L_5F5D		;5f5e
	add ix,ix		;5f61
	nop			;5f63
	in a,(0a9h)		;5f64
	and c			;5f66
	jp nz,L_5F91		;5f67
	ld a,(hl)			;5f6a
	ld (04000h),a		;5f6b
	inc hl			;5f6e
	ld a,d			;5f6f
L_5F70:
	dec a			;5f70
	jp nz,L_5F70		;5f71
	add ix,ix		;5f74
	cp 000h		;5f76
	nop			;5f78
	ld a,e			;5f79
	cp h			;5f7a
	jp nz,L_5F57		;5f7b
L_5F7E:
	ld a,(hl)			;5f7e
	ld (04000h),a		;5f7f
	inc hl			;5f82
	ld a,d			;5f83
L_5F84:
	dec a			;5f84
	jp nz,L_5F84		;5f85
	add ix,ix		;5f88
	ld h,e			;5f8a
	in a,(0a9h)		;5f8b
	and c			;5f8d
	jp z,L_5F7E		;5f8e
L_5F91:
	ld a,(hl)			;5f91
	ld (04000h),a		;5f92
	inc hl			;5f95
	ld a,d			;5f96
L_5F97:
	dec a			;5f97
	jp nz,L_5F97		;5f98
	add ix,ix		;5f9b
	cp 000h		;5f9d
	nop			;5f9f
	ld a,l			;5fa0
	or a			;5fa1
	jp nz,L_5F91		;5fa2
L_5FA5:
	ld a,(hl)			;5fa5
	ld (04000h),a		;5fa6
	inc hl			;5fa9
	ld a,d			;5faa
L_5FAB:
	dec a			;5fab
	jp nz,L_5FAB		;5fac
	add ix,ix		;5faf
	inc ix		;5fb1
	in a,(0aah)		;5fb3
	inc a			;5fb5
	ld e,a			;5fb6
	ld a,(hl)			;5fb7
	ld (04000h),a		;5fb8
	inc hl			;5fbb
	ld a,d			;5fbc
L_5FBD:
	dec a			;5fbd
	jp nz,L_5FBD		;5fbe
	add ix,ix		;5fc1
	cp 000h		;5fc3
	ld a,e			;5fc5
	and 0f7h		;5fc6
	out (0aah),a		;5fc8
	ld a,(hl)			;5fca
	ld (04000h),a		;5fcb
	inc hl			;5fce
	ld a,d			;5fcf
L_5FD0:
	dec a			;5fd0
	jp nz,L_5FD0		;5fd1
	add ix,ix		;5fd4
	nop			;5fd6
	in a,(0a9h)		;5fd7
	inc a			;5fd9
	jp nz,L_66FE		;5fda
	ld a,(hl)			;5fdd
	ld (04000h),a		;5fde
	inc hl			;5fe1
	ld a,d			;5fe2
L_5FE3:
	dec a			;5fe3
	jp nz,L_5FE3		;5fe4
	add ix,ix		;5fe7
	neg		;5fe9
	ld a,0c0h		;5feb
	cp h			;5fed
	jp nz,L_5FA5		;5fee
	jp L_66F7		;5ff1
L_5FF4:
	dec d			;5ff4
L_5FF5:
	ld a,(hl)			;5ff5
	ld (04000h),a		;5ff6
	inc hl			;5ff9
	ld a,d			;5ffa
L_5FFB:
	dec a			;5ffb
	jp nz,L_5FFB		;5ffc
	neg		;5fff
	neg		;6001
	nop			;6003
	in a,(0a9h)		;6004
	and c			;6006
	jp nz,L_6035		;6007
	ld a,(hl)			;600a
	ld (04000h),a		;600b
	inc hl			;600e
	ld a,d			;600f
L_6010:
	dec a			;6010
	jp nz,L_6010		;6011
	neg		;6014
	neg		;6016
	cp 000h		;6018
	nop			;601a
	ld a,e			;601b
	cp h			;601c
	jp nz,L_5FF5		;601d
L_6020:
	ld a,(hl)			;6020
	ld (04000h),a		;6021
	inc hl			;6024
	ld a,d			;6025
L_6026:
	dec a			;6026
	jp nz,L_6026		;6027
	neg		;602a
	neg		;602c
	ld h,e			;602e
	in a,(0a9h)		;602f
	and c			;6031
	jp z,L_6020		;6032
L_6035:
	ld a,(hl)			;6035
	ld (04000h),a		;6036
	inc hl			;6039
	ld a,d			;603a
L_603B:
	dec a			;603b
	jp nz,L_603B		;603c
	neg		;603f
	neg		;6041
	cp 000h		;6043
	nop			;6045
	ld a,l			;6046
	or a			;6047
	jp nz,L_6035		;6048
L_604B:
	ld a,(hl)			;604b
	ld (04000h),a		;604c
	inc hl			;604f
	ld a,d			;6050
L_6051:
	dec a			;6051
	jp nz,L_6051		;6052
	neg		;6055
	neg		;6057
	inc ix		;6059
	in a,(0aah)		;605b
	inc a			;605d
	ld e,a			;605e
	ld a,(hl)			;605f
	ld (04000h),a		;6060
	inc hl			;6063
	ld a,d			;6064
L_6065:
	dec a			;6065
	jp nz,L_6065		;6066
	neg		;6069
	neg		;606b
	cp 000h		;606d
	ld a,e			;606f
	and 0f7h		;6070
	out (0aah),a		;6072
	ld a,(hl)			;6074
	ld (04000h),a		;6075
	inc hl			;6078
	ld a,d			;6079
L_607A:
	dec a			;607a
	jp nz,L_607A		;607b
	neg		;607e
	neg		;6080
	nop			;6082
	in a,(0a9h)		;6083
	inc a			;6085
	jp nz,L_66FE		;6086
	ld a,(hl)			;6089
	ld (04000h),a		;608a
	inc hl			;608d
	ld a,d			;608e
L_608F:
	dec a			;608f
	jp nz,L_608F		;6090
	neg		;6093
	neg		;6095
	neg		;6097
	ld a,0c0h		;6099
	cp h			;609b
	jp nz,L_604B		;609c
	jp L_66F7		;609f
L_60A2:
	dec d			;60a2
L_60A3:
	ld a,(hl)			;60a3
	ld (04000h),a		;60a4
	inc hl			;60a7
	ld a,d			;60a8
L_60A9:
	dec a			;60a9
	jp nz,L_60A9		;60aa
	inc ix		;60ad
	cp 000h		;60af
	nop			;60b1
	in a,(0a9h)		;60b2
	and c			;60b4
	jp nz,L_60E3		;60b5
	ld a,(hl)			;60b8
	ld (04000h),a		;60b9
	inc hl			;60bc
	ld a,d			;60bd
L_60BE:
	dec a			;60be
	jp nz,L_60BE		;60bf
	inc ix		;60c2
	cp 000h		;60c4
	cp 000h		;60c6
	nop			;60c8
	ld a,e			;60c9
	cp h			;60ca
	jp nz,L_60A3		;60cb
L_60CE:
	ld a,(hl)			;60ce
	ld (04000h),a		;60cf
	inc hl			;60d2
	ld a,d			;60d3
L_60D4:
	dec a			;60d4
	jp nz,L_60D4		;60d5
	inc ix		;60d8
	cp 000h		;60da
	ld h,e			;60dc
	in a,(0a9h)		;60dd
	and c			;60df
	jp z,L_60CE		;60e0
L_60E3:
	ld a,(hl)			;60e3
	ld (04000h),a		;60e4
	inc hl			;60e7
	ld a,d			;60e8
L_60E9:
	dec a			;60e9
	jp nz,L_60E9		;60ea
	inc ix		;60ed
	cp 000h		;60ef
	cp 000h		;60f1
	nop			;60f3
	ld a,l			;60f4
	or a			;60f5
	jp nz,L_60E3		;60f6
L_60F9:
	ld a,(hl)			;60f9
	ld (04000h),a		;60fa
	inc hl			;60fd
	ld a,d			;60fe
L_60FF:
	dec a			;60ff
	jp nz,L_60FF		;6100
	inc ix		;6103
	cp 000h		;6105
	inc ix		;6107
	in a,(0aah)		;6109
	inc a			;610b
	ld e,a			;610c
	ld a,(hl)			;610d
	ld (04000h),a		;610e
	inc hl			;6111
	ld a,d			;6112
L_6113:
	dec a			;6113
	jp nz,L_6113		;6114
	inc ix		;6117
	cp 000h		;6119
	cp 000h		;611b
	ld a,e			;611d
	and 0f7h		;611e
	out (0aah),a		;6120
	ld a,(hl)			;6122
	ld (04000h),a		;6123
	inc hl			;6126
	ld a,d			;6127
L_6128:
	dec a			;6128
	jp nz,L_6128		;6129
	inc ix		;612c
	cp 000h		;612e
	nop			;6130
	in a,(0a9h)		;6131
	inc a			;6133
	jp nz,L_66FE		;6134
	ld a,(hl)			;6137
	ld (04000h),a		;6138
	inc hl			;613b
	ld a,d			;613c
L_613D:
	dec a			;613d
	jp nz,L_613D		;613e
	inc ix		;6141
	cp 000h		;6143
	neg		;6145
	ld a,0c0h		;6147
	cp h			;6149
	jp nz,L_60F9		;614a
	jp L_66F7		;614d
L_6150:
	ld a,(hl)			;6150
	ld (04000h),a		;6151
	inc hl			;6154
	ld a,d			;6155
L_6156:
	dec a			;6156
	jp nz,L_6156		;6157
	nop			;615a
	nop			;615b
	in a,(0a9h)		;615c
	and c			;615e
	jp nz,L_6187		;615f
	ld a,(hl)			;6162
	ld (04000h),a		;6163
	inc hl			;6166
	ld a,d			;6167
L_6168:
	dec a			;6168
	jp nz,L_6168		;6169
	nop			;616c
	cp 000h		;616d
	nop			;616f
	ld a,e			;6170
	cp h			;6171
	jp nz,L_6150		;6172
L_6175:
	ld a,(hl)			;6175
	ld (04000h),a		;6176
	inc hl			;6179
	ld a,d			;617a
L_617B:
	dec a			;617b
	jp nz,L_617B		;617c
	nop			;617f
	ld h,e			;6180
	in a,(0a9h)		;6181
	and c			;6183
	jp z,L_6175		;6184
L_6187:
	ld a,(hl)			;6187
	ld (04000h),a		;6188
	inc hl			;618b
	ld a,d			;618c
L_618D:
	dec a			;618d
	jp nz,L_618D		;618e
	nop			;6191
	cp 000h		;6192
	nop			;6194
	ld a,l			;6195
	or a			;6196
	jp nz,L_6187		;6197
L_619A:
	ld a,(hl)			;619a
	ld (04000h),a		;619b
	inc hl			;619e
	ld a,d			;619f
L_61A0:
	dec a			;61a0
	jp nz,L_61A0		;61a1
	nop			;61a4
	inc ix		;61a5
	in a,(0aah)		;61a7
	inc a			;61a9
	ld e,a			;61aa
	ld a,(hl)			;61ab
	ld (04000h),a		;61ac
	inc hl			;61af
	ld a,d			;61b0
L_61B1:
	dec a			;61b1
	jp nz,L_61B1		;61b2
	nop			;61b5
	cp 000h		;61b6
	ld a,e			;61b8
	and 0f7h		;61b9
	out (0aah),a		;61bb
	ld a,(hl)			;61bd
	ld (04000h),a		;61be
	inc hl			;61c1
	ld a,d			;61c2
L_61C3:
	dec a			;61c3
	jp nz,L_61C3		;61c4
	nop			;61c7
	nop			;61c8
	in a,(0a9h)		;61c9
	inc a			;61cb
	jp nz,L_66FE		;61cc
	ld a,(hl)			;61cf
	ld (04000h),a		;61d0
	inc hl			;61d3
	ld a,d			;61d4
L_61D5:
	dec a			;61d5
	jp nz,L_61D5		;61d6
	nop			;61d9
	neg		;61da
	ld a,0c0h		;61dc
	cp h			;61de
	jp nz,L_619A		;61df
	jp L_66F7		;61e2
L_61E5:
	dec d			;61e5
L_61E6:
	ld a,(hl)			;61e6
	ld (04000h),a		;61e7
	inc hl			;61ea
	ld a,d			;61eb
L_61EC:
	dec a			;61ec
	jp nz,L_61EC		;61ed
	add a,(ix+000h)		;61f0
	nop			;61f3
	in a,(0a9h)		;61f4
	and c			;61f6
	jp nz,L_6223		;61f7
	ld a,(hl)			;61fa
	ld (04000h),a		;61fb
	inc hl			;61fe
	ld a,d			;61ff
L_6200:
	dec a			;6200
	jp nz,L_6200		;6201
	add a,(ix+000h)		;6204
	cp 000h		;6207
	nop			;6209
	ld a,e			;620a
	cp h			;620b
	jp nz,L_61E6		;620c
L_620F:
	ld a,(hl)			;620f
	ld (04000h),a		;6210
	inc hl			;6213
	ld a,d			;6214
L_6215:
	dec a			;6215
	jp nz,L_6215		;6216
	add a,(ix+000h)		;6219
	ld h,e			;621c
	in a,(0a9h)		;621d
	and c			;621f
	jp z,L_620F		;6220
L_6223:
	ld a,(hl)			;6223
	ld (04000h),a		;6224
	inc hl			;6227
	ld a,d			;6228
L_6229:
	dec a			;6229
	jp nz,L_6229		;622a
	add a,(ix+000h)		;622d
	cp 000h		;6230
	nop			;6232
	ld a,l			;6233
	or a			;6234
	jp nz,L_6223		;6235
L_6238:
	ld a,(hl)			;6238
	ld (04000h),a		;6239
	inc hl			;623c
	ld a,d			;623d
L_623E:
	dec a			;623e
	jp nz,L_623E		;623f
	add a,(ix+000h)		;6242
	inc ix		;6245
	in a,(0aah)		;6247
	inc a			;6249
	ld e,a			;624a
	ld a,(hl)			;624b
	ld (04000h),a		;624c
	inc hl			;624f
	ld a,d			;6250
L_6251:
	dec a			;6251
	jp nz,L_6251		;6252
	add a,(ix+000h)		;6255
	cp 000h		;6258
	ld a,e			;625a
	and 0f7h		;625b
	out (0aah),a		;625d
	ld a,(hl)			;625f
	ld (04000h),a		;6260
	inc hl			;6263
	ld a,d			;6264
L_6265:
	dec a			;6265
	jp nz,L_6265		;6266
	add a,(ix+000h)		;6269
	nop			;626c
	in a,(0a9h)		;626d
	inc a			;626f
	jp nz,L_66FE		;6270
	ld a,(hl)			;6273
	ld (04000h),a		;6274
	inc hl			;6277
	ld a,d			;6278
L_6279:
	dec a			;6279
	jp nz,L_6279		;627a
	add a,(ix+000h)		;627d
	neg		;6280
	ld a,0c0h		;6282
	cp h			;6284
	jp nz,L_6238		;6285
	jp L_66F7		;6288
L_628B:
	dec d			;628b
L_628C:
	ld a,(hl)			;628c
	ld (04000h),a		;628d
	inc hl			;6290
	ld a,d			;6291
L_6292:
	dec a			;6292
	jp nz,L_6292		;6293
	inc ix		;6296
	inc ix		;6298
	nop			;629a
	in a,(0a9h)		;629b
	and c			;629d
	jp nz,L_62CC		;629e
	ld a,(hl)			;62a1
	ld (04000h),a		;62a2
	inc hl			;62a5
	ld a,d			;62a6
L_62A7:
	dec a			;62a7
	jp nz,L_62A7		;62a8
	inc ix		;62ab
	inc ix		;62ad
	cp 000h		;62af
	nop			;62b1
	ld a,e			;62b2
	cp h			;62b3
	jp nz,L_628C		;62b4
L_62B7:
	ld a,(hl)			;62b7
	ld (04000h),a		;62b8
	inc hl			;62bb
	ld a,d			;62bc
L_62BD:
	dec a			;62bd
	jp nz,L_62BD		;62be
	inc ix		;62c1
	inc ix		;62c3
	ld h,e			;62c5
	in a,(0a9h)		;62c6
	and c			;62c8
	jp z,L_62B7		;62c9
L_62CC:
	ld a,(hl)			;62cc
	ld (04000h),a		;62cd
	inc hl			;62d0
	ld a,d			;62d1
L_62D2:
	dec a			;62d2
	jp nz,L_62D2		;62d3
	inc ix		;62d6
	inc ix		;62d8
	cp 000h		;62da
	nop			;62dc
	ld a,l			;62dd
	or a			;62de
	jp nz,L_62CC		;62df
L_62E2:
	ld a,(hl)			;62e2
	ld (04000h),a		;62e3
	inc hl			;62e6
	ld a,d			;62e7
L_62E8:
	dec a			;62e8
	jp nz,L_62E8		;62e9
	inc ix		;62ec
	inc ix		;62ee
	inc ix		;62f0
	in a,(0aah)		;62f2
	inc a			;62f4
	ld e,a			;62f5
	ld a,(hl)			;62f6
	ld (04000h),a		;62f7
	inc hl			;62fa
	ld a,d			;62fb
L_62FC:
	dec a			;62fc
	jp nz,L_62FC		;62fd
	inc ix		;6300
	inc ix		;6302
	cp 000h		;6304
	ld a,e			;6306
	and 0f7h		;6307
	out (0aah),a		;6309
	ld a,(hl)			;630b
	ld (04000h),a		;630c
	inc hl			;630f
	ld a,d			;6310
L_6311:
	dec a			;6311
	jp nz,L_6311		;6312
	inc ix		;6315
	inc ix		;6317
	nop			;6319
	in a,(0a9h)		;631a
	inc a			;631c
	jp nz,L_66FE		;631d
	ld a,(hl)			;6320
	ld (04000h),a		;6321
	inc hl			;6324
	ld a,d			;6325
L_6326:
	dec a			;6326
	jp nz,L_6326		;6327
	inc ix		;632a
	inc ix		;632c
	neg		;632e
	ld a,0c0h		;6330
	cp h			;6332
	jp nz,L_62E2		;6333
	jp L_66F7		;6336
L_6339:
	ld a,(hl)			;6339
	ld (04000h),a		;633a
	inc hl			;633d
	ld a,d			;633e
L_633F:
	dec a			;633f
	jp nz,L_633F		;6340
	cp 000h		;6343
	nop			;6345
	in a,(0a9h)		;6346
	and c			;6348
	jp nz,L_6373		;6349
	ld a,(hl)			;634c
	ld (04000h),a		;634d
	inc hl			;6350
	ld a,d			;6351
L_6352:
	dec a			;6352
	jp nz,L_6352		;6353
	cp 000h		;6356
	cp 000h		;6358
	nop			;635a
	ld a,e			;635b
	cp h			;635c
	jp nz,L_6339		;635d
L_6360:
	ld a,(hl)			;6360
	ld (04000h),a		;6361
	inc hl			;6364
	ld a,d			;6365
L_6366:
	dec a			;6366
	jp nz,L_6366		;6367
	cp 000h		;636a
	ld h,e			;636c
	in a,(0a9h)		;636d
	and c			;636f
	jp z,L_6360		;6370
L_6373:
	ld a,(hl)			;6373
	ld (04000h),a		;6374
	inc hl			;6377
	ld a,d			;6378
L_6379:
	dec a			;6379
	jp nz,L_6379		;637a
	cp 000h		;637d
	cp 000h		;637f
	nop			;6381
	ld a,l			;6382
	or a			;6383
	jp nz,L_6373		;6384
L_6387:
	ld a,(hl)			;6387
	ld (04000h),a		;6388
	inc hl			;638b
	ld a,d			;638c
L_638D:
	dec a			;638d
	jp nz,L_638D		;638e
	cp 000h		;6391
	inc ix		;6393
	in a,(0aah)		;6395
	inc a			;6397
	ld e,a			;6398
	ld a,(hl)			;6399
	ld (04000h),a		;639a
	inc hl			;639d
	ld a,d			;639e
L_639F:
	dec a			;639f
	jp nz,L_639F		;63a0
	cp 000h		;63a3
	cp 000h		;63a5
	ld a,e			;63a7
	and 0f7h		;63a8
	out (0aah),a		;63aa
	ld a,(hl)			;63ac
	ld (04000h),a		;63ad
	inc hl			;63b0
	ld a,d			;63b1
L_63B2:
	dec a			;63b2
	jp nz,L_63B2		;63b3
	cp 000h		;63b6
	nop			;63b8
	in a,(0a9h)		;63b9
	inc a			;63bb
	jp nz,L_66FE		;63bc
	ld a,(hl)			;63bf
	ld (04000h),a		;63c0
	inc hl			;63c3
	ld a,d			;63c4
L_63C5:
	dec a			;63c5
	jp nz,L_63C5		;63c6
	cp 000h		;63c9
	neg		;63cb
	ld a,0c0h		;63cd
	cp h			;63cf
	jp nz,L_6387		;63d0
	jp L_66F7		;63d3
L_63D6:
	ld a,(hl)			;63d6
	ld (04000h),a		;63d7
	inc hl			;63da
	ld a,d			;63db
L_63DC:
	dec a			;63dc
	jp nz,L_63DC		;63dd
	neg		;63e0
	nop			;63e2
	in a,(0a9h)		;63e3
	and c			;63e5
	jp nz,L_6410		;63e6
	ld a,(hl)			;63e9
	ld (04000h),a		;63ea
	inc hl			;63ed
	ld a,d			;63ee
L_63EF:
	dec a			;63ef
	jp nz,L_63EF		;63f0
	neg		;63f3
	cp 000h		;63f5
	nop			;63f7
	ld a,e			;63f8
	cp h			;63f9
	jp nz,L_63D6		;63fa
L_63FD:
	ld a,(hl)			;63fd
	ld (04000h),a		;63fe
	inc hl			;6401
	ld a,d			;6402
L_6403:
	dec a			;6403
	jp nz,L_6403		;6404
	neg		;6407
	ld h,e			;6409
	in a,(0a9h)		;640a
	and c			;640c
	jp z,L_63FD		;640d
L_6410:
	ld a,(hl)			;6410
	ld (04000h),a		;6411
	inc hl			;6414
	ld a,d			;6415
L_6416:
	dec a			;6416
	jp nz,L_6416		;6417
	neg		;641a
	cp 000h		;641c
	nop			;641e
	ld a,l			;641f
	or a			;6420
	jp nz,L_6410		;6421
L_6424:
	ld a,(hl)			;6424
	ld (04000h),a		;6425
	inc hl			;6428
	ld a,d			;6429
L_642A:
	dec a			;642a
	jp nz,L_642A		;642b
	neg		;642e
	inc ix		;6430
	in a,(0aah)		;6432
	inc a			;6434
	ld e,a			;6435
	ld a,(hl)			;6436
	ld (04000h),a		;6437
	inc hl			;643a
	ld a,d			;643b
L_643C:
	dec a			;643c
	jp nz,L_643C		;643d
	neg		;6440
	cp 000h		;6442
	ld a,e			;6444
	and 0f7h		;6445
	out (0aah),a		;6447
	ld a,(hl)			;6449
	ld (04000h),a		;644a
	inc hl			;644d
	ld a,d			;644e
L_644F:
	dec a			;644f
	jp nz,L_644F		;6450
	neg		;6453
	nop			;6455
	in a,(0a9h)		;6456
	inc a			;6458
	jp nz,L_66FE		;6459
	ld a,(hl)			;645c
	ld (04000h),a		;645d
	inc hl			;6460
	ld a,d			;6461
L_6462:
	dec a			;6462
	jp nz,L_6462		;6463
	neg		;6466
	neg		;6468
	ld a,0c0h		;646a
	cp h			;646c
	jp nz,L_6424		;646d
	jp L_66F7		;6470
L_6473:
	ld a,(hl)			;6473
	ld (04000h),a		;6474
	inc hl			;6477
	ld a,d			;6478
L_6479:
	dec a			;6479
	jp nz,L_6479		;647a
	ld a,i		;647d
	nop			;647f
	in a,(0a9h)		;6480
	and c			;6482
	jp nz,L_64AD		;6483
	ld a,(hl)			;6486
	ld (04000h),a		;6487
	inc hl			;648a
	ld a,d			;648b
L_648C:
	dec a			;648c
	jp nz,L_648C		;648d
	ld a,i		;6490
	cp 000h		;6492
	nop			;6494
	ld a,e			;6495
	cp h			;6496
	jp nz,L_6473		;6497
L_649A:
	ld a,(hl)			;649a
	ld (04000h),a		;649b
	inc hl			;649e
	ld a,d			;649f
L_64A0:
	dec a			;64a0
	jp nz,L_64A0		;64a1
	ld a,i		;64a4
	ld h,e			;64a6
	in a,(0a9h)		;64a7
	and c			;64a9
	jp z,L_649A		;64aa
L_64AD:
	ld a,(hl)			;64ad
	ld (04000h),a		;64ae
	inc hl			;64b1
	ld a,d			;64b2
L_64B3:
	dec a			;64b3
	jp nz,L_64B3		;64b4
	ld a,i		;64b7
	cp 000h		;64b9
	nop			;64bb
	ld a,l			;64bc
	or a			;64bd
	jp nz,L_64AD		;64be
L_64C1:
	ld a,(hl)			;64c1
	ld (04000h),a		;64c2
	inc hl			;64c5
	ld a,d			;64c6
L_64C7:
	dec a			;64c7
	jp nz,L_64C7		;64c8
	ld a,i		;64cb
	inc ix		;64cd
	in a,(0aah)		;64cf
	inc a			;64d1
	ld e,a			;64d2
	ld a,(hl)			;64d3
	ld (04000h),a		;64d4
	inc hl			;64d7
	ld a,d			;64d8
L_64D9:
	dec a			;64d9
	jp nz,L_64D9		;64da
	ld a,i		;64dd
	cp 000h		;64df
	ld a,e			;64e1
	and 0f7h		;64e2
	out (0aah),a		;64e4
	ld a,(hl)			;64e6
	ld (04000h),a		;64e7
	inc hl			;64ea
	ld a,d			;64eb
L_64EC:
	dec a			;64ec
	jp nz,L_64EC		;64ed
	ld a,i		;64f0
	nop			;64f2
	in a,(0a9h)		;64f3
	inc a			;64f5
	jp nz,L_66FE		;64f6
	ld a,(hl)			;64f9
	ld (04000h),a		;64fa
	inc hl			;64fd
	ld a,d			;64fe
L_64FF:
	dec a			;64ff
	jp nz,L_64FF		;6500
	ld a,i		;6503
	neg		;6505
	ld a,0c0h		;6507
	cp h			;6509
	jp nz,L_64C1		;650a
	jp L_66F7		;650d
L_6510:
	ld a,(hl)			;6510
	ld (04000h),a		;6511
	inc hl			;6514
	ld a,d			;6515
L_6516:
	dec a			;6516
	jp nz,L_6516		;6517
	inc ix		;651a
	nop			;651c
	in a,(0a9h)		;651d
	and c			;651f
	jp nz,L_654A		;6520
	ld a,(hl)			;6523
	ld (04000h),a		;6524
	inc hl			;6527
	ld a,d			;6528
L_6529:
	dec a			;6529
	jp nz,L_6529		;652a
	inc ix		;652d
	cp 000h		;652f
	nop			;6531
	ld a,e			;6532
	cp h			;6533
	jp nz,L_6510		;6534
L_6537:
	ld a,(hl)			;6537
	ld (04000h),a		;6538
	inc hl			;653b
	ld a,d			;653c
L_653D:
	dec a			;653d
	jp nz,L_653D		;653e
	inc ix		;6541
	ld h,e			;6543
	in a,(0a9h)		;6544
	and c			;6546
	jp z,L_6537		;6547
L_654A:
	ld a,(hl)			;654a
	ld (04000h),a		;654b
	inc hl			;654e
	ld a,d			;654f
L_6550:
	dec a			;6550
	jp nz,L_6550		;6551
	inc ix		;6554
	cp 000h		;6556
	nop			;6558
	ld a,l			;6559
	or a			;655a
	jp nz,L_654A		;655b
L_655E:
	ld a,(hl)			;655e
	ld (04000h),a		;655f
	inc hl			;6562
	ld a,d			;6563
L_6564:
	dec a			;6564
	jp nz,L_6564		;6565
	inc ix		;6568
	inc ix		;656a
	in a,(0aah)		;656c
	inc a			;656e
	ld e,a			;656f
	ld a,(hl)			;6570
	ld (04000h),a		;6571
	inc hl			;6574
	ld a,d			;6575
L_6576:
	dec a			;6576
	jp nz,L_6576		;6577
	inc ix		;657a
	cp 000h		;657c
	ld a,e			;657e
	and 0f7h		;657f
	out (0aah),a		;6581
	ld a,(hl)			;6583
	ld (04000h),a		;6584
	inc hl			;6587
	ld a,d			;6588
L_6589:
	dec a			;6589
	jp nz,L_6589		;658a
	inc ix		;658d
	nop			;658f
	in a,(0a9h)		;6590
	inc a			;6592
	jp nz,L_66FE		;6593
	ld a,(hl)			;6596
	ld (04000h),a		;6597
	inc hl			;659a
	ld a,d			;659b
L_659C:
	dec a			;659c
	jp nz,L_659C		;659d
	inc ix		;65a0
	neg		;65a2
	ld a,0c0h		;65a4
	cp h			;65a6
	jp nz,L_655E		;65a7
	jp L_66F7		;65aa
L_65AD:
	ld a,(hl)			;65ad
	ld (04000h),a		;65ae
	inc hl			;65b1
	ld a,d			;65b2
L_65B3:
	dec a			;65b3
	jp nz,L_65B3		;65b4
	cp 000h		;65b7
	nop			;65b9
	nop			;65ba
	in a,(0a9h)		;65bb
	and c			;65bd
	jp nz,L_65EA		;65be
	ld a,(hl)			;65c1
	ld (04000h),a		;65c2
	inc hl			;65c5
	ld a,d			;65c6
L_65C7:
	dec a			;65c7
	jp nz,L_65C7		;65c8
	cp 000h		;65cb
	nop			;65cd
	cp 000h		;65ce
	nop			;65d0
	ld a,e			;65d1
	cp h			;65d2
	jp nz,L_65AD		;65d3
L_65D6:
	ld a,(hl)			;65d6
	ld (04000h),a		;65d7
	inc hl			;65da
	ld a,d			;65db
L_65DC:
	dec a			;65dc
	jp nz,L_65DC		;65dd
	cp 000h		;65e0
	nop			;65e2
	ld h,e			;65e3
	in a,(0a9h)		;65e4
	and c			;65e6
	jp z,L_65D6		;65e7
L_65EA:
	ld a,(hl)			;65ea
	ld (04000h),a		;65eb
	inc hl			;65ee
	ld a,d			;65ef
L_65F0:
	dec a			;65f0
	jp nz,L_65F0		;65f1
	cp 000h		;65f4
	nop			;65f6
	cp 000h		;65f7
	nop			;65f9
	ld a,l			;65fa
	or a			;65fb
	jp nz,L_65EA		;65fc
L_65FF:
	ld a,(hl)			;65ff
	ld (04000h),a		;6600
	inc hl			;6603
	ld a,d			;6604
L_6605:
	dec a			;6605
	jp nz,L_6605		;6606
	cp 000h		;6609
	nop			;660b
	inc ix		;660c
	in a,(0aah)		;660e
	inc a			;6610
	ld e,a			;6611
	ld a,(hl)			;6612
	ld (04000h),a		;6613
	inc hl			;6616
	ld a,d			;6617
L_6618:
	dec a			;6618
	jp nz,L_6618		;6619
	cp 000h		;661c
	nop			;661e
	cp 000h		;661f
	ld a,e			;6621
	and 0f7h		;6622
	out (0aah),a		;6624
	ld a,(hl)			;6626
	ld (04000h),a		;6627
	inc hl			;662a
	ld a,d			;662b
L_662C:
	dec a			;662c
	jp nz,L_662C		;662d
	cp 000h		;6630
	nop			;6632
	nop			;6633
	in a,(0a9h)		;6634
	inc a			;6636
	jp nz,L_66FE		;6637
	ld a,(hl)			;663a
	ld (04000h),a		;663b
	inc hl			;663e
	ld a,d			;663f
L_6640:
	dec a			;6640
	jp nz,L_6640		;6641
	cp 000h		;6644
	nop			;6646
	neg		;6647
	ld a,0c0h		;6649
	cp h			;664b
	jp nz,L_65FF		;664c
	jp L_66F7		;664f
L_6652:
	ld a,(hl)			;6652
	ld (04000h),a		;6653
	inc hl			;6656
	ld a,d			;6657
L_6658:
	dec a			;6658
	jp nz,L_6658		;6659
	neg		;665c
	nop			;665e
	nop			;665f
	in a,(0a9h)		;6660
	and c			;6662
	jp nz,L_668F		;6663
	ld a,(hl)			;6666
	ld (04000h),a		;6667
	inc hl			;666a
	ld a,d			;666b
L_666C:
	dec a			;666c
	jp nz,L_666C		;666d
	neg		;6670
	nop			;6672
	cp 000h		;6673
	nop			;6675
	ld a,e			;6676
	cp h			;6677
	jp nz,L_6652		;6678
L_667B:
	ld a,(hl)			;667b
	ld (04000h),a		;667c
	inc hl			;667f
	ld a,d			;6680
L_6681:
	dec a			;6681
	jp nz,L_6681		;6682
	neg		;6685
	nop			;6687
	ld h,e			;6688
	in a,(0a9h)		;6689
	and c			;668b
	jp z,L_667B		;668c
L_668F:
	ld a,(hl)			;668f
	ld (04000h),a		;6690
	inc hl			;6693
	ld a,d			;6694
L_6695:
	dec a			;6695
	jp nz,L_6695		;6696
	neg		;6699
	nop			;669b
	cp 000h		;669c
	nop			;669e
	ld a,l			;669f
	or a			;66a0
	jp nz,L_668F		;66a1
L_66A4:
	ld a,(hl)			;66a4
	ld (04000h),a		;66a5
	inc hl			;66a8
	ld a,d			;66a9
L_66AA:
	dec a			;66aa
	jp nz,L_66AA		;66ab
	neg		;66ae
	nop			;66b0
	inc ix		;66b1
	in a,(0aah)		;66b3
	inc a			;66b5
	ld e,a			;66b6
	ld a,(hl)			;66b7
	ld (04000h),a		;66b8
	inc hl			;66bb
	ld a,d			;66bc
L_66BD:
	dec a			;66bd
	jp nz,L_66BD		;66be
	neg		;66c1
	nop			;66c3
	cp 000h		;66c4
	ld a,e			;66c6
	and 0f7h		;66c7
	out (0aah),a		;66c9
	ld a,(hl)			;66cb
	ld (04000h),a		;66cc
	inc hl			;66cf
	ld a,d			;66d0
L_66D1:
	dec a			;66d1
	jp nz,L_66D1		;66d2
	neg		;66d5
	nop			;66d7
	nop			;66d8
	in a,(0a9h)		;66d9
	inc a			;66db
	jp nz,L_66FE		;66dc
	ld a,(hl)			;66df
	ld (04000h),a		;66e0
	inc hl			;66e3
	ld a,d			;66e4
L_66E5:
	dec a			;66e5
	jp nz,L_66E5		;66e6
	neg		;66e9
	nop			;66eb
	neg		;66ec
	ld a,0c0h		;66ee
	cp h			;66f0
	jp nz,L_66A4		;66f1
	jp L_66F7		;66f4
L_66F7:
	call L_4A22		;66f7
	call cartucho_en_la_pagina_2		;66fa
	ret			;66fd
L_66FE:
	push af			;66fe
	call L_4A22		;66ff
	call cartucho_en_la_pagina_2		;6702
	pop af			;6705
	jp L_5EA9		;6706

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


L_6723:
	call L_5D45		;6723
	ret z			;6726
L_6727:
	call L_5D5D		;6727
	call L_5D81		;672a
	ret z			;672d
	call L_5D90		;672e
	ld hl,06709h		;6731
	call L_5D9A		;6734
	push bc			;6737
	push de			;6738
	call ram_en_la_pagina_2		;6739
	pop de			;673c
	pop bc			;673d
	ld hl,08000h		;673e
	jp (ix)		;6741
L_6743:
	ld a,(hl)			;6743
	ld (04000h),a		;6744
	inc hl			;6747
	ld a,d			;6748
L_6749:
	dec a			;6749
	jp nz,L_6749		;674a
	nop			;674d
	in a,(0a9h)		;674e
	and c			;6750
	jp nz,L_6769		;6751
	ld a,(hl)			;6754
	ld (04000h),a		;6755
	inc hl			;6758
	ld a,d			;6759
L_675A:
	dec a			;675a
	jp nz,L_675A		;675b
	neg		;675e
	ld a,0c0h		;6760
	cp h			;6762
	jp nz,L_6743		;6763
	jp L_6EAD		;6766
L_6769:
	ld a,(hl)			;6769
	ld (04000h),a		;676a
	inc hl			;676d
	ld a,d			;676e
L_676F:
	dec a			;676f
	jp nz,L_676F		;6770
	cp 000h		;6773
	nop			;6775
	ld a,l			;6776
	or a			;6777
	jp nz,L_6769		;6778
L_677B:
	ld a,(hl)			;677b
	ld (04000h),a		;677c
	inc hl			;677f
	ld a,d			;6780
L_6781:
	dec a			;6781
	jp nz,L_6781		;6782
	inc ix		;6785
	in a,(0aah)		;6787
	inc a			;6789
	ld e,a			;678a
	ld a,(hl)			;678b
	ld (04000h),a		;678c
	inc hl			;678f
	ld a,d			;6790
L_6791:
	dec a			;6791
	jp nz,L_6791		;6792
	cp 000h		;6795
	ld a,e			;6797
	and 0f7h		;6798
	out (0aah),a		;679a
	ld a,(hl)			;679c
	ld (04000h),a		;679d
	inc hl			;67a0
	ld a,d			;67a1
L_67A2:
	dec a			;67a2
	jp nz,L_67A2		;67a3
	nop			;67a6
	in a,(0a9h)		;67a7
	inc a			;67a9
	jp nz,L_6EA2		;67aa
	ld a,(hl)			;67ad
	ld (04000h),a		;67ae
	inc hl			;67b1
	ld a,d			;67b2
L_67B3:
	dec a			;67b3
	jp nz,L_67B3		;67b4
	neg		;67b7
	ld a,0c0h		;67b9
	cp h			;67bb
	jp nz,L_677B		;67bc
	jp L_6E9B		;67bf
L_67C2:
	dec d			;67c2
L_67C3:
	ld a,(hl)			;67c3
	ld (04000h),a		;67c4
	inc hl			;67c7
	ld a,d			;67c8
L_67C9:
	dec a			;67c9
	jp nz,L_67C9		;67ca
	add ix,ix		;67cd
	nop			;67cf
	in a,(0a9h)		;67d0
	and c			;67d2
	jp nz,L_67ED		;67d3
	ld a,(hl)			;67d6
	ld (04000h),a		;67d7
	inc hl			;67da
	ld a,d			;67db
L_67DC:
	dec a			;67dc
	jp nz,L_67DC		;67dd
	add ix,ix		;67e0
	neg		;67e2
	ld a,0c0h		;67e4
	cp h			;67e6
	jp nz,L_67C3		;67e7
	jp L_6EAD		;67ea
L_67ED:
	ld a,(hl)			;67ed
	ld (04000h),a		;67ee
	inc hl			;67f1
	ld a,d			;67f2
L_67F3:
	dec a			;67f3
	jp nz,L_67F3		;67f4
	add ix,ix		;67f7
	cp 000h		;67f9
	nop			;67fb
	ld a,l			;67fc
	or a			;67fd
	jp nz,L_67ED		;67fe
L_6801:
	ld a,(hl)			;6801
	ld (04000h),a		;6802
	inc hl			;6805
	ld a,d			;6806
L_6807:
	dec a			;6807
	jp nz,L_6807		;6808
	add ix,ix		;680b
	inc ix		;680d
	in a,(0aah)		;680f
	inc a			;6811
	ld e,a			;6812
	ld a,(hl)			;6813
	ld (04000h),a		;6814
	inc hl			;6817
	ld a,d			;6818
L_6819:
	dec a			;6819
	jp nz,L_6819		;681a
	add ix,ix		;681d
	cp 000h		;681f
	ld a,e			;6821
	and 0f7h		;6822
	out (0aah),a		;6824
	ld a,(hl)			;6826
	ld (04000h),a		;6827
	inc hl			;682a
	ld a,d			;682b
L_682C:
	dec a			;682c
	jp nz,L_682C		;682d
	add ix,ix		;6830
	nop			;6832
	in a,(0a9h)		;6833
	inc a			;6835
	jp nz,L_6EA2		;6836
	ld a,(hl)			;6839
	ld (04000h),a		;683a
	inc hl			;683d
	ld a,d			;683e
L_683F:
	dec a			;683f
	jp nz,L_683F		;6840
	add ix,ix		;6843
	neg		;6845
	ld a,0c0h		;6847
	cp h			;6849
	jp nz,L_6801		;684a
	jp L_6E9B		;684d
L_6850:
	dec d			;6850
L_6851:
	ld a,(hl)			;6851
	ld (04000h),a		;6852
	inc hl			;6855
	ld a,d			;6856
L_6857:
	dec a			;6857
	jp nz,L_6857		;6858
	neg		;685b
	neg		;685d
	nop			;685f
	in a,(0a9h)		;6860
	and c			;6862
	jp nz,L_687F		;6863
	ld a,(hl)			;6866
	ld (04000h),a		;6867
	inc hl			;686a
	ld a,d			;686b
L_686C:
	dec a			;686c
	jp nz,L_686C		;686d
	neg		;6870
	neg		;6872
	neg		;6874
	ld a,0c0h		;6876
	cp h			;6878
	jp nz,L_6851		;6879
	jp L_6EAD		;687c
L_687F:
	ld a,(hl)			;687f
	ld (04000h),a		;6880
	inc hl			;6883
	ld a,d			;6884
L_6885:
	dec a			;6885
	jp nz,L_6885		;6886
	neg		;6889
	neg		;688b
	cp 000h		;688d
	nop			;688f
	ld a,l			;6890
	or a			;6891
	jp nz,L_687F		;6892
L_6895:
	ld a,(hl)			;6895
	ld (04000h),a		;6896
	inc hl			;6899
	ld a,d			;689a
L_689B:
	dec a			;689b
	jp nz,L_689B		;689c
	neg		;689f
	neg		;68a1
	inc ix		;68a3
	in a,(0aah)		;68a5
	inc a			;68a7
	ld e,a			;68a8
	ld a,(hl)			;68a9
	ld (04000h),a		;68aa
	inc hl			;68ad
	ld a,d			;68ae
L_68AF:
	dec a			;68af
	jp nz,L_68AF		;68b0
	neg		;68b3
	neg		;68b5
	cp 000h		;68b7
	ld a,e			;68b9
	and 0f7h		;68ba
	out (0aah),a		;68bc
	ld a,(hl)			;68be
	ld (04000h),a		;68bf
	inc hl			;68c2
	ld a,d			;68c3
L_68C4:
	dec a			;68c4
	jp nz,L_68C4		;68c5
	neg		;68c8
	neg		;68ca
	nop			;68cc
	in a,(0a9h)		;68cd
	inc a			;68cf
	jp nz,L_6EA2		;68d0
	ld a,(hl)			;68d3
	ld (04000h),a		;68d4
	inc hl			;68d7
	ld a,d			;68d8
L_68D9:
	dec a			;68d9
	jp nz,L_68D9		;68da
	neg		;68dd
	neg		;68df
	neg		;68e1
	ld a,0c0h		;68e3
	cp h			;68e5
	jp nz,L_6895		;68e6
	jp L_6E9B		;68e9
L_68EC:
	dec d			;68ec
L_68ED:
	ld a,(hl)			;68ed
	ld (04000h),a		;68ee
	inc hl			;68f1
	ld a,d			;68f2
L_68F3:
	dec a			;68f3
	jp nz,L_68F3		;68f4
	inc ix		;68f7
	cp 000h		;68f9
	nop			;68fb
	in a,(0a9h)		;68fc
	and c			;68fe
	jp nz,L_691B		;68ff
	ld a,(hl)			;6902
	ld (04000h),a		;6903
	inc hl			;6906
	ld a,d			;6907
L_6908:
	dec a			;6908
	jp nz,L_6908		;6909
	inc ix		;690c
	cp 000h		;690e
	neg		;6910
	ld a,0c0h		;6912
	cp h			;6914
	jp nz,L_68ED		;6915
	jp L_6EAD		;6918
L_691B:
	ld a,(hl)			;691b
	ld (04000h),a		;691c
	inc hl			;691f
	ld a,d			;6920
L_6921:
	dec a			;6921
	jp nz,L_6921		;6922
	inc ix		;6925
	cp 000h		;6927
	cp 000h		;6929
	nop			;692b
	ld a,l			;692c
	or a			;692d
	jp nz,L_691B		;692e
L_6931:
	ld a,(hl)			;6931
	ld (04000h),a		;6932
	inc hl			;6935
	ld a,d			;6936
L_6937:
	dec a			;6937
	jp nz,L_6937		;6938
	inc ix		;693b
	cp 000h		;693d
	inc ix		;693f
	in a,(0aah)		;6941
	inc a			;6943
	ld e,a			;6944
	ld a,(hl)			;6945
	ld (04000h),a		;6946
	inc hl			;6949
	ld a,d			;694a
L_694B:
	dec a			;694b
	jp nz,L_694B		;694c
	inc ix		;694f
	cp 000h		;6951
	cp 000h		;6953
	ld a,e			;6955
	and 0f7h		;6956
	out (0aah),a		;6958
	ld a,(hl)			;695a
	ld (04000h),a		;695b
	inc hl			;695e
	ld a,d			;695f
L_6960:
	dec a			;6960
	jp nz,L_6960		;6961
	inc ix		;6964
	cp 000h		;6966
	nop			;6968
	in a,(0a9h)		;6969
	inc a			;696b
	jp nz,L_6EA2		;696c
	ld a,(hl)			;696f
	ld (04000h),a		;6970
	inc hl			;6973
	ld a,d			;6974
L_6975:
	dec a			;6975
	jp nz,L_6975		;6976
	inc ix		;6979
	cp 000h		;697b
	neg		;697d
	ld a,0c0h		;697f
	cp h			;6981
	jp nz,L_6931		;6982
	jp L_6E9B		;6985
L_6988:
	ld a,(hl)			;6988
	ld (04000h),a		;6989
	inc hl			;698c
	ld a,d			;698d
L_698E:
	dec a			;698e
	jp nz,L_698E		;698f
	nop			;6992
	nop			;6993
	in a,(0a9h)		;6994
	and c			;6996
	jp nz,L_69B0		;6997
	ld a,(hl)			;699a
	ld (04000h),a		;699b
	inc hl			;699e
	ld a,d			;699f
L_69A0:
	dec a			;69a0
	jp nz,L_69A0		;69a1
	nop			;69a4
	neg		;69a5
	ld a,0c0h		;69a7
	cp h			;69a9
	jp nz,L_6988		;69aa
	jp L_6EAD		;69ad
L_69B0:
	ld a,(hl)			;69b0
	ld (04000h),a		;69b1
	inc hl			;69b4
	ld a,d			;69b5
L_69B6:
	dec a			;69b6
	jp nz,L_69B6		;69b7
	nop			;69ba
	cp 000h		;69bb
	nop			;69bd
	ld a,l			;69be
	or a			;69bf
	jp nz,L_69B0		;69c0
L_69C3:
	ld a,(hl)			;69c3
	ld (04000h),a		;69c4
	inc hl			;69c7
	ld a,d			;69c8
L_69C9:
	dec a			;69c9
	jp nz,L_69C9		;69ca
	nop			;69cd
	inc ix		;69ce
	in a,(0aah)		;69d0
	inc a			;69d2
	ld e,a			;69d3
	ld a,(hl)			;69d4
	ld (04000h),a		;69d5
	inc hl			;69d8
	ld a,d			;69d9
L_69DA:
	dec a			;69da
	jp nz,L_69DA		;69db
	nop			;69de
	cp 000h		;69df
	ld a,e			;69e1
	and 0f7h		;69e2
	out (0aah),a		;69e4
	ld a,(hl)			;69e6
	ld (04000h),a		;69e7
	inc hl			;69ea
	ld a,d			;69eb
L_69EC:
	dec a			;69ec
	jp nz,L_69EC		;69ed
	nop			;69f0
	nop			;69f1
	in a,(0a9h)		;69f2
	inc a			;69f4
	jp nz,L_6EA2		;69f5
	ld a,(hl)			;69f8
	ld (04000h),a		;69f9
	inc hl			;69fc
	ld a,d			;69fd
L_69FE:
	dec a			;69fe
	jp nz,L_69FE		;69ff
	nop			;6a02
	neg		;6a03
	ld a,0c0h		;6a05
	cp h			;6a07
	jp nz,L_69C3		;6a08
	jp L_6E9B		;6a0b
L_6A0E:
	dec d			;6a0e
L_6A0F:
	ld a,(hl)			;6a0f
	ld (04000h),a		;6a10
	inc hl			;6a13
	ld a,d			;6a14
L_6A15:
	dec a			;6a15
	jp nz,L_6A15		;6a16
	add a,(ix+000h)		;6a19
	nop			;6a1c
	in a,(0a9h)		;6a1d
	and c			;6a1f
	jp nz,L_6A3B		;6a20
	ld a,(hl)			;6a23
	ld (04000h),a		;6a24
	inc hl			;6a27
	ld a,d			;6a28
L_6A29:
	dec a			;6a29
	jp nz,L_6A29		;6a2a
	add a,(ix+000h)		;6a2d
	neg		;6a30
	ld a,0c0h		;6a32
	cp h			;6a34
	jp nz,L_6A0F		;6a35
	jp L_6EAD		;6a38
L_6A3B:
	ld a,(hl)			;6a3b
	ld (04000h),a		;6a3c
	inc hl			;6a3f
	ld a,d			;6a40
L_6A41:
	dec a			;6a41
	jp nz,L_6A41		;6a42
	add a,(ix+000h)		;6a45
	cp 000h		;6a48
	nop			;6a4a
	ld a,l			;6a4b
	or a			;6a4c
	jp nz,L_6A3B		;6a4d
L_6A50:
	ld a,(hl)			;6a50
	ld (04000h),a		;6a51
	inc hl			;6a54
	ld a,d			;6a55
L_6A56:
	dec a			;6a56
	jp nz,L_6A56		;6a57
	add a,(ix+000h)		;6a5a
	inc ix		;6a5d
	in a,(0aah)		;6a5f
	inc a			;6a61
	ld e,a			;6a62
	ld a,(hl)			;6a63
	ld (04000h),a		;6a64
	inc hl			;6a67
	ld a,d			;6a68
L_6A69:
	dec a			;6a69
	jp nz,L_6A69		;6a6a
	add a,(ix+000h)		;6a6d
	cp 000h		;6a70
	ld a,e			;6a72
	and 0f7h		;6a73
	out (0aah),a		;6a75
	ld a,(hl)			;6a77
	ld (04000h),a		;6a78
	inc hl			;6a7b
	ld a,d			;6a7c
L_6A7D:
	dec a			;6a7d
	jp nz,L_6A7D		;6a7e
	add a,(ix+000h)		;6a81
	nop			;6a84
	in a,(0a9h)		;6a85
	inc a			;6a87
	jp nz,L_6EA2		;6a88
	ld a,(hl)			;6a8b
	ld (04000h),a		;6a8c
	inc hl			;6a8f
	ld a,d			;6a90
L_6A91:
	dec a			;6a91
	jp nz,L_6A91		;6a92
	add a,(ix+000h)		;6a95
	neg		;6a98
	ld a,0c0h		;6a9a
	cp h			;6a9c
	jp nz,L_6A50		;6a9d
	jp L_6E9B		;6aa0
L_6AA3:
	dec d			;6aa3
L_6AA4:
	ld a,(hl)			;6aa4
	ld (04000h),a		;6aa5
	inc hl			;6aa8
	ld a,d			;6aa9
L_6AAA:
	dec a			;6aaa
	jp nz,L_6AAA		;6aab
	inc ix		;6aae
	inc ix		;6ab0
	nop			;6ab2
	in a,(0a9h)		;6ab3
	and c			;6ab5
	jp nz,L_6AD2		;6ab6
	ld a,(hl)			;6ab9
	ld (04000h),a		;6aba
	inc hl			;6abd
	ld a,d			;6abe
L_6ABF:
	dec a			;6abf
	jp nz,L_6ABF		;6ac0
	inc ix		;6ac3
	inc ix		;6ac5
	neg		;6ac7
	ld a,0c0h		;6ac9
	cp h			;6acb
	jp nz,L_6AA4		;6acc
	jp L_6EAD		;6acf
L_6AD2:
	ld a,(hl)			;6ad2
	ld (04000h),a		;6ad3
	inc hl			;6ad6
	ld a,d			;6ad7
L_6AD8:
	dec a			;6ad8
	jp nz,L_6AD8		;6ad9
	inc ix		;6adc
	inc ix		;6ade
	cp 000h		;6ae0
	nop			;6ae2
	ld a,l			;6ae3
	or a			;6ae4
	jp nz,L_6AD2		;6ae5
L_6AE8:
	ld a,(hl)			;6ae8
	ld (04000h),a		;6ae9
	inc hl			;6aec
	ld a,d			;6aed
L_6AEE:
	dec a			;6aee
	jp nz,L_6AEE		;6aef
	inc ix		;6af2
	inc ix		;6af4
	inc ix		;6af6
	in a,(0aah)		;6af8
	inc a			;6afa
	ld e,a			;6afb
	ld a,(hl)			;6afc
	ld (04000h),a		;6afd
	inc hl			;6b00
	ld a,d			;6b01
L_6B02:
	dec a			;6b02
	jp nz,L_6B02		;6b03
	inc ix		;6b06
	inc ix		;6b08
	cp 000h		;6b0a
	ld a,e			;6b0c
	and 0f7h		;6b0d
	out (0aah),a		;6b0f
	ld a,(hl)			;6b11
	ld (04000h),a		;6b12
	inc hl			;6b15
	ld a,d			;6b16
L_6B17:
	dec a			;6b17
	jp nz,L_6B17		;6b18
	inc ix		;6b1b
	inc ix		;6b1d
	nop			;6b1f
	in a,(0a9h)		;6b20
	inc a			;6b22
	jp nz,L_6EA2		;6b23
	ld a,(hl)			;6b26
	ld (04000h),a		;6b27
	inc hl			;6b2a
	ld a,d			;6b2b
L_6B2C:
	dec a			;6b2c
	jp nz,L_6B2C		;6b2d
	inc ix		;6b30
	inc ix		;6b32
	neg		;6b34
	ld a,0c0h		;6b36
	cp h			;6b38
	jp nz,L_6AE8		;6b39
	jp L_6E9B		;6b3c
L_6B3F:
	ld a,(hl)			;6b3f
	ld (04000h),a		;6b40
	inc hl			;6b43
	ld a,d			;6b44
L_6B45:
	dec a			;6b45
	jp nz,L_6B45		;6b46
	cp 000h		;6b49
	nop			;6b4b
	in a,(0a9h)		;6b4c
	and c			;6b4e
	jp nz,L_6B69		;6b4f
	ld a,(hl)			;6b52
	ld (04000h),a		;6b53
	inc hl			;6b56
	ld a,d			;6b57
L_6B58:
	dec a			;6b58
	jp nz,L_6B58		;6b59
	cp 000h		;6b5c
	neg		;6b5e
	ld a,0c0h		;6b60
	cp h			;6b62
	jp nz,L_6B3F		;6b63
	jp L_6EAD		;6b66
L_6B69:
	ld a,(hl)			;6b69
	ld (04000h),a		;6b6a
	inc hl			;6b6d
	ld a,d			;6b6e
L_6B6F:
	dec a			;6b6f
	jp nz,L_6B6F		;6b70
	cp 000h		;6b73
	cp 000h		;6b75
	nop			;6b77
	ld a,l			;6b78
	or a			;6b79
	jp nz,L_6B69		;6b7a
L_6B7D:
	ld a,(hl)			;6b7d
	ld (04000h),a		;6b7e
	inc hl			;6b81
	ld a,d			;6b82
L_6B83:
	dec a			;6b83
	jp nz,L_6B83		;6b84
	cp 000h		;6b87
	inc ix		;6b89
	in a,(0aah)		;6b8b
	inc a			;6b8d
	ld e,a			;6b8e
	ld a,(hl)			;6b8f
	ld (04000h),a		;6b90
	inc hl			;6b93
	ld a,d			;6b94
L_6B95:
	dec a			;6b95
	jp nz,L_6B95		;6b96
	cp 000h		;6b99
	cp 000h		;6b9b
	ld a,e			;6b9d
	and 0f7h		;6b9e
	out (0aah),a		;6ba0
	ld a,(hl)			;6ba2
	ld (04000h),a		;6ba3
	inc hl			;6ba6
	ld a,d			;6ba7
L_6BA8:
	dec a			;6ba8
	jp nz,L_6BA8		;6ba9
	cp 000h		;6bac
	nop			;6bae
	in a,(0a9h)		;6baf
	inc a			;6bb1
	jp nz,L_6EA2		;6bb2
	ld a,(hl)			;6bb5
	ld (04000h),a		;6bb6
	inc hl			;6bb9
	ld a,d			;6bba
L_6BBB:
	dec a			;6bbb
	jp nz,L_6BBB		;6bbc
	cp 000h		;6bbf
	neg		;6bc1
	ld a,0c0h		;6bc3
	cp h			;6bc5
	jp nz,L_6B7D		;6bc6
	jp L_6E9B		;6bc9
L_6BCC:
	ld a,(hl)			;6bcc
	ld (04000h),a		;6bcd
	inc hl			;6bd0
	ld a,d			;6bd1
L_6BD2:
	dec a			;6bd2
	jp nz,L_6BD2		;6bd3
	neg		;6bd6
	nop			;6bd8
	in a,(0a9h)		;6bd9
	and c			;6bdb
	jp nz,L_6BF6		;6bdc
	ld a,(hl)			;6bdf
	ld (04000h),a		;6be0
	inc hl			;6be3
	ld a,d			;6be4
L_6BE5:
	dec a			;6be5
	jp nz,L_6BE5		;6be6
	neg		;6be9
	neg		;6beb
	ld a,0c0h		;6bed
	cp h			;6bef
	jp nz,L_6BCC		;6bf0
	jp L_6EAD		;6bf3
L_6BF6:
	ld a,(hl)			;6bf6
	ld (04000h),a		;6bf7
	inc hl			;6bfa
	ld a,d			;6bfb
L_6BFC:
	dec a			;6bfc
	jp nz,L_6BFC		;6bfd
	neg		;6c00
	cp 000h		;6c02
	nop			;6c04
	ld a,l			;6c05
	or a			;6c06
	jp nz,L_6BF6		;6c07
L_6C0A:
	ld a,(hl)			;6c0a
	ld (04000h),a		;6c0b
	inc hl			;6c0e
	ld a,d			;6c0f
L_6C10:
	dec a			;6c10
	jp nz,L_6C10		;6c11
	neg		;6c14
	inc ix		;6c16
	in a,(0aah)		;6c18
	inc a			;6c1a
	ld e,a			;6c1b
	ld a,(hl)			;6c1c
	ld (04000h),a		;6c1d
	inc hl			;6c20
	ld a,d			;6c21
L_6C22:
	dec a			;6c22
	jp nz,L_6C22		;6c23
	neg		;6c26
	cp 000h		;6c28
	ld a,e			;6c2a
	and 0f7h		;6c2b
	out (0aah),a		;6c2d
	ld a,(hl)			;6c2f
	ld (04000h),a		;6c30
	inc hl			;6c33
	ld a,d			;6c34
L_6C35:
	dec a			;6c35
	jp nz,L_6C35		;6c36
	neg		;6c39
	nop			;6c3b
	in a,(0a9h)		;6c3c
	inc a			;6c3e
	jp nz,L_6EA2		;6c3f
	ld a,(hl)			;6c42
	ld (04000h),a		;6c43
	inc hl			;6c46
	ld a,d			;6c47
L_6C48:
	dec a			;6c48
	jp nz,L_6C48		;6c49
	neg		;6c4c
	neg		;6c4e
	ld a,0c0h		;6c50
	cp h			;6c52
	jp nz,L_6C0A		;6c53
	jp L_6E9B		;6c56
L_6C59:
	ld a,(hl)			;6c59
	ld (04000h),a		;6c5a
	inc hl			;6c5d
	ld a,d			;6c5e
L_6C5F:
	dec a			;6c5f
	jp nz,L_6C5F		;6c60
	ld a,i		;6c63
	nop			;6c65
	in a,(0a9h)		;6c66
	and c			;6c68
	jp nz,L_6C83		;6c69
	ld a,(hl)			;6c6c
	ld (04000h),a		;6c6d
	inc hl			;6c70
	ld a,d			;6c71
L_6C72:
	dec a			;6c72
	jp nz,L_6C72		;6c73
	ld a,i		;6c76
	neg		;6c78
	ld a,0c0h		;6c7a
	cp h			;6c7c
	jp nz,L_6C59		;6c7d
	jp L_6EAD		;6c80
L_6C83:
	ld a,(hl)			;6c83
	ld (04000h),a		;6c84
	inc hl			;6c87
	ld a,d			;6c88
L_6C89:
	dec a			;6c89
	jp nz,L_6C89		;6c8a
	ld a,i		;6c8d
	cp 000h		;6c8f
	nop			;6c91
	ld a,l			;6c92
	or a			;6c93
	jp nz,L_6C83		;6c94
L_6C97:
	ld a,(hl)			;6c97
	ld (04000h),a		;6c98
	inc hl			;6c9b
	ld a,d			;6c9c
L_6C9D:
	dec a			;6c9d
	jp nz,L_6C9D		;6c9e
	ld a,i		;6ca1
	inc ix		;6ca3
	in a,(0aah)		;6ca5
	inc a			;6ca7
	ld e,a			;6ca8
	ld a,(hl)			;6ca9
	ld (04000h),a		;6caa
	inc hl			;6cad
	ld a,d			;6cae
L_6CAF:
	dec a			;6caf
	jp nz,L_6CAF		;6cb0
	ld a,i		;6cb3
	cp 000h		;6cb5
	ld a,e			;6cb7
	and 0f7h		;6cb8
	out (0aah),a		;6cba
	ld a,(hl)			;6cbc
	ld (04000h),a		;6cbd
	inc hl			;6cc0
	ld a,d			;6cc1
L_6CC2:
	dec a			;6cc2
	jp nz,L_6CC2		;6cc3
	ld a,i		;6cc6
	nop			;6cc8
	in a,(0a9h)		;6cc9
	inc a			;6ccb
	jp nz,L_6EA2		;6ccc
	ld a,(hl)			;6ccf
	ld (04000h),a		;6cd0
	inc hl			;6cd3
	ld a,d			;6cd4
L_6CD5:
	dec a			;6cd5
	jp nz,L_6CD5		;6cd6
	ld a,i		;6cd9
	neg		;6cdb
	ld a,0c0h		;6cdd
	cp h			;6cdf
	jp nz,L_6C97		;6ce0
	jp L_6E9B		;6ce3
L_6CE6:
	ld a,(hl)			;6ce6
	ld (04000h),a		;6ce7
	inc hl			;6cea
	ld a,d			;6ceb
L_6CEC:
	dec a			;6cec
	jp nz,L_6CEC		;6ced
	inc ix		;6cf0
	nop			;6cf2
	in a,(0a9h)		;6cf3
	and c			;6cf5
	jp nz,L_6D10		;6cf6
	ld a,(hl)			;6cf9
	ld (04000h),a		;6cfa
	inc hl			;6cfd
	ld a,d			;6cfe
L_6CFF:
	dec a			;6cff
	jp nz,L_6CFF		;6d00
	inc ix		;6d03
	neg		;6d05
	ld a,0c0h		;6d07
	cp h			;6d09
	jp nz,L_6CE6		;6d0a
	jp L_6EAD		;6d0d
L_6D10:
	ld a,(hl)			;6d10
	ld (04000h),a		;6d11
	inc hl			;6d14
	ld a,d			;6d15
L_6D16:
	dec a			;6d16
	jp nz,L_6D16		;6d17
	inc ix		;6d1a
	cp 000h		;6d1c
	nop			;6d1e
	ld a,l			;6d1f
	or a			;6d20
	jp nz,L_6D10		;6d21
L_6D24:
	ld a,(hl)			;6d24
	ld (04000h),a		;6d25
	inc hl			;6d28
	ld a,d			;6d29
L_6D2A:
	dec a			;6d2a
	jp nz,L_6D2A		;6d2b
	inc ix		;6d2e
	inc ix		;6d30
	in a,(0aah)		;6d32
	inc a			;6d34
	ld e,a			;6d35
	ld a,(hl)			;6d36
	ld (04000h),a		;6d37
	inc hl			;6d3a
	ld a,d			;6d3b
L_6D3C:
	dec a			;6d3c
	jp nz,L_6D3C		;6d3d
	inc ix		;6d40
	cp 000h		;6d42
	ld a,e			;6d44
	and 0f7h		;6d45
	out (0aah),a		;6d47
	ld a,(hl)			;6d49
	ld (04000h),a		;6d4a
	inc hl			;6d4d
	ld a,d			;6d4e
L_6D4F:
	dec a			;6d4f
	jp nz,L_6D4F		;6d50
	inc ix		;6d53
	nop			;6d55
	in a,(0a9h)		;6d56
	inc a			;6d58
	jp nz,L_6EA2		;6d59
	ld a,(hl)			;6d5c
	ld (04000h),a		;6d5d
	inc hl			;6d60
	ld a,d			;6d61
L_6D62:
	dec a			;6d62
	jp nz,L_6D62		;6d63
	inc ix		;6d66
	neg		;6d68
	ld a,0c0h		;6d6a
	cp h			;6d6c
	jp nz,L_6D24		;6d6d
	jp L_6E9B		;6d70
L_6D73:
	ld a,(hl)			;6d73
	ld (04000h),a		;6d74
	inc hl			;6d77
	ld a,d			;6d78
L_6D79:
	dec a			;6d79
	jp nz,L_6D79		;6d7a
	cp 000h		;6d7d
	nop			;6d7f
	nop			;6d80
	in a,(0a9h)		;6d81
	and c			;6d83
	jp nz,L_6D9F		;6d84
	ld a,(hl)			;6d87
	ld (04000h),a		;6d88
	inc hl			;6d8b
	ld a,d			;6d8c
L_6D8D:
	dec a			;6d8d
	jp nz,L_6D8D		;6d8e
	cp 000h		;6d91
	nop			;6d93
	neg		;6d94
	ld a,0c0h		;6d96
	cp h			;6d98
	jp nz,L_6D73		;6d99
	jp L_6EAD		;6d9c
L_6D9F:
	ld a,(hl)			;6d9f
	ld (04000h),a		;6da0
	inc hl			;6da3
	ld a,d			;6da4
L_6DA5:
	dec a			;6da5
	jp nz,L_6DA5		;6da6
	cp 000h		;6da9
	nop			;6dab
	cp 000h		;6dac
	nop			;6dae
	ld a,l			;6daf
	or a			;6db0
	jp nz,L_6D9F		;6db1
L_6DB4:
	ld a,(hl)			;6db4
	ld (04000h),a		;6db5
	inc hl			;6db8
	ld a,d			;6db9
L_6DBA:
	dec a			;6dba
	jp nz,L_6DBA		;6dbb
	cp 000h		;6dbe
	nop			;6dc0
	inc ix		;6dc1
	in a,(0aah)		;6dc3
	inc a			;6dc5
	ld e,a			;6dc6
	ld a,(hl)			;6dc7
	ld (04000h),a		;6dc8
	inc hl			;6dcb
	ld a,d			;6dcc
L_6DCD:
	dec a			;6dcd
	jp nz,L_6DCD		;6dce
	cp 000h		;6dd1
	nop			;6dd3
	cp 000h		;6dd4
	ld a,e			;6dd6
	and 0f7h		;6dd7
	out (0aah),a		;6dd9
	ld a,(hl)			;6ddb
	ld (04000h),a		;6ddc
	inc hl			;6ddf
	ld a,d			;6de0
L_6DE1:
	dec a			;6de1
	jp nz,L_6DE1		;6de2
	cp 000h		;6de5
	nop			;6de7
	nop			;6de8
	in a,(0a9h)		;6de9
	inc a			;6deb
	jp nz,L_6EA2		;6dec
	ld a,(hl)			;6def
	ld (04000h),a		;6df0
	inc hl			;6df3
	ld a,d			;6df4
L_6DF5:
	dec a			;6df5
	jp nz,L_6DF5		;6df6
	cp 000h		;6df9
	nop			;6dfb
	neg		;6dfc
	ld a,0c0h		;6dfe
	cp h			;6e00
	jp nz,L_6DB4		;6e01
	jp L_6E9B		;6e04
L_6E07:
	ld a,(hl)			;6e07
	ld (04000h),a		;6e08
	inc hl			;6e0b
	ld a,d			;6e0c
L_6E0D:
	dec a			;6e0d
	jp nz,L_6E0D		;6e0e
	neg		;6e11
	nop			;6e13
	nop			;6e14
	in a,(0a9h)		;6e15
	and c			;6e17
	jp nz,L_6E33		;6e18
	ld a,(hl)			;6e1b
	ld (04000h),a		;6e1c
	inc hl			;6e1f
	ld a,d			;6e20
L_6E21:
	dec a			;6e21
	jp nz,L_6E21		;6e22
	neg		;6e25
	nop			;6e27
	neg		;6e28
	ld a,0c0h		;6e2a
	cp h			;6e2c
	jp nz,L_6E07		;6e2d
	jp L_6EAD		;6e30
L_6E33:
	ld a,(hl)			;6e33
	ld (04000h),a		;6e34
	inc hl			;6e37
	ld a,d			;6e38
L_6E39:
	dec a			;6e39
	jp nz,L_6E39		;6e3a
	neg		;6e3d
	nop			;6e3f
	cp 000h		;6e40
	nop			;6e42
	ld a,l			;6e43
	or a			;6e44
	jp nz,L_6E33		;6e45
L_6E48:
	ld a,(hl)			;6e48
	ld (04000h),a		;6e49
	inc hl			;6e4c
	ld a,d			;6e4d
L_6E4E:
	dec a			;6e4e
	jp nz,L_6E4E		;6e4f
	neg		;6e52
	nop			;6e54
	inc ix		;6e55
	in a,(0aah)		;6e57
	inc a			;6e59
	ld e,a			;6e5a
	ld a,(hl)			;6e5b
	ld (04000h),a		;6e5c
	inc hl			;6e5f
	ld a,d			;6e60
L_6E61:
	dec a			;6e61
	jp nz,L_6E61		;6e62
	neg		;6e65
	nop			;6e67
	cp 000h		;6e68
	ld a,e			;6e6a
	and 0f7h		;6e6b
	out (0aah),a		;6e6d
	ld a,(hl)			;6e6f
	ld (04000h),a		;6e70
	inc hl			;6e73
	ld a,d			;6e74
L_6E75:
	dec a			;6e75
	jp nz,L_6E75		;6e76
	neg		;6e79
	nop			;6e7b
	nop			;6e7c
	in a,(0a9h)		;6e7d
	inc a			;6e7f
	jp nz,L_6EA2		;6e80
	ld a,(hl)			;6e83
	ld (04000h),a		;6e84
	inc hl			;6e87
	ld a,d			;6e88
L_6E89:
	dec a			;6e89
	jp nz,L_6E89		;6e8a
	neg		;6e8d
	nop			;6e8f
	neg		;6e90
	ld a,0c0h		;6e92
	cp h			;6e94
	jp nz,L_6E48		;6e95
	jp L_6E9B		;6e98
L_6E9B:
	call L_4A22		;6e9b
	call cartucho_en_la_pagina_2		;6e9e
	ret			;6ea1
L_6EA2:
	push af			;6ea2
	call L_4A22		;6ea3
	call cartucho_en_la_pagina_2		;6ea6
	pop af			;6ea9
	jp L_6727		;6eaa
L_6EAD:
	ld a,080h		;6ead
	ld (04000h),a		;6eaf
L_6EB2:
	in a,(0a9h)		;6eb2
	inc a			;6eb4
	jp nz,L_6EB2		;6eb5
	jp L_6E9B		;6eb8

; ----------------------------------------------------------------------
; DATOS reproduce_samp: las 13 rutinas para la muestra cargada de cinta (SAMP)
;   0x6ebb..0x6ed5  (26 bytes)
DATA_reproduce_samp:
	defw 06f1ch,06f40h,06f69h,06f96h,06fc3h,06fe9h,07014h,07041h	; 6ebb
	defw 07069h,07091h,070b9h,070e1h,0710bh	; 6ecb

; ======================================================================
; CODIGO 0x6ed5..0x7135  (608 bytes)
; ======================================================================


L_6ED5:
	di			;6ed5
	ld de,0dd00h		;6ed6
	ld a,(0db00h)		;6ed9
	add a,0c0h		;6edc
	ld h,a			;6ede
	ld l,e			;6edf
	ld a,(0dc01h)		;6ee0
	ld b,a			;6ee3
L_6EE4:
	ld a,(hl)			;6ee4
	add a,080h		;6ee5
	ld (de),a			;6ee7
	ld a,b			;6ee8
	add a,l			;6ee9
	ld l,a			;6eea
	inc e			;6eeb
	jp nz,L_6EE4		;6eec
	ld a,(0dc47h)		;6eef
	dec a			;6ef2
L_6EF3:
	ld b,a			;6ef3
	sub 008h		;6ef4
	jp nc,L_6EF3		;6ef6
	ld c,080h		;6ef9
	inc b			;6efb
L_6EFC:
	rlc c		;6efc
	djnz L_6EFC		;6efe
	ld a,(0dc47h)		;6f00
	call L_5D81		;6f03
	ret z			;6f06
	ld hl,06ebbh		;6f07
	call L_5D9A		;6f0a
	ld hl,0dd00h		;6f0d
	ld e,h			;6f10
	call L_6F1A		;6f11
	ld a,080h		;6f14
	ld (04000h),a		;6f16
	ret			;6f19
L_6F1A:
	jp (ix)		;6f1a
L_6F1C:
	ld a,(hl)			;6f1c
	ld (04000h),a		;6f1d
	inc hl			;6f20
	ld a,d			;6f21
L_6F22:
	dec a			;6f22
	jp nz,L_6F22		;6f23
	ld h,e			;6f26
	in a,(0a9h)		;6f27
	and c			;6f29
	jp z,L_6F1C		;6f2a
L_6F2D:
	ld a,(hl)			;6f2d
	ld (04000h),a		;6f2e
	inc hl			;6f31
	ld a,d			;6f32
L_6F33:
	dec a			;6f33
	jp nz,L_6F33		;6f34
	cp 000h		;6f37
	nop			;6f39
	ld a,l			;6f3a
	or a			;6f3b
	jp nz,L_6F2D		;6f3c
	ret			;6f3f
L_6F40:
	dec d			;6f40
L_6F41:
	ld a,(hl)			;6f41
	ld (04000h),a		;6f42
	inc hl			;6f45
	ld a,d			;6f46
L_6F47:
	dec a			;6f47
	jp nz,L_6F47		;6f48
	add ix,ix		;6f4b
	ld h,e			;6f4d
	in a,(0a9h)		;6f4e
	and c			;6f50
	jp z,L_6F41		;6f51
L_6F54:
	ld a,(hl)			;6f54
	ld (04000h),a		;6f55
	inc hl			;6f58
	ld a,d			;6f59
L_6F5A:
	dec a			;6f5a
	jp nz,L_6F5A		;6f5b
	add ix,ix		;6f5e
	cp 000h		;6f60
	nop			;6f62
	ld a,l			;6f63
	or a			;6f64
	jp nz,L_6F54		;6f65
	ret			;6f68
L_6F69:
	dec d			;6f69
L_6F6A:
	ld a,(hl)			;6f6a
	ld (04000h),a		;6f6b
	inc hl			;6f6e
	ld a,d			;6f6f
L_6F70:
	dec a			;6f70
	jp nz,L_6F70		;6f71
	neg		;6f74
	neg		;6f76
	ld h,e			;6f78
	in a,(0a9h)		;6f79
	and c			;6f7b
	jp z,L_6F6A		;6f7c
L_6F7F:
	ld a,(hl)			;6f7f
	ld (04000h),a		;6f80
	inc hl			;6f83
	ld a,d			;6f84
L_6F85:
	dec a			;6f85
	jp nz,L_6F85		;6f86
	neg		;6f89
	neg		;6f8b
	cp 000h		;6f8d
	nop			;6f8f
	ld a,l			;6f90
	or a			;6f91
	jp nz,L_6F7F		;6f92
	ret			;6f95
L_6F96:
	dec d			;6f96
L_6F97:
	ld a,(hl)			;6f97
	ld (04000h),a		;6f98
	inc hl			;6f9b
	ld a,d			;6f9c
L_6F9D:
	dec a			;6f9d
	jp nz,L_6F9D		;6f9e
	inc ix		;6fa1
	cp 000h		;6fa3
	ld h,e			;6fa5
	in a,(0a9h)		;6fa6
	and c			;6fa8
	jp z,L_6F97		;6fa9
L_6FAC:
	ld a,(hl)			;6fac
	ld (04000h),a		;6fad
	inc hl			;6fb0
	ld a,d			;6fb1
L_6FB2:
	dec a			;6fb2
	jp nz,L_6FB2		;6fb3
	inc ix		;6fb6
	cp 000h		;6fb8
	cp 000h		;6fba
	nop			;6fbc
	ld a,l			;6fbd
	or a			;6fbe
	jp nz,L_6FAC		;6fbf
	ret			;6fc2
L_6FC3:
	ld a,(hl)			;6fc3
	ld (04000h),a		;6fc4
	inc hl			;6fc7
	ld a,d			;6fc8
L_6FC9:
	dec a			;6fc9
	jp nz,L_6FC9		;6fca
	nop			;6fcd
	ld h,e			;6fce
	in a,(0a9h)		;6fcf
	and c			;6fd1
	jp z,L_6FC3		;6fd2
L_6FD5:
	ld a,(hl)			;6fd5
	ld (04000h),a		;6fd6
	inc hl			;6fd9
	ld a,d			;6fda
L_6FDB:
	dec a			;6fdb
	jp nz,L_6FDB		;6fdc
	nop			;6fdf
	cp 000h		;6fe0
	nop			;6fe2
	ld a,l			;6fe3
	or a			;6fe4
	jp nz,L_6FD5		;6fe5
	ret			;6fe8
L_6FE9:
	dec d			;6fe9
L_6FEA:
	ld a,(hl)			;6fea
	ld (04000h),a		;6feb
	inc hl			;6fee
	ld a,d			;6fef
L_6FF0:
	dec a			;6ff0
	jp nz,L_6FF0		;6ff1
	add a,(ix+000h)		;6ff4
	ld h,e			;6ff7
	in a,(0a9h)		;6ff8
	and c			;6ffa
	jp z,L_6FEA		;6ffb
L_6FFE:
	ld a,(hl)			;6ffe
	ld (04000h),a		;6fff
	inc hl			;7002
	ld a,d			;7003
L_7004:
	dec a			;7004
	jp nz,L_7004		;7005
	add a,(ix+000h)		;7008
	cp 000h		;700b
	nop			;700d
	ld a,l			;700e
	or a			;700f
	jp nz,L_6FFE		;7010
	ret			;7013
L_7014:
	dec d			;7014
L_7015:
	ld a,(hl)			;7015
	ld (04000h),a		;7016
	inc hl			;7019
	ld a,d			;701a
L_701B:
	dec a			;701b
	jp nz,L_701B		;701c
	inc ix		;701f
	inc ix		;7021
	ld h,e			;7023
	in a,(0a9h)		;7024
	and c			;7026
	jp z,L_7015		;7027
L_702A:
	ld a,(hl)			;702a
	ld (04000h),a		;702b
	inc hl			;702e
	ld a,d			;702f
L_7030:
	dec a			;7030
	jp nz,L_7030		;7031
	inc ix		;7034
	inc ix		;7036
	cp 000h		;7038
	nop			;703a
	ld a,l			;703b
	or a			;703c
	jp nz,L_702A		;703d
	ret			;7040
L_7041:
	ld a,(hl)			;7041
	ld (04000h),a		;7042
	inc hl			;7045
	ld a,d			;7046
L_7047:
	dec a			;7047
	jp nz,L_7047		;7048
	cp 000h		;704b
	ld h,e			;704d
	in a,(0a9h)		;704e
	and c			;7050
	jp z,L_7041		;7051
L_7054:
	ld a,(hl)			;7054
	ld (04000h),a		;7055
	inc hl			;7058
	ld a,d			;7059
L_705A:
	dec a			;705a
	jp nz,L_705A		;705b
	cp 000h		;705e
	cp 000h		;7060
	nop			;7062
	ld a,l			;7063
	or a			;7064
	jp nz,L_7054		;7065
	ret			;7068
L_7069:
	ld a,(hl)			;7069
	ld (04000h),a		;706a
	inc hl			;706d
	ld a,d			;706e
L_706F:
	dec a			;706f
	jp nz,L_706F		;7070
	neg		;7073
	ld h,e			;7075
	in a,(0a9h)		;7076
	and c			;7078
	jp z,L_7069		;7079
L_707C:
	ld a,(hl)			;707c
	ld (04000h),a		;707d
	inc hl			;7080
	ld a,d			;7081
L_7082:
	dec a			;7082
	jp nz,L_7082		;7083
	neg		;7086
	cp 000h		;7088
	nop			;708a
	ld a,l			;708b
	or a			;708c
	jp nz,L_707C		;708d
	ret			;7090
L_7091:
	ld a,(hl)			;7091
	ld (04000h),a		;7092
	inc hl			;7095
	ld a,d			;7096
L_7097:
	dec a			;7097
	jp nz,L_7097		;7098
	ld a,i		;709b
	ld h,e			;709d
	in a,(0a9h)		;709e
	and c			;70a0
	jp z,L_7091		;70a1
L_70A4:
	ld a,(hl)			;70a4
	ld (04000h),a		;70a5
	inc hl			;70a8
	ld a,d			;70a9
L_70AA:
	dec a			;70aa
	jp nz,L_70AA		;70ab
	ld a,i		;70ae
	cp 000h		;70b0
	nop			;70b2
	ld a,l			;70b3
	or a			;70b4
	jp nz,L_70A4		;70b5
	ret			;70b8
L_70B9:
	ld a,(hl)			;70b9
	ld (04000h),a		;70ba
	inc hl			;70bd
	ld a,d			;70be
L_70BF:
	dec a			;70bf
	jp nz,L_70BF		;70c0
	inc ix		;70c3
	ld h,e			;70c5
	in a,(0a9h)		;70c6
	and c			;70c8
	jp z,L_70B9		;70c9
L_70CC:
	ld a,(hl)			;70cc
	ld (04000h),a		;70cd
	inc hl			;70d0
	ld a,d			;70d1
L_70D2:
	dec a			;70d2
	jp nz,L_70D2		;70d3
	inc ix		;70d6
	cp 000h		;70d8
	nop			;70da
	ld a,l			;70db
	or a			;70dc
	jp nz,L_70CC		;70dd
	ret			;70e0
L_70E1:
	ld a,(hl)			;70e1
	ld (04000h),a		;70e2
	inc hl			;70e5
	ld a,d			;70e6
L_70E7:
	dec a			;70e7
	jp nz,L_70E7		;70e8
	cp 000h		;70eb
	nop			;70ed
	ld h,e			;70ee
	in a,(0a9h)		;70ef
	and c			;70f1
	jp z,L_70E1		;70f2
L_70F5:
	ld a,(hl)			;70f5
	ld (04000h),a		;70f6
	inc hl			;70f9
	ld a,d			;70fa
L_70FB:
	dec a			;70fb
	jp nz,L_70FB		;70fc
	cp 000h		;70ff
	nop			;7101
	cp 000h		;7102
	nop			;7104
	ld a,l			;7105
	or a			;7106
	jp nz,L_70F5		;7107
	ret			;710a
L_710B:
	ld a,(hl)			;710b
	ld (04000h),a		;710c
	inc hl			;710f
	ld a,d			;7110
L_7111:
	dec a			;7111
	jp nz,L_7111		;7112
	neg		;7115
	nop			;7117
	ld h,e			;7118
	in a,(0a9h)		;7119
	and c			;711b
	jp z,L_710B		;711c
L_711F:
	ld a,(hl)			;711f
	ld (04000h),a		;7120
	inc hl			;7123
	ld a,d			;7124
L_7125:
	dec a			;7125
	jp nz,L_7125		;7126
	neg		;7129
	nop			;712b
	cp 000h		;712c
	nop			;712e
	ld a,l			;712f
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


L_A5AA:
	ld b,008h		;a5aa
	ld a,(0d803h)		;a5ac
	and 010h		;a5af
	jr nz,L_A5B5		;a5b1
	ld b,00ch		;a5b3
L_A5B5:
	ld a,b			;a5b5
	ld (0d873h),a		;a5b6
	ld a,(0d8fah)		;a5b9
	dec a			;a5bc
	jp z,L_ACDA		;a5bd
	jp m,L_AD5A		;a5c0
	cp 001h		;a5c3
	jp z,L_AD31		;a5c5
	ld a,(0d802h)		;a5c8
	and 040h		;a5cb
	ret z			;a5cd
	ld b,000h		;a5ce
	ld a,(0d808h)		;a5d0
	rra			;a5d3
	jr nc,L_A5D9		;a5d4
	ld a,b			;a5d6
	jr L_A5EA		;a5d7
L_A5D9:
	inc b			;a5d9
	rra			;a5da
	jr c,L_A5E5		;a5db
	inc b			;a5dd
	rra			;a5de
	jr c,L_A5E5		;a5df
	inc b			;a5e1
	rra			;a5e2
	jr nc,L_A629		;a5e3
L_A5E5:
	xor a			;a5e5
L_A5E6:
	add a,01eh		;a5e6
	djnz L_A5E6		;a5e8
L_A5EA:
	ld hl,0db01h		;a5ea
	ld b,(hl)			;a5ed
	add a,b			;a5ee
	ld de,0ac26h		;a5ef
	call de_mas_a		;a5f2
	ld a,(de)			;a5f5
	cp (hl)			;a5f6
	jr z,L_A629		;a5f7
	ld (hl),a			;a5f9
	sla a		;a5fa
	ld de,0ac9eh		;a5fc
	call de_mas_a		;a5ff
	ld b,002h		;a602
	ld hl,0d870h		;a604
L_A607:
	ld a,(de)			;a607
	ld (hl),a			;a608
	inc de			;a609
	inc hl			;a60a
	ld a,(de)			;a60b
	ld (hl),a			;a60c
	dec de			;a60d
	inc hl			;a60e
	inc hl			;a60f
	inc hl			;a610
	djnz L_A607		;a611
	ld a,001h		;a613
	call L_BEB1		;a615
	ld hl,0a9b3h		;a618
	ld a,(0db01h)		;a61b
	dec a			;a61e
	call hl_mas_a		;a61f
	ld a,(hl)			;a622
	ld de,0db06h		;a623
	ld (de),a			;a626
	inc de			;a627
	ld (de),a			;a628
L_A629:
	xor a			;a629
	ld (0d87bh),a		;a62a
	ld (0d87fh),a		;a62d
	ld (0d883h),a		;a630
	call L_ADDB		;a633
	ld a,(0d808h)		;a636
	ld c,a			;a639
	ld a,(0db01h)		;a63a
	cp 001h		;a63d
	jp c,L_A739		;a63f
	push af			;a642
	xor a			;a643
	ld (0db03h),a		;a644
	pop af			;a647
	cp 015h		;a648
	jp c,L_A7D7		;a64a
	cp 019h		;a64d
	jp c,L_AA5B		;a64f
	cp 01bh		;a652
	jp c,L_AB58		;a654
	cp 01ch		;a657
	jr c,L_A6C3		;a659
	cp 01dh		;a65b
	jp z,L_AC08		;a65d
	ld a,017h		;a660
	call hl_mas_a		;a662
	ld a,(0db02h)		;a665
	or a			;a668
	jr nz,L_A693		;a669
	ld a,(0db08h)		;a66b
	or a			;a66e
	jr nz,L_A693		;a66f
	ld c,001h		;a671
	ld a,(0db04h)		;a673
	or a			;a676
	jr z,L_A67B		;a677
	ld c,010h		;a679
L_A67B:
	ld a,(0d8f3h)		;a67b
	cp 044h		;a67e
	jr z,L_A68D		;a680
	cp 043h		;a682
	jr nz,L_A693		;a684
	ld a,(hl)			;a686
	add a,c			;a687
	jr nz,L_A692		;a688
	sub c			;a68a
	jr L_A692		;a68b
L_A68D:
	ld a,(hl)			;a68d
	sub c			;a68e
	jr nz,L_A692		;a68f
	add a,c			;a691
L_A692:
	ld (hl),a			;a692
L_A693:
	ld a,(0db04h)		;a693
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
	ld c,a			;a6a4
	ld b,000h		;a6a5
	ld de,0a000h		;a6a7
	ld a,00fh		;a6aa
	call L_A6FB		;a6ac
	ld hl,0393ch		;a6af
	ld b,002h		;a6b2
	ld de,0dbf0h		;a6b4
	call L_43DC		;a6b7
	dec hl			;a6ba
	ld b,004h		;a6bb
	ld de,0dbf1h		;a6bd
	jp L_43DC		;a6c0
L_A6C3:
	inc hl			;a6c3
	ld a,(0db02h)		;a6c4
	or a			;a6c7
	jr nz,L_A6E5		;a6c8
	ld a,(0d8f3h)		;a6ca
	cp 044h		;a6cd
	jr z,L_A6DE		;a6cf
	cp 043h		;a6d1
	ret nz			;a6d3
	ld a,(hl)			;a6d4
	add a,a			;a6d5
	cp 040h		;a6d6
	jr c,L_A6E4		;a6d8
	ld a,020h		;a6da
	jr L_A6E4		;a6dc
L_A6DE:
	ld a,(hl)			;a6de
	rra			;a6df
	jr nc,L_A6E4		;a6e0
	ld a,001h		;a6e2
L_A6E4:
	ld (hl),a			;a6e4
L_A6E5:
	ld a,(hl)			;a6e5
	ld c,a			;a6e6
	ld b,000h		;a6e7
	ld de,0fa00h		;a6e9
	xor a			;a6ec
	call L_A6FB		;a6ed
	ld hl,038c5h		;a6f0
	ld b,002h		;a6f3
	ld de,0dbf1h		;a6f5
	jp L_43DC		;a6f8
L_A6FB:
	call L_ADC0		;a6fb
	ld l,e			;a6fe
	ld h,d			;a6ff
	ld e,a			;a700
	call L_AD9C		;a701
	ld hl,0dbf4h		;a704
	ld (hl),000h		;a707
	dec hl			;a709
	ld (hl),b			;a70a
	dec hl			;a70b
	ld (hl),c			;a70c
	dec hl			;a70d
	ld (hl),d			;a70e
	dec hl			;a70f
	ld (hl),e			;a710
	ld a,e			;a711
	and 00fh		;a712
	cp 005h		;a714
	jr c,L_A72B		;a716
	ld a,010h		;a718
	add a,(hl)			;a71a
	daa			;a71b
	ld (hl),a			;a71c
	jr nc,L_A72B		;a71d
	ld b,003h		;a71f
L_A721:
	inc hl			;a721
	ld a,001h		;a722
	add a,(hl)			;a724
	daa			;a725
	ld (hl),a			;a726
	jr nc,L_A72B		;a727
	djnz L_A721		;a729
L_A72B:
	ld hl,0dbf0h		;a72b
	ld b,004h		;a72e
L_A730:
	inc hl			;a730
	ld a,(hl)			;a731
	dec hl			;a732
	rrd		;a733
	inc hl			;a735
	djnz L_A730		;a736
	ret			;a738
L_A739:
	ld a,(0db02h)		;a739
	or a			;a73c
	ret nz			;a73d
	ld b,06fh		;a73e
	jr L_A744		;a740
L_A742:
	ld b,067h		;a742
L_A744:
	ld de,0db03h		;a744
	ld a,(de)			;a747
	add a,a			;a748
	add a,a			;a749
	add a,a			;a74a
	add a,b			;a74b
	ld (0d881h),a		;a74c
	ld a,(0d870h)		;a74f
	ld (0d880h),a		;a752
	ld a,(0db17h)		;a755
	or a			;a758
	jr z,L_A766		;a759
	ld a,05dh		;a75b
	ld (0d880h),a		;a75d
	ld hl,0db0fh		;a760
	ld a,(de)			;a763
	jr L_A76E		;a764
L_A766:
	ld a,008h		;a766
	ld (0d883h),a		;a768
	ld a,(de)			;a76b
	add a,019h		;a76c
L_A76E:
	call hl_mas_a		;a76e
	ld a,(0d8f1h)		;a771
	or a			;a774
	jr z,L_A792		;a775
	cp 031h		;a777
	jr nc,L_A792		;a779
	cp 017h		;a77b
	jr nc,L_A788		;a77d
	cp 00bh		;a77f
	jr nc,L_A792		;a781
	dec a			;a783
	add a,040h		;a784
	jr L_A78C		;a786
L_A788:
	sub 017h		;a788
	add a,021h		;a78a
L_A78C:
	ld (hl),a			;a78c
	call L_A7A7		;a78d
	jr L_A7B8		;a790
L_A792:
	ld a,(0d8f3h)		;a792
	cp 03eh		;a795
	jr z,L_A7B2		;a797
	ld a,(0d806h)		;a799
	and 010h		;a79c
	jr z,L_A7B7		;a79e
	ld (hl),020h		;a7a0
	call L_A7A7		;a7a2
	jr L_A7B8		;a7a5
L_A7A7:
	ex de,hl			;a7a7
	inc (hl)			;a7a8
	ld a,(hl)			;a7a9
	cp 007h		;a7aa
	jr c,L_A7B0		;a7ac
	ld (hl),000h		;a7ae
L_A7B0:
	ex de,hl			;a7b0
	ret			;a7b1
L_A7B2:
	ex de,hl			;a7b2
	dec (hl)			;a7b3
	ret p			;a7b4
	ld (hl),006h		;a7b5
L_A7B7:
	ret			;a7b7
L_A7B8:
	jp L_AD0A		;a7b8
L_A7BB:
	dec a			;a7bb
	push de			;a7bc
	push hl			;a7bd
	call L_A7CB		;a7be
	pop hl			;a7c1
	pop de			;a7c2
	push de			;a7c3
	push hl			;a7c4
	call L_A86A		;a7c5
	pop hl			;a7c8
	pop de			;a7c9
	ret			;a7ca
L_A7CB:
	ld h,a			;a7cb
	call L_ADEB		;a7cc
	ld a,h			;a7cf
	or a			;a7d0
	jr z,L_A7D5		;a7d1
	ld l,0ffh		;a7d3
L_A7D5:
	ld a,l			;a7d5
	ret			;a7d6
L_A7D7:
	inc hl			;a7d7
	inc hl			;a7d8
	ld a,(0db01h)		;a7d9
	ld b,a			;a7dc
	dec a			;a7dd
	call hl_mas_a		;a7de
	ld c,000h		;a7e1
	ld a,b			;a7e3
	call L_A92D		;a7e4
	jr nc,L_A7F0		;a7e7
	ld a,(0db04h)		;a7e9
	or a			;a7ec
	jp nz,L_A8B7		;a7ed
L_A7F0:
	ld a,(0db02h)		;a7f0
	or a			;a7f3
	jp nz,L_A8C0		;a7f4
	call L_A94C		;a7f7
	ld a,(0db01h)		;a7fa
	dec a			;a7fd
	ld de,0a98bh		;a7fe
	call de_mas_a		;a801
	ld a,(de)			;a804
	ld c,a			;a805
	ld (0db1bh),a		;a806
	ld a,(0d8f1h)		;a809
	or a			;a80c
	jr z,L_A883		;a80d
	cp 00bh		;a80f
	jr nc,L_A883		;a811
	ld a,(0db06h)		;a813
	ld (hl),000h		;a816
	ld de,0db19h		;a818
	dec a			;a81b
	jr z,L_A858		;a81c
	jp p,L_A864		;a81e
	ld a,(de)			;a821
	or a			;a822
	jr z,L_A82C		;a823
	push de			;a825
	ld e,064h		;a826
	call L_A7BB		;a828
	pop de			;a82b
L_A82C:
	inc de			;a82c
	ld a,(de)			;a82d
	or a			;a82e
	jr z,L_A838		;a82f
	push de			;a831
	ld e,00ah		;a832
	call L_A7BB		;a834
	pop de			;a837
L_A838:
	ld a,(0d8f1h)		;a838
L_A83B:
	dec a			;a83b
	call L_A86A		;a83c
	ld de,0db06h		;a83f
	ld a,(de)			;a842
	dec a			;a843
	jp p,L_A854		;a844
	ld b,002h		;a847
	ld hl,0db19h		;a849
L_A84C:
	ld (hl),000h		;a84c
	inc hl			;a84e
	djnz L_A84C		;a84f
	inc de			;a851
	ld a,(de)			;a852
	dec de			;a853
L_A854:
	ld (de),a			;a854
	jp L_A94C		;a855
L_A858:
	ld a,(de)			;a858
	or a			;a859
	jr z,L_A863		;a85a
	push de			;a85c
	ld e,00ah		;a85d
	call L_A7BB		;a85f
	pop de			;a862
L_A863:
	inc de			;a863
L_A864:
	ld a,(0d8f1h)		;a864
	ld (de),a			;a867
	jr L_A83B		;a868
L_A86A:
	ex af,af'			;a86a
	ld a,(0db1bh)		;a86b
	ld c,a			;a86e
	or a			;a86f
	jr nz,L_A87A		;a870
	ex af,af'			;a872
	add a,(hl)			;a873
	jr nc,L_A880		;a874
	ld a,0ffh		;a876
	jr L_A880		;a878
L_A87A:
	ex af,af'			;a87a
	add a,(hl)			;a87b
	cp c			;a87c
	jr c,L_A880		;a87d
	ld a,c			;a87f
L_A880:
	ld (hl),a			;a880
	jr L_A8C0		;a881
L_A883:
	ld a,(0db1bh)		;a883
	ld c,a			;a886
	ld a,(0d8f3h)		;a887
	cp 043h		;a88a
	jr z,L_A8A6		;a88c
	cp 044h		;a88e
	jr nz,L_A8C0		;a890
	ld a,c			;a892
	or a			;a893
	jr z,L_A89D		;a894
	dec (hl)			;a896
	jp p,L_A8C0		;a897
	inc (hl)			;a89a
	jr L_A8C0		;a89b
L_A89D:
	dec (hl)			;a89d
	ld a,(hl)			;a89e
	cp 0ffh		;a89f
	jr nz,L_A8C0		;a8a1
	inc (hl)			;a8a3
	jr L_A8C0		;a8a4
L_A8A6:
	ld a,c			;a8a6
	or a			;a8a7
	jr z,L_A8B1		;a8a8
	ld a,(hl)			;a8aa
	cp c			;a8ab
	jr nc,L_A8C0		;a8ac
	inc (hl)			;a8ae
	jr L_A8C0		;a8af
L_A8B1:
	inc (hl)			;a8b1
	jr nz,L_A8C0		;a8b2
	dec (hl)			;a8b4
	jr L_A8C0		;a8b5
L_A8B7:
	push hl			;a8b7
	ld a,(0db04h)		;a8b8
	or a			;a8bb
	jr nz,L_A914		;a8bc
	jr L_A8C1		;a8be
L_A8C0:
	push hl			;a8c0
L_A8C1:
	ld l,(hl)			;a8c1
	call L_A978		;a8c2
	ld hl,0dbf0h		;a8c5
	push hl			;a8c8
	ld (hl),e			;a8c9
	inc hl			;a8ca
	ld (hl),d			;a8cb
	ld hl,0a9c7h		;a8cc
	call L_A96C		;a8cf
	ex de,hl			;a8d2
	pop de			;a8d3
	ld b,003h		;a8d4
	call L_43DC		;a8d6
L_A8D9:
	ld hl,0a9efh		;a8d9
	call L_A96C		;a8dc
	ld a,(0db01h)		;a8df
	dec a			;a8e2
	ld hl,0a99fh		;a8e3
	call hl_mas_a		;a8e6
	ld b,(hl)			;a8e9
	ld a,b			;a8ea
	or a			;a8eb
	jr nz,L_A8F3		;a8ec
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
	srl a		;a8f8
	djnz L_A8F8		;a8fa
L_A8FC:
	or a			;a8fc
	jr nz,L_A900		;a8fd
	inc a			;a8ff
L_A900:
	ld hl,0aa17h		;a900
	ld bc,00004h		;a903
	or a			;a906
	jr z,L_A90D		;a907
L_A909:
	add hl,bc			;a909
	dec a			;a90a
	jr nz,L_A909		;a90b
L_A90D:
	ex de,hl			;a90d
	ld bc,00004h		;a90e
	jp L_42FF		;a911
L_A914:
	ld (hl),000h		;a914
	ld hl,0a9c7h		;a916
	call L_A96C		;a919
	ex de,hl			;a91c
	ld de,0a92ah		;a91d
	ld bc,00003h		;a920
	dec hl			;a923
	dec hl			;a924
	call L_42FF		;a925
	jr L_A8D9		;a928

; ----------------------------------------------------------------------
; DATOS tiles_flecha: 3 tiles que copia 0xA928
;   0xa92a..0xa92d  (3 bytes)
DATA_tiles_flecha:
	defb 095h,096h,096h	; a92a

; ======================================================================
; CODIGO 0xa92d..0xa947  (26 bytes)
; ======================================================================


L_A92D:
	push bc			;a92d
	exx			;a92e
	pop bc			;a92f
	ld b,a			;a930
	ld a,c			;a931
	ld hl,0a947h		;a932
	call hl_mas_a		;a935
L_A938:
	ld a,(hl)			;a938
	inc a			;a939
	jr z,L_A944		;a93a
	inc hl			;a93c
	dec a			;a93d
	cp b			;a93e
	jr nz,L_A938		;a93f
	scf			;a941
	exx			;a942
	ret			;a943
L_A944:
	xor a			;a944
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


L_A94C:
	ld a,(0d870h)		;a94c
	dec a			;a94f
	ld (0d878h),a		;a950
	ld (0d87ch),a		;a953
	ld a,(0d871h)		;a956
	sub 03ah		;a959
	ld (0d879h),a		;a95b
	add a,010h		;a95e
	ld (0d87dh),a		;a960
	ld a,008h		;a963
	ld (0d87bh),a		;a965
	ld (0d87fh),a		;a968
	ret			;a96b
L_A96C:
	ld a,(0db01h)		;a96c
	dec a			;a96f
	rlca			;a970
	call hl_mas_a		;a971
	ld e,(hl)			;a974
	inc hl			;a975
	ld d,(hl)			;a976
	ret			;a977
L_A978:
	ld bc,00800h		;a978
	ld de,00000h		;a97b
L_A97E:
	sla l		;a97e
	ld a,e			;a980
	adc a,a			;a981
	daa			;a982
	ld e,a			;a983
	ld a,d			;a984
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


L_AA5B:
	ld a,018h		;aa5b
	call hl_mas_a		;aa5d
	ld a,(0db01h)		;aa60
	sub 015h		;aa63
	ld b,a			;aa65
	push bc			;aa66
	ld de,0ab31h		;aa67
	call de_mas_a		;aa6a
	ld a,(0db02h)		;aa6d
	or a			;aa70
	jr nz,L_AAA5		;aa71
	ld a,(de)			;aa73
	ld c,a			;aa74
	ld a,(0d8f3h)		;aa75
	cp 044h		;aa78
	jr z,L_AA94		;aa7a
	cp 043h		;aa7c
	jr z,L_AA82		;aa7e
	pop bc			;aa80
	ret			;aa81
L_AA82:
	ld a,c			;aa82
	cp 0ffh		;aa83
	jr z,L_AA8C		;aa85
	cpl			;aa87
	and (hl)			;aa88
	ld (hl),a			;aa89
	jr L_AAA5		;aa8a
L_AA8C:
	ld a,(hl)			;aa8c
	and 003h		;aa8d
	jr z,L_AAA5		;aa8f
	dec (hl)			;aa91
	jr L_AAA5		;aa92
L_AA94:
	ld a,c			;aa94
	cp 0ffh		;aa95
	jr z,L_AA9D		;aa97
	or (hl)			;aa99
	ld (hl),a			;aa9a
	jr L_AAA5		;aa9b
L_AA9D:
	ld a,(hl)			;aa9d
	and 003h		;aa9e
	cp 002h		;aaa0
	jr z,L_AAA5		;aaa2
	inc (hl)			;aaa4
L_AAA5:
	ld a,(0db01h)		;aaa5
	cp 018h		;aaa8
	jr nz,L_AACA		;aaaa
	ld a,(0db04h)		;aaac
	or a			;aaaf
	jr z,L_AABC		;aab0
	bit 7,(hl)		;aab2
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
	call L_AB09		;aac6
	pop hl			;aac9
L_AACA:
	pop bc			;aaca
	ld a,b			;aacb
	add a,a			;aacc
	add a,b			;aacd
	exx			;aace
	ld hl,0ab35h		;aacf
	call hl_mas_a		;aad2
	ld a,(hl)			;aad5
	inc hl			;aad6
	ld e,(hl)			;aad7
	inc hl			;aad8
	ld d,(hl)			;aad9
	exx			;aada
	ld b,a			;aadb
	or a			;aadc
	ld a,(hl)			;aadd
	jr nz,L_AAE8		;aade
	exx			;aae0
	ld hl,0ab47h		;aae1
	and 003h		;aae4
	jr L_AAF1		;aae6
L_AAE8:
	rrca			;aae8
	djnz L_AAE8		;aae9
	exx			;aaeb
	ld hl,0ab41h		;aaec
	and 001h		;aaef
L_AAF1:
	ld b,a			;aaf1
	add a,a			;aaf2
	add a,b			;aaf3
	call hl_mas_a		;aaf4
	ex de,hl			;aaf7
	exx			;aaf8
	ld b,003h		;aaf9
L_AAFB:
	exx			;aafb
	ld a,(de)			;aafc
	call 0004dh		;aafd   ; BIOS WRTVRM - Writes data in VRAM
	inc de			;ab00
	ld bc,00020h		;ab01
	add hl,bc			;ab04
	exx			;ab05
	djnz L_AAFB		;ab06
	ret			;ab08
L_AB09:
	ld a,001h		;ab09
	ld (0db08h),a		;ab0b
	ld a,(0db01h)		;ab0e
	ld (0db05h),a		;ab11
	ld hl,0ab50h		;ab14
	ld a,(hl)			;ab17
L_AB18:
	ld (0db01h),a		;ab18
	push hl			;ab1b
	call L_A629		;ab1c
	pop hl			;ab1f
	inc hl			;ab20
	ld a,(hl)			;ab21
	cp 0ffh		;ab22
	jr nz,L_AB18		;ab24
	ld a,(0db05h)		;ab26
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


L_AB58:
	ld de,03905h		;ab58
	ld a,(0db01h)		;ab5b
	cp 019h		;ab5e
	jr z,L_AB6A		;ab60
	ld de,03977h		;ab62
	ld a,016h		;ab65
	call hl_mas_a		;ab67
L_AB6A:
	ld a,(0db02h)		;ab6a
	or a			;ab6d
	jr nz,L_AB9E		;ab6e
	ld a,(0db08h)		;ab70
	or a			;ab73
	jr nz,L_AB9E		;ab74
	ld b,010h		;ab76
	ld a,(0db04h)		;ab78
	or a			;ab7b
	jr z,L_AB80		;ab7c
	ld b,00fh		;ab7e
L_AB80:
	ld a,(0d8f1h)		;ab80
	cp 044h		;ab83
	jr z,L_AB94		;ab85
	cp 043h		;ab87
	jr nz,L_AB9E		;ab89
	ld a,(hl)			;ab8b
	inc a			;ab8c
	cp b			;ab8d
	jr c,L_AB91		;ab8e
	xor a			;ab90
L_AB91:
	ld (hl),a			;ab91
	jr L_AB9E		;ab92
L_AB94:
	ld a,(hl)			;ab94
	dec a			;ab95
	jp p,L_AB9B		;ab96
	ld a,b			;ab99
	dec a			;ab9a
L_AB9B:
	ld (hl),a			;ab9b
	jr L_ABAB		;ab9c
L_AB9E:
	ld a,(0db04h)		;ab9e
	or a			;aba1
	jr z,L_ABAB		;aba2
	ld a,(hl)			;aba4
	cp 00fh		;aba5
	jr nz,L_ABAB		;aba7
	ld (hl),000h		;aba9
L_ABAB:
	ex de,hl			;abab
	ld a,(de)			;abac
	inc a			;abad
	push de			;abae
	cp 00ah		;abaf
	jr c,L_ABBA		;abb1
	push hl			;abb3
	ld l,a			;abb4
	call L_A978		;abb5
	ld a,e			;abb8
	pop hl			;abb9
L_ABBA:
	ld de,0dbf0h		;abba
	ld (de),a			;abbd
	ld b,002h		;abbe
	call L_43DC		;abc0
	pop de			;abc3
	inc hl			;abc4
	inc hl			;abc5
	inc hl			;abc6
	inc hl			;abc7
	ld a,(de)			;abc8
	ld b,a			;abc9
	add a,a			;abca
	add a,b			;abcb
	ld de,0abd8h		;abcc
	call de_mas_a		;abcf
	ld bc,00003h		;abd2
	jp L_42FF		;abd5

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


L_AC08:
	call L_B1E8		;ac08
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


L_ACDA:
	call L_ACEA		;acda
	ld de,0d870h		;acdd
	ld hl,0ac12h		;ace0
	ld bc,00014h		;ace3
	ldir		;ace6
	jr L_AD55		;ace8
L_ACEA:
	ld a,(0db00h)		;acea
	inc a			;aced
	ld l,a			;acee
	call L_A978		;acef
	ld a,e			;acf2
	and 00fh		;acf3
	or 040h		;acf5
	ld hl,0384ch		;acf7
	call 0004dh		;acfa   ; BIOS WRTVRM - Writes data in VRAM
	dec hl			;acfd
	ld a,e			;acfe
	and 0f0h		;acff
	rrca			;ad01
	rrca			;ad02
	rrca			;ad03
	rrca			;ad04
	or 040h		;ad05
	call 0004dh		;ad07   ; BIOS WRTVRM - Writes data in VRAM
L_AD0A:
	ld de,0db0fh		;ad0a
	ld hl,0398dh		;ad0d
	ld a,(0db17h)		;ad10
	or a			;ad13
	jr nz,L_AD21		;ad14
	call L_ADDB		;ad16
	ld de,00019h		;ad19
	add hl,de			;ad1c
	ex de,hl			;ad1d
	ld hl,0384eh		;ad1e
L_AD21:
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
L_AD31:
	ld a,001h		;ad31
	ld (0db02h),a		;ad33
	ld a,018h		;ad36
	ld (0db01h),a		;ad38
	call L_A629		;ad3b
	xor a			;ad3e
	ld (0db01h),a		;ad3f
L_AD42:
	call L_A629		;ad42
	ld hl,0db01h		;ad45
	inc (hl)			;ad48
	ld a,(hl)			;ad49
	cp 021h		;ad4a
	jr c,L_AD42		;ad4c
	xor a			;ad4e
	ld (0db02h),a		;ad4f
	ld a,01dh		;ad52
	ld (hl),a			;ad54
L_AD55:
	ld hl,0d8fah		;ad55
	inc (hl)			;ad58
	ret			;ad59
L_AD5A:
	call L_49C7		;ad5a
	call L_43B0		;ad5d
	ret p			;ad60
	xor a			;ad61
	ld (0db17h),a		;ad62
	call L_B32E		;ad65
	call L_B335		;ad68
	ld de,08ac1h		;ad6b
	ld hl,02458h		;ad6e
	call L_4327		;ad71
	ld de,08db6h		;ad74
	ld hl,00458h		;ad77
	call L_4327		;ad7a
	ld de,08fcdh		;ad7d
	call L_4352		;ad80
	ld hl,00900h		;ad83
	ld a,030h		;ad86
	ld bc,000b8h		;ad88
	call 00056h		;ad8b   ; BIOS FILVRM - Fills VRAM with value
	ld de,09087h		;ad8e
	call L_4352		;ad91
	call L_B32A		;ad94
	call L_49C4		;ad97
	jr L_AD55		;ad9a
L_AD9C:
	exx			;ad9c
	ld bc,00000h		;ad9d
	ld de,00000h		;ada0
	ld a,018h		;ada3
L_ADA5:
	ex af,af'			;ada5
	exx			;ada6
	add hl,hl			;ada7
	rl e		;ada8
	exx			;adaa
	ld a,e			;adab
	adc a,a			;adac
	daa			;adad
	ld e,a			;adae
	ld a,d			;adaf
	adc a,a			;adb0
	daa			;adb1
	ld d,a			;adb2
	ld a,c			;adb3
	adc a,a			;adb4
	daa			;adb5
	ld c,a			;adb6
	ld a,b			;adb7
	adc a,a			;adb8
	daa			;adb9
	ld b,a			;adba
	ex af,af'			;adbb
	dec a			;adbc
	jr nz,L_ADA5		;adbd
	ret			;adbf
L_ADC0:
	ld hl,00000h		;adc0
	exx			;adc3
	ld b,018h		;adc4
L_ADC6:
	exx			;adc6
	sla e		;adc7
	rl d		;adc9
	rla			;adcb
	adc hl,hl		;adcc
	sbc hl,bc		;adce
	jr c,L_ADD5		;add0
	inc e			;add2
	jr L_ADD6		;add3
L_ADD5:
	add hl,bc			;add5
L_ADD6:
	exx			;add6
	djnz L_ADC6		;add7
	exx			;add9
	ret			;adda
L_ADDB:
	ld hl,0d000h		;addb
	ld a,(0db00h)		;adde
	or a			;ade1
	ret z			;ade2
	ld b,a			;ade3
	ld de,00020h		;ade4
L_ADE7:
	add hl,de			;ade7
	djnz L_ADE7		;ade8
	ret			;adea
L_ADEB:
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
L_ADF7:
	call L_B1E8		;adf7
	jr nc,L_AE01		;adfa
	ld a,001h		;adfc
	ld (0d8fah),a		;adfe
L_AE01:
	ld a,(0d8fah)		;ae01
	dec a			;ae04
	jp z,L_AFA0		;ae05
	jp m,L_AFF9		;ae08
	cp 001h		;ae0b
	jp z,L_AFC7		;ae0d
	ld a,(0d812h)		;ae10
	or a			;ae13
	ret nz			;ae14
	ld a,(0d8f2h)		;ae15
	or a			;ae18
	jr z,L_AE26		;ae19
	cp 031h		;ae1b
	jr nc,L_AE26		;ae1d
	ld (0dc47h),a		;ae1f
	call L_6ED5		;ae22
	ei			;ae25
L_AE26:
	call L_AE88		;ae26
	call L_B19D		;ae29
	ld a,(0d8f2h)		;ae2c
	cp 032h		;ae2f
	jr nz,L_AE4F		;ae31
	ld a,008h		;ae33
	call 00141h		;ae35   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 1,a		;ae38
	ret nz			;ae3a
	xor a			;ae3b
	ld (0da80h),a		;ae3c
	call L_B1A0		;ae3f
	ld b,000h		;ae42
L_AE44:
	ld (hl),000h		;ae44
	inc hl			;ae46
	djnz L_AE44		;ae47
	ld a,001h		;ae49
	ld (0d8fah),a		;ae4b
	ret			;ae4e
L_AE4F:
	ld a,(0d8f1h)		;ae4f
	cp 03fh		;ae52
	jp z,L_AEB4		;ae54
	ld a,(0d808h)		;ae57
	ld b,a			;ae5a
	and 00ch		;ae5b
	jp nz,L_AEE1		;ae5d
	ld a,b			;ae60
	and 003h		;ae61
	ret z			;ae63
	bit 0,a		;ae64
	ld a,(hl)			;ae66
	jr z,L_AE73		;ae67
	bit 7,a		;ae69
	jr nz,L_AE70		;ae6b
	cp 07fh		;ae6d
	ret nc			;ae6f
L_AE70:
	inc (hl)			;ae70
	jr L_AE7B		;ae71
L_AE73:
	bit 7,a		;ae73
	jr z,L_AE7A		;ae75
	cp 082h		;ae77
	ret c			;ae79
L_AE7A:
	dec (hl)			;ae7a
L_AE7B:
	call L_B21B		;ae7b
	ld c,(hl)			;ae7e
	call L_AF87		;ae7f
	ld a,001h		;ae82
	ld (0da8dh),a		;ae84
	ret			;ae87
L_AE88:
	ld a,(0da8dh)		;ae88
	or a			;ae8b
	ret z			;ae8c
	call L_B236		;ae8d
	ld hl,0da8bh		;ae90
	ld de,0da80h		;ae93
	ld a,(0da87h)		;ae96
	ld c,a			;ae99
	ld (hl),a			;ae9a
	ld a,(de)			;ae9b
	inc (hl)			;ae9c
	ld a,(de)			;ae9d
	sub c			;ae9e
	dec hl			;ae9f
	ld (hl),a			;aea0
L_AEA1:
	push bc			;aea1
	push hl			;aea2
	call L_B0AB		;aea3
	pop hl			;aea6
	pop bc			;aea7
	inc (hl)			;aea8
	inc (hl)			;aea9
	inc hl			;aeaa
	dec (hl)			;aeab
	dec hl			;aeac
	jr nz,L_AEA1		;aead
	xor a			;aeaf
	ld (0da8dh),a		;aeb0
	ret			;aeb3
L_AEB4:
	ld a,(0da8dh)		;aeb4
	or a			;aeb7
	ret nz			;aeb8
	ld hl,0da86h		;aeb9
	ld a,(hl)			;aebc
	dec (hl)			;aebd
	and 003h		;aebe
	jr nz,L_AEC5		;aec0
	ld a,003h		;aec2
	dec (hl)			;aec4
L_AEC5:
	ld c,a			;aec5
	ld b,a			;aec6
	ld a,002h		;aec7
L_AEC9:
	add a,a			;aec9
	djnz L_AEC9		;aeca
	inc hl			;aecc
	ld (hl),a			;aecd
	ld hl,038dch		;aece
	push hl			;aed1
	ld a,c			;aed2
	ld hl,0aeddh		;aed3
	call hl_mas_a		;aed6
	ld l,(hl)			;aed9
	jp L_AF77		;aeda

; ----------------------------------------------------------------------
; DATOS bits_80_40_20_10: mascaras de bit que lee 0xAED9
;   0xaedd..0xaee1  (4 bytes)
DATA_bits_80_40_20_10:
	defb 080h,040h,020h,010h	; aedd

; ======================================================================
; CODIGO 0xaee1..0xb1cd  (748 bytes)
; ======================================================================


L_AEE1:
	ld a,(0da8dh)		;aee1
	or a			;aee4
	ret nz			;aee5
	ld a,(0da87h)		;aee6
	ld c,a			;aee9
	dec a			;aeea
	cpl			;aeeb
	ld b,a			;aeec
	ld de,0d871h		;aeed
	ld hl,0da80h		;aef0
	ld a,(0d808h)		;aef3
	bit 3,a		;aef6
	ld a,(hl)			;aef8
	jr nz,L_AF25		;aef9
	or a			;aefb
	jr z,L_AF60		;aefc
	cp 0ffh		;aefe
	jr nz,L_AF03		;af00
	inc a			;af02
L_AF03:
	sub c			;af03
	and b			;af04
	ld (hl),a			;af05
	ex de,hl			;af06
	ld a,c			;af07
	srl a		;af08
	ld c,a			;af0a
	dec a			;af0b
	cpl			;af0c
	ld b,a			;af0d
	ld a,(hl)			;af0e
	sub c			;af0f
	and b			;af10
	cp 038h		;af11
	jr nc,L_AF19		;af13
	xor a			;af15
	ld (de),a			;af16
	ld a,038h		;af17
L_AF19:
	ld (hl),a			;af19
	ld (0d875h),a		;af1a
	add a,004h		;af1d
	ld (0d879h),a		;af1f
	ex de,hl			;af22
	jr L_AF60		;af23
L_AF25:
	ld a,(0da87h)		;af25
	neg		;af28
	cp (hl)			;af2a
	jr z,L_AF60		;af2b
	jr nc,L_AF32		;af2d
	ld (hl),a			;af2f
	jr L_AF36		;af30
L_AF32:
	ld a,(hl)			;af32
	add a,c			;af33
	and b			;af34
	ld (hl),a			;af35
L_AF36:
	ex de,hl			;af36
	ld a,c			;af37
	srl a		;af38
	ld c,a			;af3a
	dec a			;af3b
	cpl			;af3c
	ld b,a			;af3d
	ld a,(hl)			;af3e
	add a,c			;af3f
	and b			;af40
	ld b,a			;af41
	ld a,(0da87h)		;af42
	neg		;af45
	srl a		;af47
	add a,038h		;af49
	cp b			;af4b
	jr c,L_AF4F		;af4c
	ld a,b			;af4e
L_AF4F:
	ld (hl),a			;af4f
	ld (0d875h),a		;af50
	add a,004h		;af53
	ld (0d879h),a		;af55
	ex de,hl			;af58
	ld a,(hl)			;af59
	or a			;af5a
	jr nz,L_AF60		;af5b
	ld a,0ffh		;af5d
	ld (hl),a			;af5f
L_AF60:
	call L_B19D		;af60
	call L_B21B		;af63
	ld c,(hl)			;af66
	call L_AF87		;af67
	ld hl,038c4h		;af6a
	push hl			;af6d
	ld hl,0da80h		;af6e
	ld a,(hl)			;af71
	and 0fch		;af72
	rrca			;af74
	rrca			;af75
	ld l,a			;af76
L_AF77:
	call L_A978		;af77
	pop hl			;af7a
	ld (0dbf0h),de		;af7b
	ld de,0dbf0h		;af7f
	ld b,003h		;af82
	jp L_43DC		;af84
L_AF87:
	ld a,04dh		;af87
	bit 7,c		;af89
	jr z,L_AF93		;af8b
	ld a,c			;af8d
	neg		;af8e
	ld c,a			;af90
	ld a,04ch		;af91
L_AF93:
	ld hl,03962h		;af93
	call 0004dh		;af96   ; BIOS WRTVRM - Writes data in VRAM
	ld hl,03965h		;af99
	push hl			;af9c
	ld l,c			;af9d
	jr L_AF77		;af9e
L_AFA0:
	call L_ACEA		;afa0
	xor a			;afa3
	ld (0da80h),a		;afa4
	call L_B19D		;afa7
	call L_B21B		;afaa
	ld a,038h		;afad
	ld (0d871h),a		;afaf
	ld (0d875h),a		;afb2
	add a,004h		;afb5
	ld (0d879h),a		;afb7
	ld hl,0da86h		;afba
	ld (hl),003h		;afbd
	call L_AEB4		;afbf
L_AFC2:
	ld hl,0d8fah		;afc2
	inc (hl)			;afc5
	ret			;afc6
L_AFC7:
	ld a,(0da80h)		;afc7
	ld (0da8ah),a		;afca
	call L_B0AB		;afcd
	ld hl,0da80h		;afd0
	inc (hl)			;afd3
	inc (hl)			;afd4
	jr z,L_AFE6		;afd5
	ld a,002h		;afd7
	ld c,a			;afd9
	dec a			;afda
	cpl			;afdb
	ld b,a			;afdc
	ld de,0d871h		;afdd
	ld hl,0da80h		;afe0
	jp L_AF36		;afe3
L_AFE6:
	call L_AF60		;afe6
	ld a,002h		;afe9
	call L_BEB1		;afeb
	call L_AFA0		;afee
	ld hl,0da86h		;aff1
	ld (hl),003h		;aff4
	jp L_AEB4		;aff6
L_AFF9:
	xor a			;aff9
	ld (0db17h),a		;affa
	call L_ADDB		;affd
	inc hl			;b000
	ld a,(hl)			;b001
	ld (0dc01h),a		;b002
	call L_49C7		;b005
	call L_43B0		;b008
	ret p			;b00b
	call L_B32E		;b00c
	call L_B3A6		;b00f
	xor a			;b012
	ld (0d870h),a		;b013
	ld hl,0b1cdh		;b016
	ld de,0d870h		;b019
	ld bc,0000ch		;b01c
	ldir		;b01f
	call L_B335		;b021
	ld de,0874dh		;b024
	call L_4352		;b027
	ld de,08799h		;b02a
	call L_4352		;b02d
	ld de,087a0h		;b030
	call L_4352		;b033
	ld hl,02600h		;b036
	ld a,000h		;b039
	ld bc,00200h		;b03b
	call L_4316		;b03e
	ld hl,02c00h		;b041
	ld a,000h		;b044
	ld bc,00200h		;b046
	call 00056h		;b049   ; BIOS FILVRM - Fills VRAM with value
	ld de,08815h		;b04c
	call L_4352		;b04f
	ld hl,00600h		;b052
	ld bc,00200h		;b055
	ld a,081h		;b058
	call L_4316		;b05a
	ld hl,00c00h		;b05d
	ld bc,00200h		;b060
	ld a,081h		;b063
	call 00056h		;b065   ; BIOS FILVRM - Fills VRAM with value
	ld hl,00e00h		;b068
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
	ld hl,03888h		;b07d
	ld de,0b1e4h		;b080
L_B083:
	ld a,(de)			;b083
	cp 0ffh		;b084
	jr z,L_B0A2		;b086
	push de			;b088
L_B089:
	ld b,010h		;b089
L_B08B:
	push bc			;b08b
	ld bc,00001h		;b08c
	call 00056h		;b08f   ; BIOS FILVRM - Fills VRAM with value
	inc hl			;b092
	inc a			;b093
	pop bc			;b094
	djnz L_B08B		;b095
	ld de,00010h		;b097
	add hl,de			;b09a
	or a			;b09b
	jr nz,L_B089		;b09c
	pop de			;b09e
	inc de			;b09f
	jr L_B083		;b0a0
L_B0A2:
	call L_B32A		;b0a2
	call L_49C4		;b0a5
	jp L_AFC2		;b0a8
L_B0AB:
	ld a,(0da8ah)		;b0ab
	call L_B1A0		;b0ae
	ex de,hl			;b0b1
	ld a,(0da8ah)		;b0b2
	srl a		;b0b5
	ld c,a			;b0b7
	and 007h		;b0b8
	ld hl,0b1d9h		;b0ba
	call hl_mas_a		;b0bd
	ld a,(hl)			;b0c0
	ld hl,0da81h		;b0c1
	ld (hl),a			;b0c4
	inc hl			;b0c5
	ld a,040h		;b0c6
	add a,c			;b0c8
	ld (hl),a			;b0c9
	ld b,003h		;b0ca
	inc e			;b0cc
	inc e			;b0cd
L_B0CE:
	ld a,(de)			;b0ce
	call L_B207		;b0cf
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
	ld a,(0da8ah)		;b0dd
	or a			;b0e0
	jr z,L_B0E9		;b0e1
	inc a			;b0e3
	jr nz,L_B0EA		;b0e4
	ld e,d			;b0e6
	jr L_B0EA		;b0e7
L_B0E9:
	ld c,d			;b0e9
L_B0EA:
	ld a,c			;b0ea
	cp d			;b0eb
	jr nc,L_B0FE		;b0ec
	cp e			;b0ee
	jr nc,L_B0F9		;b0ef
	ld (hl),a			;b0f1
	inc hl			;b0f2
	ld a,d			;b0f3
	cp e			;b0f4
	jr c,L_B10B		;b0f5
	jr L_B108		;b0f7
L_B0F9:
	ld (hl),e			;b0f9
	inc hl			;b0fa
	ld (hl),d			;b0fb
	jr L_B111		;b0fc
L_B0FE:
	ld a,d			;b0fe
	cp e			;b0ff
	jr nc,L_B10E		;b100
	ld (hl),a			;b102
	inc hl			;b103
	ld a,c			;b104
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
	ld a,(hl)			;b111
	dec hl			;b112
	ld c,(hl)			;b113
	sub c			;b114
	inc hl			;b115
	ld (hl),a			;b116
	dec hl			;b117
	dec hl			;b118
	ld a,(hl)			;b119
	and 0f8h		;b11a
	rrca			;b11c
	rrca			;b11d
	rrca			;b11e
	add a,080h		;b11f
	ld l,a			;b121
	ld h,038h		;b122
	call 00050h		;b124   ; BIOS SETRD - Enables VDP to read
	ld a,h			;b127
	and 003h		;b128
	ld de,0b1e1h		;b12a
	call de_mas_a		;b12d
	ld a,(de)			;b130
	ld h,a			;b131
	ld l,000h		;b132
	ld d,l			;b134
	ld a,(00006h)		;b135
	ld c,a			;b138
	in e,(c)		;b139
	ld b,003h		;b13b
L_B13D:
	sla e		;b13d
	rl d		;b13f
	djnz L_B13D		;b141
	add hl,de			;b143
	push hl			;b144
	ld b,010h		;b145
	ld de,0da00h		;b147
L_B14A:
	call 00050h		;b14a   ; BIOS SETRD - Enables VDP to read
	push bc			;b14d
	ld b,008h		;b14e
L_B150:
	in a,(c)		;b150
	ld (de),a			;b152
	inc de			;b153
	djnz L_B150		;b154
	call L_B1AE		;b156
	pop bc			;b159
	djnz L_B14A		;b15a
	ld hl,0da00h		;b15c
	ld de,0da81h		;b15f
	ld b,080h		;b162
L_B164:
	ld a,(de)			;b164
	cpl			;b165
	and (hl)			;b166
	ld (hl),a			;b167
	inc hl			;b168
	djnz L_B164		;b169
	ex de,hl			;b16b
	ld b,(hl)			;b16c
	inc hl			;b16d
	inc hl			;b16e
	inc hl			;b16f
	ld c,(hl)			;b170
	dec hl			;b171
	ld de,0da00h		;b172
	push de			;b175
	ld a,(hl)			;b176
	sub 020h		;b177
	call de_mas_a		;b179
L_B17C:
	ld a,(de)			;b17c
	or b			;b17d
	ld (de),a			;b17e
	ld a,c			;b17f
	or a			;b180
	jr z,L_B18B		;b181
	dec c			;b183
	ld a,c			;b184
	or a			;b185
	jr z,L_B18B		;b186
	inc de			;b188
	jr L_B17C		;b189
L_B18B:
	pop de			;b18b
	pop hl			;b18c
	ld b,010h		;b18d
L_B18F:
	push bc			;b18f
	ld bc,00008h		;b190
	call L_42FF		;b193
	call L_B1AE		;b196
	pop bc			;b199
	djnz L_B18F		;b19a
	ret			;b19c
L_B19D:
	ld a,(0da80h)		;b19d
L_B1A0:
	ld b,a			;b1a0
	ld a,(0db00h)		;b1a1
L_B1A4:
	ld hl,0c000h		;b1a4
	add a,h			;b1a7
	ld h,a			;b1a8
	ld a,b			;b1a9
	call hl_mas_a		;b1aa
	ret			;b1ad
L_B1AE:
	push de			;b1ae
	ld a,l			;b1af
	cp 080h		;b1b0
	jr c,L_B1C7		;b1b2
	ld a,h			;b1b4
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


L_B1E8:
	ld a,(0da8dh)		;b1e8
	or a			;b1eb
	ret nz			;b1ec
	ld hl,0db00h		;b1ed
	ld a,(0d8f1h)		;b1f0
	cp 043h		;b1f3
	jr z,L_B1FE		;b1f5
	cp 044h		;b1f7
	jr nz,L_B205		;b1f9
	dec (hl)			;b1fb
	jr L_B1FF		;b1fc
L_B1FE:
	inc (hl)			;b1fe
L_B1FF:
	ld a,(hl)			;b1ff
	and 00fh		;b200
	ld (hl),a			;b202
	scf			;b203
	ret			;b204
L_B205:
	xor a			;b205
	ret			;b206
L_B207:
	or a			;b207
	jp m,L_B214		;b208
	srl a		;b20b
	ld c,a			;b20d
	ld a,040h		;b20e
	sub c			;b210
	add a,020h		;b211
	ret			;b213
L_B214:
	neg		;b214
	srl a		;b216
	add a,060h		;b218
	ret			;b21a
L_B21B:
	ld a,(hl)			;b21b
	call L_B207		;b21c
	sub 004h		;b21f
	ld (0d878h),a		;b221
	ret			;b224
L_B225:
	ld hl,0da88h		;b225
	ld a,(0da87h)		;b228
	add a,(hl)			;b22b
	ld (hl),a			;b22c
	inc hl			;b22d
	dec (hl)			;b22e
	jp nz,L_B241		;b22f
	ei			;b232
	ret			;b233
L_B234:
	pop hl			;b234
	ret			;b235
L_B236:
	ld a,002h		;b236
	ld (0da89h),a		;b238
	ld a,(0da80h)		;b23b
	ld (0da88h),a		;b23e
L_B241:
	ld a,(0da87h)		;b241
	ld (0da8eh),a		;b244
	inc a			;b247
	ld (0dbf0h),a		;b248
L_B24B:
	call lee_teclas		;b24b
	di			;b24e
	ld a,(0d807h)		;b24f
	and 003h		;b252
	jr nz,L_B234		;b254
	ld a,(0da88h)		;b256
	call L_B1A0		;b259
	ld de,0dbf0h		;b25c
	ex de,hl			;b25f
	dec (hl)			;b260
	jr z,L_B225		;b261
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
	call L_B308		;b27f
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
	call L_ADC0		;b291
	ld (0dbf6h),de		;b294
	exx			;b298
	ex de,hl			;b299
	ld a,(hl)			;b29a
	call L_B31C		;b29b
	ld (de),a			;b29e
	ld a,(0da8eh)		;b29f
	ld c,a			;b2a2
	ld a,l			;b2a3
	sub c			;b2a4
	ld l,a			;b2a5
	ld a,(hl)			;b2a6
	call L_B31C		;b2a7
	ex de,hl			;b2aa
	ld b,000h		;b2ab
	cp (hl)			;b2ad
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
	call L_B308		;b2c9
	ld a,e			;b2cc
	ex de,hl			;b2cd
	ld bc,00010h		;b2ce
	call L_ADC0		;b2d1
	ld a,e			;b2d4
	exx			;b2d5
	ld c,a			;b2d6
	ld a,(0da8ch)		;b2d7
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
	ld (hl),a			;b2e4
	ex af,af'			;b2e5
	dec hl			;b2e6
	dec hl			;b2e7
	ld c,(hl)			;b2e8
	ld a,(0da8eh)		;b2e9
	sub c			;b2ec
	ex de,hl			;b2ed
	add a,l			;b2ee
	ld l,a			;b2ef
	ex af,af'			;b2f0
	ld b,a			;b2f1
	cp 080h		;b2f2
	jr nc,L_B2FB		;b2f4
	ld a,080h		;b2f6
	sub b			;b2f8
	jr L_B2FF		;b2f9
L_B2FB:
	sub 080h		;b2fb
	neg		;b2fd
L_B2FF:
	cp 080h		;b2ff
	jr nz,L_B304		;b301
	inc a			;b303
L_B304:
	ld (hl),a			;b304
	jp L_B24B		;b305
L_B308:
	ld hl,00000h		;b308
	ld a,010h		;b30b
L_B30D:
	add hl,hl			;b30d
	ex de,hl			;b30e
	adc hl,hl		;b30f
	ex de,hl			;b311
	jr nc,L_B318		;b312
	add hl,bc			;b314
	jr nc,L_B318		;b315
	inc de			;b317
L_B318:
	dec a			;b318
	jr nz,L_B30D		;b319
	ret			;b31b
L_B31C:
	or a			;b31c
	jp m,L_B325		;b31d
	ld c,a			;b320
	ld a,080h		;b321
	sub c			;b323
	ret			;b324
L_B325:
	neg		;b325
	add a,080h		;b327
	ret			;b329
L_B32A:
	ld b,0e2h		;b32a
	jr L_B330		;b32c
L_B32E:
	ld b,0a2h		;b32e
L_B330:
	ld c,001h		;b330
	jp 00047h		;b332   ; BIOS WRTVDP - Writes data in the VDP-register
L_B335:
	ld de,087dbh		;b335
	call L_4352		;b338
	call L_B392		;b33b
L_B33E:
	call L_48C4		;b33e
	ld de,09e37h		;b341
	ld hl,02080h		;b344
	ld bc,00050h		;b347
	call L_4303		;b34a
	ld b,00ah		;b34d
	ld hl,00080h		;b34f
L_B352:
	push bc			;b352
	ld de,09e87h		;b353
	ld a,(0d8f4h)		;b356
	or a			;b359
	jr z,L_B35F		;b35a
	ld de,09e8fh		;b35c
L_B35F:
	ld bc,00008h		;b35f
	push hl			;b362
	call L_4303		;b363
	pop hl			;b366
	ld de,00008h		;b367
	add hl,de			;b36a
	pop bc			;b36b
	djnz L_B352		;b36c
	ld hl,02200h		;b36e
	ld de,082a5h		;b371
	call L_4327		;b374
	ld de,084ebh		;b377
	ld hl,00008h		;b37a
	call L_4327		;b37d
	ld de,08531h		;b380
	ld hl,000d8h		;b383
	call L_4327		;b386
	ld de,08552h		;b389
	ld hl,001d8h		;b38c
	jp L_4327		;b38f
L_B392:
	ld de,0446eh		;b392
	ld hl,02100h		;b395
	call L_4327		;b398
	ld hl,00100h		;b39b
	ld a,0f0h		;b39e
	ld bc,000b8h		;b3a0
	jp L_4316		;b3a3
L_B3A6:
	ld hl,0d870h		;b3a6
	ld bc,00020h		;b3a9
	jp L_43A8		;b3ac
L_B3AF:
	ld b,008h		;b3af
	ld a,(0d803h)		;b3b1
	and 010h		;b3b4
	jr nz,L_B3BA		;b3b6
	ld b,004h		;b3b8
L_B3BA:
	ld a,b			;b3ba
	ld (0d873h),a		;b3bb
	ld a,(0d8fah)		;b3be
	dec a			;b3c1
	jp z,L_B509		;b3c2
	jp m,L_B4D4		;b3c5
	cp 001h		;b3c8
	jp z,L_B4C1		;b3ca
	ld a,(0d8f1h)		;b3cd
	cp 040h		;b3d0
	jp nz,L_B458		;b3d2
	ld hl,0d922h		;b3d5
	ld de,0d923h		;b3d8
	push hl			;b3db
	ld a,(hl)			;b3dc
	inc de			;b3dd
	ld hl,0397ch		;b3de
	or a			;b3e1
	jr nz,L_B3F0		;b3e2
	push de			;b3e4
	ld de,0b5c3h		;b3e5
	call L_4337		;b3e8
	pop de			;b3eb
	dec de			;b3ec
	ld hl,03938h		;b3ed
L_B3F0:
	ld a,(0d921h)		;b3f0
	ld (de),a			;b3f3
	ld a,(0d920h)		;b3f4
	call L_B53D		;b3f7
	pop hl			;b3fa
	inc (hl)			;b3fb
	ld a,(hl)			;b3fc
	cp 002h		;b3fd
	ret nz			;b3ff
	ld hl,0d000h		;b400
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
	ld hl,0d000h		;b414
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
	ld bc,00020h		;b429
	ldir		;b42c
	ld b,000h		;b42e
	ld de,0d923h		;b430
	ld a,(de)			;b433
	call L_B1A4		;b434
	push hl			;b437
	inc de			;b438
	ld a,(de)			;b439
	call L_B1A4		;b43a
	ex de,hl			;b43d
	pop hl			;b43e
	ld bc,00100h		;b43f
	ldir		;b442
	ld a,002h		;b444
	call L_BEB1		;b446
	ld hl,0d922h		;b449
	ld b,003h		;b44c
L_B44E:
	ld (hl),000h		;b44e
	inc hl			;b450
	djnz L_B44E		;b451
	call L_B509		;b453
	dec (hl)			;b456
	ret			;b457
L_B458:
	ld de,0d921h		;b458
	ld a,(0d808h)		;b45b
	and 003h		;b45e
	ret z			;b460
	and 001h		;b461
	jr z,L_B47B		;b463
	ld b,0f0h		;b465
	ld a,(de)			;b467
	or a			;b468
	ret z			;b469
	push af			;b46a
	ld a,001h		;b46b
	call L_BEB1		;b46d
	pop af			;b470
	dec a			;b471
	ld (de),a			;b472
	dec de			;b473
	ld a,(de)			;b474
	sub 001h		;b475
	daa			;b477
	ld (de),a			;b478
	jr L_B499		;b479
L_B47B:
	ld a,(de)			;b47b
	cp 00fh		;b47c
	ret nc			;b47e
	push af			;b47f
	ld a,001h		;b480
	call L_BEB1		;b482
	pop af			;b485
	inc a			;b486
	ld (de),a			;b487
	dec de			;b488
	ld a,(de)			;b489
	add a,001h		;b48a
	daa			;b48c
	ld (de),a			;b48d
	ld b,010h		;b48e
	cp 009h		;b490
	jr nz,L_B4A8		;b492
	ld hl,0b565h		;b494
	jr L_B4A0		;b497
L_B499:
	cp 008h		;b499
	jr nz,L_B4A8		;b49b
	ld hl,0b55dh		;b49d
L_B4A0:
	ld de,0d870h		;b4a0
	ld bc,00008h		;b4a3
	ldir		;b4a6
L_B4A8:
	ld hl,0d870h		;b4a8
	ld a,b			;b4ab
	add a,(hl)			;b4ac
	ld (hl),a			;b4ad
	inc hl			;b4ae
	inc hl			;b4af
	inc hl			;b4b0
	inc hl			;b4b1
	ld (hl),a			;b4b2
	ret			;b4b3
L_B4B4:
	ld b,a			;b4b4
	ld hl,0d000h		;b4b5
	ld bc,00020h		;b4b8
	xor a			;b4bb
L_B4BC:
	adc hl,bc		;b4bc
	djnz L_B4BC		;b4be
	ret			;b4c0
L_B4C1:
	ld hl,0b555h		;b4c1
	ld de,0d870h		;b4c4
	ld bc,00008h		;b4c7
	ldir		;b4ca
	ld de,0b5a1h		;b4cc
	call L_4337		;b4cf
	jr L_B538		;b4d2
L_B4D4:
	call L_B76E		;b4d4
	ret p			;b4d7
	xor a			;b4d8
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
	ld de,0b587h		;b4ec
	ld a,(0d8f4h)		;b4ef
	cp 006h		;b4f2
	jr nz,L_B4F9		;b4f4
	ld de,0b56dh		;b4f6
L_B4F9:
	call L_4352		;b4f9
	ld hl,0d920h		;b4fc
	ld b,004h		;b4ff
	ld (hl),001h		;b501
L_B503:
	inc hl			;b503
	ld (hl),000h		;b504
	djnz L_B503		;b506
	ret			;b508
L_B509:
	xor a			;b509
	inc a			;b50a
	ld de,0d019h		;b50b
	ld hl,038a2h		;b50e
L_B511:
	push af			;b511
	call L_B53D		;b512
	inc hl			;b515
	ld a,096h		;b516
	call 0004dh		;b518   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;b51b
	call L_AD21		;b51c
	ld a,019h		;b51f
	call de_mas_a		;b521
	ld a,036h		;b524
	call hl_mas_a		;b526
	pop af			;b529
	add a,001h		;b52a
	daa			;b52c
	cp 009h		;b52d
	jr nz,L_B534		;b52f
	ld hl,038adh		;b531
L_B534:
	cp 017h		;b534
	jr c,L_B511		;b536
L_B538:
	ld hl,0d8fah		;b538
	inc (hl)			;b53b
	ret			;b53c
L_B53D:
	ld c,a			;b53d
	and 0f0h		;b53e
	jr z,L_B548		;b540
	rrca			;b542
	rrca			;b543
	rrca			;b544
	rrca			;b545
	add a,040h		;b546
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


L_B5C8:
	ld a,0d0h		;b5c8
	ld (0d870h),a		;b5ca
	ld (0d874h),a		;b5cd
	ld a,(0d8fah)		;b5d0
	dec a			;b5d3
	jp z,L_B509		;b5d4
	jp m,L_B4D4		;b5d7
	ret			;b5da
L_B5DB:
	ld b,008h		;b5db
	ld a,(0d803h)		;b5dd
	and 010h		;b5e0
	jr nz,L_B5E6		;b5e2
	ld b,000h		;b5e4
L_B5E6:
	ld a,(0db16h)		;b5e6
	dec a			;b5e9
	jr z,L_B5FB		;b5ea
	ld a,b			;b5ec
	ld (0d873h),a		;b5ed
	ld a,00fh		;b5f0
	ld (0d877h),a		;b5f2
	xor a			;b5f5
	ld (0d883h),a		;b5f6
	jr L_B606		;b5f9
L_B5FB:
	ld a,b			;b5fb
	ld (0d883h),a		;b5fc
	xor a			;b5ff
	ld (0d873h),a		;b600
	ld (0d877h),a		;b603
L_B606:
	ld a,(0d8fah)		;b606
	dec a			;b609
	jp m,L_B76E		;b60a
	ld a,(0d812h)		;b60d
	or a			;b610
	ret nz			;b611
	ld a,(0db0bh)		;b612
	or a			;b615
	jp nz,L_B851		;b616
	ld hl,0db0ch		;b619
	ld a,(hl)			;b61c
	ld a,(0d806h)		;b61d
	ld b,a			;b620
	and 003h		;b621
	jr nz,L_B62D		;b623
	ld a,(0d8f1h)		;b625
	cp 040h		;b628
	jr z,L_B68F		;b62a
	ret			;b62c
L_B62D:
	ld a,001h		;b62d
	call L_BEB1		;b62f
	ld a,(0db0eh)		;b632
	ld c,a			;b635
	ld a,b			;b636
	and 002h		;b637
	jr z,L_B65B		;b639
	inc (hl)			;b63b
	ld a,(hl)			;b63c
	cp 001h		;b63d
	jr nz,L_B648		;b63f
	ld a,(0d9deh)		;b641
	or a			;b644
	jr z,L_B648		;b645
	inc (hl)			;b647
L_B648:
	ld a,(hl)			;b648
	cp 004h		;b649
	jr nz,L_B653		;b64b
	bit 0,c		;b64d
	jr nz,L_B653		;b64f
	ld (hl),006h		;b651
L_B653:
	cp 00ah		;b653
	jr c,L_B67C		;b655
	ld (hl),000h		;b657
	jr L_B67C		;b659
L_B65B:
	dec (hl)			;b65b
	jp p,L_B663		;b65c
	ld (hl),009h		;b65f
	jr L_B67C		;b661
L_B663:
	ld a,(hl)			;b663
	cp 001h		;b664
	jr nz,L_B671		;b666
	ld a,(0d9deh)		;b668
	or a			;b66b
	jr z,L_B671		;b66c
	dec (hl)			;b66e
	jr L_B67C		;b66f
L_B671:
	ld a,(hl)			;b671
	cp 005h		;b672
	jr nz,L_B67C		;b674
	bit 0,c		;b676
	jr nz,L_B67C		;b678
	ld (hl),003h		;b67a
L_B67C:
	ld a,(hl)			;b67c
	ld b,a			;b67d
	ld de,0b729h		;b67e
	call de_mas_a		;b681
	ld a,(de)			;b684
	ld hl,0d870h		;b685
	ld (hl),a			;b688
	inc hl			;b689
	inc hl			;b68a
	inc hl			;b68b
	inc hl			;b68c
	ld (hl),a			;b68d
	ret			;b68e
L_B68F:
	ld hl,0db0ch		;b68f
	ld a,(hl)			;b692
	or a			;b693
	jr nz,L_B6A0		;b694
	ld a,002h		;b696
	ld (hl),a			;b698
	call L_B6A0		;b699
	xor a			;b69c
	ld (0db0ch),a		;b69d
L_B6A0:
	ld b,a			;b6a0
	add a,a			;b6a1
	ld hl,0b733h		;b6a2
	call hl_mas_a		;b6a5
	ld de,0db0eh		;b6a8
	ld a,(de)			;b6ab
	and (hl)			;b6ac
	inc hl			;b6ad
	or (hl)			;b6ae
	ld (de),a			;b6af
	ld a,b			;b6b0
	cp 002h		;b6b1
	jr nc,L_B6CF		;b6b3
	or a			;b6b5
	jr nz,L_B6BD		;b6b6
	call L_B70B		;b6b8
	jr L_B6CF		;b6bb
L_B6BD:
	ld hl,03979h		;b6bd
	ld de,0b74dh		;b6c0
	call L_4358		;b6c3
	ld hl,03999h		;b6c6
	ld de,0b753h		;b6c9
	call L_4358		;b6cc
L_B6CF:
	ld c,009h		;b6cf
	ld a,(0db0ch)		;b6d1
	cp c			;b6d4
	jr c,L_B6E1		;b6d5
	ld a,001h		;b6d7
	ld (0db0bh),a		;b6d9
	dec a			;b6dc
	ld (0db16h),a		;b6dd
	ret			;b6e0
L_B6E1:
	ld bc,00306h		;b6e1
	cp c			;b6e4
	jr nc,L_B6F0		;b6e5
	ld bc,00402h		;b6e7
	cp c			;b6ea
	jr nc,L_B6F0		;b6eb
	ld bc,00200h		;b6ed
L_B6F0:
	ld a,c			;b6f0
	call L_B716		;b6f1
	ld a,097h		;b6f4
L_B6F6:
	call 0004dh		;b6f6   ; BIOS WRTVRM - Writes data in VRAM
	ld de,00020h		;b6f9
	add hl,de			;b6fc
	djnz L_B6F6		;b6fd
	ld a,(0db0ch)		;b6ff
	call L_B716		;b702
	ld a,098h		;b705
	call 0004dh		;b707   ; BIOS WRTVRM - Writes data in VRAM
	ret			;b70a
L_B70B:
	ld hl,03978h		;b70b
	call L_B722		;b70e
	ld hl,03998h		;b711
	jr L_B722		;b714
L_B716:
	add a,a			;b716
	ld hl,0b75ah		;b717
	call hl_mas_a		;b71a
	ld e,(hl)			;b71d
	inc hl			;b71e
	ld d,(hl)			;b71f
	ex de,hl			;b720
	ret			;b721
L_B722:
	ld de,0b747h		;b722
	call L_4358		;b725
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


L_B76E:
	call L_49C7		;b76e
	call L_43B0		;b771
	ret p			;b774
	call L_B32E		;b775
	ld a,(0d8f4h)		;b778
	cp 005h		;b77b
	jr z,L_B783		;b77d
	cp 006h		;b77f
	jr nz,L_B78D		;b781
L_B783:
	ld a,0d0h		;b783
	ld (0d870h),a		;b785
	ld (0d874h),a		;b788
	jr L_B798		;b78b
L_B78D:
	ld hl,0ba6ch		;b78d
	ld de,0d870h		;b790
	ld bc,00008h		;b793
	ldir		;b796
L_B798:
	call L_B335		;b798
	ld de,09ac5h		;b79b
	ld hl,02458h		;b79e
	call L_4327		;b7a1
	ld de,09c63h		;b7a4
	ld hl,00458h		;b7a7
	call L_4327		;b7aa
	ld de,09d74h		;b7ad
	call L_4352		;b7b0
	ld de,0b841h		;b7b3
	call L_4352		;b7b6
	call L_B80D		;b7b9
	ld a,(0d9deh)		;b7bc
	or a			;b7bf
	jr z,L_B7CB		;b7c0
	call L_B70B		;b7c2
	ld hl,038f8h		;b7c5
	call L_B722		;b7c8
L_B7CB:
	call L_B32A		;b7cb
	call L_49C4		;b7ce
	ld hl,0db0fh		;b7d1
	ld bc,00006h		;b7d4
	ld d,h			;b7d7
	ld e,l			;b7d8
	inc e			;b7d9
	ld (hl),020h		;b7da
	ldir		;b7dc
	xor a			;b7de
	ld (0db0bh),a		;b7df
	ld (0db16h),a		;b7e2
	ld (0db03h),a		;b7e5
	inc a			;b7e8
	ld (0db17h),a		;b7e9
	ld a,009h		;b7ec
	ld (0db0ch),a		;b7ee
	ld hl,0b832h		;b7f1
	ld de,0d9a6h		;b7f4
	ld bc,0000fh		;b7f7
	ldir		;b7fa
	ld hl,0d9a6h		;b7fc
	ld (0f323h),hl		;b7ff
	call L_B808		;b802
	xor a			;b805
	dec a			;b806
	ret			;b807
L_B808:
	ld hl,0d8fah		;b808
	inc (hl)			;b80b
	ret			;b80c
L_B80D:
	ld a,(0db0eh)		;b80d
	and 001h		;b810
	call L_B82B		;b812
	ld a,(0db0eh)		;b815
	ld c,002h		;b818
	call L_B826		;b81a
	ld c,006h		;b81d
	ld a,(0db0eh)		;b81f
	srl a		;b822
	srl a		;b824
L_B826:
	srl a		;b826
	and 003h		;b828
	add a,c			;b82a
L_B82B:
	ld (0db0ch),a		;b82b
	call L_B6A0		;b82e
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


L_B834:
	ld h,040h		;b834
	ld a,(0d855h)		;b836
	push bc			;b839
	call 00024h		;b83a   ; BIOS ENASLT - Switches to specified slot and page definitively
	pop bc			;b83d
	jp L_50DE		;b83e

; ----------------------------------------------------------------------
; DATOS file_flecha: flujo RLE de 0x4352 (0xB7B6)
;   0xb841..0xb851  (16 bytes)
DATA_file_flecha:
	defb 031h,038h,087h,09dh,054h,09eh,054h,09fh,054h,09ch,080h,04ah,038h,00ch,04bh,000h	; b841  18..T.T.T..J8.K.

; ======================================================================
; CODIGO 0xb851..0xba6c  (539 bytes)
; ======================================================================


L_B851:
	ld hl,0db16h		;b851
	ld a,(0db0eh)		;b854
	rrca			;b857
	rrca			;b858
	rrca			;b859
	and 003h		;b85a
	ld c,a			;b85c
	dec a			;b85d
	jr z,L_B868		;b85e
	jp p,L_B873		;b860
	ld de,01200h		;b863
	jr L_B86B		;b866
L_B868:
	ld de,000b0h		;b868
L_B86B:
	ld a,e			;b86b
	ld (0dcfeh),a		;b86c
	ld a,d			;b86f
	ld (0dcffh),a		;b870
L_B873:
	ld a,(0db0eh)		;b873
	bit 0,a		;b876
	jp nz,L_B916		;b878
	srl a		;b87b
	bit 0,a		;b87d
	jr z,L_B8CF		;b87f
	ld a,(hl)			;b881
	dec a			;b882
	jr z,L_B8AD		;b883
	jp m,L_B8B7		;b885
	call L_BA66		;b888
	ld de,0bb47h		;b88b
	call L_4337		;b88e
	ld b,007h		;b891
	ld hl,0db0fh		;b893
L_B896:
	ld a,(hl)			;b896
	cp 020h		;b897
	jr nz,L_B8A0		;b899
	inc hl			;b89b
	djnz L_B896		;b89c
	jr L_B8A5		;b89e
L_B8A0:
	call L_51DB		;b8a0
	jr c,L_B8C2		;b8a3
L_B8A5:
	call L_4D8C		;b8a5
	jp c,L_BA4E		;b8a8
	jr L_B8EA		;b8ab
L_B8AD:
	ld a,(0d8f1h)		;b8ad
	cp 040h		;b8b0
	jr z,L_B911		;b8b2
	jp L_A742		;b8b4
L_B8B7:
	call L_BA10		;b8b7
	ld de,0bafah		;b8ba
	call L_4337		;b8bd
	jr L_B911		;b8c0
L_B8C2:
	ld de,05183h		;b8c2
	ld hl,03a06h		;b8c5
	ld c,0ffh		;b8c8
	call L_433F		;b8ca
	jr L_B8F8		;b8cd
L_B8CF:
	ld a,(hl)			;b8cf
	dec a			;b8d0
	jr z,L_B8AD		;b8d1
	jp m,L_B908		;b8d3
	call L_BA66		;b8d6
	ld de,0bb3bh		;b8d9
	call L_4337		;b8dc
	call L_51DB		;b8df
	jr c,L_B8C2		;b8e2
	call L_4D04		;b8e4
	jp c,L_BA4E		;b8e7
L_B8EA:
	call L_BA66		;b8ea
	ld de,0bb54h		;b8ed
	call L_4337		;b8f0
	ld a,002h		;b8f3
	call L_BEB1		;b8f5
L_B8F8:
	xor a			;b8f8
	ld (0db0bh),a		;b8f9
	ld (0db16h),a		;b8fc
	ld (0db03h),a		;b8ff
	ld a,009h		;b902
	ld (0db0ch),a		;b904
	ret			;b907
L_B908:
	call L_BA10		;b908
	ld de,0bb06h		;b90b
	call L_4337		;b90e
L_B911:
	ld hl,0db16h		;b911
	inc (hl)			;b914
	ret			;b915
L_B916:
	rrca			;b916
	and 003h		;b917
	cp 001h		;b919
	jr z,L_B98B		;b91b
	jp c,L_B9BB		;b91d
	cp 002h		;b920
	jp z,L_B9E0		;b922
	ld a,(hl)			;b925
	dec a			;b926
	jr nz,L_B938		;b927
	call L_4FF4		;b929
	jr c,L_B92F		;b92c
	ret			;b92e
L_B92F:
	call L_BA42		;b92f
	call L_B976		;b932
	jp L_B8EA		;b935
L_B938:
	ld a,c			;b938
	add a,021h		;b939
	ld (0db18h),a		;b93b
	call L_B976		;b93e
	ld de,0ba86h		;b941
	call L_434E		;b944
	ld de,0bb1eh		;b947
	call L_434E		;b94a
	ld de,0bb31h		;b94d
	call L_4337		;b950
	call L_BA66		;b953
	ld de,0bae6h		;b956
	call L_4337		;b959
	call L_BA42		;b95c
	ld a,0d0h		;b95f
	ld (0d880h),a		;b961
	call L_4F4D		;b964
	jp c,L_B96D		;b967
	jp L_B911		;b96a
L_B96D:
	ld de,0bae6h		;b96d
	call L_434E		;b970
	jp L_BA5C		;b973
L_B976:
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
L_B98B:
	ld a,(hl)			;b98b
	dec a			;b98c
	jr z,L_B9A4		;b98d
	jp m,L_B9AF		;b98f
	call L_BA66		;b992
	ld de,0bb47h		;b995
	call L_4337		;b998
	call L_4ED1		;b99b
	jp c,L_BA5C		;b99e
	jp L_B8EA		;b9a1
L_B9A4:
	ld a,(0d8f1h)		;b9a4
	cp 040h		;b9a7
	jp z,L_B911		;b9a9
	jp L_A742		;b9ac
L_B9AF:
	call L_BA10		;b9af
	ld de,0bb12h		;b9b2
	call L_4337		;b9b5
	jp L_B911		;b9b8
L_B9BB:
	ld a,(hl)			;b9bb
	dec a			;b9bc
	jr z,L_B9A4		;b9bd
	jp m,L_B9D4		;b9bf
	call L_BA66		;b9c2
	ld de,0bb3bh		;b9c5
	call L_4337		;b9c8
	call L_4E89		;b9cb
	jp c,L_BA5C		;b9ce
	jp L_B8EA		;b9d1
L_B9D4:
	call L_BA10		;b9d4
	ld de,0bb1eh		;b9d7
	call L_4337		;b9da
	jp L_B911		;b9dd
L_B9E0:
	ld a,(hl)			;b9e0
	dec a			;b9e1
	jr z,L_B9F3		;b9e2
	jp m,L_B9FE		;b9e4
	call L_BA66		;b9e7
	call L_4F23		;b9ea
	jp c,L_BA5C		;b9ed
	jp L_B8EA		;b9f0
L_B9F3:
	ld a,(0d8f1h)		;b9f3
	cp 040h		;b9f6
	jp z,L_B911		;b9f8
	jp L_A742		;b9fb
L_B9FE:
	call L_BA10		;b9fe
	ld de,0bb1eh		;ba01
	call L_434E		;ba04
	ld de,0bb2ah		;ba07
	call L_4337		;ba0a
	jp L_B911		;ba0d
L_BA10:
	push bc			;ba10
	ld de,0ba86h		;ba11
	call L_434E		;ba14
	pop bc			;ba17
	ld a,c			;ba18
	add a,021h		;ba19
	ld (0db18h),a		;ba1b
	ld a,c			;ba1e
	add a,a			;ba1f
	ld hl,0ba80h		;ba20
	call hl_mas_a		;ba23
	ld e,(hl)			;ba26
	inc hl			;ba27
	ld d,(hl)			;ba28
	call L_4337		;ba29
	ld de,0babbh		;ba2c
	call L_4337		;ba2f
	call L_AD0A		;ba32
	ld hl,0d980h		;ba35
	ld bc,00025h		;ba38
	ld d,h			;ba3b
	ld e,l			;ba3c
	inc e			;ba3d
	ld (hl),000h		;ba3e
	ldir		;ba40
L_BA42:
	ld de,0d870h		;ba42
	ld hl,0ba6ch		;ba45
	ld bc,00014h		;ba48
	ldir		;ba4b
	ret			;ba4d
L_BA4E:
	ld de,0bb5bh		;ba4e
	push de			;ba51
	call L_BA66		;ba52
	pop de			;ba55
	call L_4337		;ba56
	call L_B8F8		;ba59
L_BA5C:
	ld a,002h		;ba5c
	call L_BEB1		;ba5e
	xor a			;ba61
	ld (0db0bh),a		;ba62
	ret			;ba65
L_BA66:
	ld de,0bad0h		;ba66
	jp L_434E		;ba69

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


L_BB6D:
	ld b,008h		;bb6d
	ld a,(0d803h)		;bb6f
	and 010h		;bb72
	jr nz,L_BB78		;bb74
	ld b,00fh		;bb76
L_BB78:
	ld a,b			;bb78
	ld (0d873h),a		;bb79
	ld a,(0d8fah)		;bb7c
	dec a			;bb7f
	jp m,L_BD27		;bb80
	ld a,(0d8f2h)		;bb83
	cp 032h		;bb86
	jr nz,L_BBA4		;bb88
	ld a,008h		;bb8a
	call 00141h		;bb8c   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 1,a		;bb8f
	ret nz			;bb91
	call L_4B21		;bb92
	call L_55DC		;bb95
	call L_BD33		;bb98
	ld hl,0d8fah		;bb9b
	dec (hl)			;bb9e
	ld a,002h		;bb9f
	jp L_BEB1		;bba1
L_BBA4:
	ld a,(0d8f1h)		;bba4
	or a			;bba7
	jp z,L_BC53		;bba8
	cp 016h		;bbab
	jp z,L_BC53		;bbad
	cp 031h		;bbb0
	jp nc,L_BC53		;bbb2
	dec a			;bbb5
	ld de,0d200h		;bbb6
	call de_mas_a		;bbb9
	ld a,(0d906h)		;bbbc
	ld (de),a			;bbbf
	ld a,(0d8f1h)		;bbc0
	dec a			;bbc3
	sla a		;bbc4
	ld de,0d230h		;bbc6
	call de_mas_a		;bbc9
	ld hl,0bd5dh		;bbcc
	ld a,(0d906h)		;bbcf
	or a			;bbd2
	jr z,L_BBE0		;bbd3
	ld a,(0d905h)		;bbd5
	sla a		;bbd8
	ld hl,05e29h		;bbda
	call hl_mas_a		;bbdd
L_BBE0:
	ld bc,00002h		;bbe0
	ldir		;bbe3
	ld a,002h		;bbe5
	call L_BEB1		;bbe7
	ld a,(0d8f1h)		;bbea
L_BBED:
	call L_BC3D		;bbed
	ld a,(de)			;bbf0
	or a			;bbf1
	jr nz,L_BC01		;bbf2
	ld de,0bdd9h		;bbf4
	call L_BC37		;bbf7
	ld bc,00020h		;bbfa
	add hl,bc			;bbfd
	jp L_BC37		;bbfe
L_BC01:
	ld a,(0d905h)		;bc01
	ld b,0ffh		;bc04
	ld de,0bdddh		;bc06
	ex de,hl			;bc09
L_BC0A:
	inc b			;bc0a
	cp (hl)			;bc0b
	inc hl			;bc0c
	jr nc,L_BC0A		;bc0d
	ex de,hl			;bc0f
	ld a,b			;bc10
	add a,a			;bc11
	push hl			;bc12
	ld hl,0bd5fh		;bc13
	call hl_mas_a		;bc16
	ld e,(hl)			;bc19
	inc hl			;bc1a
	ld d,(hl)			;bc1b
	pop hl			;bc1c
	ld a,(0d905h)		;bc1d
L_BC20:
	cp 00eh		;bc20
	jr c,L_BC28		;bc22
	sub 00eh		;bc24
	jr L_BC20		;bc26
L_BC28:
	sla a		;bc28
	call de_mas_a		;bc2a
	call L_BC37		;bc2d
	ld de,00020h		;bc30
	add hl,de			;bc33
	ld de,0bdd7h		;bc34
L_BC37:
	ld bc,00002h		;bc37
	jp L_42FF		;bc3a
L_BC3D:
	dec a			;bc3d
	push af			;bc3e
	sla a		;bc3f
	ld hl,0bde1h		;bc41
	call hl_mas_a		;bc44
	ld e,(hl)			;bc47
	inc hl			;bc48
	ld d,(hl)			;bc49
	ex de,hl			;bc4a
	pop af			;bc4b
	ld de,0d200h		;bc4c
	call de_mas_a		;bc4f
	ret			;bc52
L_BC53:
	ld hl,0d905h		;bc53
	ld a,(0d808h)		;bc56
	and 00ch		;bc59
	ret z			;bc5b
	and 004h		;bc5c
	jr nz,L_BC82		;bc5e
	ld a,030h		;bc60
	cp (hl)			;bc62
	ret z			;bc63
	ld a,001h		;bc64
	call L_BEB1		;bc66
	inc (hl)			;bc69
	ld a,(hl)			;bc6a
	call L_BCBD		;bc6b
	ld a,(hl)			;bc6e
	bit 0,a		;bc6f
	jr nz,L_BC7B		;bc71
	ld c,056h		;bc73
	ld de,0585ch		;bc75
	jp L_BCFB		;bc78
L_BC7B:
	ld c,01eh		;bc7b
	ld de,00004h		;bc7d
	jr $+123		;bc80
L_BC82:
	ld a,(hl)			;bc82
	or a			;bc83
	ret z			;bc84
	ld a,001h		;bc85
	call L_BEB1		;bc87
	dec (hl)			;bc8a
	ld a,(hl)			;bc8b
	call L_BCBD		;bc8c
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
L_BCA2:
	push hl			;bca2
	ld b,a			;bca3
	ld hl,0bcb6h		;bca4
L_BCA7:
	ld a,(hl)			;bca7
	inc hl			;bca8
	cp 0ffh		;bca9
	jr z,L_BCB3		;bcab
	cp b			;bcad
	jr nz,L_BCA7		;bcae
	pop hl			;bcb0
	scf			;bcb1
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


L_BCBD:
	push hl			;bcbd
	ld hl,0bccah		;bcbe
	call hl_mas_a		;bcc1
	ld a,(hl)			;bcc4
	ld (0d906h),a		;bcc5
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


L_BCFB:
	ld b,002h		;bcfb
	push hl			;bcfd
	ld hl,0d870h		;bcfe
L_BD01:
	ld (hl),c			;bd01
	inc hl			;bd02
	ld a,(hl)			;bd03
	add a,004h		;bd04
	ld (hl),a			;bd06
	inc hl			;bd07
	ld (hl),d			;bd08
	inc hl			;bd09
	inc hl			;bd0a
	ld a,e			;bd0b
	ld d,a			;bd0c
	djnz L_BD01		;bd0d
	pop hl			;bd0f
	ret			;bd10
L_BD11:
	ld b,002h		;bd11
	push hl			;bd13
	ld hl,0d870h		;bd14
L_BD17:
	ld (hl),c			;bd17
	inc hl			;bd18
	ld a,(hl)			;bd19
	sub 004h		;bd1a
	ld (hl),a			;bd1c
	inc hl			;bd1d
	ld (hl),d			;bd1e
	inc hl			;bd1f
	inc hl			;bd20
	ld a,e			;bd21
	ld d,a			;bd22
	djnz L_BD17		;bd23
	pop hl			;bd25
	ret			;bd26
L_BD27:
	ld a,(0d8f6h)		;bd27
	or a			;bd2a
	ret nz			;bd2b
	call L_49C7		;bd2c
	call L_43B0		;bd2f
	ret p			;bd32
L_BD33:
	call L_494E		;bd33
	call L_B392		;bd36
	call L_49C4		;bd39
	ld hl,0bd55h		;bd3c
	ld de,0d870h		;bd3f
	ld bc,00008h		;bd42
	ldir		;bd45
	xor a			;bd47
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


L_BE41:
	call L_437D		;be41
	ld hl,0d80bh		;be44
	inc (hl)			;be47
	ld a,(hl)			;be48
	and 003h		;be49
	ld de,0be5eh		;be4b
	call de_mas_a		;be4e
	ld a,(de)			;be51
	ld (0d8f4h),a		;be52
	xor a			;be55
	ld (0d8fah),a		;be56
	inc a			;be59
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


L_BE62:
	call L_47DB		;be62
	ld a,(0d803h)		;be65
	bit 0,a		;be68
	ret z			;be6a
	ld hl,0d80ch		;be6b
	inc (hl)			;be6e
	ret nz			;be6f
	xor a			;be70
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


L_BEA6:
	di			;bea6
	push hl			;bea7
	ld hl,0d802h		;bea8
	bit 6,(hl)		;beab
	jr z,L_BEBC		;bead
	jr L_BEB3		;beaf
L_BEB1:
	di			;beb1
	push hl			;beb2
L_BEB3:
	push de			;beb3
	push bc			;beb4
	push af			;beb5
	call L_BEBF		;beb6
	pop af			;beb9
	pop bc			;beba
	pop de			;bebb
L_BEBC:
	pop hl			;bebc
	ei			;bebd
	ret			;bebe
L_BEBF:
	ld c,a			;bebf
	ld b,002h		;bec0
	ld hl,0d812h		;bec2
	and 03fh		;bec5
	cp 002h		;bec7
	jr c,L_BECE		;bec9
	inc b			;becb
	jr L_BED2		;becc
L_BECE:
	dec b			;bece
	ld hl,0d81ch		;becf
L_BED2:
	ld a,(hl)			;bed2
	and 03fh		;bed3
	ld e,a			;bed5
	ld a,c			;bed6
	and 03fh		;bed7
	cp e			;bed9
	ret c			;beda
	cp 001h		;bedb
	jr nz,L_BEE3		;bedd
	ld a,e			;bedf
	cp 001h		;bee0
	ret z			;bee2
L_BEE3:
	ld a,c			;bee3
	add a,a			;bee4
	ld de,0befeh		;bee5
	add a,e			;bee8
	ld e,a			;bee9
	jr nc,L_BEED		;beea
	inc d			;beec
L_BEED:
	dec hl			;beed
	dec hl			;beee
L_BEEF:
	ld (hl),001h		;beef
	inc hl			;bef1
	inc hl			;bef2
	ld (hl),c			;bef3
	inc hl			;bef4
	ld a,(de)			;bef5
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
