;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shoot Cluster Boos Toward mario while Eyes move around screen border
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SBTStates:      dw SBTInit
				dw SBTWaitForFrame
                dw SBTShooting
                dw SBTEnd

!SBTBooSpeed 	= $20
!SBTBooInterval = $24

!SBTAccelDir    = !MiscRam1

ShootBoosTop:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SBTStates,x)
RTS

SBTInit:
		STZ $!SBTAccelDir

		LDX #$00
		LDA SBTDeltas,x
		STA $!GlobalTimer

		LDA #!SBTBooInterval
		STA $!GlobalTimer2

		INC $!SubPhase
RTS

; Ensure the next phase starts on the right frame parity, since it updates speed every other frame
; Alternative would be to handle fractional speeds, but it's not worth it here
SBTWaitForFrame:
		LDA $14
		AND #$01
		BNE .return
		INC $!SubPhase
	.return
RTS

SBTDeltas:
	db $44,$96,$88,$38
	;db $44,$96,$A8,$96,$44
SBTTableSize:


SBTAccels:
	db $01, $FF

SBTShooting:
		LDA $!GlobalTimer2
		BNE .checkAccelTimer
		LDA #!SBTBooSpeed
		STA $0D
		LDX #!LeftEyeSlot
		JSL ShootBooAtPlayer
	
		LDA #!SBTBooSpeed
		STA $0D
		LDX #!RightEyeSlot
		JSL ShootBooAtPlayer
	
		LDA #!SBTBooInterval
		STA $!GlobalTimer2

    .checkAccelTimer
        LDA $14                     ;\ 
        AND #$01                    ;| Only update speed every other frame
        BEQ .return                 ;/
    	LDA $!GlobalTimer
    	BNE .move
    	INC $!SBTAccelDir
    	INC $!SubPhase2
    	LDA $!SubPhase2
    	CMP.b #SBTTableSize-SBTDeltas
    	BNE .setTimer
    	INC $!SubPhase
    	BRA .return

  	.setTimer 
    	LDX $!SubPhase2
    	LDA SBTDeltas,x
    	STA $!GlobalTimer

    .move
    	LDA $!SBTAccelDir
    	AND #$01
    	TAY
    	LDX #!LeftEyeSlot
    	LDA !sprite_speed_x,x
    	CLC : ADC SBTAccels,y
    	STA !sprite_speed_x,x
    	LDX #!RightEyeSlot
    	TYA
    	EOR #$01
    	TAY
    	LDA !sprite_speed_x,x
    	CLC : ADC SBTAccels,y
    	STA !sprite_speed_x,x
	.return
RTS

SBTEnd:
	    JSL AttackEnded
RTS