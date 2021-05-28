pro nika_pipe_cmkidfar, param, TOI, kidpar, subscan, wsource, elevation, ofs_el

  N_pt = n_elements(TOI[0,*])
  n_kid = n_elements(TOI[*,0])
  
  w_on = where(kidpar.type eq 1, n_on)   ;Number of detector ON
  w_off = where(kidpar.type eq 2, n_off) ;Number of detector OFF
  
  TOI_in = TOI
  TOI_out = dblarr(n_kid, N_pt)

  ;;%%%%%%%%%%%%%%% Loop for all KIDs %%%%%%%%%%%%%%%
  for ikid=0, n_on-1 do begin
     ;;get the kids in a given radius
     distance = sqrt((kidpar[w_on].nas_x - kidpar[w_on[ikid]].nas_x)^2 $
                     + (kidpar[w_on].nas_y - kidpar[w_on[ikid]].nas_y)^2)
     kid_ok = where(distance ge param.decor.common_mode.d_min, nkid_ok) ; KIDs far enough

     ;;--------- Case of decorrelation per all timeline
     if param.decor.common_mode.per_subscan eq 'no' then begin

        ;;Atmosphere cross calibration
        if param.decor.common_mode.x_calib eq 'yes' then $
           atm_x_calib = nika_pipe_atmxcalib(TOI_in[w_on,*], wsource[w_on, *]) $
        else atm_x_calib = [[dblarr(n_elements(n_on))], [dblarr(n_elements(n_on))+1]]
        
        ;;Get the atmosphere template
        TOI_xcal = TOI[w_on, *]
        TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, N_pt))
        TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, N_pt))
        temp_atmo = median(TOI_xcal, dim=1)
        
        ;;Decor
        templates = transpose([[temp_atmo], [elevation], [ofs_el]])
        y = reform(TOI_in[w_on[ikid],*])
        coeff = regress(templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                        /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
        TOI_out[w_on[ikid],*] = TOI_in[w_on[ikid],*] - reform(yfit)
     endif
     
     ;;--------- Decorrelation per subscan
     if param.decor.common_mode.per_subscan eq 'yes' then begin
        
        for isubscan=(min(subscan)>0), max(subscan) do begin
           wsubscan = where(subscan eq isubscan, nwsubscan)
           if nwsubscan ne 0 then begin
              
              ;;Atmosphere cross calibration
              if param.decor.common_mode.x_calib eq 'yes' then $
                 atm_x_calib = nika_pipe_atmxcalib((TOI_in[w_on,*])[*,wsubscan], (wsource[w_on, *])[*,wsubscan]) $
              else atm_x_calib = [[dblarr(n_elements(n_on))], [dblarr(n_elements(n_on))+1]]
              
              ;;Get the atmosphere template
              TOI_xcal = (TOI[w_on, *])[*,wsubscan]
              TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, nwsubscan))
              TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, nwsubscan))
              temp_atmo = median(TOI_xcal, dim=1)
        

              ;;Decorelate from template
              templates = transpose([[temp_atmo], [elevation[wsubscan]], [ofs_el[wsubscan]]])
              y = reform(TOI_in[w_on[ikid],wsubscan])
              coeff = regress(templates, y,  CHISQ= chi, CONST= const, CORRELATION= corr, $
                              /DOUBLE, FTEST=ftest, MCORRELATION=mcorr, SIGMA=sigma, STATUS=status, YFIT=yfit)
              TOI_out[w_on[ikid],wsubscan] = TOI_in[w_on[ikid],wsubscan] - reform(yfit)
           endif
        endfor
        
     endif

     ;;--------- Case the parameter is not right
     if param.decor.common_mode.per_subscan ne 'yes' $
        and param.decor.common_mode.per_subscan ne 'no' then begin
        message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
        message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
        message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
     endif

  endfor                        ;%%%%%%%%%%%%%%% End loop for all KIDs %%%%%%%%%%%%%%%

  TOI = TOI_out

  return
end
