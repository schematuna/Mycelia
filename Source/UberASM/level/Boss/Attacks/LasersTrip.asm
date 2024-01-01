;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spin Firebars moving along ground
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


LTStates:       dw LTInit
                dw LTWaitForFrame
                dw LTToPosition
                dw LTPrepareMain
                dw LTMain
                dw LTRetractLasers
                dw LTReturnToIdle
                dw LTEnd

!LTAccelDir     = !MiscRam1
!LTAccelDir2    = !MiscRam2
!SubPhase3      = !MiscRam3

LTAccels:
    db $01, $FF
LTMaxYSpeeds:
    db $1B, $E5

LasersTrip:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (LTStates,x)
RTS

LTInit:
        LDA #$01
        STA $!LTAccelDir
    
        STZ $!SubPhase3

        ; spawn lasers
        LDX #!LeftEyeSlot                   ;\
        LDA #$78                            ;|
        STA $!ExtraByte3                    ;| initial angle
        STZ $!ExtraByte1                    ;|
        LDA #$70                            ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot1                   ;/

        LDX #!RightEyeSlot                  ;\
        LDA #$08                            ;|
        STA $!ExtraByte3                    ;| initial angle
        STZ $!ExtraByte1                    ;|
        LDA #$70                            ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot2                   ;/
    
        INC $!SubPhase
RTS

; Ensure consistent frame parity for next phase
LTWaitForFrame:
        LDA $14
        AND #$01
        BNE .return
        INC $!SubPhase
    .return
RTS

LTToPosition:
        JSL UpdateFirebarPositions

        LDA $14                                 ;\ 
        AND #$07                                ;| increase length slowly
        BNE .dontgrow                           ;/

        LDX $!SpriteSlot1     
        LDA $!FireBarLength,x       
        CMP #$06        
        BEQ .dontgrow  

        INC $!FireBarLength,x       
        
        LDX $!SpriteSlot2       
        INC $!FireBarLength,x   
    .dontgrow    


        LDA $14                     ;\ 
        AND #$01                    ;| Only update sprite oscillation every other frame, to keep it slow
        BEQ .wrap                   ;/
        LDA $!LTAccelDir            ;\ 
        AND #$01                    ;| Get our direction of acceleration (0 or 1)
        TAY                         ;/
        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LTAccels,y              ;|
        STA !sprite_speed_y,x       ;|
        LDX #!RightEyeSlot          ;|  Update the eyes' speed based on that 
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LTAccels,y              ;|
        STA !sprite_speed_y,x       ;/
        CMP LTMaxYSpeeds,y          ;\ 
        BNE .wrap                   ;| If at max speed, reverse the direction of acceleration
        INC $!LTAccelDir            ;/

    .wrap
        LDX #!LeftEyeSlot
        LDA !sprite_y_high,x
        BNE .checkSpeed
        LDA #$10
        STA !sprite_x_low,x
        LDA #$01
        STA !sprite_y_high,x
        LDX #!RightEyeSlot
        LDA #$E0
        STA !sprite_x_low,x
        LDA #$01
        STA !sprite_y_high,x

    .checkSpeed
        LDX #!LeftEyeSlot
        LDA !sprite_speed_y,x
        BNE .return
        INC $!SubPhase
    .return
RTS

LTDeltasLeft:
    db $50,$A0,$50
LTDeltasRight:
    db $50,$A0,$50
LTTableSize:

LTPrepareMain:            
        LDA #$40                            ;\
        STA $!GlobalTimer3                  ;/ set time until left eye starts moving
     
        LDA #$C0
        LDX $!SpriteSlot1 
        STA $!FireBarSpeed,x

        LDA #$01
        STA $!LTAccelDir
        STZ $!LTAccelDir2
        INC $!SubPhase  
    .return  
RTS


LTMain:
    .checkAccelTimer
        LDA $14                                 ;\ 
        AND #$01                                ;| Only update speeds every other frame
        BEQ .updateFirebarPositions             ;/
        LDA $!GlobalTimer
        BNE .moveLeft
        LDA $!SubPhase2
        CMP.b #LTDeltasRight-LTDeltasLeft
        BNE .setTimerLeft
        LDX #!LeftEyeSlot
        STZ !sprite_speed_x,x
        BRA .handleRight

    .setTimerLeft
        LDX $!SubPhase2
        LDA LTDeltasLeft,x
        STA $!GlobalTimer
        INC $!LTAccelDir
        INC $!SubPhase2

    .moveLeft
        LDA $!LTAccelDir
        AND #$01
        TAY
        LDX #!LeftEyeSlot
        LDA !sprite_speed_x,x
        CLC : ADC LTAccels,y
        STA !sprite_speed_x,x

        LDA $!GlobalTimer3
        BNE .updateFirebarPositions

        LDA #$40
        LDX $!SpriteSlot2 
        STA $!FireBarSpeed,x

    .handleRight
        LDA $!GlobalTimer2
        BNE .moveRight
        LDA $!SubPhase3
        CMP.b #LTTableSize-LTDeltasRight
        BNE .setTimerRight
        LDX #!RightEyeSlot
        STZ !sprite_speed_x,x
        INC $!SubPhase
        BRA .updateFirebarPositions

    .setTimerRight 
        LDX $!SubPhase3
        LDA LTDeltasRight,x
        STA $!GlobalTimer2
        INC $!LTAccelDir2
        INC $!SubPhase3

    .moveRight
        LDA $!LTAccelDir2
        AND #$01
        TAY
        LDX #!RightEyeSlot
        LDA !sprite_speed_x,x
        CLC : ADC LTAccels,y
        STA !sprite_speed_x,x

    .updateFirebarPositions
        JSL UpdateFirebarPositions
RTS

LTRetractLasers:
        LDA $14                         ;\ 
        AND #$01                        ;| Only decrease length every other frame
        BNE .return                     ;/

        LDX $!SpriteSlot1   
        DEC $!FireBarLength,x   
    
        LDX $!SpriteSlot2   
        DEC $!FireBarLength,x   
    
        LDA $!FireBarLength,x   
        CMP #$00    
        BNE .return   
        LDX $!SpriteSlot1                   ;\
        STZ !sprite_status,x                ;|
        LDX $!SpriteSlot2                   ;| despawn lasers
        STZ !sprite_status,x                ;/

        STZ $!LTAccelDir

        INC $!SubPhase  
    .return   
RTS

LTReturnToIdle:
        LDA $14                     ;\ 
        AND #$01                    ;| Only update sprite oscillation every other frame, to keep it slow
        BEQ .wrap                   ;/
        LDA $!LTAccelDir            ;\ 
        AND #$01                    ;| Get our direction of acceleration (0 or 1)
        TAY                         ;/
        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LTAccels,y              ;|
        STA !sprite_speed_y,x       ;|
        LDX #!RightEyeSlot          ;|  Update the eyes' speed based on that 
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LTAccels,y              ;|
        STA !sprite_speed_y,x       ;/
        CMP LTMaxYSpeeds,y          ;\ 
        BNE .wrap                   ;| If at max speed, reverse the direction of acceleration
        INC $!LTAccelDir            ;/

    .wrap
        LDX #!LeftEyeSlot
        LDA !sprite_y_high,x
        CMP #$01
        BEQ .checkSpeed
        LDA #$01
        STA !sprite_y_high,x
        LDA #!MyceliaXLoLeft
        STA !sprite_x_low,x
        LDX #!RightEyeSlot
        LDA #$01
        STA !sprite_y_high,x
        LDA #!MyceliaXLoRight
        STA !sprite_x_low,x

    .checkSpeed
        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;|
        BNE .return                 ;| ensure eye is not moving, and at top of screen
        LDA !sprite_y_low,x         ;|
        CMP #$80                    ;/
        BCS .return 
        INC $!SubPhase
    .return
RTS

LTEnd:
    JSL AttackEnded
RTS