;+
;
; SOFTWARE: NIKA pipeline
;
; NAME:
; nk_sensitivity_from_jk
;
; CATEGORY: map analysis
;
; CALLING SEQUENCE:
;         nk_sensitivity_from_jk, param, scan_list
; 
; PURPOSE: 
;        Compute the jack-knife maps and use them to compute sensitivity
; 
; INPUT: 
;        - param: the reduction parameters structure
;        - scan_list: the list of scans to use to compute jack-knife maps
; 
; OUTPUT: 
; 
; KEYWORDS:
;        - NIKA1: set to 1 if you are in a NIKA1 configuration (2 arrays)
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - September 7th, 2016: Creation based on nika_anapipe
;          routines (Florian Ruppin - ruppin@lpsc.in2p3.fr)
;-

pro nk_sensitivity_from_jk, param, scan_list, NIKA1=NIKA1

  fmt = '(1F8.1)'               ; Output format for NEFDs

  nk_average_scans, param, scan_list, coadded_map

  map_A1 = (coadded_map.map_i1)
  var_A1 = (coadded_map.map_var_i1)
  time_A1 = (coadded_map.nhits_1/!nika.f_sampling)
  map_A2 = (coadded_map.map_i2)
  var_A2 = (coadded_map.map_var_i2)
  time_A2 = (coadded_map.nhits_2/!nika.f_sampling)
  map_A3 = (coadded_map.map_i3)
  var_A3 = (coadded_map.map_var_i3)
  time_A3 = (coadded_map.nhits_3/!nika.f_sampling)

  nmap = n_elements(scan_list)
  nx = n_elements(map_A1[*,0])
  ny = n_elements(map_A1[0,*])

  map_jy_per_scan_A1 = dblarr(nx,ny,nmap)
  map_jy_per_scan_A2 = dblarr(nx,ny,nmap)
  map_jy_per_scan_A3 = dblarr(nx,ny,nmap)
  map_var_per_scan_A1 = dblarr(nx,ny,nmap)
  map_var_per_scan_A2 = dblarr(nx,ny,nmap)
  map_var_per_scan_A3 = dblarr(nx,ny,nmap)

  for iscan = 0, nmap-1 do begin
     dir = param.project_dir+"/v_"+strtrim(param.version,2)+"/"+strtrim(scan_list[iscan], 2)
     ;; Check if the requested result file exists
     file_save = dir+"/results.save"
     if file_test(file_save) eq 0 then begin
        message, /info, file_save+" not found"
     endif else begin
        ;; Restore results of each individual scan
        restore, file_save
        map_jy_per_scan_A1[*,*,iscan] = grid1.map_i1
        map_jy_per_scan_A2[*,*,iscan] = grid1.map_i2
        map_jy_per_scan_A3[*,*,iscan] = grid1.map_i3
        map_var_per_scan_A1[*,*,iscan] = grid1.map_var_i1
        map_var_per_scan_A2[*,*,iscan] = grid1.map_var_i2
        map_var_per_scan_A3[*,*,iscan] = grid1.map_var_i3
     endelse
  endfor

  ;;==================== Sensitivity computed using Jack-Knifes
  if nmap gt 1 then begin
     ;;------- Get the J-K
     ordre = sort(randomn(seed, nmap))
     map_jk_A1 = nk_jackknife(map_jy_per_scan_A1[*,*,ordre], map_var_per_scan_A1[*,*,ordre])
     map_jk_A2 = nk_jackknife(map_jy_per_scan_A2[*,*,ordre], map_var_per_scan_A2[*,*,ordre])
     map_jk_A3 = nk_jackknife(map_jy_per_scan_A3[*,*,ordre], map_var_per_scan_A3[*,*,ordre])
     map_jk_A1 *= 0.5
     map_jk_A2 *= 0.5
     map_jk_A3 *= 0.5
     
     ;;------- Histo of sensitivity from JK
     map_sens_A1 = map_jk_A1*sqrt(time_A1) 
     map_sens_A2 = map_jk_A2*sqrt(time_A2)
     map_sens_A3 = map_jk_A3*sqrt(time_A3)

     npix = nx
     reso = param.map_reso
     xmap = (dindgen(npix)-npix/2)*reso # replicate(1, npix)
     ymap = (dindgen(npix)-npix/2)*reso ## replicate(1, npix)
     rmap = sqrt(xmap^2+ymap^2)   
 
     wsens_A1 = where(finite(map_sens_A1) eq 1 and time_A1 gt 0 and map_jk_A1 ne 0 and rmap gt param.decor_cm_dmin,nwsens_A1,comp=wnosens_A1,ncomp=nwnosens_A1)
     wsens_A2 = where(finite(map_sens_A2) eq 1 and time_A2 gt 0 and map_jk_A2 ne 0 and rmap gt param.decor_cm_dmin,nwsens_A2,comp=wnosens_A2,ncomp=nwnosens_A2)
     wsens_A3 = where(finite(map_sens_A3) eq 1 and time_A3 gt 0 and map_jk_A3 ne 0 and rmap gt param.decor_cm_dmin,nwsens_A3,comp=wnosens_A3,ncomp=nwnosens_A3)
   
     if nwsens_A1 eq 0 then message, 'No pixel available for Jack-Knife'
     if nwsens_A2 eq 0 then message, 'No pixel available for Jack-Knife'
     if not keyword_set(NIKA1) then begin
        if nwsens_A3 eq 0 then message, 'No pixel available for Jack-Knife'
     endif

     map_sens_A1_clean = map_sens_A1*0.+!values.d_nan
     map_sens_A2_clean = map_sens_A2*0.+!values.d_nan
     map_sens_A3_clean = map_sens_A3*0.+!values.d_nan

     map_sens_A1_clean[wsens_A1] = map_sens_A1[wsens_A1]
     map_sens_A2_clean[wsens_A2] = map_sens_A2[wsens_A2]
     if not keyword_set(NIKA1) then map_sens_A3_clean[wsens_A3] = map_sens_A3[wsens_A3]

     map_sens_A1_clean *= 1e3
     map_sens_A2_clean *= 1e3
     map_sens_A3_clean *= 1e3

     sens_stddev_A1 = nk_stddev(map_sens_A1_clean,/nan)
     sens_stddev_A2 = nk_stddev(map_sens_A2_clean,/nan)
     sens_stddev_A3 = nk_stddev(map_sens_A3_clean,/nan)
     
     hist_A1 = histogram(map_sens_A1_clean, nbins=60, /nan)
     hist_A2 = histogram(map_sens_A2_clean, nbins=60, /nan)
     hist_A3 = histogram(map_sens_A3_clean, nbins=60, /nan)
     
     bins_A1 = FINDGEN(N_ELEMENTS(hist_A1))/(N_ELEMENTS(hist_A1)-1) * (max(map_sens_A1_clean,/nan)-min(map_sens_A1_clean,/nan))+min(map_sens_A1_clean,/nan)
     bins_A1 += (bins_A1[1]-bins_A1[0])/2
     bins_A2 = FINDGEN(N_ELEMENTS(hist_A2))/(N_ELEMENTS(hist_A2)-1) * (max(map_sens_A2_clean,/nan)-min(map_sens_A2_clean,/nan))+min(map_sens_A2_clean,/nan)
     bins_A2 += (bins_A2[1]-bins_A2[0])/2
     bins_A3 = FINDGEN(N_ELEMENTS(hist_A3))/(N_ELEMENTS(hist_A3)-1) * (max(map_sens_A3_clean,/nan)-min(map_sens_A3_clean,/nan))+min(map_sens_A3_clean,/nan)
     bins_A3 += (bins_A3[1]-bins_A3[0])/2
   
     yfit_A1 = GAUSSFIT(bins_A1, hist_A1, coeff_A1, nterms=3)
     yfit_A2 = GAUSSFIT(bins_A2, hist_A2, coeff_A2, nterms=3)
     yfit_A3 = GAUSSFIT(bins_A3, hist_A3, coeff_A3, nterms=3)

     if not keyword_set(NIKA1) then begin
        position1 = [0.05,0.05,0.25,0.95]
        position2 = [0.375,0.05,0.575,0.95]
        position3 = [0.675,0.05,0.875,0.95]
     endif else begin
        position1 = [0.05,0.05,0.45,0.95]
        position2 = [0.55,0.05,0.95,0.95]
     endelse

     window,2,XSIZE=1200, YSIZE=500
     imview,map_sens_A1_clean,coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)',title='Sensitivity map A1',position=position1, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     imview,map_sens_A2_clean,coltable=39,beam=18./2.,unitsbar='mJy.sqrt(s)',title='Sensitivity map A2',position=position2, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     if not keyword_set(NIKA1) then imview,map_sens_A3_clean,coltable=39,beam=12./2.,unitsbar='mJy.sqrt(s)',title='Sensitivity map A3',position=position3, /noerase, /noclose, xcharsize=0.7, ycharsize=0.7,charbar=0.7,charsize=0.7
     
     if not keyword_set(NIKA1) then window,3,XSIZE=1100,YSIZE=400 else window,3
     if keyword_set(NIKA1) then !P.multi = [0,2,1] else !P.multi = [0,3,1]
     cgHistoplot, map_sens_A1_clean, nbins=60, /FILLPOLYGON, POLYCOLOR=70, datacolorname=160, $
                  xtitle='mJy.sqrt(s)', ytitle='Number count', title='Array 1', $
                  charthick=1.5, charsize=1
     loadct,39, /silent
     oplot, bins_A1, yfit_A1, col=250, thick=5

     cgHistoplot, map_sens_A2_clean, nbins=60, /FILLPOLYGON, POLYCOLOR=70, datacolorname=160, $
                  xtitle='mJy.sqrt(s)', ytitle='Number count', title='Array 2', $
                  charthick=1.5, charsize=1
     loadct,39, /silent
     oplot, bins_A2, yfit_A2, col=250, thick=5

     if not keyword_set(NIKA1) then begin
        cgHistoplot, map_sens_A3_clean, nbins=60, /FILLPOLYGON, POLYCOLOR=70, datacolorname=160, $
                     xtitle='mJy.sqrt(s)', ytitle='Number count', title='Array 3',$
                     charthick=1.5, charsize=1
        loadct,39, /silent
        oplot, bins_A3, yfit_A3, col=250, thick=5
     endif
     !P.multi = 0 

     print, '=========================================='
     print, '======= Mean sensitivity found from Jack-Knife: '
     print, '=======    1 mm A1: '+string(coeff_A1[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
     print, '=======    1 mm A1: '+string(sens_stddev_A1,format = fmt )+' mJy.sqrt(s)/Beam     from the standard deviation'
     print, '=======    2 mm A2: '+string(coeff_A2[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
     print, '=======    2 mm A2: '+string(sens_stddev_A2, format = fmt2)+' mJy.sqrt(s)/Beam     from the standard deviation'
     print, '=======    1 mm A3: '+string(coeff_A3[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
     print, '=======    1 mm A3: '+string(sens_stddev_A3, format = fmt2)+' mJy.sqrt(s)/Beam     from the standard deviation'
     print, '=========================================='
     
  endif else begin
   nk_error, info, "You need to give more than one map to compute a Jack-knife"
  endelse

  return
end
