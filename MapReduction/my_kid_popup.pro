pro my_kid_popup

  common ql_maps_common
  
  defsysv, "!fw", create_struct("xcursor", 0., "ycursor", 0., $
                                "xpos", 0., "ypos", 0.)


  wind, 3, 1, /large, xpos=xpos, ypos=ypos
  !fw.xpos = xpos
  !fw.ypos = ypos

  DEVICE, CURSOR_STANDARD= 90

  NEW_POINT:
  !p.position=[0.05, 0.05, 0.7, 0.7]
  !p.multi=0

  ;; refresh wplot
  gna = where( kidpar[wplot].type le 3)
  wplot = wplot[gna]

  xcenter_plot = avg( x_peaks_1[wplot])
  ycenter_plot = avg( y_peaks_1[wplot])
  xra_plot = xcenter_plot + [-1,1]*max( abs(x_peaks_1[wplot]-xcenter_plot))*1.2
  yra_plot = ycenter_plot + [-1,1]*max( abs(y_peaks_1[wplot]-ycenter_plot))*1.2
  
  get_x0y0, x_peaks_1[wplot], y_peaks_1[wplot], xc0, yc0, ww
  ibol_ref = wplot[ww]

  def_pos = [0.05, 0.05, 0.6, 0.6]

  wset, 3
  !p.position = def_pos
  plot, x_peaks_1[wplot], y_peaks_1[wplot], psym=1, /iso, xtitle='mm', ytitle='mm', $
        title=nickname, xra=xra_plot, yra=yra_plot
  oplot, [xc0], [yc0], psym=4, col=150
  legendastro, ['Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
           'xc0 = '+strtrim(xc0,2), $
           'yc0 = '+strtrim(yc0,2)], chars=1.5
  legendastro, ['Nvalid='+strtrim(nw1,2)], /right, chars=1.5
  if nw3 ne 0 then oplot, x_peaks_1[w3], y_peaks_1[w3], psym=1, col=250
  xyouts, x_peaks_1[wplot]+1, y_peaks_1[wplot]+1, strtrim(kidpar[wplot].numdet,2), chars=1.2
  beam_scale = 0.4
  phi = dindgen(200)/200*2*!dpi
  cosphi = cos(phi)
  sinphi = sin(phi)
  for i=0, n_elements(wplot)-1 do begin
     ikid = wplot[i]
     xx1 = beam_scale*sigma_x_1[ikid]*cosphi
     yy1 = beam_scale*sigma_y_1[ikid]*sinphi
     x1 =  cos(theta_1[ikid])*xx1 - sin(theta_1[ikid])*yy1
     y1 =  sin(theta_1[ikid])*xx1 + cos(theta_1[ikid])*yy1
     oplot, x_peaks_1[ikid]+x1, y_peaks_1[ikid]+y1, col=250
  endfor

  print, "select 1 pixel (left to display, right to edit, middle to quit):"
  CURSOR, xcursor, ycursor, /WAIT, device=device
  r = convert_coord( xcursor, ycursor, /to_device)
  case !mouse.button of
     1: begin ; left button
        d2 = (x_peaks_1-xcursor)^2 + (y_peaks_1-ycursor)^2
        ibol = where( d2 eq min(d2))
        
        wset, 3
        !p.position = def_pos
        plot, x_peaks_1[wplot], y_peaks_1[wplot], psym=1, /iso, xtitle='mm', ytitle='mm', $
              title=nickname, xra=xra_plot, yra=yra_plot
        oplot, [xc0], [yc0], psym=4, col=150
        legendastro, ['Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
                      'xc0 = '+strtrim(xc0,2), $
                      'yc0 = '+strtrim(yc0,2)], chars=1.5
        legendastro, ['Nvalid='+strtrim(nw1,2)], /right, chars=1.5
        if nw3 ne 0 then oplot, x_peaks_1[w3], y_peaks_1[w3], psym=1, col=250
        xyouts, x_peaks_1[wplot]+1, y_peaks_1[wplot]+1, strtrim(kidpar[wplot].numdet,2), chars=1.2
        beam_scale = 0.4
        phi = dindgen(200)/200*2*!dpi
        cosphi = cos(phi)
        sinphi = sin(phi)
        for i=0, n_elements(wplot)-1 do begin
           ikid = wplot[i]
           xx1 = beam_scale*sigma_x_1[ikid]*cosphi
           yy1 = beam_scale*sigma_y_1[ikid]*sinphi
           x1 =  cos(theta_1[ikid])*xx1 - sin(theta_1[ikid])*yy1
           y1 =  sin(theta_1[ikid])*xx1 + cos(theta_1[ikid])*yy1
           oplot, x_peaks_1[ikid]+x1, y_peaks_1[ikid]+y1, col=250
        endfor

        ;;wind, 4, 1, /free, xs=800, ys=300
        imview, reform( map_list_out[ibol,*,*]), xmap=xmap, ymap=ymap, /noerase, $
                udg=rebin_factor, title="Kid "+strtrim(ibol,2), $
                position=[0.05, 0.6, 0.5, 0.95], legend=['Numdet : '+strtrim(kidpar[ibol].numdet,2), $
                                                      'Flag = '+strtrim(kidpar[ibol].type,2)], leg_color=textcol
        
        fmt="(F9.2)"
        imview, reform( beam_list_1[ibol,*,*]), xmap=xmap, ymap=ymap, /noerase, $
                udg=rebin_factor, title="Kid "+strtrim(ibol,2), $
                position=[0.45, 0.6, 0.9, 0.95], legend=['Numdet : '+strtrim(kidpar[ibol].numdet,2), $
                                                       'Flag = '+strtrim(kidpar[ibol].type,2)], leg_color=textcol
        legendastro, ['Ampl: '+string(a_peaks_1[ibol],format=fmt), $
                      'FWHM: '+string( sqrt( sigma_x_1[ibol]*sigma_y_1[ibol])/!fwhm2sigma, format=fmt)], box=0, /right, textcol=textcol

        !fw.xcursor = r[0] + !fw.xpos
        !fw.ycursor = r[1] + !fw.ypos
        flag_widget
     end

     2: goto, closing
     4: goto, closing

  endcase

  GOTO, NEW_POINT

CLOSING:
  !p.position = 0
  !p.multi    = 0
  DEVICE, /CURSOR_ORIGINAL

end
