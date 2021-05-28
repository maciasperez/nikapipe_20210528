;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_init_map_struct
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_init_map_struct, param, info, map_struct
; 
; PURPOSE: 
;        Create the map related information structure.
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - map_struct
; 
; KEYWORDS: polar
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014, N. Ponthieu, June 18th, 2014, A. Ritacco
;-

pro nk_init_map_struct, param, map_struct, polar=polar

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_init_map_struct, param, info, map_struct"
   return
endif

;; works only with naive projection until we've coded nk_make_header
nx = round(param.map_xsize/param.map_reso) ;Number of pixels along ra
ny = round(param.map_ysize/param.map_reso) ;Number of pixels along dec
nx = 2*long(nx/2.0) + 1                    ;Ensure there's a pixel centered on (0,0)
ny = 2*long(ny/2.0) + 1
xmin = (-nx/2-0.5)*param.map_reso
ymin = (-ny/2-0.5)*param.map_reso
xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap

map_struct = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, $
              map_reso:param.map_reso, $
              xmap:xmap, ymap:ymap,$
              mask_source:xmap*0.d0+1.d0, $ ;; no source to be masked by default
              map_i_1mm:xmap*0.d0, $
              nhits_1mm:xmap*0.d0, map_w8_1mm:xmap*0.d0, $
              map_i_2mm:xmap*0.d0, $
              nhits_2mm:xmap*0.d0, map_w8_2mm:xmap*0.d0}

end
