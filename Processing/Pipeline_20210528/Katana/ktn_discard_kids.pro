

PRO ktn_discard_kids_event, ev
  common ktn_common

  ktn_matrix_event, ev, action='discard'

exit:
end


PRO ktn_discard_kids, kidx=kidx, kidy=kidy
  common ktn_common

  matrix = disp.map_list

  ;; Display parameter
  ;; button size
  xs = 100
  ys = 70
  ;; widget size
  ;;xsize = long( !screen_size[0]*0.5)
  ;;ysize = long( !screen_size[1]*0.9)
  xsize = long( disp.xsize_matrix + xs + 20)
  ysize = long( disp.ysize_matrix + 50)
  xoff  = !screen_size[0]-xsize*1.4

  ;; How many tabs ?
  tabid_res    = lonarr( disp.ntabs)
  drawid_res_1 = lonarr( disp.ntabs)
  drawid_res_2 = lonarr( disp.ntabs)

  ;; Create widget
  main = widget_base( title='Click on kids to be discarded', /col, /frame)
  wtab = widget_tab( main, location=location, xsize=xsize, ysize=ysize)
  for itab=0, disp.ntabs-1 do begin
     kmin = itab*disp.nkids_max_per_tab
     kmax = ((itab+1)*disp.nkids_max_per_tab-1) < disp.nkids

     ;;tabid_res[itab]    = widget_base(wtab, title='Kids '+strtrim( kmin,2)+" - "+strtrim( kmax,2), /row, uvalue=strtrim(itab))
     tabid_res[itab]    = widget_base(wtab, title=strtrim( kmin,2), /row, uvalue=strtrim(itab))
     comm1              = widget_base(tabid_res[itab], /row, /frame)
     drawid_res_1[itab] = widget_draw( comm1, xsize=disp.xsize_matrix, ysize=disp.ysize_matrix, /button_events)
     comm2              = widget_base(tabid_res[itab], /col, /frame)
     b                  = widget_button( comm2, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)
  endfor

  dxmap = max(disp.xmap)-min(disp.xmap)
  dymap = max(disp.ymap)-min(disp.ymap)
  xmin = min(disp.xmap)
  ymin = min(disp.ymap)
  ymax = max(disp.ymap)

  dispmat = lonarr(disp.ntabs) ; lonarr(10)

  ;; Realize the widget
  widget_control, main, /realize, xoff=xoff, xs=xsize, ys=ysize
  for itab=0, disp.ntabs-1 do begin
     widget_control, drawid_res_1[itab], get_value=drawID
     dispmat[itab] = drawID

     wset, drawID
     kmin = itab*disp.nkids_max_per_tab
     kmax = ((itab+1)*disp.nkids_max_per_tab) < disp.nkids

     ;; LP: to define the range of the color table 
     ;;maxtab = dblarr(kmax-kmin)
     ;;for mm=0, kmax-kmin-1 do maxtab[mm] = max(matrix[kmin+mm,*,*])
     ;;mymax = median(maxtab)
     relmax = 0.2
     if keyword_set(relative_max) then relmax = relative_max
     
     ikid = kmin
     for j=0, n_elements(disp.plot_position[0,*,0])-1 do begin
        for i=0, n_elements(disp.plot_position[*,0,0])-1 do begin
           if ikid lt kmax then begin
              delvarx, imrange
              if keyword_set(relative_max) then imrange = [-1./2.5,1.]*relative_max*max(matrix[ikid,*,*])
             
              if kidpar[ikid].plot_flag ne 0 then bw=1 else bw=0
              
              ;;message, /info, "fix me:"
              ;;imrange = [-1,1]*0.2*max(matrix[ikid,*,*])
              imrange = [-0.08,0.2]*max(matrix[ikid,*,*])
              ;; LP imrange
              ;; NB: max=20000, well-suited for Uranus, TBC for other
              ;;mymax = min([max(matrix[kmin:kmax-1,*,*]),20000.])
              ;;imrange = [-0.08*mymax,0.2*mymax]
              ;;imrange = [-1./2.5,1.]*relmax*max(matrix[ikid,*,*])
              
              imview, reform(matrix[ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, $
                      position=reform(disp.plot_position[i,j,*]), bw=bw, $
                      udg=rebin_factor, /nobar, chars=1e-6, /noerase, imrange=imrange
              
              xx = xmin+0.1*dxmap
              yy = ymin+0.1*dymap
              decode_flag, kidpar[ikid].type, flagname
              xyouts, xx, yy, flagname, chars=1.5, col=disp.textcol
              
              yy = ymax-0.2*dymap
              xyouts, xx, yy, strtrim( kidpar[ikid].numdet,2)+" A"+strtrim(kidpar[ikid].array,2), col=disp.textcol

              if kidpar[ikid].plot_flag ne 0 then begin
                 yy = ymin+0.1*dymap
                 xyouts, xx, yy, "Discarded", col=disp.textcol
                 ;;oplot, minmax(disp.xmap), minmax(disp.ymap), col=disp.textcol
                 ;;oplot, minmax(disp.xmap), reverse(minmax(disp.ymap)), col=disp.textcol
              endif

              ikid += 1
           endif
        endfor
     endfor
  endfor

  xmanager, 'ktn_discard_kids', main, /no_block
END
