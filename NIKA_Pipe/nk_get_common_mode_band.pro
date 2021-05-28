;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_common_mode_band
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_get_common_mode_band, param, info, data, kidpar, common_mode_i, $
;                               common_mode_q=common_mode_q, common_mode_u=common_mode_u
; 
; PURPOSE: 
;        Computes one common mode per electronic band
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - common_mode
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 19th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_get_common_mode_band, param, info, kidpar, toi, flag, off_source, common_mode

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

;; Defined electronic band value
band_value = long(kidpar.numdet)/long(80)

;; Count how many kids per band (some may be empty, e.g. if kids have been flagged...)
n_cm = 0
for iband=min(band_value), max(band_value) do begin
   w = where( band_value eq iband, nw)
   if nw ne 0 then n_cm++
endfor
      
;; Compute one common mode per band
nsn = n_elements( toi[0,*])
common_mode = dblarr( n_cm, nsn)
icm = 0
for iband=min(band_value), max(band_value) do begin
   w = where( band_value eq iband, nw)
   if nw ne 0 then begin
      ;;nk_get_cm_sub, param, info, toi[w,*], flag[w,*], off_source[w,*], kidpar[w,*], cm
      nk_get_cm_sub_2, param, info, toi[w,*], flag[w,*], off_source[w,*], kidpar[w,*], cm
      common_mode[icm,*] = cm
      icm++
   endif
endfor

end
