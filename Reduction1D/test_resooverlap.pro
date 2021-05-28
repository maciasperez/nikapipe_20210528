function test_resooverlap, fin, width, $
                    tol = tolin,  verbose = verbose
; Now try to find kid frequencies which are too close to one another
; returns a mask where 1 means bad ie the resonance frequency is too close to
; another one : distance(1,2)< tol* (width1+width2)/2 
; assumes one set of detectors (do not mix 1 and 2mm)
; FXD dec 2013

if keyword_set( tolin) then tol = tolin else tol = 0.8
ndet = n_elements( fin)
; Compute the array of test
id = replicate(1., ndet)
d1 = fin#id
w1 = width#id
suit = indgen( ndet)
s1 = suit#id

; Distance between frequencies / average of widths
; Caveat: widths are assumed to be defined and not zero
test = abs( d1-transpose(d1))/ (0.5*(w1+transpose(w1)))

; Distance to diagonal
test2 = abs( s1-transpose(s1))  

ma = test lt tol and test2 gt 0  ; only off-diagonal terms are useful

bad = where( ma, nbad)
mask = replicate( 0B, ndet)
if nbad ne 0 then begin
  bad = bad mod ndet
  bad = bad[ sort( bad)]
  mask[ bad[ uniq( bad)]] = 1B
  if keyword_set(verbose) then message, /info, strtrim( fix( total( mask)), 2)+ ' overlapping tones'
endif else if keyword_set(verbose) then message, /info, ' no overlapping tones'
  
return, mask
end
