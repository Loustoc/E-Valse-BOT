        ;; RK - EvalBot (Cortex-M3 TI Stellaris)
        ;; Blink LED1 (PF4) and LED2 (PF5) alternately

        AREA |.text|, CODE, READONLY
        ENTRY
        EXPORT __main

;----------------------------
; Peripheral base addresses
;----------------------------

		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
			
		IMPORT  MOTEUR_SET_VITESSE      ; Import the function
			
        IMPORT  LED_INIT                ; Initialize LEDs + start SysTick
        IMPORT  LED_SET_PERIOD          ; Change blink speed
			
		IMPORT ITALODISCO
		IMPORT VALSE


SYSCTL_PERIPH_GPIOF EQU 0x400FE108
GPIO_PORTF_BASE     EQU 0x40025000

; GPIO offsets
GPIO_O_DIR          EQU 0x400   ; Direction
GPIO_O_DR2R         EQU 0x500   ; 2-mA drive
GPIO_O_DEN          EQU 0x51C   ; Digital Enable

; Delay
DUREE               EQU 0x001FFFFF
	
VITESSE_VALSE   EQU     0x155           ; Slow
VITESSE_DISCO   EQU     0x005           ; Fast


;----------------------------
; Main program
;----------------------------
__main		
		BL      MOTEUR_INIT
        BL      LED_INIT 
		
;----------------------------
; Main loop
;----------------------------
loop

   
		 BL ITALODISCO
		;BL VALSE

        B       loop
		
        END
