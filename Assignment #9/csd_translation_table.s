.globl custom_MMUTable_lv2
.section .custom_mmu_tbl_lv2,"a"

custom_MMUTable_lv2:
.word 0x400002
.word 0x401002
.word 0x402002

/* 2nd page table
.word 0x400002
.word 0x402002
.word 0x400002
*/

.globl  custom_MMUTable
.section .custom_mmu_tbl,"a"

custom_MMUTable:
.set SECT, 0
.word	SECT + 0x15de6		/* S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1 */
.word	SECT + 0x15de6		/* S=b1 TEX=b101 AP=b11, Domain=b1111, C=b0, B=b1 */
.word 	custom_MMUTable_lv2 + 0x1e1
.end
