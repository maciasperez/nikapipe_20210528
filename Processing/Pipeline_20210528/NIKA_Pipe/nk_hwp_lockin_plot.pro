
pro nk_hwp_lockin_plot, param, info, data, kidpar, y, y1

if param.do_plot ne 0 and n_elements( y) gt 10 then begin
   if param.rta eq 1 then begin
      my_multiplot, 1, 3, pp, pp1, /rev, /full, /dry, $
                    xmin=0.05, xmargin=0.01, xmax=0.55
      wind, 1, 1, /free, /large, iconic=param.iconic
      !nika.plot_window[1] = !d.window
   endif else begin
      if param.plot_ps eq 0 then wind, 1, 1, /free, /large, iconic=param.iconic
      my_multiplot, 1, 3, pp, pp1, /rev, gap_y=0.05
      outplot, file=param.plot_dir+'/nika_polar_pw', ps=param.plot_ps, png=param.plot_png
   endelse

   
   for iarray=1, 3 do begin
      ;; y and y1 do not have exactly the same size after data has
      ;; passed through nk_hwp_rm_3 to match entire periods of the
      ;; HWP rotation.
      charsize = 0.6
      if iarray eq 3 then xcharsize=charsize else xcharsize=1d-10

      power_spec, y[iarray-1,*]-my_baseline(y[iarray-1,*], base_frac=0.01), !nika.f_sampling, pw1, freq1
      power_spec, y1[iarray-1,*]-my_baseline(y1[iarray-1,*],base_frac=0.01), !nika.f_sampling, pw,  freq
      ikid = where( kidpar.numdet eq !nika.ref_det[iarray-1])
      power_spec, data.toi_q[ikid]-my_baseline(data.toi_q[ikid],base_frac=0.1), !nika.f_sampling, pw_q, freq_q

      beam_tf_ampl = 100*avg(pw[where(freq ge 4)])
      f = dindgen(1000)/999*(max(freq)-min(freq)) + min(freq)
      sigma_t = !nika.fwhm_nom[0]*!fwhm2sigma/info.median_scan_speed
      sigma_k = 1.0d0/(2.0d0*!dpi*sigma_t)
      
      plot_oo, freq1, pw1, /xs, xtitle='Hz', ytitle='Jy/Beam.Hz!u-1/2!n', $
               position=pp1[iarray-1,*], /noerase, charsize=charsize, $
               xcharsize=xcharsize
      if iarray eq 1 then nika_title, info, /ut, /az, /el, /scan
      oplot, freq, pw, col = 200
      oplot, freq_q, pw_q, col=250
      oplot, f, beam_tf_ampl*exp(-f^2/(2.0d0*sigma_k^2)), col=70
      oplot, f, beam_tf_ampl*exp(-(f-4*info.hwp_rot_freq)^2/(2.0d0*sigma_k^2)), col=70
      
      legendastro, ['Raw data', 'Raw data - HWP systematics', $
                    'Q timeline'], col=[!p.color, 200, 250], box=0, /bottom, line=0
      legendastro, ['A'+strtrim(iarray,2), $
                    'Numdet '+strtrim(!nika.ref_det[iarray-1],2)]
   endfor
   outplot,/close

endif

end
