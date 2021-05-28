
pro fitmap, map, map_var, xmap, ymap, params, covar, perror, $
            educated=educated, keep_orientation=keep_orientation, map_fit=map_fit, k_noise=k_noise


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "fitmap, map, map_var, xmap, ymap, params, covar, perror, $"
   print, "        educated=educated, keep_orientation=keep_orientation, map_fit=map_fit, k_noise=k_noise"
   return
endif

on_error, 2

wpix    = where( finite(map_var) and map_var gt 0, nwpix)
var_med = median( map_var[wpix])
;wpix    = where( finite(map_var) and map_var gt 0 and map_var le var_med,
;nwpix)
wpix    = where( finite(map_var) and map_var gt 0, nwpix)
if nwpix eq 0 then begin
   message, "No good pixel for the fit (all infinite or gt 2*median(var) ?!"
endif

if keyword_set(educated) then begin
   dmax = 60. ; 40
   d = sqrt( xmap^2 + ymap^2)
;   wpix = where( finite(map_var) and map_var gt 0 and map_var le var_med and d le dmax, nwpix)
   wpix = where( finite(map_var) and map_var gt 0 and d le dmax, nwpix)
endif

;; Fit parameters
covar = 1 ; init
fit = nika_gauss2dfit( map[wpix], xmap[wpix], ymap[wpix], map_var[wpix], params, perror, parinfo=parinfo, covar=covar)
map_fit = nika_gauss2( xmap, ymap, params)

;; ;;--------------------
;; phi = dindgen(100)/99.*2*!dpi
;; sigma = sqrt(params[2]*params[3])
;; imview,  map,  xmap = xmap, ymap = ymap
;; oplot,  dmax*cos(phi), dmax*sin(phi),  col = 255
;; loadct,  39,  /silent
;; oplot, params[4] + sigma*cos(phi), params[5] + sigma*sin(phi),  col = 250
;; stop
;; ;;---------------------

;; Estimate meaningful error bars by adding a fraction of the signal to the variance
if keyword_set(k_noise) then begin
   map_var = map_var + (k_noise*map)^2
   fit1 = nika_gauss2dfit( map[wpix], xmap[wpix], ymap[wpix], map_var[wpix], params_1, perror, parinfo=parinfo, covar=covar)
endif else begin
   perror = params*0.d0
endelse

if not keyword_set(keep_orientation) then begin
;; Change orientation convention
   params[6] = -params[6]
;; Force X to be the largest FWHM
   if params[3] gt params[2] then begin
      c    = params[2]
      params[2] = params[3]
      params[3] = c
      params[6] = params[6] + !dpi/2.
   endif
   params[6] = (params[6]+2*!dpi) mod !dpi
endif

;; ;; check
;; imview, map_fit, xmap=xmap, ymap=ymap
;; phi = dindgen( 200)/199*2*!dpi
;; xx  = params[2]*cos(phi)
;; yy  = params[3]*sin(phi)
;; xx1 =  cos(params[6])*xx + sin(params[6])*yy
;; yy1 = -sin(params[6])*xx + cos(params[6])*yy
;; oplot, params[4] + xx1, params[5] + yy1, col=250

end
