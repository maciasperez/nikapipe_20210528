
;; Uses mpfit to allow for constraints on estimated parameters but also deals
;; with sparse maps whereas mpfit2dpeak requires full maps (and sometimes does
;; not accept constraints ?!)
;;=============================================================================

function nika_gauss2dfit_2beams, z, x, y, errors, $  ; inputs
                                 params, perror, $   ; output
                                 parinfo=parinfo, covar=covar, $
                                 sigma_x_in=sigma_x_in, sigma_y_in=sigma_y_in
                          


;; Take default average value at 1 and 2mm
if keyword_set(sigma_x_in) then sigma_x = sigma_x_in else sigma_x = 14.d0
if keyword_set(sigma_y_in) then sigma_y = sigma_y_in else sigma_y = 14.d0

if keyword_set(parinfo) then begin
   p_guess = parinfo.value
endif else begin
   ;; Guess parameters
   const = median(z)
   
   ;; Look for the maximum modulus to deal with negative beams
   z_abs = abs( z-median(z))
   w     = where( z_abs eq max( z_abs))
   ampl  = z[w]
   xmax  = x[w]
   ymax  = y[w]
   
   p_guess = [const, ampl, sigma_x, sigma_y, xmax, ymax, 0.d0, $
              const, ampl, sigma_x, sigma_y, xmax, ymax, 0.d0]
endelse

params = mpfit2dfun( "nika_gauss2_2beams", x, y, z, errors, p_guess, $
                     perror=perror, dof=dof, bestnorm=bestnorm, $
                     /quiet, parinfo=parinfo, covar=covar)
fit = nika_gauss2_2beams( x, y, params)

;; Assuming the fit is good and following Markwardt's prescription in
;; mpfit2dfun, scale errors:
PERROR = PERROR * SQRT(BESTNORM / DOF)


return, fit


end

