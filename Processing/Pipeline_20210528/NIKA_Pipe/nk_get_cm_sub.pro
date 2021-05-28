;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_get_cm_sub
;
; CATEGORY: toi processing, subroutine of nk_get_cm
;
; CALLING SEQUENCE:
;
; 
; PURPOSE: 
;        Derives a common mode from all the input kids
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
;        - June 19th, 2014: (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_get_cm_sub, param, info, toi, flag, off_source, kidpar, common_mode

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_cm_sub, param, info, toi, flag, off_source, kidpar, common_mode"
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

;toi_xcal = toi*0.d0
for ikid=0, nkids-1 do begin

   ;; Determine samples for which both ikid and ikid0 are off_source
   wsample  = where( off_source[ikid0,*] ne 0 and $
                     off_source[ikid,*]  ne 0, nwsample)
   if nwsample eq 0 then begin
      ;nk_error, info, "no sample for which both kids "+strtrim(ikid0,2)+" and "+strtrim(ikid,2)+" are off source and have flag=0"
      ;return
      ;; do not project this scan
      flag[ikid,*] = 1
   endif else begin
   
      ;; Account for kid noise in the common_mode estimation
      ;; Cross calibrate ikid on ikid0 for these off source samples
      fitexy, toi[ikid,wsample], toi[ikid0,wsample], a, b, x_sig=kidpar[ikid].noise, y_sig=kidpar[ikid0].noise
      if finite(a) ne 1 or finite(b) ne 1 then begin
         nk_error, info, "infinite fit values for kid "+strtrim(ikid,2)
         return
      endif else begin
         ;; add to common mode only if off source
         common_mode += (a + b*toi[ikid,*])*double(off_source[ikid,*] eq 1)/kidpar[ikid].noise^2
         w8          += long( off_source[ikid,*] eq 1)/kidpar[ikid].noise^2
      endelse

;      toi_xcal[ikid,*] = a + b*toi[ikid,*]

   endelse

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

;;common_mode_1 = median( toi_xcal, dim=1)
;; make_ct, nkids, ct
;; wind, 1, 1, /free, /large
;; !p.multi=[0,1,3]
;; plot, toi[0,*], yra=minmax(toi), /ys
;; for i=0, nkids-1 do oplot, toi[i,*], col=ct[i]
;; oplot, common_mode, thick=2
;; 
;; plot, toi_xcal[0,*], yra=minmax(toi), /ys
;; for i=0, nkids-1 do oplot, toi_xcal[i,*], col=ct[i]
;; oplot, common_mode, thick=2
;; oplot, common_mode_1, col=70, thick=2
;; 
;; plot, common_mode_1 - common_mode
;; !p.multi=0
;; 
;; for i=0, nkids-1 do begin
;;    fit = linfit( toi[i,*], common_mode)
;;    sigma = stddev( (fit[0] + fit[1]*toi[i,*]) - common_mode)
;;    fit = linfit( toi[i,*], common_mode_1)
;;    sigma1 = stddev( (fit[0] + fit[1]*toi[i,*]) - common_mode_1)
;;    print, "i, sigma, sigma_1: ", i, sigma, sigma1
;; endfor
;;common_mode = common_mode_1   

end
