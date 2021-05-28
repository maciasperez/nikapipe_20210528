;+
;PURPOSE: Dual-band decorrelation from a principal component analysis
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 08/07/2014 start over
;-

pro nika_pipe_pca2banddec, param, data, kidpar

  Ncomp = param.decor.common_mode.Ncomp
  
  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)

  w1 = where(kidpar.type eq 1, nw1)

  TOI = data.rf_didq[w1]
  
  ;;========== Case of the principal component built from the whole scan
  if param.decor.common_mode.per_subscan eq 'no' then begin
     ;;---------- Atmosphere cross calibration
     if param.decor.common_mode.x_calib eq 'yes' then $
        atm_x_calib = nika_pipe_atmxcalib(TOI, data.on_source_dec[w1]) $
     else atm_x_calib = [[dblarr(n_elements(nw1))], [dblarr(n_elements(nw1))+1]]
     
     TOI_xcal = TOI
     TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, N_pt))
     TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, N_pt))
     
     pca = PCOMP(TOI_xcal)
     
     for ikid=0, nw1-1 do begin
        jkid = w1[ikid]
        wfit = where(data.on_source_dec[jkid] ne 1, nwfit)

        if param.fit_elevation eq 'yes' then begin
           ;;---------- Case of elevation
           ofs_el = data.ofs_el
           elev = data.el
           if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0

           ;;----- Get the template
           if no_el eq 0 then templates = transpose([[reform(transpose((pca[0:Ncomp-1,*])[*, wfit]))], $
                                                     [elev[wfit]], [ofs_el[wfit]]])
           if no_el eq 1 then templates = transpose([[reform(transpose((pca[0:Ncomp-1,*])[*, wfit]))], [elev[wfit]]])
           y = reform(TOI[ikid, wfit])

           ;;----- Regression on wfit
           coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
           bf_temp = coeff[0]*pca[0,wfit]
           for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,wfit]
           bf_temp += coeff[i]*elev[wfit]
           if no_el eq 0 then bf_temp += coeff[i+1]*ofs_el[wfit]

           coeff_0 = linfit(yfit, bf_temp)
           
           bf_temp = coeff[0]*pca[0,*]
           for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,*]
           bf_temp += coeff[i]*elev
           if no_el eq 0 then bf_temp += coeff[i+1]*ofs_el

           DATA.RF_DIDQ[jkid] = DATA.RF_DIDQ[jkid] - bf_temp + coeff_0[0]
        endif else begin
           ;;---------- Case of no elevation
           templates = reform((pca[0:Ncomp-1,*])[*, wfit])
           y = reform(TOI[ikid, wfit])

           ;;----- Regression on wfit
           coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
           bf_temp = coeff[0]*pca[0,wfit]
           for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,wfit]

           coeff_0 = linfit(yfit, bf_temp)
           
           bf_temp = coeff[0]*pca[0,*]
           for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,*]

           DATA.RF_DIDQ[jkid] = DATA.RF_DIDQ[jkid] - bf_temp + coeff_0[0]
        endelse
     endfor  
  endif

  ;;========== Case of the principal component built from subscan
  if param.decor.common_mode.per_subscan eq 'yes' then begin
     for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
        wsubscan = where(data.subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           ;;---------- Atmosphere cross calibration
           if param.decor.common_mode.x_calib eq 'yes' then $
              atm_x_calib = nika_pipe_atmxcalib(TOI[*, wsubscan], data[wsubscan].on_source_dec[w1]) $
           else atm_x_calib = [[dblarr(n_elements(nw1))], [dblarr(n_elements(nw1))+1]]
           
           TOI_xcal = TOI[*, wsubscan]
           TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, N_pt))
           TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, N_pt))
           
           pca = PCOMP(TOI_xcal)
           
           for ikid=0, nw1-1 do begin
              jkid = w1[ikid]
              wfit = where(data[wsubscan].on_source_dec[jkid] ne 1, nwfit)

              if param.fit_elevation eq 'yes' then begin
                 ;;---------- Case of elevation
                 ofs_el = data[wsubscan].ofs_el
                 elev = data[wsubscan].el
                 if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0

                 ;;----- Get the template
                 if no_el eq 0 then templates = transpose([[reform(transpose((pca[0:Ncomp-1,*])[*, wfit]))], $
                                                           [elev[wfit]],[ofs_el[wfit]]])
                 if no_el eq 1 then templates = transpose([[reform(transpose((pca[0:Ncomp-1,*])[*, wfit]))], $
                                                           [elev[wfit]]])
                 y = reform((TOI[ikid, wsubscan])[wfit])

                 ;;----- Regression on wfit
                 coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
                 bf_temp = coeff[0]*pca[0,wfit]
                 for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,wfit]
                 bf_temp += coeff[i]*elev[wfit]
                 if no_el eq 0 then bf_temp += coeff[i+1]*ofs_el[wfit]

                 coeff_0 = linfit(yfit, bf_temp)
           
                 bf_temp = coeff[0]*pca[0,*]
                 for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,*]
                 bf_temp += coeff[i]*elev
                 if no_el eq 0 then bf_temp += coeff[i+1]*ofs_el

                 DATA[wsubscan].RF_DIDQ[jkid] = DATA[wsubscan].RF_DIDQ[jkid] - bf_temp + coeff_0[0]
              endif else begin
                 ;;---------- Case of no elevation
                 templates = reform((pca[0:Ncomp-1,*])[*, wfit])
                 y = reform((TOI[ikid, wsubscan])[wfit])

                 ;;----- Regression on wfit
                 coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
                 bf_temp = coeff[0]*pca[0,wfit]
                 for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,wfit]

                 coeff_0 = linfit(yfit, bf_temp)
                 
                 bf_temp = coeff[0]*pca[0,*]
                 for i=1,Ncomp-1 do bf_temp += coeff[i]*pca[i,*]

                 DATA[wsubscan].RF_DIDQ[jkid] = DATA[wsubscan].RF_DIDQ[jkid] - bf_temp + coeff_0[0]
              endelse
           endfor  
        endif                   ;valid subscan
     endfor                     ;loop on subscans
  endif

  return
end
