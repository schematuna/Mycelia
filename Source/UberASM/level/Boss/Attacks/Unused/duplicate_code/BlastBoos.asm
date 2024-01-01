;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First attack - blast a bunch of boos!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!BBAngle      = !MiscRam1

!BBBooSpeed       = $20
!BBNumShots       = $06
!BBAngleDelta     = $18


BBStates: dw BBInit
          dw BBMain
          dw BBEnd

BlastBoos:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (BBStates,x)
RTS

BBInit:
        LDA #$30
        STA $!BBAngle

        LDA #$25                                ;\ blarg roar
        STA $1DF9                               ;/ 

        INC $!SubPhase
RTS

BBMain:
        LDA $!BBAngle                           ;\
        CLC : ADC #!BBAngleDelta                ;| update angle
        STA $!BBAngle                           ;/
        STA $04                                 ;\
        LDA #!BBBooSpeed                        ;|
        STA $0D                                 ;| shoot left boo
        LDX #$00                                ;|
        JSL ShootBooWithAngle                   ;/
        LDA $!BBAngle                           ;\
        STA $04                                 ;|
        LDA #!BBBooSpeed                        ;|
        STA $0D                                 ;| shoot right boo
        LDX #$01                                ;|
        JSL ShootBooWithAngle                   ;/
        INC $!SubPhase2                         ;\ 
        LDA $!SubPhase2                         ;|
        CMP #!BBNumShots                        ;| check if we've shot all the boos
        BNE +                                   ;|
        INC $!SubPhase                          ;/
    +
RTS

BBEnd:
        JSL AttackEnded
RTS
