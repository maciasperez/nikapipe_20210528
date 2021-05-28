;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_filter
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_filter, param, info, data, kidpar
; 
; PURPOSE: 
;        bandpass filters, subtract polynomials...
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
;        - sample_index: the sample nums absolute values
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Dec. 16th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_filter, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_filter, param, info, data, kidpar"
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkf_status = 0

;;==============================================================================================
;; Bandpass filter
if param.bandpass ne 0 then begin
   ;; Init
   np_bandpass, data.toi[0], !nika.f_sampling, s_out, $
                freqlow=param.freqlow, freqhigh=param.freqhigh, filter=filter, delta_f=param.bandpass_delta_f

   ;; Filter all kids
   for ikid=0, n_elements(kidpar)-1 do begin
      if kidpar[ikid].type ne 2 then begin
         np_bandpass, data.toi[ikid]-my_baseline(data.toi[ikid]), !nika.f_sampling, s_out, filter=filter
         data.toi[ikid] = s_out

         if info.polar ne 0 then begin
            np_bandpass, data.toi_q[ikid]-my_baseline(data.toi_q[ikid]), !nika.f_sampling, s_out, filter=filter
            data.toi_q[ikid] = s_out
            np_bandpass, data.toi_u[ikid]-my_baseline(data.toi_u[ikid]), !nika.f_sampling, s_out, filter=filter
            data.toi_u[ikid] = s_out
         endif
      endif
   endfor
endif

;;==============================================================================================
;; Polynomial subtraction
if param.polynomial ne 0 then begin
   w1 = where( kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
      index = dindgen( n_elements(data))
      for i=0, nw1-1 do begin
         ikid = w1[i]
         wfit = where( data.flag[ikid] eq 0 and data.off_source[ikid] eq 1, nind)
            if nind eq 0 then begin
;               nk_error, info, "not enough point to subtract a polynomial for kid "+strtrim(ikid,2)
;               return
            endif else begin
               r = poly_fit( index[wfit], data[wfit].toi[ikid], $
                             param.polynomial, status = status)
               yfit = index*0.d0
               if status eq 0 then $  ; success
                  for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii else $
                     nkf_status = 1
               data.toi[ikid] -= yfit

               if info.polar ne 0 then begin
                  r = poly_fit( index[wfit], data[wfit].toi_q[ikid], $
                                param.polynomial, status = status)
                  yfit = index*0.d0
                  if status eq 0 then $ ; success
                     for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii
                  data.toi_q[ikid] -= yfit
                  
                  r = poly_fit( index[wfit], data[wfit].toi_u[ikid], $
                                param.polynomial,  status = status)
                  yfit = index*0.d0
                  if status eq 0 then $ ; success
                     for ii=0, n_elements(r)-1 do yfit += r[ii]*index^ii else $
                     nkf_status = 1
                  data.toi_u[ikid] -= yfit
               endif
            endelse
         endfor
   endif
endif
if nkf_status eq 1 then begin
   info.status = 1
   info.error_message = 'nk_filter : bad polynomial fitting'
endif


end
