incsrc "../../library/BossDefs.asm"

!CommonAccelDir = !MiscRam1         ; defs for this file

; macros since subroutines don't play well with pushing/pulling to the stack asymetrically
macro preserve_scratch()
        LDA #$00         
        TAX              
    .Stash               
        LDA $00,x        
        PHA              
        INX              
        CPX #$10         
        BNE .Stash       
endmacro

macro restore_scratch()
        LDA #$0F      
        TAX           
    .Pop              
        PLA           
        STA $00,x     
        DEX           
        CPX #$FF      
        BNE .Pop      
endmacro

AttackEnded:
        JSL ResetMycelia                ; reset eye movement
        STZ $!SubPhase                  ;\ reset attack state
        STZ $!SubPhase2                 ;/
        LDA #$01                        ;\ set primary phase to Idle
        STA $!MainPhase2                ;/
        LDA #!Downtime                  ;\
        STA $00                         ;|
        STZ $01                         ;|
        REP #$20                        ;| set timer for idle phase
        LDA $00                         ;|
        STA $!GlobalTimer               ;|
        SEP #$20                        ;/
RTL

KillAllSpritesExceptEyesAndShells:
        ;LDX #12
        ;.Loop
        ;STZ !sprite_status,x
        ;DEX
        ;CPX #$01
        ;BNE .Loop
        ; above messes with eyes, keep it simple for now
        LDX $!SpriteSlot1               ;\ despawn extra sprites
        LDA !sprite_num,x               ;|
        CMP #$04                        ;| if its a green koopa (shell)
        BEQ +                           ;| don't despawn it
        STZ !sprite_status,x            ;|
    +                                   ;|
        LDX $!SpriteSlot2               ;|
        LDA !sprite_num,x               ;| 
        CMP #$04                        ;| if it's a green koopa (shell)
        BEQ ++                          ;| don't despawn it
        STZ !sprite_status,x            ;/
    ++
RTL

SpawnCustomSprite:
        JSL $02A9DE                     ;\ find empty sprite slot
        BMI +                           ;/ aborting if none are available
        TYX                             ; move sprite number to X (07F7D2 assumes sprite slot is in X)
        JSL SpawnCustomSpriteWithSlot
    +
RTL


; sprite slot in X
SpawnCustomSpriteWithSlot:
        LDA $!SpriteState           ;\ set custom sprite state
        STA !sprite_status,x        ;/
        LDA $!SpriteNumber          ;\ set custom sprite number
        STA !new_sprite_num,x       ;/

        LDA $!XLo                   ;\
        STA !sprite_x_low,x         ;|
        LDA $!XHi                   ;|
        STA !sprite_x_high,x        ;| set sprite position
        LDA $!YLo                   ;|
        STA !sprite_y_low,x         ;|
        LDA $!YHi                   ;|
        STA !sprite_y_high,x        ;/

        JSL $07F7D2                 ;\ reset sprite tables
        JSL $0187A7                 ;/ and clear additional custom sprite data

        LDA $!ExtraByte1            ;\
        STA !extra_byte_1,x         ;|
        LDA $!ExtraByte2            ;|
        STA !extra_byte_2,x         ;|
        LDA $!ExtraByte3            ;| set extra bytes
        STA !extra_byte_3,x         ;|
        LDA $!ExtraByte4            ;|
        STA !extra_byte_4,x         ;/

        LDA $!YSpeed                ;\          
        STA !sprite_speed_y,x       ;| set sprite speed
        LDA $!XSpeed                ;|
        STA !sprite_speed_x,x       ;/

        LDA $!ExtraBits             ;\ mark as custom sprite and set extra bit
        STA !extra_bits,x           ;/
    .NoSpawn
RTL


SpawnNormalSprite:
        JSL $02A9DE
        BMI +
        TYX
        LDA $!SpriteState
        STA !sprite_status,x
        LDA $!SpriteNumber
        STA !sprite_num,x

        LDA $!XLo
        STA !sprite_x_low,x
        LDA $!XHi
        STA !sprite_x_high,x
        LDA $!YLo
        STA !sprite_y_low,x
        LDA $!YHi
        STA !sprite_y_high,x
        JSL $07F7D2
    +
RTL

; Special cluster sprite number in X
; Works with:
; E1: Boo Ceiling
; E4: Swooper Death Bat Ceiling (requires GFX fix)
; E5: Appearing/disappearing boos
; E6: Background candle flames
InitSpecialSprite:
        phb                             ;\ 
        lda #$02 : pha : plb            ;/ Set DB to $02
        PHK                             ;\
        PEA .jslrtsreturn-1             ;|
        PEA $B889-1                     ;/
        TXA                             ;| move special sprite number to A
        JML $02AAC0|!bank               ;| JSL-to-RTS call to the special cluster sprite init code
        .jslrtsreturn:                  ;|
        plb                             ;/
RTL


; Sprite oscillation code borrowed from Thomas
YAccelerations:
db $01, $FF
MaxYSpeeds:
db $05, $FB
EyesIdleMovement:
        LDA $14                     ;\ 
        AND #$01                    ;| Only update sprite oscillation every other frame, to keep it slow
        BEQ +                       ;/
        LDA $!CommonAccelDir        ;\ 
        AND #$01                    ;| Get our direction of acceleration (0 or 1)
        TAY                         ;/
        LDX #!LeftEyeSlot           ;\
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC YAccelerations,y        ;|
        STA !sprite_speed_y,x       ;|
        LDX #!RightEyeSlot          ;|  Update the eyes' speed based on that 
        LDA !sprite_speed_y,x       ;|
        CLC                         ;|
        ADC YAccelerations,y        ;|
        STA !sprite_speed_y,x       ;/
        CMP MaxYSpeeds,y            ;\ 
        BNE +                       ;| If at max speed, reverse the direction of acceleration
        INC $!CommonAccelDir        ;/
    +
RTS

; Input: Firebar sprite slot in X
; Sprite oscillation code borrowed from Thomas
LengthChanges:
db $FF, $01
LengthLimits:
db $00, $0F
OscLength:
        LDA $14                     ;\ 
        AND #$03                    ;| skip every fourth frame, to slow it down a little
        BEQ .Return                 ;/
        LDA !sprite_misc_1510,x     ;\
        AND #$01                    ;| Get our direction of growth (0 or 1)
        TAY                         ;/
        LDA $!FireBarLength,x       ;\
        CMP LengthLimits,y          ;| 
        BNE +                       ;| If at length limit, reverse the direction of growth
        INC !sprite_misc_1510,x     ;| store new direction to left laser unused misc ram
        LDA !sprite_misc_1510,x     ;| 
        AND #$01                    ;| and update direction of growth (0 or 1)
        TAY                         ;/
    +
        LDA $!FireBarLength,x       ;\
        CLC                         ;| update firebar length accordingly
        ADC LengthChanges,y         ;|
        STA $!FireBarLength,x       ;/

    .Return
RTL

SpawnMycelia:
        LDA #$01
        STA $!SpriteState
        LDA #$49
        STA $!SpriteNumber
        LDA #!MyceliaXLoLeft
        STA $!XLo
        LDA $!MyceliaXHi
        STA $!XHi
        LDA #!MyceliaYLo
        STA $!YLo
        LDA #!MyceliaYHi
        STA $!YHi
        STZ $!ExtraByte1
        STZ $!ExtraByte2
        STZ $!ExtraByte3
        STZ $!ExtraByte4
        STZ $!YSpeed
        STZ $!XSpeed
        LDA #$08
        STA $!ExtraBits

        %preserve_scratch()

        LDX #!LeftEyeSlot               ;\ ensure Mycelia's eyes are in lowest slots so they draw below other sprites
        JSL SpawnCustomSpriteWithSlot   ;/

        %restore_scratch()

        LDA #!MyceliaXLoRight
        STA $!XLo
        LDA #$0C
        STA $!ExtraBits

        LDX #!RightEyeSlot
        JSL SpawnCustomSpriteWithSlot
RTL


ResetMycelia:
        STZ $!CommonAccelDir 

        LDX #!LeftEyeSlot
        LDA #!MyceliaXLoLeft
        STA !sprite_x_low,x
        LDA $!MyceliaXHi
        STA !sprite_x_high,x
        LDA #!MyceliaYLo
        STA !sprite_y_low,x
        LDA #!MyceliaYHi
        STA !sprite_y_high,x
        STZ !sprite_speed_y,x
        STZ !sprite_speed_x,x

        LDX #!RightEyeSlot
        LDA #!MyceliaXLoRight
        STA !sprite_x_low,x
        LDA $!MyceliaXHi
        STA !sprite_x_high,x
        LDA #!MyceliaYLo
        STA !sprite_y_low,x
        LDA #!MyceliaYHi
        STA !sprite_y_high,x
        STZ !sprite_speed_y,x
        STZ !sprite_speed_x,x
RTL

DespawnMycelia:
        LDX #!LeftEyeSlot   
        STZ !sprite_status,x
        LDX #!RightEyeSlot  
        STZ !sprite_status,x
RTL

; Will increment subphase once Mycelia is despawned
MoveUpAndDespawnMycelia:
        LDX #!LeftEyeSlot               ; use left eye as proxy for y position of both eyes
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|  
        REP #$20                        ;|
        CMP #$00E0                      ;| check if eyes are above screen yet
        SEP #$20                        ;/
        BCS +   
        LDX #!LeftEyeSlot               ;\
        STZ !sprite_status,x            ;|
        LDX #!RightEyeSlot              ;| despawn Mycelia
        STZ !sprite_status,x            ;/

        INC $!SubPhase
    +

        LDX #!LeftEyeSlot               ;\
        DEC !sprite_speed_y,x           ;|
        LDX #!RightEyeSlot              ;| accelerate eyes upwards
        DEC !sprite_speed_y,x           ;/
RTL

; Input:  Eye slot in X
;         Extra Bytes 1,2,3 already set up
; Output: Firebar slot in X
SpawnFirebar:
        LDA #$01
        STA $!SpriteState
        LDA #$4A
        STA $!SpriteNumber

        LDA !sprite_x_low,x                     ;\
        CPX #!LeftEyeSlot                       ;| set firebar x position
        BNE +                                   ;|
        CLC : ADC #!PupilXOffsetLeft            ;| apply offset depending on eye slot
        BRA ++                                  ;|
    +                                           ;| 
        CLC : ADC #!PupilXOffsetRight           ;|
    ++                                          ;|
        STA $!XLo                               ;|
        LDA !sprite_x_high,x                    ;|
        ADC #$00                                ;|
        STA $!XHi                               ;/

        LDA !sprite_y_low,x
        CLC : ADC #!PupilYOffset
        STA $!YLo
        LDA !sprite_y_high,x
        ADC #$00
        STA $!YHi

        STZ $!ExtraByte4
        STZ $!YSpeed
        STZ $!XSpeed
        LDA #$08
        STA $!ExtraBits

        JSL SpawnCustomSprite
RTL


; set firebars on eye pupils
UpdateFirebarPositions:
        LDX #!LeftEyeSlot
        LDA !sprite_x_low,x
        CLC : ADC #!PupilXOffsetLeft
        STA $00
        LDA !sprite_x_high,x
        ADC #$00
        STA $01

        LDA !sprite_y_low,x
        CLC : ADC #!PupilYOffset
        STA $02
        LDA !sprite_y_high,x
        ADC #$00
        STA $03

        LDX $!SpriteSlot1
        LDA $00
        STA !sprite_x_low,x
        LDA $01
        STA !sprite_x_high,x
        LDA $02
        STA !sprite_y_low,x
        LDA $03
        STA !sprite_y_high,x

        LDX #!RightEyeSlot
        LDA !sprite_x_low,x
        CLC : ADC #!PupilXOffsetRight
        STA $00
        LDA !sprite_x_high,x
        ADC #$00
        STA $01

        LDA !sprite_y_low,x
        CLC : ADC #!PupilYOffset
        STA $02
        LDA !sprite_y_high,x
        ADC #$00
        STA $03

        LDX $!SpriteSlot2
        LDA $00
        STA !sprite_x_low,x
        LDA $01
        STA !sprite_x_high,x
        LDA $02
        STA !sprite_y_low,x
        LDA $03
        STA !sprite_y_high,x
RTL


CommonEyeXLos:
db !MyceliaXLoLeft, !MyceliaXLoRight
CommonBooTiles:
db $88,$8C,$8E,$A8,$AA,$AE
CommonNumTiles:

!bulletAmount         = 20                                      ; maximum number of cluster bullets to have on screen, do not set higher than 20 or I will be sad
!bulletSpriteNum      = $01                                     ; cluster sprite number as defined in list.txt

!shootSFX             = $27                                     ; if $00, it won't play a sound effect
!shootChannel         = $1DFC                                   ; should either be $1DF9 or $1DFC. check out https://www.smwcentral.net/?p=viewthread&t=6665 for a detailed list of sound effecta

!cluster_speed_y      = $1E52
!cluster_speed_x      = $1E66
!cluster_speed_y_frac = $1E7A
!cluster_speed_x_frac = $1E8E

!cluster_expire_timer = $0F4A
!cluster_tile         = $0F72
!cluster_props        = $0F86

!ClusterOffset        = $09                                     ; usually a pixi define

!cluster_num          = $1892
!cluster_y_low        = $1E02
!cluster_y_high       = $1E2A
!cluster_x_low        = $1E16
!cluster_x_high       = $1E3E

; Eye no. in X
; Angle in $04
; Speed in $0D
ShootBooWithAngle:
        LDY #!bulletAmount-1                            ; \ load the highest possible slot index
        -                                               ; | 
        LDA !cluster_num,y                              ; | load the cluster sprite number
        BEQ +                                           ; | if zero, then a bullet can be spawned
        DEY                                             ; | if not found, try another slot
        BPL -                                           ; | if no more slots
        BRA .return                                     ; / just return
        
        +

        JSR BooShooterInit
        
        LDA #$10                                        ;\ arbitrary radius
        STA $06                                         ;/
        
        LDA #$01        
        XBA     
        LDA $04 
        REP #$20        
        STA $04 
        SEP #$20        
        
        JSL CircleX                                     ;\ use angle set early to get x and y displacements
        JSL CircleY                                     ;/
        
        REP #$20                                        ;\
        LDA $07                                         ;| 
        STA $00                                         ;| transfer output of circle subroutine to correct scratch
        LDA $09                                         ;|
        STA $02                                         ;|
        SEP #$20                                        ;|
        LDA $0D                                         ;| load speed
        JSL AimingRoutine                               ;/ 
        
        LDA $00                                         ;\
        STA !cluster_speed_x,y                          ;| and store resulting speeds to the cluster sprite
        LDA $02                                         ;|
        STA !cluster_speed_y,y                          ;/
    .return
RTL

; Eye no. in X
; Speed in $0D
ShootBooAtPlayer:
        LDY #!bulletAmount-1                            ; \ load the highest possible slot index
    -                                                   ; | 
        LDA !cluster_num,y                              ; | load the cluster sprite number
        BEQ +                                           ; | if zero, then a bullet can be spawned
        DEY                                             ; | if not found, try another slot
        BPL -                                           ; | if no more slots
        BRA .return                                     ; / just return
        
    +

        JSR BooShooterInit
        
        LDA !sprite_x_high,x                             ; get eye x pos low byte
        XBA
        LDA !sprite_x_low,x
        REP #$20
        SEC : SBC $D1                                   ; subract player x pos
        STA $00
        SEP #$20

        LDA !sprite_y_high,x                             ; get eye y pos low byte
        XBA
        LDA !sprite_y_low,x
        REP #$20
        SEC : SBC $D3                                   ; subract player x pos
        STA $02
        SEP #$20
        
        LDA $0D                                         ;| load speed
        JSL AimingRoutine                               ;/ 
        
        LDA $00                                         ;\
        STA !cluster_speed_x,y                          ;| and store resulting speeds to the cluster sprite
        LDA $02                                         ;|
        STA !cluster_speed_y,y                          ;/
    .return
RTL

; Eye no. in X
; x speed in $04
; y speed in $0D
ShootBooWithSpeeds:
        LDY #!bulletAmount-1                            ; \ load the highest possible slot index
        -                                               ; | 
        LDA !cluster_num,y                              ; | load the cluster sprite number
        BEQ +                                           ; | if zero, then a bullet can be spawned
        DEY                                             ; | if not found, try another slot
        BPL -                                           ; | if no more slots
        BRA .return                                     ; / just return
        
        +

        JSR BooShooterInit

        LDA $04                                         ;\
        STA !cluster_speed_x,y                          ;| 
        LDA $0D                                         ;|
        STA !cluster_speed_y,y                          ;/
    .return
RTL

BooShooterInit:
        LDA #$01                                        ; \ run cluster sprite code
        STA $18B8                                       ; /

        LDA.b #!bulletSpriteNum+!ClusterOffset          ; \ store bullet number
        STA !cluster_num,y                              ; /
        
        LDA #!shootSFX                                  ; \ play sound effect when shot
        BEQ +                                           ; |
        STA !shootChannel                               ; |
        +                                               ; /
        
        PHX
        LDA CommonEyeSlots,x
        TAX 
        LDA !sprite_x_low,x                             ; \ have cluster sprite spawn at the shooter's x position
        STA !cluster_x_low,y                            ; |
        LDA !sprite_x_high,x                            ; |
        STA !cluster_x_high,y                           ; /
        
        LDA !sprite_y_low,x                             ; \ have cluster sprite spawn at the shooter's y position
        STA !cluster_y_low,y                            ; |
        LDA !sprite_y_high,x                            ; |
        STA !cluster_y_high,y                           ; /
        
        LDA.b #CommonNumTiles-CommonBooTiles-1
        JSL Random
        TAX
        LDA CommonBooTiles,x                            ; \ load wanted tile
        STA !cluster_tile,y                             ; | store it into cluster sprite table
        LDA #$3F                                        ; | load wanted props
        STA !cluster_props,y                            ; / store it into cluster sprite table
        PLX
        
        LDA #$00
        STA !cluster_expire_timer,y
RTS

; x position in $04 (low byte)
; y position in $0D (low byte)
; Cluster number out Y
; set your own speed
SpawnBooAtPosition:
        LDY #!bulletAmount-1                            ; \ load the highest possible slot index
        -                                               ; | 
        LDA !cluster_num,y                              ; | load the cluster sprite number
        BEQ +                                           ; | if zero, then a bullet can be spawned
        DEY                                             ; | if not found, try another slot
        BPL -                                           ; | if no more slots
        BRA .return                                     ; / just return
        
        +

        LDA #$01                                        ; \ run cluster sprite code
        STA $18B8                                       ; /

        LDA.b #!bulletSpriteNum+!ClusterOffset          ; \ store bullet number
        STA !cluster_num,y                              ; /
        
        LDA #!shootSFX                                  ; \ play sound effect when shot
        BEQ +                                           ; |
        STA !shootChannel                               ; |
        +                                               ; /
        
        LDA $04                                         ; \ have cluster sprite spawn at the shooter's x position
        STA !cluster_x_low,y                            ; |
        LDA $1463                                       ; | use layer 1 x position as proxy
        STA !cluster_x_high,y                           ; /
        
        LDA $0D                                         ; \ have cluster sprite spawn at the shooter's y position
        STA !cluster_y_low,y                            ; |
        LDA $1465                                        ; | use layer 1 y position as proxy
        STA !cluster_y_high,y                           ; /
        
        LDA.b #CommonNumTiles-CommonBooTiles-1
        JSL Random
        TAX
        LDA CommonBooTiles,x                            ; \ load wanted tile
        STA !cluster_tile,y                             ; | store it into cluster sprite table
        LDA #$3F                                        ; | load wanted props
        STA !cluster_props,y                            ; / store it into cluster sprite table
        
        LDA #$00
        STA !cluster_expire_timer,y
    .return
RTL


; $00 is target x position low byte
; $01 is target x position high byte
; $02 is target y position low byte
; $03 is target y position high byte
; $04 is speed of movement
; X is sprite slot of sprite to move
SetSpriteSpeedTowardPoint:
        LDA !sprite_x_low,x         ;\
        SEC : SBC $00               ;| $00 = Sprite X pos - target X pos
        STA $00                     ;|
        LDA !sprite_x_high,x        ;| 
        SBC $01                     ;|
        STA $01                     ;/

        LDA !sprite_y_low,x         ;\
        SEC : SBC $02               ;|
        STA $02                     ;| $02 = Sprite Y pos - target Y pos
        LDA !sprite_y_high,x        ;|
        SBC $03                     ;|
        STA $03                     ;/

        PHX
        LDA $04
        JSL AimingRoutine
        PLX

        LDA $02                     ;\
        STA !sprite_speed_y,x       ;| set speeds
        LDA $00                     ;|
        STA !sprite_speed_x,x       ;/
RTL

; sprite slot in X
SpawnSmokeOnSprite:
        STZ $00 : STZ $01
        LDA #$1B : STA $02
        LDA #$01
        JSL SpawnSmoke
RTS

; sprite slot in X
SpawnGlitterOnSprite:
        STZ $00 : STZ $01
        LDA #$1B : STA $02
        LDA #$05
        JSL SpawnSmoke
RTS