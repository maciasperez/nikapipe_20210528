;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
;  nk_get_cm_common_block
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; PURPOSE: 
;        Computes a common mode from the kids that are most correlated to the
;current kid.
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
;        - Nov. 21st, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_get_cm_common_block, param, info, toi, flag, off_source, kidpar, common_mode

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_cm_common_block, param, info, toi, flag, off_source, kidpar, common_mode"
   return
endif

;;--------------------------------------
;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif
nkids = n_elements( toi[*,0])
if nkids ne n_elements(kidpar) then begin
   nk_error, info, "incompatible kidpar ("+strtrim(n_elements(kidpar),2)+" kids) and toi ("+strtrim(nkids,2)+" kids)."
   return
endif
w = where( kidpar.type ne 1, nw)
if nw ne 0 then begin
   nk_error, info, "Found "+strtrim(nw,2)+" unvalid kids, whereas they should all be valid to derive the C. M."
   return
endif
;;--------------------------------------

nsn         = n_elements( toi[0,*])
common_mode = dblarr(nsn)
w8          = dblarr(nsn)

;; Correlation matrix for all valid kids far from the source and unflagged
;; samples
message, /info, "Computing kids cross-correlation..."
mcorr = dblarr(nw1,nw1)
for i=0, nw1-2 do begin
   ikid = w1[i]
   for j=i+1, nw1-1 do begin
      jkid = w1[j]
      w = where( off_source[ikid] eq 1 and $
                 off_source[jkid] eq 1 and $
                 flag[      ikid] eq 0 and $
                 flag[      jkid] eq 0, nw)
      if nw lt 10 then begin
         nk_error, info, "Less than 10 good samples to correlate kids "+strtrim(ikid,2)+" and "+strtrim(jkid,2)  
      endif else begin
         mcorr[i,j] = correlate( data[w].toi[ikid], data[w].toi[jkid])
         mcorr[j,i] = mcorr[i,j] ; for convenience
      endelse
   endfor
endfor
message, /info, "done"

;wind, 1, 1, /free
;imview, mcorr, title='Valid kid correlation matrix'

;; For each kid, find the n kids that are most correlated to it
data_copy = data
for i=0, nw1-1 do begin
   ikid = w1[i]
   order = reverse( sort( mcorr[i,*]))

   ;; The current kid is self excluded since its autorcorr was not calculated
   ;; and is 0 in mcorr
   w = where( mcorr[i,*] ge mcorr[ i, order[ param.n_corr_bloc_min]], nw, compl=wcompl, ncompl=nwcompl)

   ;; Compute the median common mode for this bloc
   nk_get_cm_sub_2, param, info, data_copy.toi[w1[w]], data.flag[w1[w]], data.off_source[w1[w]], kidpar[w1[w]], common_mode

;;   ;; Add extra kids if they correlate as well as the previous ones
;;   if nwcompl ne 0 then begin

   ;; Determine valid samples for the regress
   wsample = where( data.off_source[ikid] eq 1 and data.flag[ikid] eq 0, nwsample)
   if nwsample lt param.nsample_min_per_subscan then begin
      ;; do not project this subscan for this kid
      data.flag[ikid] = 2L^7
   endif else begin

      ;; Regress the templates and the data off source
      coeff = regress( common_mode[wsample], reform( data[wsample].toi[ikid]), $
                       CHISQ= chi, CONST= const, /DOUBLE, STATUS=status)

      ;; Subtract the templates everywhere
      ;yfit = dblarr(nsn) + const
      ;for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
      yfit = const + coeff[0]*common_mode
      data.toi[ikid] -= yfit
      
      ;; !p.multi=[0,1,2]
      ;; plot, data_copy.toi[ikid], title=strtrim(ikid,2)
      ;; oplot, yfit, col=250
      ;; plot, data.toi[ikid]
      ;; !p.multi=0
      ;; wait, 0.2

   endelse
endfor


end
