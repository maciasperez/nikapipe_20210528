
;; Computes the scanning median speed

pro data2speed, data, median_speed, show=show

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "data2speed, data, median_speed, show"
   return
endif

time = dindgen( n_elements(data))/!nika.f_sampling

v_az = data.ofs_az - shift( data.ofs_az, 1)
v_az = v_az[1:*]*!nika.f_sampling

v_el = data.ofs_el - shift( data.ofs_el, 1)
v_el = v_el[1:*]*!nika.f_sampling

time = time[1:*]
v    = sqrt( v_az^2 + v_el^2)

median_speed = median(v)

if keyword_set(show) then begin
   wind, 1, 1, /free
   plot, time, v, xtitle='Time [s]', ytitle='V [arcsec/s]', /xs
   oplot, time, time*0 + median_speed, col=250
   legendastro, 'Median Speed: '+num2string(median_speed), line=0, col=250, box=0
endif



end

