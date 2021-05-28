
pro ktn_polar_plot
  common ktn_common


w1    = where( kidpar.type eq 1, nw1)
w3    = where( kidpar.type eq 3, nw3)
nsn   = n_elements(data)
time  = dindgen(nsn)/!nika.f_sampling
ikid  = pwc.ikid

;; Subract template and look at timelines and power spectra
;; Take a smaller data subset to save time                                                                                                              
junk = data[0:pwc.nsn_test-1]

;; only one kid for this quicklook                                                                                                                      
junk_kidpar = kidpar
junk_kidpar.type = 0
junk_kidpar[ikid].type = 1
nika_pipe_hwp_rm, param, junk_kidpar, junk, junk_fit

apod_frac = 0.05
make_hat_function, dindgen(pwc.nsn_test), apod_frac*pwc.nsn_test, $
                   (1-apod_frac)*pwc.nsn_test, apod_frac*pwc.nsn_test, apod_frac*pwc.nsn_test, taper, /force, /silent


baseline = 0
taper    = 0
;; Input signal
y         = data[0:pwc.nsn_test-1].toi[ikid]
cos4omega = cos( 4*data[0:pwc.nsn_test-1].c_position)
nika_power_spec, baseline=baseline, taper=taper, y,           !nika.f_sampling, pw_toi_in,   freq
nika_power_spec, baseline=baseline, taper=taper, y*cos4omega, !nika.f_sampling, pw_toi_in_q, freq

;; Output signal                                                                                                                                        
nika_power_spec, baseline=baseline, taper=taper, junk.toi[ikid],                        !nika.f_sampling, pw_toi_out,   freq
nika_power_spec, baseline=baseline, taper=taper, junk.toi[ikid]*cos(4*junk.c_position), !nika.f_sampling, pw_toi_out_q, freq

beam_freq     = exp(-freq^2/(2.d0*pwc.sigma_beam_nu^2)) ; to show beam cutoff                                                                               

units = "AU"
col_toi = !p.color
col_out = 250
leg_txt = ['Input TOI', 'Output TOI', $
           'HWP rot freq = '+num2string(param.polar.nu_rot_hwp), $
           'N harmonics = '+strtrim( param.polar.n_template_harmonics, 2)]
leg_col = [col_toi, col_out, col_toi, col_toi]

time_range = minmax( time[0:pwc.nsn_test-1])
freq_range = [1e-3, max(freq)]

;; Beam amplitude on the plot                                                                                                                           
a_beam = max( pw_toi_in[where(freq ge pwc.f_subscan/2. and freq le pwc.f_subscan*1.5)])

yra = minmax( pw_toi_in)*[1e-3, 1e3]
wset, pwc.drawID1
!p.multi=[0,1,3]
plot, freq, pw_toi_in, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
      /xs, xra=freq_range, yra=yra, /ys, /nodata, /ylog
oplot, freq, pw_toi_in,  col=col_toi
oplot, freq, pw_toi_out, col=col_out
for i=0, 10 do begin
   oplot, [i,i]*param.polar.nu_rot_hwp, [1e-10,1e20], line=2, col=70
   xyouts, i*param.polar.nu_rot_hwp, max(yra)*0.9, strtrim(i,2), col=70
endfor
legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
legendastro, [strtrim( kidpar[ikid].array,2)+" mm", $
              'T'], /right, box=0, chars=1.5
legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec"], box=0, /bottom

;; Beam amplitude on the plot                                                                                                                           
a_beam = max( pw_toi_in_q[where(freq ge pwc.f_subscan/2. and freq le pwc.f_subscan*1.5)])
yra = minmax( pw_toi_in_q)*[1e-3, 1e3]
plot, freq, pw_toi_in_q, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
      /xs, xra=freq_range, yra=yra, /ys, /nodata, /ylog
oplot, freq, pw_toi_in_q,  col=col_toi
oplot, freq, pw_toi_out_q, col=col_out
for i=0, 10 do begin
   oplot, [i,i]*param.polar.nu_rot_hwp, [1e-10,1e20], line=2, col=70
   xyouts, i*param.polar.nu_rot_hwp, max(yra)/10., strtrim(i,2), col=70
endfor
legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
legendastro, [strtrim( kidpar[ikid].array,2)+" mm", $
              'Numdet '+strtrim( kidpar[ikid].numdet,2), $
              'S!d1!n'], /right, box=0, chars=1.5
legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec"], box=0, /bottom

plot, freq, pw_toi_in_q, xtitle='Frequency [Hz]', ytitle=units+'.Hz!u-1/2!n', $
      /xs, xra=freq_range, yra=yra, /ys, /nodata, /ylog, /xlog
oplot, freq, pw_toi_in_q,  col=col_toi
oplot, freq, pw_toi_out_q, col=col_out
for i=0, 10 do begin
   oplot, [i,i]*param.polar.nu_rot_hwp, [1e-10,1e20], line=2, col=70
   xyouts, i*param.polar.nu_rot_hwp, max(yra)/10., strtrim(i,2), col=70
endfor
legendastro, leg_txt, col=leg_col, textcol=leg_col, line=0, box=0
legendastro, [strtrim( kidpar[ikid].array,2)+" mm", $
              'Numdet '+strtrim( kidpar[ikid].numdet,2), $
              'S!d1!n'], /right, box=0, chars=1.5
legendastro, ['Beam FWHM: '+strtrim( string(kidpar[ikid].fwhm,format="(F4.1)"),2)+" arcsec"], box=0, /bottom
!p.multi=0
     
;;outplot, /close                                                                                                                                       
end


pro ktn_polar_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue
  
  do_test       = 0
  apply_to_data = 0
  print, "uvalue = ", uvalue
  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end
        
        'nu_rot': begin
           param.polar.nu_rot_hwp = double( Textbox( title='HWP rot. Freq.', group_leader=ev.top, cancel=cancelled))
           do_test = 1
        end
        
        'n_harmonics': begin
           param.polar.n_template_harmonics = long( Textbox( title='N Harmonics', group_leader=ev.top, cancel=cancelled))
           do_test = 1
        end
        
        'apply': apply_to_data = 1

        ;; 'slide_ikid':begin
        ;;    pwc.ikid = long(ev.value)
        ;;    do_test = 1
        ;; end
        
        "ikid":begin
           pwc.ikid = long( Textbox( title='Ikid', group_leader=ev.top, cancel=cancelled))
           do_test = 1
        end

     endcase
  endif
  
  if do_test eq 1 then ktn_polar_plot

  if apply_to_data eq 1 then begin
     nika_pipe_hwp_rm, param, kidpar, data
     message, /info, "done."
     widget_control, ev.top, /destroy
     goto, exit
  endif

exit:
end


pro ktn_polar_widget, no_block=no_block
  common ktn_common

  xs_commands = !screen_size[0]*0.5
  ys_commands = !screen_size[1]*0.8

  xs_def = 100
  ys_def = 100
  nxpix = 800 < long( xs_commands-1.3*xs_def)
  nypix = 800 < long( ys_commands)

  ;; Create widget
  main = widget_base( title='Polarization', /row, /frame)

  ;; button size
  comm0  = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)
  comm1  = widget_base( comm0, /row, /frame, xsize=xs_commands)
  display_draw1 = widget_draw( comm1, xsize=nxpix, ysize=nypix, /button_events)

  w1 = where( kidpar.type eq 1, nw1)
  comm11 = widget_base( comm1, /column, /frame, xsize=xs_def*1.3)
;  sld = cw_fslider( comm11, title='Ikid', min=0, max=n_elements(kidpar)-1, $
;                    scroll=1, value=w1[0], uval='slide_ikid', xsize=long(xs_def), ys=ys_def, /drag, /edit)
  b = widget_button( comm11, uvalue='ikid',        value=np_cbb( 'Ikid',          bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm11, uvalue='nu_rot',      value=np_cbb( 'HWP rot. freq', bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm11, uvalue='n_harmonics', value=np_cbb( 'N harmonics',   bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm11, uvalue='apply',       value=np_cbb( 'Apply to data', bg='blk7',      fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm11, uvalue='quit',        value=np_cbb( 'Quit',          bg='firebrick', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  
  ;; Pointing of the reference detector                                                                                                                   
  w1 = where( kidpar.type eq 1, nw1)
  ikid = w1[0]
  nsn  = n_elements(data)
  time = dindgen(nsn)/!nika.f_sampling
  nsn_test = (2L^15) < nsn
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

  ;; Realize the widget
  xoff = !screen_size[0]-xs_commands*1.3
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands
  widget_control, display_draw1, get_value=drawID1

  pwc = {drawID1:drawID1,sigma_beam_nu:sigma_beam_nu, nsn_test:nsn_test, $
         f_subscan:f_subscan, ikid:w1[0]}

  ktn_polar_plot

  xmanager, "ktn_polar", main, no_block=no_block

end
