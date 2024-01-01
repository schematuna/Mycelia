;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 4 - CircleBooRings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CBRStates: dw SpawnCBRs
           dw MoveCBRs
           dw DespawnCBRs

CircleBooRings:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (CBRStates,x)
RTS

SpawnCBRs:
        LDA #$01
        STA $!SpriteState
        LDA #$2A
        STA $!SpriteNumber
        LDA #$7A
        STA $!XLo
        LDA #$01
        STA $!XHi
        LDA #$20
        STA $!YLo
        LDA #$01
        STA $!YHi
        LDA #$0A
        STA $!ExtraByte1
        LDA #$33
        STA $!ExtraByte2
        LDA #$00
        STA $!ExtraByte3
        LDA #$10
        STA $!ExtraByte4
        STZ $!YSpeed
        LDA #$00
        STA $!XSpeed
        LDA #$0C
        STA $!ExtraBits

        JSL SpawnCustomSprite       ; spawn a sprite
        STX $!SpriteSlot1

        INC $!SubPhase
RTS

; provide all target positions, including starting position
CBRXLo:
    db $7A,$00,$F0,$7A
CBRXHi:
    db $01,$01,$01,$01
CBRYLo:
    db $20,$60,$60,$20
CBRYHi:
    db $01,$01,$01,$01
CBRGrowthDirection:
    db $01,$01,$01,$FF

!CBRTableSize = $04

!MaxRadius = $60

MoveCBRs:
        ; grow or shrink boo ring as specified
        LDX $!SpriteSlot1   
        LDA !187B,x                     ; boo ring asm internal radius memory
        LDX $!SubPhase2 
        CLC 
        ADC CBRGrowthDirection,x    
        CMP #$00                        ;\ check if minimally small
        BEQ +                           ;|
        CMP #!MaxRadius                 ;| or maximally large
        BEQ +                           ;/
        LDX $!SpriteSlot1   
        STA !187B,x     
    +   
    
        LDX $!SubPhase2                 ;\
        LDA CBRXLo,x                    ;| check if boo ring has reached specified x-position
        STA $00                         ;|
        LDA CBRXHi,x                    ;|
        STA $01                         ;|
        LDX $!SpriteSlot1               ;| sprite slot of boo ring
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        CMP $00                         ;|
        SEP #$20                        ;/
        BNE .Return 
    
        INC $!SubPhase2                 ; increment movement phase
    
        LDA $!SubPhase2                 ;\
        CMP #!CBRTableSize              ;| check if we're done moving
        BCC +                           ;|
        INC $!SubPhase                  ;| if we are, increment subphase to end laser attack
        STZ $!SubPhase2                 ;/ reinitialize subphase2
        BRA .Return                     ; and skip updates
    +

        LDX $!SubPhase2                 ;\
        LDA CBRXLo,x                    ;|
        STA $00                         ;|
        LDA CBRXHi,x                    ;|
        STA $01                         ;| set boo ring moving towards next destination
        LDA CBRYLo,x                    ;|
        STA $02                         ;|
        LDA CBRYHi,x                    ;|
        STA $03                         ;|
        LDA #$18                        ;|
        STA $04                         ;|
        LDX $!SpriteSlot1               ;|
        JSL SetSpriteSpeedTowardPoint   ;/

        LDX $!SpriteSlot1               ;\
        LDA !sprite_speed_y,x           ;| 
        LDX #!LeftEyeSlot               ;|
        STA !sprite_speed_y,x           ;| 
        LDX #!RightEyeSlot              ;|
        STA !sprite_speed_y,x           ;| set eyes speeds to match boo ring speeds
        LDX $!SpriteSlot1               ;|
        LDA !sprite_speed_x,x           ;| 
        LDX #!LeftEyeSlot               ;|
        STA !sprite_speed_x,x           ;|
        LDX #!RightEyeSlot              ;|
        STA !sprite_speed_x,x           ;/
    
    .Return 
RTS 
    
DespawnCBRs:    
        LDX $!SpriteSlot1               ;\
        STZ !sprite_status,x            ;/ despawn boo ring   
        JSL AttackEnded
RTS