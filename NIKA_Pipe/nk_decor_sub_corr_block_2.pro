;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_sub_corr_block_2
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; PURPOSE: 
;        Computes a common mode from the kids that are most correlated to the current kid.
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
;        - Jan 3rd, 2015: extracted from nk_decor_sub_block_remi (NP)
;-

pro nk_decor_sub_corr_block_2, param, info, data, kidpar, $
                               kid_corr_block=kid_corr_block, out_temp_data=out_temp_data, $
                               atm_common=atm_common

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

;;--------------------------------------
;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

if param.corr_block_per_subscan eq 0 then begin
   if not keyword_set(kid_corr_block) then begin
      nk_error, info, "you must provide kid_corr_block"
      return
   endif
endif else begin
   ;; Then recompute blocks of correlated kids for each subscan if we are in
   ;; decor_per_subscan mode.
   nk_get_corr_block_2, param, info, data, kidpar, kid_corr_block
endelse
;;--------------------------------------

nkid = n_elements(kidpar)
nsn  = n_elements(data)

if info.polar ne 0 then begin
   out_temp_data = create_struct( "toi", data[0].toi, "toi_q", data[0].toi_q, "toi_u", data[0].toi_u)
endif else begin
   out_temp_data = create_struct( "toi", data[0].toi)
endelse
out_temp_data = replicate( out_temp_data, nsn)

;;======= Look at all KIDs

;; We must init a toi array otherwise each toi is altered in the loop while it
;; must be used in the common mode estimation of the next kids
toi = data.toi
if info.polar ne 0 then begin
   toi_q = data.toi_q
   toi_u = data.toi_u
endif

for iarray=1, 3 do begin
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
   
   if nw1 ne 0 then begin

      ;; To determine the kids cross-calibration a la Remi, compute the median
      ;; common mode using all kids, not only those of the block
      if param.median_common_mode_per_block eq 0 then begin
         in_median_common_mode_i = median( data.toi[w1], dim=1)
         if info.polar ne 0 then begin
            in_median_common_mode_q = median( data.toi_q[w1], dim=1)
            in_median_common_mode_u = median( data.toi_u[w1], dim=1)
         endif
      endif

      for i=0, nw1-1 do begin
         ikid = w1[i]

         ;; Flagged data have either been interpolated and are safe or are due
         ;; to uncertain pointing between subscans, but this does not affect their
         ;; temporal correlation, so we can use them for the regress.
         wsample = where( data.off_source[ikid] eq 1, nwsample)
         if nwsample lt param.nsample_min_per_subscan then begin
            ;; do not project this subscan for this kid
            data.flag[ikid] = 1
         endif else begin
            
            wb = where(kid_corr_block[ikid,*] ne -1, nwb)
            if nwb eq 0 then begin
               nk_error, info, "no correlated kid found for ikid = "+strtrim(ikid,2)
               return
            endif
            block = reform(kid_corr_block[ikid,wb])

            if param.decor_all_kids_in_block eq 1 then begin
               templates = dblarr( 1 + nwb, nsn)
               templates[0,*]   = data.el
               templates[1:*,*] = toi[block,*]
            endif else begin
               ;; Intensity
               ;; in get_sub_3, the median common mode is computed from the block only and then
               ;; serves for intercalibration. Remi actually computes the median common
               ;; mode with all kids, then cross-calibrate on this median CM and only
               ;; then builds the decorrelation CM with the block...
               nk_get_cm_sub_3, param, info, toi[block,*], data.off_source[block], kidpar[block], $
                                common_mode, coeffs, in_median_common_mode=in_median_common_mode_i
               
               ;; Ensure that "common_mode" has the correct form for
               ;; REGRESS
               if keyword_set(atm_common) then begin
                  templates = transpose( [[atm_common], [common_mode], [data.el]])
               endif else begin
                  templates = transpose( [[common_mode], [data.el]])
               endelse
            endelse

;;            if ikid eq 580 then begin
;;               wind, 1, 1, /free, /xlarge
;;               plot, common_mode, /xs, /ys
;;               stop
;;            endif

            ;; Regress the common_mode and the data off source...
            coeff = regress( templates[*,wsample], reform( toi[ikid,wsample]), $
                             CHISQ= chi, CONST= const, CORRELATION= corr, $
                             /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
            ;; ... but subtract the common_mode everywhere
            yfit = dblarr(nsn) + const
            for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
            data.toi[ikid] -= yfit
            if keyword_set(out_temp_data) then out_temp_data.toi[ikid] = yfit

            ;; Comment out the decorrelation on Q and U,
            ;; NP. Nov. 19th, 2017
;;             if info.polar ne 0 then begin
;; 
;;                ;; Q
;;                nk_get_cm_sub_3, param, info, toi_q[block,*], data.off_source[block], kidpar[block], $
;;                                 common_mode_q, in_median_common_mode=in_median_common_mode_q
;;                templates = transpose( [[common_mode_q], [data.el]])
;;                coeff = regress( templates[*,wsample], reform( toi_q[ikid,wsample]), $
;;                                 CHISQ= chi, CONST= const, CORRELATION= corr, $
;;                                 /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
;;                yfit = dblarr(nsn) + const
;;                for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
;;                data.toi_q[ikid] -= yfit
;;                if keyword_set(out_temp_data) then out_temp_data.toi_q[ikid] = yfit
;; 
;;                ;; U
;;                nk_get_cm_sub_3, param, info, toi_u[block,*], data.off_source[block], kidpar[block], $
;;                                 common_mode_u, in_median_common_mode=in_median_common_mode_u
;;                templates = transpose( [[common_mode_u], [data.el]])
;;                coeff = regress( templates[*,wsample], reform( toi_u[ikid,wsample]), $
;;                                 CHISQ= chi, CONST= const, CORRELATION= corr, $
;;                                 /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
;;                yfit = dblarr(nsn) + const
;;                for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
;;                data.toi_u[ikid] -= yfit
;;                if keyword_set(out_temp_data) then out_temp_data.toi_u[ikid] = yfit
;;             endif
         endelse
      endfor
   endif
endfor

if param.cpu_time then nk_show_cpu_time, param
  
end
