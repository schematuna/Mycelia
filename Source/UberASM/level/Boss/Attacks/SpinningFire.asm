;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 5 - Spinning Fire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


!SFEyesAngle = !MiscRam1              ; 16-bit general purpose angle for circular motion
!SFAccelDir  = !MiscRam3              ; Stores acceleration direction for oscillation movement patterns
!SFSpeed     = !MiscRam4              ; General purpose speed memory for attacks and such

!SFCenterYLo = $78
!SFCenterYHi = $01
!SFCenterXLo = $78
!SFCenterXHi = !MyceliaXHi
!SFRadius = $28

SFStates: dw SFInit
          dw SFStartingPosition
          dw SFSpin
          dw SFEndingPosition
          dw SFEnd

SpinningFire:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SFStates,x)
RTS

SFInit:
        LDX #!LeftEyeSlot                   ;\
        LDA #$80                            ;|
        STA $!ExtraByte3                    ;|
        STZ $!ExtraByte1                    ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot1                   ;/

        LDX #!RightEyeSlot                  ;\
        STZ $!ExtraByte3                    ;|
        STZ $!ExtraByte1                    ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot2                   ;/

        ;;;;;;;;;;;;;;;;;;;;;;
        ; SET INITIAL SPEEDS ;
        ;;;;;;;;;;;;;;;;;;;;;;

        ;;; Left eye and firebar ;;;

        LDA #!SFCenterXLo           ;\
        SEC : SBC #!SFRadius        ;|
        STA $00                     ;| calculate left point of circle
        LDA $!MyceliaXHi            ;|
        SBC #$00                    ;|
        STA $01                     ;|
        LDA #!SFCenterYLo           ;| 
        STA $02                     ;| and stick in scratch for subroutine
        LDA #!SFCenterYHi           ;|
        STA $03                     ;/
        LDA #$18
        STA $04 
        LDX #!LeftEyeSlot
        JSL SetSpriteSpeedTowardPoint

        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;| 
        LDX $!SpriteSlot1           ;|
        STA !sprite_speed_y,x       ;| match firebar speed to eye speed
        LDX #!LeftEyeSlot           ;|
        LDA !sprite_speed_x,x       ;|
        LDX $!SpriteSlot1           ;|
        STA !sprite_speed_x,x       ;/ 


        ;;; Right eye and firebar ;;;

        LDA #!SFCenterXLo           ;\
        CLC : ADC #!SFRadius        ;|
        STA $00                     ;| calculate right point of circle
        LDA $!MyceliaXHi            ;|
        ADC #$00                    ;|
        STA $01                     ;|
        LDA #!SFCenterYLo           ;| 
        STA $02                     ;| and stick in scratch for subroutine
        LDA #!SFCenterYHi           ;|
        STA $03                     ;/
        LDA #$18
        STA $04 
        LDX #!RightEyeSlot
        JSL SetSpriteSpeedTowardPoint

        LDX #!RightEyeSlot          ;\
        LDA !sprite_speed_y,x       ;| 
        LDX $!SpriteSlot2           ;|
        STA !sprite_speed_y,x       ;| match firebar speed to eye speed
        LDX #!RightEyeSlot          ;|
        LDA !sprite_speed_x,x       ;|
        LDX $!SpriteSlot2           ;|
        STA !sprite_speed_x,x       ;/ 

        INC $!SubPhase
RTS

SFStartingPosition:
        LDX $!SpriteSlot1
        LDA $!FireBarLength,x       ;\ grow firebars
        CMP #$0D                    ;| 13 is the limit without running out of sprite tiles
        BEQ +                       ;|
        INC $!FireBarLength,x       ;|
        LDX $!SpriteSlot2           ;|
        INC $!FireBarLength,x       ;/
    +

        LDA #!SFCenterYLo           ;\ check if eyes have reached target y position
        STA $00                     ;|
        LDA #!SFCenterYHi           ;|
        STA $01                     ;|
        LDX #!LeftEyeSlot           ;| use left eye position to determine if we should stop
        LDA !sprite_y_high,x        ;|
        XBA                         ;|
        LDA !sprite_y_low,x         ;|
        REP #$20                    ;|
        CMP $00                     ;|
        SEP #$20                    ;/
        BCC .Return

        LDX $!SpriteSlot1           ;\
        STZ !sprite_speed_x,x       ;|
        STZ !sprite_speed_y,x       ;|
        LDX $!SpriteSlot2           ;|
        STZ !sprite_speed_x,x       ;| 
        STZ !sprite_speed_y,x       ;| zero all speeds
        LDX #!LeftEyeSlot           ;|
        STZ !sprite_speed_x,x       ;|
        STZ !sprite_speed_y,x       ;|
        LDX #!RightEyeSlot          ;|
        STZ !sprite_speed_x,x       ;|
        STZ !sprite_speed_y,x       ;/ 

        REP #$20
        STZ $!SFEyesAngle
        SEP #$20

        STZ $!SFAccelDir
        STZ $!SFSpeed

        INC $!SubPhase
    .Return
RTS


SFAccelerations:
db $01, $FF
SFMaxSpeeds:
db $50, $B0

SFSpin:
        LDA $!SFAccelDir                ;\
        CMP #$02                        ;| check if we're done moving
        BNE +                           ;|
        REP #$20                        ;| 
        LDA $!SFEyesAngle               ;| check if angle in expected final position
        CMP #$0000                      ;|
        SEP #$20                        ;|
        BNE +                           ;|
        INC $!SubPhase                  ;| if we are, increment subphase to end laser attack
        JMP .Return                     ;/ and skip updates
    +

        REP #$20                        ;\
        LDA $!SFEyesAngle               ;| 
        LSR #4                          ;| shift right 4 to remove fraction accumulation bits
        STA $04                         ;| store angle for subroutine
        SEP #$20                        ;/

        LDA #!SFRadius
        STA $06                         ; radius for subroutine

        JSL CircleX
        JSL CircleY

        LDA #!SFCenterXLo               ;\ add returned offset to center position
        CLC : ADC $07                   ;| 
        LDX #!RightEyeSlot              ;|
        STA !sprite_x_low,x             ;| and store to right eye position
        LDA $!MyceliaXHi                ;|
        ADC $08                         ;|
        STA !sprite_x_high,x            ;/

        LDA #!SFCenterXLo               ;\
        SEC : SBC $07                   ;| 
        LDX #!LeftEyeSlot               ;|
        STA !sprite_x_low,x             ;| store to left eye position
        LDA $!MyceliaXHi                ;|
        SBC $08                         ;|
        STA !sprite_x_high,x            ;/

        LDA #!SFCenterYLo               ;\ add returned offset to center position
        CLC : ADC $09                   ;| 
        LDX #!RightEyeSlot              ;|
        STA !sprite_y_low,x             ;| and store to right eye position
        LDA #!SFCenterYHi               ;|
        ADC $0A                         ;|
        STA !sprite_y_high,x            ;/

        LDA #!SFCenterYLo               ;\
        SEC : SBC $09                   ;| 
        LDX #!LeftEyeSlot               ;|
        STA !sprite_y_low,x             ;| store to left eye position
        LDA #!SFCenterYHi               ;|
        SBC $0A                         ;|
        STA !sprite_y_high,x            ;/

        JSL UpdateFirebarPositions

        LDA $14                         ;\ 
        AND #$01                        ;| Only update speed every other frame, for slower acceleration
        BEQ +                           ;/
        LDA $!SFAccelDir                ;\ 
        AND #$01                        ;| Get our direction of acceleration (0 or 1)
        TAX                             ;/
        LDA $!SFSpeed
        CLC : ADC SFAccelerations,x
        STA $!SFSpeed
        CMP SFMaxSpeeds,x               ;\ 
        BNE +                           ;| If at max speed, reverse the direction of acceleration
        INC $!SFAccelDir                ;/
    +

        LDA $!SFSpeed                   ;\
        STA $00                         ;|
        BMI .minus                      ;|
        STZ $01                         ;|
        BRA +                           ;|
    .minus                              ;|
        LDA #$FF                        ;| for negative speed values, we need high byte to be FF
        STA $01                         ;| so 16-bit math works out
    +                                   ;|
        REP #$20                        ;| Increment angle by current speed
        LDA $!SFEyesAngle               ;|
        CLC : ADC $00                   ;|
        STA $!SFEyesAngle               ;|
        STA $00                         ;|
        SEP #$20                        ;/

        LDX $!SpriteSlot1               ;\
        LDA $00                         ;|
        STA $!FireBarAngleFine,x        ;| directly set firebar angles
        LDA $01                         ;|
        CLC : ADC #$10                  ;| add 10 to invert angle for left firebar
        STA $!FireBarAngleCoarse,x      ;| 
        LDX $!SpriteSlot2               ;|
        LDA $00                         ;|
        STA $!FireBarAngleFine,x        ;|
        LDA $01                         ;|
        STA $!FireBarAngleCoarse,x      ;/         
    .Return
RTS

SFEndingPosition:
        ;;; Left eye and firebar ;;;

        LDA #!MyceliaXLoLeft            ;\
        CLC : ADC #$02                  ;| have to adjust to make movement actually look right
        STA $00                         ;|
        LDA $!MyceliaXHi                ;|
        STA $01                         ;| put left eye idle position in scratch for subroutine
        LDA #!MyceliaYLo                ;| 
        STA $02                         ;|
        LDA #!MyceliaYHi                ;|
        STA $03                         ;/
        LDA #$18
        STA $04 
        LDX #!LeftEyeSlot
        JSL SetSpriteSpeedTowardPoint

        LDX #!LeftEyeSlot               ;\
        LDA !sprite_speed_y,x           ;| 
        LDX $!SpriteSlot1               ;|
        STA !sprite_speed_y,x           ;| match firebar speed to eye speed
        LDX #!LeftEyeSlot               ;|
        LDA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot1               ;|
        STA !sprite_speed_x,x           ;/ 

        ;;; Right eye and firebar ;;;

        LDA #!MyceliaXLoRight           ;\
        SEC : SBC #$02                  ;| have to adjust to make movement actually look right
        STA $00                         ;| 
        LDA $!MyceliaXHi                ;|
        STA $01                         ;| put right eye idle position in scratch for subroutine
        LDA #!MyceliaYLo                ;| 
        STA $02                         ;| 
        LDA #!MyceliaYHi                ;|
        STA $03                         ;/
        LDA #$18
        STA $04 
        LDX #!RightEyeSlot
        JSL SetSpriteSpeedTowardPoint

        LDX #!RightEyeSlot              ;\
        LDA !sprite_speed_y,x           ;| 
        LDX $!SpriteSlot2               ;|
        STA !sprite_speed_y,x           ;| match firebar speed to eye speed
        LDX #!RightEyeSlot              ;|
        LDA !sprite_speed_x,x           ;|
        LDX $!SpriteSlot2               ;|
        STA !sprite_speed_x,x           ;/ 

        INC $!SubPhase
RTS

SFEnd:
        LDX $!SpriteSlot1               ;\
        LDA $!FireBarLength,x           ;|  
        BEQ .Shrunk                     ;| skip shrinking if they're already length zero
        DEC $!FireBarLength,x           ;| 
        LDX $!SpriteSlot2               ;| shrink firebars
        DEC $!FireBarLength,x           ;/
        BRA +   
    .Shrunk 
        LDX $!SpriteSlot1               ;\
        LDA !sprite_status,x            ;| check if firebars have already been despawned
        BEQ +                           ;| if not...
        STZ !sprite_status,x            ;| despawn them
        LDX $!SpriteSlot2               ;| 
        STZ !sprite_status,x            ;/
    +   
    
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
        BCS .Return 
    
        LDX $!SpriteSlot1               ;\
        STZ !sprite_speed_x,x           ;|
        STZ !sprite_speed_y,x           ;|
        LDX $!SpriteSlot2               ;|
        STZ !sprite_speed_x,x           ;| 
        STZ !sprite_speed_y,x           ;| zero all speeds
        LDX #!LeftEyeSlot               ;|
        STZ !sprite_speed_x,x           ;|
        STZ !sprite_speed_y,x           ;|
        LDX #!RightEyeSlot              ;|
        STZ !sprite_speed_x,x           ;|
        STZ !sprite_speed_y,x           ;/ 
    
        REP #$20    
        STZ $!SFEyesAngle 
        SEP #$20    
        STZ $!SFSpeed 
    
        JSL AttackEnded
    .Return
RTS