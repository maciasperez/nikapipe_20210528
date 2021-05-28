pro taufit, am, fr, fr0, fr2K, tau, frfit, rmsfit, silent = silent
; Find a fit for skydips
; FXD, Feb 2015 (start from an extract of nk_skydip.pro)
fr0 = 0d0  ; absolute frequency at null opacity
fr2K = 0.d0  ; Hz/K calibration (taken as positive in the output)
tau = -1.    ; sky opacity at zenith
nel = n_elements( am)
if nel lt 4 then return

;; Standard method
p_start = [-1000., 0.05, 2D9]  ; fr2K, tau, fr0 guesses
e_r = 1.d3
parinfo = replicate({fixed:0, limited:[1,1], $
                     limits:[0.,0.D0]}, 3)
parinfo[0].limits=[-15000,-100] ; reasonable range
parinfo[1].limits=[0.0,2.D0]
parinfo[2].limits=[1.d9,2.5d9]
 fit = mpfitfun("tau_model2", am, fr, $
               e_r, p_start, quiet = silent, $
               parinfo=parinfo)
tau = fit[1]
fr2K = -fit[0]
fr0 = fit[2]
frfit = tau_model2( am, fit)
rmsfit = sqrt( mean( (fr-frfit)^2))


;; ;; New method
;; nparams = 3
;; parinfo = replicate({fixed:0, limited:[1,1], $
;;                      limits:[0.,0.D0]}, nparams)
;; p_start = [1, 1, 0.5]
;; delvarx, e_r
;; parinfo[0].limits=[-10, 10]
;; parinfo[1].limits=[-1,1]*10
;; parinfo[2].limits = [0, 2.d0]
;; silent=1
;; myfit = mpfitfun("my_tau_model_2", am, -fr/1d9, $
;;                  e_r, p_start, quiet = silent, $
;;                  parinfo=parinfo)
;; tau    = myfit[2]
;; fr2k   = myfit[1]
;; fr0    = myfit[0]
;; frfit  = my_tau_model_2( am, myfit) * 1d9
;; rmsfit = sqrt( mean( (-fr-frfit)^2))


return
end
