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
		EXPORT	_heap_init
_heap_init
		; you must correctly set the value of each MCB block
		; complete your code
		
		; Prepare to clear the heap
		LDR 	r0, =HEAP_TOP
		LDR		r1, =HEAP_BOT
		ADD		r1, r1, #0x20
		LDR		r3, =0x0
		
_heap_clear
		STRB	r3, [r0]		; 0-initialize the memory
		ADD		r0, r0, #0x1	; increment address
		CMP		r0, r1
		BLT		_heap_clear
		; done 0-initializing heap
		
		; Prepare to clear the MCB
		LDR		r0, =MCB_TOP
		LDR		r1, =MCB_BOT
		ADD		r1, r1, #0x2
		
_mcb_clear
		STRB	r3, [r0]		; 0-initialize the memory
		ADD		r0, r0, #0x1	; increment address
		CMP		r0, r1
		BLT		_mcb_clear
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
		
		; r0 has the size parameter
		
		; Set up the parameters to call the helper function
		MOV		r1, r0			; size
		LDR		r2, =MCB_TOP	; left_mcb_addr
		LDR		r3, =MCB_BOT	; right_mcb_addr	
		
		PUSH	{lr}
		BL		_ralloc
		POP		{lr}
		
		; Return value will already be in r0 from the _ralloc call
		BX		lr
		
; _kalloc's helper function to recursively allocate memory space
; returns value in r0
_ralloc
		; Parameters:
		; r1: size
		; r2: left_mcb_addr
		; r3: right_mcb_addr
		
		; Variables:
		; r4: entire_mcb_addr_space
		SUB		r4, r3, r2
		ADD		r4, r4, #MCB_ENT_SZ
		; r5: half_mcb_addr_space
		MOV		r5, r4
		LSR		r5, #0x1
		; r6: midpoint_mcb_addr
		ADD		r6, r2, r5
		; r7: heap_addr
		LDR		r7, =0x0
		; r8: act_entire_heap_size
		MOV		r8, r4
		LSL		r8, #0x4
		; r9: act_half_heap_size
		MOV		r9, r5
		LSL		r9, #0x4
		
		; If the data size is <= than half the heap size
		; (then it still needs to decrease size to best fit the data)
		CMP		r1, r9
		BGT		_data_size_over_half_given_size
		
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
			
			; If the buddy at the midpoint is free, divide it to 2 buddies by
			; setting the midpoint MCB block to the new buddy size
			LDR		r10, [r6]
			AND		r10, #0x1
			CMP		r10, #0x0
			BNE		_after_split_in_half
			
				STR		r9, [r6]
		
_after_split_in_half
			
			; Return heap_addr
			MOV		r0, r7
			BX		lr

_data_size_over_half_given_size
		
		; If this buddy is already allocated, then return 0
		LDR		r10, [r2]
		AND		r10, #0x1
		CMP		r10, #0x0
		BNE		_ralloc_return_0
		
		; The buddy is not already allocated
		
		; If this buddy smaller than given heap size, return 0 because
		; it has to match perfectly into left_mcb_addr and right_mcb_addr
		LDR		r10, [r2]
		CMP		r10, r8
		BLT		_ralloc_return_0
		
		; The buddy is the correct size
		
		; The base case where the memory is allocated
		
		; Set left array address to the given heap size and mark allocated
		MOV		r10, r8
		ORR		r10, #0x1
		STR		r10, [r2]
		
		; Translate the MCB address into heap address and return it
		MOV		r0, r2
		LDR		r10, =MCB_TOP
		SUB		r0, r0, r10
		LSL		r0, #0x4
		LDR		r10, =HEAP_TOP
		ADD		r0, r10
		
		BX		lr
		
_ralloc_return_0
		LDR		r0, =0x0
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		
		; r0 has the address parameter
		
		; If the address to free is outside heap, exit
		LDR		r1, =HEAP_TOP
		CMP		r0, r1
		BGE		_after_check_top_bound
		
		; return null
		LDR		r0, =0x0
		BX		lr
		
_after_check_top_bound

		LDR		r1, =HEAP_BOT
		CMP		r0, r1
		BLE		_after_check_bottom_bound
		
		; return null
		LDR		r0, =0x0
		BX		lr
		
_after_check_bottom_bound
		
		; Get the mcb address from the given heap address
		; This will be the parameter to call the helper function
		MOV		r2, r0
		LDR		r3, =HEAP_TOP
		SUB		r2, r2, r3
		LSR		r2, #0x4
		LDR		r3, =MCB_TOP
		ADD		r2, r2, r3
		
		PUSH	{lr}
		BL		_rfree
		POP		{lr}
		
		; If the memory wasn't freed, _rfree returned 0, so return null now
		CMP		r1, #0x0
		BNE		_kfree_return
		
		LDR		r0, =0x0
		
_kfree_return
		BX		lr

; _kalloc's helper function to recursively allocate memory space
; returns value in r1
_rfree
		; Parameters:
		; r2: mcb_addr
		
		; Variables:
		; r3: mcb_contents
		LDR		r3, [r2]
		; r4: mcb_index
		LDR		r4, =MCB_TOP
		SUB		r4, r2, r4
		; r5: mcb_disp
		LSR		r3, #0x4
		MOV		r5, r3
		; r6: my_size
		LSL		r3, #0x4
		MOV		r6, r3
		
		; Store the deallocation bit back into memory
		STR		r3, [r2]
		
		; Divide index by size to get the index of buddies specifically this size
		; If even, then it's first in its pair, otherwise it's the second
		UDIV	r7, r4, r5
		AND		r7, #0x1
		CMP		r7, #0x0
		BNE		_is_second_buddy
		
			; If gets here, it is the first buddy
			
			; If the buddy is past the mcb bottom, return 0
			ADD		r7, r2, r5
			LDR		r8, =MCB_BOT
			CMP		r7, r8
			BGE		_rfree_return_0
			
			; The buddy is within the MCB

			; Get the MCB start of the second buddy in the pair
			ADD		r7, r2, r5
			LDR		r7, [r7]
			
			; If the other buddy is occupied, return early
			MOV		r8, r7
			AND		r8, #0x1
			CMP		r8, #0x0
			BNE		_rfree_return
			
			; Round down buddy size to nearest 32
			LSR		r7, #0x4
			LSL		r7, #0x4
			
			; If the buddies are not the same size, return early
			CMP		r7, r6
			BNE		_rfree_return
			
			; Now combining the buddies
			
			; Reset the other buddy's size to 0 since it is combined
			LDR		r8, =0x0
			ADD		r9, r2, r5
			STR		r8, [r9]
			
			; Double my_size and save it into this buddy's size
			LSL		r6, #0x1
			STR		r6, [r2]
			
			; Recursive call to rfree
			PUSH	{r2-r12,lr}
			; The r2 parameter will stay the same
			BL		_rfree
			POP		{r2-r12,lr}
		
			B		_rfree_return
		
_is_second_buddy
			;MOV		r7, r2
		
			; If the buddy is past the mcb bottom, return 0
			ADD		r7, r2, r5
			LDR		r8, =MCB_TOP
			CMP		r7, r8
			BLT		_rfree_return_0
			
			; The buddy is within the MCB

			; r7: mcb_buddy
			; Get the MCB start of the first buddy in the pair
			SUB		r7, r2, r5
			LDR		r7, [r7]
			
			; If the other buddy is occupied, return early
			MOV		r8, r7
			AND		r8, #0x1
			CMP		r8, #0x0
			BNE		_rfree_return
			
			; Round down buddy size to nearest 32
			LSR		r7, #0x4
			LSL		r7, #0x4
			
			; If the buddies are not the same size, return early
			CMP		r7, r6
			BNE		_rfree_return
			
			; Now combining the buddies
			
			; Since it's the second buddy, can remove size data from MCB
			LDR		r8, =0x0
			STR		r8, [r2]
			
			; Double my_size and save it as the first buddy's size
			LSL		r6, #0x1
			SUB		r8, r2, r5
			STR		r6, [r8]
			
			; Recursive call to rfree
			PUSH	{r2-r12,lr}
			SUB		r2, r2, r5
			BL		_rfree
			POP		{r2-r12,lr}

_rfree_return
		MOV		r1, r2
		BX		lr

_rfree_return_0
		LDR		r1, =0x0
		BX		lr
		
		END