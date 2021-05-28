;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_discard_otf_slew
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_discard_otf_slew, param, info, data, kidpar
; 
; PURPOSE: 
;        Discards the end of the scan when the telescopes ends up on the
;        source. this messes up with common mode subtraction
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug 12th, 2014: NP
;-
;============================================================================================

pro nk_discard_otf_slew, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_discard_otf_slew, param, info, data, kidpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if strupcase(info.obs_type) eq "ONTHEFLYMAP" then begin
   speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)
   plot, speed
   stop
endif



end
