;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_bandpass_filter
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_bandpass_filter, param, info, data, kidpar
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

pro nk_bandpass_filter, param, info, data, kidpar

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

;; Init filter
np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
             freqlow=param.freqlow, freqhigh=param.freqhigh, filter=filter, delta_f=param.bandpass_delta_f

;; Filter all kids
for ikid=0, n_elements(kidpar)-1 do begin
   if kidpar[ikid].type ne 2 then begin
      np_bandpass, data.toi[ikid]-my_baseline(data.toi[ikid],base=0.01), !nika.f_sampling, s_out, filter=filter
      data.toi[ikid] = s_out
      
      if info.polar ne 0 then begin
         np_bandpass, data.toi_q[ikid]-my_baseline(data.toi_q[ikid],base=0.01), !nika.f_sampling, s_out, filter=filter
         data.toi_q[ikid] = s_out
         np_bandpass, data.toi_u[ikid]-my_baseline(data.toi_u[ikid],base=0.01), !nika.f_sampling, s_out, filter=filter
         data.toi_u[ikid] = s_out
      endif
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param, "nk_bandpass_filter"

end
