		AREA |.text|, CODE, READONLY, ALIGN=2
        ENTRY
        EXPORT __main
        IMPORT SD_Init
		IMPORT SD_ReadSector

GPIO_PORTF_BASE EQU 0x40025000
PIN_RIGHT       EQU 0x10
PIN_LEFT        EQU 0x20

        AREA |.text|, CODE, READONLY
__main
        ; Horloge Port F
        LDR     R0, =0x400FE108
        LDR     R1, [R0]
        ORR     R1, R1, #0x20
        STR     R1, [R0]
        NOP
        NOP
		NOP
        ; Config PF4/PF5
        LDR     R0, =GPIO_PORTF_BASE
        MOV     R1, #0x30
        STR     R1, [R0, #0x400]
        STR     R1, [R0, #0x51C]
		NOP
		NOP
		NOP
        ; Flash initial (Vérifie que le CPU tourne)
        MOV     R1, #0x30
        STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
        LDR     R2, =1000000
W_FL    SUBS    R2, R2, #1
        BNE     W_FL
        MOV     R1, #0
        STR     R1, [R0, #0x3FC]

		BL      SD_Init
        CMP     R0, #1
		BNE LOOP_FIN
		LDR     R1, =0x20000000     ; Adresse RAM cible
		BL      SD_ReadSector
FIN_PROGRAMME
        MOV     R1, #0
        LDR     R0, =GPIO_PORTF_BASE
        STR     R1, [R0, #0x3FC]    ; Éteint tout en fin de danse
STOP    B       STOP

Panic   LDR     R0, =0x400253FC
        MOV     R1, #0x02           ; LED Rouge
        STR     R1, [R0]
        ;B       Loop
        B LOOP_FIN

ALLUME_GAUCHE
        LDR     R0, =GPIO_PORTF_BASE
        MOV     R1, #PIN_LEFT       ; PIN_LEFT est 0x20
        STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
ALLUME_DROITE
        LDR     R0, =GPIO_PORTF_BASE
        MOV     R1, #PIN_RIGHT       ; PIN_LEFT est 0x20
        STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
LOOP_FIN
        END