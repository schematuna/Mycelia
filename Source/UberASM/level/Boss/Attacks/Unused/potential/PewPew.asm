;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; State 7 - Pew Pew
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PPStates: dw PPInit
          dw PPGrow
          dw PPFired

PewPew:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (PPStates,x)
RTS

PPInit:
        REP #$20
        LDA $D1                         ;\
        STA $!MiscRam1                  ;|
        LDA $D3                         ;| remember mario position for later use
        STA $!MiscRam3                  ;/
        SEP #$20

        LDX #!LeftEyeSlot               ;\
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam1                  ;| get x offset between left eye and mario
        STA $00                         ;|
        SEP #$20                        ;/
        
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam3                  ;| get y offset between left eye and mario
        STA $02                         ;|
        SEP #$20                        ;/

        JSL GetAtan2

        REP #$20                        ;\
        LDA $04                         ;| angle out of subroutine
        LSR                             ;| move into firebar initial angle range
        ADC #$0080                      ;| and invert angle
        SEP #$20                        ;|
        STA $!ExtraByte3                ;|
        STZ $!ExtraByte1                ;|
        STZ $!ExtraByte2                ;|
        LDX #!LeftEyeSlot               ;|
        JSL SpawnFirebar                ;|
        STX $!SpriteSlot1               ;/


        LDX #!RightEyeSlot              ;\
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam1                  ;| get x offset between right eye and mario
        STA $00                         ;|
        SEP #$20                        ;/
        
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam3                  ;| get y offset between right eye and mario
        STA $02                         ;|
        SEP #$20                        ;/

        JSL GetAtan2

        REP #$20                        ;\
        LDA $04                         ;| angle out of subroutine
        LSR                             ;| move into firebar initial angle range
        ADC #$0080                      ;| and invert angle
        SEP #$20                        ;|
        STA $!ExtraByte3                ;|
        STZ $!ExtraByte1                ;|
        STZ $!ExtraByte2                ;|
        LDX #!RightEyeSlot              ;|
        JSL SpawnFirebar                ;|
        STX $!SpriteSlot2               ;/

        INC $!SubPhase
RTS


PPGrow:
        LDX $!SpriteSlot1
        LDA $!FireBarLength,x           ;\ grow firebars
        CMP #$08                        ;| 13 is the limit without running out of sprite tiles
        BEQ +                           ;|
        LDA $14                         ;\ 
        AND #$01                        ;| skip every other frame, to slow it down a little
        BEQ .Return                     ;/
        INC $!FireBarLength,x           ;|
        LDX $!SpriteSlot2               ;|
        INC $!FireBarLength,x           ;/
        BRA .Return
    +
        
        LDX #!LeftEyeSlot               ;\
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam1                  ;| get x offset between left eye and mario
        STA $00                         ;|
        SEP #$20                        ;/
        
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam3                  ;| get y offset between left eye and mario
        STA $02                         ;|
        SEP #$20                        ;/

        LDA #$40
        JSL AimingRoutine

        LDX $!SpriteSlot1               ;\
        LDA $00
        STA !sprite_speed_x,x           ;|
        LDA $02
        STA !sprite_speed_y,x           ;|


        LDX #!RightEyeSlot              ;\
        LDA !sprite_x_high,x            ;|
        XBA                             ;|
        LDA !sprite_x_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam1                  ;| get x offset between right eye and mario
        STA $00                         ;|
        SEP #$20                        ;/
        
        LDA !sprite_y_high,x            ;\
        XBA                             ;|
        LDA !sprite_y_low,x             ;|
        REP #$20                        ;|
        SBC $!MiscRam3                  ;| get y offset between right eye and mario
        STA $02                         ;|
        SEP #$20                        ;/

        LDA #$40
        JSL AimingRoutine

        LDX $!SpriteSlot2               ;\
        LDA $00
        STA !sprite_speed_x,x           ;|
        LDA $02
        STA !sprite_speed_y,x           ;|

        LDA #$40
        STA $!GlobalTimer

        INC $!SubPhase

    .Return
RTS

PPFired:
        LDA $!GlobalTimer
        BNE .Return

        LDX $!SpriteSlot1           ;\
        STZ !sprite_status,x        ;|
        LDX $!SpriteSlot2           ;| despawn lasers
        STZ !sprite_status,x        ;/

        STZ $!SubPhase
    .Return
RTS