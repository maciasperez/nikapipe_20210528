;; pro nika_pipe_iq2rfdidq, df, I, Q, dI, dQ, RFdIdQ, shift_nb=shift_nb
;;   
;;   N_pt = n_elements(I[0,*])
;;   n_kid = n_elements(I[*,0])
;;     
;;   RFdIdQ = dblarr(n_kid, N_pt)
;; 
;;   for ikid=0, n_kid-1 do begin
;; 
;;      moy_dI = smooth(dI[ikid,*],101)
;;      moy_dQ = smooth(dQ[ikid,*],101)
;;    
;;      for m=0ll, N_pt-1 do begin
;;         if (m eq 0) then delta_I = 0d else delta_I = I[ikid,m] - I[ikid,m-1]
;;         if (m eq 0) then delta_Q = 0d else  delta_Q = Q[ikid,m] - Q[ikid,m-1]
;; 
;;         if (m eq 0) then RFdIdQ[ikid,m] = 0d $
;;         else RFdIdQ[ikid,m] = $
;;            RFdIdQ[ikid,m-1] + df * (delta_I*moy_dI[m-1] + delta_Q*moy_dQ[m-1])/(moy_dI[m-1]^2.0 + moy_dQ[m-1]^2.0)
;;      endfor
;;      
;;      if keyword_set(shift_nb) then  RFdIdQ[ikid,*] = shift(RFdIdQ[ikid,*], shift_nb)
;;   endfor
;; 
;;   return
;; end

;;************************************************************************************
;;************************************************************************************
;; NP Oct 10th, 2013
;; - Legeres modifs pour faire exactement comme Alain
;; - Plus besoin de shifter par 49 points puisque read_nika_brute a ete modifiee

pro nika_pipe_iq2rfdidq, param, data, kidpar;, I, Q, dI, dQ, RFdIdQ

N_pt  = n_elements(data)
n_kid = n_elements(kidpar)

delta_I = data.I - shift( data.I, 0, 1)
delta_Q = data.Q - shift( data.Q, 0, 1)

delta_I = shift( delta_I, 0, 49)
delta_Q = shift( delta_Q, 0, 49)

kernel = dblarr(100) + 1.d0/100.d0

for ikid=0, n_kid-1 do begin
   moy_di = convol( data.dI[ikid], kernel, center=0)
   moy_dq = convol( data.dQ[ikid], kernel, center=0)
   norm   = moy_di^2 + moy_dq^2
   incr   = kidpar[ikid].df * ( delta_I[ikid,*]*moy_dI + delta_Q[ikid,*]*moy_dQ)/norm

   w = where( finite(incr) eq 0)
   incr[w] = 0.d0

   ;; Add "-" to have positive flux
   data.rf_didq[ikid] = -(shift( total( incr, /cumul), -49))[*]
   ;; data.rf_didq[ikid] = -(total( incr, /cumul))[*]

   ;; First 48 samples are not usable
   data[0:49-1].flag[ikid] = 1
endfor

end

;; Slower but more readable version :)
;; pro my_iq2rf_didq, df, I, Q, dI, dQ, RFdIdQ
;; 
;;   N_pt  = n_elements(I[0,*])
;;   n_kid = n_elements(I[*,0])
;; 
;;   RFdIdQ = dblarr(n_kid, N_pt)
;; 
;;   delta_I = I - shift( I, 0, 1)
;;   delta_Q = Q - shift( Q, 0, 1)
;; 
;;   delta_I[*,0] = 0.d0
;;   delta_Q[*,0] = 0.d0
;; 
;;   kernel = dblarr(100) + 1.d0/100.d0
;; 
;; ;  junk = dblarr(n_pt)
;; 
;;   for ikid=0, n_kid-1 do begin
;;      percent_status, ikid, n_kid, 10, /bar
;; 
;;      moy_di = convol( reform( dI[ikid,*]), kernel, center=0)
;;      moy_dq = convol( reform( dQ[ikid,*]), kernel, center=0)
;; 
;;      ;; Start computing when 100 points have been accumulated
;;      for m=99LL, N_pt-1 do begin
;;         norm = moy_di[m]^2 + moy_dq[m]^2
;;  ;       junk[m] = norm
;;         rfdidq[ikid,m-49] = rfdidq[ikid,m-50] + df*( delta_i[ikid,m-49]*moy_dI[m] + delta_q[ikid,m-49]*moy_dQ[m])/norm
;;      endfor
;; 
;; 
;;   endfor
;; 
;; 
;; 
;;   return
;; end
