pro taufit4sim, am, fr, fr0, fr2K, tau, frfit, rmsfit, perr, silent = silent, $
                fiddle = fiddle
; Find a fit for skydip simulation where the response is known=1
; FXD, May 2021 (from taufit)
fr0 = 0d0  ; absolute frequency at null opacity
fr2K = 0.d0  ; Hz/K calibration (taken as positive in the output)
;;tau = -1.    ; sky opacity at zenith
nel = n_elements( am)
if nel lt 4 then return

;; Standard method
p_start = [-1000., tau, 2D9]  ; fr2K, tau, fr0 guesses
e_r = 1.d3
parinfo = replicate({fixed:0, limited:[1,1], $
                     limits:[0.,0.D0]}, 3)
parinfo[0].limits=[-15000,-100] ; reasonable range
parinfo[1].limits=[0.0,4.D0]
parinfo[2].limits=[1.d9,2.5d9]
parinfo[0].fixed = 1            ; gain is fixed
pst = p_start
ninit = 4
if keyword_set( fiddle) then ninit = fiddle
rmsarr = fltarr(ninit)
fact = 0.2+0.4*lindgen(ninit)
for i = 0, ninit-1 do begin
 p_start[1] = tau*fact[i]
 fit = mpfitfun("tau_model4sim", am, fr, $
               e_r, p_start, /quiet, $
                parinfo=parinfo)
 frfit = tau_model4sim( am, fit)
 rmsarr[i] = sqrt( mean( (fr-frfit)^2))
; stop
endfor
best = min(rmsarr, imin)
p_start[1] = tau*fact[imin]
fit = mpfitfun("tau_model4sim", am, fr, $
               e_r, p_start, quiet = silent, $
               parinfo=parinfo, bestnorm = bestnorm, $
               perror = perror)
;stop
;print, fit[1], rmsarr
dof = n_elements(am)- n_elements( p_start)
perr = perror*sqrt( bestnorm/dof )

tau = fit[1]
fr2K = -fit[0]
fr0 = fit[2]
frfit = tau_model4sim( am, fit)
rmsfit = sqrt( mean( (fr-frfit)^2))


return
end
