
t_max_mn = 3 ; min
f_sample = 100. ; 22. ; Hz

nsn = long( t_max_mn*60.*f_sample)

nkids = 3

rot_speed = 2.5 ; Hz

; Kids white noise
noise_ampl = 1

; template params
n_harmonics = 8
drift = 0.1
ampl = 3


;----------------------------------------------------------------------
toi = dblarr( nkids, nsn)

t = dindgen(nsn)/f_sample
omega = 2.0d0*!dpi*rot_speed*t mod (2*!dpi)

omega_deg = omega*!radeg
make_template, n_harmonics, omega_deg, t, ampl, drift, beta

; Build toi
for k=0, nkids-1 do begin
   toi[k,*] = beta + randomn( seed, nsn)*noise_ampl
endfor

; Subtract
nika_hwp_rm, toi[0,*], t, omega_deg, n_harmonics, beta_out, toi_out

; Plot results
col_beta_in  = 70
col_beta_out = 150
col_toi_out  = 250

chars = 2
xra = [0,3]
wind, 1, 1, /free, /large
!p.multi=[0,1,3]
plot, t, omega_deg, xtitle='t', ytitle='Omega [deg]', xra=xra, /xs, chars=chars
plot, t, beta, xtitle='t', ytitle='Template !7b!3', xra=xra, /xs, chars=chars
plot, t, toi[0,*], xtitle='t', ytitle='TOI[0,*]', xra=xra, /xs, chars=chars
oplot, t, beta, col=col_beta_in
oplot, t, beta_out, col=col_beta_out
legendastro, ['TOI', 'Template (in)', 'Template (out)'], $
        col=[!p.color, col_beta_in, col_beta_out], line=0
!p.multi=0


power_spec, toi[0,*], f_sample, pw_data, freq
power_spec, beta, f_sample, pw_beta_in
power_spec, toi_out[0,*], f_sample, pw_out

xra = [min(freq[where(freq ne 0)]), max(freq)*2]
yra = minmax( [pw_data, pw_out])*[0.1,10]
wind, 2, 2, /free, /large
plot_oo, freq, pw_data, xra=xra, yra=yra, /xs, /ys
oplot, freq, pw_beta_in, col=col_beta_in
oplot, freq, pw_out, col=col_toi_out
legendastro, ['TOI', 'Template (in)', 'TOI-template(fit)'], $
        col=[!p.color, col_beta_in, col_toi_out], line=0


end
