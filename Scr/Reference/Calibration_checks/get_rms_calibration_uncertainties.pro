
;;
;;   REFERENCE LAUNCHER SCRIPT TO ASSESS...
;;
;;                ...THE POINT SOURCE RMS CALIBRATION UNCERTAINTIES 
;;
;;   LP, March 2020
;;_______________________________________________________________________________

pro get_rms_calibration_uncertainties, runname, input_kidpar_file, $
                                       multiple_kidpars = multiple_kidpars, $
                                       output_dir=output_dir, $
                                       showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                       outlier_scan_list = outlier_scan_list, $
                                       pas_a_pas = pas_a_pas, $
                                       nostop=nostop, $
                                       output_nickname = output_nickname, $
                                       calibration_structure = calibration_structure, $
                                       do_aperture_photometry=do_aperture_photometry
  
  ;; setting output_dir
  if keyword_set(output_dir) then output_dir = output_dir else $
     output_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]+'/Validation'
  if file_test(output_dir, /directory) lt 1 then spawn, "mkdir -p "+output_dir
  if file_test(output_dir+'/RMS_error', /directory) lt 1 then spawn, "mkdir -p "+output_dir+'/RMS_error'
  
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
  
  ;; Minimun number of scans of a source for the scan selection
  minimum_nscan_per_source = 5
  
  ;; Flux threshold for sources selection
  flux_threshold_1mm = 1.0d0
  flux_threshold_2mm = 0.5d0

  ;; typical source list
  sources = ['MWC349', 'CRL2688', 'NGC7027', '3C84', '0316+413', 'Uranus', 'Neptune']
  
  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          DATA ANALYSIS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  scan_info = 1
  get_calibration_scan_list, runname, scan_list, $
                             source_list=sources, $
                             outlier_scan_list=outlier_scan_list, $
                             minimum_nscan_per_source=minimum_nscan_per_source, $
                             scan_info=scan_info
   
  nscans = n_elements(scan_list)
  
  ;; nk analysis using baseline parameters
  if (multiple_kidpars lt 1 and file_test(input_kidpar_file[0]) lt 1) then begin
     print, "Photometry checks: input kidpar file not found ", input_kidpar_file
     print, "Have to stop here, sorry..."
     stop
  endif
  if (nscans gt 0 and strlen(scan_list[0]) gt 1) then begin
     print,'ESTIMATION OF THE RMS ERROR'
     print,'NUMBER OF SCANS TO BE REDUCED = ', nscans

     if multiple_kidpars lt 1 then begin
        print,'USING ', input_kidpar_file[0]
        
        if pas_a_pas then stop
        launch_baseline_nk_batch, runname, input_kidpar_file[0], label='', $
                                  force_scan_list = scan_list, $
                                  output_dir = output_dir+'/RMS_error', $
                                  relaunch=1, do_aperture_photometry=do_aperture_photometry
     endif else begin
        print, 'using the reference kidpar as defined in nk_get_kidpar_ref.pro'
        if pas_a_pas then stop
        launch_baseline_nk_batch, runname, '', label='', $
                                  force_scan_list = scan_list, $
                                  output_dir = output_dir+'/RMS_error', $
                                  relaunch=1, do_aperture_photometry=do_aperture_photometry
     endelse
  endif else begin
     print, "CALIBRATION RMS UNCERTAINTIES: no scan found ???"
     print, "Nothing I can do..."
     stop
  endelse
  
    

  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  get_all_scan_result_file, runname, allresult_file, outputdir = output_dir+'/RMS_error', ecrase_file=0
  
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
  weak_fwhm_max   = [20., 20., 20.]    ;; for the scans observed during nights and mornings
  ;;strong_fwhm_max = [11.6, 17.6, 11.6] ;; for the scans observed
  ;;during afternoons
  strong_fwhm_max = [11.8, 17.7, 11.8] ;; LP Nov 2020 
  fwhm_max        = [11.8, 17.8, 11.8] ;; for the FWHM-based selection (practical)
  
  select_scans, allscan_info, index_select,$
                flux_threshold_1mm = flux_threshold_1mm, $
                flux_threshold_2mm = flux_threshold_2mm, $
                minimum_nscan_per_source = 5, $
                fwhm_max = fwhm_max, $
                weak_fwhm_max = weak_fwhm_max, $
                strong_fwhm_max = strong_fwhm_max, $
                output_dir=output_dir, $
                showplot = 1, png=png, ps=ps, pdf=pdf, $
                pas_a_pas = pas_a_pas  

  ;; NB: allscan_info now only contains sources above the flux threshold
  
  if index_select[0] gt -1 then selected_scan_list = allscan_info[index_select].scan else selected_scan_list = 'none'

  if nostop lt 1 then begin
     print, "selected_scan_list =  ", selected_scan_list
     stop
  endif
  wd, /a
  
 
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          PLOTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  duncoup = 1-pas_a_pas
  output_rms_errors  = 1
  output_source_list = 1
  plot_flux_density_all, allscan_info, index_select, $
                         outplot_dir = output_dir, $
                         png=png, ps=ps, pdf=pdf, $
                         obsdate_stability=1, $
                         obstau_stability=1, $
                         nostop = duncoup, $
                         output_rms_errors = output_rms_errors, $
                         output_source_list = output_source_list

  ntot   = n_elements(allscan_info)
  if index_select[0] gt -1 then nscans = n_elements(index_select) else nscans = 0

; Do aperture photometry too
  
  if do_aperture_photometry gt 0 then plot_flux_density_all, allscan_info, index_select, $
     outplot_dir = output_dir, $
     png=png, ps=ps, pdf=pdf, $
     obsdate_stability=1, $
     obstau_stability=1, $
     nostop = duncoup, /aperture, $
     output_rms_errors = output_rms_errors_AP
    
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          OUTPUTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  if keyword_set(calibration_structure) then begin
     ;;"total_scan_of_bright_sources", 0, $
     ;;"selected_scan_of_bright_sources", 0, $
     ;;"rms_calibration_error", fltarr(4)

     calibration_structure.list_of_bright_sources           = output_source_list
     calibration_structure.total_scan_of_bright_sources     = ntot
     calibration_structure.selected_scan_of_bright_sources  = nscans 
     calibration_structure.rms_calibration_error            = output_rms_errors
     if do_aperture_photometry gt 0 then calibration_structure.rms_calibration_error_AP         = output_rms_errors_AP
  endif 
  print, ''
  print, '==========================================================================='
  print, ''
  print, '     Point sources RMS calibration uncertainties '
  print, ''
  print, '==========================================================================='
  print, 'Strong point sources list         = ', output_source_list
  print, 'number of selected scans          = ', strtrim(nscans,2)
  print, 'total number of scans             = ', strtrim(ntot, 2)
  print, ''
  nrms = n_elements( output_rms_errors)
  print, 'RMS calibration uncertainties :'
  if nrms gt 1 then begin ; weird case when only one/zero scan is selected
     print, '-- A1 : ', strtrim(string(output_rms_errors[0]*100.0d0, format='(f7.2)'), 2), '%'
     print, '-- A3 : ', strtrim(string(output_rms_errors[1]*100.0d0,format='(f7.2)'), 2), '%'
     print, '-- 1mm: ', strtrim(string(output_rms_errors[2]*100.0d0,format='(f7.2)'), 2), '%'
     print, '-- 2mm: ', strtrim(string(output_rms_errors[3]*100.0d0,format='(f7.2)'), 2), '%'
  endif
  if do_aperture_photometry gt 0 then begin
     print, '==========================================================================='
     
     print, '  Aper. Photom. RMS calibration uncertainties :'
     if nrms gt 1 then begin    ; weird case when only one/zero scan is selected
        print, '-- A1 : ', strtrim(string(output_rms_errors_AP[0]*100.0d0, format='(f7.2)'), 2), '%'
        print, '-- A3 : ', strtrim(string(output_rms_errors_AP[1]*100.0d0,format='(f7.2)'), 2), '%'
        print, '-- 1mm: ', strtrim(string(output_rms_errors_AP[2]*100.0d0,format='(f7.2)'), 2), '%'
        print, '-- 2mm: ', strtrim(string(output_rms_errors_AP[3]*100.0d0,format='(f7.2)'), 2), '%'
     endif
  endif
     
  print, '==========================================================================='
    
  if nostop lt 1 then stop
  
end

