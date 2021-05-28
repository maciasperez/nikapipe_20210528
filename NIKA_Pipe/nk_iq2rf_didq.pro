;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_iq2rf_didq
;
; CATEGORY:
;
; CALLING SEQUENCE:
;         nk_iq2rf_didq, param, data, kidpar
; 
; PURPOSE: 
;        Computes data.toi with the "RF_dIdQ" method
; 
; INPUT: 
;        - param, data, kidpar
; 
; OUTPUT: 
;        - data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;-

pro nk_iq2rf_didq, param, data, kidpar

N_pt  = n_elements(data)
n_kid = n_elements(kidpar)

delta_I = data.I - shift( data.I, 0, 1)
delta_Q = data.Q - shift( data.Q, 0, 1)

;;; remove unnecessary loop and back-and-forth shifts (HR, 24/11/2016):
data_moy_di = smooth(data.dI, [1, 101], /edge_truncate)
data_moy_dq = smooth(data.dQ, [1, 101], /edge_truncate)
nsn = n_elements(data)
incr = rebin(kidpar.df, n_kid, nsn) $
   * (delta_I * data_moy_di + delta_Q * data_moy_dq) $
   / (data_moy_di^2.D0 + data_moy_dq^2.D0)
data.toi = total(incr, 2, /cumul, /nan)

;;;delta_I = shift( delta_I, 0, 49)
;;;delta_Q = shift( delta_Q, 0, 49)

;;;kernel = dblarr(100) + 1.d0/100.d0
;;;nsn = n_elements(data)
;;;for ikid=0, n_kid-1 do begin
;;;   moy_di = convol( data.dI[ikid], kernel, center=0)
;;;   moy_dq = convol( data.dQ[ikid], kernel, center=0)
;;;   norm   = moy_di^2 + moy_dq^2
;;;   incr   = kidpar[ikid].df * ( delta_I[ikid,*]*moy_dI + delta_Q[ikid,*]*moy_dQ)/norm

;;;   w = where( finite(incr) eq 0)
;;;   incr[w] = 0.d0

   ;; Add "-" to have positive flux
   ;; data.toi[ikid] = -(shift( total( incr, /cumul), -49))[*]

   ;; Change back the sign here, it will be done later on in
   ;; nk_data_conventions, NP. Sept 20th, 2016
;;;   data.toi[ikid] = (shift( total( incr, /cumul), -49))[*]
;;;endfor

;; flag first and last 50 samples that are not well computed
;;;nsn = n_elements(data)
;;;nk_add_flag, data, 7, wsample=indgen(50)
;;;nk_add_flag, data, 7, wsample=(indgen(50)+nsn-50)

end
