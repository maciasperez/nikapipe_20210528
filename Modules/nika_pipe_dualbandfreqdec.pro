;+
;PURPOSE: 140GHz only. Remove low frequency noise from a common-mode
;based on the 240 GHz data and high frequency noise from a common-mode
;based on the 140 GHz data. The other method simple common mode is
;used for the 240 GHz channel
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 2013: creation(adam@lpsc.in2p3.fr)
;              2014/07/09: use nika_pipe_xcal + median + elevation
;-

pro nika_pipe_dualbandfreqdec, param, data, kidpar, silent=silent
  
  ;;========== Some info
  if strupcase(param.decor.common_mode.per_subscan) ne 'YES' $
     and strupcase(param.decor.common_mode.per_subscan) ne 'NO' then begin
     message,/info,"You need to tell me if you want to decorrelate per subscan or all the timeline at once"
     message,/info,"For this, set param.decor.common_mode.per_subscan to 'yes' or 'no'"
     message,"Here param.decor.common_mode.per_subscan = '"+strtrim(param.decor.common_mode.per_subscan,2)+"'"
  endif

  if not keyword_set(silent) then begin
     if param.decor.common_mode.x_calib eq 'yes' then message, /info, "Atmospheric calibration far from the source"
     if param.decor.common_mode.x_calib eq 'no' then message, /info, "No atmospheric cross calibration"
  endif

  ;;========== Some definitions
  N_pt = n_elements(data)

  w1mm = where(kidpar.type eq 1 and kidpar.array eq 1, N1mm)
  w2mm = where(kidpar.type eq 1 and kidpar.array eq 2, N2mm)

  ;;========== Get filtered data
  ;;------- Define the filter
  fc1 = param.decor.common_mode.dbfcut[0]
  fc2 = param.decor.common_mode.dbfcut[1]
  
  npt2 = N_pt/2
  freq = dindgen(npt2+1)/double(npt2) * !nika.f_sampling/2.0 
  if ((N_pt mod 2) eq 0) then freq=[freq, -1*reverse(freq[1:npt2-1])]
  if ((N_pt mod 2) eq 1) then freq=[freq, -1*reverse(freq[1:*])]

  z1 = where(abs(freq) lt fc1)              ;low freq zone
  z2 = where(freq gt fc1 and freq lt fc2)   ;transition at positive low freq
  z3 = where(freq gt -fc2 and freq lt -fc1) ;transition at negative low freq
  z4 = where(abs(freq) gt fc2)              ;high freq zone
  
  filter_lp = dblarr(N_pt)
  filter_lp[z1] = 1.0
  filter_lp[z2] = (cos((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
  filter_lp[z3] = (cos((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2

  filter_hp = dblarr(N_pt)
  filter_hp[z4] = 1.0
  filter_hp[z2] = (sin((!pi/2)*(freq[z2]-fc1)/(fc2-fc1)))^2
  filter_hp[z3] = (sin((!pi/2)*(freq[z3]+fc1)/(fc2-fc1)))^2

  ;;------- Get the FFT and TOI filtered
  TOI1mm_lp = dblarr(N1mm,N_pt)
  TOI1mm_hp = dblarr(N1mm,N_pt)     
  TOI2mm_lp = dblarr(N2mm,N_pt)
  TOI2mm_hp = dblarr(N2mm,N_pt)

  for ikid=0, N1mm-1 do begin
     FT = FFT(data.RF_dIdQ[w1mm[ikid]] - mean(data.RF_dIdQ[w1mm[ikid]]), 1)
     TOI1mm_lp[ikid,*] = double(FFT(FT * filter_lp,-1))
     TOI1mm_hp[ikid,*] = double(FFT(FT * filter_hp,-1))
  endfor

  for ikid=0, N2mm-1 do begin
     FT = FFT(data.RF_dIdQ[w2mm[ikid]] - mean(data.RF_dIdQ[w2mm[ikid]]), 1)
     TOI2mm_lp[ikid,*] = double(FFT(FT * filter_lp,-1))
     TOI2mm_hp[ikid,*] = double(FFT(FT * filter_hp,-1))
  endfor
  
  ;;========== Decorrelation of the data in case of full scan
  if param.decor.common_mode.per_subscan eq 'no' then begin
     ;;---------- Build Low Pass 1mm common-mode
     if param.decor.common_mode.x_calib eq 'yes' then $
        xcal_lp = nika_pipe_atmxcalib(TOI1mm_lp, data.on_source_dec[w1mm]) $
     else xcal_lp = [[dblarr(n_elements(N1mm))], [dblarr(n_elements(N1mm))+1]]
     
     TOI_xcal = TOI1mm_lp
     TOI_xcal = TOI_xcal * (xcal_lp[*,1] # replicate(1, N_pt))
     TOI_xcal = TOI_xcal + (xcal_lp[*,0] # replicate(1, N_pt))
     
     if strupcase(param.decor.common_mode.median) ne 'YES' then temp_lp = total(TOI_xcal, 1)/N1mm $
     else temp_lp = median(TOI_xcal, dim=1)
     
     ;;---------- Build High Pass 2mm common-mode
     if param.decor.common_mode.x_calib eq 'yes' then $
        xcal_hp = nika_pipe_atmxcalib(TOI2mm_hp, data.on_source_dec[w2mm]) $
     else xcal_hp = [[dblarr(n_elements(N2mm))], [dblarr(n_elements(N2mm))+1]]
     
     TOI_xcal = TOI2mm_hp
     TOI_xcal = TOI_xcal * (xcal_hp[*,1] # replicate(1, N_pt))
     TOI_xcal = TOI_xcal + (xcal_hp[*,0] # replicate(1, N_pt))
     
     if strupcase(param.decor.common_mode.median) ne 'YES' then temp_hp = total(TOI_xcal, 1)/N2mm $
     else temp_hp = median(TOI_xcal, dim=1)
     
     ;;---------- Remove the atmosphere
     for i=0, N2mm-1 do begin
        ikid = w2mm[i]
        wfit = where(data.on_source_dec[ikid] ne 1, nwfit)
        
        if param.fit_elevation eq 'yes' then begin
           ;;---------- Case of elevation
           if min(data[wfit].ofs_el) eq max(data[wfit].ofs_el) then no_el = 1 else no_el = 0
           
           if no_el eq 0 then templates = transpose([[temp_hp[wfit]], [temp_lp[wfit]], $
                                                     [data[wfit].el], [data[wfit].ofs_el]])
           if no_el eq 1 then templates = transpose([[temp_hp[wfit]], [temp_lp[wfit]], [data[wfit].el]])
           
           y = reform(data[wfit].RF_dIdQ[ikid])
           coeff = regress(templates, y, CONST=const, YFIT=yfit)

           if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*temp_hp[wfit] + coeff[1]*temp_lp[wfit] + $
                                               coeff[2]*data[wfit].el + coeff[3]*data[wfit].ofs_el) $
           else coeff_0 = linfit(yfit, coeff[0]*temp_hp[wfit] + coeff[1]*temp_lp[wfit] + coeff[2]*data[wfit].el)

           data.RF_dIdQ[ikid] = reform(data.RF_dIdQ[ikid]) - coeff[0]*temp_hp - coeff[1]*temp_lp - $
                                coeff[2]*data.el  + coeff_0[0]
           if no_el eq 0 then data.RF_dIdQ[ikid] = data.RF_dIdQ[ikid] - coeff[3]*data.ofs_el
        endif else begin
           ;;---------- Case of no elevation
           templates = transpose([[temp_hp[wfit]], [temp_lp[wfit]]])
           
           y = reform(data[wfit].RF_dIdQ[ikid])
           coeff = regress(templates, y, CONST=const, YFIT=yfit)

           coeff_0 = linfit(yfit, coeff[0]*temp_hp[wfit] + coeff[1]*temp_lp[wfit])

           data.RF_dIdQ[ikid] = reform(data.RF_dIdQ[ikid]) - coeff[0]*temp_hp - coeff[1]*temp_lp + coeff_0[0]
        endelse
     endfor
  endif

  ;;========== Decorrelation of the data in case of full scan
  if param.decor.common_mode.per_subscan eq 'yes' then begin        
     ;;---------- Loop over subscans
     for isubscan=(min(data.subscan)>0), max(data.subscan) do begin
        wsubscan = where(data.subscan eq isubscan, nwsubscan)
        if nwsubscan gt long(2.5*!nika.f_sampling) then begin
           ;;---------- Build Low Pass 1mm common-mode
           if param.decor.common_mode.x_calib eq 'yes' then $
              xcal_lp = nika_pipe_atmxcalib(TOI1mm_lp[*, wsubscan], data[wsubscan].on_source_dec[w1mm]) $
           else xcal_lp = [[dblarr(n_elements(N1mm))], [dblarr(n_elements(N1mm))+1]]
           
           TOI_xcal = TOI1mm_lp[*, wsubscan]
           TOI_xcal = TOI_xcal * (xcal_lp[*,1] # replicate(1, N_pt))
           TOI_xcal = TOI_xcal + (xcal_lp[*,0] # replicate(1, N_pt))
           
           if strupcase(param.decor.common_mode.median) ne 'YES' then temp_lp = total(TOI_xcal, 1)/N1mm $
           else temp_lp = median(TOI_xcal, dim=1)
           
           ;;---------- Build High Pass 2mm common-mode
           if param.decor.common_mode.x_calib eq 'yes' then $
              xcal_hp = nika_pipe_atmxcalib(TOI2mm_hp[*, wsubscan], data[wsubscan].on_source_dec[w2mm]) $
           else xcal_hp = [[dblarr(n_elements(N2mm))], [dblarr(n_elements(N2mm))+1]]
           
           TOI_xcal = TOI2mm_hp[*, wsubscan]
           TOI_xcal = TOI_xcal * (xcal_hp[*,1] # replicate(1, N_pt))
           TOI_xcal = TOI_xcal + (xcal_hp[*,0] # replicate(1, N_pt))
           
           if strupcase(param.decor.common_mode.median) ne 'YES' then temp_hp = total(TOI_xcal, 1)/N2mm $
           else temp_hp = median(TOI_xcal, dim=1)
           
           ;;---------- Remove the atmosphere
           for i=0, N2mm-1 do begin
              ikid = w2mm[i]
              wfit = where(data[wsubscan].on_source_dec[ikid] ne 1, nwfit)
              TOIfit = reform(data[wsubscan].RF_dIdQ[ikid])

              if param.fit_elevation eq 'yes' then begin
                 ;;---------- Case of elevation
                 ofs_el = data[wsubscan].ofs_el
                 el = data[wsubscan].el

                 if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
                 
                 if no_el eq 0 then templates = transpose([[temp_hp[wfit]], [temp_lp[wfit]], $
                                                           [el[wfit]], [ofs_el[wfit]]])
                 if no_el eq 1 then templates = transpose([[temp_hp[wfit]], [temp_lp[wfit]], [el[wfit]]])
                 
                 y = reform(TOIfit[wfit])

                 coeff = regress(templates, y, CONST=const, YFIT=yfit)
                 
                 if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*temp_hp[wfit] + coeff[1]*temp_lp[wfit] + $
                                                     coeff[2]*el[wfit] + coeff[3]*ofs_el[wfit]) $
                 else coeff_0 = linfit(yfit, coeff[0]*temp_hp[wfit] + coeff[1]*temp_lp[wfit] + coeff[2]*el[wfit])

                 data[wsubscan].RF_dIdQ[ikid] = reform(data[wsubscan].RF_dIdQ[ikid]) $
                                                - coeff[0]*temp_hp - coeff[1]*temp_lp $
                                                - coeff[2]*el  + coeff_0[0]
                 if no_el eq 0 then data[wsubscan].RF_dIdQ[ikid] = data[wsubscan].RF_dIdQ[ikid] - coeff[3]*ofs_el
              endif else begin
                 ;;---------- Case of no elevation
                 templates = transpose([[temp_hp[wfit]], [temp_lp[wfit]]])
                 
                 y = reform(TOIfit[wfit])
                 coeff = regress(templates, y, CONST=const, YFIT=yfit)

                 coeff_0 = linfit(yfit, coeff[0]*temp_hp[wfit] + coeff[1]*temp_lp[wfit])

                 data[wsubscan].RF_dIdQ[ikid] = reform(data[wsubscan].RF_dIdQ[ikid]) $
                                                - coeff[0]*temp_hp - coeff[1]*temp_lp + coeff_0[0]
              endelse
           endfor
        endif
     endfor
  endif

  return
end
