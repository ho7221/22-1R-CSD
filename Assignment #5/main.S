#include "debugger.s"

.global main

main:
	ldr r0,=Input_data // Input_data addr
	ldr r1,=Output_data // Output_data addr
	mov r2,#0 // Index1=0
br1:
	cmp r2,#32 // for(Index1 < 32)
	bge forever // end
	mov r3,r2 // Index2=Index1
	mov r5,r0
	add r5,r5,r2,LSL #2 // addr of Input_data[Index1]
	ldr r4,[r5] // r4=Input_data[Index1] -> min initialize

br2:
	cmp r3,#32 // for(Index2 < 32)
	bge br3 //search finished
	mov r5,r0
	add r5,r5,r3,LSL #2 // addr of Input_data[Index2]
	ldr r6,[r5] // tmp=Input_data[Index2]
	cmp r4,r6
	blt big // branch if min is smaller
	mov r4,r6 // update min
	mov r7,r3 // update min_index

big:
	add r3,r3,#1 // r3++
	B br2

br3:
	str r4,[r1],#4 // update Output_data
	mov r5,r0
	add r5,r5,r2,LSL #2 // addr of Input_data[Index1]
	ldr r6,[r5] // tmp=Input_data[Index1]
	str r4,[r5] // Input_data[Index1]=min
	mov r5,r0
	add r5,r5,r7,LSL #2 // addr of Input_data[min_index]
	str r6,[r5] // Input_data[min_index]=tmp
	add r2,r2,#1 // r2++
	B br1

forever:
	debugger
	nop
	b forever

.data
.align 4

Input_data:
	.word 2, 0, -7, -1, 3, 8, -4, 10
	.word -9, -16, 15, 13, 1, 4, -3, 14
	.word -8, -10, -15, 6, -13, -5, 9, 12
	.word -11, -14, -6, 11, 5, 7, -2, -12

Output_data:
	.word 0, 0, 0, 0, 0, 0, 0, 0
	.word 0, 0, 0, 0, 0, 0, 0, 0
	.word 0, 0, 0, 0, 0, 0, 0, 0
	.word 0, 0, 0, 0, 0, 0, 0, 0
