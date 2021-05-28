
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_decor_common_mode_one_block
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
;        - March 25th, 2021: Emmanuel Artis and Laurence Perotto: add
;          the argument toi_out to output the noise residual after template subtraction  

pro nk_decor_common_mode_one_block, param, info, toi, flag, off_source, kidpar, $
                                    toi_out, common_mode, elevation, kid_corr_block, $
                                    extra_mode=extra_mode
;-
  
if n_params() lt 1 then begin
   dl_unix, 'nk_decor_common_mode_one_block'
   return
endif

;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)
nsn  = n_elements(toi[0,*])

;; Loop on kids
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

;; Backup toi, otherwise, it gets modified for each kid and the
;; decorrelation is performed on decorrelated timelines for the last
;; kids rather than on the same raw timelines on which the block was
;; determined ! (in nk_decor_sub_corr_block_2, the correction was done
;; on data.toi, so no prob.
;; LP: not sure it is necessary: toi is not changed in nk_get_cm_sub_2
;; -> nk_get_median_common_mode
toi_copy = toi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;E.A. & L.P.: Initialize toi_out
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
toi_out = toi
; END MODIF
common_mode = dblarr(nkids, nsn)
for i=0, nw1-1 do begin
   ikid = w1[i]
   
   ;; Flagged data have either been interpolated and are safe or are due
   ;; to uncertain pointing between subscans, but this does not affect their
   ;; temporal correlation, so we can use them for the regress.
   wsample = where( off_source[ikid,*] eq 1, nwsample)
   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this subscan for this kid
      flag[ikid,*] = 2L^7
   endif else begin
      wb = where(kid_corr_block[ikid,*] ne -1, nwb)
      if nwb eq 0 then begin
         nk_error, info, "no correlated kid found for ikid = "+strtrim(ikid,2)
         return
      endif
      block = reform(kid_corr_block[ikid,wb])

      if param.decor_all_kids_in_block eq 1 then begin
         templates = dblarr( 1 + nwb, nsn)
         templates[0,  *] = elevation
         templates[1:*,*] = toi_copy[block,*]
      endif else begin
;         if keyword_set(w8_source) then my_w8_source = w8_source[block,*]
         nk_get_cm_sub_2, param, info, toi_copy[block,*], flag[block,*], off_source[block,*], $
                          kidpar[block], block_common_mode;, w8_source=my_w8_source

         ;; Add elevation like for all decorrelations
         if keyword_set(extra_mode) then begin
            templates = transpose( [[block_common_mode], [elevation], [extra_mode]])
         endif else begin
            templates = transpose( [[block_common_mode], [elevation]])
         endelse

      endelse

      ;; Regress the common_mode and the data off source...
      coeff = regress( templates[*,wsample], reform( toi[ikid,wsample]), $
                       CHISQ= chi, CONST= const, CORRELATION= corr, $
                       /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
      ;; ... but subtract the common_mode everywhere
      yfit = dblarr(nsn) + const
      for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
      ;; EA and LP: add the following line
      toi_out[ikid,*] -= yfit
      common_mode[ikid,*] = yfit

      ;; Comment out the decorrelation on Q and U,
      ;; NP. Nov. 19th, 2017, see nk_decor_sub_corr_block2.
   endelse
endfor



if param.cpu_time then nk_show_cpu_time, param
  
end
