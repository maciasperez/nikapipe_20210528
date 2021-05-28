
psi_lkg = 0.d0               ; fiducial angle
p_lkg = 0.02                 ; approximate integrated leakage over the main beam

;; the previous lock-in provided a nice I and the decorrelation
;; gives a smooth common mode to mimic atmosphere
;; Add a fraction of it modulated by the HWP to mimic leakage
nkids = n_elements(kidpar)
dt_sampling = 1.d0/!nika.f_sampling
delta = 2d0*!dpi*info.hwp_rot_freq*dt_sampling
avg_sin4 = 1.d0/(4.d0*delta)*(cos(4.d0*data.position-4.d0*delta/2.d0)-cos(4.d0*data.position+4.d0*delta/2.))
avg_cos4 = 1.d0/(4.d0*delta)*(sin(4.d0*data.position+4.d0*delta/2.d0)-sin(4.d0*data.position-4.d0*delta/2.))
c = avg_cos4##(dblarr(nkids)+1.d0)
s = avg_sin4##(dblarr(nkids)+1.d0)
data.toi = out_temp_data.toi*(1.d0 + p_lkg*( cos(2*psi_lkg*!dtor)*c + sin(2*psi_lkg*!dtor)*s))

;; Redo the lockin to produce Q and U timelines (I should remain
;; unchanged)
nk_lockin_2, param, info, data, kidpar
