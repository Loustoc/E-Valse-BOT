;; LED.S - LED Blinking with SysTick + Speed Multiplier + Mode
;;
;; LED_MODE:
;;   0 = alternate (LED1/LED2 swap) - for dancing
;;   1 = together (both on/off) - not used
;;   2 = SD_OK: Right LED fixed ON, left LED blinks - SD card found
;;   3 = NO_SD: Right LED blinks 2x faster than left - no SD card
;;
;; LED_MULTIPLIER: 1 to 5 (1=normal, 5=5x faster)
;;
;; Functions:
;;   LED_INIT           - Initialize LEDs and SysTick
;;   LED_SET_PERIOD     - Set base blink period (ms)
;;   LED_CYCLE_SPEED    - Cycle multiplier 1->2->3->4->5->1
;;   LED_GET_MULTIPLIER - Get current multiplier
;;   LED_SET_MODE       - Set mode (0-3)

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
LED1            EQU     0x10            ; PF4 (left)
LED2            EQU     0x20            ; PF5 (right)
LED_BOTH        EQU     0x30

;; SysTick reload for 1ms @ 16MHz
SYSTICK_RELOAD_1MS EQU  15999

;; Default period
DEFAULT_PERIOD  EQU     488

;; Modes
MODE_ALTERNATE  EQU     0
MODE_TOGETHER   EQU     1
MODE_SD_OK      EQU     2               ; Right ON, left blinks
MODE_NO_SD      EQU     3               ; Right 2x faster than left

;; ============================================
;; RAM VARIABLES
;; ============================================
        AREA    |.data|, DATA, READWRITE

TICK_MS         DCD     0               ; Millisecond counter
LED1_STATE      DCD     0               ; Left LED state (0 or 1)
LED2_STATE      DCD     0               ; Right LED state (0 or 1)
LED1_LAST_TOG   DCD     0               ; Left LED last toggle time
LED2_LAST_TOG   DCD     0               ; Right LED last toggle time
LED_PERIOD      DCD     488             ; Base period in ms
LED_MULTIPLIER  DCD     1               ; Speed multiplier (1-5)
LED_MODE        DCD     2               ; Default: MODE_SD_OK (will be set by main)

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

        LDR     R1, =LED1_STATE
        STR     R0, [R1]

        LDR     R1, =LED2_STATE
        STR     R0, [R1]

        LDR     R1, =LED1_LAST_TOG
        STR     R0, [R1]

        LDR     R1, =LED2_LAST_TOG
        STR     R0, [R1]

        LDR     R1, =LED_PERIOD
        LDR     R0, =DEFAULT_PERIOD
        STR     R0, [R1]

        LDR     R1, =LED_MULTIPLIER
        MOV     R0, #1
        STR     R0, [R1]

        LDR     R1, =LED_MODE
        MOV     R0, #MODE_SD_OK
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
        PUSH    {R0-R7, LR}

        ; Increment tick counter
        LDR     R0, =TICK_MS
        LDR     R1, [R0]
        ADD     R1, R1, #1
        STR     R1, [R0]
        MOV     R7, R1                  ; R7 = current tick

        ; Get mode
        LDR     R0, =LED_MODE
        LDR     R6, [R0]                ; R6 = mode

        ; Get period and multiplier
        LDR     R0, =LED_PERIOD
        LDR     R3, [R0]                ; R3 = base period
        LDR     R0, =LED_MULTIPLIER
        LDR     R4, [R0]                ; R4 = multiplier

        ; Branch based on mode
        CMP     R6, #MODE_ALTERNATE
        BEQ     handle_alternate
        CMP     R6, #MODE_TOGETHER
        BEQ     handle_together
        CMP     R6, #MODE_SD_OK
        BEQ     handle_sd_ok
        CMP     R6, #MODE_NO_SD
        BEQ     handle_no_sd
        B       systick_done

;; --- MODE_ALTERNATE: LEDs swap ---
handle_alternate
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2              ; elapsed
        MUL     R1, R1, R4              ; elapsed * multiplier
        CMP     R1, R3
        BLT     systick_done

        STR     R7, [R0]                ; update last toggle

        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     alt_state0
        MOV     R0, #LED1               ; State 1: LED1 on, LED2 off
        B       led_write
alt_state0
        MOV     R0, #LED2               ; State 0: LED1 off, LED2 on
        B       led_write

;; --- MODE_TOGETHER: both LEDs same ---
handle_together
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     systick_done

        STR     R7, [R0]

        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     tog_off
        MOV     R0, #LED_BOTH
        B       led_write
tog_off
        MOV     R0, #0
        B       led_write

;; --- MODE_SD_OK: Right LED fixed ON, left LED blinks ---
handle_sd_ok
        ; Check if time to toggle left LED
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     sd_ok_write             ; not time yet, just write current state

        STR     R7, [R0]                ; update last toggle

        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

sd_ok_write
        ; Right LED always ON, left LED based on state
        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     sd_ok_left_off
        MOV     R0, #LED_BOTH           ; Both on (right always on, left on)
        B       led_write
sd_ok_left_off
        MOV     R0, #LED2               ; Right on, left off
        B       led_write

;; --- MODE_NO_SD: Right LED blinks 2x faster than left ---
handle_no_sd
        ; Check left LED (normal speed)
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     no_sd_check_right

        STR     R7, [R0]
        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

no_sd_check_right
        ; Check right LED (2x faster = half period)
        LDR     R0, =LED2_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        LSL     R1, R1, #1              ; multiply by 2 (2x faster)
        CMP     R1, R3
        BLT     no_sd_write

        STR     R7, [R0]
        LDR     R0, =LED2_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

no_sd_write
        ; Combine both LED states
        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        LDR     R0, =LED2_STATE
        LDR     R5, [R0]

        MOV     R0, #0
        CMP     R1, #1
        ORREQ   R0, R0, #LED1           ; Left LED on if state=1
        CMP     R5, #1
        ORREQ   R0, R0, #LED2           ; Right LED on if state=1

        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        ; fall through to led_write

led_write
        STR     R0, [R2]

systick_done
        POP     {R0-R7, PC}

;; ============================================
;; LED_SET_PERIOD - Set base period
;; Input: R0 = period in ms
;; ============================================
LED_SET_PERIOD
        LDR     R1, =LED_PERIOD
        STR     R0, [R1]
        BX      LR

;; ============================================
;; LED_CYCLE_SPEED - Cycle multiplier 1->2->3->4->5->1
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
;; Input: R0 = mode (0-3)
;; ============================================
LED_SET_MODE
        LDR     R1, =LED_MODE
        STR     R0, [R1]
        BX      LR

        END
