;; BUMPER.S - Bumper inputs (polling mode)
;; PE0 = Right bumper (free)
;; PE1 = Left bumper (LED speed control)
;; Active LOW (pressed = 0)

        AREA    |.text|, CODE, READONLY

SYSCTL_RCGC2    EQU     0x400FE108
GPIO_PORTE      EQU     0x40024000
BUMPER_RIGHT    EQU     0x01            ; PE0
BUMPER_LEFT     EQU     0x02            ; PE1
BUMPER_BOTH     EQU     0x03

        EXPORT  BUMPER_INIT
        EXPORT  BUMPER_LEFT_PRESSED
        EXPORT  BUMPER_RIGHT_PRESSED

;; ============================================
;; BUMPER_INIT - Configure PE0/PE1 as inputs
;; ============================================
BUMPER_INIT
        PUSH    {R0-R1, LR}
        
        ; Enable clock Port E
        LDR     R0, =SYSCTL_RCGC2
        LDR     R1, [R0]
        ORR     R1, R1, #0x10
        STR     R1, [R0]
        NOP
        NOP
        NOP
        
        LDR     R0, =GPIO_PORTE
        
        ; PE0, PE1 as input (DIR = 0)
        LDR     R1, [R0, #0x400]
        BIC     R1, R1, #BUMPER_BOTH
        STR     R1, [R0, #0x400]
        
        ; Pull-up enabled
        LDR     R1, [R0, #0x510]
        ORR     R1, R1, #BUMPER_BOTH
        STR     R1, [R0, #0x510]
        
        ; Digital enable
        LDR     R1, [R0, #0x51C]
        ORR     R1, R1, #BUMPER_BOTH
        STR     R1, [R0, #0x51C]
        
        POP     {R0-R1, LR}
        BX      LR

;; ============================================
;; BUMPER_LEFT_PRESSED
;; Returns: R0 = 1 if pressed, 0 if not
;; ============================================
BUMPER_LEFT_PRESSED
        LDR     R0, =GPIO_PORTE
        LDR     R0, [R0, #0x3FC]
        TST     R0, #BUMPER_LEFT
        BEQ     left_yes
        MOV     R0, #0
        BX      LR
left_yes
        MOV     R0, #1
        BX      LR

;; ============================================
;; BUMPER_RIGHT_PRESSED
;; Returns: R0 = 1 if pressed, 0 if not
;; ============================================
BUMPER_RIGHT_PRESSED
        LDR     R0, =GPIO_PORTE
        LDR     R0, [R0, #0x3FC]
        TST     R0, #BUMPER_RIGHT
        BEQ     right_yes
        MOV     R0, #0
        BX      LR
right_yes
        MOV     R0, #1
        BX      LR

        END