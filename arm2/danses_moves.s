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
        IMPORT  TICK_MS                 ; Millisecond counter from led.s
			
DUREE           EQU 0x001FFFFF
	
VITESSE_VALSE   EQU     0x155           ; Slow
VITESSE_DISCO   EQU     0x005           ; Fast
DANCE_DURATION  EQU     90000           ; 90 seconds in milliseconds (all dances)

		EXPORT  VALSE

VALSE
		PUSH    {R4-R7, LR}

		;; R4 = duration in milliseconds
		LDR     R4, =DANCE_DURATION

		;; R7 = pointer to TICK_MS, R5 = start time (R7 safe from motor.s)
		LDR     R7, =TICK_MS
		LDR     R5, [R7]            ; R5 = start tick

		;; Set speed and LED
		LDR     R0, =VITESSE_VALSE
		BL      MOTEUR_SET_VITESSE
		LDR     R0, =1000
		BL      LED_SET_PERIOD

valse_start
		BL      MOTEUR_GAUCHE_ON
		BL      MOTEUR_DROIT_ON
		BL      MOTEUR_GAUCHE_ARRIERE
		BL      MOTEUR_DROIT_AVANT

		LDR     R1, =DUREE*21
valse_w1
		SUBS    R1, #1
		BNE     valse_w1

		BL      MOTEUR_GAUCHE_AVANT
		BL      MOTEUR_DROIT_AVANT

		LDR     R1, =DUREE*10
valse_w2
		SUBS    R1, #1
		BNE     valse_w2

		BL      MOTEUR_DROIT_AVANT
		BL      MOTEUR_GAUCHE_OFF

		LDR     R1, =DUREE*10
valse_w3
		SUBS    R1, #1
		BNE     valse_w3

		;; Check if duration reached
		LDR     R0, [R7]            ; Current tick
		SUB     R0, R0, R5          ; Elapsed = current - start
		CMP     R0, R4              ; Compare with duration (ms)
		BLT     valse_start         ; Continue if not reached

		;; Stop motors and return
		BL      MOTEUR_GAUCHE_OFF
		BL      MOTEUR_DROIT_OFF

		POP     {R4-R7, LR}
		BX      LR
		
		
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

		
;; ============================================
;; DEBUG_PAUSE - Stop motors, fast blink 3 sec, restore
;; R8 = saved PWMENABLE, R9 = saved right dir, R10 = saved left dir
;; ============================================
DBG_PWMENABLE   EQU     0x40028008      ; PWM enable register
DBG_DIR_RIGHT   EQU     0x40007008      ; GPIODATA_D + (GPIO_1<<2)
DBG_DIR_LEFT    EQU     0x40027008      ; GPIODATA_H + (GPIO_1<<2)

DEBUG_PAUSE
		PUSH    {R8-R10, LR}

		;; Save motor on/off state (PWMENABLE)
		LDR     R0, =DBG_PWMENABLE
		LDR     R8, [R0]

		;; Save right motor direction
		LDR     R0, =DBG_DIR_RIGHT
		LDR     R9, [R0]

		;; Save left motor direction
		LDR     R0, =DBG_DIR_LEFT
		LDR     R10, [R0]

		;; Stop both motors
		BL      MOTEUR_GAUCHE_OFF
		BL      MOTEUR_DROIT_OFF

		;; Set LED to fast blink (50ms)
		MOV     R0, #50
		BL      LED_SET_PERIOD

		;; Wait 3 seconds
		LDR     R1, =0x900000
dbg_wait
		SUBS    R1, #1
		BNE     dbg_wait

		;; Restore normal LED period (487ms)
		LDR     R0, =487
		BL      LED_SET_PERIOD

		;; Restore right motor direction
		LDR     R0, =DBG_DIR_RIGHT
		STR     R9, [R0]

		;; Restore left motor direction
		LDR     R0, =DBG_DIR_LEFT
		STR     R10, [R0]

		;; Restore motor on/off state
		LDR     R0, =DBG_PWMENABLE
		STR     R8, [R0]

		POP     {R8-R10, LR}
		BX      LR

		EXPORT ITALODISCO
ITALODISCO
		PUSH    {R4-R7, LR}

		;; R4 = duration in milliseconds
		LDR     R4, =DANCE_DURATION

		;; R7 = pointer to TICK_MS, R5 = start time (R7 safe from motor.s)
		LDR     R7, =TICK_MS
		LDR     R5, [R7]            ; R5 = start tick

		LDR     R0, =VITESSE_DISCO
		BL      MOTEUR_SET_VITESSE

		LDR     R0, =487
		BL      LED_SET_PERIOD

disco_start
		;; Turn motors on and go forward
		BL      MOTEUR_GAUCHE_ON
		BL      MOTEUR_DROIT_ON
		BL      MOTEUR_GAUCHE_AVANT
		BL      MOTEUR_DROIT_AVANT

		BL      FRONTBACK
	
		BL      FRONTBACK
	
		BL      FRONTBACK
	
		BL      FRONTBACK
	

		BL      WALK
	
		BL      WALK
	


		BL      STAR
	
		BL      STAR
	
		BL      STAR
	
		BL      STAR
	
		BL      MOTEUR_DROIT_ON


		BL      FRONT
	


		BL      STAR
	
		BL      STAR
	
		BL      STAR
	
		BL      STAR
	
		BL      FRONTBACK
	

		BL      WALK_BACK
	
		BL      WALK
	
		BL      FRONTBACK
	
		BL      FRONTSHORT
	


		BL      CIRCLE_RIGHT
	
		BL      CIRCLE_RIGHT
	
		BL      DEMICIRCLE_RIGHT
	


		BL      FRONTBACK
	
		BL      FRONTBACK
	
		BL      FRONTBACK
	

		BL      WALK
	
		BL      WALK
	
		BL      WALK
	
		BL      WALK_BACK
	

		BL      DEMICIRCLE_LEFT
	
		BL      DEMICIRCLE_RIGHT
	
		BL      FRONTBACK
	
		BL      DEMICIRCLE_LEFT
	
		BL      DEMICIRCLE_RIGHT
	
		BL      FRONTBACK
	


		BL      MOTEUR_DROIT_OFF
		BL      FRONTBACK
	
		BL      FRONTBACK
	

		;; Check if duration reached
		LDR     R0, [R7]            ; Current tick
		SUB     R0, R0, R5          ; Elapsed = current - start
		CMP     R0, R4              ; Compare with duration (ms)
		BLT     disco_start         ; Continue if not reached

		;; Stop motors and return
		BL      MOTEUR_GAUCHE_OFF
		BL      MOTEUR_DROIT_OFF

		POP     {R4-R7, LR}
		BX      LR

		END