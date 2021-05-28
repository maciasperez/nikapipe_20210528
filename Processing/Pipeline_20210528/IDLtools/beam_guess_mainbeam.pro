pro beam_guess_mainbeam, map_list, xmap, ymap, kidpar, $
                         sidelobe_mask_r_in, sidelobe_mask_r_out, $
                         x_peaks, y_peaks, a_peaks, sigma_x, sigma_y, beam_list, theta, const, $
                         rebin=rebin_factor, noplot=noplot, verbose=verbose, method=method, $
                         p_start=p_start, err=err, parinfo=parinfo, $
                         circular=circular, type=type, nhits=nhits, riemann=riemann, $
                         cpu_time=cpu_time, silent=silent, map_list_nhits=map_list_nhits, $
                         coordinates=coordinates, guess_fit_par=guess_fit_par, chi2=chi2, $
                         interpol=interpol, az_scanning=az_scanning, map_list_interp=map_list_interp
  
  t0 = systime(0,/sec)
  if not keyword_set(type) then type = [1]
  
  if not keyword_set(rebin_factor) then rebin_factor = 1
  nkids = n_elements( map_list[*,0,0])
  
  if keyword_set(coordinates) then coord = coordinates else coord='azel'
  if keyword_set(az_scanning) then azscan = 1 else azscan=0
  
  
  if not keyword_set(nhits) then nhits = xmap*0.d0 + 1.d0
  
  x_peaks  = replicate(!values.d_nan, nkids) ; dblarr( nkids) + !undef
  y_peaks  = replicate(!values.d_nan, nkids) ; dblarr( nkids) + !undef
  a_peaks  = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  sigma_x  = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  sigma_y  = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  theta    = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  const    = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  beam_snr = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  flux_1   = replicate(!values.d_nan, nkids) ; dblarr( nkids)
  
  nx_raw = n_elements( map_list[0,*,0])
  ny_raw = n_elements( map_list[0,0,*])
  
  if not keyword_set(method) then method = 'NIKA'
  
  beam_list = dblarr( nkids, nx_raw, ny_raw)
  
  if keyword_set(chi2) then list_chi2 = dblarr( nkids)
  
  xx   = reform(xmap[*,0])
  yy   = reform(ymap[0,*])
  
  reso = xmap[1,0] - xmap[0,0]
  
;; place holder
  nk_default_info, info
  
  kp_tags = tag_names(kidpar)
  x_field = 'x_peak_azel'
  y_field = 'y_peak_azel'
  if coord eq 'nasmyth' then begin
     x_field = 'x_peak_nasmyth'
     y_field = 'y_peak_nasmyth'   
  endif
  wx = where( strupcase(kp_tags) eq strupcase(x_field), nwx)
  wy = where( strupcase(kp_tags) eq strupcase(y_field), nwy)
  
  
  w1 = where( kidpar.type eq 1, nw1)
  if keyword_set(interpol) then map_list_interp = map_list*0d0
  
;; az-el coordinates
;;_______________________________________________________________
  if coord eq 'azel' then begin

     for i=0, nw1-1 do begin
        ikid = w1[i]
        if not keyword_set(silent) then percent_status, ikid, nw1, 5, bar=bar, title='Beam fitting...'
        
        nhits = lonarr(nx_raw, ny_raw)+1L
        if keyword_set(map_list_nhits) then nhits = reform( map_list_nhits[ikid,*,*], nx_raw, ny_raw)
        
        map_raw        = reform( map_list[ikid,*,*], nx_raw, ny_raw)
        dmap = sqrt( (xmap-(kidpar.(wx))[ikid])^2 + (ymap-(kidpar.(wy))[ikid])^2)
        ar = kidpar[ikid].array
        r_in  = sidelobe_mask_r_in[ ar -1]
        r_out = sidelobe_mask_r_out[ar -1]
        wgood = where( (dmap le r_in  and finite(map_raw) eq 1 and nhits ne 0) or (dmap ge r_out and finite(map_raw) eq 1 and nhits ne 0), nwgood, compl=wundef, ncompl=nwundef)
        wgoodvar    = wgood
        wundefvar   = wundef
        nwundefvar  = nwundef
        ;;
        map2fit        = xmap*0.d0
        map2fit[wgood] = map_raw[wgood]
        
        ;; interpolate the central part of the map
        ;; (fill-in the holes due to the scanning)
        if keyword_set(interpol) then begin
           
           map_azel = map_raw
           if azscan eq 1 then begin
              map_raw = transpose(map_raw)
              nhits   = transpose(nhits)
              ymap    = transpose(ymap)
              xmap    = transpose(xmap)
              dmap    = transpose(dmap)
              map_azel= transpose(map_azel)
           endif
           
           
           wcentral = where(dmap le r_in, ncentral)
           minx = min(xmap[wcentral])
           maxx = max(xmap[wcentral])
           imin = where(abs(xmap[*, 0]-minx) le 1.d-5, nmin)
           if nmin lt 1 then imin = 0
           imax = where(abs(xmap[*, 0]-maxx) le 1.d-5, nmax)
           if nmax lt 1 then imax = nx_raw-1
           
           
           for ix= imin[0], imax[0] do begin
              v = reform(map_raw[ix, *])
              y = reform(ymap[   ix, *])
              h = reform(nhits[  ix, *])
              d = reform(dmap[   ix, *])
              wzero = where((d le r_in) and (h le 0 or finite(v) ne 1), nzero, compl=wdef, ncompl=ndef)
              if ndef gt 10. then begin
                 vec = SPLINE(y[wdef], v[wdef], y)
                 map_azel[ix, wzero] = vec[wzero]
              endif   
           endfor
           
           wgood = where((dmap le r_in) or (dmap ge r_out and finite(map_raw) eq 1 and nhits ne 0), nwgood, $
                         compl=wundef, ncompl=nwundef)
           map2fit        = xmap*0.d0
           map2fit[wgood] = map_azel[wgood]

           if azscan eq 1 then begin
              map2fit = transpose(map2fit)
              map_raw = transpose(map_raw)
              nhits   = transpose(nhits)
              ymap    = transpose(ymap)
              dmap    = transpose(dmap)
           endif
           map_list_interp[ikid, *, *] = map2fit
        endif
        
                                ;measure_errors = map2fit*0.d0
                                ;measure_errors[wgood] = 1./sqrt(nhits[wgood])
                                ;if nwundef ne 0 then measure_errors[wundef] = 1000.*max(measure_errors[wgood])
        ;; improve on the variance estimate
        wbg = where( dmap ge 100. and finite(map_raw) eq 1 and nhits ne 0, nwbg)   
        measure_errors = map2fit*0.d0
        if nwbg eq 0 then begin
           measure_errors[wgoodvar] = 1./sqrt(nhits[wgoodvar])
        endif else begin
           bg_mask = map2fit*0
           bg_mask[wbg] = 1
           nk_bg_var_map, map2fit, nhits, bg_mask, map_var
           measure_errors[wgoodvar] = sqrt(map_var[wgoodvar])
           wnan = where(finite(measure_errors) ne 1, nnan, compl=wok)
           if nnan gt 0 then measure_errors[wnan] = 1000.*max(measure_errors[wok])
        endelse
        if nwundefvar ne 0 then measure_errors[wundefvar] = 1000.*max(measure_errors[wgoodvar])
        
        ;;initialise fit parameters
        if keyword_set(guess_fit_par) then begin
           wpix   = where( finite(measure_errors) and measure_errors gt 0 and measure_errors lt median(measure_errors) and dmap ge 100., nwpix1)
           init_const  = median(map2fit[wpix])
           rclose = 15.         ; arcsec
           wclose = where(dmap le rclose, nwclose)
           wmax   = where(map2fit[wclose] eq max( map2fit[wclose]) )
           ampl   = map2fit[wclose[wmax[0]]]
           xmax   = xmap[wclose[wmax[0]]]
           ymax   = ymap[wclose[wmax[0]]]
           
           fwhm = 11.2
           if kidpar[ikid].array eq 2 then fwhm = 17.8
           init_sigma_x = fwhm*!fwhm2sigma
           init_sigma_y = fwhm*!fwhm2sigma
           
           ;; see explanation in mpfit2dfun.pro
           parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
                                limits:[0.D,0]}, 7)
           parinfo[0].value = init_const
           parinfo[1].value = ampl
           parinfo[2].value = init_sigma_x
           parinfo[3].value = init_sigma_y
           parinfo[4].value = xmax
           parinfo[5].value = ymax
           parinfo[6].value = 0. 
           ;;stop   
        endif
        
        
        case strupcase(method) of
           "MPFIT":begin
              ;; Force circular to correct for the wire in lab data
              fit  = mpfit2dpeak( map2fit, a, xx, yy, /tilt, /gauss, /circular)
           end
           "GAUSS2D":begin
              ;; set to 0 the undef values to maintain compatibility with gauss2dfit
              fit = gauss2dfit( map2fit, a, xx, yy, /tilt)
           end
           "NIKA":begin
              junk = nika_gauss2dfit( map2fit[wgood], xmap[wgood], ymap[wgood], measure_errors[wgood], a, parinfo=parinfo)
           end
        endcase
        
        const[  ikid] = a[0]
        a_peaks[ikid] = a[1]
        x_peaks[ikid] = a[4]
        y_peaks[ikid] = a[5]
        sigma_x[ikid] = a[2]
        sigma_y[ikid] = a[3]
        theta[  ikid] = a[6]
        
        if keyword_set(chi2) then begin
           best_map = nika_gauss2( xmap, ymap, a)
           list_chi2[ikid]  = total( ((map2fit[wgood] - best_map[wgood])/measure_errors[wgood])^2 )/ nwgood
           
        endif


     endfor
  endif else if coord eq 'nasmyth' then begin
     ;;
     ;;
     ;; nasmyth coordinates
     ;;_______________________________________________________________
     for i=0, nw1-1 do begin
        ikid = w1[i]
        if not keyword_set(silent) then percent_status, ikid, nw1, 5, bar=bar, title='Beam fitting...'
        
        nhits = lonarr(nx_raw, ny_raw)+1L
        if keyword_set(map_list_nhits) then nhits = reform( map_list_nhits[ikid,*,*], nx_raw, ny_raw)
        
        map_raw        = reform( map_list[ikid,*,*], nx_raw, ny_raw)
        dmap = sqrt( (xmap-(kidpar.(wx))[ikid])^2 + (ymap-(kidpar.(wy))[ikid])^2)
        ar = kidpar[ikid].array
        r_in  = sidelobe_mask_r_in[ ar -1]
        r_out = sidelobe_mask_r_out[ar -1]
        wgood = where( (dmap le r_in  and finite(map_raw) eq 1 and nhits ne 0) or (dmap ge r_out and finite(map_raw) eq 1 and nhits ne 0), nwgood, compl=wundef, ncompl=nwundef)
        wgoodvar    = wgood
        wundefvar   = wundef
        nwundefvar  = nwundef
        ;;
        map2fit        = xmap*0.d0
        map2fit[wgood] = map_raw[wgood]
        
        ;; interpolate the central part of the map
        ;; (fill-in the holes due to the scanning)
        if keyword_set(interpol) then begin
           
           map_nas = map_raw
           wzero = where((dmap le r_in) and (nhits le 0 or finite(map_nas) ne 1), nzero, compl=wdef, ncompl=ndef)
           if ndef gt 10. then begin
              ;; super long !!!!
              ;;map_int = cgKRIG2D(map_nas[wdef], xmap_nas[wdef], ymap_nas[wdef],
              ;;xout =xmap_nas[wzero],  yout=ymap_nas[wzero],
              ;;Spherical=[5.0,0.0])
              ;; ok, un peu long
              ;;map_int = GRIDDATA( xmap_nas[wdef], ymap_nas[wdef], map_nas[wdef], /grid, xout = xmap_nas[*,0], yout = ymap_nas[0, *]) 
              
              TRIANGULATE, xmap[wdef], ymap[wdef], triangles, boundary
              map_int = TRIGRID(xmap[wdef], ymap[wdef], map_nas[wdef], triangles, XOUT = xmap[*,0], $
                                YOUT = ymap[0, *], EXTRAPOLATE = boundary)

              map_nas[wzero] = map_int[wzero] 
           endif
           
           
           wgood = where((dmap le r_in) or (dmap ge r_out and finite(map_raw) eq 1 and nhits ne 0), nwgood, compl=wundef, ncompl=nwundef)
           map2fit        = xmap*0.d0
           map2fit[wgood] = map_nas[wgood]
           
           map_list_interp[ikid, *, *] = map2fit
        endif
        
        ;; improve on the variance estimate
        wbg = where( dmap ge 100. and finite(map_raw) eq 1 and nhits ne 0, nwbg)   
        measure_errors = map2fit*0.d0
        if nwbg eq 0 then begin
           measure_errors[wgoodvar] = 1./sqrt(nhits[wgoodvar])
        endif else begin
           bg_mask = map2fit*0
           bg_mask[wbg] = 1
           nk_bg_var_map, map2fit, nhits, bg_mask, map_var
           measure_errors[wgoodvar] = sqrt(map_var[wgoodvar])
           wnan = where(finite(measure_errors) ne 1, nnan, compl=wok)
           if nnan gt 0 then measure_errors[wnan] = 1000.*max(measure_errors[wok])
        endelse
        if nwundefvar ne 0 then measure_errors[wundefvar] = 1000.*max(measure_errors[wgoodvar])
        
        ;;initialise fit parameters
        if keyword_set(guess_fit_par) then begin
           wpix   = where( finite(measure_errors) and measure_errors gt 0 and measure_errors lt median(measure_errors) and dmap ge 100., nwpix1)
           init_const  = median(map2fit[wpix])
           rclose = 15.         ; arcsec
           wclose = where(dmap le rclose, nwclose)
           wmax   = where(map2fit[wclose] eq max( map2fit[wclose]) )
           ampl   = map2fit[wclose[wmax[0]]]
           xmax   = xmap[wclose[wmax[0]]]
           ymax   = ymap[wclose[wmax[0]]]
           
           fwhm = 11.2
           if kidpar[ikid].array eq 2 then fwhm = 17.8
           init_sigma_x = fwhm*!fwhm2sigma
           init_sigma_y = fwhm*!fwhm2sigma
           
           ;; see explanation in mpfit2dfun.pro
           parinfo = replicate({value:0.D, fixed:0, limited:[0,0], $
                                limits:[0.D,0]}, 7)
           parinfo[0].value = init_const
           parinfo[1].value = ampl
           parinfo[2].value = init_sigma_x
           parinfo[3].value = init_sigma_y
           parinfo[4].value = xmax
           parinfo[5].value = ymax
           parinfo[6].value = 0. 
           ;;stop   
        endif
        
        
        case strupcase(method) of
           "MPFIT":begin
              ;; Force circular to correct for the wire in lab data
              fit  = mpfit2dpeak( map2fit, a, xx, yy, /tilt, /gauss, /circular)
           end
           "GAUSS2D":begin
              ;; set to 0 the undef values to maintain compatibility with gauss2dfit
              fit = gauss2dfit( map2fit, a, xx, yy, /tilt)
           end
           "NIKA":begin
              junk = nika_gauss2dfit( map2fit[wgood], xmap[wgood], ymap[wgood], measure_errors[wgood], a, parinfo=parinfo)
           end
        endcase
        
        const[  ikid] = a[0]
        a_peaks[ikid] = a[1]
        x_peaks[ikid] = a[4]
        y_peaks[ikid] = a[5]
        sigma_x[ikid] = a[2]
        sigma_y[ikid] = a[3]
        theta[  ikid] = a[6]
        
        if keyword_set(chi2) then begin
           best_map = nika_gauss2( xmap, ymap, a)
           list_chi2[ikid]  = total( ((map2fit[wgood] - best_map[wgood])/measure_errors[wgood])^2 )/ nwgood
           
        endif

        
;;       ;;-------------------------------
;;       ;; try to iterate on 4G
;;       message, /info, "fix me: fitting 4 gaussians per kid"
;;       map_var = map2fit*0.d0
;;       map_var[wgood] = 1.d0/nhits[wgood]
;; 
;;       ;; restrict to a fraction of the map close to the 1st estimate
;;       rmax = 15.d0 ; 70.d0              ; to try
;;       w = where( abs(xmap[*,0]-a[4]) le rmax)
;;       x1 = min(w)
;;       x2 = max(w)
;;       w = where( abs(ymap[0,*]-a[5]) le rmax)
;;       y1 = min(w)
;;       y2 = max(w)
;; 
;;       ngauss = 4
;; 
;;       map2fit = map2fit[x1:x2,y1:y2]
;;       map_var = map_var[x1:x2,y1:y2]
;;       map_tot = map2fit*0.d0
;;       xmapfit = xmap[   x1:x2,y1:y2]
;;       ymapfit = ymap[   x1:x2,y1:y2]
;;       map_list = dblarr(ngauss,x2-x1+1,y2-y1+1)
;; 
;; 
;;       gauss_params = dblarr(3,ngauss,7)
;;       iarray = 1 ; place holder
;;       wind, 1, 1, /free, /large
;;       my_multiplot, 1, 1, pp, pp1, /rev, ntot=ngauss+3
;;       print, "HERE"
;;       stop
;;       for i=0, ngauss-1 do begin
;;          map = map2fit - map_tot
;;          nk_fitmap, map, map_var, xmapfit, ymapfit, output_fit_par
;;          map1 = nika_gauss2( xmapfit, ymapfit, output_fit_par)
;;          fwhm = sqrt( output_fit_par[2]*output_fit_par[3])/!fwhm2sigma
;;          imview, map1,  xmap=xmapfit, ymap=ymapfit, title=strtrim(i+1,2)+"th gaussian", /noerase, xra=xra, yra=yra, $
;;                  legend_text = ['A'+strtrim(iarray,2), $
;;                                 'Const: '+strtrim(output_fit_par[0],2), $
;;                                 'Ampl: '+strtrim(output_fit_par[1],2), $
;;                                 'FWHM: '+strtrim(fwhm,2)], leg_color=255, position=pp1[i,*], charsize=charsize
;;          map_tot += map1
;;          map_list[i,*,*] = map1
;;          gauss_params[iarray-1,i,*] = output_fit_par
;;          stop
;;       endfor
;;       imview, map_tot, xmap=xmapfit, ymap=ymapfit, title="total", /noerase, xra=xra, yra=yra, $
;;               position=pp1[ngauss,*], imrange=[-1,5]
;;       imview, input_map, xmap=xmapfit, ymap=ymapfit, title="raw", /noerase, xra=xra, yra=yra, $
;;               position=pp1[ngauss+1,*], imrange=[-1,5]
;;       imview, input_map-map_tot, xmap=xmapfit, ymap=ymapfit, title="raw-total", /noerase, xra=xra, yra=yra, $
;;               position=pp1[ngauss+2,*]
;;       my_multiplot, /reset
;;       message, /info, "First fit in 4 gaussians done"
;;       stop
;; 
;;       ;;--------------------------------------
;; 

     endfor

endif


if keyword_set(chi2) then chi2=list_chi2

if not keyword_set(noplot) then matrix_display, beam_list, kidpar=kidpar
t1 = systime(0,/sec)
cpu_time = t1-t0

end
