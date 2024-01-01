incsrc "Boss/BossCommon.asm"

incsrc "Boss/Intro.asm"
incsrc "Boss/Transition.asm"
incsrc "Boss/Die.asm"

init:
        JSL SpawnMycelia                ;\ setup eyes
        JSL ResetMycelia                ;/

        STZ $!MainPhase                 ;\
        STZ $!MainPhase2                ;|
        STZ $!MainPhase3                ;|
        STZ $!SubPhase                  ;| init all state
        STZ $!SubPhase2                 ;|
        STZ $!BossPhase                 ;| 
        STZ $!BossHits                  ;/

        STZ $1A                         ;\ hardcode layer 1 position
        STZ $1462                       ;| both current and next frame
        LDA #$01                        ;|
        STA $1B                         ;|
        STA $1463                       ;/

        LDA #$80                        ;\
        STA $1E                         ;| same for layer 2
        STA $1466                       ;|
        STZ $1F                         ;|
        STZ $1467                       ;/

        STZ $1411                       ; disable horizontal scrolling
RTL

States: dw Intro                        ; 0
        dw Primary                      ; 1
        dw Transition                   ; 2
        dw Die                          ; 3

main:
        LDA $9D                         ;\ check the 'lock animation and sprites' flag
        ORA $13D4                       ;| and paused flag
        BEQ +                           ;| 
        JMP .return                     ;| and do nothing if either are set
    +                                   ;/

        ; Main state machine
        LDA $!MainPhase 
        ASL A   
        TAX     
        JSR (States,x)  
        
        ; Decrement all global timers
        
        REP #$20                        ;\
        LDA $!GlobalTimer               ;| 
        BEQ +                           ;| if global timer is not at zero
        DEC $!GlobalTimer               ;| decrement it
    +                                   ;|
        SEP #$20                        ;/
        
        LDA $!GlobalTimer2              ;\
        BEQ +                           ;| same for secondary timer
        DEC $!GlobalTimer2              ;|
    +                                   ;/

        LDA $!GlobalTimer3              ;\
        BEQ +                           ;| same for tertiary timer
        DEC $!GlobalTimer3              ;|
    +                                   ;/
        
        DEC $!MyceliaTimer              ; decrement timer used by the Mycelia eye sprites

    .return
RTL




incsrc "Boss/Attacks/DropWeapons.asm"

incsrc "Boss/Attacks/Lasers.asm"
incsrc "Boss/Attacks/BooRings.asm"
incsrc "Boss/Attacks/SpinningFire.asm"
incsrc "Boss/Attacks/CeilingBoos.asm"
incsrc "Boss/Attacks/SpinningFireSides.asm"
incsrc "Boss/Attacks/ShootBoos.asm"
incsrc "Boss/Attacks/ShootBoosSides.asm"
incsrc "Boss/Attacks/ShootBoos2.asm"
incsrc "Boss/Attacks/Figure8.asm"
incsrc "Boss/Attacks/BooSpray.asm"
incsrc "Boss/Attacks/BooSpray2.asm"
incsrc "Boss/Attacks/ShootBoosTop.asm"
incsrc "Boss/Attacks/LasersTrip.asm"
incsrc "Boss/Attacks/ScrollingBoos.asm"



!WeaponInterval = $02                   ; num of attacks before bombs are dropped
!HitsPerPhase   = $02                   ; num of hits before moving to next phase
!NumberOfPhases = $03

PrimaryStates:
        dw PrimaryInit                  ; 0
        dw PrimaryIdle                  ; 1
        dw PrimaryChoose                ; 2
        dw PrimaryAttacking             ; 3
        dw PrimaryLastHit               ; 4
        dw PrimaryEnd                   ; 5

PrimaryAttacks:
        dw DropWeapons 
Phase1Attacks:
        dw Lasers                       ; laser attack
        dw BooSpray                     ; boollet hell attack        
        dw ShootBoosSides               ; attack from sides
        dw LasersTrip                   ;\ misc attacks
        dw BooSpray2                    ;/
Phase2Attacks:
        dw Figure8   
        dw ShootBoosTop                 
        dw SpinningFireSides
        dw CeilingBoos        
        dw ShootBoos2
Phase3Attacks:
        dw SpinningFire   
        dw ShootBoos
        dw BooRings     
        dw CeilingBoos                  ; cluster boo attack
        dw ScrollingBoos                

AttackOffsets:
        db $01,$06,$0B
NumAttacks:                             ;\
        db $04,$04,$04                  ;/ not including inital laser attack

Primary:
        LDA $!BossHits                  ;\
        CMP #!HitsPerPhase              ;/ check if we've hit the boss enough times for this phase
        BCC .attack
        LDA #$04                        ;\
        STA $!MainPhase2                ;/ go to last hit phase
    .attack
        LDA $!MainPhase2
        ASL
        TAX
        JSR (PrimaryStates,x)
    .return
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 0 - Initialize Primary Phase
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrimaryInit:
        LDA #!Downtime                  ;\
        STA $00                         ;|
        STZ $01                         ;|
        REP #$20                        ;| set timer for idle phase
        LDA $00                         ;|
        STA $!GlobalTimer               ;|
        SEP #$20                        ;/

        LDA $!BossPhase                 ;\
        BNE .notPhaseOne                ;|
        STZ $!GlobalTimer               ;| unless this is phase 1, then don't idle
    .notPhaseOne                        ;/

        STZ $!SubPhase                  ;\
        STZ $!SubPhase2                 ;/ init attack state

        STZ $!AttackCounter             ; reset attack count

        LDA #$FF                        ;\
        STA $!PreviousAttack            ;/ set invalid value as previous attack

        LDA #$01
        STA $!FirstAttackOfPhase

        INC $!MainPhase2
RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 1 - Idle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrimaryIdle:
        JSR EyesIdleMovement

        REP #$20             
        LDA $!GlobalTimer               ; check if timer is zero
        SEP #$20                
        BNE .Return     
        
        JSL ResetMycelia                ; reset eyes
        INC $!MainPhase2                ; move to attack choosing phase
    .Return   
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 2 - Choosing Attack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrimaryChoose:
        LDA $!FirstAttackOfPhase
        BEQ .notFirstAttack
        STZ $!FirstAttackOfPhase
        LDA #$00
        BRA .addOffset
        
    .notFirstAttack
        LDA #!WeaponInterval            ;\
        CMP $!AttackCounter             ;| check if we should drop bombs yet
        BNE .normalAttack               ;|
        STZ $!AttackCounter             ;|
        STZ $!MainPhase3                ;| go to drop bombs phase
        BRA .doneChoosing               ;/

    .normalAttack
        LDX $!BossPhase
        LDA NumAttacks,x
        DEC
        JSL Random
        INC
    .addOffset
        LDX $!BossPhase                 ;|
        CLC : ADC AttackOffsets,x       ;| add attack phase offset 
        CMP $!PreviousAttack
        BEQ .normalAttack               ; if same as previous, try again
        STA $!PreviousAttack            ; remember this attack
        STA $!MainPhase3                ; and store to attack phase
        INC $!AttackCounter             ; tick attack counter

    .doneChoosing
        ; testing
        ;LDA #$0D
        ;STA $!MainPhase3

        ;LDA #$01
        ;STA $!BossPhase

        LDA #$03                        ;\ go to primary attacking phase
        STA $!MainPhase2                ;/
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 3 - Attacking
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrimaryAttacking:
        LDA $!MainPhase3
        ASL
        TAX
        JSR (PrimaryAttacks,x)
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 4 - Last hit of the phase
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrimaryLastHit:
        STZ $!BossHits
        JSL KillAllSpritesExceptEyesAndShells   ;\ handle attack cleanup, killing non-eye sprites (leaving shells though)
        LDX #!LeftEyeSlot                       ;| 
        STZ !sprite_speed_y,x                   ;|
        STZ !sprite_speed_x,x                   ;|
        LDX #!RightEyeSlot                      ;| stop Mycelia moving
        STZ !sprite_speed_y,x                   ;|
        STZ !sprite_speed_x,x                   ;/
        INC $!MainPhase2
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 5 - Primary Phase ending
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PrimaryEnd:
        LDA $!MyceliaTimer              ;\
        BNE .return                     ;/ wait for hit animation to end
        STZ $!MainPhase2                ; clear state
        INC $!BossPhase                 ; move to next boss phase
        LDA $!BossPhase                 ;\ 
        CMP #!NumberOfPhases            ;| check if boss should die
        BNE .poofEyes                   ;|
        LDA #$03                        ;| go to death phase
        STA $!MainPhase                 ;/ 
        BRA .return
    .poofEyes
        LDX #!LeftEyeSlot               ;\
        JSR CheckHorzOffscreen          ;|
        BCS +                           ;|
        JSR SpawnSmokeOnSprite          ;|
    +                                   ;|
        LDX #!RightEyeSlot              ;| make Mycelia disappear somewhat dramatically
        JSR CheckHorzOffscreen          ;|
        BCS +                           ;|
        JSR SpawnSmokeOnSprite          ;| only show smoke if eye is on screen
    +                                   ;|
        JSL DespawnMycelia              ;|
        LDA #$25                        ;| poof sfx
        STA $1DFC                       ;/ 
        LDA #$02                        ;\ 
        STA $!MainPhase                 ;/ go to transition phase   
    .return
RTS


!distL  =   $0010   ; distance to check offscreen on the left (0040 = 4 16x16 tiles)
!distR  =   $0010   ; distance to check offscreen on the right

CheckHorzOffscreen:
    LDA $14E0,x
    XBA
    LDA $E4,x
    REP #$20
    SEC : SBC $1A
    CLC : ADC #!distL
    CMP #$0100+!distL+!distR
    SEP #$20
RTS