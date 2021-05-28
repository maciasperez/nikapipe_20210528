;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_deglitch_fast
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         nk_deglitch_fast, param, info, data, kidpar
; 
; PURPOSE: 
;        Detect, flags and interpolate cosmic ray induced glitches
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 20th, 2015: NP: faster version than nk_deglitch. Looks for
;          flags on a single kid timeline and corrects all other timelines.
;-
;===========================================================================================================

pro nk_deglitch_fast, param, info, data, kidpar
  
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_deglitch_fast, param, info, data, kidpar"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

nsn   = n_elements(data)
nkids = n_elements( kidpar)

index = dindgen(nsn)

;; Only samples for which the signal is not well computed should be
;; discarded. Glitches have nothing to do with pointing errors and so
;; on
w1 = where( kidpar.type eq 1, nw1)
ikid_ref = min(w1)

y = data.toi[ikid_ref]

qd_deglitch_baseline, y, param.glitch_width, param.glitch_nsigma, data_out, flag0
data.toi[ikid_ref] = data_out
;; if info.polar ne 0 then begin
;;    wgood = where( flag0 eq 0, nwgood)
;;    if nwgood ne 0 then begin
;;       data_out = interpol( data[wgood].toi_q[ikid_ref], index[wgood], index)
;;       data.toi_q[ikid_ref] = data_out
;;       data_out = interpol( data[wgood].toi_u[ikid_ref], index[wgood], index)
;;       data.toi_u[ikid_ref] = data_out
;;    endif
;; endif
   
for i=0, nw1-1 do begin
   ikid = w1[i]
   if ikid ne ikid_ref then begin ; ikid already done

      ;; Interpolate only glitches, not all flagged values
      ;; Rely on non-flagged values for the interpolation (flag contains glitch flags too)
      wgood = where( flag0 eq 0, nwgood)
      if nwgood ne 0 then begin
         data_out = interpol( data[wgood].toi[ikid], index[wgood], index)
         data.toi[ikid] = data_out
         ;; if info.polar ne 0 then begin
         ;;    data_out = interpol( data[wgood].toi_q[ikid], index[wgood], index)
         ;;    data.toi_q[ikid] = data_out
         ;;    data_out = interpol( data[wgood].toi_u[ikid], index[wgood], index)
         ;;    data.toi_u[ikid] = data_out
         ;; endif
      endif
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_deglitch_fast"

end
