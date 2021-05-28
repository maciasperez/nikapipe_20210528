pro check_flux_density_ratio_all,runname, outdir,$
                                 png=png, ps=ps, pdf=pdf, $
                                 obsdate_stability=obsdate_stability, $
                                 fwhm_stability=fwhm_stability, $
                                 obstau_stability=obstau_stability, $
                                 opacorr_method=opacorr_method, $
                                 photocorr_method = photocorr_method, $
                                 nostop = nostop, savefile = savefile
  
  ;; Flux threshold for sources selection
  ;;--------------------------------------------
  flux_threshold_1mm = 1.0d0
  flux_threshold_2mm = 0.5d0
  
  ;; number of scan thresholding for source selection
  nscan_threshold = 10
  
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
  photocorr_thres_primary_1mm  = 1.25 ; 1.08 ;1.06   
  photocorr_thres_primary_2mm  = 1.15 ; 1.06 ;1.04 
  photocorr_thres_1mm  = 1.35 ; 1.15 ;1.12  ;; si 25% d'erreur sur photocorr -> 3% d'erreur sur flux
  photocorr_thres_2mm  = 1.25 ; 1.10 ;1.08  ;; si 25% d'erreur sur photocorr -> 2% d'erreur sur flux
  
  
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
  
  ;plot_suffixe = plot_suffixe+'_more_scans'
  
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
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 1.0
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
  ut           = ''
  ut_float     = 0.
  scan_list    = ''
  
  th_flux_1mm = 0.0d0
  th_flux_a2  = 0.0d0
  th_flux_a1  = 0.0d0
  th_flux_a3  = 0.0d0

  ntot_tab    = 0L
  nselect_tab = 0L
  
  print,''
  print,'------------------------------------------'
  print,'   ', runname
  print,'------------------------------------------'
  print,'READING RESULT FILE: '
  print, allresult_file
  
  ;;
  ;;  restore result tables
  ;;____________________________________________________________
  restore, allresult_file, /v
  ;; allscan_info
  
  
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
                   '20180122s118', '20180122s119', '20180122s120', '20180122s121', $ ;; the telescope has been heated
                   '20170226s415', $                                                 ;; wrong ut time
                   '20170226s416','20170226s417', '20170226s418', '20170226s419']    ;; defocused beammaps
  
  if do_photocorr gt 0 then begin
     outlier_list = [outlier_list, $
                     '20171024s202', '20171024s220'] ;; during a pointing session
  endif
  
  out_index = 1
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
  allscan_info = allscan_info[out_index]
  
  nscans = n_elements(scan_list_run)
  print, "number of scan: ", nscans
  
  if nostop lt 1 then stop
  
  ;; NSCAN TOTAL ESTIMATE :
  ;; select scans for the desired sources
  ;;____________________________________________________________
  ;; flux thresholding
  wkeep = where( allscan_info.result_flux_i_1mm ge flux_threshold_1mm and $
                 allscan_info.result_flux_i2    ge flux_threshold_2mm, nkeep)
  print, 'nb of found scan of the sources = ', nkeep
  allscan_info = allscan_info[wkeep]
  
  wq = where(allscan_info.object eq '0316+413', nq)
  if nq gt 0 then allscan_info[wq].object = '3C84'
  
  ;; nscan thresholding
  wsource = -1
  allsources  = strupcase(allscan_info.object)
  source_list = allsources[uniq(allsources, sort(allsources))]
  nsources = n_elements(source_list)
  for isou = 0, nsources-1 do begin
     w = where(allsources eq source_list[isou], nn)
     if (nn ge nscan_threshold or source_list[isou] eq 'URANUS') then wsource = [wsource, w] 
  endfor
  if n_elements(wsource) gt 1 then wsource = wsource[1:*] else $
     print, 'NO SOURCE WITH ENOUGHT SCANS'
  allscan_info = allscan_info[wsource]
  
  ;; discarding resolved sources for photometric correction
  allsources  = strupcase(allscan_info.object)
  wreso = where(allsources eq 'MARS' or allsources eq 'NGC7027', wres, compl=wpoint)
  if do_photocorr gt 0 then allscan_info = allscan_info[wpoint]
  
  nscans       = n_elements(allscan_info)
  ntot_tab     = nscans
  
  ;;
  ;; Scan selection
  ;;____________________________________________________________ 
  to_use_photocorr = do_photocorr
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
  allscan_info = allscan_info[wtokeep]
  
  
  ;; select scans for the desired sources
  ;;____________________________________________________________
  ;; flux thresholding
  wkeep = where( allscan_info.result_flux_i_1mm ge flux_threshold_1mm and $
                 allscan_info.result_flux_i2    ge flux_threshold_2mm, nkeep)
  print, 'nb of found scan of the sources = ', nkeep
  allscan_info = allscan_info[wkeep]
  
  wq = where(allscan_info.object eq '0316+413', nq)
  if nq gt 0 then allscan_info[wq].object = '3C84'
  
  ;; nscan thresholding
  wsource = -1
  allsources  = strupcase(allscan_info.object)
  source_list = allsources[uniq(allsources, sort(allsources))]
  nsources = n_elements(source_list)
  for isou = 0, nsources-1 do begin
     w = where(allsources eq source_list[isou], nn)
     if (nn ge nscan_threshold or source_list[isou] eq 'URANUS') then wsource = [wsource, w] 
  endfor
  if n_elements(wsource) gt 1 then wsource = wsource[1:*] else $
     print, 'NO SOURCE WITH ENOUGHT SCANS'
  allscan_info = allscan_info[wsource]
  
  ;; discarding resolved sources for photometric correction
  allsources  = strupcase(allscan_info.object)
  wreso = where(allsources eq 'MARS' or allsources eq 'NGC7027', wres, compl=wpoint)
  if do_photocorr gt 0 then allscan_info = allscan_info[wpoint]
  
  nscans       = n_elements(allscan_info)
  
  
  
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
     get_tau_nika_from_tau225, runname, allscan_info.scan, tau_nika, atm=0, flux_driven=1, skydip_driven=0
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
     
     fwhm = fltarr(nscans, 4)
     flux = fltarr(nscans, 4)
     for i=0, nscans-1 do begin
        fwhm[i, 0] = allscan_info[i].result_fwhm_1
        fwhm[i, 1] = allscan_info[i].result_fwhm_2
        fwhm[i, 2] = allscan_info[i].result_fwhm_3
        fwhm[i, 3] = allscan_info[i].result_fwhm_1mm
        flux[i, 0] = allscan_info[i].result_flux_i1
        flux[i, 1] = allscan_info[i].result_flux_i2
        flux[i, 2] = allscan_info[i].result_flux_i3
        flux[i, 3] = allscan_info[i].result_flux_i_1mm
     endfor    
     tfwhm = transpose(fwhm)
     
     if photocorr_point gt 0 then begin
        
        nscans = n_elements(allscan_info.ut)
        day_run = allscan_info.day
        ut_otf  = fltarr(nscans)
        ut_run  = strmid(allscan_info.ut, 0, 5)
        for i = 0, nscans-1 do begin
           ut_otf[i]  = float((STRSPLIT(ut_run[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_run[i], ':', /EXTRACT))[1])/60.
        endfor
        get_pointing_based_beams, fwhm_point, day_run, ut_otf, runname
        tfwhm = transpose(fwhm_point)
     endif
     
     tflux = transpose(flux)
     
     ;; implementing photometric correction
     ;;--------------------------------------------------------------------------
     corr_flux_factor = dblarr(4, nscans)
     ;; delta_sidelobe needed for Uranus scans only (using 'demo')
     wu = where(strupcase(allscan_info.object) eq 'URANUS', nu, compl=wo)
     fix = fix_photocorr+delta_stable ;; test 2
     fix = 0
     photometric_correction, tflux[*, wu], tfwhm[*, wu], corr_flux_factor_uranus, $
                             fix=fix, weakly_variable=weakly_variable,$
                             variable=variable, delta_fwhm=delta_fwhm, add1mm=1
     corr_flux_factor[*, wu] = corr_flux_factor_uranus
     ;; delta_sidelobe = 0 for weaker sources (and using 'pointing')
     photometric_correction, tflux[*, wo], tfwhm[*, wo], corr_flux_factor_other, $
                             fix=fix_photocorr, weakly_variable=weakly_variable,$
                             variable=variable, delta_fwhm=0, add1mm=1
     corr_flux_factor[*, wo] = corr_flux_factor_other
     
     
     ;; test plot
     ;;index = indgen(nscans)
     ;;plot, index, reform(corr_flux_factor[0, *]), yr=[0.85, 1.3], /ys, /nodata, $
        ;;      xtitle='scan index', ytitle= 'photometric correction factor', $
     ;;      xr=[-1, nscans], /xs
     ;;oplot, [0, nscans], [1, 1]
     ;;oplot, index, reform(corr_flux_factor[0, *]), col=80, psym=8
     ;;oplot, index, reform(corr_flux_factor[2, *]), col=50, psym=8
     ;;oplot, index, reform(corr_flux_factor[1, *]), col=250, psym=8
     ;;xyouts, index, replicate(0.87,nscans), strmid(scan_list, 4, 10), charsi=0.7, orient=90
     ;;legendastro, ['A1', 'A3', 'A2'], textcol=[80, 50, 250], col=[80, 50, 250], $
     ;;             box=0, psym=[8, 8, 8]
     
     wu = where(strupcase(allscan_info.object) eq 'URANUS', nu, compl=wo)
     wphot1=where(corr_flux_factor[0, wu] gt photocorr_thres_primary_1mm or $
                  corr_flux_factor[1, wu] gt photocorr_thres_primary_2mm or $
                  corr_flux_factor[2, wu] gt photocorr_thres_primary_1mm, nwphot1, compl=wphotok1)
     
     wphot2=where(corr_flux_factor[0, wo] gt photocorr_thres_1mm or $
                  corr_flux_factor[1, wo] gt photocorr_thres_2mm or $
                  corr_flux_factor[2, wo] gt photocorr_thres_1mm, nwphot2, compl=wphotok2)
     
     wphot = [wu[wphot1], wo[wphot2]]
     nwphot = nwphot1 + nwphot2
     wphotok = [wu[wphotok1], wo[wphotok2]]
     
     if nwphot gt 0 then print, 'high photo corr for scans ', allscan_info[wphot].scan
     
     raw_flux = flux
     for ia = 0, 3 do flux[*, ia] = flux[*, ia]*corr_flux_factor[ia,*]
     
     for i=0, nscans-1 do begin
        allscan_info[i].result_flux_i1    = flux[i, 0]
        allscan_info[i].result_flux_i2    = flux[i, 1]
        allscan_info[i].result_flux_i3    = flux[i, 2]
        allscan_info[i].result_flux_i_1mm = flux[i, 3]
     endfor
     
     allscan_info = allscan_info[wphotok]
     nscans = n_elements(allscan_info)
     
  endif
  ;; END PHOTOMETRIC CORRECTION
  ;;____________________________________________________________________________
  
  
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
  
  ;;
  ;; ABSOLUTE CALIBRATION ON URANUS
  ;;____________________________________________________________
  ;; calib using all Uranus scans
  wu = where(strupcase(allscan_info.object) eq 'URANUS', nuranus)
  
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
  
  
  ;;
  ;; MEDIAN FLUX DENSITY
  ;;____________________________________________________________
  allsources  = strupcase(allscan_info.object)
  source_list = allsources[uniq(allsources, sort(allsources))]
  ;; remove URANUS from the list
  w = where(source_list eq 'URANUS', compl = w_other)
  source_list=source_list[w_other]
  nsources = n_elements(source_list)
  
  for isou = 0, nsources-1 do begin
     wsou = where(allsources eq source_list[isou], nn)
     th_flux_1mm_run[wsou]     = median(allscan_info[wsou].result_flux_i_1mm)
     th_flux_a2_run[wsou]      = median(allscan_info[wsou].result_flux_i2)
     th_flux_a1_run[wsou]      = median(allscan_info[wsou].result_flux_i1)
     th_flux_a3_run[wsou]      = median(allscan_info[wsou].result_flux_i3)
  endfor
  
  
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
  scan_list      = scan_list[1:*]
  ;;
  th_flux_1mm  = th_flux_1mm[1:*]
  th_flux_a2   = th_flux_a2[1:*]
  th_flux_a1   = th_flux_a1[1:*]
  th_flux_a3   = th_flux_a3[1:*]
  
  ;; calculate ut_float 
  nscans      = n_elements(elev)
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor
  
  if nostop lt 1 then stop
  
  
  ;;________________________________________________________________
  ;;
  ;;
  ;;          PLOTS
  ;;
  ;;________________________________________________________________
  ;;________________________________________________________________

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14

  ut_tab = ['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

  ut_col = [10, 35, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25, 15]
  
  nut = n_elements(ut_tab)-1

  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3

  
  ;;
  ;;   FLUX RATIO COLOR-CODED FROM THE UT
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obsdate_stability) then begin
     
     w_total = indgen(nscans)
     wsource = w_total
     
      ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_1mm[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_1mm[wsource])]   )
     xmax  = 0.95
     xmin  = 0.35     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_1mm[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_1mm[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=ut_col[u], symsize=symsize      
     endfor
     
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.41, ymax-0.1], spacing=0.9
     ;;
     oplot, [0.5,xmax], [1., 1.], col=0
     oplot, [0.5,xmax], [1., 1.]+stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [0.5,xmax], [1., 1.]-stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [0.5, 0.5], [ymin, ymax], col=170
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
     xmin  = 0.35
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_a1[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a1[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=ut_col[u], symsize=symsize         
     endfor
     
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.41, ymax-0.1], spacing=0.9
     
     oplot, [0.5,xmax], [1., 1.], col=0
     oplot, [0.5,xmax], [1., 1.]+stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [0.5,xmax], [1., 1.]-stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [0.5, 0.5], [ymin, ymax], col=170
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
     xmin  = 0.35

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_a3[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a3[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=ut_col[u] , symsize=symsize        
     endfor
     
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.41, ymax-0.1], spacing=0.9
     ;;
    
     oplot, [0.5,xmax], [1., 1.], col=0
     oplot, [0.5,xmax], [1., 1.]+stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [0.5,xmax], [1., 1.]-stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [0.5, 0.5], [ymin, ymax], col=170
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
     xmin  = 0.50
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_a2[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a2[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=ut_col[u] , symsize=symsize        
     endfor
     
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.52, ymax-0.1], spacing=0.9
     ;;
     oplot, [0.6,xmax], [1., 1.], col=0
     oplot, [0.6,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [0.6,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [0.6, 0.6], [ymin, ymax], col=170
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
     outplot, /close
     
     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epstopdf '+dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif
     
     
  endif

     
  ;;
  ;;   FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     w_total = indgen(nscans)
     wsource = w_total
     
     bias_tab    = dblarr(4)
     rms_tab     = dblarr(4)
     
     
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_1mm[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_1mm[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, exp(-tau_1mm[wsource]/sin(elev[wsource])), flux_ratio_1mm[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9, symsize=symsize
     bias_tab[3] = mean(flux_ratio_1mm[wsource])
     rms_tab[3]  = stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource])*100
     print, 'bias = ', bias_tab[3]
     print, 'rel.rms = ', rms_tab[3]
                                     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]+3.*stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-3.*stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
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
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, exp(-tau_a1[wsource]/sin(elev[wsource])), flux_ratio_a1[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9, symsize=symsize   
     bias_tab[0] = median(flux_ratio_a1[wsource])
     rms_tab[0]  = stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource])*100
     print, 'bias = ', bias_tab[0]
     print, 'rel.rms = ', rms_tab[0] 
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]+3.0*stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-3.0*stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
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
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     oplot, exp(-tau_a3[wsource]/sin(elev[wsource])), flux_ratio_a3[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9, symsize=symsize   
     bias_tab[2] = median(flux_ratio_a3[wsource])
     rms_tab[2]  = stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource])*100
     print, 'bias = ', bias_tab[2]
     print, 'rel.rms = ', rms_tab[2]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]+3.0*stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-3.0*stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
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
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     oplot, exp(-tau_a2[wsource]/sin(elev[wsource])), flux_ratio_a2[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9, symsize=symsize   
     bias_tab[1] = median(flux_ratio_a2[wsource])
     rms_tab[1]  = stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource])*100
     print, 'bias = ', bias_tab[1]
     print, 'rel.rms = ', rms_tab[1]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+3.0*stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-3.0*stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
     outplot, /close
     
     ;; SAUVEGARDE FICHIER
     quoi = ['A1', 'A2', 'A3', '1mm']
     calibrun = runname
     if savefile gt 0 then begin
        get_lun, lun
        openw, lun, dir+'Results_flux_density_ratio_allbright'+plot_suffixe+'.txt'
        printf, lun, ''
        printf, lun, calibrun
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
           spawn, 'epstopdf '+dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif


     ;; HISTOGRAMMES
     
     suf  = ['_a1', '_a2', '_a3', '_1mm']
     quoi = ['A1', 'A2', 'A3', 'A1&A3']

     ratio = [[flux_ratio_a1[wsource]], [flux_ratio_a2[wsource]], $
              [flux_ratio_a3[wsource]] ,[flux_ratio_1mm[wsource]] ]

     limits = [[0.6,1.4], [0.6,1.4], [0.6,1.4], [0.6,1.4]] 
     
     for ia = 0, 3 do begin
        
        print, ''
        print, ' Histo ', quoi[ia]
        print, '-----------------------'
        ymax = max( [limits[1, ia], max(ratio[*, ia]) ])
        ymin = min( [limits[0, ia], min(ratio[*, ia]) ])
        bin  = 0
        
        wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
        outfile = dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+suf[ia]
        outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
        
        f = ratio[*,ia]
        
        np_histo, [f], out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=25, fit=1, noerase=0, position=0, nolegend=1, colorfit=165, thickfit=3., nterms_fit=3, xtitle="Flux density ratio"

        leg_txt = ['N: '+strtrim(string(n_elements(f), format='(i8)'),2), $
                   '!7r!3: '+strtrim(string(out_gpar[0,2]*100, format='(f8.1)'),2)+'%']
        
        legendastro, leg_txt, textcol=0, box=0, pos=[ymax-(ymax-ymin)*0.25, max(out_yhist)]
        legendastro, quoi[ia], textcol=0, box=0, pos=[ymin+(ymax-ymin)*0.07, max(out_yhist)]
     
        outplot, /close
        
        
        if keyword_set(pdf) then $
           spawn, 'epstopdf '+dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+suf[ia]+'.eps'
        
     endfor       

     ;; histo 1 et 2 mm
     ratio_str = {a:flux_ratio_1mm[wsource], b:flux_ratio_a2[wsource]}

     limits = [[0.6,1.4], [0.6,1.4]] 
     
     ymax = max( [limits[1, 0], max(ratio[*, 0]) ])
     ymin = min( [limits[0, 0], min(ratio[*, 0]) ])
     bin  = 0
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+'_1n2mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
       
     ;;np_histo, ratio_str, out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=[col_a3, col_a2], noerase=0, position=0, nolegend=1, xtitle="Flux density ratio", /blend
     
     np_histo, ratio_str, out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=[col_a3, col_a2], noerase=0, position=0, nolegend=1, xtitle="Flux density ratio"

     polyfill, ymin+[1,1,2,2]*(ymax-ymin)*0.07, max(out_yhist)+[0,-1,-1,0]*max(out_yhist)*0.06, col=col_a3
     oplot, ymin+[1,1,2,2, 1]*(ymax-ymin)*0.07, max(out_yhist)+[0,-1,-1,0, 0]*max(out_yhist)*0.06, col=0
     
     polyfill, ymin+[1,1,2,2]*(ymax-ymin)*0.07, max(out_yhist)+[-1.7,-2.7,-2.7,-1.7]*max(out_yhist)*0.06, col=col_a2
     oplot, ymin+[1,1,2,2, 1]*(ymax-ymin)*0.07, max(out_yhist)+[-1.7,-2.7,-2.7,-1.7, -1.7]*max(out_yhist)*0.06, col=0

     xyouts, ymin+2.2*(ymax-ymin)*0.07, max(out_yhist)-1.*max(out_yhist)*0.06, 'A1&A3', col=0
     xyouts, ymin+2.2*(ymax-ymin)*0.07, max(out_yhist)-2.7*max(out_yhist)*0.06, 'A2', col=0
     
     leg_txt = ['N: '+strtrim(string(n_elements(wsource), format='(i8)'),2), $
                '!7r1!3: '+strtrim(string(rms_tab[3,3], format='(f8.1)'),2)+'%', $
                '!7r2!3: '+strtrim(string(rms_tab[1,3], format='(f8.1)'),2)+'%']
     legendastro, leg_txt, textcol=[0,col_a3, col_a2], box=0, pos=[ymax-(ymax-ymin)*0.3, max(out_yhist)-1.*max(out_yhist)*0.06]
     
     outplot, /close

     
     if keyword_set(pdf) then $
        spawn, 'epstopdf '+dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+'_1n2mm.eps'
        


     
     if nostop lt 1 then stop

  endif

  ;;
  ;;   FLUX RATIO AGAINST FWHM
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(fwhm_stability) then begin
     
     w_total = indgen(nscans)
     wsource = w_total
      
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[wsource] )+0.02 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_1mm, flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, fwhm_1mm[wsource], flux_ratio_1mm[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     ;;
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
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a1, flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, fwhm_a1[wsource], flux_ratio_a1[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     ;;
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
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a3, flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     oplot, fwhm_a3[wsource], flux_ratio_a3[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     ;;
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
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a2, flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     oplot, fwhm_a2[wsource], flux_ratio_a2[wsource], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_n2r9
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A2', col=0
     
     outplot, /close
     
     
     

     
     if nostop lt 1 then stop

  endif

  
  if nostop lt 1 then stop
  
     

end
