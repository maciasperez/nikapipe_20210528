
;; Coordinates (x,y) are meant as offsets w.r.t. the source that is followed by
;; the telescope

pro get_bolo_maps_6, toi, ipix, w8, kidpar, map_struct, map_list, nhits

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

nkids = n_elements( toi[*,0])
nsn   = n_elements( toi[0,*])

; Init
map_list = dblarr( nkids, map_struct.nx, map_struct.ny)
npix     = long(map_struct.nx)*long(map_struct.ny)
at       = fltarr(nsn, npix)
atam1    = fltarr(npix)

w = where( finite(ipix) eq 1, nw)
if nw eq 0 then begin
   message, /info, "Only infinite pixel values"
   stop
endif

junk  = fltarr(nkids,npix)
atam1 = fltarr(npix)
for i=0L, nsn-1 do begin
   p = ipix[i]
   if finite(p) eq 1 then begin
      junk[*,p]   += toi[*,i]
      atam1[   p] += 1.
   endif
endfor
nhits    = reform( atam1, map_struct.nx, map_struct.ny)
w        = where( atam1 ne 0, nw)
atam1[w] = 1.d0/atam1[w]

for i=0, nkids-1 do junk[i,*] *= atam1
map_list = reform( junk, nkids, map_struct.nx, map_struct.ny)

end
