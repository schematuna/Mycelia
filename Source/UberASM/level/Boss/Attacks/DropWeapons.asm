;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Drop Weapons - bombs or mechakoopas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DWStates:       dw DWInit
                dw DWMain
                dw DWEnd

DropWeapons:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (DWStates,x)
RTS

DWInit:
        LDA #$60
        STA $!GlobalTimer

        INC $!SubPhase   
RTS

DWMain:
        LDA $!GlobalTimer
        CMP #$00                        ; time at which we spawn weapons
        BEQ .SpawnEnemies
        LDA $14                         ;\
        AND #$02                        ;|
        BEQ +                           ;|
        LDX #!LeftEyeSlot               ;|
        INC !sprite_x_low,x             ;|
        LDX #!RightEyeSlot              ;|
        DEC !sprite_x_low,x             ;| shake Mycelia left and right
        BRA .Return                     ;|
    +                                   ;|
        LDX #!LeftEyeSlot               ;|
        DEC !sprite_x_low,x             ;|
        LDX #!RightEyeSlot              ;|
        INC !sprite_x_low,x             ;/
        BRA .Return

    .SpawnEnemies      
        JSR DWSpawnBombs

        LDA #$10                        ;\ magic sfx
        STA $1DF9                       ;/ 

        LDA #$40                        ;\
        STA $!GlobalTimer               ;/ wait a sec before moving on from attack

        INC $!SubPhase
    .Return
RTS

DWEnd:
        LDA $!GlobalTimer
        BNE .return
        JSL AttackEnded
    .return
RTS

DWLeftBooPatterns:
    dw DWPhase1LeftBoos
    dw DWPhase2LeftBoos
    dw DWPhase3LeftBoos

DWRightBooPatterns:
    dw DWPhase1RightBoos
    dw DWPhase2RightBoos
    dw DWPhase3RightBoos

DWSpawnBombs:
        LDA #$01
        JSL Random
        CMP #$00
        BNE .reversed

        LDA #$0D
        STA $!SpriteNumber
        LDA #$01 
        STA $!SpriteState
        LDA #!MyceliaXLoLeft
        SEC : SBC #$10                  ; spawn away from eyes so they don't immediately damage
        STA $!XLo
        LDA $!MyceliaXHi
        SBC #$00
        STA $!XHi
        LDA #!MyceliaYLo
        STA $!YLo
        LDA #!MyceliaYHi
        STA $!YHi

        JSL SpawnNormalSprite
        STX $!SpriteSlot1

        LDA #$F0 
        STA !sprite_speed_x,x

        LDA $!BossPhase
        ASL A
        TAX
        JSR (DWRightBooPatterns,x)

        BRA .return

    .reversed
        LDA #$0D
        STA $!SpriteNumber
        LDA #$01 
        STA $!SpriteState
        LDA #!MyceliaXLoRight
        CLC : ADC #$10                  ; spawn away from eyes
        STA $!XLo
        LDA $!MyceliaXHi
        ADC #$00
        STA $!XHi
        LDA #!MyceliaYLo
        STA $!YLo
        LDA #!MyceliaYHi
        STA $!YHi

        JSL SpawnNormalSprite
        STX $!SpriteSlot1

        LDA #$10
        STA !sprite_speed_x,x

        LDA $!BossPhase
        ASL A
        TAX
        JSR (DWLeftBooPatterns,x)

    .return
RTS

DWPhase1LeftBoos:
        LDX #!LeftEyeSlot
        LDA #$30
        STA $0D
        JSL ShootBooAtPlayer
RTS

DWPhase1RightBoos:
        LDX #!RightEyeSlot
        LDA #$30
        STA $0D
        JSL ShootBooAtPlayer
RTS

DWPhase2LeftBoos:
        LDX #!LeftEyeSlot
        LDA #$60
        STA $04
        LDA #$28
        STA $0D
        JSL ShootBooWithAngle

        LDA #$80
        STA $04
        JSL ShootBooWithAngle

        LDA #$A8
        STA $04
        JSL ShootBooWithAngle
RTS

DWPhase2RightBoos:
        LDX #!RightEyeSlot
        LDA #$60
        STA $04
        LDA #$28
        STA $0D
        JSL ShootBooWithAngle

        LDA #$80
        STA $04
        JSL ShootBooWithAngle

        LDA #$A8
        STA $04
        JSL ShootBooWithAngle
RTS

DWPhase3LeftBoos:
        LDX #!LeftEyeSlot
        LDA #$60
        STA $04
        LDA #$28
        STA $0D
        JSL ShootBooWithAngle

        LDA #$80
        STA $04
        JSL ShootBooWithAngle

        LDA #$A8
        STA $04
        JSL ShootBooWithAngle

        LDX #!RightEyeSlot
        LDA #$60
        STA $04
        LDA #$80
        STA $04
        JSL ShootBooWithAngle

        LDA #$A8
        STA $04
        JSL ShootBooWithAngle
RTS

DWPhase3RightBoos:
        LDX #!RightEyeSlot
        LDA #$60
        STA $04
        LDA #$28
        STA $0D
        JSL ShootBooWithAngle

        LDA #$80
        STA $04
        JSL ShootBooWithAngle

        LDA #$A8
        STA $04
        JSL ShootBooWithAngle

        LDX #!LeftEyeSlot
        LDA #$60
        STA $04
        LDA #$80
        STA $04
        JSL ShootBooWithAngle

        LDA #$A8
        STA $04
        JSL ShootBooWithAngle
RTS