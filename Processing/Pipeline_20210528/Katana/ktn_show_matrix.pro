

PRO ktn_show_matrix_event, ev
  common ktn_common

  ktn_matrix_event, ev, action="show"
exit:
end


PRO ktn_show_matrix, kidx=kidx, kidy=kidy
  common ktn_common

  matrix = disp.map_list

  ;; Display parameter
  ;; button size
  xs = 100
  ys = 70
  ;; widget size
  ;;xsize = long( !screen_size[0]*0.5)
  ;;ysize = long( !screen_size[1]*0.9)
  xsize = long( disp.xsize_matrix + xs + 300)
  ysize = long( disp.ysize_matrix + 50)
  xoff  = !screen_size[0]-xsize*1.4

  ;; How many tabs ?
  tabid_res    = lonarr( disp.ntabs)
  drawid_res_1 = lonarr( disp.ntabs)
  drawid_res_2 = lonarr( disp.ntabs)

  ;; Create widget
  main = widget_base( title='Click on kids to get specific info.', /col, /frame)
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

     outplot, file=sys_info.plot_dir+"/"+sys_info.nickname+"_matrix_"+strtrim(itab,2), png=sys_info.png, ps=sys_info.ps
     ikid = kmin
     for j=0, n_elements(disp.plot_position[0,*,0])-1 do begin
        for i=0, n_elements(disp.plot_position[*,0,0])-1 do begin
           if ikid lt kmax then begin
              delvarx, imrange
              if keyword_set(relative_max) then imrange = [-1,1]*relative_max*max(matrix[ikid,*,*])
              imview, reform(matrix[ikid,*,*]), xmap=disp.xmap, ymap=disp.ymap, $
                      position=reform(disp.plot_position[i,j,*]), $
                      udg=rebin_factor, /nobar, chars=1e-6, /noerase, imrange=imrange
              
              xx = xmin+0.1*dxmap
              yy = ymin+0.1*dymap
              decode_flag, kidpar[ikid].type, flagname
              xyouts, xx, yy, flagname, chars=1.5, col=disp.textcol
              
              yy = ymax-0.2*dymap
              xyouts, xx, yy, strtrim( kidpar[ikid].numdet,2), col=disp.textcol

              if kidpar[ikid].plot_flag ne 0 then begin
                 yy = ymin+0.1*dymap
                 xyouts, xx, yy, "Discarded", col=disp.textcol
              endif

              ikid += 1
           endif
        endfor
     endfor
     outplot, /close
  endfor

  ;;xmanager, 'ktn_discard_kids', main, /no_block
  xmanager, 'ktn_show_matrix', main, /no_block
END
;; PRO ktn_show_matrix, matrix, relative_max=relative_max, kidx=kidx, kidy=kidy, nan2zero=nan2zero
;;   common ktn_common
;; 
;;   ;; Display parameter
;;   ;; button size
;;   xs = 100
;;   ys = 70
;;   ;; widget size
;; ;  xsize = long( !screen_size[0]*0.5)
;; ;  ysize = long( !screen_size[1]*0.9)
;; 
;;   xsize = disp.xsize_matrix + 1.1*xs
;;   ysize = disp.ysize_matrix + 100 ; take margin due to the tab menu
;; 
;;   xoff  = !screen_size[0]-xsize*1.4
;;   ;; Graphics window size
;; ;  nxpix = long(xsize-1.2*xs)
;; ;  nypix = long(ysize-100) ; take margin due to the tab menu
;; 
;; ;  disp.xsize_matrix = nxpix
;; ;  disp.ysize_matrix = nypix
;; 
;;   ;; How many tabs ?
;;   ntabs = 1
;;   while ntabs*disp.nkids_max_per_tab lt disp.nkids do ntabs++
;;   tabid_res    = lonarr( ntabs)
;;   drawid_res_1 = lonarr( ntabs)
;;   drawid_res_2 = lonarr( ntabs)
;; 
;;   ;; Create widget
;;   main = widget_base( title='Click on kids to obtain more information', /col, /frame)
;;   wtab = widget_tab( main, location=location, xsize=xsize, ysize=ysize)
;;   for itab=0, ntabs-1 do begin
;;      kmin = itab*disp.nkids_max_per_tab
;;      kmax = ((itab+1)*disp.nkids_max_per_tab-1) < disp.nkids
;; 
;;      ;;tabid_res[itab]    = widget_base(wtab, title='Kids '+strtrim( kmin,2)+" - "+strtrim( kmax,2), /row, uvalue=strtrim(itab))
;;      tabid_res[itab]    = widget_base(wtab, title='Kids '+strtrim( kmin,2), /row, uvalue=strtrim(itab))
;;      comm1              = widget_base(tabid_res[itab], /row, /frame)
;;      drawid_res_1[itab] = widget_draw( comm1, xsize=disp.xsize_matrix, ysize=disp.ysize_matrix, /button_events)
;;      comm2              = widget_base(tabid_res[itab], /col, /frame)
;;      b                  = widget_button( comm2, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)
;;   endfor
;; 
;;   dxmap = max(disp.xmap)-min(disp.xmap)
;;   dymap = max(disp.ymap)-min(disp.ymap)
;;   xmin = min(disp.xmap)
;;   ymin = min(disp.ymap)
;;   ymax = max(disp.ymap)
;; 
;;   ;; Init with 5 tabs for now...
;;   if ntabs gt 20 then begin
;;      message, /info, ""
;;      message, "ntags = "+strtrim(ntabs,2)+", Please upgrade dispmat"
;;   endif else begin
;;      dispmat = lonarr(10)
;;   endelse
;; 
;;   ;; Realize the widget
;;   xoff = !screen_size[0]-xsize*1.4
;;   widget_control, main, /realize, xoff=xoff, xs=xsize, ys=ysize
;;   for itab=0, ntabs-1 do begin
;;      widget_control, drawid_res_1[itab], get_value=drawID
;;      dispmat[itab] = drawID
;; 
;;      wset, drawID
;;      kmin = itab*disp.nkids_max_per_tab
;;      kmax = ((itab+1)*disp.nkids_max_per_tab) < disp.nkids
;; 
;;      ikid = kmin
;;      for j=0, n_elements(disp.plot_position[0,*,0])-1 do begin
;;         for i=0, n_elements(disp.plot_position[*,0,0])-1 do begin
;;            if ikid lt kmax then begin
;;               delvarx, imrange
;;               if keyword_set(relative_max) then imrange = [-1,1]*relative_max*max(matrix[ikid,*,*])
;;               map = reform(matrix[ikid,*,*])
;;               
;;               ;; Set NaN values to zero for a nicer display
;;               if keyword_set(nan2zero) then begin
;;                  w = where( finite(map) ne 1, nw)
;;                  if nw ne 0 then map[w] = 0.d0
;;               endif
;; 
;;               imview, map, xmap=disp.xmap, ymap=disp.ymap, $
;;                       position=reform(disp.plot_position[i,j,*]), $
;;                       udg=rebin_factor, /nobar, xchars=1e-6, ychars=1e-6, /noerase, imrange=imrange
;; 
;; ;              if keyword_set(kidx) and keyword_set(kidy) then begin
;; ;                 if n_elements(kidx) eq n_elements(kidy) then oplot, [kidx[ikid]], [kidy[ikid]], psym=1, col=255, thick=2, syms=2
;; ;              endif
;; 
;;               xx = xmin+0.1*dxmap
;;               yy = ymin+0.1*dymap
;;               decode_flag, kidpar[ikid].type, flagname
;;               xyouts, xx, yy, flagname, chars=1.5, col=disp.textcol
;;               
;;               yy = ymax-0.2*dymap
;;               xyouts, xx, yy, strtrim( kidpar[ikid].numdet,2), col=disp.textcol
;;               ikid += 1
;;            endif
;;         endfor
;;      endfor
;;   endfor
;; 
;; 
;;   xmanager, 'ktn_show_matrix', main, /no_block
;; END
