
;;
;;   REFERENCE LAUNCHER SCRIPT TO ASSESS...
;;
;;                ...THE NEFD AS A FUNCTION OF THE LINE_OF_SIGHT OPACITY
;;
;;   LP, March 2020
;;_______________________________________________________________________________

pro get_nefd_using_scatter_method, runname, input_kidpar_file, $
                                   multiple_kidpars = multiple_kidpars, $
                                   output_dir=output_dir, $
                                   showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                   outlier_scan_list = outlier_scan_list, $
                                   pas_a_pas = pas_a_pas, $
                                   nostop=nostop, $
                                   output_nickname = output_nickname, $
                                   calibration_structure = calibration_structure
  
  ;; setting output_dir
  if keyword_set(output_dir) then output_dir = output_dir else $
     output_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]+'/Validation'
  if file_test(output_dir, /directory) lt 1 then spawn, "mkdir -p "+output_dir
  if file_test(output_dir+'/NEFD', /directory) lt 1 then spawn, "mkdir -p "+output_dir+'/NEFD'
  
  ;; dealing with stops in the code
  if keyword_set(nostop) then nostop = 1 else nostop=0
  if keyword_set(pas_a_pas) then pas_a_pas = 1-nostop else pas_a_pas = 0

  ;; Pool with more than one kidpar
  if keyword_set(multiple_kidpars) then multiple_kidpars = 1 else multiple_kidpars = 0
   
  ;; NAME
  if keyword_set(output_nickname) then nickname = output_nickname else begin
     if multiple_kidpars lt 1 then nickname = runname[0]+'_baseline' else nickname = runname[0] + '_baseline'+['_part1', '_part2']
  endelse

  ;; no aperture photometry check for NEFD
  do_aperture_photometry=0
    
  ;; Flux threshold for sources selection
  flux_threshold_1mm = 1.0d0
  flux_threshold_2mm = 0.5d0

  ;; SELECTION OF FAINT SOURCES
  source_rootnames = ['PSZ', 'ACT', 'GOODS', 'COSMOS', 'G2', 'HLS', 'Pluto', 'HD1']

  ;; MAXIMUM NUMBER OF SCANS TO REDUCE
  maximum_nscan = 100.

  ;; ALREADY REDUCED SCANS
  spawn, 'ls '+output_dir+'/NEFD/v_1/*/results.save | wc -l', nreduced
  maximum_nscan = maximum_nscan - nreduced
  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          DATA ANALYSIS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  if maximum_nscan ge 1 then begin
     scan_info = 1
     get_calibration_scan_list, runname, scan_list, $
                                source_list=sources, $
                                source_rootnames=source_rootnames, $
                                outlier_scan_list=outlier_scan_list, $
                                scan_info=scan_info, $
                                maximum_nscan = maximum_nscan
     
     nscans = n_elements(scan_list)
     if strlen( strtrim(scan_list[0], 2)) eq 0 then nscans = 0
     print, "NEFD nscans = ", nscans
     ;; scan_list = scan_list[0:19]
     ;; nscans = n_elements( scan_list)
     ;; print, "LIMITED nscans = ", nscans
     ;; stop  ; To BE COMMENTED
     
     ;; nk analysis using baseline parameters
     if (multiple_kidpars lt 1 and file_test(input_kidpar_file[0]) lt 1) then begin
        print, "Validation of the calibration: input kidpar file not found ", input_kidpar_file[0]
        print, "Have to stop here, sorry..."
        stop
     endif
     if (nscans gt 0 and strlen(scan_list[0]) gt 1) then begin
        print,'ESTIMATION OF THE NEFD....'
        print,'NUMBER OF SCANS THAT ARE (OR WILL BE) REDUCED = ', nscans
        if multiple_kidpars lt 1 then begin
           print,'USING ', input_kidpar_file[0]
           if pas_a_pas then stop
           launch_baseline_nk_batch, runname, input_kidpar_file[0], label='', $
                                     force_scan_list = scan_list, $
                                     output_dir = output_dir+'/NEFD', $
                                     relaunch=1, do_aperture_photometry=do_aperture_photometry
        endif else begin
           print, 'using the reference kidpar as defined in nk_get_kidpar_ref.pro'
           launch_baseline_nk_batch, runname, '', label='', $
                                     force_scan_list = scan_list, $
                                     output_dir = output_dir+'/NEFD', $
                                     relaunch=1, do_aperture_photometry=do_aperture_photometry
        endelse
     endif else begin
        print, "NEFD USING THE SCATTER METHOD: no scan found ???"
        print, "Nothing I can do..."
        ;; stop
     endelse
  endif
  
  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  get_all_scan_result_file, runname, allresult_file, outputdir = output_dir+'/NEFD', ecrase_file=0
  
  ;;
  ;;  restore result tables
  ;;____________________________________________________________
  print, ''
  print,'READING RESULT FILE: '
  print, allresult_file
  if nscans gt 0 then begin
     restore, allresult_file, /v
  ;; allscan_info

  
  ;; SCAN SELECTION
  ;;------------------------------------------------------------------
  flux_threshold_1mm = 0.8d0
  flux_threshold_2mm = 0.8d0
  faint = 1

  ;; not useful a priori with faint=1 
  weak_fwhm_max   = [20., 20., 20.]    ;; for the scans observed during nights and mornings
  strong_fwhm_max = [20., 20., 20.] ;; for the scans observed during afternoons
  fwhm_max        = [20., 20., 20.] ;; for the FWHM-based selection (practical)
  
  select_scans, allscan_info, index_select,$
                flux_threshold_1mm = flux_threshold_1mm, $
                flux_threshold_2mm = flux_threshold_2mm, $
                faint = faint, $
                fwhm_max = fwhm_max, $
                weak_fwhm_max = weak_fwhm_max, $
                strong_fwhm_max = strong_fwhm_max, $
                output_dir=output_dir, $
                showplot = 1, png=png, $
                pas_a_pas = pas_a_pas  

  ;; NB: allscan_info now only contains sources below the flux threshold
  
  cal_info = allscan_info[index_select]
  ntot   = n_elements(allscan_info)
  nscans = n_elements(cal_info)
  
  selected_scan_list = cal_info.scan
  
  if nostop lt 1 then stop
  wd, /a
  
 
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          PLOTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  duncoup = 1-pas_a_pas
  output_nefd0  = 1
  output_mapping_speed0 = 1
  output_source_list = 1
  plot_nefd_using_scatter, allscan_info, index_select, $
                           outplot_dir = output_dir, $
                           png=png, ps=ps, pdf=pdf, $
                           obsdate_stability=1, $
                           obstau_stability=1, $
                           nostop = duncoup, $
                           output_nefd0 = output_nefd0, $
                           output_mapping_speed0 = output_mapping_speed0, $
                           output_source_list = output_source_list
  


  
  ;;===========================================================================
  ;;===========================================================================
  ;;
  ;;          OUTPUTS
  ;;
  ;;===========================================================================
  ;;===========================================================================
  if keyword_set(calibration_structure) then begin
     ;;  "list_of_faint_sources"
     ;;  "number_of_faint_sources", 0, $,
     ;;  "NEFD", fltarr(4), $
     ;;  "rms_NEFD", fltarr(4),$
     ;;  "mapping_speed", fltarr(4), $
     ;;  "rms_mapping_speed", fltarr(4))
     calibration_structure.list_of_faint_sources         = output_source_list
     calibration_structure.number_of_faint_source_scans  = nscans 
     calibration_structure.nefd                          = output_nefd0(*, 0)
     calibration_structure.rms_nefd                      = output_nefd0(*, 1)
     calibration_structure.mapping_speed                 = output_mapping_speed0(*, 0)
     calibration_structure.rms_mapping_speed             = output_mapping_speed0(*, 1)
  endif 
  print, ''
  print, '==========================================================================='
  print, ''
  print, '     NEFD AT ZERO ATMOSPHERIC OPACITY USING FAINT SOURCES '
  print, ''
  print, '==========================================================================='
  print, 'List of used faint sources        = ', output_source_list
  print, 'number of selected scans          = ', strtrim(nscans,2)
  print, ''
  print, 'NEFD AT ZERO ATMOSPHERIC OPACITY:'
  print, '-- A1 : ', strtrim(string(output_nefd0[0,0], format='(f5.1)'),2), ' +- ', $
         strtrim(string(output_nefd0[0,1], format='(f5.1)'),2)
  print, '-- A3 : ', strtrim(string(output_nefd0[1,0], format='(f5.1)'),2), ' +- ', $
         strtrim(string(output_nefd0[1,1], format='(f5.1)'),2)
  print, '-- 1mm: ', strtrim(string(output_nefd0[2,0], format='(f5.1)'),2), ' +- ', $
         strtrim(string(output_nefd0[2,1], format='(f5.1)'),2)
  print, '-- 2mm: ', strtrim(string(output_nefd0[3,0], format='(f5.1)'),2), ' +- ', $
         strtrim(string(output_nefd0[3,1], format='(f5.1)'),2)
  print, ''
  print, 'MAPPING SPEED AT ZERO ATMOSPHERIC OPACITY:'
  print, '-- A1 : ', strtrim(string(output_mapping_speed0[0,0], format='(f6.0)'),2), ' +- ', $
         strtrim(string(output_mapping_speed0[0,1], format='(f6.0)'),2)
  print, '-- A3 : ', strtrim(string(output_mapping_speed0[1,0], format='(f6.0)'),2), ' +- ', $
         strtrim(string(output_mapping_speed0[1,1], format='(f6.0)'),2)
  print, '-- 1mm: ', strtrim(string(output_mapping_speed0[2,0], format='(f6.0)'),2), ' +- ', $
         strtrim(string(output_mapping_speed0[2,1], format='(f6.0)'),2)
  print, '-- 2mm: ', strtrim(string(output_mapping_speed0[3,0], format='(f6.0)'),2), ' +- ', $
         strtrim(string(output_mapping_speed0[3,1], format='(f6.0)'),2)
  print, '==========================================================================='
endif
  
  if nostop lt 1 then stop
  
end

