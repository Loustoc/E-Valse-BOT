;; LED.S - LED Blinking with SysTick + Speed Multiplier + Mode
;;
;; LED_MODE: 0 = alternate (LED1/LED2 swap), 1 = together (both on/off)
;; LED_MULTIPLIER: 1 to 5 (1=normal, 5=5x faster)
;;
;; Functions:
;;   LED_INIT           - Initialize LEDs and SysTick
;;   LED_SET_PERIOD     - Set base blink period (ms)
;;   LED_CYCLE_SPEED    - Cycle multiplier 1?2?3?4?5?1
;;   LED_GET_MULTIPLIER - Get current multiplier
;;   LED_SET_MODE       - Set mode (0=alternate, 1=together)

        AREA    |.text|, CODE, READONLY

;; SysTick registers
NVIC_ST_CTRL    EQU     0xE000E010
NVIC_ST_RELOAD  EQU     0xE000E014
NVIC_ST_CURRENT EQU     0xE000E018

;; GPIO Port F
SYSCTL_RCGC2    EQU     0x400FE108
GPIO_PORTF_BASE EQU     0x40025000
GPIO_O_DIR      EQU     0x400
GPIO_O_DEN      EQU     0x51C
GPIO_O_DR2R     EQU     0x500

;; LED pins
LED1            EQU     0x10            ; PF4
LED2            EQU     0x20            ; PF5
LED_BOTH        EQU     0x30

;; SysTick reload for 1ms @ 16MHz
SYSTICK_RELOAD_1MS EQU  15999

;; Default period
DEFAULT_PERIOD  EQU     488

;; Modes
MODE_ALTERNATE  EQU     0
MODE_TOGETHER   EQU     1

;; ============================================
;; RAM VARIABLES
;; ============================================
        AREA    |.data|, DATA, READWRITE

TICK_MS         DCD     0               ; Millisecond counter
LED_STATE       DCD     0               ; Current state (0 or 1)
LED_LAST_TOGGLE DCD     0               ; Last toggle time
LED_PERIOD      DCD     488             ; Base period in ms
LED_MULTIPLIER  DCD     1               ; Speed multiplier (1-5)
LED_MODE        DCD     1               ; 0=alternate, 1=together (default: together)

;; ============================================
;; EXPORTS
;; ============================================
        AREA    |.text|, CODE, READONLY
        
        EXPORT  SysTick_Handler
        EXPORT  LED_INIT
        EXPORT  LED_SET_PERIOD
        EXPORT  LED_CYCLE_SPEED
        EXPORT  LED_GET_MULTIPLIER
        EXPORT  LED_SET_MODE
        EXPORT  TICK_MS
					
		EXPORT L_LED_ON
		EXPORT R_LED_ON
		EXPORT LEDS_OFF

		EXPORT START_BLINKING
		EXPORT STOP_BLINKING
;; ============================================
;; LED_INIT
;; ============================================
LED_INIT
        PUSH    {R0-R2, LR}
        
        ; Enable clock Port F
        LDR     R1, =SYSCTL_RCGC2
        LDR     R0, [R1]
        ORR     R0, R0, #0x20
        STR     R0, [R1]
        NOP
        NOP
        NOP
        NOP
        
        ; PF4, PF5 as outputs
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DIR
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]
        
        ; Digital enable
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DEN
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]
        
        ; 2mA drive
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DR2R
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]
        
        ; LEDs off initially
        LDR     R1, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        MOV     R0, #0
        STR     R0, [R1]
        
        ; Initialize variables
        LDR     R1, =TICK_MS
        MOV     R0, #0
        STR     R0, [R1]
        
        LDR     R1, =LED_STATE
        STR     R0, [R1]
        
        LDR     R1, =LED_LAST_TOGGLE
        STR     R0, [R1]
        
        LDR     R1, =LED_PERIOD
        LDR     R0, =DEFAULT_PERIOD
        STR     R0, [R1]
        
        LDR     R1, =LED_MULTIPLIER
        MOV     R0, #1
        STR     R0, [R1]
        
        LDR     R1, =LED_MODE
        MOV     R0, #MODE_TOGETHER      ; Default: both LEDs together
        STR     R0, [R1]
        
        ; Configure SysTick for 1ms
        LDR     R1, =NVIC_ST_RELOAD
        LDR     R0, =SYSTICK_RELOAD_1MS
        STR     R0, [R1]
        
        LDR     R1, =NVIC_ST_CURRENT
        MOV     R0, #0
        STR     R0, [R1]
        
        ; Enable SysTick with interrupt
        LDR     R1, =NVIC_ST_CTRL
        MOV     R0, #0x07
        STR     R0, [R1]
        
        POP     {R0-R2, PC}

;; ============================================
;; SysTick_Handler - runs every 1ms
;; ============================================
SysTick_Handler
        PUSH    {R0-R6, LR}
        
        ; Increment tick counter
        LDR     R0, =TICK_MS
        LDR     R1, [R0]
        ADD     R1, R1, #1
        STR     R1, [R0]
        MOV     R5, R1                  ; R5 = current tick
        
        ; Get last toggle time
        LDR     R0, =LED_LAST_TOGGLE
        LDR     R2, [R0]                ; R2 = last toggle
        
        ; Get period
        LDR     R0, =LED_PERIOD
        LDR     R3, [R0]                ; R3 = base period
        
        ; Get multiplier
        LDR     R0, =LED_MULTIPLIER
        LDR     R4, [R0]                ; R4 = multiplier
        
        ; elapsed = current - last
        SUB     R1, R5, R2              ; R1 = elapsed
        
        ; Check: elapsed * multiplier >= period
        MUL     R1, R1, R4              ; R1 = elapsed * multiplier
        CMP     R1, R3
        BLT     systick_done
        
        ; Time to toggle - update last toggle time
        LDR     R0, =LED_LAST_TOGGLE
        STR     R5, [R0]
        
        ; Toggle state
        LDR     R0, =LED_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]
        
        ; Get mode
        LDR     R0, =LED_MODE
        LDR     R6, [R0]                ; R6 = mode
        
        ; Write to LEDs based on mode
        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        
        CMP     R6, #MODE_TOGETHER
        BEQ     mode_together
        
        ; MODE_ALTERNATE: LED1 and LED2 swap
        CMP     R1, #0
        BEQ     alt_state0
        MOV     R0, #LED1               ; State 1: LED1 on, LED2 off
        B       led_write
alt_state0
        MOV     R0, #LED2               ; State 0: LED1 off, LED2 on
        B       led_write
        
mode_together
        ; MODE_TOGETHER: both LEDs on/off together
        CMP     R1, #0
        BEQ     tog_off
        MOV     R0, #LED_BOTH           ; State 1: both on
        B       led_write
tog_off
        MOV     R0, #0                  ; State 0: both off
        
led_write
        STR     R0, [R2]
        
systick_done
        POP     {R0-R6, PC}

;; ============================================
;; LED_SET_PERIOD - Set base period
;; Input: R0 = period in ms
;; ============================================
LED_SET_PERIOD
        LDR     R1, =LED_PERIOD
        STR     R0, [R1]
        BX      LR

;; ============================================
;; LED_CYCLE_SPEED - Cycle multiplier 1?2?3?4?5?1
;; Returns: R0 = new multiplier
;; ============================================
LED_CYCLE_SPEED
        PUSH    {R1, LR}
        
        LDR     R0, =LED_MULTIPLIER
        LDR     R1, [R0]
        
        ADD     R1, R1, #1
        CMP     R1, #6
        BLT     cycle_store
        MOV     R1, #1
        
cycle_store
        STR     R1, [R0]
        MOV     R0, R1
        
        POP     {R1, LR}
        BX      LR

;; ============================================
;; LED_GET_MULTIPLIER - Get current multiplier
;; Output: R0 = multiplier (1-5)
;; ============================================
LED_GET_MULTIPLIER
        LDR     R0, =LED_MULTIPLIER
        LDR     R0, [R0]
        BX      LR

;; ============================================
;; LED_SET_MODE - Set LED mode
;; Input: R0 = 0 (alternate) or 1 (together)
;; ============================================
LED_SET_MODE
        LDR     R1, =LED_MODE
        STR     R0, [R1]
        BX      LR
		
STOP_BLINKING
        PUSH    {R0, R1, LR}
        
        LDR     R1, =NVIC_ST_CTRL
        MOV     R0, #0
        STR     R0, [R1]       
        
        BL      LEDS_OFF
        
        POP     {R0, R1, PC}

START_BLINKING
        PUSH    {R0, R1, LR}
        
        LDR     R1, =NVIC_ST_CURRENT
        MOV     R0, #0
        STR     R0, [R1]
        
        LDR     R1, =NVIC_ST_CTRL
        MOV     R0, #0x07
        STR     R0, [R1]
        
        POP     {R0, R1, PC}
;; ============================================
;; MEANT FOR DEBUGGING
;; ============================================
L_LED_ON
		LDR     R0, =GPIO_PORTF_BASE
		MOV     R1, #LED2      
		STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
R_LED_ON
		LDR     R0, =GPIO_PORTF_BASE
		MOV     R1, #LED1       
		STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
LEDS_ON
		LDR     R0, =GPIO_PORTF_BASE
		MOV     R1, #LED_BOTH
		STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
LEDS_OFF
		LDR     R0, =GPIO_PORTF_BASE
		MOV     R1, #0
		STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
		
		END