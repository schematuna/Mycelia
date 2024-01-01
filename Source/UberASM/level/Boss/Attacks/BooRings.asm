;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Boo Rings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!BRVariant = !MiscRam1

BRStates:  dw BRInit
           dw BRAttack
           dw BRMoveEyesUp
           dw BREnd

BooRings:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (BRStates,x)
RTS

BRAttackSpeeds:
        db $1A,$E6 
BREyeSlots:
        db !LeftEyeSlot,!RightEyeSlot

BRInit:
        LDA #!MyceliaXLoLeft            ;\ check if eyes have reached target x position
        SEC : SBC #$B0                  ;|
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
        LDA #$74                        ;|
        STA !sprite_y_low,x             ;|
        LDA #$01                        ;|
        STA !sprite_y_high,x            ;| move eyes to lower y position
        LDX #!RightEyeSlot              ;|
        LDA #$74                        ;|
        STA !sprite_y_low,x             ;|
        LDA #$01                        ;|
        STA !sprite_y_high,x            ;/

        LDA #$01                        ;\ 
        JSL Random                      ;| randomly choose which side starts
        STA $!BRVariant                 ;/ 
        TAY
        LDX BREyeSlots,y
        PHY
        JSR SpawnBooRingsOnEye
        PLY
        LDY $!BRVariant                 ;\
        LDA BRAttackSpeeds,y            ;|
        LDX BREyeSlots,y                ;|
        STA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot1               ;| set first eye and rings moving back inwards
        STA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot2               ;|
        STA !sprite_speed_x,x           ;/

        LDA #$E0                        ;\ set time until second eye comes in
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

BRAttack:
        LDA $!GlobalTimer
        BNE .return

        LDX $!SpriteSlot2               ;\
        STZ !sprite_status,x            ;| despawn previous inner boo ring to open up a sprite slot

        LDA $!BRVariant
        EOR #$01
        TAY
        LDX BREyeSlots,y
        PHY
        JSR SpawnBooRingsOnEye
        PLY
        LDA BRAttackSpeeds,y            ;\
        LDX BREyeSlots,y                ;|
        STA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot1               ;| set other eye and rings moving inwards
        STA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot2               ;|
        STA !sprite_speed_x,x           ;/

        REP #$20
        LDA #$0120                      ;\ set time until attack ends
        STA $!GlobalTimer               ;/
        SEP #$20

        INC $!SubPhase
    .return
RTS

BRMoveEyesUp:
        REP #$20
        LDA $!GlobalTimer
        SEP #$20
        BNE +
        LDX $!SpriteSlot1               ;\
        STZ !sprite_status,x            ;| ensure boo rings are despawned
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

BREnd:
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

; Input:
; Eye slot in X
; Output:
; SpriteSlot1/2 set
SpawnBooRingsOnEye:
        LDA #$01
        STA $!SpriteState
        LDA #$2A
        STA $!SpriteNumber
        LDA !sprite_x_low,x
        STA $!XLo
        LDA !sprite_x_high,x
        STA $!XHi
        LDA !sprite_y_low,x 
        SEC : SBC #$04                  ; offset to center ring around eye
        STA $!YLo
        LDA !sprite_y_high,x
        STA $!YHi
        LDA #$09
        STA $!ExtraByte1
        LDA #$39
        STA $!ExtraByte2
        LDA #$50
        STA $!ExtraByte3
        LDA #$2C
        STA $!ExtraByte4
        STZ $!YSpeed
        LDA #$00
        STA $!XSpeed
        CPX #!LeftEyeSlot               ;\
        BEQ +                           ;| 
        LDA #$0C                        ;|
        BRA ++                          ;| set rotation direction based on eye slot
    +                                   ;|
        LDA #$08                        ;|
    ++                                  ;|
        STA $!ExtraBits                 ;/

        %preserve_scratch()

        JSL SpawnCustomSprite       ; spawn a sprite
        STX $!SpriteSlot1

        %restore_scratch()

        LDA #$09
        STA $!ExtraByte1
        LDA #$39
        STA $!ExtraByte2
        LDA #$30
        STA $!ExtraByte3
        LDA #$2C
        STA $!ExtraByte4

        JSL SpawnCustomSprite       ; spawn a sprite
        STX $!SpriteSlot2
RTS