;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
;  nk_calibration
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_calibration, param, info, data, kidpar
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
;          adam@lpsc.in2p3.fr) from (old nika_pipe_opacity.pro and nika_pipe_calib.pro)
;-

pro nk_calibration, param, info, data, kidpar, simpar=simpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_calibration, param, info, data, kidpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;;------------
;; Small exception here for temporary configurations during observations:
w = where( kidpar.c1_skydip ne 0.d0, nw)
if nw eq 0 and param.rta eq 1 then param.do_opacity_correction = 0
;;------------

;; Compute the opacity at present time based on coefficients derived with
;; skydips
if param.do_opacity_correction ge 1 then begin
   if param.force_opacity_225 eq 1 then begin
      w1 = where( kidpar.array eq 1 or kidpar.array eq 3, nw1)
      if nw1 ne 0 then begin
         tau = info.tau225*1.28689-0.00012725
         data.toi[w1] *= (exp(tau/sin(data.el))##(dblarr(nw1)+1.d0))
      endif
      w1 = where( kidpar.array eq 2, nw1)
      if nw1 ne 0 then begin
         tau = info.tau225*0.732015+0.0200369
         data.toi[w1] *= (exp(tau/sin(data.el))##(dblarr(nw1)+1.d0))
      endif
   endif else begin
      nk_get_opacity, param, info, data, kidpar, simpar=simpar
   endelse

   ;; Pipeline/Scr/Reference/Opacity/get_corrected_tau_skydip.pro,
   ;; Oct. 9th, 2018
   if param.correct_tau eq 1 then begin
;;      a = [1.35,    1.04,   1.24,   1.26 ]
;;      b = [-0.007, -0.013,  -0.05, -0.03]

      ;; Laurence's latest estimation, Oct. 25th, 2018
      a = [1.36d0, 1.03d0, 1.23d0, 1.27d0]
      b = dblarr(4)
      for iarray=1, 3 do begin
         w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
         if nw1 ne 0 then kidpar[w1].tau_skydip = b[iarray-1] + a[iarray-1]*kidpar[w1].tau_skydip
      endfor
   endif

endif else begin
   kidpar.tau_skydip = 0.d0
endelse

if param.bypass_calib eq 0 then begin
;; Apply absolute calibration and opacity correction
   nk_apply_calib_2, param, info, data, kidpar
   
;; Account for the telescope gain dependence on elevation, only for
;; point sources (NP and Herve Aussel, Dec. 28th, 2015)
   ;; revised with NIKA2 curve derived on 3C84, N2R12, Dec. 6th, 2017 NP.
   nk_tel_gain_cor, param, info, data, kidpar, extent_source=param.extended_source
endif

if param.cpu_time then nk_show_cpu_time, param

end
