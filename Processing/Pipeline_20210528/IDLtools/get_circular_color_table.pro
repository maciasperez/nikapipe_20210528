
;; Defined a rgb triplet so that the maximum of the color range
;; matches the minimum: Convenient for angles or other periodic functions

pro get_circular_color_table, rgb, help=help

loadct, 39
tvlct, r, g, b, /get

i1 = min( where(g eq max(g)))
r1 = r[0:i1]
g1 = g[0:i1]
b1 = b[0:i1]
n = n_elements(r1)

i2 = 130
g1 = [g1, replicate(g1[n-1],i2-i1+1)]
r1 = [r1, replicate(r1[n-1],i2-i1+1)]
b1 = [b1, b1[n-1] + float(0-b1[i1])/float(i2-i1)*indgen(i2-i1+1)]
n = n_elements(r1)

i3 = 150
g1 = [g1, replicate(g1[n-1],i3-i2+1)]
r1 = [r1, float(255-0)/float(i3-i2)*findgen(i3-i2+1)]
b1 = [b1, replicate(b1[n-1],i3-i2+1)]
n = n_elements(r1)

i4 = 210
g1 = [g1, g1[n-1]+float(0-255)/float(i4-i3)*findgen(i4-i3+1)]
r1 = [r1, replicate(r1[n-1], i4-i3+1)]
b1 = [b1, replicate(b1[n-1],i4-i3+1)]
n = n_elements(r1)

i5 = 240
g1 = [g1, replicate(g1[n-1],i5-i4+1)]
r1 = [r1, r1[n-1] + float(0-255)/(i5-i4)*findgen(i5-i4+1)]
b1 = [b1, replicate(b1[n-1],i5-i4+1)]
n = n_elements(r1)

;; stretch or squeeze on 255 steps and leave the last one to
;; white for the background
n = n_elements(r1)
r1 = interpol( r1, dindgen(n)/(n-1), dindgen(255)/254.)
g1 = interpol( g1, dindgen(n)/(n-1), dindgen(255)/254.)
b1 = interpol( b1, dindgen(n)/(n-1), dindgen(255)/254.)
r1 = [r1, 255]
b1 = [b1, 255]
g1 = [g1, 255]

rgb = dblarr(3,256)
rgb[0,*] = r1
rgb[1,*] = g1
rgb[2,*] = b1

if keyword_set(help) then begin
   wind, 1, 1, /free, /large
   my_multiplot, 2, 2, pp, pp1, /rev, xmax=0.4
   plot,  r, position=pp[0,0,*], /xs, title='Ori. col. table'
   oplot, r, col=250
   oplot, g, col=150
   oplot, b, col=70
   plot, [0,10], [0,255], /nodata, /xs, /ys, position=pp[1,0,*], /noerase, $
         title='Ori. col. table'
   for i=0, 255 do oplot, [0,10], [1,1]*i, col=i
      
   plot,  r1, position=pp[0,1,*], /xs, /noerase, title='New col. table'
   oplot, r1, col=250
   oplot, g1, col=150
   oplot, b1, col=70

   tvlct, r1, g1, b1
   plot, [0,10], [0,255], /nodata, /xs, /ys, position=pp[1,1,*], /noerase, $
         title='New col. table'
   for i=0, 255 do oplot, [0,10], [1,1]*i, col=i

   my_multiplot, 2, 3, pp, pp1, /rev, xmin=0.4
   imview, dist(100), rgb=rgb, position=pp1[0,*], /noerase

   nk_default_param, param
   nk_default_info, info
   nk_init_grid, param, info, grid
   phi = atan( grid.ymap, grid.xmap)*!radeg
   imview, phi, rgb=rgb, position=pp1[1,*], /noerase


   nk_get_kidpar_ref, s, d, kidpar=kidpar, scan='20180614s2'
   w1 = where( kidpar.type eq 1 and kidpar.array eq 1, nw1)
   d = sqrt( kidpar[w1].nas_x^2 + kidpar[w1].nas_y^2)
   plot,  kidpar[w1].nas_x, kidpar[w1].nas_y, psym=8, syms=0.5, $
          position=pp1[2,*], /noerase, /iso, /xs, /ys
   
   matrix_plot, kidpar[w1].nas_x, kidpar[w1].nas_y, d, rgb=rgb, $
                position=pp1[3,*], /noerase, /iso, symsize=0.5
endif

end
