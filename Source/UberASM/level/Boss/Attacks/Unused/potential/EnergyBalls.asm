;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EnergyBalls
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!EBMarioXPos = !MiscRam1        ; 16-bit
!EBMarioYPos = !MiscRam3        ; 16-bit

EBStates: dw EBInit
          dw EBGrow
          dw EBFired

EnergyBalls:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (EBStates,x)
RTS

!EBFirebarLength        = $01
!EBAngleCoarseIncrement = $07
!EBAngleFineIncrement   = $FF

EBInit:
        REP #$20
        LDA $D1                         ;\
        STA $!EBMarioXPos               ;|
        LDA $D3                         ;| remember mario position for later use
        STA $!EBMarioYPos               ;/
        SEP #$20

        LDA #!EBFirebarLength           ;\
        STA $!ExtraByte1                ;| size
        STZ $!ExtraByte2                ;| speed 
        STZ $!ExtraByte3                ;| angle
        LDX #!LeftEyeSlot               ;|
        JSL SpawnFirebar                ;|
        STX $!SpriteSlot1               ;/

        LDA #!EBFirebarLength           ;\
        STA $!ExtraByte1                ;| size
        STZ $!ExtraByte2                ;| speed 
        LDA #$80                        ;|
        STA $!ExtraByte3                ;| angle
        LDX #!RightEyeSlot              ;|
        JSL SpawnFirebar                ;|
        STX $!SpriteSlot2               ;/

        INC $!SubPhase
RTS


EBGrow:
        LDX #!LeftEyeSlot               ;\
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        SBC $!EBMarioXPos               ;| get x offset between left eye and mario
        STA $00                         ;|
        SEP #$20                        ;/
        
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        SBC $!EBMarioYPos               ;| get y offset between left eye and mario
        STA $02                         ;|
        SEP #$20                        ;/

        LDA #$40
        JSL AimingRoutine

        LDX $!SpriteSlot1      
        LDA $00
        STA !sprite_speed_x,x  
        LDA $02
        STA !sprite_speed_y,x   

        LDX #!RightEyeSlot              ;\
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        SBC $!EBMarioXPos               ;| get x offset between right eye and mario
        STA $00                         ;|
        SEP #$20                        ;/
        
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        SBC $!EBMarioYPos               ;| get y offset between right eye and mario
        STA $02                         ;|
        SEP #$20                        ;/

        LDA #$40
        JSL AimingRoutine

        LDX $!SpriteSlot2       
        LDA $00
        STA !sprite_speed_x,x    
        LDA $02
        STA !sprite_speed_y,x     

        LDA #$50
        STA $!GlobalTimer

        INC $!SubPhase

    .Return
RTS

EBFired:
        LDX $!SpriteSlot1
        LDA $!FireBarAngleCoarse,x
        CLC : ADC #!EBAngleCoarseIncrement
        STA $!FireBarAngleCoarse,x
        LDA $!FireBarAngleFine,x
        CLC : ADC #!EBAngleFineIncrement
        STA $!FireBarAngleFine,x

        LDX $!SpriteSlot2
        LDA $!FireBarAngleCoarse,x
        CLC : ADC #!EBAngleCoarseIncrement
        STA $!FireBarAngleCoarse,x
        LDA $!FireBarAngleFine,x
        CLC : ADC #!EBAngleFineIncrement
        STA $!FireBarAngleFine,x

        LDA $!GlobalTimer
        BNE .Return

        LDX $!SpriteSlot1           ;\
        STZ !sprite_status,x        ;|
        LDX $!SpriteSlot2           ;| despawn lasers
        STZ !sprite_status,x        ;/

        STZ $!SubPhase
    .Return
RTS