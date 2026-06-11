		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		LDR R2, =0x0
		PUSH {r1-r12,lr}		

		; you need to add some code here for part 1 implmentation
_bzero_start
		CMP R1, #0x0
		BLE _bzero_end ; If there's no more bytes to go, branch to end
		
		STRB R2, [R0] ; 0-initialize the current byte
		ADD R0, R0, #1 ; Add 1 byte to the current address
		SUB R1, R1, #1 ; Decrement byte counter
		
		B _bzero_start
		
_bzero_end
		POP {r1-r12,lr}	
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT _strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		; r3 = a copy of original dest
		; r4 = src[i]
		PUSH {r1-r12,lr}

		; This is what I coded for part 1
_strncpy_start
		CMP R2, #0x0
		BLE _strncpy_end ; If there's no more bytes to go, branch to end
		
		LDRB R4, [R1] ; Copy the current byte from src to dest
		STRB R4, [R0]
		ADD R0, R0, #1 ; Add 1 byte to the src and dest addresses
		ADD R1, R1, #1
		SUB R2, R2, #1 ; Decrement size counter
		
		B _strncpy_start

_strncpy_end
		POP {r1-r12,lr}
		BX lr


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncat( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the destination array
;	src		- pointer to string to be appended
;	size	- Maximum number of characters to be appended
; Return value
;   dest
		EXPORT	_strncat
_strncat
		; r0 = dest
		; r1 = src
		; r2 = size
		PUSH {r1-r12,lr}		
		; you need to add some code here for part 1 implmentation
		POP {r1-r12,lr}	
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; r0 = size
		PUSH {r1-r12,lr}		
		
		; you need to add two lines of code here for part 2 implmentation
		LDR		r7, =0x4
		SVC		#0x0
		
		POP {r1-r12,lr}	
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		; r0 = addr
		PUSH {r1-r12,lr}		
		
		; you need to add two lines of code here for part 2 implmentation
		LDR		r7, =0x5
		SVC		#0x0
		
		POP {r1-r12,lr}	
		BX		lr


		EXPORT	_alarm
_alarm
		STMFD	sp!, {r1-r12,lr}
		MOV		r7, #0x01
		SVC		#0x0
		LDMFD	sp!, {r1-r12,lr}
		
		MOV		pc, lr
		
		
		EXPORT	_signal
_signal
		STMFD	sp!, {r1-r12,lr}
		MOV		r7, #0x02
		SVC		#0x0
		LDMFD	sp!, {r1-r12,lr}
		
		MOV		pc, lr
		
		END