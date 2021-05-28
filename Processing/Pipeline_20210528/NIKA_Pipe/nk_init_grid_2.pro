;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_init_grid_2
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_init_grid_2, param, info, grid, astr=astr
; 
; PURPOSE: 
;        Create the map related information structure and astr if present
; 
; INPUT: 
;        - param, info, [astr]
; 
; OUTPUT: 
;        - grid, param is modified according to the astr constraints
;          if it is passed as keyword and if param.map_proj eq radec
;          or galactic.
;
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 14th, 2019: NP

pro nk_init_grid_2, param, info, grid, astr=astr
;-

if n_params() lt 1 then begin
   dl_unix, 'nk_init_grid_2'
   return
endif

if not keyword_set(astr) then begin
   nk_param_info2astr, param, info, astr
endif

if strupcase(param.map_proj) eq "RADEC" or $
   strupcase(param.map_proj) eq "GALACTIC" then begin
   
;;    if not keyword_set(astr) then begin
;;       nk_param_info2astr, param, info, astr
;;    endif

   nx = astr.naxis[0]
   ny = astr.naxis[1]
   param.map_reso = abs( astr.cd[0] * astr.cdelt[0] * 3600.d0)

   if (nx mod 2) eq 0 then xmin = -nx/2*param.map_reso else xmin=(-nx/2-0.5)*param.map_reso
   if (ny mod 2) eq 0 then ymin = -ny/2*param.map_reso else ymin=(-ny/2-0.5)*param.map_reso

;    ad2xy, astr.crval[0], astr.crval[1], astr, xcenter, ycenter
;    xmin = (-xcenter - 0.5d0)*param.map_reso ; left edge of the lower left pixel
;    ymin = (-ycenter - 0.5d0)*param.map_reso ; bottom edge of the lowest pixels

   xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap, xgrid, ygrid, xmax, ymax   

endif else begin
   ;; azel or nasmyth
   nx = long( round(param.map_xsize/param.map_reso))    ;Number of pixels along ra
   ny = long( round(param.map_ysize/param.map_reso))    ;Number of pixels along dec
   nx = 2L*long(nx/2.0) + 1                             ;Ensure there's a pixel centered on (0,0)
   ny = 2L*long(ny/2.0) + 1
   xmin = (-nx/2-0.5)*param.map_reso
   ymin = (-ny/2-0.5)*param.map_reso
   xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap, xgrid, ygrid, xmax, ymax

   ;; correct the default sign of astr.cdelt
   astr.cdelt = param.map_reso/3600.d0
endelse

str_exec = "grid = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, xmax:xmax, ymax:ymax, "+$
           "naxis:astr.naxis, cd:astr.cd, cdelt:astr.cdelt, crpix:astr.crpix, "+$
           "crval:astr.crval, ctype:astr.ctype, longpole:astr.longpole, "+$
           "latpole:astr.latpole, pv2:astr.pv2, object:'', "+$
           "integ_time:0.d0, eta: dblarr(5), map_reso:param.map_reso, "+$
           "map_proj:param.map_proj, xmap:xmap, ymap:ymap, "

map_field_list = ['mask_source_1mm', 'mask_source_2mm', 'w8_source_1mm', 'w8_source_2mm', $
                  'map_i_1mm', 'map_i_2mm', 'map_var_i_1mm', 'map_var_i_2mm', 'nhits_1mm', $
                  'nhits_2mm', 'map_i1', 'map_i2', 'map_i3', 'map_var_i1', 'map_var_i2', $
                  'map_var_i3', 'nhits_1', 'nhits_2', 'nhits_3', 'nvalid_kids1', 'nvalid_kids2', $
                  'nvalid_kids3', 'nvalid_kids_1mm', 'nvalid_kids_2mm', 'iter_mask_1mm', 'iter_mask_2mm', $
                  'map_w8_i1', 'map_w8_i2', 'map_w8_i3', 'map_w8_I_1mm', 'map_w8_I_2mm', 'zero_level_mask', $
                  'zero_level_mask_1mm', 'zero_level_mask_2mm', $
                  'snr_mask_1mm', 'snr_mask_2mm', 'snr_w8_1mm', 'snr_w8_2mm']

if info.polar ne 0 then begin
   map_field_list = [map_field_list, $
                     "map_q_1mm", "map_u_1mm", "map_q_2mm", "map_u_2mm", "map_w8_q_1mm", "map_w8_u_1mm", "map_w8_q_2mm", $
                     "map_w8_u_2mm", "map_var_q_1mm", "map_var_u_1mm", "map_var_q_2mm", "map_var_u_2mm", "map_q1", $
                     "map_u1", "map_q2", "map_u2", "map_q3", "map_u3", "map_w8_q1", "map_w8_u1", "map_w8_q2", "map_w8_u2", $
                     "map_w8_q3", "map_w8_u3", "map_var_q1", "map_var_u1", "map_var_q2", "map_var_u2", "map_var_q3", "map_var_u3", $
                     "iq_lkg_1", "iu_lkg_1", "iq_lkg_2", "iu_lkg_2", "iq_lkg_3", "iu_lkg_3", "polar_mask"]
endif

nfields = n_elements(map_field_list)
for i=0, nfields-2 do str_exec += map_field_list[i]+":xmap*0.d0, "
str_exec += map_field_list[nfields-1]+":xmap*0.d0}"
junk = execute( str_exec)

;; Init a default mask around the source at the center here.
;; In case param.decor_method=common_mode or any other method ignoring the mask,
;; data.off_source is forced to 1 anyway.
nk_default_mask, param, info, grid, xcenter=xcenter, ycenter=ycenter

;; Init a default mask where to compute the zero level (depending on
;; which decorrelation method is used)
grid.zero_level_mask = 1.d0     ; default, compute the zero level on the entire map
grid.zero_level_mask_1mm = 1.d0 ; default, compute the zero level on the entire map
grid.zero_level_mask_2mm = 1.d0 ; default, compute the zero level on the entire map
;; exclude a disk around the center (where the source is most often)
w = where( sqrt( grid.xmap^2+grid.ymap^2) lt param.radius_zero_level_mask, nw)
if nw ne 0 then grid.zero_level_mask[w] = 0.d0


end
