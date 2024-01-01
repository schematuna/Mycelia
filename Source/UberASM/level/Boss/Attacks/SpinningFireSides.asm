;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spinning Fire from side
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SFSVariant = !MiscRam1

SFSStates:  dw SFSInit
            dw SFSAttack
            dw SFSMoveEyesUp
            dw SFSEnd

SpinningFireSides:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SFSStates,x)
RTS

SFSAttackSpeeds:
        db $16,$EA 
SFSEyeSlots:
        db !LeftEyeSlot,!RightEyeSlot
SFSFirebarSpeeds:
        db $E8,$E8

!SFSFirebarLength = $06
!SFSFirebarAngle  = $40

SFSInit:
        LDA #!MyceliaXLoLeft            ;\ check if eyes have reached target x position
        SEC : SBC #$A8                  ;|
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
        LDA #$A0                        ;|
        STA !sprite_y_low,x             ;|
        LDA #$01                        ;|
        STA !sprite_y_high,x            ;| move eyes to lower y position
        LDX #!RightEyeSlot              ;|
        LDA #$A0                        ;|
        STA !sprite_y_low,x             ;|
        LDA #$01                        ;|
        STA !sprite_y_high,x            ;/

        LDA #$01                        ;\ 
        JSL Random                      ;| randomly choose which side starts
        STA $!SFSVariant                ;/ 
        TAY
        LDA #!SFSFirebarLength          ;\
        STA $!ExtraByte1                ;| and length (bits 0-4)
        LDA SFSFirebarSpeeds,y          ;|
        STA $!ExtraByte2                ;| set up firebar speed (bits 0-6)
        LDA #!SFSFirebarAngle           ;| initial angle
        STA $!ExtraByte3                ;/
        LDX SFSEyeSlots,y               ;\
        JSL SpawnFirebar                ;| for first firebar
        STX $!SpriteSlot1               ;/

        LDY $!SFSVariant                ;\
        LDA SFSAttackSpeeds,y           ;| 
        LDX SFSEyeSlots,y               ;| set first eye and firebar moving back inwards
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

SFSAttack:
        LDA $!GlobalTimer
        BNE .return

        LDA $!SFSVariant
        EOR #$01
        TAY
        LDA #!SFSFirebarLength          ;\
        STA $!ExtraByte1                ;| and length (bits 0-4)
        LDA SFSFirebarSpeeds,y          ;|
        STA $!ExtraByte2                ;| set up firebar speed (bits 0-6)
        LDA #!SFSFirebarAngle           ;| initial angle
        STA $!ExtraByte3                ;/
        PHY                             ;\
        LDX SFSEyeSlots,y               ;|
        JSL SpawnFirebar                ;| for second firebar
        STX $!SpriteSlot2               ;|
        PLY                             ;/

        LDA SFSAttackSpeeds,y           ;\
        LDX SFSEyeSlots,y               ;|
        STA !sprite_speed_x,x           ;| set other eye and firebar moving inwards
        LDX $!SpriteSlot2               ;|
        STA !sprite_speed_x,x           ;/

        REP #$20
        LDA #$0120                      ;\ set time until attack ends
        STA $!GlobalTimer               ;/
        SEP #$20

        INC $!SubPhase
    .return
RTS

SFSMoveEyesUp:
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

SFSEnd:
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
