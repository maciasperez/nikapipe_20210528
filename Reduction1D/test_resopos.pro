function test_resopos,  fref, fin, width, $
                    tol = tolin,  niter = niterin,  verbose = verbose
; returns a mask where 1 means bad ie the reso frequency is too far off the
; predicted frequency (distance>tol*width)
; assumes one set of detectors (do not mix 1 and 2mm)
; niter is the number of iterations with respect to badies. 1 should be ok.
; FXD dec 2013


if keyword_set( tolin) then tol = tolin else tol = 0.7
if keyword_set( niterin) then niter = niterin else niter = 1

; Compute the average ratio
rat1 = median( fin/fref)
if keyword_set( verbose) then print, rat1, 1-rat1
fexp = fref * rat1

mask = abs( fin-fexp) gt tol*width

; Iterate
if keyword_set( niter) then begin
   for iter = 0, niter-1 do begin
      good = where( mask eq 0,  ngood)
      if ngood eq 0 then begin
         mask = mask*0+1        ; everything is wrong
         if iter eq 0 then $
            message, /info, 'This scan is totally wrong for this array'
      endif else begin
         rat = median( fin[ good]/fref[good])
         if keyword_set( verbose) then print, rat,  1-rat, '  number of valid KIDs', ngood
         fexp = fref*rat1
         mask = abs( fin-fexp) gt tol*width
         if iter eq (niter-1) and keyword_set( verbose) then $
            message, /info, strtrim( fix( total( mask)), 2)+' out-of-resonance tones'
      endelse
   endfor
endif
   
return, mask
end
