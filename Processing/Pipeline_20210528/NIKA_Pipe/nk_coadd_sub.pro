;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_coadd_sub
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_coadd_sub, map_tot, map_w8_tot, map, map_8
; 
; PURPOSE: 
;        Combine maps with inverse noise weighting
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
;        - Nov. 28th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_coadd_sub, param, map_tot, map_w8_tot, nhits_tot, map, map_w8, nhits, mask_source

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

map_w8_1 = map_w8 ; init

w = where( map_w8 ne 0, nw)
if nw ne 0 then begin
   ;; Decide if you weight each scan by its inverse variance
   ;; derived on TOI's or on the map background.
   if param.map_bg_var_w8 eq 1 then begin
      wbg = where( map_w8 ne 0 and mask_source eq 1, nwbg)

      if nwbg eq 0 then begin
         message, /info, "No valid pix to estimate the weight."
         stop
      endif
      ;; Compute the equivalent sigma(1 hit) far from the source
      hh = sqrt(nhits[wbg])*map[wbg]
      sigma = stddev(hh)
      ;; Derive the new map variance on the entire map
      map_w8_1[w] = nhits[w]/sigma^2
   endif

   map_tot[   w] += map_w8_1[w] * map[w]
   map_w8_tot[w] += map_w8_1[w]       
   nhits_tot[ w] +=    nhits[w]       
endif

end
