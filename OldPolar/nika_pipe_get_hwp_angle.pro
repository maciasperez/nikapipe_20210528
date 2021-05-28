
;; Patch code to build the HWP angle until we understand the true meaning of
;; c_position

pro nika_pipe_get_hwp_angle, param, data, kidpar, check=check


if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_pipe_get_hwp_angle, param, data, kidpar, check=check"
   return
endif

nsn   = n_elements(data)
time  = dindgen(nsn)/!nika.f_sampling
omega = dblarr(nsn)

;; Generate HWP angle from the synchro, phased with the syncrho.
;;w = where( (data.c_synchro - shift( data.c_synchro,1)) lt -1000, nw)
y = data.c_synchro - median(data.c_synchro)
w = where( y lt min(y)/2., nw)
if nw gt 1 then begin
   for i=0L, nw-1 do omega[w[i]] = i*2.d0*!dpi

   ;; Interpol also does extrapolation on pieces of time that are
   ;; larger than max(time[w]) in this simple linear case.
   ;; ==> good for us.
   omega = interpol( omega[w], time[w], time)
endif

if keyword_set(check) then begin
   time_range = [2,4]
   wind, 1, 1, /free, /large
   !p.multi=[0,1,3]
   plot, time, data.c_position, xra=time_range, /xs, ytitle='c_position'
   plot, time, data.c_synchro,  xra=time_range, /xs, ytitle='c_synchro'
   plot,  time, omega, xra=time_range, /xs, ytitle='Omega'
   oplot, time[w], omega[w], psym=8, col=250
   !p.multi=0
endif

;; Update the correct field
data.c_position = omega mod (2.d0*!dpi)

end
