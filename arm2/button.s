;; BUTTON.S - SW1 (PD6) and SW2 (PD7) inputs
;; Active LOW (pressed = 0)

        AREA    |.text|, CODE, READONLY, ALIGN=2

SYSCTL_RCGC2    EQU     0x400FE108
GPIO_PORTD      EQU     0x40007000
SW1_PIN         EQU     0x40            ; PD6
SW2_PIN         EQU     0x80            ; PD7
SW_BOTH         EQU     0xC0

        EXPORT  BUTTON_INIT
        EXPORT  BUTTON1_PRESSED
        EXPORT  BUTTON2_PRESSED

;; ============================================
;; BUTTON_INIT - Configure PD6/PD7 as inputs
;; ============================================
BUTTON_INIT
        PUSH    {R0-R1, LR}
        
        ; Enable clock Port D
        LDR     R1, =SYSCTL_RCGC2
        LDR     R0, [R1]
        ORR     R0, R0, #0x08
        STR     R0, [R1]
        NOP
        NOP
        NOP
        
        LDR     R1, =GPIO_PORTD

        ; Clear alternate function (use as GPIO)
        LDR     R0, [R1, #0x420]
        BIC     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x420]

        ; PD6, PD7 as input (DIR = 0)
        LDR     R0, [R1, #0x400]
        BIC     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x400]

        ; Pull-up enabled
        LDR     R0, [R1, #0x510]
        ORR     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x510]

        ; Digital enable
        LDR     R0, [R1, #0x51C]
        ORR     R0, R0, #SW_BOTH
        STR     R0, [R1, #0x51C]
        
        POP     {R0-R1, LR}
        BX      LR

;; ============================================
;; BUTTON1_PRESSED (SW1 = PD6)
;; Returns: R0 = 1 if pressed, 0 if not
;; ============================================
BUTTON1_PRESSED
        LDR     R0, =GPIO_PORTD
        LDR     R0, [R0, #0x3FC]
        TST     R0, #SW1_PIN
        BEQ     btn1_yes
        MOV     R0, #0
        BX      LR
btn1_yes
        MOV     R0, #1
        BX      LR

;; ============================================
;; BUTTON2_PRESSED (SW2 = PD7)
;; Returns: R0 = 1 if pressed, 0 if not
;; ============================================
BUTTON2_PRESSED
        LDR     R0, =GPIO_PORTD
        LDR     R0, [R0, #0x3FC]
        TST     R0, #SW2_PIN
        BEQ     btn2_yes
        MOV     R0, #0
        BX      LR
btn2_yes
        MOV     R0, #1
        BX      LR

        END