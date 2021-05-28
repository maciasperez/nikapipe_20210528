;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_map2toi_3
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
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


pro nk_map2toi_3, param, info, map, ipix, toi, $
                  map_q=map_q, map_u=map_u, toi_q=toi_q, toi_u=toi_u, $
                  toi_init_val=toi_init_val
;-
if n_params() lt 1 then begin
   dl_unix, 'nk_map2toi_3'
   return
endif

if param.cpu_time then param.cpu_t0 = systime( 0, /sec)

if not keyword_set(toi_init_val) then toi_init_val = !values.d_nan

;; Init to NaN samples that fall outside the input map
toi  = double(finite(ipix))*0.d0 + toi_init_val

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
   toi_q = double(finite(ipix))*0.d0 + toi_init_val
   toi_u = double(finite(ipix))*0.d0 + toi_init_val
   toi_q[w] = map_q[ ipix[w]]
   toi_u[w] = map_u[ ipix[w]]
endif

if param.cpu_time then nk_show_cpu_time, param

end
