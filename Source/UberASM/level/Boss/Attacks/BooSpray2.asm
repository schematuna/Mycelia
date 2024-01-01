;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spray a bunch of boos at once
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


!IntroAngle      = !MiscRam1

!IntroBooSpeed       = $20
!IntroNumShots       = $04
!IntroAngleDelta     = $20

BS2States: dw BS2Init
           dw BS2Main
           dw BS2End

BooSpray2:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (BS2States,x)
RTS

BS2Init:
        LDA #$34
        STA $!IntroAngle

        LDA #$25                                ;\ blarg roar
        STA $1DF9                               ;/ 

        INC $!SubPhase
RTS

BS2Main:

        LDA $!IntroAngle                        ;\
        CLC : ADC #!IntroAngleDelta             ;| update angle
        STA $!IntroAngle                        ;/
        STA $04                                 ;\
        LDA #!IntroBooSpeed                     ;|
        STA $0D                                 ;| shoot left boo
        LDX #$00                                ;|
        JSL ShootBooWithAngle                   ;/
        LDA #$FF
        SEC : SBC $!IntroAngle                  ;\
        STA $04                                 ;|
        LDA #!IntroBooSpeed                     ;|
        STA $0D                                 ;| shoot right boo
        LDX #$01                                ;|
        JSL ShootBooWithAngle                   ;/
        INC $!SubPhase2                         ;\ 
        LDA $!SubPhase2                         ;|
        CMP #!IntroNumShots                     ;| check if we've shot all the boos
        BNE .return                             ;/
        INC $!SubPhase
    .return
RTS

BS2End:
        JSL AttackEnded
RTS
