;+
;PURPOSE: Single band decorrelation from a principal component analysis
;
;INPUT: The parameter, data and kidpar structures
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: 03/01/2014: creation(adam@lpsc.in2p3.fr)
;-

pro nika_pipe_pca1banddec, param, data, kidpar

  N_comp = param.decor.pca.Ncomp
  
  N_pt = n_elements(data)
  N_kid = n_elements(kidpar)
  subscan = data.subscan

  w1mm = where(kidpar.type eq 1 and kidpar.array eq 1, n1mm)
  w2mm = where(kidpar.type eq 1 and kidpar.array eq 2, n2mm)

  toi1mm = data.rf_didq[w1mm]
  toi2mm = data.rf_didq[w2mm]

  for ikid=0, n1mm-1 do toi1mm[ikid,*] -= mean(toi1mm[ikid,*]) 
  for ikid=0, n2mm-1 do toi2mm[ikid,*] -= mean(toi2mm[ikid,*]) 
  
  ;;------- Case of the principal component built from the whole scan
  if param.decor.pca.pca_subscan eq 'no' then begin
     pca_scan1mm = PCOMP(toi1mm)
     pca_scan2mm = PCOMP(toi1mm)

     ;;------- Decorrelation for the entire scan
     if param.decor.pca.dec_subscan eq 'no' then begin
        for ikid=0, n1mm-1 do begin
           y = reform(toi1mm[ikid,*])
           templates = reform(pca_scan1mm[0:N_comp-1,*])
           coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
           DATA.RF_DIDQ[w1mm[ikid]] -= yfit 
           DATA.RF_DIDQ[w1mm[ikid]] -= mean(DATA.RF_DIDQ[w1mm[ikid]])
        endfor  
        for ikid=0, n2mm-1 do begin
           y = reform(toi2mm[ikid,*])
           templates = reform(pca_scan2mm[0:N_comp-1,*])
           coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
           DATA.RF_DIDQ[w2mm[ikid]] -= yfit 
           DATA.RF_DIDQ[w2mm[ikid]] -= mean(DATA.RF_DIDQ[w2mm[ikid]])
        endfor  
     endif

     ;;------- Decorrelation per subscan
     if param.decor.pca.dec_subscan eq 'yes' then begin
        for isubscan=(min(subscan)>0), max(subscan) do begin
           wsubscan = where(subscan eq isubscan, nwsubscan)
           if nwsubscan ne 0 then begin
              for ikid=0, n1mm-1 do begin
                 y = reform((toi1mm[ikid,*])[wsubscan])
                 templates = pca_scan1mm[0:N_comp-1,wsubscan]
                 coeff = regress(templates, y, /DOUBLE, yfit=yfit)
                 data[wsubscan].RF_dIdQ[w1mm[ikid]] = y - yfit
                 data[wsubscan].RF_dIdQ[w1mm[ikid]] -= mean(data[wsubscan].RF_dIdQ[w1mm[ikid]])
              endfor
              for ikid=0, n2mm-1 do begin
                 y = reform((toi2mm[ikid,*])[wsubscan])
                 templates = pca_scan2mm[0:N_comp-1,wsubscan]
                 coeff = regress(templates, y, /DOUBLE, yfit=yfit)
                 data[wsubscan].RF_dIdQ[w2mm[ikid]] = y - yfit
                 data[wsubscan].RF_dIdQ[w2mm[ikid]] -= mean(data[wsubscan].RF_dIdQ[w2mm[ikid]])
              endfor
           endif                ;valid subscan
        endfor                  ;loop on subscans
     endif

  endif

  ;;------- Case of the principal component built from subscan
  if param.decor.pca.pca_subscan eq 'yes' then begin
     if param.decor.pca.dec_subscan eq 'no' then message, 'You cannot build the pca per subscan and decorrelate the entire scan at once. Change param.decor.pca.pca_subscan to "no" or param.decor.pca.dec_subscan to "yes"'

     for isubscan=(min(subscan)>0), max(subscan) do begin
        wsubscan = where(subscan eq isubscan, nwsubscan)
        if nwsubscan ne 0 then begin
           toi_ss1mm = data[wsubscan].rf_didq[w1mm]
           toi_ss2mm = data[wsubscan].rf_didq[w2mm]
           for ikid=0, n1mm-1 do toi_ss1mm[ikid,*] -= mean(toi_ss1mm[ikid,*]) 
           for ikid=0, n2mm-1 do toi_ss2mm[ikid,*] -= mean(toi_ss2mm[ikid,*]) 
           pca_ss1mm = PCOMP(toi_ss1mm)
           pca_ss2mm = PCOMP(toi_ss2mm)

           for ikid=0, n1mm-1 do begin
              y = reform(toi_ss1mm[ikid,*])
              templates = reform(pca_ss1mm[0:N_comp-1,*])
              coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
              DATA[wsubscan].RF_DIDQ[w1mm[ikid]] -= yfit
              DATA[wsubscan].RF_DIDQ[w1mm[ikid]] -= mean(DATA[wsubscan].RF_DIDQ[w1mm[ikid]])
           endfor
           for ikid=0, n2mm-1 do begin
              y = reform(toi_ss2mm[ikid,*])
              templates = reform(pca_ss2mm[0:N_comp-1,*])
              coeff = regress(templates, y, /DOUBLE, YFIT=yfit)
              DATA[wsubscan].RF_DIDQ[w2mm[ikid]] -= yfit
              DATA[wsubscan].RF_DIDQ[w2mm[ikid]] -= mean(DATA[wsubscan].RF_DIDQ[w2mm[ikid]])
           endfor
        endif                   ;valid subscan
     endfor                     ;loop on subscans

  endif


  return
end
