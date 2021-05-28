
pro show_matrix, matrix, window=window

  common ql_maps_common

  wx = where( x_cross gt !undef, nwx)

  if keyword_set(window) then begin
     wind, window, 1, xs=900, ys=900
  endif else begin
     wind, 1, 1, xs=900, ys=900
  endelse

  p = 0
  dx = (max(xmap)-min(xmap))*0.1

  kid_plot_position = dblarr( nkids, 4)

  dxmap = max(xmap)-min(xmap)
  dymap = max(ymap)-min(ymap)
  xmin = min(xmap)
  ymin = min(ymap)
  ymax = max(ymap)

  for j=0, n_elements(plot_position[0,*,0])-1 do begin
     for i=0, n_elements(plot_position[*,0,0])-1 do begin

        if (p lt nkids) then begin
           !p.position = plot_position[i,j,*]
           kid_plot_position[p,*] = plot_position[i, j, *]

           imview, reform(matrix[p,*,*]), xmap=xmap, ymap=ymap, position=plot_position[i,j,*], $
                   udg=rebin_factor, /nobar, xchars=1e-6, ychars=1e-6, /noerase

           xx = xmin+0.1*dxmap
           yy = ymin+0.1*dymap
           decode_flag, kidpar[p].type, flagname
           xyouts, xx, yy, flagname, chars=1.5, col=textcol

           yy = ymax-0.2*dymap
           ;;xyouts, xx, yy, strtrim(p,2), col=textcol
           xyouts, xx, yy, strtrim( kidpar[p].numdet,2), col=textcol
           if nwx ne 0 then begin
              loadct, 7, /silent
              oplot, [x_cross[wx]], [y_cross[wx]], psym=1, thick=2, col=200
              loadct, 39, /silent
           endif
           p = p + 1
        endif
     endfor
  endfor
  !p.multi = 0 
  !p.position = 0

  xyouts, !d.x_size*0.8, !d.y_size*0.9, box+strtrim(lambda,2)+'mm', chars=4, /dev

loadct, 39
end
