;; 120928_09:11:12: before adding "goto's" and "plot all button"
;; 120928_10:44:17: before adding computation if outplot

PRO flag_widget_event, ev
  common ql_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  w1  = where( kidpar.type eq 1, nw1)
  if wplot_init lt 0 then wplot = w1

  CASE uvalue OF

     'blind':     kidpar[ibol].type = 0
     'valid':     kidpar[ibol].type = 1
     'off':       kidpar[ibol].type = 2
     'combined':  kidpar[ibol].type = 3
     'mult':      kidpar[ibol].type = 4
     'tbc':       kidpar[ibol].type = 5
     ;'save_exit':

     'quit': widget_control, ev.top, /destroy
  Endcase
end


pro flag_widget
  common ql_maps_common

  main = widget_base( title='NIKA_flag', /row, /frame)

  xs = 70
  ys = 50
  comm_0 = widget_base( main, /row, /frame)
  b = widget_button( comm_0, uvalue='blind',    value=np_cbb( 'BLIND',         bg='dark slate blue', fg='white', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_0, uvalue='valid',    value=np_cbb( 'Valid',         bg='dark slate blue', fg='white', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_0, uvalue='off',      value=np_cbb( 'Off resonance', bg='dark slate blue', fg='white', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_0, uvalue='combined', value=np_cbb( 'Combined',      bg='dark slate blue', fg='white', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_0, uvalue='mult',     value=np_cbb( 'Mult',          bg='dark slate blue', fg='white', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_0, uvalue='tbc',      value=np_cbb( 'TBC',           bg='dark slate blue', fg='white', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_0, uvalue='quit',     value=np_cbb( 'Quit',          bg='firebrick',       xs=xs, ys=ys), xsize=xs, ysize=ys)

  my_screen_size = get_screen_size()

  ;;xoff = long(0.45*my_screen_size[0])
  xoff = long(!fw.xcursor)
  yoff = long(my_screen_size[1] - !fw.ycursor)
  print, "!fw.xcursor, !fw.ycursor, xoff, yoff: ", !fw.xcursor, !fw.ycursor, xoff, yoff
  widget_control, main, /realize, xoff=xoff, yoff=yoff
  xmanager, 'flag_widget', main, no_block=0 ; wait for events

end
