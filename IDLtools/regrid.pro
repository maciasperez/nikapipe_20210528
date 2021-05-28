
pro regrid, grid_in, param_in, grid_out, param_out, noplot=noplot

npix1 = long(grid_in.nx)*long(grid_in.ny)
npix2 = long(grid_out.nx)*long(grid_out.ny)

;; Mapping from grid_in to grid_out
a12 = dblarr(npix1,npix2)

xra = [min([min(grid_in.xmap-grid_in.map_reso/2.), min(grid_out.xmap-grid_out.map_reso/2.)]), $
       max([max(grid_in.xmap+grid_in.map_reso/2.), max(grid_out.xmap+grid_out.map_reso/2.)])]
yra = [min([min(grid_in.ymap-grid_in.map_reso/2.), min(grid_out.ymap-grid_out.map_reso/2.)]), $
       max([max(grid_in.ymap+grid_out.map_reso/2.), max(grid_out.ymap+grid_out.map_reso/2.)])]

if not keyword_set(noplot) then begin
   wind, 1, 1, /free, ysize=600, xsize=700
   my_multiplot, 2, 2, pp, pp1, /rev
   imview, grid_in.map_i1, xmap=grid_in.xmap, ymap=grid_in.ymap, $
           xtitle='arcmin', ytitle='arcmin', title='grid_in', colt=1, $
           xra = xra, yra=yra, position=pp1[0,*]
   oplot, [1,1]*param_in.map_center_ra, [1,1]*param_in.map_center_dec, psym=1, syms=2, col=255
   oplot, [1,1]*param_out.map_center_ra, [1,1]*param_out.map_center_dec, psym=1, syms=2, col=250
   for ipix2=0, npix2-1 do $
      plots, [grid_out.xmap[ipix2]-grid_out.map_reso/2., $
              grid_out.xmap[ipix2]-grid_out.map_reso/2., $
              grid_out.xmap[ipix2]+grid_out.map_reso/2., $
              grid_out.xmap[ipix2]+grid_out.map_reso/2., $
              grid_out.xmap[ipix2]-grid_out.map_reso/2.], $
             [grid_out.ymap[ipix2]-grid_out.map_reso/2., $
              grid_out.ymap[ipix2]+grid_out.map_reso/2., $
              grid_out.ymap[ipix2]+grid_out.map_reso/2., $
              grid_out.ymap[ipix2]-grid_out.map_reso/2., $
              grid_out.ymap[ipix2]-grid_out.map_reso/2.], col=250
endif

x1 = (dblarr(npix2)+1)##reform(grid_in.xmap, npix1)
x2 = reform(grid_out.xmap,npix2)##(dblarr(npix1)+1)
y1 = (dblarr(npix2)+1)##reform(grid_in.ymap, npix1)
y2 = reform(grid_out.ymap,npix2)##(dblarr(npix1)+1)
mask = long( abs(x1-x2) le (grid_in.map_reso+grid_out.map_reso)/2.d0 and $
             abs(y1-y2) le (grid_in.map_reso+grid_out.map_reso)/2.d0)

w = where( mask ne 0, nw)
a = dblarr( npix1, npix2)
if nw eq 0 then begin
   message, /info, "oh oh...?!"
endif else begin
   for i=0, nw-1 do begin
      icross=w[i]
      xmin = max( [x1[icross]-grid_in.map_reso/2.d0, x2[icross]-grid_out.map_reso/2.d0])
      xmax = min( [x1[icross]+grid_in.map_reso/2.d0, x2[icross]+grid_out.map_reso/2.d0])
      ymin = max( [y1[icross]-grid_in.map_reso/2.d0, y2[icross]-grid_out.map_reso/2.d0])
      ymax = min( [y1[icross]+grid_in.map_reso/2.d0, y2[icross]+grid_out.map_reso/2.d0])
      a[icross] = abs(xmax-xmin)*abs(ymax-ymin)/grid_in.map_reso^2
   endfor
endelse

;; Normalize weights
for i=0, npix2-1 do begin
   if total( a[*,i]) gt 0.d0 then a[*,i] /= total(a[*,i])
endfor

grid_out.map_i1    = reform( a##reform(grid_in.map_i1,npix1), grid_out.nx, grid_out.ny)
grid_out.map_i2    = reform( a##reform(grid_in.map_i2,npix1), grid_out.nx, grid_out.ny)
grid_out.map_i3    = reform( a##reform(grid_in.map_i3,npix1), grid_out.nx, grid_out.ny)
grid_out.map_i_1mm = reform( a##reform(grid_in.map_i_1mm,npix1), grid_out.nx, grid_out.ny)
grid_out.map_i_2mm = reform( a##reform(grid_in.map_i_2mm,npix1), grid_out.nx, grid_out.ny)

grid_out.map_nhits1    = reform( a##reform(grid_in.map_nhits1,npix1), grid_out.nx, grid_out.ny)
grid_out.map_nhits2    = reform( a##reform(grid_in.map_nhits2,npix1), grid_out.nx, grid_out.ny)
grid_out.map_nhits3    = reform( a##reform(grid_in.map_nhits3,npix1), grid_out.nx, grid_out.ny)
grid_out.map_nhits_1mm = reform( a##reform(grid_in.map_nhits_1mm,npix1), grid_out.nx, grid_out.ny)
grid_out.map_nhits_2mm = reform( a##reform(grid_in.map_nhits_2mm,npix1), grid_out.nx, grid_out.ny)

grid_out.map_var_i1    = reform( a##reform(grid_in.map_var_i1,npix1), grid_out.nx, grid_out.ny)
grid_out.map_var_i2    = reform( a##reform(grid_in.map_var_i2,npix1), grid_out.nx, grid_out.ny)
grid_out.map_var_i3    = reform( a##reform(grid_in.map_var_i3,npix1), grid_out.nx, grid_out.ny)
grid_out.map_var_i_1mm = reform( a##reform(grid_in.map_var_i_1mm,npix1), grid_out.nx, grid_out.ny)
grid_out.map_var_i_2mm = reform( a##reform(grid_in.map_var_i_2mm,npix1), grid_out.nx, grid_out.ny)

if tag_exist( grid_in.map_q1) then begin
   grid_out.map_q1    = reform( a##reform(grid_in.map_q1,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_q2    = reform( a##reform(grid_in.map_q2,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_q3    = reform( a##reform(grid_in.map_q3,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_q_1mm = reform( a##reform(grid_in.map_q_1mm,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_q_2mm = reform( a##reform(grid_in.map_q_2mm,npix1), grid_out.nx, grid_out.ny)

   grid_out.map_u1    = reform( a##reform(grid_in.map_u1,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_u2    = reform( a##reform(grid_in.map_u2,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_u3    = reform( a##reform(grid_in.map_u3,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_u_1mm = reform( a##reform(grid_in.map_u_1mm,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_u_2mm = reform( a##reform(grid_in.map_u_2mm,npix1), grid_out.nx, grid_out.ny)

   grid_out.map_var_q1    = reform( a##reform(grid_in.map_var_q1,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_q2    = reform( a##reform(grid_in.map_var_q2,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_q3    = reform( a##reform(grid_in.map_var_q3,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_q_1mm = reform( a##reform(grid_in.map_var_q_1mm,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_q_2mm = reform( a##reform(grid_in.map_var_q_2mm,npix1), grid_out.nx, grid_out.ny)
   
   grid_out.map_var_u1    = reform( a##reform(grid_in.map_var_u1,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_u2    = reform( a##reform(grid_in.map_var_u2,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_u3    = reform( a##reform(grid_in.map_var_u3,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_u_1mm = reform( a##reform(grid_in.map_var_u_1mm,npix1), grid_out.nx, grid_out.ny)
   grid_out.map_var_u_2mm = reform( a##reform(grid_in.map_var_u_2mm,npix1), grid_out.nx, grid_out.ny)
endif



end

