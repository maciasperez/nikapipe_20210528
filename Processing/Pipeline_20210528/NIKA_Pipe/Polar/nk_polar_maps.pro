;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: check_nk_polar_maps
;
; CATEGORY: general, launcher
;
; CALLING SEQUENCE:
;         check_nk_polar_maps, param, info
; 
; PURPOSE: 
;        This is the main procedure of the NIKA offline analysis
;        software that reduces the timelines to maps.
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - info: an information structure to be filled
; 
; OUTPUT: 
;        - FITS maps 
;        - Calibrated Time Ordered Data (optional)
;        - Calibration products: beam, bandpass, unit conversion
;          (optional)
;        - pdf check plots (optional)
;        - log file of the terminal (optional)
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - 11/06/2014: creation (Nicolas Ponthieu & Alessia Ritacco alessia.ritacco@lpsc.in2p3.fr)
;-     
;=========================================================================================================

pro nk_polar_maps, param, info, data, data_q, data_u,kidpar,$
                   azel=azel, nasmyth=nasmyth


  if n_params() lt 1 then begin
     message, /info, "Calling sequence:"
     print, "nika_pipe_polar_maps, param, data, kidpar, $"
     print, "                      map, map_q, map_u, $"
     print, "                      maps_covar, nhits, $"
     print, "                      xmap=xmap, ymap=ymap,$"
     print, "                      azel=azel, nasmyth=nasmyth"
     return
  endif

  if keyword_set(nasmyth) and keyword_set(azel) then $
     message, "you must choose either /azel or /nasmyth, not both"
  radec = 1                     ; default
  if keyword_set(nasmyth) or keyword_set(azel) then radec = 0

  nsn   = n_elements( data)
  nkids = n_elements( kidpar)
  npix  = n_elements( info.xmap)
  nhits = lonarr( npix, 2)
  if param.naive_projection eq 1 then begin
     if param.polar_do_lockin eq 1 then begin        
;   stop
        cos4omega = cos(4.d0*data.c_position)
        sin4omega = sin(4.d0*data.c_position)
        ;; Init filter
        np_bandpass, dblarr(nsn), !nika.f_sampling, junk, $
                     freqlow=param.polar_lockin_freqlow, $
                     freqhigh=param.polar_lockin_freqhigh, $
                     delta_f=param.polar_lockin_delta_f, filter=filter
        
        ;; Rotation of polarization depending on the choice of coordinates
        if keyword_set(nasmyth) then alpha = 0.d0 ; do nothing
        if keyword_set(azel)    then alpha = alpha_nasmyth( data.el)
        if radec eq 1           then alpha = alpha_nasmyth( data.el) - data.paral
        
        
        ;; Deal with bands separately
        for lambda=1, 2 do begin
           nk_list_kids, kidpar, lambda=lambda, valid=w1, nvalid=nw1
           ;; wkids = where( kidpar.type eq 1 and kidpar.array eq lambda, nwkids)
           if nw1 ne 0 then begin
              ;;map_w8 = dblarr(nx,info.ny)
              ;; Init output maps
              map    = info.coadd_1mm   *0.d0
              map_q  = info.coadd_q_1mm *0.d0
              map_u  = info.coadd_u_1mm *0.d0
              map_w8 = info.coadd_1mm   *0.d0
              nhits  = info.coadd_1mm   *0.d0
              maps_covar = dblarr(npix, 2, 6)
              ;; 2 bands, 6 covariance terms per pixel
              
              message, /info, "Lock-in, lambda = "+Strtrim(lambda,2)+"/ Loop on kids..."
              for i=0, nw1-1 do begin
                 percent_status, i, nw1, 10
                 ikid = w1[i]                
                 
                 ix   = (data.dra[ikid]  - info.xmin)/param.map_reso 
                                ;Coord of the pixel along x
                 iy   = (data.ddec[ikid] - info.ymin)/param.map_reso 
                                ;Coord of the pixel along y
                 ipix = double( long(ix) + long(iy)*info.nx)
                 
                 w = where( long(ix) lt 0 or long(ix) gt (info.nx-1), nw)
                 if nw ne 0 then ipix[w] = !values.d_nan ; for histogram
                 
                 w = where( long(iy) lt 0 or long(iy) gt (info.ny-1), nw)
                 if nw ne 0 then ipix[w] = !values.d_nan ; for histogram

                 w = where( data.flag[ikid] ne 0, nw)
                 if nw ne 0 then ipix[w] = !values.d_nan
                 

                 toi_t = data.toi[  ikid]
                 toi_q = data_q.toi[ikid]
                 toi_u = data_u.toi[ikid]
                 
                 ;; Rotate polarization to sky coordinates
                 junk  =  toi_q*cos(2.d0*alpha) + toi_u*sin(2.d0*alpha)
                 toi_u = -toi_q*sin(2.d0*alpha) + toi_u*cos(2.d0*alpha)
                 toi_q = junk


                 h = histogram( ipix, /nan, reverse_ind=R)
                 p = lindgen( n_elements(h)) + long(min(ipix,/nan))
                 
                 ;; Co-add demodulated timelines
                 for j=0L, n_elements(h)-1 do begin
                    if r[j] ne r[j+1] then begin
                       index = R[R[j]:R[j+1]-1]                      
                       map  [ p[j]] += total( toi_t[index]*data[index].w8[ikid]*2.d0)
                       map_q[ p[j]] += total( toi_q[index]*data[index].w8[ikid]*4.d0)
                       map_u[ p[j]] += total( toi_u[index]*data[index].w8[ikid]*4.d0)
                       map_w8[p[j]] += total(              data[index].w8[ikid])
                       nhits[ p[j]] += R[j+1]-1 - R[j] + 1
                    endif
                 endfor
              endfor            ; loop on nw1
              
              w = where( map_w8 ne 0, nw)
              if nw eq 0 then begin
                 nk_error, info, "all pixels empty at "+strtrim(lambda,2)+" mm"
                 return
              endif
           endif                ; nw1 ne 0
           if lambda eq 1 then begin
              info.coadd_1mm      += map
              info.coadd_q_1mm    += map_q
              info.coadd_u_1mm    += map_u
              info.map_w8_1mm     += map_w8
              info.nhits_1mm      += nhits
           endif else begin
              info.coadd_2mm      += map
              info.coadd_q_2mm    += map_q
              info.coadd_u_2mm    += map_u
              info.map_w8_2mm     += map_w8
              info.nhits_2mm      += nhits
           endelse

        endfor                  ; lambda
     endif
  endif
end
