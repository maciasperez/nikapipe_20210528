

pro montier2d_test_p, p0, psi0_deg, sigma_p, pol_deg, alpha_deg, $
                      position=position, plot=plot, xra=xra, yra=yra

nsn = 100 ; 200
psi0 = psi0_deg*!dtor

;; Prior integration intervals
p_range   = [0.d0, 1.d0]

;; To be symetric around the starting value
psi_range = [-1,1]*90.d0 + psi0_deg

p   = dindgen(nsn)/(nsn-1)*(max(  p_range)-min(  p_range)) + min(  p_range)
psi = dindgen(nsn)/(nsn-1)*(max(psi_range)-min(psi_range)) + min(psi_range)
psi *= !dtor

p   = rebin( p#(dblarr(nsn)+1), nsn, nsn)
psi = rebin( (dblarr(nsn)+1)#psi, nsn, nsn)
y = exp(-0.5d0*( (p*cos(2.d0*psi)-p0*cos(2.d0*psi0))^2/sigma_p^2 + $
                 (p*sin(2.d0*psi)-p0*sin(2.d0*psi0))^2/sigma_p^2))

;; because we normalize, no need to multiply the totals by dp*dpsi*di1
;; to get the integrals
norm      = total(y)
pol_deg   = total( y*p)/norm
alpha_deg = total( y*psi)/norm * !radeg

if keyword_set(plot) then begin
   imview, y, xmap=p, ymap=psi*!radeg, $
           xtitle='p', ytitle='Angle (deg)', title='y (I)', $
           position=position, /noerase, xra=xra, yra=yra
endif

end
