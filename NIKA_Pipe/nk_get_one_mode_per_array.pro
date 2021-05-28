;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_get_one_mode_per_array
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_get_one_mode_per_array, param, info, toi, flag, off_source, kidpar, out_temp
; 
; PURPOSE: 
;        subroutine of nk_decor_sub_6
; 
; INPUT: 
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 16th, 2018: NP, extracted from nk_decor_sub_5 and
;          adpated to nk_clean_data_4.pro and its subroutines

pro nk_get_one_mode_per_array, param, info, toi, flag, off_source, kidpar, common_mode;, w8_source=w8_source
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_get_one_mode_per_array'
   return
endif

nsn = n_elements(toi[0,*])
common_mode = dblarr(3,nsn)
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      kidpar1 = kidpar[w1]
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar1, cm ;, w8_source=w8_source
      kidpar[w1].corr2cm = kidpar1.corr2cm
      common_mode[iarray-1,*] = cm
   endif
endfor


end
