; fichier avec toutes les fonctions de danse
; chaque danse dure 90 secondes max grace au timer TICK_MS

		AREA    |.text|, CODE, READONLY

		; imports des fonctions moteur
		IMPORT	MOTEUR_DROIT_ON
		IMPORT  MOTEUR_DROIT_OFF
		IMPORT  MOTEUR_DROIT_AVANT
		IMPORT  MOTEUR_DROIT_ARRIERE
		IMPORT  MOTEUR_DROIT_INVERSE

		IMPORT	MOTEUR_GAUCHE_ON
		IMPORT  MOTEUR_GAUCHE_OFF
		IMPORT  MOTEUR_GAUCHE_AVANT
		IMPORT  MOTEUR_GAUCHE_ARRIERE
		IMPORT  MOTEUR_GAUCHE_INVERSE

		IMPORT  MOTEUR_SET_VITESSE

		; pour les LEDs et le timer
        IMPORT  LED_INIT
        IMPORT  LED_SET_PERIOD
        IMPORT  TICK_MS                 ; compteur de millisecondes

DUREE           EQU 0x001FFFFF          ; duree de base pour les boucles d'attente

VITESSE_VALSE   EQU     0x155           ; vitesse lente pour la valse
VITESSE_DISCO   EQU     0x005           ; vitesse rapide pour l'italodisco
DANCE_DURATION  EQU     90000           ; 90 secondes en ms pour toutes les danses

		EXPORT  VALSE

; VALSE: danse lente qui tourne en rond
; utilise R7 pour TICK_MS car motor.s clobber R6
VALSE
		PUSH    {R4-R7, LR}

		; R4 = duree max de la danse en ms
		LDR     R4, =DANCE_DURATION

		; R7 pointe vers TICK_MS, R5 = temps de depart
		LDR     R7, =TICK_MS
		LDR     R5, [R7]

		; on met la vitesse lente et LED qui clignote lentement
		LDR     R0, =VITESSE_VALSE
		BL      MOTEUR_SET_VITESSE
		LDR     R0, =1000
		BL      LED_SET_PERIOD

valse_start
		; rotation: gauche arriere + droit avant
		BL      MOTEUR_GAUCHE_ON
		BL      MOTEUR_DROIT_ON
		BL      MOTEUR_GAUCHE_ARRIERE
		BL      MOTEUR_DROIT_AVANT

		LDR     R1, =DUREE*21
valse_w1
		SUBS    R1, #1
		BNE     valse_w1

		; avancer tout droit
		BL      MOTEUR_GAUCHE_AVANT
		BL      MOTEUR_DROIT_AVANT

		LDR     R1, =DUREE*10
valse_w2
		SUBS    R1, #1
		BNE     valse_w2

		; tourner a gauche (moteur gauche off)
		BL      MOTEUR_DROIT_AVANT
		BL      MOTEUR_GAUCHE_OFF

		LDR     R1, =DUREE*10
valse_w3
		SUBS    R1, #1
		BNE     valse_w3

		; check si on a atteint 90 secondes
		LDR     R0, [R7]            ; tick actuel
		SUB     R0, R0, R5          ; temps ecoule = actuel - depart
		CMP     R0, R4
		BLT     valse_start         ; si pas fini on recommence

		; on arrete les moteurs et on retourne
		BL      MOTEUR_GAUCHE_OFF
		BL      MOTEUR_DROIT_OFF

		POP     {R4-R7, LR}
		BX      LR
		
		
; STAR: figure en etoile, avance recule puis tourne
		EXPORT STAR
STAR
		PUSH {LR}

		; avancer
		BL  MOTEUR_DROIT_ON
		BL  MOTEUR_GAUCHE_AVANT
		BL  MOTEUR_DROIT_AVANT

        LDR R1, =DUREE*1
star_w1
        SUBS R1, #1
        BNE  star_w1

		; reculer
		BL  MOTEUR_GAUCHE_ARRIERE
		BL  MOTEUR_DROIT_ARRIERE

        LDR R1, =DUREE*1
star_w2
        SUBS R1, #1
        BNE  star_w2

		; tourner (moteur droit off)
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
		
		
; CIRCLE_RIGHT: tourne sur place vers la droite
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


; CIRCLE_LEFT: tourne sur place vers la gauche
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


; DEMICIRCLE_RIGHT: demi tour vers la droite
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


; DEMICIRCLE_LEFT: demi tour vers la gauche
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
		



; WALK: marche en zigzag (avance puis corrige a droite puis a gauche)
		EXPORT WALK
WALK
		PUSH {LR}

		; avancer
		 BL  MOTEUR_GAUCHE_AVANT
		 BL  MOTEUR_DROIT_AVANT

         LDR R1, =DUREE*1
walk_w1
         SUBS R1, #1
         BNE  walk_w1

		; correction a droite
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_ARRIERE

		LDR R1, =(DUREE*3)/2
walk_w2
        SUBS R1, #1
        BNE  walk_w2

		; avancer
		 BL  MOTEUR_GAUCHE_AVANT
		 BL  MOTEUR_DROIT_AVANT

         LDR R1, =DUREE*1
walk_w3
         SUBS R1, #1
         BNE  walk_w3

		; correction a gauche
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT

		LDR R1, =(DUREE*3)/2
walk_w4
        SUBS R1, #1
        BNE  walk_w4

		POP {LR}
        BX  LR
		
		
		
		
		
; WALK_BACK: marche arriere en zigzag
		EXPORT WALK_BACK
WALK_BACK
		PUSH {LR}

		; reculer
		 BL  MOTEUR_GAUCHE_ARRIERE
		 BL  MOTEUR_DROIT_ARRIERE

         LDR R1, =DUREE*1
wb_w1
         SUBS R1, #1
         BNE  wb_w1

		; correction
		BL  MOTEUR_DROIT_ARRIERE
		BL  MOTEUR_GAUCHE_AVANT

		LDR R1, =(DUREE*3)/2
wb_w2
        SUBS R1, #1
        BNE  wb_w2

		; reculer
		 BL  MOTEUR_GAUCHE_ARRIERE
		 BL  MOTEUR_DROIT_ARRIERE

         LDR R1, =DUREE*1
wb_w3
         SUBS R1, #1
         BNE  wb_w3

		; correction
		BL  MOTEUR_DROIT_AVANT
		BL  MOTEUR_GAUCHE_ARRIERE

		LDR R1, =(DUREE*3)/2
wb_w4
        SUBS R1, #1
        BNE  wb_w4

		POP {LR}
        BX  LR





; FRONTBACK: avance puis recule (mouvement de va et vient)
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


; FRONT: avance tout droit pendant un moment
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

; FRONTSHORT: avance tout droit mais moins longtemps
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

		
; DEBUG_PAUSE: pour debugger, arrete les moteurs 3 sec avec LED rapide
; sauvegarde et restaure l'etat des moteurs
DBG_PWMENABLE   EQU     0x40028008      ; registre PWM enable
DBG_DIR_RIGHT   EQU     0x40007008      ; direction moteur droit
DBG_DIR_LEFT    EQU     0x40027008      ; direction moteur gauche

DEBUG_PAUSE
		PUSH    {R8-R10, LR}

		; sauvegarde l'etat des moteurs (on/off)
		LDR     R0, =DBG_PWMENABLE
		LDR     R8, [R0]

		; sauvegarde direction moteur droit
		LDR     R0, =DBG_DIR_RIGHT
		LDR     R9, [R0]

		; sauvegarde direction moteur gauche
		LDR     R0, =DBG_DIR_LEFT
		LDR     R10, [R0]

		; arrete les deux moteurs
		BL      MOTEUR_GAUCHE_OFF
		BL      MOTEUR_DROIT_OFF

		; LED clignote vite pour montrer qu'on est en pause
		MOV     R0, #50
		BL      LED_SET_PERIOD

		; on attend 3 secondes
		LDR     R1, =0x900000
dbg_wait
		SUBS    R1, #1
		BNE     dbg_wait

		; remet la LED normale
		LDR     R0, =487
		BL      LED_SET_PERIOD

		; restaure direction moteur droit
		LDR     R0, =DBG_DIR_RIGHT
		STR     R9, [R0]

		; restaure direction moteur gauche
		LDR     R0, =DBG_DIR_LEFT
		STR     R10, [R0]

		; restaure l'etat on/off des moteurs
		LDR     R0, =DBG_PWMENABLE
		STR     R8, [R0]

		POP     {R8-R10, LR}
		BX      LR

; ITALODISCO: danse rapide avec plein de figures enchainees
; meme principe que VALSE pour le timer avec R7
		EXPORT ITALODISCO
ITALODISCO
		PUSH    {R4-R7, LR}

		; R4 = duree max en ms
		LDR     R4, =DANCE_DURATION

		; R7 pointe vers TICK_MS, R5 = temps de depart
		LDR     R7, =TICK_MS
		LDR     R5, [R7]

		; vitesse rapide pour le disco
		LDR     R0, =VITESSE_DISCO
		BL      MOTEUR_SET_VITESSE

		LDR     R0, =487
		BL      LED_SET_PERIOD

disco_start
		; allume les moteurs et en avant
		BL      MOTEUR_GAUCHE_ON
		BL      MOTEUR_DROIT_ON
		BL      MOTEUR_GAUCHE_AVANT
		BL      MOTEUR_DROIT_AVANT

		; sequence de mouvements
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

		; check si on a atteint 90 secondes
		LDR     R0, [R7]
		SUB     R0, R0, R5
		CMP     R0, R4
		BLT     disco_start         ; si pas fini on recommence

		; arrete les moteurs et retourne
		BL      MOTEUR_GAUCHE_OFF
		BL      MOTEUR_DROIT_OFF

		POP     {R4-R7, LR}
		BX      LR

		END