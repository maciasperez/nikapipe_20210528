
pro sanity_checks_event, ev
  common ktn_common

  widget_control, ev.id, get_uvalue=uvalue

  tags = tag_names( ev)
  w    = where( tags eq "TAB", nw)

  if nw ne 0 then wset, ks[ev.tab]

  if defined(uvalue) then begin
     case uvalue of
        "quit": begin
           widget_control, ev.top, /destroy
           goto, exit
        end
     endcase
  endif

exit:
end

PRO ktn_sanity_checks
  common ktn_common

  ;; Display window parameters
  xsize = 1200 < (!screen_size[0]*0.7)
  ysize =  1000 < (!screen_size[1]*0.7)
  
  ;; Button parameters
  xs = 140
  ys = 30

  ;; Widget size
  im_size = [xsize-xs*1.1, ysize-ys*1.1]

  ;; Create the widget
  main = widget_base( title='KATANA Sanity Checks', /col, /frame)
  wTab = WIDGET_TAB( main, LOCATION=location, xsize=xsize, ysize=ysize)

  fmt = "(F7.2)" ; "(F6.2)"
  
  nsn   = n_elements(data)
  nkids = n_elements(kidpar)
  
  w1 = where( kidpar.type eq 1, nw1)
  w2 = where( kidpar.type eq 2, nw2)
  
  w1mm = where( kidpar.array eq 1, nw1mm)
  w2mm = where( kidpar.array eq 2, nw2mm)
  scan_length = nsn/!nika.f_sampling
  time = dindgen(nsn)/!nika.f_sampling

  ;; take margin on both sides to see potential jumps
  time_range = minmax(time)+[-1,1]*scan_length/5.
  
  default_col = [!p.color, 70, 250]

  ;; Display kids
  wT0           = WIDGET_BASE(wTab, TITLE='Raw TOIs', /row, uvalue='tois')
  comm1         = widget_base( wt0, /row, /frame)
  display_draw0 = widget_draw( comm1, xsize=im_size[0], ysize=im_size[1], /button_events)
  comm11        = widget_base( comm1, /column, /frame)
  b = widget_button( comm11, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)

  wT1           = WIDGET_BASE(wTab, TITLE='Filtered TOIs', /row, uvalue='tois')
  comm1         = widget_base( wt1, /row, /frame)
  display_draw1 = widget_draw( comm1, xsize=im_size[0], ysize=im_size[1], /button_events)
  comm11        = widget_base( comm1, /column, /frame)
  b = widget_button( comm11, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)

  wT2           =  WIDGET_BASE(wTab, TITLE='Scan', /row, uvalue='scan')
  comm2         = widget_base( wt2, /row, /frame)
  display_draw2 = widget_draw( comm2, xsize=im_size[0], ysize=im_size[1], /button_events)
  comm22        = widget_base( comm2, /column, /frame)
  b = widget_button( comm22, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)

  wT3           =  WIDGET_BASE(wTab, TITLE='Synchro', /row, uvalue='synchro')
  comm3         = widget_base( wt3, /row, /frame)
  display_draw3 = widget_draw( comm3, xsize=im_size[0], ysize=im_size[1], /button_events)
  comm33        = widget_base( comm3, /column, /frame)
  b = widget_button( comm33, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)

  wT4           =  WIDGET_BASE(wTab, TITLE='Noise', /row, uvalue='noise')
  comm4         = widget_base( wt4, /row, /frame)
  display_draw4 = widget_draw( comm4, xsize=im_size[0], ysize=im_size[1], /button_events)
  comm44        = widget_base( comm4, /column, /frame)
  b = widget_button( comm44, uvalue='quit',    value=np_cbb( 'Quit', bg='Firebrick', xs=xs, ys=xs), xs=xs, ys=ys)


  ;; Realize the widget
;  xsize = long( (npix+xs)*1.05)
;  xsize = im_size[0] + xs*1.3
  xoff = !screen_size[0]-xsize*1.3
  widget_control, main, /realize, xoff=xoff, xs=xsize, ys=ysize

  widget_control, display_draw0, get_value=drawID0
  widget_control, display_draw1, get_value=drawID1
  widget_control, display_draw2, get_value=drawID2
  widget_control, display_draw3, get_value=drawID3
  widget_control, display_draw4, get_value=drawID4

  ;;----------------------------------------------------------------------------------------------
  ;; Quicklook at timelines (Raw)
  wset, drawID0
  for lambda=1, 2 do begin
     w = where( kidpar.type eq 1 and kidpar.array eq lambda, nw)
     if nw ne 0 then begin
        nw = nw < 4   ; for plot purpose                                                                                                                        
        my_multiplot, 1, 1, ntot=nw, pp, pp1, /full
        for i=0, nw-1 do begin
           if i eq 0 then begin
              xtitle = 'Time (sec)'
              !x.charsize = 1
           endif else begin
              delvarx, charsize
              !x.charsize = 1e-10
           endelse
           plot, data_copy.toi[ w[i]], /xs, /ys, /noerase, position=pp1[i,*], $
                 xtitle='Sample num'
           oplot, data_copy.toi[ w[i]], col=default_col[lambda]
           legendastro, [ strtrim(lambda,2)+"mm", $
                          "(Raw) toi, kid "+strtrim(w[i],2)], box=0
        endfor
        my_multiplot, /reset
     endif
  endfor

  ;;----------------------------------------------------------------------------------------------
  ;; Quicklook at timelines (filtered)
  wset, drawID1
  for lambda=1, 2 do begin
     w = where( kidpar.type eq 1 and kidpar.array eq lambda, nw)
     if nw ne 0 then begin
        nw = nw < 4   ; for plot purpose                                                                                                                        
        my_multiplot, 1, 1, ntot=nw, pp, pp1, /full
        for i=0, nw-1 do begin
           if i eq 0 then begin
              xtitle = 'Time (sec)'
              !x.charsize = 1
           endif else begin
              delvarx, charsize
              !x.charsize = 1e-10
           endelse
           plot, time, data.toi[ w[i]], /xs, /ys, /noerase, position=pp1[i,*], $
                 xtitle=xtitle
           oplot, time, data.toi[ w[i]], col=default_col[lambda]
           legendastro, [ strtrim(lambda,2)+"mm", $
                          "(filtered) toi, kid "+strtrim(w[i],2)], box=0
        endfor
        my_multiplot, /reset
     endif
  endfor


  ;; ----------------------------------------------------------------------------------------------------                                                       
  ;; Quicklook at the scan pattern and parameters 
  wset, drawID2
  wsubscan = where( data.subscan ge 1, nwsubscan)
  if nwsubscan eq 0 then message, "No subscan >= 1 ?"

;; scanning speed                                                                                                                                            
  ws2 = where( data.subscan eq 2, nws2)
  dx = data.ofs_az - shift( data.ofs_az, 1)
  scan_speed = sqrt( dx^2)* !nika.f_sampling ; compute only in azimuth to avoid numerical jumps with the elevation                                             
  yra_speed = minmax( scan_speed[wsubscan[1:*]]) ; make sure the fist sample is discarded in speed estimation                                              
  ws2 = where( data.subscan eq 2, nws2)
  median_speed = median( scan_speed[ws2[1:*]])
  smax = max( data.subscan)
  avg_speed = 0.d0
  for iscan=1, smax do begin
     w = where( data.subscan eq iscan, nw)
     avg_speed += abs( max( data[w].ofs_az) - min( data[w].ofs_az))/(nw/!nika.f_sampling) / smax
  endfor
  
;; Plots                                                                                                                                                     
  !p.multi=[0,2,3]
  plot, data.ofs_az, data.ofs_el, /iso, xtitle='OFS_AZ', ytitle='OFS_el', chars=1.5
  oplot, data[wsubscan].ofs_az, data[wsubscan].ofs_el, psym=3, col=150, thick=2
  plot,  time, data.subscan
  oplot, time[wsubscan], data[wsubscan].subscan, col=150, psym=3, thick=2
  legendastro, "Subscan", box=0
  
  plot, time, data.scan_st, chars=1.5, /xs
  oplot, time[wsubscan], data[wsubscan].scan_st, col=150, psym=3, thick=2
  legendastro, "Scan_st", box=0
  
  plot, time, scan_speed, xtitle='Time', yra=yra_speed, /ys, chars=1.5, /xs
  oplot, time[wsubscan], scan_speed[wsubscan], col=150, psym=3, thick=2
  legendastro, ["Scan speed (arcsec/s)", $
                "", $
                "median speed (1subscan): "+strtrim( string(median_speed,format=fmt), 2), $
                "aveg speed (per subscan): "+strtrim( string(avg_speed,format=fmt), 2)], box=0
  
  ;;n_histwork, scan_speed[wsubscan], /fill, min=0, max=4*median_speed, fcolor=150, chars=1.5
  np_histo, scan_speed[wsubscan], fcol=150, min=0, max=4*median_speed, charsize=1.5
  legendastro, 'Instantaneous Scan speed (arcsec/s)', chars=1.5, box=0
  
;; Check the regularity of time samples sent by Elvin.
;; This enters the interpolation of the pointing, and if they are delayed, it
;; leads to under/over estimation of the scanning speed
  w = where( time ge 206 and time le 210)
  ww = where( long( (data[w].mjd-data[w[0]].mjd)*1d8 mod 100) eq 0 or long( (data[w].mjd-data[w[0]].mjd)*1d8 mod 100) eq 99)
  plot,  time[w], scan_speed[w], /xs, xtitle='time (sec)', ytitle='Scan speed', chars=1.5
  oplot, time[w], scan_speed[w], psym=1
  oplot, time[w[ww]], scan_speed[w[ww]], psym=4, col=250
  legendastro, ['Points sent by Elvin'], psym=4, col=250, textcol=250, box=0
  !p.multi=0
  
  ;; ----------------------------------------------------------------------------------------------------
  ;; Quicklook at timing   
  wset, drawID3
  !p.multi=[0,2,2]
  if tag_exist( data, 'a_t_utc') then begin
     mjd = (data.mjd - long( data[100].mjd))*86400.d0
     dt_med =  median( data.a_t_utc -mjd)
     
     plot, time, data.a_t_utc -mjd, /ys, /xs, yra=[-1,1], xtitle='time (sec)', ytitle='Seconds', title='A_T_UTC - MJD'
     oplot, time, time*0 + 1/!nika.f_sampling, col=150, thick=2
     oplot, time, time*0 - 1/!nika.f_sampling, col=150, thick=2
     oplot, time, time*0 + dt_med, col=250
     legendastro, ["median value: "+strtrim( string( dt_med*1000, format=fmt), 2)+" msec", $
                   "+- 1 sample"], col=[250, 150], line=0, box=0
  endif

  if tag_exist( data, 'b_t_utc') then begin
     mjd = (data.mjd - long( data[100].mjd))*86400.d0
     dt_med =  median( data.b_t_utc -mjd)

     plot, time, data.b_t_utc -mjd, /ys, /xs, yra=[-1,1], xtitle='time (sec)', ytitle='Seconds', title='B_T_UTC - MJD'
     oplot, time, time*0 + 1/!nika.f_sampling, col=150, thick=2
     oplot, time, time*0 - 1/!nika.f_sampling, col=150, thick=2
     oplot, time, time*0 + dt_med, col=250
     legendastro, ["median value: "+strtrim( string( dt_med*1000, format=fmt), 2)+" msec", $
                   "+- 1 sample"], col=[250, 150], line=0, box=0
  endif

  if tag_exist( data, 'b_t_utc') and tag_exist( data, 'a_t_utc') then begin
     dt = data.b_t_utc - data.a_t_utc
     dt_med =  median( dt)

     ymin = -0.1 < min(dt)
     ymax =  0.1 > max(dt)
     yra = [ymin,ymax] + [-1,1]*0.2*(ymax-ymin)
     plot, time, dt, /ys, /xs, yra=yra, xtitle='time (sec)', ytitle='Seconds', title='B_T_UTC - A_T_UTC'
     oplot, time, time*0 + 1/!nika.f_sampling, col=150, thick=2
     oplot, time, time*0 - 1/!nika.f_sampling, col=150, thick=2
     legendastro, ["+- 1 sample", $
                   "Median diff: "+strtrim( string( dt_med*1000, format=fmt), 2)+" ms"], $
                  textcol=[150, !p.color], box=0
  endif
  !p.multi = 0

  
  ;; ------------------------------------------------------------------------------------------------------
  ;; Noise properties, zeroed samples
  wset, drawID4
  ktn_noise_estim
  wplot = where( kidpar.plot_flag eq 0, nwplot)
  lambda = kidpar[wplot[0]].array
  my_multiplot, 2, 1, pp, pp1, /rev
  np_histo, kidpar[wplot].noise, fcol=70, /noerase, xtitle='Hz/sqrt(Hz)', chars=1.5, position=pp1[0,*]
  noise_med = median( kidpar[wplot].noise)
  legendastro, [strtrim(lambda,2)+" mm", $
                'Avg noise > 4 Hz', $
                "", $
                'Median: '+strtrim( string( noise_med, format=fmt), 2)+" Hz/Hz!u-1/2!n"], box=0, /right, charsize=1.5

  np_histo, kidpar[wplot].sensitivity_decorr, fcol=150, /noerase, xtitle='Jy.s!u1/2!n', chars=1.5, position=pp1[1,*]
  med = median( kidpar[wplot].sensitivity_decorr)
  legendastro, [strtrim(lambda,2)+" mm", $
                'Sensitiviy ', $
                "", $
                'Median: '+num2string(med)+" Jy.s!u1/2!n"], box=0, /right
  my_multiplot, /reset
  
;; Plot de kurtosis sur une fenetre glissante de 50 pts, flag if >1 or infinite
;; How to display ? 

  ks = lonarr(5)
  ks[0] = drawID0
  ks[1] = drawID1
  ks[2] = drawID2
  ks[3] = drawID3
  ks[4] = drawID4
  xmanager, 'sanity_checks', main, /no_block
END
