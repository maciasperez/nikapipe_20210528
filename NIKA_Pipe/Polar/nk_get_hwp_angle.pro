
;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_get_hwp_angle
;
; CALLING SEQUENCE:
; nk_get_hwp_angle, param, info, data, check=check
;
; PURPOSE: 
;        Computes the HWP angle at each time
; 
; INPUT: 
;        - data
; 
; OUTPUT: 
;        - data.position contains the HWP angle in RADIANS
; 
; KEYWORDS:
;        
; 
; MODIFICATION HISTORY: 
;        - NP, 2014
;        - Alessia Ritacco: now take data.position directly. (oct 2014)
;        - AR: nov 2015 debugging for NIKA2  

pro nk_get_hwp_angle, param, info, data, hwp_motor_position, check=check
;-    

if n_params() lt 1 then begin
   dl_unix, 'nk_get_hwp_angle'
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; Turn data.position into radians
if long(!nika.run) le 12 then begin
   data.position = data.position/6400.d0*2.d0*!dpi
endif else begin
   data.position = data.position/12800.d0*2.d0*!dpi
endelse

;; Store for further monitoring
hwp_motor_position = data.position

;; if long(!nika.run) le 12 then begin
;;    ;; NIKA1
;;    case strtrim(strupcase(param.map_proj),2) of
;;       "NASMYTH": alpha = 0.d0
;;       "AZEL":    alpha = alpha_nasmyth( data.el)
;;       "RADEC":   alpha = alpha_nasmyth( data.el) - data.paral
;;    endcase
;;    alpha = alpha + param.polar_angle_offset_deg*!dtor
;; endif else begin
;; ;;if long(!nika.run) ge 13 then param.polar_angle_offset_deg = 76.2
;;    ;; NIKA2
;;    case strtrim(strupcase(param.map_proj),2) of
;;       "NASMYTH": alpha = 0.d0
;; ;      "RADEC":   alpha = -alpha_nasmyth( data.el) + data.paral - !dpi/4.
;; 
;;       ;"AZEL":    alpha = -alpha_nasmyth( data.el)
;;       ;; put back the same convention for alpha_nasmyth between azel
;;       ;; and radec as it should ? (NP+AA, Apr. 2018)
;;       "AZEL":  alpha = alpha_nasmyth( data.el)
;;       "RADEC": alpha = alpha_nasmyth( data.el) - data.paral - !dpi/4.
;;    endcase

;; Detecting the synchronization top
wtop = where( abs(data.synchro-median(data.synchro)) gt 3*stddev(data.synchro))
npts_per_per = median( wtop-shift(wtop,1))

;; Use a fit to interpolate: more robust to potentially missing
;; points
nsn = n_elements(data)
index = dindgen(nsn)
fit = linfit( index[wtop], (wtop-wtop[0])/npts_per_per*2d0*!dpi + !dpi)
data.position = (fit[0] + fit[1]*index + 2*!dpi) mod (2.d0*!dpi)   

   ;;------ begin check synchro and new acquisition ----
;;   print, "minmax(data.a_hours+data.a_time_pps): ", minmax(data.a_hours+data.a_time_pps)
;;   synchro = data.synchro
;;   myfile = 'synchro_'+strtrim( long(randomu( seed, 1)*1e8),2)+'.save'
;;   save, synchro, file=myfile
;;   print, "myfile: "+myfile
;;   help, wtop
;;   print, "wtop[0] = ", wtop[0]
;;   stop
   ;;------ end check synchro and new acquisition ----
   
;;   hwp_angle = (fit[0] + fit[1]*index + 2*!dpi) mod (2.d0*!dpi)   
;;    xra = [-10,80]
;;    wind, 1, 1, /free, /large
;;    my_multiplot, 2, 2, pp, pp1, /rev
;;    plot,  index, data.synchro, xra=xra, /xs, psym=-8, position=pp1[0,*]
;;    oplot, index[wtop], data[wtop].synchro, psym=8, col=250
;;    plot,  index, data.position, xra=xra, /xs, position=pp1[1,*], /noerase, yra=[-1,2*!dpi], /ys
;;    oplot, index, hwp_angle, col=250
;;    plot,  index[wtop], (wtop-wtop[0])/npts_per_per, xra=xra, position=pp1[2,*], /noerase, psym=-8
;;    plot, hwp_angle*!radeg, data.synchro, position=pp1[3,*], /noerase
   
;;endelse

;; Commented out, should be in nk_nasmyth2sky_polar.pro (Apr. 18th,
;; 2018, NP+AA)
;; data.cospolar = cos(4.d0*data.position + 2.d0*alpha)
;; data.sinpolar = sin(4.d0*data.position + 2.d0*alpha)

info.angle_avg = median(data.position)

if param.cpu_time then nk_show_cpu_time, param

end
