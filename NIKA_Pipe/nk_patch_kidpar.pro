
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_patch_kidpar
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_patch_kidpar, param, info, data, kidpar
; 
; PURPOSE: 
;        Local patch for old version of acquisition
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 18th, 2018: NP extracted from nk_clean_data_3


pro nk_patch_kidpar, param, info, data, kidpar

if strupcase( strtrim(!nika.run,2)) eq "CRYO" or long(!nika.run) le 5 then begin
   w1 = where( kidpar.type eq 1, nw1)
   for i=0, nw1-1 do begin
      ikid = w1[i]
      power_spec, data.toi[ikid] - my_baseline( data.toi[ikid]), !nika.f_sampling, pw, freq
      wf = where( freq gt 4.d0)
      kidpar[ikid].noise = avg(pw[wf]) ; Jy/Beam/sqrt(Hz) since data is in Jy/Beam
   endfor
endif

end
