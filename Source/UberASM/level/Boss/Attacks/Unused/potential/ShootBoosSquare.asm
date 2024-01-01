;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shoot Cluster Boos Toward mario while Eyes move around screen border
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SSStates:       dw SSInit
                dw SSTop1
                dw SSSides1
                dw SSBottom
                dw SSSides2
                dw SSTop2
                dw SSEnd

!SSPosSpeed = $10
!SSNegSpeed = $F0
!SSBooSpeed = $20
!SSBooInterval = $28

ShootSquare:
        LDA $!SubPhase
        ASL A
        TAX
        JSR (SSStates,x)
RTS

SSInit:
		LDX #!LeftEyeSlot
		LDA #!SSNegSpeed
		STA !sprite_speed_x,x
		LDX #!RightEyeSlot
		LDA #!SSPosSpeed 
		STA !sprite_speed_x,x
	
		INC $!SubPhase
RTS

SSTop1:
		LDA $!GlobalTimer
		BNE .checkPos
		STZ $04
		LDA #!SSBooSpeed
		STA $0D
		LDX #!LeftEyeSlot
		JSL ShootBooWithSpeeds

		STZ $04
		LDA #!SSBooSpeed
		STA $0D
		LDX #!RightEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooInterval
		STA $!GlobalTimer
	.checkPos

		LDX #!LeftEyeSlot
		LDA !sprite_x_low,x
		CMP #$08
		BCS .return
		STZ !sprite_speed_x,x
		LDA #!SSPosSpeed 
		STA !sprite_speed_y,x
		LDX #!RightEyeSlot
		STZ !sprite_speed_x,x
		STA !sprite_speed_y,x
		INC $!SubPhase
	.return
RTS

SSSides1:
		LDA $!GlobalTimer
		BNE .checkPos
		LDA #!SSBooSpeed
		STA $04
		STZ $0D
		LDX #!LeftEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooSpeed
		EOR #$FF
		INC
		STA $04
		STZ $0D
		LDX #!RightEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooInterval
		STA $!GlobalTimer
	.checkPos

		LDX #!LeftEyeSlot
		LDA !sprite_y_low,x
		CMP #$E0
		BCC .return
		STZ !sprite_speed_y,x
		LDA #!SSPosSpeed 
		STA !sprite_speed_x,x
		LDX #!RightEyeSlot
		STZ !sprite_speed_y,x
		LDA #!SSNegSpeed
		STA !sprite_speed_x,x
		INC $!SubPhase	
	.return
RTS

SSBottom:
		LDA $!GlobalTimer
		BNE .checkPos
		STZ $04
		LDA #!SSBooSpeed
		EOR #$FF
		INC
		STA $0D
		LDX #!LeftEyeSlot
		JSL ShootBooWithSpeeds

		STZ $04
		LDA #!SSBooSpeed
		EOR #$FF
		INC
		STA $0D
		LDX #!RightEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooInterval
		STA $!GlobalTimer
	.checkPos
		LDX #!LeftEyeSlot
		LDA !sprite_x_low,x
		CMP #$E8
		BCC .return
		STZ !sprite_speed_x,x
		LDA #!SSNegSpeed 
		STA !sprite_speed_y,x
		LDX #!RightEyeSlot
		STZ !sprite_speed_x,x
		STA !sprite_speed_y,x
		INC $!SubPhase
	.return
RTS

SSSides2:
		LDA $!GlobalTimer
		BNE .checkPos
		LDA #!SSBooSpeed
		EOR #$FF
		INC
		STA $04
		STZ $0D
		LDX #!LeftEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooSpeed
		STA $04
		STZ $0D
		LDX #!RightEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooInterval
		STA $!GlobalTimer
	.checkPos

		LDX #!LeftEyeSlot
		LDA !sprite_y_low,x
		CMP #!MyceliaYLo
		BCS .return
		STZ !sprite_speed_y,x
		LDA #!SSNegSpeed 
		STA !sprite_speed_x,x
		LDX #!RightEyeSlot
		STZ !sprite_speed_y,x
		LDA #!SSPosSpeed
		STA !sprite_speed_x,x
		INC $!SubPhase	
	.return
RTS

SSTop2:
		LDA $!GlobalTimer
		BNE .checkPos
		STZ $04
		LDA #!SSBooSpeed
		STA $0D
		LDX #!LeftEyeSlot
		JSL ShootBooWithSpeeds

		STZ $04
		LDA #!SSBooSpeed
		STA $0D
		LDX #!RightEyeSlot
		JSL ShootBooWithSpeeds

		LDA #!SSBooInterval
		STA $!GlobalTimer
	.checkPos

		LDX #!LeftEyeSlot
		LDA !sprite_x_low,x
		CMP #!MyceliaXLoLeft
		BCS .return
		INC $!SubPhase
	.return
RTS

SSEnd:
	    JSL AttackEnded
RTS


; Eye no. in X
; x speed in $04
; y speed in $0D
;ShootBooWithSpeeds:

SSShootBoos:
		LDA $!GlobalTimer
		BNE .return
		LDA #!SSBooSpeed
		STA $0D
		LDX #!RightEyeSlot
		JSL ShootBooAtPlayer

		LDA #!SSBooSpeed
		STA $0D
		LDX #!LeftEyeSlot
		JSL ShootBooAtPlayer

		LDA #!SSBooInterval
		STA $!GlobalTimer
	.return
RTS