
; Plots a scalar quantity on a x,y grid

;; @check_matrix_plot.pro
;+
pro matrix_plot, x, y, z, zrange=zrange, nlevels=nlevels, position=position, xrange=xrange, yrange=yrange, $
                 charsize=charsize, nticks=nticks, format=format, small = small, symsize=symsize, $
                 units=units, outcolor=outcolor, incolor=incolor, nobar=nobar, $
                 psym = psym, postscript=postscript, coltable=coltable, black_and_white=black_and_white, $
                 title=title, noerase=noerase, iso=iso, xtitle=xtitle, ytitle=ytitle, rgb=rgb
;-
if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   dl_unix, 'matrix_plot'
   return
endif

if not keyword_set(small) then my_symsize = 1 else my_symsize = 0.5
if keyword_set(symsize) then my_symsize=symsize
if not keyword_set(psym)       then psym = 8
if not keyword_set(nlevels)    then nlevels    = 5
if not keyword_set(zrange)     then zrange     = minmax(z)
if keyword_set(position) then begin
   my_position = reform( position, 4) ; make sure
endif else begin
   position = [0.1, 0.1, 0.9, 0.9]
endelse
if not keyword_set(coltable) then coltable=39
if keyword_set(black_and_white) then coltable=0

loadct, coltable

n = n_elements(x)

;; Color table
ctmin = 0
ctmax = 254 ; to avoid that the largest value appear as white on top of white background
zmin  = min( double(zrange))
zmax  = max( double(zrange))
dcol  = (zmax-zmin)/nlevels

;; Force xrange and yrange to compute bar position accurately
if not keyword_set(xrange) then xrange = minmax(x)
if not keyword_set(yrange) then yrange = minmax(y)

;; Leave room for the bar
pp = [position[0], position[1], $
      position[0]+(position[2]-position[0])*0.8, $
      position[3]]

;; Plot
if keyword_set(incolor) then outcolor=incolor else outcolor = fltarr(n)

if keyword_set(rgb) then tvlct, reform(rgb[0,*]), reform(rgb[1,*]), reform(rgb[2,*])

plot, x, y, charsize=charsize, noerase=noerase, iso=iso, $
      /nodata, position=pp, /xs, /ys, xrange=xrange, yrange=yrange, title=title, xtitle=xtitle, ytitle=ytitle
for ibol=0, n-1 do begin
   if not keyword_set(incolor) then begin
      icol = ((z[ibol]-zmin)/(zmax-zmin)>0) < 1.0d0
      outcolor[ibol] = icol*ctmax + ctmin
   endif
   oplot, [x[ibol]], [y[ibol]], psym=psym, syms=my_symsize, col=outcolor[ibol]
endfor

if not keyword_set(nobar) then begin

   init_bar_params
   
;;    if keyword_set(postscript) then begin
;;       dpx = position(2)-position(0)
;;       dpy = position(3)-position(1)
;;       pix_per_position = [taille(1)/dpx, taille(2)/dpy]
;;       tx = pix_per_position(0)  ; taille du champ en DEVICE
;;       ty = pix_per_position(1)  ; taille du champ en DEVICE
;;       if not keyword_set(bits) then bits=8
;;       xdisplay_size = 19.
;;       ydisplay_size = 27.
;;       xsize_psdev = xdisplay_size*1000.
;;       ysize_psdev = ydisplay_size*1000.
;;       scale = min([fix(xsize_psdev/float(tx)), $
;;                    fix(ysize_psdev/float(ty))])
;;       
;;       ps_sizex = 15             ; taille du champ PS en cm
;;       ps_sizey = 15        ; taille du champ PS en cm
;;       !MAMDLIB.SCALE = scale
;;       !MAMDLIB.PS_SIZEX = ps_sizex
;;       !MAMDLIB.PS_SIZEY = ps_sizey
;;       xoffset = (21.-ps_sizex)/2.
;;       yoffset = (29.-ps_sizey)/2.
;;    endif

   !p.charthick = 1

   dummy = convert_coord(xrange[1], yrange[0], /to_device)
   x0_bar = dummy[0]/!d.x_size
   y0_bar = dummy[1]/!d.y_size
   dummy  = convert_coord(xrange[1], yrange[1], /to_device)
   y1_bar = dummy[1]/!d.y_size
   posbar = [x0_bar+(!bar.thickbar+!bar.dxbar)/8., y0_bar, $
             x0_bar+(!bar.thickbar+!bar.dxbar)/2., $
             y1_bar]

   if not keyword_set(nticks) then nticks = nlevels
   value = dindgen(nticks)/(nticks-1)*(zmax-zmin) + zmin
   mamd_bar, posbar, imrange=[zmin, zmax], value=value, format=format, charsize=charsize
   
;; Units
   if keyword_set(units) then begin
      posunits = [posbar[0], posbar[3]+0.02]
      xyouts, posunits[0], posunits[1], units, /normal, charsize=charsize
   endif
endif

end
