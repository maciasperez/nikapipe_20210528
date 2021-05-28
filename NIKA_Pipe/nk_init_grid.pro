;+
;
; SOFTWARE: 
;        NIKA pipeline
;
; NAME: 
;        nk_init_grid
;
; CATEGORY: 
;        general, initialization
;
; CALLING SEQUENCE:
;         nk_init_grid, param, info, grid
; 
; PURPOSE: 
;        Create the map related information structure.
; 
; INPUT: 
;        - param
; 
; OUTPUT: 
;        - grid
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - June 14th, 2014, N. Ponthieu, June 18th, 2014, A. Ritacco
;-

pro nk_init_grid, param, info, grid, header=header, astr=astr, $
                  radius=radius, xcenter=xcenter, ycenter=ycenter

if n_params() lt 1 then begin
   message, /info, "Calling sequence: "
   print, "nk_init_grid, param, info, grid, header=header, astr=astr, $"
   print, "              radius=radius, xcenter=xcenter, ycenter=ycenter"
   return
endif

if keyword_set(header) then begin

   ;; coordinates of the ref pixel
   extast, header, astr

;;    ;; Generate the full astro coordinates corresponding to this
;;    ;; header to init arrays of the correct size
;;    create_coo2, header, xmap, ymap, /silent
;;    
;;    ;; coordinates of the center of the projection area (needed for NIKA's
;;    ;; projection to match data.dra and data.ddec)
;;    nx = n_elements(xmap[*,0])
;;    ny = n_elements(ymap[0,*])

   nx = sxpar( header, "NAXIS1")
   ny = sxpar( header, "NAXIS2")
;;   xc = double(nx)/2.d0         ; abscissa of the symetry axis if nx is even, center of the pix is nx is odd
;;   yc = double(ny)/2.d0
;;   xy2ad, xc, yc, astr, ra_center, dec_center
   
;;   param.map_reso = abs( sxpar(header, "CDELT1", /silent) * 3600.d0)
   param.map_reso = abs( astr.cd[0] * astr.cdelt[0] * 3600.d0)
;   print, "param.map_reso:", param.map_reso
;   stop

   ;; NP, Sept. 7th, 2017
   ;; ;; map_center_ra and map_center_dec must come from the info.longobj
   ;; ;; and latobj that are the actual center coordinates of the
   ;; ;; telescope, and not from the header on which we project that is arbitrary
   ;; param.map_center_ra  = ra_center
   ;; param.map_center_dec = dec_center

;; Now overwrite xmap and ymap by a regular set of coordinates
   ;; understood as offsets to the center
   if (nx mod 2) eq 0 then xmin = -nx/2*param.map_reso else xmin=(-nx/2-0.5)*param.map_reso
   if (ny mod 2) eq 0 then ymin = -ny/2*param.map_reso else ymin=(-ny/2-0.5)*param.map_reso
   xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap, xgrid, ygrid, xmax, ymax   

endif else begin
   nx = long( round(param.map_xsize/param.map_reso))    ;Number of pixels along ra
   ny = long( round(param.map_ysize/param.map_reso))    ;Number of pixels along dec
   nx = 2L*long(nx/2.0) + 1                             ;Ensure there's a pixel centered on (0,0)
   ny = 2L*long(ny/2.0) + 1
   xmin = (-nx/2-0.5)*param.map_reso
   ymin = (-ny/2-0.5)*param.map_reso
   xymaps, nx, ny, xmin, ymin, param.map_reso, xmap, ymap, xgrid, ygrid, xmax, ymax

   ;; Generate a the astrometry structure for (ra,dec) projections
   ;; Note that i've just forced nx and ny to be odd, so crval
   ;; are the coordinates of the ref pixel.
   crpix = double( [nx/2+1, ny/2+1])

   if strupcase(param.map_proj) eq "GALACTIC" then begin
      ctype = ['GLON-TAN', 'GLAT-TAN']
   endif else begin
      ctype = ["RA---TAN", "DEC--TAN"]
   endelse
   
   astr = create_struct("naxis", [nx, ny], $
                        "cd", double( [[1,0], [0,1]]), $
                        "cdelt", [-1.d0, 1.d0]*param.map_reso/3600.d0, $
                        "crpix", crpix, $
                        "crval", double([info.longobj, info.latobj]), $
                        "ctype", ctype, $
                        "longpole", 180.d0, $
                        "latpole", 90.d0, $
                        "pv2", dblarr(2))
   
endelse

grid = {nx:nx, ny:ny, xmin:xmin, ymin:ymin, xmax:xmax, ymax:ymax, $
        object:'', $
        integ_time:0.d0, $
        eta: dblarr(5), $
        map_reso:param.map_reso, $
        map_proj:param.map_proj, $
        xmap:xmap, ymap:ymap,$
;;        mask_source:xmap*0.d0+1.d0, $     ;; no source to be masked by default
        mask_source_1mm:xmap*0.d0+1.d0, $ ;; no source to be masked by default
        mask_source_2mm:xmap*0.d0+1.d0, $ ;; no source to be masked by default
        w8_source_1mm:xmap*0.d0+1.d0, $
        w8_source_2mm:xmap*0.d0+1.d0, $
        map_i_1mm:xmap*0.d0, $
        map_i_2mm:xmap*0.d0, $
        map_var_i_1mm:xmap*0.d0, $
        map_var_i_2mm:xmap*0.d0, $
        nhits_1mm:xmap*0.d0, $
        nhits_2mm:xmap*0.d0, $
        map_i1:xmap*0.d0, $
        map_i2:xmap*0.d0, $
        map_i3:xmap*0.d0, $
        map_var_i1:xmap*0.d0, $
        map_var_i2:xmap*0.d0, $
        map_var_i3:xmap*0.d0, $
        nhits_1:xmap*0.d0, $
        nhits_2:xmap*0.d0, $
        nhits_3:xmap*0.d0, $
;        nefd_i1:xmap*0.d0, $
;        nefd_i2:xmap*0.d0, $
;        nefd_i3:xmap*0.d0, $
;        nefd_i_1mm:xmap*0.d0, $
;        nefd_i_2mm:xmap*0.d0, $
        nvalid_kids1:0, $
        nvalid_kids2:0, $
        nvalid_kids3:0, $
        nvalid_kids_1mm:0, $
        nvalid_kids_2mm:0, $
        iter_mask_1mm:xmap*0.d0, $
        iter_mask_2mm:xmap*0.d0, $
        map_w8_i1:xmap*0.d0, $
        map_w8_i2:xmap*0.d0, $
        map_w8_i3:xmap*0.d0, $
        map_w8_I_1mm:xmap*0.d0, $
        map_w8_I_2mm:xmap*0.d0}
;;         covar_iq1:xmap*0.d0, $
;;         covar_iu1:xmap*0.d0, $
;;         covar_qu1:xmap*0.d0, $
;;         covar_iq2:xmap*0.d0, $
;;         covar_iu2:xmap*0.d0, $
;;         covar_qu2:xmap*0.d0, $
;;         covar_iq3:xmap*0.d0, $
;;         covar_iu3:xmap*0.d0, $
;;         covar_qu3:xmap*0.d0, $
;;         covar_iq_1mm:xmap*0.d0, $
;;         covar_iu_1mm:xmap*0.d0, $
;;         covar_qu_1mm:xmap*0.d0, $
;;         covar_iq_2mm:xmap*0.d0, $
;;         covar_iu_2mm:xmap*0.d0, $
;;         covar_qu_2mm:xmap*0.d0, $


;; Init a default mask around the source at the center here.
;; In case param.decor_method=common_mode or any other method ignoring the mask,
;; data.off_source is forced to 1 anyway.
nk_default_mask, param, info, grid, radius=radius, xcenter=xcenter, ycenter=ycenter

end
