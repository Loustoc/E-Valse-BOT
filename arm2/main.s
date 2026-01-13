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

        ;; Try to initialize SD card (with timeout - won't hang)
        BL      SD_Init
        CMP     R0, #1
        BNE     sd_not_available

        ;; SD card OK - index dances
        BL      SD_IndexDances
        LDR     R0, =SD_AVAILABLE
        MOV     R1, #1
        STR     R1, [R0]

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
;; ============================================
do_sd_dance
wait_bumper_right_release
        BL      BUMPER_RIGHT_PRESSED
        CMP     R0, #1
        BEQ     wait_bumper_right_release

        BL      debounce_long

        ;; Check if SD card is available
        LDR     R0, =SD_AVAILABLE
        LDR     R0, [R0]
        CMP     R0, #1
        BNE     wait_input          ; no SD card, ignore

        ;; Set LED mode to alternate for dancing
        MOV     R0, #MODE_ALTERNATE
        BL      LED_SET_MODE

        ;; Play first dance from SD card (index 0)
        MOV     R0, #0
        BL      SD_ReadSector

        ;; Back to idle mode
        LDR     R0, =IDLE_MODE
        LDR     R0, [R0]
        BL      LED_SET_MODE
        B       wait_input

;; ============================================
;; Button 1 - VALSE
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
;; Button 2 - ITALODISCO
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
