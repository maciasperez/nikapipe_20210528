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
;
;KEYWORDS: warning: tells is the common mode had to be interpolated at
;                   some point
;
;LAST EDITION: 2013: creation from nika_pipe_subtract_atm.pro
;              2014.07.14: add the elevation fit
;
;-

pro nika_pipe_subtract_common_bloc, param, rf_didq, kidpar, w8source, temp_atmo, base, $
                                    warning=warning, elev=elev, ofs_el=ofs_el, k_median=k_median, toi_est=toi_est

  warning = 'no'
  
  nkid = n_elements(kidpar)
; CHANGE TO AVOID PROBLEMS WITH WRONG POINTING FILES
;  w1  = where( kidpar.type eq 1, nw1)
;;  lonsource = where(w8source eq 0.0, nlonsource)
;;; FXD This line is wrong  if nlonsource gt 0 then w8source[lonsource,*]=1.0
 ;; if nlonsource gt 0 then w8source[ lonsource] = 1.0
  w1  = where( kidpar.type eq 1, nw1)
;  w1  = where( kidpar.type eq 1 and total(w8source,2) gt 0.0, nw1)
  nsn = n_elements( rf_didq[0,*])

  base = rf_didq*0.d0
  TOI_out = rf_didq*0

  ;;------- Cross Calibration
  atm_x_calib = dblarr(nkid,2)
  atm_x_calib[*,1] = 1.d0

  if param.decor.common_mode.x_calib eq 'yes' then begin
     atmxcalib = nika_pipe_atmxcalib(RF_dIdQ[w1,*], 1-w8source[w1, *])
     atm_x_calib[w1, *] = atmxcalib
  endif 
  
  ;;------- Compute the correlation between all KIDs and to 0
  mcorr = correlate(RF_dIdQ)
  wnan = where(finite(mcorr) ne 1, nwnan)
  if nwnan ne 0 then mcorr[wnan] = -1

  ;;======= Look at all KIDs
  for i=0, nw1-1 do begin
     ikid = w1[i]
     wfit = where(w8source[ikid,*] ne 0, nwfit)
     if nwfit eq 0 then begin
        message, /info,'!!!!! KID alway on source: !!!!!'+$
                 'You need to reduce param.decor.common_mode.d_min. ' + $
                 'It is so large that the decorrelated KID is always on-source'
        w8source[ikid,*] = 1
        wfit = where(w8source[ikid,*] ne 0, nwfit)
     endif
     
     ;;------- Search for best set of KIDs to be used for deccorelation
     corr = reform(mcorr[ikid,*])
     wbad = where(kidpar.type ne 1, nwbad) ;Force rejected KIDs not to be correlated
     if nwbad ne 0 then corr[wbad] = -1
     s_corr = corr[reverse(sort(corr))] ;Sorted by best correlation
     
     ;;First bloc with the min number of KIDs allowed
     bloc = where(corr gt s_corr[param.decor.common_mode.nbloc_min+1] and corr ne 1, nbloc)
     ;;Then add KIDs and test if correlated enough  
     sd_bloc = stddev(corr[bloc])
     mean_bloc = mean(corr[bloc])
     iter = param.decor.common_mode.nbloc_min+1
     test = 'ok'

     while test eq 'ok' and iter lt nw1-2 do begin
        if s_corr[iter] lt mean_bloc-param.decor.common_mode.nsig_bloc*sd_bloc $
        then test = 'pas_ok' $
        else bloc = where(corr gt s_corr[iter+1] and corr ne 1, nbloc)
        iter += 1
     endwhile
     
     ;;------- Build the appropriate noise template
     hit_b = lonarr(nsn)        ;Number of hit in the block common mode timeline 
     cm_b = dblarr(nsn)         ;Block common mode ignoring the source
     for j=0, nbloc-1 do begin
        if keyword_set(toi_Est) then cm_b += (atm_x_calib[bloc[j],0] + atm_x_calib[bloc[j],1]*(rf_didq[bloc[j],*] - toi_est[bloc[j], *])) else cm_b += (atm_x_calib[bloc[j],0] + atm_x_calib[bloc[j],1]*rf_didq[bloc[j],*]) * w8source[bloc[j],*]
        if keyword_set(toi_Est) then hit_b += w8source[bloc[j],*]*0+1 else hit_b += w8source[bloc[j],*]
     endfor
     
     loc_hit_b = where(hit_b ge 1, nloc_hit_b, COMPLEMENT=loc_no_hit_b, ncompl=nloc_no_hit_b)
     if nloc_hit_b ne 0 then cm_b[loc_hit_b] = cm_b[loc_hit_b]/hit_b[loc_hit_b]
     if nloc_no_hit_b ne 0 then cm_b[loc_no_hit_b] = !values.f_nan

     ;;------- If holes, interpolates
     if nloc_no_hit_b ne 0 then begin
        if nloc_hit_b eq 0 then message, 'You need to reduce param.decor.common_mode.d_min. ' + $
                                         'It is so large that not even a single KID used in the ' + $
                                         'common-mode can be assumed be off-source'
        warning = 'yes'
        indice = dindgen(nsn)
        cm_b = interpol(cm_b[loc_hit_b], indice[loc_hit_b], indice, /quadratic)
     endif
     
     ;;---------- Case of elevation
     if keyword_set(elev) and keyword_set(ofs_el) and param.fit_elevation eq 'yes' then begin
        if min(ofs_el[wfit]) eq max(ofs_el[wfit]) then no_el = 1 else no_el = 0
        if param.scan_type[param.iscan] ne 'lissajous' then no_el = 1 ;Useless for OTF and avoid problems
        if no_el eq 0 then templates = transpose([[cm_b[wfit]], [elev[wfit]], [ofs_el[wfit]]])
        if no_el eq 1 then templates = transpose([[cm_b[wfit]], [elev[wfit]]])
        
        y = reform(rf_didq[ikid,wfit])
        coeff = regress(templates, y, CONST=const, YFIT=yfit)

        if no_el eq 0 then coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit] + coeff[1]*elev[wfit] + coeff[2]*ofs_el[wfit]) else coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit] + coeff[1]*elev[wfit])

        TOI_out[ikid,*] = RF_dIdQ[ikid,*] - coeff[0]*cm_b - coeff[1]*elev  + coeff_0[0]
        if no_el eq 0 then TOI_out[ikid,*] = TOI_out[ikid,*] - coeff[2]*ofs_el

        base[ikid,*] = coeff[0]*cm_b + coeff[1]*elev - coeff_0[0]
        if no_el eq 0 then base[ikid,*] += coeff[2]*ofs_el
        
        ;;---------- Case of no elevation
     endif else begin
        templates = cm_b[wfit]
        y = reform(rf_didq[ikid,wfit])
        coeff = regress(templates, y, CONST=const, YFIT=yfit)
        coeff_0 = linfit(yfit, coeff[0]*cm_b[wfit])
        TOI_out[ikid,*] = RF_dIdQ[ikid,*] - coeff[0]*cm_b + coeff_0[0]
        base[ikid,*] = coeff[0]*cm_b - coeff_0[0]
     endelse
  endfor

  RF_dIdQ = TOI_out
  
  return
end
