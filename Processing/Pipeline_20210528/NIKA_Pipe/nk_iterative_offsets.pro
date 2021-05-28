;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_iterative_offsets
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_iterative_offsets, param, info, data, kidpar, subtract_maps
; 
; PURPOSE: 
;        Computes offsets (aka zero level) per subscan after a first iteration
;of the final map was provided and subtracted. All the subscan is used, no
;region is masked but regions with strong signal are downweighted.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - May 4th, 2016: NP & FXD

pro nk_iterative_offsets, param, info, data, kidpar, subtract_maps

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_iterative_offsets, param, info, data, kidpar, subtract_maps"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

nsn = n_elements(data)
w1  = where( kidpar.type eq 1, nw1)

;; Read input maps and associated variance
nk_maps2data_toi, param, info, data, kidpar, subtract_maps, $
                  toi_input_maps, $
                  output_toi_var_i=toi_var_i

w1 = where( kidpar.type eq 1, nw1)

;; wind, 1, 1, /free
;; plot, data.toi[w1[0]], /xs, title=param.scan
;; oplot, toi_input_maps[w1[0],*], col=150
;; stop

for isubscan=min(data.subscan), max(data.subscan) do begin
   wsample = where( data.subscan eq isubscan, nwsample)
   if nwsample ne 0 then begin

      for i=0, nw1-1 do begin
         ikid = w1[i]
         sigma2 = stddev( data[wsample].toi[ikid])^2
         
         ;; Xavier's original idea
         w8 = 1.d0/(sigma2 + param.iterative_offsets_k*toi_input_maps[ikid,wsample]^2)
         offset = total(w8*data[wsample].toi[ikid])/total(w8)

         ;; ;; old formula (off source and equal weight)
         ;; w = where( data.subscan eq isubscan and data.off_source[ikid] eq 1, nw)
         ;; old_offset = avg( data[w].toi[ikid])
         ;; print, "offset, old_offset: ", offset, old_offset
         
         data[wsample].toi[ikid] -= offset
      endfor

   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_iterative_offsets"
end
