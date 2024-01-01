;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spray boos while sweeping
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!BSAngle      = !MiscRam1
!BSVariant    = !MiscRam2
!BSPhase      = !MiscRam3

!BSBooSpeed       = $20
!BSNumShots       = $06
!BSFireInterval   = $06

BSAngleIncrements:
db $E8,$18
BSInitialAngles:
db $D0,$30

BSStates: dw BSInit
          dw BSMain
          dw BSEnd

BooSpray:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (BSStates,x)
RTS

BSInit:
        STZ $!BSPhase

        LDA #$01
        JSL Random
        STA $!BSVariant

        TAX
        LDA BSInitialAngles,x
        STA $!BSAngle

        INC $!SubPhase
RTS

BSMain:
        LDA $!GlobalTimer
        BNE .return

        LDA $!BSAngle                       ;\ update left angle
        LDX $!BSVariant                     ;|
        CLC : ADC BSAngleIncrements,x       ;|
        STA $!BSAngle                       ;|
        STA $04                             ;|
        LDA #!BSBooSpeed                    ;|
        STA $0D                             ;|
        JSL ShootBooWithAngle               ;/ and shoot a boo

        INC $!SubPhase2                     ;\ 
        LDA $!SubPhase2                     ;|
        CMP #!BSNumShots                    ;| check if current eye's shots are over
        BNE +                               ;/
        LDA $!BSPhase                       ;\
        BEQ ++                              ;| check if we've done both eyes
        INC $!SubPhase                      ;|
        BRA .return                         ;/
    ++
        STZ $!SubPhase2                     ;\
        LDA $!BSVariant                     ;|
        EOR #$01                            ;| switch to other eye shooting
        STA $!BSVariant                     ;|
        INC $!BSPhase                       ;/
        LDA #!BSFireInterval                ;\
        ASL #2                              ;| longer pause when switching eyes
        STA $!GlobalTimer                   ;/ 
        BRA .return
    +
        LDA #!BSFireInterval 
        STA $!GlobalTimer
    .return
RTS

BSEnd:
        JSL AttackEnded
RTS
