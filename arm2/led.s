;; ============================================================================
;; LED.S - LED Blinking with SysTick Interrupt (NEW FILE)
;; ============================================================================
;; This module handles LED blinking automatically via SysTick interrupt.
;; The interrupt fires every 1ms and:
;;   1. Increments a millisecond counter (TICK_MS)
;;   2. Toggles LEDs when the blink period is reached
;;
;; USAGE:
;;   - Call LED_INIT once at startup to configure GPIO and start SysTick
;;   - LEDs will blink automatically! No code needed in main loop.
;;   - Call LED_SET_PERIOD to change blink speed (in milliseconds)
;;
;; HARDWARE:
;;   PF4 = LED1
;;   PF5 = LED2
;; ============================================================================

        AREA    |.text|, CODE, READONLY

;; ============================================================================
;; CONSTANTS
;; ============================================================================

;; SysTick registers (Cortex-M3 core peripheral)
NVIC_ST_CTRL    EQU     0xE000E010      ; Control and Status
NVIC_ST_RELOAD  EQU     0xE000E014      ; Reload Value
NVIC_ST_CURRENT EQU     0xE000E018      ; Current Value

;; GPIO Port F
SYSCTL_RCGC2    EQU     0x400FE108      ; Clock gating
GPIO_PORTF_BASE EQU     0x40025000
GPIO_O_DIR      EQU     0x400
GPIO_O_DEN      EQU     0x51C
GPIO_O_DR2R     EQU     0x500

;; LED pins
LED1            EQU     0x10            ; PF4
LED2            EQU     0x20            ; PF5
LED_BOTH        EQU     0x30            ; Both LEDs

;; Timing (assuming 16 MHz clock)
;; SysTick reload for 1ms = 16,000,000 / 1000 - 1 = 15999
SYSTICK_RELOAD_1MS EQU  15999

;; Default blink period
DEFAULT_PERIOD  EQU     488             ; 250ms = 4 blinks per second

;; ============================================================================
;; RAM VARIABLES
;; ============================================================================
        AREA    |.data|, DATA, READWRITE

TICK_MS         DCD     0               ; Millisecond counter (incremented by interrupt)
LED_STATE       DCD     0               ; Current LED state (0 or 1)
LED_LAST_TOGGLE DCD     0               ; Time of last toggle
LED_PERIOD      DCD     250             ; Blink period in ms

;; ============================================================================
;; EXPORTS
;; ============================================================================
        AREA    |.text|, CODE, READONLY
        
        EXPORT  SysTick_Handler         ; EXPORTED for Startup.s vector table!
        EXPORT  LED_INIT                ; Initialize LEDs and start SysTick
        EXPORT  LED_SET_PERIOD          ; Set blink period in ms
        EXPORT  TICK_MS                 ; Export tick counter for other modules

;; ============================================================================
;; LED_INIT - Initialize LED GPIO and start SysTick interrupt
;; ============================================================================
;; Call this once at the start of your program.
;; After this, LEDs will blink automatically!
;;
;; Parameters: None
;; Returns: None
;; ============================================================================
LED_INIT        PROC
        PUSH    {R0-R2, LR}
        
        ;; ----- Enable clock for Port F -----
        LDR     R1, =SYSCTL_RCGC2
        LDR     R0, [R1]
        ORR     R0, R0, #0x20           ; Bit 5 = Port F
        STR     R0, [R1]
        
        ;; Wait for clock to stabilize
        NOP
        NOP
        NOP
        NOP
        
        ;; ----- Configure PF4, PF5 as outputs -----
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DIR
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]
        
        ;; ----- Enable digital function -----
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DEN
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]
        
        ;; ----- Set 2mA drive -----
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DR2R
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]
        
        ;; ----- Turn off both LEDs initially -----
        LDR     R1, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        MOV     R0, #0
        STR     R0, [R1]
        
        ;; ----- Initialize variables -----
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
        
        ;; ----- Configure SysTick for 1ms interrupt -----
        ;; Set reload value
        LDR     R1, =NVIC_ST_RELOAD
        LDR     R0, =SYSTICK_RELOAD_1MS
        STR     R0, [R1]
        
        ;; Clear current value
        LDR     R1, =NVIC_ST_CURRENT
        MOV     R0, #0
        STR     R0, [R1]
        
        ;; Enable SysTick with interrupt
        ;; Bit 0: ENABLE
        ;; Bit 1: TICKINT (enable interrupt)
        ;; Bit 2: CLKSOURCE (use CPU clock)
        LDR     R1, =NVIC_ST_CTRL
        MOV     R0, #0x07               ; ENABLE | TICKINT | CLKSOURCE
        STR     R0, [R1]
        
        POP     {R0-R2, PC}
        ENDP

;; ============================================================================
;; SysTick_Handler - Interrupt handler (runs every 1ms AUTOMATICALLY!)
;; ============================================================================
;; This function is called by the CPU every 1ms (via vector table).
;; It:
;;   1. Increments TICK_MS counter
;;   2. Checks if LED period elapsed
;;   3. Toggles LEDs if needed
;;
;; YOU DON'T CALL THIS - IT RUNS AUTOMATICALLY!
;; ============================================================================
SysTick_Handler PROC
        PUSH    {R0-R4, LR}
        
        ;; ===== Step 1: Increment millisecond counter =====
        LDR     R0, =TICK_MS
        LDR     R1, [R0]
        ADD     R1, R1, #1
        STR     R1, [R0]
        MOV     R4, R1                  ; R4 = current tick count
        
        ;; ===== Step 2: Check if LED period elapsed =====
        LDR     R0, =LED_LAST_TOGGLE
        LDR     R2, [R0]                ; R2 = last toggle time
        
        LDR     R0, =LED_PERIOD
        LDR     R3, [R0]                ; R3 = period
        
        SUB     R1, R4, R2              ; R1 = elapsed time
        CMP     R1, R3                  ; Compare with period
        BLT     systick_done            ; Not time to toggle yet
        
        ;; ===== Step 3: Toggle LEDs =====
        ;; Update last toggle time
        LDR     R0, =LED_LAST_TOGGLE
        STR     R4, [R0]
        
        ;; Toggle state variable
        LDR     R0, =LED_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1              ; Toggle: 0?1 or 1?0
        STR     R1, [R0]
        
        ;; Write to LED pins (alternate pattern: LED1 and LED2 swap)
        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     led_state_0
        
        ;; State 1: LED1 ON, LED2 OFF
        MOV     R0, #LED1
        B       write_leds
        
led_state_0
        ;; State 0: LED1 OFF, LED2 ON
        MOV     R0, #LED2
        
write_leds
        STR     R0, [R2]
        
systick_done
        POP     {R0-R4, PC}
        ENDP

;; ============================================================================
;; LED_SET_PERIOD - Change LED blink period
;; ============================================================================
;; Parameters: R0 = new period in milliseconds
;; Returns: None
;;
;; Example:
;;   MOV R0, #100    ; 100ms = fast blink
;;   BL  LED_SET_PERIOD
;;
;;   MOV R0, #500    ; 500ms = slow blink
;;   BL  LED_SET_PERIOD
;; ============================================================================
LED_SET_PERIOD  PROC
        LDR     R1, =LED_PERIOD
        STR     R0, [R1]
        BX      LR
        ENDP

        END