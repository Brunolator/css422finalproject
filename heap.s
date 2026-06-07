		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _kinit( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_kinit
_kinit
		; you must correctly set the value of each MCB block
		; complete your code
		
		; Prepare to clear the heap
		LDR 	r0, =HEAP_TOP
		LDR		r1, =HEAP_BOT
		LDR		r3, =0x0
		
_heap_init
		STRB	r3, [r0]		; 0-initialize the memory
		ADD		r0, r0, #0x1	; increment address
		CMP		r0, r1
		BLT		_heap_init
		; done 0-initializing heap
		
		; Prepare to clear the MCB
		LDR		r0, =MCB_TOP
		LDR		r1, =MCB_BOT
		
_mcb_init
		STRB	r3, [r0]		; 0-initialize the memory
		ADD		r0, r0, #0x1	; increment address
		CMP		r0, r1
		BLT		_mcb_init
		; done 0-initializing mcb
		
		; Start the MCB with one buddy the size of the heap
		LDR		r0, =MCB_TOP
		LDR		r1, =MAX_SIZE
		STR		r1, [r0]
		
		BX		lr ; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		; complete your code
		; return value should be saved into r0
		
		; Set up the parameters to call the helper function
		MOV		r1, r0			; size
		LDR		r2, =MCB_TOP	; left_mcb_addr
		LDR		r3, =MCB_BOT	; right_mcb_addr
		
		PUSH	{lr}
		BL		_ralloc
		POP		{lr}
		
		LDR		r0, =HEAP_TOP ; PLACEHOLDER
		BX		lr
		
; _kalloc's helper function to recursively allocate memory space
_ralloc
		; Parameters:
		; r1: size
		; r2: left_mcb_addr
		; r3: right_mcb_addr
		
		; entire_mcb_addr_space
		SUB		r4, r3, r2
		ADD		r4, r4, #MCB_ENT_SZ
		; half_mcb_addr_space
		MOV		r5, r4
		LSR		r5, #0x1
		; midpoint_mcb_addr
		ADD		r6, r2, r5
		; heap_addr
		LDR		r7, =0x0
		; act_entire_heap_size
		MOV		r8, r4
		LSL		r8, #0x4
		; act_half_heap_size
		MOV		r9, r5
		LSL		r9, #0x4
		
		; If the data size is <= than half the heap size
		; (then it still needs to decrease size to best fit the data)
		CMP		r1, r9
		BGT		_after_split_in_half
		
		; Recursive call to ralloc, only using the first half of given
		; heap portion, and saving the result to heap_addr
		PUSH	{r2-r12,lr}
		SUB		r3, r6, #MCB_ENT_SZ
		BL		_ralloc
		POP		{r2-r12,lr}
		MOV		r7, r0
		
		; If the recursive call result was invalid (returned 0), then
		; try with the second buddy and return that result
		CMP		r7, #0x0
		BNE		_after_verify_result_valid
		
		PUSH	{r2-r12,lr}
		MOV		r2, r6
		BL		_ralloc
		POP		{r2-r12,lr}
		; The result will already be in r0 because of the recursive call
		BX		lr
		
_after_verify_result_valid
		
_after_split_in_half
		
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		
		
		BX		lr
		
		END