
;;
;;   REFERENCE LAUNCHER SCRIPT TO CHECK...
;;
;;                ...THE PHOTOMETRY ON SECONDARY CALIBRATORS 
;;
;;   LP, March 2020
;;_______________________________________________________________________________

pro photometry_check_on_secondaries, runname, input_kidpar_file, $
                                     multiple_kidpars = multiple_kidpars, $
                                     root_dir = root_dir, $
                                     output_dir=output_dir, $
                                     showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                     outlier_scan_list = outlier_scan_list, $
                                     pas_a_pas = pas_a_pas, $
                                     nostop=nostop, $
                                     output_nickname = output_nickname, $
                                     calibration_structure = calibration_structure, $
                                     do_aperture_photometry=do_aperture_photometry
                            
  ;; setting output_dir
  if keyword_set(output_dir) then begin
     output_dir = output_dir
     rdir = rdir
  endif else if keyword_set(root_dir) then begin
     rdir = root_dir 
     if (file_test(rdir, /directory) lt 1) then spawn, "mkdir -p "+rdir
     output_dir = rdir+'/SecondaryCal'
  endif else begin
     dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0] 
     if (file_test(dir, /directory) lt 1) then spawn, "mkdir -p "+dir
     rdir = dir+'/Photometry'
     if (file_test(rdir, /directory) lt 1) then spawn, "mkdir -p "+rdir
     output_dir = rdir+'/SecondaryCal'
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

  if keyword_set(do_aperture_photometry) then do_aperture_photometry = 1 else do_aperture_photometry=0
  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          DATA ANALYSIS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  calib_sources = ['MWC349', 'CRL2688', 'NGC7027']
  calib_sources = ['MWC349']
  get_calibration_scan_list, runname, scan_list, source_list=calib_sources, outlier_scan_list=outlier_scan_list
  
   
  nscans = n_elements(scan_list)
  for i=0, nscans-1 do print, "'"+strtrim(scan_list[i],2)+"', $"

  ;; nk analysis using baseline parameters
  if (multiple_kidpars lt 1 and file_test(input_kidpar_file[0]) lt 1) then begin
     print, "Photometry checks: input kidpar file not found ", input_kidpar_file[0]
     print, "Have to stop here, sorry..."
     stop
  endif
  if (n_elements(scan_list) gt 0 and strlen(scan_list[0]) gt 1) then begin
     if multiple_kidpars lt 1 then begin
        print,'PHOTOMETRY USING ', input_kidpar_file[0]
        launch_baseline_nk_batch, runname, input_kidpar_file[0], label='', $
                                  force_scan_list = scan_list, $
                                  force_source_list = calib_sources, $
                                  output_dir = output_dir, $
                                  relaunch=1, do_aperture_photometry=do_aperture_photometry
     endif else begin
        print,'PHOTOMETRY USING REFERENCE KIDPARS AS SET IN NK_GET_KIDPAR_REF'
        launch_baseline_nk_batch, runname, '', label='', $
                                  force_scan_list = scan_list, $
                                  force_source_list = calib_sources, $
                                  output_dir = output_dir, $
                                  relaunch=1, do_aperture_photometry=do_aperture_photometry
     endelse
        
  endif else begin
     print, "Photometry checks: no secondary calibrators were observed ???"
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

  
  ;; SCAN SELECTION
  ;;------------------------------------------------------------------
  output_selection_type = 1
  select_secondary_calibrator_scans, allscan_info, index_select,$
                                     calibrator_list = calib_sources, $
                                     output_dir=output_dir, $
                                     showplot = 1, png=png, ps=ps, pdf=pdf, $
                                     pas_a_pas = pas_a_pas, $
                                     force_manual_selection = 1, $
                                     output_selection_type = output_selection_type

  cal_info = allscan_info[index_select]
  nscans = n_elements(cal_info)
  
  selected_scan_list = cal_info.scan
  
  if nostop lt 1 then begin
     print, "selected_scan_list = ", selected_scan_list
     stop
  endif
 
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          PLOTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  duncoup = 1-pas_a_pas
  savefile = 1
  plot_flux_density_secondaries, allscan_info, index_select, $
                                 outplot_dir = output_dir, $
                                 png=png, ps=ps, pdf=pdf, $
                                 fwhm_stability=1, $
                                 obstau_stability=1, $
                                 nostop = duncoup, $
                                 savefile = 1
  
  if do_aperture_photometry gt 0 then $
     plot_flux_density_secondaries, allscan_info, index_select, $
                                    outplot_dir = output_dir, $
                                    png=png, ps=ps, pdf=pdf, $
                                    fwhm_stability=1, $
                                    obstau_stability=1, $
                                    nostop = duncoup, /aperture, $
                                    savefile = 1 ; to save AP

  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          OUTPUTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  print, ''
  print, 'READING ', output_dir+'/photometry_check_on_secondaries.save'
  restore, output_dir+'/photometry_check_on_secondaries.save'
  if keyword_set(calibration_structure) then begin
     ;;secondary = create_struct(  "calibrator", '', $
     ;;                            "observed_scan_list", strarr(100), $,
     ;;                            "selected_scan_list", strarr(100), $,
     ;;                            "calibration_bias", fltarr(4), $
     ;;                            "calibration_bias_rms", fltarr(4))

     calibration_structure.secondary_calibrator = secondary.calibrator
     calibration_structure.secondary_scan_list  = secondary.selected_scan_list
     calibration_structure.calibration_bias     = secondary.calibration_bias
     calibration_structure.calibration_bias_rms = secondary.calibration_bias_rms
     if do_aperture_photometry gt 0 then begin
        calibration_structure.calibration_bias_AP     = secondary.calibration_bias_AP
        calibration_structure.calibration_bias_rms_AP = secondary.calibration_bias_rms_AP
     endif
     if strmatch(output_selection_type, 'manual*', /fold_case) then calibration_structure.photometry_check_comment = 'Manual selection of a scan that does not met the selection criteria'
  endif 
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
  print, 'Calibration bias :'
  print, '-- A1 : ', (secondary.calibration_bias)[0] , ', rms = ', (secondary.calibration_bias_rms)[0] 
  print, '-- A3 : ', (secondary.calibration_bias)[1] , ', rms = ', (secondary.calibration_bias_rms)[1] 
  print, '-- 1mm: ', (secondary.calibration_bias)[2] , ', rms = ', (secondary.calibration_bias_rms)[2]
  print, '-- 2mm: ', (secondary.calibration_bias)[3] , ', rms = ', (secondary.calibration_bias_rms)[3]
  print, '==========================================================================='
  if do_aperture_photometry gt 0 then begin
     print, ''
     print, '  Aper. Photom. Calibration bias :'
     print, '-- A1 : ', (secondary.calibration_bias_AP)[0] , ', rms = ', (secondary.calibration_bias_rms_AP)[0] 
     print, '-- A3 : ', (secondary.calibration_bias_AP)[1] , ', rms = ', (secondary.calibration_bias_rms_AP)[1] 
     print, '-- 1mm: ', (secondary.calibration_bias_AP)[2] , ', rms = ', (secondary.calibration_bias_rms_AP)[2]
     print, '-- 2mm: ', (secondary.calibration_bias_AP)[3] , ', rms = ', (secondary.calibration_bias_rms_AP)[3]
     print, '==========================================================================='
  endif
  if nostop lt 1 then stop
  
end

