
;; Look at corr2cm coefficients per subscan and per scan and compare
;; to calib_fix_fwhm
;;-----------------------------------------------------------------

;+
pro nk_check_tau_variations, param, info, data, kidpar, tauall, $
                             taua1, tau2, taua3, $
                             opacorrall, opacorra1, opacorr2, opacorra3

;-

if n_params() lt 1 then begin
   dl_unix, 'nk_check_tau_variations'
   return
endif

if param.plot_ps eq 0 and param.plot_z eq 0 then wind, 1, 1, /free, /large

outplot, file=param.project_dir+'/Plots/tau_variations_'+param.scan, $
         png=param.plot_png, ps=param.plot_ps, z=param.plot_z

my_multiplot, 3, 3, pp, pp1, /rev, gap_x=0.05
nsn = n_elements(data)
time = dindgen(nsn)/!nika.f_sampling
pap = [0,2,1]
for iarray=1, 3 do begin
   if iarray eq 1 then ytitle='tau' else ytitle=''
   plot, minmax(time), [0,2], /xs, /ys, /nodata, $
         position=pp[pap[iarray-1],0,*], xtitle='time (sec)', ytitle=ytitle, /noerase
   nika_title, info, /all

   legendastro, 'A'+strtrim(iarray,2)
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   make_ct, nw1, ct
   for i=0, nw1-1 do begin
      ikid = w1[i]
      oplot, time, tauall[*,ikid], col=ct[i]
   endfor

   if iarray eq 1 then ytitle='opacorr' else ytitle=''
   plot, minmax(time), [0,2], /xs, /ys, /nodata, $
         position=pp[pap[iarray-1],1,*], xtitle='time (sec)', ytitle=ytitle, /noerase
   legendastro, 'A'+strtrim(iarray,2)
   w1 = where( kidpar.type eq 1 and kidpar.array eq iarray, nw1)
   make_ct, nw1, ct
   for i=0, nw1-1 do begin
      ikid = w1[i]
      oplot, time, opacorrall[*,ikid], col=ct[i]
   endfor
endfor

plot, time, [0,2], /xs, /ys, xtitle='time', title='e!7!us/!3sin(el)!n', $
      position=pp[0,2,*], /noerase
oplot, time, exp(taua1/sin(data.el)), col=70
oplot, time, exp(taua3/sin(data.el)), col=100
oplot, time, exp(tau2/sin(data.el)), col=250

yra = array2range( [exp(taua1/sin(data.el)) / avg( exp(taua1/sin(data.el))), $
                    exp(taua3/sin(data.el)) / avg( exp(taua3/sin(data.el))), $
                    exp(tau2 /sin(data.el)) / avg( exp(tau2 /sin(data.el)))])
plot, time, yra, /xs, /ys, yra=yra, xtitle='time', title='e!7!us/!3sin(el)!n/<e!7!us/!3sin(el)!n>', $
      position=pp[1,2,*], /noerase
oplot, time, exp(taua1/sin(data.el)) / avg( exp(taua1/sin(data.el))), col=70
oplot, time, exp(taua3/sin(data.el)) / avg( exp(taua3/sin(data.el))), col=100
oplot, time, exp(tau2 /sin(data.el)) / avg( exp(tau2 /sin(data.el))), col=250

yra = array2range( [exp(taua1/sin(data.el))/opacorra1, $
                    exp(taua3/sin(data.el))/opacorra3, $
                    exp(tau2/sin(data.el))/opacorr2])
plot, time, yra, yra=yra, /xs, /ys, xtitle='time', title='e!7!us/!3sin(el)!n/opacorr', $
      position=pp[2,2,*], /noerase
oplot, time, exp(taua1/sin(data.el))/opacorra1, col=70
oplot, time, exp(taua3/sin(data.el))/opacorra3, col=100
oplot, time, exp(tau2/sin(data.el))/opacorr2, col=250

outplot, /close

end
