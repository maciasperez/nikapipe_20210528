
;+
;
; SOFTWARE:
;
; NAME: nk_save_scan_results_polar
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;            - nk_save_scan_results_polar, param, info, data, kidpar
; 
; PURPOSE: 
;        Save intermediate quantities relevant to this scan for
;        further combination with other scans
; 
; INPUT: 
;       - param, info, data, kidpar
; 
; OUTPUT: 
;      - a .save for the moment in !nika.plot_dir+"/Pipeline/scan_YYYYMMDD
; 
; KEYWORDS:
;      - map_1mm, map_2mm: maps of the current scan *only* (not the
;        cumulative of all scans until this one)
;
; SIDE EFFECT:
;      - creates directories and writes results on disk
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014: Nicolas Ponthieu
;-
;================================================================================================

pro nk_save_scan_results_polar, param, info, data, kidpar, $
                                map_1mm=map_1mm, map_q_1mm=map_q_1mm,$
                                map_u_1mm=map_u_1mm, map_2mm=map_2mm, $
                                map_q_2mm=map_q_2mm, map_u_2mm=map_u_2mm,$
                                filing=filing

if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   print, "nk_save_scan_results_polar, param, info, data, kidpar, $"
   print, "                            map_1mm=map_1mm, map_2mm=map_2mm, filing=filing"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; Create output directory
output_dir = !nika.plot_dir+"/Pipeline/scan_"+strtrim(param.scan,2)
spawn, "mkdir -p "+output_dir

;; Change names of variables for easier comparison to the current ones
;; when we restore them
param1  = param
info1   = info
kidpar1 = kidpar

cmd = "save, file=output_dir+'/results.save', param1, info1, kidpar1"
if keyword_set(map_1mm)   then cmd = cmd+", map_1mm"
if keyword_set(map_q_1mm) then cmd = cmd+", map_q_1mm"
if keyword_set(map_u_1mm) then cmd = cmd+", map_u_1mm"
if keyword_set(map_2mm)   then cmd = cmd+", map_2mm"
if keyword_set(map_q_2mm) then cmd = cmd+", map_q_2mm"
if keyword_set(map_u_2mm) then cmd = cmd+", map_u_2mm"
junk = execute(cmd)

if keyword_set(filing) then spawn, "rm -f "+param.up_file

end
