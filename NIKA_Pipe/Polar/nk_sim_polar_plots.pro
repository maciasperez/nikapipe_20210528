
pro nk_sim_polar_plots, param, kidpar, data, ps, data_in, test_toi, postscript=postscript, png=png, transp=transp

;; Useful quantities
nsn       = n_elements(data)
cos4omega = cos(4.*data.position)
sin4omega = sin(4.*data.position)
time      = dindgen(nsn)/ps.gen.nu_sampling

apod_frac = 0.05
make_hat_function, dindgen(nsn), apod_frac*nsn, (1-apod_frac)*nsn, apod_frac*nsn, apod_frac*nsn, taper, /force, /silent

for lambda=1, 2 do begin
   wkids = where( long( kidpar.array) eq lambda and kidpar.type eq 1, nwkids)
   if nwkids ne 0 then begin

      ikid = wkids[0]

      ;; Precompute map making lowpass filter
      delvarx, filter
      np_bandpass, dblarr(nsn), ps.gen.nu_sampling, y_out, $
                   freqlow=param.polar_lockin_freqlow, $
                   freqhigh=param.polar_lockin_freqhigh, delta_f=param.polar_lockin_delta_f, filter=filter

      ;; Perfect sky signal after the HWP
      nika_power_spec, /base, taper=taper, test_toi.sky_signal,           ps.gen.nu_sampling, pw_sky_signal,   freq
      nika_power_spec, taper=taper, (test_toi.sky_signal-my_baseline(test_toi.sky_signal))*cos4omega, ps.gen.nu_sampling, pw_sky_signal_q, freq

      ;; Sky noise
      nika_power_spec, /base, taper=taper, test_toi.sky_noise,           ps.gen.nu_sampling, pw_sky_noise
      nika_power_spec, taper=taper, (test_toi.sky_noise-my_baseline(test_toi.sky_noise))*cos4omega, ps.gen.nu_sampling, pw_sky_noise_q

      ;; Noise
      nika_power_spec, /base, taper=taper, test_toi.noise,           ps.gen.nu_sampling, pw_noise
      nika_power_spec, taper=taper, (test_toi.noise-my_baseline(test_toi.noise))*cos4omega, ps.gen.nu_sampling, pw_noise_q

      ;; Template
      nika_power_spec, /base, taper=taper, test_toi.template,           ps.gen.nu_sampling, pw_template
      nika_power_spec, taper=taper, (test_toi.template-my_baseline(test_toi.template))*cos4omega, ps.gen.nu_sampling, pw_template_q

      ;; Detector timeline
      nika_power_spec, /base, taper=taper, data.toi[ikid],           ps.gen.nu_sampling, pw_toi
      nika_power_spec, taper=taper, (data.toi[ikid]-my_baseline(data.toi[ikid]))*cos4omega, ps.gen.nu_sampling, pw_toi_q
      
      ;; Template residuals
      nika_power_spec, /base, taper=taper, test_toi.template - test_toi.template_fit, ps.gen.nu_sampling, pw_hwp_residual
      y = test_toi.template - test_toi.template_fit
      y = y - my_baseline(y)
      nika_power_spec, taper=taper, y*cos4omega, ps.gen.nu_sampling, pw_hwp_residual_q

      ;; Pointing of the reference detector
      nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                            kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                            0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                            nas_y_ref=kidpar[ikid].nas_center_Y      
      wsubscan = where( data.subscan eq data[nsn/2].subscan, nww) ; middle of the scan for margin
      i1 = min( wsubscan)
      i2 = max( wsubscan)
      dist = sqrt( (dra[i2]-dra[i1])^2 + (ddec[i2]-ddec[i1])^2)
      ds_dt = dist/(nww/ps.gen.nu_sampling) ; arcsec/s
      sigma_beam_t  = kidpar[ikid].fwhm*!fwhm2sigma/ds_dt
      sigma_beam_nu = 1.d0/(2.d0*!dpi*sigma_beam_t)

      beam_freq     = exp(-freq^2/(2.d0*sigma_beam_nu^2)) ; to show beam cutoff
      ;; This is the correct expression for beam_freq as it can be checked on a
      ;; ~flat input power spectrum such as diffuse_index=-1

      ;; approx subscan frequency
      f_subscan = ps.scan.n_subscans/(max(time)-min(time))/2.

      ;; Projected timelines
      if param.polar_do_lockin eq 1 then begin
         y = reform( data.toi[ikid]) ;; - my_baseline( data.toi[ikid]))
         np_bandpass, y,           ps.gen.nu_sampling, toi_proj_t, filter=filter
         np_bandpass, y*cos4omega, ps.gen.nu_sampling, toi_proj_q, filter=filter
         nika_power_spec, /base, taper=taper, toi_proj_t, ps.gen.nu_sampling, pw_toi_proj_t
         nika_power_spec, /base, taper=taper, toi_proj_q, ps.gen.nu_sampling, pw_toi_proj_q
      endif


      ;; Plots
      my_loadct, col
      units = "AU"
      col_sky_signal        = col.purple
      col_toi               = col.black
      col_noise             = col.blue
      col_sky_noise         = col.grey
      col_template          = col.darkgreen
      col_template_residual = col.red
      col_toi_proj          = col.green

      leg_txt = ['TOI', 'Sky signal', 'Noise', 'Sky Noise']
      leg_col = [col_toi, col_sky_signal, col_noise, col_sky_noise]
      if ps.gen.add_template ne 0 then begin
         leg_txt = [ leg_txt, 'Template', 'Template Residual']
         leg_col = [ leg_col, col_template, col_template_residual]
      endif

      time_range = [0,100]
      freq_range = [1e-3, max(freq)>50]
      
      ;; Beam amplitude on the plot
      a_beam = max( pw_sky_signal[where(freq ge f_subscan/2. and freq le f_subscan*1.5)])

      yra = minmax( [pw_toi, pw_sky_noise])*[1e-3, 1e3]
      wind, 1, 1, /free, xsize=1200, ysize=800
      plot_file = 'timelines'
      outplot, file=ps.gen.output_dir+"/"+plot_file, png=png, ps=postscript, transp=transp
      !p.multi=[0,1,2]
      plot_oo, freq, pw_toi, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
               /xs, xra=freq_range, yra=yra, /ys, /nodata
      oplot, freq, pw_toi, col=col_toi
      oplot, freq, pw_sky_signal, col=col_sky_signal
      oplot, freq, pw_noise, col=col_noise
      oplot, freq, pw_sky_noise, col=col_sky_noise
      oplot, freq, pw_template, col=col_template
      oplot, freq, pw_hwp_residual, col=col_template_residual
      oplot, freq, a_beam*beam_freq, line=2
      legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
      legendastro, [strtrim( lambda,2)+" mm", $
                    'Total power'], /right, box=0, chars=1.5
      legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec", $
                    'HWP rot. speed: '+strtrim( string( ps.hwp.nu_rot,format="(F3.1)"),2)+" Hz", $
                    'Az scan speed : '+strtrim( string(ps.scan.az_speed,format="(F4.1)"),2)+" arcsec/s"], box=0, /bottom

      ;; Beam amplitude on the plot
      a_beam = max( pw_sky_signal_q[where(freq ge f_subscan/2. and freq le f_subscan*1.5)])

      yra = minmax( [pw_toi_q, pw_sky_noise_q])*[1e-3, 1e3]
      plot_oo, freq, pw_toi_q, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
               /xs, xra=freq_range, yra=yra, /ys, /nodata
      oplot, freq, pw_toi_q, col=col_toi
      oplot, freq, pw_sky_signal_q, col=col_sky_signal
      oplot, freq, pw_noise_q, col=col_noise
      oplot, freq, pw_sky_noise_q, col=col_sky_noise
      oplot, freq, pw_template_q, col=col_template
      oplot, freq, pw_hwp_residual_q, col=col_template_residual
      oplot, freq, a_beam*beam_freq, line=2

      legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
      legendastro, [strtrim(lambda,2)+" mm", $
                    'S!d1!n timeline'], /right, box=0, chars=1.5
      legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec", $
                    'HWP rot. speed: '+strtrim( string( ps.hwp.nu_rot,format="(F3.1)"),2)+" Hz", $
                    'Az scan speed : '+strtrim( string(ps.scan.az_speed,format="(F4.1)"),2)+" arcsec/s"], box=0, /bottom
      !p.multi=0
      outplot, /close

   endif
endfor

;;!;;  leg_txt = ['Signal', 'Input TOI', 'Output TOI']
;;!;;  leg_col     = [col_signal, col_in_toi, col_out_toi]
;;!;;  ;;!p.multi=[0,1,3]
;;!;;  ;;plot,  time, signal, xra=time_range, /xs, xtitle='Time [sec]', ytitle=units
;;!;;  ;;oplot, time, signal, col=col_signal
;;!;;  
;;!;;  outplot, file=plot_dir+'/one_over_f_0', /png, /transp
;;!;;  plot_oo, freq, pw_signal, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
;;!;;           /xs, xra=freq_range, yra=[1e-6,1e1]*max(pw_signal), /ys, /nodata
;;!;;  oplot,   freq, pw_tl_ref, col=col_in_toi
;;!;;  outplot, /close, /pre
;;!;;  
;;!;;  outplot, file=plot_dir+'/one_over_f_1', /png, /transp
;;!;;  plot_oo, freq, pw_signal, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
;;!;;           /xs, xra=freq_range, yra=[1e-6,1e1]*max(pw_signal), /ys, /nodata
;;!;;  oplot,   freq, pw_tl_ref, col=col_in_toi
;;!;;  oplot,   freq, pw_signal, col=70
;;!;;  outplot, /close, /pre
;;!;;  
;;!;;  outplot, file=plot_dir+'/one_over_f_2', /png, /transp
;;!;;  plot_oo, freq, pw_signal, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
;;!;;           /xs, xra=freq_range, yra=[1e-6,1e1]*max(pw_signal), /ys, /nodata
;;!;;  oplot,   freq, pw_tl_ref, col=col_in_toi
;;!;;  oplot,   freq, pw_signal, col=70
;;!;;  oplot,   freq, pw_tl_ref_q, col=250
;;!;;  leg_txt = ['Signal (T+P) + Noise', 'Signal (T+P)', 'Demodulated']
;;!;;  leg_col = [0, 70, 250]
;;!;;  legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, /bottom, box=0, chars=1.5
;;!;;  outplot, /close, /pre
;;!;;  
;;!;;  
;;!;;  ;; oplot,   freq, pw_toi, col=col_out_toi
;;!;;  ;; oplot,   freq, beam_freq*pw_signal[1], col=col_beam, line=2
;;!;;  ;; if strupcase(method) eq "LOCKIN" then oplot,  [freq_max, freq_max], [1e-10,1e10], col=col.green, line=2, thick=2
;;!;;  ;; for i=1, 10 do oplot, i*[1,1]*nu_hwp, [1e-10,1e10]
;;!;;  ;; legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0, /bottom
;;!;;  ;; plot_oo, freq, pw_signal_q, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
;;!;;  ;;          /xs, xra=freq_range, yra=[1e-6,1e1]*max(pw_signal_q)
;;!;;  ;; oplot,   freq, pw_tl_ref_q, col=col_in_toi
;;!;;  ;; oplot,   freq, pw_signal_q, col=col_signal
;;!;;  ;; oplot,   freq, beam_freq*pw_signal_q[1], col=col_beam, line=2
;;!;;  ;; oplot,   freq, pw_toi_q, col=col_out_toi
;;!;;  ;; for i=1, 10 do begin
;;!;;  ;;    oplot, i*[1,1]*nu_hwp, [1e-10,1e10]
;;!;;  ;;    oplot, i*[1,1]*f_subscan, [1e-10,1e10], line=2
;;!;;  ;; endfor
;;!;;  ;; if strupcase(method) eq "LOCKIN" then oplot,  [freq_max, freq_max], [1e-10,1e10], col=col.green, line=2, thick=2
;;!;;  ;; legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0, /bottom
;;!;;  ;; legendastro, ['Beam FWHM: '+strtrim( string(kidpar[0].fwhm,format="(F4.1)"),2)+" arcsec", $
;;!;;  ;;               'HWP rot. speed: '+strtrim( string( nu_hwp,format="(F3.1)"),2)+" Hz", $
;;!;;  ;;               'Az scan speed : '+strtrim( string(az_speed,format="(F4.1)"),2)+" arcsec/s", $
;;!;;  ;;               'upgrade resolution : '+strtrim( long(upgrade_res_fact),2)], box=0
;;!;;  ;; outplot, /close
;;!;;  ;; stop
;;!;;  
;;!;;  ;; ;; Specific plot
;;!;;  ;; y = reform( stokes_in[*,0])
;;!;;  ;; y = y - my_baseline(y)
;;!;;  ;; power_spec, taper*y, nu_sampling, pw_t_only
;;!;;  ;; 
;;!;;  ;; y = cos(4*data.omega)*stokes_in[*,1] + sin(4*data.omega)*stokes_in[*,2]
;;!;;  ;; y = y - my_baseline(y)
;;!;;  ;; power_spec, taper*y, nu_sampling, pw_q_only
;;!;;  ;; 
;;!;;  ;; !p.multi=0
;;!;;  ;; outplot, file="t_and_p_log", /png, /transp
;;!;;  ;; plot_oo, freq, pw_t_only, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
;;!;;  ;;          /xs, xra=freq_range, yra=[1e-6,1e1]*max(pw_signal), /ys, /nodata
;;!;;  ;; oplot, freq, pw_t_only
;;!;;  ;; for i=1, 10 do oplot, i*[1,1]*f_subscan, [1e-10,1e10], line=2
;;!;;  ;; oplot, freq, pw_q_only, col=col.red
;;!;;  ;; oplot,   freq, beam_freq*pw_t_only[1], col=col_beam, line=2
;;!;;  ;; leg_col = [col.black, col.red]
;;!;;  ;; leg_txt = ['Temperature', 'Polarization']
;;!;;  ;; legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0, chars=1.5
;;!;;  ;; outplot, /close, /preview
;;!;;  ;; 
;;!;;  ;; outplot, file="t_and_p_lin", /png, /transp
;;!;;  ;; plot, freq, pw_t_only, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
;;!;;  ;;          /xs, xra=[-1,1]+4*nu_hwp, /ys, yra=minmax([pw_q_only])
;;!;;  ;; oplot, freq, pw_t_only
;;!;;  ;; for i=1, 10 do oplot, i*[1,1]*f_subscan, [1e-10,1e10], line=2
;;!;;  ;; oplot, freq, pw_q_only, col=col.red
;;!;;  ;; leg_col = [col.black, col.red]
;;!;;  ;; leg_txt = ['Temperature', 'Polarization']
;;!;;  ;; legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0, chars=1.5
;;!;;  ;; for i=1, 10 do oplot,  i*[1,1]*f_subscan+4*nu_hwp, [1e-10,1e10], line=2
;;!;;  ;; for i=1, 10 do oplot, -i*[1,1]*f_subscan+4*nu_hwp, [1e-10,1e10], line=2
;;!;;  ;; outplot, /close, /pre
;;!;;  ;; stop
;;!;;  
;;!;;  ;; Project maps
;;!;;  !nika.f_sampling = nu_sampling ;; patch
;;!;;  
;;!;;  data_copy = data
;;!;;  ;; Make co-add maps at the same time to show the difference between co-add and
;;!;;  ;; lock-in on the same input maps for the talk
;;!;;  param1 = param
;;!;;  param1.polar_map.method = "coadd"
;;!;;  nika_pipe_polar_maps, param1, data_copy, kidpar, $
;;!;;                        maps_S0_coadd, maps_S1_coadd, maps_S2_coadd, maps_covar_coadd, nhits_coadd, $
;;!;;                        xmap=xmap_out, ymap=ymap_out
;;!;;  
;;!;;  nx = n_elements( xmap_out[*,0])
;;!;;  ny = n_elements( xmap_out[0,*])
;;!;;  map_S0_coadd = reform( maps_S0_coadd[*,0], nx, ny)
;;!;;  map_S1_coadd = reform( maps_S1_coadd[*,0], nx, ny)
;;!;;  map_S2_coadd = reform( maps_S2_coadd[*,0], nx, ny)
;;!;;  
;;!;;  ;; lockin
;;!;;  nika_pipe_polar_maps, param, data, kidpar, $
;;!;;                        maps_S0, maps_S1, maps_S2, maps_covar, nhits, $
;;!;;                        xmap=xmap_out, ymap=ymap_out
;;!;;  map_S0 = reform( maps_S0[*,0], nx, ny)
;;!;;  map_S1 = reform( maps_S1[*,0], nx, ny)
;;!;;  map_S2 = reform( maps_S2[*,0], nx, ny)
;;!;;  map_hits   = reform( nhits[  *,0], nx, ny)
;;!;;  
;;!;;  w = where( finite(map_t))
;;!;;  t_ra = minmax(map_t[w])
;;!;;  q_ra = minmax(map_q[w])
;;!;;  u_ra = minmax(map_u[w])
;;!;;  
;;!;;  my_multiplot, 3, 4, pp, pp1, /rev, gap_x=0.1
;;!;;  if keyword_set(png) then begin
;;!;;     t_in_png  = plot_dir+"/t_in.png"
;;!;;     q_in_png  = plot_dir+"/q_in.png"
;;!;;     u_in_png  = plot_dir+"/u_in.png"
;;!;;     t_out_png = plot_dir+"/t_out.png"
;;!;;     q_out_png = plot_dir+"/q_out.png"
;;!;;     u_out_png = plot_dir+"/u_out.png"
;;!;;  
;;!;;     t_out_coadd_png = plot_dir+"/t_out_coadd.png"
;;!;;     q_out_coadd_png = plot_dir+"/q_out_coadd.png"
;;!;;     u_out_coadd_png = plot_dir+"/u_out_coadd.png"
;;!;;  
;;!;;     diff_t_png  = plot_dir+'/diff_s0.png'
;;!;;     diff_q_png  = plot_dir+'/diff_s1.png'
;;!;;     diff_u_png  = plot_dir+'/diff_s2.png'
;;!;;     diff_t1_png = plot_dir+'/diff_s0_1.png'
;;!;;     diff_q1_png = plot_dir+'/diff_s1_1.png'
;;!;;     diff_u1_png = plot_dir+'/diff_s2_1.png'
;;!;;  
;;!;;     diff_t1_coadd_png = plot_dir+'/diff_s0_coadd_1.png'
;;!;;     diff_q1_coadd_png = plot_dir+'/diff_s1_coadd_1.png'
;;!;;     diff_u1_coadd_png = plot_dir+'/diff_s2_coadd_1.png'
;;!;;  endif
;;!;;  
;;!;;  wind, 1, 1, /free, /large
;;!;;  erase
;;!;;  imview, map_t,  xmap=xmap_in,  ymap=ymap_in,  position=pp1[0,*], title='S0 in',  imrange=t_ra, /noerase, png=t_in_png
;;!;;  imview, map_q,  xmap=xmap_in,  ymap=ymap_in,  position=pp1[1,*], title='S1 in',  imrange=q_ra, /noerase, png=q_in_png
;;!;;  imview, map_u,  xmap=xmap_in,  ymap=ymap_in,  position=pp1[2,*], title='S2 in',  imrange=u_ra, /noerase, png=u_in_png
;;!;;  imview, map_S0, xmap=xmap_out, ymap=ymap_out, position=pp1[3,*], title='S0 out', imrange=t_ra, /noerase, png=t_out_png
;;!;;  imview, map_S1, xmap=xmap_out, ymap=ymap_out, position=pp1[4,*], title='S1 out', imrange=q_ra, /noerase, png=q_out_png
;;!;;  imview, map_S2, xmap=xmap_out, ymap=ymap_out, position=pp1[5,*], title='S2 out', imrange=u_ra, /noerase, png=u_out_png
;;!;;  
;;!;;  imview, map_S0_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[3,*], title='S0 out', imrange=t_ra, /noerase, png=t_out_coadd_png
;;!;;  imview, map_S1_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[4,*], title='S1 out', imrange=q_ra, /noerase, png=q_out_coadd_png
;;!;;  imview, map_S2_coadd, xmap=xmap_out, ymap=ymap_out, position=pp1[5,*], title='S2 out', imrange=u_ra, /noerase, png=u_out_coadd_png
;;!;;  
;;!;;  ;; Differences with the original color scale
;;!;;  if n_elements(xmap_in) eq n_elements(xmap_out) then begin
;;!;;     map_diff = map_t*0.
;;!;;     w = where( finite(map_S0) eq 1)
;;!;;     map_diff[w] = map_t[w]-map_S0[w]
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[6,*], title='T in - out', imrange=t_ra, /noerase, png=diff_t_png
;;!;;  
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = map_q[w]-map_S1[w]
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[7,*], title='Q in - out', imrange=q_ra, /noerase, png=diff_q_png
;;!;;  
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = map_u[w]-map_S2[w]
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[8,*], title='U in - out', imrange=u_ra, /noerase, png=diff_u_png
;;!;;  
;;!;;  ;; specific color scales
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = (map_t[w]-map_S0[w])/stddev(map_t[w])
;;!;;     imrange = [-3,3]*stddev(map_diff[w])
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[9,*], title='(T!din!n - T!dout!n)/!7r!3(T!din!n)', imrange=imrange, /noerase, png=diff_t1_png
;;!;;  
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = (map_q[w]-map_S1[w])/stddev(map_q[w])
;;!;;     imrange = [-3,3]*stddev(map_diff[w])
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[10,*], title='(Q!din!n - Q!dout!n)/!7r!3(Q!din!n)', imrange=imrange, /noerase, png=diff_q1_png
;;!;;  
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = (map_u[w]-map_S2[w])/stddev(map_u[w])
;;!;;     imrange = [-3,3]*stddev(map_diff[w])
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[11,*], title='(U!din!n - U!dout!n)/!7r!3(U!din!n)', imrange=imrange, /noerase, png=diff_u1_png
;;!;;  
;;!;;  ;; specific color scales (coadd)
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = (map_t[w]-map_S0_coadd[w])/stddev(map_t[w])
;;!;;     imrange = [-3,3]*stddev(map_diff[w])
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[9,*], title='(T!din!n - T!dout!n)/!7r!3(T!din!n)', imrange=imrange, /noerase, png=diff_t1_coadd_png
;;!;;  
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = (map_q[w]-map_S1_coadd[w])/stddev(map_q[w])
;;!;;     imrange = [-3,3]*stddev(map_diff[w])
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[10,*], title='(Q!din!n - Q!dout!n)/!7r!3(Q!din!n)', imrange=imrange, /noerase, png=diff_q1_coadd_png
;;!;;  
;;!;;     map_diff = map_t*0. + !values.d_nan
;;!;;     map_diff[w] = (map_u[w]-map_S2_coadd[w])/stddev(map_u[w])
;;!;;     imrange = [-3,3]*stddev(map_diff[w])
;;!;;     imview, map_diff, xmap=xmap_out, ymap=ymap_out, position=pp1[11,*], title='(U!din!n - U!dout!n)/!7r!3(U!din!n)', imrange=imrange, /noerase, png=diff_u1_coadd_png
;;!;;  endif else begin
;;!;;     print, ""
;;!;;     print, "Need to rebin, but careful to the interpretation of the differences then..."
;;!;;  endelse
;;!;;  
;;!;;  ;; ;; Stats
;;!;;  ;; w = where( map_hits gt median( map_hits), nw)
;;!;;  ;; wind, 1, 1, /free, /large
;;!;;  ;; n_histwork, map_t[w]-map_S0[w], /fill, title='S0!din!n - S0!dout!n', position=pp1[0,*]
;;!;;  ;; n_histwork, map_q[w]-map_S1[w], /fill, title='S1!din!n - S1!dout!n', position=pp1[1,*], /noerase
;;!;;  ;; n_histwork, map_u[w]-map_S2[w], /fill, title='S2!din!n - S2!dout!n', position=pp1[2,*], /noerase
;;!;; endif
;;!;; endfor


end
