;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 1 - Lasers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!LasersAngle1  = !MiscRam1 ; 2 bytes
!LasersAngle2  = !MiscRam3 ; 2 bytes
!LasersSpeed1  = !MiscRam5
!LasersSpeed2  = !MiscRam7
!LasersVariant = !MiscRam9

Lasers:
        LDA $!SubPhase              
        JSL $0086DF
        dw InitMycelia
        dw MyceliaDescending
        dw InitLasers
        dw ExtendLasers
        dw MoveLasers
        dw RetractLasers
        dw EndLasers
        dw MyceliaAscending

    .Return
        RTS

InitMycelia:
        LDA #$10                            ;\
        LDX #!LeftEyeSlot                   ;|
        STA !sprite_speed_y,x               ;| set eyes downward speed
        LDX #!RightEyeSlot                  ;|
        STA !sprite_speed_y,x               ;/
            
        LDA #$01                            ;\ num attacks-1
        JSL Random                          ;| run random subroutine
        STA $!LasersVariant                 ;/ remember attack number
        
        INC $!SubPhase      
RTS     
        
MyceliaDescending:      
        LDX #!LeftEyeSlot                   ; use left eye as proxy for y position of both eyes
        LDA !sprite_y_high,x                ;\
        XBA                                 ;|
        LDA !sprite_y_low,x                 ;|  
        REP #$20                            ;|
        CMP #$014C                          ;| check if eyes have reached lower position yet
        SEP #$20                            ;/
        BCC +           
        LDX #!LeftEyeSlot                   ;\
        STZ !sprite_speed_y,x               ;|
        LDX #!RightEyeSlot                  ;| stop Mycelia moving
        STZ !sprite_speed_y,x               ;|
        INC $!SubPhase                      ;/ and progress to next state
    +           
RTS         
            
InitLasers:         
        LDA #$70                            ;\
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

        LDA #$10                            ;\
        XBA                                 ;|
        LDA #$00                            ;|
        REP #$20                            ;|
        STA $!LasersAngle2                  ;|
        SEP #$20                            ;|
        XBA                                 ;|
        LDX #!RightEyeSlot                  ;|
        STA $!ExtraByte3                    ;|
        STZ $!ExtraByte1                    ;|
        STZ $!ExtraByte2                    ;|
        JSL SpawnFirebar                    ;|
        STX $!SpriteSlot2                   ;/
        
        INC $!SubPhase      
RTS     
        
ExtendLasers:       
        LDX $!SpriteSlot1       
        INC $!FireBarLength,x       
        
        LDX $!SpriteSlot2       
        INC $!FireBarLength,x       
        
        LDA $!FireBarLength,x       
        CMP #$13                            ; 13 is the limit without running out of sprite tiles
        BNE +       
        LDX $!SpriteSlot1       
        STZ !sprite_misc_1510,x             ; init growth direction that's used for both firebars, if needed
    
        DEC $!SubPhase2                     ; init subphase2 counter for next subphase
        STZ $!LasersSpeed2

        INC $!SubPhase  
    +   
RTS 
    
; all tables must be the same size
LaserAccelsA:
    db $FA,$06,$04,$FC;,$FC,$04;,$04,$FC
LaserAccelsB:
    db $01,$FF,$04,$FC;,$FC,$04;,$04,$FC
LaserDeltas:
    db $4E,$4E,$58,$58;,$50,$50;,$30,$30
LaserTableSize:
    
MoveLasers: 
        LDA $!GlobalTimer                   ;\ 
        BNE +                               ;/ if timer is 0...
    
        INC $!SubPhase2                     ; increment movement phase
        
        LDA $!SubPhase2                     ;\
        CMP.b #LaserTableSize-LaserDeltas   ;| check if we're done moving
        BCC ++                              ;|
        INC $!SubPhase                      ;| if we are, increment subphase to end laser attack
        STZ $!SubPhase2                     ;| reinitialize subphase2
        JMP .Return                         ;/ and skip updates
    ++      
        LDX $!SubPhase2                     ;\
        LDA LaserDeltas,x                   ;| get next time value
        STA $!GlobalTimer                   ;/ update timer to new value
    +   

        LDA $14                             ;\ 
        AND #$01                            ;| Only update speed every other frame, for slower acceleration
        BEQ .modifyAngle1                   ;/
        LDX $!SubPhase2                     ;\
        LDA $!LasersVariant                 ;|
        BNE +                               ;|
        LDA LaserAccelsB,x                  ;| get current acceleration
        EOR #$FF                            ;| accounting for mirrored attack variation
        INC                                 ;|
        BRA ++                              ;|
    +                                       ;|
        LDA LaserAccelsA,x                  ;/
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
        LDA $!LasersSpeed1                  ;\
        CLC : ADC $00                       ;| add accel to speed
        STA $!LasersSpeed1                  ;/
        SEP #$20

    .modifyAngle1
        REP #$20
        LDA $!LasersSpeed1 
        CLC : ADC $!LasersAngle1            ;\ add speed to angle
        STA $!LasersAngle1                  ;|
        LSR #3                              ;| lower precision for firebars (remove the 3 bits of headroom)
        STA $00                             ;|
        SEP #$20                            ;/
    
        LDX $!SpriteSlot1                   ;\
        LDA $00                             ;| set firebar angle directly
        STA $!FireBarAngleFine,x            ;|
        LDA $01                             ;|
        STA $!FireBarAngleCoarse,x          ;/    


        LDA $14                             ;\ 
        AND #$01                            ;| Only update speed every other frame, for slower acceleration
        BEQ .modifyAngle2                   ;/
        LDX $!SubPhase2                     ;\
        LDA $!LasersVariant                 ;|
        BNE +                               ;| get current acceleration
        LDA LaserAccelsA,x                  ;| accounting for mirrored attack variation
        EOR #$FF                            ;|
        INC                                 ;|
        BRA ++                              ;|
    +                                       ;|
        LDA LaserAccelsB,x                  ;/ get current acceleration
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
        LDA $!LasersSpeed2                  ;\
        CLC : ADC $00                       ;| add accel to speed
        STA $!LasersSpeed2                  ;/
        SEP #$20

    .modifyAngle2
        REP #$20
        LDA $!LasersSpeed2 
        CLC : ADC $!LasersAngle2            ;\ add speed to angle
        STA $!LasersAngle2                  ;|
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
    
RetractLasers:  
        LDX $!SpriteSlot1   
        DEC $!FireBarLength,x   
    
        LDX $!SpriteSlot2   
        DEC $!FireBarLength,x   
    
        LDA $!FireBarLength,x   
        CMP #$00    
        BNE +   
        INC $!SubPhase  
    +   
RTS 
    
EndLasers:  
        LDX $!SpriteSlot1                   ;\
        STZ !sprite_status,x                ;|
        LDX $!SpriteSlot2                   ;| despawn lasers
        STZ !sprite_status,x                ;/
            
        LDA #$F0                            ;\
        LDX #!LeftEyeSlot                   ;|
        STA !sprite_speed_y,x               ;| start Mycelia moving upward
        LDX #!RightEyeSlot                  ;|
        STA !sprite_speed_y,x               ;/
            
        INC $!SubPhase          
RTS         
            
MyceliaAscending:           
        LDA #!MyceliaYLo        
        STA $00     
        LDA #!MyceliaYHi        
        STA $01     
        LDX #!LeftEyeSlot                   ; use left eye as proxy for y position of both eyes
        LDA !sprite_y_high,x                ;\
        XBA                                 ;|
        LDA !sprite_y_low,x                 ;|
        REP #$20                            ;|
        CMP $00                             ;| check if eyes have reached upper position yet
        SEP #$20                            ;/
        BCS .Return                     
        JSL AttackEnded
    .Return
RTS