
;;
;;   REFERENCE LAUNCHER SCRIPT FOR ABSOLUTE CALIBRATION
;;
;;   LP, April 2018
;;_________________________________________________

pro calibration_uranus_reference, runname, input_kidpar_file, $
                                  output_dir=output_dir, showplot=showplot, png=png, $
                                  fix_photocorr=fix_photocorr, $
                                  var1_photocorr=var1_photocorr, $
                                  var2_photocorr=var2_photocorr, $
                                  photocorr_using_pointing=photocorr_using_pointing, $
                                  delta_fwhm=delta_fwhm, $
                                  photometric_correction_suffixe=photometric_correction_suffixe, $
                                  opa_version_name=opa_version_name, $
                                  hybrid_opacity_after_reduction=hybrid_opacity_after_reduction, $
                                  pas_a_pas = pas_a_pas, $
                                  opacity_from_tau225 = opacity_from_tau225, $
                                  nostop=nostop, $
                                  calibration_per_array = calibration_per_array, $
                                  test_version_name=test_version_name, $
                                  output_allinfo_file = output_allinfo_file

  
  if not(keyword_set(output_dir)) then $
     output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'
  
  if file_test(output_dir, /directory) gt 1 then spawn, "mkdir -p "+output_dir
  
  if keyword_set(nostop) then nostop=1 else nostop=0
  
  if keyword_set(delta_fwhm) then delta_fwhm=delta_fwhm else delta_fwhm=0.

  calpera = 0
  if keyword_set(calibration_per_array) then calpera = 1
  
  
  ;; REFERENCE ANALYSIS PARAMS
  ;;------------------------------------------------------------------------------
  
  compute = 1
  
  ;; PARAMS
  do_tel_gain_corr   = 0      ;; NIKA2 telescope elevation-gain correction
  ;; options are:
  ;; - 0  = no correction
  ;; - 1  = correction using EMIR's curve
  ;; - 2 = correction using NIKA2 best-fitting curve
  ;; (default is zero -- see point_source_default_param.pro)
  
  elevation_min      = 0.0d0     ; select only scan taken at elevation > elevation_min

  decor_cm_dmin      = 60.0d0  ;;40.0d0 ;; 60.0d0    ; 90.0d0
  
  opacity_correction = 4
  ;; options are:
  ;; - 0 = no correction
  ;; - 1 = a constant correction per scan
  ;; - 2 = elevation-dependent correction per scan
  ;; - 3 = constant correction per scan after decorrelation
  ;; - 4 = elevation-dependent and array dependent correction per scan
  ;; - 5 = hybrid opacity correction: elevation-dependent,
  ;;   array-dependent correction and array 2 opacities extrapolated
  ;;   from array 1 ones
  corrected_skydip   = 1
  ;; apply correcting factor to skydip tau
  if opacity_correction lt 1 then NoTauCorrect  = 1 else NoTauCorrect   = 0
  
  method      = 'common_mode_one_block'
  source      = 'Uranus'

  
  ;; PHOTOMETRIC CORRECTION
  ;; SANS CORRECTION PHOTOMETRIQUE
  to_use_photocorr = 0
  photocorr        = 0
  
  fix=0
  if keyword_set(fix_photocorr) then begin
     fix=fix_photocorr
  endif  
  if keyword_set(var1_photocorr) then weakly_variable=1 else weakly_variable=0
  if keyword_set(var2_photocorr) then variable=1 else variable=0

  tt = fix[0]+weakly_variable+variable
  if tt gt 0 then begin
     to_use_photocorr = 1 ;; for dedicated scan selection
     photocorr=1
  endif
  
  
  ;;-------------------------------------------------------------------------------------------------

  
 
  ;; NAME
  nickname = runname
  ;; 'opa' version name to define the opacity correction version
  if keyword_set(opa_version_name) then nickname=nickname+opa_version_name
  ;; 'test' version name for testing various scan reduction paramaters
  if keyword_set(test_version_name) then nickname=nickname+test_version_name
  
  opa_suf = ''
  if keyword_set(hybrid_opacity_after_reduction) then opa_suf = '_hybrid_v0'
  if keyword_set(opacity_from_tau225) then opa_suf = '_use_tau225_v0'

  cal_suf = '_calperband'
  if calpera gt 0 then cal_suf = ''
 
  
  ;; Selection of Uranus scans
  restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_"+strupcase(runname)+"_v0.save"

  dz1 = abs(scan.focusz_mm - shift(scan.focusz_mm, -1))  ; 0.8
  dz2 = scan.focusz_mm - shift(scan.focusz_mm, -2)       ; 0.4
  dz3 = scan.focusz_mm - shift(scan.focusz_mm, -3)       ; -0.4
  dz4 = scan.focusz_mm - shift(scan.focusz_mm, -4)       ; -0.8
  
  dx1 = abs(scan.focusx_mm - shift(scan.focusx_mm, -1))  ; 1.4
  dx2 = scan.focusx_mm - shift(scan.focusx_mm, -2)       ; 0.7
  dx3 = scan.focusx_mm - shift(scan.focusx_mm, -3)       ; -0.7
  dx4 = scan.focusx_mm - shift(scan.focusx_mm, -4)       ; -1.4
  
  dy1 = abs(scan.focusy_mm - shift(scan.focusy_mm, -1))  ; 1.4
  dy2 = scan.focusy_mm - shift(scan.focusy_mm, -2)       ; 0.7
  dy3 = scan.focusy_mm - shift(scan.focusy_mm, -3)       ; -0.7
  dy4 = scan.focusy_mm - shift(scan.focusy_mm, -4)       ;-1.4
        
  wfocus = where((strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
                 (dz1 gt 0.3 or dx1 gt 0.5 or dy1 gt 0.5)) or  $
                 (strmid(scan.comment,0, 5) eq 'focus'), nscans, compl=wok, ncompl=nok)
  
  wtokeep = where(strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' $
                  and scan[wok].n_obs gt 4  $
                  and strupcase(scan[wok].object) eq 'URANUS', nkeep)

  
  scan_str = scan[wok[wtokeep]]
  scan_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)

  all_day       = scan.day
  all_day_list  = all_day[uniq(all_day, sort(all_day))]
  ndays         = n_elements(all_day_list)

 
  ;; concatenate all outliers per run
  ;; TBD: use blacklists instead 
  outlier_list =  [$
                  '20170223s16', $ ; dark test
                  '20170223s17', $ ; dark test
                  '20171024s171', $ ; focus scan
                  '20171026s235', $ ; focus scan
                  '20171028s313', $ ; RAS from tapas
                  '20180114s73', $  ; TBC
                  '20180116s94', $  ; focus scan
                  '20180118s212', $ ; focus scan
                  '20180119s241', $ ; Tapas comment: 'out of focus'
                  '20180119s242', $ ; Tapas comment: 'out of focus'
                  '20180119s243' $ ; Tapas comment: 'out of focus'                  
                  ]

  
  scan_list_ori = scan_list
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list
  
  
  nscans = n_elements(scan_list)
  for i=0, nscans-1 do print, "'"+strtrim(scan_list[i],2)+"', $"

  
  nk_scan2run, scan_list[0], rr
  
  
;; Make maps of all observations of Uranus
  reset=0
  if compute eq 1 then begin
         
     if reset gt 0 then begin
        scan_list_to_analyse = scan_list
        nscan_to_analyse = nscans
     endif else begin
        scan_list_to_analyse = ''
        for isc = 0, nscans-1 do begin
           file = output_dir+"/Uranus_photometry_"+nickname+'/v_1/'+scan_list[isc]+'/results.save'
           if file_test(file) lt 1 then scan_list_to_analyse = [ scan_list_to_analyse, scan_list[isc]]
        endfor
        nscan_to_analyse = n_elements(scan_list_to_analyse)-1
        if nscan_to_analyse gt 0 then scan_list_to_analyse = scan_list_to_analyse[1:*] 
     endelse
     
     print, 'nscan to be reduced = ', nscan_to_analyse
     if nscan_to_analyse gt 0 then begin
        print, 'go ahead ?'
        if nostop lt 1 then stop
     endif
          
     if nscan_to_analyse gt 0 then begin
        ncpu_max = 20 ;; 24
        ;;optimize_nproc, nscan_to_analyse, ncpu_max, nproc
        nproc=min([nscan_to_analyse,ncpu_max])
        
        ;; split series of beammap scans
        scan_list_to_analyse = shuffle( scan_list_to_analyse) 
        reset = 1
        project_dir = output_dir+"/Uranus_photometry_"+nickname
        if file_test(project_dir, /directory) lt 1 then spawn, "mkdir -p "+project_dir
        split_for, 0, nscan_to_analyse-1, $
                   commands=['obs_nk_ps, i, scan_list_to_analyse, project_dir, '+$
                             'method, source, input_kidpar_file=input_kidpar_file, '+$
                             'reset=reset, ' +$
                             'do_tel_gain_corr=do_tel_gain_corr, ' +$
                             'decor_cm_dmin=decor_cm_dmin, ' +$
                             'opacity_correction=opacity_correction, ' +$
                             'corrected_skydip=corrected_skydip, ' +$
                             'NoTauCorrect=NoTauCorrect'], $
                   nsplit=nproc, $
                   varnames=['scan_list_to_analyse', 'project_dir', 'method', 'source', $
                             'input_kidpar_file', $
                             'reset', 'do_tel_gain_corr', $
                             'decor_cm_dmin', 'opacity_correction', 'corrected_skydip', $
                             'NoTauCorrect']
     endif
  endif
  
  scan_list = scan_list[ sort(scan_list)]
  nscans = n_elements(scan_list)
  
  
;; check if all scans were indeed processed
  run = !nika.run
  project_dir = output_dir+"/Uranus_photometry_"+nickname
  
  flux         = fltarr(nscans,4)
  err_flux     = fltarr(nscans,4)
  tau_1mm      = fltarr(nscans)
  tau_2mm      = fltarr(nscans)
  tau1         = dblarr(nscans)
  tau2         = dblarr(nscans)
  tau2_hybrid  = dblarr(nscans)
  tau3         = dblarr(nscans)
  tau225       = dblarr(nscans)
  fwhm         = fltarr(nscans,4)
  nsub         = intarr(nscans)
  elev         = dblarr(nscans)
  ut           = strarr(nscans)
  ut_float     = fltarr(nscans)
  fwhm_point_4   = fltarr(nscans,4)
  fwhm_point_2   = fltarr(nscans,4)

  if photocorr gt 0 then begin
     ;; Xavier's Log relying on 4''-reso maps
     correction_file = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_corr_'+runname+'_v1.csv'
     pcorr4ok = 0
     if file_test(correction_file) then begin
        nk_read_csv_3, correction_file, pcorr
        
        ns = n_elements(pcorr.(0))
        index = indgen(ns)
        ;;
        wundef = where(pcorr.fwhm1 lt 0., nundef, compl=wdef, ncompl=ndef)
        fwhm1_interp = pcorr.fwhm1
        if nundef gt 0 then fwhm1_interp[wundef] = interpol(fwhm1_interp[wdef], index[wdef], index[wundef] )
        if nundef gt 0 then pcorr[wundef].fwhm1 = !values.f_nan
        fwhm1_lkv = last_known_value(pcorr.fwhm1)
        ;;
        wundef = where(pcorr.fwhm2 lt 0., nundef, compl=wdef, ncompl=ndef)
        fwhm2_interp = pcorr.fwhm2
        if nundef gt 0 then fwhm2_interp[wundef] = interpol(fwhm2_interp[wdef], index[wdef], index[wundef] )
        if nundef gt 0 then pcorr[wundef].fwhm2 = !values.f_nan
        fwhm2_lkv = last_known_value(pcorr.fwhm2)
        
        
        ;;pcorr.fwhm1 = fwhm1_lkv
        ;;pcorr.fwhm2 = fwhm2_lkv
        pcorr.fwhm1 = fwhm1_interp
        pcorr.fwhm2 = fwhm2_interp
        
        
        pcorr4ok = 1
     endif else print, "Pointing-scan-based correction file from Xavier's log not found"
     
     
     ;; Juan's Log relying on 2''-reso maps
     correction_file = !nika.pipeline_dir+'/Datamanage/Logbook/All_pointings_'+strupcase(runname)+'_baseline.save'
     pcorr2ok = 0
     if file_test(correction_file) then begin
        
        restore, correction_file
        ;; table of 'info' structures
        
        
        ;; treat NaN
        wok = where(finite(allpoint_info.result_fwhm_1) gt 0 and $
                    finite(allpoint_info.result_fwhm_2) gt 0 and $
                    finite(allpoint_info.result_fwhm_3) gt 0, nok)
        allpoint_info = allpoint_info[wok]
        
        ;; remove pointing toward extended sources
        wext = where(strlowcase(allpoint_info.object) eq 'ngc7027', next, compl=wok, ncompl=nok)
        allpoint_info = allpoint_info[wok]
        
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
        pointing_outliers = ['20170225s224']
        remove_scan_from_list, pointing_list, pointing_outliers, olist, out_index = oind
        pointing_list = pointing_list[oind]
        allpoint_info = allpoint_info[oind]
        
        ;;
        np_scans       = n_elements(pointing_list)
        ut_point = fltarr(np_scans)
        ut_str   = strmid(allpoint_info.ut, 0, 5)
        for i = 0, np_scans-1 do ut_point[i]  = float((STRSPLIT(ut_str[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_str[i], ':', /EXTRACT))[1])/60.
        
        pcorr2ok = 1
     endif else print, "Pointing-scan-based correction file from Juan's analysis not found"
  endif
  
  
  ;; init info_all
  ;;nk_default_info, info_vide
  ;;info_all     = replicate(info_vide, nscans)
  ;;new_tags     = tag_names(info_all)
  
  
  dir = project_dir+"/v_1/"
  spawn, 'ls '+dir+'*/results.save', files
  restore,  files[0]
  ;;dir = project_dir+"/v_1/"+strtrim(scan_list[0], 2)
  ;;restore,  dir+"/results.save"
  allscan_info = replicate(info1, nscans)

  for i =0, nscans-1 do begin
     dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
     if file_test(dir+"/results.save") then begin
        restore,  dir+"/results.save"
        if info1.polar eq 1 then print, scan_list[i]+" is polarized !"
        
        ;;tag1  = tag_names(info1)
        ;;my_match, new_tags, tag1, suba, subb
        ;;for j=0, n_elements(subb)-1 do (info_all.(suba[j]))[i] = info1.(subb[j]) 
        allscan_info[i] = info1
        
        
        fwhm[i,0] = info1.result_fwhm_1
        fwhm[i,1] = info1.result_fwhm_2
        fwhm[i,2] = info1.result_fwhm_3
        fwhm[i,3] = info1.result_fwhm_1mm
        
        flux[i, 0] = info1.result_flux_i1
        flux[i, 1] = info1.result_flux_i2
        flux[i, 2] = info1.result_flux_i3
        flux[i, 3] = info1.result_flux_i_1mm
        
        tau_1mm[ i] = info1.result_tau_1mm
        tau_2mm[ i] = info1.result_tau_2mm
        tau1[ i] = info1.result_tau_1
        tau2[ i] = info1.result_tau_2
        tau3[ i] = info1.result_tau_3
        
        err_flux[i, 0] = info1.result_err_flux_i1
        err_flux[i, 1] = info1.result_err_flux_i2
        err_flux[i, 2] = info1.result_err_flux_i3
        err_flux[i, 3] = info1.result_err_flux_i_1mm
        nsub[i]        = info1.nsubscans
        elev[i]        = info1.RESULT_ELEVATION_DEG
        ut[i]          = strmid(info1.ut, 0, 5)
        ut_float[i]    = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
        tau225[i]      = info1.TAU225
        ;;if i eq 4 then stop
     endif
  endfor

  if photocorr gt 0 then begin
     if pcorr4ok gt 0 then begin
        all = strtrim(pcorr.day, 2)+'s'+strtrim(pcorr.scannum,2)
        my_match, all, scan_list, suba, subb
        
        fwhm_point_4[subb, 0] = pcorr[suba].fwhm1
        fwhm_point_4[subb, 1] = pcorr[suba].fwhm2
        fwhm_point_4[subb, 2] = pcorr[suba].fwhm1
     endif
     
     if pcorr2ok gt 0 then begin
        
        ;;first_val = [(allpoint_info.result_fwhm_1)[0],
        ;;(allpoint_info.result_fwhm_2)[0],
        ;;(allpoint_info.result_fwhm_3)[0],
        ;;(allpoint_info.result_fwhm_1mm)[0]]

        ;; start at nominal FWHMs
        first_val = [11.5, 17.5, 11.5, 11.5]
        time_index = findgen(ndays*1440.)/60.
        all_fwhm_interp = fltarr(ndays*1440., 4)
        
        time_point = fltarr(np_scans)
        time_otf   = fltarr(nscans)
        for id = 0., ndays-1. do begin
           wpoint = where(allpoint_info.day eq all_day_list[id], npoint)
           wotf   = where(info_all.day eq all_day_list[id], notf)
           ;; bug de minuit
           if npoint gt 1 and ut_point[wpoint[npoint-1]] lt 1.0d-1 then ut_point[wpoint[npoint-1]] = 24.0
           if notf gt 1 and ut_float[wotf[notf-1]] lt 1.0d-1 then ut_float[wotf[notf-1]] = 24.0 
           if npoint gt 0 then time_point[wpoint] = ut_point[wpoint]+24.0*id
           if notf gt 0 then time_otf[wotf] = ut_float[wotf]+24.0*id
        endfor
          
        indpoint = intarr(np_scans)
        for i=0, np_scans-1 do indpoint[i] = (where(time_point[i] gt time_index-0.01 and time_point[i] lt time_index+0.01, nindpoint))[0]
        
        ;; all_fwhm_interp[*, 0] = interpol( [first_val[0], (allpoint_info.result_fwhm_1)],  [0., time_index[indpoint]], time_index)
        ;; all_fwhm_interp[*, 1] = interpol( [first_val[1], (allpoint_info.result_fwhm_2)],  [0., time_index[indpoint]], time_index)
        ;; all_fwhm_interp[*, 2] = interpol( [first_val[2], (allpoint_info.result_fwhm_3)],  [0., time_index[indpoint]], time_index)
        ;; all_fwhm_interp[*, 3] = interpol( [first_val[3],
        ;; (allpoint_info.result_fwhm_1mm)],  [0., time_index[indpoint]],
        ;; time_index)
        
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
        fwhm_point_2[*, 1] = all_fwhm_interp[indotf, 1]
        ;;fwhm_point_2[*, 2] = all_fwhm_interp[indotf, 2]
        fwhm_point_2[*, 0] = all_fwhm_interp[indotf, 3]
        fwhm_point_2[*, 2] = all_fwhm_interp[indotf, 3]
        fwhm_point_2[*, 3] = all_fwhm_interp[indotf, 3]
        
        plotdir = '/home/perotto/NIKA/Plots/Baseline_plots'
        
        wind, 1, 1, /free, xsize=600, ysize=310
        outplot, file=plotdir+'/Pointings_for_Uranus_'+$
              strtrim(nickname,2)+photocorr_suffixe+opa_suf, png=png, ps=ps
        plot,  time_index, all_fwhm_interp[*, 0], yrange=[10., 20.] ;, xr=[90, 120]
        oplot, time_index, all_fwhm_interp[*, 3], col=200
        oplot, time_index[indpoint], (allpoint_info.result_fwhm_1), psym=8, col=250
        for i=0, ndays-1 do oplot, 24.*[i, i], [0., 100]
        oplot, time_index[indpoint], p_med[*, 0], col=50
        oplot, time_index[indpoint], p_med[*, 0]+p_rms[*, 0], col=50
        oplot, time_index[indpoint], p_med[*, 0]-p_rms[*, 0], col=50
        oplot, time_index[indotf], fwhm_point_2[*, 0], psym=8, col=80
        outplot, /close
        
        if nostop lt 1 then stop
        
     endif
  endif
  
  
  if keyword_set(hybrid_opacity_after_reduction) then begin
     tau2_hybrid = modified_atm_ratio(tau3,use_taua3=1)*tau3
     flux_ori    = flux
     flux[*, 1]  = flux[*, 1]*exp((tau2_hybrid[*]-tau2[*])/sin(elev[*]*!dtor))
  endif
  
  if keyword_set(opacity_from_tau225) then begin
     
     opa_file = !nika.pipeline_dir+'/Datamanage/Tau225/results_opacity_tau225interp_'+strupcase(runname)+'.fits'
     restore, !nika.pipeline_dir+'/Datamanage/Tau225/modified_ATM_tau225_ratios.save'
     if file_test(opa_file) then begin
        
        opa = mrdfits(opa_file, 1)
        
        scan_list_opa = strtrim(opa.day,2)+'s'+strtrim(opa.scannum,2)
        my_match, scan_list_opa, scan_list, suba, subb

        if n_elements(subb) ne nscans then begin
           print, "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
           print, "BEWARE: some scans are not found in the tau225 file"
        endif
        
        tau1_interp = dblarr(nscans)
        tau2_interp = dblarr(nscans)
        tau3_interp = dblarr(nscans)
        tau_1mm_interp = dblarr(nscans)
        
        tau225[subb] = opa[suba].tau225_medfilt
        
        tau1_interp[subb] = opa[suba].tau1_medfilt + modified_atm_tau225_ratio[0]*tau225[subb]
        tau2_interp[subb] = opa[suba].tau2_medfilt + modified_atm_tau225_ratio[1]*tau225[subb]
        tau3_interp[subb] = opa[suba].tau3_medfilt + modified_atm_tau225_ratio[2]*tau225[subb]
        tau_1mm_interp[subb] = opa[suba].tau3_medfilt + modified_atm_tau225_ratio[3]*tau225[subb]
        
        flux[subb, 0] = flux[subb, 0]*exp((tau1_interp[subb]-tau1[subb])/sin(elev[subb]*!dtor))
        flux[subb, 1] = flux[subb, 1]*exp((tau2_interp[subb]-tau2[subb])/sin(elev[subb]*!dtor))
        flux[subb, 2] = flux[subb, 2]*exp((tau3_interp[subb]-tau3[subb])/sin(elev[subb]*!dtor))
        flux[subb, 3] = flux[subb, 3]*exp((tau_1mm_interp[subb]-tau_1mm[subb])/sin(elev[subb]*!dtor))
        
        tau1_ori = tau1
        tau2_ori = tau2
        tau3_ori = tau3
        tau_1mm_ori = tau_1mm
        tau1 = tau1_interp
        tau2 = tau2_interp
        tau3 = tau3_interp
        tau_1mm = tau_1mm_interp
        
     endif else print, "File containing interpolated opacities from tau225 not found: ",opa_file 
  endif

  
  photocorr_suffixe=''
  if photocorr gt 0 then begin
     
     tflux = transpose(flux)
     tfwhm = transpose(fwhm)
     if keyword_set(photocorr_using_pointing) then begin
        if pcorr4ok gt 0 then tfwhm = transpose(fwhm_point_4)
        if pcorr2ok gt 0 then tfwhm = transpose(fwhm_point_2)
     endif
     photometric_correction, tflux, tfwhm, corr_flux_factor, $
                             fix=fix, weakly_variable=weakly_variable, $
                             variable=variable, delta_fwhm=delta_fwhm

     ;; for testing, we implement also the photometric correction
     ;; using the flux without using the hybrid opacity
     if keyword_set(hybrid_opacity_after_reduction) then begin
        tfwhm = transpose(fwhm)
        tflux = transpose(flux_ori)
        photometric_correction, tflux, tfwhm, corr_flux_factor_ori, $
                                fix=fix, weakly_variable=weakly_variable, $
                                variable=variable, delta_fwhm=delta_fwhm
        for ia = 0, 3 do flux_ori[*, ia] = flux_ori[*, ia]*corr_flux_factor_ori[ia,*]
     endif
     
     plot, reform(corr_flux_factor[0, *]), yr=[0.8, 1.1], /ys, /nodata
     oplot, [0, 100], [1, 1]
     oplot, reform(corr_flux_factor[0, *]), col=80, psym=8
     oplot, reform(corr_flux_factor[2, *]), col=50, psym=8
     oplot, reform(corr_flux_factor[1, *]), col=250, psym=8         
        

     photocorr_suffixe = '_photocorr'
     if fix[0] gt 0 then begin
        nn = n_elements(fix)
        if nn eq 1 then photocorr_suffixe=photocorr_suffixe+'_fix' else $
           if nn eq 3 then photocorr_suffixe=photocorr_suffixe+'_step'
     endif
     if weakly_variable gt 0 then photocorr_suffixe=photocorr_suffixe+'_var1'
     if variable gt 0 then photocorr_suffixe=photocorr_suffixe+'_var2'
     if delta_fwhm[0] gt 0 then photocorr_suffixe='_photocorr_mod_var1'

     if keyword_set(photometric_correction_suffixe) then photocorr_suffixe=photometric_correction_suffixe
     
     raw_flux = flux
     for ia = 0, 3 do flux[*, ia] = flux[*, ia]*corr_flux_factor[ia,*]

     if keyword_set(pas_a_pas) then stop
  endif

  
  ;; selection before recalibration
  ;;------------------------------------------------------------------
  
  fwhm_sigma = dblarr(3)
  fwhm_avg   = dblarr(3)
  for j=0, 2 do begin
     w=where(fwhm[*,j] lt !nika.fwhm_array[j]*1.2 and fwhm[*,j] gt !nika.fwhm_array[j]*0.65, nok)
     if nok gt 0 then begin
        fwhm_sigma[j] = stddev( fwhm[w, j])
        fwhm_avg[j]   = avg(    fwhm[w, j])
     endif else print, "all scans have catastrophic fwhm!"
  endfor

  ;; select the needed outputs
  nscan_all  = nscans
  wout       = 1
  wlargebeam = 1 
  wdaytime   = 1
  whitau3    = 1
  fwhm_max   = 1
  baseline_scan_selection, allscan_info, wtokeep, $
                  to_use_photocorr=to_use_photocorr, complement_index=wout, $
                  beamok_index = beamok_index, largebeam_index = wlargebeam,$
                  tauok_index = tauok_index, hightau_index=whitau3, $
                  osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                  planet_fwhm_max = fwhm_max
  
  if wlargebeam[0] ge 0 then nlargebeam = n_elements(wlargebeam) else nlargebeam=0  
  if wdaytime[0] ge 0 then ndaytime = n_elements(wdaytime) else ndaytime=0
  if whitau3[0] ge 0 then nhitau3 = n_elements(whitau3) else nhitau3=0
  if wout[0] ge 0 then nout = n_elements(wout) else nout=0
  if wtokeep[0] ge 0 then nscans = n_elements(wtokeep) else nscans=0

  ;; plot 
  day_list = strmid(scan_list,0,8)
  
  wind, 1, 1, /free, /large
  outplot, file='fwhm_uranus_'+strtrim(nickname,2)+photocorr_suffixe, png=png, ps=ps
  !p.multi=[0,1,3]
  index = dindgen(n_elements(flux[*, 0]))
  for j=0, 2 do begin
     plot, index, fwhm[*,j], /xs, psym=-8, xtitle='scan index', ytitle='FWHM (arcsec)', $
           /ys, symsize=0.5
     if nlargebeam gt 0 then oplot, index[wlargebeam],   fwhm[wlargebeam,j], psym=7, col=250
     if ndaytime gt 0 then oplot, index[wdaytime], fwhm[wdaytime,j], psym=4, col=250
     if nhitau3 gt 0 then oplot, index[whitau3], fwhm[whitau3,j], psym=6, col=250
     
     if j eq 2 then   xyouts, index[wtokeep], fwhm[wtokeep,j], scan_list[wtokeep], charsi=0.7, orient=90
     if nout gt 0 and j eq 2 then  xyouts, index[wout], fwhm[wout,j], scan_list[wout], charsi=0.7, orient=90, col=250
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     oplot, [0,nscans+nout+1], index*0.+fwhm_avg[j], col=50, LINESTYLE = 5
     oplot, [0,nscans+nout+1], index*0.+fwhm_max[j], col=50
     if photocorr gt 0 then oplot, index, fwhm_point_4[*,j], psym=8, col=80
     if photocorr gt 0 then oplot, index, fwhm_point_2[*,j], psym=8, col=200
     legendastro, 'Array '+strtrim(j+1,2), box=0
     if j eq 0 then legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=[250, 250, 250], psym=[7, 4, 6], color=[250, 250, 250], box=0, /right;pos=[n_elements(fwhm[*,j]), max(fwhm[*,j])*0.9]
  endfor
  !p.multi=0
  outplot, /close


  ;;stop
  ;;ns = n_elements(pcorr.fwhm1)
  ;;index=indgen(ns)
  ;;plot, index, pcorr.fwhm1, xr=[630,700], /xs, /nodata, yr=[10., 14.], /ys
  ;;oplot, index, pcorr.fwhm1, psym=1, col=0
  ;;oplot, index, fwhm1_lkv, psym=1, col=80
  ;;oplot, index, fwhm1_interp, psym=1, col=150
  ;;oplot, index[suba], pcorr[suba].fwhm1, psym=5, col=250
  ;;oplot, index[suba], fwhm[subb, 0], psym=4, col=50
  ;;stop

  
  if nscans le 0 then begin
     print, "all scans have abberant FWHM...."
     print, "stopping here to investigate"
     if nostop lt 1 then stop
  endif else begin
     
     
     
     ;; apply the selection
     if nout gt 0 then begin
        print,''
        print,'============================================='
        black_list = scan_list[wout]
        print,'outlier_list =  [ $'
        for i=0, nout-2 do print,"'",black_list[i],"', $"
        print,"'",black_list[nout-1],"' ]"
        print,'============================================='
     endif
     
     scan_list_all = scan_list
     scan_list  = scan_list[wtokeep]
     flux_1     = flux[wtokeep, 0]
     flux_2     = flux[wtokeep, 1]
     flux_3     = flux[wtokeep, 2]
     flux_1mm   = flux[wtokeep, 3]
     
     day_list = strmid(scan_list,0,8)
     
     ;; save scan list
     info_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)
     my_match, info_list, scan_list, suba, subb
     wbeammap = where(scan_str[suba].n_obs gt 50, nbeammap)
     wotf     = where(scan_str[suba].n_obs gt 10 and scan_str[suba].n_obs lt 99, notf)
     beammap_list = ''
     if nbeammap gt 0 then beammap_list = scan_list[subb[wbeammap]]
     otf_list = ''
     if notf gt 0 then otf_list = scan_list[subb[wotf]]
     save, beammap_list, otf_list, filename=output_dir+'/Goodscans_Uranus_'+runname+'.save'
     ;; 

     ;; ABSOLUTE CALIBRATION
     ;;________________________________________________________________-

     if keyword_set(pas_a_pas) then stop
     
     sigma_1 = stddev( flux_1)
     sigma_2 = stddev( flux_2)
     sigma_3 = stddev( flux_3)
     sigma_1mm = stddev( flux_1mm)
     flux_avg_1 = avg( flux_1)
     flux_avg_2 = avg( flux_2)
     flux_avg_3 = avg( flux_3)
     flux_avg_1mm = avg( flux_1mm)
     
     print,''
     print,'======================================================'
     print,"Relative uncertainty A1: "+strtrim(100.*sigma_1/flux_avg_1,2)+" %"
     print,"Relative uncertainty A3: "+strtrim(100.*sigma_3/flux_avg_3,2)+" %"
     print,"Relative uncertainty A1&A3: "+strtrim(100.*sigma_1mm/flux_avg_1mm,2)+" %"
     print,"Relative uncertainty A2: "+strtrim(100.*sigma_2/flux_avg_2,2)+" %"
     print,'======================================================'
     print,"Flux correction coefficient A1: "+strtrim(!nika.flux_uranus[0]/flux_avg_1,2)
     print,"Flux correction coefficient A3: "+strtrim(!nika.flux_uranus[0]/flux_avg_3,2)
     print,"Flux correction coefficient A1&A3: "+strtrim(!nika.flux_uranus[0]/flux_avg_1mm,2)
     print,"Flux correction coefficient A2: "+strtrim(!nika.flux_uranus[1]/flux_avg_2,2)
     print,'======================================================'
     print,"Flux ratio to expectation A1: "+strtrim(flux_avg_1/!nika.flux_uranus[0],2)
     print,"Flux ratio to expectation A3: "+strtrim(flux_avg_3/!nika.flux_uranus[0],2)
     print,"Flux ratio to expectation A1&A3: "+strtrim(flux_avg_1mm/!nika.flux_uranus[0],2)
     print,"Flux ratio to expectation A2: "+strtrim(flux_avg_2/!nika.flux_uranus[1],2)     
     print,'======================================================'
     
     if calpera gt 0 then begin
        correction_coef = [!nika.flux_uranus[0]/flux_avg_1,!nika.flux_uranus[1]/flux_avg_2,!nika.flux_uranus[0]/flux_avg_3, !nika.flux_uranus[0]/flux_avg_1mm]
     endif else begin
        correction_coef = [!nika.flux_uranus[0]/flux_avg_1mm,!nika.flux_uranus[1]/flux_avg_2,!nika.flux_uranus[0]/flux_avg_1mm, !nika.flux_uranus[0]/flux_avg_1mm]
     endelse
     relative_error = [100.*sigma_1/flux_avg_1, 100.*sigma_2/flux_avg_2, 100.*sigma_3/flux_avg_3, 100.*sigma_1mm/flux_avg_1mm ]
     corr_file = output_dir+"/Absolute_calibration_"+nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
     nscan_total = n_elements(scan_list_all)
     save, correction_coef, relative_error, nscans, nscan_total, filename=corr_file
     
     ;; save also the calibration factors without resorting to hybrid
     ;; opacity correction
     if keyword_set(hybrid_opacity_after_reduction) then begin
        if calpera gt 0 then begin
           correction_coef = [!nika.flux_uranus[0]/avg(flux_ori[wtokeep, 0]),$
                              !nika.flux_uranus[1]/avg(flux_ori[wtokeep, 1]),$
                              !nika.flux_uranus[0]/avg(flux_ori[wtokeep, 2]), $
                              !nika.flux_uranus[0]/avg(flux_ori[wtokeep, 3])]
        endif else begin
           correction_coef = [!nika.flux_uranus[0]/avg(flux_ori[wtokeep, 3]),$
                              !nika.flux_uranus[1]/avg(flux_ori[wtokeep, 1]),$
                              !nika.flux_uranus[0]/avg(flux_ori[wtokeep, 3]),$
                              !nika.flux_uranus[0]/avg(flux_ori[wtokeep, 3])]
        endelse
        relative_error = [100.*stddev(flux_ori[wtokeep, 0])/avg(flux_ori[wtokeep, 0]),$
                          100.*stddev(flux_ori[wtokeep, 1])/avg(flux_ori[wtokeep, 1]),$
                          100.*stddev(flux_ori[wtokeep, 2])/avg(flux_ori[wtokeep, 2]),$
                          100.*stddev(flux_ori[wtokeep, 3])/avg(flux_ori[wtokeep, 3])]
        
        corr_file = output_dir+"/Absolute_calibration_"+nickname+photocorr_suffixe+cal_suf+'.save'
        nscan_total = n_elements(scan_list_all)
        save, correction_coef, relative_error, nscans, nscan_total, filename=corr_file
     endif

      ;; Recalibrate the flux
     ;;________________________________________________________________
    
     flux_1 = flux_1*correction_coef[0]
     flux_2 = flux_2*correction_coef[1]
     flux_3 = flux_3*correction_coef[2]
     flux_1mm = flux_1mm*correction_coef[3]

     for ia = 0, 3 do flux[*, ia] = flux[*, ia]*correction_coef[ia] 
     for ia = 0, 3 do err_flux[*, ia] = err_flux[*, ia]*correction_coef[ia] 

     
     ;; plot of the flux
     ;;--------------------------------------------------------------------
     
     delvarx, yra    
     index = dindgen(n_elements(flux_1))
     
     fmt = "(F5.2)"
     wind, 1, 1, /free, /large
     outfile = project_dir+'/photometry_uranus_'+strtrim(nickname,2)+photocorr_suffixe
     outplot, file=outfile, png=png, ps=ps
     my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
     !x.charsize = 1e-10
     
     yra=!nika.flux_uranus[0]*[0.7, 1.3]
     plot,       index, flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
     oploterror, index, flux_1, err_flux[wtokeep, 0], psym=8 
     oplot, [-1,nscans], [flux_avg_1, flux_avg_1], col=70
     oplot, [-1,nscans], !nika.flux_uranus[0]*[1., 1.], col=250
     legendastro, ['Array 1', 'sigma/avg: '+strtrim( string(sigma_1/flux_avg_1,format=fmt),2)], box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     yra=!nika.flux_uranus[0]*[0.7, 1.3]
     plot,       index, flux_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
     oploterror, index, flux_3, err_flux[wtokeep, 2], psym=8
     oplot, [-1,nscans], [flux_avg_3, flux_avg_3], col=70
     oplot, [-1,nscans], !nika.flux_uranus[0]*[1., 1.], col=250
     legendastro, ['Array 3', 'sigma/avg: '+strtrim( string(sigma_3/flux_avg_3,format=fmt),2)], box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     yra=!nika.flux_uranus[1]*[0.7, 1.3]
     plot,       index, flux_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
     oploterror, index, flux_2, err_flux[wtokeep,1], psym=8
     oplot, [-1,nscans], [flux_avg_2, flux_avg_2], col=70
     oplot, [-1,nscans], !nika.flux_uranus[1]*[1., 1.], col=250
     xyouts, index, flux_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
     legendastro, ['Array 2', 'sigma/avg: '+strtrim( string(sigma_2/flux_avg_2,format=fmt),2)], box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     
     plot, index, tau_1mm[wtokeep], xr=[-1,nscans],/xs, position=pp1[3,*], /noerase,/nodata
     oplot, index, tau_1mm[wtokeep], col=250
     oplot, index, tau_2mm[wtokeep], col=50
     legendastro, ['Tau 1mm', 'Tau 2mm'], col=[250, 50],box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     !p.multi = 0
     outplot, /close
     
     
     
    
     ;; correlation plots
     ;;----------------------------------------------
     ut_tab=['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '20:30', '21:00', '22:00', '24:00']
     
     
     dok = where(ut ne '', nok) 
     
     minut = min(ut[dok])
     maxut = max(ut[dok])
     minh = where(ut_tab ge minut)
     maxh = where(ut_tab le maxut)
     ut_tab = ut_tab[minh[0]-1:maxh[n_elements(maxh)-1]+1]
     
     nut = n_elements(ut_tab)-1
     
     quant = ['Flux', 'FWHM', 'elev', 'tau']
     index = dindgen(nscans)
     day_list = strmid(scan_list,0,8)
     
     coltab = [200, 80, 250]
     !x.charsize = 1.
     
     
     ;; 1mm
     ;;--------------------------------------------
     wind, 1, 1, /free, xsize=1150, ysize=670
     outplot, file=project_dir+'/Correlation_plot_Uranus_1mm_'+$
              strtrim(nickname,2)+photocorr_suffixe+opa_suf, png=png, ps=ps
     my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
     
     ;; FWHM- Flux
     ymax = max( [!nika.flux_uranus[0]*1.2, max(flux[wtokeep, 0])]   )
     ymin = min( [!nika.flux_uranus[0]*0.7, min(flux[wtokeep, 0])]   )
     plot, fwhm[*, 0] , flux[*, 0], /xs, yr=[ymin, ymax], $
           xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),15.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[0, *]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm[w, 0] , flux[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, fwhm[w, 2] , flux[w, 2], psym=8, col=(u+1.)*250./nut
     endfor
     legendastro, ['A1', 'A3'], psym=[4, 8]
     
     ;;oplot, fwhm[wtokeep, 0] , flux[wtokeep, 0], psym=8, col=coltab[0]
     if nout gt 0 then oplot, fwhm[wout, 0] , flux[wout, 0], psym=7, col=0, thick=2
     ;;oplot, fwhm[wtokeep, 2] , flux[wtokeep, 2], psym=8, col=coltab[2]
     if nout gt 0 then oplot, fwhm[wout, 2] , flux[wout, 2], psym=7, col=0, thick=2
     
     oplot, [0,50], !nika.flux_uranus[0]*[1., 1.], col=0
     
     if photocorr lt 1 then oplot, fwhm[*, 0], !nika.flux_uranus[0]*(12.0^2+!nika.fwhm_nom[0]^2)/(fwhm[*,0]^2+!nika.fwhm_nom[0]^2), col=0
     
     
     ;; tau-flux     
     plot, tau_1mm[*]/sin(elev[*]*!dtor) , flux[*, 0], /xs, yr=[ymin, ymax], $
           xr=[min(tau_1mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5,$
               min([max(tau_1mm[*]/sin(elev[*]*!dtor)),1.])], psym=-4, $
           xtitle='Observed opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau1[w]/sin(elev[w]*!dtor) , flux[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, tau3[w]/sin(elev[w]*!dtor) , flux[w, 2], psym=8, col=(u+1.)*250./nut
        print, 'from ', ut_tab[u], ' to ',  ut_tab[u+1], ' : ', nn, ' scans'
     endfor
     
     ;;oplot, tau_1mm[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
     if nout gt 0 then oplot, tau1[wout]/sin(elev[wout]*!dtor) , flux[wout, 0], psym=7, col=0, thick=2
     ;;oplot, tau_1mm[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
     if nout gt 0 then oplot, tau3[wout]/sin(elev[wout]*!dtor) , flux[wout, 2], psym=7, col=0, thick=2
     
     
     oplot, [0,50], !nika.flux_uranus[0]*[1., 1.], col=0
     
     
     ;; elev-flux
     plot, elev[*] , flux[*, 0], /xs, yr=[ymin, ymax], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[2, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , flux[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, elev[w] , flux[w, 2], psym=8, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, elev[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
     if nout gt 0 then oplot, elev[wout] , flux[wout, 0], psym=7, col=0, thick=2
     ;;oplot, elev[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
     if nout gt 0 then oplot, elev[wout] , flux[wout, 2], psym=7, col=0, thick=2
     
     
     oplot, [0,90], !nika.flux_uranus[0]*[1., 1.], col=0
     
     ;; FWHM-elev
     f_max = min([max(fwhm[*, 0]),15.])
     f_min = min(fwhm[*, 0])*0.90
     plot, elev[*] , FWHM[*, 0], /xs, yr=[f_min,f_max], $
           xr=[10., 80.], psym=-4, $
           xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[3, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , fwhm[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, elev[w] , fwhm[w, 2], psym=8, col=(u+1.)*250./nut
        xyouts, 15., f_max - (f_max-f_min)*(u+0.5)/nut, ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
     if nout gt 0 then oplot, elev[wout] , fwhm[wout, 0], psym=7, col=0, thick=2
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
     if nout gt 0 then oplot, elev[wout] , fwhm[wout, 2], psym=7, col=0, thick=2
     
     oplot, [0,90], 12.0*[1., 1.], col=0
     
     ;; FWHM-tau 
     plot, tau_1mm[*] , fwhm[*, 0], /xs, yr=[min(fwhm[*, 0])*0.90,min([max(fwhm[*, 0]),15.])], $
           xr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[4, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_1mm[w] , fwhm[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, tau_1mm[w] , fwhm[w, 2], psym=8, col=(u+1.)*250./nut    
     endfor
     
     ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
     if nout gt 0 then oplot, tau_1mm[wout] , fwhm[wout, 0], psym=7, col=0, thick=2
     ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
     if nout gt 0 then oplot, tau_1mm[wout] , fwhm[wout, 2], psym=7, col=0, thick=2
     
     oplot, [0,50], 12.0*[1., 1.], col=0
     
     ;; tau-elev
     plot, elev[*] , tau_1mm[*], /xs, yr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], $
           xr=[10., 80.], psym=-4, $
           xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
           pos=pp1[5, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , tau_1mm[w], psym=8, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, elev[wtokeep] , tau_1mm[wtokeep, 0], psym=8, col=coltab[2]
     if nout gt 0 then oplot, elev[wout] , tau_1mm[wout, 0], psym=7, col=0, thick=2
     
     oplot, [0,90], 0.2*[1., 1.], col=0
     
     !p.multi=0
     outplot, /close
     
     
     ;; 2mm
     ;;--------------------------------------------
     
     wind, 1, 1, /free, xsize=1150, ysize=670
     outplot, file=project_dir+'/Correlation_plot_Uranus_2mm_'+$
              strtrim(nickname,2)+photocorr_suffixe+opa_suf, png=png, ps=ps
     my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
     
     ;; FWHM- Flux
     ymax = max( [!nika.flux_uranus[1]*1.2, max(flux[wtokeep, 1])]   )
     ymin = min( [!nika.flux_uranus[1]*0.7, min(flux[wtokeep, 1])]   )
     plot, fwhm[*, 1] , flux[*, 1], /xs, yr=[ymin, ymax], $
        xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[0, *]
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm[w, 1] , flux[w, 1], psym=8, col=(u+1.)*250./nut
        xyouts, 17.2, !nika.flux_uranus[1]*(1.2-0.5*(u+0.5)/nut), ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, fwhm[wtokeep, 1] , flux[wtokeep, 1], psym=8, col=coltab[1]
     if nout gt 0 then oplot, fwhm[wout, 1] , flux[wout, 1], psym=7, col=0, thick=2
     
     oplot, [0,50], !nika.flux_uranus[1]*[1., 1.], col=0
     
     if photocorr lt 1 then oplot, fwhm[*, 1], !nika.flux_uranus[1]*(18.0^2+!nika.fwhm_nom[1]^2)/(fwhm[*,1]^2+!nika.fwhm_nom[1]^2), col=0
     
     
     ;; tau-flux     
     plot, tau_2mm[*]/sin(elev[*]*!dtor) , flux[*, 1], /xs, yr=[ymin, ymax], $
           xr=[min(tau_2mm[wtokeep]/sin(elev[wtokeep]*!dtor))*0.5,$
               min([max(tau_2mm[*]/sin(elev[*]*!dtor)),1.])], psym=-4, $
           xtitle='Observed opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_2mm[w]/sin(elev[w]*!dtor) , flux[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, tau_2mm[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
     if nout gt 0 then oplot, tau_2mm[wout]/sin(elev[wout]*!dtor) , flux[wout, 1], psym=7, col=0, thick=2
     
     oplot, [0,50], !nika.flux_uranus[1]*[1., 1.], col=0
     
     
     ;; elev-flux
     plot, elev[*] , flux[*, 1], /xs, yr=[ymin, ymax], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[2, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , flux[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, elev[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
     if nout gt 0 then oplot, elev[wout] , flux[wout, 1], psym=7, col=0, thick=2
     oplot, [0,90], !nika.flux_uranus[1]*[1., 1.], col=0
     
     ;; FWHM-elev
     plot, elev[*] , FWHM[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[3, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , fwhm[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
     if nout gt 0 then oplot, elev[wout] , fwhm[wout, 1], psym=7, col=0, thick=2
     oplot, [0,90], 17.5*[1., 1.], col=0
     
     ;; FWHM-tau 
     plot, tau_2mm[*] , fwhm[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
           xr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[4, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_2mm[w] , fwhm[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     ;;oplot, tau_2mm[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
     if nout gt 0 then oplot, tau_2mm[wout] , fwhm[wout, 1], psym=7, col=0, thick=2
     oplot, [0,50], 17.5*[1., 1.], col=0
     
     ;; tau-elev
     plot, elev[*] , tau_2mm[*], /xs, yr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
           pos=pp1[5, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , tau_2mm[w], psym=8, col=(u+1.)*250./nut
     endfor
     
     ;;oplot, elev[wtokeep] , tau_2mm[wtokeep, 0], psym=8, col=coltab[1]
     if nout gt 0 then oplot, elev[wout] , tau_2mm[wout, 0], psym=7, col=0, thick=2
     
     oplot, [0,90], 0.1*[1., 1.], col=0
     
     !p.multi=0
     outplot, /close
     ;;---------------------------------------------------------------
     
     
     
     ;; Recalibrate
     ;;________________________________________________________________
     
     print, "============================================="
     print, 'Recalibration'
     print, "============================================"
     print, ''

     
     print,''
     print,'Shall I apply the absolute calibration gain ?'
     print,'.c to go ahead'
     stop
     
     if keyword_set(output_allinfo_file) then begin

        recalibration_coef = correction_coef
        
        ;;------------------------------------------------------------------
        ;; NEFD
        allscan_info.result_nefd_i_1mm = allscan_info.result_nefd_i_1mm*recalibration_coef[3]
        allscan_info.result_nefd_i_2mm = allscan_info.result_nefd_i_2mm*recalibration_coef[1]
        allscan_info.result_nefd_i1    = allscan_info.result_nefd_i1*recalibration_coef[0]
        allscan_info.result_nefd_i2    = allscan_info.result_nefd_i2*recalibration_coef[1]
        allscan_info.result_nefd_i3    = allscan_info.result_nefd_i3*recalibration_coef[2]
        ;; FLUX
        allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*recalibration_coef[3]
        allscan_info.result_flux_i_2mm = allscan_info.result_flux_i_2mm*recalibration_coef[1]
        allscan_info.result_flux_i1    = allscan_info.result_flux_i1*recalibration_coef[0]
        allscan_info.result_flux_i2    = allscan_info.result_flux_i2*recalibration_coef[1]
        allscan_info.result_flux_i3    = allscan_info.result_flux_i3*recalibration_coef[2]
        ;; FLUX CENTER
        allscan_info.result_flux_center_i_1mm = allscan_info.result_flux_center_i_1mm*recalibration_coef[3]
        allscan_info.result_flux_center_i_2mm = allscan_info.result_flux_center_i_2mm*recalibration_coef[1]
        allscan_info.result_flux_center_i1    = allscan_info.result_flux_center_i1*recalibration_coef[0]
        allscan_info.result_flux_center_i2    = allscan_info.result_flux_center_i2*recalibration_coef[1]
        allscan_info.result_flux_center_i3    = allscan_info.result_flux_center_i3*recalibration_coef[2]
        ;; ERRFLUX
        allscan_info.result_err_flux_i_1mm = allscan_info.result_err_flux_i_1mm*recalibration_coef[3]
        allscan_info.result_err_flux_i_2mm = allscan_info.result_err_flux_i_2mm*recalibration_coef[1]
        allscan_info.result_err_flux_i1    = allscan_info.result_err_flux_i1*recalibration_coef[0]
        allscan_info.result_err_flux_i2    = allscan_info.result_err_flux_i2*recalibration_coef[1]
        allscan_info.result_err_flux_i3    = allscan_info.result_err_flux_i3*recalibration_coef[2]
        ;; ERRFLUX CENTER
        allscan_info.result_err_flux_center_i_1mm = allscan_info.result_err_flux_center_i_1mm*recalibration_coef[3]
        allscan_info.result_err_flux_center_i_2mm = allscan_info.result_err_flux_center_i_2mm*recalibration_coef[1]
        allscan_info.result_err_flux_center_i1    = allscan_info.result_err_flux_center_i1*recalibration_coef[0]
        allscan_info.result_err_flux_center_i2    = allscan_info.result_err_flux_center_i2*recalibration_coef[1]
        allscan_info.result_err_flux_center_i3    = allscan_info.result_err_flux_center_i3*recalibration_coef[2]
        
        save, allscan_info, filename=output_dir+'/'+output_allinfo_file
     endif
        
     
     print, 'Reading ', input_kidpar_file
     kidpar = mrdfits( input_kidpar_file, 1, /silent)
     if calpera gt 0 then begin
        w1 = where( kidpar.array eq 1, nw1) 
        kidpar[w1].calib          *= !nika.flux_uranus[0]/flux_avg_1
        kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[0]/flux_avg_1
        w3 = where( kidpar.array eq 3, nw3) 
        kidpar[w3].calib          *= !nika.flux_uranus[0]/flux_avg_3
        kidpar[w3].calib_fix_fwhm *= !nika.flux_uranus[0]/flux_avg_3      
     endif else begin
        w1 = where( (kidpar.array eq 1 or kidpar.array eq 3),nw1) ; and $
                                ; kidpar.n_of_geom ge 2, nw1)
        kidpar[w1].calib          *= !nika.flux_uranus[0]/flux_avg_1
        kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[0]/flux_avg_1
     endelse
        
     w1 = where( kidpar.array eq 2 ,nw2) ;and $
                                ;kidpar.n_of_geom ge 2, nw1)
     kidpar[w1].calib          *= !nika.flux_uranus[1]/flux_avg_2
     kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[1]/flux_avg_2
     
     
     file_rootname = file_basename(input_kidpar_file, '.fits')
     output_kidpar_file = output_dir+"/Uranus_photometry_"+nickname+'/'+file_rootname+test_version_name+photocorr_suffixe+cal_suf+opa_suf+'.fits'
     
     stop
     
     print, 'Writing recalibrated kidpar in ', output_kidpar_file
     nk_write_kidpar, kidpar, output_kidpar_file
     
     for i=0, nscans-1 do print, "'"+strtrim(scan_list[i],2)+"', $"
     print, nscans
  endelse
  
  if nostop lt 1 then stop
  
end

