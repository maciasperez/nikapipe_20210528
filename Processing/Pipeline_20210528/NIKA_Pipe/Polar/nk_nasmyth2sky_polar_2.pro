
;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_nasmyth2sky_polar_2
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
; 
; MODIFICATION HISTORY: 
;        - NP, Dec. 5th, 2017, from nk_get_hwp_angle.pro
;-    
pro nk_nasmyth2sky_polar_2, param, info, data, kidpar

if n_params() lt 1 then begin
   print, "nk_nasmyth2sky_polar_2, param, info, data, kidpar"
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
   ;; NIKA2
;;    case strtrim(strupcase(param.map_proj),2) of
;;       "NASMYTH": alpha = 0.d0
;;       "AZEL": alpha = data.el
;;       "RADEC": begin
;;          ;; change sign of paral angle (dec. 2018) to match astro
;;          ;; convention. NP + Ph. A., Dec. 2018
;;          alpha = data.el - data.paral
;;       end
;;    endcase

   case strtrim(strupcase(param.map_proj),2) of
      "NASMYTH": alpha = 0.d0
      "AZEL":    nk_elparal2alpha, data.el, data.paral, alpha, /nas_azel
      "RADEC":   nk_elparal2alpha, data.el, data.paral, alpha, /nas_radec
   endcase
endelse

;; ;; ;;-------------------------------------------------------
;; ;; ;; Comparing cos of average angle to averge of cos(angle)
;; my_cos = cos(4.d0*data.position)
;; my_sin = sin(4.d0*data.position)
;; avg_cos =   my_sin - shift(my_sin,1)
;; avg_sin = -(my_cos - shift(my_cos,1))

;; cos_avg = cos(4.d0*(data.position+shift(data.position,1))/2.d0)
;; sin_avg = sin(4.d0*(data.position+shift(data.position,1))/2.d0)
;; 
;; ;; ;; discard 1st sample (shift wrap around)
;; ;; avg_cos = avg_cos[1:*]
;; ;; avg_sin = avg_sin[1:*]
;; ;; cos_avg = cos_avg[1:*]
;; ;; sin_avg = sin_avg[1:*]
;; wind, 1, 1, /free, /large
;; !p.multi=[0,1,2]
;; xra = [10,50]
;; plot, cos_avg, yra=[-1.5,1.5], xra=xra
;; oplot, avg_cos, col=250
;; legendastro, ['cos(avg)', 'avg(cos)'], col=[!p.color,250]
;; 
;; plot, sin_avg, yra=[-1.5,1.5], xra=xra
;; oplot, avg_sin, col=250
;; legendastro, ['sin(avg)', 'avg(sin)'], col=[!p.color,250]
;; !p.multi=0

;;---------------------------------------------------------------------------
;; ;; Nico 12-2018
;; mycos         =  cos(2.d0*alpha)*data.cospolar + sin(2.d0*alpha)*data.sinpolar
;; data.sinpolar = -sin(2.d0*alpha)*data.cospolar + cos(2.d0*alpha)*data.sinpolar
;; data.cospolar = mycos

;; Nico Feb. 2020
;;alpha = atan( cos(40.*!dtor)*tan(alpha))
;; alpha = atan( 1./cos(40.*!dtor)*tan(alpha))
twoalpha = 2.d0*alpha

mycos         =  cos(twoalpha)*data.cospolar + sin(twoalpha)*data.sinpolar
data.sinpolar = -sin(twoalpha)*data.cospolar + cos(twoalpha)*data.sinpolar
data.cospolar = mycos

if param.cpu_time then nk_show_cpu_time, param

end


