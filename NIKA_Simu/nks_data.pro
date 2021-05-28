;+
;
; SOFTWARE: NIKA simulation pipeline
;
; NAME:
; nks_data
;
; CATEGORY: general,launcher
;
; CALLING SEQUENCE:
;         nks_data, param, simpar, data, kidpar
; 
; PURPOSE: 
;        Produces the simulated data structure to be processed by the analysis pipeline
; 
; INPUT: 
;        - simparam: the simulation parameter structure
;        - info: the data info structure
;        - data: the original data taken from a real observation scan or
;          produced by another extra simulation routine from scratch.
;        - kidpar: the original kid structure from a real observation scan or
;          produced by another extra simulation routine from scratch.
; 
; OUTPUT: 
;        - data
;        - kidpar
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 23rd, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)

pro nks_data, param, simpar, info, data, kidpar, astr=astr
;-

;;========== Calling sequence
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'nks_data'
   return
endif
  
if simpar.reset ge 1 then data.toi = 0.d0
if param.cpu_time    then param.cpu_t0 = systime(0, /sec)

;; if simpar.uniform_fwhm eq 1 then begin
;;    for lambda=1, 2 do begin
;;       w = where( kidpar.array eq lambda, nw)
;;       if lambda eq 1 then fwhm = simpar.fwhm_1mm else fwhm = simpar.fwhm_2mm
;;       if nw ne 0 then begin
;;          kidpar[w].fwhm    = fwhm
;;          kidpar[w].sigma_x = fwhm*!fwhm2sigma
;;          kidpar[w].sigma_y = fwhm*!fwhm2sigma
;;       endif
;;    endfor
;; endif

;; @ If there is an imput map, produce the TOI's
if tag_exist( simpar, "XMAP") then begin
   nk_maps2data_toi, param, info, data, kidpar, simpar, output_toi, astr=astr
   if simpar.reset eq 1 then begin
      data.toi = output_toi
   endif else begin
      data.toi += output_toi
   endelse
endif

;; @ Add point sources directly to the timelines
nks_add_source, param, simpar, info, data, kidpar, astr=astr

;; Sanity check on the simulated TOI:
w1 = where( kidpar.type eq 1, nw1)
for i=0, nw1-1 do begin
   ikid = w1[i]
   if total( finite(data.toi[ikid]))/n_elements(data) lt 1 then begin
      message, /info, "There are NaN values in the simulated TOI (ikid = "+strtrim(ikid,2)
      stop
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param
  
end
