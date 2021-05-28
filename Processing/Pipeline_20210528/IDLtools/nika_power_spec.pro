
;; Convenient wrapper to power_spec for common quicklook

pro nika_power_spec, data, acq_freq, pw, freq, $
                     median=n_median, total_sp= total_sp, $
                     logsm= logsm, cross = cross, $
                     apod_frac=apod_frac, baseline=baseline, taper_in=taper_in


toi = data
nsn = n_elements(data)

if keyword_set(baseline) then toi = toi - qd_baseline(toi)

taper = 1.d0 ; default
if keyword_set(taper_in) then begin
   taper = taper_in
endif else begin
   if keyword_set(apod_frac) then begin
      make_hat_function, dindgen(nsn), apod_frac*nsn, (1-apod_frac)*nsn, apod_frac*nsn, apod_frac*nsn, taper, /force, /silent
   endif
endelse

power_spec, toi*taper, acq_freq, pw, freq, $
            median=n_median, total_sp= total_sp, $
            logsm= logsm, cross = cross

end
