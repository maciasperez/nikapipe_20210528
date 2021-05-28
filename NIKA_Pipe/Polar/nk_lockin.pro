;+
;
; SOFTWARE: NIKA pipeline (polarization specific)
;
; NAME:
; nk_lockin
;
; CATEGORY:
;
; CALLING SEQUENCE:
;       nk_lockin, param, info, data, kidpar
; 
; PURPOSE: 
;        Updates toi_i, toi_q and toi_u, together with pointing and flag info
;        and reduces the number of samples.
; 
; INPUT: 
;        - param: the reduction parameters array of structures (one per scan)
;        - info: the array of information structure to be filled (one
;          per scan)
;        - data
;        - kidpar
; 
; OUTPUT: 
;        - data is resamples, data.toi now contains I timeline, data.toi_q and
;          data.toi_u are built
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 11/07/2014: nk_decor_polar.pro : creation (Alessia Ritacco & Nicolas Ponthieu-ritacco@lpsc.in2p3.fr)
;        - Aug. 9th, 2014: modify nk_decor_polar into this version of the code
;          to be compliant with nk.pro
;-
;=========================================================================================================

pro nk_lockin, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_lockin, param, info, data, kidpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then    message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nsn = n_elements(data)

if param.polar_lockin_freqlow ne 0 or param.polar_lockin_freqhigh ne 0 then do_bandpass = 1 else do_bandpass = 0

if do_bandpass eq 1 then begin
   ;;Classical method, no decimation
   ;;Init filter
   np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
                freqlow=param.polar_lockin_freqlow, $
                freqhigh=param.polar_lockin_freqhigh, $
                delta_f=param.polar_lockin_delta_f, filter=filter
endif

;; Account for the relative orientation of the two 1mm matrices in NIKA2
;; NP, Feb. 10th, 2016
nkids = n_elements(kidpar)
pol_sign = dblarr(nkids) + 1.d0
w3 = where( kidpar.array eq 3, nw3)
if nw3 ne 0 then pol_sign[w3] = -1.d0

if do_bandpass eq 1 then begin
   w1 = where(kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      for i=0, nw1-1 do begin
         if param.silent eq 0 then percent_status, i, nw1, 10, message='nk_lockin'
         ikid  = w1[i]
         y = reform( data.toi[ikid]) - my_baseline( data.toi[ikid], base_frac=!nika.f_sampling/nsn)
         np_bandpass, y,               !nika.f_sampling, toi_t, filter=filter
         np_bandpass, y*data.cospolar, !nika.f_sampling, toi_q, filter=filter
         np_bandpass, y*data.sinpolar, !nika.f_sampling, toi_u, filter=filter
         
         if total( finite(toi_t))/n_elements(data) lt 1 then stop
         
         data.toi[  ikid] = toi_t
         data.toi_q[ikid] = pol_sign[ikid] * toi_q*2.d0
         data.toi_u[ikid] = pol_sign[ikid] * toi_u*2.d0
      endfor
   endif
endif else begin

   w1 = where( kidpar.type eq 1,  nw1)
   t0 = systime(0, /sec)

   ;; - Added factor 2, following Helene's advice, Oct. 28th, 2015 (NP)
   ;; - Account for the rel. orient. of the 1mm matrices in NIKA2 NP, Feb. 10th, 2016
   data.toi_q[w1] = 2.d0*data.cospolar##(dblarr(nw1)+pol_sign[w1]) * data.toi[w1]
   data.toi_u[w1] = 2.d0*data.sinpolar##(dblarr(nw1)+pol_sign[w1]) * data.toi[w1]

endelse

if param.cpu_time then nk_show_cpu_time, param

end
