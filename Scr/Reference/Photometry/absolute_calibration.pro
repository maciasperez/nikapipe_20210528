
;;
;;   REFERENCE LAUNCHER SCRIPT FOR ABSOLUTE CALIBRATION
;;
;;   LP, March 2020
;;_________________________________________________

pro absolute_calibration, runname, input_kidpar_file, $
                          multiple_kidpars = multiple_kidpars, $
                          root_dir = root_dir, $
                          output_dir=output_dir, $
                          showplot=showplot, png=png, ps=ps, pdf=pdf, $
                          outlier_scan_list = outlier_scan_list, $
                          pas_a_pas = pas_a_pas, $
                          nostop=nostop, $
                          output_primary_calibrator = output_primary_calibrator, $
                          output_allinfo_file = output_allinfo_file, $
                          output_selected_scan_list = output_selected_scan_list, $
                          output_comment = output_comment, $
                          output_nickname = output_nickname, $
                          do_aperture_photometry=do_aperture_photometry
                            
  ;; setting output_dir
  if keyword_set(output_dir) then begin
     output_dir = output_dir
     rdir = rdir
  endif else if keyword_set(root_dir) then begin
     rdir = root_dir 
     if (file_test(rdir, /directory) lt 1) then spawn, "mkdir -p "+rdir
     output_dir = rdir+'/PrimaryCal'
  endif else begin
     dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0] 
     if (file_test(dir, /directory) lt 1) then spawn, "mkdir -p "+dir
     rdir = dir+'/Photometry'
     if (file_test(rdir, /directory) lt 1) then spawn, "mkdir -p "+rdir
     output_dir = rdir+'/PrimaryCal'
  endelse
  if file_test(output_dir, /directory) lt 1 then spawn, "mkdir -p "+output_dir

  ;; dealing with stops in the code
  if keyword_set(nostop) then nostop = 1 else nostop=0
  if keyword_set(pas_a_pas) then pas_a_pas = 1-nostop else pas_a_pas = 0

  ;; Pool with more than one kidpar
  if keyword_set(multiple_kidpars) then multiple_kidpars = 1 else multiple_kidpars = 0
   
  ;; NAME
  if keyword_set(output_nickname) then nickname = output_nickname else begin
     if multiple_kidpars lt 1 then nickname = runname[0]+'_baseline' else nickname = runname[0] + '_baseline'+['_part1', '_part2']
  endelse
  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          DATA ANALYSIS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  calib_sources = ['Uranus', 'Neptune']
  get_calibration_scan_list, runname, scan_list, source_list=calib_sources, outlier_scan_list=outlier_scan_list
  
   
  nscans = n_elements(scan_list)
  for i=0, nscans-1 do print, "'"+strtrim(scan_list[i],2)+"', $"

  
  ;; nk analysis using baseline parameters
  if multiple_kidpars lt 1 and file_test(input_kidpar_file[0]) lt 1 then begin
     print, "Absolute_calibration: input kidpar file not found ", input_kidpar_file[0]
     print, "Have to stop here, sorry..."
     stop
  endif
    
  if (n_elements(scan_list) gt 0 and strlen(scan_list[0]) gt 1) then begin
     if multiple_kidpars lt 1 then begin
        print,'ABSOLUTE CALIBRATION USING ', input_kidpar_file[0] 
        launch_baseline_nk_batch, runname, input_kidpar_file[0], label='', $
                                  force_scan_list = scan_list, $
                                  force_source_list = calib_sources, $
                                  output_dir = output_dir, $
                                  relaunch=1, do_aperture_photometry=do_aperture_photometry
     endif else begin
        print, 'ABSOLUTE CALIBRATION using the reference kidpar as defined in nk_get_kidpar_ref.pro'
        launch_baseline_nk_batch, runname, '', label='', $
                                  force_scan_list = scan_list, $
                                  force_source_list = calib_sources, $
                                  output_dir = output_dir, $
                                  relaunch=1, do_aperture_photometry=do_aperture_photometry
     endelse
  endif else begin
     print, "Absolute_calibration: no primary calibrators were observed ???"
     print, "Nothing I can do..."
     stop
  endelse
  
    

  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  get_all_scan_result_file, runname, allresult_file, outputdir = output_dir, ecrase_file=0
  
  ;;
  ;;  restore result tables
  ;;____________________________________________________________
  print, ''
  print,'READING RESULT FILE: '
  print, allresult_file
  restore, allresult_file, /v
  ;; allscan_info

  
  ;; selection before recalibration
  ;;------------------------------------------------------------------
  selection_type = 1
  select_primary_calibrator_scans, allscan_info, index_select, $
                                   output_dir=output_dir, $
                                   showplot = 1, png=png, ps=ps, pdf=pdf, $
                                   nostop = nostop, pas_a_pas = pas_a_pas, $
                                   selection_type = selection_type

  primary_info = allscan_info[index_select]
  nscans = n_elements(primary_info)
  
  selected_scan_list = primary_info.scan
  
  if nostop lt 1 then begin
     print, 'selected_scan_list = ', selected_scan_list
     for i=0, nscans-1 do begin
        print, ''
        print,'Scan: ', selected_scan_list[i]
        print,'UT: ', strmid(primary_info[i].ut, 0, 5)
        print,'el: ', primary_info[i].result_elevation_deg
        print,'A1: FWHM = ',strtrim(primary_info[i].result_fwhm_1,2), $
              ', tau = ',strtrim(primary_info[i].result_tau_1, 2), $
              ', flux = ',strtrim(primary_info[i].result_flux_i1, 2)
        print,'A3: FWHM = ',strtrim(primary_info[i].result_fwhm_3,2), $
              ', tau = ',strtrim(primary_info[i].result_tau_3, 2), $
              ', flux = ',strtrim(primary_info[i].result_flux_i3, 2)
        print,'1mm: FWHM = ',strtrim(primary_info[i].result_fwhm_1mm,2), $
              ', tau = ',strtrim(primary_info[i].result_tau_1mm, 2), $
              ', flux = ',strtrim(primary_info[i].result_flux_i_1mm, 2)
        print,'2mm: FWHM = ',strtrim(primary_info[i].result_fwhm_2,2), $
              ', tau = ',strtrim(primary_info[i].result_tau_2, 2), $
              ', flux = ',strtrim(primary_info[i].result_flux_i2, 2)   
     endfor
     stop
  endif
  ;; ABSOLUTE CALIBRATION
  ;;________________________________________________________________-
  
  th_flux_1mm_run = dblarr(nscans)
  th_flux_a2_run  = dblarr(nscans)
  th_flux_a1_run  = dblarr(nscans)
  th_flux_a3_run  = dblarr(nscans)

  wuranus = where(strupcase(primary_info.object) eq 'URANUS', nuranus)
  primary_calibrator = ''
  if nuranus gt 0 then begin   
     for ui=0, nuranus-1 do begin
           i = wuranus[ui]
           nk_scan2run, selected_scan_list[i], run
           th_flux_1mm_run[i]     = !nika.flux_uranus[0]
           th_flux_a2_run[i]      = !nika.flux_uranus[1]
           th_flux_a1_run[i]      = !nika.flux_uranus[0]
           th_flux_a3_run[i]      = !nika.flux_uranus[0]
        endfor
     primary_calibrator = 'URANUS'
  endif
  wneptune = where(strupcase(primary_info.object) eq 'NEPTUNE', nneptune)
  if nneptune gt 0 then begin   
     for ui=0, nneptune-1 do begin
           i = wneptune[ui]
           nk_scan2run, selected_scan_list[i], run
           th_flux_1mm_run[i]     = !nika.flux_neptune[0]
           th_flux_a2_run[i]      = !nika.flux_neptune[1]
           th_flux_a1_run[i]      = !nika.flux_neptune[0]
           th_flux_a3_run[i]      = !nika.flux_neptune[0]
        endfor
     primary_calibrator = 'NEPTUNE'
  endif

  ;; JFMP 28 March 2020 begin: 
  ;; it might happen that the fluxes are  <= 0
  ;; in this case we should not consider  this data
  
  ;; flux_ratio_1   = mean( th_flux_a1_run/primary_info.result_flux_i1)
  ;; flux_ratio_2   = mean( th_flux_a2_run/primary_info.result_flux_i2)
  ;; flux_ratio_3   = mean( th_flux_a3_run/primary_info.result_flux_i3)
  ;; flux_ratio_1mm = mean( th_flux_1mm_run/primary_info.result_flux_i_1mm)
      
  wok = where( (primary_info.result_flux_i1 gt 0 ) and (primary_info.result_flux_i3 gt 0 ) and (primary_info.result_flux_i2 gt 0 ), nwok)
  ;; JFMP 28 March 2020 end: 
  if nwok ge 1 then begin 
     flux_ratio_1   = mean( th_flux_a1_run[wok]/primary_info[wok].result_flux_i1)
     flux_ratio_2   = mean( th_flux_a2_run[wok]/primary_info[wok].result_flux_i2)
     flux_ratio_3   = mean( th_flux_a3_run[wok]/primary_info[wok].result_flux_i3)
     flux_ratio_1mm = mean( th_flux_1mm_run[wok]/primary_info[wok].result_flux_i_1mm)

     if nwok gt 1 then begin
        rms_flux_ratio_1   = stddev( th_flux_a1_run[wok]/primary_info[wok].result_flux_i1)
        rms_flux_ratio_2   = stddev( th_flux_a2_run[wok]/primary_info[wok].result_flux_i2)
        rms_flux_ratio_3   = stddev( th_flux_a3_run[wok]/primary_info[wok].result_flux_i3)
        rms_flux_ratio_1mm = stddev( th_flux_1mm_run[wok]/primary_info[wok].result_flux_i_1mm)
     endif else begin
        rms_flux_ratio_1   = 0.
        rms_flux_ratio_2   = 0.
        rms_flux_ratio_3   = 0.
        rms_flux_ratio_1mm = 0.
     endelse
  endif else begin
     print, "WARNING: no scan valid for performing absolute calibration"
     print, "Do you want to continue, if so type .c "
     print, "If continuing, flux_ratio_(1,2,3), will be set to 1"
     if nostop lt 1 then stop
     
     flux_ratio_1   = 1.0
     flux_ratio_2   = 1.0
     flux_ratio_3   = 1.0
     flux_ratio_1mm = 1.0

     rms_flux_ratio_1   = 0.0
     rms_flux_ratio_2   = 0.0
     rms_flux_ratio_3   = 0.0
     rms_flux_ratio_1mm = 0.0
          
  endelse
  

  correction_coef = [flux_ratio_1, flux_ratio_2, flux_ratio_3, flux_ratio_1mm]
  print,'======================================================'
  print,"Flux correction coefficient A1: "+strtrim(correction_coef[0],2)
  print,"Flux correction coefficient A3: "+strtrim(correction_coef[2],2)
  print,"Flux correction coefficient A1&A3: "+strtrim(correction_coef[3],2)
  print,"Flux correction coefficient A2: "+strtrim(correction_coef[1],2)
  print,'======================================================'

      
  rms_correction_coef = [rms_flux_ratio_1, rms_flux_ratio_2, rms_flux_ratio_3, rms_flux_ratio_1mm]
  print,'======================================================'
  print,"RMS Flux correction coefficient A1: "+strtrim(rms_correction_coef[0],2)
  print,"RMS Flux correction coefficient A3: "+strtrim(rms_correction_coef[2],2)
  print,"RMS Flux correction coefficient A1&A3: "+strtrim(rms_correction_coef[3],2)
  print,"RMS Flux correction coefficient A2: "+strtrim(rms_correction_coef[1],2)
  print,'======================================================'


  if nostop lt 1 then stop

  ;; LP 2021, October, 20
  ;; save the predicted flux of primary calibrators
  predicted_flux_1mm = th_flux_1mm_run
  predicted_flux_2mm = th_flux_a2_run
  ;;if keyword_set(output_nickname) then savename = output_nickname[0] else savename = runname[0]+'_baseline'
  corr_file = rdir+"/Absolute_calibration_"+runname[0]+'_baseline.save'
  selected_scan_list = selected_scan_list
  uranus_ntot  = n_elements(where(strupcase(allscan_info.object) eq 'URANUS'))
  uranus_nsel  = nuranus
  neptune_ntot = n_elements(where(strupcase(allscan_info.object) eq 'NEPTUNE'))
  neptune_nsel = nneptune
  save, correction_coef, rms_correction_coef, scan_list, selected_scan_list, uranus_ntot, uranus_nsel, neptune_ntot, neptune_nsel, selection_type, predicted_flux_1mm, predicted_flux_2mm, filename=corr_file
  

  ;; Aperture photometry
  ;;________________________________________________________________
  if keyword_set(do_aperture_photometry) then begin
     
     wok = where( (primary_info.result_aperture_photometry_i1 gt 0 ) and (primary_info.result_aperture_photometry_i3 gt 0 ) and (primary_info.result_aperture_photometry_i2 gt 0 ), nwok)
     
     if nwok ge 1 then begin 
     flux_ratio_1   = mean( th_flux_a1_run[wok]/primary_info[wok].result_aperture_photometry_i1)
     flux_ratio_2   = mean( th_flux_a2_run[wok]/primary_info[wok].result_aperture_photometry_i2)
     flux_ratio_3   = mean( th_flux_a3_run[wok]/primary_info[wok].result_aperture_photometry_i3)
     flux_ratio_1mm = mean( th_flux_1mm_run[wok]/primary_info[wok].result_aperture_photometry_i_1mm)

     if nwok gt 1 then begin
        rms_flux_ratio_1   = stddev( th_flux_a1_run[wok]/primary_info[wok].result_aperture_photometry_i1)
        rms_flux_ratio_2   = stddev( th_flux_a2_run[wok]/primary_info[wok].result_aperture_photometry_i2)
        rms_flux_ratio_3   = stddev( th_flux_a3_run[wok]/primary_info[wok].result_aperture_photometry_i3)
        rms_flux_ratio_1mm = stddev( th_flux_1mm_run[wok]/primary_info[wok].result_aperture_photometry_i_1mm)
     endif else begin
        rms_flux_ratio_1   = 0.
        rms_flux_ratio_2   = 0.
        rms_flux_ratio_3   = 0.
        rms_flux_ratio_1mm = 0.
     endelse
  endif else begin
     print, "WARNING: no scan valid for performing absolute calibration"
     print, "Do you want to continue, if so type .c "
     print, "If continuing, flux_ratio_(1,2,3), will be set to 1"
     if nostop lt 1 then stop
     
     flux_ratio_1   = 1.0
     flux_ratio_2   = 1.0
     flux_ratio_3   = 1.0
     flux_ratio_1mm = 1.0

     rms_flux_ratio_1   = 0.0
     rms_flux_ratio_2   = 0.0
     rms_flux_ratio_3   = 0.0
     rms_flux_ratio_1mm = 0.0
          
  endelse
  

  AP_correction_coef = [flux_ratio_1, flux_ratio_2, flux_ratio_3, flux_ratio_1mm]
  print,'======================================================'
  print,"AP Flux correction coefficient A1: "+strtrim(AP_correction_coef[0],2)
  print,"AP Flux correction coefficient A3: "+strtrim(AP_correction_coef[2],2)
  print,"AP Flux correction coefficient A1&A3: "+strtrim(AP_correction_coef[3],2)
  print,"AP Flux correction coefficient A2: "+strtrim(AP_correction_coef[1],2)
  print,'======================================================'

      
  AP_rms_correction_coef = [rms_flux_ratio_1, rms_flux_ratio_2, rms_flux_ratio_3, rms_flux_ratio_1mm]
  print,'======================================================'
  print,"RMS AP Flux correction coefficient A1: "+strtrim(AP_rms_correction_coef[0],2)
  print,"RMS AP Flux correction coefficient A3: "+strtrim(AP_rms_correction_coef[2],2)
  print,"RMS AP Flux correction coefficient A1&A3: "+strtrim(AP_rms_correction_coef[3],2)
  print,"RMS AP Flux correction coefficient A2: "+strtrim(AP_rms_correction_coef[1],2)
  print,'======================================================'


  if nostop lt 1 then stop
  
  AP_corr_file = rdir+"/AP_Absolute_calibration_"+runname[0]+'_baseline.save'
  selected_scan_list = selected_scan_list
  uranus_ntot  = n_elements(where(strupcase(allscan_info.object) eq 'URANUS'))
  uranus_nsel  = nuranus
  neptune_ntot = n_elements(where(strupcase(allscan_info.object) eq 'NEPTUNE'))
  neptune_nsel = nneptune
  save, AP_correction_coef, AP_rms_correction_coef, scan_list, selected_scan_list, uranus_ntot, uranus_nsel, neptune_ntot, neptune_nsel, selection_type, filename=AP_corr_file
  
  endif


  
  ;; Recalibrate
  ;;________________________________________________________________
  
  print, "============================================="
  print, 'Recalibration'
  print, "============================================"
  print, ''
 
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
  
  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          PLOTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  duncoup = 1-pas_a_pas
  plot_flux_density_primary, allscan_info, index_select, $
                             outplot_dir = output_dir, $
                             png=png, ps=ps, pdf=pdf, $
                             fwhm_stability=1, $
                             obstau_stability=1, $
                             nostop = duncoup
  

  
  
  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          OUTPUTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  if keyword_set(output_allinfo_file) then output_allinfo_file = allscan_info
  if keyword_set(output_primary_calibrator) then output_primary_calibrator = primary_calibrator
  if keyword_set(output_selected_scan_list) then output_selected_scan_list = selected_scan_list
  if keyword_set(output_comment) then output_comment = selection_type
  
  if nostop lt 1 then begin
     print,''
     print,'Shall I apply the absolute calibration gain ?'
     print,'.c to go ahead'
     stop
  endif

  ;; only one kidpar for the whole observational run
  if multiple_kidpars lt 1 then begin
     print, ''
     print,'#######################################################'
     print, 'Reading ', input_kidpar_file[0]
     kidpar = mrdfits( input_kidpar_file[0], 1, /silent)
     
     w1 = where( kidpar.array eq 1, nw1) 
     kidpar[w1].calib          *= recalibration_coef[0]
     kidpar[w1].calib_fix_fwhm *= recalibration_coef[0]
     w3 = where( kidpar.array eq 3, nw3) 
     kidpar[w3].calib          *= recalibration_coef[2]
     kidpar[w3].calib_fix_fwhm *= recalibration_coef[2]
     w2 = where( kidpar.array eq 2 ,nw2) 
     kidpar[w2].calib          *= recalibration_coef[1]
     kidpar[w2].calib_fix_fwhm *= recalibration_coef[1]
     
     
     output_kidpar_file = rdir+'/kidpar_'+nickname+'.fits'
     print, ''
     print,'#######################################################'
     print, 'Writing recalibrated kidpar in ', output_kidpar_file
     nk_write_kidpar, kidpar, output_kidpar_file

  endif else begin
     print, ''
     print, 'DEALING WITH MULTIPLE KIDPARS FOR A SINGLE RUN'
     print, ''
     for i=0, 1 do begin
        print, ''
        print,'#######################################################'
        print, 'Reading ', input_kidpar_file[i]
        kidpar = mrdfits( input_kidpar_file[i], 1, /silent)
        
        w1 = where( kidpar.array eq 1, nw1) 
        kidpar[w1].calib          *= recalibration_coef[0]
        kidpar[w1].calib_fix_fwhm *= recalibration_coef[0]
        w3 = where( kidpar.array eq 3, nw3) 
        kidpar[w3].calib          *= recalibration_coef[2]
        kidpar[w3].calib_fix_fwhm *= recalibration_coef[2]
        w2 = where( kidpar.array eq 2 ,nw2) 
        kidpar[w2].calib          *= recalibration_coef[1]
        kidpar[w2].calib_fix_fwhm *= recalibration_coef[1]
        
        
        output_kidpar_file = rdir+'/kidpar_'+nickname[i]+'.fits'
        print, ''
        print,'#######################################################'
        print, 'Writing recalibrated kidpar in ', output_kidpar_file
        nk_write_kidpar, kidpar, output_kidpar_file
        print, ''
        print,'#######################################################'
        print, 'Copying recalibrated kidpar in ', input_kidpar_file[i]
        spawn, 'cp '+ output_kidpar_file+' '+input_kidpar_file[i]
        print,'#######################################################'
        print, ''
     endfor
     
  endelse

  
  print, "Selected scans of ", primary_calibrator
  for i=0, nscans-1 do print, "'"+strtrim(selected_scan_list[i],2)+"', $"
  
  
  if nostop lt 1 then stop
  
end

