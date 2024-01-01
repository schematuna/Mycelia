;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Make mario move in a Figure 8 pattern
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!F8Angle1  = !MiscRam1 ; 2 bytes
!F8Angle2  = !MiscRam3 ; 2 bytes
!F8Speed1  = !MiscRam5
!F8Speed2  = !MiscRam7
!F8Variant = !MiscRam9

!F8CenterYLo = $A0
!F8CenterYHi = $01

F8States: dw F8Init
          dw F8StartingPosition
          dw F8Main
          dw F8RetractLasers
          dw F8EndingPosition
          dw F8End

Figure8:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (F8States,x)
RTS

F8Init:
        LDA #$01                            ;\ num attacks-1
        JSL Random                          ;| run random subroutine
        STA $!F8Variant                     ;/ remember attack number

        LDA #$78                            ;\
        XBA                                 ;|
        LDA #$00                            ;|
        REP #$20                            ;|
        STA $!LasersAngle1                  ;| store 16-bit angles for future modulation
        SEP #$20                            ;|
        XBA                                 ;|
        LDX #!LeftEyeSlot                   ;|
        STA $!ExtraByte3                    ;|
        STZ $!ExtraByte1                    ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot1                   ;/

        LDA #$90                            ;\
        XBA                                 ;|
        LDA #$00                            ;|
        REP #$20                            ;|
        STA $!LasersAngle2                  ;|
        SEP #$20                            ;|
        XBA                                 ;|
        LDX #!RightEyeSlot                  ;\
        STA $!ExtraByte3                    ;|
        STZ $!ExtraByte1                    ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot2                   ;/

        ;;;;;;;;;;;;;;;;;;;;;;
        ; SET INITIAL SPEEDS ;
        ;;;;;;;;;;;;;;;;;;;;;;

        ;;; Left eye and firebar ;;;
        LDA #!MyceliaXLoLeft            ;\
        SEC : SBC #$10                  ;|
        STA $00                         ;|
        LDA $!MyceliaXHi                ;|
        SBC #$00                        ;|
        STA $01                         ;|
        LDA #!F8CenterYLo               ;| 
        STA $02                         ;| stick position in scratch for subroutine
        LDA #!F8CenterYHi               ;|
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
        CLC : ADC #$10                  ;|
        STA $00                         ;|
        LDA $!MyceliaXHi                ;|
        ADC #$00                        ;|
        STA $01                         ;|
        LDA #!F8CenterYLo               ;| 
        STA $02                         ;| stick position in scratch for subroutine
        LDA #!F8CenterYHi               ;|
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

F8StartingPosition:
        LDX $!SpriteSlot1
        LDA $!FireBarLength,x           ;\ grow firebars
        CMP #$13                        ;| 13 is the limit without running out of sprite tiles
        BEQ +                           ;|
        INC $!FireBarLength,x           ;|
        LDX $!SpriteSlot2               ;|
        INC $!FireBarLength,x           ;/
    +   
    
        LDA #!F8CenterYLo               ;\ check if eyes have reached target y position
        STA $00                         ;|
        LDA #!F8CenterYHi               ;|
        STA $01                         ;|
        LDX #!LeftEyeSlot               ;| use left eye position to determine if we should stop
        LDA !sprite_y_high,x            ;|
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        CMP $00                         ;|
        SEP #$20                        ;/
        BCC .Return 
    
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
        STZ $!F8Speed1
        STZ $!F8Speed2
        SEP #$20

        INC $!SubPhase
    .Return
RTS

; first values get skipped I guess
F8Accels:
    db $01, $03,$02,$01,$01,$FF,$FF,$FE
F8Deltas:
    db $F0, $10,$40,$A0,$A0,$A0,$A0,$20
F8TableSize:
    
F8Main: 
        LDA $!GlobalTimer                   ;\ 
        BNE +                               ;/ if timer is 0...
    
        INC $!SubPhase2                     ; increment movement phase
        
        LDA $!SubPhase2                     ;\
        CMP.b #F8TableSize-F8Deltas         ;| check if we're done moving
        BCC ++                              ;|
        INC $!SubPhase                      ;| if we are, increment subphase to end attack
        STZ $!SubPhase2                     ;| reinitialize subphase2
        JMP .Return                         ;/ and skip updates
    ++      
        LDX $!SubPhase2                     ;\
        LDA F8Deltas,x                      ;| get next time value
        STA $!GlobalTimer                   ;/ update timer to new value
    +   

        LDX $!SubPhase2                     ;\
        LDA $!F8Variant                     ;|
        BNE +                               ;|
        LDA F8Accels,x                      ;| get current acceleration
        EOR #$FF                            ;| accounting for mirrored attack variation
        INC                                 ;|
        BRA ++                              ;|
    +                                       ;|
        LDA F8Accels,x                      ;/
    ++
        STA $00                             ;
        BPL +                               ;\ if accel is negative
        LDA #$FF                            ;/ make sure the high bit will be FF in 16-bit mode
        STA $01                             ;
        BRA ++                              ;
    +                                       ;
        STZ $01                             ; otherwise it should be zero
    ++                                      ;
        REP #$20                            ;
        LDA $!F8Speed1                      ;\
        CLC : ADC $00                       ;| add accel to speed
        STA $!F8Speed1                      ;/
        CLC : ADC $!F8Angle1                ;\ add speed to angle
        STA $!F8Angle1                      ;|
        LSR #3                              ;| lower precision for firebars (remove the 3 bits of headroom)
        STA $00                             ;|
        SEP #$20                            ;/
    
        LDX $!SpriteSlot1                   ;\
        LDA $00                             ;| set firebar angle directly
        STA $!FireBarAngleFine,x            ;|
        LDA $01                             ;|
        STA $!FireBarAngleCoarse,x          ;/    


        LDX $!SubPhase2                     ;\
        LDA $!F8Variant                     ;|
        BNE +                               ;| get current acceleration
        LDA F8Accels,x                      ;| accounting for mirrored attack variation
        BRA ++                              ;|
    +                                       ;|
        LDA F8Accels,x                      ;/ get current acceleration
        EOR #$FF                            ;|
        INC                                 ;|
    ++
        STA $00                             ;
        BPL +                               ;\ if accel is negative
        LDA #$FF                            ;/ make sure the high bit will be FF in 16-bit mode
        STA $01                             ;
        BRA ++                              ;
    +                                       ;
        STZ $01                             ; otherwise it should be zero
    ++                                      ;
        REP #$20                            ;
        LDA $!F8Speed2                      ;\
        CLC : ADC $00                       ;| add accel to speed
        STA $!F8Speed2                      ;/
        CLC : ADC $!F8Angle2                ;\ add speed to angle
        STA $!F8Angle2                      ;|
        LSR #3                              ;| lower precision for firebars (remove the 3 bits of headroom)
        STA $00                             ;|
        SEP #$20                            ;/
    
        LDX $!SpriteSlot2                   ;\
        LDA $00                             ;| set firebar angle directly
        STA $!FireBarAngleFine,x            ;|
        LDA $01                             ;|
        STA $!FireBarAngleCoarse,x          ;/    

    .Return 
RTS 

F8RetractLasers:  
        LDX $!SpriteSlot1   
        DEC $!FireBarLength,x   
    
        LDX $!SpriteSlot2   
        DEC $!FireBarLength,x   
    
        LDA $!FireBarLength,x   
        CMP #$00    
        BNE +   

        LDX $!SpriteSlot1                   ;\
        STZ !sprite_status,x                ;|
        LDX $!SpriteSlot2                   ;| despawn lasers
        STZ !sprite_status,x                ;/

        INC $!SubPhase  
    +   
RTS 

F8EndingPosition:
        ;;; Left eye and firebar ;;;

        LDA #!MyceliaXLoLeft                ;\
        STA $00                             ;|
        LDA $!MyceliaXHi                    ;|
        STA $01                             ;| put left eye idle position in scratch for subroutine
        LDA #!MyceliaYLo                    ;| 
        STA $02                             ;|
        LDA #!MyceliaYHi                    ;|
        STA $03                             ;/
        LDA #$18    
        STA $04     
        LDX #!LeftEyeSlot   
        JSL SetSpriteSpeedTowardPoint   
    
        LDX #!LeftEyeSlot                   ;\
        LDA !sprite_speed_y,x               ;| 
        LDX #!LeftEyeSlot                   ;|
        LDA !sprite_speed_x,x               ;/

    
        ;;; Right eye and firebar ;;;   
    
        LDA #!MyceliaXLoRight               ;\
        STA $00                             ;| 
        LDA $!MyceliaXHi                    ;|
        STA $01                             ;| put right eye idle position in scratch for subroutine
        LDA #!MyceliaYLo                    ;| 
        STA $02                             ;| 
        LDA #!MyceliaYHi                    ;|
        STA $03                             ;/
        LDA #$18    
        STA $04     
        LDX #!RightEyeSlot  
        JSL SetSpriteSpeedTowardPoint   
    
        LDX #!RightEyeSlot                  ;\
        LDA !sprite_speed_y,x               ;| 
        LDX #!RightEyeSlot                  ;|
        LDA !sprite_speed_x,x               ;/
    
        INC $!SubPhase  
RTS 
    
F8End:          
        LDA #!MyceliaYLo                    ;\ check if eyes have reached target y position
        STA $00                             ;|
        LDA #!MyceliaYHi                    ;|
        STA $01                             ;|
        LDX #!LeftEyeSlot                   ;| use left eye position to determine if we should stop
        LDA !sprite_y_high,x                ;|
        XBA                                 ;|
        LDA !sprite_y_low,x                 ;|
        REP #$20                            ;|
        CMP $00                             ;|
        SEP #$20                            ;/
        BCS .Return     
                
        JSL AttackEnded
    .Return
RTS