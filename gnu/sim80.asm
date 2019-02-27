; This is an older version of the 8080 simulator for Linux that
; was assembled using nasm.  It runs only in 32-bit mode.
; See sim80.S for the current version of the 8080 simulator.

;	title	sim80 - 8080 simulator with ISIS-II front end
;	page	66,128
;	name	sim80

	section	.data

	extern	mem8080		; pointer to base of 8080 memory block, always
				; guaranteed to have zero in its low 16 bits

; 8080 register equates

;a	 equ	 al
;flags	 equ	 ah
;psw	 equ	 ax
;b	 equ	 ch
;c	 equ	 cl
;bc	 equ	 bx
;d	 equ	 dh
;e	 equ	 dl
;de	 equ	 dx
;h	 equ	 bh
;l	 equ	 bl
;hl	 equ	 bx
;m	 equ	 byte ptr [bx]
;pc	 equ	 si
;scratch equ	 di

; Register values passed to ISIS-II from simulator

	global	savepsw,savebc,savede,savehl,savesp,savepc

savepsw:dw	0		; contents of flags and A register
savebc:	dw	0		; contents of B & C registers
savede:	dw	0		; contents of D & E registers
savehl:	dw	0		; contents of H & L registers
savesp:	dw	0		; contents of stack pointer
savepc:	dw	0		; contents of program counter

; Saved value of C stack pointer

cstack:	dd	0

; Trace flag - set to non-zero to enable tracing

	global	trace
trace:	dd	0

traceret:
	dw	0
	
; JMPTAB - table of instruction handlers, indexed by opcode 0-255

jmptab	dd	fetch,lxib	   ; 0,1
	dd	staxb,inxb	   ; 2,3
	dd	inrb,dcrb	   ; 4,5
	dd	mvib,rlc	   ; 6,7
	dd	halt, dadb	   ; 8,9
	dd	ldaxb,dcxb	   ; a,b
	dd	inrc,dcrc	   ; c,d
	dd	mvic,rrc	   ; e,f
	dd	halt, lxid	   ; 10,11
	dd	staxd,inxd	   ; 12,13
	dd	inrd,dcrd	   ; 14,15
	dd	mvid,ral	   ; 16,17
	dd	halt, dadd	   ; 18,19
	dd	ldaxd,dcxd	   ; 1a,1b
	dd	inre,dcre	   ; 1c,1d
	dd	mvie,rar	   ; 1e,1f
	dd	halt, lxih	   ; 20,21
	dd	shldx, inxh	   ; 22,23
	dd	inrh,dcrh	   ; 24,25
	dd	mvih,daa1	   ; 26,27
	dd	halt, dadh	   ; 28,29
	dd	lhld, dcxh	   ; 2a,2b
	dd	inrl,dcrl	   ; 2c,2d
	dd	mvil,cma	   ; 2e,2f
	dd	halt, lxisp    ; 30,31
	dd	sta,  inxsp    ; 32,33
	dd	inrm,dcrm	   ; 34,35
	dd	mvim,stc1	   ; 36,37
	dd	halt, dadsp    ; 38,39
	dd	lda,  dcxsp    ; 3a,3b
	dd	inra,dcra	   ; 3c,3d
	dd	mvia,cmc1	   ; 3e,3f
	dd	movbb,movbc    ; 40,41
	dd	movbd,movbe    ; 42,43
	dd	movbh,movbl    ; 44,45
	dd	movbm,movba    ; 46,47
	dd	movcb,movcc    ; 48,49
	dd	movcd,movce    ; 4a,4b
	dd	movch,movcl    ; 4c,4d
	dd	movcm,movca    ; 4e,4f
	dd	movdb,movdc    ; 50,51
	dd	movdd,movde    ; 52,53
	dd	movdh,movdl    ; 54,55
	dd	movdm,movda    ; 56,57
	dd	moveb,movec    ; 58,59
	dd	moved,movee    ; 5a,5b
	dd	moveh,movel    ; 5c,5d
	dd	movem,movea    ; 5e,5f
	dd	movhb,movhc    ; 60,61
	dd	movhd,movhe    ; 62,63
	dd	movhh,movhl    ; 64,65
	dd	movhm,movha    ; 66,67
	dd	movlb,movlc    ; 68,69
	dd	movld,movle    ; 6a,6b
	dd	movlh,movll    ; 6c,6d
	dd	movlm,movla    ; 6e,6f
	dd	movmb,movmc    ; 70,71
	dd	movmd,movme    ; 72,73
	dd	movmh,movml    ; 74,75
	dd	halt, movma    ; 76,77
	dd	movab,movac    ; 78,79
	dd	movad,movae    ; 7a,7b
	dd	movah,moval    ; 7c,7d
	dd	movam,movaa    ; 7e,7f
	dd	addb,addc	   ; 80,81
	dd	addd,adde	   ; 82,83
	dd	addh,addl	   ; 84,85
	dd	addm,adda	   ; 86,87
	dd	adcb,adcc	   ; 88,89
	dd	adcd,adce	   ; 8a,8b
	dd	adch,adcl	   ; 8c,8d
	dd	adcm,adca	   ; 8e,8f
	dd	subb,subc	   ; 90,91
	dd	subd,sube	   ; 92,93
	dd	subh,subl	   ; 94,95
	dd	subm,suba	   ; 96,97
	dd	sbbb,sbbc	   ; 98,99
	dd	sbbd,sbbe	   ; 9a,9b
	dd	sbbh,sbbl	   ; 9c,9d
	dd	sbbm,sbba	   ; 9e,9f
	dd	anab,anac	   ; a0,a1
	dd	anad,anae	   ; a2,a3
	dd	anah,anal	   ; a4,a5
	dd	anam,anaa	   ; a6,a7
	dd	xrab,xrac	   ; a8,a9
	dd	xrad,xrae	   ; aa,ab
	dd	xrah,xral	   ; ac,ad
	dd	xram,xraa	   ; ae,af
	dd	orab,orac	   ; b0,b1
	dd	orad,orae	   ; b2,b3
	dd	orah,oral	   ; b4,b5
	dd	oram,oraa	   ; b6,b7
	dd	cmpb,cmpc	   ; b8,b9
	dd	cmpd,cmpe	   ; ba,bb
	dd	cmph,cmpl	   ; bc,bd
	dd	cmpm,cmpa	   ; be,bf
	dd	rnz, popb	   ; c0,c1
	dd	jnz1,jmp1	   ; c2,c3
	dd	cnz, pushb	   ; c4,c5
	dd	adi, rst0	   ; c6,c7
	dd	rz,  ret1	   ; c8,c9
	dd	jz1, halt	   ; ca,cb
	dd	cz,  call1	   ; cc,cd
	dd	aci, rst1	   ; ce,cf
	dd	rnc, popd	   ; d0,d1
	dd	jnc1,halt	   ; d2,d3
	dd	cnc, pushd	   ; d4,d5
	dd	sui, rst2	   ; d6,d7
	dd	rc,  halt	   ; d8,d9
	dd	jc1, halt	   ; da,db
	dd	cc,  halt	   ; dc,dd
	dd	sbi, rst3	   ; de,df
	dd	rpo, poph	   ; e0,e1
	dd	jpo1,xthl	   ; e2,e3
	dd	cpo, pushh	   ; e4,e5
	dd	ani, rst4	   ; e6,e7
	dd	rpe, pchl	   ; e8,e9
	dd	jpe1,xchgx	   ; ea,eb
	dd	cpe, halt	   ; ec,ed
	dd	xri, rst5	   ; ee,ef
	dd	rp,  poppsw    	   ; f0,f1
	dd	jpx, fetch	   ; f2,f3
	dd	cp,  pushpsw       ; f4,f5
	dd	ori, rst6	   ; f6,f7
	dd	rm,  sphl	   ; f8,f9
	dd	jm,  fetch	   ; fa,fb
	dd	cm,  halt	   ; fc,fd
	dd	cpi, rst7	   ; fe,ff

	section	.text

	extern	isis
	extern	trace8080

; Macros for checking stray pointers - remove when simulator works

%macro	chkbx	0
;	call	checkbx
%endmacro

%macro	chkdi	0
;	call	checkdi
%endmacro

checkbx:
	cmp	bx,0367fh
	ja	bxok
	int	3		; enter debugger
bxok:
	ret

checkdi:
	cmp	di,0367fh
	ja	diok
	int	3		; enter debugger
diok:
	ret

; Macros for pushing and popping registers - at one time we used bp as stack

%macro	push1	1
	push	%1
;	sub	bp,2
;	mov	[bp],%1
%endmacro

%macro	pop1	1
	pop	%1
;	mov	%1,[bp]
;	add	bp,2
%endmacro

; Macro for getting the flags from where they are saved (ah for now).
; Must be used only in each instruction processing routine, not
; in the various instruction fetch/decode routines.

%macro	getf	0
	sahf
%endmacro


; dotrace - save registers and call instruction trace printer

dotrace:
	mov	[traceret], edi		; save place to resume decoding
	mov	[savepsw],ax
	mov	[savebc],cx
	mov	[savede],dx
	mov	[savehl],bx
	mov	[savesp],sp
	mov	[savepc],si
	mov	esp, [cstack]		; use alternate stack
	call	trace8080
resume:
	mov	eax, [mem8080]		; get base of 8080 memory
	mov	ecx, eax		; copy it to all 8080 registers
	mov	edx, eax
	mov	ebx, eax
	mov	esp, eax
	mov	esi, eax
	mov	ax,[savepsw]		; set 8080 registers (low words)
	mov	cx,[savebc]
	mov	dx,[savede]
	mov	bx,[savehl]
	mov	sp,[savesp]
	mov	si,[savepc]
	jmp	decode			; resume decoding

; HALT - save registers and call ISIS-II emulator.
;
; This routine is called to emulate illegal instructions.  It
; is assumed that FD is used at the ISIS and monitor entry points
; to break emulation.  The FD must be followed by a C9 (RET).

halt:
	mov	[savepsw],ax
	mov	[savebc],cx
	mov	[savede],dx
	mov	[savehl],bx
	mov	[savesp],sp
	mov	[savepc],si
	mov	esp, [cstack]		; use alternate stack
	call	isis			; when doing ISIS stuff
	jmp	resume			; resume decoding

; GO8080 - start 8080 program
;
; GO8080 can be used by external programs to start emulation using the
; saved register values.

	global	go8080

go8080:
	mov	[cstack], esp		; save C stack pointer
	mov	eax, [mem8080]		; get base of 8080 memory
	mov	ecx, eax		; copy it to all 8080 registers
	mov	edx, eax
	mov	ebx, eax
	mov	esp, eax
	mov	esi, eax
	mov	ax,[savepsw]		; set 8080 registers (low words)
	mov	cx,[savebc]
	mov	dx,[savede]
	mov	bx,[savehl]
	mov	sp,[savesp]
	mov	si,[savepc]
	jmp	fetch			; start decoding instructions

; FETCH - fetch and decode the next 8080 instruction
;
; This is the main instruction fetch loop.
; There are six entry points:
;	FETCHF	update flags from previous operation, then fetch instruction
;	BUMP1F	bump pc by 1, then do a FETCHF
;	BUMP2F	bump pc by 2, then do a FETCHF
;	FETCH	discard flags, then fetch instruction
;	BUMP1	bump pc by 1, then do a FETCHF
;	BUMP2	bump pc by 2, then do a FETCHF
; The fetch operation destroys the flags (they're still in ah though),
; so any instruction that needs the flags back must do a "getf" macro call.

;%macro	decode	0
;	cmp	[trace], byte 0	; is trace flag set?
;	jnz	%%trace
;%%fetch:
;	mov	edi,[esi] 	; get the opcode
;	inc	esi		; bump the program counter
;	and	edi,0ffh 	; mask off high bits of opcode
;	shl	edi,2		; make it an address pointer
;	jmp	[edi+jmptab]	; jump to appropriate instruction handler
;%%trace:
;	mov	edi, %%fetch
;	jmp	dotrace
;%endmacro

bump2f:
	lahf			; save flags
	add	esi,2		; skip two-byte operand
	jmp	short fetch
bump1f:
	lahf			; save flags
	inc	esi		; skip past one-byte operand
	jmp	short fetch
fetchf:
	lahf			; save flags
	jmp	short fetch
bump2:
	inc	si		; bump program counter by 2
bump1:
	inc	si		; bump program counter by 1
fetch:
	cmp	[trace], byte 0	; is trace flag set?
	jnz	dotrace1
decode:
	mov	edi,[esi] 	; get the opcode
	inc	esi		; bump the program counter
	and	edi,0ffh 	; mask off high bits of opcode
	shl	edi,2		; make it an address pointer
	jmp	[edi+jmptab]	; jump to appropriate instruction handler
dotrace1:
	jmp	dotrace

; 1-f

lxib:	mov	cx,[esi]
	jmp	bump2
staxb:	mov	edi,esi
	mov	di,cx
	chkdi
	mov	[edi],al
	jmp	fetch
inxb:	inc	cx
	jmp	fetch
inrb:	getf
	inc	ch
	jmp	fetchf
dcrb:	getf
	dec	ch
	jmp	fetchf
mvib:	mov	ch,[esi]
	jmp	bump1
	getf
rlc:	getf
	rol	al,1
	jmp	fetchf
dadb:	add	bx,cx
testc:	jc	stc1
clc1:	and	ah,0feh
	jmp	fetch
stc1:	or	ah,1
	jmp	fetch
ldaxb:	mov	edi,esi
	mov	di,cx
	mov	al,[edi]
	jmp	fetch
dcxb:	dec	cx
	jmp	fetch
inrc:	getf
	inc	cl
	jmp	fetchf
dcrc:	getf
	dec	cl
	jmp	fetchf
mvic:	mov	cl,[esi]
	jmp	bump1
rrc:	getf
	ror	al,1
	jmp	fetchf

; 10-1f

lxid:	mov	dx,[esi]
	jmp	bump2
staxd:	mov	edi,esi
	mov	di,dx
	chkdi
	mov	[edi],al
	jmp	fetch
inxd:	inc	dx
	jmp	fetch
inrd:	getf
	inc	dh
	jmp	fetchf
dcrd:	getf
	dec	dh
	jmp	fetchf
mvid:	mov	dh,[esi]
	jmp	bump1
ral:	getf
	rcl	al,1
	jmp	fetchf
dadd:	add	bx,dx
	jmp	testc
ldaxd:	mov	edi,esi
	mov	di,dx
	mov	al,[edi]
	jmp	fetch
dcxd:	dec	dx
	jmp	fetch
inre:	getf
	inc	dl
	jmp	fetchf
dcre:	getf
	dec	dl
	jmp	fetchf
mvie:	mov	dl,[esi]
	jmp	bump1
rar:	getf
	rcr	al,1
	jmp	fetchf

; 20-2f

lxih:	mov	bx,[esi]
	jmp	bump2
shldx:	mov	edi,esi
	mov	di,[esi]
	chkdi
	mov	[edi],bx
	jmp	bump2
inxh:	inc	bx
	jmp	fetch
inrh:	getf
	inc	bh
	jmp	fetchf
dcrh:	getf
	dec	bh
	jmp	fetchf
mvih:	mov	bh,[esi]
	jmp	bump1
daa1:	getf
	daa
	jmp	fetchf
dadh:	add	bx,bx
	jmp	testc
lhld:	mov	edi,esi
	mov	di,[esi]
	chkdi
	mov	bx,[edi]
	jmp	bump2
dcxh:	dec	bx
	jmp	fetch
inrl:	getf
	inc	bl
	jmp	fetchf
dcrl:	getf
	dec	bl
	jmp	fetchf
mvil:	mov	bl,[esi]
	jmp	bump1
cma:	not	al
	jmp	fetch

; 30-3F

lxisp:	mov	sp,[esi]
	jmp	bump2
sta:	mov	edi,esi
	mov	di,[esi]
	chkdi
	mov	[edi],al
	jmp	bump2
inxsp:	inc	sp
	jmp	fetch
inrm:	chkbx
	getf
	inc	byte [ebx]
	jmp	fetchf
dcrm:	chkbx
	getf
	dec	byte [ebx]
	jmp	fetchf
mvim:	mov	edi,esi
	mov	di,bx
	chkdi
	mov	bl,[esi]
	mov	[edi],bl
	mov	bx,di
	jmp	bump1
dadsp:	add	bx,sp
	jmp	testc
lda:	mov	edi,esi
	mov	di,[esi]
	mov	al,[edi]
	jmp	bump2
dcxsp:	dec	sp
	jmp	fetch
inra:	getf
	inc	al
	jmp	fetchf
dcra:	getf
	dec	al
	jmp	fetchf
mvia:	mov	al,[esi]
	jmp	bump1
cmc1:	xor	ah,1
	jmp	fetch

; 40-4F

movbb:	mov	ch,ch
	jmp	fetch
movbc:	mov	ch,cl
	jmp	fetch
movbd:	mov	ch,dh
	jmp	fetch
movbe:	mov	ch,dl
	jmp	fetch
movbh:	mov	ch,bh
	jmp	fetch
movbl:	mov	ch,bl
	jmp	fetch
movbm:	mov	ch,[ebx]
	jmp	fetch
movba:	mov	ch,al
	jmp	fetch
movcb:	mov	cl,ch
	jmp	fetch
movcc:	mov	cl,cl
	jmp	fetch
movcd:	mov	cl,dh
	jmp	fetch
movce:	mov	cl,dl
	jmp	fetch
movch:	mov	cl,bh
	jmp	fetch
movcl:	mov	cl,bl
	jmp	fetch
movcm:	mov	cl,[ebx]
	jmp	fetch
movca:	mov	cl,al
	jmp	fetch

; 50-5F

movdb:	mov	dh,ch
	jmp	fetch
movdc:	mov	dh,cl
	jmp	fetch
movdd:	mov	dh,dh
	jmp	fetch
movde:	mov	dh,dl
	jmp	fetch
movdh:	mov	dh,bh
	jmp	fetch
movdl:	mov	dh,bl
	jmp	fetch
movdm:	mov	dh,[ebx]
	jmp	fetch
movda:	mov	dh,al
	jmp	fetch
moveb:	mov	dl,ch
	jmp	fetch
movec:	mov	dl,cl
	jmp	fetch
moved:	mov	dl,dh
	jmp	fetch
movee:	mov	dl,dl
	jmp	fetch
moveh:	mov	dl,bh
	jmp	fetch
movel:	mov	dl,bl
	jmp	fetch
movem:	mov	dl,[ebx]
	jmp	fetch
movea:	mov	dl,al
	jmp	fetch

; 60-6F

movhb:	mov	bh,ch
	jmp	fetch
movhc:	mov	bh,cl
	jmp	fetch
movhd:	mov	bh,dh
	jmp	fetch
movhe:	mov	bh,dl
	jmp	fetch
movhh:	mov	bh,bh
	jmp	fetch
movhl:	mov	bh,bl
	jmp	fetch
movhm:	mov	bh,[ebx]
	jmp	fetch
movha:	mov	bh,al
	jmp	fetch
movlb:	mov	bl,ch
	jmp	fetch
movlc:	mov	bl,cl
	jmp	fetch
movld:	mov	bl,dh
	jmp	fetch
movle:	mov	bl,dl
	jmp	fetch
movlh:	mov	bl,bh
	jmp	fetch
movll:	mov	bl,bl
	jmp	fetch
movlm:	mov	bl,[ebx]
	jmp	fetch
movla:	mov	bl,al
	jmp	fetch

; 70-7F

movmb:	chkbx
	mov	[ebx],ch
	jmp	fetch
movmc:	chkbx
	mov	[ebx],cl
	jmp	fetch
movmd:	chkbx
	mov	[ebx],dh
	jmp	fetch
movme:	chkbx
	mov	[ebx],dl
	jmp	fetch
movmh:	chkbx
	mov	[ebx],bh
	jmp	fetch
movml:	chkbx
	mov	[ebx],bl
	jmp	fetch
movma:	chkbx
	mov	[ebx],al
	jmp	fetch
movab:	mov	al,ch
	jmp	fetch
movac:	mov	al,cl
	jmp	fetch
movad:	mov	al,dh
	jmp	fetch
movae:	mov	al,dl
	jmp	fetch
movah:	mov	al,bh
	jmp	fetch
moval:	mov	al,bl
	jmp	fetch
movam:	mov	al,[ebx]
	jmp	fetch
movaa:	mov	al,al
	jmp	fetch

; 80-8F

addb:	add	al,ch
	jmp	fetchf
addc:	add	al,cl
	jmp	fetchf
addd:	add	al,dh
	jmp	fetchf
adde:	add	al,dl
	jmp	fetchf
addh:	add	al,bh
	jmp	fetchf
addl:	add	al,bl
	jmp	fetchf
addm:	add	al,[ebx]
	jmp	fetchf
adda:	add	al,al
	jmp	fetchf
adcb:	getf
	adc	al,ch
	jmp	fetchf
adcc:	getf
	adc	al,cl
	jmp	fetchf
adcd:	getf
	adc	al,dh
	jmp	fetchf
adce:	getf
	adc	al,dl
	jmp	fetchf
adch:	getf
	adc	al,bh
	jmp	fetchf
adcl:	getf
	adc	al,bl
	jmp	fetchf
adcm:	getf
	adc	al,[ebx]
	jmp	fetchf
adca:	getf
	adc	al,al
	jmp	fetchf

; 90-9F

subb:
	sub	al,ch
	jmp	fetchf
subc:
	sub	al,cl
	jmp	fetchf
subd:
	sub	al,dh
	jmp	fetchf
sube:
	sub	al,dl
	jmp	fetchf
subh:
	sub	al,bh
	jmp	fetchf
subl:
	sub	al,bl
	jmp	fetchf
subm:
	sub	al,[ebx]
	jmp	fetchf
suba:
	sub	al,al
	jmp	fetchf
sbbb:	getf
	sbb	al,ch
	jmp	fetchf
sbbc:	getf
	sbb	al,cl
	jmp	fetchf
sbbd:	getf
	sbb	al,dh
	jmp	fetchf
sbbe:	getf
	sbb	al,dl
	jmp	fetchf
	public
sbbh:	getf
	sbb	al,bh
	jmp	fetchf
sbbl:	getf
	sbb	al,bl
	jmp	fetchf
sbbm:	getf
	sbb	al,[ebx]
	jmp	fetchf
sbba:	getf
	sbb	al,al
	jmp	fetchf

; a0-aF

anab:	and	al,ch
	jmp	fetchf
anac:	and	al,cl
	jmp	fetchf
anad:	and	al,dh
	jmp	fetchf
anae:	and	al,dl
	jmp	fetchf
anah:	and	al,bh
	jmp	fetchf
anal:	and	al,bl
	jmp	fetchf
anam:	and	al,[ebx]
	jmp	fetchf
anaa:	and	al,al
	jmp	fetchf
xrab:	xor	al,ch
	jmp	fetchf
xrac:	xor	al,cl
	jmp	fetchf
xrad:	xor	al,dh
	jmp	fetchf
xrae:	xor	al,dl
	jmp	fetchf
xrah:	xor	al,bh
	jmp	fetchf
xral:	xor	al,bl
	jmp	fetchf
xram:	xor	al,[ebx]
	jmp	fetchf
xraa:	xor	al,al
	jmp	fetchf

; b0-bF

orab:	or	al,ch
	jmp	fetchf
orac:	or	al,cl
	jmp	fetchf
orad:	or	al,dh
	jmp	fetchf
orae:	or	al,dl
	jmp	fetchf
orah:	or	al,bh
	jmp	fetchf
oral:	or	al,bl
	jmp	fetchf
oram:	or	al,[ebx]
	jmp	fetchf
oraa:	or	al,al
	jmp	fetchf
cmpb:	cmp	al,ch
	jmp	fetchf
cmpc:	cmp	al,cl
	jmp	fetchf
cmpd:	cmp	al,dh
	jmp	fetchf
cmpe:	cmp	al,dl
	jmp	fetchf
cmph:	cmp	al,bh
	jmp	fetchf
cmpl:	cmp	al,bl
	jmp	fetchf
cmpm:	cmp	al,[ebx]
	jmp	fetchf
cmpa:	cmp	al,al
	jmp	fetchf

; c0 - cf

rnz:	getf
	jz	fetch1
	pop1	si
	jmp	short fetch1
popb:	pop1	cx
	jmp	short fetch1
jnz1:	getf
	jz	bump2a
jmp1:	mov	si,[esi]
	jmp	short fetch1
cnz:	getf
	jnz	call1
	jmp	short bump2a
pushb:	push1	cx
	jmp	short fetch1
adi:	add	al,[esi]
	jmp	bump1f
rst0:	xor	di,di
	jmp	short calldi1
rz:	getf
	jnz	fetch1
ret1:	pop1	si
	jmp	short fetch1
jz1:	getf
	jnz	bump2a
	mov	si,[esi]
	jmp	short fetch1
cz:	getf
	jz	call1
	jmp	short bump2a
aci:	getf
	adc	al,[esi]
	jmp	bump1f
rst1:	mov	di,8
	jmp	short calldi1

; routines used by c0-df

call1:
	mov	di,[esi]
	inc	si
	inc	si
calldi1:			; come here for RSTx, di contains new PC
	push1	si
	mov	si,di
fetch1:
	jmp	fetch
bump2a:
	add	si,2		; skip past two-byte operand
	jmp	fetch

; d0 - df

call4:	jmp	call1
rnc:	getf
	jc	fetch1
	pop1	si
	jmp	short fetch1
popd:	pop1	dx
	jmp	short fetch1
jnc1:	getf
	jc	bump2a
	mov	si,[esi]
	jmp	short fetch1
cnc:	getf
	jnc	call4
	jmp	short bump2a
pushd:	push1	dx
	jmp	fetch1
sui:	sub	al,[esi]
	jmp	bump1f
rst2:	mov	di,2*8
	jmp	calldi1
rc:	getf
	jnc	fetch4
	pop1	si
fetch4:	jmp	fetch1
jc1:	getf
	jnc	bump2a
	mov	si,[esi]
	jmp	fetch1
cc:	getf
	jc	call2
	jmp	bump2a
sbi:	getf
	sbb	al,[esi]
	jmp	bump1f
rst3:	mov	di,3*8
	jmp	short calldi2

; e0 - ef

rpo:	getf
	jpe	fetch2
	pop1	si
	jmp	short fetch2
poph:	pop1	bx
	jmp	short fetch2
jpo1:	getf
	jpe	bump2c
	mov	si,[esi]
	jmp	short fetch2
xthl:	xchg	bx,[esp]
	jmp	short fetch2
cpo:	getf
	jpo	call2
bump2c:	jmp	short bump2b
pushh:	push1	bx
	jmp	short fetch2
ani:	and	al,[esi]
	jmp	bump1f
rst4:	mov	di,4*8
	jmp	short calldi2
rpe:	getf
	jpo	fetch2
	pop1	si
	jmp	short fetch2
pchl:	mov	si,bx
	jmp	short fetch2
jpe1:	getf
	jpo	bump2b
	mov	si,[esi]
	jmp	short fetch2
xchgx:	xchg	dx,bx
	jmp	short fetch2
cpe:	getf
	jpe	call2
	jmp	short bump2b
xri:	xor	al,[esi]
	jmp	bump1f
rst5:	mov	di,5*8
	jmp	short calldi2

; routines used by e0-ff

call2:
	mov	di,[esi]
	inc	si
	inc	si
calldi2:			; come here for RSTx, di contains new PC
	push1	si
	mov	si,di
fetch2:
	jmp	fetch
bump2b:
	add	si,2		; skip past two byte operand
	jmp	fetch

; f0 - ff

rp:	getf
	js	fetch2
	pop1	si
	jmp	short fetch2
poppsw: pop1	ax
	xchg	ah,al
	jmp	short fetch2
jpx:	getf
	js	bump2b
	mov	si,[esi]
	jmp	short fetch2
cp:	getf
	jns	call3
	jmp	short bump2b
pushpsw:xchg	ah,al
	push1	ax
	xchg	ah,al
	jmp	fetch2
ori:	or	al,[esi]
	jmp	bump1f
rst6:	mov	di,6*8
	jmp	calldi2
rm:	getf
	jns	fetch3
	pop1	si
fetch3:	jmp	fetch2
sphl:	mov	sp,bx
	jmp	fetch2
jm:	getf
	jns	bump2b
	mov	si,[esi]
	jmp	fetch2
call3:	jmp	call2
cm:	getf
	js	call3
	jmp	bump2b
cpi:	cmp	al,[esi]
	jmp	bump1f
rst7:	mov	di,7*8
	jmp	calldi2

