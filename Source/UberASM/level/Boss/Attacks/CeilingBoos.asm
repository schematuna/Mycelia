;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 9 - Boo Ceiling & 2 Sprites
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!CBSprite1 = !MiscRam1
!CBSprite2 = !MiscRam2
!CBVariant = !MiscRam3

CBStates:       dw CBInit
                dw CBTransformMycelia
                dw CBSetSpriteDir
                dw CBMain
                dw CBEndCeilingBoos
                dw CBReturnMycelia

CeilingBoos:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (CBStates,x)
RTS

CBChooseTable:
    dw CBChoose1
    dw CBChoose2
    dw CBChoose3

CBInit:
        LDA #$60
        STA $!GlobalTimer

        ; Choose which sprites to spawn
        LDA $!BossPhase
        ASL A
        TAX
        JSR (CBChooseTable,x)

        LDA #$01
        JSL Random
        STA $!CBVariant

        INC $!SubPhase   
RTS

CBChoose1:
        ; nothing for phase 1
        STZ $!CBSprite1
        STZ $!CBSprite2
RTS

CBChoose2:
        LDA #$09                        ; bouncing koopa
        STA $!CBSprite1
        STA $!CBSprite2
RTS 

CBChoose3:
        LDA #$B4                        ; saw
        STA $!CBSprite1
        STA $!CBSprite2
RTS

CBSpawnTable:
        dw CBPhase1Spawn
        dw CBPhase2Spawn
        dw CBPhase3Spawn

CBTransformMycelia:
        LDA $!GlobalTimer
        CMP #$20                        ; time at which we flash the saws
        BEQ .SpawnEnemies
        CMP #$1C                        ; time at which we return to mycelia
        BEQ .BackToMycelia
        CMP #$00                        ; spawn saws for good at zero
        BEQ .SpawnEnemies
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

    .SpawnEnemies
        JSL DespawnMycelia              ;\ replace Mycelia with saws
        LDA $!BossPhase
        ASL A
        TAX
        JSR (CBSpawnTable,x)
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

; Need dedicated phase for setting sprite direction AFTER their init code runs
CBSetSpriteDir:
        LDX $!SpriteSlot1
        LDA #$01                        ;\
        STA !157C,x                     ;| directly set sprite initial directions
        LDX $!SpriteSlot2               ;|
        LDA #$00                        ;| instead of using their default behavior where they face mario 
        STA !157C,x                     ;/

        REP #$20                        ;\
        LDA #$0280                      ;| set time for main attack to run
        STA $!GlobalTimer               ;|
        SEP #$20                        ;/

        INC $!SubPhase
RTS

CBMain:
        REP #$20                        ;\
        LDA $!GlobalTimer               ;|
        SEP #$20                        ;| if attack timer is up
        BNE +                           ;/
        LDA #$13                        ;\
        STA $!SubPhase2                 ;/ set initial cluster index
        INC $!SubPhase                  ; end the attack
    +
RTS

CBEndCeilingBoos:
        LDA $14                         ;\ 
        AND #$01                        ;| every other frame
        BEQ .return                     ;/
        LDX $!SubPhase2                 ;\
        STZ $1892,X                     ;| remove one cluster sprite until they're all gone
        DEC $!SubPhase2                 ;|
        BPL .return                     ;/
        STZ $18B8                       ; don't run cluster code anymore
        LDX $!SpriteSlot1               ;\
        LDA $14C8,x                     ;| get sprite status
        CMP #$0B                        ;| check if it's being carried
        BEQ +                           ;| don't despawn if it is
        LDA !sprite_status,x            ;| also don't despawn if already dead
        BEQ +                           ;|
        JSR SpawnSmokeOnSprite          ;|
        STZ !sprite_status,x            ;|
    +                                   ;|
        LDX $!SpriteSlot2               ;| same for other sprite
        LDA $14C8,x                     ;| 
        CMP #$0B                        ;| 
        BEQ +                           ;| 
        LDA !sprite_status,x            ;| also don't despawn if already dead
        BEQ +                           ;|
        JSR SpawnSmokeOnSprite          ;|
        STZ !sprite_status,x            ;/
    +
        LDA #$25                        ;\ poof sfx
        STA $1DFC                       ;/ 
        LDA #$18                        ;\ set time until Mycelia reappears
        STA $!GlobalTimer               ;/
        STZ $!SubPhase2                 ; reinit subphase2
        INC $!SubPhase                  ; move on
    .return
RTS

CBReturnMycelia:
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

CBPhase1Spawn:
        ; this attack isn't presently called in phase 1
RTS

CBPhase2Spawn:
        LDA #$01 
        STA $!SpriteState
        LDA $!CBSprite1
        STA $!SpriteNumber
        LDA #!MyceliaXLoLeft
        SEC : SBC #$0A
        STA $!XLo
        LDA $!MyceliaXHi
        STA $!XHi
        LDA #!MyceliaYLo
        LDX $!CBVariant
        CPX #$00
        BEQ +
        SEC : SBC #$08                  ; one koopa will be higher so it has a different bounce pattern
    +                  
        STA $!YLo
        LDA #!MyceliaYHi
        STA $!YHi
        JSL SpawnNormalSprite
        TXA
        STX $!SpriteSlot1

        LDA $!CBSprite2
        STA $!SpriteNumber
        LDA #!MyceliaXLoRight
        CLC : ADC #$0A
        STA $!XLo
        LDA #!MyceliaYLo
        LDX $!CBVariant
        CPX #$00
        BNE +
        SEC : SBC #$08                  ; depending on random value chosen in init
    +         
        STA $!YLo
        JSL SpawnNormalSprite
        TXA
        STX $!SpriteSlot2
RTS

CBPhase3Spawn:
        LDA #$01 
        STA $!SpriteState
        LDA $!CBSprite1
        STA $!SpriteNumber
        LDA #!MyceliaXLoLeft
        STA $!XLo
        LDA $!MyceliaXHi
        STA $!XHi
        LDA #!MyceliaYLo
        SEC : SBC #$10                  ; raise saws so they look right
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