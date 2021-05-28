;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_check_param
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
;        - Nov. 26th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_check_param, param, info

if param.set_zero_level_full_scan ne 0 and $
   param.set_zero_level_per_subscan ne 0 then begin
   message = "Please choose either set_zero_level_full_scan OR set_zero_level_per_subscan OR none of them"
   nk_error, info, message
endif

if param.lab ne 0 then param.do_opacity_correction = 0

if param.corr_block_per_subscan eq 1 and strupcase(param.decor_per_subscan) eq 0 then begin
   print, ""
   message = "You asked for a decorrelation per blocks of correlated kids and per subscan"
   message = message+", but you set param.decor_per_subscan to 0."
   message = message+" You must set the two accordingly"
   nk_error, info, message
endif

if (param.clean_data_version eq 4) then begin
   message = ''
   error = 0
   if (strupcase(param.decor_2_method) ne "NONE") then begin
      print, ""
      message += "A second decorrelation is not available in param.clean_data_version=4"
      message += "because it does not work with an iterative map making and alternative"
      message += "methods of decorrelations have been divised."
      error = 1
   endif
   if param.line_filter ne 0 then begin
      print, ""
      message += "param.line_filter does not work with param.clean_data_version=4 for now"
      message += " because it does not work with iterative MM."
      error = 1
   endif
   if param.bandkill ne 0 then begin
      print, ""
      message += "param.bandkill does not work with param.clean_data_version=4 for now"
      message += " because it does not work with iterative MM."
      error = 1
   endif
   if error eq 1 then nk_error, info, message
endif

if tag_exist( param, 'tiling_decorrelation') then begin
   if param.tiling_decorrelation eq 1 then begin
      param.decor_per_subscan = 0
   endif
endif

if param.polynomial_on_residual ne 0 and param.edge_source_interpol eq 0 then begin
   txt = "polynomial_on_residual and edge_source_interpol must be set together"
   message, /info, txt
   nk_error, info, txt
endif


end
