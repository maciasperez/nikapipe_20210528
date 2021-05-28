
;+
;
; SOFTWARE:
; NIKA pipeline
;
; NAME: 
; nk_check_lkg
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_check_lkg, param, info, input_polar_maps, lkg_kernel
; 
; PURPOSE: 
;        Checks that lkg_kernel and input_polar_maps match the current scan reduction.
; 
; INPUT: 
;        - param, info, input_polar_maps, lkg_kernel
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Aug. 13th, 2015: N. Ponthieu
;-

pro nk_check_lkg, param, info, input_polar_maps, lkg_kernel

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_check_lkg, param, info, input_polar_maps, lkg_kernel"
   return
endif

if input_polar_maps.map_proj ne param.map_proj then begin
   nk_error, info, "input_polar_maps.map_proj = "+strtrim(input_polar_maps.map_proj,2)+" does not match "+$
             "param.map_proj="+strtrim(param.map_proj,2)
   return
endif
if lkg_kernel.map_reso ne param.map_reso then begin
   nk_error, info, "lkg_kernel.map_reso = "+strtrim(lkg_kernel.map_reso,2)+" does not match "+$
             "param.map_reso="+strtrim(param.map_reso,2)
   return
endif
if input_polar_maps.nx ne lkg_kernel.nx then begin
   nk_error, info, "input_polar_maps_param.nx = "+strtrim(input_polar_maps_param.nx,2)+" does not match "+$
             "param.nx="+strtrim(param.nx,2)
   return
endif
if input_polar_maps.ny ne lkg_kernel.ny then begin
   nk_error, info, "input_polar_maps_param.ny = "+strtrim(input_polar_maps_param.ny,2)+" does not match "+$
             "param.ny="+strtrim(param.ny,2)
   return
endif

end
