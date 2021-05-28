pro reg_polyder,  IDa,  QDa, dIDa,  dQDa, $
                 SDa,  $  ; Delta 
                 FIDa, FQDa, $  ; Offset
                 NIDa, NQDa, NdIDa, NdQDa, $  ; Normalized data
                 nocompute= nocompute

if not keyword_set( nocompute) then begin 
   FIDa = mean(   IDa, /double)
   SIDa = stddev( IDa, /double)
   if SIDa eq 0 then SIDa = 1.D0
   
   FQDa = mean(   QDa, /double)
   SQDa = stddev( QDa, /double)
   if SQDa eq 0 then SQDa = 1.D0
   SDa= SIDa > SQDa  ; take the largest delta
endif 

NIDa= (IDa - FIDa) / SDa
NQDa= (QDa - FQDa) / SDa
NdIDa= dIDa  / SDa
NdQDa= dQDa  / SDa

return

end

