
pro nk_get_hwp_rot_freq, data, rot_freq_hz

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_get_hwp_rot_freq, data, rot_freq_hz"
   return
endif

y = data.position - min(data.position)
w = where(y eq 0, nw)
npoint = median(w-shift(w,1))
rot_freq_hz = !nika.f_sampling/npoint


end
