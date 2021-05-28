;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_check_param_grid
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_check_param, param
; 
; PURPOSE: 
;        check coherence between parameters
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 26th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - June 9th, 2015: added grid to nk_check_param and renamed the code accordingly
;-

pro nk_check_param_grid, param, info, grid

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_check_param_grid, param, info, grid"
   return
endif

if param.set_zero_level_full_scan ne 0 and $
   param.set_zero_level_per_subscan ne 0 then begin
   diagnostic = "Please choose either set_zero_level_full_scan OR set_zero_level_per_subscan OR none of them"
endif

if param.lab ne 0 then param.do_opacity_correction = 0

if param.corr_block_per_subscan eq 1 and strupcase(param.decor_per_subscan) eq 0 then begin
   print, ""
   diagnostic = "You asked for a decorrelation per blocks of correlated kids and per subscan"
   diagnostic = diagnostic+", but you set param.decor_per_subscan to 0."
   diagnostic = diagnostic+" You must set the two accordingly"
endif

if min(grid.mask_source) eq 1 then begin
   if strupcase(param.decor_method) eq "COMMON_MODE_KIDS_OUT" or $
      strupcase(param.decor_method) eq "COMMON_MODE_BAND_MASK" then begin
      diagnostic = "You have a chosen a decorrelation method that is meant to use a mask, "
      diagnostic = diagnostic+"however, grid.mask_source is uniformly 1, so nothing is masked out."
      diagnostic = diagnostic+" If you still want to proceed, then set param.do_checks = 0."
   endif
endif

if param.input_cm_1mm ne param.input_cm_2mm then begin
   diagnostic = "Please provide an input common mode to both bands"
endif

if param.map_reso ne grid.map_reso then begin
   diagnostic, "param.map_reso = "+strtrim(param.map_reso,2)+" does not match grid.map_reso = "+strtrim(grid.map_reso,2)
endif

nk_error, info, diagnostic

end
