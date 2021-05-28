;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_run5_opacity_patch
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_run5_opacity_patch, param, info, data, kidpar
; 
; PURPOSE: 
;        Reads the opacities that have been precomputed during run5
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the general NIKA strucutre containing time ordered information
;        - kidpar: the general NIKA structure containing kid related information
; 
; OUTPUT: 
;        - kidpar.tau_skydip is modified
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

pro nk_run5_opacity_patch, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_run5_opacity_patch, param, info, data, kidpar"
   return
endif

if strmid( strtrim(param.day,2), 0, 6) eq '201211' then begin
   ;;####### Rustine pour le Run5 sans le kidpar.opcity #######
       
   ;;------- Get the scan used here
   file_here = param.scan ;file written as 20121124s0008
   scan_here = param.scan_num
   day_here  = param.day

   ;;------- In some cases the opacity Run5 file has not been well
   ;;        computed, so we use the opacity taken from the closest scan
   if day_here eq '20121122' then begin
      if scan_here eq 78 or scan_here eq 79 or scan_here eq 80 or scan_here eq 81 or scan_here eq 82 $
      then scan_here = 83
      if scan_here eq 184 then scan_here = 180
   endif
   if day_here eq '20121123' then begin
      if scan_here eq 14 then scan_here = 13
   endif
   
   ;;------- Get the opacities for each scan of the Run5
   opa_r5 = mrdfits(!nika.soft_dir+'/Run5_pipeline/Calibration/opacity.fits', 1, head_r5)
   loc = where(opa_r5.day eq day_here and opa_r5.scan_num eq scan_here, nloc)
   
   ;;------- Get the right opacity
   if nloc ne 1 then message, 'The scan used here does not have one and only one opacity correspondance'
   opacity_1mm = (opa_r5.tau1mm[loc])[0]>0 ; truncate to avoid amplifying light (FXD)
   opacity_2mm = (opa_r5.tau2mm[loc])[0]>0 
   
   ;;------- Print the result for info
   if not keyword_set(simu) then message, /info, 'Opacity found at 1mm: '+ $
                                          string(opacity_1mm, format = fmt)
   if not keyword_set(simu) then message, /info, 'Opacity found at 2mm: '+ $
                                          string(opacity_2mm, format = fmt)
   
   ;; update param
   w = where( kidpar.array eq 1, nw)
   if nw ne 0 then kidpar[w].tau_skydip = opacity_1mm
   w = where( kidpar.array eq 2, nw)
   if nw ne 0 then kidpar[w].tau_skydip = opacity_2mm

   info.result_tau_1mm = opacity_1mm
   info.result_tau_2mm = opacity_2mm
endif

end
