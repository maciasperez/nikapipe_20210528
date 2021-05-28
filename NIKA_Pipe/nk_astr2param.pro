;+
;
; SOFTWARE:
;
; NAME: 
; nk_astr2param.pro
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;  nk_astr2param, astr, param
;
; PURPOSE: 
;        Update param according to the input astr
; 
; INPUT: 
;      - astr, [param]
; 
; OUTPUT: 
;     - param
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct. 2019, NP
; ================================================================================================

pro nk_astr2param, astr, param
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_astr2param'
   return
endif

if defined(param) eq 0 then nk_default_param, param

param.map_xsize = astr.naxis[0]*abs(astr.cdelt[0])*3600.d0
param.map_ysize = astr.naxis[1]*abs(astr.cdelt[1])*3600.d0
param.map_reso  = abs( astr.cdelt[0])

end
