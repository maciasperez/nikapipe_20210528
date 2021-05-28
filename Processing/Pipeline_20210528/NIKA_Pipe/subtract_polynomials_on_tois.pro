
if param.log then nk_log, info, "subtracting polynomials from TOIs"

delvarx, w8_in
if defined(snr_toi) then w8_in = 1.d0/(1.d0+param.k_snr_w8_decor*snr_toi^2)

;toi1 = data.toi
nk_polynomial_subtraction, param, info, data, kidpar, w8_in=w8_in

if param.mydebug eq 0 then delvarx, toi1

;; if param.debug eq 1 then begin &$
;;    ;; polynomials are actually subtracted from data.toi in the
;;    ;; routine, so to isolate them, we need another buffer: &$
;;    toi_temp = data.toi
;;    
;;    w1 = where( kidpar.type eq 1) &$
;;       make_ct, 5, ct &$
;;       wind, 1, 1, /free, /xlarge &$
;;       plot, toi_temp[w1[0],*], /xs, xra=[0,2000], yra=[-0.1, 0.1] &$
;;       loadct, 7 & oplot, data.subscan/max(data.subscan)*0.2-0.1, col=200 & loadct, 39 &$
;;       for ii=1, 5 do begin &$
;;       data.toi = toi_temp &$
;;       param.polynomial = ii &$
;;       nk_polynomial_subtraction, param, info, data, kidpar &$
;;       poly = toi_temp - data.toi &$
;;       oplot, poly[w1[0],*], col=ct[ii-1] &$
;;       endfor &$
;;       legendastro, "deg "+strtrim(indgen(5)+1,2), col=ct &$
;;       stop &$
;;       endif else begin &$
;;       nk_polynomial_subtraction, param, info, data, kidpar &$
;;       ;;poly = toi_temp - data.toi &$
;;    endelse &$
;; 
;; ;;   ;; Now subtract the polynomials from the data
;; ;;   data.toi = toi_copy - poly &$
;; endelse

