;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_bandpass_filter_2
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_bandpass_filter_2, param, info, data, kidpar
; 
; PURPOSE: 
;        bandpass filters then data
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
;        - Dec. 16th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - March 4th, 2016: extracted from nk_filter
;-

pro nk_bandpass_filter_2, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_bandpass_filter, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;; ;; Init filter
;; np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
;;              freqlow=param.freqlow, freqhigh=param.freqhigh, filter=filter, delta_f=param.bandpass_delta_f
;; 
;; ;; Filter all kids
;; for ikid=0, n_elements(kidpar)-1 do begin
;;    if kidpar[ikid].type ne 2 then begin
;;       np_bandpass, data.toi[ikid]-my_baseline(data.toi[ikid],base=0.01), !nika.f_sampling, s_out, filter=filter
;;       data.toi[ikid] = s_out
;;       
;;       if info.polar ne 0 then begin
;;          np_bandpass, data.toi_q[ikid]-my_baseline(data.toi_q[ikid],base=0.01), !nika.f_sampling, s_out, filter=filter
;;          data.toi_q[ikid] = s_out
;;          np_bandpass, data.toi_u[ikid]-my_baseline(data.toi_u[ikid],base=0.01), !nika.f_sampling, s_out, filter=filter
;;          data.toi_u[ikid] = s_out
;;       endif
;;    endif
;; endfor

nsn = n_elements(data)

;; init filter
np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
             freqlow=param.freqlow, $
             freqhigh=param.freqhigh, $
             delta_f=param.bandpass_delta_f, filter=filter

;; check fft calling sequence
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

;; Expand filter
my_filter = filter##(dblarr(nw1)+1.d0)

;; Subtract baseline
nsn_base = round( !nika.f_sampling)
y0 = median( data[0:nsn_base-1].toi[w1], dim=2)
y1 = median( data[nsn-nsn_base:*].toi[w1], dim=2)
x0 = double( median( indgen(nsn_base)))
x1 = double( median( indgen(nsn_base)+nsn-nsn_base))
slope = (y1-y0)/(x1-x0)
baseline = (dblarr(nsn)+1.d0)##y0 + ((dblarr(nsn)+1.d0)##slope) * (dindgen(nsn)##(dblarr(nw1)+1.d0))
y = data.toi[w1] - baseline

;; Bandpass
ftsig = fft( y, /double, dimension=2)
data.toi[w1] = double( fft( ftsig*my_filter, /double, /inv, dim=2))
         
if param.cpu_time then nk_show_cpu_time, param

end
