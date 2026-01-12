		AREA |.text|, CODE, READONLY, ALIGN=2
		ENTRY
		EXPORT __main
		IMPORT SD_Init
		IMPORT SD_ReadSector
		IMPORT SD_IndexDances
		IMPORT DANCE_COUNT
		IMPORT SWITCH_INIT
		IMPORT READ_SWITCH
		IMPORT L_LED_ON
		IMPORT R_LED_ON
			
GPIO_PORTF_BASE EQU 0x40025000

		AREA |.text|, CODE, READONLY
__main
        BL      SWITCH_INIT
        
        LDR     R0, =0x400FE108
        LDR     R1, [R0]
        ORR     R1, R1, #0x20      
        STR     R1, [R0]
        NOP
        NOP
        NOP

        LDR     R0, =GPIO_PORTF_BASE
        MOV     R1, #0x30           
        STR     R1, [R0, #0x400]
        STR     R1, [R0, #0x51C]

        BL      SD_Init
        CMP     R0, #1
        BNE     Panic               

        BL      SD_IndexDances
        
        MOV     R11, #0             

BOUCLE_PRINCIPALE
        BL      R_LED_ON       
        
ATTENTE_APPUI
        BL      READ_SWITCH        
        BNE     ATTENTE_APPUI       
        
        LDR     R2, =800000
DELAI_DEB SUBS R2, R2, #1
        BNE     DELAI_DEB
        
ATTENTE_RELACHE
        BL      READ_SWITCH
        BEQ     ATTENTE_RELACHE    

        BL      L_LED_ON
        MOV     R0, R11
        BL      SD_ReadSector      
        
        ADD     R11, R11, #1
        B       BOUCLE_PRINCIPALE
Panic   
		LDR     R0, =0x400253FC
		MOV     R1, #0x02          
		STR     R1, [R0]
STOP    B       STOP
		END
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
