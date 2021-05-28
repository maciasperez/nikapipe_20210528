
pro show_ikid_properties_3_event, ev
  common bt_maps_common


  widget_control, ev.id, get_uvalue=uvalue

  tags = tag_names( ev)

  if defined(uvalue) then begin

     case uvalue of
        'valid': kidpar[disp.ikid].type = 1
        'off'  : kidpar[disp.ikid].type = 2
        'tbc'  : kidpar[disp.ikid].type = 5

        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end
     endcase

  endif


exit:
end


pro show_ikid_properties_3
  common bt_maps_common

  ;; window size
  nxpix = 600 < long( !screen_size[0]*0.7)
  nypix = 600 < long( !screen_size[1]*0.7)

  ;; Create widget
  main = widget_base( title='Kid '+strtrim(disp.ikid,2)+" / Numdet "+strtrim( kidpar[disp.ikid].numdet,2), /col, /frame)

  xsize    = (nxpix+300) < long( !screen_size[0]*0.9)
  commands = widget_base( main, /column, /frame, xsize=xsize, ysize=ys_commands)
  comm     = widget_base( commands, /row, /frame)

  display_draw1     = widget_draw( comm, xsize=nxpix, ysize=nypix)

  xs = 100
  ys = 70
  comm1 = widget_base( comm, /col, /frame)
  b = widget_button( comm1, uvalue='valid', value=np_cbb('valid', bg='blue', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm1, uvalue='off',   value=np_cbb('Off',   bg='blue', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm1, uvalue='tbc',   value=np_cbb('TBC',   bg='blue', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm1, uvalue='quit', value=np_cbb( 'Quit', bg='firebrick', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)

  ;; Realize the widget
  xoff = !screen_size[0]-xsize*1.3

  widget_control, main, /realize, xoff=xoff, xs=xsize
  widget_control, display_draw1, get_value=drawID1

  wset, drawID1

  dxmap = max(disp.xmap)-min(disp.xmap)
  dymap = max(disp.ymap)-min(disp.ymap)
  xmin = min(disp.xmap)
  ymin = min(disp.ymap)
  ymax = max(disp.ymap)

  imview, reform( disp.map_list[disp.ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, $
          udg=rebin_factor, /nobar, xchars=1e-6, ychars=1e-6

  xx = xmin+0.1*dxmap
  yy = ymin+0.1*dymap
  decode_flag, kidpar[disp.ikid].type, flagname
  xyouts, xx, yy, flagname, chars=1.5, col=disp.textcol
           
  yy = ymax-0.2*dymap
  xyouts, xx, yy, strtrim( kidpar[disp.ikid].numdet,2), col=disp.textcol

  xmanager, 'show_ikid_properties_3', main, /no_block

end

