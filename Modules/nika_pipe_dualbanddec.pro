;+
;PURPOSE: Decorrelation of the 2mm channel with the 1mm one
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 
;-

pro nika_pipe_dualbanddec, param, data, kidpar, silent=silent

  N_pt = n_elements(data)
  N1mm = n_elements(kidpar[where(kidpar.array eq 1)])
  N2mm = n_elements(kidpar[where(kidpar.array eq 2)])
  
  won1mm = where(kidpar.type eq 1 and kidpar.array eq 1, Non1mm) 
  won2mm = where(kidpar.type eq 1 and kidpar.array eq 2, Non2mm)
  
  TOI1mm = data.RF_dIdQ[won1mm]
  TOI2mm = data.RF_dIdQ[won2mm]

  ;;---------- Some info is provided
  if not keyword_set(silent) then begin
     if param.decor.common_mode.x_calib eq 'yes' then $
        message,/info,'Atmospheric cross calibration' $
     else message,/info,'No atmospheric cross calibration'
  endif
  
  if param.decor.common_mode.per_subscan ne 'yes' $
     and param.decor.common_mode.per_subscan ne 'no' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  ;;========== Full scan case
  if param.decor.common_mode.per_subscan eq 'no' then begin
     ;;---------- Atmosphere cross calibration KIDs 1mm
     if param.decor.common_mode.x_calib eq 'yes' then $
        atm_x_calib = nika_pipe_atmxcalib(TOI1mm, data.on_source_dec[won1mm]) $
     else atm_x_calib = [[dblarr(Non1mm)], [dblarr(Non1mm)+1]]
     TOI1mm = TOI1mm * (atm_x_calib[*,1] # replicate(1, N_pt))
     TOI1mm = TOI1mm + (atm_x_calib[*,0] # replicate(1, N_pt))

     ;;---------- Get the atmosphere template from 1mm
     if strupcase(param.decor.common_mode.median) ne 'YES' then temp_atmo = total(TOI1mm, 1)/Non1mm $
     else temp_atmo = median(TOI1mm, dim=1)
     
     ;;---------- Remove the atmosphere
     for i=0, Non2mm-1 do begin
        ikid = won2mm[i]
        wfit = where(data.on_source_dec[ikid] ne 1, nwfit)
        
        ;;---------- Case of elevation
        if param.fit_elevation eq 'yes' then begin
           if min(data[wfit].ofs_el) eq max(data[wfit].ofs_el) then no_el = 1 else no_el = 0

           if no_el eq 0 then templates = transpose([[temp_atmo[wfit]], [data[wfit].el], [data[wfit].ofs_el]])
           if no_el eq 1 then templates = transpose([[temp_atmo[wfit]], [data[wfit].el]])
           
           y = reform(TOI2mm[i, wfit])
           coeff = regress(templates, y, CONST=const, YFIT=yfit, status=status)

           if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit] + coeff[1]*data[wfit].el + coeff[2]*data[wfit].ofs_el) else coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit] + coeff[1]*data[wfit].el)

           data.RF_dIdQ[ikid] = reform(TOI2mm[i,*]) - coeff[0]*temp_atmo - coeff[1]*data.el  + coeff_0[0]
           if no_el eq 0 then data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - coeff[2]*data.ofs_el

           ;;---------- Case of no elevation
        endif else begin
           templates = temp_atmo[wfit]
           y = reform(TOI2mm[i, wfit])
           coeff = regress(templates, y, CONST=const, YFIT=yfit, status=status)
           coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit])
           data.RF_dIdQ[ikid] = reform(TOI2mm[i,*]) - (coeff[0]*temp_atmo - coeff_0[0])
        endelse
     endfor
  endif

  ;;========== Case per subscan
  if param.decor.common_mode.per_subscan eq 'yes' then begin ;Common mode is by subscan
     for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
        wsubscan = where(data.subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin

           ;;---------- Atmosphere cross calibration KIDs 1mm
           if param.decor.common_mode.x_calib eq 'yes' then $
              atm_x_calib = nika_pipe_atmxcalib(TOI1mm[*,wsubscan], data[wsubscan].on_source_dec[won1mm]) $
           else atm_x_calib = [[dblarr(Non1mm)], [dblarr(Non1mm)+1]]
           TOIxcal = TOI1mm[*, wsubscan]
           TOIxcal = TOIxcal * (atm_x_calib[*,1] # replicate(1, N_pt))
           TOIxcal = TOIxcal + (atm_x_calib[*,0] # replicate(1, N_pt))
           
           ;;---------- Remove the atmosphere
           for i=0, Non2mm-1 do begin
              ikid = won2mm[i]
              wfit = where(data[wsubscan].on_source_dec[ikid] ne 1, nwfit)
              if nwfit lt 10 then wfit = where(data[wsubscan].on_source_dec[ikid] ne -1, nwfit) ;if no off source take it all
              TOIfit = reform(TOI2mm[i, wsubscan])
              
              ;;---------- Use only most correlated KIDs
              Nmax = param.decor.common_mode.nbloc_min
              if Non1mm lt Nmax then Nmax = Non1mm
              mcorr = correlate([transpose([TOIfit]),[TOIxcal]])
              corr = reform(mcorr[0,1:*])
              s_corr = corr[reverse(sort(corr))]                        ;Sorted by best correlation
              bloc = where(corr gt s_corr[Nmax-1] and corr ne 1, nbloc) ;reject 2/3 of the KIDs
              TOIxcalbis = TOIxcal[bloc,*]

              ;;---------- Get the atmosphere template from 1mm
              if strupcase(param.decor.common_mode.median) ne 'YES' then temp_atmo = total(TOIxcalbis, 1)/Nmax $
              else temp_atmo = median(TOIxcalbis, dim=1)
              
              ;;---------- Case of elevation
              if param.fit_elevation eq 'yes' then begin
                 ofs_el = data[wsubscan].ofs_el
                 el = data[wsubscan].el
                 
                 if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
                 
                 if no_el eq 0 then templates = transpose([[temp_atmo[wfit]], [el[wfit]], [ofs_el[wfit]]])
                 if no_el eq 1 then templates = transpose([[temp_atmo[wfit]], [el[wfit]]])
                 
                 y = reform(TOIfit[wfit])
                 coeff = regress(templates, y, CONST=const, YFIT=yfit, status=status)

                 if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit] + coeff[1]*el[wfit] + coeff[2]*ofs_el[wfit]) else coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit] + coeff[1]*el[wfit])
                 
                 data[wsubscan].RF_dIdQ[ikid] = TOIfit - coeff[0]*temp_atmo - coeff[1]*el  + coeff_0[0]
                 if no_el eq 0 then data[wsubscan].RF_dIdQ[ikid] = data[wsubscan].RF_dIdQ[ikid] - coeff[2]*ofs_el
                 
                 ;;---------- Case of no elevation
              endif else begin
                 templates = temp_atmo[wfit]
                 y = reform(TOIfit[wfit])
                 coeff = regress(templates, y, CONST=const, YFIT=yfit, status=status)
                 coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit])
                 data[wsubscan].RF_dIdQ[ikid] = TOIfit - (coeff[0]*temp_atmo - coeff_0[0])
              endelse
           endfor
        endif                   ;valid subscan
     endfor                     ;loop on subscans
  endif
  
  return
end
