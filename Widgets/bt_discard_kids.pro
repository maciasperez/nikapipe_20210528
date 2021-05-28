

PRO bt_discard_kids_event, ev
  common bt_maps_common

  widget_control, ev.id, get_uvalue=uvalue
  tags = tag_names( ev)

  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end
     endcase

  endif else begin
     
     IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
        x = float(ev.x)/disp.xsize_matrix
        y = float(ev.y)/disp.ysize_matrix
        for j=0, n_elements( disp.plot_position1[*,0])-1 do begin
           if (float(x) ge disp.plot_position1[j,0] and $
               float(x) lt disp.plot_position1[j,2] and $
               float(y) ge disp.plot_position1[j,1] and $
               float(y) lt disp.plot_position1[j,3]) then begin
              disp.ikid = j

              message, /info, "kidpar[disp.ikid].numdet = "+strtrim( kidpar[disp.ikid].numdet,2)
              ;; kidpar[disp.ikid].type = 5
              kidpar[disp.ikid].plot_flag = 1
           endif
        endfor
     endif

  endelse

exit:
end


PRO bt_discard_kids
  common bt_maps_common

  ;; window size
  nxpix = 800 < long( !screen_size[0]*0.9)
  nypix = 800 < long( !screen_size[1]*0.9)

  ;; Create widget
  main = widget_base( title='Discard kids', /col, /frame)

  display_draw1 = widget_draw( main, xsize=nxpix, ysize=nypix, /button_events)
  disp.xsize_matrix = nxpix
  disp.ysize_matrix = nypix

  ys = 70
  b = widget_button( main, uvalue='quit', value=np_cbb( 'Quit', bg='firebrick', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)

  ;; Realize the widget
  xsize = long( (nxpix+xs)*1.05)
  xoff = !screen_size[0]-xsize*1.3
  widget_control, main, /realize, xoff=xoff, xs=xsize

  widget_control, display_draw1, get_value=drawID1

  wset, drawID1

  dxmap = max(disp.xmap)-min(disp.xmap)
  dymap = max(disp.ymap)-min(disp.ymap)
  xmin = min(disp.xmap)
  ymin = min(disp.ymap)
  ymax = max(disp.ymap)

  ikid = 0
  for j=0, n_elements(disp.plot_position[0,*,0])-1 do begin
     for i=0, n_elements(disp.plot_position[*,0,0])-1 do begin
        if ikid lt disp.nkids then begin
           imview, reform(disp.map_list[ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, $
                   position=reform(disp.plot_position[i,j,*]), $
                   udg=rebin_factor, /nobar, xchars=1e-6, ychars=1e-6, /noerase

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

  xmanager, 'bt_discard_kids', main, /no_block
END
