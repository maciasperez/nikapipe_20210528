
pro bt_decorr

common bt_maps_common

;; reinit timelines
data.rf_didq = toi_med

;;time = dindgen( disp.nsn)/!nika.f_sampling/60.
disp.time_min = disp.time_min > 0
disp.time_max = disp.time_max < max(time)
w = where( time ge disp.time_min and time le disp.time_max, nw)
power_spec, dindgen(nw), !nika.f_sampling, pw, freq
pw     = dblarr( disp.nkids, n_elements(freq))
pw_raw = pw
if disp.do_decorr_filter eq 1 then begin
   delvarx, filter
   np_bandpass, dblarr(nw), !nika.f_sampling, freqlow=disp.freq_min, freqhigh=disp.freq_max, filter=filter
endif

for ikid=0, disp.nkids-1 do begin
   percent_status, ikid, disp.nkids, 10, title='Decorrelation', /bar
   if kidpar[ikid].plot_flag eq 0 then begin
      do_decorr_display = 1
      operations.decorr = 1

      ;; Raw power spectra
      power_spec, toi_med[ikid,w]-my_baseline( toi_med[ikid,w]), !nika.f_sampling, pw1, freq
      pw_raw[ikid,*] = reform(pw1)

      ;; Build decorrelation template
      wt = where( kidpar.in_decorr_template eq 1 and kidpar.numdet ne kidpar[ikid].numdet, nwt)
      if nwt eq 0 then begin
         message, "No valid kid in the decorrelation template ?!"
      endif else begin
         if disp.do_decorr_filter eq 1 then begin
            junk = data[w].rf_didq[wt]                 
            np_bandpass, junk, !nika.f_sampling, dummy, filter=filter
            templates = dummy
         endif else begin
            templates = data[w].rf_didq[wt]
         endelse
      endelse
      
      ;; filter data
      if disp.do_decorr_filter eq 1 then begin
         np_bandpass, data[w].rf_didq[ikid]-my_baseline(data[w].rf_didq[ikid]), !nika.f_sampling, y_data, filter=filter
      endif else begin
         y_data = data[w].rf_didq[ikid]
      endelse
      
      ;; compute coeffs
      c = regress( templates, reform(y_data,nw), /double, const=const)
      
      ;; Apply the coeffs to the full timeline
      yfit = dblarr(disp.nsn) + const
      for i=0, n_elements(c)-1 do yfit += c[i]*data.rf_didq[wt[i]]
      data.rf_didq[ikid] -= yfit
      
      ;; Compute the power spec on [time_min time_max]
      power_spec, data[w].rf_didq[ikid] - my_baseline( data[w].rf_didq[ikid]), !nika.f_sampling, pw1, freq
      pw[ikid,*] = reform(pw1)
   endif
endfor


for ikid=0, disp.nkids-1 do begin
   if kidpar[ikid].plot_flag eq 0 then begin
      kidpar[ikid].noise        = avg( pw[ikid,*])                                     ; Hz/sqrt(Hz)
      kidpar[ikid].response     = 1000.*sys_info.t_planet/kidpar[ikid].a_peak          ; mK/Hz
      kidpar[ikid].sensitivity_decorr = kidpar[ikid].noise* kidpar[ikid].response      ; Hz/sqrt(Hz) x mK/Hz = mK/sqrt(Hz)
   endif
endfor


end
