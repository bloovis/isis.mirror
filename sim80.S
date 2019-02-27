#    sim80 - 8080 simulator with ISIS-II front end
#
#    Copyright (C) 2019 Mark Alexander
#
#    This file is part of Isis, an ISIS-II simulator
#
#    Isis is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Preprocessor defines for 32-bit/64-bit portability.

#if __i386__

#define RAX %eax
#define RBX %ebx
#define RCX %ecx
#define RDX %edx
#define RSP %esp
#define RSI %esi
#define RDI %edi

#define wptr .long

#else

#define RAX %rax
#define RBX %rbx
#define RCX %rcx
#define RDX %rdx
#define RSP %rsp
#define RSI %rsi
#define RDI %rdi

#define wptr .quad

#endif

# 8080 register equates

#define PC	RSI
#define PC16	%si
#define SP16	%sp
#define A	%al
#define FLAGS	%ah
#define PSW	%ax
#define B	%ch
#define C	%cl
#define BC	%cx
#define D	%dh
#define E	%dl
#define DE	%dx
#define H	%bh
#define L	%bl
#define HL	RBX
#define HL16	%bx
#define SCRATCH	RDI
#define SCRATCH16 %di


	.data

# The public names with underscore prefixes are needed for MinGW.

#if defined(__WIN32__)
#define mem8080 _mem8080
#define trace8080 _trace8080
#define go8080 _go8080
#define savebc _savebc
#define savede _savede
#define savehl _savehl
#define savesp _savesp
#define savepc _savepc
#define savepsw _savepsw
#define trace _trace
#define isis _isis
#endif

	.globl	mem8080		# pointer to base of 8080 memory block, always
				# guaranteed to have zero in its low 16 bits

# Register values passed to ISIS-II from simulator.

	.globl	savebc,savede,savehl,savesp,savepc,savepsw

savepsw:	.short	0		# contents of flags and A register
savebc:		.short	0		# contents of B & C registers
savede:		.short	0		# contents of D & E registers
savehl:		.short	0		# contents of H & L registers
savesp:		.short	0		# contents of stack pointer
savepc:		.short	0		# contents of program counter

# Saved value of C stack pointer

cstack:	wptr	0

# Trace flag - set to non-zero to enable tracing

	.globl	trace
trace:	.int	0

traceret:
	wptr	0

# Access variables in position-independent manner on 64-bit.

#if __i386__
#define MEM8080  mem8080
#define SAVEPSW savepsw
#define SAVEBC savebc
#define SAVEDE savede
#define SAVEHL savehl
#define SAVESP savesp
#define SAVEPC savepc
#define CSTACK cstack
#define TRACERET traceret
#define TRACE    trace
#else
#define MEM8080  mem8080(%rip)
#define SAVEPSW savepsw(%rip)
#define SAVEBC savebc(%rip)
#define SAVEDE savede(%rip)
#define SAVEHL savehl(%rip)
#define SAVESP savesp(%rip)
#define SAVEPC savepc(%rip)
#define CSTACK cstack(%rip)
#define TRACERET traceret(%rip)
#define TRACE    trace(%rip)
#endif

# JMPTAB - table of instruction handlers, indexed by opcode 0-255

jmptab:	wptr	fetch,lxib		# 0,1
	wptr	staxb,inxb		# 2,3
	wptr	inrb,dcrb		# 4,5
	wptr	mvib,rlc		# 6,7
	wptr	halt,dadb		# 8,9
	wptr	ldaxb,dcxb		# a,b
	wptr	inrc,dcrc		# c,d
	wptr	mvic,rrc		# e,f
	wptr	halt,lxid		# 10,11
	wptr	staxd,inxd		# 12,13
	wptr	inrd,dcrd		# 14,15
	wptr	mvid,ral		# 16,17
	wptr	halt,dadd		# 18,19
	wptr	ldaxd,dcxd		# 1a,1b
	wptr	inre,dcre		# 1c,1d
	wptr	mvie,rar		# 1e,1f
	wptr	halt,lxih		# 20,21
	wptr	shldx,inxh		# 22,23
	wptr	inrh,dcrh		# 24,25
	wptr	mvih,daa1		# 26,27
	wptr	halt,dadh		# 28,29
	wptr	lhld,dcxh		# 2a,2b
	wptr	inrl,dcrl		# 2c,2d
	wptr	mvil,cma		# 2e,2f
	wptr	halt,lxisp 	# 30,31
	wptr	sta,inxsp 	# 32,33
	wptr	inrm,dcrm		# 34,35
	wptr	mvim,stc1		# 36,37
	wptr	halt,dadsp 	# 38,39
	wptr	lda,dcxsp 	# 3a,3b
	wptr	inra,dcra		# 3c,3d
	wptr	mvia,cmc1		# 3e,3f
	wptr	movbb,movbc 	# 40,41
	wptr	movbd,movbe 	# 42,43
	wptr	movbh,movbl 	# 44,45
	wptr	movbm,movba 	# 46,47
	wptr	movcb,movcc 	# 48,49
	wptr	movcd,movce 	# 4a,4b
	wptr	movch,movcl 	# 4c,4d
	wptr	movcm,movca 	# 4e,4f
	wptr	movdb,movdc 	# 50,51
	wptr	movdd,movde 	# 52,53
	wptr	movdh,movdl 	# 54,55
	wptr	movdm,movda 	# 56,57
	wptr	moveb,movec 	# 58,59
	wptr	moved,movee 	# 5a,5b
	wptr	moveh,movel 	# 5c,5d
	wptr	movem,movea 	# 5e,5f
	wptr	movhb,movhc 	# 60,61
	wptr	movhd,movhe 	# 62,63
	wptr	movhh,movhl 	# 64,65
	wptr	movhm,movha 	# 66,67
	wptr	movlb,movlc 	# 68,69
	wptr	movld,movle 	# 6a,6b
	wptr	movlh,movll 	# 6c,6d
	wptr	movlm,movla 	# 6e,6f
	wptr	movmb,movmc 	# 70,71
	wptr	movmd,movme 	# 72,73
	wptr	movmh,movml 	# 74,75
	wptr	halt,movma 	# 76,77
	wptr	movab,movac 	# 78,79
	wptr	movad,movae 	# 7a,7b
	wptr	movah,moval 	# 7c,7d
	wptr	movam,movaa 	# 7e,7f
	wptr	addb,addc		# 80,81
	wptr	addd,adde		# 82,83
	wptr	addh,addl		# 84,85
	wptr	addm,adda		# 86,87
	wptr	adcb,adcc		# 88,89
	wptr	adcd,adce		# 8a,8b
	wptr	adch,adcl		# 8c,8d
	wptr	adcm,adca		# 8e,8f
	wptr	subb,subc		# 90,91
	wptr	subd,sube		# 92,93
	wptr	subh,subl		# 94,95
	wptr	subm,suba		# 96,97
	wptr	sbbb,sbbc		# 98,99
	wptr	sbbd,sbbe		# 9a,9b
	wptr	sbbh,sbbl		# 9c,9d
	wptr	sbbm,sbba		# 9e,9f
	wptr	anab,anac		# a0,a1
	wptr	anad,anae		# a2,a3
	wptr	anah,anal		# a4,a5
	wptr	anam,anaa		# a6,a7
	wptr	xrab,xrac		# a8,a9
	wptr	xrad,xrae		# aa,ab
	wptr	xrah,xral		# ac,ad
	wptr	xram,xraa		# ae,af
	wptr	orab,orac		# b0,b1
	wptr	orad,orae		# b2,b3
	wptr	orah,oral		# b4,b5
	wptr	oram,oraa		# b6,b7
	wptr	cmpb,cmpc		# b8,b9
	wptr	cmpd,cmpe		# ba,bb
	wptr	cmph,cmpl		# bc,bd
	wptr	cmpm,cmpa		# be,bf
	wptr	rnz,popb		# c0,c1
	wptr	jnz1,jmp1		# c2,c3
	wptr	cnz,pushb		# c4,c5
	wptr	adi,rst0		# c6,c7
	wptr	rz,ret1		# c8,c9
	wptr	jz1,halt		# ca,cb
	wptr	cz,call1		# cc,cd
	wptr	aci,rst1		# ce,cf
	wptr	rnc,popd		# d0,d1
	wptr	jnc1,halt		# d2,d3
	wptr	cnc,pushd		# d4,d5
	wptr	sui,rst2		# d6,d7
	wptr	rc,halt		# d8,d9
	wptr	jc1,halt		# da,db
	wptr	cc,halt		# dc,dd
	wptr	sbi,rst3		# de,df
	wptr	rpo,poph		# e0,e1
	wptr	jpo1,xthl		# e2,e3
	wptr	cpo,pushh		# e4,e5
	wptr	ani,rst4		# e6,e7
	wptr	rpe,pchl		# e8,e9
	wptr	jpe1,xchgx		# ea,eb
	wptr	cpe,halt		# ec,ed
	wptr	xri,rst5		# ee,ef
	wptr	rp,poppsw    		# f0,f1
	wptr	jpx,fetch		# f2,f3
	wptr	cp,pushpsw    	# f4,f5
	wptr	ori,rst6		# f6,f7
	wptr	rm,sphl		# f8,f9
	wptr	jm,fetch		# fa,fb
	wptr	cm,halt		# fc,fd
	wptr	cpi,rst7		# fe,ff

	.text

	.globl	isis
	.globl	trace8080

# Macros for checking stray pointers - remove when simulator works

	.macro	chkbx
#	call	checkbx
	.endm

	.macro	chkdi
#	call	checkdi
	.endm

checkbx:
	cmpw	$0x0367f,%bx
	ja	bxok
	int	$3		# enter debugger
bxok:
	ret

checkdi:
	cmpw	$0x0367f,%di
	ja	diok
	int	$3		# enter debugger
diok:
	ret

# Macros for pushing and popping registers - at one time we used bp as stack

	.macro	push1	reg
	push	\reg
#	sub	bp,2
#	mov	[bp],%1
	.endm

	.macro	pop1	reg
	pop	\reg
#	mov	%1,[bp]
#	add	bp,2
	.endm

# Macro for getting the flags from where they are saved (ah for now).
# Must be used only in each instruction processing routine, not
# in the various instruction fetch/decode routines.

	.macro	getf
	sahf
	.endm


# dotrace - save registers and call instruction trace printer

dotrace:
	mov	RDI,TRACERET		# save place to resume decoding
	movw	PSW,SAVEPSW
	movw	BC,SAVEBC
	movw	DE,SAVEDE
	movw	HL16,SAVEHL
	movw	SP16,SAVESP
	movw	PC16,SAVEPC
	mov	CSTACK,RSP		# use alternate stack
	call	trace8080
resume:
	mov	MEM8080,RAX		# get base of 8080 memory
	mov	RAX,RCX			# copy it to all 8080 registers
	mov	RAX,RDX
	mov	RAX,RBX
	mov	RAX,RSP
	mov	RAX,RSI
	movw	SAVEPSW,PSW		# set 8080 registers (low words)
	movw	SAVEBC,BC
	movw	SAVEDE,DE
	movw	SAVEHL,HL16
	movw	SAVESP,SP16
	movw	SAVEPC,PC16
	jmp	decode			# resume decoding

# HALT - save registers and call ISIS-II emulator.
#
# This routine is called to emulate illegal instructions.  It
# is assumed that FD is used at the ISIS and monitor entry points
# to break emulation.  The FD must be followed by a C9 (RET).

halt:
	movw	PSW,SAVEPSW
	movw	BC,SAVEBC
	movw	DE,SAVEDE
	movw	HL16,SAVEHL
	movw	SP16,SAVESP
	movw	PC16,SAVEPC
	mov	CSTACK,RSP		# use alternate stack
	call	isis			# when doing ISIS stuff
	jmp	resume			# resume decoding

# GO8080 - start 8080 program
#
# GO8080 can be used by external programs to start emulation using the
# saved register values.

	.globl	go8080

go8080:
	mov	RSP,CSTACK		# save C stack pointer
	mov	MEM8080,RAX		# get base of 8080 memory
	mov	RAX,RCX			# copy it to all 8080 registers
	mov	RAX,RDX
	mov	RAX,HL
	mov	RAX,RSP
	mov	RAX,RSI
	movw	SAVEPSW,PSW		# set 8080 registers (low words)
	movw	SAVEBC,BC
	movw	SAVEDE,DE
	movw	SAVEHL,HL16
	movw	SAVESP,SP16
	movw	SAVEPC,PC16
	jmp	fetch			# start decoding instructions

# FETCH - fetch and decode the next 8080 instruction
#
# This is the main instruction fetch loop.
# There are six entry points:
#	FETCHF	update flags from previous operation, then fetch instruction
#	BUMP1F	bump pc by 1, then do a FETCHF
#	BUMP2F	bump pc by 2, then do a FETCHF
#	FETCH	discard flags, then fetch instruction
#	BUMP1	bump pc by 1, then do a FETCHF
#	BUMP2	bump pc by 2, then do a FETCHF
# The fetch operation destroys the flags (they're still in ah though),
# so any instruction that needs the flags back must do a "getf" macro call.

#%macro	decode	0
#	cmp	[trace], byte 0	; is trace flag set?
#	jnz	%%trace
#%%fetch:
#	mov	edi,[esi] 	; get the opcode
#	inc	esi		; bump the program counter
#	and	edi,0ffh 	; mask off high bits of opcode
#	shl	edi,2		; make it an address pointer
#	jmp	[edi+jmptab]	; jump to appropriate instruction handler
#%%trace:
#	mov	edi, %%fetch
#	jmp	dotrace
#%endmacro

bump2f:
	lahf			# save flags
	add	$2,PC		# skip two-byte operand
	jmp	fetch
bump1f:
	lahf			# save flags
	inc	PC		# skip past one-byte operand
	jmp	fetch
fetchf:
	lahf			# save flags
	jmp	fetch
bump2:
	incw	PC16		# bump program counter by 2
bump1:
	incw	PC16		# bump program counter by 1
fetch:
	cmpl	$0, TRACE	# is trace flag set?
	jnz	dotrace1
decode:
	mov	(PC),SCRATCH16 	# get the opcode
	inc	PC		# bump the program counter
	and	$0x0ff,SCRATCH 	# mask off high bits of opcode
#if __i386__
	shl	$2,SCRATCH	# make it an address pointer
	jmp	*jmptab(SCRATCH) # jump to appropriate instruction handler
#else
	leaq	jmptab(%rip), %r8
	jmp	*(%r8, SCRATCH, 8)
#endif
dotrace1:
	jmp	dotrace

# 1-f

lxib:	movw	(PC),BC
	jmp	bump2
staxb:	mov	PC,SCRATCH
	movw	BC,SCRATCH16
	chkdi
	movb	A,(SCRATCH)
	jmp	fetch
inxb:	incw	BC
	jmp	fetch
inrb:	getf
	incb	B
	jmp	fetchf
dcrb:	getf
	decb	B
	jmp	fetchf
mvib:	movb	(PC),B
	jmp	bump1
	getf
rlc:	getf
	rolb	$1,A
	jmp	fetchf
dadb:	addw	BC,HL16
testc:	jc	stc1
clc1:	andb	$0x0fe,FLAGS
	jmp	fetch
stc1:	orb	$1,FLAGS
	jmp	fetch
ldaxb:	mov	PC,SCRATCH
	movw	BC,SCRATCH16
	movb	(SCRATCH),A
	jmp	fetch
dcxb:	decw	BC
	jmp	fetch
inrc:	getf
	incb	C
	jmp	fetchf
dcrc:	getf
	decb	C
	jmp	fetchf
mvic:	movb	(PC),C
	jmp	bump1
rrc:	getf
	rorb	$1,A
	jmp	fetchf

# 10-1f

lxid:	movw	(PC),DE
	jmp	bump2
staxd:	mov	PC,SCRATCH
	movw	DE,SCRATCH16
	chkdi
	movb	A,(SCRATCH)
	jmp	fetch
inxd:	incw	DE
	jmp	fetch
inrd:	getf
	incb	D
	jmp	fetchf
dcrd:	getf
	decb	D
	jmp	fetchf
mvid:	movb	(PC),D
	jmp	bump1
ral:	getf
	rclb	$1,A
	jmp	fetchf
dadd:	addw	DE,HL16
	jmp	testc
ldaxd:	mov	PC,SCRATCH
	movw	DE,SCRATCH16
	movb	(SCRATCH),A
	jmp	fetch
dcxd:	decw	DE
	jmp	fetch
inre:	getf
	incb	E
	jmp	fetchf
dcre:	getf
	decb	E
	jmp	fetchf
mvie:	movb	(PC),E
	jmp	bump1
rar:	getf
	rcrb	$1,A
	jmp	fetchf

# 20-2f

lxih:	movw	(PC),HL16
	jmp	bump2
shldx:	mov	PC,SCRATCH
	movw	(PC),SCRATCH16
	chkdi
	movw	HL16,(SCRATCH)
	jmp	bump2
inxh:	incw	HL16
	jmp	fetch
inrh:	getf
	incb	H
	jmp	fetchf
dcrh:	getf
	decb	H
	jmp	fetchf
mvih:	movb	(PC),H
	jmp	bump1
daa1:	getf
#if __i386__
	daa
#else
	jmp	halt
#endif
	jmp	fetchf
dadh:	addw	HL16,HL16
	jmp	testc
lhld:	mov	PC,SCRATCH
	movw	(PC),SCRATCH16
	chkdi
	movw	(SCRATCH),HL16
	jmp	bump2
dcxh:	decw	HL16
	jmp	fetch
inrl:	getf
	incb	L
	jmp	fetchf
dcrl:	getf
	decb	L
	jmp	fetchf
mvil:	movb	(PC),L
	jmp	bump1
cma:	notb	A
	jmp	fetch

# 30-3F

lxisp:	movw	(PC),SP16
	jmp	bump2
sta:	mov	PC,SCRATCH
	movw	(PC),SCRATCH16
	chkdi
	movb	A,(SCRATCH)
	jmp	bump2
inxsp:	incw	SP16
	jmp	fetch
inrm:	chkbx
	getf
	incb	(HL)
	jmp	fetchf
dcrm:	chkbx
	getf
	decb	(HL)
	jmp	fetchf
mvim:	mov	PC,SCRATCH
	movw	HL16,SCRATCH16
	chkdi
	movb	(PC),L
	movb	L,(SCRATCH)
	movw	SCRATCH16,HL16
	jmp	bump1
dadsp:	addw	SP16,HL16
	jmp	testc
lda:	mov	PC,SCRATCH
	movw	(PC),SCRATCH16
	movb	(SCRATCH),A
	jmp	bump2
dcxsp:	decw	SP16
	jmp	fetch
inra:	getf
	incb	A
	jmp	fetchf
dcra:	getf
	decb	A
	jmp	fetchf
mvia:	movb	(PC),A
	jmp	bump1
cmc1:	xorb	$1,FLAGS
	jmp	fetch

# 40-4F

movbb:	movb	B,B
	jmp	fetch
movbc:	movb	C,B
	jmp	fetch
movbd:	movb	D,B
	jmp	fetch
movbe:	movb	E,B
	jmp	fetch
movbh:	movb	H,B
	jmp	fetch
movbl:	movb	L,B
	jmp	fetch
movbm:	movb	(HL),B
	jmp	fetch
movba:	movb	A,B
	jmp	fetch
movcb:	movb	B,C
	jmp	fetch
movcc:	movb	C,C
	jmp	fetch
movcd:	movb	D,C
	jmp	fetch
movce:	movb	E,C
	jmp	fetch
movch:	movb	H,C
	jmp	fetch
movcl:	movb	L,C
	jmp	fetch
movcm:	movb	(HL),C
	jmp	fetch
movca:	movb	A,C
	jmp	fetch

# 50-5F

movdb:	movb	B,D
	jmp	fetch
movdc:	movb	C,D
	jmp	fetch
movdd:	movb	D,D
	jmp	fetch
movde:	movb	E,D
	jmp	fetch
movdh:	movb	H,D
	jmp	fetch
movdl:	movb	L,D
	jmp	fetch
movdm:	movb	(HL),D
	jmp	fetch
movda:	movb	A,D
	jmp	fetch
moveb:	movb	B,E
	jmp	fetch
movec:	movb	C,E
	jmp	fetch
moved:	movb	D,E
	jmp	fetch
movee:	movb	E,E
	jmp	fetch
moveh:	movb	H,E
	jmp	fetch
movel:	movb	L,E
	jmp	fetch
movem:	movb	(HL),E
	jmp	fetch
movea:	movb	A,E
	jmp	fetch

# 60-6F

movhb:	movb	B,H
	jmp	fetch
movhc:	movb	C,H
	jmp	fetch
movhd:	movb	D,H
	jmp	fetch
movhe:	movb	E,H
	jmp	fetch
movhh:	movb	H,H
	jmp	fetch
movhl:	movb	L,H
	jmp	fetch
movhm:	movb	(HL),H
	jmp	fetch
movha:	movb	A,H
	jmp	fetch
movlb:	movb	B,L
	jmp	fetch
movlc:	movb	C,L
	jmp	fetch
movld:	movb	D,L
	jmp	fetch
movle:	movb	E,L
	jmp	fetch
movlh:	movb	H,L
	jmp	fetch
movll:	movb	L,L
	jmp	fetch
movlm:	movb	(HL),L
	jmp	fetch
movla:	movb	A,L
	jmp	fetch

# 70-7F

movmb:	chkbx
	movb	B,(HL)
	jmp	fetch
movmc:	chkbx
	movb	C,(HL)
	jmp	fetch
movmd:	chkbx
	movb	D,(HL)
	jmp	fetch
movme:	chkbx
	movb	E,(HL)
	jmp	fetch
movmh:	chkbx
	movb	H,(HL)
	jmp	fetch
movml:	chkbx
	movb	L,(HL)
	jmp	fetch
movma:	chkbx
	movb	A,(HL)
	jmp	fetch
movab:	movb	B,A
	jmp	fetch
movac:	movb	C,A
	jmp	fetch
movad:	movb	D,A
	jmp	fetch
movae:	movb	E,A
	jmp	fetch
movah:	movb	H,A
	jmp	fetch
moval:	movb	L,A
	jmp	fetch
movam:	movb	(HL),A
	jmp	fetch
movaa:	movb	A,A
	jmp	fetch

# 80-8F

addb:	addb	B,A
	jmp	fetchf
addc:	addb	C,A
	jmp	fetchf
addd:	addb	D,A
	jmp	fetchf
adde:	addb	E,A
	jmp	fetchf
addh:	addb	H,A
	jmp	fetchf
addl:	addb	L,A
	jmp	fetchf
addm:	addb	(HL),A
	jmp	fetchf
adda:	addb	A,A
	jmp	fetchf
adcb:	getf
	adcb	B,A
	jmp	fetchf
adcc:	getf
	adcb	C,A
	jmp	fetchf
adcd:	getf
	adcb	D,A
	jmp	fetchf
adce:	getf
	adcb	E,A
	jmp	fetchf
adch:	getf
	adcb	H,A
	jmp	fetchf
adcl:	getf
	adcb	L,A
	jmp	fetchf
adcm:	getf
	adcb	(HL),A
	jmp	fetchf
adca:	getf
	adcb	A,A
	jmp	fetchf

# 90-9F

subb:
	subb	B,A
	jmp	fetchf
subc:
	subb	C,A
	jmp	fetchf
subd:
	subb	D,A
	jmp	fetchf
sube:
	subb	E,A
	jmp	fetchf
subh:
	subb	H,A
	jmp	fetchf
subl:
	subb	L,A
	jmp	fetchf
subm:
	subb	(HL),A
	jmp	fetchf
suba:
	subb	A,A
	jmp	fetchf
sbbb:	getf
	sbbb	B,A
	jmp	fetchf
sbbc:	getf
	sbbb	C,A
	jmp	fetchf
sbbd:	getf
	sbbb	D,A
	jmp	fetchf
sbbe:	getf
	sbbb	E,A
	jmp	fetchf
sbbh:	getf
	sbbb	H,A
	jmp	fetchf
sbbl:	getf
	sbbb	L,A
	jmp	fetchf
sbbm:	getf
	sbbb	(HL),A
	jmp	fetchf
sbba:	getf
	sbbb	A,A
	jmp	fetchf

# a0-aF

anab:	andb	B,A
	jmp	fetchf
anac:	andb	C,A
	jmp	fetchf
anad:	andb	D,A
	jmp	fetchf
anae:	andb	E,A
	jmp	fetchf
anah:	andb	H,A
	jmp	fetchf
anal:	andb	L,A
	jmp	fetchf
anam:	andb	(HL),A
	jmp	fetchf
anaa:	andb	A,A
	jmp	fetchf
xrab:	xorb	B,A
	jmp	fetchf
xrac:	xorb	C,A
	jmp	fetchf
xrad:	xorb	D,A
	jmp	fetchf
xrae:	xorb	E,A
	jmp	fetchf
xrah:	xorb	H,A
	jmp	fetchf
xral:	xorb	L,A
	jmp	fetchf
xram:	xorb	(HL),A
	jmp	fetchf
xraa:	xorb	A,A
	jmp	fetchf

# b0-bF

orab:	orb	B,A
	jmp	fetchf
orac:	orb	C,A
	jmp	fetchf
orad:	orb	D,A
	jmp	fetchf
orae:	orb	E,A
	jmp	fetchf
orah:	orb	H,A
	jmp	fetchf
oral:	orb	L,A
	jmp	fetchf
oram:	orb	(HL),A
	jmp	fetchf
oraa:	orb	A,A
	jmp	fetchf
cmpb:	cmpb	B,A
	jmp	fetchf
cmpc:	cmpb	C,A
	jmp	fetchf
cmpd:	cmpb	D,A
	jmp	fetchf
cmpe:	cmpb	E,A
	jmp	fetchf
cmph:	cmpb	H,A
	jmp	fetchf
cmpl:	cmpb	L,A
	jmp	fetchf
cmpm:	cmpb	(HL),A
	jmp	fetchf
cmpa:	cmpb	A,A
	jmp	fetchf

# c0 - cf

rnz:	getf
	jz	fetch1
	pop1	PC16
	jmp	fetch1
popb:	pop1	BC
	jmp	fetch1
jnz1:	getf
	jz	bump2a
jmp1:	movw	(PC),PC16
	jmp	fetch1
cnz:	getf
	jnz	call1
	jmp	bump2a
pushb:	push1	BC
	jmp	fetch1
adi:	addb	(PC),A
	jmp	bump1f
rst0:	xorw	SCRATCH16,SCRATCH16
	jmp	calldi1
rz:	getf
	jnz	fetch1
ret1:	pop1	PC16
	jmp	fetch1
jz1:	getf
	jnz	bump2a
	movw	(PC),PC16
	jmp	fetch1
cz:	getf
	jz	call1
	jmp	bump2a
aci:	getf
	adcb	(PC),A
	jmp	bump1f
rst1:	movw	$8,SCRATCH16
	jmp	calldi1

# routines used by c0-df

call1:
	movw	(PC),SCRATCH16
	incw	PC16
	incw	PC16
calldi1:			# come here for RSTx, di contains new PC
	push1	PC16
	movw	SCRATCH16,PC16
fetch1:
	jmp	fetch
bump2a:
	addw	$2,PC16		# skip past two-byte operand
	jmp	fetch

# d0 - df

call4:	jmp	call1
rnc:	getf
	jc	fetch1
	pop1	PC16
	jmp	fetch1
popd:	pop1	DE
	jmp	fetch1
jnc1:	getf
	jc	bump2a
	movw	(PC),PC16
	jmp	fetch1
cnc:	getf
	jnc	call4
	jmp	bump2a
pushd:	push1	DE
	jmp	fetch1
sui:	subb	(PC),A
	jmp	bump1f
rst2:	movw	$2*8,SCRATCH16
	jmp	calldi1
rc:	getf
	jnc	fetch4
	pop1	PC16
fetch4:	jmp	fetch1
jc1:	getf
	jnc	bump2a
	movw	(PC),PC16
	jmp	fetch1
cc:	getf
	jc	call2
	jmp	bump2a
sbi:	getf
	sbbb	(PC),A
	jmp	bump1f
rst3:	movw	$3*8,SCRATCH16
	jmp	calldi2

# e0 - ef

rpo:	getf
	jpe	fetch2
	pop1	PC16
	jmp	fetch2
poph:	pop1	HL16
	jmp	fetch2
jpo1:	getf
	jpe	bump2c
	movw	(PC),PC16
	jmp	fetch2
xthl:	xchgw	(RSP),HL16
	jmp	fetch2
cpo:	getf
	jpo	call2
bump2c:	jmp	bump2b
pushh:	push1	HL16
	jmp	fetch2
ani:	andb	(PC),A
	jmp	bump1f
rst4:	movw	$4*8,SCRATCH16
	jmp	calldi2
rpe:	getf
	jpo	fetch2
	pop1	PC16
	jmp	fetch2
pchl:	movw	HL16,PC16
	jmp	fetch2
jpe1:	getf
	jpo	bump2b
	movw	(PC),PC16
	jmp	fetch2
xchgx:	xchgw	HL16,DE
	jmp	fetch2
cpe:	getf
	jpe	call2
	jmp	bump2b
xri:	xorb	(PC),A
	jmp	bump1f
rst5:	movw	$5*8,SCRATCH16
	jmp	calldi2

# routines used by e0-ff

call2:
	movw	(PC),SCRATCH16
	incw	PC16
	incw	PC16
calldi2:			# come here for RSTx, di contains new PC
	push1	PC16
	movw	SCRATCH16,PC16
fetch2:
	jmp	fetch
bump2b:
	addw	$2,PC16		# skip past two byte operand
	jmp	fetch

# f0 - ff

rp:	getf
	js	fetch2
	pop1	PC16
	jmp	fetch2
poppsw:	pop1	PSW
	xchgb	A,FLAGS
	jmp	fetch2
jpx:	getf
	js	bump2b
	movw	(PC),PC16
	jmp	fetch2
cp:	getf
	jns	call3
	jmp	bump2b
pushpsw:	xchgb	A,FLAGS
	push1	PSW
	xchgb	A,FLAGS
	jmp	fetch2
ori:	orb	(PC),A
	jmp	bump1f
rst6:	movw	$6*8,SCRATCH16
	jmp	calldi2
rm:	getf
	jns	fetch3
	pop1	PC16
fetch3:	jmp	fetch2
sphl:	movw	HL16,SP16
	jmp	fetch2
jm:	getf
	jns	bump2b
	movw	(PC),PC16
	jmp	fetch2
call3:	jmp	call2
cm:	getf
	js	call3
	jmp	bump2b
cpi:	cmpb	(PC),A
	jmp	bump1f
rst7:	movw	$7*8,SCRATCH16
	jmp	calldi2

