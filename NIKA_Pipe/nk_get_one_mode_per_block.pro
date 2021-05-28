
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_one_mode_per_block
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; PURPOSE: 
;       Decorrelates kids from a common mode. This common mode is
;computed from the block of kids specified in kid_corr_block
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - toi, flag, off_source, kid_corr_block
; 
; OUTPUT: 
;        - toi
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 16th, 2018: NP, from nk_decor_sub_corr_block2,
;          adpated to nk_decor_sub_6
;-

pro nk_get_one_mode_per_block, param, info, toi, flag, off_source, kidpar, kid_corr_block, common_mode, $
                               atm_common=atm_common, decor_per_block=decor_per_block

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_one_mode_per_block, param, info, toi, flag, off_source, kidpar, common_mode, $"
   print, "                           atm_common=atm_common, decor_per_block=decor_per_block"  
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkid = n_elements(kidpar)
nsn  = n_elements(data)

;; Loop on all kids
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

for i=0, nw1-1 do begin
   ikid = w1[i]
   
   ;; Flagged data have either been interpolated and are safe or are due
   ;; to uncertain pointing between subscans, but this does not affect their
   ;; temporal correlation, so we can use them for the regress.
   wsample = where( off_source[ikid,*] eq 1, nwsample)
   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this subscan for this kid
      flag[ikid,*] = 1
   endif else begin
      wb = where(kid_corr_block[ikid,*] ne -1, nwb)
      if nwb eq 0 then begin
         nk_error, info, "no correlated kid found for ikid = "+strtrim(ikid,2)
         return
      endif
      block = reform(kid_corr_block[ikid,wb])

      ;; Intensity
      ;; in get_sub_3, the median common mode is computed from the block only and then
      ;; serves for intercalibration. Remi actually computes the median common
      ;; mode with all kids, then cross-calibrate on this median CM and only
      ;; then builds the decorrelation CM with the block...
      nk_get_cm_sub_3, param, info, toi[block,*], off_source[block,*], kidpar[block], $
                       block_common_mode, coeffs
      
      ;; Ensure that "block_common_mode" has the correct form for
      ;; REGRESS
      if keyword_set(atm_common) then begin
         templates = transpose( [[atm_common], [block_common_mode], [data.el]])
      endif else begin
         templates = transpose( [[block_common_mode], [data.el]])
      endelse

      ;; Regress the common_mode and the data off source...
      coeff = regress( templates[*,wsample], reform( toi[ikid,wsample]), $
                       CHISQ= chi, CONST= const, CORRELATION= corr, $
                       /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
      ;; ... but subtract the common_mode everywhere
      yfit = dblarr(nsn) + const
      for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
      toi[ikid,*] -= yfit
      common_mode[ikid,*] = yfit

      ;; Comment out the decorrelation on Q and U,
      ;; NP. Nov. 19th, 2017, see nk_decor_sub_corr_block2.
   endelse
endfor

if param.cpu_time then nk_show_cpu_time, param
  
end
