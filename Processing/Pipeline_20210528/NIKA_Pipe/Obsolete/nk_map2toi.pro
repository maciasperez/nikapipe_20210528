;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_map2toi
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         nk_map2toi, map, xmap, ymap, x, y, toi, status, error_message, $
;                     nx=nx, ny=ny, reso=reso, xmin=xmin, ymin=ymin
; 
; PURPOSE: 
;        Produces kid timelines from an input map and kid pointing.
; 
; INPUT: 
;        - map: then input sky map
;        - xmap: coordinates in the x direction
;        - ymap: coordinates in the y direction
;        - x:    pointing toi in x coordinates
;        - y:    pointing toi in y coordinates
; 
; OUTPUT: 
;        - toi
; 
; KEYWORDS:
;        - nx: number of pixels in the x direction
;        - ny: number of pixels in the y direction
;        - reso: map resolution
;        - xmin: x coordinate of the lower left pixel corner
;        - ymin: y coordinate of the lower left pixel corner
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Apr 24th, 2014: creation (Nicolas Ponthieu & Remi Adam - adam@lpsc.in2p3.fr)
;-

pro nk_map2toi, map, xmap, ymap, x, y, toi, status, error_message, $
                nx=nx, ny=ny, reso=reso, xmin=xmin, ymin=ymin, $
                map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map2toi, map, xmap, ymap, x, y, toi, status, error_message, $"
   print, "            nx=nx, ny=ny, reso=reso, xmin=xmin, ymin=ymin"
   return
endif

status = -1
error_message = "no error"

if not keyword_set(nx)   then nx   = n_elements(xmap[*,0])
if not keyword_set(ny)   then ny   = n_elements(ymap[0,*])
if not keyword_set(reso) then reso = xmap[1] - xmap[0]
if not keyword_set(xmin) then xmin = min(xmap) - reso/2.d0
if not keyword_set(ymin) then ymin = min(ymap) - reso/2.d0

ix   = long( (x - xmin)/reso)   ; Coord of the pixel along x
iy   = long( (y - ymin)/reso)   ; Coord of the pixel along y
ipix = ix + iy*nx               ; Number of the pixel
            
w = where( (ix ge 0) and (ix le (nx-1)) and $
           (iy ge 0) and (iy le (ny-1)), nw)

;; Init to NaN samples that fall outside the input map
toi = dblarr( n_elements(ipix)) + !values.d_nan
if nw eq 0 then begin
   nk_error, info, "No coordinates fall inside the input map"
   return
endif else begin
   ;; Output toi
   toi[w] = map[ipix[w]]
endelse

;; Polar
if keyword_set(map_q)*keyword_set(map_u)*keyword_set(toi_q)*keyword_set(toi_u) eq 1 and nw ne 0 then begin
   toi_q = dblarr( n_elements(ipix)) + !values.d_nan
   toi_u = dblarr( n_elements(ipix)) + !values.d_nan
   toi_q[w] = map_q[ipix[w]]
   toi_u[w] = map_u[ipix[w]]
endif

end
