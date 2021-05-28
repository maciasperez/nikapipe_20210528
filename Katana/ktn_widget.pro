
PRO ktn_works_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue

  do_beam_guess   = 0
  plot_beams      = 0
  plot_beams_stat = 0

  cancelled = 0 ; default

  w1 = where( kidpar.type eq 1, nw1, compl=wbad, ncompl=nwbad)

  case uvalue of

     'beam_guess': begin
        do_beam_guess = 1
        beam_noplot = 1 ; 0
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

     "noise_min": begin
        noise_min = double( Textbox( title='NOISE min', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.noise lt noise_min, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
           if operations.beam_guess_done ne 1 then do_beam_guess   = 1
           beam_noplot     = 1
           plot_beams_stat = 1
        endif
     end
     "noise_max": begin
        noise_max = double( Textbox( title='NOISE max', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.noise gt noise_max, nw)
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
     'histo_fit': begin
        disp.histo_fit = 1
        ktn_beam_stats
     end

     'quit': begin
        !check_list.status[2] = 1
        if disp.check_list ne 0 then         show_checklist, !check_list
        wd, !check_list.wind_num

        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end
  endcase

  ;;-------------------------------------------------------
  ;; operations

  if do_beam_guess eq 1 then begin
     print, "Beam guess..."
     ;;ktn_beam_guess, noplot=beam_noplot
     ktn_beam_calibration, noplot=beam_noplot
     operations.beam_guess_done = 1
     print, "done."
  endif

  if plot_beams eq 1 then begin
     ktn_show_matrix, disp.beam_list
  endif

  if plot_beams_stat eq 1 then ktn_beam_stats


message, /info, "done."

exit:
end

;;=========================================================================================================================
PRO ktn_widget_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue

  w1    = where( kidpar.type eq 1, nw1)
  w3    = where( kidpar.type eq 3, nw3)
  w13   = where( kidpar.type eq 1 or kidpar.type eq 3, nw13)
  wplot = where( kidpar.plot_flag eq 0, nwplot)

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
  do_get_grid_nodes = 0

  CASE uvalue OF

     'kid_selector':ktn_kid_selector_widget
     'plot_all_kids':begin
        kidpar.plot_flag = 1
        if nw1 ne 0 then kidpar[w1].plot_flag = 0
        if nw3 ne 0 then kidpar[w3].plot_flag = 0
        sys_info.outlyers = 0
     end

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
     
     'sanity_checks': ktn_sanity_checks;, param, data, kidpar, param_c, param_d

     'show_plateau': ktn_show_matrix, disp.map_list, relative_max=0.02, /nan2zero;, kidx=kidpar[wplot].x_peak_azel, kidy=kidpar[wplot].y_peak_azel

     'zigzag': begin
        print, "Running zigzag..."
        zigzag, param.scan_num, param.day, kidpar[0].array, optimal_shift, $
                ishift_min=disp.ishift_min, ishift_max=disp.ishift_max, png=png, ps=ps, d_max=20, $
                data=data, kidpar=kidpar, /pipe, wplot=wplot
        print, "zigzag done."
     end
     
;;     "slide_fwhm_min": begin
;;        fwhm_min = double(ev.value)
;;        w = where( kidpar.fwhm lt fwhm_min, nw)
;;        if nw ne 0 then kidpar[w].plot_flag = 1
;;        if operations.beam_guess_done ne 1 then do_beam_guess   = 1
;;        beam_noplot     = 1
;;        plot_beams_stat = 1
;;     end
;;     "slide_fwhm_max": begin
;;        fwhm_max = double( ev.value)
;;        w = where( kidpar.fwhm gt fwhm_max, nw)
;;        if nw ne 0 then kidpar[w].plot_flag = 1
;;        if operations.beam_guess_done ne 1 then do_beam_guess   = 1
;;        beam_noplot     = 1
;;        plot_beams_stat = 1
;;     end



     'slide_ishift_min': disp.ishift_min = long(ev.value)
     'slide_ishift_max': disp.ishift_max = long(ev.value)

     'polar': ktn_polar_widget, /no_block
     
     'show_check_list':begin
        ;disp.check_list=1
        show_checklist, !check_list, /init
     end

     "wd_all": wd, /all

;;      'broadcast':begin
;;         compilation_dir = !nika.soft_dir+'/NIKA_lib/Readdata/IDL_so_files/'
;;         libso = compilation_dir +'IDL_read_data.so'
;;         w1 = where( kidpar.type eq 1, nw1)
;; 
;;         ;; to debug doubles to long
;;         kidpar[w1].x_pix = long( kidpar[w1].nas_x)
;;         kidpar[w1].y_pix = long( kidpar[w1].nas_y)
;;         nn = call_external( libso, "IDL_geo_bcast", long(nw1), kidpar[w1].raw_num, kidpar[w1].x_pix, kidpar[w1].y_pix)
;;      end

     ;; redo plots and outputs in .png
     'save_plots':begin
        junk = sys_info.png
        sys_info.png = 1 ; force
        ktn_plot_fp
        ktn_beam_stats

        itab = 0
        kmin = itab*disp.nkids_max_per_tab
        kmax = ((itab+1)*disp.nkids_max_per_tab-1) < disp.nkids
        dxmap = max(disp.xmap)-min(disp.xmap)
        dymap = max(disp.ymap)-min(disp.ymap)
        xmin = min(disp.xmap)
        ymin = min(disp.ymap)
        ymax = max(disp.ymap)

        wind, 1, 1, /free, xsize=disp.xsize_matrix, ysize=disp.ysize_matrix
        outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+"_matrix", png=sys_info.png, ps=sys_info.ps
        kmin = itab*disp.nkids_max_per_tab
        kmax = ((itab+1)*disp.nkids_max_per_tab) < disp.nkids

        matrix = disp.map_list
        ikid = kmin
        for j=0, n_elements(disp.plot_position[0,*,0])-1 do begin
           for i=0, n_elements(disp.plot_position[*,0,0])-1 do begin
              if ikid lt kmax then begin
                 delvarx, imrange
                 imview, reform(matrix[ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, $
                         position=reform(disp.plot_position[i,j,*]), $
                         udg=rebin_factor, /nobar, chars=1e-6, /noerase, imrange=imrange
                 xx = xmin+0.1*dxmap
                 yy = ymin+0.1*dymap
                 decode_flag, kidpar[ikid].type, flagname
                 xyouts, xx, yy, flagname, chars=1.5, col=disp.textcol
                 yy = ymax-0.2*dymap
                 xyouts, xx, yy, strtrim( kidpar[ikid].numdet,2), col=disp.textcol
                 ikid += 1
              endif
           endfor
        endfor
        outplot, /close

        sys_info.png = junk ; restore
        print, "save_plots done."
     end

;;     'new_file':begin
;;        delvarx, file
;;        ktn_analyse_data, file=file
;;        ktn_plot_fp
;;     end
        
     'save_kidpar':begin
        w       = where( kidpar.plot_flag eq 1, nw)
        w2      = where( kidpar.type      eq 2, nw2)
        wdouble = where( kidpar.plot_flag eq 2, nwdouble)
        if nw       ne 0 then kidpar[w ].type      = 5
        if nw2      ne 0 then kidpar[w2].type      = 2 ; preserve off resonance kids
        if nwdouble ne 0 then kidpar[wdouble].type = 4 ; keep record of "double" kids

;        sys_info.output_kidpar_fits = "kidpar_"+sys_info.nickname+"_temp.fits"
        
        ;; Set to NaN undef values for convenience
        w = where( kidpar.type ne 1, nw)
        if nw ne 0 then begin
           kidpar[w].NAS_X = !values.d_nan
           kidpar[w].NAS_Y = !values.d_nan
           kidpar[w].NAS_CENTER_X = !values.d_nan
           kidpar[w].NAS_CENTER_Y = !values.d_nan
           kidpar[w].MAGNIF = !values.d_nan
           kidpar[w].CALIB = !values.d_nan
           kidpar[w].CALIB_FIX_FWHM = !values.d_nan
           kidpar[w].ATM_X_CALIB = !values.d_nan
           kidpar[w].FWHM = !values.d_nan
           kidpar[w].FWHM_X = !values.d_nan
           kidpar[w].FWHM_Y = !values.d_nan
           kidpar[w].THETA = !values.d_nan
           kidpar[w].X_PEAK = !values.d_nan
           kidpar[w].Y_PEAK = !values.d_nan
           kidpar[w].X_PEAK_NASMYTH = !values.d_nan
           kidpar[w].Y_PEAK_NASMYTH = !values.d_nan
           kidpar[w].X_PEAK_AZEL = !values.d_nan
           kidpar[w].Y_PEAK_AZEL = !values.d_nan
           kidpar[w].SIGMA_X = !values.d_nan
           kidpar[w].SIGMA_Y = !values.d_nan
           kidpar[w].ELLIPT = !values.d_nan
           kidpar[w].RESPONSE = !values.d_nan
           kidpar[w].SCREEN_RESPONSE = !values.d_nan
           kidpar[w].NOISE = !values.d_nan
           kidpar[w].SENSITIVITY_DECORR = !values.d_nan
           kidpar[w].IN_DECORR_TEMPLATE = 0
           kidpar[w].IDCT_DEF = 0
           kidpar[w].OK = 0
           kidpar[w].PLOT_FLAG = 1
           kidpar[w].C0_SKYDIP = !values.d_nan
           kidpar[w].C1_SKYDIP = !values.d_nan
           kidpar[w].TAU0 = !values.d_nan
           kidpar[w].DF = !values.d_nan
           kidpar[w].A_PEAK = !values.d_nan
           kidpar[w].TAU_skydip = !values.d_nan
        endif
        
        ;; Compute the grid step with the currently selected pixels and put into kidpar
;        get_grid_nodes, kidpar[wplot].x_peak_nasmyth, kidpar[wplot].y_peak_nasmyth, $
;                        xnode, ynode, alpha_opt, delta_opt, name=kidpar[wplot].name, /noplot
;        kidpar.grid_step = delta_opt

        ;; nika_write_kidpar, kidpar, sys_info.output_kidpar_fits
        nk_write_kidpar, kidpar, sys_info.output_kidpar_fits
        !check_list.status[1] = 1

        ;; Produce ASCII summary files
        scan2daynum, param.scan, day, scan_num
        ktn_kidpar2summary, day, kidpar, $
                            sys_info.output_dir+"/allkids_summary.txt", $
                            sys_info.output_dir+"/matrix_summary.txt"
        print, "save kid done"

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

     'matrix_display': begin
        !p.color = 255
        !p.background = 0
        plot_matrix_display = 1
     end

     'discard_kids': begin
        ;; ktn_discard_kids, kidx=kidpar.x_peak_azel,
        ;; kidy=kidpar.y_peak_azel
         ktn_select_kids, kidx = kidpar.x_peak_azel,  kidy = kidpar.y_peak_azel, action = 'discard'
        !check_list.status[0] = 1
     end

     'find_doubles': begin
        ktn_double_kids, kidx=kidpar.x_peak_azel, kidy=kidpar.y_peak_azel
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
        ktn_ikid_properties
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

     'beam_stats': ktn_works_event, ev
     'beam_guess': ktn_works_event, ev
     'fwhm_min':   ktn_works_event, ev
     'fwhm_max':   ktn_works_event, ev
     'ampl_min':   ktn_works_event, ev
     'ampl_max':   ktn_works_event, ev
     'noise_min':   ktn_works_event, ev
     'noise_max':   ktn_works_event, ev
     'ellipt_min': ktn_works_event, ev
     'ellipt_max': ktn_works_event, ev
     'histo_fit' : ktn_works_event, ev

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

     'string':begin
        print, "killing the string..."
        ;; ;;-------------------------------
        ;; ;; Regress on maps
        ;; nkids_corr = 5
        ;; ;; Find the nkids_corr most correlated maps to each kid
        ;; matrix = disp.map_list
        ;; wire_matrix = disp.map_list*0.d0
        ;; nkids = n_elements( matrix[*,0,0])
        ;; corr_mat = dblarr(nkids,nkids)
        ;; for i=0, nkids-2 do begin
        ;;    percent_status, i, nkids, 5
        ;;    for j=i+1, nkids-1 do begin
        ;;       corr_mat[i,j] = correlate( matrix[i,*,*], matrix[j,*,*])
        ;;    endfor
        ;; endfor
        ;; for i=0, nkids-1 do begin
        ;;    if kidpar[i].type eq 1 then begin
        ;;       order = reverse( sort( corr_mat[i,*]))
        ;;       wire = median( matrix[order[0:nkids_corr-1],*,*], dim=1)
        ;;       fit = linfit( wire, matrix[i,*,*])
        ;;       wire_matrix[i,*,*] = fit[0] + fit[1]*wire
        ;;    endif
        ;; endfor
        ;; 
        ;; nk_list_kids, kidpar, valid=w1
        ;; matrix_display, matrix[w1,*,*]
        ;; matrix_display, matrix[w1,*,*]-wire_matrix
        ;; choice = 0
        ;; read, choice, prompt="Enter: 1 to accept, 0 to reject: "
        ;; print, "you chose: "+strtrim(choice,2)
        ;; stop
     
        ;;---------------------------------------
        ;; produce a combined map, mask out the planet, read and subtract from timelines
        ;; Combine kids on a map with finer resolution
        ;; Striped down version of nk.pro
        data1 = data
        nk_default_param, param1
        param1.do_opacity_correction=0
        nk_default_info, info1
        nk_init_grid, param1, info1, grid_tot
        nk_get_kid_pointing, param1, info1, data1, kidpar
        nk_apply_calib, param1, info1, data1, kidpar
        nk_deglitch_fast, param1, info1, data1, kidpar
        nk_get_ipix, data1, info1, grid_tot
        nk_w8, param1, info1, data1, kidpar
        nk_projection_3, param1, info1, data1, kidpar, grid_tot
        map     = grid_tot.map_i_1mm
        map_var = grid_tot.map_var_i_1mm
        nhits   = grid_tot.nhits_1mm
        xx = grid_tot.xmap[*,0]
        yy = grid_tot.ymap[0,*]

        ;; Mask out the planet, leave only the string
        fit  = mpfit2dpeak( map, a, xx, yy, /tilt, /gauss, /circular)
        subtract_maps = grid_tot
        subtract_maps.map_i_1mm = double( (fit/max(fit)) lt 0.1)*map
        subtract_maps.map_i_2mm = double( (fit/max(fit)) lt 0.1)*map

        ;; Produce string timelines and regress out
        nk_maps2data_toi, param, info, data1, kidpar, subtract_maps, toi_input_maps
        for i=0, nw1-1 do begin
           ikid = w1[i]
           w = where( toi_input_maps[ikid,*] gt max(toi_input_maps[ikid,*])/10., nw)
           if nw eq 0 then begin
              message, /info, "problem here"
           endif else begin
              fit = linfit( toi_input_maps[ikid,w], data[w].toi[ikid])
              data.toi[ikid] -= (fit[0] + fit[1]*toi_input_maps[ikid,*])
           endelse
        endfor

        print, "string killed (if it did not vibrate too much)."
     end

     'quickview':begin
        disp.nasmyth = 0
        ktn_quickview_widget
     end

     'quickview_nasmyth':begin
        disp.nasmyth = 1
        ktn_quickview_widget
     end

     "otfmap":begin
        print, "call nk,..."
        ;; Combine kids on a map with finer resolution
        ;; Striped down version of nk.pro
        data1 = data
        param1 = param
        param1.do_opacity_correction=0
        nk_default_info, info1
        nk_init_grid, param1, info1, grid_tot
        nk_get_kid_pointing, param1, info1, data1, kidpar
        nk_apply_calib, param1, info1, data1, kidpar
        nk_deglitch_fast, param1, info1, data1, kidpar
        nk_get_ipix, data1, info1, grid_tot
        nk_w8, param1, info1, data1, kidpar
        nk_projection_3, param1, info1, data1, kidpar, grid_tot
        map     = grid_tot.map_i_1mm
        map_var = grid_tot.map_var_i_1mm
        nhits   = grid_tot.nhits_1mm
        xx = grid_tot.xmap[*,0]
        yy = grid_tot.ymap[0,*]

        ;; Derive a mask for decorrelation
        mask = map*0.d0 + 1
        w = where( map_var ne 0, nw)
        if nw eq 0 then message, "No pixel with non zero variance."
        map_sn = map*0.d0
        map_sn[w] = map[w]/sqrt(map_var[w])
        w = where( map_sn gt 5, nw)
        mask[w] = 0.d0

        ;; Enlarge the mask a bit for safety
        ;; m = filter_image( mask, fwhm=1)
        ;; mask = long( m gt 0.99)
        if param.lab ne 0 then begin
           kernel = [1.d0, 1.d0]
           mask1 = mask ; local copy
           nx = n_elements(mask[*,0])
           ny = n_elements(mask[0,*])
           for ix=0, nx-1 do begin
              mask1[ix,*]    = convol( reform(mask[ix,*]), kernel)/total(kernel)
              mask1[ix,0]    = mask[ix,0]    ; restore edge
              mask1[ix,ny-1] = mask[ix,ny-1] ; restore edge
           endfor
           mask = long(mask1 eq 1)
        endif

        grid_tot.mask_source = mask
        nk_mask_source, param1, info1, data1, kidpar, grid_tot
        index = dindgen( n_elements(data1))
        nsn = n_elements(data1)
        for i=0, nw1-1 do begin
           ikid = w1[i]

           w = where( data1.off_source[ikid] eq 1, nw)

           ;; force the first/last index to be good anyway to avoid bad
           ;; interpolation/extrapolation on the edges of the subscans
           if w[0] ne 0 then w = [0, w]
           if w[nw-1] ne (nsn-1) then w = [w, nsn-1]
           r = interpol( data_copy[w].toi[ikid], index[w], index) ; work on original data in Hz
           data1.toi[ikid] = r ; reuse data1.toi
        endfor

        ;; Fill kidpar with noise params
        data2 = data            ; keep a copy
        data  = data1
        ktn_noise_estim
        kidpar.noise_raw_source_interp_1Hz = kidpar.noise_1Hz
        kidpar.noise_raw_source_interp_2Hz = kidpar.noise_2Hz
        kidpar.noise_raw_source_interp_10Hz = kidpar.noise_10Hz
        data = data2 ; restore copy
        
        ;; Decorrelate
        param1.decor_method = 'common_mode_kids_out'
        nk_deglitch, param1, info1, data1, kidpar
        nk_clean_data, param1, info1, data1, kidpar, out_temp_data=out_temp_data

        data2 = data ; keep a copy
        data  = data1
        ktn_noise_estim
        kidpar.noise_source_interp_and_decorr_1Hz  = kidpar.noise_1Hz
        kidpar.noise_source_interp_and_decorr_2Hz  = kidpar.noise_2Hz
        kidpar.noise_source_interp_and_decorr_10Hz = kidpar.noise_10Hz
        data = data2 ; restore copy
        print, "Decorrelation done."

        ;; show combined map
        data1 = data
        nk_default_param, param1
        param1.do_opacity_correction=0
        nk_default_info, info1
        nk_init_grid, param1, info1, grid_tot

        nk_get_kid_pointing, param1, info1, data1, kidpar
        nk_apply_calib, param1, info1, data1, kidpar
        nk_deglitch_fast, param1, info1, data1, kidpar
        nk_get_ipix, data1, info1, grid_tot
        nk_w8, param1, info1, data1, kidpar
        nk_projection_3, param1, info1, data1, kidpar, grid_tot
        wind, 1, 1, /free
        imview, grid_tot.map_i_1mm, xmap=grid_tot.xmap, ymap=grid_tot.ymap
        print, "otfmap/decorr done."


     end

     "reset": begin
        data = data_copy
        print, "reset done"
     end

     "median_simple":begin
        print, "starting median filter..."
        speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
        median_speed = median( speed)
        decor_median_width = long(10*20.*!fwhm2sigma/median_speed*!nika.f_sampling) ; 5 sigma on each side at about 35 arcsec/s
        w1 = where( kidpar.type eq 1, nw1)
        for i=0, nw1-1 do begin
           ikid = w1[i]
           baseline = median( data.toi[ikid], decor_median_width)
           data.toi[ikid] -= baseline
        endfor
        print, "median filter done."
     end

     "outlyers": begin
        sys_info.outlyers = 1
        ktn_discard_outlyers
     end
     "beamfitnika": sys_info.beam_fit_method = "nika"
     "beamfitmpfit": sys_info.beam_fit_method = "mpfit"
     
     "subscan_beams":begin
        print, "Running subscan beams..."
        ktn_subscan_beams
        print, "done."
     end

     "cmkidout":begin
        print, "cmkidout..."
        
        if defined(info) eq 0 then nk_default_info, info

        d = sqrt( (grid.xmap-sys_info.pos_planet[0])^2 + (grid.ymap-sys_info.pos_planet[1])^2)
        ;;w = where( d lt 30, nw)
        w = where( d lt param.decor_cm_dmin, nw)
        if nw eq 0 then begin
           message, /info, "Problem with the planet position"
           stop
        endif
        grid.mask_source[w] = 0.d0
        param.decor_method = "common_mode_kids_out"
        param.polynomial = 0
        param.decor_per_subscan = "yes"

        ;; In katana, all kids are refered to the ref pointing
        dra_copy = data.dra
        ddec_copy = data.ddec
        nk_get_kid_pointing, param, info, data, kidpar
        nk_get_ipix, data, info, grid
        nk_mask_source, param, info, data, kidpar, grid
        nk_clean_data, param, info, data, kidpar, out_temp_data=out_temp_data

        ;; Quick check on the projection
        ;; ;; Allers simples
        ;; w4 = where( data.scan_st eq 4, nw4) ; & print, nw
        ;; w5 = where( data.scan_st eq 5, nw5) ; & print, nw
        ;; for i=0, nw4-1 do begin
        ;;    w = where( w5 gt w4[i], nw)
        ;;    if nw ne 0 then begin ; maybe the last subscan is cut off, then discard
        ;;       imin = min(w)
        ;;       w8[ w4[i]:w5[imin]] = 1
        ;;    endif
        ;; endfor
        ;; ww = where( w8 eq 0, nww)
        ;; if nww ne 0 then nk_add_flag, data, 11, ww
        ;; nk_projection_3, param, info, data, kidpar, grid
        ;; stop

        data.dra = dra_copy
        data.ddec = ddec_copy
        print, "cmkidout done"
     end

     "calibrate": begin
        print, "beam calibration..."
        ktn_beam_calibration, /noplot
        print, "beam calibration done."
     end

     'gnodes': begin
        ktn_grid_nodes, /no_block
        operations.grid_nodes = 1
     end

;;      'slide_fwhm_min':begin
;;         w = where( kidpar.type eq 1 and kidpar.fwhm lt ev.value, nw)
;;         if nw ne 0 then kidpar[w].plot_flag = 1
;;         beam_noplot     = 1
;;         plot_beams_stat = 1
;;      end
;;      'slide_fwhm_max':begin
;;         w = where( kidpar.type eq 1 and kidpar.fwhm gt ev.value, nw)
;;         if nw ne 0 then kidpar[w].plot_flag = 1
;;         beam_noplot     = 1
;;         plot_beams_stat = 1
;;      end

     'slide_ampl_min':begin
        w = where( kidpar.type eq 1 and kidpar.a_peak lt ev.value, nw)
        if nw ne 0 then kidpar[w].plot_flag = 1
        beam_noplot     = 1
        plot_beams_stat = 1
     end
     'slide_ampl_max':begin
        w = where( kidpar.type eq 1 and kidpar.a_peak gt ev.value, nw)
        if nw ne 0 then kidpar[w].plot_flag = 1
        beam_noplot     = 1
        plot_beams_stat = 1
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
     'decorr_reset': data.toi = toi_med
     'smooth_decorr_display': disp.smooth_decorr_display = 1-disp.smooth_decorr_display
     'decorr':begin
        ktn_decorr, status
        if status eq 0 then begin
           wind, 2, 2, /free, xs=long(!screen_size[0]/3), ys=long(!screen_size[1]*0.75)
           disp.decorr_window = !d.window
           do_decorr_display = 1
        endif
     end
     ;;-----------------------------------------------------------------------------------------------------------------

  Endcase


  ;;-operations.beam_gues---------------------------------------------------------
  ;; Operations
  operations:

  if do_decorr_display eq 1 then begin

     if operations.decorr eq 0 then begin
        ktn_decorr
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
           if min( data.toi[ikid]) lt yra[0] then yra[0] = min( data.toi[ikid])
           if max( data.toi[ikid]) gt yra[1] then yra[1] = max( data.toi[ikid])
        endif
     endfor
     ;; plot, time, data.toi[wplot[0]], /xs, /ys, xtitle='Time [mn]', ytitle='Hz', /nodata, yra=yra
     plot, time, toi_med[wplot[0],*], /xs, /ys, xtitle='Time [mn]', ytitle='Hz', /nodata, yra=yra
     for ikid=0, disp.nkids-1 do begin
        ;; if kidpar[ikid].plot_flag eq 0 then oplot, time, data.toi[ikid], col=kidpar[ikid].color
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

  if do_beam_guess  eq 1 then begin
     ;;ktn_beam_guess, /noplot
     ktn_beam_calibration, /noplot
     plot_beams = 1
     plot_beams_stat = 1
  endif

  if plot_beams_stat eq 1 then ktn_beam_stats

  if plot_matrix_display eq 1 then begin
     ;; outplot, file=sys_info.nickname+'_raw_maps', png=png, ps=ps
     ;;ktn_show_matrix, disp.map_list, /nan2zero, kidx=kidpar.x_peak_azel, kidy=kidpar.y_peak_azel
     ktn_show_matrix, kidx=kidpar.x_peak_azel, kidy=kidpar.y_peak_azel
     ;; outplot, /close
  endif

  if plot_coeff_matrix eq 1 then begin
     ;; outplot, file=sys_info.nickname+'_map_out', png=png, ps=ps
     ktn_show_matrix, map_list_out, /nan2zero
     ;; outplot, /close
  endif

  if do_plot_fp_pos eq 1 then begin
     ktn_plot_fp
  endif

  if do_quick_view eq 1 then ktn_kid_pop_up

  if do_get_grid_nodes eq 1 then get_grid_nodes, kidpar[wplot].nas_x, kidpar[wplot].nas_y, xnode, ynode, alpha_opt, delta_opt, name=kidpar[wplot].name

  if disp.check_list ne 0 then show_checklist, !check_list


  exit:
end


pro ktn_widget, no_block=no_block, check_list=check_list

  common ktn_common
  
  ;; Create checklist
  items = ['Discard uncertain kids', $
           'Grid nodes (check superposition)', $
           'OTF map', $
           'Reset data', $
           'Cmkidout', $
           'Beam Calibrate', $
           'Grid nodes (=> grid_step)', $
           'OTF map', $
           'Save plots', $
           'Save kid type', $
           'Quit']
  list = create_struct("items", items, $
                       "status", intarr(n_elements(items)), $
                       "wind_num", (!my_window>0))
  defsysv, "!check_list", list

  if keyword_set(check_list) then disp.check_list = 1
  
  ;; Start widget
  main = widget_base(title='KATANA', /row, /frame)

  nkids = n_elements( kidpar)

  ;; Number of buttons etc... to be updated manually for now
  xs_def = 120
  ys_def = 40

  n_buttons_x = 9
  n_buttons_y = 18
  xs_commands = (n_buttons_x*xs_def*1.1) < (!screen_size[0]*0.5)
  ys_commands = (n_buttons_y*ys_def*1.1) < (!screen_size[1]*0.7)

  ;; update
  xs_def = long( xs_commands/n_buttons_x)
  ys_def = long( ys_commands/n_buttons_y)

  commands = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

  comm = widget_base( commands, /row, /frame)
  bgc = "grey"
  sld = cw_fslider( comm, title='Select one kid', min=0, max=nkids-1, $
                    scroll=1, value=0, uval='slide_ibol', xsize=3*xs_def, ys=ys_def, /drag, /edit)

  comm1 = widget_base(comm, /col, /frame)
  b = widget_button( comm1, uvalue='sanity_checks', value=np_cbb( 'SanityChecks', bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='kid_selector',  value=np_cbb( 'Kid Selector', bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='polar',         value=np_cbb( 'Pol. template', bg='blk6', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='plot_all_kids', value=np_cbb( 'Reset all kids', bg='sea green', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base(comm, /col, /frame)
  b = widget_button( comm1, uvalue='zigzag',     value=np_cbb( 'Zig Zag',   bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  sld = cw_fslider( comm1, title='Min Shift', min=-10, max=10, $
                    scroll=1, value=-2, uval='slide_ishift_min', xsize=long(xs_def), ys=ys_def, /drag, /edit)
  sld = cw_fslider( comm1, title='Max Shift', min=-10, max=10, $
                    scroll=1, value=2, uval='slide_ishift_max', xsize=long(xs_def), ys=ys_def, /drag, /edit)
  
  ;b = widget_button( comm1, uvalue='ishift_min', value=np_cbb( 'min shift', bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  ;b = widget_button( comm1, uvalue='ishift_max', value=np_cbb( 'max shift', bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base(comm, /col, /frame)
  b = widget_button( comm1, uvalue='show_plateau',    value=np_cbb( 'Plateau',    bg='blk5', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='subscan_beams', value=np_cbb("Subscan Beams",   bg='blk5', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base(comm, /col, /frame)
  b = widget_button( comm1, uvalue='comments',        value=np_cbb( 'Comments',   bg='blk6', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='show_check_list', value=np_cbb( 'Check List', bg='gray', fg='black', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

;;   ;;--------------------------------------------------------------------
;;   ;; Decorrelation
;;   comm1 = widget_base( commands, /row, /frame)
;;   comm22 = widget_base( comm1, /column);, /frame)
;;   bgc = 'grn5'
;;   fg  = 'black'
;;   b = widget_button( comm22, uvalue='decorr',         value=np_cbb( 'Decorrelation',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
;;   bgc = 'grn4'
;;   b = widget_button( comm22, uvalue='decorr_display', value=np_cbb( 'Decorr. Display', bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
;;   bgc = 'grn3'
;;   b = widget_button( comm22, uvalue='smooth_decorr_display', value=np_cbb( 'Smooth Display', bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
;; 
;;   comm22 = widget_base( comm1, /col, /frame)
;;   sld = cw_fslider( comm22, /double, title='Freq min', min=0, max=!nika.f_sampling/2., $
;;                     scroll=0.01, value=disp.freq_min, uval='slide_freq_min', xsize=2*xs_def, ysize=ys_def, /drag, /edit)
;;   sld = cw_fslider( comm22, title='Freq max', min=0, max=!nika.f_sampling/2., $
;;                     scroll=0.01, value=disp.freq_max, uval='slide_freq_max', xsize=2*xs_def, ysize=ys_def, /drag, /edit)
;; 
;;   comm22 = widget_base( comm1, /column, /frame)
;;   sld = cw_fslider( comm22, /double, title='Time min', min=0, max=disp.nsn/!nika.f_sampling/60., $
;;                     scroll=0.01, value=disp.time_min, uval='slide_time_min', xsize=2*xs_def, ysize=ys_def, /drag, /edit)
;;   sld = cw_fslider( comm22, title='Time max', min=0, max=disp.nsn/!nika.f_sampling/60., $
;;                     scroll=0.01, value=disp.time_max, uval='slide_time_max', xsize=2*xs_def, ysize=ys_def, /drag, /edit)

  w1 = where( kidpar.type eq 1, nw1)
  comm1 = widget_base( commands, /row, /frame)


;;-------------------------------------------------------
;; Slides on beam statistics
;;   comm22 = widget_base( comm1, /column, /frame)
;;   sld = cw_fslider( comm22, /double, title='AMPL min', min=min(kidpar[w1].a_peak), max=max(kidpar[w1].a_peak), $
;;                     scroll=1.d3, value=round(mean(kidpar[w1].a_peak)), uval='slide_ampl_min', xsize=xs_def, ysize=ys_def, /drag, /edit)
;;   sld = cw_fslider( comm22, /double, title='AMPL max', min=min(kidpar[w1].a_peak), max=max(kidpar[w1].a_peak), $
;;                     scroll=1.d2, value=round(mean(kidpar[w1].a_peak)), uval='slide_ampl_max', xsize=xs_def, ysize=ys_def, /drag, /edit)
;;   
;;   comm22 = widget_base( comm1, /column, /frame)
;;   sld = cw_fslider( comm22, /double, title='FWHM min', min=0, max=max(kidpar[w1].fwhm), $
;;                     scroll=1.d0, value=round(mean(kidpar[w1].fwhm)), uval='slide_fwhm_min', xsize=xs_def, ysize=ys_def, /drag, /edit)
;;   
;;   sld = cw_fslider( comm22, title='FWHM max', min=0, max=max(kidpar[w1].fwhm), $
;;                     scroll=1d0, value=round(avg(kidpar[w1].fwhm)), uval='slide_fwhm_max', xsize=xs_def, ysize=ys_def, /drag, /edit)
;;-------------------------------------------------------

 
  comm22 = widget_base( comm1, /column, /frame)
  b = widget_button( comm22, uvalue='otfmap', value=np_cbb("Map/decorr/Noise", bg='navyblue', fg='white', xs=2*xs_def, ys=ys_def), xs=2*xs_def, ys=ys_def)

  comm22 = widget_base( comm1, /column, /frame)
  b = widget_button( comm22, uvalue='reset',         value=np_cbb("Reset Data",     bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm22, uvalue='cmkidout',      value=np_cbb("CM kid out",     bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm22, uvalue='calibrate',     value=np_cbb("Beam Calib.",    bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm22 = widget_base( comm1, /column, /frame)
  b = widget_button( comm22, uvalue='median_simple', value=np_cbb("Median Simple",  bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  
  comm22 = widget_base( comm1, /column, /frame)
  b = widget_button( comm22, uvalue='outlyers',      value=np_cbb("Outlyers",      bg='navyblue', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm22, uvalue='beamfitnika', value=np_cbb("BeamFitNIKA", bg='navyblue', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm22, uvalue='beamfitmpfit', value=np_cbb("BeamFitMPfit", bg='navyblue', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  
  ;; Display options
  comm2 = widget_base( commands, /row, /frame)
  comm_1 = widget_base( comm2, /col, /frame)
  value_list = ['Focal Plane', 'Input Matrix',   'Beam Stats'] ;'Apply Coeffs', ]
  uv_list    = ['show_fp',     'matrix_display', 'beam_stats'];'coeff',        ]
  nuv = n_elements(uv_list)
  bgcol = ['blu7',   'blu7',  'blu7'];,  'blu7',  'tg3']
  fgcol = ['white',  'white', 'white'];, 'white', 'black']
  for i=0, nuv-1 do b = widget_button( comm_1, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;; Ways to select kids
  comm_1 = widget_base( comm2, /col, /frame)
  value_list = ['Discard kids', 'Find doubles', 'Grid Nodes', 'QVNasm', 'QVazel']
  uv_list    = ['discard_kids', 'find_doubles', 'gnodes',     'quickview_nasmyth', 'quickview']
  nuv = n_elements(uv_list)
  bgcol = ['Pur8',   'Pur8', 'Pur8', 'Pur8', 'Pur8']
  fgcol = ['white',  'white',  'white', 'white', 'white']
  for i=0, nuv-1 do b = widget_button( comm_1, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;;-----------------------------------------------------------
  ;; Short cuts to beam analysis
  comm22 = widget_base( comm2, /col, /frame)
;;  comm1 = widget_base( comm22, /row);, /frame)
;;  fg = 'black'
;;  bgc = 'tg3'
;;  b = widget_button( comm1, uvalue='beam_guess', value=np_cbb( 'Beam Guess', bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
;;  b = widget_button( comm1, uvalue='beam_stats', value=np_cbb( 'Beams Stat', bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base( comm22, /row);, /frame)
  bgc = 'tan8'
  b = widget_button( comm1, uvalue='fwhm_min',   value=np_cbb( 'FWHM min',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='fwhm_max',   value=np_cbb( 'FWHM max',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
;;  sld = cw_fslider( comm1, /double, title='FWHM min', min=0, max=40, $
;;                    scroll=1, value=0, uval='slide_fwhm_min', xsize=long(xs_def), ysize=ys_def, /drag, /edit)
;;  sld = cw_fslider( comm1, title='FWHM max', min=0, max=40, $
;;                    scroll=1, value=40, uval='slide_fwhm_max', xsize=long(xs_def), ysize=ys_def, /drag, /edit)

  comm1 = widget_base( comm22, /row);, /frame)
  bgc = 'tan8'
  b = widget_button( comm1, uvalue='ellipt_min', value=np_cbb( 'Ellipt min', bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='ellipt_max', value=np_cbb( 'Ellipt max', bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm1 = widget_base( comm22, /row);, /frame)
  bgc = 'tan8'
  b = widget_button( comm1, uvalue='ampl_min',   value=np_cbb( 'Ampl min',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='ampl_max',   value=np_cbb( 'Ampl max',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  comm1 = widget_base( comm22, /row);, /frame)

  comm1 = widget_base( comm22, /row);, /frame)
  bgc = 'tan8'
  b = widget_button( comm1, uvalue='noise_min',   value=np_cbb( 'Noise min',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='noise_max',   value=np_cbb( 'Noise max',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  comm1 = widget_base( comm22, /row);, /frame)

  bgc = 'tan6'
  b = widget_button( comm1, uvalue='histo_fit',  value=np_cbb( 'histo fit',  bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;;----------------------------------------------------------
  ;; Options
;  comm_3 = widget_base( commands, /row, /frame)
  comm_3 = widget_base( comm2, /col, /frame)
  ;; value_list = ['Screen resp', 'New File']
  ;; uv_list    = ['screen', 'new_file']
  ;; bgcol      = ['red3', 'red3']
  ;; fgcol      = ['black', 'black']
  value_list = ['Kill string']
  uv_list    = ['string']
  bgcol      = ['red3']
  fgcol      = ['black']
  nuv        = n_elements(uv_list)
  for i=0, nuv-1 do b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

;  comm_3 = widget_base( commands, /row, /frame)
  comm_3 = widget_base( comm2, /col, /frame)
  ;; value_list = ['Broadcast Geometry', 'Reverse text color', 'Save plots', "wd, /all"]
  ;; uv_list    = ['broadcast',          'textcol',            'save_plots', "wd_all"]
  ;; bgcol      = ['ygb7', 'ygb7', 'ygb7', "ygb7"];'dark slate blue',    'dark slate blue',    'dark slate blue']
  ;; fgcol      = ['white',              'white',              'white', "white"]

  value_list = ['Reverse text color', 'Save plots', "wd, /all"]
  uv_list    = ['textcol',            'save_plots', "wd_all"]
  bgcol      = ['ygb7',               'ygb7',       "ygb7"];'dark slate blue',    'dark slate blue',    'dark slate blue']
  fgcol      = ['white',              'white',      "white"]
  nuv        = n_elements(uv_list)
  for i=0, nuv-1 do b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm_3 = widget_base( comm2, /col, /frame)
  value_list = ['Pause',  'Save kidpar', 'Quit']
  uv_list    = ['pause',  'save_kidpar',   'quit']
  bgcol      = ['khaki', 'sea green',     'firebrick']
  fgcol      = ['black', 'white',         'white']
  nuv        = n_elements(uv_list)
  for i=0, nuv-1 do b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  

  ;;============================================================================
  ;;================================ Create the widget =========================
  ;;============================================================================
  xoff = long( !screen_size[0]-xs_commands*1.2)  
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands ;; creates the widgets

  if keyword_set(check_list) then show_checklist, !check_list, /init

  ;; Display kid maps
;  ktn_show_matrix, disp.map_list
  xmanager, 'ktn_widget', main, no_block=no_block
   
end
