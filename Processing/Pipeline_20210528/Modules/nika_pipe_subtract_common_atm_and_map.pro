;+
;PURPOSE: Similar as nika_pipe_subtract_common_atm.pro but also
;         subtract the first estimate of the map itself
;
;INPUT: the param structure, the TOI, the estimated TOI, the kidpar,
;the scan/subscan position the source position
;
;OUTPUT: The decorrelated data structure.
;
;LAST EDITION: - 2014/07/06: use nika_pipe_atmxcal.pro
;              - 2015/07/12: subtract TOI_est before cross
;                calibration
;-

pro nika_pipe_subtract_common_atm_and_map, param, TOI, TOI_est, kidpar, wsubscan, w8source, $
   temp_atmo, base, $
   elev=elev, ofs_el=ofs_el, k_median=k_median

  w1 = where(kidpar.type eq 1, nw1)
  nwsubscan = n_elements(wsubscan)

  base = TOI*0
  
  ;;========== Atmosphere cross calibration
  if param.decor.common_mode.x_calib eq 'yes' then $
     atm_x_calib = nika_pipe_atmxcalib(TOI[w1,*], 1-w8source[w1, *]) $
  else atm_x_calib = [[dblarr(n_elements(nw1))], [dblarr(n_elements(nw1))+1]]
  
  ;;========== Common-mode built
  TOI_xcal = TOI[w1, *] - TOI_est[w1, *]
  TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, nwsubscan))
  TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, nwsubscan))

  if not keyword_set(k_median) then temp_atmo = total(TOI_xcal, 1)/nw1 $
  else temp_atmo = median(TOI_xcal, dim=1)
  
  whole = where(finite(temp_atmo) ne 1, nwhole, comp=whit)
  if nwhole ne 0 then begin
     indice = dindgen(nsn)
     temp_atmo = interpol(temp_atmo[whit], indice[whit], indice, /quadratic)
  endif

  ;;========== Subtract this template from the kids
  for i=0, nw1-1 do begin
     ikid = w1[i]
     wfit = where(w8source[ikid,*] ne 0, nw)
     if nw lt 10 then w8source[ikid,*] = 1 ;Request at least 10 points for the fit
     wfit = where(w8source[ikid,*] ne 0, nw)

     ;;---------- Case of elevation
     if keyword_set(elev) and keyword_set(ofs_el) and param.fit_elevation eq 'yes' then begin
        ;;---------- Findout if the elevation offset template is constant
        if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
        if no_el eq 0 then templates = transpose([[temp_atmo[wfit]], [elev[wfit]], [ofs_el[wfit]]])
        if no_el eq 1 then templates = transpose([[temp_atmo[wfit]], [elev[wfit]]])
        
        y = reform(TOI[ikid, wfit])
        coeff = regress(templates, y, CONST=const, YFIT=yfit, status=status)

        if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit] + coeff[1]*elev[wfit] + coeff[2]*ofs_el[wfit]) else coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit] + coeff[1]*elev[wfit])

        TOI[ikid,*] = TOI[ikid,*] - coeff[0]*temp_atmo - coeff[1]*elev  + coeff_0[0]
        if no_el eq 0 then TOI[ikid,*] = TOI[ikid,*] - coeff[2]*ofs_el

        base[ikid,*] = coeff[0]*temp_atmo + coeff[1]*elev - coeff_0[0]
        if no_el eq 0 then base[ikid,*] += coeff[2]*ofs_el
        
        ;;---------- Case of no elevation
     endif else begin
        templates = temp_atmo[wfit]
        y = reform(TOI[ikid, wfit])
        coeff = regress(templates, y, CONST=const, YFIT=yfit, status=status)
        coeff_0 = linfit(yfit, coeff[0]*temp_atmo[wfit])
        TOI[ikid,*] = TOI[ikid,*] - (coeff[0]*temp_atmo - coeff_0[0])
        base[ikid,*] = coeff[0]*temp_atmo - coeff_0[0]
     endelse
  endfor

  return
end
