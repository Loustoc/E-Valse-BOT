; driver carte SD en SPI
; gere l'init, lecture de secteurs et execution des choreographies

		AREA SD_DATA, DATA, READWRITE
DANCE_TABLE  SPACE 80               ; table des secteurs de danses (max 20)
DANCE_COUNT  DCD 0                  ; nombre de danses trouvees

        AREA SD_DRIVER, CODE, READONLY, ALIGN=2
        EXPORT SD_Init
        EXPORT SD_ReadSector
        EXPORT SD_IndexDances
		EXPORT DANCE_COUNT
        EXPORT sd_spi_send
        EXPORT sd_spi_read_R1

		; imports moteurs et LEDs pour jouer les danses
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
        IMPORT  TICK_MS                 ; compteur ms pour timer des danses

SSI0_BASE         EQU 0x40008000        ; base du module SPI
GPIO_PORTA_BASE   EQU 0x40004000        ; GPIO port A pour CS
PA3_CS_ADDR       EQU 0x40004020        ; adresse du pin CS (PA3)
RAM_BUF           EQU 0x20002000        ; buffer en RAM pour lire les secteurs
DANCE_DURATION    EQU 60000             ; 60 secondes en ms
	
; SD_IndexDances: scanne les premiers secteurs pour trouver les danses
; cherche le magic "ST" (STEP) au debut de chaque header
SD_IndexDances
        PUSH    {R4-R8, LR}
        MOV     R6, #0              ; R6 = numero de secteur courant
        MOV     R8, #0              ; R8 = nombre de danses trouvees
        LDR     R7, =DANCE_TABLE

SCAN_LOOP_INIT
        ; lit le secteur courant
        MOV     R0, R6
        LSL     R0, R0, #9          ; adresse byte = secteur * 512
        BL      Read_Single_Block
        CMP     R0, #0
        BEQ     SCAN_NEXT           ; erreur de lecture, on passe au suivant

        ; check si ca commence par "ST" (debut de "STEP")
        LDR     R4, =RAM_BUF
        LDRB    R0, [R4]
        CMP     R0, #0x53           ; 'S'
        BNE     SCAN_NEXT
        LDRB    R0, [R4, #1]
        CMP     R0, #0x54           ; 'T'
        BNE     SCAN_NEXT

        ; trouve! on stocke le secteur des moves (header + 1)
        ADD     R1, R6, #1
        STR     R1, [R7, R8, LSL #2]
        ADD     R8, R8, #1

        CMP     R8, #20             ; max 20 danses
        BEQ     SCAN_FINISHED

SCAN_NEXT
        ADD     R6, R6, #1
        CMP     R6, #10             ; scanne seulement les 10 premiers secteurs
        BNE     SCAN_LOOP_INIT

SCAN_FINISHED
        LDR     R0, =DANCE_COUNT
        STR     R8, [R0]            ; sauvegarde le nombre de danses
        POP     {R4-R8, PC}

; sd_spi_send: envoie un byte sur SPI et retourne la reponse
; R0 = byte a envoyer, retourne la reponse dans R0
sd_spi_send
        PUSH    {R1, R2}
        LDR     R1, =SSI0_BASE
WAIT_TX_F
        LDR     R2, [R1, #0x00C]    ; lit le registre status
        TST     R2, #0x02           ; check si TX FIFO pas plein
        BEQ     WAIT_TX_F

        STR     R0, [R1, #0x008]    ; envoie le byte
SD_DELAY
        SUBS    R2, R2, #1
        BNE     SD_DELAY

WAIT_BUSY
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x10           ; attend que le SPI soit pas busy
        BNE     WAIT_BUSY

        LDR     R0, [R1, #0x008]    ; lit la reponse
        AND     R0, R0, #0xFF
        POP     {R1, R2}
        BX      LR

; sd_spi_read_R1: lit une reponse R1 de la carte SD
; attend jusqu'a 500 essais pour avoir une reponse valide
sd_spi_read_R1
        PUSH    {R4, LR}
        MOV     R4, #500
R1_LOOP
        MOV     R0, #0xFF
        BL      sd_spi_send
        CMP     R0, #0xFF           ; 0xFF = pas de reponse
        BEQ     R1_RETRY
        TST     R0, #0x80           ; bit 7 doit etre 0 pour reponse valide
        BEQ     R1_OK
R1_RETRY
        SUBS    R4, R4, #1
        BNE     R1_LOOP
        MOV     R0, #0xFF           ; timeout, retourne erreur
R1_OK
        POP     {R4, PC}

; SD_Init: initialise la carte SD en mode SPI
; retourne 1 si ok, 0 si pas de carte ou erreur
SD_Init
        PUSH    {R4-R6, LR}

        ; active les clocks pour SSI0 et GPIO port A
        LDR     R0, =0x400FE108
        LDR     R1, [R0]
        ORR     R1, R1, #0x01
        STR     R1, [R0]
        LDR     R0, =0x400FE104
        LDR     R1, [R0]
        ORR     R1, R1, #0x10
        STR     R1, [R0]

        ; config GPIO port A pour SPI (PA2,4,5 = CLK,MOSI,MISO)
        LDR     R0, =GPIO_PORTA_BASE
        MOV     R1, #0x34
        STR     R1, [R0, #0x420]
        LDR     R1, [R0, #0x400]
        ORR     R1, R1, #0x08           ; PA3 = CS en output
        STR     R1, [R0, #0x400]
        MOV     R1, #0x3C
        STR     R1, [R0, #0x51C]

        ; config SSI0 en mode SPI, vitesse lente pour init
		LDR     R0, =SSI0_BASE
        MOV     R1, #0x00000000
        STR     R1, [R0, #0x004]        ; desactive SSI

        MOV     R1, #0x07               ; mode SPI, 8 bits
        STR     R1, [R0, #0x000]
        MOV     R1, #254                ; clock prescaler = 254 (lent)
        STR     R1, [R0, #0x010]
        MOV     R1, #0x02               ; active SSI
        STR     R1, [R0, #0x004]

        ; CS high et on envoie des clocks pour reveiller la carte
        LDR     R4, =PA3_CS_ADDR
        MOV     R1, #0x08
        STR     R1, [R4]
        MOV     R6, #20                 ; 20 bytes = 160 clocks
INIT_WAKE
        MOV     R0, #0xFF
        BL      sd_spi_send
        SUBS    R6, R6, #1
        BNE     INIT_WAKE

        ; CMD0: met la carte en mode idle, doit repondre 0x01
        MOV     R5, #200
CMD0_SEND
        MOV     R1, #0
        STR     R1, [R4]                ; CS low
        MOV     R0, #0x40               ; CMD0 = 0x40
        BL      sd_spi_send
        MOV     R0, #0
        BL      sd_spi_send             ; argument = 0
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        MOV     R0, #0x95               ; CRC pour CMD0
        BL      sd_spi_send
        BL      sd_spi_read_R1
        CMP     R0, #0x01               ; 0x01 = idle state
        BEQ     CMD0_OK
        SUBS    R5, R5, #1
        BNE     CMD0_SEND
        B       SD_INIT_FAIL            ; timeout, pas de carte
CMD0_OK

        ; CMD1 pour finir l'init (carte 2GB standard)
        LDR     R5, =10
ACMD41_LOOP
        MOV     R0, #0x41               ; CMD1
        BL      sd_spi_send
        MOV     R0, #0
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        BL      sd_spi_send
        MOV     R0, #0xFF
        BL      sd_spi_send
        BL      sd_spi_read_R1
        CMP     R0, #0x00               ; 0x00 = init complete
        BEQ     ACMD41_OK
        SUBS    R5, R5, #1
        BNE     ACMD41_LOOP
        B       SD_INIT_FAIL
ACMD41_OK

        ; augmente la vitesse SPI maintenant que l'init est finie
        LDR     R0, =SSI0_BASE
        MOV     R1, #10                 ; clock prescaler = 10 (rapide)
        STR     R1, [R0, #0x010]

        MOV     R1, #0x08
        STR     R1, [R4]                ; CS high
        MOV     R0, #1                  ; succes
        POP     {R4-R6, PC}

SD_INIT_FAIL
        MOV     R1, #0x08
        STR     R1, [R4]                ; CS high
        MOV     R0, #0                  ; echec
        POP     {R4-R6, PC}
; SD_ReadSector: lit et execute une danse depuis la carte SD
; R0 = index de la danse (0, 1, 2...)
SD_ReadSector
        PUSH    {R4-R11, LR}
        MOV     R8, R0                  ; R8 = index de la danse

        ; check si l'index est valide (on inverse la condition car READ_FAIL est trop loin)
        LDR     R1, =DANCE_COUNT
        LDR     R1, [R1]
        CMP     R8, R1
        BLT     index_ok
        B       READ_FAIL
index_ok

        ; recupere le numero de secteur des moves
        LDR     R1, =DANCE_TABLE
        LDR     R6, [R1, R8, LSL #2]

        ; lit d'abord le header (secteur avant les moves)
        SUB     R0, R6, #1
        LSL     R0, R0, #9
        BL      Read_Single_Block
        CMP     R0, #1
        BNE     READ_FAIL

        ; extrait la vitesse moteur du header (offset 8-9, big-endian)
        LDR     R4, =RAM_BUF
        LDRB    R0, [R4, #8]
        LDRB    R1, [R4, #9]
        LSL     R0, R0, #8
        ORR     R0, R0, R1
        BL      MOTEUR_SET_VITESSE

        ; extrait la periode LED du header (offset 10-11)
        LDR     R4, =RAM_BUF
        LDRB    R0, [R4, #10]
        LDRB    R1, [R4, #11]
        LSL     R0, R0, #8
        ORR     R0, R0, R1
        BL      LED_SET_PERIOD

        ; maintenant on lit les moves
        MOV     R0, R6
        LSL     R0, R0, #9
        BL      Read_Single_Block
        CMP     R0, #1
        BNE     READ_FAIL

        LDR     R4, =RAM_BUF            ; R4 pointe vers les moves

        ; setup du timer pour limiter a 60 sec
        LDR     R9, =TICK_MS
        LDR     R10, [R9]               ; R10 = temps de depart
        LDR     R11, =DANCE_DURATION

; execute la choregraphie
; format: 2 bytes par move [moteur][duree]
; bits 3-2 = moteur gauche (00=off, 01=avant, 10=arriere)
; bits 1-0 = moteur droit (idem)
; fin = 0xFF 0xFF, puis on recommence jusqu'a 60s
CHOREO_EXEC
        ; lit le byte moteur
        LDRB    R0, [R4], #1
        CMP     R0, #0xFF
        BNE     choreo_not_end
        LDRB    R1, [R4]
        CMP     R1, #0xFF               ; 0xFF 0xFF = fin de sequence
        BEQ     choreo_check_loop       ; verifie si on doit boucler
choreo_not_end
        CMP     R0, #0x00               ; ignore les zeros (padding)
        BEQ     CHOREO_EXEC

        ; R5 = byte moteur, R6 = duree
        MOV     R5, R0
        LDRB    R6, [R4], #1
        PUSH    {R6}                    ; sauvegarde car motor.s clobber R6

        ; moteur gauche (bits 3-2)
        MOV     R0, R5
        LSR     R0, R0, #2
        AND     R0, R0, #0x03

        CMP     R0, #0
        BEQ     left_off
        CMP     R0, #1
        BEQ     left_fwd
        CMP     R0, #2
        BEQ     left_bck
        B       left_done

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

        ; moteur droit (bits 1-0)
        AND     R0, R5, #0x03

        CMP     R0, #0
        BEQ     right_off
        CMP     R0, #1
        BEQ     right_fwd
        CMP     R0, #2
        BEQ     right_bck
        B       right_done

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

        ; delai selon la duree du move
        POP     {R6}
        LDR     R7, =0x1FFFFF           ; meme constante que les danses en dur
        MUL     R6, R6, R7

DANCE_DELAY
        SUBS    R6, R6, #1
        BNE     DANCE_DELAY

        ; check si on a depasse 60 secondes
        LDR     R0, [R9]
        SUB     R0, R0, R10
        CMP     R0, R11
        BGE     CHOREO_END

        B       CHOREO_EXEC

; fin de sequence, on verifie si on doit recommencer
choreo_check_loop
        LDR     R0, [R9]
        SUB     R0, R0, R10
        CMP     R0, R11
        BGE     CHOREO_END              ; 60s atteintes, on arrete
        ; sinon on recommence depuis le debut
        LDR     R4, =RAM_BUF
        B       CHOREO_EXEC

CHOREO_END
        ; arrete les moteurs avant de sortir
		BL 		MOTEUR_DROIT_OFF
		BL 		MOTEUR_GAUCHE_OFF

        MOV     R0, #1
        POP     {R4-R11, PC}

READ_FAIL
        MOV     R0, #0
        POP     {R4-R11, PC}

; Read_Single_Block: lit un secteur de 512 bytes depuis la carte SD
; R0 = adresse byte du secteur
; retourne 1 si ok, 0 si erreur
Read_Single_Block
        PUSH    {R4-R7, LR}
        MOV     R5, R0              ; R5 = adresse byte
        LDR     R4, =PA3_CS_ADDR
        LDR     R1, =SSI0_BASE

        ; vide le FIFO RX avant de commencer
RSB_FL_L
        LDR     R2, [R1, #0x00C]
        TST     R2, #0x04
        BEQ     RSB_S_CMD
        LDRB    R2, [R1, #0x008]
        B       RSB_FL_L

RSB_S_CMD
        MOV     R3, #0
        STR     R3, [R4]            ; CS low

        ; CMD17 (0x51) = read single block
        MOV     R0, #0x51
        BL      sd_spi_send
        LSR     R0, R5, #24         ; adresse en big-endian
		BL sd_spi_send
        LSR     R0, R5, #16
		BL sd_spi_send
        LSR     R0, R5, #8
		BL sd_spi_send
        MOV     R0, R5
		BL sd_spi_send
        MOV     R0, #0xFF           ; dummy CRC
		BL sd_spi_send

        ; attend reponse 0x00
        BL      sd_spi_read_R1
        CMP     R0, #0x00
        BNE     RSB_E_OUT

        ; attend le token de debut de donnees (0xFE)
        LDR     R3, =500000
RSB_W_T
        MOV     R0, #0xFF
        BL      sd_spi_send
        CMP     R0, #0xFE
        BEQ     RSB_DO_RD
        SUBS    R3, R3, #1
        BNE     RSB_W_T
        B       RSB_E_OUT           ; timeout

RSB_DO_RD
        ; lit les 512 bytes dans RAM_BUF
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
        ; lit le CRC (2 bytes, on s'en fout)
        MOV     R0, #0xFF
        BL      sd_spi_send
        BL      sd_spi_send

        ; CS high avec petit delai
        MOV     R0, #0x08
        STR     R0, [R4]
		NOP
		NOP
		NOP
        MOV     R0, #0xFF
        BL      sd_spi_send         ; trailing clock

        MOV     R0, #1              ; succes
        POP     {R4-R7, PC}

RSB_E_OUT
        MOV     R0, #0x08
        STR     R0, [R4]            ; CS high
        MOV     R0, #0              ; erreur
        POP     {R4-R7, PC}

        END