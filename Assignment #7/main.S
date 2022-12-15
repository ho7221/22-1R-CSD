#include "csd_zynq_peripherals.h"
#include "uart_init.s"
// 2000000 for 1 sec, 800000 for minute check, 8000 for hour check
#define timer_init 0x2000000

.align 5

myIVT:
	b .
	b .
	b .
	b .
	b .
	b .
	b my_IRQ_ISR
	b .

.global main
main:
	// UART initialization
	UART_init
	// Disable interrupt: CPSR'I = 1
	cpsID i

	cps #0x12	   	       // IRQ mode
	ldr	r13,=irq_stack_top // Stack pointer setup for IRQ mode
	// timer info
	mov r4,#0 // second[0]
	mov r5,#0 // second[1]
	mov r6,#0 // minute[0]
	mov r7,#0 // minute[1]
	mov r8,#0 // hour[0]
	mov r9,#0 // hour[1]
	mov r10,#0 // hour count
	stmfd sp!,{r4-r10} // push r4-r10 to irq_stack

	cps #0x1F	             // SYS mode

	// Set VBAR (Vector Base Address Register) to my vector table
	ldr     r0, =myIVT
	mcr     p15, 0, r0, c12, c0, 0
	dsb
	isb

	// Enable interrupt: CPSR'I = 0
	cpsIE i

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
// Private Timer setup - Begin
// ---------------------------

 	// Private Timer Load Register
	ldr r0, =PRIVATE_LOAD
 	ldr r1, =timer_init
 	str r1, [r0]

 	// Private Timer Control Register
  	ldr r0, =PRIVATE_CONTROL
 	mov r1, #10 << 8   // Prescalar
 	orr r1, r1, #7     // IRQ Enable, Auto-Reload, Timer Enable
 	str r1, [r0]

forever:
	b forever // loop forever

// IRQ ISR
my_IRQ_ISR:
	stmfd sp!, {r0-r12, lr} // backup r0-r12,lr
	sub sp,sp,#56 // move to previous sp(location of timer info)
	ldmfd sp!,{r4-r10} // restore timer info

 	// Interrupt Ack
  	ldr r0, =GICC_IAR
	ldr r3, [r0]

 	// Test if IRQ is Timer interrupt
 	cmp r3, #29
 	bne not_timer

	// print timer
	// add 0x30 for digit, 58 for :, 13 for CR
	ldr r2,=uart_TX_RX_FIFO0
	add r11,r9,#0x30
	str r11,[r2]
	add r11,r8,#0x30
	str r11,[r2]
	mov r11,#58
	str r11,[r2]
	add r11,r7,#0x30
	str r11,[r2]
	add r11,r6,#0x30
	str r11,[r2]
	mov r11,#58
	str r11,[r2]
	add r11,r5,#0x30
	str r11,[r2]
	add r11,r4,#0x30
	str r11,[r2]
	mov r11,#13
	str r11,[r2]

	// Increment timer
	// h[1]h[0] : m[1]m[0] : s[1]s[0]

 	// second[0]
	add r4,r4,#1
	cmp r4,#10 // second[0] < 10
	bne done
	mov r4,#0 // second[0] reset
	add r5,r5,#1 // second[1] inc
	//second[1]
	cmp r5,#6 // second[1] < 6
	bne done
	mov r5,#0 // second[1] reset
	add r6,r6,#1 // minute[0] inc
	// minute[0]
	cmp r6,#10 // minute[0] < 10
	bne done
	mov r6,#0 // minute[0] reset
	add r7,r7,#1 // minute[1] inc
	// minute[1]
	cmp r7,#6 // minute[1] < 6
	bne done
	mov r7,#0 // minute[1] reset
	add r8,r8,#1 // hour[0] inc
	add r10,r10,#1 // hour count inc
	cmp r10,#24 // TIMER FULL(23:59:59 -> 24:00:00)
	beq reset
	// hour[0]
	cmp r8,#10 // hour[0] < 10
	bne done
	mov r8,#0 // hour[0] reset
	add r9,r9,#1 // hour[1] inc
	b done
reset:
	// TIMER FULL(23:59:59 -> 24:00:00)
	mov r4,#0
	mov r5,#0
	mov r6,#0
	mov r7,#0
	mov r8,#0
	mov r9,#0
	mov r10,#0

done:
	stmfd sp!,{r4-r10} // backup timer info
 	// Clear Timer Interrupt Status bit(sticky bit)
  	ldr r0, =PRIVATE_STATUS
  	mov r1, #1
	str r1, [r0]

not_timer:
 	// End-of-Interrupt
  	ldr r0, =GICC_EOIR
	str r3, [r0]

	add sp,sp,#56 // restore sp
	ldmfd sp!, {r0-r12, lr} // restore r0-r12,lr
	subs pc, lr, #4 // return from IRQ
// ----------------------------
// Interrupt Service Routines (ISRs) - End
// ----------------------------

.data
.align 4

irq_stack:     .space 1024
irq_stack_top:
