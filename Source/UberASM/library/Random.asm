; Ranged pseudorandom number generation.
; Input: A = max value
; Output: A = random number in the interval [0, A]
 
Random:
    PHX : PHP
    SEP #$30
    PHA
    JSL $01ACF9|!bank
	LDA $148D|!addr
    PLX
    CPX #$FF
    BEQ .end
 
.normal
    INX
 
    if !sa1 == 0
        STA $4202               ; Write first multiplicand.
        STX $4203               ; Write second multiplicand.
        NOP #4                  ; Wait 8 cycles.
        LDA $4217               ; Read multiplication product (high byte).
    else
        STZ $2250               ; Set multiplication mode.
        STA $2251               ; Write first multiplicand.
        STZ $2252
        STX $2253               ; Write second multiplicand.
        STZ $2254
        NOP                     ; Wait 2 cycles, which is enough according to SnesLab docs about sa-1 registers.
        LDA $2307               ; Read multiplication product.
    endif
.end
    PLP : PLX
    RTL
