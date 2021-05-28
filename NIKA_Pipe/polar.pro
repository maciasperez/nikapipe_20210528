

scan = '20150211s205'
nk_getdata, param, info, data, kidpar, scan=scan

nk_list_kids, kidpar, lambda=2, valid=w1, nvalid=nw1

ikid = w1[0]

power_spec, data.toi[ikid], !nika.f_sampling, pw, freq

wind, 1, 1, /free, xs=1000
outplot, file='polar_pow_spec', png=png
plot_oo, freq, pw, xtitle='Hz', ytitle='TOI Power spectrum', /xs
for i=1, 6 do oplot, [i,i]*info.hwp_rot_freq, [1e-10,1e10], line=2
outplot, /close

end
