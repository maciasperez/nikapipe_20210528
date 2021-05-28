
;+
;
; SOFTWARE: General
;
; NAME: 
; nk_fitmap
;
; CATEGORY: general
;
; CALLING SEQUENCE:
;        nk_fitmap, map, map_var, xmap, ymap, params, covar, perror, $
;                   educated=educated, keep_orientation=keep_orientation,
;                   map_fit=map_fit, k_noise=k_noise
;
; PURPOSE:
;        Performs a 2D gaussian fit on signal map
;
; INPUT:
;       - map: signal map
;       - map_var: variance map
;       - xmap: coordinates along the x direction
;       - ymap: coordinates along the y direction
;
; OUTPUT:
;      - params: gaussian fit parameters
;      - covar: covariance on the fit parameters
;      - perror: error on the fit parameters
;
; KEYWORDS:
;      - educated: forces the fit around the center of the map
;      - keep_orientation: if *not* set, the major axis of the elliptical
;        gaussian fit is forced to be "x"
;      - map_fit: output fit map
;      - k_noise: adds this fraction of the signal map to the noise map to
;                 derive meaningful error bars on real data maps (when
;                 there's residual atmosphere and/or correlated noise, the variance per
;                 pixel can be underestimated when computed from TOI's stddev)
;
; SIDE EFFECT:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;        - June 11th, 2014: Nicolas Ponthieu (ported from IDLtools/fitmap)
;-
;================================================================================================

pro nk_fitmap, map, map_var, xmap, ymap, params, covar, perror, $
               educated=educated, keep_orientation=keep_orientation, map_fit=map_fit, k_noise=k_noise, $
               info=info, status=status, xguess=xguess, yguess=yguess, silent=silent, $
               guess_fit_par=guess_fit_par, sigma_guess=sigma_guess, dmax=dmax ;; LP fix


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_fitmap, map, map_var, xmap, ymap, params, covar, perror, $"
   print, "           educated=educated, keep_orientation=keep_orientation, map_fit=map_fit, k_noise=k_noise, $"
   print, "           info=info, status=status, xguess=xguess, yguess=yguess,$"
   print, "           guess_fit_par=guess_fit_par, sigma_guess=sigma_guess"
   return
endif
params = dblarr(7)

;on_error, 2

wpix = where( finite(map_var) and map_var gt 0, nwpix)
if nwpix lt 16 then begin
   if keyword_set(info) then begin
      nk_error, info, "Less than 16 pixels have a defined variance, I cannot fit.", status = 2
   endif else begin
      message,/info, $
              "Less than 16 pixels have a defined variance, I cannot fit."
   endelse      
   return
endif
var_med = median( map_var[wpix])

;;--------------------------------------------
if (keyword_set(educated) or keyword_set(guess_fit_par)) then begin

   if not keyword_set(xguess) then xguess = 0.d0
   if not keyword_set(yguess) then yguess = 0.d0
   dma = 60. ; 40
   if keyword_set(dmax) then dma = dmax
   d = sqrt( (xmap-xguess)^2 + (ymap-yguess)^2)
   wpix1 = where( finite(map_var) and map_var gt 0 and d le dma, nwpix1)
   if nwpix1 eq 0 then begin
      if not keyword_set(silent) then $
         message, /info, "No pixel valid at less than "+strtrim(dma, 2)+" arcsec from the map center"
   endif else begin
      wpix = wpix1
   endelse
endif

;; Fit parameters
covar = 1 ; init

;; LP add
;; define guess parameters
if keyword_set(guess_fit_par) then begin

   const = median(map[wpix])
   rclose = 15. ; arcsec
   wclose = where(d[wpix] le rclose, nwclose)
   w     = where(map[wpix[wclose]] eq max( map[wpix[wclose]]) )
   ampl  = map[wpix[wclose[w]]]
   xmax  = xmap[wpix[wclose[w]]]
   ymax  = ymap[wpix[wclose[w]]]
   
   ;; Take default average value at 1 and 2mm
   if keyword_set(sigma_guess) then sigma_x = sigma_guess else sigma_x = 6.d0
   if keyword_set(sigma_guess) then sigma_y = sigma_guess else sigma_y = 6.d0
   
   ;; see explanation in mpfit2dfun.pro
   parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
                        limits:[0.D,0]}, 7)
   parinfo[0].value = const
   parinfo[1].value = ampl
   parinfo[2].value = sigma_x
   parinfo[3].value = sigma_y
   parinfo[4].value = xmax
   parinfo[5].value = ymax
   ;;stop

endif
;help,wpix
;stop

fit = nika_gauss2dfit( map[wpix], xmap[wpix], ymap[wpix], map_var[wpix], $
                       params, perror=perror, parinfo=parinfo, covar=covar, status=status)
if status ne 0 then begin
   txt = "Gaussian fit on map did not work"
   message, /info, txt
   nk_error, info, txt
   return
endif
map_fit = nika_gauss2( xmap, ymap, params)

;; Estimate meaningful error bars by adding a fraction of the signal
;; to the variance but keep "fit" as the results
if keyword_set(k_noise) then begin
   fit1 = nika_gauss2dfit( map[wpix], xmap[wpix], ymap[wpix], map_var[wpix] + (k_noise*map[wpix])^2, $
                           params_1, perror=perror, parinfo=parinfo, covar=covar)
endif else begin
   perror = params*0.d0
endelse

;; ;;--------------------------------------------
;; message, /info, "fix me:"
;; reso = abs(xmap[1, 0]-xmap[0, 0])
;; parinfo = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 7)
;; if keyword_set(educated) then begin
;;   parinfo[4].limited = [1,1]
;;   parinfo[4].limits = [-1, 1]*60.d0
;;   parinfo[5].limited = [1,1]
;;   parinfo[5].limits = [-1, 1]*60.d0
;; endif
;; 
;; estimates = [0, 1e-2, 15/reso*!fwhm2sigma, 15/reso*!fwhm2sigma, 0.d0, 0.d0, 0] ; Standard guess
;; 
;; w8 = xmap*0.d0
;; w = where(map_var gt 0, nw)
;; if nw eq 0 then message, "No fixel with a positive variance"
;; if keyword_set(k_noise) then map_var =  map_var + (k_noise*map)^2
;; w8[w] = 1.d0/map_var[w]
;; 
;; ;;------- Fit gaussian parameters A
;; tilt = 1
;; circular = 0
;; best_fit = mpfit2dpeak(map, params, /GAUSSIAN, WEIGHTS=w8, CIRCULAR=CIRCULAR, TILT=TILT, $
;;                        ESTIMATES=estimates, parinfo=parinfo, QUIET=1, SIGMA=err_params, CHISQ=CHISQ, DOF=DOF)
;; ;  rchi2 = CHISQ/DOF
;; 
;; ;;----- Convert paramss to physical values
;; params[2] *= reso
;; params[3] *= reso
;; params[4] *= reso
;; params[5] *= reso
;; 
;; print, '------------------------------------------'
;; print, '--- Single gaussian model ----------------'
;; print, '--------- Best fit parametres : ----------'
;; print, '--------- Background : ', params[0]
;; print, '--------- Amplitude : ', params[1]
;; print, '--------- FWHM along x: ', params[2]/!fwhm2sigma
;; print, '--------- FWHM along y: ', params[3]/!fwhm2sigma
;; print, '--------- FWHM total: ', sqrt(params[3]*params[2])
;; print, '--------- Center along x:', params[4], '  arcsec'
;; print, '--------- Center along y:', params[5], '  arcsec'
;; print, '--------- Tilt angle : ', params[6]
;; print, '------------------------------------------'
;; 
;; ;;stop
;; 
;; if not keyword_set(keep_orientation) then begin
;; ;; Change orientation convention
;;    params[6] = -params[6]
;; ;; Force X to be the largest FWHM
;;    if params[3] gt params[2] then begin
;;       c    = params[2]
;;       params[2] = params[3]
;;       params[3] = c
;;       params[6] = params[6] + !dpi/2.
;;    endif
;;    params[6] = (params[6]+2*!dpi) mod !dpi
;; endif
;; 
;; ;; ;; check
;; ;; imview, map_fit, xmap=xmap, ymap=ymap
;; ;; phi = dindgen( 200)/199*2*!dpi
;; ;; xx  = params[2]*cos(phi)
;; ;; yy  = params[3]*sin(phi)
;; ;; xx1 =  cos(params[6])*xx + sin(params[6])*yy
;; ;; yy1 = -sin(params[6])*xx + cos(params[6])*yy
;; ;; oplot, params[4] + xx1, params[5] + yy1, col=250

end
