		AREA |.text|, CODE, READONLY, ALIGN=2
        EXPORT SWITCH_INIT
        EXPORT READ_SWITCH

SYSCTL_RCGC2_R     EQU 0x400FE108
GPIO_PORTD_BASE    EQU 0x40007000
BROCHE6            EQU 0x40

SWITCH_INIT
        LDR     R1, =SYSCTL_RCGC2_R
        LDR     R0, [R1]
        ORR     R0, R0, #0x08     
        STR     R0, [R1]
		NOP
        NOP
        NOP
        LDR     R1, =GPIO_PORTD_BASE
        MOV     R0, #0xC0           
        STR     R0, [R1, #0x510]    
		NOP
        NOP
        NOP
        STR     R0, [R1, #0x51C]    
		NOP
        NOP
        NOP
        BX      LR

READ_SWITCH
        LDR     R1, =GPIO_PORTD_BASE + (BROCHE6 << 2)
        LDR     R5, [R1]
        CMP     R5, #0x00           
        BX      LR
        END