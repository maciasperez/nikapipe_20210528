pro taufitc1fix, am, fr, fr0, fr2K, tau, frfit, rmsfit, silent = silent
; Find a fit for skydips
; FXD, Feb 2015 (start from an extract of nk_skydip.pro)
; Here fr2K is supposed to be known
fr0 = 0d0  ; absolute frequency at null opacity
;fr2K = 0.d0  ; Hz/K calibration (taken as positive in the input/output)
tau = -1.    ; sky opacity at zenith
nel = n_elements( am)
if nel lt 4 then return

p_start = [-fr2K, 0.05, 2D9]  ; -fr2K, tau, fr0 guesses
e_r = 1.d3
parinfo = replicate({fixed:0, limited:[1,1], $
                     limits:[0.,0.D0]}, 3)
parinfo[0].limits=[-15000,-100] ; reasonable range
parinfo[1].limits=[0.0,2.D0]
parinfo[2].limits=[0.8d9,2.5d9]

parinfo[0].fixed = 1
 
fit = mpfitfun("tau_model2", am, fr, $
               e_r, p_start, quiet = silent, $
               parinfo=parinfo)
tau = fit[1]
fr2K = -fit[0]
fr0 = fit[2]
frfit = tau_model2( am, fit)
rmsfit = sqrt( mean( (fr-frfit)^2))

return
end
