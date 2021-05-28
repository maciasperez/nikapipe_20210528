;+
;PURPOSE: Filter the TOI in order to remove spectral lines and the
;         very low frequency noise.
;
;INPUT: The parameter data and kidpar structures.
;
;OUTPUT: The filters data structure.
;
;LAST EDITION: 
;   17/01/2013: creation (adam@lpsc.in2p3.fr)
;   07/01/2014: use only KID that are not flagged entirely
;-

pro nika_pipe_filter, param, data, kidpar0, check=check

  ;;########## Flag KIDs that should not be used for decorrelation ##########
  kidpar = kidpar0
  w_valid_kid = nika_pipe_kid4cm(param, data, kidpar, Nvalid=nv, complement=w_bad_kid, ncomplement=nw_bad_kid)
  if nw_bad_kid ne 0 then kidpar[w_bad_kid].type = -1 ;We use only Valid On KIDs and eventually Offs tones

  ;;################# Case we filter #################
  if param.filter.apply eq 'yes' then begin
     message,/info, 'The data are filtered'
     N_pt = n_elements(data)
     N_kid = n_elements(kidpar)
     wsource = data.rf_didq * 0 ;default is never on source

     ;;------- If we want to flag the source
     if param.filter.dist_off_source gt 0 then begin
        ;;------- position of the source vs pointing (arcsec_x, arcsec_y)
        pos = [-ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 + $    
               ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0, $ 
               ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) - $
               ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])]*3600.0
        
        ;;----- Get the distance from the source
        for ikid=0, N_kid-1 do begin
           if kidpar[ikid].type eq 1 then begin
              nika_nasmyth2draddec, data.ofs_az, data.ofs_el, data.el, data.paral, $
                                    kidpar[ikid].nas_x, kidpar[ikid].nas_y, $
                                    0., 0., dra, ddec, nas_x_ref=kidpar[ikid].nas_center_X, $
                                    nas_y_ref=kidpar[ikid].nas_center_Y
              
              dist_source = sqrt((ddec - pos[1])^2 + (dra - pos[0])^2)
              on_source = where(dist_source lt param.filter.dist_off_source, n_on_source)
              if n_on_source ne 0 then wsource[ikid, on_source] = 1 
           endif
        endfor
     endif

     if param.filter.cos_sin eq 'yes' then begin
        ;;--------- Case of elevation scans
        if param.scan_type[param.iscan] eq 'otf_elevation' then begin
           for ikid=0, N_kid-1 do begin
              if kidpar[ikid].type eq 1 then begin
                 loc_fit = where(wsource[ikid,*] eq 0, nloc_fit)
                 ;;----- Remove elevation effect
                 if nloc_fit ne 0 then fit = linfit(data[loc_fit].ofs_el, data[loc_fit].RF_dIdQ[ikid])
                 if nloc_fit ne 0 then data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - fit[1]*data.ofs_el - fit[0]
                 ;;----- Remove templates at the subscan frequency
                 t1 = cos(dindgen(N_pt)/(N_pt-1)*2*!pi*max(data.subscan))
                 t2 = sin(dindgen(N_pt)/(N_pt-1)*2*!pi*max(data.subscan))
                 temp = transpose([[t1[loc_fit]],[t2[loc_fit]]])
                 y = reform(data.RF_dIdQ[ikid])
                 if nloc_fit ne 0 then coeff = regress(temp, y[loc_fit], YFIT=yfit)
                 if nloc_fit ne 0 then data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - coeff[0]*t1 - coeff[1]*t2
              endif
           endfor
        endif

        ;;--------- Case of azimuth scan
        if param.scan_type[param.iscan] eq 'otf_azimuth' then begin
           for ikid=0, N_kid-1 do begin
              if kidpar[ikid].type eq 1 then begin
                 ;;----- Fit sin and cosine
                 the_flag = dblarr(N_pt)
                 loc_flag = where(wsource[ikid,*] eq 1, nloc_flag)
                 if nloc_flag ne 0 then the_flag[loc_flag] = 1
                 yfit = lf_sin_fit(data.RF_dIdQ[ikid], the_flag, N_pt/max(data.subscan), 1)
                 data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - yfit
                 ;;----- Remove templates at the subscan frequency
                 for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
                    wsubscan = where(data.subscan eq isubscan, nwsubscan)
                    if nwsubscan gt long(2.5*!nika.f_sampling) then begin
                       loc_fit = where(wsource[ikid,*] eq 0 and data.subscan eq isubscan, nloc_fit)
                       if nloc_fit ne 0 then begin
                          t1 = cos(dindgen(N_pt)/(N_pt-1)*2*!pi*max(data.subscan))
                          t2 = sin(dindgen(N_pt)/(N_pt-1)*2*!pi*max(data.subscan))
                          temp = transpose([[t1[loc_fit]],[t2[loc_fit]]])
                          y = reform(data[loc_fit].RF_dIdQ[ikid])
                          coeff = regress(temp, y, YFIT=yfit)
                          data[wsubscan].RF_dIdQ[ikid] = data[wsubscan].RF_dIdQ[ikid] - $
                                                         coeff[0]*t1[wsubscan] - coeff[1]*t2[wsubscan]
                       endif
                    endif
                 endfor
              endif
           endfor
        endif

        ;;--------- Case of lissajous scan
        if param.scan_type[param.iscan] eq 'lissajous' then begin
           for ikid=0, N_kid-1 do begin
              if kidpar[ikid].type eq 1 then begin
                 loc_fit = where(wsource[ikid,*] eq 0, nloc_fit)
                 ;;----- Remove elevation effect
                 fit = linfit(data.ofs_el, data.RF_dIdQ[ikid], yfit=yfit)
                 data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - yfit
                 ;;----- Remove sin and cos at low freq per subscan
                 for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
                    wsubscan = where(data.subscan eq isubscan, nwsubscan)
                    if nwsubscan gt long(2.5*!nika.f_sampling) then begin
                       loc_fit = where(wsource[ikid,wsubscan] eq 0, nloc_fit)
                       flag_fit = dblarr(nwsubscan)+1                
                       if nloc_fit ne 0 then flag_fit[loc_fit] = 0
                       yfit = lf_sin_fit(data[wsubscan].RF_dIdQ[ikid], flag_fit, nwsubscan, 1)
                       data[wsubscan].RF_dIdQ[ikid] = data[wsubscan].RF_dIdQ[ikid] - yfit
                    endif
                 endfor
              endif
           endfor
        endif
     endif
     
     ;;$$$$$$$$$$$$$$$$$$$ Remove the frequency lines $$$$$$$$$$$$$$$$$$
     for ikid=0, N_kid-1 do begin
        if kidpar[ikid].type eq 1 then begin
           nika_pipe_linefilter, param.filter.low_cut, param.filter.width, param.filter.nsigma, $
                                 param.filter.freq_start, data.RF_dIdQ[ikid], data_clean , check=check
           data.RF_dIdQ[ikid] = data_clean
        endif
     endfor
  endif
  
  ;;################# Case we filter #################
  if param.filter.apply eq 'no' then message,/info, 'No filter applied'
  
  return
end
