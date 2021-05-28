
;+
pro mb3d, stokes_I, stokes_Q, stokes_U, sigma_i, sigma_q, sigma_u, pol_deg, $
          sigma_p_plus, sigma_p_minus, psi_deg, sigma_psi_deg_minus, sigma_psi_deg_plus, $
          noI=noI, plot=plot, $
          p_max_pdf=p_max_pdf, psi_max_pdf=psi_max_pdf, p_pdf=p_pdf, psi_pdf=psi_pdf, $
          p_mb3d=p, psi_mb3d=psi
;-
if stokes_I eq 0 then begin
   pol_deg = 0.d0
   sigma_p_plus = 0.d0
   sigma_p_minus = 0.d0
   psi_deg = 0.d0
   sigma_psi_deg_minus = 0.d0
   sigma_psi_deg_plus = 0.d0
   p_max_pdf = 0.d0
   psi_max_pdf = 0.d0
   p_mb3d = 0.d0
   psi_mb3d = 0.d0
   return
endif
  
nsn = 300 ; 100 ; 200

p0          = sqrt( stokes_Q^2 + stokes_U^2)/stokes_I
psi0_deg_in = 0.5*atan(stokes_u,stokes_q)*!radeg

;;---------------------------------------
;; Prior integration intervals
;; p_range   = [0.d0, 1.d0]
qmax = max( abs( stokes_q+[-1,1]*5*sigma_q))
umax = max( abs( stokes_u+[-1,1]*5*sigma_u))
imin = min( abs( stokes_i+[-1,1]*5*sigma_i))
qmin = min( abs( stokes_q+[-1,1]*5*sigma_q))
umin = min( abs( stokes_u+[-1,1]*5*sigma_u))
imax = max( abs( stokes_i+[-1,1]*5*sigma_i))
p_range = [(sqrt(qmin^2+umin^2)/imax)>0.d0, (sqrt(qmax^2+umax^2)/imin) < 1d0]

;; To be symetric around the starting value
;; psi_range = [-1,1]*90.d0 + psi0_deg_in
sigma_psi_th_deg = 0.5*sqrt(stokes_u^2*sigma_q^2 + stokes_q^2*sigma_u^2)/(stokes_q^2+stokes_u^2)*!radeg
sigma_psi_th_deg = sigma_psi_th_deg < 90.d0

psi_range = psi0_deg_in + [-1,1]*5*sigma_psi_th_deg

p   = dindgen(nsn)/(nsn-1)*(max(  p_range)-min(  p_range)) + min(  p_range)
psi = dindgen(nsn)/(nsn-1)*(max(psi_range)-min(psi_range)) + min(psi_range)
psi *= !dtor

if keyword_set(noI) then begin 
   p1   = rebin( p#(dblarr(nsn)+1), nsn, nsn)
   psi1 = rebin( (dblarr(nsn)+1)#psi, nsn, nsn)

   pdf2d = exp(-0.5d0*( (p1*stokes_I*cos(2.d0*psi1)-stokes_Q)^2/sigma_q^2 + $
                        (p1*stokes_I*sin(2.d0*psi1)-stokes_U)^2/sigma_u^2))

   if keyword_set(plot) then begin
      wind, 1, 1, /free
      imview, pdf2d, xmap=p, ymap=psi*!radeg, $
              xtitle='p', ytitle='Angle (deg)', title='PDF 2D (stokes_I)'
   endif
   p_pdf    = total( pdf2d, 2)
   p_pdf   /= total( p_pdf)
   psi_pdf  = total( pdf2d, 1)
   psi_pdf /= total( psi_pdf)

;; because we normalize, no need to multiply the totals by dp*dpsi*di1
;; to get the integrals
   norm      = total( pdf2d)
   pol_deg   = total( pdf2d*p1)/norm
   psi_deg = total( pdf2d*psi1)/norm * !radeg

endif else begin

   i1_range  = stokes_I + [-1,1]*sigma_i*5
   i1  = dindgen(nsn)/(nsn-1)*(max( i1_range)-min( i1_range)) + min( i1_range)

   p1   = rebin( p#(dblarr(nsn)+1), nsn, nsn, nsn)
   psi1 = rebin( (dblarr(nsn)+1)#psi, nsn, nsn, nsn)
   i1   = rebin( reform(i1,1,1,nsn),nsn,nsn,nsn)

   pdf3d = exp(-0.5d0*( (i1-stokes_I)^2/sigma_i^2 + $
                        (p1*i1*cos(2.d0*psi1)-stokes_Q)^2/sigma_q^2 + $
                        (p1*i1*sin(2.d0*psi1)-stokes_U)^2/sigma_u^2))

   p_pdf   = total( total( pdf3d, 3), 2)
   p_pdf   /= total(p_pdf)

   psi_pdf = total( total( pdf3d, 3), 1)
   psi_pdf /= total(psi_pdf)

;; because we normalize, no need to multiply the totals by dp*dpsi*di1
;; to get the integrals
   norm      = total(pdf3d)
   pol_deg   = total( pdf3d*p1)/norm
   psi_deg = total( pdf3d*psi1)/norm * !radeg
endelse


p_max_pdf = p[ (where(p_pdf eq max(p_pdf)))[0]]
dp = p-p_max_pdf
order = sort( abs(dp))
frac = 0.d0
pmin = 1d10
pmax = -1d0
i=0
frac = 0.d0
while (i lt nsn) and frac le 0.68 do begin
   frac += p_pdf[ order[i]]
   if p[order[i]] lt pmin then pmin = p[order[i]]
   if p[order[i]] gt pmax then pmax = p[order[i]]
   i++
endwhile
sigma_p_minus = p_max_pdf-pmin
sigma_p_plus  = pmax-p_max_pdf


psi_max_pdf = !radeg * psi[ (where( psi_pdf eq max(psi_pdf)))[0]]
;; psi_max_pdf = (xpsi[ where(psi_fit eq max(psi_fit))])[0]
;; psi_max_pdf = a[1] 

dpsi = psi - psi_max_pdf*!dtor
order = sort( abs(dpsi))
frac = 0.d0
psi_min = 1d10
psi_max = -1d0
i=0
frac = 0.d0
while (i lt nsn) and frac le 0.68 do begin &$
   frac += psi_pdf[ order[i]] &$
   if psi[order[i]] lt psi_min then psi_min = psi[order[i]] &$
   if psi[order[i]] gt psi_max then psi_max = psi[order[i]] &$
   i++ &$
endwhile
sigma_psi_deg_minus = psi_max_pdf - psi_min*!radeg
sigma_psi_deg_plus  = psi_max*!radeg - psi_max_pdf

;; fit PDF p
if keyword_set(plot) then begin
   fmt = '(F5.2)'
   wind, 1, 1, /free, /xlarge
   my_multiplot, 2, 1, pp, pp1
   plot, p, p_pdf, psym=-8, syms=0.5, xra=xra, /xs, $
         xtitle='pol deg', ytitle='PDF', position=pp1[0,*], yra=[0,max(p_pdf)]*1.3
   oplot, [1,1]*pmin, [-1,1]*1d10, line=2
   oplot, [1,1]*pmax, [-1,1]*1d10, line=2
   oplot, [1,1]*p_max_pdf, [-1,1]*1d10
   legendastro, ['P!dmax pdf!n (%)= '+string(100*p_max_pdf,format=fmt)+$
                 " + "+string(100*sigma_p_plus,format=fmt)+$
                 " - "+string(100*sigma_p_minus,format=fmt)]
;; r = gaussfit( p, p_pdf, a)
;; xp = dindgen(1000)/999
;; z = (xp-a[1])/a[2]
;; pfit = a[0]*exp(-z^2/2.d0) + a[3] + a[4]*xp + a[5]*xp^2
;; oplot, xp, pfit, col=250
;; print, xp[where(pfit eq max(pfit))]
;   stop

   plot, psi*!radeg, psi_pdf, psym=-8, syms=0.5, /xs, $
         xtitle='Psi (deg)', ytitle='PDF', position=pp1[1,*], /noerase, yra=[0,max(psi_pdf)]*1.3
   oplot, [1,1]*psi_min*!radeg, [-1,1]*1d10, line=2
   oplot, [1,1]*psi_max*!radeg, [-1,1]*1d10, line=2
   legendastro, ['Psi!dmax pdf!n (deg) = '+string(psi_max_pdf,form='(F7.2)')+$
                 ' + '+string(sigma_psi_deg_plus,form='(F7.2)')+$
                 ' - '+string(sigma_psi_deg_minus,form='(F7.2)')]
;   stop
endif

;; fit PDF psi
;delvarx, xra
;wind, 1, 1, /free
;plot, psi*!radeg, psi_pdf, psym=-8, syms=0.5, xra=xra, /xs
;; r = gaussfit( psi*!radeg, psi_pdf, a)
;; xpsi = dindgen(1000)/999.*180.-90
;; z = (xpsi-a[1])/a[2]
;; psi_fit = a[0]*exp(-z^2/2.d0) + a[3] + a[4]*xpsi + a[5]*xpsi^2
;oplot, xpsi, psi_fit, col=250
;stop
end
