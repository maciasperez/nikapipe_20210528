
;; Coordinates (x,y) are meant as offsets w.r.t. the source that is followed by
;; the telescope

pro get_bolo_maps, toi, x, y, reso, xmap, ymap, kidpar, map_list, nhits_list, $
                   w8=w8, xcenter=xcenter, ycenter=ycenter, $
                   alpha_deg=alpha_deg, xc_rot=xc_rot, yc_rot=yc_rot, calib=calib

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "get_bolo_maps, toi, x, y, reso, xmap, ymap, kidpar, map_list, nhits_list, $"
   print, "               w8=w8, xcenter=xcenter, ycenter=ycenter, $"
   print, "               alpha_deg=alpha_deg, xc_rot=xc_rot, yc_rot=yc_rot, calib=calib"
   return
endif


nbol = n_elements( toi[*,0])
nsn  = n_elements( toi[0,*])

if not keyword_set(calib) then calib = dblarr(nbol)+1.0d0

; Init
nx         = n_elements(xmap[*,0])
ny         = n_elements(xmap[0,*])
map_list   = dblarr( nbol, nx, ny)
nhits_list = dblarr( nbol, nx, ny)

for ibol=0, nbol-1 do begin
   x0 = 0.0d0
   y0 = 0.0d0
   if keyword_set(xcenter) then x0 = xcenter[ibol]
   if keyword_set(ycenter) then y0 = ycenter[ibol]

   qd_map, x-x0, y-y0, calib[ibol]*toi[ibol,*], reso, xmap, ymap, map_raw, nhits, $
           w8=w8, alpha_deg=alpha_deg, xc_rot=xc_rot, yc_rot=yc_rot
   map_list[   ibol,*,*] = map_raw
   nhits_list[ ibol,*,*] = nhits
endfor


end
