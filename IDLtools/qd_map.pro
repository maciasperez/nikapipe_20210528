
; quick and dirty timeline map making for ground calibration

pro qd_map, x, y, signal, reso, xmap, ymap, map, nhits, $
            w8=w8, ix=ix, iy=iy, ipix=ipix, $
            alpha_deg=alpha_deg, xc_rot=xc_rot, yc_rot=yc_rot, verbose=verbose

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "qd_map, x, y, signal, reso, xmap, ymap, map, nhits, $"
   print, "        w8=w8, ix=ix, iy=iy, ipix=ipix, $"
   print, "        alpha_deg=alpha_deg, xc_rot=xc_rot, yc_rot=yc_rot, verbose=verbose"
   return
endif

if not keyword_set(w8) then w8 = x*0.0d0 + 1.0d0

nsn   = n_elements(x)
dx1   = reform( double(x), nsn)
dy1   = reform( double(y), nsn)
xmin  = min( xmap) - reso/2.d0 ; xmap, ymap give coordinates of the pixel centers
ymin  = min( ymap) - reso/2.d0
nx    = n_elements( xmap[*,0])
ny    = n_elements( xmap[0,*])
npix  = long(nx)*long(ny)
map   = xmap*0.0d0
nhits = xmap*0.0d0

if not keyword_set(alpha_deg) then alpha_deg = 0.0d0
if not keyword_set(xc_rot)    then xc_rot    = 0.0d0
if not keyword_set(yc_rot)    then yc_rot    = 0.0d0

alpha = alpha_deg*!dtor
dx = cos(alpha)*(dx1-xc_rot) - sin(alpha)*(dy1-yc_rot)
dy = sin(alpha)*(dx1-xc_rot) + cos(alpha)*(dy1-yc_rot)

ix    = long( (dx-xmin)/reso)
iy    = long( (dy-ymin)/reso)
ipix  = ix + iy*nx

w = where( (ix ge 0) and (ix le (nx-1)) and $
           (iy ge 0) and (iy le (ny-1)), nw)
if nw eq 0 and keyword_set(verbose) then begin
   print, "no good pixel ?!"
   print, "minmax(dx): ", minmax(dx)
   print, "minmax(dy): ", minmax(dy)
   print, "xrange: ", xmin, max(xmap)+reso/2.
   print, "yrange: ", ymin, max(ymap)+reso/2.
endif else begin

   for i=0L, nw-1 do begin
      map[   ipix[w[i]]] += signal[w[i]] * w8[ w[i]]
      nhits[ ipix[w[i]]] += w8[ w[i]]
   endfor
   
   w = where( nhits ne 0, nw, compl=w1, ncompl=nw1)
   if nw  ne 0 then map[w]  = map[w]/nhits[w]
   if nw1 ne 0 then map[w1] = !values.d_nan
endelse

end
