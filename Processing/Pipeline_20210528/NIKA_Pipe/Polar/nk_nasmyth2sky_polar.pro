
;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_nasmyth2sky_polar
;
; CALLING SEQUENCE:
; nk_nasmyth2sky_polar, param, info, data, kidpar
;
; PURPOSE: 
;       Rotates polarization angles from Nasmyth coordinates to sky coordinates
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - data.position is modified
; 
; KEYWORDS:
; 
; MODIFICATION HISTORY: 
;        - NP, Dec. 5th, 2017, from nk_get_hwp_angle.pro
;-

pro nk_nasmyth2sky_polar, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_nasmyth2sky_polar, param, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if long(!nika.run) le 12 then begin
   ;; NIKA1
   case strtrim(strupcase(param.map_proj),2) of
      "NASMYTH": alpha = 0.d0
      "AZEL":    alpha = alpha_nasmyth( data.el)
      "RADEC":   alpha = alpha_nasmyth( data.el) - data.paral
   endcase
   alpha = alpha + param.polar_angle_offset_deg*!dtor
endif else begin
;;if long(!nika.run) ge 13 then param.polar_angle_offset_deg = 76.2
   ;; NIKA2
   case strtrim(strupcase(param.map_proj),2) of
      "NASMYTH": alpha = 0.d0
      "AZEL":    alpha = data.el
      "RADEC":   alpha = data.el - data.paral
   endcase
endelse

data.cospolar  = cos(4.d0*data.position + 2.d0*alpha)
data.sinpolar  = sin(4.d0*data.position + 2.d0*alpha)

if param.cpu_time then nk_show_cpu_time, param

end


