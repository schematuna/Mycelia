;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Scrolling Boos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SCBBooSpeed       = !MiscRam1
!SCBTableAddress   = !MiscRam2          ; 16 bits
!SCBTableDir       = !MiscRam4

SCBStates:      dw SCBInit
                dw SCBTransformMycelia
                dw SCBSetSawDirection
                dw SCBMain
                dw SCBPoofSaws
                dw SCBReturnMycelia

ScrollingBoos:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SCBStates,x)
RTS

SCBInit:
        LDA #$60
        STA $!GlobalTimer

        LDA #$0A
        STA $!SCBBooSpeed

        INC $!SubPhase   
RTS

SCBTransformMycelia:
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
        JSR SCBSpawnSaws                ;| replace Mycelia with saws
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
SCBSetSawDirection:
        LDX $!SpriteSlot1
        LDA #$01
        STA !157C,x
        LDX $!SpriteSlot2
        LDA #$00
        STA !157C,x

    .initRNG
        LDA #$01                                ;\
        JSL Random                              ;| 
        ASL                                     ;|
        TAX                                     ;|
        REP #$20                                ;| Randomly choose which table to use for boo y positions
        LDA SCBPositionTables,x                 ;|
        STA $!SCBTableAddress                   ;|
        SEP #$20                                ;/

        LDA #$01                                ;\
        JSL Random                              ;| Pick random table traversal direction
        STA $!SCBTableDir                       ;/

        INC $!SubPhase
RTS

SCBPositionTables:
        dw SCBXY1,SCBXY2

; These are vanilla tables, I use the x positions as y positions for the boos
SCBXY1:  db $31,$71,$A1,$43,$93,$C3,$14,$65       ;\ Position of reappearing boos, frame 1
         db $E5,$36,$A7,$39,$99,$F9;,$1A,$7A       ;| 
         ;db $DA,$4C,$AD,$ED                       ;/ Format: $xy.

SCBXY2:  db $01,$51,$91,$D1,$22,$62,$A2,$73       ;\
         db $E3,$C7,$88,$29,$5A,$AA;,$EB,$2C       ;| same, but frame 2
         ;db $8C,$CC,$FC,$5D                       ;/
SCBNumPositions:

SCBMain:
        LDA $!GlobalTimer
        BNE .return
        REP #$20                        ;\
        LDA $!SCBTableAddress           ;| store chosen table address to memory for indirect addressing
        STA $00                         ;|
        SEP #$20                        ;/
        LDY $!SubPhase2
        LDA $!SCBTableDir               ;\
        BEQ +                           ;|
        LDA.b #SCBNumPositions-SCBXY2-1 ;| if random flag set, read through table backwards
        SEC : SBC $!SubPhase2           ;|
        TAY                             ;/
    +                                   
        LDA ($00),y                     ;\
        AND #$F0                        ;/ get high nibble of current table value
        LSR                             ;\
        CLC : ADC #$48                  ;/ compress the value to a usable range
        STA $0D                         ; and use as boo y position
        STZ $04                         ; and spawn at left side of screen
        JSL SpawnBooAtPosition
        LDA $!SCBBooSpeed
        STA !cluster_speed_x,y
        LDA #$00
        STA !cluster_speed_y,y

        LDA $!SCBBooSpeed
        LDX #$13
    -
        STA !cluster_speed_x,x          ; Update speed of all cluster sprites
        DEX                             
        BPL -                           

        LDA #$40                        ;\
        STA $!GlobalTimer               ;/ set timer until next boo spawn
        INC $!SCBBooSpeed               ;\ slowly ramp up speed...
        INC $!SCBBooSpeed               ;/
        INC $!SubPhase2                 ;\
        LDA $!SubPhase2                 ;| incrememnt boo count and check if we're done yet
        CMP.b #SCBNumPositions-SCBXY2   ;/
        BNE .return
        INC $!SubPhase
    .return
RTS

SCBPoofSaws:
        ;STZ $18B8                       ; end cluster code
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
RTS

SCBReturnMycelia:
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

SCBSpawnSaws:
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