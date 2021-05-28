pro nika_pipe_cmkidoutmap, param, data, kidpar
baseline = data.rf_didq*0.d0

  ;;------- Sanity check
  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin

     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"

  endif else begin

     ;;------- Source position from the center (arcsec)
     pos = [-ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0 + $
            ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $
            ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2]) - $
            ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
     
     ;;------- Define variables
     N_pt  = n_elements( data)
     n_kid = n_elements( kidpar)
     w1    = where( kidpar.type eq 1, nw1)   ; Number of detector ON
     w_off = where( kidpar.type eq 2, n_off) ; Number of detector OFF
     
     ;;------- Extract the flagging maps
     map_flux_1mm = mrdfits(param.decor.common_mode.map_guess1mm, 0, header1mm)
     map_flux_2mm = mrdfits(param.decor.common_mode.map_guess2mm, 0, header2mm)
     map_noise_1mm = mrdfits(param.decor.common_mode.map_guess1mm, 2, header1mm)
     map_noise_2mm = mrdfits(param.decor.common_mode.map_guess2mm, 2, header2mm)

     EXTAST, header1mm, astr1mm
     EXTAST, header2mm, astr2mm
     reso_guess1mm = astr1mm.cdelt[1]*3600
     reso_guess2mm = astr2mm.cdelt[1]*3600
     nx1mm = astr1mm.naxis[0]
     ny1mm = astr1mm.naxis[1]
     nx2mm = astr2mm.naxis[0]
     ny2mm = astr2mm.naxis[1]
     
     lnan_1mm = where(finite(map_noise_1mm) ne 1 or map_noise_1mm le 0, nlnan_1mm)
     lnan_2mm = where(finite(map_noise_2mm) ne 1 or map_noise_2mm le 0, nlnan_2mm)
     if nlnan_1mm ne 0 then map_noise_1mm[lnan_1mm] = max(map_noise_1mm, /nan)*100
     if nlnan_2mm ne 0 then map_noise_2mm[lnan_2mm] = max(map_noise_2mm, /nan)*100
     map_noise_1mm = filter_image(map_noise_1mm, fwhm=param.decor.common_mode.relob.a/reso_guess1mm ,/all)
     map_noise_2mm = filter_image(map_noise_2mm, fwhm=param.decor.common_mode.relob.b/reso_guess2mm ,/all)
     map_flux_1mm = filter_image(map_flux_1mm, fwhm=param.decor.common_mode.relob.a/reso_guess1mm ,/all)
     map_flux_2mm = filter_image(map_flux_2mm, fwhm=param.decor.common_mode.relob.b/reso_guess2mm ,/all)
          
     if param.decor.common_mode.flag_type eq 'snr' then begin
        fact1mm = stddev(filter_image(randomn(seed,nx1mm,ny1mm), $
                                      FWHM=param.decor.common_mode.relob.a/reso_guess1mm, /all))
        fact2mm = stddev(filter_image(randomn(seed,nx2mm,ny2mm), $
                                      FWHM=param.decor.common_mode.relob.b/reso_guess2mm, /all))
        map_guess_1mm = map_flux_1mm/map_noise_1mm/fact1mm
        map_guess_2mm = map_flux_2mm/map_noise_2mm/fact2mm
     endif
     if param.decor.common_mode.flag_type eq 'flux' then begin
        ln_1mm = where(map_noise_1mm gt 4*min(map_noise_1mm), nln_1mm)
        ln_2mm = where(map_noise_2mm gt 4*min(map_noise_2mm), nln_2mm)
        if nln_1mm ne 0 then map_flux_1mm[ln_1mm] = 0
        if nln_2mm ne 0 then map_flux_2mm[ln_2mm] = 0
        map_guess_1mm = map_flux_1mm
        map_guess_2mm = map_flux_2mm
     endif

     ;;------- Correction if projection already radec
     if strupcase(param.projection.type) eq "PROJECTION" then begin        
        alpha = data.paral
        daz =  -cos(alpha)*data.ofs_az - sin(alpha)*data.ofs_el
        del =  -sin(alpha)*data.ofs_az + cos(alpha)*data.ofs_el

        mean_dec_pointing=ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])
        correction = cos(mean_dec_pointing*!pi/180.0)

     endif else begin
        daz = data.ofs_az
        del = data.ofs_el
        correction = 1.0
     endelse
       ; window, 0, xsize=600, ysize=600

     ;;------- Determine if kids are "on" or "off source"
     w8source = data.rf_didq*0.d0 + 1.d0 ; Set to 0 if "on source"
     for i=0, nw1-1 do begin
        ikid = w1[i]
        nika_nasmyth2draddec, daz, del, data.el, data.paral, $
                              kidpar[ikid].nas_x,kidpar[ikid].nas_y, 0., 0., $
                              dra,ddec,nas_x_ref=kidpar[ikid].nas_center_X,nas_y_ref=kidpar[ikid].nas_center_Y
        dra = dra - pos[0]*correction
        ddec = ddec - pos[1]
        
        case kidpar[ikid].array of
           1: begin 
              map_guess = map_guess_1mm
              flag_lim = param.decor.common_mode.flag_lim[0]
              reso_guess = reso_guess1mm
           end
           2: begin map_guess = map_guess_2mm
              flag_lim = param.decor.common_mode.flag_lim[1]
              reso_guess = reso_guess2mm
           end
        endcase
        source = simu_map2toi(map_guess, reso_guess, dra, ddec)
        if flag_lim ge 0 then loc_on = where(source gt flag_lim, nloc_on)
        if flag_lim lt 0 then loc_on = where(source lt flag_lim, nloc_on)
        if nloc_on ne 0 then w8source[ikid, loc_on] = 0

        ;;ind = dindgen(n_elements(data))
        ;;plot, ind, source
        ;;oplot, ind[loc_on], source[loc_on], col=250, psym=1

        ;if i eq 0 then plot, dra, ddec, xr=[-500,500], yr=[-500,500], /nodata
        ;oplot, dra, ddec
        ;oplot, dra[loc_on], ddec[loc_on], col=250, psym=1

     endfor

     if param.decor.common_mode.x_calib eq 'yes' then message,/info,"Atmospheric calibration far from the source"
     
     if param.decor.common_mode.per_subscan eq 'no' then begin
      ;; Build the atmosphere template on the entire scan
           arr1mm = where(kidpar.array eq 1)
           arr2mm = where(kidpar.array eq 2)
           rf_didq_a = data.rf_didq[arr1mm]
           rf_didq_b = data.rf_didq[arr2mm]
           kidpar_a = kidpar[arr1mm]
           kidpar_b = kidpar[arr2mm]
           w8source_a = w8source[arr1mm,*]
           w8source_b = w8source[arr2mm,*]
           nika_pipe_subtract_common_atm, param, rf_didq_a, kidpar_a, w8source_a, temp_atm_a, base_a
           nika_pipe_subtract_common_atm, param, rf_didq_b, kidpar_b, w8source_b, temp_atm_b, base_b
           data.rf_didq[arr1mm] = rf_didq_a
           data.rf_didq[arr2mm] = rf_didq_b
           for ia=0, n_elements(arr1mm)-1 do baseline[arr1mm[ia],*] = base_a[ia,*]
           for ib=0, n_elements(arr2mm)-1 do baseline[arr2mm[ib],*] = base_b[ib,*]
   endif else begin
      ;; Build the atmosphere template subscan by subscan
      for isubscan=1, max(data.subscan) do begin
         wsubscan = where( data.subscan eq isubscan, nwsubscan)
         if nwsubscan ne 0 then begin
            arr1mm = where(kidpar.array eq 1)
            arr2mm = where(kidpar.array eq 2)
            rf_didq_a = data[wsubscan].rf_didq[arr1mm]
            rf_didq_b = data[wsubscan].rf_didq[arr2mm]
            kidpar_a = kidpar[arr1mm]
            kidpar_b = kidpar[arr2mm]
            w8source_a = (w8source[arr1mm,*])[*,wsubscan]
            w8source_b = (w8source[arr2mm,*])[*,wsubscan]
            nika_pipe_subtract_common_atm, param, rf_didq_a, kidpar_a, w8source_a, temp_atm_a, base_a
            nika_pipe_subtract_common_atm, param, rf_didq_b, kidpar_b, w8source_b, temp_atm_b, base_b
            data[wsubscan].rf_didq[arr1mm] = rf_didq_a
            data[wsubscan].rf_didq[arr2mm] = rf_didq_b
            for ia=0, n_elements(arr1mm)-1 do baseline[arr1mm[ia],wsubscan] = base_a[ia,*]
            for ib=0, n_elements(arr2mm)-1 do baseline[arr2mm[ib],wsubscan] = base_b[ib,*]
         endif
      endfor

   endelse
endelse


end
