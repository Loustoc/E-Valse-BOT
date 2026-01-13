		AREA    |.text|, CODE, READONLY
			
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; d?activer le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arri?re
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; d?activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arri?re
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche
			
		IMPORT  MOTEUR_SET_VITESSE      ; Import the function
			
        IMPORT  LED_INIT                ; Initialize LEDs + start SysTick
        IMPORT  LED_SET_PERIOD          ; Change blink speed
			
DUREE           EQU 0x001FFFFF
	
VITESSE_VALSE   EQU     0x155           ; Slow
VITESSE_DISCO   EQU     0x005           ; Fast

		EXPORT  VALSE

VALSE
		
		PUSH {LR}
		
		LDR     R0, =VITESSE_VALSE
        BL      MOTEUR_SET_VITESSE
		
		LDR     R0, =1000
        BL      LED_SET_PERIOD
        
        BL  MOTEUR_GAUCHE_ON
		BL 	MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_AVANT

        LDR R1, =DUREE*21
valse_w1
        SUBS R1, #1
        BNE  valse_w1
		
        
        BL  MOTEUR_GAUCHE_AVANT
        BL  MOTEUR_DROIT_AVANT

        LDR R1, =DUREE*10
valse_w2
        SUBS R1, #1
        BNE  valse_w2



        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_OFF

        LDR R1, =DUREE*10
valse_w3
        SUBS R1, #1
        BNE  valse_w3

		POP {LR}
        BX  LR
		
		
; STAR		
		
		EXPORT STAR
STAR
		PUSH {LR}
		
		BL  MOTEUR_DROIT_ON
		BL  MOTEUR_GAUCHE_AVANT
		BL  MOTEUR_DROIT_AVANT
	
        LDR R1, =DUREE*1
star_w1
        SUBS R1, #1
        BNE  star_w1
   
   
   
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE
	
        LDR R1, =DUREE*1
star_w2
        SUBS R1, #1
        BNE  star_w2
   
		
		BL  MOTEUR_DROIT_OFF
		BL  MOTEUR_GAUCHE_AVANT
		BL  MOTEUR_DROIT_ARRIERE

        LDR R1, =DUREE*3
star_w3
		SUBS R1, #1
		BNE  star_w3
		BL  MOTEUR_DROIT_ON
		
		BL	MOTEUR_DROIT_OFF
		BL 	MOTEUR_GAUCHE_OFF
		
		
		
		
		POP {LR}
        BX  LR
		
		
;CIRCLE_RIGHT
		EXPORT CIRCLE_RIGHT
CIRCLE_RIGHT		
		
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_AVANT
	
        LDR R1, =DUREE*6
cr_wait
        SUBS R1, #1
        BNE  cr_wait
		
		POP {LR}
        BX  LR
		
		
;CIRCLE_LEFT
		EXPORT CIRCLE_LEFT
CIRCLE_LEFT
		
		PUSH {LR}
		
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
        LDR R1, =DUREE*6
cl_wait
        SUBS R1, #1
        BNE  cl_wait
		
		POP {LR}
        BX  LR




;DEMICIRCLE_RIGHT
		EXPORT DEMICIRCLE_RIGHT
DEMICIRCLE_RIGHT		
		
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_AVANT
	
        LDR R1, =DUREE*3
dcr_wait
        SUBS R1, #1
        BNE  dcr_wait
		
		POP {LR}
        BX  LR
		
		
;DEMICIRCLE_LEFT
		EXPORT DEMICIRCLE_LEFT
DEMICIRCLE_LEFT
		
		PUSH {LR}
		
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
        LDR R1, =DUREE*3
dcl_wait
        SUBS R1, #1
        BNE  dcl_wait
		
		POP {LR}
        BX  LR
		



;WALK
		EXPORT WALK
WALK
		PUSH {LR}


		 BL  MOTEUR_GAUCHE_AVANT
		 BL  MOTEUR_DROIT_AVANT

         LDR R1, =DUREE*1
walk_w1
         SUBS R1, #1
         BNE  walk_w1
		 
		 
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_ARRIERE
	
		LDR R1, =(DUREE*3)/2
walk_w2
        SUBS R1, #1
        BNE  walk_w2	


		 BL  MOTEUR_GAUCHE_AVANT
		 BL  MOTEUR_DROIT_AVANT

         LDR R1, =DUREE*1
walk_w3
         SUBS R1, #1
         BNE  walk_w3
		 
		 
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
		LDR R1, =(DUREE*3)/2
walk_w4
        SUBS R1, #1
        BNE  walk_w4	
		
		
		
		
		
		POP {LR}
        BX  LR
		
		
		
		
		
;WALK ON BACK
		EXPORT WALK_BACK
WALK_BACK
		PUSH {LR}


		 BL  MOTEUR_GAUCHE_ARRIERE
		 BL  MOTEUR_DROIT_ARRIERE

         LDR R1, =DUREE*1
wb_w1
         SUBS R1, #1
         BNE  wb_w1
		 
		 
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
		LDR R1, =(DUREE*3)/2
wb_w2
        SUBS R1, #1
        BNE  wb_w2	


		 BL  MOTEUR_GAUCHE_ARRIERE
		 BL  MOTEUR_DROIT_ARRIERE

         LDR R1, =DUREE*1
wb_w3
         SUBS R1, #1
         BNE  wb_w3
		 
		 
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_ARRIERE
	
		LDR R1, =(DUREE*3)/2
wb_w4
        SUBS R1, #1
        BNE  wb_w4	
		
		
		POP {LR}
        BX  LR





		EXPORT FRONTBACK
FRONTBACK
		PUSH {LR}
		
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_AVANT
	
		LDR R1, =DUREE*1
fb_w1
        SUBS R1, #1
        BNE  fb_w1	
		
		
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_ARRIERE
	
		LDR R1, =DUREE*1
fb_w2
        SUBS R1, #1
        BNE  fb_w2	



		POP {LR}
        BX  LR


		EXPORT FRONT
FRONT
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE
	
        LDR R1, =DUREE*4
front_w
        SUBS R1, #1
        BNE  front_w
		
		
		POP {LR}
        BX  LR

		EXPORT FRONTSHORT
FRONTSHORT
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE
	
        LDR R1, =DUREE*2
fs_wait
        SUBS R1, #1
        BNE  fs_wait
		
		
		POP {LR}
        BX  LR

		
		EXPORT ITALODISCO
ITALODISCO
;; MINIMAL TEST VERSION - just do one simple move
		PUSH {LR}

		LDR     R0, =VITESSE_DISCO
        BL      MOTEUR_SET_VITESSE

		LDR     R0, =487
        BL      LED_SET_PERIOD

		;; Turn motors on and go forward (same as VALSE start)
		BL  MOTEUR_GAUCHE_ON
		BL 	MOTEUR_DROIT_ON
        BL  MOTEUR_GAUCHE_AVANT
        BL  MOTEUR_DROIT_AVANT

        LDR R1, =DUREE*10
disco_test_w1
        SUBS R1, #1
        BNE  disco_test_w1

		;; Stop motors
		BL MOTEUR_GAUCHE_OFF
		BL MOTEUR_DROIT_OFF

		POP {LR}
        BX  LR

		END