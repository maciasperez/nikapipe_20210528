;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
;  nk_calibration_2
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_calibration_2, param, info, data, kidpar
; 
; PURPOSE: 
;        Computes current opacity and applies absolute calibration to timelines
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the general NIKA strucutre containing time ordered information
;        - kidpar: the general NIKA structure containing kid related information
; 
; OUTPUT: 
;        - data: data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 17/03/2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr) from (old nika_pipe_opacity.pro and
;          nika_pipe_calib.pro)
;        - Jan 2019 (NP): correct bug on the application of opacity
;          correction when do_opacity_correction=4 (was actually not
;          applied before)

pro nk_calibration_2, param, info, data, kidpar, simpar=simpar
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_calibration_2'
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; default init
kidpar.tau_skydip = 0.d0

;; Small exception here for temporary configurations during observations:
w = where( kidpar.c1_skydip ne 0.d0, nw)
if nw eq 0 and param.rta eq 1 then param.do_opacity_correction = 0

;; force_opacity_225 has priority on do_opacity_correction that may
;; have been set by default in rta...
if param.force_opacity_225 eq 1 then param.do_opacity_correction = 1

;; Compute the opacities and apply the correction to the TOIs
if param.do_opacity_correction GE 1 then begin
   
   if param.force_opacity_225 eq 1 then begin
;;       w1 = where( kidpar.array eq 1 or kidpar.array eq 3, nw1)
;;       if nw1 ne 0 then begin
;;          tau = info.tau225*1.28689-0.00012725
;;          if param.force_constant_elevation_opacorr then begin
;;             data.toi[w1] *= exp(tau/sin(median(data.el))) ; constant in time
;;          endif else begin
;;             data.toi[w1] *= (exp(tau/sin(data.el))##(dblarr(nw1)+1.d0))
;;          endelse
;;          info.result_tau_1mm = tau
;;          info.result_tau_1   = tau
;;          info.result_tau_3   = tau
;;       endif
;;       w1 = where( kidpar.array eq 2, nw1)
;;       if nw1 ne 0 then begin
;;          tau = info.tau225*0.732015+0.0200369
;;          if param.force_constant_elevation_opacorr then begin
;;             data.toi[w1] *= exp(tau/sin(median(data.el)))
;;          endif else begin
;;             data.toi[w1] *= (exp(tau/sin(data.el))##(dblarr(nw1)+1.d0))
;;          endelse
;;          info.result_tau_2mm = tau
;;          info.result_tau_2   = tau
;;       endif
;; 

      if param.dave_tau_file ne '' then begin
         get_dave_taus, param.dave_tau_file, dave_mjd, dave_day, dave_ut, dave_tau225, /lin
         my_mjd = dave_mjd[0] + dindgen( round( max(dave_mjd-dave_mjd[0])*86400.d0/60.) + 1)/(24.*60.d0)
         tau1 = interpol( dave_tau225, dave_mjd, my_mjd)
         ;; smooth over 5 minutes to reduce noise
         nsmooth = 5
         info.tau225 = interpol( smooth(tau1,nsmooth), my_mjd, info.mjd)
      endif

      for iarray=1, 3 do begin
         if iarray eq 2 then begin
            tau = info.tau225*0.732015+0.0200369
            info.result_tau_2mm = tau
            info.result_tau_2   = tau
         endif else begin
            tau = info.tau225*1.28689-0.00012725
            info.result_tau_1mm = tau
            info.result_tau_1   = tau
            info.result_tau_3   = tau
         endelse
         w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
         if nw1 ne 0 then begin
            if param.force_constant_elevation_opacorr then begin
               data.toi[w1] *= exp(tau/sin(median(data.el))) ; constant in time
            endif else begin
               data.toi[w1] *= (exp(tau/sin(data.el))##(dblarr(nw1)+1.d0))
            endelse
         endif
      endfor      

   endif else begin
      nk_get_opacity, param, info, data, kidpar, simpar=simpar
   endelse
endif


;; Apply the absolute calibration present in the kidpar
w1 = where( kidpar.type eq 1, nw1)
nsn = n_elements(data)

;; This solution with ## is actually faster than using "rebin"
;; NP. Dec. 2016 as can be checked below
calib = (dblarr(nsn)+1) ## kidpar[w1].calib_fix_fwhm
data.toi[w1] *= calib

;; calib_ori = calib
;; toi_ori = data.toi
;; t0 = systime(0,/sec)
;; calib = (dblarr(nsn)+1) ## calib[w1]
;; data.toi[w1] *= calib
;; t1 = systime(0,/sec)
;; 
;; data.toi = toi_ori
;; 
;; t2 = systime(0,/sec)
;; data.toi[w1] *= rebin(calib_ori[w1],nw1,nsn)
;; t3 = systime(0,/sec)
;; print, "t1-t0: ", t1-t0
;; print, "t3-t2: ", t3-t2
;; ;; t1-t0:        2.7277792
;; ;; t3-t2:        4.0461020

;; Account for the telescope gain dependence on elevation, only for
;; point sources (NP and Herve Aussel, Dec. 28th, 2015)
;; revised with NIKA2 curve derived on 3C84, N2R12, Dec. 6th, 2017 NP.
;;
;; Should not be applied apparently, hence the new do_tel_gain_corr=0
;; in nk_default_param...
if param.do_tel_gain_corr ge 1 then $
   nk_tel_gain_cor, param, info, data, kidpar, extent_source=param.extended_source

if param.cpu_time then nk_show_cpu_time, param

end
