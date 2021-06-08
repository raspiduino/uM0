;XXX: return from readword/writeword ?
;XXX: unaligned addrs ?
;XXX: oc alignment ?
;XXX: strh strb can be optimized by not reading entire reg

;XXX: SRAM is at 0x20000000 and is limited to 64K for now


;CPU:
;	0x00:	u32 regs[15]
;	0x3C:   u8 oldInstrLowByte

;register mappings:
;	r0	- short-lived temp var (clobbered often)
;	r1	- always zero
;	r2 -r3	- CPU pointer (persistent)
;	r4	- avr_sr_c 	//has AVR's SR, whose C is the only valuable thing
;	r5	- avr_sr_z	//has logical or of all bytes of result (zero if result was zero thus)
;	r6	- avr_sr_n	//has n flag (top bit)
;	r7	- avr_sr_v	//has AVR's SR, whose V is the only valuable thing
;	r12-r15	- PC
;	r16	- top half of previous 16-bit half of a 32bit op
;	r17	- short-lived temp var
;	r18-r21	- 32-bit operand
;	r22-r25	- 32-bit operand
;	r26-r27	- current instruction (until it is clobbered)
;	r28-r29 - used as temp pointer for some instructions
;	r30-r31 - used by memory & register ops (clobbered often)


.globl _CPU
.globl m0_do_mul
.globl bkpt

jumptbl:			//IN: reg(r28)									CLOBBERS: Z(r30..r31)
	pop   r31		;pc hi
	pop   r30		;pc lo
	add   r30, r28
	adc   r31, r1
	ijmp

get_Rx0_r18:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r18..r21)		CLOBBERS: Z(r30..r31), r17
	mov   r17, r26
	andi  r17, 0x07
	lsl   r17
	lsl   r17
	
	movw  r30, r2
	add   r30, r17
	adc   r31, r1
	
	ld    r18, Z+
	ld    r19, Z+
	ld    r20, Z+
	ld    r21, Z
	
	ret

get_Rx0_r22:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r22..r25)		CLOBBERS: Z(r30..r31), r17
	mov   r17, r26
	andi  r17, 0x07
	lsl   r17
	lsl   r17
	
	movw  r30, r2
	add   r30, r17
	adc   r31, r1
	
	ld    r22, Z+
	ld    r23, Z+
	ld    r24, Z+
	ld    r25, Z
	
	ret

get_Rx8_r22:			//IN: instrHi(r27), _CPU(r2-r3)			OUT: Rx(r22..r25)		CLOBBERS: Z(r30..r31)
	mov   r22, r27
	andi  r22, 0x07
	lsl   r22
	lsl   r22
	
	movw  r30, r2
	add   r30, r22
	adc   r31, r1
	
	ld    r22, Z+
	ld    r23, Z+
	ld    r24, Z+
	ld    r25, Z
	ret

get_Rx8_r18:			//IN: instrHi(r27), _CPU(r2-r3)			OUT: Rx(r18..r21)		CLOBBERS: Z(r30..r31)
	mov   r18, r27
	andi  r18, 0x07
	lsl   r18
	lsl   r18
	
	movw  r30, r2
	add   r30, r18
	adc   r31, r1
	
	ld    r18, Z+
	ld    r19, Z+
	ld    r20, Z+
	ld    r21, Z
	ret

get_Rx0L_r22:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r22..r25)		CLOBBERS: Z(r30..r31), r17
	mov   r17, r26
	andi  r17, 0x07
	lsl   r17
	lsl   r17
	sbrc  r26, 7
	ori   r17, 0x20
	
	cpi   r17, 0x3C
	breq  get_Rx0L_r22_isPC
	
	movw  r30, r2
	add   r30, r17
	adc   r31, r1
	
	ld    r22, Z+
	ld    r23, Z+
	ld    r24, Z+
	ld    r25, Z
	ret
	
get_Rx0L_r22_isPC:
	movw  r22, r12
	movw  r24, r14
	subi  r22, -2
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	ret

get_Rx3L_r18:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r18..r21)		CLOBBERS: Z(r30..r31), r17
	mov   r17, r26
	andi  r17, 0x78
	lsr   r17
	
	cpi   r17, 0x3C
	breq  get_Rx3L_r18_isPC
	
	movw  r30, r2
	add   r30, r17
	adc   r31, r1
	
	ld    r18, Z+
	ld    r19, Z+
	ld    r20, Z+
	ld    r21, Z
	ret

get_Rx3L_r18_isPC:

	movw  r18, r12
	movw  r20, r14
	subi  r18, -2
	sbci  r19, -1
	sbci  r20, -1
	sbci  r21, -1
	ret



get_Rx3L_r22:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r22..r25)		CLOBBERS: Z(r30..r31), r17
	mov   r17, r26
	andi  r17, 0x78
	lsr   r17
	
	cpi   r17, 0x3C
	breq  get_Rx3L_r22_isPC
	
	movw  r30, r2
	add   r30, r17
	adc   r31, r1
	
	ld    r22, Z+
	ld    r23, Z+
	ld    r24, Z+
	ld    r25, Z
	ret
	
get_Rx3L_r22_isPC:

	movw  r22, r12
	movw  r24, r14
	subi  r22, -2
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	ret

get_Rx3_r22:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r22..r25)		CLOBBERS: Z(r30..r31)
	mov   r22, r26
	andi  r22, 0x38
	lsr   r22
	
	movw  r30, r2
	add   r30, r22
	adc   r31, r1
	
	ld    r22, Z+
	ld    r23, Z+
	ld    r24, Z+
	ld    r25, Z
	ret

get_Rx3_r18:			//IN: instrLo(r26), _CPU(r2-r3)			OUT: Rx(r18..r21)		CLOBBERS: Z(r30..r31)
	mov   r18, r26
	andi  r18, 0x38
	lsr   r18
	
	movw  r30, r2
	add   r30, r18
	adc   r31, r1
	
	ld    r18, Z+
	ld    r19, Z+
	ld    r20, Z+
	ld    r21, Z
	ret

get_Rx6:			//IN: instrLo(r26), instrHi(r27), _CPU(r2-r3)	OUT: Rx(r18..r21)		CLOBBERS: Z(r30..r31)
	mov   r21, r26
	swap  r21
	andi  r21, 0x0C
	sbrc  r27, 0
	ori   r21, 0x10
	
	movw  r30, r2
	add   r30, r21
	adc   r31, r1
	
	ld    r18, Z+
	ld    r19, Z+
	ld    r20, Z+
	ld    r21, Z
	ret

set_NZ:				//IN: Rx(r22..r25)								CLOBBERS: r0
	
	mov   r6, r25
	mov   r5, r22
	or    r5, r23
	or    r5, r24
	or    r5, r25
	rjmp  m0_instr
	

put_Rx0L_r22:			//IN: instrLo(r26), _CPU(r2-r3), Rx(r22..r25)					CLOBBERS: r26, Z(r30..r31)
;store r22 -> Rd
		
	andi  r26, 0x87
	sbrc  r26, 7
	ori   r26, 0x08
	lsl   r26
	lsl   r26
	
	movw  r30, r2
	add   r30, r26
	adc   r31, r1
	
	st    Z+, r22
	st    Z+, r23
	st    Z+, r24
	st    Z,  r25
	rjmp  m0_instr
	

set_CVNZ_put_Rx0_r22:
	in    r7, 0x3F

set_CNZ_put_Rx0_r22:
	in    r4, 0x3F

set_NZ_put_Rx0_r22:
	mov   r6, r25
	mov   r5, r22
	or    r5, r23
	or    r5, r24
	or    r5, r25

put_Rx0_r22:			//IN: instrLo(r26), _CPU(r2-r3), Rx(r22..r25)					CLOBBERS: r26, Z(r30..r31)
;store r22 -> Rd
		
	andi  r26, 0x07
	lsl   r26
	lsl   r26
	movw  r30, r2
	add   r30, r26
	adc   r31, r1
	
	st    Z+, r22
	st    Z+, r23
	st    Z+, r24
	st    Z,  r25
	rjmp  m0_instr

put_Rx0_r18:			//IN: instrLo(r26), _CPU(r2-r3), Rx(r18..r21)					CLOBBERS: r26, Z(r30..r31)
;store r22 -> Rd
		
	andi  r26, 0x07
	lsl   r26
	lsl   r26
	movw  r30, r2
	add   r30, r26
	adc   r31, r1
	
	st    Z+, r18
	st    Z+, r19
	st    Z+, r20
	st    Z,  r21
	rjmp  m0_instr

put_Rx8_r18:			//IN: instrHi(r27), _CPU(r2-r3), Rx(r18..r21)					CLOBBERS: r27, Z(r30..r31)
;store r18 -> Rd
		
	andi  r27, 0x07
	lsl   r27
	lsl   r27
	movw  r30, r2
	add   r30, r27
	adc   r31, r1
	
	st    Z+, r18
	st    Z+, r19
	st    Z+, r20
	st    Z,  r21
	rjmp  m0_instr


set_NZ_put_Rx8_r22:
	mov   r6, r25
	mov   r5, r22
	or    r5, r23
	or    r5, r24
	or    r5, r25

put_Rx8_r22:			//IN: instrHi(r27), _CPU(r2-r3), Rx(r22..r25)					CLOBBERS: r27, Z(r30..r31)
;store r22 -> Rd
		
	andi  r27, 0x07
	lsl   r27
	lsl   r27
	movw  r30, r2
	add   r30, r27
	adc   r31, r1
	
	st    Z+, r22
	st    Z+, r23
	st    Z+, r24
	st    Z,  r25
	rjmp  m0_instr

get_imm5:			//IN: instrHi(r27) instrLo(r26)		OUT: imm5: r31				CLOBBERS: r30			NOTE: Z flag is set on imm5 - this is used by the callers!
	
	movw  r30, r26
	lsl   r30
	rol   r31
	lsl   r30
	rol   r31
	andi  r31, 0x1F
	ret

get_imm3:			//IN: instrHi(r27) instrLo(r26)		OUT: imm3: r30				CLOBBERS: r31
	
	movw  r30, r26
	lsr   r31
	ror   r30
	lsr   r30
	swap  r30
	andi  r30, 0x07
	ret

m0_adr_w_imm5_x4:		//IN: instrHi(r27) instrLo(r26)		OUT: addr(r22..r25)			CLOBBERS: Y(r28,r29), Z(r30..r31)
	rcall get_Rx3_r22
	movw  r28, r26
	swap  r29
	swap  r28
	andi  r29, 0x70
	andi  r28, 0x0C
	add   r29, r28
	add   r22, r29
	adc   r23, r1
	adc   r24, r1
	adc   r25, r1
	ret

m0_adr_w_imm5_x2:		//IN: instrHi(r27) instrLo(r26)		OUT: addr(r22..r25)			CLOBBERS: Y(r28,r29), Z(r30..r31)
	rcall get_Rx3_r22
	movw  r28, r26
	lsl   r28
	rol   r29
	lsl   r28
	rol   r29
	lsl   r29
	andi  r29, 0x3E
	add   r22, r29
	adc   r23, r1
	adc   r24, r1
	adc   r25, r1
	ret

m0_adr_w_imm5_x1:		//IN: instrHi(r27) instrLo(r26)		OUT: addr(r22..r25)			CLOBBERS: Y(r28,r29), Z(r30..r31)
	rcall get_Rx3_r22
	movw  r28, r26
	lsl   r28
	rol   r29
	lsl   r28
	rol   r29
	andi  r29, 0x1F
	add   r22, r29
	adc   r23, r1
	adc   r24, r1
	adc   r25, r1
	ret

m0_adr_w_reg:			//IN: instrLo(r26)			OUT: addr(r22..r25)			CLOBBERS: Y(r28,r29), Z(r30..r31)
	rcall get_Rx3_r22
	rcall get_Rx6
	add   r22, r18
	adc   r23, r19
	adc   r24, r20
	adc   r25, r21
	ret

m0_adr_w_sp_ofst:		//IN: instrLo(r26)			OUT: addr(r22..r25)			CLOBBERS: r0, r17
	lds   r22, _CPU + 0x34
	lds   r23, _CPU + 0x35
	lds   r24, _CPU + 0x36
	lds   r25, _CPU + 0x37
	clr   r17
	mov   r0, r26
	lsl   r0
	rol   r17
	lsl   r0
	rol   r17
	add   r22, r0
	adc   r23, r17
	adc   r24, r1
	adc   r25, r1
	ret

m0_adr_w_pc_ofst:		//IN: instrLo(r26)			OUT: addr(r22..r25)			CLOBBERS: r0, r17
	
	movw  r22, r12
	movw  r24, r14
	clr   r17
	mov   r0, r26
	lsl   r0
	rol   r17
	lsl   r0
	rol   r17
	add   r22, r0
	adc   r23, r17
	adc   r24, r1
	adc   r25, r1
	subi  r22, -2
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	ret

m0_do_stmdb:			//IN: addr(r22..r25), data(r18..r21)	OUT: addr(r22..r25)			CLOBBERS: Z(r30..r31)
	
	subi  r22, 4
	sbci  r23, 0
	sbci  r24, 0
	sbci  r25, 0
	rjmp  writeword

m0_do_ldmia:			//IN: addr(r22..r25)			OUT: addr(r22..r25), data(r18..r21)	CLOBBERS: Z(r30..r31)
	
	rcall readword
	subi  r22, -4
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	ret


readword:			//IN: addr(r22..r25)			OUT: data(r18..r21)			CLOBBERS: Z(r30..r31)

;	cpi   r24, 0x00
;	brne  fail2
	movw  r30, r22
	cpi   r25, 0x20
	breq  readword_sram
	cpi   r25, 0x40
	brne  fail1
	
readword_flash:
	lpm   r18, Z+
	lpm   r19, Z+
	lpm   r20, Z+
	lpm   r21, Z
	ret

readword_sram:
	ld    r18, Z+
	ld    r19, Z+
	ld    r20, Z+
	ld    r21, Z
	ret


readhalfword:			//IN: addr(r22..r25)			OUT: data(r18..r19)			CLOBBERS: Z(r30..r31)

;	cpi   r24, 0x00
;	brne  fail4
	movw  r30, r22
	cpi   r25, 0x20
	breq  readhalfword_sram
	cpi   r25, 0x40
	brne  fail3
	
readhalfword_flash:
	lpm   r18, Z+
	lpm   r19, Z
	ret

readhalfword_sram:
	ld    r18, Z+
	ld    r19, Z
	ret

readbyte:			//IN: addr(r22..r25)			OUT: data(r18)				CLOBBERS: Z(r30..r31)

;	cpi   r24, 0x00
;	brne  fail6
	movw  r30, r22
	cpi   r25, 0x20
	breq  readbyte_sram
	cpi   r25, 0x40
	brne  fail5
	
readbyte_flash:
	lpm   r18, Z
	ret

readbyte_sram:
	ld    r18, Z
	ret


fail1: rjmp fail1
fail2: rjmp fail2
fail3: rjmp fail3
fail4: rjmp fail4
fail5: rjmp fail5
fail6: rjmp fail6

writeword:			//IN: addr(r22..r25), data(r18..r21)						CLOBBERS: Z(r30..r31)

	cpi   r25, 0x20
	brne  fail7
;	cpi   r24, 0x00
;	brne  fail8
	movw  r30, r22
	st    Z+, r18
	st    Z+, r19
	st    Z+, r20
	st    Z,  r21
	ret

writehalfword:			//IN: addr(r22..r25), data(r18..r19)						CLOBBERS: Z(r30..r31)

	cpi   r25, 0x20
	brne  fail9
;	cpi   r24, 0x00
;	brne  fail10
	movw  r30, r22
	st    Z+, r18
	st    Z,  r19
	ret

writebyte:			//IN: addr(r22..r25), data(r18)							CLOBBERS: Z(r30..r31)

	cpi   r25, 0x20
	brne  fail11
;	cpi   r24, 0x00
;	brne  fail12
	movw  r30, r22
	st    Z, r18
	ret


fail7: rjmp fail7
fail8: rjmp fail8
fail9: rjmp fail9
fail10: rjmp fail10
fail11: rjmp fail11
fail12: rjmp fail12

.globl M0	;assumes r1 = 0
M0:
	;gcc passes param (PC) in r22..r25 ->  store it to PC
	movw  r12, r22
	movw  r14, r24

	;erase previous stack & round it to top of ram again
	in    r30, 0x3D
	ori   r30, 0x0F
	out   0x3D, r30
	
	;set SP for emulated code
	in    r31, 0x3E
	sbiw  r30, 8	;4 levels of calls should be enough for our code
	ldi   r28, 0x20
	andi  r30, 0xFC
	sts   _CPU + 0x34, r30
	sts   _CPU + 0x35, r31
	sts   _CPU + 0x36, r1
	sts   _CPU + 0x37, r28

	;set CPU pointer
	ldi   r31, hi8(_CPU)
	ldi   r30, lo8(_CPU)
	movw  r2, r30
	
	;erase the 32-bit state
	mov   r16, r1

m0_instr:
	
	movw  r22, r12
	movw  r24, r14
	rcall readhalfword
	movw  r26, r18
	subi  r22, -2
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	movw  r12, r22
	movw  r14, r24

	cpse  r16, r1
	rjmp  m0_32bit_p2

m0_16bit:
	mov   r28, r27
	lsr   r28
	rcall jumptbl
	
	;jumptable
	
	rjmp  m0_lsl1		;0b0000000x
	rjmp  m0_lsl1		;0b0000011x
	rjmp  m0_lsl1		;0b0000000x
	rjmp  m0_lsl1		;0b0000011x
	
	rjmp  m0_lsr1		;0b0000100x
	rjmp  m0_lsr1		;0b0000111x
	rjmp  m0_lsr1		;0b0000100x
	rjmp  m0_lsr1		;0b0000111x
	
	rjmp  m0_asr1		;0b0001000x
	rjmp  m0_asr1		;0b0001011x
	rjmp  m0_asr1		;0b0001000x
	rjmp  m0_asr1		;0b0001011x
	
	rjmp  m0_add3		;0b0001100x
	rjmp  m0_sub3		;0b0001101x
	rjmp  m0_add1		;0b0001110x
	rjmp  m0_sub1		;0b0001111x
	
	rjmp  m0_mov1		;0b0010000x
	rjmp  m0_mov1		;0b0010011x
	rjmp  m0_mov1		;0b0010000x
	rjmp  m0_mov1		;0b0010011x
	
	rjmp  m0_cmp1		;0b0010100x
	rjmp  m0_cmp1		;0b0010111x
	rjmp  m0_cmp1		;0b0010100x
	rjmp  m0_cmp1		;0b0010111x
	
	rjmp  m0_add2		;0b0011000x
	rjmp  m0_add2		;0b0011011x
	rjmp  m0_add2		;0b0011000x
	rjmp  m0_add2		;0b0011011x
	
	rjmp  m0_sub2		;0b0011100x
	rjmp  m0_sub2		;0b0011111x
	rjmp  m0_sub2		;0b0011100x
	rjmp  m0_sub2		;0b0011111x
	
	rjmp  m0_dpr_0		;0b0100000x - data processing register (part0: and,eor,lsl2,lsr2,asr2,adc,sbc,ror)
	rjmp  m0_dpr_1		;0b0100001x - data processing register (part1: tst,neg,cmp, cmn, orr, mul,bic,mvn)
	rjmp  m0_sdp_0		;0b0100010x - special data processing (part0: add4, cmp3)
	rjmp  m0_sdp_1		;0b0100011x - special data processing (part1: mov3 & B[L][X])	XXX: may be undefined (see bits for B[L][X])...
	
	rjmp  m0_ldr3		;0b0100100x
	rjmp  m0_ldr3		;0b0100111x
	rjmp  m0_ldr3		;0b0100100x
	rjmp  m0_ldr3		;0b0100111x
	
	rjmp  m0_str2		;0b0101000x
	rjmp  m0_strh2		;0b0101001x
	rjmp  m0_strb2		;0b0101010x
	rjmp  m0_ldrsb		;0b0101011x
	
	rjmp  m0_ldr2		;0b0101100x
	rjmp  m0_ldrh2		;0b0101101x
	rjmp  m0_ldrb2		;0b0101110x
	rjmp  m0_ldrsh		;0b0101111x
	
	rjmp  m0_str1		;0b0110000x
	rjmp  m0_str1		;0b0110001x
	rjmp  m0_str1		;0b0110010x
	rjmp  m0_str1		;0b0110011x
	
	rjmp  m0_ldr1		;0b0110100x
	rjmp  m0_ldr1		;0b0110101x
	rjmp  m0_ldr1		;0b0110110x
	rjmp  m0_ldr1		;0b0110111x
	
	rjmp  m0_strb1		;0b0111000x
	rjmp  m0_strb1		;0b0111001x
	rjmp  m0_strb1		;0b0111010x
	rjmp  m0_strb1		;0b0111011x
	
	rjmp  m0_ldrb1		;0b0111100x
	rjmp  m0_ldrb1		;0b0111101x
	rjmp  m0_ldrb1		;0b0111110x
	rjmp  m0_ldrb1		;0b0111111x
	
	rjmp  m0_strh1		;0b1000000x
	rjmp  m0_strh1		;0b1000001x
	rjmp  m0_strh1		;0b1000010x
	rjmp  m0_strh1		;0b1000011x
	
	rjmp  m0_ldrh1		;0b1000100x
	rjmp  m0_ldrh1		;0b1000101x
	rjmp  m0_ldrh1		;0b1000110x
	rjmp  m0_ldrh1		;0b1000111x
	
	rjmp  m0_str3		;0b1001000x
	rjmp  m0_str3		;0b1001001x
	rjmp  m0_str3		;0b1001010x
	rjmp  m0_str3		;0b1001011x
	
	rjmp  m0_ldr4		;0b1001100x
	rjmp  m0_ldr4		;0b1001101x
	rjmp  m0_ldr4		;0b1001110x
	rjmp  m0_ldr4		;0b1001111x
	
	rjmp  m0_add5		;0b1010000x
	rjmp  m0_add5		;0b1010001x
	rjmp  m0_add5		;0b1010010x
	rjmp  m0_add5		;0b1010011x
	
	rjmp  m0_add6		;0b1010100x
	rjmp  m0_add6		;0b1010101x
	rjmp  m0_add6		;0b1010110x
	rjmp  m0_add6		;0b1010111x
	
	rjmp  m0_add7sub4	;0b1011000x	;todo: when x == 1 -> undefined
	rjmp  m0_xt		;0b1011001x	;todo: when x == 1 -> undefined		SXTH SXTB UXTH UXTB
	rjmp  m0_push		;0b1011010x
	rjmp  m0_cps		;0b1011011x	;todo: may be undefined
	
	rjmp  m0_undef		;0b1011100x
	rjmp  m0_revX		;0b1011101x	;todo: may be undefined			REV REV16 REVSH
	rjmp  m0_pop		;0b1011110x
	rjmp  m0_bkpt_hints	;0b1011111x	;todo: may be undefined			NOP YIELD WFE WFI SEV BKPT
	
	rjmp  m0_stmia		;0b1100000x
	rjmp  m0_stmia		;0b1100001x
	rjmp  m0_stmia		;0b1100010x
	rjmp  m0_stmia		;0b1100011x
	
	rjmp  m0_ldmia		;0b1100100x
	rjmp  m0_ldmia		;0b1100101x
	rjmp  m0_ldmia		;0b1100110x
	rjmp  m0_ldmia		;0b1100111x
	
	rjmp  m0_b1_Zset	;0b1101000x	;BEQ/BNE
	rjmp  m0_b1_Cset	;0b1101001x	;BCS/BCC
	rjmp  m0_b1_Nset	;0b1101010x	;BMI/BPL
	rjmp  m0_b1_Vset	;0b1101011x	;BVS/BVC
	
	rjmp  m0_b1_CsetZclr	;0b1101100x	;BHI/BLS
	rjmp  m0_b1_NeqV	;0b1101101x	;BGE/BLT
	rjmp  m0_b1_ZclrNeqV	;0b1101110x	;BGT/BLE
	rjmp  m0_swi		;0b1101111x	;todo: when x == 0 -> undefined
	
	rjmp  m0_b2		;0b1110000x
	rjmp  m0_b2		;0b1110001x
	rjmp  m0_b2		;0b1110010x
	rjmp  m0_b2		;0b1110011x
	
	rjmp  m0_32bit		;0b1110100x
	rjmp  m0_32bit		;0b1110101x
	rjmp  m0_32bit		;0b1110110x
	rjmp  m0_32bit		;0b1110111x
	
	rjmp  m0_32bit		;0b1111000x
	rjmp  m0_32bit		;0b1111001x
	rjmp  m0_32bit		;0b1111010x
	rjmp  m0_32bit		;0b1111011x
	
	rjmp  m0_32bit		;0b1111100x
	rjmp  m0_32bit		;0b1111101x
	rjmp  m0_32bit		;0b1111110x
	rjmp  m0_32bit		;0b1111111x
	
m0_lsl1:
	
	rcall get_Rx3_r22
	rcall get_imm5
	breq  m0_lsl1_done
		
	m0_lsl1_loop:
		
		lsl   r22
		rol   r23
		rol   r24
		rol   r25
		dec   r31
		brne  m0_lsl1_loop
	
	in    r4, 0x3F
	
m0_lsl1_done:
	rjmp set_NZ_put_Rx0_r22


m0_lsr1:
	
	rcall get_Rx3_r22
	rcall get_imm5
	brne  m0_lsr1_loop
	ldi   r31, 32
		
	m0_lsr1_loop:
		
		lsr   r25
		ror   r24
		ror   r23
		ror   r22
		dec   r31
		brne  m0_lsr1_loop
	
	rjmp  set_CNZ_put_Rx0_r22


m0_asr1:
	
	rcall get_Rx3_r22
	rcall get_imm5
	brne  m0_lsr1_loop
	ldi   r31, 32
		
	m0_asr1_loop:
		
		asr   r25
		ror   r24
		ror   r23
		ror   r22
		dec   r31
		brne  m0_asr1_loop
	
	rjmp  set_CNZ_put_Rx0_r22


m0_add3:
	
	rcall get_Rx3_r22
	rcall get_Rx6
	
	add   r22, r18
	adc   r23, r19
	adc   r24, r20
	adc   r25, r21
	
	rjmp  set_CVNZ_put_Rx0_r22


m0_sub3:
	
	rcall get_Rx3_r22
	rcall get_Rx6
	
	sub   r22, r18
	sbc   r23, r19
	sbc   r24, r20
	sbc   r25, r21
	
	
	

m0_set_flags_store_r22:		;only for SUB & the like

	in    r7, 0x3F
	mov   r4, r7
	inc   r4		;flip C
	rjmp  set_NZ_put_Rx0_r22


m0_add1:
	
	rcall get_Rx3_r22
	rcall get_imm3
	
	add   r22, r30
	adc   r23, r1
	adc   r24, r1
	adc   r25, r1
	
	rjmp  set_CVNZ_put_Rx0_r22


m0_sub1:
	
	rcall get_Rx3_r22
	rcall get_imm3
	
	sub   r22, r30
	sbc   r23, r1
	sbc   r24, r1
	sbc   r25, r1
	
	rjmp  set_CVNZ_put_Rx0_r22


m0_mov1:
	
	clr   r23
	clr   r24
	clr   r25
	mov   r22, r26

	rjmp  set_NZ_put_Rx8_r22


m0_cmp1:
	
	rcall get_Rx8_r22
	
	sub   r22, r26
	sbc   r23, r1
	sbc   r24, r1
	sbc   r25, r1
	
m0_set_flags_invC_r22:

	in    r7, 0x3F
	mov   r4, r7
	inc   r4		;flip C
	rjmp  set_NZ

m0_add2:
	
	rcall get_Rx8_r22
	
	add   r22, r26
	adc   r23, r1
	adc   r24, r1
	adc   r25, r1
	
	in    r4, 0x3F
	mov   r7, r4
	rjmp  set_NZ_put_Rx8_r22


m0_sub2:
	
	rcall get_Rx8_r22
	
	sub   r22, r26
	sbc   r23, r1
	sbc   r24, r1
	sbc   r25, r1
	
	in    r7, 0x3F
	mov   r4, r7
	inc   r4		;flip C
	rjmp  set_NZ_put_Rx8_r22


m0_dpr_0:
	
	rcall get_Rx0_r22
	rcall get_Rx3_r18
	
	mov   r28, r26
	andi  r28, 0xC0
	
	sbrc  r27, 0
	rjmp  m0_dpr_01

m0_dpr_00:	; and,eor,lsl2,lsr2

	cpi   r28, 0x40
	breq  m0_eor
	cpi   r28, 0x80
	breq  m0_lsl2
	cpi   r28, 0xC0
	breq  m0_lsr2

m0_and:
	
	and   r22, r18
	and   r23, r19
	and   r24, r20
	and   r25, r21
	rjmp  m0_dpr_0_fini

m0_eor:
	
	eor   r22, r18
	eor   r23, r19
	eor   r24, r20
	eor   r25, r21

m0_goto_dpr_0_fini_0:
	rjmp  m0_dpr_0_fini


m0_lsl2:
		
		cpi   r18, 0
		breq  m0_goto_dpr_0_fini_0
		cpi   r18, 32
		brcs  m0_lsl2_overshift
	
	m0_lsl2_shift:
		
		lsl   r22
		rol   r23
		rol   r24
		rol   r25
		dec   r18
		brne  m0_lsl2_shift
		rjmp  m0_lsl2_doneshift
	
	m0_lsl2_overshift:
		
		clc
	
	m0_lsl2_doneshift:
		
		in    r4, 0x3F
		
m0_goto_dpr_0_fini_1:
		rjmp  m0_dpr_0_fini

m0_lsr2:
		
		cpi   r18, 0
		breq  m0_goto_dpr_0_fini_1
		cpi   r18, 32
		brcs  m0_lsr2_overshift
	
	m0_lsr2_shift:
		
		lsr   r25
		ror   r24
		ror   r23
		ror   r22
		dec   r18
		brne  m0_lsr2_shift
		rjmp  m0_lsr2_doneshift
	
	m0_lsr2_overshift:
		
		clc
	
	m0_lsr2_doneshift:
		
		in    r4, 0x3F
	
m0_goto_dpr_0_fini_2:
		rjmp  m0_dpr_0_fini

m0_dpr_01:	; asr2,adc,sbc,ror

	cpi   r28, 0x40
	breq  m0_adc
	cpi   r28, 0x80
	breq  m0_sbc
	cpi   r28, 0xC0
	breq  m0_ror

m0_asr2:
	
		cpi   r18, 0
		breq  m0_goto_dpr_0_fini_2
		cpi   r18, 32
		brcc  m0_asr2_shift
		
		ldi   r18, 32
	
	m0_asr2_shift:
		
		asr   r25
		ror   r24
		ror   r23
		ror   r22
		dec   r18
		brne  m0_asr2_shift
		rjmp  m0_asr2_doneshift
	
	m0_asr2_doneshift:
		
		in    r4, 0x3F
		rjmp  m0_dpr_0_fini

m0_adc:
	
	lsr   r4			;copy saved carry flag to carry
	
	adc   r22, r18
	adc   r23, r18
	adc   r24, r20
	adc   r25, r21
	
	in    r4, 0x3F
	mov   r7, r4
	rjmp  m0_dpr_0_fini

m0_sbc:
	
	inc   r4			;flip C
	lsr   r4			;copy saved carry flag to carry
	
	sbc   r22, r18
	sbc   r23, r19
	sbc   r24, r20
	sbc   r25, r21
	
	in    r7, 0x3F
	mov   r4, r7
	inc   r4			;flip C
	rjmp  m0_dpr_0_fini

m0_ror:
	
		cpi   r18, 0
		breq  m0_dpr_0_fini
		andi  r18, 0x0F
		brne  m0_ror2_shift
		
		rol   r25
		in    r4, 0x3F
		ror   r25
		rjmp  m0_dpr_0_fini
	
	m0_ror2_shift:
		
		clc
		sbrc  r22, 0
		bset  0
		ror   r25
		ror   r24
		ror   r23
		ror   r22
		dec   r18
		brne  m0_ror2_shift
		rjmp  m0_ror2_doneshift
	
	m0_ror2_doneshift:
		
		in    r4, 0x3F

m0_dpr_0_fini:
	
	rjmp  set_NZ_put_Rx0_r22

m0_dpr_1:

	rcall get_Rx0_r22
	rcall get_Rx3_r18
	
	mov   r28, r26
	andi  r28, 0xC0
	
	sbrc  r27, 0
	rjmp  m0_dpr_11

m0_dpr_10:	; tst,neg,cmp,cmn

	cpi   r28, 0x40
	breq  m0_neg
	cpi   r28, 0x80
	breq  m0_cmp
	cpi   r28, 0xC0
	breq  m0_cmn

m0_tst:
	
	and   r22, r18
	and   r23, r19
	and   r24, r20
	and   r25, r21
	rjmp  set_NZ

m0_neg:
	
	clr   r18
	clr   r19
	movw  r20, r18
	sub   r18, r22
	sbc   r19, r23
	sbc   r20, r24
	sbc   r21, r25
	rjmp  m0_set_flags_store_r22

m0_cmp:
	sub   r22, r18
	sbc   r23, r19
	sbc   r24, r20
	sbc   r25, r21
	
	rjmp  m0_set_flags_invC_r22

m0_cmn:
	
	add   r22, r18
	adc   r23, r19
	adc   r24, r20
	adc   r25, r21
	
	in    r4, 0x3F
	mov   r7, r4
	rjmp  set_NZ

m0_dpr_11:	; orr,mul,bic,mvn

	cpi   r28, 0x40
	breq  m0_mul
	cpi   r28, 0x80
	breq  m0_bic
	cpi   r28, 0xC0
	breq  m0_mvn

m0_orr:

	or    r22, r18
	or    r23, r19
	or    r24, r20
	or    r25, r21
	rjmp  m0_dpr_0_fini

m0_mul:
	
	rcall m0_do_mul
	rjmp  m0_dpr_0_fini

m0_bic:
	
	com   r18
	com   r19
	com   r20
	com   r21
	and   r22, r18
	and   r23, r19
	and   r24, r20
	and   r25, r21
	rjmp  m0_dpr_0_fini

m0_mvn:
	
	com   r18
	com   r19
	com   r20
	com   r21
	movw  r12, r18
	movw  r24, r20
	rjmp  m0_dpr_0_fini

m0_sdp_0:
	
	rcall get_Rx0L_r22
	rcall get_Rx3L_r18
	sbrc  r27, 0
	rjmp  m0_cmp3

m0_add4:
	
	add   r22, r18
	adc   r23, r19
	adc   r24, r20
	adc   r25, r21

m0_sdp_0_fini:

	rjmp put_Rx0L_r22

m0_cmp3:
	
	sub   r22, r18
	sbc   r23, r19
	sbc   r24, r20
	sbc   r25, r21
	rjmp  m0_set_flags_invC_r22

m0_sdp_1:
	
	rcall get_Rx3L_r22
	sbrs  r27, 0
	rjmp  m0_sdp_0_fini

m0_blx2:
	
	sbrs  r26, 7
	rjmp  m0_bx
	sts   _CPU + 0x38, r12
	sts   _CPU + 0x39, r13
	sts   _CPU + 0x3A, r14
	sts   _CPU + 0x3B, r15

m0_bx:
	
	andi  r22, 0xFE
	movw  r12, r22
	movw  r14, r24
	rjmp  m0_instr


m0_ldr3:
	
	rcall m0_adr_w_pc_ofst
	andi  r22, 0xFC
	rcall readword
	rjmp  put_Rx8_r18


m0_str2:
	
	rcall m0_adr_w_reg
	rcall get_Rx0_r18
	rcall writeword
	rjmp  m0_instr


m0_strh2:
	
	rcall m0_adr_w_reg
	rcall get_Rx0_r18
	rcall writehalfword
	rjmp  m0_instr


m0_strb2:
	
	rcall m0_adr_w_reg
	rcall get_Rx0_r18
	rcall writebyte
	rjmp  m0_instr


m0_ldrsb:
	
	rcall m0_adr_w_reg
	rcall readbyte
	clr   r19
	clr   r20
	clr   r21
	sbrs  r18, 7
	rjmp  m0_ldrsb_ext_done
	com   r19
	com   r20
	com   r21
	
m0_ldrsb_ext_done:
	rjmp  put_Rx0_r18



m0_ldr2:
	
	rcall m0_adr_w_reg
	rcall readword
	rjmp  put_Rx0_r18



m0_ldrh2:

	rcall m0_adr_w_reg
	rcall readhalfword
	clr   r20
	clr   r21
	rjmp  put_Rx0_r18



m0_ldrb2:
	
	rcall m0_adr_w_reg
	rcall readbyte
	clr   r19
	clr   r20
	clr   r21
	rjmp  put_Rx0_r18



m0_ldrsh:
	
	rcall m0_adr_w_reg
	rcall readhalfword
	clr   r20
	clr   r21
	sbrs  r19, 7
	rjmp  m0_ldrsh_ext_done
	com   r20
	com   r21
	
m0_ldrsh_ext_done:
	rjmp  put_Rx0_r18



m0_str1:
	
	rcall m0_adr_w_imm5_x4
	rcall get_Rx0_r18
	rcall writeword
	rjmp  m0_instr


m0_ldr1:

	rcall m0_adr_w_imm5_x4
	rcall readword
	rjmp  put_Rx0_r18


m0_strb1:

	rcall m0_adr_w_imm5_x1
	rcall get_Rx0_r18
	rcall writebyte
	rjmp  m0_instr

m0_ldrb1:

	rcall m0_adr_w_imm5_x1
	rcall readbyte
	clr   r19
	clr   r20
	clr   r21
	rjmp  put_Rx0_r18


m0_strh1:

	rcall m0_adr_w_imm5_x2
	rcall get_Rx0_r18
	rcall writehalfword
	rjmp  m0_instr


m0_ldrh1:
	
	rcall m0_adr_w_imm5_x2
	rcall readhalfword
	clr   r20
	clr   r21
	rjmp  put_Rx0_r18



m0_str3:

	rcall m0_adr_w_sp_ofst
	rcall get_Rx8_r18
	rcall writeword
	rjmp  m0_instr


m0_ldr4:
	
	rcall m0_adr_w_sp_ofst
	rcall readword
	rjmp  put_Rx8_r18


m0_add5:
	
	rcall m0_adr_w_pc_ofst
	rjmp  put_Rx8_r22


m0_add6:
	
	rcall m0_adr_w_sp_ofst
	rjmp  put_Rx8_r22


m0_add7sub4:
	
	lds   r22, _CPU + 0x34
	lds   r23, _CPU + 0x35
	lds   r24, _CPU + 0x36
	lds   r25, _CPU + 0x37
	
	clr   r18
	lsl   r26
	rol   r19	;bottom bit now has what was bit7
	lsl   r26
	rol   r18	;r18:r26 is now the value to add/sub
	
	sbrc  r19, 0
	rjmp  m0_add7sub4_s
	
m0_add7sub4_a:
	
	add   r22, r26
	adc   r23, r18
	adc   r24, r1
	adc   r25, r1
	rjmp  m0_add7sub4_f

m0_add7sub4_s:
	
	sub   r22, r26
	sbc   r23, r18
	sbc   r24, r1
	sbc   r25, r1
	
m0_add7sub4_f:
	
	sts   _CPU + 0x34, r22
	sts   _CPU + 0x35, r23
	sts   _CPU + 0x36, r24
	sts   _CPU + 0x37, r25
	rjmp  m0_instr

m0_xt:

	rcall get_Rx3_r22
	clr   r28
	sbrc  r26, 7
	rjmp  m0_xt_u
	
m0_xt_s:
	
	sbrc  r26, 6
	rjmp  m0_sxtb

m0_sxth:
	
	sbrc  r23, 7
	ser   r28
	mov   r24, r28
	mov   r25, r28
	rjmp  put_Rx0_r22
	
m0_sxtb:
	
	sbrc  r22, 7
	ser   r28
	mov   r23, r28
	mov   r24, r28
	mov   r25, r28
	rjmp  put_Rx0_r22

m0_xt_u:
	
	sbrc  r26, 6
	mov   r23, r1
	mov   r24, r1
	mov   r25, r1
	rjmp  put_Rx0_r22


m0_push:
	
	lds   r22, _CPU + 0x34	;sp -> r22
	lds   r23, _CPU + 0x35
	lds   r24, _CPU + 0x36
	lds   r25, _CPU + 0x37
	
	sbrs  r27, 0
	rjmp  m0_push_no_lr
	
	lds   r18, _CPU + 0x38	;lr -> r18
	lds   r19, _CPU + 0x39
	lds   r20, _CPU + 0x3A
	lds   r21, _CPU + 0x3B
	rcall m0_do_stmdb
	
m0_push_no_lr:
	
	movw r28, r2
	adiw r28, 0x20		;point to r8

m0_push_loop:
	
	sbiw  r28, 4
	lsl   r26
	brcc  m0_push_check_done
	ldd   r18, Y + 0
	ldd   r19, Y + 1
	ldd   r20, Y + 2
	ldd   r21, Y + 3
	rcall m0_do_stmdb
	
	rjmp  m0_push_loop

m0_push_check_done:
	
	brne  m0_push_loop
	
	sts   _CPU + 0x34, r22
	sts   _CPU + 0x35, r23
	sts   _CPU + 0x36, r24
	sts   _CPU + 0x37, r25
	rjmp  m0_instr

m0_cps:
	
	;TODO: this

m0_revX:
	
	rcall get_Rx3_r22
	sbrc  r26, 7
	rjmp  m0_revsh
	sbrc  r26, 6
	rjmp  m0_rev16

m0_rev:
	
	eor   r22, r25
	eor   r25, r22
	eor   r22, r25
	eor   r23, r24
	eor   r24, r23
	eor   r23, r24
	rjmp  put_Rx0_r22


m0_rev16:
	
	eor   r23, r22
	eor   r22, r23
	eor   r23, r22
	rjmp  put_Rx0_r22


m0_revsh:
	
	clr   r28
	eor   r23, r22
	eor   r22, r23
	eor   r23, r22
	sbrc  r23, 7
	ser   r28
	mov   r24, r28
	mov   r25, r28
	rjmp  put_Rx0_r22


m0_pop:
	
	lds   r22, _CPU + 0x34	;sp -> r22
	lds   r23, _CPU + 0x35
	lds   r24, _CPU + 0x36
	lds   r25, _CPU + 0x37
	
	movw  r28, r2
	sbiw  r28, 4

m0_pop_loop:
	
	adiw  r28, 4
	lsr   r26
	brcc  m0_pop_check_done
	rcall m0_do_ldmia
	std   Y + 0, r18
	std   Y + 1, r19
	std   Y + 2, r20
	std   Y + 3, r21
	
	rjmp  m0_pop_loop

m0_pop_check_done:
	
	brne  m0_pop_loop
	
	sbrs  r27, 0
	rjmp  m0_pop_no_pc

m0_pop_pc:
	
	rcall m0_do_ldmia
	movw  r12, r18
	movw  r14, r20
	dec   r12
	
m0_pop_no_pc:

	sts   _CPU + 0x34, r22
	sts   _CPU + 0x35, r23
	sts   _CPU + 0x36, r24
	sts   _CPU + 0x37, r25
	rjmp  m0_instr


m0_bkpt_hints:

	sbrs  r27, 0
	rjmp  m0_bkpt

m0_hints:

	cpi   r26, 0x30
	breq  m0_wfi		;WFI
	cpi   r26, 0x20
	breq  m0_wfe		;WFE
	cpi   r26, 0x40
	breq  m0_wfe		;SEV
	cpi   r26, 0x00
	breq  m0_nop_yield	;NOP
	cpi   r26, 0x10
	breq  m0_nop_yield	;YIELD
	rjmp  m0_undef


m0_nop_yield:
	
	;nothing to do here
	rjmp m0_instr

m0_wfe:
	
	;TODO

m0_wfi:
	
	;TODO

m0_sev:
	
	;TODO
	rjmp  m0_instr

m0_bkpt:
	
	mov   r24, r26
	rcall bkpt
	rjmp  m0_instr

m0_stmia:

	rcall get_Rx8_r22
	movw  r28, r26
	sbiw  r28, 4
	
m0_stmia_loop:
	
	adiw  r28, 4
	lsr   r26
	brcc  m0_stmia_check_done
	ldd   r18, Y + 0
	ldd   r19, Y + 1
	ldd   r20, Y + 2
	ldd   r21, Y + 3
	rcall writeword
	subi  r22, -4
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	
m0_stmia_check_done:
	
	brne  m0_stmia_loop
	rjmp  put_Rx8_r22


m0_ldmia:

	rcall get_Rx8_r22
	mov   r17, r27
	andi  r17, 0x07
	inc   r17
	movw  r28, r26
	sbiw  r28, 4
	clt
	
m0_ldmia_loop:
	
	adiw  r28, 4
	dec   r17
	lsr   r26
	brcc  m0_ldmia_check_done
	
	cpse  r17, r1
	set
	
	rcall readword
	subi  r22, -4
	sbci  r23, -1
	sbci  r24, -1
	sbci  r25, -1
	std   Y + 0, r18
	std   Y + 1, r19
	std   Y + 2, r20
	std   Y + 3, r21
	
m0_ldmia_check_done:
	
	brne  m0_ldmia_loop
	brts  m0_goto_instr_0	;no writeback if T is set
	rjmp  put_Rx8_r22
	
m0_goto_instr_0:
	rjmp  m0_instr


m0_b1_Zset:

	cpse  r5, r1
	rjmp  m0_b1_false
	rjmp  m0_b1_true
	

m0_b1_Cset:

	sbrc  r4, 0
	rjmp  m0_b1_true
	rjmp  m0_b1_false
	

m0_b1_Nset:

	sbrc  r6, 7
	rjmp  m0_b1_true
	rjmp  m0_b1_false

m0_b1_Vset:

	sbrc  r7, 3
	rjmp  m0_b1_true
	rjmp  m0_b1_false

m0_b1_CsetZclr:

	sbrs  r4, 0
	rjmp  m0_b1_false
	cpse  r5, r1
	rjmp  m0_b1_true
	rjmp  m0_b1_false

m0_b1_ZclrNeqV:

	cp    r5, r1
	breq  m0_b1_false

m0_b1_NeqV:

	mov   r28, r7
	swap  r28
	eor   r28, r6
	brmi  m0_b1_false
	rjmp  m0_b1_true

m0_b1_false:
	
	sbrs  r27, 0
	rjmp  m0_instr
	rjmp  m0_br1_exec

m0_b1_true:
	
	sbrc  r27, 0
	rjmp  m0_instr

m0_br1_exec:
	
	clr   r28
	lsl   r26
	brcc  m0_br1_nonneg
	ser   r28
	
m0_br1_nonneg:
	add   r12, r26
	adc   r13, r28
	adc   r14, r28
	adc   r15, r28
	ldi   r26, 2
	add   r12, r26
	adc   r13, r1
	adc   r14, r1
	adc   r15, r1
	rjmp  m0_instr

m0_swi:

	;TODO: this

m0_b2:

	clr   r28
	lsl   r26
	rol   r27
	andi  r27, 0x0F
	sbrs  r27, 3
	rjmp  m0_b2_pos_ext
	ori   r27, 0xF0
	ser   r28
m0_b2_pos_ext:
	mov   r29, r28
	adiw  r26, 2
	adc   r28, r1
	adc   r29, r1
	add   r12, r26
	adc   r13, r27
	adc   r14, r28
	adc   r15, r29
	rjmp  m0_instr

m0_32bit:
	
	sts   _CPU + 0x3C, r26
	mov   r16, r27
	rjmp  m0_instr

m0_32bit_p2:
	
	mov   r23, r16
	lds   r22, _CPU + 0x3C
	mov   r16, r1	;erase the state

	;now: instr is r23:r22:r27:r26

	mov   r28, r27
	andi  r28, 0xD0
	breq  m0_some_32bits
	cpi   r28, 0xD0
	breq  m0_bl

m0_goto_undef_0:
	rjmp  m0_undef

m0_bl:

	;move pc to LR + 1
	inc   r12
	sts   _CPU + 0x38, r12
	sts   _CPU + 0x39, r13
	sts   _CPU + 0x3A, r14
	sts   _CPU + 0x3B, r15
	dec   r12
	
	;pc += ((first & 0x7FF) << 12) + ((second & 0x7FF) << 1)
	lsl  r26
	rol  r27
	andi r27, 0x0F
	andi r23, 0x07
	swap r23
	swap r22
	mov  r28, r22
	andi r28, 0x0F
	andi r22, 0xF0
	or   r27, r22
	or   r23, r28

	;offset is now in r23:r27:r26 - sign extend it
	clr  r28
	sbrc r23, 6
	ser  r28
	lsl  r23
	asr  r23
	
	;full offset now in r28:r23:r27:r26 - add it to pc
	; note we do not need to add 2 to pc this is soecial!
	
	add  r12, r26
	adc  r13, r27
	adc  r14, r23
	adc  r15, r28
	rjmp  m0_instr

m0_some_32bits:
	
	cpi   r23, 0xF3
	brne  m0_goto_undef_0
	mov   r28, r22
	swap  r28
	andi  r28, 0x0F
	rcall jumptbl
	
	rjmp  m0_undef	;0b0000
	rjmp  m0_undef	;0b0001
	rjmp  m0_undef	;0b0010
	rjmp  m0_undef	;0b0011
	
	rjmp  m0_undef	;0b0100
	rjmp  m0_undef	;0b0101
	rjmp  m0_undef	;0b0110
	rjmp  m0_undef	;0b0111
	
	rjmp  m0_msr	;0b1000
	rjmp  m0_msr	;0b1001
	rjmp  m0_undef	;0b1010
	rjmp  m0_misc32	;0b1011
	
	rjmp  m0_undef	;0b1100
	rjmp  m0_undef	;0b1101
	rjmp  m0_mrs	;0b1110
	rjmp  m0_mrs	;0b1111


m0_msr:
	
	;TODO


m0_mrs:
	
	;TODO



m0_misc32:

	mov   r28, r26
	andi  r28, 0xF0
	
	cpi   r28, 0x40
	breq  m0_nothing_to_do	;DSB
	cpi   r28, 0x50
	breq  m0_nothing_to_do	;DMB
	cpi   r28, 0x60
	breq  m0_nothing_to_do	;ISB
	rjmp  m0_undef

m0_nothing_to_do:
	
	rjmp m0_instr

m0_undef:
	
	;TODO
	rjmp  m0_undef;
	
