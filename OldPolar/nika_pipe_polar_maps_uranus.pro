
pro nika_pipe_polar_maps_uranus, param, data, kidpar, $
                                 maps_S0, maps_S1, maps_S2, $
                                 maps_covar, nhits, $
                                 xmap=xmap, ymap=ymap, azel=azel, nasmyth=nasmyth
  

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nika_pipe_polar_maps, param, data, kidpar, $"
   print, "                      maps_S0, maps_S1, maps_S2, $"
   print, "                      maps_covar, nhits, $"
   print, "                      xmap=xmap, ymap=ymap, azel=azel, nasmyth=nasmyth"
   return
endif

if keyword_set(nasmyth) and keyword_set(azel) then $
   message, "you must choose either /azel or /nasmyth, not both"

radec = 1 ; default
if keyword_set(nasmyth) or keyword_set(azel) then radec = 0

nsn   = n_elements( data)
nkids = n_elements( kidpar)

;; Determine map size parameters
;;nika_pipe_xymaps, param, data, kidpar, xmap, ymap, nx, ny, xmin, ymin
reso_x = param.map.reso
reso_y = param.map.reso
nx = round(param.map.size_ra/param.map.reso)     ;Number of pixels along ra
ny = round(param.map.size_dec/param.map.reso)    ;Number of pixels along dec
nx = 2*long(nx/2.0) + 1                          ;Ensure there's a pixel centered on (0,0)
ny = 2*long(ny/2.0) + 1
xmin = (-nx/2-0.5)*param.map.reso
ymin = (-ny/2-0.5)*param.map.reso
xymaps, nx, ny, xmin, ymin, param.map.reso, xmap, ymap, xgrid, ygrid

npix = n_elements( xmap)

nhits = lonarr( npix, 2)

;; Project
if param.polar.do_lockin eq 1 then begin

   ;; Init output maps
   maps_S0 = dblarr( npix, 2)
   maps_S1 = dblarr( npix, 2)
   maps_S2 = dblarr( npix, 2)
   map_w8  = dblarr( npix, 2)
   maps_covar = dblarr(npix, 2, 6) ; 2 bands, 6 covariance terms per pixel

   cos4omega = cos(4.d0*data.c_position)
   sin4omega = sin(4.d0*data.c_position)

;   stop
   ;; Init filter
   np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
                freqlow=param.polar.lockin_freqlow, $
                freqhigh=param.polar.lockin_freqhigh, $
                delta_f=param.polar.lockin_delta_f, filter=filter

   ;; Rotation of polarization depending on the choice of coordinates
   if keyword_set(nasmyth) then alpha = 0.d0 ; do nothing
   if keyword_set(azel)    then alpha = alpha_nasmyth( data.el)
   if radec eq 1           then alpha = alpha_nasmyth( data.el) - data.paral

;;--------------------------------------------------
   ;; Deal with bands separately
   ;; Lockin and subtract Q and U common modes for Uranus
   data_q = data
   data_u = data
   for lambda=1, 2 do begin
      wkids = where( kidpar.type eq 1 and kidpar.array eq lambda, nwkids)
      if nwkids ne 0 then begin
         ;;map_w8 = dblarr(nx,ny)
         
         message, /info, "Lock-in, lambda = "+Strtrim(lambda,2)+"/ Loop on kids..."
         for i=0, nwkids-1 do begin
            percent_status, i, nwkids, 10
            ikid = wkids[i]
            
            ;; Lock-in
            y = reform( data.rf_didq[ikid]) - my_baseline( data.rf_didq[ikid])
            np_bandpass, y,           !nika.f_sampling, toi_t, filter=filter
            np_bandpass, y*cos4omega, !nika.f_sampling, toi_q, filter=filter
            np_bandpass, y*sin4omega, !nika.f_sampling, toi_u, filter=filter

            data.rf_didq[  ikid] = toi_t
            data_q.rf_didq[ikid] = toi_q
            data_u.rf_didq[ikid] = toi_u
         endfor
      endif
   endfor

   ;; Subtract Q and U common modes
   param1 = param
   param1.decor.method = 'COMMON_MODE_KIDS_OUT'
   nika_pipe_decor, param1, data_q, kidpar
   nika_pipe_decor, param1, data_u, kidpar

   ;; Project
   for lambda=1, 2 do begin
      wkids = where( kidpar.type eq 1 and kidpar.array eq lambda, nwkids)
      if nwkids ne 0 then begin
         ;;map_w8 = dblarr(nx,ny)

         message, /info, "Lock-in, lambda = "+Strtrim(lambda,2)+"/ Loop on kids..."
         for i=0, nwkids-1 do begin
            percent_status, i, nwkids, 10
            ikid = wkids[i]
            
            ;; ;; Lock-in
            ;; y = reform( data.rf_didq[ikid]) - my_baseline( data.rf_didq[ikid])
            ;; np_bandpass, y,           !nika.f_sampling, toi_t, filter=filter
            ;; np_bandpass, y*cos4omega, !nika.f_sampling, toi_q, filter=filter
            ;; np_bandpass, y*sin4omega, !nika.f_sampling, toi_u, filter=filter
            
            ;; Pixel address
            if keyword_set(azel) then begin
               nika_nasmyth2azel, kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                  0.0, 0.0, data.el*!radeg, dra, ddec, $
                                  nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
               dra  = dra - data.ofs_az
               ddec = ddec - data.ofs_el
            endif else begin
               nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                                     kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                     0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                                     nas_y_ref=kidpar[ikid].nas_center_Y
            endelse
            ix   = long( (dra  - xmin)/param.map.reso)    ;Coord of the pixel along x
            iy   = long( (ddec - ymin)/param.map.reso)    ;Coord of the pixel along y
            ipix = long(ix + iy*nx)
            
            toi_t = data.rf_didq[  ikid]
            toi_q = data_q.rf_didq[ikid]
            toi_u = data_u.rf_didq[ikid]

            ;; Rotate polarization to sky coordinates
            junk  =  toi_q*cos(2.d0*alpha) + toi_u*sin(2.d0*alpha)
            toi_u = -toi_q*sin(2.d0*alpha) + toi_u*cos(2.d0*alpha)
            toi_q = junk

            ;; Co-add demodulated timelines
            for isn=0L, nsn-1 do begin
               if (ix[isn] ge 0) and (ix[isn] le (nx-1)) and $
                  (iy[isn] ge 0) and (iy[isn] le (ny-1)) and $
                  data[isn].flag[ikid] eq 0 then begin
                  p = ipix[isn]
                  ;; should be ok for all samples if xmap and ymap have been
                  ;; defined correctly...
                  maps_S0[ p, lambda-1] += toi_t[isn]*data[isn].w8[ikid] * 2.d0    ; factor 2 due to the splitting grid
                  maps_S1[ p, lambda-1] += toi_q[isn]*data[isn].w8[ikid] * 4.d0    ; factor 4 due to the splitting grid and the demodulation
                  maps_S2[ p, lambda-1] += toi_u[isn]*data[isn].w8[ikid] * 4.d0    ; factor 4 due to the splitting grid and the demodulation
                  nhits[   p, lambda-1] += double( data[isn].w8[ikid] ne 0)
                  map_w8[  p, lambda-1] += data[isn].w8[ikid]
               endif
            endfor              ; isn
         endfor                 ; ikid

         ;; Normalize
         message, /info, "Lock-in, lamba="+strtrim(lambda,2)+" / Normalize maps..."
         w = where( nhits[*,lambda-1] ne 0, nw, compl=w_undef, ncompl=nw_undef)
         if nw eq 0 then begin
            message, "All pixels empty ?!"
         endif else begin
            maps_S0[ w, lambda-1] /= map_w8[ w, lambda-1]
            maps_S1[ w, lambda-1] /= map_w8[ w, lambda-1]
            maps_S2[ w, lambda-1] /= map_w8[ w, lambda-1]

            maps_covar[w,lambda-1,0] = 1.d0/( 4.d0*map_w8[ w, lambda-1]) ; factor  4 here due to factor 2 when co-adding T timeline
            maps_covar[w,lambda-1,1] = 1.d0/(16.d0*map_w8[ w, lambda-1]) ; factor 16 here due to factor 4 when co-adding T timeline
            maps_covar[w,lambda-1,2] = 1.d0/(16.d0*map_w8[ w, lambda-1]) ; factor 16 here due to factor 4 when co-adding T timeline
         endelse
         
         if nw_undef ne 0 then begin
            maps_S0[ w_undef, lambda-1] = !values.d_nan
            maps_S1[ w_undef, lambda-1] = !values.d_nan
            maps_S2[ w_undef, lambda-1] = !values.d_nan
         endif
         
      endif                     ; nwkids ne 0
   endfor                       ; lambda
endif

;;------------------------------------------------------
if param.polar.do_coadd eq 1 then begin

   ;; Init output maps
   maps_S0 = dblarr(npix, 2)
   maps_S1 = dblarr(npix, 2)
   maps_S2 = dblarr(npix, 2)
   maps_covar = dblarr(npix, 2, 6) ; 2 bands, 6 covariance terms per pixel

   ;; Init
   cos4omega = cos(4.d0*data.c_position)
   sin4omega = sin(4.d0*data.c_position)
   ata_map   = dblarr( npix, 5)
   atd_map   = dblarr( npix, 3)

   ;; Deal with bands separately
   for lambda=1, 2 do begin
      wkids = where( kidpar.type eq 1 and kidpar.array eq lambda, nwkids)
      if nwkids ne 0 then begin

         message, /info, "Co-add / loop on kids..."
         for i=0, nwkids-1 do begin
            percent_status, i, nwkids, 10
            ikid = wkids[i]

            ;; Pixel address
            if keyword_set(azel) then begin
               nika_nasmyth2azel, kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                  0.0, 0.0, data.el*!radeg, dra, ddec, $
                                  nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y
               dra  = dra - data.ofs_az
               ddec = ddec - data.ofs_el
            endif else begin
               nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                                  kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                  0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                                  nas_y_ref=kidpar[ikid].nas_center_Y
            endelse
            ix   = long( (dra  - xmin)/param.map.reso)    ;Coord of the pixel along x
            iy   = long( (ddec - ymin)/param.map.reso)    ;Coord of the pixel along y
            ipix = long(ix + iy*nx)

            ;; save addressing time
            toi = data.rf_didq[ikid]

            for isn=0L, nsn-1 do begin
               if (ix[isn] ge 0) and (ix[isn] le (nx-1)) and $
                  (iy[isn] ge 0) and (iy[isn] le (ny-1)) then begin
                  p = ipix[isn]
                  
                  nhits[ p, lambda-1] += double( data[isn].w8[ikid] ne 0)

                  ata_map[ p, 0] += 0.25d0 * data[isn].w8[ikid] * 1.d0
                  ata_map[ p, 1] += 0.25d0 * data[isn].w8[ikid] * cos4omega[isn]
                  ata_map[ p, 2] += 0.25d0 * data[isn].w8[ikid] * sin4omega[isn]
                  ata_map[ p, 3] += 0.25d0 * data[isn].w8[ikid] * cos4omega[isn]^2
                  ata_map[ p, 4] += 0.25d0 * data[isn].w8[ikid] * cos4omega[isn]*sin4omega[isn]
                  
                  atd_map[ p, 0] += 0.5d0  * data[isn].w8[ikid] *                toi[isn]
                  atd_map[ p, 1] += 0.5d0  * data[isn].w8[ikid] * cos4omega[isn]*toi[isn]
                  atd_map[ p, 2] += 0.5d0  * data[isn].w8[ikid] * sin4omega[isn]*toi[isn]
               endif
            endfor
         endfor

         ;; Solve for S0, S1, S2 on observed pixels
         message, /info, "Co-add / Inverting system..."
         wpix = where( ata_map[*,0] ne 0, nwpix, compl=w_undef, ncompl=nw_undef) ; loop only on pixels that were hit
         if nwpix eq 0 then message, "All pixels empty ?!"
         if nw_undef ne 0 then begin
            maps_S0[w_undef,lambda-1] = !values.d_nan
            maps_S1[w_undef,lambda-1] = !values.d_nan
            maps_S2[w_undef,lambda-1] = !values.d_nan
         endif

         for ip=0L, nwpix-1 do begin
            p = wpix[ip]
            
            ata = dblarr(3,3)
            ata[0,0] = ata_map[ p, 0]
            ata[1,0] = ata_map[ p, 1]
            ata[2,0] = ata_map[ p, 2]
            ata[1,1] = ata_map[ p, 3]
            ata[2,1] = ata_map[ p, 4]
            ata[2,2] = ata[0] - ata[1,1]
            ata[0,1] = ata[1,0]
            ata[0,2] = ata[2,0]
            ata[1,2] = ata[2,1]

            cond_num = cond( ata, /double, lnorm=2)
            if cond_num le param.polar.cond_num_max then begin
               atd = dblarr(3)
               atd[0] = atd_map[ p, 0]
               atd[1] = atd_map[ p, 1]
               atd[2] = atd_map[ p, 2]

               atam1 = invert(ata)
               s = atam1 ## atd
               
               maps_S0[ p, lambda-1] = s[0]
               maps_S1[ p, lambda-1] = s[1]
               maps_S2[ p, lambda-1] = s[2]

               maps_covar[ p, lambda-1, 0] = atam1[0,0]    ; II
               maps_covar[ p, lambda-1, 1] = atam1[1,1]    ; QQ
               maps_covar[ p, lambda-1, 2] = atam1[2,2]    ; UU
               maps_covar[ p, lambda-1, 3] = atam1[1,0]    ; IQ
               maps_covar[ p, lambda-1, 4] = atam1[2,0]    ; IU
               maps_covar[ p, lambda-1, 5] = atam1[2,1]    ; QU
            endif
         endfor
      endif
   endfor
endif

end

