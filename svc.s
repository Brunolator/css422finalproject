		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MEMCPY		EQU		0x3		; address 20007B0C
SYS_MALLOC		EQU		0x4		; address 20007B10
SYS_FREE		EQU		0x5		; address 20007B14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
		LDR		r0, = SYSTEMCALLTBL
		
		; Initialize SYSTEMCALLTBL[0] = _sys_exit
		LDR		r1, = _sys_exit
		STR		r1, [r0]
		
		; Initialize_SYSTEMCALLTBL[1] = _sys_alarm
		ADD		r0, r0, #0x4
		LDR		r1, = _sys_alarm
		STR		r1, [r0]

		; Initialize_SYSTEMCALLTBL[2] = _sys_signal
		ADD		r0, r0, #0x4
		LDR		r1, = _sys_signal
		STR		r1, [r0]

		; Initialize_SYSTEMCALLTBL[3] = _sys_memcpy
		ADD		r0, r0, #0x4
		LDR		r1, = _sys_memcpy
		STR		r1, [r0]

		; Initialize_SYSTEMCALLTBL[4] = _sys_malloc
		ADD		r0, r0, #0x4
		LDR		r1, = _sys_malloc
		STR		r1, [r0]
	
		; Initialize_SYSTEMCALLTBL[5] = _sys_free
		ADD		r0, r0, #0x4
		LDR		r1, = _sys_free
		STR		r1, [r0]
		
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
		LDR		r11, = SYSTEMCALLTBL
		MOV		r10, r7
		LSL		r10, #0x2		; system call number * 4
		ADD		r10, r10, r11	; r10 = jump table entry
		LDR		r11, [r10]		; r11 = top address of the system call routine
		STMFD	sp!, {lr}		; save lr
		BLX		r11				; jump to the system call routine
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr			; return to SVC_Handler
		
_sys_exit
		STMFD	sp!, {lr}		; save lr
		BLX		r11	
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr
		
_sys_alarm
		IMPORT	_timer_start
		LDR		r11, = _timer_start	
		STMFD	sp!, {lr}		; save lr
		BLX		r11	
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr
		
_sys_signal
		IMPORT	_signal_handler
		LDR		r11, = _signal_handler
		STMFD	sp!, {lr}		; save lr
		BLX		r11	
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr
		
_sys_memcpy
		IMPORT	_dma_start
		LDR		r11, = _dma_start	
		STMFD	sp!, {lr}		; save lr
		BLX		r11	
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr
		
_sys_malloc
		IMPORT	_kalloc
		LDR		r11, = _kalloc	
		STMFD	sp!, {lr}		; save lr
		BLX		r11	
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr	
		
_sys_free
		IMPORT	_kfree
		LDR		r11, = _kfree	
		STMFD	sp!, {lr}		; save lr
		BLX		r11	
		LDMFD	sp!, {lr}		; resume lr
		MOV		pc, lr			
		
		END


		