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
;        - Jan. 3rd, 2015: (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_get_corr_block_2, param, info, data, kidpar, kid_corr_block

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_corr_block_2, param, info, data, kidpar, kid_corr_block, box_corr_block"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

mcorr = correlate( data.toi)
wnan  = where(finite(mcorr) ne 1, nwnan)
if nwnan ne 0 then mcorr[wnan] = -1

;; init blocks of correlated kids to -1
nkids = n_elements(kidpar)
kid_corr_block   = intarr(nkids,nkids) - 1

;; LP begin
;;for iarray=1, 3 do begin
   
;;w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;; LP end

w1 = where( kidpar.type eq 1, nw1)
   if nw1 ne 0 then begin
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
         if param.dist_max_between_kids gt 0.d0 then begin
            d = sqrt( (kidpar[ikid].nas_x-kidpar.nas_x)^2 + (kidpar[ikid].nas_y-kidpar.nas_y)^2)
            w = where( d lt param.dist_max_between_kids, nw)
            if nw ne 0 then corr[w] = -1
         endif

         ;; Sort by order of maximum correlation
         s_corr = corr[reverse(sort(corr))]
         
         ;; First block with the requested min number of KIDs
         block = where(corr gt s_corr[param.n_corr_block_min+1] and corr ne 1, nblock)
         
         ;; Then add KIDs and if they are correlated enough
         sd_block   = stddev(corr[block])
         mean_block = mean(corr[block])
         iter = 1               ; 2                                                                                                          
         test = 'ok'
         while test eq 'ok' and (param.n_corr_block_min+iter) lt nw1-2 do begin
            if s_corr[param.n_corr_block_min+iter] lt mean_block-param.nsigma_corr_block*sd_block $
            then test = 'pas_ok' $
            else block = where(corr gt s_corr[param.n_corr_block_min+iter] and corr ne 1, nblock)
            iter += 1
         endwhile
         
         kid_corr_block[ikid,0:nblock-1] = block
      endfor
   endif

   ;; LP begin
   ;;endfor
   ;; LP end
   
end
