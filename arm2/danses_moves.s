		AREA    |.text|, CODE, READONLY
			
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
			
DUREE           EQU 0x001FFFFF
	
VITESSE_VALSE   EQU     0x155           ; Slow
VITESSE_DISCO   EQU     0x005           ; Fast

		EXPORT  VALSE

VALSE
		
		PUSH {LR}
		
		LDR     R0, =VITESSE_VALSE
        BL      MOTEUR_SET_VITESSE
		
		LDR     R0, #1000
        BL      LED_SET_PERIOD
        
        BL  MOTEUR_GAUCHE_ON
        BL  MOTEUR_GAUCHE_ARRIERE
        BL  MOTEUR_DROIT_AVANT

        LDR R1, =DUREE*21
wait_1
        SUBS R1, #1
        BNE  wait_1
		
        
        BL  MOTEUR_GAUCHE_AVANT
        BL  MOTEUR_DROIT_AVANT

        LDR R1, =DUREE*10
wait_2
        SUBS R1, #1
        BNE  wait_2



        BL  MOTEUR_DROIT_AVANT
        BL  MOTEUR_GAUCHE_OFF

        LDR R1, =DUREE*10
wait_3
        SUBS R1, #1
        BNE  wait_3

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
wait10
        SUBS R1, #1
        BNE  wait10
   
   
   
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE
	
        LDR R1, =DUREE*1
wait101
        SUBS R1, #1
        BNE  wait101
   
		
		BL  MOTEUR_DROIT_OFF
		BL  MOTEUR_GAUCHE_AVANT
		BL  MOTEUR_DROIT_ARRIERE

        LDR R1, =DUREE*3
wait11
		SUBS R1, #1
		BNE  wait11
		BL  MOTEUR_DROIT_ON
		
		
		
		POP {LR}
        BX  LR
		
		
;CIRCLE_RIGHT
		EXPORT CIRCLE_RIGHT
CIRCLE_RIGHT		
		
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_AVANT
	
        LDR R1, =DUREE*6
wait10222
        SUBS R1, #1
        BNE  wait10222
		
		POP {LR}
        BX  LR
		
		
;CIRCLE_LEFT
		EXPORT CIRCLE_LEFT
CIRCLE_LEFT
		
		PUSH {LR}
		
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
        LDR R1, =DUREE*6
wait19
        SUBS R1, #1
        BNE  wait19
		
		POP {LR}
        BX  LR




;DEMICIRCLE_RIGHT
		EXPORT CIRCLE_RIGHT
DEMICIRCLE_RIGHT		
		
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_AVANT
	
        LDR R1, =DUREE*3
wait220
        SUBS R1, #1
        BNE  wait220
		
		POP {LR}
        BX  LR
		
		
;DEMICIRCLE_LEFT
		EXPORT CIRCLE_LEFT
DEMICIRCLE_LEFT
		
		PUSH {LR}
		
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
        LDR R1, =DUREE*3
wait192
        SUBS R1, #1
        BNE  wait192
		
		POP {LR}
        BX  LR
		



;WALK
		EXPORT WALK
WALK
		PUSH {LR}


		 BL  MOTEUR_GAUCHE_AVANT
		 BL  MOTEUR_DROIT_AVANT

         LDR R1, =DUREE*1
wait33
         SUBS R1, #1
         BNE  wait33
		 
		 
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_ARRIERE
	
		LDR R1, =(DUREE*3)/2
wait119
        SUBS R1, #1
        BNE  wait119	


		 BL  MOTEUR_GAUCHE_AVANT
		 BL  MOTEUR_DROIT_AVANT

         LDR R1, =DUREE*1
wait332
         SUBS R1, #1
         BNE  wait332
		 
		 
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
		LDR R1, =(DUREE*3)/2
wait1129
        SUBS R1, #1
        BNE  wait1129	
		
		
		
		
		
		POP {LR}
        BX  LR
		
		
		
		
		
;WALK ON BACK
		EXPORT WALK
WALK_BACK
		PUSH {LR}


		 BL  MOTEUR_GAUCHE_ARRIERE
		 BL  MOTEUR_DROIT_ARRIERE

         LDR R1, =DUREE*1
wait44
         SUBS R1, #1
         BNE  wait44
		 
		 
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT
	
		LDR R1, =(DUREE*3)/2
wait88
        SUBS R1, #1
        BNE  wait88	


		 BL  MOTEUR_GAUCHE_ARRIERE
		 BL  MOTEUR_DROIT_ARRIERE

         LDR R1, =DUREE*1
wait66
         SUBS R1, #1
         BNE  wait66
		 
		 
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_ARRIERE
	
		LDR R1, =(DUREE*3)/2
wait78
        SUBS R1, #1
        BNE  wait78	
		
		
		POP {LR}
        BX  LR





		EXPORT FRONTBACK
FRONTBACK
		PUSH {LR}
		
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_AVANT
	
		LDR R1, =DUREE*1
wait758
        SUBS R1, #1
        BNE  wait758	
		
		
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_ARRIERE
	
		LDR R1, =DUREE*1
wait748
        SUBS R1, #1
        BNE  wait748	



		POP {LR}
        BX  LR


		EXPORT FRONT
FRONT
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE
	
        LDR R1, =DUREE*4
wait10232
        SUBS R1, #1
        BNE  wait10232
		
		
		POP {LR}
        BX  LR

		EXPORT FRONTSHORT
FRONTSHORT
		PUSH {LR}
		
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE
	
        LDR R1, =DUREE*2
wait102323
        SUBS R1, #1
        BNE  wait102323
		
		
		POP {LR}
        BX  LR

		
		EXPORT ITALODISCO
ITALODISCO

		PUSH {LR}
		
		LDR     R0, =VITESSE_DISCO
        BL      MOTEUR_SET_VITESSE
		
		LDR     R0, #1000
        BL      LED_SET_PERIOD

		
		BL FRONTBACK
		BL FRONTBACK
		BL FRONTBACK
		BL FRONTBACK
		
		
		BL WALK
		BL WALK
		
		
		BL STAR
		BL STAR
		BL STAR
		BL STAR
		BL MOTEUR_DROIT_ON
		
	
		BL  FRONT
		
		
		BL STAR
		BL STAR
		BL STAR
		BL STAR
		BL FRONTBACK
		
		BL WALK_BACK
		BL WALK 
		BL FRONTBACK
		BL FRONTSHORT
		
		
		BL CIRCLE_RIGHT
		BL CIRCLE_RIGHT
		BL DEMICIRCLE_RIGHT
		
		
		BL FRONTBACK
		BL FRONTBACK
		BL FRONTBACK
		
		BL WALK
		BL WALK 
		BL WALK	
		BL WALK_BACK
		
		BL DEMICIRCLE_LEFT
		BL DEMICIRCLE_RIGHT
		BL FRONTBACK
		BL DEMICIRCLE_LEFT
		BL DEMICIRCLE_RIGHT
		BL FRONTBACK
		
		
		BL MOTEUR_DROIT_OFF
		BL FRONTBACK
		BL FRONTBACK
		
		
		POP {LR}
        BX  LR
		
		END