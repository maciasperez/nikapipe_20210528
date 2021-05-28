;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_iq2rfpipq
;
; CATEGORY: 1D processing
;
; CALLING SEQUENCE:
;         nk_iq2rfpipq, param, data, kidpar
; 
; PURPOSE: 
;        computes the equivalent of rf_didq but with pI and pQ
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
;        - data
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Oct, 5th, 2014: NP
;-
;===========================================================================================================

pro nk_iq2rfpIpQ, param, data, kidpar

N_pt  = n_elements(data)
n_kid = n_elements(kidpar)

delta_I = data.I - shift( data.I, 0, 1)
delta_Q = data.Q - shift( data.Q, 0, 1)

delta_I = shift( delta_I, 0, 49)
delta_Q = shift( delta_Q, 0, 49)

kernel = dblarr(100) + 1.d0/100.d0

for ikid=0, n_kid-1 do begin
   moy_pI = convol( data.pI[ikid], kernel, center=0)
   moy_pQ = convol( data.pQ[ikid], kernel, center=0)
   norm   = moy_pI^2 + moy_pQ^2
;;   incr   = kidpar[ikid].df * ( delta_I[ikid,*]*moy_pI + delta_Q[ikid,*]*moy_pQ)/norm
   incr   = ( delta_I[ikid,*]*moy_pI + delta_Q[ikid,*]*moy_pQ)/norm
   
   w = where( finite(incr) eq 0)
   incr[w] = 0.d0

   ;; Add "-" to have positive flux
   data.rf_pIpQ[ikid] = -(shift( total( incr, /cumul), -49))[*]

   ;; First 48 samples are not usable
   ;data[0:49-1].flag[ikid] = 1
   nk_add_flag, data, 7, wsample=indgen(49), wkid=ikid
endfor

end
