
pro nk_deal_with_hwp_template, param, info, data, kidpar, y, y1, $
                               hwpss=hwpss

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, " nk_deal_with_hwp_template, param, info, data, kidpar, y, y1, $"
   print, "                            hwpss=hwpss"
   return
endif

if param.cpu_time then param.cpu_t0 = systime(0, /sec)

if param.lab_polar eq 1 then return

;; ;; if not specified, filter just before the next harmonics of the
;; ;; HWP rotation
;; if param.polar_lockin_freqhigh le 0 then param.polar_lockin_freqhigh = 0.99*info.hwp_rot_freq
   
;; Subtract HWP parasitic signal   
w1 = where(kidpar.array eq 1 and kidpar.type eq 1)

;; Copy of toi before subtraction for monitoring plots
nsn = n_elements(data)
y   = dblarr(3,nsn)
for iarray=1, 3 do begin
   ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
   y[iarray-1,*] = data.toi[ikid]
endfor

;; Subtract HWP beta
w1 = where( kidpar.type eq 1)
if param.force_subtract_hwp_per_subscan eq 1 then begin

   if param.debug then begin
      data_copy = data
   endif

   hwpss = {t:dblarr(n_elements(kidpar))}
   hwpss = replicate( hwpss, nsn)

   for isubscan=min(data.subscan), max(data.subscan) do begin
      wsubscan = where( data.subscan eq isubscan, nwsubscan)
      data1 = data[wsubscan]
      doplot = 0
      if param.debug  and (isubscan eq (min(data.subscan)+2)) then doplot=1
      nk_hwp_rm_4, param, info, data1, kidpar, $
                   plot=doplot, debug=param.debug, hwpss=hwpss_temp
      
      data[wsubscan].toi[w1] = data1.toi[w1]
      hwpss[wsubscan].t[w1]  = hwpss_temp
   endfor

   if param.debug then np_check_hwp_plots, param, info, data, kidpar, data_copy
   
endif else begin
   nk_hwp_rm_3, param, info, data, kidpar, new_fit=new_fit
   hwpss = {t:dblarr(n_elements(kidpar))}
   hwpss = replicate( hwpss, n_elements(data))
   hwpss.t[w1] = new_fit
endelse

;; The exact size of data is changed to match entire rotation periods
;; of the HWP
nsn = n_elements(data)
y1  = dblarr(3,nsn)

;; Copy of toi after subtraction for monitoring plots
nsn = n_elements(data)
y1  = dblarr(3,nsn)
for iarray=1, 3 do begin
   ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
   y1[iarray-1,*] = data.toi[ikid]
endfor

;; ;; Choose a kid on one of the 1mm arrays to make sure it sees polarization
;; loadct,  39, /silent
;; if param.do_plot ne 0 then begin
;;    power_spec, ycopy - my_baseline(ycopy), !nika.f_sampling, pw, freq
;;    power_spec, data.toi[ikid]      - my_baseline(data.toi[ikid]),      !nika.f_sampling, pw1, freq
;;    if param.plot_ps eq 0 then wind,  1,  1, /free, /xlarge, title = 'nk_deal_with_template', iconic = param.iconic
;;    outplot,  file = param.plot_dir+"/hwp_rm_"+strtrim(param.scan, 2),  png = param.plot_png, ps = param.plot_ps
;;    plot_oo, freq, pw, /xs, xtitle = 'Hz'
;;    for i = 1, 10 do oplot, [i, i]*info.hwp_rot_freq, [1e-10, 1e10], col = 70, line = 2
;;    oplot,   freq, pw1, col = 250, thick=2
;;    legendastro, ["Numdet: "+strtrim(kidpar[ikid].numdet, 2), $
;;                  "Raw data",  $
;;                  "HWP rm"], textcol = [0, 0, 250], box = 0, chars = 2
;;    nika_title, info, /ut, /az, /el, /scan
;;    outplot,  /close
;; endif

;;-------------------------------
;; Feb. 17th, 2019: NP
;; comment this out, it should be useless (already done at the end of
;; nk_getdata). It was there for an old version of nk_hwp_rm that used
;; to truncate the data to entire periods of the HWP. It's not
;; done any more and we here take the risk to have toi_copy of a
;; different size than hwpss.t
;; 
;; ;; Ensure prime numbers for future Fourier transforms in the lockin
;; ;; procedure
;; nsn     = n_elements(data)
;; nsn_max = test_primenumber(nsn)
;; data    = temporary( data[0:nsn_max-1])
;;-------------------------------

end
