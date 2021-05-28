;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_map2toi_2
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

pro nk_map2toi_2, param, info, map, data, toi, map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_map2toi_2map, data, toi, map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u"
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

;; Init to NaN samples that fall outside the input map
ipix = data.ipix
toi  = data.toi*0.d0 + !values.d_nan

w = where( finite( ipix), nw)
if nw eq 0 then begin
   nk_error, info, "No coordinates fall inside the input map"
   return
endif else begin
   ;; Output toi
   toi[w] = map[ipix[w]]
endelse

;; Polar
if keyword_set(map_q)*keyword_set(map_u) eq 1 and nw ne 0 then begin
   toi_q = data.toi*0.d0 + !values.d_nan
   toi_u = data.toi*0.d0 + !values.d_nan
   toi_q[w] = map_q[ ipix[w]]
   toi_u[w] = map_u[ ipix[w]]
endif

if param.cpu_time then nk_show_cpu_time, param, "nk_map2toi_2"

end
