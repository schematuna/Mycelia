;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Death Bat Ceiling (uses modify death bat gfx patch)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DBCStates: dw DBCInit
           dw DBCMain

DeathBatCeiling:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (DBCStates,x)
RTS

DBCInit:
        LDX #$E4
        JSL InitSpecialSprite

        LDX #$0E
    -
        LDA $1E02,x                     ;\ cluster y low byte
        CLC : ADC #$30                  ;| move bats up a bit... actually should just set absolute position here
        STA $1E02,x                     ;/
        DEX
        BPL -

        INC $!SubPhase
RTS

DBCMain:

RTS