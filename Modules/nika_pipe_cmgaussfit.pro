pro nika_pipe_cmgaussfit, param, TOI, kidpar, data

  N_pt = n_elements(TOI[0,*])
  n_kid = n_elements(TOI[*,0])
  
  w_on = where(kidpar.type eq 1, n_on)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF
  
  ;;Source position from the center (arcsec)
  pos = [-ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 + $
         ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $
         ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) - $
         ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
  
  TOI_in = TOI
  Flag = intarr(n_kid, N_pt) + 1 ;Set to 0 if on source
  TOI_out = dblarr(n_kid, N_pt)
  
  ;;%%%%%%%%%%%%%%% Build the flag %%%%%%%%%%%%%%%
  for ikid=0, n_on-1 do begin
     ;;Flag TOI when too close to the source
;     nika_nasmyth2azel, kidpar[w_on[ikid]].nas_x, kidpar[w_on[ikid]].nas_y, $
;                        0.0, 0.0, data.el*!radeg, dx, dy, $
;                        nas_x_ref=kidpar[w_on[ikid]].nas_center_x, nas_y_ref=kidpar[w_on[ikid]].nas_center_y
;     dx = -dx + data.ofs_az*cos(data.el)
;     dy = -dy + data.ofs_el
;     dra  =  cos(data.paral)*dx + sin(data.paral)*dy ;Scan in 
;     ddec = -sin(data.paral)*dx + cos(data.paral)*dy ;the sky.
     
     nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                           kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                           0., 0., dra, ddec, $
                           nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y

     dist_source = sqrt((ddec - pos[1])^2 + (dra - pos[0])^2) ;Distance from the source
     loc_on = where(dist_source le param.decor.common_mode.d_min, nloc_on)
     if nloc_on ne 0 then Flag[w_on[ikid], loc_on] = 0
  endfor

  temp_atmo = dblarr(N_pt)
  ;;%%%%%%%%%%%%%%% Build the template in the case per subscan %%%%%%%%%%%%%%%
  if param.decor.common_mode.per_subscan eq 'no' then begin
     ;;Atmosphere cross calibration
     atm_x_calib = dblarr(n_on, 2)
     if param.decor.common_mode.x_calib eq 'yes' then begin
        message,/info,'Atmospheric cross calibration'
        for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
           fit = linfit(TOI_in[w_on[jkid],*], TOI_in[w_on[0],*])
           atm_x_calib[jkid,0] = fit[0]
           atm_x_calib[jkid,1] = fit[1]
        endfor
     endif else begin
        message,/info,'No atmospheric cross calibration'
        atm_x_calib[*,0] = 0.0
        atm_x_calib[*,1] = 1.0
     endelse
     ;;Template
     hit = intarr(N_pt)
     for jkid=0, n_on-1 do begin
        temp_atmo += (atm_x_calib[jkid,0] + atm_x_calib[jkid,1]*TOI_in[w_on[jkid], *]) * $
                     Flag[w_on[jkid],*]
        hit += Flag[w_on[jkid],*] ;Number hit in the TOI
     endfor
     loc_hit = where(hit ge 1, nloc_hit)
     if nloc_hit ne N_pt then message,/info, 'Warning, the atmospheric template is not continuous'
     temp_atmo[loc_hit] = temp_atmo[loc_hit]/hit[loc_hit]
  endif
  
  ;;%%%%%%%%%%%%%%% Build the template in the case per subscan %%%%%%%%%%%%%%%
  if param.decor.common_mode.per_subscan eq 'yes' then begin
     temp_atmo = dblarr(N_pt)
     for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
        wsubscan = where(data.subscan eq isubscan, nwsubscan)
        if nwsubscan ne 0 then begin
           ;;Atmosphere cross calibration
           atm_x_calib = dblarr(n_on, 2)
           if param.decor.common_mode.x_calib eq 'yes' then begin
              if isubscan eq 1 then message,/info,'Atmospheric cross calibration'
              for jkid=0, n_on-1 do begin ; auto calib on valid[0] to init atm_x_calib, no problem
                 fit = linfit((TOI_in[w_on[jkid],*])[*,wsubscan], (TOI_in[w_on[0],*])[*,wsubscan])
                 atm_x_calib[jkid,0] = fit[0]
                 atm_x_calib[jkid,1] = fit[1]
              endfor 
           endif else begin
              if isubscan eq 1 and ikid eq 0 then message,/info,'No atmospheric cross calibration'
              atm_x_calib[*,0] = 0.0
              atm_x_calib[*,1] = 1.0
           endelse
           ;;Template
           hit = intarr(nwsubscan)
           for jkid=0, n_on-1 do begin
              temp_atmo[wsubscan] += (atm_x_calib[jkid,0] + atm_x_calib[jkid,1]*TOI_in[w_on[jkid], wsubscan]) * $
                                     Flag[w_on[jkid],wsubscan]
              hit += Flag[w_on[jkid],wsubscan] ;Number hit in the TOI
           endfor
           loc_hit = where(hit ge 1, nloc_hit)
           if nloc_hit ne nwsubscan then message,/info, 'Warning, the atmospheric template is not continuous'
           temp_atmo[wsubscan[loc_hit]] = temp_atmo[loc_hit]/hit[loc_hit]
        endif
     endfor
  endif
  
  ;;%%%%%%%%%%%%%%% Loop for all KIDs %%%%%%%%%%%%%%%
  for ikid=0, n_on-1 do begin
     ;;--------- Case of decorrelation per all timeline
     if param.decor.common_mode.per_subscan eq 'no' then begin
        ;;Templates
        templates = dblarr(2, N_pt)
        templates[0,*] = temp_atmo ;Atmosphere

;        nika_nasmyth2azel, kidpar[w_on[ikid]].nas_x, kidpar[w_on[ikid]].nas_y, $
;                           0.0, 0.0, data.el*!radeg, dx, dy, $
;                           nas_x_ref=kidpar[w_on[ikid]].nas_center_x, nas_y_ref=kidpar[w_on[ikid]].nas_center_y
;        dx = -dx + data.ofs_az*cos(data.el)
;        dy = -dy + data.ofs_el
;        dra  =  cos(data.paral)*dx + sin(data.paral)*dy ;Scan in 
;        ddec = -sin(data.paral)*dx + cos(data.paral)*dy ;the sky.

        nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                              kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                              0., 0., dra, ddec, $
                              nas_x_ref=kidpar[ikid].nas_center_X, nas_y_ref=kidpar[ikid].nas_center_Y

        beam = kidpar[w_on[ikid]].fwhm*!fwhm2sigma
        templates[1,*] = exp(-((ddec - pos[1])^2 + (dra - pos[0])^2)/(2*beam^2)) ;Gaussian template
        
        ;;Decor
        y = reform(TOI_in[w_on[ikid],*])
        coeff = regress(templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                        /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
        TOI_out[w_on[ikid],*] = TOI_in[w_on[ikid],*] - coeff[0]*templates[0,*]
     endif
     
     ;;--------- Decorrelation per subscan
     if param.decor.common_mode.per_subscan eq 'yes' then begin
        for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
           wsubscan = where(data.subscan eq isubscan, nwsubscan)
           if nwsubscan ne 0 then begin
              ;;Templates
              templates = dblarr(2, nwsubscan)
              templates[0,*] = temp_atmo[wsubscan] ;atmo

              nika_nasmyth2azel, kidpar[w_on[ikid]].nas_x, kidpar[w_on[ikid]].nas_y, $
                                 0.0, 0.0, data.el*!radeg, dx, dy, $
                                 nas_x_ref=kidpar[w_on[ikid]].nas_center_x, $
                                 nas_y_ref=kidpar[w_on[ikid]].nas_center_y
              dx = -dx + data.ofs_az*cos(data.el)
              dy = -dy + data.ofs_el
              dra  =  cos(data.paral)*dx + sin(data.paral)*dy ;Scan in 
              ddec = -sin(data.paral)*dx + cos(data.paral)*dy ;the sky.
              beam = kidpar[w_on[ikid]].fwhm*!fwhm2sigma
              gauss = exp(-((ddec - pos[1])^2 + (dra - pos[0])^2)/(2*beam^2)) ;Gaussian template
              templates[1,*] = gauss[wsubscan]
              
              ;;Decorelate from template
              y = reform(TOI_in[w_on[ikid],wsubscan])
              coeff = regress(templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                              /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
              TOI_out[w_on[ikid],wsubscan] = TOI_in[w_on[ikid],wsubscan] - coeff[0]*templates[0,*]
           endif
        endfor
     endif

  endfor  ;;%%%%%%%%%%%%%%% End of the loop for all KIDs %%%%%%%%%%%%%%%


  ;;--------- Case the parameter is not right
  if param.decor.common_mode.per_subscan ne 'yes' $
     and param.decor.common_mode.per_subscan ne 'no' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  TOI = TOI_out

  return
end
