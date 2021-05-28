;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_discard_noisy_kids
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_discard_noisy_kids, param, info, data, kidpar
; 
; PURPOSE: 
;        Discards the kids whose stddev is larger than 3 x the median
;stddev from all the other kids.
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - kidpar.type is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - April 16th, 2018: NP, extracted from nk_clean_data_3.pro

pro nk_discard_noisy_kids, param, info, data, kidpar
;-

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

;; for iarray=1, 3 do begin
;;    w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;    if nw1 ne 0 then begin
;;       noise_avg = avg( kidpar[w1].noise)
;;       sigma = stddev(  kidpar[w1].noise)
;;       ;; BUG IN THE DEFINITION OF WOUT HERE. Solve NP, Apr 25th, 2016
;;       w = where( kidpar.type eq 1 and kidpar.array eq iarray and $
;;                  kidpar.noise le (noise_avg + 3*sigma), nw) ; , compl=wout, ncompl=nwout)
;;       if nw eq 0 then begin
;;          nk_error, info, "No kid in array "+strtrim(iarray,2)+" has a noise closer to the average than 3 sigma."
;;          return
;;       endif
;;       ;; CORRECT DEFINITION OF WOUT (Apr. 25th, 2016)
;;       wout = where( finite(kidpar.noise) eq 1 and kidpar.array eq iarray and $
;;                     kidpar.noise gt (noise_avg + 3*sigma), nwout)
;;       if nwout ne 0 then begin
;;          kidpar[wout].type = 3
;;          if param.silent eq 0 then print, "noisy kids: ", nwout
;;       endif
;;    endif
;; endfor


for iarray=1, 3 do begin
   nn = 0
   w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;      wind, 1, 1, /ylarge
;;      !p.multi=[0,1,2]
;;      make_ct, nw1, ct
;;      plot, data.toi[w1[0]], /xs, /ys, yra=minmax(data.toi[w1]), title='Array '+strtrim(iarray,2)
;;      for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
   if nw1 ne 0 then begin
      sigma = fltarr(nw1)
      for i=0, nw1-1 do begin
         ikid = w1[i]
         woff = where( data.off_source[ikid] eq 1)
         sigma[i] = stddev( data[woff].toi[ikid])
      endfor
      noise_avg = avg( sigma)
      s_sigma = stddev( sigma)
      w = where( sigma ge (noise_avg+3*s_sigma), nw)
      if nw ne 0 then begin
         kidpar[w1[w]].type = 3
         if param.silent eq 0 then message, /info, "found "+strtrim(nw,2)+$
                                            " kids with too high noise in A"+strtrim(iarray,2)+" => not used nor projected"
      endif
   endif
;;       w1 = where( kidpar.array eq iarray and kidpar.type eq 1, nw1)
;;       make_ct, nw1, ct
;;       plot, data.toi[w1[0]], /xs, /ys, yra=minmax(data.toi[w1])
;;       for i=0, nw1-1 do oplot, data.toi[w1[i]], col=ct[i]
;;       !p.multi=0
;;       stop
endfor

if param.cpu_time then nk_show_cpu_time, param

end
