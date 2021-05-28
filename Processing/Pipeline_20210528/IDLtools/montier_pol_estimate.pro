

pro montier_pol_estimate, I, Q, U, sigma_i, sigma_q, sigma_u, pol_deg, $
                          sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, noI=noI, plot=plot, $
                          p_max_pdf=p_max_pdf, psi_max_pdf=psi_max_pdf


nsn = 100 ; 200

p0          = sqrt( Q^2 + U^2)/I
psi0_deg_in = 0.5*atan(u,q)*!radeg

;;---------------------------------------
psi0 = psi0_deg_in*!dtor

;; Prior integration intervals
p_range   = [0.d0, 1.d0]

;; To be symetric around the starting value
psi_range = [-1,1]*90.d0 + psi0_deg_in

p   = dindgen(nsn)/(nsn-1)*(max(  p_range)-min(  p_range)) + min(  p_range)
psi = dindgen(nsn)/(nsn-1)*(max(psi_range)-min(psi_range)) + min(psi_range)
psi *= !dtor

if keyword_set(noI) then begin 
   p1   = rebin( p#(dblarr(nsn)+1), nsn, nsn)
   psi1 = rebin( (dblarr(nsn)+1)#psi, nsn, nsn)
   y = exp(-0.5d0*( (p1*I*cos(2.d0*psi1)-p0*I*cos(2.d0*psi0))^2/sigma_q^2 + $
                    (p1*I*sin(2.d0*psi1)-p0*I*sin(2.d0*psi0))^2/sigma_u^2))

   if keyword_set(plot) then begin
      wind, 1, 1, /free
      imview, y, xmap=p, ymap=psi*!radeg, $
              xtitle='p', ytitle='Angle (deg)', title='y (I)'
   endif

endif else begin
   i1_range  = I + [-1,1]*sigma_i*5
   i1  = dindgen(nsn)/(nsn-1)*(max( i1_range)-min( i1_range)) + min( i1_range)
   
   p1   = rebin( p#(dblarr(nsn)+1), nsn, nsn, nsn)
   psi1 = rebin( (dblarr(nsn)+1)#psi, nsn, nsn, nsn)
   i1   = rebin( reform(i1,1,1,nsn),nsn,nsn,nsn)
   
   y = exp(-0.5d0*( (i1-I)^2/sigma_i^2 + $
                    (p1*i1*cos(2.d0*psi1)-p0*I*cos(2.d0*psi0))^2/sigma_q^2 + $
                    (p1*i1*sin(2.d0*psi1)-p0*I*sin(2.d0*psi0))^2/sigma_u^2))

   if keyword_set(p_max_pdf) then begin
      pdf_p   = total( total( y, 3), 2)
      pdf_p   /= total(pdf_p)
      ;; p_max_pdf = p[ (where(pdf_p eq max(pdf_p)))[0]]
      p_max_pdf = total(p*pdf_p)/total(pdf_p)
   endif
   if keyword_set(psi_max_pdf) then begin
      pdf_psi = total( total( y, 3), 1)
      pdf_psi /= total(pdf_psi)
      ;; psi_max_pdf = !radeg * psi[ (where( pdf_psi eq max(pdf_psi)))[0]]
      psi_max_pdf = !radeg * total( psi*pdf_psi)/total(pdf_psi)
   endif

   if keyword_set(plot) then begin
      wind, 1, 1, /free
      my_y = reform(y[*,*,nsn/2])
      imview, my_y, xmap=p[*,*,nsn/2], ymap=psi[*,*,nsn/2]*!radeg, $
              xtitle='p', ytitle='Angle (deg)', title='y (I)'
   endif
endelse


;; because we normalize, no need to multiply the totals by dp*dpsi*di1
;; to get the integrals
norm      = total(y)
pol_deg   = total( y*p1)/norm
alpha_deg = total( y*psi1)/norm * !radeg

end
