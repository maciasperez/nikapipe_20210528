;+
;PURPOSE: Project TOI onto maps. The TOI are weighted before
;projection.
;
;INPUT: The parameter, data and kidpar structures.
;
;OUTPUT: A structure of maps containing the flux map, the variance map
;        and the integration time per pixel map.
;
;LAST EDITION: 
;   12/05/2013: update (adam@lpsc.in2p3.fr)
;   21/09/2013: possibility to use a header for the map (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_map, param, data, kidpar, maps, $
                   kidlist=kidlist, $ ;The list of kids to combine
                   map_per_KID=map_per_KID, $
                   map_per_scan_per_kid=map_per_scan_per_kid, $
                   one_mm_only=one_mm_only, $
                   two_mm_only=two_mm_only, $
                   xmap=xmap, $
                   ymap=ymap, $
                   azel=azel, $
                   nasmyth=nasmyth, $
                   astr=astr, $
                   undef_var2nan=undef_var2nan,$
                   bypass_error=bypass_error, $
                   beammap=beammap

  if not keyword_set(beammap) then beammap_pro = 1 else beammap_pro = 0

  if n_params() lt 1 then begin
     message, /info, "Calling sequence: "
     print, "nika_pipe_map, param, data, kidpar, maps, $"
     print, "               kidlist=kidlist, $"
     print, "               map_per_KID=map_per_KID, $"
     print, "               map_per_scan_per_kid=map_per_scan_per_kid, $"
     print, "               one_mm_only=one_mm_only, $"
     print, "               two_mm_only=two_mm_only, $"
     print, "               xmap=xmap, $"
     print, "               ymap=ymap, $"
     print, "               azel=azel, $"
     print, "               nasmyth=nasmyth, $"
     print, "               astr=astr, $"
     print, "               undef_var2nan=undef_var2nan,$"
     print, "               bypass_error=bypass_error"
     return
  endif

  N_pt  = n_elements(data)
  if keyword_set(kidlist) then N_kid = n_elements(kidlist) else N_kid = n_elements(kidpar)

  ;;-------------- Get the grid in the case of predefined header
  if keyword_set(astr) then begin
     reso_x = abs(astr.cdelt[0])*3600
     reso_y = abs(astr.cdelt[1])*3600
     nx = astr.naxis[0]
     ny = astr.naxis[1]
     xmin = (-nx/2-0.5)*reso_x
     ymin = (-ny/2-0.5)*reso_y
     
     ra_pointing = ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0
     dec_pointing = ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])
     
     ra_map = astr.crval[0] + reso_x*(astr.crpix[0] - ((nx-1)/2.0+1))/3600.0
     dec_map = astr.crval[1] - reso_y*(astr.crpix[1] - ((ny-1)/2.0+1))/3600.0
     
     c_arcsec_x = (ra_pointing-ra_map)*3600.0
     c_arcsec_y = (dec_map-dec_pointing)*3600.0

     ;; FXD: the above lines don't work in case of azel TO BE SOLVED soon
     if keyword_set( azel) then begin
        c_arcsec_x = 0.
        c_arcsec_y = 0.
     endif

  endif

  ;;-------------- Get the grid without header (real time for example?)
  if not keyword_set(astr) then begin
     reso_x = param.map.reso
     reso_y = param.map.reso
     nx = round(param.map.size_ra/param.map.reso) ;Number of pixels along ra
     ny = round(param.map.size_dec/param.map.reso) ;Number of pixels along dec
     nx = 2*long(nx/2.0) + 1                       ;Ensure there's a pixel centered on (0,0)
     ny = 2*long(ny/2.0) + 1
     xmin = (-nx/2-0.5)*param.map.reso
     ymin = (-ny/2-0.5)*param.map.reso
     xymaps, nx, ny, xmin, ymin, param.map.reso, xmap, ymap, xgrid, ygrid
     c_arcsec_x = 0.0
     c_arcsec_y = 0.0
  endif

  ;;-------------- Rotate c_arcsec if Az El map required
  if keyword_set(azel) then begin
     c_arcsec_az = cos(data.paral)*c_arcsec_x - sin(data.paral)*c_arcsec_y
     c_arcsec_el = sin(data.paral)*c_arcsec_x + cos(data.paral)*c_arcsec_y
     c_arcsec_x = c_arcsec_az
     c_arcsec_y = c_arcsec_el
  endif  

  ;;-------------- Define the maps used
  map_A     = dblarr(nx,ny)     ;flux map (Jy/Beam)
  map_B     = dblarr(nx,ny)     ;
  hit_A     = dblarr(nx,ny)     ;Number of hit per pixel
  hit_B     = dblarr(nx,ny)     ;
  map_w8_A  = dblarr(nx,ny)     ;Weight map
  map_w8_B  = dblarr(nx,ny)     ;
  map_var_A = dblarr(nx,ny) - 1 ;Variance (set to -1 if undefined) (Jy*Jy)
  map_var_B = dblarr(nx,ny) - 1 ;
  map_time_A = dblarr(nx,ny)    ;Time per pixel (seconde)
  map_time_B = dblarr(nx,ny)    ;

  ;; Depending on PAKO's projection keyword, data.ofs_az and data.ofs_el
  ;; may be already Ra and Dec
  if strupcase(param.projection.type) eq "PROJECTION" then begin
     mean_dec_pointing = ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])
     c_arcsec_x *= cos(mean_dec_pointing*!pi/180.0)
     
     ;;------------------
     ;; works on 20140220s302
     alpha = data.paral
     daz =  -cos(alpha)*data.ofs_az - sin(alpha)*data.ofs_el
     del =  -sin(alpha)*data.ofs_az + cos(alpha)*data.ofs_el
     ;;------------------

;   alpha = data.paral + 90*!dtor
;   daz =  cos(alpha)*data.ofs_az - sin(alpha)*data.ofs_el
;   del =  sin(alpha)*data.ofs_az + cos(alpha)*data.ofs_el


;   daz =  cos(alpha)*data.ofs_el - sin(alpha)*data.ofs_az
;   del =  sin(alpha)*data.ofs_el + cos(alpha)*data.ofs_az
     
     
     data.ofs_az =  daz
     data.ofs_el =  del

;   data.ofs_az =  data.ofs_x/!arcsec2rad
;   data.ofs_el =  data.ofs_y/!arcsec2rad

  endif

;; ;;;;*****************************
;; ;;;;*****************************
;; ;data.paral =  0.d0
;; w =  where( kidpar.array eq 1 and kidpar.type eq 1, nw)
;; if nw ne 0 then ikid1 = w[0]
;; w =  where( kidpar.array eq 2 and kidpar.type eq 1, nw)
;; if nw ne 0 then ikid2 = w[0]
;; kidpar.type =  5
;; kidpar[ikid1].type = 1
;; kidpar[ikid2].type = 1
;; ;;;;;;*****************************
;; ;;;;;;*****************************
;; ;;;stop

;;message, /info, '----- Pointing shift for projection are '+strtrim(c_arcsec_x,2)+' and '+strtrim(c_arcsec_y,2)+' arcsec'

;;-------------- Projection per detector
  for i=0, N_kid-1 do begin
     if keyword_set(kidlist) then ikid = kidlist[i] else ikid = i ;Project only TOI of detectors that we want
     if kidpar[ikid].type eq 1 then begin

        ;;------- Compute the R.A.-Dec. (or Az.-El.) TOI
        if keyword_set(azel) then begin
           nika_nasmyth2azel, kidpar[ikid].nas_x * beammap_pro, $
                              kidpar[ikid].nas_y * beammap_pro, $
                              0.0, 0.0, data.el*!radeg, dra, ddec, $
                              nas_x_ref=kidpar[ikid].nas_center_X, $
                              nas_y_ref=kidpar[ikid].nas_center_Y
           dra  = dra  - data.ofs_az
           ddec = ddec - data.ofs_el

        endif else begin

           if keyword_set(nasmyth) then begin
              ;; alpha = !dpi/2.d0 - data.el
              ;; ofs_x  = cos(-alpha)*data.ofs_az - sin(-alpha)*data.ofs_el
              ;; ofs_y  = sin(-alpha)*data.ofs_az + cos(-alpha)*data.ofs_el
              azel2nasm, data.el, data.ofs_az, data.ofs_el, ofs_x, ofs_y
              dra  = ofs_x - kidpar[ikid].nas_x * beammap_pro
              ddec = ofs_y - kidpar[ikid].nas_y * beammap_pro
           endif else begin     ; then do radec
              nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                                    kidpar[ikid].nas_x * beammap_pro, $
                                    kidpar[ikid].nas_y * beammap_pro, $
                                    0., 0., dra, ddec, $
                                    nas_x_ref=kidpar[ikid].nas_center_X, $
                                    nas_y_ref=kidpar[ikid].nas_center_Y
           endelse
        endelse
        
        ;;------- Shift TOI according to projection
        dra  = dra  - c_arcsec_x
        ddec = ddec - c_arcsec_y
        
        ;;------- Order the pixels
        ix   = long( (dra  - xmin)/reso_x) ;Coord of the pixel along x
        iy   = long( (ddec - ymin)/reso_y) ;Coord of the pixel along y
        ipix = ix + iy*nx                  ;Number of the pixel
        
        ;;------- Project the data
        for isn=0l, N_pt-1 do begin
           p = ipix[isn]
           
                                ; if ikid eq 9 then stop
           
           if (ix[isn] ge 0) and (ix[isn] le (nx-1)) and $
              (iy[isn] ge 0) and (iy[isn] le (ny-1)) and $
              (data[isn].w8[ikid] ne 0) and (data[isn].flag[ikid] eq 0) then begin
              
              if kidpar[ikid].array eq 1 and (not keyword_set(two_mm_only)) then begin
                 map_A[   p] += data[isn].w8[ikid]*data[isn].RF_dIdQ[ikid]
                 map_w8_A[p] += data[isn].w8[ikid]
                 hit_A[   p] += double( data[isn].w8[ikid] ne 0)
              endif 
              if kidpar[ikid].array eq 2 and (not keyword_set(one_mm_only)) then begin
                 map_B[   p] += data[isn].w8[ikid]*data[isn].RF_dIdQ[ikid]
                 map_w8_B[p] += data[isn].w8[ikid]
                 hit_B[   p] += double( data[isn].w8[ikid] ne 0)
              endif
           endif
        endfor
     endif
  endfor

;;-------------- Moyenne sur le nombre de coups
  pos_A     = where(hit_A ge 1, nwpos_A)
  pos_B     = where(hit_B ge 1, nwpos_B)
  pos_var_A = where(hit_A ge 2, nwpos_var_A)
  pos_var_B = where(hit_B ge 2, nwpos_var_B)

  if nwpos_var_A ne 0 then map_var_A[pos_var_A] = 1.0/map_w8_A[pos_var_A]
  if nwpos_var_B ne 0 then map_var_B[pos_var_B] = 1.0/map_w8_B[pos_var_B]

  if not keyword_set(bypass_error) then if not keyword_set(two_mm_only) and nwpos_var_A eq 0 then begin
     message, "No pixel with more than 2 hits at 240GHz/1mm ?!", /info
     currentscan = param.iscan
     param.flag.scan[currentscan]=1
  endif

  if not keyword_set(bypass_error) then if not keyword_set(one_mm_only) and nwpos_var_B eq 0 then begin
     message, "No pixel with more than 2 hits at 140GHz/2mm ?!", /info
     currentscan = param.iscan
     param.flag.scan[currentscan]=1
  endif 

  if nwpos_A ne 0 then map_A[pos_A] /= map_w8_A[pos_A]
  if nwpos_B ne 0 then map_B[pos_B] /= map_w8_B[pos_B]

  if not keyword_set(bypass_error) then if not keyword_set(two_mm_only) and nwpos_A eq 0 then begin
     message, "No pixel was hit at 240GHz ?!", /info
     currentscan = param.iscan
     param.flag.scan[currentscan]=1
  endif 
  if not keyword_set(bypass_error) then if not keyword_set(one_mm_only) and nwpos_B eq 0 then begin
     message, "No pixel was hit at 140 GHz?!", /info
     currentscan = param.iscan
     param.flag.scan[currentscan]=1
  endif 

  map_time_A = hit_A /!nika.f_sampling ; in sec
  map_time_B = hit_B /!nika.f_sampling ; in sec

  if keyword_set(undef_var2nan) then begin
     loc_undef_A = where(map_var_a le 0, nloc_undef_A)
     loc_undef_B = where(map_var_b le 0, nloc_undef_B)
     if nloc_undef_A ne 0 then map_var_a[loc_undef_A] = !values.f_nan
     if nloc_undef_B ne 0 then map_var_b[loc_undef_B] = !values.f_nan
  endif

;;-------------- Returned structure of maps
  maps = {A:{Jy:map_A, var:map_var_A, time:map_time_A, noise_map:map_time_A*0},$
          B:{Jy:map_B, var:map_var_B, time:map_time_B, noise_map:map_time_B*0}}


;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;%%%%%%%%%%%%%%%%%%%%%%%%%%% CASE WE NEED ONE MAP PER KIDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if keyword_set(map_per_scan_per_kid) or keyword_set(map_per_kid) then begin
     ;;------- check if you are using the same set of detectors all
     ;;        the time
     check_kidpar1mm = where(param.kid_file.a eq param.kid_file.a[0], ncheck_kidpar1mm)
     check_kidpar2mm = where(param.kid_file.b eq param.kid_file.b[0], ncheck_kidpar2mm)
     if not keyword_set(bypass_error) then if ncheck_kidpar1mm ne n_elements(param.kid_file.a) then message, $
        'You cannot make a map per detector since you are combining different kidpars'
     if not keyword_set(bypass_error) then if ncheck_kidpar2mm ne n_elements(param.kid_file.b) then message, $
        'You cannot make a map per detector since you are combining different kidpars'

     message,/info, 'You asked for a map per detector, if it is to heavy you can reduce the resolution'
     n_scan = n_elements(param.scan_list)
     w_on = where(kidpar.type eq 1, n_on)

     ;;---------- Define the map per scan per kid for the first time
     if param.iscan eq 0 then begin
        map_per_scan_per_kid = {Jy:dblarr(nx, ny), var:dblarr(nx, ny), $
                                time:dblarr(nx, ny)} ;, noise_map:dblarr(nx, ny)}
        map_per_scan_per_kid = replicate(map_per_scan_per_kid, n_scan, n_on)
     endif

     ;;-------------- Projection per detector
     for i=0, n_on-1 do begin
        if keyword_set(kidlist) then ikid = kidlist[w_on[i]] else ikid = i ;Project only TOI of detectors that we want
        ;;------- Compute the R.A.-Dec. (or Az.-El.) TOI 
        if keyword_set(azel) then begin
           nika_nasmyth2azel, kidpar[w_on[ikid]].nas_x * beammap_pro, $
                              kidpar[w_on[ikid]].nas_y * beammap_pro, $
                              0.0, 0.0, data.el*!radeg, dra, ddec, $
                              nas_x_ref=kidpar[w_on[ikid]].nas_center_X, $
                              nas_y_ref=kidpar[w_on[ikid]].nas_center_Y
           dra = dra - data.ofs_az
           ddec = ddec - data.ofs_el
        endif else begin

           if keyword_set(nasmyth) then begin
              alpha = !dpi/2.d0 - data.el
              ofs_x  = cos(-alpha)*data.ofs_az - sin(-alpha)*data.ofs_el
              ofs_y  = sin(-alpha)*data.ofs_az + cos(-alpha)*data.ofs_el
              
              dra  = ofs_x - kidpar[w_on[ikid]].nas_x * beammap_pro
              ddec = ofs_y - kidpar[w_on[ikid]].nas_y * beammap_pro
           endif else begin     ; then do radec     
              
              nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                                    kidpar[w_on[ikid]].nas_x * beammap_pro, $
                                    kidpar[w_on[ikid]].nas_y * beammap_pro, $
                                    0., 0., dra, ddec, $
                                    nas_x_ref=kidpar[w_on[ikid]].nas_center_X, $
                                    nas_y_ref=kidpar[w_on[ikid]].nas_center_Y
           endelse
        endelse
        
        ;;------- Shift TOI according to projection
        dra = dra - c_arcsec_x
        ddec = ddec - c_arcsec_y
        
        ;;------- Order the pixels
        ix   = long( (dra  - xmin)/reso_x) ;Coord of the pixel along x
        iy   = long( (ddec - ymin)/reso_y) ;Coord of the pixel along y
        ipix = ix + iy*nx                  ;Number of the pixel
        
        for isn=0l, N_pt-1 do begin
           p = ipix[isn]
           if (ix[isn] ge 0) and (ix[isn] le (nx-1)) and (iy[isn] ge 0) and (iy[isn] le (ny-1)) and $
              (data[isn].w8[w_on[ikid]] ne 0) then begin
              map_per_scan_per_kid[param.iscan,ikid].Jy[p] += data[isn].w8[w_on[ikid]]*data[isn].RF_dIdQ[w_on[ikid]]
              map_per_scan_per_kid[param.iscan,ikid].var[p] += data[isn].w8[w_on[ikid]] ;Var is w8 for now
              map_per_scan_per_kid[param.iscan,ikid].time[p] += 1                       ;Time is hit for now
           endif
        endfor
        ;;-------------- Normalizing and converting to real var and real var
        pos_gt1 = where(map_per_scan_per_kid[param.iscan, ikid].time ge 1, nwpos_gt1, COMP=pos_lt1,NCOMP=npos_lt1)
        pos_gt2 = where(map_per_scan_per_kid[param.iscan, ikid].time ge 2, nwpos_gt2, COMP=pos_lt2, NCOMP=npos_lt2) 
        
        if nwpos_gt1 ne 0 then $ ;Normalize by w8 (var = w8 here)
           map_per_scan_per_kid[param.iscan,ikid].Jy[pos_gt1] /= map_per_scan_per_kid[param.iscan,ikid].var[pos_gt1]  
        if nwpos_gt2 ne 0 then $ ;Change w8 to var
           map_per_scan_per_kid[param.iscan,ikid].var[pos_gt2] = 1.0/map_per_scan_per_kid[param.iscan,ikid].var[pos_gt2]
        if npos_lt2 ne 0 then begin ;Change w8 to var
           if keyword_set(undef_var2nan) then map_per_scan_per_kid[param.iscan,ikid].var[pos_lt2] = !values.f_nan else $
              map_per_scan_per_kid[param.iscan,ikid].var[pos_lt2] = -1
        endif
        map_per_scan_per_kid[param.iscan, ikid].time /= !nika.f_sampling ; in sec
     endfor

     ;;---------- Combine the maps per scan at the end
     if param.iscan eq n_scan-1 then begin
        if keyword_set(map_per_kid) then begin
           mpk = {Jy:dblarr(nx, ny), var:dblarr(nx, ny), time:dblarr(nx, ny), noise_map:dblarr(nx, ny)}
           mpk = replicate(mpk, n_on)

           for i=0, n_on-1 do begin
              if keyword_set(kidlist) then ikid = kidlist[w_on[i]] else ikid = i ;Project only TOI requested
              mpk_norm = dblarr(nx, ny)
              for iscan=0, n_scan-1 do begin
                 mpk_w8 = 1.0/map_per_scan_per_kid[iscan,ikid].var
                 bad_loc = where(map_per_scan_per_kid[iscan,ikid].var eq -1 or $
                                 finite(map_per_scan_per_kid[iscan,ikid].var) ne 1, nbad_loc)
                 if nbad_loc ne 0 then mpk_w8[bad_loc] = 0.0
                 mpk[ikid].Jy += mpk_w8 * map_per_scan_per_kid[iscan,ikid].Jy
                 mpk_norm = mpk_norm + mpk_w8

                 mpk[ikid].time += map_per_scan_per_kid[iscan,ikid].time ;Sum the time per pixel
              endfor
              mpk[ikid].Jy /= mpk_norm                              ;Normalizing the maps
              loc_normal = where(mpk_norm eq 0, nloc_normal)        ;where no hit
              if nloc_normal ne 0 then mpk[ikid].Jy[loc_normal] = 0.0 ;no infinity
              mpk[ikid].var = 1.0/mpk_norm
              if nloc_normal ne 0 then mpk[ikid].var[loc_normal] = -1 ;Set undef var to -1
              if keyword_set(undef_var2nan) and nloc_normal ne 0 then mpk[ikid].var[loc_normal] = !values.f_nan 
           endfor
           
           map_per_kid = mpk    ;The final variable is map_per_kid summed over all scans
        endif
     endif

  endif

end
