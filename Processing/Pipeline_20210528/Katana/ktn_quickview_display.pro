pro ktn_quickview_display, xra_plot, yra_plot, position=position, $
                           ikid_in=ikid_in, noerase=noerase, only_ikid=only_ikid, nasmyth=nasmyth, $
                           noellipse=noellipse

  common ktn_common

  if keyword_set(nasmyth) then begin
     title = 'Nasmyth'
     kidpar.x_peak = kidpar.x_peak_nasmyth
     kidpar.y_peak = kidpar.y_peak_nasmyth
  endif else begin
     title = 'Az, El'
     kidpar.x_peak = kidpar.x_peak_azel
     kidpar.y_peak = kidpar.y_peak_azel
  endelse

  if not keyword_set(ikid_in)  then ikid_in  = -1
  if not keyword_set(position) then position = fltarr(4)

  w1    = where( kidpar.type eq 1, nw1)
  w3    = where( kidpar.type eq 3, nw3)
  wplot = where( kidpar.plot_flag eq 0, nwplot)


  ;; ---------------------------------------------------------------------------
  ;; Display maps first to have a correct redefinition of xy plot ranges for the
  ;; interactive cursor

  ;; Display kid map
  fmt="(F9.2)"
  position = [0.6,  0.62,  0.95,  0.95]
  imview, reform( disp.map_list[disp.ikid,*,*]), xmap=xmap, ymap=ymap, $
          udg=rebin_factor, position=position, legend_text=['True map', 'Numdet: '+strtrim(kidpar[ikid_in].numdet,2)], leg_color=255
  
;; Display kid beam fit
  position=[0.6,0.1 ,0.95,0.6]
  imview, reform( disp.beam_list[disp.ikid,*,*]), xmap=xmap, ymap=ymap, $
          udg=rebin_factor, position = position, /noerase, legend_text=['Gaussian fit', 'Numdet: '+strtrim(kidpar[ikid_in].numdet,2)], leg_color=255

!x.charsize = 1
!y.charsize = 1

;;----------------------------------------------------------------------------------------
;; Focal plane
  xcenter_plot = avg( kidpar[wplot].x_peak)
  ycenter_plot = avg( kidpar[wplot].y_peak)
  xra_plot = xcenter_plot + [-1,1]*max( abs(kidpar[wplot].x_peak-xcenter_plot))*1.1
  yra_plot = ycenter_plot + [-1,1]*max( abs(kidpar[wplot].y_peak-ycenter_plot))*1.1

  xra_plot = [xra_plot[0] <(-100), xra_plot[1] >100] ; to keep nice display
  yra_plot = [yra_plot[0] <(-100), yra_plot[1] >100] ; to keep nice display
  
  get_x0y0, kidpar[wplot].x_peak, kidpar[wplot].y_peak, xc0, yc0, ww
  ibol_ref = wplot[ww]

  position = [0.05, 0.05, 0.6, 0.95]
  plot, [kidpar[wplot].x_peak], [kidpar[wplot].y_peak], psym=1, /iso, xtitle='mm', ytitle='mm', $
        title=title, xra=xra_plot, yra=yra_plot, /noerase, position=position
  oplot, [xc0], [yc0], psym=4, col=150
  if not keyword_set(only_ikid) then begin
     legendastro, ['Approx center kid = '+strtrim( kidpar[ibol_ref].numdet,2), $
                   'xc0 = '+strtrim(xc0,2), $
                   'yc0 = '+strtrim(yc0,2)], chars=1.5
     legendastro, ['Nvalid='+strtrim(nw1,2)], /right, chars=1.5
  endif

  phi = dindgen(200)/200*2*!dpi
  cosphi = cos(phi)
  sinphi = sin(phi)
  for i=0, n_elements(wplot)-1 do begin
     col = !p.color
     thick=1
     ikid = wplot[i]
     if long(ikid_in) eq ikid then begin
        col = 250
        thick=2
     endif
     oplot, [kidpar[ikid].x_peak], [kidpar[ikid].y_peak], psym=1, thick=thick, col=col
     if not keyword_set(noellipse) and $
        ((long(ikid_in) eq ikid) or (not keyword_set(only_ikid))) then begin
        xx1 = disp.beam_scale*kidpar[ikid].sigma_x*cosphi
        yy1 = disp.beam_scale*kidpar[ikid].sigma_y*sinphi
        x1 =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
        y1 =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
        oplot, [kidpar[ikid].x_peak+x1], [kidpar[ikid].y_peak+y1], col=col, thick=thick
     endif
  endfor

end
