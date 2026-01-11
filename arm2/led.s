		AREA |.text|, CODE, READONLY, ALIGN=2
		ENTRY
		EXPORT __main
		IMPORT SD_Init
		IMPORT SD_ReadSector
		IMPORT SD_IndexDances
		IMPORT DANCE_COUNT
		IMPORT SWITCH_INIT
		IMPORT READ_SWITCH
GPIO_PORTF_BASE EQU 0x40025000
PIN_RIGHT       EQU 0x10
PIN_LEFT        EQU 0x20

		AREA |.text|, CODE, READONLY
__main
        BL      SWITCH_INIT
        
        LDR     R0, =0x400FE108
        LDR     R1, [R0]
        ORR     R1, R1, #0x20      
        STR     R1, [R0]
        NOP
        NOP
        NOP

        LDR     R0, =GPIO_PORTF_BASE
        MOV     R1, #0x30           
        STR     R1, [R0, #0x400]
        STR     R1, [R0, #0x51C]

        BL      SD_Init
        CMP     R0, #1
        BNE     Panic               

        BL      SD_IndexDances
        
        MOV     R11, #0             

BOUCLE_PRINCIPALE
        BL      ALLUME_DROITE       
        
ATTENTE_APPUI
        BL      READ_SWITCH        
        BNE     ATTENTE_APPUI       
        
        LDR     R2, =800000
DELAI_DEB SUBS R2, R2, #1
        BNE     DELAI_DEB
        
ATTENTE_RELACHE
        BL      READ_SWITCH
        BEQ     ATTENTE_RELACHE    

        BL      ALLUME_GAUCHE
        MOV     R0, R11
        BL      SD_ReadSector      
        
        ADD     R11, R11, #1
        B       BOUCLE_PRINCIPALE
Panic   
		LDR     R0, =0x400253FC
		MOV     R1, #0x02          
		STR     R1, [R0]
ALLUME_GAUCHE
		LDR     R0, =GPIO_PORTF_BASE
		MOV     R1, #PIN_LEFT      
		STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
ALLUME_DROITE
		LDR     R0, =GPIO_PORTF_BASE
		MOV     R1, #PIN_RIGHT       
		STR     R1, [R0, #0x3FC]
		NOP
		NOP
		NOP
		BX      LR
STOP    B       STOP
		END