pro kid_popup

  common ql_maps_common

  xra1 = minmax( x_peaks_1[wplot])
  yra1 = minmax( y_peaks_1[wplot])
  xmin = mean(xra1) - 0.3*(xra1[1]-xra1[0])
  xmax = mean(xra1) + 0.3*(xra1[1]-xra1[0])
  ymin = mean(yra1) - 0.3*(yra1[1]-yra1[0])
  ymax = mean(yra1) + 0.3*(yra1[1]-yra1[0])
  
  get_x0y0, x_peaks_1[wplot], y_peaks_1[wplot], xc0, yc0, ww
  ibol_ref = wplot[ww]
  
  wind, 3, 1, /large
  DEVICE, CURSOR_STANDARD= 90
  NEW_POINT:
  !p.position=0
  !p.multi=0
  plot, x_peaks_1[wplot], y_peaks_1[wplot], psym=1, /iso, xtitle='mm', ytitle='mm', $
        title=nickname, xra=xra_plot, yra=yra_plot, /noerase
  oplot, [xc0], [yc0], psym=4, col=150
  legendastro, ['Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
           'xc0 = '+strtrim(xc0,2), $
           'yc0 = '+strtrim(yc0,2)], chars=1.5
  legendastro, ['Nvalid='+strtrim(nw1,2)], /right, chars=1.5
  if nw3 ne 0 then oplot, x_peaks_1[w3], y_peaks_1[w3], psym=1, col=250
  xyouts, x_peaks_1[wplot]+1, y_peaks_1[wplot]+1, strtrim(wplot,2), chars=1.2

  print, "select 1 pixel:"
  CURSOR, X, Y, /WAIT, device=device
  IF !MOUSE.BUTTON EQ 2 OR !MOUSE.BUTTON EQ 4 THEN GOTO, CLOSING

  d2 = (x_peaks_1-x)^2 + (y_peaks_1-y)^2
  current_pix = where( d2 eq min(d2))
  imview, reform( map_list_out[current_pix,*,*]), xmap=xmap, ymap=ymap, $
          udg=rebin_factor, title="Kid "+strtrim(current_pix,2), $
          position=[0.5, 0.5, 0.9, 0.9]

; Suspend going on for a while
  GOTO, NEW_POINT

CLOSING:
  DEVICE, /CURSOR_ORIGINAL

end
