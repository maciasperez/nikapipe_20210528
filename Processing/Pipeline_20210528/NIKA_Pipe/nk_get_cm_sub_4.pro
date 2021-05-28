;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_cm_sub_4
;
; CATEGORY: toi processing
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;  Same as nk_get_cm_sub_2 but I only consider kids that are further
;  from the current kid than some minimum distance to avoid ringing.
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
;        - July 8th, 2019: NP
;-

pro nk_get_cm_sub_4, param, info, toi, flag, off_source, kidpar, final_common_mode, $
                     w8_source=w8_source

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

;;toi_in = toi ; backup; not used 

nsn         = n_elements( toi[0,*])
nkids       = n_elements( toi[*,0])

wjunk = where( (finite(kidpar.noise) eq 0 or kidpar.noise eq 0) and kidpar.type eq 1, nw)
if nw ne 0 then begin
   nk_error, info, "There are NaN's in kidpar.noise", silent=param.silent
   return
endif

;; Possibility to have a smoother weighting than just 0/1 on/off source
if keyword_set(w8_source) then begin
   include_measure_errors = 1
endif else begin
   include_measure_errors = 0
   w8_source = off_source
endelse

;; Compute KID to KID distance
nk_kid2kid_dist, kidpar, kid_dist_matrix

;; Account for kid noise
kid_w8 = (kid_dist_matrix gt param.cm_kid_min_dist)##diag_matrix(1.d0/kidpar.noise)^2

;; Account for source and mask weights in time domain
sample_w8 = w8_source * ( finite(w8_source) and (flag eq 0 or flag eq 2L^11))

;; Use median common mode for a 1st cross-calibration
nk_get_median_common_mode, param, info, toi, flag, off_source, kidpar, median_common_mode

;; cross-cal on the median common mode
for ikid=0, nkids-1 do begin
   wsample = where( w8_source[ikid,*] ne 0 and finite(w8_source[ikid,*]) and $
                    (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nwsample)
   r = poly_fit( median_common_mode[wsample], toi[ikid,wsample], 1, $
                 measure_errors=measure_errors, status=status)
   toi[ikid,*] = -r[0]/r[1] + 1.d0/r[1]*toi[ikid,*]
endfor

;; Compute average common mode for all KIDs at the same time
avg_cm   = matrix_multiply( toi*sample_w8, kid_w8, /atranspose)
avg_norm = matrix_multiply(     sample_w8, kid_w8, /atranspose)
w = where( avg_norm ne 0, nw, compl=wzero, ncompl=nwzero)
if nw eq 0 then begin
   message, /info, "All common mode weights are zero"
   stop
endif
avg_cm[w] /= avg_norm[w]
if nwzero ne 0 then avg_cm[wzero] = !values.d_nan

;; Deal with holes
for ikid=0, nkids-1 do begin
   w = where( finite(avg_cm[*,ikid]) eq 0, nw, compl=wkeep)
   if nw ne 0 then begin
      info.common_mode_interpolated_samples = info.common_mode_interpolated_samples > nw
      if param.interpol_common_mode ge 1 then begin
         avg_cm[*,ikid] = interpol( avg_cm[wkeep,ikid], wkeep, lindgen(nsn))
      endif else begin
         nk_error, info, "There are "+strtrim(nw,2)+" holes in "+strtrim(ikid,2)+"'s common mode"
         return
      endelse
      w = where( finite(avg_cm[*,ikid]) eq 0, nw, compl=wkeep)
   endif
endfor

;; Regress
final_common_mode = avg_cm*0.d0
for ikid=0, nkids-1 do begin
   ata = dblarr(2,2)
   atd = dblarr(2)
   
   sample_mask = double( sample_w8[ikid,*] ne 0)
   
   ata[0,0] = total(                   sample_mask/kidpar[ikid].noise^2)
   ata[1,0] = total( avg_cm[*,ikid]   *sample_mask/kidpar[ikid].noise^2)
   ata[0,1] = ata[1,0]
   ata[1,1] = total( avg_cm[*,ikid]^2 *sample_mask/kidpar[ikid].noise^2)
   
   atd[0] = total( sample_mask               *toi[ikid,*]/kidpar[ikid].noise^2)
   atd[1] = total( sample_mask*avg_cm[*,ikid]*toi[ikid,*]/kidpar[ikid].noise^2)
   
   coeffs = invert(ata)##atd
   final_common_mode[*,ikid] = coeffs[0] + coeffs[1]*avg_cm[*,ikid]
endfor


end
