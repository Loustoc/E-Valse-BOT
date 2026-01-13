;; EvalBot - Dancing Robot
;; Features:
;;   - Button/Bumper controls
;;   - LED speed control
;;   - SD card dance support (right bumper)
;;   - Hardcoded VALSE/ITALODISCO (buttons)

        AREA    |.text|, CODE, READONLY
        ENTRY
        EXPORT  __main

        ;; Hardware init
        IMPORT  MOTEUR_INIT
        IMPORT  LED_INIT
        IMPORT  LED_CYCLE_SPEED
        IMPORT  LED_SET_MODE
        IMPORT  LED_SET_PERIOD
        IMPORT  BUMPER_INIT
        IMPORT  BUMPER_LEFT_PRESSED
        IMPORT  BUMPER_RIGHT_PRESSED
        IMPORT  BUTTON_INIT
        IMPORT  BUTTON1_PRESSED
        IMPORT  BUTTON2_PRESSED

        ;; Dance routines (hardcoded)
        IMPORT  ITALODISCO
        IMPORT  VALSE

        ;; SD card functions
        IMPORT  SD_Init
        IMPORT  SD_ReadSector
        IMPORT  SD_IndexDances
        IMPORT  SD_WriteEmbeddedDances

;; LED modes
MODE_ALTERNATE  EQU     0
MODE_TOGETHER   EQU     1
MODE_SD_OK      EQU     2               ; Right LED fixed ON, left blinks
MODE_NO_SD      EQU     3               ; Right LED blinks 2x faster than left

;; ============================================
;; Variables in RAM
;; ============================================
        AREA    |.data|, DATA, READWRITE
SD_AVAILABLE    DCD     0               ; 1 if SD card initialized
IDLE_MODE       DCD     3               ; LED mode for idle (2=SD_OK, 3=NO_SD)

;; ============================================
;; Main program
;; ============================================
        AREA    |.text|, CODE, READONLY
__main
        ;; Initialize all hardware
        BL      MOTEUR_INIT
        BL      LED_INIT
        BL      BUMPER_INIT
        BL      BUTTON_INIT

        ;; Set LEDs to alternate mode at 100ms for SD card loading
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE
        MOV     R0, #100
        BL      LED_SET_PERIOD

        ;; Try to initialize SD card (with timeout - won't hang)
        BL      SD_Init
        CMP     R0, #1
        BNE     sd_not_available

        ;; SD card OK - write embedded dances to SD card
        BL      SD_WriteEmbeddedDances

        ;; Index dances (will find the ones we just wrote)
        BL      SD_IndexDances
        LDR     R0, =SD_AVAILABLE
        MOV     R1, #1
        STR     R1, [R0]

        ;; Restore default LED period after loading
        LDR     R0, =488
        BL      LED_SET_PERIOD

        ;; Set idle mode: right LED fixed ON, left blinks
        LDR     R0, =IDLE_MODE
        MOV     R1, #MODE_SD_OK
        STR     R1, [R0]
        MOV     R0, #MODE_SD_OK
        BL      LED_SET_MODE
        B       wait_input

sd_not_available
        LDR     R0, =SD_AVAILABLE
        MOV     R1, #0
        STR     R1, [R0]

        ;; Restore default LED period after loading
        LDR     R0, =488
        BL      LED_SET_PERIOD

        ;; Set idle mode: right LED blinks 2x faster than left
        LDR     R0, =IDLE_MODE
        MOV     R1, #MODE_NO_SD
        STR     R1, [R0]
        MOV     R0, #MODE_NO_SD
        BL      LED_SET_MODE

;; ============================================
;; Wait loop - wait for button or bumper
;; ============================================
wait_input
        LDR     R1, =0x1000
poll_delay
        SUBS    R1, #1
        BNE     poll_delay

        ;; Check bumper left - cycle LED speed
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     do_cycle_speed

        ;; Check bumper right - play SD card dance
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     do_sd_dance

        ;; Check button 1 (SW1) - ITALODISCO (swapped for test)
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     do_disco

        ;; Check button 2 (SW2) - VALSE (swapped for test)
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     do_valse

        B       wait_input

;; ============================================
;; Bumper left - cycle LED speed
;; ============================================
do_cycle_speed
        BL      LED_CYCLE_SPEED

wait_bumper_left_release
        BL      BUMPER_LEFT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_left_release

        BL      debounce_long
        B       wait_input

;; ============================================
;; Bumper right - play SD card dance
;; Hold bumper right, then press SW1 for dance 0 or SW2 for dance 1
;; Release bumper right without button → play default (dance 0)
;; ============================================
do_sd_dance
        MOV     R5, #0              ; Default to dance 0

        ;; Wait loop: check for SW1, SW2, or bumper release
wait_for_button_or_release
        ;; Check if SW1 pressed
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     got_dance_0

        ;; Check if SW2 pressed
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     got_dance_1

        ;; Check if bumper still held
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     wait_for_button_or_release  ; Still held, keep waiting

        ;; Bumper released without button → do nothing, go back
        BL      debounce_long
        B       wait_input

got_dance_0
        MOV     R5, #0
        B       wait_bumper_release_then_play

got_dance_1
        MOV     R5, #1

wait_bumper_release_then_play
        ;; Wait for bumper to be released
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_release_then_play

play_selected_dance
        BL      debounce_long

        ;; Check if SD card is available
        LDR     R0, =SD_AVAILABLE
        LDR     R0, [R0]
        CMP     R0, #1
        BNE     wait_input          ; no SD card, ignore

        ;; Set LED mode to alternate for dancing
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        ;; Play selected dance from SD card
        MOV     R0, R5              ; Get dance index from R5
        BL      SD_ReadSector

        ;; Back to idle mode
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

;; ============================================
;; Button 1 - VALSE (hardcoded)
;; ============================================
do_valse
wait_btn1_release
        BL      BUTTON1_PRESSED
        CMP     R0, #1
        BEQ     wait_btn1_release

        BL      debounce

        ;; Set LED mode to alternate for dancing
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        ;; Play VALSE
        BL      VALSE

        ;; Back to idle mode
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

;; ============================================
;; Button 2 - ITALODISCO (hardcoded)
;; ============================================
do_disco
wait_btn2_release
        BL      BUTTON2_PRESSED
        CMP     R0, #1
        BEQ     wait_btn2_release

        BL      debounce

        ;; Set LED mode to alternate for dancing
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        ;; Play ITALODISCO
        BL      ITALODISCO

        ;; Back to idle mode
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

;; ============================================
;; Debounce delays
;; ============================================
debounce
        PUSH    {R1, LR}
        LDR     R1, =0x50000
deb_loop
        SUBS    R1, #1
        BNE     deb_loop
        POP     {R1, LR}
        BX      LR

debounce_long
        PUSH    {R1, LR}
        LDR     R1, =0x200000
deb_long_loop
        SUBS    R1, #1
        BNE     deb_long_loop
        POP     {R1, LR}
        BX      LR

        END
