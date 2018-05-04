#	title	sim80 - 8080 simulator with ISIS-II front end
#	page	66,128
#	name	sim80

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

	.data

	.globl	mem8080		# pointer to base of 8080 memory block, always
				# guaranteed to have zero in its low 16 bits

# 8080 register equates

#a	 equ	 al
#flags	 equ	 ah
#psw	 equ	 ax
#b	 equ	 ch
#c	 equ	 cl
#bc	 equ	 bx
#d	 equ	 dh
#e	 equ	 dl
#de	 equ	 dx
#h	 equ	 bh
#l	 equ	 bl
#hl	 equ	 bx
#m	 equ	 byte ptr [bx]
#pc	 equ	 si
#scratch equ	 di

# Register values passed to ISIS-II from simulator

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
	mov	RDI,traceret		# save place to resume decoding
	movw	%ax,savepsw
	movw	%cx,savebc
	movw	%dx,savede
	movw	%bx,savehl
	movw	%sp,savesp
	movw	%si,savepc
	mov	cstack,RSP		# use alternate stack
	call	trace8080
resume:
	mov	mem8080,RAX		# get base of 8080 memory
	mov	RAX,RCX			# copy it to all 8080 registers
	mov	RAX,RDX
	mov	RAX,RBX
	mov	RAX,RSP
	mov	RAX,RSI
	movw	savepsw,%ax		# set 8080 registers (low words)
	movw	savebc,%cx
	movw	savede,%dx
	movw	savehl,%bx
	movw	savesp,%sp
	movw	savepc,%si
	jmp	decode			# resume decoding

# HALT - save registers and call ISIS-II emulator.
#
# This routine is called to emulate illegal instructions.  It
# is assumed that FD is used at the ISIS and monitor entry points
# to break emulation.  The FD must be followed by a C9 (RET).

halt:
	movw	%ax,savepsw
	movw	%cx,savebc
	movw	%dx,savede
	movw	%bx,savehl
	movw	%sp,savesp
	movw	%si,savepc
	mov	cstack,RSP		# use alternate stack
	call	isis			# when doing ISIS stuff
	jmp	resume			# resume decoding

# GO8080 - start 8080 program
#
# GO8080 can be used by external programs to start emulation using the
# saved register values.

	.globl	go8080

go8080:
	mov	RSP,cstack		# save C stack pointer
	mov	mem8080,RAX		# get base of 8080 memory
	mov	RAX,RCX			# copy it to all 8080 registers
	mov	RAX,RDX
	mov	RAX,RBX
	mov	RAX,RSP
	mov	RAX,RSI
	movw	savepsw,%ax		# set 8080 registers (low words)
	movw	savebc,%cx
	movw	savede,%dx
	movw	savehl,%bx
	movw	savesp,%sp
	movw	savepc,%si
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
	add	$2,RSI		# skip two-byte operand
	jmp	fetch
bump1f:
	lahf			# save flags
	inc	RSI		# skip past one-byte operand
	jmp	fetch
fetchf:
	lahf			# save flags
	jmp	fetch
bump2:
	incw	%si		# bump program counter by 2
bump1:
	incw	%si		# bump program counter by 1
fetch:
	cmpl	$0, trace	# is trace flag set?
	jnz	dotrace1
decode:
	mov	(RSI),%edi 	# get the opcode
	inc	RSI		# bump the program counter
	and	$0x0ff,RDI 	# mask off high bits of opcode
#if __i386__
	shl	$2,RDI		# make it an address pointer
#else
	shl	$3,RDI		# make it an address pointer
#endif
	jmp	*jmptab(RDI)	# jump to appropriate instruction handler
dotrace1:
	jmp	dotrace

# 1-f

lxib:	movw	(RSI),%cx
	jmp	bump2
staxb:	mov	RSI,RDI
	movw	%cx,%di
	chkdi
	movb	%al,(RDI)
	jmp	fetch
inxb:	incw	%cx
	jmp	fetch
inrb:	getf
	incb	%ch
	jmp	fetchf
dcrb:	getf
	decb	%ch
	jmp	fetchf
mvib:	movb	(RSI),%ch
	jmp	bump1
	getf
rlc:	getf
	rolb	$1,%al
	jmp	fetchf
dadb:	addw	%cx,%bx
testc:	jc	stc1
clc1:	andb	$0x0fe,%ah
	jmp	fetch
stc1:	orb	$1,%ah
	jmp	fetch
ldaxb:	mov	RSI,RDI
	movw	%cx,%di
	movb	(RDI),%al
	jmp	fetch
dcxb:	decw	%cx
	jmp	fetch
inrc:	getf
	incb	%cl
	jmp	fetchf
dcrc:	getf
	decb	%cl
	jmp	fetchf
mvic:	movb	(RSI),%cl
	jmp	bump1
rrc:	getf
	rorb	$1,%al
	jmp	fetchf

# 10-1f

lxid:	movw	(RSI),%dx
	jmp	bump2
staxd:	mov	RSI,RDI
	movw	%dx,%di
	chkdi
	movb	%al,(RDI)
	jmp	fetch
inxd:	incw	%dx
	jmp	fetch
inrd:	getf
	incb	%dh
	jmp	fetchf
dcrd:	getf
	decb	%dh
	jmp	fetchf
mvid:	movb	(RSI),%dh
	jmp	bump1
ral:	getf
	rclb	$1,%al
	jmp	fetchf
dadd:	addw	%dx,%bx
	jmp	testc
ldaxd:	mov	RSI,RDI
	movw	%dx,%di
	movb	(RDI),%al
	jmp	fetch
dcxd:	decw	%dx
	jmp	fetch
inre:	getf
	incb	%dl
	jmp	fetchf
dcre:	getf
	decb	%dl
	jmp	fetchf
mvie:	movb	(RSI),%dl
	jmp	bump1
rar:	getf
	rcrb	$1,%al
	jmp	fetchf

# 20-2f

lxih:	movw	(RSI),%bx
	jmp	bump2
shldx:	mov	RSI,RDI
	movw	(RSI),%di
	chkdi
	movw	%bx,(RDI)
	jmp	bump2
inxh:	incw	%bx
	jmp	fetch
inrh:	getf
	incb	%bh
	jmp	fetchf
dcrh:	getf
	decb	%bh
	jmp	fetchf
mvih:	movb	(RSI),%bh
	jmp	bump1
daa1:	getf
#if __i386__
	daa
#else
	jmp	halt
#endif
	jmp	fetchf
dadh:	addw	%bx,%bx
	jmp	testc
lhld:	mov	RSI,RDI
	movw	(RSI),%di
	chkdi
	movw	(RDI),%bx
	jmp	bump2
dcxh:	decw	%bx
	jmp	fetch
inrl:	getf
	incb	%bl
	jmp	fetchf
dcrl:	getf
	decb	%bl
	jmp	fetchf
mvil:	movb	(RSI),%bl
	jmp	bump1
cma:	notb	%al
	jmp	fetch

# 30-3F

lxisp:	movw	(RSI),%sp
	jmp	bump2
sta:	mov	RSI,RDI
	movw	(RSI),%di
	chkdi
	movb	%al,(RDI)
	jmp	bump2
inxsp:	incw	%sp
	jmp	fetch
inrm:	chkbx
	getf
	incb	(RBX)
	jmp	fetchf
dcrm:	chkbx
	getf
	decb	(RBX)
	jmp	fetchf
mvim:	mov	RSI,RDI
	movw	%bx,%di
	chkdi
	movb	(RSI),%bl
	movb	%bl,(RDI)
	movw	%di,%bx
	jmp	bump1
dadsp:	addw	%sp,%bx
	jmp	testc
lda:	mov	RSI,RDI
	movw	(RSI),%di
	movb	(RDI),%al
	jmp	bump2
dcxsp:	decw	%sp
	jmp	fetch
inra:	getf
	incb	%al
	jmp	fetchf
dcra:	getf
	decb	%al
	jmp	fetchf
mvia:	movb	(RSI),%al
	jmp	bump1
cmc1:	xorb	$1,%ah
	jmp	fetch

# 40-4F

movbb:	movb	%ch,%ch
	jmp	fetch
movbc:	movb	%cl,%ch
	jmp	fetch
movbd:	movb	%dh,%ch
	jmp	fetch
movbe:	movb	%dl,%ch
	jmp	fetch
movbh:	movb	%bh,%ch
	jmp	fetch
movbl:	movb	%bl,%ch
	jmp	fetch
movbm:	movb	(RBX),%ch
	jmp	fetch
movba:	movb	%al,%ch
	jmp	fetch
movcb:	movb	%ch,%cl
	jmp	fetch
movcc:	movb	%cl,%cl
	jmp	fetch
movcd:	movb	%dh,%cl
	jmp	fetch
movce:	movb	%dl,%cl
	jmp	fetch
movch:	movb	%bh,%cl
	jmp	fetch
movcl:	movb	%bl,%cl
	jmp	fetch
movcm:	movb	(RBX),%cl
	jmp	fetch
movca:	movb	%al,%cl
	jmp	fetch

# 50-5F

movdb:	movb	%ch,%dh
	jmp	fetch
movdc:	movb	%cl,%dh
	jmp	fetch
movdd:	movb	%dh,%dh
	jmp	fetch
movde:	movb	%dl,%dh
	jmp	fetch
movdh:	movb	%bh,%dh
	jmp	fetch
movdl:	movb	%bl,%dh
	jmp	fetch
movdm:	movb	(RBX),%dh
	jmp	fetch
movda:	movb	%al,%dh
	jmp	fetch
moveb:	movb	%ch,%dl
	jmp	fetch
movec:	movb	%cl,%dl
	jmp	fetch
moved:	movb	%dh,%dl
	jmp	fetch
movee:	movb	%dl,%dl
	jmp	fetch
moveh:	movb	%bh,%dl
	jmp	fetch
movel:	movb	%bl,%dl
	jmp	fetch
movem:	movb	(RBX),%dl
	jmp	fetch
movea:	movb	%al,%dl
	jmp	fetch

# 60-6F

movhb:	movb	%ch,%bh
	jmp	fetch
movhc:	movb	%cl,%bh
	jmp	fetch
movhd:	movb	%dh,%bh
	jmp	fetch
movhe:	movb	%dl,%bh
	jmp	fetch
movhh:	movb	%bh,%bh
	jmp	fetch
movhl:	movb	%bl,%bh
	jmp	fetch
movhm:	movb	(RBX),%bh
	jmp	fetch
movha:	movb	%al,%bh
	jmp	fetch
movlb:	movb	%ch,%bl
	jmp	fetch
movlc:	movb	%cl,%bl
	jmp	fetch
movld:	movb	%dh,%bl
	jmp	fetch
movle:	movb	%dl,%bl
	jmp	fetch
movlh:	movb	%bh,%bl
	jmp	fetch
movll:	movb	%bl,%bl
	jmp	fetch
movlm:	movb	(RBX),%bl
	jmp	fetch
movla:	movb	%al,%bl
	jmp	fetch

# 70-7F

movmb:	chkbx
	movb	%ch,(RBX)
	jmp	fetch
movmc:	chkbx
	movb	%cl,(RBX)
	jmp	fetch
movmd:	chkbx
	movb	%dh,(RBX)
	jmp	fetch
movme:	chkbx
	movb	%dl,(RBX)
	jmp	fetch
movmh:	chkbx
	movb	%bh,(RBX)
	jmp	fetch
movml:	chkbx
	movb	%bl,(RBX)
	jmp	fetch
movma:	chkbx
	movb	%al,(RBX)
	jmp	fetch
movab:	movb	%ch,%al
	jmp	fetch
movac:	movb	%cl,%al
	jmp	fetch
movad:	movb	%dh,%al
	jmp	fetch
movae:	movb	%dl,%al
	jmp	fetch
movah:	movb	%bh,%al
	jmp	fetch
moval:	movb	%bl,%al
	jmp	fetch
movam:	movb	(RBX),%al
	jmp	fetch
movaa:	movb	%al,%al
	jmp	fetch

# 80-8F

addb:	addb	%ch,%al
	jmp	fetchf
addc:	addb	%cl,%al
	jmp	fetchf
addd:	addb	%dh,%al
	jmp	fetchf
adde:	addb	%dl,%al
	jmp	fetchf
addh:	addb	%bh,%al
	jmp	fetchf
addl:	addb	%bl,%al
	jmp	fetchf
addm:	addb	(RBX),%al
	jmp	fetchf
adda:	addb	%al,%al
	jmp	fetchf
adcb:	getf
	adcb	%ch,%al
	jmp	fetchf
adcc:	getf
	adcb	%cl,%al
	jmp	fetchf
adcd:	getf
	adcb	%dh,%al
	jmp	fetchf
adce:	getf
	adcb	%dl,%al
	jmp	fetchf
adch:	getf
	adcb	%bh,%al
	jmp	fetchf
adcl:	getf
	adcb	%bl,%al
	jmp	fetchf
adcm:	getf
	adcb	(RBX),%al
	jmp	fetchf
adca:	getf
	adcb	%al,%al
	jmp	fetchf

# 90-9F

subb:
	subb	%ch,%al
	jmp	fetchf
subc:
	subb	%cl,%al
	jmp	fetchf
subd:
	subb	%dh,%al
	jmp	fetchf
sube:
	subb	%dl,%al
	jmp	fetchf
subh:
	subb	%bh,%al
	jmp	fetchf
subl:
	subb	%bl,%al
	jmp	fetchf
subm:
	subb	(RBX),%al
	jmp	fetchf
suba:
	subb	%al,%al
	jmp	fetchf
sbbb:	getf
	sbbb	%ch,%al
	jmp	fetchf
sbbc:	getf
	sbbb	%cl,%al
	jmp	fetchf
sbbd:	getf
	sbbb	%dh,%al
	jmp	fetchf
sbbe:	getf
	sbbb	%dl,%al
	jmp	fetchf
sbbh:	getf
	sbbb	%bh,%al
	jmp	fetchf
sbbl:	getf
	sbbb	%bl,%al
	jmp	fetchf
sbbm:	getf
	sbbb	(RBX),%al
	jmp	fetchf
sbba:	getf
	sbbb	%al,%al
	jmp	fetchf

# a0-aF

anab:	andb	%ch,%al
	jmp	fetchf
anac:	andb	%cl,%al
	jmp	fetchf
anad:	andb	%dh,%al
	jmp	fetchf
anae:	andb	%dl,%al
	jmp	fetchf
anah:	andb	%bh,%al
	jmp	fetchf
anal:	andb	%bl,%al
	jmp	fetchf
anam:	andb	(RBX),%al
	jmp	fetchf
anaa:	andb	%al,%al
	jmp	fetchf
xrab:	xorb	%ch,%al
	jmp	fetchf
xrac:	xorb	%cl,%al
	jmp	fetchf
xrad:	xorb	%dh,%al
	jmp	fetchf
xrae:	xorb	%dl,%al
	jmp	fetchf
xrah:	xorb	%bh,%al
	jmp	fetchf
xral:	xorb	%bl,%al
	jmp	fetchf
xram:	xorb	(RBX),%al
	jmp	fetchf
xraa:	xorb	%al,%al
	jmp	fetchf

# b0-bF

orab:	orb	%ch,%al
	jmp	fetchf
orac:	orb	%cl,%al
	jmp	fetchf
orad:	orb	%dh,%al
	jmp	fetchf
orae:	orb	%dl,%al
	jmp	fetchf
orah:	orb	%bh,%al
	jmp	fetchf
oral:	orb	%bl,%al
	jmp	fetchf
oram:	orb	(RBX),%al
	jmp	fetchf
oraa:	orb	%al,%al
	jmp	fetchf
cmpb:	cmpb	%ch,%al
	jmp	fetchf
cmpc:	cmpb	%cl,%al
	jmp	fetchf
cmpd:	cmpb	%dh,%al
	jmp	fetchf
cmpe:	cmpb	%dl,%al
	jmp	fetchf
cmph:	cmpb	%bh,%al
	jmp	fetchf
cmpl:	cmpb	%bl,%al
	jmp	fetchf
cmpm:	cmpb	(RBX),%al
	jmp	fetchf
cmpa:	cmpb	%al,%al
	jmp	fetchf

# c0 - cf

rnz:	getf
	jz	fetch1
	pop1	%si
	jmp	fetch1
popb:	pop1	%cx
	jmp	fetch1
jnz1:	getf
	jz	bump2a
jmp1:	movw	(RSI),%si
	jmp	fetch1
cnz:	getf
	jnz	call1
	jmp	bump2a
pushb:	push1	%cx
	jmp	fetch1
adi:	addb	(RSI),%al
	jmp	bump1f
rst0:	xorw	%di,%di
	jmp	calldi1
rz:	getf
	jnz	fetch1
ret1:	pop1	%si
	jmp	fetch1
jz1:	getf
	jnz	bump2a
	movw	(RSI),%si
	jmp	fetch1
cz:	getf
	jz	call1
	jmp	bump2a
aci:	getf
	adcb	(RSI),%al
	jmp	bump1f
rst1:	movw	$8,%di
	jmp	calldi1

# routines used by c0-df

call1:
	movw	(RSI),%di
	incw	%si
	incw	%si
calldi1:			# come here for RSTx, di contains new PC
	push1	%si
	movw	%di,%si
fetch1:
	jmp	fetch
bump2a:
	addw	$2,%si		# skip past two-byte operand
	jmp	fetch

# d0 - df

call4:	jmp	call1
rnc:	getf
	jc	fetch1
	pop1	%si
	jmp	fetch1
popd:	pop1	%dx
	jmp	fetch1
jnc1:	getf
	jc	bump2a
	movw	(RSI),%si
	jmp	fetch1
cnc:	getf
	jnc	call4
	jmp	bump2a
pushd:	push1	%dx
	jmp	fetch1
sui:	subb	(RSI),%al
	jmp	bump1f
rst2:	movw	2*8,%di
	jmp	calldi1
rc:	getf
	jnc	fetch4
	pop1	%si
fetch4:	jmp	fetch1
jc1:	getf
	jnc	bump2a
	movw	(RSI),%si
	jmp	fetch1
cc:	getf
	jc	call2
	jmp	bump2a
sbi:	getf
	sbbb	(RSI),%al
	jmp	bump1f
rst3:	movw	3*8,%di
	jmp	calldi2

# e0 - ef

rpo:	getf
	jpe	fetch2
	pop1	%si
	jmp	fetch2
poph:	pop1	%bx
	jmp	fetch2
jpo1:	getf
	jpe	bump2c
	movw	(RSI),%si
	jmp	fetch2
xthl:	xchgw	(RSP),%bx
	jmp	fetch2
cpo:	getf
	jpo	call2
bump2c:	jmp	bump2b
pushh:	push1	%bx
	jmp	fetch2
ani:	andb	(RSI),%al
	jmp	bump1f
rst4:	movw	4*8,%di
	jmp	calldi2
rpe:	getf
	jpo	fetch2
	pop1	%si
	jmp	fetch2
pchl:	movw	%bx,%si
	jmp	fetch2
jpe1:	getf
	jpo	bump2b
	movw	(RSI),%si
	jmp	fetch2
xchgx:	xchgw	%bx,%dx
	jmp	fetch2
cpe:	getf
	jpe	call2
	jmp	bump2b
xri:	xorb	(RSI),%al
	jmp	bump1f
rst5:	movw	5*8,%di
	jmp	calldi2

# routines used by e0-ff

call2:
	movw	(RSI),%di
	incw	%si
	incw	%si
calldi2:			# come here for RSTx, di contains new PC
	push1	%si
	movw	%di,%si
fetch2:
	jmp	fetch
bump2b:
	addw	$2,%si		# skip past two byte operand
	jmp	fetch

# f0 - ff

rp:	getf
	js	fetch2
	pop1	%si
	jmp	fetch2
poppsw:	pop1	%ax
	xchgb	%al,%ah
	jmp	fetch2
jpx:	getf
	js	bump2b
	movw	(RSI),%si
	jmp	fetch2
cp:	getf
	jns	call3
	jmp	bump2b
pushpsw:	xchgb	%al,%ah
	push1	%ax
	xchgb	%al,%ah
	jmp	fetch2
ori:	orb	(RSI),%al
	jmp	bump1f
rst6:	movw	6*8,%di
	jmp	calldi2
rm:	getf
	jns	fetch3
	pop1	%si
fetch3:	jmp	fetch2
sphl:	movw	%bx,%sp
	jmp	fetch2
jm:	getf
	jns	bump2b
	movw	(RSI),%si
	jmp	fetch2
call3:	jmp	call2
cm:	getf
	js	call3
	jmp	bump2b
cpi:	cmpb	(RSI),%al
	jmp	bump1f
rst7:	movw	7*8,%di
	jmp	calldi2

