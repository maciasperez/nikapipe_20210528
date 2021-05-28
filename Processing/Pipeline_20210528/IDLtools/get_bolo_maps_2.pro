
;; Coordinates (x,y) are meant as offsets w.r.t. the source that is followed by
;; the telescope

pro get_bolo_maps_2, toi, x, y, w8, kidpar, map_struct, map_list, map_var_list

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

nkids = n_elements( toi[*,0])
nsn   = n_elements( toi[0,*])

wkill = where( finite(x) eq 0 or finite(y) eq 0, nwkill)
ix    = (x - map_struct.xmin)/map_struct.map_reso
iy    = (y - map_struct.ymin)/map_struct.map_reso
if nwkill ne 0 then begin
   ix[wkill] = -1
   iy[wkill] = -1
endif
ipix = double( long(ix) + long(iy)*map_struct.nx)
w = where( long(ix) lt 0 or long(ix) gt (map_struct.nx-1) or $
           long(iy) lt 0 or long(iy) gt (map_struct.ny-1), nw)
if nw ne 0 then ipix[w] = !values.d_nan ; for histogram

h = histogram( ipix, /nan, reverse_ind=R)
p = lindgen( n_elements(h)) + long(min(ipix,/nan))

; Init
map_list     = dblarr( nkids, map_struct.nx, map_struct.ny)
map_var_list = dblarr( nkids, map_struct.nx, map_struct.ny)

;; Project
;; In Katana, since we do not combine kids for individual maps, w8 is synonymous of nhits
for ikid=0, nkids-1 do begin
   map     = dblarr( map_struct.nx, map_struct.ny)
   map_w8  = dblarr( map_struct.nx, map_struct.ny)
   
   for j=0L, n_elements(h)-1 do begin
      if r[j] ne r[j+1] then begin
         index = R[R[j]:R[j+1]-1]
         map[   p[j]] += total( toi[ikid,index]*w8[index])
         map_w8[p[j]] += total( w8[index])
      endif
   endfor
   w = where( map_w8 ne 0, nw)
   if nw eq 0 then message, "All pixels empty."
   map[w] /= map_w8[w]
   
   map_var = map_w8*0.d0
   map_var[w] = 1.d0/map_w8[w]

   map_list[     ikid,*,*] = reform( map,     map_struct.nx, map_struct.ny)
   map_var_list[ ikid,*,*] = reform( map_var, map_struct.nx, map_struct.ny)
endfor

end
