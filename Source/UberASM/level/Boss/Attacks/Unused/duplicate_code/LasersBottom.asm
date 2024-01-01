;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Spin Firebars from bottom of screen
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


LBStates:       dw LBInit
                dw LBWaitForFrame
                dw LBToPosition
                dw LBSpawnLasers
                dw LBExtendLasers
                dw LBMain
                dw LBRetractLasers
                dw LBReturnToIdle
                dw LBEnd

!LBAccelDir     = !MiscRam1
!LBAccelDir2    = !MiscRam2
!SubPhase3      = !MiscRam3

LBAccels:
    db $01, $FF
LBMaxYSpeeds:
    db $1A, $E6

LasersBottom:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (LBStates,x)
RTS

LBInit:
        LDA #$01
        STA $!LBAccelDir
    
        STZ $!SubPhase3
    
        INC $!SubPhase
RTS

; Ensure consistent frame parity for next phase
LBWaitForFrame:
        LDA $14
        AND #$01
        BNE .return
        INC $!SubPhase
    .return
RTS

LBToPosition:
        LDA $14                     ;\ 
        AND #$01                    ;| Only update sprite oscillation every other frame, to keep it slow
        BEQ .wrap                   ;/
        LDA $!LBAccelDir            ;\ 
        AND #$01                    ;| Get our direction of acceleration (0 or 1)
        TAY                         ;/
        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LBAccels,y              ;|
        STA !sprite_speed_y,x       ;|
        LDX #!RightEyeSlot          ;|  Update the eyes' speed based on that 
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LBAccels,y              ;|
        STA !sprite_speed_y,x       ;/
        CMP LBMaxYSpeeds,y          ;\ 
        BNE .wrap                   ;| If at max speed, reverse the direction of acceleration
        INC $!LBAccelDir            ;/

    .wrap
        LDX #!LeftEyeSlot
        LDA !sprite_y_high,x
        BNE .checkSpeed
        LDA #$01
        STA !sprite_y_high,x
        LDX #!RightEyeSlot
        STA !sprite_y_high,x

    .checkSpeed
        LDX #!LeftEyeSlot
        LDA !sprite_speed_y,x
        BNE .return
        INC $!SubPhase
    .return
RTS

LBSpawnLasers:
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

LBDeltasLeft:
    db $34,$88,$A8,$88,$36
LBDeltasRight:
    db $42,$96,$A8,$96,$44
LBTableSize:

LBExtendLasers:
        LDA $14                                 ;\ 
        AND #$0F                                ;| Only increase length every 16th frame
        BNE .return                             ;/

        LDX $!SpriteSlot1       
        INC $!FireBarLength,x       
        
        LDX $!SpriteSlot2       
        INC $!FireBarLength,x       
        
        LDA $!FireBarLength,x       
        CMP #$06                            
        BNE .return       

        LDA #$40                            ;\
        STA $!GlobalTimer3                  ;/ set time until left eye starts moving
     
        LDA #$C0
        LDX $!SpriteSlot1 
        STA $!FireBarSpeed,x

        STZ $!LBAccelDir
        STZ $!LBAccelDir2
        INC $!SubPhase  
    .return  
RTS


LBMain:
    .checkAccelTimer
        LDA $14                                 ;\ 
        AND #$01                                ;| Only update speeds every other frame
        BEQ .updateFirebarPositions             ;/
        LDA $!GlobalTimer
        BNE .moveLeft
        LDA $!SubPhase2
        CMP.b #LBDeltasRight-LBDeltasLeft
        BNE .setTimerLeft
        LDX #!LeftEyeSlot
        STZ !sprite_speed_x,x
        BRA .handleRight

    .setTimerLeft
        LDX $!SubPhase2
        LDA LBDeltasLeft,x
        STA $!GlobalTimer
        INC $!LBAccelDir
        INC $!SubPhase2

    .moveLeft
        LDA $!LBAccelDir
        AND #$01
        TAY
        LDX #!LeftEyeSlot
        LDA !sprite_speed_x,x
        CLC : ADC LBAccels,y
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
        CMP.b #LBTableSize-LBDeltasRight
        BNE .setTimerRight
        LDX #!RightEyeSlot
        STZ !sprite_speed_x,x
        INC $!SubPhase
        BRA .updateFirebarPositions

    .setTimerRight 
        LDX $!SubPhase3
        LDA LBDeltasRight,x
        STA $!GlobalTimer2
        INC $!LBAccelDir2
        INC $!SubPhase3

    .moveRight
        LDA $!LBAccelDir2
        AND #$01
        TAY
        LDX #!RightEyeSlot
        LDA !sprite_speed_x,x
        CLC : ADC LBAccels,y
        STA !sprite_speed_x,x

    .updateFirebarPositions
        JSL UpdateFirebarPositions
RTS

LBRetractLasers:
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

        STZ $!LBAccelDir

        INC $!SubPhase  
    .return   
RTS

LBReturnToIdle:
        LDA $14                     ;\ 
        AND #$01                    ;| Only update sprite oscillation every other frame, to keep it slow
        BEQ .wrap                   ;/
        LDA $!LBAccelDir            ;\ 
        AND #$01                    ;| Get our direction of acceleration (0 or 1)
        TAY                         ;/
        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LBAccels,y              ;|
        STA !sprite_speed_y,x       ;|
        LDX #!RightEyeSlot          ;|  Update the eyes' speed based on that 
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC LBAccels,y              ;|
        STA !sprite_speed_y,x       ;/
        CMP LBMaxYSpeeds,y          ;\ 
        BNE .wrap                   ;| If at max speed, reverse the direction of acceleration
        INC $!LBAccelDir            ;/

    .wrap
        LDX #!LeftEyeSlot
        LDA !sprite_y_high,x
        BEQ .checkSpeed
        LDA #$01
        STA !sprite_y_high,x
        LDX #!RightEyeSlot
        STA !sprite_y_high,x

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

LBEnd:
    JSL AttackEnded
RTS