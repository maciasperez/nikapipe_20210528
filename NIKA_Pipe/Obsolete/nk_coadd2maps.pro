;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_coadd2maps
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_coadd2maps, info_in, info_out
; 
; PURPOSE: 
;        Normalizes the coadded map by the weights map
; 
; INPUT: 
;
; 
; OUTPUT: 
;        - info_out: info_out.map_1mm, info_out.2mm, info_out.map_var_1mm,
;          info_out.map_var_2mm
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 13th, NP
;-

pro nk_coadd2maps, param, info, coadd_map, map_w8, map, map_var

if n_params() lt 1 then begin
   message, /info, 'Calling sequence:'
   print, "nk_coadd2maps, param, info, coadd_map, map_w8, map, map_var"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;; init
map     = coadd_map*0.d0
map_var = coadd_map*0.d0

;; Compute
w = where( map_w8 ne 0, nw)
if nw ne 0 then begin
   map[w]     = coadd_map[w]/map_w8[w]
   map_var[w] =         1.d0/map_w8[w]
endif
  
end
