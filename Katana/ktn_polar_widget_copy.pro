


PRO ktn_polar_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue

  w1  = where( kidpar.type eq 1, nw1)
  w3  = where( kidpar.type eq 3, nw3)
  w13 = where( kidpar.type eq 1 or kidpar.type eq 3, nw13)

  do_test       = 0
  apply_to_data = 0

  CASE uvalue OF

     'quit': begin
        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end

     'nu_rot':param.polar.nu_rot_hwp = double( Textbox( title='HWP rot. Freq.', group_leader=ev.top, cancel=cancelled))

     'n_harmonics': begin
        param.polar.n_template_harmonics = long( Textbox( title='N Harmonics', group_leader=ev.top, cancel=cancelled))
        do_test = 1
     end

     'apply': apply_to_data = 1

  Endcase

  if do_test eq 1 then begin
     print, "param.polar.n_template_harmonics: ", param.polar.n_template_harmonics

     nsn  = n_elements(data)
     time = dindgen(nsn)/!nika.f_sampling
     ikid = w1[0]
     nsn_test = (2L^15) < nsn

     ;; Subract template and look at timelines and power spectra
     ;; Take a smaller data subset to save time
     junk = data[0:nsn_test-1]

     ;; only one kid for this quicklook
     junk_kidpar = kidpar
     junk_kidpar.type = 0
     junk_kidpar[w1[0]].type = 1

     ;; Pointing of the reference detector
     nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                           kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                           0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                           nas_y_ref=kidpar[ikid].nas_center_Y      
     wsubscan = where( data.subscan eq data[nsn_test/2].subscan, nww) ; middle of the scan for margin
     i1 = min( wsubscan)
     i2 = max( wsubscan)
     dist = sqrt( (dra[i2]-dra[i1])^2 + (ddec[i2]-ddec[i1])^2)
     ds_dt = dist/(nww/!nika.f_sampling) ; arcsec/s
     sigma_beam_t  = kidpar[ikid].fwhm*!fwhm2sigma/ds_dt
     sigma_beam_nu = 1.d0/(2.d0*!dpi*sigma_beam_t)
     n_subscans = max(data.subscan) - min(data.subscan) + 1
     f_subscan  = n_subscans/(max(time)-min(time))/2.

     
     ;;------------------------
     ;; Remove the low freq due to atmosphere and noise to make template
     ;; estimation easier
;     y = junk.toi[ikid]
;     np_bandpass, y-my_baseline(y), !nika.f_sampling, s_out, freqhigh=f_subscan/2.
;     junk.toi[ikid] = s_out
     ;;------------------------

     nika_pipe_hwp_rm, param, junk_kidpar, junk, junk_fit

     apod_frac = 0.05
     make_hat_function, dindgen(nsn_test), apod_frac*nsn_test, (1-apod_frac)*nsn_test, apod_frac*nsn_test, apod_frac*nsn_test, taper, /force, /silent

     ;; Input signal
     y = data[0:nsn_test-1].toi[ikid]
     cos4omega = cos( data[0:nsn_test-1].omega)
     nika_power_spec, /base, taper=taper, y,           !nika.f_sampling, pw_toi_in,   freq
     nika_power_spec, /base, taper=taper, y*cos4omega, !nika.f_sampling, pw_toi_in_q, freq

     ;; Output signal
     cos4omega = cos(4.*junk.omega)
     nika_power_spec, /base, taper=taper, junk.toi[ikid],           !nika.f_sampling, pw_toi_out,   freq
     nika_power_spec, /base, taper=taper, junk.toi[ikid]*cos4omega, !nika.f_sampling, pw_toi_out_q, freq


     beam_freq     = exp(-freq^2/(2.d0*sigma_beam_nu^2)) ; to show beam cutoff

     units = "AU"
     col_toi = !p.color
     col_out = 250
     leg_txt = ['Input TOI', 'Output TOI', 'N harmonics = '+strtrim( param.polar.n_template_harmonics, 2)]
     leg_col = [col_toi, col_out, col_toi]

     time_range = minmax( time[0:nsn_test-1])
     freq_range = [1e-3, max(freq)>50]
     
     ;; Beam amplitude on the plot
     a_beam = max( pw_toi_in[where(freq ge f_subscan/2. and freq le f_subscan*1.5)])

     yra = minmax( pw_toi_in)*[1e-3, 1e3]
     ;;wind, 1, 1, /free, xsize=1000, ysize=800
     plot_file = 'timelines'
     ;;outplot, file=ps.gen.output_dir+"/"+plot_file, png=png, ps=postscript, transp=transp
     !p.multi=[0,1,2]
     plot_oo, freq, pw_toi_in, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
              /xs, xra=freq_range, yra=yra, /ys, /nodata
     oplot, freq, pw_toi_in,  col=col_toi
     oplot, freq, pw_toi_out, col=col_out
     legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
     legendastro, [strtrim( long(kidpar[ikid].lambda),2)+" mm", $
                   'Total power'], /right, box=0, chars=1.5
     legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec"], box=0, /bottom

     ;; Beam amplitude on the plot
     a_beam = max( pw_toi_in_q[where(freq ge f_subscan/2. and freq le f_subscan*1.5)])
     yra = minmax( pw_toi_in_q)*[1e-3, 1e3]
     plot_oo, freq, pw_toi_in_q, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
              /xs, xra=freq_range, yra=yra, /ys, /nodata
     oplot, freq, pw_toi_in_q,  col=col_toi
     oplot, freq, pw_toi_out_q, col=col_out
     legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
     legendastro, [strtrim( long(kidpar[ikid].lambda),2)+" mm", $
                   'S!d1!n timeline'], /right, box=0, chars=1.5
     legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec"], box=0, /bottom
     !p.multi=0

     ;;outplot, /close
  endif

  if apply_to_data eq 1 then begin
     nika_pipe_hwp_rm, param, kidpar, data
     message, /info, "done."
  endif

  exit:
end


pro ktn_polar_widget, no_block=no_block

  common ktn_common
  

  ;; Plot
  nsn  = n_elements(data)
  time = dindgen(nsn)/!nika.f_sampling
  w1 = where( kidpar.type eq 1, nw1)
  ikid = w1[0]
  nsn_test = (2L^15) < nsn

  ;; Subract template and look at timelines and power spectra
  ;; Take a smaller data subset to save time
  junk = data[0:nsn_test-1].toi[ikid]

  apod_frac = 0.05
  make_hat_function, dindgen(nsn_test), apod_frac*nsn_test, (1-apod_frac)*nsn_test, apod_frac*nsn_test, apod_frac*nsn_test, taper, /force, /silent

  ;; Input signal for quicklook
  y = junk - my_baseline(junk)
  cos4omega = cos( data[0:nsn_test-1].omega)
  nika_power_spec, /base, taper=taper, y,           !nika.f_sampling, pw_junk_in,   freq
  nika_power_spec, /base, taper=taper, y*cos4omega, !nika.f_sampling, pw_junk_in_q, freq

  freq_range = [1e-3, max(freq)>50]
     
  units = "AU"
  yra = minmax( pw_junk_in)*[1e-3, 1e3]
  wind, 1, 1, /free, xsize=1000, ysize=800
  !p.multi=[0,1,2]
  plot_oo, freq, pw_junk_in, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
           /xs, xra=freq_range, yra=yra, /ys, /nodata
  oplot, freq, pw_junk_in,  col=col_junk
  legendastro, [strtrim( long(kidpar[ikid].lambda),2)+" mm", $
                'Total power'], /right, box=0, chars=1.5

  yra = minmax( pw_junk_in_q)*[1e-3, 1e3]
  plot_oo, freq, pw_junk_in_q, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
           /xs, xra=freq_range, yra=yra, /ys, /nodata
  oplot, freq, pw_junk_in_q,  col=col_junk
  !p.multi=0
   
  ;;============================================================================
  ;;================================ Create the widget =========================
  ;;============================================================================
  ;; Start widget
  main = widget_base(title='Polarization', /row, /frame)

;;   ;; Number of buttons etc... to be updated manually for now
;;   if keyword_set(check_list) then begin
;;      n_buttons_x = 8+3
;;      n_buttons_y = 20 ; 19
;;   endif else begin
;;      n_buttons_x = 8
;;      n_buttons_y = 17 ; 16
;;   endelse
  xs_commands = !screen_size[0]*0.5
  ys_commands = !screen_size[1]*0.7

  xs_def = 200 ; long( xs_commands/n_buttons_x)
  ys_def = 100 ; long( ys_commands/n_buttons_y)

  commands = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

  comm = widget_base( commands, /row, /frame)
  b = widget_button( comm, uvalue='nu_rot',      value=np_cbb( 'HWP rot. freq', bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm, uvalue='n_harmonics', value=np_cbb( 'N harmonics',   bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm, uvalue='apply',       value=np_cbb( 'Apply to data', bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm, uvalue='quit',        value=np_cbb( 'Quit',          bg='firebrick', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  xoff = long( !screen_size[0]-xs_commands*1.2)  
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands ;; creates the widgets
  xmanager, 'ktn_polar', main, no_block=no_block


end
