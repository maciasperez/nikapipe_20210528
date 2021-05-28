;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME:
; nk_tdilflag
; 
; PURPOSE: 
;        Detects dilution flags
; 
; INPUT: 
;        - param: the parameter structure
;        - info: the information structure
; 
; OUTPUT: 
;
; 
; KEYWORDS:
;        NONE
; 
; MODIFICATION HISTORY: 
;        - 13/03/2014: creation from nika_pipe_tdilflag.pro by FXD
;-
;====================================================================================================

pro nk_tdilflag, param, info, data, kidpar


if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif


if param.cpu_time then param.cpu_t0 = systime(0, /sec)

; Test if tag exists
; Otherwise test cannot be done
;tdil_exist = tag_exist( data, 'MAP_TBM')
;if tdil_exist le 0 then return  ; no error message though
tags = tag_names(data)
wtdil = where( strupcase(tags) eq "MAP_TBM", nwtdil)
if nwtdil eq 0 then return  ; no error message though

; Method is optimized for Run8 only
; Find the glitch if it exists
glamp = max( data.map_tbm, imax)

; Do something if there is a significant deviation from 150mK
; 0.2e-3 means 0.2mK
if (glamp-median( data.map_tbm)) gt 0.2E-3 then begin
   mask = imax-3.50*!nika.f_sampling +[0, 2.0*!nika.f_sampling] 
; optimized window (the glitch is earlier in the data than in the dilution
; temperature variable
   nsa = n_elements( data)

   mask[0] = mask[0]>0
   mask[1] = mask[1] < (nsa-1)
   sa = lindgen( nsa)
   badtdil = where(sa gt mask[0] and sa lt mask[1], nbadtdil)
   if nbadtdil ne 0 then nk_addflag, data, 19, wsample=badtdil
endif
  
if param.cpu_time then nk_show_cpu_time, param, "nk_tdilflag"

end
