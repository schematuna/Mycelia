;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 8 - Reappearing Boos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!BooCycles = $2

RBStates:       dw RBInit
                dw TransformMycelia
                dw SetSawDirection
                dw StartBoos
                dw RBMain
                dw RBReturnMycelia

ReappearingBoos:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (RBStates,x)
RTS

RBInit:
        LDA #$60
        STA $!GlobalTimer

        INC $!SubPhase   
RTS

TransformMycelia:
        LDA $!GlobalTimer
        CMP #$20                        ; time at which we flash the saws
        BEQ .SpawnSaws
        CMP #$1C                        ; time at which we return to mycelia
        BEQ .BackToMycelia
        CMP #$00                        ; spawn saws for good at zero
        BEQ .SpawnSaws
        LDA $14                         ;\
        AND #$02                        ;|
        BEQ +                           ;|
        LDX #!LeftEyeSlot               ;|
        INC !sprite_x_low,x             ;|
        LDX #!RightEyeSlot              ;|
        DEC !sprite_x_low,x             ;| shake Mycelia left and right... she's gonna...
        BRA .Return                     ;| TRANSFOOOOOOOOOOOOOORM
    +                                   ;|
        LDX #!LeftEyeSlot               ;|
        DEC !sprite_x_low,x             ;|
        LDX #!RightEyeSlot              ;|
        INC !sprite_x_low,x             ;/
        BRA .Return

    .SpawnSaws
        JSL DespawnMycelia              ;\
        JSR RBSpawnSaws                 ;| replace Mycelia with saws
        LDA $!GlobalTimer               ;|
        CMP #$00                        ;|
        BNE .Return                     ;| 
        LDA #$10                        ;|
        STA $1DF9                       ;| magic sfx
        INC $!SubPhase                  ;|
        BRA .Return                     ;/

    .BackToMycelia
        LDX $!SpriteSlot1               ;\
        STZ !sprite_status,x            ;|
        LDX $!SpriteSlot2               ;| despawn saws
        STZ !sprite_status,x            ;/
        JSL SpawnMycelia

    .Return
RTS

; Need dedicated phase for this so it happens after the saws init code
SetSawDirection:
        LDX $!SpriteSlot1
        LDA #$01
        STA !157C,x
        LDX $!SpriteSlot2
        LDA #$00
        STA !157C,x

        LDA #$90                        ;\ set time until reappearing boos will start
        STA $!GlobalTimer               ;/

        INC $!SubPhase
RTS

StartBoos:
        LDA $!GlobalTimer               ;\
        BNE +                           ;|
        LDX #$E5                        ;| once timer is up, start reappearing boos and move to next phase
        JSL InitSpecialSprite           ;|
        JSR RandomizeBooPositions       ;| start off with random boo x offset
        INC $!SubPhase                  ;/
    +
RTS

RBMain:
        LDA $190A                       ;\ if we've completed another boo cycle
        BNE +                           ;|
        JSR RandomizeBooPositions       ;| randomize x offset
        INC $!SubPhase2                 ;| increment cycle counter
        LDA $!SubPhase2                 ;|
        CMP #!BooCycles                 ;| if we've done the set number of cycles
        BNE +                           ;/

        STZ $18B8                       ; end reappearing boos by ending the cluster code
        LDX $!SpriteSlot1               ;\
        JSR SpawnSmokeOnSprite          ;|
        STZ !sprite_status,x            ;|
        LDX $!SpriteSlot2               ;| poof saws
        JSR SpawnSmokeOnSprite          ;|
        STZ !sprite_status,x            ;/
        LDA #$25                        ;\
        STA $1DFC                       ;/ poof sfx
        LDA #$30                        ;\
        STA $!GlobalTimer               ;/ set timer until Mycelia comes back
        STZ $!SubPhase2                 ;\
        INC $!SubPhase                  ;/ end the attack

    +
RTS

RBReturnMycelia:
        LDA $!GlobalTimer               ;\
        BNE +                           ;| when the timer is up
        JSL SpawnMycelia                ;| bring back Mycelia
        LDX #!LeftEyeSlot               ;| 
        JSR SpawnGlitterOnSprite        ;| ...with glitter
        LDX #!RightEyeSlot              ;|
        JSR SpawnGlitterOnSprite        ;/
        LDA #$10                        ;\
        STA $1DF9                       ;/ magic sfx
        JSL AttackEnded
    +
RTS

RBSpawnSaws:
        LDA #$01 
        STA $!SpriteState
        LDA #$B4
        STA $!SpriteNumber
        LDA #!MyceliaXLoLeft
        STA $!XLo
        LDA $!MyceliaXHi
        STA $!XHi
        LDA #!MyceliaYLo
        SEC : SBC #$10
        STA $!YLo
        LDA #!MyceliaYHi
        STA $!YHi
        JSL SpawnNormalSprite
        TXA
        STX $!SpriteSlot1

        LDA #!MyceliaXLoRight
        STA $!XLo
        JSL SpawnNormalSprite
        TXA
        STX $!SpriteSlot2
RTS

SpawnBooStreams:
        LDA #$01
        STA $!SpriteState
        LDA #$4C
        STA $!SpriteNumber
        LDA #$E0
        STA $!XLo
        LDA #$00
        STA $!XHi
        LDA #$00
        STA $!YLo
        LDA #$01
        STA $!YHi
        STZ $!ExtraByte1        
        STZ $!ExtraByte2        
        STZ $!ExtraByte3        
        STZ $!ExtraByte4
        STZ $!YSpeed
        STZ $!XSpeed
        LDA #$08                
        STA $!ExtraBits

        JSL SpawnCustomSprite
RTS

; just randomize x offset
RandomizeBooPositions:
        LDA #$0F                        ; offset their positions by a random amount!
        JSL Random                      ; so we don't get the same pattern every time...
        ASL #4                  
        STA $!MiscRam1           
        LDX #$13
    -
        LDA $1E66,x                     ;\ 
        CLC : ADC $!MiscRam1            ;| frame 1 x
        STA $1E66,x                     ;/
        LDA $1E8E,x                     ;\ 
        CLC : ADC $!MiscRam1            ;| frame 2 x
        STA $1E8E,x                     ;/
        DEX                             ;\
        BPL -                           ;/ repeat for all cluster sprites
RTS
