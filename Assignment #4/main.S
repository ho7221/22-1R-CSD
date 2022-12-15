#define csd_LED_ADDR 0x41200000
#include "uart_init.s"

.extern get_time

.global main

main:
	UART_init
	ldr r1, =csd_LED_ADDR // r1 is LED's addr

loop:
	bl io // call input, output function
	sub r0,r0,#0x30 // returned as ascii so subtract 0x30
	bl get_time // call C function r0=get_time(r0)
	ldr r2,=led
	mov r3,#0 // r3 is one LED loop index(reach til 8)

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
	mov r4,#0
	str r4,[r1]
	b loop

io:
	ldr r2, =alert // message data
	b TX_empty

TX_empty:
	ldr r3, =uart_Channel_sts_reg0
	ldr r4,[r3] // read from status reg
	and r4,r4,#8 // read 4th bit which is TX_empty
	cmp r4,#8
	bne TX_empty // if TX is empty, continue to send data

	ldr r3,=uart_TX_RX_FIFO0
	ldrb r4,[r2],#1 // read char from message data
	strb r4,[r3] // send char to TX_FIFO
	cmp r4,#0 // end condition
	bne TX_empty

RX_empty:
	ldr r3, =uart_Channel_sts_reg0
	ldr r4,[r3] // read from status reg
	and r4,r4,#2 // read 2th bit which is RX_empty
	cmp r4,#2
	beq RX_empty // if RX is empty, keep reading

	ldr r3,=uart_TX_RX_FIFO0
	ldrb r0,[r3] // get char from RX_FIFO, returned via r0
	strb r0,[r3] // send echo data
	ldr r2,=newline_data // print newline

newline:
	ldr r3, =uart_Channel_sts_reg0
	ldr r4,[r3] // read from status reg
	and r4,r4,#8 // read 4th bit which is TX_empty
	cmp r4,#8
	bne newline // if TX is empty, continue to send data

	ldr r3,=uart_TX_RX_FIFO0
	ldrb r4,[r2],#1 // read char from newline data
	strb r4,[r3] // send char to TX_FIFO
	cmp r4,#0 // end condition
	bne newline
	mov pc,lr // return to where called io function


.data
.align 4

led:
	.word 1,2,4,8,16,32,64,128
alert:
	.ascii "----------------- LED On Duration ----------------"
	.byte 0x0D
	.byte 0x0A
	.ascii " 1. 100ms 2. 200ms 3. 300ms 4. 400 ms "
	.byte 0x0D
	.byte 0x0A
	.ascii " 5. 500ms 6. 600ms 7. 700ms 8. 1 sec "
	.byte 0x0D
	.byte 0x0A
	.ascii "---------------------------------------------------"
	.byte 0x0D
	.byte 0x0A
	.ascii "Select:"
	.byte 0x00

newline_data:
	.byte 0x0D
	.byte 0x0A
	.byte 0x00
