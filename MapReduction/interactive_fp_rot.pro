
PRO interactive_fp_rot_event, ev
  common ql_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  case uvalue of
     "rotate_fp":begin
        alpha_fp = ev.value
        !check_list.status[2] = 1
     end
     
     "gross_fp":begin
        delta_fp = ev.value
        !check_list.status[3] = 1
     end

     'save_exit':begin
        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end

     'cancel': begin
        alpha_fp = !nika.array[ilambda].alpha_fp_deg
        delta_fp = !nika.array[ilambda].magnif
        widget_control, ev.top, /destroy
        print, "Done."
        goto, exit
     end
  endcase


  plot_name = "FP_pos"

  x11 = ( cos(alpha_fp*!dtor)*x_peaks_1[wplot] + sin(alpha_fp*!dtor)*y_peaks_1[wplot])/delta_fp
  y11 = (-sin(alpha_fp*!dtor)*x_peaks_1[wplot] + cos(alpha_fp*!dtor)*y_peaks_1[wplot])/delta_fp
  get_x0y0, x11, y11, xc0, yc0
  x11 = x11 - xc0
  y11 = y11 - yc0
  kidpar[wplot].x_pix = round(x11)
  kidpar[wplot].y_pix = round(y11)

  if nw3 ne 0 then begin
     x3 = ( cos(alpha_fp*!dtor)*x_peaks_1[w3] + sin(alpha_fp*!dtor)*y_peaks_1[w3])/delta_fp
     y3 = (-sin(alpha_fp*!dtor)*x_peaks_1[w3] + cos(alpha_fp*!dtor)*y_peaks_1[w3])/delta_fp
     x3 = x3 - xc0
     y3 = y3 - yc0
     kidpar[w3].x_pix = round(x3)
     kidpar[w3].y_pix = round(y3)
  endif

  xra_width = (max(x11)-min(x11))
  yra_width = (max(y11)-min(y11))
  xra2 = (min(x11)+max(x11))/2. + [-1,1]*xra_width/2.*1.2
  yra2 = (min(y11)+max(y11))/2. + [-1,1]*yra_width/2.*1.2
                                ;xra2 = xra_plot
                                ;yra2 = yra_plot
  wshet, 1
  outplot, file=nickname+'_rotate_fp', png=png, ps=ps
  plot, x11, y11, /iso, psym=1, title='Alpha_fp = '+strtrim(alpha_fp,2)+', Delta='+strtrim(delta_fp,2), $
        xra=xra2, yra=yra2, syms=2, /xs, /ys, chars=1.5
  oplot, kidpar[wplot].x_pix, kidpar[wplot].y_pix, psym=8, col=70
  xyouts, x11, y11, strtrim(kidpar[wplot].numdet,2), col=250, chars=1.5
  for i=min( long([xra2[0], yra2[0]]))-1, max(long([xra2[1], yra2[1]]))+1 do begin
     oplot, [i,i], yra2, line=1
     oplot, xra2, [i,i], line=1
  endfor        
  oplot, x11, y11, psym=1, thick=2, col=250
  legendastro, [box+strtrim(lambda,2)+"mm", $
                'N columns = '+strtrim( long(max(kidpar[wplot].x_pix)-min(kidpar[wplot].x_pix)+1),2), $
                'N lines   = '+strtrim( long(max(kidpar[wplot].y_pix)-min(kidpar[wplot].y_pix)+1),2)], box=0, chars=3, thick=2
  outplot, /close

exit:
end


PRO interactive_fp_rot
  common ql_maps_common

  main = widget_base( title='Focal Plane', /row, /frame)

  xs = 100
  ys = 100
  comm1 = widget_base( main, /col, /frame)
  sl_alpha = cw_fslider( comm1, title='FP angle', min=-180, max=180, $
                         scroll=0.5, value=!nika.array[ilambda].alpha_fp_deg, uval='rotate_fp', xsize=200, /drag)
  sl_delta = cw_fslider( comm1, title='Delta FP', min=0, max=20, $
                         scroll=0.1, value=!nika.array[ilambda].magnif, uval='gross_fp', xsize=200, /drag)

  comm2 = widget_base( main, /row, /frame)
  b = widget_button( comm2, uvalue='save_exit', value=np_cbb( 'SaveExit', bgc='sea green', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm2, uvalue='cancel',    value=np_cbb( 'Cancel',     bgc='firebrick', xs=xs, ys=ys), xs=xs, ys=ys)

  ;; init values
  alpha_fp = !nika.array[ilambda].alpha_fp_deg
  delta_fp = !nika.array[ilambda].magnif

  widget_control, main, /realize, xoff=long(0.6*my_screen_size[0])
  xmanager, 'interactive_fp_rot', main;, /no_block
END

