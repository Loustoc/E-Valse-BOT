		AREA SD_DATA, DATA, READWRITE
DANCE_TABLE  SPACE 80               
DANCE_COUNT  DCD 0                  

        AREA SD_DRIVER, CODE, READONLY, ALIGN=2
        EXPORT SD_Init
        EXPORT SD_ReadSector
        EXPORT SD_IndexDances
		EXPORT DANCE_COUNT
        EXPORT sd_spi_send
        EXPORT sd_spi_read_R1

        IMPORT  MOTEUR_SET_VITESSE
        IMPORT  LED_SET_PERIOD
        IMPORT  MOTEUR_GAUCHE_ON
        IMPORT  MOTEUR_GAUCHE_OFF
        IMPORT  MOTEUR_GAUCHE_AVANT
        IMPORT  MOTEUR_GAUCHE_ARRIERE
        IMPORT  MOTEUR_DROIT_ON
        IMPORT  MOTEUR_DROIT_OFF
        IMPORT  MOTEUR_DROIT_AVANT
        IMPORT  MOTEUR_DROIT_ARRIERE
        IMPORT  TICK_MS                 ; Millisecond counter from led.s

SSI0_BASE         EQU 0x40008000
GPIO_PORTA_BASE   EQU 0x40004000
PA3_CS_ADDR       EQU 0x40004020
RAM_BUF           EQU 0x20002000
DANCE_DURATION    EQU 90000             ; 90 seconds in milliseconds
	
SD_IndexDances
        PUSH    {R4-R8, LR}
        MOV     R6, #0             
        MOV     R8, #0              
        LDR     R7, =DANCE_TABLE

SCAN_LOOP_INIT
        MOV     R0, R6
        LSL     R0, R0, #9          
        BL      Read_Single_Block
        CMP     R0, #0
        BEQ     SCAN_NEXT           

        LDR     R4, =RAM_BUF
        LDRB    R0, [R4]
        CMP     R0, #0x53           ; 'S'
        BNE     SCAN_NEXT
        LDRB    R0, [R4, #1]
        CMP     R0, #0x54           ; 'T'
        BNE     SCAN_NEXT
        
        ADD     R1, R6, #1
        STR     R1, [R7, R8, LSL #2] ; DANCE_TABLE[R8] = R6 + 1
        ADD     R8, R8, #1
        
        CMP     R8, #20             
        BEQ     SCAN_FINISHED

SCAN_NEXT
        ADD     R6, R6, #1
        CMP     R6, #10             ; Only scan first 10 sectors (was 5000!)
        BNE     SCAN_LOOP_INIT

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

        MOV     R5, #200            ; CMD0 retry limit
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
        BEQ     CMD0_OK             ; success
        SUBS    R5, R5, #1
        BNE     CMD0_SEND
        B       SD_INIT_FAIL        ; timeout - no SD card
CMD0_OK

        LDR     R5, =1000           ; ACMD41 retry limit (needs more attempts)
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
        BEQ     ACMD41_OK           ; success
        SUBS    R5, R5, #1
        BNE     ACMD41_LOOP
        B       SD_INIT_FAIL        ; timeout
ACMD41_OK

        LDR     R0, =SSI0_BASE
        MOV     R1, #10
        STR     R1, [R0, #0x010]

        MOV     R1, #0x08
        STR     R1, [R4]
        MOV     R0, #1              ; return 1 = success
        POP     {R4-R6, PC}

SD_INIT_FAIL
        MOV     R1, #0x08
        STR     R1, [R4]            ; CS high
        MOV     R0, #0              ; return 0 = failure
        POP     {R4-R6, PC}
SD_ReadSector
        PUSH    {R4-R11, LR}
        MOV     R8, R0

        LDR     R1, =DANCE_COUNT
        LDR     R1, [R1]
        CMP     R8, R1
        BGE     READ_FAIL

        LDR     R1, =DANCE_TABLE
        LDR     R6, [R1, R8, LSL #2]     ; R6 = moves sector

        ;; First read HEADER block (sector before moves)
        SUB     R0, R6, #1               ; header sector = moves - 1
        LSL     R0, R0, #9               ; byte address
        BL      Read_Single_Block
        CMP     R0, #1
        BNE     READ_FAIL

        ;; Extract motor speed from header offset 8-9 (big-endian)
        LDR     R4, =RAM_BUF
        LDRB    R0, [R4, #8]             ; high byte
        LDRB    R1, [R4, #9]             ; low byte
        LSL     R0, R0, #8
        ORR     R0, R0, R1               ; R0 = motor speed
        BL      MOTEUR_SET_VITESSE

        ;; Extract LED period from header offset 10-11 (big-endian)
        LDR     R4, =RAM_BUF
        LDRB    R0, [R4, #10]            ; high byte
        LDRB    R1, [R4, #11]            ; low byte
        LSL     R0, R0, #8
        ORR     R0, R0, R1               ; R0 = LED period in ms
        BL      LED_SET_PERIOD

        ;; Now read MOVES block
        MOV     R0, R6
        LSL     R0, R0, #9
        BL      Read_Single_Block
        CMP     R0, #1
        BNE     READ_FAIL

        LDR     R4, =RAM_BUF

        ;; Setup duration tracking
        ;; R9 = pointer to TICK_MS, R10 = start time, R11 = duration
        LDR     R9, =TICK_MS
        LDR     R10, [R9]               ; R10 = start tick
        LDR     R11, =DANCE_DURATION    ; R11 = 90000 ms

;; ============================================
;; CHOREO_EXEC - Execute choreography v3 format
;; 2-byte moves: [motor_byte][duration_byte]
;;   motor_byte bits 3-2: left motor  (00=off, 01=fwd, 10=back)
;;   motor_byte bits 1-0: right motor (00=off, 01=fwd, 10=back)
;;   duration_byte: 0-255 time units
;;   End marker: 0xFF 0xFF
;; ============================================
CHOREO_EXEC
        ;; Read motor byte
        LDRB    R0, [R4], #1
        CMP     R0, #0xFF                ; check end marker (first byte)
        BNE     choreo_not_end
        LDRB    R1, [R4]                 ; peek next byte
        CMP     R1, #0xFF                ; end marker = 0xFF 0xFF
        BEQ     CHOREO_END
choreo_not_end
        CMP     R0, #0x00                ; skip zero bytes (padding)
        BEQ     CHOREO_EXEC

        ;; R0 = motor byte, read duration byte
        MOV     R5, R0                   ; save motor byte in R5
        LDRB    R6, [R4], #1             ; R6 = duration byte
        PUSH    {R6}                     ; save duration (motor funcs clobber R6!)

        ;; Extract left motor state (bits 3-2)
        MOV     R0, R5
        LSR     R0, R0, #2
        AND     R0, R0, #0x03            ; R0 = left motor state

        ;; Set left motor direction and on/off
        CMP     R0, #0                   ; OFF
        BEQ     left_off
        CMP     R0, #1                   ; FORWARD
        BEQ     left_fwd
        CMP     R0, #2                   ; BACKWARD
        BEQ     left_bck
        B       left_done                ; skip invalid

left_off
        BL      MOTEUR_GAUCHE_OFF
        B       left_done
left_fwd
        BL      MOTEUR_GAUCHE_AVANT
        BL      MOTEUR_GAUCHE_ON
        B       left_done
left_bck
        BL      MOTEUR_GAUCHE_ARRIERE
        BL      MOTEUR_GAUCHE_ON
left_done

        ;; Extract right motor state (bits 1-0)
        AND     R0, R5, #0x03            ; R0 = right motor state

        ;; Set right motor direction and on/off
        CMP     R0, #0                   ; OFF
        BEQ     right_off
        CMP     R0, #1                   ; FORWARD
        BEQ     right_fwd
        CMP     R0, #2                   ; BACKWARD
        BEQ     right_bck
        B       right_done               ; skip invalid

right_off
        BL      MOTEUR_DROIT_OFF
        B       right_done
right_fwd
        BL      MOTEUR_DROIT_AVANT
        BL      MOTEUR_DROIT_ON
        B       right_done
right_bck
        BL      MOTEUR_DROIT_ARRIERE
        BL      MOTEUR_DROIT_ON
right_done

        ;; Delay based on duration
        ;; Restore duration from stack (was saved before motor calls)
        POP     {R6}
        ;; Use same constant as hardcoded dances: DUREE = 0x1FFFFF
        LDR     R7, =0x1FFFFF
        MUL     R6, R6, R7

DANCE_DELAY
        SUBS    R6, R6, #1
        BNE     DANCE_DELAY

        ;; Check if duration reached
        LDR     R0, [R9]                ; Current tick
        SUB     R0, R0, R10             ; Elapsed = current - start
        CMP     R0, R11                 ; Compare with duration (ms)
        BGE     CHOREO_END              ; Stop if duration reached

        B       CHOREO_EXEC

CHOREO_END
		BL 		MOTEUR_DROIT_OFF
		BL 		MOTEUR_GAUCHE_OFF

        MOV     R0, #1                   ; success
        POP     {R4-R11, PC}

READ_FAIL
        MOV     R0, #0
        POP     {R4-R11, PC}

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
        LDR     R7, =100000
        MUL     R7, R7, R2
VD_LP   SUBS    R7, R7, #1
        BNE     VD_LP
        POP     {R7}              
        BX      LR

ShortPause
        PUSH    {R7}
        LDR     R7, =400000
SP_LP   SUBS    R7, R7, #1
        BNE     SP_LP
        POP     {R7}
        BX      LR

        END