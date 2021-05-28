;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_one_mode_per_array
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;         nk_decor_one_mode_per_array, param, info, toi, flag, off_source, kidpar, out_temp
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
;-

pro nk_decor_one_mode_per_array, param, info, toi, flag, off_source, kidpar, out_temp

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_decor_one_mode_per_array, param, info, toi, flag, off_source, kidpar, out_temp"
   return
endif

out_temp = toi*0.d0
for iarray=1, 3 do begin
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   if nw1 ne 0 then begin
      kidpar1 = kidpar[w1]
            ;;; Compute the common mode per array
      nk_get_cm_sub_2, param, info, toi[w1,*], flag[w1,*], $
                       off_source[w1,*], kidpar1, common_mode
      ;; update corr2cm
      kidpar[w1].corr2cm = kidpar1.corr2cm
      ;; Subtract this common mode per array
      nk_subtract_templates_3, param, info, toi[w1,*], flag[w1,*], off_source[w1,*], $
                               kidpar[w1], common_mode, out_cm
      out_temp[w1,*] = out_cm
   endif
endfor


end
