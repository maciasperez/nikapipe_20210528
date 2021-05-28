;; 120928_09:11:12: before adding "goto's" and "plot all button"
;; 120928_10:44:17: before adding computation if outplot
;;
;; svn version 394(-2?) : derniere version de "my_widget" dans mon labtools qui
;; a migre ici.

PRO nika_widget_event, ev
  common ql_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  wx  = where( x_cross ne !undef, nwx)
  w1  = where( kidpar.type eq 1, nw1)
  w2  = where( kidpar.type eq 2, nw2)
  w3  = where( kidpar.type eq 3, nw3)
  w4  = where( kidpar.type eq 4, nw4)
  w5  = where( kidpar.type eq 5, nw5)
  w13 = where( kidpar.type eq 1 or kidpar.type eq 3, nw13)
  if wplot_init lt 0 then wplot = w1

  do_beam_guess = 0

  plot_nodes_fit        = 0
  plot_fp_anim          = 0
  plot_matrix_display   = 0
  plot_coeff_matrix     = 0
  plot_beams            = 0
  plot_beams_stat       = 0
  do_plot_fp_pos           = 0
  do_quick_view         = 0
  do_interactive_fp_rot = 0

  CASE uvalue OF

     'broadcast':begin
        compilation_dir = !nika.camera_dir+'/programmes/readdata/IDL_so_files/'
        libso = compilation_dir +'IDL_read_data.so'
        w1 = where( kidpar.type eq 1, nw1)

        ;; to debug doubles to long
        kidpar[w1].x_pix = long( x_peaks_1[w1])
        kidpar[w1].y_pix = long( y_peaks_1[w1])
        nn = call_external( libso, "IDL_geo_bcast", long(nw1), kidpar[w1].raw_num, kidpar[w1].x_pix, kidpar[w1].y_pix)
     end


     'intr_fp': begin
        if !check_list.status[1] ne 1 then do_beam_guess = 1
        do_interactive_fp_rot = 1
     end

     'bwrk': beam_works
     
     'nodes_fit': begin
        plot_nodes_fit = 1
        if !check_list.status[1] ne 1 then do_beam_guess = 1
     end

     "numdet_ref":begin
        Numdet_ref = long( Textbox( title='Numdet Ref.', group_leader=ev.top))
        !check_list.status[4] = 1
     end

     'Outplot_all':begin
        plot_matrix_display = 1
        plot_coeff_matrix   = 1
        plot_beams          = 1
        do_plot_fp_pos         = 1
        do_beam_guess       = 1
        do_quick_view       = 1
        
        png = 1
        ps  = 0
     end

     'wplot': begin
        case ev.index of
           0: wplot = indgen(n_elements(kidpar))
           1: wplot = w1
           2: wplot = w3
           3: wplot = w13
        endcase
        wplot_init = 1
     end

     'blind':     kidpar[ibol].type = 0
     'valid':     kidpar[ibol].type = 1
     'off':       kidpar[ibol].type = 2
     'combined':  kidpar[ibol].type = 3
     'mult':      kidpar[ibol].type = 4
     'tbc':       kidpar[ibol].type = 5

     'matrix_display': begin
        !p.color = 255
        !p.background = 0
        plot_matrix_display = 1
     end

     'c_cursor': coor_cursor, x_cross, y_cross, /cross

     'reset_cursor': begin
        x_cross = [double( !undef)]
        y_cross = [double( !undef)]
     end

     'slide_ibol': begin
        ibol = ev.value
        plot_name = "kid_"+strtrim( kidpar[ibol].numdet,2)
        window, 3, xs=800, ys=700, xp=10, yp=500
        outplot, file=nickname+'_map_kid_'+strtrim(ibol,2), png=png, ps=ps
        ;; imview, reform(map_list_ref[ibol,*,*], nx, ny), xmap=xmap, ymap=ymap, udgrade=rebin_factor, $
        ;;         title='Apply Coeff : '+strtrim(kidpar[ibol].numdet,2)+", flag = "+strtrim(kidpar[ibol].type,2), $
        ;;         charsize=1.3
        imview, reform(map_list_ref[ibol,*,*], nx, ny), xmap=xmap, ymap=ymap, udgrade=rebin_factor, $
                legend=['Numdet : '+strtrim(kidpar[ibol].numdet,2), $
                        'Flag = '+strtrim(kidpar[ibol].type,2)], $
                charsize=1.5, title='Coeff applied', leg_color=textcol
        if nwx ne 0 then oplot, x_cross[wx], y_cross[wx], psym=1, thick=2, syms=2
        outplot, /close
     end

     'decouple': begin
        window, 3, xs=800, ys=700, xp=10, yp=500
        slide_decouple_2
        theta1 = !sld_dec.theta1*!dtor
        theta2 = !sld_dec.theta2*!dtor
        coeff[             *, !sld_dec.ibol] = 0.0d0 ; matrix convention
        coeff[             *, !sld_dec.jbol] = 0.0d0
        coeff[ !sld_dec.ibol, !sld_dec.ibol] = cos(theta1)
        coeff[ !sld_dec.jbol, !sld_dec.ibol] = sin(theta1)
        coeff[ !sld_dec.ibol, !sld_dec.jbol] = cos(theta2)
        coeff[ !sld_dec.jbol, !sld_dec.jbol] = sin(theta2)
        print, !sld_dec.theta1, !sld_dec.theta2
     end

     'multi_decouple': multi_decouple

     'discard': begin
        wshet, 1
        print, "!d.window = ", !d.window
        coor_cursor, x, y, /dev
        keep = [0]
        for i=0, n_elements(x)-1 do begin
           for j=0, n_elements(kid_plot_position[*,0])-1 do begin
              if (float(x[i])/!d.x_size ge kid_plot_position[j,0] and $
                  float(x[i])/!d.x_size lt kid_plot_position[j,2] and $
                  float(y[i])/!d.y_size ge kid_plot_position[j,1] and $
                  float(y[i])/!d.y_size lt kid_plot_position[j,3]) then keep = [keep, j]
           endfor
        endfor
        if n_elements(keep) gt 1 then begin
           keep = keep[1:*]
           for i=0, n_elements(keep)-1 do begin
              if kidpar[keep[i]].type ne 2 then kidpar[keep[i]].type = 5
           endfor
        endif
        !check_list.status[0] = 1
     end

     'coeff':begin
        plot_name = "matrix_coeff"
        apply_coeff, map_list_ref, coeff, kidpar, map_list_out
        plot_coeff_matrix = 1
     end

     'beam_stats': begin
        plot_beams_stat = 1
        if !check_list.status[1] ne 1 then do_beam_guess = 1
     end
     
     'show_fp':begin
        plot_name = "FP_pos"
        if !check_list.status[1] ne 1 then do_beam_guess = 1
        do_plot_fp_pos = 1
     end

     'rotate_fp':begin
        plot_name = "FP_pos"
        alpha_fp = ev.value
        plot_fp_anim = 1
        !check_list.status[2] = 1
     end

     'gross_fp':begin
        plot_name = "FP_pos"
        delta_fp = ev.value
        plot_fp_anim = 1
        !check_list.status[3] = 1
     end

     'save_exit':begin

        ;; make sure version match at 1 and 2mm in case we did not run one of
        ;; the two and make sure there's a copy of each with the same version number
        name = !nika.save_dir+"/"+ext+"_"+string(scan_num,format='(I4.4)')+'_'+day
        extension = ".save"
        get_version, name, extension, version
        version = long( version + 1) ; increment       
        kidpar_save_file = !nika.save_dir+"/"+ext+"_"+string(scan_num,format='(I4.4)')+'_'+day+"_v"+strtrim(version,2)+".save"

        ;get_x0y0, x_peaks_1[wplot], y_peaks_1[wplot], xc0, yc0, ww
        ;ikid_ref = wplot[ww]

        ;; Center on Reference Numdet
        ;; to be done in otf_geometry
        ikid_ref = where( kidpar.numdet eq numdet_ref)
        ;; w = where( kidpar.x_pix ne !undef)
        ;; kidpar[w].x_pix -= kidpar[ikid_ref].x_pix
        ;; kidpar[w].y_pix -= kidpar[ikid_ref].y_pix
        ;; kidpar[w].nas_x -= kidpar[ikid_ref].nas_x
        ;; kidpar[w].nas_y -= kidpar[ikid_ref].nas_y

        save, numdet_ref, ikid_ref, coeff, kidpar, file=kidpar_save_file
        print, "Saved kidpar to "+kidpar_save_file
        print, ""
        banner, "Remember I just found alpha_fp = "+$
                strtrim(alpha_fp,2)+" deg for the "+strtrim(lambda,2)+"mm...", n=2
        print, "Done with select kids"
        exit
     end


     'remove_string': remove_string
     'recover_string': map_list_out = map_list_out_0

     'quit': begin
        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end

     'Snapshot': png, plot_dir+"/"+nickname+"_"+plot_name+"_snapshot.png"

     'textcol': textcol = 255-textcol
     'quickview': begin
        do_quick_view = 1
        if !check_list.status[1] ne 1 then do_beam_guess = 1
     end

  Endcase


  ;;----------------------------------------------------------
  ;; Operations
  operations:
  if do_beam_guess   eq 1 then begin
     nika_beam_guess
     !check_list.status[1] = 1
     plot_beams = 1
     plot_beams_stat = 1
  endif

  if plot_beams_stat eq 1 then show_beam_stats

;;  if plot_fp_anim eq 1 then begin
;;        plot_name = "FP_pos"
;;
;;        x11 = ( cos(alpha_fp*!dtor)*x_peaks_1[wplot] + sin(alpha_fp*!dtor)*y_peaks_1[wplot])/delta_fp
;;        y11 = (-sin(alpha_fp*!dtor)*x_peaks_1[wplot] + cos(alpha_fp*!dtor)*y_peaks_1[wplot])/delta_fp
;;        get_x0y0, x11, y11, xc0, yc0
;;        x11 = x11 - xc0
;;        y11 = y11 - yc0
;;        kidpar[wplot].x_pix = round(x11)
;;        kidpar[wplot].y_pix = round(y11)
;;
;;        if nw3 ne 0 then begin
;;           x3 = ( cos(alpha_fp*!dtor)*x_peaks_1[w3] + sin(alpha_fp*!dtor)*y_peaks_1[w3])/delta_fp
;;           y3 = (-sin(alpha_fp*!dtor)*x_peaks_1[w3] + cos(alpha_fp*!dtor)*y_peaks_1[w3])/delta_fp
;;           x3 = x3 - xc0
;;           y3 = y3 - yc0
;;           kidpar[w3].x_pix = round(x3)
;;           kidpar[w3].y_pix = round(y3)
;;        endif
;;
;;        xra_width = (max(x11)-min(x11))
;;        yra_width = (max(y11)-min(y11))
;;        xra2 = (min(x11)+max(x11))/2. + [-1,1]*xra_width/2.*1.2
;;        yra2 = (min(y11)+max(y11))/2. + [-1,1]*yra_width/2.*1.2
;;        ;xra2 = xra_plot
;;        ;yra2 = yra_plot
;;        wshet, 1
;;        outplot, file=nickname+'_rotate_fp', png=png, ps=ps
;;        plot, x11, y11, /iso, psym=1, title='Alpha_fp = '+strtrim(alpha_fp,2)+', Delta='+strtrim(delta_fp,2), $
;;              xra=xra2, yra=yra2, syms=2, /xs, /ys, chars=1.5
;;        oplot, kidpar[wplot].x_pix, kidpar[wplot].y_pix, psym=8, col=70
;;        xyouts, x11, y11, strtrim(kidpar[wplot].numdet,2), col=250, chars=1.5
;;        for i=min( long([xra2[0], yra2[0]]))-1, max(long([xra2[1], yra2[1]]))+1 do begin
;;           oplot, [i,i], yra2, line=1
;;           oplot, xra2, [i,i], line=1
;;        endfor        
;;        oplot, x11, y11, psym=1, thick=2, col=250
;;        legendastro, [box+strtrim(lambda,2)+"mm", $
;;                      'N columns = '+strtrim( long(max(kidpar[wplot].x_pix)-min(kidpar[wplot].x_pix)+1),2), $
;;                      'N lines   = '+strtrim( long(max(kidpar[wplot].y_pix)-min(kidpar[wplot].y_pix)+1),2)], box=0, chars=3, thick=2
;;        outplot, /close
;;        ;!check_list.status[2] = 1
;;  endif

  if do_interactive_fp_rot eq 1 then interactive_fp_rot


  if plot_nodes_fit eq 1 then begin
     
     ;; get approx center pix
     get_x0y0, x_peaks_1[wplot], y_peaks_1[wplot], xc0, yc0, ww

     ;; Redefine positions to this pixel
     x_offset = x_peaks_1[wplot] - xc0 ; x_peaks_1[ww[0]]
     y_offset = y_peaks_1[wplot] - yc0 ; y_peaks_1[ww[0]]
     
     ;; Rotate by the approx matrix angle to make pixel to grid-node association
     ;; easier
     gna      = cos(-!nika.array[ilambda].alpha_fp_deg*!dtor)*x_offset - sin(-!nika.array[ilambda].alpha_fp_deg*!dtor)*y_offset
     y_offset = sin(-!nika.array[ilambda].alpha_fp_deg*!dtor)*x_offset + cos(-!nika.array[ilambda].alpha_fp_deg*!dtor)*y_offset
     x_offset = gna
     delvarx, gna

     wind, 1, 1, /free
     plot, x_offset, y_offset, psym=1, /iso

     ;; Brute force loop to look for good first guess for grid position:
     alpha_Start = -5
     alpha_end   =  5            ; deg
     delta_alpha =  1            ; deg

     step_start  = 1
     step_end    = 20 ; we know that the magnification is between 0.5 and 1.5

     offset_x_start = -10
     offset_x_end   =  10
     offset_y_start = -10
     offset_y_end   =  10

     dmin = 1d6                 ; dummy init
     for alpha=alpha_start, alpha_end do begin
        percent_status, alpha, alpha_end-alpha_start+1, 10, /bar
        for istep=step_start, step_end do begin
           step = istep*0.05
           for i_offset_x=offset_x_start, offset_x_end do begin
              offset_x = i_offset_x*0.1
              for i_offset_y=offset_y_start, offset_y_end do begin
                 offset_y = i_offset_y*0.1

                 ;; rotate the measured position back (clockwise) to (x,y) basis
                 x_try = offset_x + step*( cos(-alpha*!dtor)*x_offset - sin(-alpha*!dtor)*y_offset)
                 y_try = offset_y + step*( sin(-alpha*!dtor)*x_offset + cos(-alpha*!dtor)*y_offset)
                 
                 ;; compute distance to the nearest integer node
                 xnode = round( x_try)
                 ynode = round( y_try)
                 d = total( (x_try-xnode)^2 + (y_try-ynode)^2)
                 if d lt dmin then begin
                    alpha_opt = alpha
                    step_opt  = step
                    offset_x_opt = offset_x
                    offset_y_opt = offset_y
                    dmin = d
                 endif
              endfor
           endfor
        endfor
     endfor

     print, "alpha_opt, step_opt, offset_x_opt, offset_y_opt: ", alpha_opt, step_opt, offset_x_opt, offset_y_opt

     x_try = offset_x_opt + step_opt*( cos(-alpha_opt*!dtor)*x_offset - sin(-alpha_opt*!dtor)*y_offset)
     y_try = offset_y_opt + step_opt*( sin(-alpha_opt*!dtor)*x_offset + cos(-alpha_opt*!dtor)*y_offset)
     xnode = round( x_try)
     ynode = round( y_try)
     
     ;; Best fit
     grid_fit_5, xnode, ynode, x_offset, y_offset, $
                 delta_fp, alpha_fp, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, /noplot, /nowarp

     x_out = 1./delta_fp*( cos(-alpha_fp*!dtor)*x_offset - sin(-alpha_fp*!dtor)*y_offset) + nas_center_x
     y_out = 1./delta_fp*( sin(-alpha_fp*!dtor)*x_offset + cos(-alpha_fp*!dtor)*y_offset) + nas_center_y

     ;; plot best fit in grid coordinates for clarity
     wind, 1, 1, /free, /large
     plot, xnode, ynode, /iso, /nodata, $
           title='alpha_opt = '+strtrim(alpha_fp,2)+' deg, Delta_opt = '+strtrim(delta_fp,2), $
           /noerase, xra=minmax(xnode)+[-1,1], yra=minmax(ynode)+[-1,1]
     oplot, xnode, ynode, psym=8, col=70
     for i=min( [xnode, ynode])-1, max([xnode,ynode])+1 do begin
        oplot, [i,i], minmax(ynode), line=1
        oplot, minmax(xnode), [i,i], line=1
     endfor        
     oplot, x_out, y_out, col=250, psym=1
     xyouts, x_out, y_out, strtrim(kidpar[wplot].numdet,2), col=250, chars=1.3

     kidpar[wplot].x_pix = xnode
     kidpar[wplot].y_pix = ynode

  endif

  if plot_matrix_display eq 1 then begin
     outplot, file=nickname+'_raw_maps', png=png, ps=ps
     show_matrix, map_list_ref
     outplot, /close
  endif

  if plot_coeff_matrix eq 1 then begin
     outplot, file=nickname+'_map_out', png=png, ps=ps
     show_matrix, map_list_out
     outplot, /close
  endif

  if do_plot_fp_pos eq 1 then begin
     give_noise_estim
     plot_fp_pos
  endif

  if do_quick_view eq 1 then my_kid_popup

;  if checklist eq 1 then show_checklist, !check_list

  print, "Next ?"

  exit:
end


pro reduce_map_widget

;;pro my_widget
  common ql_maps_common


  ;; Create checklist
  items = ['1. Discard uncertain kids', $
           '2. Beam guess to get positions and calibration', $
           '3. Rotate focal plane', $
           '4. Adjust grid step', $
           '5. Choose Numdet ref', $
           '6. Press Save and exit']
  list = create_struct("items", items, $
                       "status", intarr(n_elements(items)), $
                       "wind_num", (!my_window>0))
  defsysv, "!check_list", list


  plot_name = "plot"
  nkids = n_elements( map_list_ref[*,0,0])
  nx    = n_elements( map_list_ref[0,*,0])
  ny    = n_elements( map_list_ref[0,0,*])

  main = widget_base (title='NIKA', /row, /frame)

  ;; Slider on kid number
  xs_commands = 620
  commands = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)
  sld = widget_slider( commands, title='Select one kid', min=0, max=nkids-1, $
                       scroll=1, value=0, uval='slide_ibol', xsize=400, /drag) ; slider 

  ;;-----------------------------------------------------------
  xs = 90
  ys = 50
  comm_0 = widget_base( commands, /row, /frame)
  value_list = ['BLIND', 'Valid', 'Off resonance', 'Combined', 'Mult', 'TBC']
  uv_list    = ['blind', 'valid', 'off', 'combined', 'mult', 'tbc']
  nuv = n_elements(uv_list)
  bgcol = 'rosy brown'
  fgcol = 'black'
  for i=0, nuv-1 do b = widget_button( comm_0, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol, fg=fgcol, xs=xs, ys=ys), xs=xs, ys=ys)
  if (nuv*xs) gt xs_commands then xs_commands = nuv*xs

  ;;-----------------------------------------------------------
  xs = 100
  ys = 100
  comm_01 = widget_base( commands, /row, /frame)
  value_list = ['Coor. Cursor',  'Reset cursor',  'Double Decouple', 'Multi Decouple', 'Discard kids']
  uv_list    = ['c_cursor', 'reset_cursor', 'decouple', 'multi_decouple', 'discard']
  nuv = n_elements(uv_list)
  bgcol = 'burlywood'
  fgcol = 'black'
  for i=0, nuv-1 do b = widget_button( comm_01, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol, fg=fgcol, xs=xs, ys=ys), xs=xs, ys=ys)
  if (nuv*xs) gt xs_commands then xs_commands = nuv*xs
  
  ;;-----------------------------------------------------------
  comm_1 = widget_base( commands, /row, /frame)
  value_list = ['Input Matrix','Apply Coeffs','Rem. String', 'Recov. String']
  uv_list    = ['matrix_display', 'coeff', 'remove_string', 'recover_string']
  nuv = n_elements(uv_list)
  bgcol = 'steel blue'
  fgcol = 'white'
  for i=0, nuv-1 do b = widget_button( comm_1, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol, fg=fgcol, xs=xs, ys=ys), xs=xs, ys=ys)
  if (nuv*xs) gt xs_commands then xs_commands = nuv*xs
  
  ;;-----------------------------------------------------------
  comm_2 = widget_base( commands, /row, /frame)
  xs = 120
  ys = 70
  value_list = ['Beam Works', 'Beams Stat', 'Numdet Ref', 'Reverse text color']
  uv_list    = ['bwrk',       'beam_stats', 'numdet_ref', 'textcol']
  nuv        = n_elements(uv_list)
  bgcol      = replicate('dark slate blue', nuv)
  fgcol      = 'white'
  for i=0, nuv-1 do b = widget_button( comm_2, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], xs=xs, ys=xs), xs=xs, ys=ys)

  ;;-----------------------------------------------------------
  comm_25 = widget_base( commands, /row, /frame)
  xs = 120
  ys = 70
  value_list = ['Nodes fit', 'Show FP',  'Quick view', 'Outplot all',  'Interactive FP']
  uv_list    = ['nodes_fit', 'show_fp', 'quickview', 'Outplot_all', 'intr_fp']
  nuv = n_elements(uv_list)
  bgcol = 'purple'
  fgcol = 'white'
  for i=0, nuv-1 do b = widget_button( comm_25, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol, fg=fgcol, xs=xs, ys=ys), xs=xs, ys=ys)
  if (nuv*xs) gt xs_commands then xs_commands = nuv*xs

  ilambda = where( !nika.lambda eq lambda)

  ;;----------------------------------------------------------
  comm_3 = widget_base( commands, /row, /frame)
  ;value_list = ['Numdet Ref', 'SaveExit', 'Reverse text color', 'Quit']
  ;uv_list    = ['numdet_ref', 'save_exit', 'textcol',  'quit']
  ;bgcol      = ['dark slate blue', 'sea green', 'dark slate blue', 'firebrick']
  value_list = ['Broadcast Geometry', 'SaveExit',  'Quit']
  uv_list    = ['broadcast', 'save_exit', 'quit']
  nuv = n_elements(uv_list)
  bgcol      = ['dark slate blue', 'sea green', 'firebrick']
  fgcol      = 'white'
  for i=0, nuv-1 do b = widget_button( comm_3, uvalue=uv_list[i], value=np_cbb( value_list[i], bg=bgcol[i], fg=fgcol, xs=xs, ys=ys), xs=xs, ys=ys)
  if (nuv*xs) gt xs_commands then xs_commands = nuv*xs


  ;;--------------------------------------------------------------
  my_screen_size = get_screen_size()
  xs_commands = xs_commands * 1.05
  xoff = long( my_screen_size[0]-xs_commands)
  widget_control, main, /realize, xoff=xoff, xs=xs_commands ;; creates the widgets

  show_matrix, map_list_ref

;  if checklist eq 1 then show_checklist, !check_list, /init

  xmanager, 'nika_widget', main, no_block=no_block ; no_block = 0 => wait for events
  
  numdet_ref = -1 ; init
  wshet, 1

end
