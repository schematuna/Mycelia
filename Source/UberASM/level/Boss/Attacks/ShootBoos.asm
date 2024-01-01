;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shoot Cluster Boos (CREDIT MARKALARM and WORLDPEACE)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SBAngleLeft          = !MiscRam1
!SBAngleRight         = !MiscRam2
!SBAngleLeftSpeedDir  = !MiscRam3
!SBAngleRightSpeedDir = !MiscRam4

!SBNumShots           = $0E
!SBBooSpeed           = $2A
!SBMaxAngle           = $C0
!SBMinAngle           = $40
!SBFireInterval       = $1B

; How fast the shooting angle changes
SBAngleDeltas:
db $1F, $E1


SBStates: dw SBInit
          dw SBMain
          dw SBEnd

ShootBoos:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SBStates,x)
RTS

SBInit:
        ; pretty unhinged randomness here
        ; with starting angles and directions
        LDA #!SBMaxAngle
        SEC : SBC #!SBMinAngle
        JSL Random
        STA $!SBAngleLeft
        LDA #$01
        JSL Random
        STA $!SBAngleLeftSpeedDir
        LDA #!SBMaxAngle
        SEC : SBC #!SBMinAngle
        JSL Random
        STA $!SBAngleRight
        LDA #$01
        JSL Random
        STA $!SBAngleRightSpeedDir

        INC $!SubPhase
RTS

SBMain:
        LDA $!GlobalTimer
        BNE .return

        LDX #$00                                        ;\
        JSR SBOscillateAngle                            ;|
        STA $!SBAngleLeft                               ;| update left angle
        STA $04                                         ;|
        LDA #!SBBooSpeed                                ;|
        STA $0D                                         ;|
        LDX #$00                                        ;| and shoot a boo
        JSL ShootBooWithAngle                           ;/

        LDX #$01                                        ;\
        JSR SBOscillateAngle                            ;|
        STA $!SBAngleRight                              ;| update right angle
        STA $04                                         ;|
        LDA #!SBBooSpeed                                ;|
        STA $0D                                         ;|
        LDX #$01                                        ;| and shoot a boo
        JSL ShootBooWithAngle                           ;/

        INC $!SubPhase2                                 ;\ 
        LDA $!SubPhase2                                 ;|
        CMP #!SBNumShots                                ;| check if attack is over
        BNE +                                           ;|
        INC $!SubPhase                                  ;/
    +

        LDA #!SBFireInterval 
        STA $!GlobalTimer
    .return
RTS

SBEnd:
        JSL AttackEnded
RTS

; These addresses are assumed to be absolute addresses!
SBAngleSpeedDirs:
dw $!SBAngleLeftSpeedDir,$!SBAngleRightSpeedDir
SBAngles:
dw $!SBAngleLeft,$!SBAngleRight

; Eye no. in X
; Angle out A
SBOscillateAngle:
        TXA                                             ;\
        ASL                                             ;|
        TAX                                             ;|
        REP #$20                                        ;|
        LDA SBAngleSpeedDirs,x                          ;| set up eye-specific absolute addresses
        STA $00                                         ;|
        LDA SBAngles,x                                  ;|
        STA $02                                         ;|
        SEP #$20                                        ;/

        LDA ($00)                                       ;\ 
        AND #$01                                        ;| Get our direction of acceleration (0 or 1)
        TAY                                             ;/
        LDA ($02)                                       ;\   
        CLC : ADC SBAngleDeltas,y                       ;| increment the current angle
        CMP #!SBMaxAngle                                ;| 
        BCS .over                                       ;| check if it's over the max
        CMP #!SBMinAngle                                ;|
        BCC .under                                      ;| or under the min
        BRA +                                           ;/ or neither
    .over
        SEC : SBC #!SBMaxAngle                          ;\
        STA $05                                         ;|
        LDA #!SBMaxAngle                                ;| mirror angle over max
        SEC : SBC $05                                   ;|
        BRA .changeDir                                  ;/
    .under
        STA $05                                         ;\
        LDA #!SBMinAngle                                ;| mirror angle over min
        SEC : SBC $05                                   ;|
        CLC : ADC #!SBMinAngle                          ;/
    .changeDir
        PHA                                             ;\
        LDA ($00)                                       ;|
        INC                                             ;| If we crossed over a max, reverse the direction of acceleration
        STA ($00)                                       ;|
        PLA                                             ;/
    +
RTS