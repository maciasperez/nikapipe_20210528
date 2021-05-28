
PRO kid_selector_event, ev
  common bt_maps_common

  widget_control, ev.id, get_uvalue=uvalue

  w1    = where( kidpar.type eq 1, nw1)

  tags = tag_names( ev)
  w = where( tags eq "TAB", nw)

  if nw ne 0 then begin
     if ev.tab eq 0 then begin
        ks.col_max = 2
        kidpar.ok = 0
        w = where( kidpar.plot_flag eq 0, nw)
        if nw ne 0 then kidpar[w].ok = 1
        wset, ks.drawID1
        ks.select_type = 'plot'
     endif

     if ev.tab eq 1 then begin
        ks.col_max = 3
        kidpar.ok = 0
        w = where( kidpar.in_decorr_template eq 1, nw)
        if nw ne 0 then kidpar[w].ok = 1
        wset, ks.drawID2
        ks.select_type = 'decorr'
     endif
  endif

  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end

        "plot_all":begin
           kidpar.plot_flag = 1
           kidpar[w1].plot_flag = 0
           ks.select_action = 'keep'
        end

        "plot_discard_all":begin
           kidpar.plot_flag= 1
           ks.select_action = 'discard'
        end
        
        "plot_select":begin
           ks.select_action = 'keep'
        end

        "plot_discard":begin
           ks.select_action = 'discard'
        end

        'decorr_all':begin
           kidpar.in_decorr_template = 0
           ;; kidpar[w1].in_decorr_template = 1
           kidpar[where( kidpar.idct_def eq 1)].in_decorr_template = 1
           ks.select_action = 'keep'
        end
        'decorr_discard_all':begin
           kidpar.in_decorr_template = 0
           ks.select_action = 'discard'
        end

        'decorr_select':begin
           ks.select_action = 'keep'
        end

        'decorr_discard':begin
           ks.select_action = 'discard'
        end

        'numdet_min':begin
           junk = long( Textbox( title='Numdet Min', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( kidpar.numdet lt junk, nw)
              if nw ne 0 then kidpar[w].plot_flag = 1
           endif
        end

        'numdet_max':begin
           junk = long( Textbox( title='Numdet Max', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( kidpar.numdet gt junk, nw)
              if nw ne 0 then kidpar[w].plot_flag = 1
           endif
        end
        
        'min_response':begin
           n_histwork, kidpar[w1].response, /fill, /fit, bin=bin
           wok = where( kidpar.ok eq 1, nwok)
           n_histwork, kidpar[wok].response, xhist, yhist, junk,  xfill, yfill, /noplot, bin=bin
           n_hist = n_elements(xhist)
           oplot, [xhist[0] - bin, xhist, xhist[n_hist-1]+ bin] , [0,yhist,0],  psym=10, col=150, thick=2
           polyfill, Xfill,Yfill, color=150, spacing=0, orient=45.

           min_resp = double( Textbox( title='Minimum Response (mK/Hz)', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( kidpar.response lt min_resp, nw)
              if nw ne 0 then kidpar[w].plot_flag = 1
           endif
        end

        'max_noise':begin

           n_histwork, kidpar[w1].noise, /fill, /fit, bin=bin
           wok = where( kidpar.ok eq 1, nwok)
           n_histwork, kidpar[wok].noise, xhist, yhist, junk,  xfill, yfill, /noplot, bin=bin
           n_hist = n_elements(xhist)
           oplot, [xhist[0] - bin, xhist, xhist[n_hist-1]+ bin] , [0,yhist,0],  psym=10, col=150, thick=2
           polyfill, Xfill,Yfill, color=150, spacing=0, orient=45.

           max_n = double( Textbox( title='Maximum Noise (Hz/sqrt(Hz)', group_leader=ev.top, cancel=cancelled))
           if not cancelled then begin
              w = where( kidpar.noise gt max_n, nw)
              if nw ne 0 then kidpar[w].plot_flag = 1
           endif
        end
        

     endcase

  endif else begin

     IF (TAG_NAMES(ev, /STRUCTURE_NAME) eq 'WIDGET_DRAW') THEN BEGIN
        ix = long( ev.x/ks.xfact)
        iy = long( ev.y/ks.xfact)
        ikid_select = ix + ks.nx*iy
        if ikid_select lt disp.nkids then begin
           if ks.select_type eq 'plot' then begin
              if ks.select_action eq 'keep' then kidpar[ikid_select].plot_flag = 0 else kidpar[ikid_select].plot_flag = 1
           endif else begin
              if ks.select_action eq 'keep' then kidpar[ikid_select].in_decorr_template = 1 else kidpar[ikid_select].in_decorr_template = 0
           endelse

        endif
     ENDIF

  endelse

  kidpar.ok = 0
  if strupcase(ks.select_type) eq "PLOT" then begin
     w = where( kidpar.plot_flag eq 0, nw)
     if nw ne 0 then kidpar[w].ok = 1
     wset, ks.drawID1
  endif else begin
     w = where( kidpar.in_decorr_template eq 1, nw)
     if nw ne 0 then kidpar[w].ok = 1
     wset, ks.drawID2
  endelse

  ;; Fill select grid
  ikid = 0 
  ks.select_grid = 0.
  for iy=0, ks.ny-1 do begin
     for ix=0, ks.nx-1 do begin
        if ikid lt disp.nkids then begin
           if kidpar[ikid].ok eq 1 then ks.select_grid[ix,iy] = 1
        endif
        ikid++
     endfor
  endfor

  ;; Display
  image = long( bytscl( congrid( ks.select_grid, ks.nx*ks.xfact, ks.ny*ks.xfact), min=0, max=ks.col_max, top=255))
  tv, image
  for ix=1, ks.nx-1 do plots, [1,1]*ix*ks.xfact,  [0,ks.ny]*ks.xfact, /dev, col=255
  for iy=1, ks.ny-1 do plots, [0,ks.nx]*ks.xfact, [1,1]*iy*ks.xfact, /dev, col=255
  ikid = 0
  for ix=0, ks.nx-1 do begin
     for iy=0, ks.ny-1 do begin
        if ikid lt disp.nkids then begin
           if kidpar[ikid].ok eq 1 then col=0 else col=255
           xyouts, (iy+0.1)*ks.xfact, (ix+0.1)*ks.xfact, kidpar[ikid].name, /dev, col=col
        endif
        ikid++
     endfor
  endfor

exit:
end


PRO kid_selector_widget
  common bt_maps_common

  ;; Init select_grid
  nx = long(sqrt( disp.nkids))
  if (nx^2) eq disp.nkids then begin
     ny = nx
  endif else begin
     nx++
     ny = 1
     while (ny*nx) lt disp.nkids do ny++
  endelse
  select_grid = intarr(nx,ny) - 1

  ;; Choose size of kid selector arrays
  npix = 500
  xfact = long( float(npix)/nx)
  im_size = [nx*xfact, ny*xfact]

  ;; Create widget
  main = widget_base( title='Kid Selector', /col, /frame)
  wTab = WIDGET_TAB( main, LOCATION=location, xsize=600)

  ;; Display kids
  bgc = 'purple'
  xs = 140
  ys = 30
  wT1           = WIDGET_BASE(wTab, TITLE='Display', /row, uvalue='display_kids_tab')
  comm1         = widget_base( wt1, /row, /frame)
  display_draw1 = widget_draw( comm1, xsize=im_size[0], ysize=im_size[1], /button_events)
  comm11        = widget_base( comm1, /column, /frame)
  b = widget_button( comm11, uvalue='plot_all',    value=np_cbb( 'Plot/All valid/Reset', bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm11, uvalue='plot_select', value=np_cbb( 'Plot/Select',    bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm11, uvalue='plot_discard', value=np_cbb( 'Plot/Discard',    bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm11, uvalue='plot_discard_all', value=np_cbb( 'Plot/Discard all', bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)

  bgc = 'dark slate blue'
  b = widget_button( comm11, uvalue='max_noise', value=np_cbb( 'Max. Noise', bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm11, uvalue='min_response',  value=np_cbb( 'Min. Resp.', bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)

  bgc = 'sea green'
  b = widget_button( comm11, uvalue='numdet_min', value=np_cbb( 'Min. Numdet', bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm11, uvalue='numdet_max', value=np_cbb( 'Max. Numdet', bg=bgc, xs=xs, ys=xs), xs=xs, ys=ys)

  b = widget_button( comm11, uvalue='quit', value=np_cbb( 'Quit', bg='firebrick', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)

  ;; Decorrelation kids
  bgc = 'orange'
  fgc = 'black'
  xs = 140
  ys = 30
  wT2           =  WIDGET_BASE(wTab, TITLE='Decorrelation', /row, uvalue='decorr_kids_tab')
  comm2         = widget_base( wt2, /row, /frame)
  display_draw2 = widget_draw( comm2, xsize=im_size[0], ysize=im_size[1], /button_events)

  comm22        = widget_base( comm2, /column, /frame)
  b = widget_button( comm22, uvalue='decorr_all',         value=np_cbb( 'Decorr/All valid/Reset', bg=bgc, fgc=fgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm22, uvalue='decorr_select',      value=np_cbb( 'Decorr/Select',          bg=bgc, fgc=fgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm22, uvalue='decorr_discard',     value=np_cbb( 'Decorr/Discard',         bg=bgc, fgc=fgc, xs=xs, ys=xs), xs=xs, ys=ys)
  b = widget_button( comm22, uvalue='decorr_discard_all', value=np_cbb( 'Decorr/Discard all',     bg=bgc, fgc=fgc, xs=xs, ys=xs), xs=xs, ys=ys)

  b = widget_button( comm22, uvalue='quit', value=np_cbb( 'Quit', bg='firebrick', fg='white', xs=xs, ys=xs), xs=xs, ys=ys)


  ;; Realize the widget
  xsize = long( (npix+xs)*1.05)
  xoff = !screen_size[0]-xsize*1.3
  widget_control, main, /realize, xoff=xoff, xs=xsize

  widget_control, display_draw1, get_value=drawID1
  widget_control, display_draw2, get_value=drawID2

  ks = {xfact:xfact, nx:nx, ny:ny, select_grid:select_grid, $
        col_max:2L, drawID1:drawID1, drawID2:drawID2, $
        select_type:'plot', select_action:'keep'}


  ;; Init display
  kidpar.ok = 0
  w = where( kidpar.plot_flag eq 0, nw)
  if nw ne 0 then kidpar[w].ok = 1
  wset, ks.drawID1

  ;; Fill select grid
  ikid = 0 
  ks.select_grid = 0.
  for iy=0, ks.ny-1 do begin
     for ix=0, ks.nx-1 do begin
        if ikid lt disp.nkids then begin
           if kidpar[ikid].ok eq 1 then ks.select_grid[ix,iy] = 1
        endif
        ikid++
     endfor
  endfor

  ;; Display
  image = long( bytscl( congrid( ks.select_grid, ks.nx*ks.xfact, ks.ny*ks.xfact), min=0, max=ks.col_max, top=255))
  tv, image
  for ix=1, ks.nx-1 do plots, [1,1]*ix*ks.xfact,  [0,ks.ny]*ks.xfact, /dev, col=255
  for iy=1, ks.ny-1 do plots, [0,ks.nx]*ks.xfact, [1,1]*iy*ks.xfact, /dev, col=255
  ikid = 0
  for ix=0, ks.nx-1 do begin
     for iy=0, ks.ny-1 do begin
        if ikid lt disp.nkids then begin
           if kidpar[ikid].ok eq 1 then col=0 else col=255
           xyouts, (iy+0.1)*ks.xfact, (ix+0.1)*ks.xfact, kidpar[ikid].name, /dev, col=col
        endif
        ikid++
     endfor
  endfor

  xmanager, 'kid_selector', main, /no_block
END

