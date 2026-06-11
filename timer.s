		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14				; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
		LDR		r3, =STCTRL			; Stop SysTick
		MOV		r4, #STCTRL_STOP
		STR		r4,	[r3]	

		LDR		r3, =STRELOAD		; Initialize SysTick Reload
		MOV		r4, #STRELOAD_MX
		STR		r4,	[r3]
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
		CMP		r0, #0
		BLE		_timer_start_done	; alarm( 0 ) or alarm( -1 )
		LDR		r3, =SECOND_LEFT	; save seconds left
		LDR		r1, [r3]			; r1 = previous seconds left
		STR		r0, [r3]			
		LDR		r3, =STCTRL			; Start SysTick
		MOV		r4, #STCTRL_GO
		STR		r4,	[r3]		
		
		LDR		r3, =STCURRENT		; Clear STRCTRL.COUNT
		MOV		r4, #STCURR_CLR
		STR		r4,	[r3]		
_timer_start_done	
		MOV		r0, r1				; r0 = return value (previous seconds left)
		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
		;;  Implement Your Logic
		
		; read SECOND_LEFT
		LDR		R3, =SECOND_LEFT 
		LDR		R0, [R3]

		SUBS	R0, R0, #1 ; decrement SECOND_LEFT by 1
		STR		R0, [R3] ; Write back the decremented value

		; Branch to timer update done if not 0
		CMP		R0, #0
		BNE		_timer_update_done

		; If left is 0
		LDR		R3, =STCTRL
		MOV		R4, #STCTRL_STOP
		STR		R4, [R3]

		; Invoke a user-provided signal handler
		MOV		R0, #3
		MSR		CONTROL, R0
		LDR		R5, =USR_HANDLER
		LDR		R6, [R5]
		PUSH	{lr}
		BLX		R6
		POP		{lr}
		
_timer_update_done
		MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Signal handler
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;;  Implement Your Logic
	
	; Read memory at user handler to r2
	LDR		r2, =USR_HANDLER
	LDR		r2, [r2]
	
	; If r0 is SIGALRM, save func (r1) to USR_HANDLER in memory
	LDR		r3, =SIGALRM
	CMP		r0, r3
	BNE		_signal_handler_done
	
	LDR		r3, =USR_HANDLER
	STR		r1, [r3]
	
_signal_handler_done
		MOV		r0, r2					; r0 = return value (previous user handler)
		MOV		pc, lr		; return to Reset_Handler
		
		END		
