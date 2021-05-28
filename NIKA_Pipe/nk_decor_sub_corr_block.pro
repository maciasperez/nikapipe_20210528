;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_decor_sub_corr_block
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

pro nk_decor_sub_corr_block, param, info, kidpar, toi, off_source, elev, ofs_el, out_temp, out_block

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
;;--------------------------------------

nkid = n_elements(kidpar)
if nkid ne n_elements(toi[*,0]) then message, "incompatible kidpar and toi"
w1  = where( kidpar.type eq 1, nw1)
nsn = n_elements( toi[0,*])

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; if min(kidpar.array eq 2) then begin
;;    stop
;;    message, /info, "fix me:"
;;    restore, "rf_didq.save"
;;    toi[w1,255] = rf_didq[w1,255]
;;    stop
;; endif
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TOI_out  = toi*0.d0
out_temp = toi*0.d0

;;------- Cross Calibration
atm_x_calib = dblarr(nkid,2)
atm_x_calib[*,1] = 1.d0
atmxcalib = nika_pipe_atmxcalib(toi[w1,*], 1-off_source[w1, *])
atm_x_calib[w1, *] = atmxcalib
;;print, "atm_x_calib[0:10]: ", atm_x_calib[0:10]
  
;;------- Compute the correlation between all KIDs and to 0
;mcorr = correlate(toi)
w = where( off_source eq 1, nw)
mcorr = correlate( toi[*,w])
wnan = where(finite(mcorr) ne 1, nwnan)
if nwnan ne 0 then mcorr[wnan] = -1

;;======= Look at all KIDs
for i=0, nw1-1 do begin
   ikid = w1[i]
   wfit = where(off_source[ikid,*] eq 1, nwfit)
   if nwfit eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
                               'It is so large that the decorrelated KID is always on-source'

   ;;------- Search for best set of KIDs to be used for deccorelation
   corr = reform(mcorr[ikid,*])
   wbad = where(kidpar.type ne 1, nwbad) ;Force rejected KIDs not to be correlated
   if nwbad ne 0 then corr[wbad] = -1
   s_corr = corr[reverse(sort(corr))] ;Sorted by best correlation
     
   ;;First bloc with the min number of KIDs allowed
   block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)
;;   if kidpar[ikid].array eq 2 then begin
;;      print, "ikid / s_corr[0:10]: "+strtrim(ikid,2)+"/ ", s_corr[0:10]
;;      stop
;;   endif
   ;;Then add KIDs and test if correlated enough  
   sd_block = stddev(corr[block])
   mean_block = mean(corr[block])

;;   ;;*************************************************
;;   ;; Original
;;   iter = param.n_corr_block_min+1
;;   test = 'ok'
;;   while test eq 'ok' and iter lt nw1-2 do begin &$
;;      if s_corr[iter] lt mean_block-param.nsigma_corr_block*sd_block $
;;      then test = 'pas_ok' $
;;      else block = where(corr gt s_corr[param.n_corr_block_min+iter] and corr ne 1, nblock) &$
;;      iter += 1 &$
;;   endwhile

   ;;***************************************
   ;; Debugged ?
   iter = 2
   test = 'ok'
   while test eq 'ok' and (param.n_corr_block_min+iter) lt nw1-2 do begin
      if s_corr[param.n_corr_block_min+iter] lt mean_block-param.nsigma_corr_block*sd_block $
      then test = 'pas_ok' $
      else block = where(corr gt s_corr[param.n_corr_block_min+iter] and corr ne 1, nblock)
      iter += 1
   endwhile
   ;;***************************************

   ;; to check
   if i eq 10 then out_block = block



;   print, "block numdet:", kidpar[block].numdet
;   stop
     
   ;;------- Build the appropriate noise template
   hit_b = lonarr(nsn)          ;Number of hit in the block common mode timeline 
   cm_b = dblarr(nsn)           ;Block common mode ignoring the source
   for j=0, nblock-1 do begin &$
      cm_b += (atm_x_calib[block[j],0] + atm_x_calib[block[j],1]*toi[block[j],*]) * off_source[block[j],*] &$
      hit_b += off_source[block[j],*] &$
   endfor
   
   ;;if kidpar[ikid].array eq 2 and kidpar[ikid].numdet eq 436 then begin
;;   if kidpar[ikid].array eq 2 then begin
;;      print, "ikid: ", ikid
;;      print, "cm_b[0:10]: ", cm_b[0:10]
;;      stop
;;   endif
   
   loc_hit_b = where(hit_b ge 1, nloc_hit_b, COMPLEMENT=loc_no_hit_b, ncompl=nloc_no_hit_b)
   if nloc_hit_b ne 0 then cm_b[loc_hit_b] = cm_b[loc_hit_b]/hit_b[loc_hit_b]
   if nloc_no_hit_b ne 0 then cm_b[loc_no_hit_b] = !values.f_nan

     ;;------- If holes, interpolates
   if nloc_no_hit_b ne 0 then begin
      if nloc_hit_b eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
                                       'It is so large that not even a single KID used in the ' + $
                                       'common-mode can be assumed be off-source'
      warning = 'yes'
      indice = dindgen(nsn)
      cm_b = interpol(cm_b[loc_hit_b], indice[loc_hit_b], indice, /quadratic)
   endif
   
     ;;---------- Case of elevation
;     if keyword_set(elev) and keyword_set(ofs_el) and param.fit_elevation eq 'yes' then begin
   if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
   if strupcase(info.obs_type) ne strupcase('lissajous') then no_el = 1 ;Useless for OTF and avoid problems
   templates = transpose([[cm_b[wfit]], [elev[wfit]]])
        
   y = reform(toi[ikid,wfit])
   coeff = regress(templates, y, CONST=const, YFIT=yfit)

   coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit] + coeff[1]*elev[wfit])

   TOI_out[ ikid,*] = toi[ikid,*] - coeff[0]*cm_b - coeff[1]*elev  + coeff_0[0]
   out_temp[ikid,*] = coeff[0]*cm_b + coeff[1]*elev - coeff_0[0]
endfor

toi = TOI_out
  
end
