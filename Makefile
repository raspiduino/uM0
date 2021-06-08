APP		= uM0

#ifeq ($(BUILD), sim)
#
#	DEVICE	= atmega16
#	CMD	= simulavr --device $(DEVICE) --file $(APP) -W 0x20,-
#	OPTS	= -DSIM
#else
#	DEVICE	= attiny85
#	CMD	= sudo avrdude -p $(DEVICE) -c avrisp2 -P usb -U flash:w:$(APP).hex:i
#	OPTS	=
#endif

DEVICE = atmega328p

OPT		= -O3 #-O0 -g -ggdb3
CC_FLAGS	=  -Wall -Wextra $(OPT) -mmcu=$(DEVICE) -I/usr/lib/avr/include $(OPTS) -ffunction-sections
LD_FLAGS	=  -Wall -Wextra $(OPT) -mmcu=$(DEVICE) -Wl,--gc-sections -lm -lc
CC		= avr-gcc
LD		= avr-gcc
EXTRA		= avr-size -Ax $(APP) && avr-objcopy -j .text -j .data -O ihex $(APP) $(APP).hex

OBJS		= main.o m0.o mul_atmega.o

$(APP): $(OBJS)
	$(LD) $(LD_FLAGS) -o $(APP) $(OBJS)
	avr-size -Ax $(APP)
	avr-objcopy -j .text -j .data -O ihex $(APP) $(APP).hex

AVR:	$(APP)
	$(CMD)

%.o : %.c
	$(CC) $(CC_FLAGS) -c $< -o $@

%.o : %.S
	$(CC) $(CC_FLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(APP)
