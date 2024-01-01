; Mycelia main boss sprite
; heavily aided by MFG's sprite coding tutorial

incsrc "../../UberASM/library/BossDefs.asm"

print "INIT ",pc
		STZ $!MyceliaPhase   	; init phase
RTL

print "MAIN ",pc
		PHB : PHK : PLB
		JSR MyceliaMain
		PLB
RTL

MyceliaMain:
		JSR Graphics

        LDA $9D                 ;\ check the 'lock animation and sprites' flag
        ORA $13D4               ;| and paused flag
		BNE .return 			; and don't update any state if they are set

		JSL $018022 			; Call routine to update X position
		JSL $01801A 			; and Y position

		JSL $01A7DC|!BankB		;\ if mario interacts
		BCC + 					;|
		JSL $00F5B7|!BankB		;/ hurt mario
	+

		JSR SpriteInteract      ; sprite interact routine

	    LDA $!MyceliaPhase      ; set animation states, pretty much
	    JSL $0086DF
	    dw Idle
	    dw GotHit

	 .return
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sprite state 0 - Normal state, oscillating
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Idle:
	    LDA !15F6,x 			 ;\
	    AND #$F5 				 ;| make sure palette is always correct
	    ORA #$04  				 ;|
	    STA !15F6,x 			 ;/
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sprite state 1 - Got Hit (also from big boo boss asm)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GotHit:
		LDA $!MyceliaTimer       ; \ if the timer is set...
	    BNE .setPal              ; /
	    STZ $!MyceliaPhase       ; reset sprite state
		RTS                      ; return

	.setPal	    
		AND #$0E                ; set timer value for the flashing palette
	    EOR !15F6,x             ; set flashing palette
	    STA !15F6,x             ; store sprite palette
RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sprite interact routine (tuna: taken from big boo boss asm)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SpriteInteract:    
		LDY #!SprSize-1         ; 
	Loop:	
		LDA !14C8,y             ; \ if the sprite status is..
		CMP #$09                ;  | ...shell-like
		BEQ ProcessSprite       ; /
		CMP #$0A                ; \ ...throwned shell-like
		BEQ ProcessSprite       ; /
	NextSprite:	    
		DEY                     ;
		BPL Loop                ; ...otherwise, loop
		RTS                     ; return
	ProcessSprite:	    
		PHX                     ; push x
		TYX                     ; transfer x to y
		JSL $03B6E5		        ; get sprite clipping B routine
		PLX                     ; pull x
		JSL $03B69F		        ; get sprite clipping A routine
		JSL $03B72B	            ; check for contact routine
		BCC NextSprite          ;

		LDA #$01                ; \ set sprite state
		STA $!MyceliaPhase      ; /
		LDA #$40                ; \ set timer
		STA $!MyceliaTimer      ; /
		INC $!BossHits  		; increase boss hit count

		PHX                     ; push x
		TYX                     ; transfer x to y

		STZ !14C8,x             ; destroy the sprite

	BlockSetup:
	    LDA !E4,x               ; \ setup block properties
        STA $9A                 ;  |
        LDA !14E0,x             ;  |
        STA $9B                 ;  |
        LDA !D8,x               ;  |
        STA $98                 ;  |
        LDA !14D4,x             ;  |
        STA $99                 ; /

	ExplodingBlock:    
		PHB                     ; \ set the exploding block routine
		LDA #$02                ;  |
		PHA                     ;  |
		PLB                     ;  |
		LDA #$FF                ;  | $FF = set flashing palette
		JSL $028663	            ;  |
		PLB                     ; /

		PLX                     ; pull x
		LDA #$28                ; \ sound effect
		STA $1DFC 		        ; /
RTS                      		; return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sprite graphics routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Tiles:
db $84,$86
db $A4,$A6

XOffset:
db $F8,$08	; Left tiles: Moved by eight pixels to the left
db $F8,$08	; Right tiles: Moved by eight pixels to the right

db $08,$F8	; Left tiles: Moved by eight pixels to the right
db $08,$F8	; Right tiles: Moved by eight pixels to the left

YOffset:
db $F0,$F0	; Top tiles: Moved by sixteen pixels to the left
db $00,$00	; Bottom tiles: No displacement

Graphics:
		%GetDrawInfo()

		LDA !7FAB10,x 			;\ Check if extra bit is set
		AND #$04				;|
		BEQ .NoFlip				;/ And don't flip sprite if it is

		LDA #$04 				;\ 
		STA $04 				;| Store x tile offset to scratch RAM
		LDA #$40				;| And initalize properties bits with X flip bit set
		BRA .StoreProperties 	;/

		.NoFlip 				;\ Otherwise
		STZ $04 				;| zero x tile offset RAM
		LDA #$00 				;/ And initialize properties bits to zero

		.StoreProperties
		ORA $15F6,x				;\ OR with YXPPCCCT properties for sprite (set in CFG editor)
		ORA $64					;| OR with default priority for current level mode
		STA $03 				;/ store to scratch

		LDA #$03				;\ loop over four tiles
		STA $05 				;/
	.GFXLoop
		LDA $05					; Load loop counter
		CLC : ADC $04 			; Add x tile offset in case extra bit is set and sprite is flipped
		TAX
		LDA XOffset,x
		CLC : ADC $00
		STA $0300,y				; X position
		LDA $05
		TAX
		LDA Tiles,x
		STA $0302,y				; Tile number

		LDX $05					; Load loop counter for the rest of the settings
		LDA YOffset,x
		CLC : ADC $01
		STA $0301,y				; Y position
		
		LDA $03
		STA $0303,y				; Properties

		INY #4					; Increase OAM index
		
		DEC $05					; Decrease loop counter
		BPL .GFXLoop

		LDX $15E9				; Restore sprite index

		LDA #$03				; Tiles to draw - 4
		LDY #$02				; 16x16 sprite
		JSL $01B7B3

RTS