function nika_freq_polyder_str, data, kidpar, ndeg, freqnorm, indexfit

; same as freq_polyder but with an input structure
; Fit polynomial to the frequency for indexfit values
; apply the fit to the whole array
; freqnorm is a vector of 2 (NIKA) or 3 (NIKA2)= number of arrays
; Do only kids not Off reso
ndet= n_elements( data[0].i)
freq= fltarr( ndet, n_elements( data))
nouseful = 0
for ik= 0, ndet-1 do begin 
  if kidpar[ ik].type  eq 1 then begin ; true kid
     IDa =  reform( data.i[ik])
     QDa =  reform( data.q[ik])
     dIDa = reform( data.di[ik])
     dQDa = reform( data.dq[ik])
     
; Gain some time with this test
     IF median( dIDa) NE 0 OR median( dQDa) NE 0 THEN BEGIN 
        reg_polyder, IDa,  QDa,  dIDa,  dQDa,  $
                     SDa,  $    ; Delta 
                     FIDa, FQDa,  $ ; Offset
                     NIDa, NQDa, NdIDa, NdQDa
        status = 1
        fit_polyder, NIDa[ indexfit], NQDa[ indexfit], $
                     NdIDa[ indexfit], NdQDa[ indexfit], ndeg, ncoeff, status = status
; Allow one more chance by lowering the polyn degree
        if status eq 1 then begin
           fit_polyder, NIDa[ indexfit], NQDa[ indexfit], $
                        NdIDa[ indexfit], NdQDa[ indexfit], ndeg - 1, $
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
