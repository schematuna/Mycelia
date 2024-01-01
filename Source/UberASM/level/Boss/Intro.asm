;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mycelia Intro Movement
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!IntroAngle      = !MiscRam1
!IntroPolarity   = !MiscRam2 

!IntroBooSpeed       = $20
!IntroNumShots       = $05
!IntroAngleDelta     = $18

IntroPhases:
        dw IntroInit
        dw IntroMoving
        ;dw IntroAttack 
        dw IntroEnd

Intro:
        LDA $!MainPhase2
        ASL A
        TAX
        JSR (IntroPhases,x)
RTS

IntroInit:
        LDA #!MyceliaXLoLeft
        SEC : SBC #$80
        LDX #!LeftEyeSlot
        STA !sprite_x_low,x
        LDA $!MyceliaXHi
        SBC #$00
        STA !sprite_x_high,x

        LDA #!MyceliaXLoRight
        CLC : ADC #$80
        LDX #!RightEyeSlot
        STA !sprite_x_low,x
        LDA $!MyceliaXHi
        ADC #$00
        STA !sprite_x_high,x

        LDA #$10
        LDX #!LeftEyeSlot
        STA !sprite_speed_x,x
        EOR #$FF
        INC
        LDX #!RightEyeSlot
        STA !sprite_speed_x,x

        INC $!MainPhase2
RTS

IntroMoving:
        LDA #!MyceliaXLoLeft                    ;\
        STA $00                                 ;|
        LDA $!MyceliaXHi                        ;|
        STA $01                                 ;|
        LDX #!LeftEyeSlot                       ;| wait for left eye to hit x position
        LDA !sprite_x_high,x                    ;|
        XBA                                     ;|
        LDA !sprite_x_low,x                     ;|  
        REP #$20                                ;|
        CMP $00                                 ;| check if eyes have reached idle position yet
        SEP #$20                                ;/
        BCC .return           

        JSL ResetMycelia

        LDA #$01
        JSL Random
        STA $!IntroPolarity 

        LDA #$38
        STA $!IntroAngle
        LDA $!IntroPolarity 
        BEQ +
        LDA #$D0
        STA $!IntroAngle
    +

        ;LDA #$25                                ;\ blarg roar
        ;STA $1DF9                               ;/ 

        INC $!MainPhase2
    .return           
RTS

; unused for now
IntroAttack:
        LDA $!IntroPolarity
        BNE +
        LDA $!IntroAngle                        ;\
        CLC : ADC #!IntroAngleDelta             ;| update angle
        BRA ++
     +
        LDA $!IntroAngle                        ;\
        SEC : SBC #!IntroAngleDelta             ;| update angle
     ++
        STA $!IntroAngle                        ;/
        STA $04                                 ;\
        LDA #!IntroBooSpeed                     ;|
        STA $0D                                 ;| shoot left boo
        LDX #$00                                ;|
        JSL ShootBooWithAngle                   ;/
        LDA $!IntroAngle                        ;\
        STA $04                                 ;|
        LDA #!IntroBooSpeed                     ;|
        STA $0D                                 ;| shoot right boo
        LDX #$01                                ;|
        JSL ShootBooWithAngle                   ;/
        INC $!SubPhase2                         ;\ 
        LDA $!SubPhase2                         ;|
        CMP #!IntroNumShots                     ;| check if we've shot all the boos
        BNE .return                             ;/
        INC $!MainPhase2
    .return
RTS

IntroEnd:
        JSL ResetMycelia                        ; reset eyes
        STZ $!MainPhase2                        ;\ reset state
        STZ $!SubPhase2                         ;/
        LDA #$60                                ;\
        STA $00                                 ;|
        STZ $01                                 ;| prepare for idle
        REP #$20                                ;| 
        LDA $00                                 ;|
        STA $!GlobalTimer                       ;|
        SEP #$20                                ;/

        LDA #$01                                ;\
        STA $!MainPhase                         ;/ go to phase 1
RTS