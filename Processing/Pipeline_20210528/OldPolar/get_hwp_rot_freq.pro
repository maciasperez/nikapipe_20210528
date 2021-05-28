
pro get_hwp_rot_freq, data, rot_freq_hz

w = where( data.c_synchro lt median( data.c_synchro)*0.9, nw)

time = dindgen( n_elements(data))/!nika.f_sampling
dt_hwp = time[w] - shift( time[w], 1)

;; get rid of the first one (circular difference screws up its values)
dt_hwp = dt_hwp[1:*]

;; estimate hwp rotation frequency
rot_freq_hz = 1.d0/median( dt_hwp)


end
