
;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_elparal2alpha
;
; CALLING SEQUENCE:
; 
;
; PURPOSE: 
;       Computes the rotation from Nasmyth to sky (azel or radec) or
;       vice versa
; 
; INPUT:
;     - elevation angle in radians
;     - parallactic angle in radians
;     - keyword /nas_azel, /nas_radec
; 
; OUTPUT: 
;     - alpha in radians
;
; KEYWORDS:
;     - nas_azel, nas_radec
; 
; MODIFICATION HISTORY: 
;        - NP, Feb. 28th, 2020
;-

pro nk_elparal2alpha, el_rad, paral_rad, alpha_rad, nas_azel=nas_azel, nas_radec=nas_radec

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_elparal2alpha'
   return
endif

nkwd = 0
if keyword_set(nas_azel)  then nkwd++
if keyword_set(nas_radec) then nkwd++

case nkwd of
   0:begin
      message, /info, "You must specify either nas_to_azel or nas_to_radec or azel_to_nas or radec_to_nas"
      stop
   end
   1:begin
      if keyword_set(nas_azel)  then alpha_rad = el_rad             - 76.2*!dtor + !dpi/2
      if keyword_set(nas_radec) then alpha_rad = el_rad - paral_rad - 76.2*!dtor + !dpi/2
   end
   else: begin
      message, /info, "You must specify either nas_azel or nas_radec and only one of them."
      stop
   end
endcase

;;;; NIKA2
;;   case strtrim(strupcase(param.map_proj),2) of
;;      "NASMYTH": alpha = 0.d0
;;      "AZEL": alpha = data.el
;;      "RADEC": begin
;;         ;; change sign of paral angle (dec. 2018) to match astro
;;         ;; convention. NP + Ph. A., Dec. 2018
;;         alpha = data.el - data.paral
;;      end
;;   endcase
;;endelse

end


