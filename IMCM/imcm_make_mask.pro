
;; Launch several types of reduction on all G2 scans
;; Calls Labtools/NP/Dev/source_analysis.pro
;;=========================================================

pro imcm_make_mask, map_file, map_jk_file, subtract_maps, $
                    snr_thres_1mm=snr_thres_1mm, snr_thres_2mm=snr_thres_2mm, $
                    noplot=noplot, sz=sz, sigma_boost_1mm=sigma_boost_1mm, $
                    sigma_boost_2mm=sigma_boost_2mm, radius_max=radius_max, $
                    title_in=title_in, same_mask_at_1_and_2mm=same_mask_at_1_and_2mm, $
                    param=param, snr_thres_q=snr_thres_q, snr_thres_u=snr_thres_u, $
                    polar=polar

if not keyword_set(snr_thres_1mm) then snr_thres_1mm = 6.d0
if not keyword_set(snr_thres_2mm) then snr_thres_2mm = 6.d0
if not keyword_set(title_in)      then title_in = ''
if not keyword_set(snr_thres_q) then snr_thres_q = snr_thres_1mm
if not keyword_set(snr_thres_u) then snr_thres_u = snr_thres_q

if not file_test( map_jk_file) then message, 'No map available, imcm process did not work'
nk_fits2grid, map_jk_file, map_jk
nk_fits2grid, map_file, subtract_maps
subtract_maps.map_i_2mm = subtract_maps.map_i2

map_ext = ['_1mm', '2']
hits_ext = ['1mm', '2']
fwhm_list = [12.5, 18.5]

if tag_exist( subtract_maps, 'map_q_1mm') then begin
   stokes = ['I', 'Q', 'U']
endif else begin
   stokes = ['I']
endelse
nstokes = n_elements( stokes)

snr_thres = [snr_thres_1mm, snr_thres_2mm]
my_plot_window = 0
sigma_boost_1mm = 0.d0 ; default output
sigma_boost_1mm = 0.d0
for iext=0, n_elements(map_ext)-1 do begin
   junk = execute( "nhits   = subtract_maps.nhits_"+hits_ext[iext])

   ;; init mask
   mask       = subtract_maps.xmap*0.d0
   if iext eq 0 and keyword_set(polar) then polar_mask = mask
   
   if max(nhits) gt 0 then begin
      ;; Get rid of poorly sampled edges that could bias the estimates
      ;; of map_flux and map_var_flux during the convolution
      wh = where(nhits ne 0)
      nhits_med = median( nhits[wh])
      whits_reject = where( nhits lt 0.5*nhits_med)

;      message, /info, "FIX ME:"
;      wind, 1, 1, /free, /large
;      my_multiplot, 3, 3, pp, pp1, /rev

      for istokes=0, nstokes-1 do begin

         case istokes of
            0: snr_threshold = snr_thres[iext]
            1: snr_threshold = snr_thres_q
            2: snr_threshold = snr_thres_u
         endcase
         
         junk = execute( "map     = subtract_maps.map_"+stokes[istokes]+map_ext[iext])
         junk = execute( "map_var = map_jk.map_var_"+stokes[istokes]+map_ext[iext])

         map[    whits_reject] = 0.d0
         map_var[whits_reject] = 0.d0
         
         if param.new_snr_mask_method eq 1 then begin
            nk_default_info, info
            nk_snr_flux_map, map, map_var, $
                             nhits, !nika.fwhm_nom[iext], $
                             subtract_maps.map_reso, info, snr, $
                             map_smooth=map_flux, method = 3, /noboost
            if info.status eq 1 then begin
               message, /info, "pb in nk_snr_flux_map"
               stop
            endif
         endif else begin
            nk_map_photometry, map, map_var, nhits, $
                               map_jk.xmap, map_jk.ymap, !nika.fwhm_array[iext], $
                               flux, sigma_flux, grid_step=!nika.grid_step[iext], $
                               sigma_boost=sigma_boost, map_var_flux=map_var_flux, $
                               map_flux=map_flux, /noplot, param=param
            if iext eq 0 then sigma_boost_1mm = sigma_boost else sigma_boost_2mm = sigma_boost
            snr = map_jk.xmap*0.d0
            w = where( map_var_flux ne 0, nw)
            ;; snr[w] = sqrt( map_flux[w]^2/map_var_flux[w])
            ;; Keep sign in case of SZ
            snr[w] = map_flux[w]/sqrt(map_var_flux[w])
         endelse
         
;;          if (keyword_set(sz) and iext gt 0) then begin
;;             ;; Keep significant values even with negative (SZ) signal
;;             ;; as valid
;;             mask = long( mask OR double( abs(snr) gt snr_threshold))
;;          endif else begin
;;             ;; Restrict to positive intensity sources
;;             mask = long( mask OR double( snr gt snr_threshold and map_flux gt 0.d0))
;;          endelse
         
;;             if param.mask_positive_region_only eq 1 then begin
;;                mask[*] = long( mask OR double(snr gt snr_threshold and map_flux gt 0.d0))
;;             endif

         ;; Update the polarization only mask
         if iext eq 0 and istokes ge 1 then begin
            polar_mask = double( (polar_mask gt 0.) OR double( abs(snr) gt snr_threshold))
         endif

         ;; Joint I,Q,U mask
         ;; Deal with positive or neative SNR and update "mask" at the
         ;; same time from I to Q and U if present
         if (keyword_set(sz) and iext gt 0) or istokes ge 1 then begin
            mask = double( (mask gt 0.) OR double( abs(snr) gt snr_threshold))
         endif else begin
            mask = double( (mask gt 0.) OR double( snr gt snr_threshold and map_flux gt 0.d0))
         endelse

         if istokes eq 0 then imrange=[-1,1]/2. else imrange=[-1,1]/100.
;         imview, snr, position=pp[istokes,0,*], /noerase, imr=[-4,4]
;         imview, mask, position=pp[istokes,1,*], /noerase
;         imview, polar_mask, position=pp[istokes,2,*], /noerase
      endfor
;      stop
      
      ;; smooth a bit to take margin
      nk_smooth = round( !nika.fwhm_nom[iext]/map_jk.map_reso)
      k = dblarr(nk_smooth,nk_smooth) + 1.d0/nk_smooth^2
      mask = double( convol( mask, k) gt 0.d0)
      
      ;; Take margin on the edges if requested to avoid working on too
      ;; high variance regions
      if keyword_set(radius_max) then begin
         w = where( sqrt(subtract_maps.xmap^2 + subtract_maps.ymap^2) gt radius_max, nw)
         if nw ne 0 then mask[w] = 0.d0
      endif
   endif ; nhits /= 0
   
   ;; Pass the mask to the output structure
   junk = execute( "subtract_maps.iter_mask_"+strtrim(iext+1,2)+"mm = mask")
   if (defined(polar_mask) and nstokes gt 1) then subtract_maps.polar_mask = polar_mask
   
   ;; Display
   if not keyword_set(noplot) then begin
      imr_1 = [-1,1]*2*stddev(subtract_maps.map_i_1mm)/50.
      imr_2 = [-1,1]*2*stddev(subtract_maps.map_i2)/50.
      if my_plot_window eq 0 then wind, 1, 1, /free, /large
      my_plot_window = !d.window
      my_multiplot, 2, 2, pp, pp1, /rev
      junk = execute( "map = subtract_maps.map_i_"+strtrim(iext+1,2)+"mm")
      junk = execute( "mask = subtract_maps.iter_mask_"+strtrim(iext+1,2)+"mm")
      if iext eq 0 then imr = imr_1 else imr = imr_2
      w = where( map ne 0.d0, nw)
      imview, map, position=pp[iext,0,*], /noerase, title=strtrim(iext+1,2)+$
              'mm (smoothed 5 arcsec) '+title_in, fwhm=5., imr=[-1,1]*stddev(map[w])
      imview, mask, position=pp[iext,1,*], /noerase, title='Mask '+strtrim(iext+1,2)+'mm'
   endif
endfor

if keyword_set(same_mask_at_1_and_2mm) then begin
   mask = double( subtract_maps.iter_mask_1mm or subtract_maps.iter_mask_2mm)
   subtract_maps.iter_mask_1mm = mask
   subtract_maps.iter_mask_2mm = mask
endif


end
