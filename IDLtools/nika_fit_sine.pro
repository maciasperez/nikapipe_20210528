;; Add param to the inputs to add flexibilty (NP)

;; flag is 0 if the point is valid for fit, anything else to discard
;; it.

pro nika_fit_sine, x, y, flag, params, fit, status=status

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_fit_sine, x, y, flag, params, fit, status=status"
   return
endif

on_error, 2

nsn = n_elements(x)

if total( flag) ne 0 then begin
   w  = where( flag eq 0, nw)
   y1 = interpol( y[w], x[w], x)
endif else begin
   w = lindgen( nsn)
   y1 = y
   nw=nsn
endelse

;; valid sample range
i1 = min(w)
i2 = max(w)

if nw gt 300 then begin
;; First guess on frequency and amplitude
power_spec, y1[i1:i2], 1., pw, freq

pw_max  = max(pw, imax)
ampl    = minmax( y1[ i1:i2])
p_guess = [2d0*!dpi*freq[imax], ampl, ampl]
errors  = y1*0.d0 + 1.d0

;; Fit
params = mpfitfun( "nika_sine", x[w], y[w], errors[w], p_guess, /quiet, status=status)
fit = nika_sine( x, params)
endif else begin
   ; pathological cases
   status = -1000
endelse

end
