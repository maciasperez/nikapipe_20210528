
PRO ktn_works_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue

  do_beam_guess   = 0
  plot_beams      = 0
  plot_beams_stat = 0

  cancelled = 0 ; default

  w1 = where( kidpar.type eq 1, nw1, compl=wbad, ncompl=nwbad)

  case uvalue of
     
     'beam_stats': begin
        plot_beams_stat = 1
     end
     "fwhm_min": begin
        fwhm_min = double( Textbox( title='FWHM min', group_leader=ev.top, cancel=cancelled))
        if not cancelled then begin
           w = where( kidpar.fwhm lt fwhm_min, nw)
           if nw ne 0 then kidpar[w].plot_flag = 1
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
;; 20160728 ;;        !check_list.status[2] = 1
;; 20160728 ;;        if disp.check_list ne 0 then         show_checklist, !check_list
;; 20160728 ;;        wd, !check_list.wind_num

        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end
  endcase

  ;;-------------------------------------------------------
  ;; operations
  if plot_beams eq 1 then ktn_show_matrix, disp.beam_list
  if plot_beams_stat eq 1 then ktn_beam_stats

message, /info, "done."

exit:
end

;;=========================================================================================================================
PRO ktn_widget_light_event, ev
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
;; 20160728 ;;     'plot_all_kids':begin
;; 20160728 ;;        kidpar.plot_flag = 1
;; 20160728 ;;        kidpar[w1].plot_flag = 0
;; 20160728 ;;        sys_info.outlyers = 0
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;;;      'comments':begin
;; 20160728 ;;;;         r = file_search( sys_info.comments_file)
;; 20160728 ;;;;         if r eq '' then begin
;; 20160728 ;;;;            openw, 1, sys_info.comments_file
;; 20160728 ;;;;            printf, 1, "# Enter the pieces of information you want about "+sys_info.nickname
;; 20160728 ;;;;            printf, 1, "# One comment per line"
;; 20160728 ;;;;            printf, 1, ""
;; 20160728 ;;;;            close, 1
;; 20160728 ;;;;         endif
;; 20160728 ;;;;         spawn, "open -a textedit "+sys_info.comments_file+" &"
;; 20160728 ;;;;      end
;; 20160728 ;;     
;; 20160728 ;;     'sanity_checks': ktn_sanity_checks;, param, data, kidpar, param_c, param_d
;; 20160728 ;;
;; 20160728 ;;     'show_plateau': ktn_show_matrix, disp.map_list, relative_max=0.02, /nan2zero;, kidx=kidpar[wplot].x_peak_azel, kidy=kidpar[wplot].y_peak_azel
;; 20160728 ;;
;; 20160728 ;;     'zigzag': begin
;; 20160728 ;;        print, "Running zigzag..."
;; 20160728 ;;        zigzag, param.scan_num, param.day, kidpar[0].array, optimal_shift, $
;; 20160728 ;;                ishift_min=disp.ishift_min, ishift_max=disp.ishift_max, png=png, ps=ps, d_max=20, $
;; 20160728 ;;                data=data, kidpar=kidpar, /pipe, wplot=wplot
;; 20160728 ;;        print, "zigzag done."
;; 20160728 ;;     end
     
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


;; 20160728 ;;     'slide_ishift_min': disp.ishift_min = long(ev.value)
;; 20160728 ;;     'slide_ishift_max': disp.ishift_max = long(ev.value)
;; 20160728 ;;
;; 20160728 ;;     'polar': ktn_polar_widget, /no_block
;; 20160728 ;;     
;; 20160728 ;;     'show_check_list':begin
;; 20160728 ;;        ;disp.check_list=1
;; 20160728 ;;        show_checklist, !check_list, /init
;; 20160728 ;;     end

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
        
        nk_write_kidpar, kidpar, sys_info.output_kidpar_fits
;; 20160728 ;;        !check_list.status[1] = 1
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

;; 20160728 ;;     'wplot': begin        
;; 20160728 ;;        case ev.index of
;; 20160728 ;;           0: kidpar.plot_flag = 0 ; keep all
;; 20160728 ;;           1: begin
;; 20160728 ;;              kidpar.plot_flag = 1                      ; kill all...
;; 20160728 ;;              if nw1 ne 0 then kidpar[w1].plot_flag = 0 ; ... but w1
;; 20160728 ;;           end
;; 20160728 ;;           2: begin
;; 20160728 ;;              kidpar.plot_flag = 1                      ; kill all...
;; 20160728 ;;              if nw3 ne 0 then kidpar[w3].plot_flag = 0 ; ... but w3
;; 20160728 ;;           end
;; 20160728 ;;           3:begin
;; 20160728 ;;              kidpar.plot_flag = 1                      ; kill all...
;; 20160728 ;;              if nw13 ne 0 then kidpar[w13].plot_flag = 0 ; ... but w13
;; 20160728 ;;           end
;; 20160728 ;;        endcase
;; 20160728 ;;     end

     'matrix_display': begin
        !p.color = 255
        !p.background = 0
        plot_matrix_display = 1
     end

     'select_kids_discard': ktn_select_kids, kidx = kidpar.x_peak_azel,  kidy = kidpar.y_peak_azel, action = 'discard'
     'select_kids_restore': ktn_select_kids, kidx = kidpar.x_peak_azel,  kidy = kidpar.y_peak_azel, action = 'restore'
     
;; 20160728 ;;     'c_cursor': begin
;; 20160728 ;;        coor_cursor, x_cross, y_cross, /cross
;; 20160728 ;;        disp.x_cross = x_cross
;; 20160728 ;;        disp.y_cross = y_cross
;; 20160728 ;;     end

;; 20160728 ;;     'reset_cursor': begin
;; 20160728 ;;        disp.x_cross = disp.x_cross*0. + !undef
;; 20160728 ;;        disp.y_cross = disp.y_cross*0. + !undef
;; 20160728 ;;     end

;; 20160728 ;;     'slide_ibol': begin
;; 20160728 ;;        disp.ikid = long(ev.value)
;; 20160728 ;;        wind, 1, 1, xs=900, ys=800
;; 20160728 ;;        disp.window=1
;; 20160728 ;;        ktn_ikid_properties
;; 20160728 ;;     end

;; 20160728 ;;     'decouple': begin
;; 20160728 ;;        window, 3, xs=800, ys=700, xp=10, yp=500
;; 20160728 ;;        slide_decouple_2
;; 20160728 ;;        theta1 = !sld_dec.theta1*!dtor
;; 20160728 ;;        theta2 = !sld_dec.theta2*!dtor
;; 20160728 ;;        disp.coeff[             *, !sld_dec.ibol] = 0.0d0 ; matrix convention
;; 20160728 ;;        disp.coeff[             *, !sld_dec.jbol] = 0.0d0
;; 20160728 ;;        disp.coeff[ !sld_dec.ibol, !sld_dec.ibol] = cos(theta1)
;; 20160728 ;;        disp.coeff[ !sld_dec.jbol, !sld_dec.ibol] = sin(theta1)
;; 20160728 ;;        disp.coeff[ !sld_dec.ibol, !sld_dec.jbol] = cos(theta2)
;; 20160728 ;;        disp.coeff[ !sld_dec.jbol, !sld_dec.jbol] = sin(theta2)
;; 20160728 ;;        print, !sld_dec.theta1, !sld_dec.theta2
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     'multi_decouple': multi_decouple

;; 20160728 ;;     'discard': begin
;; 20160728 ;;        wshet, 1
;; 20160728 ;;        print, "!d.window = ", !d.window
;; 20160728 ;;        coor_cursor, x, y, /dev
;; 20160728 ;;        keep = [0]
;; 20160728 ;;        for i=0, n_elements(x)-1 do begin
;; 20160728 ;;           for j=0, n_elements(disp.plot_position1[*,0])-1 do begin
;; 20160728 ;;              if (float(x[i])/!d.x_size ge disp.plot_position1[j,0] and $
;; 20160728 ;;                  float(x[i])/!d.x_size lt disp.plot_position1[j,2] and $
;; 20160728 ;;                  float(y[i])/!d.y_size ge disp.plot_position1[j,1] and $
;; 20160728 ;;                  float(y[i])/!d.y_size lt disp.plot_position1[j,3]) then keep = [keep, j]
;; 20160728 ;;           endfor
;; 20160728 ;;        endfor
;; 20160728 ;;        if n_elements(keep) gt 1 then begin
;; 20160728 ;;           keep = keep[1:*]
;; 20160728 ;;           for i=0, n_elements(keep)-1 do begin
;; 20160728 ;;              if kidpar[keep[i]].type ne 2 then kidpar[keep[i]].type = 5
;; 20160728 ;;           endfor
;; 20160728 ;;        endif
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     'coeff':begin
;; 20160728 ;;        plot_name = "matrix_coeff"
;; 20160728 ;;        apply_coeff, disp.map_list, disp.coeff, kidpar, map_list_out
;; 20160728 ;;        plot_coeff_matrix = 1
;; 20160728 ;;     end

     'beam_stats': ktn_works_event, ev
;; 20160728 ;;     'beam_guess': ktn_works_event, ev
     'fwhm_min':   ktn_works_event, ev
     'fwhm_max':   ktn_works_event, ev
     'ampl_min':   ktn_works_event, ev
     'ampl_max':   ktn_works_event, ev
     'noise_min':   ktn_works_event, ev
     'noise_max':   ktn_works_event, ev
     'ellipt_min': ktn_works_event, ev
     'ellipt_max': ktn_works_event, ev
     'histo_fit' : ktn_works_event, ev

;; 20160728 ;;     'plot_all':begin
;; 20160728 ;;        wshet, ks.drawID1
;; 20160728 ;;        kidpar.plot_flag = 1
;; 20160728 ;;        kidpar[w1].plot_flag = 0
;; 20160728 ;;     end
;; 20160728 ;;     'numdet_min':begin
;; 20160728 ;;        wshet, ks.drawID1
;; 20160728 ;;        kid_selector_event, ev
;; 20160728 ;;     end
;; 20160728 ;;     'numdet_max':begin
;; 20160728 ;;        wshet, ks.drawID1
;; 20160728 ;;        kid_selector_event, ev
;; 20160728 ;;     end
;; 20160728 ;;     'max_noise':begin
;; 20160728 ;;        wshet, ks.drawID1
;; 20160728 ;;        kid_selector_event, ev
;; 20160728 ;;     end
;; 20160728 ;;     'min_response':begin
;; 20160728 ;;        wshet, ks.drawID1
;; 20160728 ;;        kid_selector_event, ev
;; 20160728 ;;     end

     'show_fp':begin
        plot_name = "FP_pos"
        if operations.beam_guess_done eq 0 then do_beam_guess = 1
        do_plot_fp_pos = 1
     end

;; 20160728 ;;     'screen':screening_widget

     'quickview':begin
        disp.nasmyth = 0
        ktn_quickview_widget
     end

     'quickview_nasmyth':begin
        disp.nasmyth = 1
        ktn_quickview_widget
     end

     
;; 20160728 ;;     "otfmap":begin
;; 20160728 ;;        print, "call nk,..."
;; 20160728 ;;        ;; Combine kids on a map with finer resolution
;; 20160728 ;;        ;; Striped down version of nk.pro
;; 20160728 ;;        data1 = data
;; 20160728 ;;        param1 = param
;; 20160728 ;;        param1.do_opacity_correction=0
;; 20160728 ;;        nk_default_info, info1
;; 20160728 ;;        nk_init_grid, param1, info1, grid_tot
;; 20160728 ;;
;; 20160728 ;;        nk_get_kid_pointing, param1, info1, data1, kidpar
;; 20160728 ;;        nk_apply_calib, param1, info1, data1, kidpar
;; 20160728 ;;        nk_deglitch_fast, param1, info1, data1, kidpar
;; 20160728 ;;        nk_get_ipix, data1, info1, grid_tot
;; 20160728 ;;        nk_w8, param1, info1, data1, kidpar
;; 20160728 ;;        nk_projection_3, param1, info1, data1, kidpar, grid_tot
;; 20160728 ;;        map     = grid_tot.map_i_1mm
;; 20160728 ;;        map_var = grid_tot.map_var_i_1mm
;; 20160728 ;;        nhits   = grid_tot.nhits_1mm
;; 20160728 ;;        xx = grid_tot.xmap[*,0]
;; 20160728 ;;        yy = grid_tot.ymap[0,*]
;; 20160728 ;;
;; 20160728 ;;        ;; Derive a mask for decorrelation
;; 20160728 ;;        mask = map*0.d0 + 1
;; 20160728 ;;        w = where( map_var ne 0, nw)
;; 20160728 ;;        if nw eq 0 then message, "No pixel with non zero variance."
;; 20160728 ;;        map_sn = map*0.d0
;; 20160728 ;;        map_sn[w] = map[w]/sqrt(map_var[w])
;; 20160728 ;;        w = where( map_sn gt 5, nw)
;; 20160728 ;;        mask[w] = 0.d0
;; 20160728 ;;
;; 20160728 ;;        ;; Enlarge the mask a bit for safety
;; 20160728 ;;        ;; m = filter_image( mask, fwhm=1)
;; 20160728 ;;        ;; mask = long( m gt 0.99)
;; 20160728 ;;        if param.lab ne 0 then begin
;; 20160728 ;;           kernel = [1.d0, 1.d0]
;; 20160728 ;;           mask1 = mask ; local copy
;; 20160728 ;;           nx = n_elements(mask[*,0])
;; 20160728 ;;           ny = n_elements(mask[0,*])
;; 20160728 ;;           for ix=0, nx-1 do begin
;; 20160728 ;;              mask1[ix,*]    = convol( reform(mask[ix,*]), kernel)/total(kernel)
;; 20160728 ;;              mask1[ix,0]    = mask[ix,0]    ; restore edge
;; 20160728 ;;              mask1[ix,ny-1] = mask[ix,ny-1] ; restore edge
;; 20160728 ;;           endfor
;; 20160728 ;;           mask = long(mask1 eq 1)
;; 20160728 ;;        endif
;; 20160728 ;;
;; 20160728 ;;        grid_tot.mask_source = mask
;; 20160728 ;;        nk_mask_source, param1, info1, data1, kidpar, grid_tot
;; 20160728 ;;        index = dindgen( n_elements(data1))
;; 20160728 ;;        nsn = n_elements(data1)
;; 20160728 ;;        for i=0, nw1-1 do begin
;; 20160728 ;;           ikid = w1[i]
;; 20160728 ;;
;; 20160728 ;;           w = where( data1.off_source[ikid] eq 1, nw)
;; 20160728 ;;
;; 20160728 ;;           ;; force the first/last index to be good anyway to avoid bad
;; 20160728 ;;           ;; interpolation/extrapolation on the edges of the subscans
;; 20160728 ;;           if w[0] ne 0 then w = [0, w]
;; 20160728 ;;           if w[nw-1] ne (nsn-1) then w = [w, nsn-1]
;; 20160728 ;;           r = interpol( data_copy[w].toi[ikid], index[w], index) ; work on original data in Hz
;; 20160728 ;;           data1.toi[ikid] = r ; reuse data1.toi
;; 20160728 ;;        endfor
;; 20160728 ;;
;; 20160728 ;;        ;; Fill kidpar with noise params
;; 20160728 ;;        data2 = data            ; keep a copy
;; 20160728 ;;        data  = data1
;; 20160728 ;;        ktn_noise_estim
;; 20160728 ;;        kidpar.noise_raw_source_interp_1Hz = kidpar.noise_1Hz
;; 20160728 ;;        kidpar.noise_raw_source_interp_2Hz = kidpar.noise_2Hz
;; 20160728 ;;        kidpar.noise_raw_source_interp_10Hz = kidpar.noise_10Hz
;; 20160728 ;;        data = data2 ; restore copy
;; 20160728 ;;        
;; 20160728 ;;        ;; Decorrelate
;; 20160728 ;;        param1.decor_method = 'common_mode_kids_out'
;; 20160728 ;;        nk_deglitch, param1, info1, data1, kidpar
;; 20160728 ;;        nk_clean_data, param1, info1, data1, kidpar, out_temp_data=out_temp_data
;; 20160728 ;;
;; 20160728 ;;        data2 = data ; keep a copy
;; 20160728 ;;        data  = data1
;; 20160728 ;;        ktn_noise_estim
;; 20160728 ;;        kidpar.noise_source_interp_and_decorr_1Hz  = kidpar.noise_1Hz
;; 20160728 ;;        kidpar.noise_source_interp_and_decorr_2Hz  = kidpar.noise_2Hz
;; 20160728 ;;        kidpar.noise_source_interp_and_decorr_10Hz = kidpar.noise_10Hz
;; 20160728 ;;        data = data2 ; restore copy
;; 20160728 ;;        print, "Decorrelation done."
;; 20160728 ;;
;; 20160728 ;;        ;; show combined map
;; 20160728 ;;        data1 = data
;; 20160728 ;;        nk_default_param, param1
;; 20160728 ;;        param1.do_opacity_correction=0
;; 20160728 ;;        nk_default_info, info1
;; 20160728 ;;        nk_init_grid, param1, info1, grid_tot
;; 20160728 ;;
;; 20160728 ;;        nk_get_kid_pointing, param1, info1, data1, kidpar
;; 20160728 ;;        nk_apply_calib, param1, info1, data1, kidpar
;; 20160728 ;;        nk_deglitch_fast, param1, info1, data1, kidpar
;; 20160728 ;;        nk_get_ipix, data1, info1, grid_tot
;; 20160728 ;;        nk_w8, param1, info1, data1, kidpar
;; 20160728 ;;        nk_projection_3, param1, info1, data1, kidpar, grid_tot
;; 20160728 ;;        wind, 1, 1, /free
;; 20160728 ;;        imview, grid_tot.map_i_1mm, xmap=grid_tot.xmap, ymap=grid_tot.ymap
;; 20160728 ;;        print, "otfmap/decorr done."
;; 20160728 ;;
;; 20160728 ;;
;; 20160728 ;;     end

;; 20160728 ;;     "reset": begin
;; 20160728 ;;        data = data_copy
;; 20160728 ;;        print, "reset done"
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     "median_simple":begin
;; 20160728 ;;        print, "starting median filter..."
;; 20160728 ;;        speed = sqrt( deriv(data.ofs_az)^2 + deriv(data.ofs_el)^2)*!nika.f_sampling
;; 20160728 ;;        median_speed = median( speed)
;; 20160728 ;;        decor_median_width = long(10*20.*!fwhm2sigma/median_speed*!nika.f_sampling) ; 5 sigma on each side at about 35 arcsec/s
;; 20160728 ;;        w1 = where( kidpar.type eq 1, nw1)
;; 20160728 ;;        for i=0, nw1-1 do begin
;; 20160728 ;;           ikid = w1[i]
;; 20160728 ;;           baseline = median( data.toi[ikid], decor_median_width)
;; 20160728 ;;           data.toi[ikid] -= baseline
;; 20160728 ;;        endfor
;; 20160728 ;;        print, "median filter done."
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     "outlyers": begin
;; 20160728 ;;        sys_info.outlyers = 1
;; 20160728 ;;        ktn_discard_outlyers
;; 20160728 ;;     end
;; 20160728 ;;     "beamfitnika": sys_info.beam_fit_method = "nika"
;; 20160728 ;;     "beamfitmpfit": sys_info.beam_fit_method = "mpfit"
     
;; 20160728 ;;     "subscan_beams":begin
;; 20160728 ;;        print, "Running subscan beams..."
;; 20160728 ;;        ktn_subscan_beams
;; 20160728 ;;        print, "done."
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     "cmkidout":begin
;; 20160728 ;;        print, "cmkidout..."
;; 20160728 ;;        
;; 20160728 ;;        if defined(info) eq 0 then nk_default_info, info
;; 20160728 ;;
;; 20160728 ;;        d = sqrt( (grid.xmap-sys_info.pos_planet[0])^2 + (grid.ymap-sys_info.pos_planet[1])^2)
;; 20160728 ;;        ;;w = where( d lt 30, nw)
;; 20160728 ;;        w = where( d lt param.decor_cm_dmin, nw)
;; 20160728 ;;        if nw eq 0 then begin
;; 20160728 ;;           message, /info, "Problem with the planet position"
;; 20160728 ;;           stop
;; 20160728 ;;        endif
;; 20160728 ;;        grid.mask_source[w] = 0.d0
;; 20160728 ;;        param.decor_method = "common_mode_kids_out"
;; 20160728 ;;        param.polynomial = 0
;; 20160728 ;;        param.decor_per_subscan = "yes"
;; 20160728 ;;
;; 20160728 ;;        ;; In katana, all kids are refered to the ref pointing
;; 20160728 ;;        dra_copy = data.dra
;; 20160728 ;;        ddec_copy = data.ddec
;; 20160728 ;;        nk_get_kid_pointing, param, info, data, kidpar
;; 20160728 ;;        nk_get_ipix, data, info, grid
;; 20160728 ;;        nk_mask_source, param, info, data, kidpar, grid
;; 20160728 ;;        nk_clean_data, param, info, data, kidpar, out_temp_data=out_temp_data
;; 20160728 ;;
;; 20160728 ;;        ;; Quick check on the projection
;; 20160728 ;;        ;; ;; Allers simples
;; 20160728 ;;        ;; w4 = where( data.scan_st eq 4, nw4) ; & print, nw
;; 20160728 ;;        ;; w5 = where( data.scan_st eq 5, nw5) ; & print, nw
;; 20160728 ;;        ;; for i=0, nw4-1 do begin
;; 20160728 ;;        ;;    w = where( w5 gt w4[i], nw)
;; 20160728 ;;        ;;    if nw ne 0 then begin ; maybe the last subscan is cut off, then discard
;; 20160728 ;;        ;;       imin = min(w)
;; 20160728 ;;        ;;       w8[ w4[i]:w5[imin]] = 1
;; 20160728 ;;        ;;    endif
;; 20160728 ;;        ;; endfor
;; 20160728 ;;        ;; ww = where( w8 eq 0, nww)
;; 20160728 ;;        ;; if nww ne 0 then nk_add_flag, data, 11, ww
;; 20160728 ;;        ;; nk_projection_3, param, info, data, kidpar, grid
;; 20160728 ;;        ;; stop
;; 20160728 ;;
;; 20160728 ;;        data.dra = dra_copy
;; 20160728 ;;        data.ddec = ddec_copy
;; 20160728 ;;        print, "cmkidout done"
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     "calibrate": begin
;; 20160728 ;;        print, "beam calibration..."
;; 20160728 ;;        ktn_beam_calibration, /noplot
;; 20160728 ;;        print, "beam calibration done."
;; 20160728 ;;     end

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

;; 20160728 ;;     'slide_ampl_min':begin
;; 20160728 ;;        w = where( kidpar.type eq 1 and kidpar.a_peak lt ev.value, nw)
;; 20160728 ;;        if nw ne 0 then kidpar[w].plot_flag = 1
;; 20160728 ;;        beam_noplot     = 1
;; 20160728 ;;        plot_beams_stat = 1
;; 20160728 ;;     end
;; 20160728 ;;     'slide_ampl_max':begin
;; 20160728 ;;        w = where( kidpar.type eq 1 and kidpar.a_peak gt ev.value, nw)
;; 20160728 ;;        if nw ne 0 then kidpar[w].plot_flag = 1
;; 20160728 ;;        beam_noplot     = 1
;; 20160728 ;;        plot_beams_stat = 1
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;
;; 20160728 ;;     ;; Frequency band for decorrelation
;; 20160728 ;;     "slide_freq_min": begin
;; 20160728 ;;        disp.freq_min = ev.value
;; 20160728 ;;        disp.do_decorr_filter = 1
;; 20160728 ;;     end
;; 20160728 ;;     "slide_freq_max": begin
;; 20160728 ;;        disp.freq_max = ev.value
;; 20160728 ;;        disp.do_decorr_filter = 1
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     "slide_time_min": begin
;; 20160728 ;;        disp.time_min = ev.value
;; 20160728 ;;        disp.do_decorr_filter = 1
;; 20160728 ;;     end
;; 20160728 ;;     "slide_time_max": begin
;; 20160728 ;;        disp.time_max = ev.value
;; 20160728 ;;        disp.do_decorr_filter = 1
;; 20160728 ;;     end
;; 20160728 ;;
;; 20160728 ;;     'new_decorr':cg_decorr_widget
;; 20160728 ;;     'decorr_display': do_decorr_display = 1
;; 20160728 ;;     'decorr_reset': data.toi = toi_med
;; 20160728 ;;     'smooth_decorr_display': disp.smooth_decorr_display = 1-disp.smooth_decorr_display
;; 20160728 ;;     'decorr':begin
;; 20160728 ;;        ktn_decorr, status
;; 20160728 ;;        if status eq 0 then begin
;; 20160728 ;;           wind, 2, 2, /free, xs=long(!screen_size[0]/3), ys=long(!screen_size[1]*0.75)
;; 20160728 ;;           disp.decorr_window = !d.window
;; 20160728 ;;           do_decorr_display = 1
;; 20160728 ;;        endif
;; 20160728 ;;     end
     ;;-----------------------------------------------------------------------------------------------------------------

  Endcase


  ;;-operations.beam_gues---------------------------------------------------------
  ;; Operations
  operations:

;; 20160728 ;;  if do_decorr_display eq 1 then begin
;; 20160728 ;;
;; 20160728 ;;     if operations.decorr eq 0 then begin
;; 20160728 ;;        ktn_decorr
;; 20160728 ;;        wind, 2, 2, /free, xs=long(!screen_size[0]/3), ys=long(!screen_size[1]*0.75)
;; 20160728 ;;        disp.decorr_window = !d.window
;; 20160728 ;;     endif
;; 20160728 ;;
;; 20160728 ;;     make_ct, disp.nkids, coltable
;; 20160728 ;;     kidpar.color = coltable
;; 20160728 ;;     wshet, disp.decorr_window
;; 20160728 ;;     !x.charsize = 2
;; 20160728 ;;     !y.charsize = 2
;; 20160728 ;;     wshet, disp.decorr_window
;; 20160728 ;;     !p.multi=[0,1,4]
;; 20160728 ;;     ;; time = dindgen( disp.nsn)/!nika.f_sampling/60.
;; 20160728 ;;     disp.time_max = disp.time_max < max(time)
;; 20160728 ;;     w = where( time ge disp.time_min and time le disp.time_max, nw)
;; 20160728 ;;     wplot = where( kidpar.plot_flag eq 0, nwplot)
;; 20160728 ;;     yra = [0,-1] ; init
;; 20160728 ;;
;; 20160728 ;;     for ikid=0, disp.nkids-1 do begin
;; 20160728 ;;        if kidpar[ikid].plot_flag eq 0 then begin
;; 20160728 ;;           if min( data.toi[ikid]) lt yra[0] then yra[0] = min( data.toi[ikid])
;; 20160728 ;;           if max( data.toi[ikid]) gt yra[1] then yra[1] = max( data.toi[ikid])
;; 20160728 ;;        endif
;; 20160728 ;;     endfor
;; 20160728 ;;     ;; plot, time, data.toi[wplot[0]], /xs, /ys, xtitle='Time [mn]', ytitle='Hz', /nodata, yra=yra
;; 20160728 ;;     plot, time, toi_med[wplot[0],*], /xs, /ys, xtitle='Time [mn]', ytitle='Hz', /nodata, yra=yra
;; 20160728 ;;     for ikid=0, disp.nkids-1 do begin
;; 20160728 ;;        ;; if kidpar[ikid].plot_flag eq 0 then oplot, time, data.toi[ikid], col=kidpar[ikid].color
;; 20160728 ;;        if kidpar[ikid].plot_flag eq 0 then oplot, time, toi_med[ikid,*], col=kidpar[ikid].color
;; 20160728 ;;     endfor
;; 20160728 ;;     plots, [disp.time_min, disp.time_min, disp.time_max, disp.time_max, disp.time_min], $
;; 20160728 ;;            [min(toi_med[wplot[0],w]), max(toi_med[wplot[0],w]), max(toi_med[wplot[0],w]), $
;; 20160728 ;;             min(toi_med[wplot[0],w]), min(toi_med[wplot[0],w])], thick=2
;; 20160728 ;;
;; 20160728 ;;     ;; yra = minmax( pw[where(pw ne 0)])*[0.1,10]
;; 20160728 ;;     wf = where( abs(freq-5.) eq min( abs(freq-5.)))
;; 20160728 ;;     wf = wf[0]
;; 20160728 ;;     junk = reform( pw[wplot,wf])
;; 20160728 ;;     yra = avg(junk)*[0.01, 100]
;; 20160728 ;;
;; 20160728 ;;     plot_oo, freq, minmax(pw[wplot[0],*]), xra=minmax(freq), yra=yra, /xs, /ys, xtitle='Freq. [Hz]', ytitle='Hz/Sqrt(Hz)', /nodata
;; 20160728 ;;     ww = where( abs(freq- 5.) lt 0.2, nww)
;; 20160728 ;;     nn = 0
;; 20160728 ;;     junk = 0.d0
;; 20160728 ;;     for ikid=0, disp.nkids-1 do begin
;; 20160728 ;;        if kidpar[ikid].plot_flag eq 0 then begin
;; 20160728 ;;           if long( disp.smooth_decorr_display) ne 0 then begin
;; 20160728 ;;              oplot, freq, sqrt( gausslog_convolve(pw[ikid,*]^2,0.2)), col=kidpar[ikid].color
;; 20160728 ;;           endif else begin
;; 20160728 ;;              oplot, freq, pw[ikid,*], col=kidpar[ikid].color
;; 20160728 ;;           endelse
;; 20160728 ;;           junk += avg( pw[ikid,ww])
;; 20160728 ;;           nn   += 1
;; 20160728 ;;        endif
;; 20160728 ;;     endfor
;; 20160728 ;;     junk /= nn
;; 20160728 ;;     wplot = where( kidpar.plot_flag eq 0, nwplot)
;; 20160728 ;;     ;; legend, kidpar[wplot].name, textcol=kidpar[wplot].color, /bottom, box=0
;; 20160728 ;;     legendastro, ['Decorrelated'], box=0, chars=2, charthick=2, /bottom
;; 20160728 ;;     arrow, 5., junk*10, 5., junk, /data, hsize=!d.x_size/128.
;; 20160728 ;;     xyouts, 5., junk*10, strtrim(string( junk, format="(F6.2)"),2)+"Hz/Hz!u-1/2!n", chars=2, charthick=2
;; 20160728 ;;
;; 20160728 ;;
;; 20160728 ;;     junk = reform( pw_raw[wplot,wf])
;; 20160728 ;;     yra = avg(junk)*[0.01, 100]
;; 20160728 ;;     plot_oo, freq, minmax(pw_raw[wplot[0],*]), xra=minmax(freq), yra=yra, /xs, /ys, xtitle='Freq. [Hz]', ytitle='Hz/Sqrt(Hz)', /nodata
;; 20160728 ;;     nn = 0
;; 20160728 ;;     junk = 0.d0
;; 20160728 ;;     for ikid=0, disp.nkids-1 do begin
;; 20160728 ;;        if kidpar[ikid].plot_flag eq 0 then begin
;; 20160728 ;;           if long( disp.smooth_decorr_display) ne 0 then begin
;; 20160728 ;;              oplot, freq, sqrt( gausslog_convolve(pw_raw[ikid,*]^2,0.2)), col=kidpar[ikid].color
;; 20160728 ;;           endif else begin
;; 20160728 ;;              oplot, freq, pw_raw[ikid,*], col=kidpar[ikid].color
;; 20160728 ;;           endelse
;; 20160728 ;;           junk += avg( pw_raw[ikid,ww])
;; 20160728 ;;           nn   += 1
;; 20160728 ;;        endif
;; 20160728 ;;     endfor
;; 20160728 ;;     junk /= nn
;; 20160728 ;;     wplot = where( kidpar.plot_flag eq 0, nwplot)
;; 20160728 ;;     legendastro, ['Raw'], box=0, chars=2, charthick=2, /bottom
;; 20160728 ;;     arrow, 5., junk*10, 5., junk, /data, hsize=!d.x_size/128.
;; 20160728 ;;     xyouts, 5., junk*10, strtrim( string( junk, format="(F6.2)"), 2)+"Hz/Hz!u-1/2!n", chars=2, charthick=2
;; 20160728 ;;
;; 20160728 ;;
;; 20160728 ;;     plot, [0, 1], [0, 1], /nodata, xs=4, ys=4
;; 20160728 ;;     nkids_per_column = 15
;; 20160728 ;;     ncol = long( disp.nkids/nkids_per_column) + 1
;; 20160728 ;;     p = 0
;; 20160728 ;;     for ikid=0, disp.nkids-1 do begin
;; 20160728 ;;        if kidpar[ikid].plot_flag eq 0 then begin
;; 20160728 ;;           icol  = long( p/nkids_per_column)
;; 20160728 ;;           iline = p mod nkids_per_column
;; 20160728 ;;           oplot,  [icol]*1./ncol+0.02, 0.95-[iline]*1./nkids_per_column, psym=8, col=kidpar[ikid].color
;; 20160728 ;;           xyouts, [icol]*1./ncol+0.03, 0.95-[iline]*1./nkids_per_column, kidpar[ikid].name
;; 20160728 ;;           p++
;; 20160728 ;;        endif
;; 20160728 ;;     endfor
;; 20160728 ;;
;; 20160728 ;;     !p.multi=0
;; 20160728 ;;  endif

;; 20160728 ;;  if do_beam_guess  eq 1 then begin
;; 20160728 ;;     ;;ktn_beam_guess, /noplot
;; 20160728 ;;     ktn_beam_calibration, /noplot
;; 20160728 ;;     plot_beams = 1
;; 20160728 ;;     plot_beams_stat = 1
;; 20160728 ;;  endif

  if plot_beams_stat eq 1 then ktn_beam_stats

  if plot_matrix_display eq 1 then begin
     ;; outplot, file=sys_info.nickname+'_raw_maps', png=png, ps=ps
     ;;ktn_show_matrix, disp.map_list, /nan2zero, kidx=kidpar.x_peak_azel, kidy=kidpar.y_peak_azel
     ktn_show_matrix, kidx=kidpar.x_peak_azel, kidy=kidpar.y_peak_azel
     ;; outplot, /close
  endif

;; 20160728 ;;  if plot_coeff_matrix eq 1 then begin
;; 20160728 ;;     ;; outplot, file=sys_info.nickname+'_map_out', png=png, ps=ps
;; 20160728 ;;     ktn_show_matrix, map_list_out, /nan2zero
;; 20160728 ;;     ;; outplot, /close
;; 20160728 ;;  endif

  if do_plot_fp_pos eq 1 then begin
     ktn_plot_fp
  endif

  if do_quick_view eq 1 then ktn_kid_pop_up

  if do_get_grid_nodes eq 1 then get_grid_nodes, kidpar[wplot].nas_x, kidpar[wplot].nas_y, xnode, ynode, alpha_opt, delta_opt, name=kidpar[wplot].name

;; 20160728 ;;  if disp.check_list ne 0 then show_checklist, !check_list

  exit:
end


pro ktn_widget_light, preproc_index, ptg_numdet_ref, scan_num, day, $
                      no_block=no_block;, check_list=check_list

  common ktn_common
  
;; 20160728 ;;  ;; Create checklist
;; 20160728 ;;  items = ['Discard uncertain kids', $
;; 20160728 ;;           'Grid nodes (check superposition)', $
;; 20160728 ;;           'OTF map', $
;; 20160728 ;;           'Reset data', $
;; 20160728 ;;           'Cmkidout', $
;; 20160728 ;;           'Beam Calibrate', $
;; 20160728 ;;           'Grid nodes (=> grid_step)', $
;; 20160728 ;;           'OTF map', $
;; 20160728 ;;           'Save plots', $
;; 20160728 ;;           'Save kid type', $
;; 20160728 ;;           'Quit']
;; 20160728 ;;  list = create_struct("items", items, $
;; 20160728 ;;                       "status", intarr(n_elements(items)), $
;; 20160728 ;;                       "wind_num", (!my_window>0))
;; 20160728 ;;  defsysv, "!check_list", list

;; 20160728 ;;  if keyword_set(check_list) then disp.check_list = 1
  
  ;; Start widget
  main = widget_base(title='KATANA Light', /row, /frame)

  nkids = n_elements( kidpar)

  ;; Number of buttons etc... to be updated manually for now
  xs_def = 120 ; 140 ; 120
  ys_def = 40

  n_buttons_x = 8; 9
  n_buttons_y = 8; 10
  xs_commands = (n_buttons_x*xs_def*1.1) < (!screen_size[0]*0.5)
  ys_commands = (n_buttons_y*ys_def*1.1) < (!screen_size[1]*0.7)

  ;; update
  xs_def = long( xs_commands/n_buttons_x)
  ys_def = long( ys_commands/n_buttons_y)

  commands = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

;; 20160728 ;;  comm = widget_base( commands, /row, /frame)
;; 20160728 ;;
;; 20160728 ;;  comm1 = widget_base(comm, /col, /frame)
;; 20160728 ;;  b = widget_button( comm1, uvalue='kid_selector',  value=np_cbb( 'Kid Selector', bg='blk7', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
;; 20160728 ;;  b = widget_button( comm1, uvalue='plot_all_kids', value=np_cbb( 'Reset all kids', bg='sea green', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

;; 20160728 ;;  w1 = where( kidpar.type eq 1, nw1)
;; 20160728 ;;  comm1 = widget_base( commands, /row, /frame)
;; 20160728 ;;
;; 20160728 ;;  comm22 = widget_base( comm1, /column, /frame)
;; 20160728 ;;  b = widget_button( comm22, uvalue='outlyers',      value=np_cbb("Outlyers",      bg='navyblue', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  
  ;; Display options
  comm2 = widget_base( commands, /row, /frame)
  comm_1 = widget_base( comm2, /col, /frame)
  value_list = ['Focal Plane', 'Input Matrix',   'Beam Stats'] ;'Apply Coeffs', ]
  uv_list    = ['show_fp',     'matrix_display', 'beam_stats'];'coeff',        ]
  nuv = n_elements(uv_list)
  bgcol = ['blu7',   'blu7',  'blu7'];,  'blu7',  'tg3']
  fgcol = ['white',  'white', 'white'];, 'white', 'black']
  for i=0, nuv-1 do $
     b = widget_button( comm_1, uvalue=uv_list[i], $
                        value=np_cbb( value_list[i], $
                                      bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;; Ways to select kids
  comm_1 = widget_base( comm2, /col, /frame)
  value_list = ['Discard',             'Restore',             'Grid Nodes', 'QVNasm', 'QVazel'];, 'Rotation']
  uv_list    = ['select_kids_discard', 'select_kids_restore', 'gnodes',     'quickview_nasmyth', 'quickview'];, 'rotation']
  nuv = n_elements(uv_list)
  bgcol = ['Pur8', 'Pur8', 'Pur8', 'Pur8', 'Pur8']
  fgcol = ['white',  'white', 'white', 'white', 'white']
  for i=0, nuv-1 do $
     b = widget_button( comm_1, uvalue=uv_list[i], $
                        value=np_cbb( value_list[i], $
                                      bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  ;;-----------------------------------------------------------
  ;; Short cuts to beam analysis
  comm22 = widget_base( comm2, /col, /frame)

  comm1 = widget_base( comm22, /row);, /frame)
  bgc = 'tan8'
  b = widget_button( comm1, uvalue='fwhm_min',   value=np_cbb( 'FWHM min',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm1, uvalue='fwhm_max',   value=np_cbb( 'FWHM max',   bg=bgc, fg=fg, xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

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

  comm_3 = widget_base( comm2, /col, /frame)

  value_list = ['Reverse text color', 'Save plots', "wd, /all"]
  uv_list    = ['textcol',            'save_plots', "wd_all"]
  bgcol      = ['ygb7',               'ygb7',       "ygb7"];'dark slate blue',    'dark slate blue',    'dark slate blue']
  fgcol      = ['white',              'white',      "white"]
  nuv        = n_elements(uv_list)
  for i=0, nuv-1 do $
     b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)

  comm_3 = widget_base( comm2, /col, /frame)
  value_list = ['Pause',  'Save kidpar', 'Quit']
  uv_list    = ['pause',  'save_kidpar',   'quit']
  bgcol      = ['khaki', 'sea green',     'firebrick']
  fgcol      = ['black', 'white',         'white']
  nuv        = n_elements(uv_list)
  for i=0, nuv-1 do $
     b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol[i], xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  

  ;;============================================================================
  ;;================================ Create the widget =========================
  ;;============================================================================
  xoff = long( !screen_size[0]-xs_commands*1.2)  
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands ;; creates the widgets

;; 20160728 ;;  if keyword_set(check_list) then show_checklist, !check_list, /init

  ;; Display kid maps
;  ktn_show_matrix, disp.map_list
  xmanager, 'ktn_widget_light', main, no_block=no_block
   
end
