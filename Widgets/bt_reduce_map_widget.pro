
PRO bt_beam_works_event, ev
  common bt_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  do_beam_guess   = 0
  plot_beams      = 0
  plot_beams_stat = 0

  cancelled = 0 ; default

  w1 = where( kidpar.type eq 1, nw1)

  case uvalue of

     'beam_guess': begin
        do_beam_guess = 1
        beam_noplot = 0
     end
     'beam_stats': begin
        plot_beams_stat = 1
        if operations.beam_guess_done ne 1 then do_beam_guess = 1
     end
     "fwhm_min": begin
        fwhm_min = double( Textbox( title='FWHM min', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.fwhm lt fwhm_min, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     "fwhm_max": begin
        fwhm_max = double( Textbox( title='FWHM max', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.fwhm gt fwhm_max, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     "ampl_min": begin
        ampl_min = double( Textbox( title='AMPL min', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.a_peak lt ampl_min, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     "ampl_max": begin
        ampl_max = double( Textbox( title='AMPL max', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.a_peak gt ampl_max, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     "ellipt_min": begin
        ellipt_min = double( Textbox( title='ELLIPT min', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.ellipt lt ellipt_min, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     "ellipt_max": begin
        ellipt_max = double( Textbox( title='ELLIPT max', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.ellipt gt ellipt_max, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     'quit': begin
        !check_list.status[2] = 1
        show_checklist, !check_list
        wd, !check_list.wind_num

        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end
  endcase

  ;;-------------------------------------------------------
  ;; operations

  if do_beam_guess eq 1 then begin
     bt_nika_beam_guess, noplot=beam_noplot
     operations.beam_guess_done = 1
  endif

  if plot_beams eq 1 then begin
     bt_show_matrix, disp.beam_list_1
  endif

  if plot_beams_stat eq 1 then bt_beam_stats


message, /info, "done."

exit:
end

;;=========================================================================================================================
PRO bt_nika_widget_event, ev
  common bt_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  w1  = where( kidpar.type eq 1, nw1)
  w3  = where( kidpar.type eq 3, nw3)
  w13 = where( kidpar.type eq 1 or kidpar.type eq 3, nw13)

  do_beam_guess = 0

  plot_matrix_display   = 0
  plot_coeff_matrix     = 0
  plot_beams            = 0
  plot_beams_stat       = 0
  do_plot_fp_pos        = 0
  do_quick_view         = 0
  do_interactive_fp_rot = 0
  do_decorr_display     = 0
  do_show_kid_plot_selector  = 0
  do_show_kid_decorr_selector  = 0

  CASE uvalue OF

     'kid_selector':kid_selector_widget

     'comments':begin
        r = file_search( sys_info.comments_file)
        if r eq '' then begin
           openw, 1, sys_info.comments_file
           printf, 1, "# Enter the pieces of information you want about "+sys_info.nickname
           printf, 1, "# One comment per line"
           printf, 1, ""
           close, 1
        endif
        spawn, "open -a textedit "+sys_info.comments_file+" &"
     end
     

     'broadcast':begin
        compilation_dir = !nika.soft_dir+'/NIKA_lib/Readdata/IDL_so_files/'
        libso = compilation_dir +'IDL_read_data.so'
        w1 = where( kidpar.type eq 1, nw1)

        ;; to debug doubles to long
        kidpar[w1].x_pix = long( kidpar[w1].nas_x)
        kidpar[w1].y_pix = long( kidpar[w1].nas_y)
        nn = call_external( libso, "IDL_geo_bcast", long(nw1), kidpar[w1].raw_num, kidpar[w1].x_pix, kidpar[w1].y_pix)
     end

     ;; redo plots and outputs in .png
     'save_plots':begin
        junk = sys_info.png
        sys_info.png = 1 ; force
        bt_plot_fp_pos
        bt_beam_stats
        sys_info.png = junk ; restore
     end

     'new_file':begin
        delvarx, file
        bt_analyse_data, file=file
        bt_plot_fp_pos
     end
        
     'save_kidpar':begin
        w = where( kidpar.plot_flag ne 0 and kidpar.type ne 2, nw)
        if nw ne 0 then kidpar[w].type = 5
        sys_info.output_kidpar_fits = "kidpar_"+sys_info.nickname+"_temp.fits"
        nika_write_kidpar, kidpar, sys_info.output_kidpar_fits
        !check_list.status[1] = 1
     end

     'pause':begin
        stop
        ;; to have access to the terminal window and all data
     end

     'quit': begin
        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end

     'textcol':disp.textcol = 255 - disp.textcol

     'wplot': begin        
        case ev.index of
           0: kidpar.plot_flag = 0 ; keep all
           1: begin
              kidpar.plot_flag = 1                      ; kill all...
              if nw1 ne 0 then kidpar[w1].plot_flag = 0 ; ... but w1
           end
           2: begin
              kidpar.plot_flag = 1                      ; kill all...
              if nw3 ne 0 then kidpar[w3].plot_flag = 0 ; ... but w3
           end
           3:begin
              kidpar.plot_flag = 1                      ; kill all...
              if nw13 ne 0 then kidpar[w13].plot_flag = 0 ; ... but w13
           end
        endcase
     end

     'blind':     kidpar[disp.ikid].type = 0
     'valid':     kidpar[disp.ikid].type = 1
     'off':       kidpar[disp.ikid].type = 2
     'combined':  kidpar[disp.ikid].type = 3
     'mult':      kidpar[disp.ikid].type = 4
     'tbc':       kidpar[disp.ikid].type = 5

     'matrix_display': begin
        !p.color = 255
        !p.background = 0
        plot_matrix_display = 1
     end

     'discard_kids': begin
        bt_discard_kids
        !check_list.status[0] = 1
     end

     'c_cursor': begin
        coor_cursor, x_cross, y_cross, /cross
        disp.x_cross = x_cross
        disp.y_cross = y_cross
     end

     'reset_cursor': begin
        disp.x_cross = disp.x_cross*0. + !undef
        disp.y_cross = disp.y_cross*0. + !undef
     end

     'slide_ibol': begin
        disp.ikid = long(ev.value)
        wind, 1, 1, xs=900, ys=800
        disp.window=1
        show_ikid_properties
     end

     'decouple': begin
        window, 3, xs=800, ys=700, xp=10, yp=500
        slide_decouple_2
        theta1 = !sld_dec.theta1*!dtor
        theta2 = !sld_dec.theta2*!dtor
        disp.coeff[             *, !sld_dec.ibol] = 0.0d0 ; matrix convention
        disp.coeff[             *, !sld_dec.jbol] = 0.0d0
        disp.coeff[ !sld_dec.ibol, !sld_dec.ibol] = cos(theta1)
        disp.coeff[ !sld_dec.jbol, !sld_dec.ibol] = sin(theta1)
        disp.coeff[ !sld_dec.ibol, !sld_dec.jbol] = cos(theta2)
        disp.coeff[ !sld_dec.jbol, !sld_dec.jbol] = sin(theta2)
        print, !sld_dec.theta1, !sld_dec.theta2
     end

     'multi_decouple': multi_decouple

     'discard': begin
        wshet, 1
        print, "!d.window = ", !d.window
        coor_cursor, x, y, /dev
        keep = [0]
        for i=0, n_elements(x)-1 do begin
           for j=0, n_elements(disp.plot_position1[*,0])-1 do begin
              if (float(x[i])/!d.x_size ge disp.plot_position1[j,0] and $
                  float(x[i])/!d.x_size lt disp.plot_position1[j,2] and $
                  float(y[i])/!d.y_size ge disp.plot_position1[j,1] and $
                  float(y[i])/!d.y_size lt disp.plot_position1[j,3]) then keep = [keep, j]
           endfor
        endfor
        if n_elements(keep) gt 1 then begin
           keep = keep[1:*]
           for i=0, n_elements(keep)-1 do begin
              if kidpar[keep[i]].type ne 2 then kidpar[keep[i]].type = 5
           endfor
        endif
     end

     'coeff':begin
        plot_name = "matrix_coeff"
        apply_coeff, disp.map_list, disp.coeff, kidpar, map_list_out
        plot_coeff_matrix = 1
     end

     'beam_stats': bt_beam_works_event, ev
     'beam_guess': bt_beam_works_event, ev
     'fwhm_min':   bt_beam_works_event, ev
     'fwhm_max':   bt_beam_works_event, ev
     'ampl_min':   bt_beam_works_event, ev
     'ampl_max':   bt_beam_works_event, ev
     'ellipt_min': bt_beam_works_event, ev
     'ellipt_max': bt_beam_works_event, ev

     'plot_all':begin
        wshet, ks.drawID1
        kidpar.plot_flag = 1
        kidpar[w1].plot_flag = 0
     end
     'numdet_min':begin
        wshet, ks.drawID1
        kid_selector_event, ev
     end
     'numdet_max':begin
        wshet, ks.drawID1
        kid_selector_event, ev
     end
     'max_noise':begin
        wshet, ks.drawID1
        kid_selector_event, ev
     end
     'min_response':begin
        wshet, ks.drawID1
        kid_selector_event, ev
     end

     'show_fp':begin
        plot_name = "FP_pos"
        if operations.beam_guess_done eq 0 then do_beam_guess = 1
        do_plot_fp_pos = 1
     end

     'screen':screening_widget

     'quickview':begin
        disp.nasmyth = 0
        quickview_widget
     end

     'quickview_nasmyth':begin
        disp.nasmyth = 1
        quickview_widget
     end

     ;; Frequency band for decorrelation
     "slide_freq_min": begin
        disp.freq_min = ev.value
        disp.do_decorr_filter = 1
     end
     "slide_freq_max": begin
        disp.freq_max = ev.value
        disp.do_decorr_filter = 1
     end

     "slide_time_min": begin
        disp.time_min = ev.value
        disp.do_decorr_filter = 1
     end
     "slide_time_max": begin
        disp.time_max = ev.value
        disp.do_decorr_filter = 1
     end

     'new_decorr':cg_decorr_widget
     'decorr_display': do_decorr_display = 1
     'decorr_reset': data.rf_didq = toi_med
     'smooth_decorr_display': disp.smooth_decorr_display = 1-disp.smooth_decorr_display
     'decorr':begin
        bt_decorr
        wind, 2, 2, /free, xs=long(!screen_size[0]/3), ys=long(!screen_size[1]*0.75)
        disp.decorr_window = !d.window
        do_decorr_display = 1
     end
     ;;-----------------------------------------------------------------------------------------------------------------

  Endcase


  ;;-operations.beam_gues---------------------------------------------------------
  ;; Operations
  operations:

  if do_decorr_display eq 1 then begin

     if operations.decorr eq 0 then begin
        bt_decorr
        wind, 2, 2, /free, xs=long(!screen_size[0]/3), ys=long(!screen_size[1]*0.75)
        disp.decorr_window = !d.window
     endif

     make_ct, disp.nkids, coltable
     kidpar.color = coltable
     wshet, disp.decorr_window
     !x.charsize = 2
     !y.charsize = 2
     wshet, disp.decorr_window
     !p.multi=[0,1,4]
     ;; time = dindgen( disp.nsn)/!nika.f_sampling/60.
     disp.time_max = disp.time_max < max(time)
     w = where( time ge disp.time_min and time le disp.time_max, nw)
     wplot = where( kidpar.plot_flag eq 0, nwplot)
     yra = [0,-1] ; init

     for ikid=0, disp.nkids-1 do begin
        if kidpar[ikid].plot_flag eq 0 then begin
           if min( data.rf_didq[ikid]) lt yra[0] then yra[0] = min( data.rf_didq[ikid])
           if max( data.rf_didq[ikid]) gt yra[1] then yra[1] = max( data.rf_didq[ikid])
        endif
     endfor
     ;; plot, time, data.rf_didq[wplot[0]], /xs, /ys, xtitle='Time [mn]', ytitle='Hz', /nodata, yra=yra
     plot, time, toi_med[wplot[0],*], /xs, /ys, xtitle='Time [mn]', ytitle='Hz', /nodata, yra=yra
     for ikid=0, disp.nkids-1 do begin
        ;; if kidpar[ikid].plot_flag eq 0 then oplot, time, data.rf_didq[ikid], col=kidpar[ikid].color
        if kidpar[ikid].plot_flag eq 0 then oplot, time, toi_med[ikid,*], col=kidpar[ikid].color
     endfor
     plots, [disp.time_min, disp.time_min, disp.time_max, disp.time_max, disp.time_min], $
            [min(toi_med[wplot[0],w]), max(toi_med[wplot[0],w]), max(toi_med[wplot[0],w]), $
             min(toi_med[wplot[0],w]), min(toi_med[wplot[0],w])], thick=2

     ;; yra = minmax( pw[where(pw ne 0)])*[0.1,10]
     wf = where( abs(freq-5.) eq min( abs(freq-5.)))
     wf = wf[0]
     junk = reform( pw[wplot,wf])
     yra = avg(junk)*[0.01, 100]

     plot_oo, freq, minmax(pw[wplot[0],*]), xra=minmax(freq), yra=yra, /xs, /ys, xtitle='Freq. [Hz]', ytitle='Hz/Sqrt(Hz)', /nodata
     ww = where( abs(freq- 5.) lt 0.2, nww)
     nn = 0
     junk = 0.d0
     for ikid=0, disp.nkids-1 do begin
        if kidpar[ikid].plot_flag eq 0 then begin
           if long( disp.smooth_decorr_display) ne 0 then begin
              oplot, freq, sqrt( gausslog_convolve(pw[ikid,*]^2,0.2)), col=kidpar[ikid].color
           endif else begin
              oplot, freq, pw[ikid,*], col=kidpar[ikid].color
           endelse
           junk += avg( pw[ikid,ww])
           nn   += 1
        endif
     endfor
     junk /= nn
     wplot = where( kidpar.plot_flag eq 0, nwplot)
     ;; legend, kidpar[wplot].name, textcol=kidpar[wplot].color, /bottom, box=0
     legendastro, ['Decorrelated'], box=0, chars=2, charthick=2, /bottom
     arrow, 5., junk*10, 5., junk, /data, hsize=!d.x_size/128.
     xyouts, 5., junk*10, strtrim(string( junk, format="(F6.2)"),2)+"Hz/Hz!u-1/2!n", chars=2, charthick=2


     junk = reform( pw_raw[wplot,wf])
     yra = avg(junk)*[0.01, 100]
     plot_oo, freq, minmax(pw_raw[wplot[0],*]), xra=minmax(freq), yra=yra, /xs, /ys, xtitle='Freq. [Hz]', ytitle='Hz/Sqrt(Hz)', /nodata
     nn = 0
     junk = 0.d0
     for ikid=0, disp.nkids-1 do begin
        if kidpar[ikid].plot_flag eq 0 then begin
           if long( disp.smooth_decorr_display) ne 0 then begin
              oplot, freq, sqrt( gausslog_convolve(pw_raw[ikid,*]^2,0.2)), col=kidpar[ikid].color
           endif else begin
              oplot, freq, pw_raw[ikid,*], col=kidpar[ikid].color
           endelse
           junk += avg( pw_raw[ikid,ww])
           nn   += 1
        endif
     endfor
     junk /= nn
     wplot = where( kidpar.plot_flag eq 0, nwplot)
     legendastro, ['Raw'], box=0, chars=2, charthick=2, /bottom
     arrow, 5., junk*10, 5., junk, /data, hsize=!d.x_size/128.
     xyouts, 5., junk*10, strtrim( string( junk, format="(F6.2)"), 2)+"Hz/Hz!u-1/2!n", chars=2, charthick=2


     plot, [0, 1], [0, 1], /nodata, xs=4, ys=4
     nkids_per_column = 15
     ncol = long( disp.nkids/nkids_per_column) + 1
     p = 0
     for ikid=0, disp.nkids-1 do begin
        if kidpar[ikid].plot_flag eq 0 then begin
           icol  = long( p/nkids_per_column)
           iline = p mod nkids_per_column
           oplot,  [icol]*1./ncol+0.02, 0.95-[iline]*1./nkids_per_column, psym=8, col=kidpar[ikid].color
           xyouts, [icol]*1./ncol+0.03, 0.95-[iline]*1./nkids_per_column, kidpar[ikid].name
           p++
        endif
     endfor

     !p.multi=0
  endif


  if do_beam_guess   eq 1 then begin
     bt_nika_beam_guess, /noplot
     plot_beams = 1
     plot_beams_stat = 1
  endif

  if plot_beams_stat eq 1 then bt_beam_stats

  if plot_matrix_display eq 1 then begin
     ;; outplot, file=sys_info.nickname+'_raw_maps', png=png, ps=ps
     bt_show_matrix, disp.map_list
     ;; outplot, /close
  endif

  if plot_coeff_matrix eq 1 then begin
     ;; outplot, file=sys_info.nickname+'_map_out', png=png, ps=ps
     bt_show_matrix, map_list_out
     ;; outplot, /close
  endif

  if do_plot_fp_pos eq 1 then begin
     bt_plot_fp_pos
  endif

  if do_quick_view eq 1 then bt_kid_popup

  if disp.check_list ne 0 then show_checklist, !check_list


  exit:
end


pro bt_reduce_map_widget, no_block=no_block, check_list=check_list

  common bt_maps_common
  
  ;; Create checklist
  items = ['0. Discard uncertain kids', $
           '1. Save kid config', $
           '2. Quit']
  list = create_struct("items", items, $
                       "status", intarr(n_elements(items)), $
                       "wind_num", (!my_window>0))
  defsysv, "!check_list", list

  if keyword_set(check_list) then disp.check_list = 1
  
  ;; Start widget
  main = widget_base(title='NIKA Reduce Map', /row, /frame)

  nkids = n_elements( data[0].rf_didq)

  ;; Number of buttons etc... to be updated manually for now
  if keyword_set(check_list) then begin
     n_buttons_x = 8+3
     n_buttons_y = 20 ; 19
  endif else begin
     n_buttons_x = 8
     n_buttons_y = 17 ; 16
  endelse
  xs_commands = !screen_size[0]*0.5
  ys_commands = !screen_size[1]*0.7

  xs_def = long( xs_commands/n_buttons_x)
  ys_def = long( ys_commands/n_buttons_y)

  commands = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

  comm = widget_base( commands, /row, /frame)
  bgc = "grey"
  sld = cw_fslider( comm, title='Select one kid', min=0, max=nkids-1, $
                    scroll=1, value=0, uval='slide_ibol', xsize=4*xs_def, ys=ys_def, /drag, /edit) ; slider 
  b = widget_button( comm, uvalue='kid_selector', value=np_cbb( 'Kid Selector', bg='aquamarine',      fg='black', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm, uvalue='comments',     value=np_cbb( 'Comments',     bg='dark slate blue', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;;--------------------------------------------------------------------
  ;; Decorrelation
  comm2 = widget_base( commands, /row, /frame)
  comm22 = widget_base( comm2, /column, /frame)
  sld = cw_fslider( comm22, /double, title='Freq min', min=0, max=!nika.f_sampling/2., $
                    scroll=0.01, value=disp.freq_min, uval='slide_freq_min', xsize=2*xs_def, ysize=ys_def, /drag, /edit)
  sld = cw_fslider( comm22, title='Freq max', min=0, max=!nika.f_sampling/2., $
                    scroll=0.01, value=disp.freq_max, uval='slide_freq_max', xsize=2*xs_def, ysize=ys_def, /drag, /edit)

  comm22 = widget_base( comm2, /column, /frame)
  sld = cw_fslider( comm22, /double, title='Time min', min=0, max=disp.nsn/!nika.f_sampling/60., $
                    scroll=0.01, value=disp.time_min, uval='slide_time_min', xsize=2*xs_def, ysize=ys_def, /drag, /edit)
  sld = cw_fslider( comm22, title='Time max', min=0, max=disp.nsn/!nika.f_sampling/60., $
                    scroll=0.01, value=disp.time_max, uval='slide_time_max', xsize=2*xs_def, ysize=ys_def, /drag, /edit)
 
  bgc = 'dark slate blue'
  comm22 = widget_base( comm2, /column, /frame)
  b = widget_button( comm22, uvalue='decorr',         value=np_cbb( 'Decorrelation',   bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm22, uvalue='decorr_display', value=np_cbb( 'Decorr. Display', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  bgc = 'sea green'
  b = widget_button( comm22, uvalue='smooth_decorr_display', value=np_cbb( 'Smooth Display', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)


  ;;-----------------------------------------------------------
  ;; Main display options
  comm_1 = widget_base( commands, /row, /frame)
  value_list = ['Input Matrix',   'Discard kids', 'Apply Coeffs', 'Show FP', 'Quick view', 'QVNasm',            'Screen Resp.']
  uv_list    = ['matrix_display', 'discard_kids', 'coeff',        'show_fp', 'quickview',  'quickview_nasmyth', 'screen']
  nuv = n_elements(uv_list)
  bgcol = ['steel blue', 'steel blue', 'steel blue', 'purple', 'purple', 'purple', 'aquamarine']
  fgcol = ['white',      'white',      'white',      'white',  'white',  'white',  'black']
  for i=0, nuv-1 do b = widget_button( comm_1, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;;-----------------------------------------------------------
  ;; Short cuts to beam analysis
  comm2 = widget_base( commands, /row, /frame)
  comm1 = widget_base( comm2, /row, /frame)
  bgc = 'dark slate blue'
  b = widget_button( comm1, uvalue='beam_guess', value=np_cbb( 'Beam Guess', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='beam_stats', value=np_cbb( 'Beams Stat', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base( comm2, /column, /frame)
  b = widget_button( comm1, uvalue='fwhm_min',   value=np_cbb( 'FWHM min',   bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='fwhm_max',   value=np_cbb( 'FWHM max',   bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='ampl_min',   value=np_cbb( 'Ampl min',   bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='ampl_max',   value=np_cbb( 'Ampl max',   bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='ellipt_min', value=np_cbb( 'Ellipt min', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='ellipt_max', value=np_cbb( 'Ellipt max', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base( comm2, /column, /frame)
  bgc = 'dark slate blue'
  b = widget_button( comm1, uvalue='plot_all',     value=np_cbb( 'Plot/All valid/Reset', bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='max_noise',    value=np_cbb( 'Max. Noise',           bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='min_response', value=np_cbb( 'Min. Resp.',           bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='numdet_min',   value=np_cbb( 'Min. Numdet',          bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='numdet_max',   value=np_cbb( 'Max. Numdet',          bg=bgc, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

;  if keyword_set(check_list) then begin
;     comm1 = widget_base( comm2, /column, /frame)
;     display_draw1 = widget_draw( comm1, xsize=3*xs_def, ysize=2*ys_def)
;  endif

  ;;----------------------------------------------------------
  ;; Options
  comm_3 = widget_base( commands, /row, /frame)
  value_list = ['Broadcast Geometry', 'Reverse text color', 'Save plots',       'Pause',      'New File',   'Save kid type', 'Quit']
  uv_list    = ['broadcast',          'textcol',            'save_plots',       'pause',      'new_file',   'save_kidpar',   'quit']
  bgcol      = ['dark slate blue',    'dark slate blue',    'dark slate blue',  'aquamarine', 'aquamarine', 'sea green',     'firebrick']
  fgcol      = ['white',              'white',              'white',            'black',      'black',      'white',         'white']
  nuv        = n_elements(uv_list)
  for i=0, nuv-1 do b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

;;  ;;----------------------------------------------------------
;;  ;; Options
;;  comm_3 = widget_base( commands, /row, /frame)
;;  value_list = ['Pause',      'New File',   'Quit']
;;  uv_list    = ['pause',      'new_file',   'quit']
;;  bgcol      = ['aquamarine', 'aquamarine', 'firebrick']
;;  fgcol      = ['black',      'black',      'white']
;;  nuv        = n_elements(uv_list)
;;  for i=0, nuv-1 do b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;;--------------------------------------------------------------
;;  xs_commands = xs_commands * 1.2
  xoff = long( !screen_size[0]-xs_commands*1.2)
  
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands ;; creates the widgets

  if keyword_set(check_list) then show_checklist, !check_list, /init

  ;; Display kid maps
;  bt_show_matrix, disp.map_list
  xmanager, 'bt_nika_widget', main, no_block=no_block
   
end
