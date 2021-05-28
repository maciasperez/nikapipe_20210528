;+
;PURPOSE: usefule subroutine for nika_pipe_cmkidout
;
;INPUT: - The parameter structure
;       - The flux timelines
;       - the kidpar structure
;       - the w8 (telling if the KIDs are on source or not)
;
;OUTPUT: - The decorrelated data
;        - The atmospheric template
;        - The baseline
;
;KEYWORDS: - The telescpe elevation template
;          - median (to build the common mode with the median of all
;            detectors at any sample)
;
;LAST EDITION: - 2013: creation (Nicolas Ponthieu)
;              - 05/07/2014: remove loops and use
;              nika_pipe_atmxcalib.pro for atmospheric cross
;              calibration and loops are removed
;-

pro nika_pipe_subtract_common_atm, param, TOI, kidpar, w8source, $
                                   temp_atmo, base, $
                                   elev=elev, ofs_el=ofs_el, k_median=k_median
  
  w1  = where(kidpar.type eq 1, nw1)
  nsn = n_elements(TOI[0,*])

  base = TOI*0
  
  ;;---------- Atmosphere cross calibration
  if param.decor.common_mode.x_calib eq 'yes' then $
     atm_x_calib = nika_pipe_atmxcalib(TOI[w1,*], 1-w8source[w1, *]) $
  else atm_x_calib = [[dblarr(n_elements(nw1))], [dblarr(n_elements(nw1))+1]]
  
  ;;++++++++++ ADDED FOR TRANSFER FUNCTION PURPOSES
  ;;spawn, "ls "+param.output_dir+"/atm_xcal_"+param.day[param.iscan]+"_"+strtrim(param.scan_num[param.iscan],2)+"_subscan*.save", atm_name
  ;;atm_name = atm_name[0] ;Take the first one
  ;;restore, atm_name
  ;;spawn, 'rm -f '+atm_name

  ;;----------
  ;;spawn, "ls "+param.output_dir+"/atm_xcal_"+param.day[param.iscan]+"_"+strtrim(param.scan_num[param.iscan],2)+"_subscan*.save", atm_name
  ;;atm_name = atm_name[n_elements(atm_name)-1] ;Take the last one
  ;;if atm_name eq '' then index = '00' else begin
  ;;   clean_name = STRSPLIT(atm_name, param.output_dir+"/atm_xcal_"+param.day[param.iscan]+"_"+strtrim(param.scan_num[param.iscan],2)+"_subscan", /REGEX, /EXTRACT)
  ;;   clean_name = STRSPLIT(clean_name, ".save", /REGEX, /EXTRACT) 
  ;;   index = string(long(clean_name + 1), FORMAT='(I02)') 
  ;;endelse
  ;;save, filename=param.output_dir+"/atm_xcal_"+param.day[param.iscan]+"_"+strtrim(param.scan_num[param.iscan],2)+"_subscan"+index+".save", atm_x_calib
  ;;++++++++++

  ;;========== Common-mode built
  if not keyword_set(k_median) then begin     
     ;;---------- Take the mean of the detectors
     TOI_xcal = TOI[w1, *]
     TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, nsn))
     TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, nsn))
     TOI_xcal = TOI_xcal * w8source[w1, *]
     temp_atmo = total(TOI_xcal, 1)
     hit = total(w8source[w1,*], 1)
     temp_atmo /= hit
     
     ;;---------- If the source is too large we can have holes in the atmosphere
     whole = where(hit eq 0, nwhole, comp=whit)
     if nwhole ne 0 then begin
        indice = dindgen(nsn)
        temp_atmo = interpol(temp_atmo[whit], indice[whit], indice, /quadratic)
     endif

  endif else begin
     ;;---------- Common mode as median over all KIDs at a given time
     TOI_xcal = TOI[w1, *]
     TOI_xcal = TOI_xcal * (atm_x_calib[*,1] # replicate(1, nsn))
     TOI_xcal = TOI_xcal + (atm_x_calib[*,0] # replicate(1, nsn))
     
     wnan = where(w8source[w1, *] eq 0, nwnan)
     if nwnan ne 0 then TOI_xcal[wnan] = !values.f_nan
     
     temp_atmo = median(TOI_xcal, dim=1)

     ;;---------- If the source is too large we can have holes in the atmosphere
     whole = where(finite(temp_atmo) ne 1, nwhole, comp=whit)
     if nwhole ne 0 then begin
        print, '=================== BIG WARNING: atmosphere interpolated'
        indice = dindgen(nsn)
        temp_atmo = interpol(temp_atmo[whit], indice[whit], indice, /quadratic)
     endif
  endelse
  
  ;;---------- Subtract this template from the kids
  for i=0, nw1-1 do begin
     ikid = w1[i]
     wfit = where(w8source[ikid,*] ne 0, nw)
     if nw lt 10 then w8source[ikid,*] = 1 ;Request at least 10 points for the fit
     wfit = where(w8source[ikid,*] ne 0, nw)
     
     ;;---------- Case of elevation
     if keyword_set(elev) and keyword_set(ofs_el) and param.fit_elevation eq 'yes' then begin
        if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
        if param.scan_type[param.iscan] ne 'lissajous' then no_el = 1 ;Useless for OTF and avoid problems
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
