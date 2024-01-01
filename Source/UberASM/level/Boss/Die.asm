;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Mycelia Death Routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


Die:
        LDA $!MainPhase2              
        JSL $0086DF
        dw KMInit
        dw KMFalling
        dw KMMusicChange
        dw KMDie
        dw KMDone
RTS

KMInit:        
        JSL KillAllSpritesExceptEyesAndShells
        JSL ResetMycelia

        LDA #$10                            ;\
        LDX #!LeftEyeSlot                   ;|
        STA !sprite_speed_y,x               ;| set eyes downward speed
        LDX #!RightEyeSlot                  ;|
        STA !sprite_speed_y,x               ;/

        LDA #$FF                            ;
        STA $1DFB                           ; kill music

        INC $!MainPhase2
RTS

KMFalling:
        LDX #!LeftEyeSlot                   ; use left eye as proxy for y position of both eyes
        LDA !sprite_y_high,x                ;\
        XBA                                 ;|
        LDA !sprite_y_low,x                 ;|  
        REP #$20                            ;|
        CMP #$01B0                          ;| check if eyes have reached lower position yet
        SEP #$20                            ;/
        BCC +           
        LDX #!LeftEyeSlot                   ;\
        STZ !sprite_speed_y,x               ;|
        LDX #!RightEyeSlot                  ;| stop Mycelia moving
        STZ !sprite_speed_y,x               ;|

        LDA #$60
        STA $!GlobalTimer

        INC $!MainPhase2                    ;/ and progress to next state
        BRA .return
    +           
        JSR KMShakeMycelia
        JSR KMRandomSmoke

    .return
RTS

KMMusicChange:
        JSR KMShakeMycelia
        JSR KMRandomSmoke

        LDA $!GlobalTimer
        BNE +

        LDA #$42                        ;\ 
        STA $1DFB                       ;/ start ambience music

        INC $!MainPhase2
    +
RTS

KMDie:
        LDA #$10                        ;\ play magic sfx and despawn boss
        STA $1DF9                       ;| once ambient music has finished loading 
        JSL DespawnMycelia              ;/

        LDA #$01 
        STA $!SpriteState
        LDA #$80                        ; key
        STA $!SpriteNumber
        LDX #!LeftEyeSlot
        LDA !sprite_x_low,x
        STA $!XLo
        LDA !sprite_x_high,x
        STA $!XHi
        LDA !sprite_y_low,x
        STA $!YLo
        LDA !sprite_y_high,x
        STA $!YHi
        JSL SpawnNormalSprite

        LDA #$0E                        ; keyhole
        STA $!SpriteNumber
        LDX #!RightEyeSlot
        LDA !sprite_x_low,x
        STA $!XLo
        JSL SpawnNormalSprite

        INC $!MainPhase2
RTS

KMDone:
        ; Wait for player to put key in hole :3
RTS

; Spawn smoke around the eyes
KMRandomSmoke:
        LDA $!GlobalTimer2
        BNE +
        LDX #!LeftEyeSlot
        LDA #$10 : JSL Random : STA $00
        LDA #$10 : JSL Random : STA $01
        LDA #$1B : STA $02
        LDA #$01
        JSL SpawnSmoke

        LDX #!RightEyeSlot
        LDA #$10 : JSL Random : STA $00
        LDA #$10 : JSL Random : STA $01
        LDA #$1B : STA $02
        LDA #$01
        JSL SpawnSmoke

        LDA #$25                        ;\ poof sfx
        STA $1DFC                       ;/ 

        LDA #$0C
        STA $!GlobalTimer2
    +

RTS


; TODO: refactor into common to use with ceiling boos
KMShakeMycelia:
        LDA $14                             ;\
        AND #$02                            ;|
        BEQ +                               ;|
        LDX #!LeftEyeSlot                   ;|
        INC !sprite_x_low,x                 ;|
        LDX #!RightEyeSlot                  ;|
        DEC !sprite_x_low,x                 ;| shake Mycelia left and right as she dies
        BRA .return                         ;|
    +                                       ;|
        LDX #!LeftEyeSlot                   ;|
        DEC !sprite_x_low,x                 ;|
        LDX #!RightEyeSlot                  ;|
        INC !sprite_x_low,x                 ;/
    .return
RTS