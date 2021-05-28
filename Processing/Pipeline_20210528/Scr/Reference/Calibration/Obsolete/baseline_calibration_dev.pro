;;
;;   PERFORM THE BASELINE CALIBRATION 
;;
;;  Purpose: perform the absolute calibration
;;  Output : a calibrated kidpar file
;;  Input  : a geometry kidpar file (produced using e.g. reduce_beammap)
;;  
;;
;;   INCLUDE THE PERFORMANCE ASSESSMENT
;;
;;   NEW VERSION IN DEVELOPMENT (LP, March 2020)
;;_______________________________________________________________________

pro baseline_calibration_dev

  ;; RUN NAME
  ;;__________________________________________
  runname = ['N2R36', 'N2R37']  ;;  Joint analysis of the NIKA2 runs within the same cryo run
  runname = ['N2R15'] 
  

  ;; All calibration results will be in getenv('NIKA_PLOT_DIR')+'/'+runname[0]

  
  ;; FOCAL PLANE GEOMETRY
  ;;
  ;; a geometry must have been produced using e.g. Geometry/reduce_beammap.pro
  ;; geom_kidpar_file is the output of reduce_beammap.pro : kidpar_<scan_id>_v2
  ;;_____________________________________________________________________
  geom_kidpar_file = !nika.off_proc_dir+'/kidpar_20180219s170_v2_skd_BL.fits'

  
  ;; ACTIONS
  ;;__________________________________________

  ;; CALIBRATION
  do_opacity_correction        = 0
  do_absolute_calibration      = 1

  ;; >>>> When the two previous steps are done, the calibration is
  ;; completed
  ;; >>>> The next steps consists of validation and assessment of the
  ;; calibration quality
  
  ;; VALIDATION
  ;; 1/ minimum validation: check the photometry on secondary calibrators 
  do_photometry_check_on_secondaries = 1
  
  ;; 2/ [REDUCTION OF ABOUT 100 SCANS] more evolved validation: evaluate the RMS uncertainties on bright sources (>1Jy)
  do_rms_calibration_uncertainties   = 1
  
  ;; 3/ [CPU AND DISC-SPACE DEMANDING] performance assessment: evaluate the NEFD using all sources < 1 Jy
  do_nefd_using_scatter_method       = 1 


  ;; OUTPUT THE CALIBRATION RESULTS
  save_calibration_results           = 1
  
  
  ;; set to 1 to run the whole script without stopping after the main steps
  nostop = 1
  
  ;; set to 1 to stop after each step 
  pas_a_pas = 0

 
;; NO MORE EDITABLE SETTINGS FROM NOW ON

;;_______________________________________________________________________________________________
;;_______________________________________________________________________________________________

  ;; test calibration dir
  calibration_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]
  if file_test(calibration_dir, /directory) lt 1 then spawn, "mkdir -p "+calibration_dir

  ;; test geom_kidpar_file
  if file_test(geom_kidpar_file) lt 1 then begin
     print, 'Not found input kidpar file ', geom_kidpar_file
     stop
  endif
  
  ;; test log file
  filesave_out = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_'+runname[0]+'_v0.save'
  get_calibration_scan_list, runname, scan_list


  ;; init the calibration structure
  ;;====================================================================
  calibration = create_struct( "nika2run", strarr(2), $
                               "cryorun", 0, $
                               "detector_ref", 0, $
                               "geom_kidpar_file", '', $
                               "skydip_scan_list", strarr(100), $
                               "opacity_kidpar_file", '', $
                               "input_kidpar_file", '', $
                               "primary_calibrator", '', $
                               "primary_scan_list", strarr(100), $
                               "abscal_kidpar_file", '', $
                               ;;-------------------------------------------
                               "secondary_calibrator", '', $
                               "secondary_scan_list", strarr(100), $,
                               "calibration_bias", fltarr(4), $
                               "calibration_bias_rms", fltarr(4), $
                               ;;------------------------------------------
                               "list_of_bright_sources", strarr(100), $
                               "total_scan_of_bright_sources", 0, $
                               "selected_scan_of_bright_sources", 0, $
                               "rms_calibration_error", fltarr(4), $
                               ;;------------------------------------------
                               "list_of_faint_sources", strarr(100), $
                               "number_of_faint_source_scans", 0, $,
                               "NEFD", fltarr(4), $
                               "rms_NEFD", fltarr(4),$
                               "mapping_speed", fltarr(4), $
                               "rms_mapping_speed", fltarr(4))
  ;;======================================================================
  
  calibration.geom_kidpar_file = geom_kidpar_file

  
;; 1/ OPACITY CORRECTION
;;_______________________________________________________________________________________________    
  
  if do_opacity_correction gt 0 then begin
     
     do_first_iteration  = 1
     do_skydip_selection = 1    ; 0
     do_second_iteration = 1
     
     show_plot = 1
     check_after_selection  = 1 ;; launch again the selection code after the second iteration

     skydip_scan_list = 1 
     png=1
     
     reduce_skydips_reference, runname, geom_kidpar_file, $
                               root_dir = calibration_dir, $
                               hightau2=0, atmlike=0, $
                               baseline=1, $
                               showplot=show_plot, png=png, $
                               do_first_iteration=do_first_iteration, $
                               do_skydip_selection=do_skydip_selection, $
                               do_second_iteration=do_second_iteration, $
                               check_after_selection=check_after_selection, $
                               reiterate=reiterate, output_skydip_scan_list=skydip_scan_list

     ;; output:  output_dir+'/Opacity/kidpar_C0C1_'+runname[0]+'_baseline.fits'

     opacity_dir = calibration_dir+'/Opacity'
     calibration.opacity_kidpar_file = opacity_dir+'/kidpar_C0C1_'+runname[0]+'_baseline.fits'
     calibration.skydip_scan_list = skydip_scan_list
     
     if nostop lt 1 then stop
     
  endif
  
  
;; 2/ ABSOLUTE CALIBRATION
;;_______________________________________________________________________________________________
     
  if do_absolute_calibration gt 0 then begin


     photo_dir = calibration_dir+'/Photometry'
     if file_test(photo_dir, /directory) lt 1 then spawn, "mkdir -p "+photo_dir

     primary_dir = photo_dir+'/PrimaryCal'
     if file_test(primary_dir, /directory) lt 1 then spawn, "mkdir -p "+primary_dir
     
     version_name = '_baseline'
     
     showplot = 1
     png = 0
     ps  = 1
     pdf = 1

     
     ;; copy the C0, C1 skydip coefficients into the geometry kidpar
     skydip_kidpar_file = calibration_dir+'/Opacity/kidpar_C0C1_'+runname[0]+version_name+'.fits'
     input_kidpar_file  = photo_dir+'/input_kidpar_calib_'+runname[0]+version_name+'.fits'
     if file_test(input_kidpar_file) lt 1 then skydip_coeffs, geom_kidpar_file, skydip_kidpar_file, input_kidpar_file
     print, "Geometry kidpar_file: ",   geom_kidpar_file
     print, "Skydip kidpar_file: ", skydip_kidpar_file
     
     print, "Input kidpar_file for the absolute calibration: ",  input_kidpar_file

     calibration.opacity_kidpar_file = skydip_kidpar_file
     calibration.input_kidpar_file = input_kidpar_file
     
     if nostop lt 1 then begin
        rep = ''
        print, "Let's continue ?"
        read, rep
     endif
        
     ;; no photometric correction
     ;;____________________________________________________
     primary_calibrator = 1
     primary_scan_list  = 1
     absolute_calibration, runname, input_kidpar_file, $
                           root_dir = photo_dir, $
                           showplot=showplot, png=png, ps=ps, pdf=pdf, $
                           outlier_scan_list = outlier_scan_list, $
                           pas_a_pas = pas_a_pas, $
                           nostop = nostop, $
                           output_primary_calibrator = primary_calibrator, $
                           output_allinfo_file = output_allinfo_file, $
                           output_selected_scan_list = primary_scan_list, $
                           output_nickname = runname[0]+version_name

     calibration.primary_calibrator = primary_calibrator
     calibration.primary_scan_list = primary_scan_list
     
     absolute_calibration_file = photo_dir+"/Absolute_calibration_"+runname[0]+version_name+'.save'
     restore, absolute_calibration_file, /v
     print, ''
     print, '==========================================================================='
     print, ''
     print, '     Absolute calibration summary '
     print, ''
     print, '==========================================================================='
     print, 'Uranus, total number of scans     = ', uranus_ntot
     print, 'Uranus, number of selected scans  = ', uranus_nsel
     print, 'Neptune, total number of scans    = ', neptune_ntot
     print, 'Neptune, number of selected scans = ', neptune_nsel
     print, ''
     print, 'Calibration Coefficients :'
     print, '-- A1 : ', correction_coef[0], ', rms = ', rms_correction_coef[0] 
     print, '-- A3 : ', correction_coef[2], ', rms = ', rms_correction_coef[2] 
     print, '-- 1mm: ', correction_coef[3], ', rms = ', rms_correction_coef[3]
     print, '-- 2mm: ', correction_coef[1], ', rms = ', rms_correction_coef[1] 
     print, '==========================================================================='

     calibration.abscal_kidpar_file = photo_dir+'/kidpar_'+runname[0]+version_name+'.fits'
     
     if nostop lt 1 then stop
     wd, /a
     
  endif
  
     
;; 3./ CROSS_CHECK USING MWC349
;;_______________________________________________________________________________________________    
  if do_photometry_check_on_secondaries gt 0 then begin
     
     photo_dir = calibration_dir+'/Photometry'
     if file_test(photo_dir, /directory) lt 1 then spawn, "mkdir -p "+photo_dir
     
     secondary_dir = photo_dir+'/SecondaryCal'
     if file_test(secondary_dir, /directory) lt 1 then spawn, "mkdir -p "+secondary_dir
     
     version_name = '_baseline'
     
     showplot = 1
     png = 0
     ps  = 1
     pdf = 1 
     
     kidpar_file =  photo_dir+'/kidpar_'+runname[0]+version_name+'.fits'
     calibration.abscal_kidpar_file = kidpar_file
     print, "kidpar_file: "+kidpar_file
     
     photometry_check_on_secondaries, runname[0], kidpar_file, $
                                      root_dir = photo_dir, $
                                      output_dir=secondary_dir, $
                                      showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                      outlier_scan_list = outlier_scan_list, $
                                      pas_a_pas = pas_a_pas, $
                                      nostop=nostop, $
                                      calibration_structure = calibration

     
     if nostop lt 1 then stop
     wd, /a
  endif
     

  ;; 4/ CHECK FOR SYSTEMATIC EFFECTS USING ALL BRIGHT SOURCES (> 1Jy)
  ;;__________________________________________________________________     
  if do_rms_calibration_uncertainties gt 0 then begin
     
     validation_dir = calibration_dir+'/Validation'
     if file_test(validation_dir, /directory) lt 1 then spawn, "mkdir -p "+validation_dir
     
     version_name = '_baseline'
     
     showplot = 1
     png = 0
     ps  = 1
     pdf = 1 
     
     kidpar_file =  calibration_dir+'/Photometry/kidpar_'+runname[0]+version_name+'.fits'
     calibration.abscal_kidpar_file = kidpar_file
     print, "kidpar_file: "+kidpar_file


     ;; OUTPUTS
     ;; "total_scan_of_bright_sources", 0, $
     ;; "selected_scan_of_bright_sources", 0, $
     ;; "rms_calibration_error", fltarr(4), $
     get_rms_calibration_uncertainties, runname[0], kidpar_file, $
                                        output_dir=validation_dir, $
                                        showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                        outlier_scan_list = outlier_scan_list, $
                                        pas_a_pas = pas_a_pas, $
                                        nostop=nostop, $
                                        calibration_structure = calibration

     
     if nostop lt 1 then stop
     wd, /a
  endif


  ;; 5/ CHECK THE NEFD USING ALL FAINT (moderately bright) SOURCES (< 1Jy)
  ;;________________________________________________________________________
  
  if do_nefd_using_scatter_method gt 0 then begin
     
     validation_dir = calibration_dir+'/Validation'
     if file_test(validation_dir, /directory) lt 1 then spawn, "mkdir -p "+validation_dir
     
     version_name = '_baseline'
     
     showplot = 1
     png = 0
     ps  = 1
     pdf = 1 
     
     kidpar_file =  calibration_dir+'/Photometry/kidpar_'+runname[0]+version_name+'.fits'
     calibration.abscal_kidpar_file = kidpar_file
     print, "kidpar_file: "+kidpar_file

     ;; OUTPUTS :
     ;;  "faint_source_list "
     ;;  "number_of_faint_sources", 0, $,
     ;;  "NEFD", fltarr(4), $
     ;;  "rms_NEFD", fltarr(4),$
     ;;  "mapping_speed", fltarr(4), $
     ;;  "rms_mapping_speed", fltarr(4))
     get_nefd_using_scatter_method, runname[0], kidpar_file, $
                                    output_dir=validation_dir, $
                                    showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                    outlier_scan_list = outlier_scan_list, $
                                    pas_a_pas = pas_a_pas, $
                                    nostop=nostop, $
                                    calibration_structure = calibration

     
     if nostop lt 1 then stop
     wd, /a
  endif


  ;;==========================================================================='
  ;;
  ;;     SAVING THE CALIBRATION RESULTS
  ;;
  ;;==========================================================================='
  nickname = runname[0]+'_baseline'
  calibration_file = calibration_dir+'/calibration_results_'+nickname+'.save'
  if save_calibration_results gt 0 then save, calibration, file=calibration_file
  
  ;;==========================================================================='
  ;;
  ;;     SUMMARY  TABLE 
  ;;
  ;;==========================================================================='
  print,'==========================================================================='
  print,''
  print,''
  print,'     SUMMARY  TABLE '
  print,''
  print,'     CALIBRATION OF ', runname
  print,'     All results are summarised below'
  print,''
  print,''
  print,'==========================================================================='
  print, 'KIDPAR FILES: '
  print, 'Geometry kidpar file: ', calibration.geom_kidpar_file
  print, 'Opacity kidpar file: ', calibration.opacity_kidpar_file
  print, 'Output kidpar file: ', calibration.abscal_kidpar_file
  
  photo_dir = calibration_dir+'/Photometry'
  nickname = runname[0]+'_baseline'
  acal_file = photo_dir+"/Absolute_calibration_"+nickname+'.save'
  if file_test(acal_file) gt 0 then begin
     ;;print, "reading : ",acal_file
     restore, acal_file
     print, ''
     print, '==========================================================================='
     print, ''
     print, '     Absolute calibration summary '
     print, ''
     print, '==========================================================================='
     print, 'Uranus, total number of scans     = ', uranus_ntot
     print, 'Uranus, number of selected scans  = ', uranus_nsel
     print, 'Neptune, total number of scans    = ', neptune_ntot
     print, 'Neptune, number of selected scans = ', neptune_nsel
     print, ''
     print, 'Calibration Coefficients (Expected flux / Raw flux) :'
     print, '-- A1 : ', correction_coef[0], ', rms = ', rms_correction_coef[0] 
     print, '-- A3 : ', correction_coef[2], ', rms = ', rms_correction_coef[2] 
     print, '-- 1mm: ', correction_coef[3], ', rms = ', rms_correction_coef[3]
     print, '-- 2mm: ', correction_coef[1], ', rms = ', rms_correction_coef[1] 
     print, '==========================================================================='
  endif

  second_dir = photo_dir + '/SecondaryCal'
  second_file = second_dir+'/photometry_check_on_secondaries.save'
  if file_test(second_file) gt 0 then begin
     ;;print, "reading : ",second_file
     restore, second_file
     print, ''
     print, '==========================================================================='
     print, ''
     print, '     Photometry check on secondary calibrators '
     print, ''
     print, '==========================================================================='
     print, 'Secondary calibrator              = ', secondary.calibrator
     w = where(strmatch(secondary.selected_scan_list, '') eq 0, n)
     print, 'number of selected scans          = ', strtrim(n,2)
     w = where(strmatch(secondary.observed_scan_list, '') eq 0, n)
     print, 'total number of scans             = ', strtrim(n, 2)
     print, ''
     print, 'Calibration bias (Measured/Expected):'
     print, '-- A1 : ', (secondary.calibration_bias)[0] , ', rms = ', (secondary.calibration_bias_rms)[0] 
     print, '-- A3 : ', (secondary.calibration_bias)[1] , ', rms = ', (secondary.calibration_bias_rms)[1] 
     print, '-- 1mm: ', (secondary.calibration_bias)[2] , ', rms = ', (secondary.calibration_bias_rms)[2]
     print, '-- 2mm: ', (secondary.calibration_bias)[3] , ', rms = ', (secondary.calibration_bias_rms)[3]
     print, '==========================================================================='   
  endif


  
  if do_rms_calibration_uncertainties gt 0 then begin
     print, ''
     print, '==========================================================================='
     print, ''
     print, '     Point sources RMS calibration uncertainties '
     print, ''
     print, '==========================================================================='
     print, 'List of used bright point sources = ', calibration.list_of_bright_sources
     print, 'number of selected scans          = ', strtrim(calibration.selected_scan_of_bright_sources,2)
     print, 'total number of scans             = ', strtrim(calibration.total_scan_of_bright_sources, 2)
     print, ''
     print, 'RMS calibration uncertainties :'
     print, '-- A1 : ', strtrim(string(calibration.rms_calibration_error[0]*100.0d0, format='(f4.2)'), 2), '%'
     print, '-- A3 : ', strtrim(string(calibration.rms_calibration_error[1]*100.0d0,format='(f4.2)'), 2), '%'
     print, '-- 1mm: ', strtrim(string(calibration.rms_calibration_error[2]*100.0d0,format='(f4.2)'), 2), '%'
     print, '-- 2mm: ', strtrim(string(calibration.rms_calibration_error[3]*100.0d0,format='(f4.2)'), 2), '%'
     print, '==========================================================================='
  endif
  
  if do_nefd_using_scatter_method gt 0 then begin
     print, ''
     print, '==========================================================================='
     print, ''
     print, '     NEFD AT ZERO ATMOSPHERIC OPACITY USING FAINT SOURCES '
     print, ''
     print, '==========================================================================='
     print, 'List of used faint sources        = ', calibration.list_of_faint_sources
     print, 'number of selected scans          = ', strtrim(calibration.number_of_faint_source_scans,2)
     print, ''
     print, 'NEFD AT ZERO ATMOSPHERIC OPACITY [mJy s^{0.5}]:'
     print, '-- A1 : ', strtrim(string(calibration.nefd[0], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[0], format='(f5.1)'),2)
     print, '-- A3 : ', strtrim(string(calibration.nefd[1], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[1], format='(f5.1)'),2)
     print, '-- 1mm: ', strtrim(string(calibration.nefd[2], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[2], format='(f5.1)'),2)
     print, '-- 2mm: ', strtrim(string(calibration.nefd[3], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[3], format='(f5.1)'),2)
     print, ''
     print, 'MAPPING SPEED AT ZERO ATMOSPHERIC OPACITY [arcmin^2 / mJy^2 / hr]:'
     print, '-- A1 : ', strtrim(string(calibration.mapping_speed[0], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[0], format='(f6.0)'),2)
     print, '-- A3 : ', strtrim(string(calibration.mapping_speed[1], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[1], format='(f6.0)'),2)
     print, '-- 1mm: ', strtrim(string(calibration.mapping_speed[2], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[2], format='(f6.0)'),2)
     print, '-- 2mm: ', strtrim(string(calibration.mapping_speed[3], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[3], format='(f6.0)'),2)
     print, '==========================================================================='
     
  endif


  

  stop


  
  
end
