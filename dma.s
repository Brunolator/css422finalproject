		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Module initialization
RCGCDMA		EQU		0x400FE60C	; Port Address for Run Mode Clock Gating Control 
DMACFG		EQU		0x400FF004	; Port Address for DMA Configuration
DMACTLBASE	EQU		0x400FF008	; Port Address for DMA Channel Control Base Pointer

DMAPRIOSET	EQU		0x400FF038	; Port Address for DMA Priority Set
DMAALTCLR	EQU 	0x400FF034	; Port Address for DMA Channel Primary Alternate Clear
DMAUSEBURSTCLR	EQU 0x400FF01C	; Port Address for DMA Channel Useburst Clear
DMAREQMASKCLR	EQU 0x400FF024	; Port Address for DMA Channel Request Mask Clear

DMAMEMMAP		EQU		0x20007C00	; The last 1024 bytes in the 30K RAM (0x2000.7C00-2000.7FFF)	
CH30_SRCENDPTR	EQU		     0x1E0	; Ch30's source end pointer
CH30_DSTENDPTR	EQU		     0x1E4	; Ch30's destination end pointer
CH30_CTLWORD	EQU		     0x1E8	; Ch30's control word

CTLWORD_INIT	EQU		0xAA00C002	; Ch30's control word contents
									; 10 10 10 10 00 0 00 0 0011 0000000000 0 010
									; A     A     0     0     C    0   0    2
		EXPORT		_dma_init
_dma_init
		LDR		r0, =RCGCDMA	; enable Run Mode Clock Gating Control
		MOV		r1, #0x00000001
		STR		r1,	[r0]
		
		LDR		r0, =DMACFG		; enable DMA Configuration
		MOV		r1, #0x00000001
		STR		r1,	[r0]
		
		LDR		r0, =DMACTLBASE	; set up DMA Channel Control Base Pointer
		LDR		r1, =DMAMEMMAP
		STR		r1,	[r0]	

		LDR		r0, =DMAPRIOSET	; prioritize Ch30 
		MOV		r1, #0x40000000
		STR		r1,	[r0]

		LDR		r0, =DMAALTCLR	; use the primary control structure for ch30
		MOV		r1, #0x40000000
		STR		r1,	[r0]
		
		LDR		r0, =DMAUSEBURSTCLR	; Make ch30 respond to single and burst requests
		MOV		r1, #0x40000000
		STR		r1,	[r0]

		LDR		r0, =DMAREQMASKCLR	; ch30 is enabled to request DMA
		MOV		r1, #0x40000000
		STR		r1,	[r0]
		
		LDR		r0,	=DMAMEMMAP + CH30_CTLWORD	; set up ch30's control word
		LDR		r1,	=CTLWORD_INIT
		STR		r1,	[r0]
		
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DMA Start
; R0 = arg0: void* dest
; R1 = arg1: void* src
; R2 = arg2: int count (in bytes)

; R3 = DMAMEMMAP + CH30_SRCENDPTR, DMAMEMMAP + CH30_DSTENDPTR, or DMAMEMMAP + CH30_CTLWORD
; R4 = src/dest end pointer or ctonrol word initialization

DMAENASET	EQU 	0x400FF028	; DMA Channel Enable Set
DMASWREQ	EQU 	0x400FF014	; DMA Channel Software Request

		EXPORT		_dma_start
_dma_start
; set up src address end pointer = R1 + R2 - 4 (+ 0x3FC?)
		LDR		r3,	=DMAMEMMAP + CH30_SRCENDPTR	; set up ch30's src address end pointer
		ADD		r4,	R1, R2
		SUB		r4, r4, #4
		ADD		r4, r4, #0x3FC
		STR		r4,	[r3]
		
; set up dest address end pointer = R0 + R2 - 4 (+ 0x3FC?)		
		LDR		r3,	=DMAMEMMAP + CH30_DSTENDPTR	; set up ch30's dest address end pointer
		ADD		r4, R0, R2
		SUB		r4, r4, #4
		ADD		r4, r4, #0x3FC
		STR		r4,	[r3]

; set up channel control word (r4) = CLWORD_INIT + ( R2 / 4 - 1 ) * 16
		LDR		r3,	=DMAMEMMAP + CH30_CTLWORD	; set up ch30's control word
		LSR		r2, #2
		SUB		r2, r2, #1
		LSL		r2,	#4
		LDR		r4, =CTLWORD_INIT
		ADD		r4, r4, r2
		STR		r4,	[r3]

		LDR		r3, =DMAENASET	; Enable Ch30
		MOV		r4, #0x40000000
		STR		r4,	[r3]
		
		LDR		r3, =DMASWREQ	; Issue a transfer request
		MOV		r4, #0x40000000
		STR		r4,	[r3]		
		
		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DMA Interrupt
; 44: uDMA Software Transfer

		MOV		pc, lr		; return to SVC_Handler
		END
		