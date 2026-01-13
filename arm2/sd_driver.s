		AREA SD_DATA, DATA, READWRITE
DANCE_TABLE  SPACE 80               
DANCE_COUNT  DCD 0                  

        AREA SD_DRIVER, CODE, READONLY, ALIGN=2
        EXPORT SD_Init
        EXPORT SD_ReadSector
        EXPORT SD_IndexDances
		EXPORT DANCE_COUNT
			
		IMPORT R_LED_ON
		IMPORT L_LED_ON
		
        IMPORT STAR
        IMPORT CIRCLE_RIGHT
        IMPORT CIRCLE_LEFT
        IMPORT DEMICIRCLE_RIGHT
        IMPORT DEMICIRCLE_LEFT
        IMPORT WALK
        IMPORT WALK_BACK
        IMPORT FRONTBACK
		IMPORT MOTEUR_INIT
		IMPORT MOTEUR_DROIT_ON
		IMPORT MOTEUR_DROIT_OFF
		IMPORT MOTEUR_DROIT_AVANT
		IMPORT MOTEUR_DROIT_ARRIERE
		IMPORT MOTEUR_GAUCHE_ON
		IMPORT MOTEUR_GAUCHE_OFF
		IMPORT MOTEUR_GAUCHE_AVANT
		IMPORT MOTEUR_GAUCHE_ARRIERE
			
		IMPORT L_LED_ON


SSI0_BASE         EQU 0x40008000
GPIO_PORTA_BASE   EQU 0x40004000
	
GPIO_PORTF_DATA   EQU 0x400253FC
PA3_CS_ADDR       EQU 0x40004020
RAM_BUF           EQU 0x20002000
	
SD_IndexDances
        PUSH    {R4-R8, LR}
        MOV     R6, #0              ; Secteur de départ (LBA)
        MOV     R8, #0              ; Compteur de danses trouvées
        LDR     R7, =DANCE_TABLE

SCAN_LOOP
        MOV     R0, R6
        LSL     R0, R0, #9          
        BL      Read_Single_Block   
        
        CMP     R0, #0
        BEQ     SCAN_NEXT         

        LDR     R4, =RAM_BUF
        LDRH    R0, [R4]            
        LDR     R1, =0x5453        
        CMP     R0, R1
        BNE     SCAN_NEXT           
        
        STR     R6, [R7, R8, LSL #2] 
        ADD     R8, R8, #1
        
        CMP     R8, #20             
        BEQ     SCAN_FINISHED

SCAN_NEXT
        ADD     R6, R6, #1
        LDR     R1, =4000          
        CMP     R6, R1
        BNE     SCAN_LOOP

SCAN_FINISHED
        LDR     R0, =DANCE_COUNT
        STR     R8, [R0]            
        POP     {R4-R8, PC}

sd_spi_send
        PUSH    {R1, R2}
        LDR     R1, =SSI0_BASE
WAIT_TX_F
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x02           
        BEQ     WAIT_TX_F
        
        STR     R0, [R1, #0x008]
SD_DELAY
        SUBS    R2, R2, #1
        BNE     SD_DELAY

WAIT_BUSY
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x10           
        BNE     WAIT_BUSY

        LDR     R0, [R1, #0x008]    
        AND     R0, R0, #0xFF       
        POP     {R1, R2}
        BX      LR
		
sd_spi_read_R1
        PUSH    {R4, LR}
        MOV     R4, #500
R1_LOOP
        MOV     R0, #0xFF
        BL      sd_spi_send
        CMP     R0, #0xFF
        BEQ     R1_RETRY
        TST     R0, #0x80           
        BEQ     R1_OK
R1_RETRY
        SUBS    R4, R4, #1
        BNE     R1_LOOP
        MOV     R0, #0xFF
R1_OK
        POP     {R4, PC}

SD_Init
        PUSH    {R4-R6, LR}
        LDR     R0, =0x400FE108
        LDR     R1, [R0]
        ORR     R1, R1, #0x01
        STR     R1, [R0]
        LDR     R0, =0x400FE104
        LDR     R1, [R0]
        ORR     R1, R1, #0x10
        STR     R1, [R0]

        LDR     R0, =GPIO_PORTA_BASE
        MOV     R1, #0x34
        STR     R1, [R0, #0x420]
        LDR     R1, [R0, #0x400]
        ORR     R1, R1, #0x08       
        STR     R1, [R0, #0x400]
        MOV     R1, #0x3C
        STR     R1, [R0, #0x51C]

		LDR     R0, =SSI0_BASE
        MOV     R1, #0x00000000     
        STR     R1, [R0, #0x004]
        
        MOV     R1, #0x07           
        STR     R1, [R0, #0x000]
        MOV     R1, #254            
        STR     R1, [R0, #0x010]
        MOV     R1, #0x02           
        STR     R1, [R0, #0x004]

        LDR     R4, =PA3_CS_ADDR
        MOV     R1, #0x08
        STR     R1, [R4]            
        MOV     R6, #20
INIT_WAKE
        MOV     R0, #0xFF
        BL      sd_spi_send
        SUBS    R6, R6, #1
        BNE     INIT_WAKE

CMD0_SEND
        MOV     R1, #0
        STR     R1, [R4]            
        MOV     R0, #0x40           
        BL      sd_spi_send
        MOV     R0, #0
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        MOV     R0, #0x95
        BL      sd_spi_send
        BL      sd_spi_read_R1
        CMP     R0, #0x01
        BNE     CMD0_SEND          

ACMD41_LOOP
        MOV     R0, #0x41           
        BL      sd_spi_send
        MOV     R0, #0
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        MOV     R0, #0xFF
        BL      sd_spi_send
        BL      sd_spi_read_R1
        CMP     R0, #0x00
        BNE     ACMD41_LOOP

        LDR     R0, =SSI0_BASE
        MOV     R1, #10            
        STR     R1, [R0, #0x010]

        MOV     R1, #0x08
        STR     R1, [R4]            
        MOV     R0, #1              
        POP     {R4-R6, PC}
SD_ReadSector
        PUSH    {R4-R8, LR}
        MOV     R8, R0              
        
        LDR     R1, =DANCE_COUNT
        LDR     R1, [R1]
        CMP     R8, R1
        BGE     READ_FAIL           
        
        LDR     R1, =DANCE_TABLE
        LDR     R6, [R1, R8, LSL #2] 
        
        ADD     R0, R6, #1         
        LSL     R0, R0, #9          
        BL      Read_Single_Block
        CMP     R0, #1
        BNE     READ_FAIL

        LDR     R4, =RAM_BUF
        MOV     R5, #0              

FIND_DATA_START
        CMP     R5, #510           
        BGE     CHOREO_END
        LDRB    R0, [R4], #1
        ADD     R5, R5, #1
        CMP     R0, #0x53           ; 'S'
        BNE     FIND_DATA_START
        LDRB    R0, [R4], #1        ; 'T'
        ADD     R5, R5, #1
        CMP     R0, #0x54
        BNE     FIND_DATA_START

        ; --- Table de saut ---
CHOREO_EXEC 
        LDRB    R0, [R4], #1        
        ADD     R5, R5, #1          
        CMP     R5, #512            
        BGE     CHOREO_END
        CMP     R0, #0xFF           
        BEQ     CHOREO_END
        CMP     R0, #0x00           
        BEQ     CHOREO_EXEC
	
        ; --- TABLE DE SAUT ---
        CMP     R0, #0x01
        BLEQ    MOTEUR_AVANT
        CMP     R0, #0x02
        BLEQ    MOTEUR_ARRIERE
        CMP     R0, #0x03
        BLEQ    PIVOT_DROITE
        CMP     R0, #0x04
        BLEQ    PIVOT_GAUCHE
        CMP     R0, #0x05
        BLEQ    MOTEURS_OFF
        CMP     R0, #0x06
        BLEQ    WALK
        CMP     R0, #0x07
        BLEQ    WALK_BACK
        CMP     R0, #0x08
        BLEQ    STAR
        CMP     R0, #0x09
        BLEQ    CIRCLE_LEFT
        CMP     R0, #0x0A
        BLEQ    CIRCLE_RIGHT
        CMP     R0, #0x0B
        BLEQ    DEMICIRCLE_LEFT
        CMP     R0, #0x0C
        BLEQ    DEMICIRCLE_RIGHT
        CMP     R0, #0x0D
        BLEQ    FRONTBACK

        CMP     R0, #0xFE
        BNE     CHOREO_EXEC         

        LDRB    R2, [R4], #1       
        ADD     R5, R5, #1
        BL      VariableDelay
        B       CHOREO_EXEC         

EXEC_WAIT_PARAM
        LDRB    R2, [R4], #1        
        ADD     R5, R5, #1
        BL      VariableDelay
        B       CHOREO_EXEC

CHOREO_END
        BL      MOTEURS_OFF        
        MOV     R0, #1              
        POP     {R4-R8, PC}

READ_FAIL
        BL      MOTEURS_OFF
        MOV     R0, #0
        POP     {R4-R8, PC}

Read_Single_Block
        PUSH    {R4-R7, LR}        
        MOV     R5, R0              
        LDR     R4, =PA3_CS_ADDR
        LDR     R1, =SSI0_BASE

RSB_FL_L
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x04
        BEQ     RSB_S_CMD
        LDRB    R2, [R1, #0x008]
        B       RSB_FL_L

RSB_S_CMD
        MOV     R3, #0
        STR     R3, [R4]           
        
        MOV     R0, #0x51           
        BL      sd_spi_send
        LSR     R0, R5, #24
		BL sd_spi_send
        LSR     R0, R5, #16
		BL sd_spi_send
        LSR     R0, R5, #8
		BL sd_spi_send
        MOV     R0, R5 
		BL sd_spi_send
        MOV     R0, #0xFF   
		BL sd_spi_send

        BL      sd_spi_read_R1
        CMP     R0, #0x00
        BNE     RSB_E_OUT           

        LDR     R3, =500000
RSB_W_T
        MOV     R0, #0xFF
        BL      sd_spi_send
        CMP     R0, #0xFE
        BEQ     RSB_DO_RD
        SUBS    R3, R3, #1
        BNE     RSB_W_T
        B       RSB_E_OUT

RSB_DO_RD
        LDR     R3, =512          
        LDR     R2, =RAM_BUF      
RSB_L_DATA_SAFE
        CMP     R3, #0
        BEQ     RSB_L_DONE         
        MOV     R0, #0xFF
        BL      sd_spi_send
        STRB    R0, [R2], #1       
        SUBS    R3, R3, #1
        BNE     RSB_L_DATA_SAFE    
RSB_L_DONE        
        MOV     R0, #0xFF
        BL      sd_spi_send
        BL      sd_spi_send
        
        MOV     R0, #0x08
        STR     R0, [R4]      
		NOP
		NOP
		NOP
        MOV     R0, #0xFF
        BL      sd_spi_send     

        MOV     R0, #1          
        POP     {R4-R7, PC}       

RSB_E_OUT
        MOV     R0, #0x08
        STR     R0, [R4]            
        MOV     R0, #0              
        POP     {R4-R7, PC}         

; --- DELAIS ---
VariableDelay
        PUSH    {R7}
        CMP     R2, #0              
		BEQ     VD_END             
        LDR     R7, =10000000        
        MUL     R7, R7, R2
VD_LP   SUBS    R7, R7, #1
        BNE     VD_LP
VD_END  POP     {R7}
        BX      LR

MOTEUR_AVANT
        PUSH    {LR}
        BL      MOTEURS_OFF         
        BL      MOTEUR_DROIT_AVANT
        BL      MOTEUR_GAUCHE_AVANT
        BL      MOTEUR_DROIT_ON
        BL      MOTEUR_GAUCHE_ON
        POP     {PC}

MOTEUR_ARRIERE
        PUSH    {LR}
        BL      MOTEURS_OFF
        BL      MOTEUR_DROIT_ARRIERE
        BL      MOTEUR_GAUCHE_ARRIERE
        BL      MOTEUR_DROIT_ON
        BL      MOTEUR_GAUCHE_ON
        POP     {PC}

PIVOT_DROITE
        PUSH    {LR}
        BL      MOTEURS_OFF
        BL      MOTEUR_GAUCHE_AVANT
        BL      MOTEUR_DROIT_ARRIERE
        BL      MOTEUR_DROIT_ON
        BL      MOTEUR_GAUCHE_ON
        POP     {PC}

PIVOT_GAUCHE
        PUSH    {LR}
        BL      MOTEURS_OFF
        BL      MOTEUR_DROIT_AVANT
        BL      MOTEUR_GAUCHE_ARRIERE
        BL      MOTEUR_DROIT_ON
        BL      MOTEUR_GAUCHE_ON
        POP     {PC}

MOTEURS_OFF
        PUSH    {R0, R1, LR}
        MOV     R0, #0
        LDR     R1, =GPIO_PORTF_DATA
        STR     R0, [R1]            
        POP     {R0, R1, PC}

        END