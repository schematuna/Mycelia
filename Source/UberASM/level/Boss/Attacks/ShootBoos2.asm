;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shooting boos in from the sides
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SB2BooSpeed = $20
!SB2FireInterval = $30 

!SB2Variant = !MiscRam1

SB2States:      dw SB2Init
                dw SB2ToLocation
                dw SB2Main
                dw SB2Return
                dw SB2End


ShootBoos2:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SB2States,x)
RTS

SB2Init:
        LDA #!MyceliaXLoLeft            ;\ 
        SEC : SBC #$50                  ;|
        STA $00                         ;| x lo
        LDA $!MyceliaXHi                ;|
        SBC #$00                        ;|
        STA $01                         ;| x hi
        LDA #$A4                        ;| 
        STA $02                         ;| y lo
        LDA #$01                        ;|
        STA $03                         ;| y hi
        LDA #$20                        ;|
        STA $04                         ;| speed
        LDX #!LeftEyeSlot               ;|
        JSL SetSpriteSpeedTowardPoint   ;/

        LDA #!MyceliaXLoRight           ;\ 
        CLC : ADC #$50                  ;|
        STA $00                         ;| x lo
        LDA $!MyceliaXHi                ;|
        ADC #$00                        ;|
        STA $01                         ;| x hi
        LDA #$A4                        ;| 
        STA $02                         ;| y lo
        LDA #$01                        ;|
        STA $03                         ;| y hi
        LDA #$20                        ;|
        STA $04                         ;| speed
        LDX #!RightEyeSlot              ;|
        JSL SetSpriteSpeedTowardPoint   ;/

        LDA #$01
        JSL Random
        STA $!SB2Variant

        INC $!SubPhase
RTS

SB2ToLocation:
        LDA #!MyceliaXLoLeft            ;\ check if eyes have reached target x position
        SEC : SBC #$50                  ;|
        STA $00                         ;|
        LDA $!MyceliaXHi                ;|
        SBC #$00                        ;|
        STA $01                         ;|
        LDX #!LeftEyeSlot               ;| use left eye position to determine if we should stop
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        CMP $00                         ;|
        SEP #$20                        ;/
        BCS .return

        LDX #!LeftEyeSlot
        STZ !sprite_speed_y,x
        STZ !sprite_speed_x,x

        LDX #!RightEyeSlot
        STZ !sprite_speed_y,x
        STZ !sprite_speed_x,x

        LDX #$00
        LDA SB2Deltas,x
        STA $!GlobalTimer2

        INC $!SubPhase

    .return
RTS

SB2Deltas:
db $01,$12,$12,$B8,$1A,$1A,$C0,$13,$13
SB2Accelerations:
db $00,$01,$FF,$00,$FF,$01,$00,$01,$FF
SB2TableSize:

SB2Main:
        LDA $!GlobalTimer2
        BNE +
        INC $!SubPhase2
        LDA $!SubPhase2
        CMP.b #SB2TableSize-SB2Accelerations    ; check if this attack is over
        BNE ++
        INC $!SubPhase
        BRA .return
    ++
        LDX $!SubPhase2
        LDA SB2Deltas,x
        STA $!GlobalTimer2
    +

        ; apply acceleration to eye y speeds
        LDX #!LeftEyeSlot
        LDY $!SubPhase2
        LDA $!SB2Variant
        BEQ .variant1
        LDA SB2Accelerations,y
        BRA .updateSpeed1
    .variant1
        LDA SB2Accelerations,y
        EOR #$FF : INC
    .updateSpeed1
        CLC : ADC !sprite_speed_y,x
        STA !sprite_speed_y,x

        LDX #!RightEyeSlot
        LDY $!SubPhase2
        LDA $!SB2Variant
        BNE .variant2
        LDA SB2Accelerations,y
        BRA .updateSpeed2
    .variant2
        LDA SB2Accelerations,y
        EOR #$FF : INC
    .updateSpeed2
        CLC : ADC !sprite_speed_y,x
        STA !sprite_speed_y,x

        LDX $!SubPhase2                 ;\
        LDA SB2Accelerations,x          ;| don't shoot while eyes are changing position
        BNE .return                     ;/

        ; while shooting boos inwards
        LDA $!GlobalTimer
        BNE .return

        LDA #!SB2BooSpeed
        STA $04
        STZ $0D
        LDX #!LeftEyeSlot
        JSL ShootBooWithSpeeds

        LDA #!SB2BooSpeed
        EOR #$FF
        STA $04
        STZ $0D
        LDX #!RightEyeSlot
        JSL ShootBooWithSpeeds

        LDA #!SB2FireInterval
        STA $!GlobalTimer
    .return
RTS

SB2Return:
        LDA #!MyceliaXLoLeft            ;\
        STA $00                         ;|
        LDA $!MyceliaXHi                ;|
        STA $01                         ;| put left eye idle position in scratch for subroutine
        LDA #!MyceliaYLo                ;| 
        STA $02                         ;|
        LDA #!MyceliaYHi                ;|
        STA $03                         ;/
        LDA #$20
        STA $04 
        LDX #!LeftEyeSlot
        JSL SetSpriteSpeedTowardPoint

        LDA #!MyceliaXLoRight           ;\
        STA $00                         ;| 
        LDA $!MyceliaXHi                ;|
        STA $01                         ;| put right eye idle position in scratch for subroutine
        LDA #!MyceliaYLo                ;| 
        STA $02                         ;| 
        LDA #!MyceliaYHi                ;|
        STA $03                         ;/
        LDA #$20
        STA $04 
        LDX #!RightEyeSlot
        JSL SetSpriteSpeedTowardPoint

        INC $!SubPhase
RTS

SB2End:
        LDA #!MyceliaYLo                ;\ check if eyes have reached target y position
        STA $00                         ;|
        LDA #!MyceliaYHi                ;|
        STA $01                         ;|
        LDX #!LeftEyeSlot               ;| use left eye position to determine if we should stop
        LDA !sprite_y_high,x            ;|
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        CMP $00                         ;|
        SEP #$20                        ;/
        BCS .return 
        JSL AttackEnded
    .return
RTS