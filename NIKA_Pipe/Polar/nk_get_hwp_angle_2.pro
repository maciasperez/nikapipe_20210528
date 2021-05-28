
;+
; 
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_get_hwp_angle_2
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

pro nk_get_hwp_angle_2, param, info, data, hwp_motor_position, check=check
;-    

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nk_get_hwp_angle_2'
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

;; Detecting the synchronization top
wtop = where( abs(data.synchro-median(data.synchro)) gt 3*stddev(data.synchro))
npts_per_per = median( wtop-shift(wtop,1))
;print, "npt_per_per: ", npts_per_per
;stop

info.phase_hwp_motor_position = avg( hwp_motor_position[wtop]*!radeg)

;; Use a fit to interpolate: more robust to potentially missing
;; points
nsn = n_elements(data)
index = dindgen(nsn)
fit = linfit( index[wtop], (wtop-wtop[0])/npts_per_per*2d0*!dpi + !dpi)
data.position = (fit[0] + fit[1]*index + 2*!dpi)

;; wind, 1, 1, /free, /large
;; xra = [0,400]
;; plot, index, data.synchro, xra=xra, /xs
;; oplot, index[wtop], data[wtop].synchro, psym=8, col=250

;; The synchro signal is sampled at ticks seperated by 20ns whereas the data are sampled
;; at !nika.f_sampling.
;; The value of data.synchro is the number of ticks since the
;; beginning of the current data sample.
;;dt_ticks = min(data.synchro) * 20.d-9 ; sec
info.TOP_SYNCHRO_VALUE = median(data[wtop].synchro)
dt_ticks = median(data[wtop].synchro) * 20.d-9 ; sec
;; the HWP rotates at hwp_rot_freq Hz, hence at 2*pi*hwp_rot_freq
;; rad.s^-1, hence:
info.phase_hwp = dt_ticks * 2d0*!dpi*info.hwp_rot_freq

data.position += param.sign_new_pol_synchro * info.phase_hwp
data.position = data.position mod (2.d0*!dpi)
data.position *= !nika.sign_data_position

;; Need to account for integration over the acquisition sample
;; This leads to an effective reduction of the modulation amplitude
;; that induces a reduction of the polarization efficiency that must
;; be accounted for
;;
;; hwp_rot_freq = 2.9802322
;; f_sampling = 47.683716
;; dt_sampling = 1.d0/f_sampling
;; delta = 2d0*!dpi*hwp_rot_freq*dt_sampling
;; phi = dindgen(360)*!dtor
;; cospolar = 1.d0/(4.d0*delta)*(sin(4.d0*phi+4.d0*delta/2.d0)-sin(4.d0*phi-4.d0*delta/2.))
;; sinpolar = 1.d0/(4.d0*delta)*(cos(4.d0*phi-4.d0*delta/2.d0)-cos(4.d0*phi+4.d0*delta/2.))
;; plot, sqrt( cospolar^2 + sinpolar^2)
;; print, avg( sqrt( cospolar^2 + sinpolar^2))
;; ;; 0.90031632
dt_sampling = 1.d0/!nika.f_sampling
delta = 2d0*!dpi*info.hwp_rot_freq*dt_sampling
avg_sin4 = 1.d0/(4.d0*delta)*(cos(4.d0*data.position-4.d0*delta/2.d0)-cos(4.d0*data.position+4.d0*delta/2.))
avg_cos4 = 1.d0/(4.d0*delta)*(sin(4.d0*data.position+4.d0*delta/2.d0)-sin(4.d0*data.position-4.d0*delta/2.))
data.cospolar  = avg_cos4
data.sinpolar  = avg_sin4

phi = 0.d0
cospolar = 1.d0/(4.d0*delta)*(sin(4.d0*phi+4.d0*delta/2.d0)-sin(4.d0*phi-4.d0*delta/2.))
sinpolar = 1.d0/(4.d0*delta)*(cos(4.d0*phi-4.d0*delta/2.d0)-cos(4.d0*phi+4.d0*delta/2.))
ampl = sqrt( cospolar^2 + sinpolar^2)
;; print, ampl
;; 0.90031632

data.cospolar *= 1.d0/ampl
data.sinpolar *= 1.d0/ampl

if param.cpu_time then nk_show_cpu_time, param

end
