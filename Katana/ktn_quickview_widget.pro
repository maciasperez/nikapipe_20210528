
pro ktn_quickview_widget_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue
  tags = tag_names(ev)
  
  w1    = where( kidpar.type eq 1, nw1)
  w3    = where( kidpar.type eq 3, nw3)
  wplot = where( kidpar.plot_flag eq 0, nwplot)

  if disp.nasmyth eq 0 then begin
     kidpar.x_peak = kidpar.x_peak_azel
     kidpar.y_peak = kidpar.y_peak_azel
  endif else begin
     kidpar.x_peak = kidpar.x_peak_nasmyth
     kidpar.y_peak = kidpar.y_peak_nasmyth
  endelse

  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, ciao
        end
        "discard": kidpar[disp.ikid].plot_flag = 1
        "reset": begin
           kidpar.plot_flag = 1
           kidpar[w1].plot_flag = 0
        end
     endcase
  endif

  ;; Display current focal plane, ready to take actions
;  message, /info, "avant"
  wset, kquick.drawID1
  ktn_quickview_display, xra_plot, yra_plot, nasmyth=disp.nasmyth, ikid_in=disp.ikid

  ;; Take actions
  IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
     xy = convert_coord( ev.x, ev.y, /device, /to_data)
     xcursor = xy[0]
     ycursor = xy[1]
     if xcursor ge min( xra_plot) and xcursor le max( xra_plot) and $
        ycursor ge min( yra_plot) and ycursor le max( yra_plot) then begin
        d2 = (kidpar[wplot].x_peak-xcursor)^2 + (kidpar[wplot].y_peak-ycursor)^2
        disp.ikid = wplot[ (where( d2 eq min(d2)))[0]]
        ;; discard
        if ev.release eq 4 then kidpar[disp.ikid].plot_flag = 1
     endif
  ENDIF

  ;; Display updated focal plane
  wset, kquick.drawID1
  ktn_quickview_display, ikid_in=disp.ikid, nasmyth=disp.nasmyth

  ;; Compare rotation of Nasmyth to azel to check for outlyers
  d = sqrt( kidpar.nas_x^2 + kidpar.nas_y^2)
  ww = where(kidpar.type eq 1 and kidpar.plot_flag eq 0, nww)
  if nww eq 0 then begin
     message, /info, "No valid kid with plot_flag eq 0 ?"
     stop
  endif
  dmin = min( d[ww])
  ww1 = where( d eq dmin and kidpar.type eq 1 and kidpar.plot_flag eq 0, nww1)
  if nww1 eq 0 then begin
     message, /info, "I can't find the central kid ?"
     stop
  endif
  ptg_numdet_ref = kidpar[ww1[0]].numdet

  ;; Fit rotation and mangnification
  w1 = where( kidpar.type eq 1 and kidpar.plot_flag eq 0, nw1, compl=wbad, ncompl=nwbad)
  grid_fit_5, kidpar[w1].nas_x, kidpar[w1].nas_y, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, /nowarp, $
              delta_out, alpha_rot_deg, nas_center_x, nas_center_y, xc_0, yc_0, kx, ky, xfit, yfit, names=names, $
              title = 'grid_fit_5', /noplot, distance=distance

  ;; new variables for convenience and indices
  xfit1 = dblarr( n_elements(kidpar))
  yfit1 = dblarr( n_elements(kidpar))
  xfit1[w1] = xfit
  yfit1[w1] = yfit

  wind, 1, 1
  dx = max(kidpar[w1].x_peak_azel)-min(kidpar[w1].x_peak_azel)
  xra = minmax(kidpar[w1].x_peak_azel) + [-1, 1]*0.2*dx
  dy = max(kidpar[w1].y_peak_azel)-min(kidpar[w1].y_peak_azel)
  yra = minmax(kidpar[w1].y_peak_azel) + [-1, 1]*0.2*dy
  plot, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, /iso, psym=1, xra = xra, yra = yra
  oplot, xfit, yfit, psym=4, col=70
  oplot, [kidpar[disp.ikid].x_peak_azel], [kidpar[disp.ikid].y_peak_azel], psym = 1, col = 150, thick = 2
  oplot, [xfit1[disp.ikid]], [yfit1[disp.ikid]], psym=4, col=250, thick=2
  arrow, kidpar[w1].x_peak_azel, kidpar[w1].y_peak_azel, xfit,  yfit, hsize = 0.5, /data
  legendastro, ['Azel','Nas to Azel','Current kid'], psym=[1,4,4], $
               col=[!p.color,70,250], box=0, textcol=[!p.color,70,250]


ciao:
end


pro ktn_quickview_widget, nasmyth=nasmyth
  common ktn_common

  ;; Widget size
  xs_commands = round(!screen_size[0]*0.8)
  ys_commands = round(!screen_size[1]*0.8)

  ;; button size
  xs_def = 100
  ys_def = 50

  ;; Focal plane view
  nxpix = 800 ;< long( (xs_commands-1.3*xs_def)*2./3)
  nypix = 800 ;< long( ys_commands*0.8)

  ;; Create widget
  main = widget_base( title='Quickview', /row, /frame)

  comm0  = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

  comm1  = widget_base( comm0, /row, /frame, xsize=xs_commands)
  display_draw1 = widget_draw( comm1, xsize=nxpix, ysize=nypix, /button_events)

  comm11 = widget_base( comm1, /column, /frame, xsize=nxpix/2, ysize=nypix)

  comm12 = widget_base( comm11, /column, /frame, xsize=xs_def*1.2)
  b = widget_button( comm12, uvalue='reset',   value=np_cbb( 'Reset Plot kids', bg='sea green', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm12, uvalue='quit',    value=np_cbb( 'Quit',            bg='firebrick', fg='white', xs=xs_def, ys=xs_def), xs=xs_def, ys=ys_def)

  ;; Realize the widget
  xoff = long(0.1*!screen_size[0])    ;-xs_commands*1.3
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands
  widget_control, display_draw1, get_value=drawID1
  kquick = {drawID1:drawID1};, drawID2:drawID2, drawID3:drawID3, drawID4:drawID4}
  xmanager, "ktn_quickview_widget", main, /no_block

  ;; Init plot
  wset, kquick.drawID1
  ktn_quickview_display, nasmyth=disp.nasmyth

end
