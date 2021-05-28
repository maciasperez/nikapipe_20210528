
PRO beam_works_event, ev
  common ql_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  do_beam_guess   = 0
  plot_beams      = 0
  plot_beams_stat = 0

  cancelled = 0 ; default

  case uvalue of
     'beam_guess': do_beam_guess = 1
     'beam_stats': begin
        plot_beams_stat = 1
        if !check_list.status[1] ne 1 then do_beam_guess = 1
     end
     "fwhm_min": begin
        if !check_list.status[1] ne 1 then begin
           do_beam_guess = 1
        endif else begin
           fwhm_min = double( Textbox( title='FWHM min', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( fwhm lt fwhm_min, nw)
              if nw ne 0 then kidpar[w].type = 5
           endif
        endelse
     end
     "fwhm_max": begin
        if !check_list.status[1] ne 1 then begin
           do_beam_guess = 1
        endif else begin
           fwhm_max = double( Textbox( title='FWHM min', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( fwhm gt fwhm_max, nw)
              if nw ne 0 then kidpar[w].type = 5
           endif
        endelse
     end
     "ampl_min": begin
        if !check_list.status[1] ne 1 then begin
           do_beam_guess = 1
        endif else begin
           ampl_min = double( Textbox( title='AMPL min', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( a_peaks_1 lt ampl_min, nw)
              if nw ne 0 then kidpar[w].type = 5
           endif
        endelse
     end
     "ampl_max": begin
        if !check_list.status[1] ne 1 then begin
           do_beam_guess = 1
        endif else begin
           ampl_max = double( Textbox( title='AMPL min', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( a_peaks_1 gt ampl_max, nw)
              if nw ne 0 then kidpar[w].type = 5
           endif
        endelse
     end
     "ellipt_max": begin
        if !check_list.status[1] ne 1 then begin
           do_beam_guess = 1
        endif else begin
           ellipt_max = double( Textbox( title='ELLIPT max', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( ellipt gt ellipt_max, nw)
              if nw ne 0 then kidpar[w].type = 5
           endif
        endelse
     end
     'quit': begin
        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end
  endcase

  ;;-------------------------------------------------------
  ;; operations

  if do_beam_guess eq 1 then begin
     plot_name = "beam_matrix"
     ;; ;;----------------------------
     ;; parinfo = replicate( {fixed:0, limited:[1,1], limits:[0,0]}, 7)
     ;; parinfo[0].limits = minmax(map_list_out) ; constant
     ;; parinfo[1].limits = minmax(map_list_out) ; amplitude
     ;; parinfo[2].limits = [5.d0, 20.d0] ; arcsec
     ;; parinfo[3].limits = [5.d0, 20.d0] ; arcsec
     ;; parinfo[4].limits = [-80d0, 80d0]
     ;; parinfo[5].limits = [-80d0, 80d0]
     ;; parinfo[6].limits = 2*!dpi
     ;; ;;----------------------------
     ;;beam_guess, map_list_out, xmap, ymap, kidpar, x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
     ;;            beam_list_1, theta_1, rebin=rebin_factor, /mpfit, /circular, /noplot, verbose=verbose
     
     method = "mpfit"           ; "myfit"
     beam_guess, map_list_out, xmap, ymap, kidpar, x_peaks_1, y_peaks_1, a_peaks_1, sigma_x_1, sigma_y_1, $
                 beam_list_1, theta_1, rebin=rebin_factor, /noplot, verbose=verbose, parinfo=parinfo, $
                 method=method                                 ;, /circular
     gnaw = where( a_peaks_1 le 0 and kidpar.type ne 2, nn)      ;; preserve OFF information
     if nn ne 0 then kidpar[gnaw].type = 5
     plot_beams = 1
     plot_beams_stat = 1
     !check_list.status[1] = 1
  endif

  if plot_beams eq 1 then begin
     outplot, file=nickname+'_beam_pict', png=png, ps=ps
     show_matrix, beam_list_1
     outplot, /close
  endif

  if plot_beams_stat eq 1 then begin
     wind, 1, 1, /free, ys=900
     outplot, file=nickname+'_beam_histos', png=png, ps=ps
     !p.multi=[0,1,3]
     w = where( kidpar.type eq 1, nw)
     fwhm = sqrt( sigma_x_1*sigma_y_1)/!fwhm2sigma
     if total(finite(fwhm[w])) ne nw then begin
        ww = where( finite(fwhm) ne 1 and (kidpar.type eq 1 or kidpar.type eq 3))
        print, "Infinite fwhm for kids: ", ww
        stop
     endif else begin
        n_histwork, fwhm[w], bin=stddev( fwhm[w])/3.d0, /fit, xhist, yhist, gpar_fwhm, charsize=1.3, /fill
        legendastro, [box+strtrim(lambda,2)+'mm', $
                      'FWHM (mm)', 'Nvalid='+strtrim(nw1,2)], chars=1.5, box=0
     endelse

     ellipt = fwhm*0.
     ellipt[w] = sigma_x_1[w]/sigma_y_1[w]
     n_histwork, ellipt[w], bin=stddev(ellipt[w])/3., /fit, xhist, yhist, gpar_ellipt, charsize=1.3, /fill
     legendastro, [box+strtrim(lambda,2)+'mm', $
                   'Ellipt=FWHM!dx!n/FWHM!dy!n', 'Nvalid='+strtrim(nw1,2)], box=0, chars=1.5

     n_histwork, a_peaks_1[w], xhist, yhist, gpar_ampl, bin=stddev(a_peaks_1[w])/3., title='Peak Amplitude (Hz)', /fit, charsize=1.3, /fill
     legendastro, [box+strtrim(lambda,2)+'mm', $
                   'Nvalid='+strtrim(nw1,2)], chars=1.5, box=0
     !p.multi=0
     outplot, /close
  endif








exit:
end


PRO beam_works
  common ql_maps_common

  main = widget_base( title='Beam Works', /col, /frame)

  xs = 100
  ys = 100
  comm1 = widget_base( main, /row, /frame)
  b = widget_button( comm1, uvalue='beam_guess', value=np_cbb( 'Beam Guess', bg='dark slate blue', xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm1, uvalue='beam_stats', value=np_cbb( 'Beams Stat', bg='dark slate blue', xs=xs, ys=xs), xs=xs, ys=ys)

  comm2 = widget_base( main, /row, /frame)
  b = widget_button( comm2, uvalue='fwhm_min',   value=np_cbb( 'FWHM min',   bg='dark slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm2, uvalue='fwhm_max',   value=np_cbb( 'FWHM max',   bg='dark slate blue', xs=xs, ys=ys), xs=xs, ys=ys)

  comm3 = widget_base( main, /row, /frame)
  b = widget_button( comm3, uvalue='ampl_min',   value=np_cbb( 'Ampl min',   bg='dark slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm3, uvalue='ampl_max',   value=np_cbb( 'Ampl max',   bg='dark slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  
  comm4 = widget_base( main, /row, /frame)
  b = widget_button( comm4, uvalue='ellipt_max', value=np_cbb( 'Ellipt max', bg='dark slate blue', xs=xs, ys=ys), xs=xs, ys=ys)

  btn_quit = widget_button( main, uvalue='quit', value=np_cbb( 'Quit',       bgc='firebrick',      xs=xs, ys=ys), xs=xs, ys=ys)

  my_screen_size = get_screen_size()
  widget_control, main, /realize, xoff=long(0.6*my_screen_size[0])
  xmanager, 'beam_works', main;, /no_block
END

