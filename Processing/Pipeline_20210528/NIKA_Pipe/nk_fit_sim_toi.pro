;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_fit_sim_toi
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_fit_sim_toi, param, info, data, kidpar
; 
; PURPOSE: 
;        replaces the TOI's by noise simulations. Allows to
;        check for NEFD in particular
; 
; INPUT: 
;        - param, info, data, kidpar
; 
; OUTPUT: 
;        - data.toi is modified
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Jan. 15th, 2016: NP
;-

function power_spec_mpfit,x,p
  return, p[0] * x^(p[1]) + p[2]
end


pro nk_fit_sim_toi, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   nk_fit_sim_toi, param, info, data, kidpar
   return
endif

w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kids."
   return
endif

;; Use the same fitting method as in nk_measure_atmo
nsn = n_elements(data)

;; init arrays
delta_t  = 1.0d0/!nika.f_sampling
delta_nu = 1./(nsn*delta_t)
n_mid = nsn/2             ; integer
sim_freq = dblarr(nsn)
sim_freq[0:n_mid]   = dindgen(n_mid+1)
sim_freq[n_mid+1:*] = -reverse( dindgen( nsn-n_mid-1)+1)
sim_freq = sim_freq/(nsn/!nika.f_sampling)
wf = where( sim_freq ne 0, nwf)

;; Main loop
for i=0, nw1-1 do begin
   ikid = w1[i]
   power_spec, data.toi[ikid], !nika.f_sampling, pw, freq

   weights = freq               ;Spectrum slope is close to -1 so weight for having log fit (first guess)
   parinfo = replicate({value:0.D,fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
   parinfo[2].limited = [1,0]
   parinfo[2].limits = [0.0,0.0]
   
   par0 = [mean(pw[n_elements(pw)/2:*]), -1.0, mean(pw[n_elements(pw)/2:*])]   
   par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                  weights=weights, parinfo=parinfo, yfit=yfit, AUTODERIVATIVE=1, /QUIET)
   weights = freq^(-par[1])     ;Spectrum slope used for weigthing
   par = mpfitfun('power_spec_mpfit',freq, pw, 0, par0, $
                  weights=weights,parinfo=parinfo,yfit=yfit,AUTODERIVATIVE=1,/QUIET)

   ;; Simu
   noise_model = sim_freq*0.d0
   noise_model[wf] = par[0]*abs(sim_freq[wf])^par[1]+par[2]
   noise = fft( randomn( seed, nsn), /double)
   noise = noise * noise_model * sqrt(!nika.f_sampling)
   noise = double( fft( noise, /double, /inv))

   data.toi[ikid] = noise
   
   ;; power_spec, noise, !nika.f_sampling, pw1
   ;; plot_oo, freq, pw, xtitle='Frequency (Hz)', $
   ;;          ytitle='P(f) (Jy.Hz!U-1/2!N)', /xs, /ys, charsize=0.7
   ;; oplot, freq, yfit, col=250
   ;; oplot, freq, par[2] + freq*0, col=150, linestyle=2
   ;; oplot, freq, par[0]*freq^par[1], col=150, linestyle=2
   ;; oplot, freq, pw1, col=250

endfor

end
