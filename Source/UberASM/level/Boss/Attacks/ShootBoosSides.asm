;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Eyes shoot boos down from the sides
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SBSBooSpeed           = $48
!SBSFireInterval       = $18
SBSBooAngles:
db $50,$B0

!SBSVariant            = !MiscRam1

SBSStates:   dw SBSInit
             dw SBSAttack
             dw SBSMoveEyesUp
             dw SBSEnd

ShootBoosSides:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SBSStates,x)
RTS

SBSAttackSpeeds:
        db $18,$E8 
SBSEyeSlots:
        db !LeftEyeSlot,!RightEyeSlot

SBSInit:
        LDA #!MyceliaXLoLeft            ;\ check if eyes have reached target y position
        SEC : SBC #$80                  ;|
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
        BCS .accel
        LDX #!LeftEyeSlot               ;\
        STZ !sprite_speed_x,x           ;| zero eyes x speed
        LDX #!RightEyeSlot              ;|
        STZ !sprite_speed_x,x           ;/

        LDX #!LeftEyeSlot               ;\
        LDA #$60                        ;|
        STA !sprite_y_low,x             ;|
        LDA #$01                        ;|
        STA !sprite_y_high,x            ;| move eyes to lower y position
        LDX #!RightEyeSlot              ;|
        LDA #$60                        ;|
        STA !sprite_y_low,x             ;|
        LDA #$01                        ;|
        STA !sprite_y_high,x            ;/

        LDA #$01                        ;\ 
        JSL Random                      ;| randomly choose which side starts
        STA $!SBSVariant                ;/ 
        TAY                             ;\
        LDA SBSAttackSpeeds,y           ;|
        LDX SBSEyeSlots,y               ;| set first eye moving back inwards
        STA !sprite_speed_x,x           ;/

        LDA #$C0                        ;\ set time until second eye comes in
        STA $!GlobalTimer               ;/

        INC $!SubPhase
        BRA .return
    .accel
        LDX #!LeftEyeSlot               ;\
        DEC !sprite_speed_x,x           ;| accelerate eyes in opposite directions
        LDX #!RightEyeSlot              ;|
        INC !sprite_speed_x,x           ;/

    .return
RTS

SBSAttack:
        LDX $!SBSVariant
        JSR SBSShootBoo

        LDA $!GlobalTimer
        BNE .return

        LDA $!SBSVariant
        EOR #$01
        TAY
        LDA SBSAttackSpeeds,y           ;\
        LDX SBSEyeSlots,y               ;| set other eye moving inwards
        STA !sprite_speed_x,x           ;/

        REP #$20
        LDA #$00E0                      ;\ set time until attack ends
        STA $!GlobalTimer               ;/
        SEP #$20

        INC $!SubPhase
    .return
RTS

SBSMoveEyesUp:
        LDA $!SBSVariant
        EOR #$01
        TAX
        JSR SBSShootBoo

        REP #$20
        LDA $!GlobalTimer
        SEP #$20
        BNE +

        LDX #!LeftEyeSlot               ;\
        LDA #!MyceliaYLo                ;|
        STA !sprite_y_low,x             ;|
        LDA #!MyceliaYHi                ;|
        STA !sprite_y_high,x            ;|
        LDA #!MyceliaXLoLeft            ;|
        CLC : ADC #$B0                  ;|
        STA !sprite_x_low,x             ;|
        LDA $!MyceliaXHi                ;|
        ADC #$00                        ;|
        STA !sprite_x_high,x            ;| move eyes to upper position
        LDX #!RightEyeSlot              ;|
        LDA #!MyceliaYLo                ;|
        STA !sprite_y_low,x             ;|
        LDA #!MyceliaYHi                ;|
        STA !sprite_y_high,x            ;|
        LDA #!MyceliaXLoRight           ;|
        SEC : SBC #$B0                  ;|
        STA !sprite_x_low,x             ;|
        LDA $!MyceliaXHi                ;|
        SBC #$00                        ;|
        STA !sprite_x_high,x            ;/

        LDA #$B4                        ;\
        LDX #!LeftEyeSlot               ;|
        STA !sprite_speed_x,x           ;| start eyes moving inwards
        LDA #$4C                        ;|
        LDX #!RightEyeSlot              ;|
        STA !sprite_speed_x,x           ;/

        INC $!SubPhase
    +
RTS

SBSEnd:
        LDA #!MyceliaXLoLeft            ;\ check if eyes have reached target x position
        STA $00                         ;|
        LDA $!MyceliaXHi                ;|
        STA $01                         ;|
        LDX #!LeftEyeSlot               ;| use left eye position to determine if we should stop
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        CMP $00                         ;|
        SEP #$20                        ;/
        BCS +
        JSL AttackEnded
        BRA .Return

    +
        LDX #!LeftEyeSlot               ;\
        INC !sprite_speed_x,x           ;| decelerate eyes
        LDX #!RightEyeSlot              ;|
        DEC !sprite_speed_x,x           ;/
    .Return
RTS

; Eye no. in X
SBSShootBoo:
        LDA $!GlobalTimer2
        BNE +

        LDA SBSAttackSpeeds,x
        STA $04
        LDA #!SBSBooSpeed
        STA $0D
        JSL ShootBooWithSpeeds

        LDA #!SBSFireInterval
        STA $!GlobalTimer2
    +
RTS