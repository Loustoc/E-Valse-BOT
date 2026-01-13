; led.s - gestion des LEDs avec SysTick
;
; modes:
;   0 = alternate: les 2 LEDs alternent (pour danser)
;   1 = together: les 2 LEDs ensemble (pas utilise)
;   2 = SD_OK: LED droite fixe, gauche clignote (carte SD ok)
;   3 = NO_SD: LED droite clignote 2x plus vite (pas de carte)
;
; multiplier: 1 a 5 pour accelerer le clignotement

        AREA    |.text|, CODE, READONLY

; registres SysTick (timer systeme)
NVIC_ST_CTRL    EQU     0xE000E010
NVIC_ST_RELOAD  EQU     0xE000E014
NVIC_ST_CURRENT EQU     0xE000E018

; GPIO Port F (les LEDs sont sur PF4 et PF5)
SYSCTL_RCGC2    EQU     0x400FE108
GPIO_PORTF_BASE EQU     0x40025000
GPIO_O_DIR      EQU     0x400
GPIO_O_DEN      EQU     0x51C
GPIO_O_DR2R     EQU     0x500

LED1            EQU     0x10            ; PF4 = LED gauche
LED2            EQU     0x20            ; PF5 = LED droite
LED_BOTH        EQU     0x30

SYSTICK_RELOAD_1MS EQU  15999           ; pour tick de 1ms a 16MHz
DEFAULT_PERIOD  EQU     488             ; periode par defaut

MODE_ALTERNATE  EQU     0
MODE_TOGETHER   EQU     1
MODE_SD_OK      EQU     2
MODE_NO_SD      EQU     3

; variables en RAM
        AREA    |.data|, DATA, READWRITE

TICK_MS         DCD     0               ; compteur de millisecondes
LED1_STATE      DCD     0               ; etat LED gauche
LED2_STATE      DCD     0               ; etat LED droite
LED1_LAST_TOG   DCD     0               ; dernier toggle LED gauche
LED2_LAST_TOG   DCD     0               ; dernier toggle LED droite
LED_PERIOD      DCD     488             ; periode de base en ms
LED_MULTIPLIER  DCD     1               ; multiplicateur vitesse (1-5)
LED_MODE        DCD     2               ; mode par defaut

        AREA    |.text|, CODE, READONLY

        EXPORT  SysTick_Handler
        EXPORT  LED_INIT
        EXPORT  LED_SET_PERIOD
        EXPORT  LED_CYCLE_SPEED
        EXPORT  LED_SET_MODE
        EXPORT  TICK_MS

; LED_INIT: initialise les LEDs et le timer SysTick
LED_INIT
        PUSH    {R0-R2, LR}

        ; active le clock pour le port F
        LDR     R1, =SYSCTL_RCGC2
        LDR     R0, [R1]
        ORR     R0, R0, #0x20
        STR     R0, [R1]
        NOP
        NOP
        NOP
        NOP

        ; PF4 et PF5 en sortie
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DIR
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]

        ; active les pins en mode digital
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DEN
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]

        ; force de courant 2mA
        LDR     R1, =GPIO_PORTF_BASE + GPIO_O_DR2R
        LDR     R0, [R1]
        ORR     R0, R0, #LED_BOTH
        STR     R0, [R1]

        ; LEDs eteintes au depart
        LDR     R1, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        MOV     R0, #0
        STR     R0, [R1]

        ; init des variables
        LDR     R1, =TICK_MS
        MOV     R0, #0
        STR     R0, [R1]

        LDR     R1, =LED1_STATE
        STR     R0, [R1]

        LDR     R1, =LED2_STATE
        STR     R0, [R1]

        LDR     R1, =LED1_LAST_TOG
        STR     R0, [R1]

        LDR     R1, =LED2_LAST_TOG
        STR     R0, [R1]

        LDR     R1, =LED_PERIOD
        LDR     R0, =DEFAULT_PERIOD
        STR     R0, [R1]

        LDR     R1, =LED_MULTIPLIER
        MOV     R0, #1
        STR     R0, [R1]

        LDR     R1, =LED_MODE
        MOV     R0, #MODE_SD_OK
        STR     R0, [R1]

        ; configure SysTick pour interruption toutes les 1ms
        LDR     R1, =NVIC_ST_RELOAD
        LDR     R0, =SYSTICK_RELOAD_1MS
        STR     R0, [R1]

        LDR     R1, =NVIC_ST_CURRENT
        MOV     R0, #0
        STR     R0, [R1]

        ; active SysTick avec interruption
        LDR     R1, =NVIC_ST_CTRL
        MOV     R0, #0x07
        STR     R0, [R1]

        POP     {R0-R2, PC}

; SysTick_Handler: interruption appelee toutes les 1ms
; gere le clignotement des LEDs selon le mode
SysTick_Handler
        PUSH    {R0-R7, LR}

        ; incremente le compteur de ms
        LDR     R0, =TICK_MS
        LDR     R1, [R0]
        ADD     R1, R1, #1
        STR     R1, [R0]
        MOV     R7, R1                  ; R7 = tick actuel

        ; recupere le mode et les parametres
        LDR     R0, =LED_MODE
        LDR     R6, [R0]
        LDR     R0, =LED_PERIOD
        LDR     R3, [R0]
        LDR     R0, =LED_MULTIPLIER
        LDR     R4, [R0]

        ; saute au bon handler selon le mode
        CMP     R6, #MODE_ALTERNATE
        BEQ     handle_alternate
        CMP     R6, #MODE_TOGETHER
        BEQ     handle_together
        CMP     R6, #MODE_SD_OK
        BEQ     handle_sd_ok
        CMP     R6, #MODE_NO_SD
        BEQ     handle_no_sd
        B       systick_done

; mode alternate: les LEDs alternent
handle_alternate
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     systick_done

        STR     R7, [R0]

        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     alt_state0
        MOV     R0, #LED1
        B       led_write
alt_state0
        MOV     R0, #LED2
        B       led_write

; mode together: les 2 LEDs ensemble
handle_together
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     systick_done

        STR     R7, [R0]

        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     tog_off
        MOV     R0, #LED_BOTH
        B       led_write
tog_off
        MOV     R0, #0
        B       led_write

; mode SD_OK: LED droite fixe, gauche clignote
handle_sd_ok
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     sd_ok_write

        STR     R7, [R0]

        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

sd_ok_write
        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)
        CMP     R1, #0
        BEQ     sd_ok_left_off
        MOV     R0, #LED_BOTH
        B       led_write
sd_ok_left_off
        MOV     R0, #LED2
        B       led_write

; mode NO_SD: LED droite clignote 2x plus vite que la gauche
handle_no_sd
        ; LED gauche vitesse normale
        LDR     R0, =LED1_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        CMP     R1, R3
        BLT     no_sd_check_right

        STR     R7, [R0]
        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

no_sd_check_right
        ; LED droite 2x plus vite
        LDR     R0, =LED2_LAST_TOG
        LDR     R2, [R0]
        SUB     R1, R7, R2
        MUL     R1, R1, R4
        LSL     R1, R1, #1              ; x2 pour aller plus vite
        CMP     R1, R3
        BLT     no_sd_write

        STR     R7, [R0]
        LDR     R0, =LED2_STATE
        LDR     R1, [R0]
        EOR     R1, R1, #1
        STR     R1, [R0]

no_sd_write
        ; combine les 2 etats
        LDR     R0, =LED1_STATE
        LDR     R1, [R0]
        LDR     R0, =LED2_STATE
        LDR     R5, [R0]

        MOV     R0, #0
        CMP     R1, #1
        ORREQ   R0, R0, #LED1
        CMP     R5, #1
        ORREQ   R0, R0, #LED2

        LDR     R2, =GPIO_PORTF_BASE + (LED_BOTH << 2)

led_write
        STR     R0, [R2]

systick_done
        POP     {R0-R7, PC}

; LED_SET_PERIOD: change la periode de base (en ms)
LED_SET_PERIOD
        LDR     R1, =LED_PERIOD
        STR     R0, [R1]
        BX      LR

; LED_CYCLE_SPEED: cycle le multiplicateur 1->2->3->4->5->1
; bumper gauche pour accelerer les LEDs
LED_CYCLE_SPEED
        PUSH    {R1-R2, LR}

        LDR     R2, =LED_MULTIPLIER
        LDR     R1, [R2]

        ADD     R1, R1, #1
        CMP     R1, #6
        BLT     cycle_store
        MOV     R1, #1

cycle_store
        STR     R1, [R2]
        MOV     R0, R1

        POP     {R1-R2, LR}
        BX      LR

; LED_SET_MODE: change le mode des LEDs (0-3)
LED_SET_MODE
        LDR     R1, =LED_MODE
        STR     R0, [R1]
        BX      LR

        END
