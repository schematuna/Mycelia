;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Oscillating fire from side
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!FOVariant = !MiscRam1

FOStates:   dw FOInit
            dw FOAttack
            dw FOMoveEyesUp
            dw FOEnd

FirebarOsc:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (FOStates,x)
RTS

FOAttackSpeeds:
        db $18,$E8 
FOEyeSlots:
        db !LeftEyeSlot,!RightEyeSlot

FOInit:
        LDA #$D0                        ;\ check if eyes have reached target x position
        STA $00                         ;|
        LDA #$00                        ;|
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
        STA $!FOVariant                 ;/ 
        TAY
        LDX FOEyeSlots,y
        STZ $!ExtraByte1
        STZ $!ExtraByte2
        LDA #$40
        STA $!ExtraByte3
        JSL SpawnFirebar
        STX $!SpriteSlot1
        LDY $!FOVariant                 ;\
        LDA FOAttackSpeeds,y            ;|
        LDX FOEyeSlots,y                ;| set first eye and firebar moving back inwards
        STA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot1               ;|
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

FOAttack:
        LDX $!SpriteSlot1
        JSL OscLength

        LDA $!GlobalTimer
        BNE .return

        LDA $!FOVariant
        EOR #$01
        TAY
        LDX FOEyeSlots,y
        STZ $!ExtraByte1
        STZ $!ExtraByte2
        LDA #$40
        STA $!ExtraByte3
        PHY
        JSL SpawnFirebar
        STX $!SpriteSlot2
        PLY
        LDA FOAttackSpeeds,y            ;\
        LDX FOEyeSlots,y                ;|
        STA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot2               ;| set other eye and firebar moving inwards
        STA !sprite_speed_x,x           ;/

        REP #$20
        LDA #$00E0                      ;\ set time until attack ends
        STA $!GlobalTimer               ;/
        SEP #$20

        INC $!SubPhase
    .return
RTS

FOMoveEyesUp:
        LDX $!SpriteSlot1
        JSL OscLength
        LDX $!SpriteSlot2
        JSL OscLength

        REP #$20
        LDA $!GlobalTimer
        SEP #$20
        BNE +
        LDX $!SpriteSlot1               ;\
        STZ !sprite_status,x            ;| ensure firebars are despawned
        LDX $!SpriteSlot2               ;|
        STZ !sprite_status,x            ;/

        LDX #!LeftEyeSlot               ;\
        LDA #!MyceliaYLo                ;|
        STA !sprite_y_low,x             ;|
        LDA #!MyceliaYHi                ;|
        STA !sprite_y_high,x            ;|
        LDA #$10                        ;|
        STA !sprite_x_low,x             ;|
        LDA #$02                        ;|
        STA !sprite_x_high,x            ;| move eyes to upper position
        LDX #!RightEyeSlot              ;|
        LDA #!MyceliaYLo                ;|
        STA !sprite_y_low,x             ;|
        LDA #!MyceliaYHi                ;|
        STA !sprite_y_high,x            ;|
        LDA #$E0                        ;|
        STA !sprite_x_low,x             ;|
        LDA #$00                        ;|
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

FOEnd:
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
