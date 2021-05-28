
PRO dec_slider_event, ev
  common ql_maps_common
  common slide_decouple_common, sld_dec_theta, theta1, theta2, map_a, map_b

  widget_control, ev.id, get_uvalue=uvalue

  wx = where( x_cross ne !undef, nwx)

  CASE uvalue OF

     'slide_theta': begin
        sld_dec_theta = ev.value
        print, "theta = ", sld_dec_theta
        ;;db, cos(sld_dec_theta*!dtor)*!sld_dec.map_a + sin(sld_dec_theta*!dtor)*!sld_dec.map_b, title=strtrim(sld_dec_theta,2)
        plottv, cos(sld_dec_theta*!dtor)*!sld_dec.map_a + sin(sld_dec_theta*!dtor)*!sld_dec.map_b, $
                rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
                rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
                /scal, /iso, title=strtrim(!sld_dec.ibol,2)
        if nwx ne 0 then oplot, x_cross[wx], y_cross[wx], psym=1, thick=2, syms=2, col=0
     end

     'slide_ibol': begin
        !sld_dec.ibol = ev.value
        !sld_dec.map_a = rebin( reform(map_list_ref[!sld_dec.ibol,*,*]), nx*rebin_factor, ny*rebin_factor)
        plottv, rebin( reform(map_list_ref[!sld_dec.ibol,*,*]), nx*rebin_factor, ny*rebin_factor), $
                rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
                rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
                /scal, /iso, title=strtrim(!sld_dec.ibol,2)
        if nwx ne 0 then oplot, x_cross[wx], y_cross[wx], psym=1, thick=2, syms=2, col=0
     end

     'slide_jbol': begin
        !sld_dec.jbol = ev.value
        !sld_dec.map_b = rebin( reform(map_list_ref[!sld_dec.jbol,*,*]), nx*rebin_factor, ny*rebin_factor)
        plottv, rebin( reform(map_list_ref[!sld_dec.jbol,*,*]), nx*rebin_factor, ny*rebin_factor), $
                rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
                rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
                /scal, /iso, title=strtrim(!sld_dec.jbol,2)
        if nwx ne 0 then oplot, x_cross[wx], y_cross[wx], psym=1, thick=2, syms=2, col=0
     end

     'theta1': !sld_dec.theta1 = sld_dec_theta

     'theta2': !sld_dec.theta2 = sld_dec_theta

     'Done': begin
        kidpar[ !sld_dec.ibol].type = 3
        kidpar[ !sld_dec.jbol].type = 3
        widget_control, ev.top, /destroy
     end

     'Cancel': begin
        !sld_dec.theta1 = 0.d0
        !sld_dec.theta2 = 90.d0
        widget_control, ev.top, /destroy
     end

  Endcase

end


PRO slide_decouple_2
  common ql_maps_common
  common slide_decouple_common

  !p.multi=0
  !p.position = 0

  str = {map_a:dblarr(nx*rebin_factor, ny*rebin_factor), $
         map_b:dblarr(nx*rebin_factor, ny*rebin_factor), $
         ibol:0, jbol:0, $
         theta1:0.d0, $
         theta2:0.d0}
;;          theta:0.0d0, $
;; 
   defsysv, "!sld_dec", str

  ;; init
  sld_dec_theta =  0.0d0
  theta1        =  0.0d0
  theta2        = 90.0d0
  map_a         = rebin( reform( map_list_ref[ibol,*,*]), nx*rebin_factor, ny*rebin_factor)
  map_b         = rebin( reform( map_list_ref[jbol,*,*]), nx*rebin_factor, ny*rebin_factor)

  main = widget_base (title='slide_decouple_2', /row, /frame)
  cntl  = widget_base (main, /column, /frame)

  xs = 400
  ys = 100
  sld        = widget_slider (cntl, title='Kid (1)', min=0, max=nkids-1, scroll=1, value=ibol, uval='slide_ibol', xsize=400, /drag)
  sld        = widget_slider (cntl, title='Kid (2)', min=0, max=nkids-1, scroll=1, value=ibol, uval='slide_jbol', xsize=400, /drag)

  sld        = widget_slider (cntl, title='theta', min=0, max=360, scroll=1, value=0, uval='slide_theta', xsize=400, /drag)

  btn_theta1 = widget_button( cntl, uvalue='theta1', value=np_cbb( 'theta1', bg='slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  btn_theta2 = widget_button( cntl, uvalue='theta2', value=np_cbb( 'theta2', bg='slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( cntl, uvalue='Done',    value=np_cbb( 'Done', bg='green', fg='black', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( cntl, uvalue='Cancel', value=np_cbb( 'Cancel', bg='firebrick', fg='white', xs=xs, ys=ys), xs=xs, ys=100)

  ;; draw1      = widget_draw(main, uvalue='draw1', /button, xsize=600, ysize=600) ; graphics pane

  widget_control, main, /realize, xoff=600                                      ; create the widgets
  xmanager, 'dec_slider', main;, /no_block                         ; wait for events

END

