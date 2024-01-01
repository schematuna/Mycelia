;;;;;;;;;;;;
;; Memory ;;
;;;;;;;;;;;;

!GlobalTimer = 13E6                 ; 16-bit timer for timing attacks and such
!GlobalTimer2 = 18BB                ; secondary 8-bit timer
!GlobalTimer3 = 0F3A 				; tertiary 8-bit timer
!SpriteSlot1 = 1864                 ;\ Remember the slots of sprites we spawn
!SpriteSlot2 = 1879                 ;/ so we can modify their properties later on
!BossHits = CC                      ; How many hits the boss has taken
!MainPhase = 18B4                 	; Highest level Fight Phase
!MainPhase2 = 18DB 					; lower level phase
!MainPhase3 = 1923 					; lowerer level phase, used for attack phase
!SubPhase = 18D8                    ; used for shorter inter-attack phases
!SubPhase2 = 0DC4                   ; and another for deeper phases...
!BossPhase = 191B 					; phase 1, 2, or 3
!AttackCounter = 18E6               ; counts attacks as needed
!PreviousAttack = 191F 				; pointer to attack number memory
!FirstAttackOfPhase = 0F3B 			; 1st attack flag

!MyceliaTimer = 0DC3                ;\ memory for mycelia animations and synchronization
!MyceliaPhase = 13F8                ;/

!FireBarLength = 1528               ;\
!FireBarSpeed = 1534                ;| firebar sprite memories
!FireBarAngleFine = C2              ;|
!FireBarAngleCoarse = 1504          ;/

; The code expects these to be absolute addresses
!MiscRam1 = 18C5                    ;\
!MiscRam2 = 18C6                    ;|
!MiscRam3 = 18C7                    ;|
!MiscRam4 = 18C8                    ;| contiguous ram for whatever is needed
!MiscRam5 = 18C9                    ;|
!MiscRam6 = 18CA                    ;|
!MiscRam7 = 18CB                    ;|
!MiscRam8 = 18CC                    ;/
!MiscRam9 = 18B7                    ; more misc ram...


!SpriteState = 00                   ;\
!SpriteNumber = 01                  ;|
!XLo = 02                           ;|
!XHi = 03                           ;|
!YLo = 04                           ;|
!YHi = 05                           ;| convenience defines for scratch RAM values used with sprite spawn subroutines
!ExtraByte1 = 06                    ;|
!ExtraByte2 = 07                    ;|
!ExtraByte3 = 08                    ;|
!ExtraByte4 = 09                    ;|
!YSpeed = 0A                        ;|
!XSpeed = 0B                        ;|
!ExtraBits = 0C                     ;/

;;;;;;;;;;;;;;;
;; Constants ;;
;;;;;;;;;;;;;;;

!LeftEyeSlot = $00                  ;\
!RightEyeSlot = $01                 ;/ eyes are hardcoded to use lowest slots so they draw below other sprites

CommonEyeSlots:
db !LeftEyeSlot,!RightEyeSlot

!MyceliaXHi = 1B 					; mycelia x hi is just the screen x hi
!MyceliaXLoLeft = $60               ;\ x positions are on left side of the eyes
!MyceliaXLoRight = $90              ;/ 28true center is 78 so that the visual center is 80
!MyceliaYLo = $20
!MyceliaYHi = $01
!PupilYOffset = $04
!PupilXOffsetLeft = $09
!PupilXOffsetRight = $00

!Downtime = $28 					; time between subsequent attacks (must line up with eye oscillation pattern)