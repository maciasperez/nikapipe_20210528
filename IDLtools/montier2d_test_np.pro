

pro montier2d_test_np, i0, q0, u0, I, Q, U, sigma_i, sigma_q, sigma_u, pol_deg, $
                    sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg,plot=plot


nsn = 100

p0 = sqrt(q0^2+u0^2)/i0
psi0_deg_in = 0.5*atan(u0,q0)*!radeg

;;---------------------------------------
psi0 = psi0_deg_in*!dtor

;; Prior integration intervals
p_range   = [0.d0, 1.d0]

;; To be symetric around the starting value
psi_range = [-1,1]*90.d0 + psi0_deg_in

p   = dindgen(nsn)/(nsn-1)*(max(  p_range)-min(  p_range)) + min(  p_range)
psi = dindgen(nsn)/(nsn-1)*(max(psi_range)-min(psi_range)) + min(psi_range)
psi *= !dtor

p   = rebin( p#(dblarr(nsn)+1), nsn, nsn)
psi = rebin( (dblarr(nsn)+1)#psi, nsn, nsn)
;; y = exp(-0.5d0*I^2*( (p*cos(2.d0*psi)-p0*cos(2.d0*psi0))^2/sigma_q^2 + $
;;                      (p*sin(2.d0*psi)-p0*sin(2.d0*psi0))^2/sigma_u^2))
y = exp(-0.5d0*I^2*( (p*cos(2.d0*psi)-p0*cos(2.d0*psi0))^2/sigma_q^2 + $
                     (p*sin(2.d0*psi)-p0*sin(2.d0*psi0))^2/sigma_u^2))

if keyword_set(plot) then begin
;   wind, 1, 1, /free
   imview, y, xmap=p, ymap=psi*!radeg, $
           xtitle='p', ytitle='Angle (deg)', title='y (I)', $
           position=position, /noerase
endif


;; because we normalize, no need to multiply the totals by dp*dpsi*di1
;; to get the integrals
norm      = total(y)
pol_deg   = total( y*p)/norm
alpha_deg = total( y*psi)/norm * !radeg

end
