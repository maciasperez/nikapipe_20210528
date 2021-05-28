;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_map_var_bg
;
; CATEGORY: map processing
;
; CALLING SEQUENCE:
;         nk_map_var_bg, map, nhits, mask_soure, map_var
; 
; PURPOSE: 
;        Derive the variance map from weights, observations and source mask
; 
; INPUT: 
;        - map, nhits, mask_source
; 
; OUTPUT: 
;        - map_var
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 11th, 2015: NP
;-

pro nk_map_var_bg, map, nhits, mask_source, map_var

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map_var_bg, map, nhits, mask_source, map_var"
   return
endif

wbg = where( nhits ne 0 and mask_source eq 1, nwbg)
if nwbg eq 0 then begin
   message, /info, "No valid pix to estimate the weight."
   stop
endif

;; Compute the equivalent sigma(1 hit) far from the source
hh = sqrt(nhits[wbg])*map[wbg]
sigma = stddev(hh)

;; Derive the new map variance on the entire map
map_var = double(nhits)*0.d0
w = where( nhits ne 0)
map_var[w] = sigma^2/nhits[w]


end
