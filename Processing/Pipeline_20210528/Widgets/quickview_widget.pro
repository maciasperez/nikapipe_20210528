
pro quickview_widget_event, ev
  common bt_maps_common

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
     print, "uvalue = ", uvalue
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end

        "discard": kidpar[disp.ikid].plot_flag = 1

        "reset": begin
           kidpar.plot_flag = 1
           kidpar[w1].plot_flag = 0
        end
        
     endcase
  endif

  wset, kquick.drawID1
  quickview_display, xra_plot, yra_plot, nasmyth=disp.nasmyth

  IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
     xy = convert_coord( ev.x, ev.y, /device, /to_data)
     xcursor = xy[0]
     ycursor = xy[1]
     if xcursor ge min( xra_plot) and xcursor le max( xra_plot) and $
        ycursor ge min( yra_plot) and ycursor le max( yra_plot) then begin

        ;; d2 = (kidpar.x_peak-xcursor)^2 + (kidpar.y_peak-ycursor)^2
        d2 = (kidpar[wplot].x_peak-xcursor)^2 + (kidpar[wplot].y_peak-ycursor)^2
        disp.ikid = wplot[where( d2 eq min(d2))]

        ;; discard
        if ev.release eq 4 then kidpar[disp.ikid].plot_flag = 1

     endif
  ENDIF

  wset, kquick.drawID1
  quickview_display, ikid_in=disp.ikid, nasmyth=disp.nasmyth

  fmt="(F9.2)"
  wset, kquick.drawID2
  imview, reform( disp.map_list[disp.ikid,*,*]), xmap=xmap, ymap=ymap, $
          udg=rebin_factor, $ ;title="iKid "+strtrim(disp.ikid,2), $
          legend_text=['Numdet : '+strtrim(kidpar[disp.ikid].numdet,2), $
                       'Name : '+kidpar[disp.ikid].name, $
                       'Flag = '+strtrim(kidpar[disp.ikid].type,2)], leg_color=255
  legendastro, "ikid = "+strtrim(disp.ikid,2), /right, box=0, textcol=255
      
  wset, kquick.drawID3
  imview, reform( disp.beam_list[disp.ikid,*,*]), xmap=xmap, ymap=ymap, $
          udg=rebin_factor, $;title="iKid "+strtrim(disp.ikid,2), $
          legend_text=['Numdet : '+strtrim(kidpar[disp.ikid].numdet,2), $
                       'Name : '+kidpar[disp.ikid].name, $
                       'Flag = '+strtrim(kidpar[disp.ikid].type,2)], leg_color=255
  legendastro, "ikid = "+strtrim(disp.ikid,2), /right, box=0, textcol=255
  legendastro, ['Resp.: '+string( kidpar[disp.ikid].response,format=fmt)+" mK/Hz", $
                'FWHM: '+string( sqrt( kidpar[disp.ikid].sigma_x*kidpar[disp.ikid].sigma_y)/!fwhm2sigma, format=fmt)], $
               box=0, /bottom, textcol=255

  wset, kquick.drawID4
  show_ikid_properties_2

exit:
end


pro quickview_widget, nasmyth=nasmyth
  common bt_maps_common


  xs_commands = !screen_size[0]*0.5
  ys_commands = !screen_size[1]*0.8

  xs_def = 100
  ys_def = 100
  nxpix = 500 < long( (xs_commands-1.3*xs_def)*2./3)
  nypix = 500 < long( ys_commands/2.)

  ;; Create widget
  main = widget_base( title='Quickview', /row, /frame)

  ;; button size
  comm0  = widget_base( main, /column, /frame, xsize=xs_commands, ysize=ys_commands)

  comm1  = widget_base( comm0, /row, /frame, xsize=xs_commands)
  display_draw1 = widget_draw( comm1, xsize=nxpix, ysize=nypix, /button_events)

  comm11 = widget_base( comm1, /column, /frame, xsize=nxpix/2, ysize=nypix)
  display_draw2 = widget_draw( comm11, xsize=nxpix/2, ysize=nypix/2)
  display_draw3 = widget_draw( comm11, xsize=nxpix/2, ysize=nypix/2)

  comm12 = widget_base( comm1, /column, /frame, xsize=xs_def*1.2)
  b = widget_button( comm12, uvalue='reset',   value=np_cbb( 'Reset Plot kids', bg='sea green', fg='white', xs=xs_def, ys=ys_def), xs=xs_def, ys=ys_def)
  b = widget_button( comm12, uvalue='quit',    value=np_cbb( 'Quit',            bg='firebrick', fg='white', xs=xs_def, ys=xs_def), xs=xs_def, ys=ys_def)

  display_draw4 = widget_draw( comm0, xsize=nxpix*1.5, ysize=nypix)

  ;; Realize the widget
  xoff = !screen_size[0]-xs_commands*1.3
  widget_control, main, /realize, xoff=xoff, xs=xs_commands, ys=ys_commands
  widget_control, display_draw1, get_value=drawID1
  widget_control, display_draw2, get_value=drawID2
  widget_control, display_draw3, get_value=drawID3
  widget_control, display_draw4, get_value=drawID4
  kquick = {drawID1:drawID1, drawID2:drawID2, drawID3:drawID3, drawID4:drawID4}
  xmanager, "quickview_widget", main, /no_block

  ;; Init plot
  wset, kquick.drawID1
  quickview_display, nasmyth=disp.nasmyth

end
