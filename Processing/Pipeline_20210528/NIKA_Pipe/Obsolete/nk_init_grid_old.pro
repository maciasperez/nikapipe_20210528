
pro nk_init_grid_old, param, info, grid, header=header, $
                  radius=radius, xcenter=xcenter, ycenter=ycenter

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_init_grid, param, info, grid"
   return
endif


if keyword_set(header) then begin
   
;;    param.map_center_ra  = sxpar(header, "CRVAL1", /silent)
;;    param.map_center_dec = sxpar(header, "CRVAL2", /silent)

;;    crval1 = sxpar(header, "CRVAL1", /silent)
;;    crval2 = sxpar(header, "CRVAL2", /silent)
;;    crpix1 = sxpar(header, "CRPIX1", /silent)w
;;    crpix2 = sxpar(header, "CRPIX2", /silent)w
;;    param.map_center_ra

   ;; Generate astro coordinates
   create_coo2, header, xmap, ymap, /silent
   nx = n_elements(xmap[*,0])
   ny = n_elements(xmap[0,*])
   ;; Reso converted from degrees to arcsec to match data.dra and data.ddec
   param.map_reso = abs( sxpar(header, "CDELT1", /silent) * 3600.d0)
   ;; xmap and ymap must be in arcsec offsets to the center for
   ;; nk_map_photometry

   param.map_center_ra  = avg( xmap[*,0])
   param.map_center_dec = avg( ymap[0,*])
;;    print, "param.map_center_ra: ", param.map_center_ra
;;    print, "param.map_center_dec: ", param.map_center_dec
;;    print, sxpar(header, "CRVAL1", /silent) 
;;    print, sxpar(header, "CRVAL2", /silent)
;;    stop

   xmap = (xmap - param.map_center_ra) *3600.d0*cos(param.map_center_dec*!dtor)
   ymap = (ymap - param.map_center_dec)*3600.d0
   xcenter = avg( xmap[*,0])
   ycenter = avg( ymap[0,*])
   xmin = min(xmap) - param.map_reso/2.d0
   ymin = min(ymap) - param.map_reso/2.d0
   xmax = max(xmap) + param.map_reso/2.d0
   ymax = max(ymap) + param.map_reso/2.d0
endif else begin
;; works only with naive projection until we've coded nk_make_header
   nx = long( round(param.map_xsize/param.map_reso))    ;Number of pixels along ra
   ny = long( round(param.map_ysize/param.map_reso))    ;Number of pixels along dec
   nx = 2L*long(nx/2.0) + 1                             ;Ensure there's a pixel centered on (0,0)
   ny = 2L*long(ny/2.0) + 1
   xmin = (-nx/2-0.5)*param.map_reso
   ymin = (-ny/2-0.5)*param.map_reso
   xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap, xgrid, ygrid, xmax, ymax
endelse

grid = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, xmax:xmax, ymax:ymax, $
        map_reso:param.map_reso, $
        map_proj:param.map_proj, $
        xmap:xmap, ymap:ymap,$
        mask_source:xmap*0.d0+1.d0, $ ;; no source to be masked by default
        map_i_1mm:xmap*0.d0, $
        map_i_2mm:xmap*0.d0, $
        map_var_i_1mm:xmap*0.d0, $
        map_var_i_2mm:xmap*0.d0, $
        nhits_1mm:xmap*0.d0, $
        nhits_2mm:xmap*0.d0, $
        map_w8_I_1mm:xmap*0.d0, $
        map_w8_I_2mm:xmap*0.d0, $
        map_i1:xmap*0.d0, $
        map_i2:xmap*0.d0, $
        map_i3:xmap*0.d0, $
        map_var_i1:xmap*0.d0, $
        map_var_i2:xmap*0.d0, $
        map_var_i3:xmap*0.d0, $
        map_w8_i1:xmap*0.d0, $
        map_w8_i2:xmap*0.d0, $
        map_w8_i3:xmap*0.d0, $
        nhits_1:xmap*0.d0, $
        nhits_2:xmap*0.d0, $
        nhits_3:xmap*0.d0, $
        nefd_i1:xmap*0.d0, $
        nefd_i2:xmap*0.d0, $
        nefd_i3:xmap*0.d0, $
        nefd_i_1mm:xmap*0.d0, $
        nefd_i_2mm:xmap*0.d0, $
        covar_iq1:xmap*0.d0, $
        covar_iu1:xmap*0.d0, $
        covar_qu1:xmap*0.d0, $
        covar_iq2:xmap*0.d0, $
        covar_iu2:xmap*0.d0, $
        covar_qu2:xmap*0.d0, $
        covar_iq3:xmap*0.d0, $
        covar_iu3:xmap*0.d0, $
        covar_qu3:xmap*0.d0, $
        covar_iq_1mm:xmap*0.d0, $
        covar_iu_1mm:xmap*0.d0, $
        covar_qu_1mm:xmap*0.d0, $
        covar_iq_2mm:xmap*0.d0, $
        covar_iu_2mm:xmap*0.d0, $
        covar_qu_2mm:xmap*0.d0}


;; Init a default mask around the source at the center here.
;; In case param.decor_method=common_mode or any other method ignoring the mask,
;; data.off_source is forced to 1 anyway.
nk_default_mask, param, info, grid, radius=radius, xcenter=xcenter, ycenter=ycenter

end
