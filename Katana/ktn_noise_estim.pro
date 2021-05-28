
;; Look for the two most quiet minutes for noise estimation and take the average
;; value above 4Hz.
;;----------------------------------------------------------------------------

pro ktn_noise_estim

common ktn_common

n_2mn = 2*60.*!nika.f_sampling
nsn_noise = 2L^round( alog(n_2mn)/alog(2))
my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1
for lambda = 1, 2 do begin
   wk   = where( kidpar.type eq 1 and kidpar.array eq lambda, nwk)
   
   if nwk ne 0 then begin
      noise_spec = dblarr( nwk, nsn_noise/2)

      for i=0, nwk-1 do begin
         ikid = wk[i]
         rms  = 1e10
         ixp  = 0
         while (ixp+nsn_noise-1) lt disp.nsn do begin
            d = reform( data[ixp:ixp+nsn_noise-1].toi[ikid])
            if stddev(d) lt rms then ix1 = ixp
            ixp += nsn_noise
         endwhile
         
         power_spec, data[ix1:ix1+nsn_noise-1].toi[ikid] - $
                     my_baseline( data[ix1:ix1+nsn_noise-1].toi[ikid]), !nika.f_sampling, pw, freq
         ;;wf = (where( abs(freq-sys_info.nu_noise_ref) eq min( abs(freq-sys_info.nu_noise_ref))))[0]
         wf = where( freq gt 4.d0)
         kidpar[ikid].noise = avg(pw[wf]) ; Hz/sqrt(Hz) since data is in Hz

         wf = where( abs(freq-1.d0) lt 0.2, nwf)
         if nwf ne 0 then kidpar[ikid].noise_1hz = avg(pw[wf])
         wf = where( abs(freq-2.d0) lt 0.2, nwf)
         if nwf ne 0 then kidpar[ikid].noise_2hz = avg(pw[wf])
         wf = where( abs(freq-10.d0) lt 1, nwf)
         if nwf ne 0 then kidpar[ikid].noise_10hz = avg(pw[wf])

      endfor
   endif
endfor

;; Derive sensitivity
kidpar.sensitivity_decorr  = kidpar.calib * kidpar.noise * 1000 ; Jy/Hz x Hz/sqrt(Hz) x 1000 = mJy/sqrt(Hz) x 1
kidpar.sensitivity_decorr /= sqrt(2.d0) ; /Hz^1/2 to s^1/2

;; Estimate median sensitivity and its associated error: look for 68% of
;; sensitivities around the median
wplot = where( kidpar.plot_flag eq 0, nwplot)
if nwplot eq 0 then begin
   message, /info, "No valid plot with plot_flag eq 0"
   stop
endif
sys_info.avg_noise         = median( kidpar[wplot].noise)    ; Hz/Sqrt(Hz)
sys_info.sigma_noise       = stddev( kidpar[wplot].noise)    ; Hz/Sqrt(Hz)

med = median( kidpar[wplot].sensitivity_decorr)
np_histo, abs( kidpar[wplot].sensitivity_decorr-med), xhist, yhist, /noplot
keep = where(finite(xhist))
xhist = xhist[keep]
yhist = yhist[keep]
t_cumul = total( yhist, /cumul)/total(yhist)
err_sensit = xhist[min(where(t_cumul ge 0.68))]

if kidpar[wplot[0]].array eq 1 then fwhm_nominal=12. else fwhm_nominal=17.
ndet_per_beam = (fwhm_nominal/disp.delta)^2

sys_info.avg_sensitivity_decorr   = med       /sqrt(ndet_per_beam)        ; mJy.sqrt(s)
sys_info.sigma_sensitivity_decorr = err_sensit/sqrt(ndet_per_beam) ; mJy.sqrt(s)

end
