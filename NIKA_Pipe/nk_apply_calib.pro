;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
; nk_apply_calib
;
; CATEGORY: 
;        calibration
;
; CALLING SEQUENCE:
;         nk_apply_calib, param, info, data, kidpar
; 
; PURPOSE: 
;        Applies point source calibration to all timelines, accouting for
;        opacity as provided in kidpar.tau_skydip
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

pro nk_apply_calib, param, info, data, kidpar, inverse=inverse

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_apply_calib param, info, data, kidpar"
   return
endif

nkids = n_elements(kidpar)

;; Correct to avoid elevation being 0 
bad = where(data.scan_valid[0] gt 0 and data.scan_valid[1] gt 0, nbad, comp=oksamp, ncomp=noksamp)
if noksamp gt 1 then begin
   elev_moy = median(data[oksamp].el)
endif else begin
   nk_error, info, "No valid samples ?!"
   return
endelse

;; Loop over all kids
for ikid=0, nkids-1 do begin
   if kidpar[ikid].type eq 1 then begin ;only calibrate type 1 KIDs
      
      ;; kidpar.tau_skydip is zero by default or updated by nk_get_opacity
      if param.do_opacity_correction eq 0 then begin
         corr = 1.d0
      endif else begin
         corr = exp( kidpar[ikid].tau_skydip/sin(elev_moy))
      endelse

      ;; Calibrate
      if keyword_set(inverse) then begin
         if param.lab eq 1 then begin
            ;; take calib and not calib_fix_fwhm because in the lab, the FWHM are
            ;; larger than the nominal ones stored in !nika
            data.toi[ikid] = data.toi[ikid] / kidpar[ikid].calib
         endif else begin
            if strmid( strtrim(param.day,2), 0, 6) eq '201211' or $
               strmid( strtrim(param.day,2), 0, 6) eq '201306' or $
               strmid( strtrim(param.day,2), 0, 6) eq '201311' $
            then data.toi[ikid] = data.toi[ikid] /( kidpar[ikid].calib * corr) $
            else data.toi[ikid] = data.toi[ikid] /( kidpar[ikid].calib_fix_fwhm * corr)
         endelse
      endif else begin
         if param.lab eq 1 then begin
            ;; take calib and not calib_fix_fwhm because in the lab, the FWHM are
            ;; larger than the nominal ones stored in !nika
            data.toi[ikid] = data.toi[ikid] * kidpar[ikid].calib
         endif else begin
            if strmid( strtrim(param.day,2), 0, 6) eq '201211' or $
               strmid( strtrim(param.day,2), 0, 6) eq '201306' or $
               strmid( strtrim(param.day,2), 0, 6) eq '201311' $
            then data.toi[ikid] = data.toi[ikid] * kidpar[ikid].calib * corr $
            else data.toi[ikid] = data.toi[ikid] * kidpar[ikid].calib_fix_fwhm * corr
         endelse
      endelse

   endif
 
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_apply_calib"


end
