
;; New qu estimator


pro qu2psi, stokes_q, stokes_u, sigma_q, sigma_u, psi_deg, cos2psi, sin2psi, alpha_deg

nsn = 100 ; 200

q_range = [-5,5]*sigma_q + stokes_q
u_range = [-5,5]*sigma_u + stokes_u

q = dindgen(nsn)/(nsn-1)*(max(q_range)-min(q_range)) + min(q_range)
u = dindgen(nsn)/(nsn-1)*(max(u_range)-min(u_range)) + min(u_range)

q = rebin( q#(dblarr(nsn)+1), nsn, nsn)
u = rebin( (dblarr(nsn)+1)#u, nsn, nsn)

pdf = exp( -0.5d0*( (q-stokes_q)^2/sigma_q^2 + $
                    (u-stokes_u)^2/sigma_u^2))
pdf /= total(pdf)

alpha_deg  = total(pdf * 0.5*atan(u,q))*!radeg
cos2psi = total( pdf * q/sqrt(q^2+u^2))
sin2psi = total( pdf * u/sqrt(q^2+u^2))

;; ensure normalization
cos2psi = cos2psi/sqrt(cos2psi^2+sin2psi^2)
sin2psi = sin2psi/sqrt(cos2psi^2+sin2psi^2)

psi_deg = 0.5d0*atan( sin2psi, cos2psi)*!radeg

stop



;; ;; try to solve the +-180 dispersion issue
;; if abs(sin2psi) lt 0.5 and cos2psi lt -0.5 then begin
;;    psi_deg = 0.5*atan( -sin2psi, -cos2psi)*!radeg
;; endif

;; ;;--------------------------------------------------------
;; ;; recenter on 0...
;; qu_norm = sqrt(stokes_q^2+stokes_u^2)
;; phi = 0.5*atan( stokes_u/qu_norm, stokes_q/qu_norm)
;; ;print, "phi_deg: ", phi*!radeg
;; 
;; cos2psi = total( pdf * q/sqrt(q^2+u^2))
;; sin2psi = total( pdf * u/sqrt(q^2+u^2))
;; ;; ensure normalization
;; cos2psi = cos2psi/sqrt(cos2psi^2+sin2psi^2)
;; sin2psi = sin2psi/sqrt(cos2psi^2+sin2psi^2)
;; 
;; ;; shift before taking the arctan
;; psi_deg = 0.5*Atan( cos(2*phi)*sin2psi - sin(2*phi)*cos2psi, $
;;                     cos(2*phi)*cos2psi + sin(2*phi)*sin2psi)*!radeg
;; 
;; ;print, "psi_deg before correction: ", psi_deg
;; 
;; ;; back around "input" position
;; psi_deg += phi*!radeg
;; ;print, "psi_deg (final): ", psi_deg
;;


end
