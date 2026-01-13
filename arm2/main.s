; TODO : LINK LED SPEED TO MOVE SPEED		
		; CLEANUP
		; DOCS
		
		AREA |.text|, CODE, READONLY, ALIGN=2
		ENTRY
		EXPORT __main
		IMPORT SD_Init
		IMPORT SD_ReadSector
		IMPORT SD_IndexDances
			
		IMPORT DANCE_COUNT
			
		IMPORT BUMPER_INIT
        IMPORT BUMPER_LEFT_PRESSED
		
		IMPORT BUTTON_INIT
        IMPORT BUTTON1_PRESSED

		IMPORT L_LED_ON
		IMPORT R_LED_ON
		IMPORT LED_INIT
		IMPORT LED_SET_MODE
		IMPORT LED_CYCLE_SPEED
		IMPORT LEDS_OFF
			
		IMPORT MOTEUR_INIT
		IMPORT MOTEUR_DROIT_OFF
		IMPORT MOTEUR_GAUCHE_OFF
			
		IMPORT START_BLINKING
		IMPORT STOP_BLINKING
;; LED modes
MODE_ALTERNATE  EQU     0
MODE_TOGETHER   EQU     1
	
GPIO_PORTF_BASE EQU 0x40025000

		AREA |.text|, CODE, READONLY
__main
        BL      BUTTON_INIT
        BL      MOTEUR_INIT
		BL      LED_INIT
		BL		BUMPER_INIT
		
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

        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     do_cycle_speed
		
		BL      BUTTON1_PRESSED
		CMP		R0, #1
		BEQ		START_SD_INIT
		
        B       wait_input

;; ============================================
;; Bumper left pressed - cycle LED speed
;; ============================================
do_cycle_speed
        BL      LED_CYCLE_SPEED
wait_bumper_release
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_release
        
        ; Longer debounce for bumpers
        BL      debounce_long
        B       wait_input
START_SD_INIT		
		BL		STOP_BLINKING
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
		BL		MOTEUR_DROIT_OFF
		BL		MOTEUR_GAUCHE_OFF      
        BL		R_LED_ON
ATTENTE_APPUI
        BL      BUTTON1_PRESSED        
        BNE     ATTENTE_APPUI       
        
        LDR     R2, =800000
DELAI_DEB SUBS R2, R2, #1
        BNE     DELAI_DEB
        
ATTENTE_RELACHE
        BL      BUTTON1_PRESSED
        BEQ     ATTENTE_RELACHE 
		BL		START_BLINKING
		MOV     R0, R11
        BL      SD_ReadSector      
        
        ADD     R11, R11, #1
		BL		STOP_BLINKING
        B       BOUCLE_PRINCIPALE
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
Panic   
		LDR     R0, =0x400253FC
		MOV     R1, #0x02          
		STR     R1, [R0]
STOP    B       STOP
			
			
wait_btn1_release
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     wait_btn1_release
        
        BL      debounce
		MOV		R0, #2
        B       wait_input
debounce
        PUSH    {R1, LR}
        LDR     R1, =0x50000
deb_loop
        SUBS    R1, #1
        BNE     deb_loop
        POP     {R1, LR}
        BX      LR
END