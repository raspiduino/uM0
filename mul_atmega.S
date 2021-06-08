;in: u32 r22..r25  u32 r18..r21    out -> r22..r25   clobber: r17, r30, r31, r0  clobbers & clears: r1

.globl m0_do_mul		;34 cycles + ret
m0_do_mul:
	mul   r25, r18
	mov   r17, r0
	mul   r24, r19
	add   r17, r0
	mul   r23, r20
	add   r17, r0
	mul   r22, r21
	add   r17, r0
	mul   r24, r18
	add   r17, r1
	mov   r21, r0
	mul   r22, r18
	movw  r30, r0
	mul   r22, r20
	add   r21, r0
	adc   r17, r1
	mul   r23, r19
	add   r21, r0
	adc   r17, r1
	clr   r25
	mul   r23, r18
	add   r31, r0
	adc   r21, r1
	adc   r17, r25
	mul   r22, r19
	add   r31, r0
	adc   r21, r1
	adc   r17, r25
	movw  r22, r30
	mov   r24, r21
	mov   r25, r17
	clr   r1
	ret