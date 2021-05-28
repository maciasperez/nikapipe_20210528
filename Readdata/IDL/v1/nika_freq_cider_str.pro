function nika_freq_cider_str, data, kidpar, ndeg, freqnorm, indexfit

; same as freq_cider but with an input structure
; Fit a circle + polynomial to the frequency for indexfit values
; apply the fit to the whole array
; freqnorm is a vector of 2
; Do only kids not Off reso
ndet= n_elements( data[0].i)
freq= dblarr( ndet, n_elements( data))
nouseful = 0
angle = angleiq_didq( data)
for ik= 0, ndet-1 do begin 
  if kidpar[ ik].type  eq 1 then begin ; true kid
     IDa =  reform( data.i[ik])
     QDa =  reform( data.q[ik])
     dIDa = reform( data.di[ik])
     dQDa = reform( data.dq[ik])
     
; Gain some time with this test
  IF median( dIDa) NE 0 OR median( dQDa) NE 0 THEN BEGIN 
    status = 1
    fit_cider, IDa[ indexfit], QDa[ indexfit], $
               dIDa[ indexfit], dQDa[ indexfit], ndeg, $
               coeff, corot, sirot, xc, yc, radius, status = status

; Allow one more chance by lowering the polyn degree
    if status eq 1 then begin
       fit_cider, IDa[ indexfit], QDa[ indexfit], $
               dIDa[ indexfit], dQDa[ indexfit], ndeg - 1, $
               coeff, corot, sirot, xc, yc, radius, status = status
    endif

; Set the zero frequency in the same way as df_tone (angle=0)
    aux = min( abs(angle[ ik, *]), imin)
    coeff[0] = -freq_cider(IDa[ imin], QDa[ imin], $
                          coeff, corot, sirot, xc, yc, radius)

;Here frequency norm is around 1kHz
        fruse = freqnorm[ kidpar[ ik].acqbox]
        foundcf = -fruse * freq_cider(IDa, QDa, $
                                        coeff, corot, sirot, xc, yc, radius)
; test if bad fit is found
        bad = where( 1-finite( foundcf),  nbad)
        if nbad ne 0 then foundcf[ bad] = !undef
        freq[ ik,*] = foundcf
     ENDIF else nouseful = nouseful + 1
  endif else nouseful = nouseful + 1
endfor
        
if nouseful eq ndet then $
   message, /info, 'No useful I,Q data' ; end case when calculation is useful

return, freq
end
