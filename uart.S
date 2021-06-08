;//uses B4 pin to output UART signal
;//assumes clock is 16MHz
;//baud rate: 115200bps
;//per-bit tyme: 139 cycles

uart_delay8:
	
	nop
	ret
	

uart_delay:	;delay 122 cycles not including ret

	ldi   r22, 40
	
uart_delay_loop:
	dec   r22
	brne  uart_delay_loop
	nop
	nop
	
	ret

.globl uart
uart:		;val in: r24
	
	ldi   r25, 8
	cbi   0x18, 4
	rcall uart_delay
	rcall uart_delay8
	
uart_loop:
	
	lsr   r24
	brcc  uart_send0

uart_send1:
	
	nop
	sbi   0x18, 4
	rjmp  uart_sent

uart_send0:
	
	cbi   0x18, 4
	nop
	nop

uart_sent:
	
	rcall uart_delay
	dec   r25
	brne  uart_loop
	
	nop
	nop
	nop
	nop
	nop
	nop
	
	sbi   0x18, 4
	rcall uart_delay
	rcall uart_delay8
	ret

