pro taufit4sim2, am, fr, fr0, fr2K, tau, ctau, frac_oxy, $
                 frfit, rmsfit, perr, silent = silent
; Find a fit for skydip simulation where the response is known=1
; FXD, May 2021 (from taufit)
fr0 = 0d0  ; absolute frequency at null opacity
fr2K = 0.d0  ; Hz/K calibration (taken as positive in the output)
;;tau = -1.    ; sky opacity at zenith
;; Here the difference with taufit4sim is that there is constant ctau added
;; into the fit
nel = n_elements( am)
if nel lt 4 then return

;; Standard method
p_start = [-1000., tau, ctau, frac_oxy, 2D9]  ; fr2K, tau, ctau, frac_oxy,fr0 guesses
e_r = 1.d3
parinfo = replicate({fixed:0, limited:[1,1], $
                     limits:[0.,0.D0]}, 5)
parinfo[0].limits=[-15000,-100] ; reasonable range
parinfo[1].limits=[0.0,4.D0]
parinfo[2].limits=[0., 0.4]; reasonable range for oxygen
parinfo[3].limits=[0., 0.5]; reasonable range for oxygen
parinfo[4].limits=[1.d9,2.5d9]
parinfo[0].fixed = 1            ; gain is fixed
parinfo[2].fixed = 1            ; ctau is fixed
parinfo[4].fixed = 1            ; fr0 is fixed
pst = p_start
ninit = 10
rmsarr = fltarr(ninit)
fact = 0.2+0.4*lindgen(ninit)
for i = 0, ninit-1 do begin
 p_start[1] = tau*fact[i]
 fit = mpfitfun("tau_model4sim2", am, fr, $
               e_r, p_start, /quiet, $
                parinfo=parinfo)
 frfit = tau_model4sim2( am, fit)
 rmsarr[i] = sqrt( mean( (fr-frfit)^2))
endfor
best = min(rmsarr, imin)
p_start[1] = tau*fact[imin]
fit = mpfitfun("tau_model4sim2", am, fr, $
               e_r, p_start, quiet = silent, $
               parinfo=parinfo, bestnorm = bestnorm, $
               perror = perror)
;stop
dof = n_elements(am)- n_elements( p_start)
perr = perror*sqrt( bestnorm/dof )

tau = fit[1]
ctau = fit[2]
frac_oxy = fit[3]
fr2K = -fit[0]
fr0 = fit[4]
frfit = tau_model4sim2( am, fit)
rmsfit = sqrt( mean( (fr-frfit)^2))


return
end
