#include "csd_zynq_peripherals.h"
#define switch_addr 0x41210000

.extern csd_main
.global main
main:
	ldr r2,=switch_addr // read switch data
	ldrb r3,[r2] // read in byte
	and r3,r3,#1 // get sw[0] data
	cmp r3,#1 // compare with 1
	beq enable // if sw[0] is up, enable cache
			   // else disable cache

disable:
	// L2 disable
	ldr r0, =L2_reg1_ctrl // L2 cache control reg
	mov r1, #0x0 // 0 for disabling L2
	str r1, [r0] // disable

	// L1 disable
	mrc		p15, 0, r0, c1, c0, 0	@ read control register (CP15 register1)
	bic		r0, r0, #4096		    @ disable I bit (Instruction Cache)
	bic		r0, r0, #4		        @ disable C bit (Data and Unified Caches)
	mcr		p15, 0, r0, c1, c0, 0	@ write control register (CP15 register2)
	b blink // jump to blink c code

enable:
	// L2 enable
	ldr r0, =L2_reg1_ctrl // L2 cache control reg
    mov r1, #0x1 // 1 for disabling L2
    str r1, [r0] // enable

	// L1 enable
	mrc		p15, 0, r0, c1, c0, 0	@ read control register (CP15 register1)
	orr		r0, r0, #(1<<12)	    @ Enable I bit (Instruction Cache)
	orr		r0, r0, #(1<<2)         @ Enable C bit (Data and Unified Caches)
	mcr		p15, 0, r0, c1, c0, 0	@ write control register (CP15 register2)

blink:
	bl  csd_main

forever:
	nop
	b forever
