;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; nk_twin_noise_toi
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         nk_twin_noise_toi, param, info, data, kidpar
; 
; PURPOSE: 
;        replaces the TOI's by noise simulations with the exact spectrum
;        of each toi, not a model fit like in nk_fit_sim_toi.
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
;        - Feb. 11th, 2016: NP
;-


pro nk_twin_noise_toi, param, info, data, kidpar

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   nk_twin_noise_toi, param, info, data, kidpar
   return
endif

w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kids."
   return
endif

;; Use the same fitting method as in nk_measure_atmo
nsn = n_elements(data)

w1 = where( kidpar.type eq 1, nw1)

;; Generate random seeds once for all to avoid spurious correlations with the clock.
seeds = reform( randomn(seed, nw1*2), nw1, 2)

for i=0, nw1-1 do begin
   ikid = w1[i]
   ft = fft( data.toi[ikid], /double)
   ftnoise = complex( randomn( seeds[i,0], nsn), randomn( seeds[i,1], nsn))
   ;; the power spec = |ft|^2, hence take the sqrt
   ftnoise = ftnoise*abs(ft)

;;   toi = data.toi[ikid]
;;   power_spec, data.toi[ikid], !nika.f_Sampling, pw, freq

   data.toi[ikid] = double(fft( ftnoise, /inv, /double))

;;    power_spec, data.toi[ikid], !nika.f_Sampling, pw_noise
;;    col_noise = 250
;;    wind, 1, 1, /free, /large
;;    my_multiplot, 1, 2, pp, pp1, /rev
;;    plot,  toi, /xs, position=pp1[0,*], title='raw toi'
;;    oplot, data.toi[ikid], col=col_noise
;;    legendastro, ['raw toi', 'noise'], line=[0,0], col=[!p.color, col_noise], box=0
;;    plot_oo, freq, pw, /xs, position=pp1[1,*], /noerase
;;    oplot,   freq, pw_noise, col=col_noise
;;    my_multiplot, /reset
;; stop
endfor

end
