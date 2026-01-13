; button.s - gestion des boutons SW1 et SW2 sur le robot
; SW1 = PD6, SW2 = PD7
; active LOW (appuye = 0)

        AREA    |.text|, CODE, READONLY, ALIGN=2

SYSCTL_RCGC2    EQU     0x400FE108
GPIO_PORTD      EQU     0x40007000
SW1_PIN         EQU     0x40            ; PD6
SW2_PIN         EQU     0x80            ; PD7
SW_BOTH         EQU     0xC0

        EXPORT  BUTTON_INIT
        EXPORT  BUTTON1_PRESSED
        EXPORT  BUTTON2_PRESSED

; BUTTON_INIT: config PD6 et PD7 en entree avec pull-up
BUTTON_INIT
        PUSH    {R0-R1, LR}

        ; active le clock pour le port D
        LDR     R1, =SYSCTL_RCGC2
        LDR     R0, [R1]
        ORR     R0, R0, #0x08
        STR     R0, [R1]
        NOP
        NOP
        NOP

        LDR     R1, =GPIO_PORTD

        ; desactive les fonctions alternatives (GPIO normal)
        LDR     R0, [R1, #0x420]
        BIC     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x420]

        ; PD6 et PD7 en entree
        LDR     R0, [R1, #0x400]
        BIC     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x400]

        ; active les pull-ups
        LDR     R0, [R1, #0x510]
        ORR     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x510]

        ; active en mode digital
        LDR     R0, [R1, #0x51C]
        ORR     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x51C]

        POP     {R0-R1, LR}
        BX      LR

; BUTTON1_PRESSED: retourne 1 si SW1 est appuye
BUTTON1_PRESSED
        LDR     R0, =GPIO_PORTD
        LDR     R0, [R0, #0x3FC]
        TST     R0, #SW1_PIN
        BEQ     btn1_yes                ; 0 = appuye (active low)
        MOV     R0, #0
        BX      LR
btn1_yes
        MOV     R0, #1
        BX      LR

; BUTTON2_PRESSED: retourne 1 si SW2 est appuye
BUTTON2_PRESSED
        LDR     R0, =GPIO_PORTD
        LDR     R0, [R0, #0x3FC]
        TST     R0, #SW2_PIN
        BEQ     btn2_yes                ; 0 = appuye (active low)
        MOV     R0, #0
        BX      LR
btn2_yes
        MOV     R0, #1
        BX      LR

        END