function nika_freq_polyder_str2, data, kidpar, ndeg, freqnorm, indexfit, $
                                 satur_level = satur_level

; same as freq_polyder but with an input structure
; Fit polynomial to the frequency for indexfit values
; apply the fit to the whole array
; freqnorm is a vector of 2
; Do only kids not Off reso
; version 2 is for testing purpose (frequency sweeps)

ndet= n_elements( data[0].i)
freq= fltarr( ndet, n_elements( data))
nouseful = 0
nel = n_elements( data)
maindex = bytarr(nel)+1
maindex[ indexfit] = 0 ; 0 is good
if keyword_set( satur_level) then sl = abs(satur_level) else sl = !dpi/2
angle = angleiq_didq( data)
mask = abs( angle) gt sl ; 0 is good

for ik= 0, ndet-1 do begin 
  if kidpar[ ik].type  eq 1 then begin ; true kid
     IDa =  reform( data.i[ik])
     QDa =  reform( data.q[ik])
     dIDa = reform( data.di[ik])
     dQDa = reform( data.dq[ik])
     
     index = where( maindex eq 0 and mask[ ik, *] eq 0, nindex)
; Gain some time with this test
     IF median( dIDa) NE 0 OR median( dQDa) NE 0 and nindex gt 5 THEN BEGIN 
        reg_polyder, IDa,  QDa,  dIDa,  dQDa,  $
                     SDa,  $    ; Delta 
                     FIDa, FQDa,  $ ; Offset
                     NIDa, NQDa, NdIDa, NdQDa
        status = 1
        fit_polyder, NIDa[ index], NQDa[ index], $
                     NdIDa[ index], NdQDa[ index], ndeg, ncoeff, status = status
; Allow one more chance by lowering the polyn degree
        if status eq 1 then begin
           fit_polyder, NIDa[ index], NQDa[ index], $
                        NdIDa[ index], NdQDa[ index], ndeg - 1, $
                        ncoeff, status = status
        endif
        
;Here frequency norm is around 1kHz
        fruse = freqnorm[ kidpar[ ik].array - 1]
        foundpf = -fruse * polyder( NIDa, NQDa, ncoeff)
; test if bad fit is found
        bad = where( 1-finite( foundpf),  nbad)
        if nbad ne 0 then foundpf[ bad] = !undef
        freq[ ik,*] = foundpf
     ENDIF else nouseful = nouseful + 1
  endif else nouseful = nouseful + 1
endfor
if nouseful eq ndet then $
   message, /info, 'No useful I,Q data' ; end case when calculation is useful
return, freq
end 
