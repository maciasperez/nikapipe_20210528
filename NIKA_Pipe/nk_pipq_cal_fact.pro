;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_pipq_cal_fact
;
; CATEGORY:
;    calibration
;
; CALLING SEQUENCE:
;         nk_pipq_cal_fact, param, info, data, kidpar
; 
; PURPOSE: 
;    computes the calibration coefficient from the external calibrator
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
;        - data: the NIKA general data structure
;        - kidpar: the NIKA general kid structure
; 
; OUTPUT: 
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Sept. 23rd, 2018, NP
;-
;===========================================================================================================

pro nk_pipq_cal_fact, param, info, data, kidpar, pipq

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_pipq_cal_fact, param, data, kidpar, pipq"
   return
endif

n_kid = n_elements(kidpar)
nsn   = n_elements(data)

delta_I = data.I - shift( data.I, 0, 1)
delta_Q = data.Q - shift( data.Q, 0, 1)

data_moy_di = smooth(data.dI, [1, 101], /edge_truncate)
data_moy_dq = smooth(data.dQ, [1, 101], /edge_truncate)

pipq = rebin(1.d0/kidpar.df, n_kid, nsn) $
       * (data.pI * data_moy_di + data.pQ * data_moy_dq) $
       / (data_moy_di^2.D0 + data_moy_dq^2.D0)

nsmooth_pipq = long( param.nsec_smooth_pipq*!nika.f_sampling)
pipq = smooth( pipq, [1, nsmooth_pipq], /edge_truncate)

;; w1 = where( kidpar.type eq 1)
;; ikid = w1[0]
;; wind, 1, 1, /free, /large
;; my_multiplot, 2, 2, pp, pp1, /rev
;; plot, data.toi[ikid,*], /xs, /ys, title='RF_dIdQ', position=pp1[0,*]
;; plot, pipq[ikid,*], /xs, /ys, title='RF_pIpQ', position=pp1[1,*], /noerase
;; oplot, pipq[ikid,*], col=250


end
