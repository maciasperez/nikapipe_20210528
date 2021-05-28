;+
;
; SOFTWARE:
;
; NAME: 
; nk_header2param.pro
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;  nk_header2param, header, param
;
; PURPOSE: 
;        Update param according to the input header
; 
; INPUT: 
;      - header, [param]
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

pro nk_header2param, header, param
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_header2param'
   return
endif

if defined(param) eq 0 then nk_default_param, param

extast, header, astr

nk_astr2param, astr, param

end
