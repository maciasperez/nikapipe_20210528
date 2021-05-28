
PRO multi_decouple_event, ev
  common ql_maps_common

widget_control, ev.id, get_uvalue=uvalue

loadct, 39
do_plot = 1
case uvalue of
   
   'slide_ibol': ibol = ev.value
   
   'add_kid': bolo_list = [bolo_list, ibol]
   
   'add_peak': begin
      ;;wind, 2, 1
      plottv, rebin( reform(map_list_ref[ibol,*,*]), nx*rebin_factor, ny*rebin_factor), $
              rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
              rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
              /scal, /iso, title=strtrim(ibol,2)+", flag = "+strtrim(kidpar[ibol].type,2)
      ww = where( x_peak_list gt !undef, nw)
      if nw ne 0 then oplot, x_peak_list[ww], y_peak_list[ww], psym=1, thick=2, syms=2

      coor_cursor, x, y, /cross
      if n_elements(x) ge 1 then x_peak_list = [x_peak_list, x]
      if n_elements(x) ge 1 then y_peak_list = [y_peak_list, y]
   end

   'view_all':begin
      gna = where( bolo_list ge 0, ngna)
      np = long( sqrt( ngna)) + 1
      ww = where( x_peak_list gt !undef, nw)
      !p.multi = [0, np, np]
      ;;wind, 3, 1, xs=900, ys=900
      for i=1, n_elements(bolo_list)-1 do begin
         plottv, rebin( reform(map_list_ref[ bolo_list[i],*,*]), nx*rebin_factor, ny*rebin_factor), $
                 rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
                 rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
                 /scal, /iso, title=strtrim( bolo_list[i],2)+", flag = "+strtrim(kidpar[bolo_list[i]].type,2)
         if nw ne 0 then oplot, x_peak_list[ww], y_peak_list[ww], psym=1, thick=2, syms=2
      endfor
      !p.multi=0
      do_plot = 0
   end

   'separate':begin
      bolo_list   = bolo_list[1:*]
      x_peak_list = x_peak_list[1:*]
      y_peak_list = y_peak_list[1:*]
      n = n_elements( bolo_list)
      mat = dblarr( n, n)
      for ibolo=0, n-1 do begin
         for ipeak=0, n-1 do begin
            x = x_peak_list[ipeak]
            y = y_peak_list[ipeak]
            
            ix = long( (x-min(xra))/reso_map)
            iy = long( (y-min(yra))/reso_map)

            mat[ipeak, ibolo] = map_list_ref[ bolo_list[ibolo], ix, iy]
         endfor
      endfor
      mat_m1 = invert(mat)
      
      ;; Check
      map = dblarr(n, nx, ny)
      for ibeam=0, n-1 do begin
         for i=0, nx-1 do begin
            for j=0, ny-1 do begin
               map[*,i,j] = mat_m1##map_list_ref[ bolo_list,i,j]
            endfor
         endfor
      endfor

      np = long( sqrt(n)+1)
      print, "n, np: ", n, np
      !p.multi = [0, np, np]
      for i=0, n-1 do begin
         plottv, rebin( reform(map[i,*,*]), nx*rebin_factor, ny*rebin_factor), $
                 rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
                 rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
                 /scal, /iso, title=strtrim( bolo_list[i],2)+", flag = "+strtrim(kidpar[bolo_list[i]].type,2)
         oplot, x_peak_list, y_peak_list, psym=1, thick=2, syms=2
      endfor
      !p.multi=0
      do_plot = 0
   end

   'reset_kids':  bolo_list = [-1.0d0]
   'reset_peaks': begin
      x_peak_list = [double(!undef)]
      y_peak_list = [double(!undef)]
      a_peak_list = [double(!undef)]
   end

   'exit': begin
      n = n_elements( bolo_list)
      for i=0, n-1 do coeff[*, bolo_list[i]] = 0.0d0
      for i=0, n-1 do begin
         for j=0, n-1 do begin
            coeff[bolo_list[i],bolo_list[j]] = mat_m1[i,j]/total( mat_m1[*,j]) ; /total(...) to restore photometry
         endfor
      endfor

      for i=0, n-1 do kidpar[bolo_list[i]].type = 3

      widget_control, ev.top, /destroy
   end


   'cancel': widget_control, ev.top, /destroy

endcase

if do_plot eq 1 then begin
   ;;wind, 2, 1
   plottv, rebin( reform(map_list_ref[ibol,*,*]), nx*rebin_factor, ny*rebin_factor), $
           rebin( xmap, nx*rebin_factor, ny*rebin_factor), $
           rebin( ymap, nx*rebin_factor, ny*rebin_factor), $
           /scal, /iso, title=strtrim(ibol,2)+", flag = "+strtrim(kidpar[ibol].type,2)
   ww = where( x_peak_list gt !undef, nw)
   if nw ne 0 then oplot, x_peak_list[ww], y_peak_list[ww], psym=1, thick=2, syms=2
endif


end

pro multi_decouple
  common ql_maps_common

  main     = widget_base( title='Multi decouple', /row, /frame)
  
  draw1 = widget_draw( main, uvalue='draw1', xsize=600, ysize=600)

  commands = widget_base( main, /column, /frame)

  sld = widget_slider( commands, title='Select one kid', min=0, max=nkids-1, $
                         scroll=1, value=ibol, uval='slide_ibol', xsize=400, /drag) ; slider 

  xs = 100
  ys = 100

  comm_1 = widget_base( commands, /row, /frame)
  b = widget_button( comm_1, uvalue='add_kid',  value=np_cbb( 'Add kid',  bg='slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_1, uvalue='add_peak', value=np_cbb( 'Add peak', bg='slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_1, uvalue='view_all', value=np_cbb( 'View all', bg='slate blue', xs=xs, ys=ys), xs=xs, ys=ys)

  comm_2 = widget_base( commands, /row, /frame)
  b = widget_button( comm_2, uvalue='reset_kids',  value=np_cbb( 'Reset kid list',  bg='orange', fg='black', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_2, uvalue='reset_peaks', value=np_cbb( 'Reset peak list', bg='orange', fg='black', xs=xs, ys=ys), xs=xs, ys=ys)

  comm_3 = widget_base( commands, /row, /frame)
  b = widget_button( comm_3, uvalue='separate', value=np_cbb( 'Separate',      bg='slate blue', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_3, uvalue='exit',     value=np_cbb( 'Save and Exit', bg='sea green', xs=xs, ys=ys), xs=xs, ys=ys)
  b = widget_button( comm_3, uvalue='cancel',   value=np_cbb( 'Cancel',        bg='firebrick', xs=xs, ys=ys), xs=xs, ys=ys)

  ; init
  bolo_list   = [-1.0d0]
  x_peak_list = [double(!undef)]
  y_peak_list = [double(!undef)]
  a_peak_list = [double(!undef)]
  widget_control, main, /realize                                      ; create the widgets
  xmanager, 'multi_decouple', main, /no_block
end
