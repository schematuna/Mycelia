;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Falling spike disassembly
; By Nekoh
;
; Setting the extra bit will make the spike rise instead of fall.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite init JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                    print "INIT ",pc
                    RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite main code 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                    print "MAIN ",pc
                    PHB                       
                    PHK                       
                    PLB                                 
                    JSR FALLINGSPIKE        
                    PLB                       
                    RTL                       ; Return 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite code JSL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FALLINGSPIKE:       JSL $0190B2    
                    LDY !15EA,x               ; Y = Index into sprite OAM 
					LDA !7FAB10,x
					AND #$04
					BEQ ExbitNotSet
					LDA !15F6,x
					ORA #$80
					STA !15F6,x
					ExbitNotSet:
                    LDA #$E0                
                    STA $0302|!Base2,y        
                    LDA $0301|!Base2,y         
                    DEC A                     
                    STA $0301|!Base2,y         
                    LDA !1540,x             
                    BEQ LABEL_ONE           
                    LSR                       
                    LSR                       
                    AND #$01                
                    CLC                       
                    ADC $0300|!Base2,y         
                    STA $0300|!Base2,y         
LABEL_ONE:          LDA $9D     
                    BNE LABEL_TWO           
                    %SubOffScreen() 
                    JSL $01802A     
                    LDA !C2,x     
                    JSL $0086DF       

POINTER:            dw LABEL_THREE         
                    dw LABEL_TWO     

LABEL_THREE:        STZ !AA,x                 ; Sprite Y Speed = 0 
                    ;%SubHorzPos()            ; tuna: these trigger immediately, regardless of mario's location
                    ;LDA $0E                  
                    ;CLC                       
                    ;ADC #$40                
                    ;CMP #$80                
                    ;BCS RTN_ONE          
                    INC !C2,x     
                    LDA #$08                  ; tuna: faster timer (vanilla: #$20) 
                    STA !1540,x             
RTN_ONE:            RTS                       ; Return 

LABEL_TWO:          					
					LDA !1540,x             
                    BNE FREEZE_SPR
					
					;LDA !7FAB10,x
					;AND #$04
					;BEQ +
					;LDA #$B0                  ; Maximum falling speed, don't go below #$80.
                    ;CMP !AA,x                 ; tuna: comment this out, not needed? This also skipped 01A7DC...
                    ;BPL RTN_ONE
                    LDA !AA,x
                    CLC
                    ADC #$0D                  ; tuna: FASTS fall
                    STA !AA,x
					;+						
                    JSL $01A7DC	
					RTS
FREEZE_SPR:         STZ !AA,x                 ; Sprite Y Speed = 0 
                    RTS                       ; Return 