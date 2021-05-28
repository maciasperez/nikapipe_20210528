
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
;     nk_planet_calib
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         
; 
; PURPOSE: 
;        Applies planet (or calibration sources) fluxes in the derivation of the
;        absolute calibration.
; 
; INPUT: 
;        - param, data, kidpar
; 
; OUTPUT: 
;        - kidpar.calib and kidpar.calib_fix_fwhm
; 
; KEYWORDS:
;        - flux_1mm, flux_2mm : outputs
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - March 2015, NP, from nika_pipe_planet_calib
;-

pro nk_planet_calib, param, data, kidpar, flux_1mm=flux_1mm, flux_2mm=flux_2mm

;; Safe init
kidpar.calib          = 0.d0
kidpar.calib_fix_fwhm = 0.d0

nsn = n_elements(data)

;;el_avg_rad = data[nsn/2].el
bad = where(data.scan_valid[0] gt 0 and data.scan_valid[1] gt 0, nbad, comp=oksamp, ncomp=noksamp)
if noksamp gt 1 then begin
   el_avg_rad = median(data[oksamp].el)
endif else begin
   nk_error, info, "No valid samples ?!"
   return
endelse

for lambda=1, 2 do begin
   il = (where( round(!nika.lambda) eq lambda))[0]

   ;; Default init to make cross-calibration possible
   flux = 1.

   ;; Look for planet flux
   if strupcase(param.source) eq "URANUS"  then flux = !nika.flux_uranus[il]
   if strupcase(param.source) eq "MARS"    then flux = !nika.flux_mars[il]
   if strupcase(param.source) eq "NEPTUNE" then flux = !nika.flux_neptune[il]
   if strupcase(param.source) eq "SATURN"  then flux = !nika.flux_saturn[il]
   if strupcase(param.source) eq "CERES"   then flux = !nika.flux_ceres[il]
   if strupcase(param.source) eq "PALLAS"  then flux = !nika.flux_pallas[il]
   if strupcase(param.source) eq "VESTA"   then flux = !nika.flux_vesta[il]
   if strupcase(param.source) eq "LUTETIA" then flux = !nika.flux_lutetia[il]
   if strupcase(param.source) eq '3C84'    then flux = !nika.flux_3c84[il]

   ;; Overwrite if the fluxes are passed in input
   if keyword_set(flux_1mm) and lambda eq 1 then flux = flux_1mm
   if keyword_set(flux_2mm) and lambda eq 2 then flux = flux_2mm

   
   nk_list_kids, kidpar, lambda=lambda, on=w1, non=nw1
   if nw1 ne 0 then begin
      if el_avg_rad ne 0 then begin
         kidpar[w1].calib          = flux * exp(-kidpar[w1].tau_skydip/sin(el_avg_rad))/kidpar[w1].a_peak ; Jy/Hz
         kidpar[w1].calib_fix_fwhm = flux * exp(-kidpar[w1].tau_skydip/sin(el_avg_rad))/kidpar[w1].flux
      endif else begin
         ;; Lab measurements
         kidpar[w1].calib          = flux/kidpar[w1].a_peak ; Jy/Hz
         kidpar[w1].calib_fix_fwhm = flux/kidpar[w1].flux
      endelse
   endif
endfor

;; check calibration was indeed done
w = where( kidpar.calib ne 0, nw)
if nw eq 0 then begin
   message, /info
   message, "No calibration was done in nk_planet_calib."
endif


end
