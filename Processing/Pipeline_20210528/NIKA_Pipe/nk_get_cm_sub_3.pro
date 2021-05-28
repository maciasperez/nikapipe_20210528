;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_cm_sub_3
;
; CATEGORY: toi processing, subroutine of nk_get_cm
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Derives a common mode from all the input kids. Same as nk_get_cm_sub,
;but instead of cross calibrating kids on the first valid kid, I now cross
;calibrate on the median common mode.
; 
; INPUT: 
; 
; OUTPUT: 
;        - common_mode: an average common mode computed from the input
;          toi
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Nov. 16th, 2014: (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_get_cm_sub_3, param, info, toi, off_source, kidpar, common_mode, coeffs, $
                     in_median_common_mode=in_median_common_mode

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_cm_sub_3, param, info, toi, off_source, kidpar, common_mode, coeffs, $"
   print, "                 in_median_common_mode=in_median_common_mode"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nsn         = n_elements( toi[0,*])
common_mode = dblarr(nsn)
w8          = dblarr(nsn)
nkids       = n_elements( toi[*,0])
ikid0       = 0 ; ref kid for cross-calibration
coeffs      = dblarr( nkids, 2)

;; Cross-calibration common mode
if keyword_set(in_median_common_mode) then begin
   median_common_mode = in_median_common_mode
endif else begin
   median_common_mode = median( toi, dim=1)
endelse

for ikid=0, nkids-1 do begin

   wsample  = where( off_source[ikid,*]  ne 0, nwsample)
   if nwsample ne 0 then begin
   
      ;; Account for kid noise in the common_mode estimation
      ;; Cross calibrate ikid on the median common mode
      fit = linfit( toi[ikid,wsample], median_common_mode[wsample])
      if total(finite(fit)) ne 2 then begin
         message,  /info, "infinite fit values for kid "+strtrim(ikid,2)
      endif else begin
         ;; add to common mode only if the sample is off source
         common_mode += (fit[0] + fit[1]*toi[ikid,*])*double(off_source[ikid,*] eq 1)/kidpar[ikid].noise^2
         w8          +=                               double(off_source[ikid,*] eq 1)/kidpar[ikid].noise^2
         coeffs[ikid,0] = fit[0]
         coeffs[ikid,1] = fit[1]
      endelse
   endif

endfor

;; check for holes and average
w = where( w8 eq 0, nw, compl=wkeep, ncompl=nwkeep)
if nw eq 0 then begin
   common_mode /= w8
endif else begin

   if nwkeep eq 0 then begin
      ;; no common mode was computed because flags and off_source did not allow
      ;; it
;      nk_error, info, "Common mode not computed"
;      return
   endif else begin
      if not param.interpol_common_mode then begin
         nk_error, info, "There are "+strtrim(nw,2)+" holes in the derived common_mode"
         return
      endif else begin
         common_mode = interpol( common_mode[wkeep], wkeep, lindgen(n_elements(common_mode)))
         w8          = interpol(          w8[wkeep], wkeep, lindgen(n_elements(common_mode)))
         common_mode /= w8
      endelse
   endelse
endelse

end
