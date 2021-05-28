pro check_flux_density_ratio_secondary, runname, outdir, $
                                        png=png, ps=ps, pdf=pdf, $
                                        fwhm_stability=fwhm_stability, $
                                        obstau_stability=obstau_stability, $
                                        mwc349_stability=mwc349_stability, $
                                        opacorr_method=opacorr_method, $
                                        photocorr_method = photocorr_method, $
                                        nostop = nostop, savefile=savefile
  
  
  sources = ['URANUS', 'MWC349', 'CRL2688', 'NGC7027']
  nsource = 4

  ;; 
  

  ;; Opacity correction
  ;;---------------------------------------------
  skydip               = 0
  corrected_skydip     = 1
  taumeter             = 0

  ;; Photometric correction
  ;;---------------------------------------------
  do_photocorr         = 1
  photocorr_demo       = 0
  photocorr_point      = 1
  photocorr_thres_primary_1mm  = 1.25  ;1.08 ;1.06   
  photocorr_thres_primary_2mm  = 1.15  ;1.06 ;1.04 
  photocorr_thres_1mm  = 1.35 ; 1.15 ;1.12  ;; si 25% d'erreur sur photocorr -> 3% d'erreur sur flux
  photocorr_thres_2mm  = 1.25 ; 1.10 ;1.08  ;; si 25% d'erreur sur photocorr -> 2% d'erreur sur flux
  
  ;mwc349_stability = 1
  ;obstau_stability = 1
  
  if keyword_set(nostop) then nostop = 1 else nostop = 0
  if keyword_set(savefile) then savefile = 1 else savefile = 0
  
  ;; use keywords
  ;;________________________________________________________
  if keyword_set(opacorr_method) then begin
     skydip               = 0
     corrected_skydip     = 0
     taumeter             = 0
     case opacorr_method of
        1: skydip           = 1
        2: corrected_skydip = 1
        3: taumeter         = 1
     endcase
  endif
  if keyword_set(photocorr_method) then begin
     do_photocorr         = 1
     photocorr_demo       = 0
     photocorr_point      = 0
     case photocorr_method of
        1: do_photocorr     = 0
        2: photocorr_demo   = 1
        3: photocorr_point  = 1
     endcase
  endif

  
  ;; Automatic plot suffixe
  ;;--------------------------------------------------------------
  if skydip gt 0 then $
     plot_suffixe = '_skydip' else if corrected_skydip gt 0 then $
        plot_suffixe = '_corrected_skydip' else if taumeter gt 0 then $
           plot_suffixe = '_tau225' else print, 'UNKNOWN OPACITY CORRECTION METHOD'
  if do_photocorr gt 0 then begin
     if photocorr_demo gt 0 then plot_suffixe=plot_suffixe+'_photocorr_demo' else $
        if photocorr_point gt 0 then plot_suffixe=plot_suffixe+'_photocorr_pointing' $
        else print, 'UNKNOWN PHOTOMETRIC CORRECTION METHOD'
  endif
  
  ;;plot_suffixe = plot_suffixe+'_more_scans'
 
  ;; plot aspect
  ;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 550.
  wysize = 400.
  ;; plot size in files
  pxsize = 11.
  pysize =  8.
  ;; charsize
  charsize  = 1.2
  charthick = 3.0 ;0.7
  thick     = 3.0
  symsize   = 0.7
  


  ;;________________________________________________________________
  ;;
  ;; get all result files
  ;;________________________________________________________________
  ;;________________________________________________________________
  get_all_scan_result_file, runname, allresult_file, outputdir = outdir

  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
    
  flux_1mm     = 0.
  flux_a2      = 0.
  flux_a1      = 0.
  flux_a3      = 0.
  err_flux_1mm = 0.
  err_flux_a2  = 0.
  err_flux_a1  = 0.
  err_flux_a3  = 0.
  tau_1mm      = 0.0d0
  tau_a2       = 0.0d0
  tau_a1       = 0.0d0
  tau_a3       = 0.0d0
  fwhm_1mm     = 0.
  fwhm_a2      = 0.
  fwhm_a1      = 0.
  fwhm_a3      = 0.
  elev         = 0.
  obj          = ''
  day          = ''
  runid        = ''
  index_select = -1 ;; index of scans to include in the final selection
  ut           = ''
  ut_float     = 0.
  scan_list    = ''
  
  th_flux_1mm = 0.0d0
  th_flux_a2  = 0.0d0
  th_flux_a1  = 0.0d0
  th_flux_a3  = 0.0d0

  photocorr_flag = 0

  print,''
  print,'------------------------------------------'
  print,'   ', strupcase(runname)
  print,'------------------------------------------'
  print,'READING RESULT FILE: '
  print, allresult_file
  
  ;;
  ;;  restore result tables
  ;;____________________________________________________________
  restore, allresult_file, /v
  ;; allscan_info
  
  
  ;; select scans for the desired sources
  ;;____________________________________________________________
  wsource = -1
  for isou = 0, nsource-1 do begin
     wtokeep = where( strupcase(allscan_info.object) eq strupcase(sources[isou]), nkeep)
     if nkeep gt 0 then wsource = [wsource, wtokeep]
  endfor
  if n_elements(wsource) gt 1 then wsource = wsource[1:*] else begin
     print, 'no scan for the sources'
     stop
  endelse
  print, 'nb of found scan of the sources = ', n_elements(wsource)
  allscan_info = allscan_info[wsource]
  
  
  ;; remove known outliers
  ;;___________________________________________________________
  scan_list_ori = allscan_info.scan
  
  outlier_list =  ['20170223s16', $     ; dark test
                   '20170223s17', $     ; dark test
                   '20171024s171', $    ; focus scan
                   '20171026s235', $    ; focus scan
                   '20171028s313', $    ; RAS from tapas
                   '20180114s73', $     ; TBC
                   '20180116s94', $     ; focus scan
                   '20180118s212', $    ; focus scan
                   '20180119s241', $    ; Tapas comment: 'out of focus'
                   '20180119s242', $    ; Tapas comment: 'out of focus'
                   '20180119s243', $    ; Tapas comment: 'out of focus'   '20180122s98', $
                   '20180122s118', '20180122s119', '20180122s120', '20180122s121'] ;; the telescope has been heated
  
  out_index = 1
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
  allscan_info = allscan_info[out_index]
  
  nscans = n_elements(scan_list_run)
  print, "number of scan: ", nscans
  
  if nostop lt 1 then stop
  
  ;;
  ;; FLUX DENSITY EXPECTATIONS
  ;;____________________________________________________________
  th_flux_1mm_run = dblarr(nscans)
  th_flux_a2_run  = dblarr(nscans)
  th_flux_a1_run  = dblarr(nscans)
  th_flux_a3_run  = dblarr(nscans)
  
  ;; URANUS
  ;;------------------------------
  wu = where(strupcase(allscan_info.object) eq 'URANUS', nuranus)
  for iu=0, nuranus-1 do begin
     i = wu[iu]
     nk_scan2run, scan_list_run[i], run
     th_flux_1mm_run[i]     = !nika.flux_uranus[0]
     th_flux_a2_run[i]      = !nika.flux_uranus[1]
     th_flux_a1_run[i]      = !nika.flux_uranus[0]
     th_flux_a3_run[i]      = !nika.flux_uranus[0]
  endfor
  
  ;; MWC349
  ;;------------------------------
  wsou = where(strupcase(allscan_info.object) eq 'MWC349', nscan_sou)
  if nscan_sou gt 0 then begin
     lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
     nu = !const.c/(lambda*1e-3)/1.0d9
     th_flux           = 1.16d0*(nu/100.0)^0.60
     ;; assuming indep param
     err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
     th_flux_1mm_run[wsou]     = th_flux[0]
     th_flux_a2_run[wsou]      = th_flux[1]
     th_flux_a1_run[wsou]      = th_flux[0]
     th_flux_a3_run[wsou]      = th_flux[2]
  endif
  
  ;; CRL2688
  ;;------------------------------
  wsou = where(strupcase(allscan_info.object) eq 'CRL2688', nscan_sou)
  if nscan_sou gt 0 then begin
     ;;th_flux           = [2.91, 0.76]
     th_flux           = [2.51, 0.54] ;; JFL
     alpha = 2.44
     ;; Dempsey 2013
     flux_scuba2 = [5.64, 24.9] ;; Jy.beam-1
     lam_scuba2  = [850., 450.]*1.0d-6
     nu_scuba2   = !const.c/(lam_scuba2)/1.0d9
     th_flux_1mm_mbb = flux_scuba2[0] * (nu[0]/nu_scuba2[0])^(0.4)*$
                       black_body(nu[0],210.)/black_body(nu_scuba2[0],210.)
     th_flux_2mm_mbb = flux_scuba2[0] * (nu[1]/nu_scuba2[0])^(0.4)*$
                       black_body(nu[1], 210.)/black_body(nu_scuba2[0],210.)
     ;; 2.71, 0.72
     
     th_flux_1mm_alpha = flux_scuba2 * (nu[0]/nu_scuba2)^(2.44)    ;; 2.6801162   2.5068608
     th_flux_2mm_alpha = flux_scuba2 * (nu[1]/nu_scuba2)^(2.44)    ;; 0.70029542  0.65502500
     ;;
     th_flux_1mm_run[wsou]     = th_flux[0]
     th_flux_a2_run[wsou]      = th_flux[1]
     th_flux_a1_run[wsou]      = th_flux[0]
     th_flux_a3_run[wsou]      = th_flux[0]
  endif
  
  ;; NGC7027
  ;;------------------------------
  wsou = where(strupcase(allscan_info.object) eq 'NGC7027', nscan_sou)
  if nscan_sou gt 0 then begin
     th_flux           = [3.46, 4.26]
     th_flux_1mm_run[wsou]     = th_flux[0]
     th_flux_a2_run[wsou]      = th_flux[1]
     th_flux_a1_run[wsou]      = th_flux[0]
     th_flux_a3_run[wsou]      = th_flux[0]
  endif
  
  
  ;;
  ;; OPACITY CORRECTION
  ;;____________________________________________________________
  
  ;; 1/ getting tau_NIKA
  ;;tau_nika = dblarr(nscans, 4)
  if skydip gt 0 then begin
     tau_nika = [[allscan_info.result_tau_1], [allscan_info.result_tau_2], $
                 [allscan_info.result_tau_3], [allscan_info.result_tau_1mm]]
  endif
  
  if corrected_skydip gt 0 then begin
     tau_skydip = [[allscan_info.result_tau_1], [allscan_info.result_tau_2], $
                   [allscan_info.result_tau_3], [allscan_info.result_tau_1mm]]
     get_corrected_tau_skydip, tau_skydip, tau_nika
  endif
  
  if taumeter gt 0 then begin
     get_tau_nika_from_tau225, runname, allscan_info.scan, tau_nika, flux_driven=1, skydip_driven=0
  endif
  
  ;; 2/ implementing opacity correction
  sinel = sin(allscan_info.result_elevation_deg*!dtor)
  allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*exp((tau_nika[*,3]-allscan_info.result_tau_1mm)/sinel)
  allscan_info.result_flux_i1 = allscan_info.result_flux_i1*exp((tau_nika[*,0]-allscan_info.result_tau_1)/sinel)
  allscan_info.result_flux_i2 = allscan_info.result_flux_i2*exp((tau_nika[*,1]-allscan_info.result_tau_2)/sinel)
  allscan_info.result_flux_i3 = allscan_info.result_flux_i3*exp((tau_nika[*,2]-allscan_info.result_tau_3)/sinel) 
  
  
  ;;
  ;; photometric correction 
  ;;____________________________________________________________
  if do_photocorr gt 0 then begin
     
     ;; DEMO
     if photocorr_demo gt 0 then begin
        photocorr = 1
        ;; test 3
        fix_photocorr   = 0
        variable        = 0
        weakly_variable = 1
        delta_fwhm      = [0.4, 0.25, 0.4] ;; [0.2, 0.13, 0.2]
        delta_stable    = 0
        
        photocorr_using_pointing = 0
     endif
     
     ;; POINTING-BASED
     if photocorr_point gt 0 then begin
        photocorr = 1
        ;; test 3
        fix_photocorr   = 0
        variable        = 0
        weakly_variable = 1
        delta_fwhm      = 0
        delta_stable    = [0., 0., 0.]
        ;;
        photocorr_using_pointing = 1
     endif
     
     ;;
     ;; first scan selection
     ;;____________________________________________________________ 
     ;; 1/ allscan selection for photocorr
     to_use_photocorr = 1
     complement_index = 0
     beamok_index     = 0
     largebeam_index  = 0
     tauok_index      = 0
     hightau_index    = 0
     obsdateok_index  = 0
     afternoon_index  = 0
     fwhm_max         = 0
     nefd_index       = 0
     baseline_scan_selection, allscan_info, wtokeep, $
                     to_use_photocorr=to_use_photocorr, complement_index=wout, $
                     beamok_index = beamok_index, largebeam_index = wlargebeam,$
                     tauok_index = tauok_index, hightau_index=whitau3, $
                     osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                     fwhm_max = fwhm_max, nefd_index = nefd_index
     
     nscans_phot   = n_elements(wtokeep)
     
     fwhm = fltarr(nscans_phot, 4)
     flux = fltarr(nscans_phot, 4)
     for ii=0, nscans_phot-1 do begin
        i = wtokeep[ii]
        fwhm[ii, 0] = allscan_info[i].result_fwhm_1
        fwhm[ii, 1] = allscan_info[i].result_fwhm_2
        fwhm[ii, 2] = allscan_info[i].result_fwhm_3
        fwhm[ii, 3] = allscan_info[i].result_fwhm_1mm
        flux[ii, 0] = allscan_info[i].result_flux_i1
        flux[ii, 1] = allscan_info[i].result_flux_i2
        flux[ii, 2] = allscan_info[i].result_flux_i3
        flux[ii, 3] = allscan_info[i].result_flux_i_1mm
     endfor    
     tfwhm = transpose(fwhm)
     
     if photocorr_point gt 0 then begin
        day_run = allscan_info[wtokeep].day
        ut_otf = fltarr(nscans_phot)
        ut_run = strmid(allscan_info[wtokeep].ut, 0, 5)
        for i = 0, nscans_phot-1 do begin
           ut_otf[i]  = float((STRSPLIT(ut_run[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_run[i], ':', /EXTRACT))[1])/60.
        endfor
        get_pointing_based_beams, fwhm_point, day_run, ut_otf, runname
        tfwhm = transpose(fwhm_point)
     endif
     
     tflux = transpose(flux)
     corr_flux_factor = dblarr(4, nscans_phot)
     ;; delta_sidelobe needed for Uranus scans only (using 'demo')
     wu = where(strupcase(allscan_info[wtokeep].object) eq 'URANUS', nu, compl=wo)
     ;;fix = fix_photocorr+delta_stable ;; test 2
     fix = 0 ;; test 3
                                ;fix = fix_photocorr ;; test 1
     photometric_correction, tflux[*, wu], tfwhm[*, wu], corr_flux_factor_uranus, $
                             fix=fix, weakly_variable=weakly_variable,$
                             variable=variable, delta_fwhm=delta_fwhm, add1mm=1
     corr_flux_factor[*, wu] = corr_flux_factor_uranus
     ;; delta_sidelobe = 0 for weaker sources (and using 'pointing')
     photometric_correction, tflux[*, wo], tfwhm[*, wo], corr_flux_factor_other, $
                             fix=fix_photocorr, weakly_variable=weakly_variable,$
                             variable=variable, delta_fwhm=0, add1mm=1 ;, showplot=1
     corr_flux_factor[*, wo] = corr_flux_factor_other
     
     
     
     
     ;; test plot
     ;;index = indgen(nscans_phot)
     ;;plot, index, reform(corr_flux_factor[0, *]), yr=[0.85, 1.3], /ys, /nodata, $
     ;;      xtitle='scan index', ytitle= 'photometric correction factor', $
     ;;      xr=[-1, nscans_phot], /xs
     ;;oplot, [0, nscans_phot], [1, 1]
     ;;oplot, index, reform(corr_flux_factor[0, *]), col=80, psym=8
     ;;oplot, index, reform(corr_flux_factor[2, *]), col=50, psym=8
     ;;oplot, index, reform(corr_flux_factor[1, *]), col=250, psym=8
     ;;xyouts, index, replicate(0.87,nscans_phot), strmid(scan_list, 4, 10), charsi=0.7, orient=90
     ;;legendastro, ['A1', 'A3', 'A2'], textcol=[80, 50, 250], col=[80, 50, 250], $
     ;;             box=0, psym=[8, 8, 8]
                                ;stop
     
     photocorr_flag_run = intarr(nscans) ;; all scans
     
     wu = where(strupcase(allscan_info[wtokeep].object) eq 'URANUS', nu, compl=wo)
     wphot1=where(corr_flux_factor[0, wu] gt photocorr_thres_primary_1mm or $
                  corr_flux_factor[1, wu] gt photocorr_thres_primary_2mm or $
                  corr_flux_factor[2, wu] gt photocorr_thres_primary_1mm, nwphot1, compl=wphotok1)
     
     wphot2=where(corr_flux_factor[0, wo] gt photocorr_thres_1mm or $
                  corr_flux_factor[1, wo] gt photocorr_thres_2mm or $
                  corr_flux_factor[2, wo] gt photocorr_thres_1mm, nwphot2, compl=wphotok2)
     
     wphot = [wu[wphot1], wo[wphot2]]
     nwphot = nwphot1 + nwphot2
     wphotok = [wu[wphotok1], wo[wphotok2]]
     
     
     
     if nwphot gt 0 then begin
        print, 'high photo corr for scans ', allscan_info[wtokeep[wphot]].scan
        photocorr_flag_run[wtokeep[wphot]] = 1
        photocorr_flag = [photocorr_flag, photocorr_flag_run]
     endif
     
     raw_flux = flux
     for ia = 0, 3 do flux[*, ia] = flux[*, ia]*corr_flux_factor[ia,*]
     
     for i=0, nscans_phot-1 do begin
        ii = wtokeep[i]
        allscan_info[ii].result_flux_i1    = flux[i, 0]
        allscan_info[ii].result_flux_i2    = flux[i, 1]
        allscan_info[ii].result_flux_i3    = flux[i, 2]
        allscan_info[ii].result_flux_i_1mm = flux[i, 3]
     endfor
     
     wselect = wtokeep[wphotok]
     index_select_run = intarr(nscans)
     index_select_run[wselect] = 1 
     index_select = [index_select, index_select_run]
     
  endif
  ;; END PHOTOMETRIC CORRECTION
  ;;____________________________________________________________________________
  
  if do_photocorr lt 1 then begin
     ;;
     ;; second scan selection
     ;;____________________________________________________________ 
     ;; 2/ baseline selection
     to_use_photocorr = 0
     complement_index = 0
     beamok_index     = 0
     largebeam_index  = 0
     tauok_index      = 0
     hightau_index    = 0
     obsdateok_index  = 0
     afternoon_index  = 0
     fwhm_max         = 0
     nefd_index       = 0
     baseline_scan_selection, allscan_info, wbaseline, $
                     to_use_photocorr=to_use_photocorr, complement_index=wout, $
                     beamok_index = beamok_index, largebeam_index = wlargebeam,$
                     tauok_index = tauok_index, hightau_index=whitau3, $
                     osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                     fwhm_max = fwhm_max, nefd_index = nefd_index
     
     wselect = wbaseline
     mask = intarr(nscans)
     mask[wselect] = 1
     index_select = [index_select, mask]
     
     print, "baseline selection, nscans = "
     help, wselect
  endif
  
  ;;
  ;; ABSOLUTE CALIBRATION ON URANUS
  ;;____________________________________________________________
  ;; calib using the selection of Uranus scans
  wuranus = where(strupcase(allscan_info[wselect].object) eq 'URANUS', nuranus)
  wu = wselect[wuranus]
  
  
  flux_ratio_1   = avg( th_flux_a1_run[wu]/allscan_info[wu].result_flux_i1)
  flux_ratio_2   = avg( th_flux_a2_run[wu]/allscan_info[wu].result_flux_i2)
  flux_ratio_3   = avg( th_flux_a3_run[wu]/allscan_info[wu].result_flux_i3)
  flux_ratio_1mm = avg( th_flux_1mm_run[wu]/allscan_info[wu].result_flux_i_1mm)
  
  correction_coef = [flux_ratio_1, flux_ratio_2, flux_ratio_3, flux_ratio_1mm]
  print,'======================================================'
  print,"Flux correction coefficient A1: "+strtrim(correction_coef[0],2)
  print,"Flux correction coefficient A3: "+strtrim(correction_coef[2],2)
  print,"Flux correction coefficient A1&A3: "+strtrim(correction_coef[3],2)
  print,"Flux correction coefficient A2: "+strtrim(correction_coef[1],2)
  print,'======================================================'
  
  
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
  
  
  
  ;; add in tables
  ;;____________________________________________________________
  
  scan_list    = [scan_list, allscan_info.scan]
  
  flux_1mm     = [flux_1mm, allscan_info.result_flux_i_1mm]
  flux_a2      = [flux_a2, allscan_info.result_flux_i2]
  flux_a1      = [flux_a1, allscan_info.result_flux_i1]
  flux_a3      = [flux_a3, allscan_info.result_flux_i3]
  err_flux_1mm = [err_flux_1mm, allscan_info.result_err_flux_i_1mm]
  err_flux_a2  = [err_flux_a2, allscan_info.result_err_flux_i2]
  err_flux_a1  = [err_flux_a1, allscan_info.result_err_flux_i1]
  err_flux_a3  = [err_flux_a3, allscan_info.result_err_flux_i3]
  ;;
  fwhm_1mm     = [fwhm_1mm, allscan_info.result_fwhm_1mm]
  fwhm_a2      = [fwhm_a2, allscan_info.result_fwhm_2]
  fwhm_a1      = [fwhm_a1, allscan_info.result_fwhm_1]
  fwhm_a3      = [fwhm_a3, allscan_info.result_fwhm_3]
  ;;
  tau_1mm      = [tau_1mm, allscan_info.result_tau_1mm]
  tau_a2       = [tau_a2, allscan_info.result_tau_2mm]
  tau_a1       = [tau_a1, allscan_info.result_tau_1]
  tau_a3       = [tau_a3, allscan_info.result_tau_3]
  ;;
  elev         = [elev, allscan_info.result_elevation_deg*!dtor]
  obj          = [obj, allscan_info.object]
  day          = [day, allscan_info.day]
  runid        = [runid, replicate(runname, n_elements(allscan_info.day))]
  ut           = [ut, strmid(allscan_info.ut, 0, 5)]
  ;;
  th_flux_1mm  = [th_flux_1mm, th_flux_1mm_run]
  th_flux_a2   = [th_flux_a2, th_flux_a2_run]
  th_flux_a1   = [th_flux_a1, th_flux_a1_run]
  th_flux_a3   = [th_flux_a3, th_flux_a3_run]
  ;;
  
  ;; discard the placeholder first element of each tables
  flux_1mm     = flux_1mm[1:*]
  flux_a2      = flux_a2[1:*]
  flux_a1      = flux_a1[1:*]
  flux_a3      = flux_a3[1:*]
  err_flux_1mm = err_flux_1mm[1:*]
  err_flux_a2  = err_flux_a2[1:*]
  err_flux_a1  = err_flux_a1[1:*]
  err_flux_a3  = err_flux_a3[1:*]
  ;;
  fwhm_1mm     = fwhm_1mm[1:*]
  fwhm_a2      = fwhm_a2[1:*]
  fwhm_a1      = fwhm_a1[1:*]
  fwhm_a3      = fwhm_a3[1:*]
  ;;
  tau_1mm      = tau_1mm[1:*]
  tau_a2       = tau_a2[1:*]
  tau_a1       = tau_a1[1:*]
  tau_a3       = tau_a3[1:*]
  ;;
  elev         = elev[1:*]
  obj          = obj[1:*]
  day          = day[1:*]
  runid        = runid[1:*]
  ut           = ut[1:*]
  index_select = index_select[1:*]
  if do_photocorr gt 0 and photocorr_point gt 0 then photocorr_flag = photocorr_flag[1:*]
  scan_list      = scan_list[1:*]
  ;;
  th_flux_1mm  = th_flux_1mm[1:*]
  th_flux_a2   = th_flux_a2[1:*]
  th_flux_a1   = th_flux_a1[1:*]
  th_flux_a3   = th_flux_a3[1:*]
  
  ;; calculate ut_float 
  nscans      = n_elements(day)
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor

  
  
  
  if nostop lt 1 then stop

  ;;________________________________________________________________
  ;;
  ;; plots
  ;;________________________________________________________________
  ;;________________________________________________________________

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14

  ut_tab = ['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

  ut_col = [10, 35, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25, 15]
  
  nut = n_elements(ut_tab)-1

  wselect = where(index_select gt 0, nselect)
  
  planet_fwhm_max  = [13.0, 18.3, 13.0]
  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3


  
  ;;
  ;;   MWC349 3 RUNS : FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(mwc349_stability) then begin
     
     w_total = where(obj eq 'MWC349', n_total)
     
     wselect = where(index_select gt 0 and obj eq 'MWC349', nselect)
     wsource = wselect


     ;; color correction from JFL Table (A.1)
     cc = [0.969, 0.996, 0.987]
     cc_1mm = mean(cc([0, 2]))
     cc = [cc, cc_1mm]
     ;;cc = [1.0, 1.0, 1.0, 1.0]
     
     ;; Correction of the beam-widening effect due to Uranus disc
     cu = [1.016, 1.007, 1.016, 1.016]
     cu = [0.9855, 0.9936, 0.9855, 0.9855]
     cu = [1.0, 1.0, 1.0, 1.0]
     
     flux_ratio_1mm[w_total] = flux_ratio_1mm[w_total]*cc[3]*cu[3] 
     flux_ratio_a1[w_total]  = flux_ratio_a1[w_total]*cc[0]*cu[0] 
     flux_ratio_a2[w_total]  = flux_ratio_a2[w_total]*cc[1]*cu[1] 
     flux_ratio_a3[w_total]  = flux_ratio_a3[w_total]*cc[2]*cu[2] 
    
     ntot_tab    = n_total
     nselect_tab = nselect
     bias_tab    = dblarr(4)
     rms_tab     = dblarr(4)
     
     
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_1mm[wsource])]   )
     ymin = min( [0.6, min(flux_ratio_1mm[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     ww = wsource
     wt = w_total
     oplot, exp(-tau_1mm[ww]/sin(elev[ww])), flux_ratio_1mm[ww], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     wflag = where(photocorr_flag[wt] gt 0, nflag)
     if nflag gt 0 then oplot, exp(-tau_1mm[wt[wflag]]/sin(elev[wt[wflag]])), flux_ratio_1mm[wt[wflag]], $
                                  psym=cgsymcat('OPENCIRCLE', thick=thick*0.25), col=col_n2r9
     bias = mean(flux_ratio_1mm[ww])
     rms  = stddev(flux_ratio_1mm[ww])/mean(flux_ratio_1mm[ww])*100
     print, 'bias = ', bias
     bias_tab[3] =  bias
     print, 'rel.rms = ',rms
     rms_tab[3] = rms
   
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     print, ''
     print, ' A1 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a1[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a1[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, exp(-tau_a1[wsource]/sin(elev[wsource])), flux_ratio_a1[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     bias = mean(flux_ratio_a1[wsource])
     rms  = stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource])*100
     print, 'bias = ', bias
     bias_tab[0] =  bias
     print, 'rel.rms = ',rms
     rms_tab[0] = rms
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     print, ''
     print, ' A3 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a3[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a3[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     oplot, exp(-tau_a3[wsource]/sin(elev[wsource])), flux_ratio_a3[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     bias = mean(flux_ratio_a3[wsource])
     rms = stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource])*100
     print, 'bias = ', bias
     bias_tab[2] =  bias
     print, 'rel.rms = ',rms
     rms_tab[2] = rms
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a2[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a2[wsource])]   )
     xmax  = 0.95
     xmin  = 0.55
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     oplot, exp(-tau_a2[wsource]/sin(elev[wsource])), flux_ratio_a2[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     bias = mean(flux_ratio_a2[wsource])
     rms  = stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource])*100
     print, 'bias = ', bias
     bias_tab[1] =  bias
     print, 'rel.rms = ',rms
     rms_tab[1] = rms
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
     outplot, /close
     

     quoi = ['A1', 'A2', 'A3', '1mm']
     calib_run = runname
     ;; SAUVEGARDE FICHIER
     if savefile gt 0 then begin
        get_lun, lun
        openw, lun, dir+'Results_flux_density_ratio_MWC349'+plot_suffixe+'.txt'
        printf, lun, ''
        printf, lun, calib_run
        printf, lun, 'ntot = ', ntot_tab
        printf, lun, 'nselect = ', nselect_tab
        for ia = 0, 3 do begin
           printf, lun, quoi[ia], ' bias = ', bias_tab[ia], ', rms = ', rms_tab[ia]
        endfor
        
        close, lun
     endif
     
     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epstopdf '+dir+'plot_flux_density_ratio_MWC349_obstau'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif
     
     
     if nostop lt 1 then  stop

  endif



  
  ;;
  ;;   PLOT 3 SOURCES: FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     col_tab = [col_mwc349, col_crl2688, col_ngc7027]

     wsource = where(index_select gt 0, n_select)
     
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[wsource])+0.02 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[wsource])-0.02]   )
     xmax  = 0.8
     xmin  = 0.     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_obstau'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, tau_1mm/sin(elev), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata

     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_1mm[wsource[w]]/sin(elev[wsource[w]]), flux_ratio_1mm[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
  
     ;;
     legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[0.05, ymin+0.10]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, 0.68, ymax-0.05, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a1[wsource])-0.02]   )
     xmax  = 0.8
     xmin  = 0.
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_obstau'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, tau_a1/sin(elev), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_a1[wsource[w]]/sin(elev[wsource[w]]), flux_ratio_a1[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[0.05, ymin+0.10], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, 0.7, ymax-0.05, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a3[wsource])-0.02]   )
     xmax  = 0.8
     xmin  = 0.

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_obstau'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, tau_a3/sin(elev), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_a3[wsource[w]]/sin(elev[wsource[w]]), flux_ratio_a3[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[0.05, ymin+0.10], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, 0.7, ymax-0.05, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a2[wsource])-0.02]   )
     xmax  = 0.5
     xmin  = 0.
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_obstau'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, tau_a2/sin(elev), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_a2[wsource[w]]/sin(elev[wsource[w]]), flux_ratio_a2[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[0.03, ymax-0.05], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, 0.45, ymax-0.05, 'A2', col=0
     
     outplot, /close
     
     if nostop lt 1 then stop

  endif
  
  ;;
  ;;   PLOT 3 SOURCES: FLUX RATIO AGAINST FWHM
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(fwhm_stability) then begin
     
     col_tab = [col_mwc349, col_crl2688, col_ngc7027]
     
     
     wsource = where(index_select gt 0, n_select)
    
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[wsource] )+0.02 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_1mm, flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata

     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_1mm[wsource[w]], flux_ratio_1mm[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
  
     ;;
     legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[xmax-(xmax-xmin)*0.25, ymin+0.10]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmax-0.5, ymax-0.05, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a1[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a1, flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a1[wsource[w]], flux_ratio_a1[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+0.2, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a3[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a3, flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a3[wsource[w]], flux_ratio_a3[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+0.2, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a2[wsource])-0.02]   )
     xmax  = 19.5
     xmin  = 17.2
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a2, flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[wsource] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a2[wsource[w]], flux_ratio_a2[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+0.2, ymax-0.05], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A2', col=0
     
     outplot, /close
     
     
     

     
     if nostop lt 1 then stop

  endif

  
  if nostop lt 1 then stop
  
     

end
