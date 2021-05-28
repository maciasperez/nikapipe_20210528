
pro nk_check_lockin_plots, param, info, data, kidpar, baseline, my_filter

w1 = where( kidpar.type eq 1 and kidpar.array eq 1)
nsn = n_elements(data)
i=0
ikid = w1[0]



y_bl     = (data.toi[ikid] - baseline[i,*])[100:nsn-100]
toi_q_bl = double( fft( fft( y_bl*data.cospolar,/double)*my_filter[ikid,*], /double, /inv))


power_spec, y_bl, !nika.f_sampling, pwi_bl, freq
power_spec, toi_q_bl, !nika.f_sampling, pwq_bl, freq_q

power_spec, data.ofs_az, !nika.f_sampling, pwaz, freq_az

;; see NP/Polar/Mess/bhss.pro
sigma_t = 11.d0*!fwhm2sigma/info.median_scan_speed
sigma_k = 1.0d0/(2.0d0*!dpi*sigma_t)

;wd, /a
wind, 1, 1, /free, /large
my_multiplot, 2, 3, pp, pp1, /rev, xmin=0.6, xmax=0.95, xmargin=0.01, ymin=0.05, ymax=0.95
plot, data.toi[ikid], /xs, /ys, position=pp[0,0,*]
legendastro, ['raw'], col=[!p.color, col_boxcar, col_gauss], line=0, /bottom

plot, data.toi[ikid], /xs, /ys, position=pp[0,1,*], xra=[0,300], /noerase
legendastro, ['raw']

plot, data.toi[ikid], /xs, /ys, position=pp[0,1,*], xra=[nsn-300,nsn], /noerase
legendastro, ['raw']

plot_oo, freq, pwi_bl, /xs, position=pp[1,0,*], /noerase
oplot, freq_q, max(pwq_bl)*exp(-freq_q^2/(2.d0*sigma_k^2)), col=200
oplot, freq_q, max(pwaz)*exp(-freq_q^2/(2.d0*sigma_k^2)), col=200


;;--------------------------

freqhigh = 6.
np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
             freqlow=0.d0, $
             freqhigh=freqhigh, $
             delta_f=0.2, filter=I_filter


baseline_i = my_baseline( data.toi[ikid], base=0.05)
np_bandpass, data.toi[ikid] - baseline_i, !nika.f_sampling, I_out, filter=I_filter

power_spec, data.toi[ikid]-baseline_i, !nika.f_sampling, pwi, freq
power_spec, I_out, !nika.f_sampling, pwi_out

toi_q_out = double( fft( fft( (data.toi[ikid]-baseline_i-I_out)*data.cospolar,/double)*my_filter[ikid,*], /double, /inv))
power_spec, toi_q_out, !nika.f_sampling, pwq_out

col_i_out = 40
wind, 2, 3, /free, /large
my_multiplot, 2, 4, pp, pp1, /rev, gap_x=0.1
plot, data.toi[ikid], position=pp[0,0,*], title='I', /noerase
oplot, baseline_i, col=70

plot, data.toi[ikid]-baseline_i, position=pp[0,1,*], title='I-baseline', /noerase
oplot, i_out, col=100
legendastro, 'I_out', line=0, col=100

plot, data.toi[ikid]-baseline_i-i_out, position=pp[0,2,*], title='I-baseline-i_out', /noerase

plot_oo, freq, pwi, /xs, position=pp[1,1,*], /noerase, yra=max(pwi)*[1d-6, 10.], /ys
oplot, freq, pwi_out, col=100
oplot, freq, max(pwi_out)*exp(-freq^2/(2.d0*sigma_k^2)), col=200
oplot, freq, max(pwi_out)*exp(-(freq-info.hwp_rot_freq*4)^2/(2.d0*sigma_k^2)), col=150
legendastro, ['toi', 'I_out'], line=0, col=[!p.color, 100]

plot, freq, pwi, /xs, position=pp[1,2,*], /noerase, yra=max(pwi)*[1d-6, 10.], /ys, /ylog
oplot, freq, pwi_out, col=100
oplot, freq, max(pwi_out)*exp(-freq^2/(2.d0*sigma_k^2)), col=200
legendastro, ['toi', 'I_out'], line=0, col=[!p.color, 100]

plot, toi_q_out, position=pp[0,3,*], /noerase, title='toi_q_out'
oplot, toi_q_out, col=250
plot_oo, freq, pwq_out, /xs, position=pp[1,3,*], /noerase, title='Q out', yra=max(pwq_out)*[1d-6,10.], /ys
oplot, freq, pwq_out, col=250
oplot, freq, max(pwq_out)*exp(-freq^2/(2.d0*sigma_k^2)), col=200


end

