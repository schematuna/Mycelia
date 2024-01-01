;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 9 - Boo Ceiling & Chucks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CBCStates:      dw CBCInit
                dw CBCTransformMycelia
                dw CBCSetSawDirection
                dw CBCMain
                dw CBCEndCeilingBoos
                dw CBCReturnMycelia

CeilingBoosChucks:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (CBCStates,x)
RTS

CBCInit:
        LDA #$60
        STA $!GlobalTimer

        INC $!SubPhase   
RTS

CBCTransformMycelia:
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
        JSL DespawnMycelia              ;\ replace Mycelia with saws
        JSR CBCSpawnChucks              ;/
        LDA $!GlobalTimer               ;
        CMP #$00                        ;
        BNE .Return                     ; 
        LDA #$10                        ;\ magic sfx
        STA $1DF9                       ;/ 
        LDX #$E1                        ;\ start up ceiling boos
        JSL InitSpecialSprite           ;/
        INC $!SubPhase                  ;
        BRA .Return                     ;

    .BackToMycelia
        LDX $!SpriteSlot1               ;\
        STZ !sprite_status,x            ;|
        LDX $!SpriteSlot2               ;| despawn saws
        STZ !sprite_status,x            ;/
        JSL SpawnMycelia

    .Return
RTS

; Need dedicated phase for this so it happens after the saws init code
CBCSetSawDirection:
        ;LDX $!SpriteSlot1               ;\
        ;LDA #$01                        ;|
        ;STA !157C,x                     ;| directly set saw initial directions
        ;LDX $!SpriteSlot2               ;| instead of using their default behavior
        ;LDA #$00                        ;| where they face mario
        ;STA !157C,x                     ;/

        REP #$20                        ;\
        LDA #$0280                      ;| set time for main attack to run
        STA $!GlobalTimer               ;|
        SEP #$20                        ;/

        INC $!SubPhase
RTS

CBCMain:
        REP #$20                        ;\
        LDA $!GlobalTimer               ;|
        SEP #$20                        ;| if attack timer is up
        BNE +                           ;/
        LDA #$13                        ;\
        STA $!SubPhase2                 ;/ set initial cluster index
        INC $!SubPhase                  ; end the attack
    +
RTS

CBCEndCeilingBoos:
        LDA $14                         ;\ 
        AND #$01                        ;| every other frame
        BEQ +                           ;/
        LDX $!SubPhase2                 ;\
        STZ $1892,X                     ;| remove one cluster sprite until they're all gone
        DEC $!SubPhase2                 ;|
        BPL +                           ;/
        STZ $18B8                       ; don't run cluster code anymore
        LDX $!SpriteSlot1               ;\
        JSR SpawnSmokeOnSprite          ;|
        STZ !sprite_status,x            ;|
        LDX $!SpriteSlot2               ;| poof saws
        JSR SpawnSmokeOnSprite          ;|
        STZ !sprite_status,x            ;/
        LDA #$25                        ;\ poof sfx
        STA $1DFC                       ;/ 
        LDA #$18                        ;\ set time until Mycelia reappears
        STA $!GlobalTimer               ;/
        STZ $!SubPhase2                 ; reinit subphase2
        INC $!SubPhase                  ; move on
    +
RTS

CBCReturnMycelia:
        LDA $!GlobalTimer               ;\ once timer is up
        BNE +                           ;|
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

CBCSpawnChucks:
        LDA #$01 
        STA $!SpriteState
        LDA #$91 ; chucks ;#$86 OR WIGGLERS
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
