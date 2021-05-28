function freq_polyder_str, data, ndeg, freqnorm, indexfit

; same as freq_polyder but with an input structure
; Fit polynomial to the frequency for indexfit values
; apply the fit to the whole array
nkid= n_elements( data[0].i)
freq= fltarr( nkid, n_elements( data))
nouseful = 0
for ik= 0, nkid-1 do begin 
  IDa =  reform( data.i[ik])
  QDa =  reform( data.q[ik])
  dIDa = reform( data.di[ik])
  dQDa = reform( data.dq[ik])

; Gain some time with this test
  IF median( dIDa) NE 0 OR median( dQDa) NE 0 THEN BEGIN 
    reg_polyder, IDa,  QDa,  dIDa,  dQDa,  $
                 SDa,  $  ; Delta 
                 FIDa, FQDa,  $  ; Offset
                 NIDa, NQDa, NdIDa, NdQDa
    status = 1
    fit_polyder, NIDa[ indexfit], NQDa[ indexfit], $
      NdIDa[ indexfit], NdQDa[ indexfit], ndeg, ncoeff, status = status
; Allow one more chance by lowering the polyn degree
    if status eq 1 then begin
      fit_polyder, NIDa[ indexfit], NQDa[ indexfit], $
        NdIDa[ indexfit], NdQDa[ indexfit], ndeg - 1, ncoeff, status = status
    endif
; too many useless messages
;     if status eq 1 then print, ik, ' status is ', status, $
;                                    ' ; 1 is invalid, 2 is weak (but ok)'

;Here frequency norm is around 1kHz
    freq[ ik,*] = -freqnorm * polyder( NIDa, NQDa, ncoeff)
 ENDIF else nouseful = nouseful + 1
endfor
if nouseful eq nkid then $
   message, /info, 'No useful I,Q data' ; end case when calculation is useful
return, freq
end 
