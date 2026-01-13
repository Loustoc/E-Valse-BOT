;; sd_writer.s - SD Card Write Functions
;; Writes embedded dance data to SD card on boot

        AREA SD_WRITER, CODE, READONLY, ALIGN=2

        EXPORT SD_WriteEmbeddedDances

        ;; Import SPI functions from sd_driver.s
        IMPORT sd_spi_send
        IMPORT sd_spi_read_R1

        ;; Import embedded dance data (combined file)
        IMPORT EMBEDDED_DANCES_BASE

;; Constants
SSI0_BASE       EQU 0x40008000
PA3_CS_ADDR     EQU 0x40004020

;; Dance offsets in combined file (each dance = 1024 bytes)
VALSE_OFFSET        EQU 0       ; Valse at offset 0
ITALODISCO_OFFSET   EQU 1024    ; Italodisco at offset 1024

;; ============================================
;; Write_Single_Block - Write 512 bytes to SD card
;; Input: R0 = byte address, R1 = pointer to 512 bytes of data
;; Output: R0 = 1 (success) or 0 (failure)
;; Uses CMD24 (0x58)
;; ============================================
Write_Single_Block
        PUSH    {R4-R7, LR}
        MOV     R5, R0              ; R5 = byte address
        MOV     R6, R1              ; R6 = data pointer
        LDR     R4, =PA3_CS_ADDR

        ;; Flush RX FIFO
        LDR     R1, =SSI0_BASE
WSB_FL_L
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x04
        BEQ     WSB_S_CMD
        LDRB    R2, [R1, #0x008]
        B       WSB_FL_L

WSB_S_CMD
        ;; Pull CS low
        MOV     R3, #0
        STR     R3, [R4]

        ;; Send CMD24 (0x58 = 0x40 + 0x18)
        MOV     R0, #0x58
        BL      sd_spi_send
        ;; Send 4-byte address (big-endian)
        LSR     R0, R5, #24
        BL      sd_spi_send
        LSR     R0, R5, #16
        BL      sd_spi_send
        LSR     R0, R5, #8
        BL      sd_spi_send
        MOV     R0, R5
        BL      sd_spi_send
        ;; Send dummy CRC
        MOV     R0, #0xFF
        BL      sd_spi_send

        ;; Read R1 response (must be 0x00)
        BL      sd_spi_read_R1
        CMP     R0, #0x00
        BNE     WSB_E_OUT

        ;; Send data token (0xFE = start block)
        MOV     R0, #0xFE
        BL      sd_spi_send

        ;; Send 512 bytes of data
        LDR     R3, =512
WSB_DATA_LOOP
        LDRB    R0, [R6], #1
        BL      sd_spi_send
        SUBS    R3, R3, #1
        BNE     WSB_DATA_LOOP

        ;; Send 2 dummy CRC bytes
        MOV     R0, #0xFF
        BL      sd_spi_send
        MOV     R0, #0xFF
        BL      sd_spi_send

        ;; Read data response (bits 4-0: 0x05 = accepted)
        MOV     R0, #0xFF
        BL      sd_spi_send
        AND     R0, R0, #0x1F
        CMP     R0, #0x05
        BNE     WSB_E_OUT

        ;; Wait for card to finish writing (busy = 0x00)
        LDR     R3, =500000
WSB_BUSY_LOOP
        MOV     R0, #0xFF
        BL      sd_spi_send
        CMP     R0, #0x00
        BNE     WSB_DONE           ; Not busy anymore
        SUBS    R3, R3, #1
        BNE     WSB_BUSY_LOOP
        B       WSB_E_OUT          ; Timeout

WSB_DONE
        ;; Pull CS high
        MOV     R0, #0x08
        STR     R0, [R4]
        NOP
        NOP
        NOP
        ;; Send trailing clocks
        MOV     R0, #0xFF
        BL      sd_spi_send

        MOV     R0, #1              ; Success
        POP     {R4-R7, PC}

WSB_E_OUT
        MOV     R0, #0x08
        STR     R0, [R4]            ; CS high
        MOV     R0, #0              ; Failure
        POP     {R4-R7, PC}

;; ============================================
;; SD_WriteEmbeddedDances - Write embedded dances to SD card
;; Writes both valse and italodisco to sectors 0-3
;; Call after SD_Init succeeds, before SD_IndexDances
;; ============================================
SD_WriteEmbeddedDances
        PUSH    {R4-R5, LR}

        ;; Get base address of embedded dances
        LDR     R4, =EMBEDDED_DANCES_BASE

        ;; Write Valse header (sector 0, byte address 0)
        MOV     R0, #0
        ADD     R1, R4, #VALSE_OFFSET
        BL      Write_Single_Block
        CMP     R0, #1
        BNE     WED_DONE

        ;; Write Valse moves (sector 1, byte address 512)
        LDR     R0, =512
        ADD     R1, R4, #VALSE_OFFSET
        ADD     R1, R1, #512
        BL      Write_Single_Block
        CMP     R0, #1
        BNE     WED_DONE

        ;; Write Italodisco header (sector 2, byte address 1024)
        LDR     R0, =1024
        ADD     R1, R4, #ITALODISCO_OFFSET
        BL      Write_Single_Block
        CMP     R0, #1
        BNE     WED_DONE

        ;; Write Italodisco moves (sector 3, byte address 1536)
        LDR     R0, =1536
        ADD     R1, R4, #ITALODISCO_OFFSET
        ADD     R1, R1, #512
        BL      Write_Single_Block

WED_DONE
        POP     {R4-R5, PC}

        END
