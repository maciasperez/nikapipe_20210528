
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_check_simpar
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_check_simpar, simpar
; 
; PURPOSE: 
; 
; INPUT: 
;        - simpar
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 

pro nk_check_simpar, simpar, info
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_check_simpar'
   return
endif

if simpar.add_one_corr_and_white_noise ne 0 and $
   simpar.sigma_white_noise ne 0.d0 then begin
   error_message = "simpar.add_one_corr_and_white_noise and simpar.sigma_white_noise should not be set together"
   nk_error, info, error_message
   return
endif


end
