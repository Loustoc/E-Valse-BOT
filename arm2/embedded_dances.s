; embedded_dances.s - fichier binaire des danses inclus dans le flash
; ces danses sont ecrites sur la carte SD au demarrage

        AREA EMBEDDED_DANCES, DATA, READONLY

        EXPORT EMBEDDED_DANCES_BASE

; fichier combine - 2048 bytes au total
; valse: bytes 0-1023 (secteurs 0-1)
; italodisco: bytes 1024-2047 (secteurs 2-3)
EMBEDDED_DANCES_BASE
        INCBIN ..\tests\SD\choreo_all.bin

        END
