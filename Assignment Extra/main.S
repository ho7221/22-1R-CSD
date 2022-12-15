#include "csd_zynq_peripherals.h"
#include "uart_init.s"
#define timer_value 2000
.extern task1_c,task2_c,task3_c

// Vector table base location should be aligned at 2^5
.align 5

custom_vector_table:
	b .
	b .
	b .
	b .
	b .
	b .
	b custom_IRQ_ISR
	b .

.global main
main:
// ---------------------------
// UART setup
// ---------------------------
	UART_init

	// Disable interrupt: CPSR'I = 1
	cpsID i

// ---------------------------
// Setup IRQ mode stack
// ---------------------------
	cps #0x12               // IRQ mode
	ldr	r13,=irq_stack_top 	// IRQ stack pointer

	cps #0x1F				// SYS mode

	// Set VBAR (Vector Base Address Register) to my vector table
	ldr     r0, =custom_vector_table
	mcr     p15, 0, r0, c12, c0, 0
	dsb
	isb

// ---------------------------
// Generic Interrupt Controller (GIC) setup - Begin
// ---------------------------

// CPU Interface ID Register
	ldr r0, =GICC_IIDR
	ldr r3, [r0]

	// CPU Controller Type Register
	ldr r0, =GICD_TYPER
	ldr r3, [r0]

	// CPU Binary Pointer Register
	ldr r0, =GICC_BPR
	ldr r3, [r0]

	// Distributor Control Register
	ldr r0, =GICD_CTLR
	ldr r1, [r0]
	mov r2, #1       // Enable
	orr r1, r1, r2
	str r1, [r0]
 	ldr r3, [r0]

	 // Interrupt Set-Enable Register 0
	ldr r0, =GICD_ISENABLER0
	ldr r1, [r0]
	mov r2, #1 << 29   // Enable #29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	// According to specifications,
	// Cortex-A9 supports 5-bit version of priority format [7:3] in secure world
	// ( 0 -> 8 -> 16 -> 24...)

	// Interrupt Priority Register #7
	ldr r0, =GICD_PRIOR7
	ldr r1, [r0]
	mov r2, #0x10 << 8    // Priority 16 for ID# 29 (Private Timer)
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

	// CPU Interface Control Register
	ldr r0, =GICC_CTLR
	ldr r1, [r0]
	mov r2, #1        // Enable
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

 	// CPU Interface Interrupt Priority Mask Register
	ldr r0, =GICC_PMR
	ldr r1, [r0]
	mov r2, #0xFF     // Lowest
	orr r1, r1, r2
	str r1, [r0]
	ldr r3, [r0]

// ---------------------------
// Generic Interrupt Controller (GIC) setup - End
// ---------------------------

// ---------------------------
// PCB setup - Begin
// ---------------------------
	MRS r2,CPSR
	bic r2,#0b10000000
	bic r2,#0b11111
	orr r2,#0b10000
	ldr r0,=PCB1
	str r2,[r0]
	ldr r1,=task1_stack_top
	str r1,[r0,#60]
	ldr r1,=task1_c
	add r1,r1,#4
	str r1,[r0,#4]
	ldr r0,=PCB2
	str r2,[r0]
	ldr r1,=task2_stack_top
	str r1,[r0,#60]
	ldr r1,=task2_c
	add r1,r1,#4
	str r1,[r0,#4]
	ldr r0,=PCB3
	str r2,[r0]
	ldr r1,=task3_stack_top
	str r1,[r0,#60]
	ldr r1,=task3_c
	add r1,r1,#4
	str r1,[r0,#4]
// ---------------------------
// PCB setup - End
// ---------------------------
	cps #0x12 // IRQ mode

// ---------------------------
// Private Timer setup - Begin
// ---------------------------
 	// Private Timer Control Register
  	ldr r0, =PRIVATE_CONTROL
 	mov r1, #10 << 8   // Prescalar
 	orr r1, r1, #5     // IRQ Enable, not Auto-Reload, Timer Enable
 	str r1, [r0]
	// Private Timer Load Register
	ldr r0, =PRIVATE_LOAD
 	ldr r1, =timer_value
 	str r1, [r0]
// ---------------------------
// Private Timer setup - End
// ---------------------------

 	// Enable IRQ and Change to User Mode
	cpsIE i,#0x10

forever:
	b forever


// ----------------------------
// Interrupt Service Routines (ISRs) - Begin
// ----------------------------

custom_IRQ_ISR:
	stmfd sp,{r0-r14}^
	sub sp,sp,#60

	ldr r0,=TCB_idx
	ldr r0,[r0]
	cmp r0,#-1
	beq init

	ldr r1,=TCB_array
	add r1,r1,r0,LSL #2
	ldr r0,[r1]
	MRS r2,SPSR
	stmea r0!,{r2}
	stmea r0!,{r14}
	ldm sp!,{r1}
	stmea r0,{r1}
	add r0,r0,#4
	ldmfd sp,{r1-r14}^
	stmea r0,{r1-r14}^
	sub sp,sp,#4

init:
	ldr r1,=TCB_idx
	ldr r0,[r1]
	add r0,r0,#1
	cmp r0,#3
	moveq r0,#0
	str r0,[r1]

	ldr r1,=TCB_array
	add r1,r1,r0,LSL #2
	ldr r0,[r1]
	add r0,r0,#12

	ldmfd r0,{r1-r14}^
	stmfd sp,{r1-r14}^
	mov r1,r0
	ldmea r1,{r0}^
	sub sp,sp,#56
	stmfd sp,{r0}^
	sub sp,sp,#4
	sub r1,r1,#4
	ldmea r1,{r14}
	stmfd sp,{r14}
	sub r1,r1,#4
	sub sp,sp,#4
	ldmea r1,{r2}
	stmfd sp,{r2}
	sub sp,sp,#4


	// timer load value
	ldr r0, =PRIVATE_LOAD
 	ldr r1, =timer_value
 	str r1, [r0]

	// Interrupt ACK
  	ldr r0, =GICC_IAR
	ldr r3, [r0]
 	// End-of-Interrupt
  	ldr r0, =GICC_EOIR
	str r3, [r0]
	ldmfd sp!,{r0}
	MSR SPSR,r0
	ldmfd sp!,{lr}
	ldmfd sp,{r0-r14}^
	add sp,sp,#120
	subs pc, lr,#4

// ----------------------------
// Interrupt Service Routines (ISRs) - End
// ----------------------------


.data
.align 4

irq_stack:     .space 1024
irq_stack_top:
task1_stack:	.space 1024
task1_stack_top:
task2_stack: 	.space 1024
task2_stack_top:
task3_stack:	.space 1024
task3_stack_top:

PCB1:	.space 68
PCB2:	.space 68
PCB3:	.space 68
TCB_array:
	.word PCB1
	.word PCB2
	.word PCB3
TCB_idx:
	.word -1
