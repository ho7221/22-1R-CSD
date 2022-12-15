#include "uart_init.s"

.macro debugger
	// push register
	sub r13,r13,#16
	stmfd r13!,{r0-r12}
	mov r0,r13
	add r0,r0,#68 // manually calculate sp before calling debugger
	add r13,r13,#64
	mov r1,r14
	mov r2,r15
	sub r2,r2,#36 // manually calculate pc before calling debugger
	stmfd r13!,{r0,r1,r2}
	add r13,r13,#16
	mrs r12, CPSR // load CPSR(r12)
	stmfd r13!,{r12} // push CPSR
	sub r13,r13,#64

	UART_init

// print start line
	ldr r9,=line
line_1:
	ldr r0,=uart_Channel_sts_reg0
	ldr r1,[r0]
	and r1,r1,#8
	cmp r1,#8
	bne line_1
	ldr r0,=uart_TX_RX_FIFO0
	ldrb r7,[r9],#1
	strb r7,[r0]
	cmp r7,#0
	bne line_1
	mov r7,#0x0D
	strb r7,[r0]
	mov r7,#0x0A
	strb r7,[r0]

// start of print register
// reg is format for printing register
// there is 2 loop(printregformat,b0) to print register 4 by 4
	ldr r8,=reg
	mov r10,#0
b0:
	mov r11,#0

printregformat:
	ldr r0,=uart_Channel_sts_reg0
	ldr r1,[r0]
	and r1,r1,#8
	cmp r1,#8
	bne printregformat

	ldr r0,=uart_TX_RX_FIFO0
	mov r9,#0
// print format for register(e.g. r0 = 0x )
// I aligned them all in 8 bytes
b1:
	ldrb r2,[r8],#1
	strb r2,[r0]
	add r9,r9,#1
	cmp r9,#8
	blt b1
	mov r7,#3
// after printing format, print register data
	bl printreg

//print space
	mov r6,#32
	strb r6,[r0]

	add r13,r13,#4
	add r11,r11,#1
	cmp r11,#4
	blt printregformat

	mov r6,#0x0D
	strb r6,[r0]
	mov r6,#0x0A
	strb r6,[r0]

	add r10,r10,#1
	cmp r10,#4
	blt b0
// register print ended

	ldr r1,=cpsr1
bcpsr1: // print cpsr =
	ldrb r2,[r1],#1
	strb r2,[r0]
	cmp r2,#0
	bne bcpsr1
// print nzcv
	mov r1,r13
	add r1,r1,#3 // nzcv is in last byte in mem(little endian)
	ldrb r2,[r1]
	lsr r2,r2,#4 // r2 = nzcv in bit
	mov r3,#3
	ldr r4,=cpsr2 // r4 = nzcv in ascii
nzcv:
	ldrb r5,[r4],#1
	lsr r6,r2,r3
	and r6,r6,#1
	cmp r6,#1 // if flag enabled
	bne bnzcv
	sub r5,r5,#32 // convert to Upper character
bnzcv:
	strb r5,[r0]
	sub r3,r3,#1
	cmp r3,#0
	bge nzcv
// print nzcv ended

// print ', '
	mov r1,#44
	strb r1,[r0]
	mov r1,#32
	strb r1,[r0]

// print if
	ldrb r2,[r13]
	lsr r2,r2,#6 // r2 = if in bit
	mov r3,#1
	ldr r4,=cpsr3 // r4 = if in ascii
if:
	ldrb r5,[r4],#1
	lsr r6,r2,r3
	and r6,r6,#1
	cmp r6,#1 // if flag enabled
	bne bif
	sub r5,r5,#32 // convert to Upper character
bif:
	strb r5,[r0]
	sub r3,r3,#1
	cmp r3,#0
	bge if
// print if ended
// print ', '
	mov r3,#44
	strb r3,[r0]
	mov r3,#32
	strb r3,[r0]

// print IS state
	ldr r3,=IS // r3 is char* array's first location addr
	mov r4,#0
	ldrb r5,[r13,#3]
	and r5,r5,#0b1 // get J
	lsl r5,r5,#1
	add r4,r4,r5
	ldrb r5,[r13]
	and r5,r5,#0b100000
	lsr r5,r5,#5
	add r4,r5,r5 // r4 is JT flag
	add r3,r3,r4,LSL #2 // flag state char*'s array location addr
	ldr r3,[r3] // real flag pointer

bis: // print instruction set state
	ldrb r4,[r3],#1
	strb r4,[r0]
	cmp r4,#0
	bne bis
// print IS state ended
// print ' mode, current mode = '
	ldr r3,=cpsr4
bcpsr4:
	ldrb r2,[r3],#1
	strb r2,[r0]
	cmp r2,#0
	bne bcpsr4

// print mode
// mode is saved in cpsr's first byte
// I will ignore first bit and only care last 4 bit
// I aligned mode string in 3 characters
// I can access string with mode[0:3]*3
	ldrb r2,[r13]
	and r1,r2,#15
	mov r3,#3
	mul r1,r1,r3
	mov r2,#0
	ldr r3,=mode
	add r3,r3,r1
bmode:
	ldr r0,=uart_Channel_sts_reg0
	ldr r1,[r0]
	and r1,r1,#8
	cmp r1,#8
	bne bmode
	ldr r0,=uart_TX_RX_FIFO0
	ldrb r4,[r3],#1
	strb r4,[r0]
	add r2,r2,#1
	cmp r2,#3
	blt bmode

// print ' ( = 0x'
	mov r1,#32
	strb r1,[r0]
	mov r1,#40
	strb r1,[r0]
	mov r1,#61
	strb r1,[r0]
	mov r1,#48
	strb r1,[r0]
	mov r1,#120
	strb r1,[r0]
	mov r7,#3
// print cpsr data
	bl printreg
// print ')' with new line
	mov r1,#41
	strb r1,[r0]
	mov r1,#0x0D
	strb r1,[r0]
	mov r1,#0x0A
	strb r1,[r0]

// print end line
	ldr r9,=line
line_2:
	ldr r0,=uart_Channel_sts_reg0
	ldr r1,[r0]
	and r1,r1,#8
	cmp r1,#8
	bne line_2
	ldr r0,=uart_TX_RX_FIFO0
	ldrb r7,[r9],#1
	strb r7,[r0]
	cmp r7,#0
	bne line_2

	mov r1,#0x0D
	strb r1,[r0]
	mov r1,#0x0A
	strb r1,[r0]
// print end line ended

	msr CPSR,r12 // restore CPSR
	sub r13,r13,#64
	ldmfd r13!,{r0-r12} // restore r0-r12
	add r13,r13,#4 // calculate r14's stack addr
	ldmfd r13!,{r14} // restore r14
	add r13,r13,#8 // restore r13(epilogue)
	add pc,pc,#0x98 // restore pc(epilogue), 0x98 is calculated from elf(from pc+8 to next main code)

// register print started
// print first 2 byte and _ and last 2 byte
// note that register data is saved in little endian that
// r7 will start from 3 and decrease
// if word is alphabet, convert to ascii will be adding 0x37
// if word is numeric, convert to ascii will be adding 0x30
printreg:
	mov r2,r13
	add r2,r2,r7
	ldrb r1,[r2],#1
	mov r6,r1,LSR #4
	cmp r6,#10
	blt alpha1
	add r6,r6,#7
alpha1:
	add r6,r6,#0x30
	strb r6,[r0]
	and r6,r1,#15
	cmp r6,#10
	blt alpha2
	add r6,r6,#7
alpha2:
	add r6,r6,#0x30
	strb r6,[r0]
	sub r7,r7,#1
	cmp r7,#2
	bge printreg
// print _
	mov r6,#0x5F
	strb r6,[r0]
b2:
	mov r2,r13
	add r2,r2,r7
	ldrb r1,[r2],#1
	mov r6,r1,LSR #4
	cmp r6,#10
	blt alpha3
	add r6,r6,#7
alpha3:
	add r6,r6,#0x30
	strb r6,[r0]
	and r6,r1,#15
	cmp r6,#10
	blt alpha4
	add r6,r6,#7
alpha4:
	add r6,r6,#0x30
	strb r6,[r0]
	sub r7,r7,#1
	cmp r7,#0
	bge b2
	mov pc,lr
// register print ended

// define as data section
.data
.align 4

line:
.ascii "------------------------------------------------------------------------"
.byte 0x00

reg:
.ascii "r0  = 0xr1  = 0xr2  = 0xr3  = 0xr4  = 0xr5  = 0xr6  = 0xr7  = 0xr8  = 0xr9  = 0xr10 = 0xr11 = 0xr12 = 0xr13 = 0xr14 = 0xr15 = 0x"
.byte 0x00

cpsr1:
.ascii "cpsr = "
.byte 0x00

cpsr2:
.ascii "nzcv"
.byte 0x00
cpsr3:
.ascii "if"
.byte 0x00
cpsr4:
.ascii " mode, current mode = "
.byte 0x00

arm:
.ascii "ARM"
.byte 0x00
thumb2:
.ascii "Thumb2"
.byte 0x00
jazelle:
.ascii "Jazelle"
.byte 0x00
ThumbEE:
.ascii "ThumbEE"
.byte 0x00

IS: // array of char*
.word arm
.word thumb2
.word jazelle
.word ThumbEE

mode:
.ascii "USRFIQIRQSVC      MONABT      HYPUND         SYS"
.byte 0x00

.text // restore to text section
.endm
