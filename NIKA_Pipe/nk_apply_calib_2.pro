;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_apply_calib_2
;
; CATEGORY: 
;        calibration
;
; CALLING SEQUENCE:
;         nk_apply_calib_2, param, info, data, kidpar
; 
; PURPOSE: 
;        Calibrates TOIs using kidpar.calib_fix_fwhm and
;        opacity/elevation corrections.
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
;        - 17/03/2014: creation (Nicolas Ponthieu) from (old
;          nika_pipe_opacity.pro and nika_pipe_calib.pro)
;-

pro nk_apply_calib_2, param, info, data, kidpar, inverse=inverse

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_apply_calib param, info, data, kidpar"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

nkids = n_elements(kidpar)

;; Correct to avoid elevation being 0 
bad = where(data.scan_valid[0] gt 0 and data.scan_valid[1] gt 0, nbad, comp=oksamp, ncomp=noksamp)
if noksamp gt 1 then begin
   elev_moy = median(data[oksamp].el)
endif else begin
   nk_error, info, "No valid samples ?!"
   return
endelse

corr = exp( kidpar.tau_skydip/sin(elev_moy))

; Correction is already done in nk_get_opacity if do_opacity_correction==2
; and it will be done after the decorrelation in nk_scan_reduce if do_opacity_correction==3
if param.do_opacity_correction GE 2 then corr = 1D0

if param.force_opacity_225 then begin
   corr = exp( info.tau225/sin(elev_moy))
endif

;; Calibrate
if param.lab eq 1 then begin
   calib = kidpar.calib
endif else begin
   if strmid( strtrim(param.day,2), 0, 6) eq '201211' or $
      strmid( strtrim(param.day,2), 0, 6) eq '201306' or $
      strmid( strtrim(param.day,2), 0, 6) eq '201311' $
   then calib = kidpar.calib*corr $
   else calib = kidpar.calib_fix_fwhm * corr
endelse

w1 = where( kidpar.type eq 1, nw1)
nsn = n_elements(data)

;; This solution with ## is actually faster than using "rebin"
;; NP. Dec. 2016 as can be checked below
calib = (dblarr(nsn)+1) ## calib[w1]
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

if param.cpu_time then nk_show_cpu_time, param

end
