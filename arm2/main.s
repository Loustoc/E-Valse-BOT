;; EvalBot - Dancing Robot
        ;; Wait for input:
        ;;   - Bumper Left (PE1) = cycle LED speed (1-5)
        ;;   - Button 1 (SW1/PD6) = VALSE
        ;;   - Button 2 (SW2/PD7) = ITALODISCO
        ;;
        ;; While waiting: both LEDs blink together
        ;; While dancing: LEDs alternate

        AREA    |.text|, CODE, READONLY
        ENTRY
        EXPORT  __main

        IMPORT  MOTEUR_INIT
        IMPORT  LED_INIT
        IMPORT  LED_CYCLE_SPEED
        IMPORT  LED_SET_MODE
        IMPORT  BUMPER_INIT
        IMPORT  BUMPER_LEFT_PRESSED
        IMPORT  BUTTON_INIT
        IMPORT  BUTTON1_PRESSED
        IMPORT  BUTTON2_PRESSED
        IMPORT  ITALODISCO
        IMPORT  VALSE

;; LED modes
MODE_ALTERNATE  EQU     0
MODE_TOGETHER   EQU     1

;; ============================================
;; Main program
;; ============================================
__main
        BL      MOTEUR_INIT
        BL      LED_INIT
        BL      BUMPER_INIT
        BL      BUTTON_INIT
        
        ; Set LED mode to "together" for waiting
        MOV     R0, #MODE_TOGETHER
        BL      LED_SET_MODE

;; ============================================
;; Wait loop - wait for button or bumper
;; ============================================
wait_input
        ; Small delay to avoid too fast polling
        LDR     R1, =0x1000
poll_delay
        SUBS    R1, #1
        BNE     poll_delay

        ; Check bumper left (PE1) - cycle LED speed
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     do_cycle_speed
        
        ; Check button 1 (SW1/PD6) - VALSE
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     do_valse
        
        ; Check button 2 (SW2/PD7) - ITALODISCO
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     do_disco
        
        ; Nothing pressed, keep waiting
        B       wait_input

;; ============================================
;; Bumper left pressed - cycle LED speed
;; ============================================
do_cycle_speed
        BL      LED_CYCLE_SPEED
        
        ; Wait for release
wait_bumper_release
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_release
        
        ; Longer debounce for bumpers
        BL      debounce_long
        
        B       wait_input

;; ============================================
;; Button 1 pressed - VALSE
;; ============================================
do_valse
        ; Wait for release first
wait_btn1_release
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     wait_btn1_release
        
        BL      debounce
        
        ; Set LED mode to alternate for dancing
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE
        
        ; Run VALSE
        BL      VALSE
        
        ; Back to together mode for waiting
        MOV     R0, #MODE_TOGETHER
        BL      LED_SET_MODE
        
        ; Back to waiting
        B       wait_input

;; ============================================
;; Button 2 pressed - ITALODISCO
;; ============================================
do_disco
        ; Wait for release first
wait_btn2_release
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     wait_btn2_release
        
        BL      debounce
        
        ; Set LED mode to alternate for dancing
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE
        
        ; Run ITALODISCO
        BL      ITALODISCO
        
        ; Back to together mode for waiting
        MOV     R0, #MODE_TOGETHER
        BL      LED_SET_MODE
        
        ; Back to waiting
        B       wait_input

;; ============================================
;; Debounce delay (~50ms) for buttons
;; ============================================
debounce
        PUSH    {R1, LR}
        LDR     R1, =0x50000
deb_loop
        SUBS    R1, #1
        BNE     deb_loop
        POP     {R1, LR}
        BX      LR

;; ============================================
;; Debounce delay (~200ms) for bumpers
;; ============================================
debounce_long
        PUSH    {R1, LR}
        LDR     R1, =0x200000
deb_long_loop
        SUBS    R1, #1
        BNE     deb_long_loop
        POP     {R1, LR}
        BX      LR

        END