;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 3 - Spikes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!SpikeSpawnDelta = $10
!NumSpikes = $08

SpikeXLo:
    db $10,$30,$50,$70,$90,$B0,$D0,$F0

FallingSpikes:
        LDA $!GlobalTimer           ;\ 
        BNE .Return                 ;/ if timer is 0...

        LDX $!SubPhase              ;\
        CPX #!NumSpikes             ;| check if attack is finished,
        BNE +                       ;/
        JSL AttackEnded
        BRA .Return                 ; skip updates
    +

        LDA #$01
        STA $!SpriteState
        LDA #$4B
        STA $!SpriteNumber
        STZ $!ExtraByte1
        STZ $!ExtraByte2
        STZ $!ExtraByte3
        STZ $!ExtraByte4
        LDA #$08
        STA $!ExtraBits
        STZ $!YSpeed
        STZ $!XSpeed
        LDA SpikeXLo,x
        STA $!XLo
        LDA #$01
        STA $!XHi
        LDA #$10
        STA $!YLo
        LDA #$01
        STA $!YHi

        JSL SpawnCustomSprite

        LDA #!SpikeSpawnDelta       ;\
        STA $!GlobalTimer           ;/ set timer

        INC $!SubPhase
    .Return
RTS