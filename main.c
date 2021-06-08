// This file was originally created by Dmitry Grinberg at http://dmitry.gr/?r=05.Projects&proj=08.%20uM0
// Licensed under GPL-v3

#define F_CPU   16000000UL
#define BAUDRATE 9600 // 9600 bps
#include <avr/wdt.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <math.h>
#include <stdarg.h>
#include <stdio.h>

typedef unsigned long UInt32;
typedef unsigned short UInt16;
typedef unsigned char UInt8;

struct{

    UInt32 regs[15];
    UInt8 first_half_low;   //low byte of first half of 32-bit instr
}_CPU;

extern void __attribute__((noreturn)) M0(unsigned long pc);

void bkpt(){

    // wait for transmit buffer to be empty
    while(!(UCSR0A & (1 << UDRE0)));

    // Send the output!
    UDR0 = _CPU.regs[0];
}

int __attribute__((noreturn)) main(){

    // Watchdog
    cli();
    wdt_reset();
    wdt_disable();

    // Init the UART of Arduino UNO
    // From http://www.rjhcoding.com/avrc-uart.php
    // ubrr is calculated by ubrr = (f/(16baud))-1

    // set baudrate in UBRR
    UBRR0L = (uint8_t)(103);
    UBRR0H = (uint8_t)(103 >> 8);

    // Set Frame Format
    UCSR0C = (0 << UMSEL00) | (0 << UPM00) | (0 << USBS0) | (3<<UCSZ00);

    // enable the transmitter and receiver
    UCSR0B |= (1 << RXEN0) | (1 << TXEN0);

    // Emulated program goes here:
    
    static const unsigned char __attribute__((aligned(8),progmem)) x[] = {
        0x78, 0x46, 0x04, 0x38, 0x82, 0x46, 0x00, 0xF0, 0x19, 0xF8, 0x00, 0x00, 0x00, 0xBE, 0x70, 0x47,
        0x00, 0x29, 0x10, 0xD0, 0x01, 0x22, 0x00, 0x23, 0x00, 0x29, 0x02, 0xD4, 0x49, 0x00, 0x52, 0x00,
        0xFA, 0xE7, 0x88, 0x42, 0x01, 0xD3, 0x40, 0x1A, 0x13, 0x43, 0x49, 0x08, 0x52, 0x08, 0xF8, 0xD1,
        0x01, 0x1C, 0x18, 0x1C, 0x70, 0x47, 0x00, 0x20, 0x00, 0x21, 0x70, 0x47, 0x70, 0xB5, 0x84, 0xB0,
        0x3F, 0x48, 0x50, 0x44, 0x00, 0xF0, 0xCC, 0xF8, 0x00, 0x25, 0x28, 0x1C, 0x00, 0xF0, 0x8C, 0xF8,
        0x06, 0x1C, 0x02, 0x24, 0x02, 0x2E, 0x08, 0xD9, 0x28, 0x1C, 0x21, 0x1C, 0xFF, 0xF7, 0xD8, 0xFF,
        0x00, 0x29, 0x02, 0xD0, 0x64, 0x1C, 0xB4, 0x42, 0xF6, 0xD3, 0xB4, 0x42, 0x0A, 0xD1, 0x00, 0xA8,
        0x29, 0x1C, 0x00, 0xF0, 0x8D, 0xF8, 0x00, 0xA8, 0x00, 0xF0, 0xB2, 0xF8, 0x31, 0x48, 0x50, 0x44,
        0x00, 0xF0, 0xAE, 0xF8, 0x6D, 0x1C, 0x30, 0x48, 0x85, 0x42, 0xDE, 0xD3, 0x00, 0x22, 0x87, 0x21,
        0x2E, 0x48, 0x81, 0x70, 0x0C, 0x21, 0xC1, 0x70, 0x84, 0x1C, 0x23, 0x78, 0x40, 0x21, 0x0B, 0x43,
        0x23, 0x70, 0x83, 0x78, 0x0B, 0x40, 0x00, 0x2B, 0xFB, 0xD1, 0x00, 0x21, 0x27, 0x4D, 0xA8, 0x1C,
        0x40, 0x23, 0x04, 0x78, 0x1C, 0x43, 0x04, 0x70, 0xAC, 0x78, 0x1C, 0x40, 0x00, 0x2C, 0xFB, 0xD1,
        0x2C, 0x88, 0x12, 0x19, 0x49, 0x1C, 0x10, 0x29, 0xF3, 0xD3, 0x51, 0x08, 0x20, 0x48, 0x08, 0x18,
        0x11, 0x1C, 0xFF, 0xF7, 0x9D, 0xFF, 0x04, 0x1C, 0x1E, 0x48, 0x50, 0x44, 0x00, 0xF0, 0x80, 0xF8,
        0x20, 0x1C, 0x19, 0x49, 0xFF, 0xF7, 0x94, 0xFF, 0x01, 0x1C, 0x00, 0xA8, 0x00, 0xF0, 0x50, 0xF8,
        0x20, 0x1C, 0x15, 0x49, 0xFF, 0xF7, 0x8C, 0xFF, 0x0C, 0x1C, 0x00, 0xA8, 0x00, 0xF0, 0x70, 0xF8,
        0x15, 0x48, 0x50, 0x44, 0x00, 0xF0, 0x6C, 0xF8, 0x00, 0xA8, 0x21, 0x1C, 0x00, 0xF0, 0x40, 0xF8,
        0x64, 0x2C, 0x03, 0xD2, 0x11, 0x48, 0x50, 0x44, 0x00, 0xF0, 0x62, 0xF8, 0x0A, 0x2C, 0x03, 0xD2,
        0x0E, 0x48, 0x50, 0x44, 0x00, 0xF0, 0x5C, 0xF8, 0x00, 0xA8, 0x00, 0xF0, 0x59, 0xF8, 0x0C, 0x48,
        0x50, 0x44, 0x00, 0xF0, 0x55, 0xF8, 0x10, 0x21, 0x0A, 0x48, 0x01, 0x70, 0xFD, 0xE7, 0xC0, 0x46,
        0x2C, 0x02, 0x00, 0x00, 0x3D, 0x02, 0x00, 0x00, 0xE8, 0x03, 0x00, 0x00, 0x24, 0x00, 0x00, 0x20,
        0x00, 0x00, 0x13, 0x01, 0x3F, 0x02, 0x00, 0x00, 0x46, 0x02, 0x00, 0x00, 0x48, 0x02, 0x00, 0x00,
        0x4A, 0x02, 0x00, 0x00, 0x36, 0x00, 0x00, 0x20, 0x07, 0x4B, 0x08, 0x4A, 0x19, 0x1C, 0x59, 0x43,
        0x81, 0x42, 0x07, 0xD0, 0x81, 0x42, 0x01, 0xD2, 0x9B, 0x18, 0x00, 0xE0, 0x9B, 0x1A, 0x52, 0x08,
        0x00, 0x2A, 0xF3, 0xD1, 0x18, 0x1C, 0x70, 0x47, 0x00, 0x40, 0x00, 0x00, 0x00, 0x20, 0x00, 0x00,
        0x70, 0xB5, 0x05, 0x1C, 0x0C, 0x1C, 0x00, 0x26, 0x00, 0x2C, 0x03, 0xDA, 0x2D, 0x20, 0x28, 0x70,
        0x6D, 0x1C, 0x64, 0x42, 0x20, 0x1C, 0x71, 0x1C, 0x09, 0x06, 0x0E, 0x0E, 0x0A, 0x21, 0xFF, 0xF7,
        0x2F, 0xFF, 0x00, 0x28, 0xF7, 0xD1, 0xA9, 0x19, 0x4D, 0x1E, 0x00, 0x20, 0x08, 0x70, 0x20, 0x1C,
        0x0A, 0x21, 0xFF, 0xF7, 0x25, 0xFF, 0x30, 0x31, 0x29, 0x70, 0x6D, 0x1E, 0x20, 0x1C, 0x0A, 0x21,
        0xFF, 0xF7, 0x1E, 0xFF, 0x04, 0x1C, 0x00, 0x2C, 0xF1, 0xD1, 0x70, 0xBC, 0x08, 0xBC, 0x18, 0x47,
        0x10, 0xB5, 0x04, 0x1C, 0x00, 0x20, 0x20, 0x56, 0x64, 0x1C, 0x00, 0x28, 0x06, 0xD0, 0xFF, 0xF7,
        0x0D, 0xFF, 0x00, 0x20, 0x20, 0x56, 0x64, 0x1C, 0x00, 0x28, 0xF8, 0xD1, 0x10, 0xBC, 0x08, 0xBC,
        0x18, 0x47, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3D, 0x00, 0x00, 0x00, 0x2D, 0x01, 0x00, 0x00,
        0x80, 0x07, 0x40, 0x00, 0x91, 0x01, 0x00, 0x00, 0x51, 0x00, 0x00, 0x00, 0x80, 0x07, 0x20, 0x00,
        0xE1, 0x01, 0x00, 0x00, 0x23, 0x00, 0x00, 0x00, 0x80, 0x01, 0x10, 0x00, 0x74, 0x68, 0x69, 0x73,
        0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x74, 0x65, 0x73, 0x74, 0x21, 0x0A, 0x00, 0x0A, 0x00, 0x56,
        0x63, 0x63, 0x20, 0x3D, 0x20, 0x00, 0x2E, 0x00, 0x30, 0x00, 0x56, 0x0A, 0x00, 0x00, 0x00, 0x00
    };
    
    M0(((unsigned long)x) + 0x40000000UL);
}

