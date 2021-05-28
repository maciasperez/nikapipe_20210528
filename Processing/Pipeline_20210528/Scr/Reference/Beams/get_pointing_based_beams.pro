;
;
;  get FWHM from beam monitoring with pointing scans
;
;  pointing results in files:'All_pointings_'+runname_tab[irun]+'_'+version_tab[irun]+'.save'
;  produced using beam_monitoring_with_pointings.pro 
;
;  LP, July 2018
;______________________________________________________

pro get_pointing_based_beams, fwhm_point, day, ut_otf, runname

  ;;runname_tab = ['N2R9', 'N2R12', 'N2R14']
  ;;version_tab = ['baseline', 'baseline', 'baseline']

  correction_file = !nika.pipeline_dir+'/Datamanage/Logbook/All_pointings_'+strupcase(runname)+'_baseline_v2.save'
  pcorr2ok = 0
  if file_test(correction_file) then begin
     
     restore, correction_file
     ;; table of 'info' structures
     
     ;; treat NaN
     wok = where(finite(allpoint_info.result_fwhm_1) gt 0 and $
                 finite(allpoint_info.result_fwhm_2) gt 0 and $
                 finite(allpoint_info.result_fwhm_3) gt 0 and $
                 finite(allpoint_info.result_fwhm_1mm) gt 0 ,  nok)     
     allpoint_info = allpoint_info[wok]
     
     ;; remove pointing toward extended sources
     wext = where(strlowcase(allpoint_info.object) eq 'ngc7027', next, compl=wok, ncompl=nok)
     allpoint_info = allpoint_info[wok]

     ;; account for Uranus beam widening due to finite diameter
     wu = where(strlowcase(allpoint_info.object) eq 'uranus', nu, compl=wo)
     bw = [0.2, 0.13, 0.2, 0.2] ;; diameter=3.5 arcsec
     if nu gt 0 then begin
        allpoint_info[wu].result_fwhm_1   = allpoint_info[wu].result_fwhm_1-0.2
        allpoint_info[wu].result_fwhm_3   = allpoint_info[wu].result_fwhm_3-0.2
        allpoint_info[wu].result_fwhm_1mm = allpoint_info[wu].result_fwhm_1mm-0.2
        allpoint_info[wu].result_fwhm_2   = allpoint_info[wu].result_fwhm_2-0.13
     endif
          
     ;;reordered allpoint_info
     pday = allpoint_info.day
     pday_list = pday[uniq(pday, sort(pday))]
     npdays = n_elements(pday_list)
     for ip = 0, npdays-1 do begin
        w = where(pday eq pday_list[ip], n)
        allpoint_info[w] = allpoint_info[w[sort((allpoint_info.scan_num)[w])]]
     endfor
     
     pointing_list = strtrim(string(allpoint_info.day, format='(i8)'), 2)+'s'+$
                     strtrim(string(allpoint_info.scan_num, format='(i8)'), 2)
     
     ;; outliers :
     ;; mettre une fenetre glissante pour virer les outliers ?
     pointing_outliers = ['20170225s224']
     remove_scan_from_list, pointing_list, pointing_outliers, olist, out_index = oind
     pointing_list = pointing_list[oind]
     allpoint_info = allpoint_info[oind]

     ;; remove extreme values
     w = where(allpoint_info.result_fwhm_1mm le 20. and allpoint_info.result_fwhm_1mm ge 10. and $
               allpoint_info.result_fwhm_2 le 20. and allpoint_info.result_fwhm_2 ge 16., nok)
     pointing_list = pointing_list[w]
     allpoint_info = allpoint_info[w]

     
     ;;
     np_scans       = n_elements(pointing_list)
     ut_point       = fltarr(np_scans)
     ut_str         = strmid(allpoint_info.ut, 0, 5)
     for i = 0, np_scans-1 do ut_point[i]  = float((STRSPLIT(ut_str[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_str[i], ':', /EXTRACT))[1])/60.
     
     pcorr2ok = 1
     ;stop
  endif else print, "Pointing-scan-based correction file from Juan's analysis not found"

  
  if pcorr2ok gt 0 then begin

     nscans        = n_elements(ut_otf)   
     all_day_list  = day[uniq(day, sort(day))]
     ndays         = n_elements(all_day_list)

     fwhm_point    = fltarr(nscans,4)
  

     
     first_val = [(allpoint_info.result_fwhm_1)[0], (allpoint_info.result_fwhm_2)[0], (allpoint_info.result_fwhm_3)[0], (allpoint_info.result_fwhm_1mm)[0]]
     time_index = findgen(ndays*1440.)/60.
     all_fwhm_interp = fltarr(ndays*1440., 4)
      
      time_point = fltarr(np_scans)
      time_otf   = fltarr(nscans)
      for id = 0., ndays-1. do begin
         wpoint = where(allpoint_info.day eq all_day_list[id], npoint)
         wotf   = where(day eq all_day_list[id], notf)
         ;; bug de minuit
         if npoint gt 1 and ut_point[wpoint[npoint-1]] lt 1.0d-1 then ut_point[wpoint[npoint-1]] = 24.0
         if notf gt 1 and ut_otf[wotf[notf-1]] lt 1.0d-1 then ut_otf[wotf[notf-1]] = 24.0 
         if npoint gt 0 then time_point[wpoint] = ut_point[wpoint]+24.0*id
         if notf gt 0 then time_otf[wotf] = ut_otf[wotf]+24.0*id
      endfor
      
      indpoint = intarr(np_scans)
      for i=0, np_scans-1 do indpoint[i] = (where(time_point[i] gt time_index-0.01 and time_point[i] lt time_index+0.01, nindpoint))[0]
      
      
      ;; lissage
      p_med = fltarr(np_scans, 4)
      p_rms = fltarr(np_scans, 4)
      nf_tab = intarr(np_scans) 
      
      for i=0, np_scans-1 do begin
         fenetre = where(time_point gt time_point[i]-0.35 and time_point lt time_point[i]+0.35, nf)
         if nf ge 3 then begin
            p_med[i, 0] = median((allpoint_info.result_fwhm_1)[fenetre])
            p_med[i, 1] = median((allpoint_info.result_fwhm_2)[fenetre])
            p_med[i, 2] = median((allpoint_info.result_fwhm_3)[fenetre])
            p_med[i, 3] = median((allpoint_info.result_fwhm_1mm)[fenetre])
         endif else begin
            ;; broader fenetre
            fenetre = where(time_point gt time_point[i]-0.60 and time_point lt time_point[i]+0.60, nf)
            p_med[i, 0] = median((allpoint_info.result_fwhm_1)[fenetre])
            p_med[i, 1] = median((allpoint_info.result_fwhm_2)[fenetre])
            p_med[i, 2] = median((allpoint_info.result_fwhm_3)[fenetre])
            p_med[i, 3] = median((allpoint_info.result_fwhm_1mm)[fenetre])
         endelse
         
         if nf gt 1 then begin 
            p_rms[i, 0] = stddev((allpoint_info.result_fwhm_1)[fenetre])
            p_rms[i, 1] = stddev((allpoint_info.result_fwhm_2)[fenetre])
            p_rms[i, 2] = stddev((allpoint_info.result_fwhm_3)[fenetre])
            p_rms[i, 3] = stddev((allpoint_info.result_fwhm_1mm)[fenetre])
         endif
         nf_tab[i] = nf
      endfor

      ;; using the median
      for i=0, 3 do all_fwhm_interp[*, i] = interpol( [first_val[i], p_med[*, i], p_med[np_scans-1, i]  ],  $
                                                      [0., time_index[indpoint],  time_index[indpoint[np_scans-1]]+1 ] , time_index)
      
      
      indotf = intarr(nscans)
      for i=0, nscans-1 do indotf[i] = (where(time_otf[i] gt time_index-0.01 and time_otf[i] lt time_index+0.01, nindotf))[0]
      
      ;;fwhm_point_2[*, 0] = all_fwhm_interp[indotf, 0]
      fwhm_point[*, 1] = all_fwhm_interp[indotf, 1]
      ;;fwhm_point_2[*, 2] = all_fwhm_interp[indotf, 2]
      fwhm_point[*, 0] = all_fwhm_interp[indotf, 3]
      fwhm_point[*, 2] = all_fwhm_interp[indotf, 3]
      fwhm_point[*, 3] = all_fwhm_interp[indotf, 3]

   endif






  
end
