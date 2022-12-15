#define csd_LED_ADDR 0x41200000


.extern get_switch

.global main

main:
	push {fp} // make stack frame for get_switch(r3)
	mov fp,sp // make stack frame for get_switch(r3)
	sub sp,sp,#4 // make stack frame for get_switch(r3)
	ldr r1, =csd_LED_ADDR // r1 is LED's addr

loop:
	ldr r2,=led
	mov r3,#0 // r3 is one LED loop index(reach til 8)
	stmfd r13!,{r3} // push r3
	bl get_switch // call C function return is r0
	ldmfd r13!,{r3} // pop r3

b0: // change led value
	ldr r6,[r2],#4 // get led, increase r2 by 4
	str r6,[r1] // led input
	mov r4, #0 // r4 is sleep counter

b1: // sleep 100*r0 milisec with r4
	mov r8,#0
b2:
	mov r7,#0
b3: // sleep 100 milisec with r5, r7 100MHz -> 10000000 inst for 100ms
	mov r5,#0
b4:
	add r4,r4,#1
	sub r4,r4,#1
	add r4,r4,#1
	sub r4,r4,#1
	add r4,r4,#1
	sub r4,r4,#1

	add r5,r5,#1
	cmp r5,#1000 // x 1000
	blt b4
	add r7,r7,#1
	cmp r7,#1000 // x 1000
	blt b3
	add r8,r8,#1
	cmp r8,#10 // x 10 x 10inst in code
	blt b2

	add r4,r4,#1
	cmp r4,r0
	blt b1

	add r3,r3,#1
	cmp r3,#8
	blt b0
	b loop

.data
.align 4

led:
	.word 1,2,4,8,16,32,64,128
