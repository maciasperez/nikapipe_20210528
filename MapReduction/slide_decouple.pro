
PRO dec_slider_event, ev
  widget_control, ev.id, get_uvalue=uvalue

  CASE uvalue OF
     'slide': begin
        !sld_dec.theta = ev.value
        print, "theta = ", !sld_dec.theta
;;        wset, win_id1
        db, cos(!sld_dec.theta*!dtor)*!sld_dec.map_a + sin(!sld_dec.theta*!dtor)*!sld_dec.map_b, title=strtrim(!sld_dec.theta,2)
     end
     'theta1': !sld_dec.theta1 = !sld_dec.theta
     'theta2': !sld_dec.theta2 = !sld_dec.theta
;;     'alpha':begin
;;        !sld_dec.alpha = ev.value
;;        print, "alpha = ", !sld_dec.alpha
;;        db, 0.01*!sld_dec.alpha*!sld_dec.map_a + (1.0d0-!sld_dec.alpha*0.01)*!sld_dec.map_b, title=strtrim(!sld_dec.alpha,2)
;;     end
     'quit': widget_control, ev.top, /destroy
  Endcase

end


PRO dec_slider
  main = widget_base (title='A401 experiments', /row, /frame)
  cntl  = widget_base (main, /column, /frame)

  sld        = widget_slider (cntl, title='theta', min=0, max=360, $
                              scroll=1, value=0, uval='slide', xsize=400, /drag) ; slider 
  btn_theta1 = widget_button( cntl, uvalue='theta1', value='theta1', xsize=100, ysize=100)
  btn_theta2 = widget_button( cntl, uvalue='theta2', value='theta2', xsize=100, ysize=100)
  btn_quit   = widget_button( cntl, uvalue='quit', value='Quit', xsize=100, ysize=100)
  draw1      = widget_draw (main, uvalue='draw1', /button, xsize=400, ysize=400) ; graphics pane



  widget_control, main, /realize                                      ; create the widgets
  xmanager, 'dec_slider', main;, /no_block                         ; wait for events
END

pro slide_decouple, map_list, ibol, jbol, coeff_out, theta1, theta2, map_out_1, map_out_2, rebin=rebin

  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "slide_decouple, map_list, ibol, jbol, coeff_out, theta1, theta2, rebin=rebin"
     return
  endif

  
  if not keyword_set(rebin) then rebin=1

  !p.multi=0
  !p.position = 0
  nkids = n_elements( map_list[*,0,0])
  nx    = n_elements( map_list[0,*,0])
  ny    = n_elements( map_list[0,0,*])

  str = {map_a:rebin( reform( map_list[ibol,*,*]), nx*rebin, ny*rebin), $
         map_b:rebin( reform( map_list[jbol,*,*]), nx*rebin, ny*rebin), $
         theta:0.0d0, $
         theta1:0.0d0, $
         theta2:0.0d0};, $
;;         alpha:0.0d0}

  defsysv, "!sld_dec", str

  dec_slider

  map_out_1 = cos(!sld_dec.theta1*!dtor)*str.map_a + sin(!sld_dec.theta1*!dtor)*str.map_b
  map_out_2 = cos(!sld_dec.theta2*!dtor)*str.map_a + sin(!sld_dec.theta2*!dtor)*str.map_b

  theta1 = !sld_dec.theta1*!dtor
  theta2 = !sld_dec.theta2*!dtor

  print, ""
  print, "theta1 = "+strtrim(theta1,2)
  print, "theta2 = "+strtrim(theta2,2)

  coeff_out = dblarr(nkids, nkids)

  coeff_out[*,ibol] = 0.0d0 ; matrix convention
  coeff_out[*,jbol] = 0.0d0

  coeff_out[ibol,ibol] = cos(!sld_dec.theta1*!dtor)
  coeff_out[jbol,ibol] = sin(!sld_dec.theta1*!dtor)

  coeff_out[ibol,jbol] = cos(!sld_dec.theta2*!dtor)
  coeff_out[jbol,jbol] = sin(!sld_dec.theta2*!dtor)

end
