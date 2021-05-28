
pro nika_pipe_lockin_maps, param, data, kidpar, $
                           maps_S0, maps_S1, maps_S2, $
                           maps_covar, nhits, $
                           xmap=xmap, ymap=ymap, azel=azel

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

;; Init output maps
maps_S0 = dblarr( npix, 2)
maps_S1 = dblarr( npix, 2)
maps_S2 = dblarr( npix, 2)
map_w8  = dblarr( npix, 2)
maps_covar = dblarr(npix, 2, 6) ; 2 bands, 6 covariance terms per pixel

;; Simple HWP rotation : IQU in Matrix coordinates (Nasmyth, up to a
;; (x,y) convention)
;cos4omega = cos(4.d0*data.c_position)
;sin4omega = sin(4.d0*data.c_position)

;; I put a "-" in front of omega to remember that i turns in clockwise
;; when the matrix looks to the sky through it (TBC !!!!)
if keyword_set(azel) then begin
;; Add Nasmyth to Azel rotation (check rotation orientation !!)
   cos4omega = cos( -4.d0*data.c_position + 2*(!dpi/2.-data.el))
   sin4omega = sin( -4.d0*data.c_position + 2*(!dpi/2.-data.el))
endif else begin
   ;; then (ra,dec) (check rotation orientation !!)
   cos4omega = cos( -4.d0*data.c_position + 2*(!dpi/2.-data.el) - 2*data.paral)
   sin4omega = sin( -4.d0*data.c_position + 2*(!dpi/2.-data.el) - 2*data.paral)
endelse

;; Init filter
np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
             freqhigh=param.polar.lockin_freqhigh, delta_f=param.polar.lockin_delta_f, filter=filter

;; Deal with bands separately
for lambda=1, 2 do begin
   wkids = where( kidpar.type eq 1 and kidpar.array eq lambda, nwkids)
   if nwkids ne 0 then begin
      ;;map_w8 = dblarr(nx,ny)

      message, /info, "Lock-in / Loop on kids..."
      for i=0, nwkids-1 do begin
         percent_status, i, nwkids, 10
         ikid = wkids[i]
         
         ;; Lock-in
         y = reform( data.rf_didq[ikid]) - my_baseline( data.rf_didq[ikid])
         np_bandpass, y,           !nika.f_sampling, toi_t, filter=filter
         np_bandpass, y*cos4omega, !nika.f_sampling, toi_q, filter=filter
         np_bandpass, y*sin4omega, !nika.f_sampling, toi_u, filter=filter

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
         
         ;; Co-add demodulated timelines
         for isn=0L, nsn-1 do begin
            if (ix[isn] ge 0) and (ix[isn] le (nx-1)) and $
               (iy[isn] ge 0) and (iy[isn] le (ny-1)) then begin
               p = ipix[isn]
               ;; should be ok for all samples if xmap and ymap have been
               ;; defined correctly...
               maps_S0[ p, lambda-1] += toi_t[isn]*data[isn].w8[ikid] * 2.d0    ; factor 2 due to the splitting grid
               maps_S1[ p, lambda-1] += toi_q[isn]*data[isn].w8[ikid] * 4.d0    ; factor 4 due to the splitting grid and the demodulation
               maps_S2[ p, lambda-1] += toi_u[isn]*data[isn].w8[ikid] * 4.d0    ; factor 4 due to the splitting grid and the demodulation
               nhits[   p, lambda-1] += double( data[isn].w8[ikid] ne 0)
               map_w8[  p, lambda-1] += data[isn].w8[ikid]
            endif
         endfor                 ; isn
      endfor                    ; ikid

      ;; Normalize
      message, /info, "Lock-in / Normalize maps..."
      w = where( nhits[*,lambda-1] ne 0, nw, compl=w_undef, ncompl=nw_undef)
      if nw eq 0 then begin
         message, "All pixels empty ?!"
      endif else begin
         maps_S0[ w, lambda-1] /= map_w8[ w, lambda-1]
         maps_S1[ w, lambda-1] /= map_w8[ w, lambda-1]
         maps_S2[ w, lambda-1] /= map_w8[ w, lambda-1]

         maps_covar[w,lambda-1,0] = 1.d0/( 4.d0*map_w8[ w, lambda-1])    ; factor  4 here due to factor 2 when co-adding T timeline
         maps_covar[w,lambda-1,1] = 1.d0/(16.d0*map_w8[ w, lambda-1])    ; factor 16 here due to factor 4 when co-adding T timeline
         maps_covar[w,lambda-1,2] = 1.d0/(16.d0*map_w8[ w, lambda-1])    ; factor 16 here due to factor 4 when co-adding T timeline
      endelse
      
      if nw_undef ne 0 then begin
         maps_S0[ w_undef, lambda-1] = !values.d_nan
         maps_S1[ w_undef, lambda-1] = !values.d_nan
         maps_S2[ w_undef, lambda-1] = !values.d_nan
      endif
      
   endif                        ; nwkids ne 0
endfor                          ; lambda

end

