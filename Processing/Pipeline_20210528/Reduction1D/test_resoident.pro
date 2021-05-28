function test_resoident, fin, $
                    tol = tolin,  verbose = verbose
; Now try to find kid frequencies which are identical to one another
; in a common box. Use fmod (without dfmod) for fin.
; returns a mask where 1 means bad ie the resonance frequency is identical to
; another one : distance(1,2)< tol
; FXD august 2019 (adapted from test_resooverlap)

if keyword_set( tolin) then tol = tolin else tol = 1D0  ; 1Hz tolerance
ndet = n_elements( fin)
; Compute the array of test
id = replicate(1., ndet)
d1 = fin#id
suit = indgen( ndet)
s1 = suit#id

; Distance between frequencies
; Caveat: widths are assumed to be defined and not zero
test = abs( d1-transpose(d1))

; Distance to diagonal
test2 = abs( s1-transpose(s1))  

ma = test lt tol and test2 gt 0  ; only off-diagonal terms are useful

bad = where( ma, nbad)
mask = replicate( 0B, ndet)
if nbad ne 0 then begin
  bad = bad mod ndet
  bad = bad[ sort( bad)]
  mask[ bad[ uniq( bad)]] = 1B
  if keyword_set(verbose) then message, /info, strtrim( fix( total( mask)), 2)+ ' identical tones'
endif else if keyword_set(verbose) then message, /info, ' no identical tones'
  
return, mask
end
