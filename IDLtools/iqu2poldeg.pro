
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; iqu2poldeg
;
; CATEGORY:
; polarization
;
; CALLING SEQUENCE:
;         
; 
; PURPOSE: 
;        Computes the degree of polarization and associated error bars
;given I, Q, U and sigma_q using Vaillancourt's 2006 equations
;(see also Montier et al, 2014)
; 
; INPUT: 
;        - I, Q, U, sigma_q
; 
; OUTPUT: 
;        - p: maximum likelihood degree of polarization
;        - sigma_p_plus : distance from p to the upper bound of the 68% confidence
;          interval (equivalent of 1sigma error bar)
;        - sigma_p_minus: distance to the lower bound of the 68%
;          confidence interval
;        - two_sigma_p_plus, two_sigma_p_minus, three_sigma_p_plus,
;          three_sigma_p_minus: analogous of previous quantities for
;95% and 99% confidence intervals.
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Ritacco and NP, May 2016.
;-

pro iqu2poldeg, i_in, q_in, u_in, sigma_i, sigma_q, sigma_u, p_out, sigma_p_plus, sigma_p_minus, $
                two_sigma_p_plus, two_sigma_p_minus, three_sigma_p_plus, three_sigma_p_minus, $
                old_formula=old_formula, do_plot=do_plot

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "iqu2poldeg, i, q, u, sigma_i, sigma_q, p, sigma_p_plus, sigma_p_minus, $"
   print, "            two_sigma_p_plus, two_sigma_p_minus, three_sigma_p_plus, three_sigma_p_minus"
   return
endif
p = sqrt(Q_in^2+U_in^2) ; /I_in
sigma_p = max( [sigma_q, sigma_u]) ; to be safe

if keyword_set(old_formula) or (q_in^2+u_in^2 gt 5*(sigma_q^2+sigma_u^2))  then begin
;; Old version
   p_out = sqrt(q_in^2+u_in^2-sigma_q^2-sigma_u^2)/i_in
   sigma_pol_deg = sqrt(q_in^2*sigma_q^2 + u_in^2*sigma_u^2 +p_out^4*i_in^2*sigma_i^2)/(p_out*i_in^2)
   sigma_p_plus = sigma_pol_deg
   sigma_p_minus = sigma_pol_deg

endif else begin
;; New version
 n = 1000
 ;; Determine the maximum likelihood degree of polarization
;; epsilon = 1e-3
;; a = double(xra[0])
;; b = double(xra[1])
;; a=0
;; b=1
;; d = b-a
;; yb = p*beseli(p*b/sigma_p^2,1) - b*beseli(p*b/sigma_p^2,0)
;; while d ge epsilon do begin
;;    x = (a+b)/2.
;;    y = p*beseli(p*x/sigma_p^2,1) - x*beseli(p*x/sigma_p^2,0)
;;    if sign(y) eq sign(yb) then b = x else a = x
;;    d = b-a
;; endwhile
;; p_max_l = (a+b)/2.
;; Full Likelihood
;; nl = p*sqrt(!pi/2.)*exp(-p^2/(4.*sigma_p^2))*beselI(p^2/(4.*sigma_p^2), 0)

 p0 = dindgen(n)/(n-1)*(p+5*sigma_p/p)
 dp0 = p0[1]-p0[0]
;;  if p/sigma_p gt 5 then begin
;;     p_out = sqrt(q^2+u^2-sigma_q^2-sigma_u^2)/i
;;     sigma_pol_deg = sqrt(q^2*sigma_q^2 + u^2*sigma_u^2 +p_out^4*I^2*sigma_i^2)/(p_out*i^2)
;;     sigma_p_plus = sigma_pol_deg
;;     sigma_p_minus = sigma_pol_deg
;;     return
;;  endif
;; likelihood = 1.d0/nl*p/sigma_p^2*exp(-(p^2+p0^2)/(2.*sigma_p^2))*beselI(p*p0/sigma_p^2,0)
 likelihood = p/sigma_p^2*exp(-(p^2+p0^2)/(2.*sigma_p^2))*beselI((p*p0/sigma_p^2) < 30,0)
                                ; FXD June  2 2016, had to limit the
                                ; range within BeselI to avoid the
                                ; stop of the program

;; Normalize the likelihood
   likelihood /= (total( likelihood)*dp0)
   w = where( likelihood eq max(likelihood))
   p_max_l = (p0[w])[0]

;; Confidence intervals
   p_cumul = total( likelihood, /cumul)*dp0
; print, "p_cumul[n-1]: ", p_cumul[n-1], ", should be 1... ?!"

   confidence_interval = dblarr(3, 2)
   confidence_level = [0.68, 0.95, 0.99]
   i0 = (where( abs(p0-p_max_l) eq min( abs(p0-p_max_l))))[0]

   if keyword_set(do_plot) then begin
      wind, 1, 1, /free
      plot, p0, likelihood, $
            xtitle='P!d0!n', ytitle='Likelihood L(P!d0!n|P)'
      oplot, [1,1]*p_max_l, [0, max(likelihood)]
   endif

;; Integrate the likelihood around the maximum likelihood value to
;; determine boundaries of confidence intervals
   i1 = i0
   i2 = i0
   confidence_interval = dblarr(3, 2)
   one_sigma_done = 0
   two_sigma_done = 0
   three_sigma_done = 0
   i=0
   while (i1 ge 0) or (i2 le (n-1)) do begin
      frac = p_cumul[(i0+i)<(n-1)]-p_cumul[(i0-i)>0]

      i1 = i0-i
      i2 = i0+i
      
      if frac ge 0.68 and one_sigma_done eq 0 then begin
         confidence_interval[0,0] = p0[i1>0]
         confidence_interval[0,1] = p0[i2<(n-1)]
         one_sigma_done++
         if keyword_set(do_plot) then begin
            oplot, [1,1]*p0[i1>0], [0, likelihood[i1>0]], col=150
            oplot, [1,1]*p0[i2<(n-1)], [0, likelihood[i2<(n-1)]], col=150
         endif
      endif
      if frac ge 0.95 and two_sigma_done eq 0 then begin
         confidence_interval[1,0] = p0[i1>0]
         confidence_interval[1,1] = p0[i2<(n-1)]
         two_sigma_done++
;         oplot, [1,1]*p0[i1>0], [-1,1]*1e10, col=70
;         oplot, [1,1]*p0[i2<(n-1)], [-1,1]*1e10, col=70
      endif

      if frac ge 0.99 and three_sigma_done eq 0 then begin
         confidence_interval[2,0] = p0[i1>0]
         confidence_interval[2,1] = p0[i2<(n-1)]
         three_sigma_done++
;         oplot, [1,1]*p0[i1>0], [-1,1]*1e10, col=250
;         oplot, [1,1]*p0[i2<(n-1)], [-1,1]*1e10, col=250
      endif
      
      i++
   endwhile
      
;; print, p_max_l, p_max_l-confidence_interval[0,0], confidence_interval[0,1]-p_max_l
;; print, p_max_l, p_max_l-confidence_interval[1,0], confidence_interval[1,1]-p_max_l
;; print, p_max_l, p_max_l-confidence_interval[2,0], confidence_interval[2,1]-p_max_l

;;   p_out         = p_max_l
   p_out         = p_max_l/I_in
;;    print, "p_max_l: ", p_max_l
;;    print, "p_max_l/I: ", p_max_l/I_in
;;    stop
   sigma_p_plus  = confidence_interval[0,1]-p_max_l
   sigma_p_minus = p_max_l-confidence_interval[0,0]

   two_sigma_p_plus  = confidence_interval[1,1]-p_max_l
   two_sigma_p_minus = p_max_l-confidence_interval[1,0]

   three_sigma_p_plus  = confidence_interval[2,1]-p_max_l
   three_sigma_p_minus = p_max_l-confidence_interval[2,0]

   sigma_p_plus        /= I_in
   sigma_p_minus       /= I_in
   two_sigma_p_plus    /= I_in
   two_sigma_p_minus   /= I_in
   three_sigma_p_plus  /= I_in
   three_sigma_p_minus /= I_in

   if keyword_set(do_plot) then begin
      legendastro, ["Max. Likelihood P: "+num2string(p_max_l), $
                    "!7r!3+ = "+num2string(sigma_p_plus), $
                    "!7r!3- = "+num2string(sigma_p_minus), $
                    "!7r!3+ = "+num2string(sigma_p_plus)], $
                   /right, box=0
   endif


endelse


end
