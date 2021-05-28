
;; Derive polarization degree and angles in the case of high signal to noise.

;+
pro iqu2pol_info, i, q, u, sigma_i, sigma_q, sigma_u, pol_deg, sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg, $
                  old_formula=old_formula, mb3d=mb3d
;-

if n_params() lt 1 then begin
   message, /info, "Calling sequence"
   dl_unix, 'iqu2pol_info'
   return
endif

;;   montier_pol_estimate, i, q, u, sigma_i, sigma_q, sigma_u, pol_deg, $
;;                         sigma_p_plus, sigma_p_minus, alpha_deg, sigma_alpha_deg

if keyword_set(mb3d) then begin

   mb3d, I, Q, U, sigma_i, sigma_q, sigma_u, pol_deg_junk, $
         sigma_p_plus, sigma_p_minus, psijunk, sigma_psi_deg_minus, sigma_psi_deg_plus, $
         p_max_pdf=pol_deg, psi_max_pdf=alpha_deg
   sigma_alpha_deg = (sigma_psi_deg_plus+sigma_psi_deg_minus)/2.
   
endif else begin
     
;; Angle (high S/N case) (default)
   alpha_deg = 0.5*atan( u, q)*!radeg
   sigma_alpha_deg = 0.5d0/(q^2+u^2)*sqrt( q^2*sigma_u^2 + u^2*sigma_q^2)*!radeg
   
;; Degree of polarization (high S/N case)
   iqu2poldeg, i, q, u, $
               sigma_i, sigma_q, sigma_u, pol_deg, sigma_p_plus, sigma_p_minus, $
               two_sigma_p_plus, two_sigma_p_minus, three_sigma_p_plus, three_sigma_p_minus, $
               old_formula=old_formula
endelse

end
