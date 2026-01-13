; prog principal du robot danseur
; SW1/SW2 pour danses, bumpers pour controle

        AREA    |.text|, CODE, READONLY
        ENTRY
        EXPORT  __main

        ; imports hardware
        IMPORT  MOTEUR_INIT
        IMPORT  LED_INIT
        IMPORT  LED_CYCLE_SPEED
        IMPORT  LED_SET_MODE
        IMPORT  LED_SET_PERIOD
        IMPORT  BUMPER_INIT
        IMPORT  BUMPER_LEFT_PRESSED
        IMPORT  BUMPER_RIGHT_PRESSED
        IMPORT  BUTTON_INIT
        IMPORT  BUTTON1_PRESSED
        IMPORT  BUTTON2_PRESSED

        ; danses en dur dans le code
        IMPORT  ITALODISCO
        IMPORT  VALSE

        ; fonctions carte SD
        IMPORT  SD_Init
        IMPORT  SD_ReadSector
        IMPORT  SD_IndexDances
        IMPORT  SD_WriteEmbeddedDances

; modes des LEDs pour savoir l'etat du robot
MODE_ALTERNATE  EQU     0               ; les 2 LEDs alternent
MODE_TOGETHER   EQU     1               ; les 2 LEDs ensemble
MODE_SD_OK      EQU     2               ; LED droite fixe = carte SD ok
MODE_NO_SD      EQU     3               ; LED droite clignote vite = pas de carte

; variables en RAM
        AREA    |.data|, DATA, READWRITE
SD_AVAILABLE    DCD     0               ; 1 si carte SD initialisee
IDLE_MODE       DCD     3               ; mode LED au repos

;; ============================================
;; Main program
;; ============================================
        AREA    |.text|, CODE, READONLY
__main
        ; on init tout le hardware au demarrage
        BL      MOTEUR_INIT
        BL      LED_INIT
        BL      BUMPER_INIT
        BL      BUTTON_INIT

        ; LED en mode alterné rapide pendant le chargement SD
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE
        MOV     R0, #100
        BL      LED_SET_PERIOD

        ; on tente d'init la carte SD, y'a un timeout donc ca bloque pas
        BL      SD_Init
        CMP     R0, #1
        BNE     sd_not_available

        ; carte SD ok, on ecrit les danses embedded dessus
        BL      SD_WriteEmbeddedDances

        ; on indexe les danses sur la carte
        BL      SD_IndexDances
        LDR     R0, =SD_AVAILABLE
        MOV     R1, #1
        STR     R1, [R0]

        ; on remet la periode LED normale
        LDR     R0, =488
        BL      LED_SET_PERIOD

        ; mode idle avec SD: LED droite fixe pour montrer que ca marche
        LDR     R0, =IDLE_MODE
        MOV     R1, #MODE_SD_OK
        STR     R1, [R0]
        MOV     R0, #MODE_SD_OK
        BL      LED_SET_MODE
        B       wait_input

sd_not_available
        ; pas de carte SD, on met le flag a 0
        LDR     R0, =SD_AVAILABLE
        MOV     R1, #0
        STR     R1, [R0]

        ; on remet la periode LED normale
        LDR     R0, =488
        BL      LED_SET_PERIOD

        ; mode idle sans SD: LED droite clignote vite pour dire y'a un probleme
        LDR     R0, =IDLE_MODE
        MOV     R1, #MODE_NO_SD
        STR     R1, [R0]
        MOV     R0, #MODE_NO_SD
        BL      LED_SET_MODE

; boucle principale, on poll les boutons et bumpers en continu
wait_input
        LDR     R1, =0x1000
poll_delay
        SUBS    R1, #1
        BNE     poll_delay

        ; bumper gauche = changer la vitesse des LEDs
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     do_cycle_speed

        ; bumper droit = jouer une danse de la carte SD
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     do_sd_dance

        ; SW1 = ITALODISCO en dur dans le code
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     do_disco

        ; SW2 = VALSE en dur dans le code
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     do_valse

        B       wait_input

; bumper gauche: on cycle la vitesse des LEDs
do_cycle_speed
        BL      LED_CYCLE_SPEED

        ; on attend que l'utilisateur relache le bumper
wait_bumper_left_release
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_left_release

        BL      debounce_long
        B       wait_input

; bumper droit: on joue une danse de la carte SD
; faut maintenir bumper droit puis appuyer SW1 ou SW2 pour choisir
do_sd_dance
        MOV     R5, #0              ; par defaut danse 0

        ; on attend soit un bouton soit que le bumper soit relache
wait_for_button_or_release
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     got_dance_0

        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     got_dance_1

        ; check si le bumper est encore appuyé
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     wait_for_button_or_release

        ; relache sans bouton = on fait rien
        BL      debounce_long
        B       wait_input

got_dance_0
        MOV     R5, #0
        B       wait_bumper_release_then_play

got_dance_1
        MOV     R5, #1

wait_bumper_release_then_play
        ; on attend que le bumper soit relache avant de jouer
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_release_then_play

play_selected_dance
        BL      debounce_long

        ; check si la carte SD est dispo
        LDR     R0, =SD_AVAILABLE
        LDR     R0, [R0]
        CMP     R0, #1
        BNE     wait_input          ; pas de carte, on ignore

        ; LEDs en mode alterné pour la danse
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        ; on joue la danse selectionnee depuis la carte SD
        MOV     R0, R5              ; R5 contient l'index de la danse
        BL      SD_ReadSector

        ; on revient en mode idle
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

; SW1 lance la VALSE (fonction en dur dans le code)
do_valse
wait_btn1_release
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     wait_btn1_release

        BL      debounce

        ; LEDs en mode alterné pour la danse
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        BL      VALSE

        ; on revient en mode idle
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

; SW2 lance ITALODISCO (fonction en dur dans le code)
do_disco
wait_btn2_release
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     wait_btn2_release

        BL      debounce

        ; LEDs en mode alterné pour la danse
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        BL      ITALODISCO

        ; on revient en mode idle
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

; petits delais pour eviter les rebonds des boutons
debounce
        PUSH    {R1, LR}
        LDR     R1, =0x50000
deb_loop
        SUBS    R1, #1
        BNE     deb_loop
        POP     {R1, LR}
        BX      LR

; delai plus long pour les bumpers
debounce_long
        PUSH    {R1, LR}
        LDR     R1, =0x200000
deb_long_loop
        SUBS    R1, #1
        BNE     deb_long_loop
        POP     {R1, LR}
        BX      LR

        END
