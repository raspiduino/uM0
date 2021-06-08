typedef unsigned long UInt32;
typedef unsigned short UInt16;
typedef unsigned char UInt8;




void putchar_emu(char c){

	*(volatile UInt8*)0x20000020 = c;
}

asm void putchar_avr(){

	dcd 0x4770BE00
}

void ps(const char* str){
	char c;
	
	while(c = *str++) putchar_avr(c);
}

void itoa_16(char* d, long x){
	
	char t;
	
	if(x < 0){
		
		*d++ = '-';
		x = -x;
	}
	*d++ = '0';
	while(x && !(x >> 28)) x <<= 4;
	
	if(x){
		
		*d++ = 'x';
		
		while(x){
			t = x >> 28;
			x <<= 4;
			*d++ = (t >= 10) ? t + 'A' - 10 : t + '0';
		}
	}
	*d = 0;
}

void itoa_10(char* d, long xx){

	UInt8 nDigits = 0;
	UInt32 t, x;
	
	if(xx < 0){
		*d++ = '-';
		xx = -xx;
	}
	
	x = xx;
	t = xx;
	
	do{
		nDigits++;
		t /= 10;
	}while(t);
	
	d += nDigits;
	*d-- = 0;
	
	do{
		
		*d-- = '0' + (x % 10);
		x /= 10;
		
	}while(x);
}

UInt32 isqrt(UInt32 v){

	UInt32 guess = 0x4000, adj = 0x2000, t;
	
	do{
		t = guess * guess;
		if(t == v)		break;
		else if(t < v)	guess += adj;
		else			guess -= adj;
		adj >>= 1;
	}while(adj);
	
	return guess;
}

void main(){
	UInt32 x, i, L;
	char xs[12];
	
	ps("this is a test!\n");
	
	for(x = 0; x < 1000; x++){
	
		L = isqrt(x);
	
		for(i = 2; i < L; i++) if(!(x % i)) break;
	
		if(i == L){
			itoa_10(xs, x);
			ps(xs);
			ps("\n");
		}
	}
	
	//try some ADC
	{
		UInt32 val = 0, i;
		
		volatile struct{
		
			UInt16	adc;
			UInt8	adcsra;
			UInt8	admux;
			UInt8	adcsr;
		
		} *ADC = (void*)0x20000024;	//hehehe, I kid you not
		
		ADC->adcsra	= 0x87;			//ADC on, clock is Fosc/128 = 125KHz
		ADC->admux	= 0x0C;			//ref is Vcc, right adjusted result, input is 1.1 reference
	
		//trow away first conversion
		ADC->adcsra |= 0x40;		//start
		while(ADC->adcsra & 0x40);	//wait
	
		for(i = 0; i < 16; i++){
		
			ADC->adcsra |= 0x40;		//start
			while(ADC->adcsra & 0x40);	//wait
			val += ADC->adc;
		}
		
		val = (16384 * 1100 + (val >> 1)) / val;
		
		ps("Vcc = ");
		itoa_10(xs, val / 1000);
		val %= 1000;
		ps(xs);
		ps(".");
		itoa_10(xs, val);
		if(val < 100) ps("0");
		if(val < 10) ps("0");
		ps(xs);
		ps("V\n");
	}
	
	
	while(1) *(volatile UInt8*)0x20000036 = 1 << 4;
	
	while(1);
}

asm void _u32_div_f(UInt32 num, UInt32 denom){

	cmp r1, #0
	beq div0

	mov r2, #1
	mov r3, #0

norm_loop:
	
	cmp r1, #0
	bmi div_loop
	lsl r1, r1, #1
	lsl r2, r2, #1

	b norm_loop

div_loop:

	cmp r0, r1
	bcc sub_fail
	sub r0, r0, r1
	orr r3, r2
	
sub_fail:
	
	lsr r1, r1, #1
	lsr r2, r2, #1
	bne div_loop


	mov r1, r0
	mov r0, r3
	bx  lr

div0:
	mov r0, #0
	mov r1, #0
	bx  lr
}


void asm __ARMlet_Startup__(){

	//we assume sp is set up for us already
	mov r0, pc
	sub r0, #4
	mov r10, r0
	bl  main
}
