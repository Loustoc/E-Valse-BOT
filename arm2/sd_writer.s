; sd_writer.s - ecrit les danses embedded sur la carte SD au boot
; comme ca on peut les jouer depuis la carte

        AREA SD_WRITER, CODE, READONLY, ALIGN=2

        EXPORT SD_WriteEmbeddedDances

        ; imports des fonctions SPI du driver
        IMPORT sd_spi_send
        IMPORT sd_spi_read_R1

        ; les donnees des danses sont dans embedded_dances.s
        IMPORT EMBEDDED_DANCES_BASE

SSI0_BASE       EQU 0x40008000
PA3_CS_ADDR     EQU 0x40004020

; chaque danse fait 1024 bytes (2 secteurs de 512)
VALSE_OFFSET        EQU 0
ITALODISCO_OFFSET   EQU 1024

; Write_Single_Block: ecrit 512 bytes sur la carte SD
; R0 = adresse byte, R1 = pointeur vers les donnees
; retourne 1 si ok, 0 si erreur
Write_Single_Block
        PUSH    {R4-R7, LR}
        MOV     R5, R0              ; R5 = adresse byte
        MOV     R6, R1              ; R6 = pointeur data
        LDR     R4, =PA3_CS_ADDR

        ; vide le FIFO RX
        LDR     R1, =SSI0_BASE
WSB_FL_L
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x04
        BEQ     WSB_S_CMD
        LDRB    R2, [R1, #0x008]
        B       WSB_FL_L

WSB_S_CMD
        MOV     R3, #0
        STR     R3, [R4]            ; CS low

        ; CMD24 (0x58) = write single block
        MOV     R0, #0x58
        BL      sd_spi_send
        LSR     R0, R5, #24         ; adresse en big-endian
        BL      sd_spi_send
        LSR     R0, R5, #16
        BL      sd_spi_send
        LSR     R0, R5, #8
        BL      sd_spi_send
        MOV     R0, R5
        BL      sd_spi_send
        MOV     R0, #0xFF           ; dummy CRC
        BL      sd_spi_send

        ; attend reponse 0x00
        BL      sd_spi_read_R1
        CMP     R0, #0x00
        BNE     WSB_E_OUT

        ; envoie le token de debut (0xFE)
        MOV     R0, #0xFE
        BL      sd_spi_send

        ; envoie les 512 bytes
        LDR     R3, =512
WSB_DATA_LOOP
        LDRB    R0, [R6], #1
        BL      sd_spi_send
        SUBS    R3, R3, #1
        BNE     WSB_DATA_LOOP

        ; envoie le CRC (dummy)
        MOV     R0, #0xFF
        BL      sd_spi_send
        MOV     R0, #0xFF
        BL      sd_spi_send

        ; lit la reponse (0x05 = accepte)
        MOV     R0, #0xFF
        BL      sd_spi_send
        AND     R0, R0, #0x1F
        CMP     R0, #0x05
        BNE     WSB_E_OUT

        ; attend que la carte finisse d'ecrire (busy = 0x00)
        LDR     R3, =500000
WSB_BUSY_LOOP
        MOV     R0, #0xFF
        BL      sd_spi_send
        CMP     R0, #0x00
        BNE     WSB_DONE            ; plus busy
        SUBS    R3, R3, #1
        BNE     WSB_BUSY_LOOP
        B       WSB_E_OUT           ; timeout

WSB_DONE
        MOV     R0, #0x08
        STR     R0, [R4]            ; CS high
        NOP
        NOP
        NOP
        MOV     R0, #0xFF
        BL      sd_spi_send         ; trailing clock

        MOV     R0, #1              ; succes
        POP     {R4-R7, PC}

WSB_E_OUT
        MOV     R0, #0x08
        STR     R0, [R4]            ; CS high
        MOV     R0, #0              ; erreur
        POP     {R4-R7, PC}

; SD_WriteEmbeddedDances: ecrit les danses embedded sur la carte SD
; valse dans secteurs 0-1, italodisco dans secteurs 2-3
; a appeler apres SD_Init et avant SD_IndexDances
SD_WriteEmbeddedDances
        PUSH    {R4-R5, LR}

        LDR     R4, =EMBEDDED_DANCES_BASE

        ; ecrit header valse (secteur 0)
        MOV     R0, #0
        ADD     R1, R4, #VALSE_OFFSET
        BL      Write_Single_Block
        CMP     R0, #1
        BNE     WED_DONE

        ; ecrit moves valse (secteur 1)
        LDR     R0, =512
        ADD     R1, R4, #VALSE_OFFSET
        ADD     R1, R1, #512
        BL      Write_Single_Block
        CMP     R0, #1
        BNE     WED_DONE

        ; ecrit header italodisco (secteur 2)
        LDR     R0, =1024
        ADD     R1, R4, #ITALODISCO_OFFSET
        BL      Write_Single_Block
        CMP     R0, #1
        BNE     WED_DONE

        ; ecrit moves italodisco (secteur 3)
        LDR     R0, =1536
        ADD     R1, R4, #ITALODISCO_OFFSET
        ADD     R1, R1, #512
        BL      Write_Single_Block

WED_DONE
        POP     {R4-R5, PC}

        END
