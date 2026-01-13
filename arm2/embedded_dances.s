;; embedded_dances.s - Combined binary dance file included in flash
;; These dances are written to SD card on every boot

        AREA EMBEDDED_DANCES, DATA, READONLY

        EXPORT EMBEDDED_DANCES_BASE

;; Combined dance file - 2048 bytes total
;; Valse: bytes 0-1023 (sectors 0-1)
;; Italodisco: bytes 1024-2047 (sectors 2-3)
EMBEDDED_DANCES_BASE
        INCBIN ..\tests\SD\choreo_all.bin

        END
