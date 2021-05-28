;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_init_info
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_init_info, param, info
; 
; PURPOSE: 
;        Create the information structure.
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - info
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

pro nk_init_info, param, info, polar=polar


nk_default_info, info

;; works only with naive projection until we've coded nk_make_header
;; Init the grid
nx = round(param.map_xsize/param.map_reso)         ;Number of pixels along ra
ny = round(param.map_ysize/param.map_reso) ;Number of pixels along dec
nx = 2*long(nx/2.0) + 1         ;Ensure there's a pixel centered on (0,0)
ny = 2*long(ny/2.0) + 1
xmin = (-nx/2-0.5)*param.map_reso
ymin = (-ny/2-0.5)*param.map_reso
xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap

if keyword_set(polar) then begin
   new_struct = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, $
                 xmap:xmap, ymap:ymap,$
                 mask_source:xmap*0.d0+1.d0, $ ;; no source to be masked by default
                 coadd_1mm:xmap*0.d0, coadd_q_1mm:xmap*0.d0, coadd_u_1mm:xmap*0.d0,$
                 nhits_1mm:xmap*0.d0, map_w8_1mm:xmap*0.d0, map_var_1mm:xmap*0.d0, $
                 coadd_2mm:xmap*0.d0, coadd_q_2mm:xmap*0.d0, coadd_u_2mm:xmap*0d0, $
                 nhits_2mm:xmap*0.d0, map_w8_2mm:xmap*0.d0, map_var_2mm:xmap*0.d0}

endif else begin

   new_struct = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, $
                 xmap:xmap, ymap:ymap, $
                 mask_source: xmap*0.d0 + 1.d0, $ ;; no source to be masked by default
                 coadd_1mm:xmap*0.d0, nhits_1mm:xmap*0.d0, map_w8_1mm:xmap*0.d0, map_var_1mm:xmap*0.d0, $
                 coadd_2mm:xmap*0.d0, nhits_2mm:xmap*0.d0, map_w8_2mm:xmap*0.d0, map_var_2mm:xmap*0.d0, $
                 map_1mm:xmap*0.d0, map_2mm:xmap*0.d0}
endelse

junk = info
upgrade_struct, junk, new_struct, info

end
