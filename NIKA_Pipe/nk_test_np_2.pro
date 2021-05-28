
pro nk_test_np_2, param, info, toi, flag, off_source, kidpar, $
                  common_mode, elevation
  
;; sanity checks  
if info.status eq 1 then begin
   if param.silent eq 0 then message, /info, "info.status = 1 from the beginning => exiting"
   return
endif

nkids = n_elements(kidpar)
nsn  = n_elements(toi[0,*])

;; Loop on kids
w1 = where( kidpar.type eq 1, nw1)
if nw1 eq 0 then begin
   nk_error, info, "No valid kid"
   return
endif

common_mode = dblarr(nkids, nsn)
snr         = dblarr(nkids, nsn)

;; do not use nk_get_cm_sub_2 because in iterative mode, all
;; off_source are 1.
block_common_mode = median(toi,dim=1)

;; Use this first CM estimation to derive a SNR per sample and
;; improve its estimation
for ikid=0, nkids-1 do begin
   w = where( off_source[ikid,*] eq 1 and (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nw)
   if nw ne 0 then begin
      fit = linfit( block_common_mode[w], toi[ikid,w])
      y = toi[ikid,*] - (fit[0] + fit[1]*block_common_mode)
      ;; Compute standard dev off_source as a first easy and
      ;; better than nothing estimation, but estimate snr everywhere...
      snr[ikid,*] = abs(y/stddev(y[w]))
   endif
endfor

;; Iterate to derive a better snr
for ikid=0, nkids-1 do begin
   measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^param.snr_exp))
   fit1 = linfit( block_common_mode, toi[ikid,*], measure_error=measure_error)
   y = toi[ikid,*] - (fit1[0]+fit1[1]*block_common_mode)
   w = where( snr[ikid,*] le 5)
   snr[ikid,*] = smooth(abs(y/stddev(y[w])),5)
endfor

;; Build final common mode like in get_cm_sub_2 but
;; weighting with the current snr rather than the hard
;; coded kidpar.noise
new_common_mode = dblarr(nsn)
new_w8          = dblarr(nsn)
for ikid=0, nkids-1 do begin
   measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^param.snr_exp))
   fit1 = linfit( block_common_mode, toi[ikid,*], measure_error=measure_error)
   new_common_mode += (fit1[0] + fit1[1]*reform(toi[ikid,*]))/measure_error^2
   new_w8          += 1.d0/measure_error^2
endfor
wjunk = where( new_w8 le 0, nwjunk)
if nwjunk ne 0 then begin
   message, /info, "Hole in new_common_mode"
   stop
endif
new_common_mode /= new_w8

d = sqrt(kidpar.nas_x^2 + kidpar.nas_y^2)
ikid = (where(d eq min(d)))[0]
if param.do_plot eq 1 then begin
   ;; Now fit with SNR weight
   if param.plot_ps eq 0 then wind, 1, 1, /free, /large
   outplot, file=param.plot_dir+"/measure_error_common_mode", png=param.plot_png, ps=param.plot_ps
   my_multiplot, 1, 2, pp, pp1, /rev

   plot, block_common_mode, /xs, yra=minmax(block_common_mode), /ys, $
         position=pp1[0,*]
   fit = linfit( new_common_mode, block_common_mode)
   oplot, fit[0] + fit[1]*new_common_mode, col=250
   legendastro, ['param.k_snr '+strtrim(param.k_snr,2), $
                 'param.snr_exp '+strtrim(param.snr_exp,2)], /bottom
   legendastro, ['block_common_mode', 'new_common_mode (scaled)'], col=[0,250]

   w = where( off_source[ikid,*] eq 1 and (flag[ikid,*] eq 0 or flag[ikid,*] eq 2L^11), nw)
   measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^param.snr_exp))
   fit1 = linfit( new_common_mode, toi[ikid,*], measure_error=measure_error)
   fit  = linfit( block_common_mode[w], toi[ikid,w])
   fit2 = linfit( block_common_mode, toi[ikid,*], measure_error=measure_error)
   yra = minmax(toi[ikid,*])
   plot,  toi[ikid,*], /xs, position=pp1[1,*], /noerase, /ys, yra=yra
   oplot, (fit1[0] + fit1[1]*new_common_mode), col=250
   oplot, (fit[ 0] + fit[ 1]*block_common_mode), col=70
   loadct, 7
   oplot, fit2[0] + fit2[1]*block_common_mode, col=200
   loadct, 39
   z = 1./measure_error^2
   oplot, yra[0] + z/max(z)*(yra[1]-yra[0])/2., col=200
   oplot, yra[0] + off_source[ikid,*]*(yra[1]-yra[0])/2., col=150
   legendastro, ['off_soure CM', 'new_CM', $
                 '1/measure_error^2', 'off_source', 'off_source and measure_error'] , col=[70,250,200,150,40]
   legendastro, ['param.k_snr '+strtrim(param.k_snr,2), $
                 'param.snr_exp '+strtrim(param.snr_exp,2)], /bottom
   legendastro, 'Numdet '+strtrim(kidpar[ikid].numdet,2), /right
;   stop
endif

;; Add elevation like for all decorrelations
templates = transpose( [[new_common_mode], [elevation]])

;; Regress the common_mode and the data WITH MEASURE_ERROR
for ikid=0, nkids-1 do begin
   measure_error = reform( sqrt(1.+param.k_snr*snr[ikid,*]^2))
   coeff = regress( templates, reform( toi[ikid,*]), measure_error=measure_error, $
                    CHISQ= chi, CONST= const, CORRELATION= corr, $
                    /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status)
   yfit = dblarr(nsn) + const
   for ii=0, n_elements(coeff)-1 do yfit += coeff[ii]*templates[ii,*]
   ;; EA and LP: uncomment the line below
   toi[ikid,*] -= yfit
   common_mode[ikid,*] = yfit
endfor

if param.cpu_time then nk_show_cpu_time, param
  
end
