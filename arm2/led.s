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


SYSCTL_PERIPH_GPIOF EQU 0x400FE108
GPIO_PORTF_BASE     EQU 0x40025000

; GPIO offsets
GPIO_O_DIR          EQU 0x400   ; Direction
GPIO_O_DR2R         EQU 0x500   ; 2-mA drive
GPIO_O_DEN          EQU 0x51C   ; Digital Enable

; LED pins
LED1                EQU 0x10    ; PF4
LED2                EQU 0x20    ; PF5

; Delay
DUREE               EQU 0x001FFFFF

;----------------------------
; Main program
;----------------------------
__main
        ;; Enable clock for Port F
        LDR     R6, =SYSCTL_PERIPH_GPIOF
        MOV     R0, #0x20         ; bit 5 = GPIOF
        STR     R0, [R6]

        ;; small delay for clock to stabilize
        NOP
        NOP
        NOP

        ;; Configure LED pins as output
        LDR     R6, =GPIO_PORTF_BASE + GPIO_O_DIR
        LDR     R0, =LED1 | LED2
        STR     R0, [R6]

        ;; Enable digital function
        LDR     R6, =GPIO_PORTF_BASE + GPIO_O_DEN
        STR     R0, [R6]

        ;; 2-mA drive
        LDR     R6, =GPIO_PORTF_BASE + GPIO_O_DR2R
        STR     R0, [R6]

        ;; Prepare LED masks
        LDR     R2, =0x00          ; all LEDs OFF
        LDR     R3, =LED1          ; LED1 ON
        LDR     R4, =LED2          ; LED2 ON

        ;; Use GPIODATA address mapping for pins
        LDR     R5, =GPIO_PORTF_BASE + (LED1<<2)  ; LED1 data address
        LDR     R7, =GPIO_PORTF_BASE + (LED2<<2)  ; LED2 data address
		
		
		;; BL Branchement vers un lien (sous programme)

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT	   		   
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		
		

;----------------------------
; Blink loop
;----------------------------
loop
        ;; LED1 ON, LED2 OFF
        STR     R3, [R5]           ; LED1 ON
        STR     R2, [R7]           ; LED2 OFF
        LDR     R1, =DUREE/8
wait1   SUBS    R1, #1
        BNE     wait1

        ;; LED1 OFF, LED2 ON
        STR     R2, [R5]           ; LED1 OFF
        STR     R4, [R7]           ; LED2 ON
        LDR     R1, =DUREE/8
wait2   SUBS    R1, #1
        BNE     wait2
		

; Evalbot avance droit devant
	
		BL		MOTEUR_GAUCHE_AVANT	   
		BL		MOTEUR_DROIT_AVANT

		
		LDR     R1, =DUREE*5
wait3   SUBS    R1, #1
        BNE     wait3
		
		
		
		BL 		MOTEUR_GAUCHE_AVANT
		BL 		MOTEUR_DROIT_ARRIERE
		
		LDR     R1, =DUREE*12
wait4   SUBS    R1, #1
        BNE     wait4
		
		
		
		BL 		MOTEUR_GAUCHE_ARRIERE
		BL 		MOTEUR_DROIT_AVANT
		
		LDR     R1, =DUREE*12
wait8   SUBS    R1, #1
        BNE     wait8
		
		
		
		BL		MOTEUR_GAUCHE_AVANT	   
		BL		MOTEUR_DROIT_AVANT

		
		LDR     R1, =DUREE*5
wait5   SUBS    R1, #1
        BNE     wait5
		
		
		
		BL		MOTEUR_GAUCHE_AVANT	  
		BL		MOTEUR_DROIT_OFF

		
		LDR     R1, =DUREE*10
wait6   SUBS    R1, #1
        BNE     wait6
		
		BL		MOTEUR_DROIT_ON
		BL		MOTEUR_GAUCHE_AVANT	   
		BL		MOTEUR_DROIT_AVANT

		
		LDR     R1, =DUREE*5
wait7   SUBS    R1, #1
        BNE     wait7

		
			
		
		; Avancement pendant une période (deux WAIT)
		;BL	WAIT	; BL (Branchement vers le lien WAIT); possibilité de retour à la suite avec (BX LR)
		;BL	WAIT
		
		; Rotation à droite de l'Evalbot pendant une demi-période (1 seul WAIT)
		;BL	MOTEUR_DROIT_ARRIERE   ; MOTEUR_DROIT_INVERSE
		;BL	WAIT


        B       loop
        END
