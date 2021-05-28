;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_cm
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_get_cm, param, info, data, kidpar, wsample, common_mode
; 
; PURPOSE: 
;        Derives a common mode from all valid kids per band
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - common_mode: an average common mode computed from data.toi.
;          Common_mode is an array of [2,n_elements(data)] (one
;          common mode per band)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 08th, 2014: creation (Nicolas Ponthieu & Remi Adam -
;          adam@lpsc.in2p3.fr)
;        - June 19th, 2014: use nk_get_cm_sub now, NP
;-

pro nk_get_cm, param, info, data, kidpar, common_mode

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_cm, param, info, data, kidpar, common_mode"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn = n_elements(data)
common_mode = dblarr(2, nsn)

for lambda=1, 2 do begin
   nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1

   if nw1 ne 0 then begin

      if strupcase(param.decor_per_subscan) eq "YES" then begin

         for isubscan=min(data.subscan), max(data.subscan) do begin
            wsubscan = where( data.subscan eq isubscan, nwsubscan)
            nk_get_cm_sub, param, info, data[wsubscan].toi[w1], data[wsubscan].flag[w1], data[wsubscan].off_source[w1], kidpar[w1], cm
            common_mode[lambda-1,wsubscan] = cm
         endfor

      endif else begin          ; entire scan then
         nk_get_cm_sub, param, info, data.toi[w1], data.flag[w1], data.off_source[w1], kidpar[w1], cm
         common_mode[lambda-1,*] = cm
      endelse
   endif
endfor

end
