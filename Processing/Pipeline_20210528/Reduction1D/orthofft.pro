FUNCTION  orthofft, vecin
;+
;=-----------------------------------------------------------------------------
; NAME:   
;   orthofft
; PURPOSE:
;   Make a vector data fully orthogonal to the input vector
;     the cross-correlation @ zero lag is zero, their power spectrum are identical
; CATEGORY:
;   statistics
; CALLING SEQUENCE:
;   vecout= orthofft( vecin)
; INPUTS:
;   vecin	: Vector of regularly sampled data
; OPTIONAL INPUTS: none
; KEYWORD INPUTS : 
; OUTPUTS:
;   vecout has same dimension as vecin and satisfies : 
;     total( vecout * vecin)= 0
;     Power_spectrum(vecout)= Power_spectrum(vecin)                                                
; OPTIONAL OUTPUTS: None
; SIDE EFFECTS:  
; RESTRICIONS: none
; PROCEDURE CALLS: FFT
; METHOD:  Multiply in Fourier domain by i at positive frequencies 
;            and -i at negative ones         
; EXAMPLE:
;   signal= sin( 2*!dpi*dindgen(10000)/50)+ $
;       sin( 2*!dpi*dindgen(10000)/100)
;   osignal=orthofft( signal)
;   plot, signal, xra=[4000,5000.], thick = 1
;   oplot, osignal, thick = 2
;   print,total(signal*osignal) / total(signal*signal) 
;       3.3722747e-16
; HISTORY:
;  22-Aug-2002 FXD LAOG first version
;=-----------------------------------------------------------------------------
;-
;------------------------------------------------------------------------------
; On error conditions 
;------------------------------------------------------------------------------
ON_ERROR, 2	 ; To be uncommented when the routine has been fully tested

;------------------------------------------------------------------------------
; Check parameters   
;------------------------------------------------------------------------------
vecout = -1
IF N_PARAMS() LE 0 THEN BEGIN
	MESSAGE,/info, 'Call is '
	PRINT, 'vecout= orthofft( vecin)' 
	GOTO, CLOSING
ENDIF

;------------------------------------------------------------------------------
; Main loop
;------------------------------------------------------------------------------

sizd= size( vecin)
IF sizd(0) NE 1 THEN BEGIN
  message, /info, one_string( string( $
     'Input data should be a vector, here size( vecin)= ', sizd))
  GOTO, closing
ENDIF 
n_vecin = sizd( 1)
; increase speed by padding the end with zero so we get 2^n
;            data , n_vecin-1 works better
ntot= 2L^(floor(alog(n_vecin-1)/alog(2))+1)
npadd = ntot- n_vecin
ntot2 = ntot/2L
IF npadd NE 0 THEN BEGIN
  padd = replicate(0., npadd)
  vecout =  [vecin, padd]
ENDIF ELSE vecout = vecin
vecout = double( vecout) ; always safer
vecout = vecout - mean( vecout)  ; FFT safeguard
fftin = fft( vecout, -1)
fftout = fftin
fftout[0: ntot2]           = complex(0, + 1) * fftin[0: ntot2]
fftout[ntot2 + 1: ntot- 1] = complex(0, - 1) * fftin[ntot2 + 1: ntot- 1]
vecout = double(( fft( fftout, 1))[0: n_vecin- 1])

; convert back to float
IF size( /type, vecin) EQ 4 THEN vecout = float( vecout) 
;------------------------------------------------------------------------------
; Ending
;------------------------------------------------------------------------------
CLOSING:

RETURN, vecout
END
