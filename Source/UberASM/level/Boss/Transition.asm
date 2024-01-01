;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 2 - Transition
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
!TransAccel                     = $0001

; this speed value increases with the TransAccel value and gets added to the x increment every frame
!TransSpeed                     = !MiscRam1             ; 16-bit

; the low bits of this are basically accumulating fraction bits
; the high bits are the number of pixels the screen moves that frame, and gets reset every frame
!TransScreenXIncrement          = !MiscRam3             ; 16-bit

ArenaPositions:
dw $0100,$0500,$0900

TransStates:
        dw TransInit
        dw TransMain
        dw TransEnd

Transition:
        LDA $!MainPhase2
        ASL
        TAX
        JSR (TransStates,x)
RTS

TransInit:
        JSL ResetMycelia

        REP #$20
        STZ $!TransSpeed
        STZ $!TransScreenXIncrement
        SEP #$20

        INC $!MainPhase2
RTS

TransMain:                                      
        LDA $!BossPhase                         ;\ check if screen is at next arena position
        ASL                                     ;|
        TAX                                     ;|
        REP #$20                                ;|
        LDA $1A                                 ;|
        CMP ArenaPositions,x                    ;/
        BCC +                                    
        LDA ArenaPositions,x                    ;\
        STA $1462                               ;| set position directly to be sure
        SEP #$20                                ;/    
        INC $!MainPhase2
        
        LDA #$30                                ;\
        STA $!GlobalTimer                       ;/ set delay for when Mycelia comes back

        BRA .return                             ;
    + 

        LDA $!TransSpeed                        ;\
        CLC : ADC #!TransAccel                  ;| increase speed by acceleration amount
        STA $!TransSpeed                        ;/
        LDA $!TransScreenXIncrement             ;\
        CLC : ADC $!TransSpeed                  ;| increase screen x increment by speed
        STA $!TransScreenXIncrement             ;/
        SEP #$20

        LDA $1462                               ; Layer 1 low X pos (next frame)
        CLC : ADC $!TransScreenXIncrement+1     ; add high bits of speed
        STA $1462

        LDA $1463                               ; Layer 1 high X pos (next frame)
        ADC #$00
        STA $1463

        STZ $!TransScreenXIncrement+1           ; reset increment high bits


        ; keep mario within screen edges (without killing him...)
        ; taken from Multi-step autoscroll by Mathos
        REP #$20                                ; A 16-bit
        LDA $1462                               ;\ handle left wall
        CLC : ADC #$000A                        ;|
        CMP $94                                 ;|
        BCC .NotTooLeft                         ;|
        STA $94                                 ;|
        .NotTooLeft                             ;/
        LDA $1462                               ;\ handle right wall
        CLC : ADC #$00EA                        ;|
        CMP $94                                 ;|
        BCS .NotTooRight                        ;|
        STA $94                                 ;|
        .NotTooRight                            ;/
        SEP #$20                                ; A back to 8-bit        
    .return
RTS

TransEnd:
        LDA $!GlobalTimer
        BNE .return
        STZ $!MainPhase2                        ; clear state

        JSL SpawnMycelia                        ;\
        JSL ResetMycelia                        ;/ bring eyes back
        LDX #!LeftEyeSlot                       ;\
        JSR SpawnSmokeOnSprite                  ;| show smoke when eyes reappear
        LDX #!RightEyeSlot                      ;|
        JSR SpawnSmokeOnSprite                  ;|
        LDA #$10                                ;|
        STA $1DF9                               ;/ magic sfx

        LDA #$01                                ;| set main phase to primary phase
        STA $!MainPhase                         ;/
    .return
RTS