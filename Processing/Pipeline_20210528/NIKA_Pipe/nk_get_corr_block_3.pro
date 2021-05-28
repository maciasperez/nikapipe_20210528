;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_corr_block_2
;
; CATEGORY: toi processing, subroutine of nk_decor
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Determines blocks of kids that are maximally correlated to the current kid
; 
; INPUT: 
; 
; OUTPUT: 
;        kid_corr_block: a (nkid,nkid) array with the kid index or the
;correlated kids (otherwise -1).
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 16th, 2018: NP: adapt nk_get_corr_block_2 to nk_decor_sub_6.
;-

pro nk_get_corr_block_3, param, info, toi, flag, off_source, kidpar, kid_corr_block

if n_params() lt 1 then begin
   dl_unix, "nk_get_corr_block_3"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)

;------------
;t0 = systime(0, /sec)
mcorr = correlate( toi)
;;t1 = systime(0,/sec)
;;
;;mcorr = dblarr(nkids, nkids) -1
;;for i=0, nkids-2 do begin
;;   if kidpar[i].type eq 1 then begin
;;      for j=i+1, nkids-1 do begin
;;         if kidpar[j].type eq 1 then begin
;;            w = where( flag[i,*] eq 0 and flag[j,*] eq 0 and $
;;                       off_source[i,*] eq 1 and off_source[j,*] eq 1, nw)
;;            if nw lt 2 then begin
;;               message, /info, "No valid sample off source to compute correlation between"
;;               message, /info, "kids "+strtrim(i,2)+" and "+strtrim(j,2)+"."
;;            endif else begin
;;               mcorr[i,j] = correlate( toi[i,w], toi[j,w])
;;            endelse
;;         endif
;;      endfor
;;   endif
;;endfor
;;t2 = systime(0,/sec)
;;
;;message, /info, "Global call: t1-t0: "+strtrim(t1-t0,2)
;;message, /info, "Loop and account for flags: "+strtrim(t2-t1,2)
;;stop
;------------

;; Discard NaN if any
wnan  = where(finite(mcorr) ne 1, nwnan)
if nwnan ne 0 then mcorr[wnan] = -1

;; init blocks of correlated kids to -1
kid_corr_block  = intarr(nkids,nkids) - 1

;; Loop on KIDS
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif else begin

   for i=0, nw1-1 do begin
      ikid = w1[i]
      
      ;; Search for best set of KIDs to be used for deccorelation
      corr = reform(mcorr[ikid,*])
      
      ;; Do not use discarded kids nor kids from the other matrix
      wbad = where(kidpar.type ne 1 or kidpar.array ne kidpar[ikid].array, nwbad)
      if nwbad ne 0 then corr[wbad] = -1
         
      ;; If requested, do not use kids that are too close from the
      ;; current kid.
      if param.dist_min_between_kids gt 0.d0 then begin
         d = sqrt( (kidpar[ikid].nas_x-kidpar.nas_x)^2 + (kidpar[ikid].nas_y-kidpar.nas_y)^2)
         w = where( d gt param.dist_min_between_kids, nw)
         if nw ne 0 then corr[w] = -1
      endif

      ;; Sort by order of maximum correlation
      s_corr = corr[reverse(sort(corr))]
      
      ;; First block with the requested min number of KIDs
      ;; reject where(corr eq 1) to discard the current kid from its
      ;; own block
      block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)
         
      ;; Then add KIDs and if they are correlated enough
      sd_block   = stddev(corr[block])
      mean_block = mean(corr[block])
      iter = 1      ; 2                                                                                                          
      test = 'ok'
      while test eq 'ok' and (param.n_corr_block_min+iter) lt nw1-2 do begin
         if s_corr[param.n_corr_block_min+iter] lt mean_block-param.nsigma_corr_block*sd_block $
         then test = 'pas_ok' $
         else block = where(corr gt s_corr[param.n_corr_block_min+iter] and corr ne 1, nblock)
         iter += 1
      endwhile
      
      kid_corr_block[ikid,0:nblock-1] = block
   endfor
endelse


end
