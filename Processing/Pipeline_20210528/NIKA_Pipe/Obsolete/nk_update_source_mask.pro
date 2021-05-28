;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_update_source_mask
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;         nk_update_source_mask, param, info, data, kidpar
; 
; PURPOSE: 
;        updates info.mask_source during iterations in nk_toi2map
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the nika data structure
;        - kidpar: the kids structure
; 
; OUTPUT: 
;        - info.mask_source
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 12th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_update_source_mask, param, info, data, kidpar

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.mask_freq eq 1 then begin
   map     = info.map_1mm
   map_var = info.map_var_1mm
endif else begin
   map     = info.map_2mm
   map_var = info.map_var_2mm
endelse

if strupcase( param.mask_method) eq "S_OVER_N" then begin
   ;; Common mask for both lambda for now (to be changed later on)
   map_sn = map*0.d0 + 1.d0
   w = where( map_var gt 0.d0, nw)
   if nw eq 0 then begin
      nk_error, info, "variance <0 for all pixels at 1mm"
      return
   endif else begin
      map_sn[w] = map[w]/sqrt(map_var[w])
   endelse

   ;; reset mask
   info.mask_source = 1.d0
   w = where( map_sn ge param.mask_s_over_n_nsigma, nw)
   if nw ne 0 then info.mask_source[w] = 0.d0
endif

if strupcase( param.mask_method) eq "SIGNAL" then begin
   ;; Common mask for both lambda for now (to be changed later on)
   w = where( map gt param.mask_signal_threshold, nw)
   if nw eq 0 then begin
      nk_error, info, "No pixel with intensity >= param.mask_signal_threshold: "+num2string(param.mask_signal_threshold)+" ?!"
      return
   endif else begin
      ;; reset mask
      info.mask_source = 1.d0
      if nw ne 0 then info.mask_source[w] = 0.d0
   endelse
endif



end
