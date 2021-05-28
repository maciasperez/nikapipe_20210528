
if param.log then nk_log, info, "Deriving kid noise on the fly"

;; - kidpar.noise is used in all common modes related subroutines, so
;; it must be computed before hand, hence here.
;; - can't take a brute force stddev because dominated by
;;   atmosphere at this stage of the processing
;; => brute force smooth and look above 4Hz
;; n4hz = round(!nika.f_sampling/4.d0)
nmed = round( !nika.f_sampling/param.lf_hf_freq_delim)

;; Correcting factor to get back to the full bandwidth white noise
junk = randomn( seed, 100000L)
hf=junk-median(junk,nmed)
white_noise_corr_factor = stddev(junk)/stddev(hf)
;; print, white_noise_corr_factor, 1.d0/white_noise_corr_factor

w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin &$
   nk_error, info, "No valid kid" &$
   return &$
endif
;; Need to loop: can't simply run median( toi, nwidth, dim=2), IDL doesn't allow
;; this (sic !)
kidpar_copy = kidpar
for i=0, nw1-1 do begin &$
   ikid = w1[i] &$
   y = data.toi[ikid]-median( data.toi[ikid], nmed) &$
   kidpar[ikid].noise = stddev( y) * white_noise_corr_factor &$
endfor
