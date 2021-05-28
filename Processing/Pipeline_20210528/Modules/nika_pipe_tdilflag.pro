;+
;PURPOSE: Add flag based on the dilution temperature (regulation glitches)
;
;INPUT: The data and kidpar structures
;
;OUTPUT: The flagged data structure.
;
;LAST EDITION: 16/05/2014: Creation FXD
; Modifications
;-

pro nika_pipe_tdilflag, param, data, kidpar

; Test if tag exists
; Otherwise test cannot be done
tdil_exist = tag_exist( data, 'MAP_TBM')
if tdil_exist le 0 then return  ; no error message though

; Method is optimized for Run8 only
; Find the glitch if it exists
glamp = max( data.map_tbm, imax)

; Do something if there is a significant deviation
if (glamp-median( data.map_tbm)) gt 0.2E-3 then begin
   mask = imax-3.50*!nika.f_sampling +[0, 2.0*!nika.f_sampling] 
; optimized window (the glitch is earlier in the data than in the dilution
; temperature variable
   nsa = n_elements( data)

   mask[0] = mask[0]>0
   mask[1] = mask[1] < (nsa-1)
   sa = lindgen( nsa)
   badtdil = where(sa gt mask[0] and sa lt mask[1], nbadtdil)
   if nbadtdil ne 0 then nika_pipe_addflag, data, 19, wsample=badtdil
endif
  
  return
end
