;;
;;   PERFORM THE BASELINE CALIBRATION 
;;
;;  Purpose: perform the absolute calibration
;;  Output : a calibrated kidpar file
;;  Input  : a geometry kidpar file (produced using e.g. reduce_beammap)
;;  
;;
;;   CAN ALSO PERFORM THE VALIDATION INCLUDING:
;;    
;;   * Test of the photometry using secondary calibrators
;;   * Estimation of the point-source RMS calibration uncertainties
;;   using bright sources
;;   * Estimation of the NEFD at zero opacity using faint sources
;;
;;   DEMONSTRATION VERSION (LP, March 2020)
;; FXD, make it a routine with inputs
;; basecalrun from revision 24370 of baseline_calibration_demo
;; LP, updated for rev 24443
;;_______________________________________________________________________

pro basecalrun, runname, kidin = k_kidin,  $
                multiple_kidpars = multiple_kidpars, $
                opacorr = k_opa, no_iteropacorr = no_iteropacorr, $
                no_skydip_selection =  no_skydip_selection, $
                abscal = k_abscal, photsec = k_photsec, $
                rmscal = k_rmscal, nefd = k_nefd, savecal = k_savecal, $
                nostop = k_nostop, pas_a_pas = k_pas_a_pas, $
                ap = k_ap, $
                noplot = k_noplot, nopdf = k_nopdf, png = k_png

  ;;_____________________________________________________________________
  ;;
  ;; RUN NAME
  ;;
  ;; Several NIKA2 runs within the same cryo run can be jointly
  ;; analysed, for example : 
  ;;runname = ['N2R36', 'N2R37']
  ;;_____________________________________________________________________
;  runname = ['N2R14'] 

  ;; OUTPUT_DIR
  ;; All calibration results will be in getenv('NIKA_PLOT_DIR')+'/'+runname[0]
  
  ;;_____________________________________________________________________
  ;;
  ;; FOCAL PLANE GEOMETRY
  ;;
  ;; a geometry must have been produced using e.g. Geometry/reduce_beammap.pro
  ;;
  ;; in this case, geom_kidpar_file is the output of reduce_beammap.pro :
  ;; kidpar_<scan_id>_v2
  ;;
  ;; or one can start with the current reference kidpar as defined in
  ;; nk_get_kidpar_ref.pro. See the example below:
  ;;

  
  ;; In case of multiples kidpar used in a run, one can choose to let
  ;; nk_get_kidpar_ref picking the relevant kidpar for each scan
  ;; --> set the keyword multiple_kidpars

  if keyword_set(multiple_kidpars) then multiple_kidpars = 1 else multiple_kidpars = 0

  get_nika2_run_info, nika2run_info
  wrun = where(strmatch(nika2run_info.nika2run, runname[0]) gt 0)
  
  day = nika2run_info[wrun].lastday
  nk_get_kidpar_ref, '1', day, info, kidpar_file
  geom_kidpar_file = [kidpar_file]

  if multiple_kidpars gt 0 then begin
     day = nika2run_info[wrun].firstday
     nk_get_kidpar_ref, '1', day, info, kidpar_file_1
     
     day = nika2run_info[wrun].lastday
     nk_get_kidpar_ref, '1', day, info, kidpar_file_2
     
     geom_kidpar_file = [kidpar_file_1, kidpar_file_2]
  endif
  
  ;;geom_kidpar_file = !nika.off_proc_dir+'/kidpar_N2R14_baseline.fits'
  if (keyword_set( k_kidin)) then geom_kidpar_file = k_kidin
  ;; consistency with multipe kidpar cases
  if n_elements(geom_kidpar_file) eq 1 then geom_kidpar_file = [geom_kidpar_file]
  
  ;;___________________________________________________________________________
  ;;
  ;; ACTIONS
  ;;____________________________________________________________________________

  ;; PERFORM THE CALIBRATION
if keyword_set( k_opa) then $
   do_opacity_correction        = 1 else $
      do_opacity_correction     = 0
if keyword_set( k_abscal) then $
   do_absolute_calibration      = 1 else $
      do_absolute_calibration      = 0

  ;; >>>> When the two previous steps are done, the calibration is
  ;; completed
  ;; >>>> The next steps consists of validation and assessment of the
  ;; calibration quality
  
  ;; VALIDATION OF THE CALIBRATION
  ;; 1/ minimum validation: check the photometry on secondary calibrators 
if keyword_set( k_photsec) then $
   do_photometry_check_on_secondaries = 1 else $
      do_photometry_check_on_secondaries = 0

  ;; 2/ [REDUCTION OF ABOUT 100 SCANS] evaluate the RMS uncertainties on bright sources (>1Jy)
if keyword_set( k_rmscal) then $
   do_rms_calibration_uncertainties   = 1 else $
      do_rms_calibration_uncertainties   = 0
  
  ;; 3/ [REDUCTION OF ABOUT 100 SCANS] evaluate the NEFD using all sources < 1 Jy
if keyword_set( k_nefd) then $
   do_nefd_using_scatter_method       = 1 else $
      do_nefd_using_scatter_method       = 0
        

  ;; OUTPUT THE CALIBRATION RESULTS
  ;; the IDL structure 'calibration' will be saved in the output directory 
if keyword_set( k_savecal) then $
   save_calibration_results           = 1 else $
      save_calibration_results           = 0

;; CHECK USING APERTURE PHOTOMETRY
if keyword_set( k_ap) then $
   do_aperture_photometry = 1 else $
      do_aperture_photometry = 0


  ;; set to 1 to run the whole script without stopping after the main steps
if keyword_set( k_nostop) then nostop = 1 else nostop = 0
  
  ;; set to 1 to stop after each step 
if keyword_set(k_pas_a_pas) then pas_a_pas = 1 else pas_a_pas = 0


;; OUTPUT THE MAIN CALIBRATION PLOTS
;; default settings to produce the file of result plots
showplot = 1
if keyword_set(k_noplot) then begin
   showplot = 0
   png      = 0
   ps       = 0
   pdf      = 0
endif
if keyword_set(k_png) then png = 1 else png = 0
if keyword_set(k_nopdf) then begin
   ps  = 0
   pdf = 0
endif else begin
   ps  = 1
   pdf = 1
endelse
  

;; NO MORE EDITABLE SETTINGS FROM NOW ON

;;_______________________________________________________________________________________________
;;_______________________________________________________________________________________________


  ;; test calibration dir
;;calibration_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]
calibration_dir = getenv('NIKA_PLOT_DIR')+'/'+runname[0]
  if file_test(calibration_dir, /directory) lt 1 then spawn, "mkdir -p "+calibration_dir

  ;; test geom_kidpar_file
  if file_test(geom_kidpar_file[0]) lt 1 then begin
     print, 'Not found input kidpar file ', geom_kidpar_file[0]
     stop
  endif
  if multiple_kidpars gt 0 then begin
     if file_test(geom_kidpar_file[1]) lt 1 then begin
        print, 'Not found input kidpar file ', geom_kidpar_file[1]
        stop
     endif
  endif
  
  ;; test log file
  ;; test if a Log_Iram_tel file exists in Datamanage
  ;; otherwise create a local version of Log_Iram_tel
  logbook_dir = 1
  
  ;;print,"before get_calibration_scan_list"
  ;;print,!nika.raw_acq_dir
  get_calibration_scan_list, runname, scan_list, out_logbook_dir = logbook_dir
  ;;print,"after get_calibration_scan_list"
  ;;print,!nika.raw_acq_dir
    
  ;; init the calibration structure
  ;;====================================================================
  calibration = create_struct( "nika2run", strarr(2), $
                               "cryorun", 0, $
                               "detector_ref", 0, $
                               "svnrev", 0, $
                               "geom_kidpar_file", strarr(2), $
                               "skydip_scan_list", strarr(100), $
                               "opacity_kidpar_file", '', $
                               "input_kidpar_file", strarr(2), $
                               "multiple_kidpars", 0, $
                               "primary_calibrator", '', $
                               "primary_scan_list", strarr(100), $
                               "absolute_calibration_comment", '', $
                               "abscal_kidpar_file", strarr(2), $
                               ;;-------------------------------------------
                               "secondary_calibrator", '', $
                               "secondary_scan_list", strarr(100), $,
                               "calibration_bias", fltarr(4), $
                               "calibration_bias_rms", fltarr(4), $
                               "calibration_bias_AP", fltarr(4), $
                               "calibration_bias_rms_AP", fltarr(4), $
                               "photometry_check_comment", '', $
                               ;;------------------------------------------
                               "list_of_bright_sources", strarr(100), $
                               "total_scan_of_bright_sources", 0, $
                               "selected_scan_of_bright_sources", 0, $
                               "rms_calibration_error", fltarr(4), $
                               "rms_calibration_error_AP", fltarr(4), $
                               ;;------------------------------------------
                               "list_of_faint_sources", strarr(100), $
                               "number_of_faint_source_scans", 0, $,
                               "NEFD", fltarr(4), $
                               "rms_NEFD", fltarr(4),$
                               "mapping_speed", fltarr(4), $
                               "rms_mapping_speed", fltarr(4))
  ;;======================================================================

  ;; get SVN revision
  ;; inspired from nk_get_svn_rev, rev
  spawn, "svn info $NIKA_PIPELINE > bidon.dat"
  spawn, "grep -i revision bidon.dat", rev
  spawn, "rm -f bidon.dat"
  a = strsplit( rev, ":", /extract)
  rev = long( strtrim( a[1],2))
  calibration.svnrev = rev

 
  calibration.geom_kidpar_file[0] = geom_kidpar_file[0]
  calibration.multiple_kidpars = multiple_kidpars
  if multiple_kidpars gt 0 then calibration.geom_kidpar_file[1] = geom_kidpar_file[1]

  
;; 1/ OPACITY CORRECTION
;;_______________________________________________________________________________________________    
  
  if do_opacity_correction gt 0 then begin
     ;; No need to deal with multiple kidpars for the analysis of
     ;; skydip scans
    
     do_first_iteration  = 1
     if keyword_set( no_skydip_selection) then do_skydip_selection = 0 else $
        do_skydip_selection = 1
     if keyword_set( no_iteropacorr) then do_second_iteration = 0 else do_second_iteration = 1

     show_plot = 1
     check_after_selection  = 1 ;; launch again the selection code after the second iteration
     if keyword_set( no_skydip_selection) then check_after_selection  = 0
     skydip_scan_list = 1 
     base_skydip = 1
     if keyword_set( no_iteropacorr) then base_skydip = 0
     reduce_skydips_reference, runname, geom_kidpar_file[0], $
                               root_dir = calibration_dir, $
                               logbook_dir = logbook_dir, $
                               nostop = nostop, $
                               hightau2=0, atmlike=0, $
                               baseline=base_skydip, $
                               showplot=showplot, png=png, ps=ps, pdf=pdf, $
                               do_first_iteration=do_first_iteration, $
                               do_skydip_selection=do_skydip_selection, $
                               do_second_iteration=do_second_iteration, $
                               check_after_selection=check_after_selection, $
                               reiterate=reiterate, output_skydip_scan_list=skydip_scan_list, skdout = skdout

     ;; output:  output_dir+'/Opacity/kidpar_C0C1_'+runname[0]+'_baseline.fits'

     opacity_dir = calibration_dir+'/Opacity'
     calibration.opacity_kidpar_file = opacity_dir+'/kidpar_C0C1_'+runname[0]+'_baseline.fits'
     if keyword_set( skydip_scan_list) then calibration.skydip_scan_list = skydip_scan_list else $
        calibration.skydip_scan_list = skdout.scanname
     
     if nostop lt 1 then stop
     wd, /a
     
  endif
  
  
;; 2/ ABSOLUTE CALIBRATION
;;_______________________________________________________________________________________________
     
  if do_absolute_calibration gt 0 then begin


     photo_dir = calibration_dir+'/Photometry'
     if file_test(photo_dir, /directory) lt 1 then spawn, "mkdir -p "+photo_dir

     primary_dir = photo_dir+'/PrimaryCal'
     if file_test(primary_dir, /directory) lt 1 then spawn, "mkdir -p "+primary_dir
     
     version_name = '_baseline'
     
     ;; copy the C0, C1 skydip coefficients into the geometry kidpar
     skydip_kidpar_file = calibration_dir+'/Opacity/kidpar_C0C1_'+runname[0]+version_name+'.fits'
     input_kidpar_file = strarr(2)
     input_kidpar_file[0]  = photo_dir+'/input_kidpar_calib_'+runname[0]+version_name+'.fits'
     if (multiple_kidpars lt 1 and file_test(input_kidpar_file[0]) lt 1) then skydip_coeffs, geom_kidpar_file[0], skydip_kidpar_file, input_kidpar_file[0]

     ;; dealing with multiple kidpars
     ;; copy the CO, C1 directly in the geom_kidpars
     if multiple_kidpars gt 0 then begin
        input_kidpar_file =  photo_dir+'/input_kidpar_calib_'+runname[0]+version_name+['_part1', '_part2']+'.fits'
        for ikp = 0,1 do begin
           if file_test(input_kidpar_file[ikp]) lt 1 then begin
              skydip_coeffs, geom_kidpar_file[ikp], skydip_kidpar_file, input_kidpar_file[ikp]
              spawn, 'cp '+input_kidpar_file[ikp]+' '+geom_kidpar_file[ikp]
           endif
        endfor
     endif
     
     print, "Geometry kidpar_file: ",   geom_kidpar_file
     print, "Skydip kidpar_file: ", skydip_kidpar_file
     
     print, "Input kidpar_file for the absolute calibration: ",  input_kidpar_file

     calibration.opacity_kidpar_file = skydip_kidpar_file
     calibration.input_kidpar_file = input_kidpar_file

     ;; needed for absolute_calibration.pro
     if multiple_kidpars gt 0 then input_kidpar_file = geom_kidpar_file
     
     output_nickname = ''
     svn_rev = strtrim(calibration.svnrev,2) 
     if multiple_kidpars lt 1 then output_nickname = runname[0]+'_baseline_'+svn_rev else $
        output_nickname = runname[0] + '_baseline_'+svn_rev+['_part1', '_part2']
     
     
     if nostop lt 1 then begin
        rep = ''
        print, "Let's continue ?"
        read, rep
     endif

     
     ;; no photometric correction
     ;;____________________________________________________
     primary_calibrator = 1
     primary_scan_list  = 1
     output_comment     = 1
     absolute_calibration, runname, input_kidpar_file, $
                           multiple_kidpars = multiple_kidpars, $
                           root_dir = photo_dir, $
                           showplot=showplot, png=png, ps=ps, pdf=pdf, $
                           outlier_scan_list = outlier_scan_list, $
                           pas_a_pas = pas_a_pas, $
                           nostop = nostop, $
                           output_primary_calibrator = primary_calibrator, $
                           output_allinfo_file = output_allinfo_file, $
                           output_selected_scan_list = primary_scan_list, $
                           output_nickname = output_nickname, $
                           output_comment = output_comment, $
                           do_aperture_photometry=do_aperture_photometry

     calibration.primary_calibrator = primary_calibrator
     calibration.primary_scan_list = primary_scan_list
     calibration.absolute_calibration_comment = output_comment
     
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

     if do_aperture_photometry gt 0 then begin
        ap_absolute_calibration_file = photo_dir+"/AP_Absolute_calibration_"+runname[0]+version_name+'.save'
        restore, ap_absolute_calibration_file, /v
        print, ''
        print, '==========================================================================='
        print, ''
        print, '     Aperture-photometry-based absolute calibration cross-check '
        print, ''
        print, '==========================================================================='
        print, 'Uranus, total number of scans     = ', uranus_ntot
        print, 'Uranus, number of selected scans  = ', uranus_nsel
        print, 'Neptune, total number of scans    = ', neptune_ntot
        print, 'Neptune, number of selected scans = ', neptune_nsel
        print, ''
        print, 'Calibration Coefficients :'
        print, '-- A1 : ', AP_correction_coef[0], ', rms = ', AP_rms_correction_coef[0] 
        print, '-- A3 : ', AP_correction_coef[2], ', rms = ', AP_rms_correction_coef[2] 
        print, '-- 1mm: ', AP_correction_coef[3], ', rms = ', AP_rms_correction_coef[3]
        print, '-- 2mm: ', AP_correction_coef[1], ', rms = ', AP_rms_correction_coef[1] 
        print, '==========================================================================='
     endif
     
     if multiple_kidpars lt 1 then calibration.abscal_kidpar_file = [photo_dir+'/kidpar_'+output_nickname+'.fits'] $
        else calibration.abscal_kidpar_file = photo_dir+'/kidpar_'+output_nickname+'.fits'
     
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

     abscal_nickname = ''
     svn_rev=strtrim(calibration.svnrev,2)
     if multiple_kidpars lt 1 then abscal_nickname = runname[0]+'_baseline_'+svn_rev else $
        abscal_nickname = runname[0] + '_baseline_'+svn_rev+['_part1', '_part2']
     
     kidpar_file =  photo_dir+'/kidpar_'+abscal_nickname+'.fits'
        
     calibration.abscal_kidpar_file = kidpar_file
     print, "kidpar_file: "+kidpar_file

     ;; needed to deal with multiple kidpars in photometry_check_on_secondary
     if multiple_kidpars gt 0 then kidpar_file = ''
     
     photometry_check_on_secondaries, runname, kidpar_file, $
                                      multiple_kidpars = multiple_kidpars, $
                                      root_dir = photo_dir, $
                                      output_dir=secondary_dir, $
                                      showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                      outlier_scan_list = outlier_scan_list, $
                                      pas_a_pas = pas_a_pas, $
                                      nostop = nostop, $
                                      calibration_structure = calibration, $
                                      do_aperture_photometry=do_aperture_photometry
     

     
     if nostop lt 1 then stop
     wd, /a
  endif
     

  ;; 4/ CHECK FOR SYSTEMATIC EFFECTS USING ALL BRIGHT SOURCES (> 1Jy)
  ;;__________________________________________________________________     
  if do_rms_calibration_uncertainties gt 0 then begin
     
     validation_dir = calibration_dir+'/Validation'
     if file_test(validation_dir, /directory) lt 1 then spawn, "mkdir -p "+validation_dir
     
     version_name = '_baseline'
     
     abscal_nickname = ''
     svn_rev = strtrim(calibration.svnrev,2) 
     if multiple_kidpars lt 1 then abscal_nickname = runname[0]+'_baseline_'+svn_rev else $
        abscal_nickname = runname[0] + '_baseline_'+svn_rev+['_part1', '_part2']
        
     kidpar_file =  calibration_dir+'/Photometry/kidpar_'+abscal_nickname+'.fits'
     calibration.abscal_kidpar_file = kidpar_file
     print, "kidpar_file: "+kidpar_file


     ;; needed to deal with multiple kidpars in get_rms_calibration_uncertainties
     if multiple_kidpars gt 0 then kidpar_file = ''
     
     
     ;; OUTPUTS
     ;; "total_scan_of_bright_sources", 0, $
     ;; "selected_scan_of_bright_sources", 0, $
     ;; "rms_calibration_error", fltarr(4), $
     get_rms_calibration_uncertainties, runname, kidpar_file, $
                                        multiple_kidpars = multiple_kidpars, $
                                        output_dir=validation_dir, $
                                        showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                        outlier_scan_list = outlier_scan_list, $
                                        pas_a_pas = pas_a_pas, $
                                        nostop=nostop, $
                                        calibration_structure = calibration,$
                                        do_aperture_photometry=do_aperture_photometry

     
     if nostop lt 1 then stop
     wd, /a
  endif


  ;; 5/ CHECK THE NEFD USING ALL FAINT (moderately bright) SOURCES (< 1Jy)
  ;;________________________________________________________________________
  
  if do_nefd_using_scatter_method gt 0 then begin
     
     validation_dir = calibration_dir+'/Validation'
     if file_test(validation_dir, /directory) lt 1 then spawn, "mkdir -p "+validation_dir
     
     version_name = '_baseline'

     abscal_nickname = ''
     svn_rev = strtrim(calibration.svnrev,2) 
     if multiple_kidpars lt 1 then abscal_nickname = runname[0]+'_baseline_'+svn_rev else $
        abscal_nickname = runname[0] + '_baseline_'+svn_rev+['_part1', '_part2']
     
          
     ;;kidpar_file = calibration_dir+'/Photometry/kidpar_'+runname[0]+version_name+'.fits'
     kidpar_file = calibration_dir+'/Photometry/kidpar_'+abscal_nickname+'.fits'
     calibration.abscal_kidpar_file = kidpar_file
     print, "kidpar_file: "+kidpar_file

     ;; needed to deal with multiple kidpars in get_nefd_using_scatter_method 
     if multiple_kidpars gt 0 then kidpar_file = ''
     

     ;; OUTPUTS :
     ;;  "faint_source_list "
     ;;  "number_of_faint_sources", 0, $,
     ;;  "NEFD", fltarr(4), $
     ;;  "rms_NEFD", fltarr(4),$
     ;;  "mapping_speed", fltarr(4), $
     ;;  "rms_mapping_speed", fltarr(4))
     get_nefd_using_scatter_method, runname, kidpar_file, $
                                    multiple_kidpars=multiple_kidpars, $
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
  nickname = runname[0]+'_baseline_'+strtrim(calibration.svnrev, 2)
  calibration_file = calibration_dir+'/calibration_results_'+nickname+'.save'
  if save_calibration_results gt 0 then save, calibration, file=calibration_file
  if file_test(calibration_file) then restore, calibration_file
  
  print, ''
  print, ''
  print, ''
  print,'==================================================================='
  print, ''
  print, 'The production and validation of the calibration is completed'
  print, 'Congratulation!'
  print, ''
  print, 'Last step:'
  print, 'The lines above are to be copied in the Calibration wiki:'
  print, ''
  print, 'https://wiki.iram.fr/wiki/nika2/index.php/NIKA2Calibration'
  print, ''
  print,'==================================================================='
  print, ''
  print, ''
  print, ''
  ;;==========================================================================='
  ;;
  ;;     SUMMARY  TABLE 
  ;;
  ;;==========================================================================='
  print, '[[NIKA2Calibration | Back to the main calibration page]]'
  print, ''
  print,'<!--===================================================================-->'
  print,''
  print,''
  print,'==     SUMMARY  TABLE    == '
  print,''
  print,'CALIBRATION OF ', runname[0],'  <br />'
  print,'Using the SVN revision of the IDL pipeline = ', calibration.svnrev, '  <br /> '
  print,'All results are summarised below'
  print,''
  print,''
  print,'<!--====================================================================-->'
  print, 'KIDPAR FILES: '
  print, '* Geometry kidpar file: ', calibration.geom_kidpar_file
  print, '* Opacity kidpar file: ', calibration.opacity_kidpar_file
  print, '* Output kidpar file: ', calibration.abscal_kidpar_file
  
  photo_dir = calibration_dir+'/Photometry'
  nickname = runname[0]+'_baseline'
  acal_file = photo_dir+"/Absolute_calibration_"+nickname+'.save'
  if file_test(acal_file) gt 0 then begin
     ;;print, "reading : ",acal_file
     restore, acal_file
     print, ''
     print, '<!--===========================================================================-->'
     print, ''
     print, '===   Absolute calibration summary   === '
     print, ''
     print, '<!--===========================================================================-->'
     print, 'Uranus:'
     print, '* total number of scans     = ', uranus_ntot
     print, '* number of selected scans  = ', uranus_nsel
     print, 'Neptune: '
     print, '* total number of scans    = ', neptune_ntot
     print, '* number of selected scans = ', neptune_nsel
     print, ''
     if strcmp(selection_type, 'lastchance', /fold_case) gt 0 then begin
        print, 'No scan met the nominal selection criteria'
        ;;print, 'The absolute calibration will be let unchanged
        ;;w.r.t. whose of the geometry kidpar'
        if defined(selected_scan_list) then begin
           print, 'Selected scan list: '
           print, '[ '
           for i=0, n_elements(selected_scan_list)-1 do print, selected_scan_list[i]
           print, ']'
        endif
        print, ''
     endif
     if defined(predicted_flux_1mm) then begin
        print, 'Primary calibrators expected flux for the selected scans [Jy]: '
        print, '* 1mm: ', predicted_flux_1mm
        print, '* 2mm: ', predicted_flux_2mm
        print, ''
     endif     
     print, 'Calibration Coefficients (Expected flux / Raw flux) :'
     print, '* A1 : ', correction_coef[0], ', rms = ', rms_correction_coef[0] 
     print, '* A3 : ', correction_coef[2], ', rms = ', rms_correction_coef[2] 
     print, '* 1mm: ', correction_coef[3], ', rms = ', rms_correction_coef[3]
     print, '* 2mm: ', correction_coef[1], ', rms = ', rms_correction_coef[1]
     print, ''
     print, 'Number of valid KIDs : '
     
     kp = mrdfits(calibration.abscal_kidpar_file[0], 1)
     w1 = where(kp.type eq 1 and kp.array eq 1, nw1)
     w1 = where(kp.type eq 1 and kp.array eq 2, nw2)
     w1 = where(kp.type eq 1 and kp.array eq 3, nw3)
     print, '* A1 : ', strtrim(nw1,1)
     print, '* A3 : ', strtrim(nw3,1)
     print, '* A2 : ', strtrim(nw2,1)
     print, '<!--===========================================================================-->'
  endif
  
  ap_acal_file = photo_dir+"/AP_Absolute_calibration_"+nickname+'.save'
  if file_test(ap_acal_file) gt 0 then begin
     ;;print, "reading : ",acal_file
     restore, ap_acal_file
     print, ''
     print, '<!--===========================================================================-->'
     print, ''
     print, '====   Cross-check using Aperture Photometry    ==== '
     print, ''
     print, '<!--===========================================================================-->'
     print, 'AP Calibration Coefficients (Expected flux / Raw AP flux) :'
     print, '* A1 : ', ap_correction_coef[0], ', rms = ', ap_rms_correction_coef[0] 
     print, '* A3 : ', ap_correction_coef[2], ', rms = ', ap_rms_correction_coef[2] 
     print, '* 1mm: ', ap_correction_coef[3], ', rms = ', ap_rms_correction_coef[3]
     print, '* 2mm: ', ap_correction_coef[1], ', rms = ', ap_rms_correction_coef[1]
     print, ''
     print, '<!--===========================================================================-->'
  endif
  
  second_dir = photo_dir + '/SecondaryCal'
  second_file = second_dir+'/photometry_check_on_secondaries.save'
  if file_test(second_file) gt 0 then begin
     ;;print, "reading : ",second_file
     restore, second_file
     print, ''
     print, '<!--===========================================================================-->'
     print, ''
     print, '===  Photometry check on secondary calibrators  === '
     print, ''
     print, '<!--===========================================================================-->'
     print, 'Secondary calibrator              = ', secondary.calibrator, '   <br />'
     w = where(strmatch(secondary.selected_scan_list, '') eq 0, n)
     print, '* number of selected scans          = ', strtrim(n,2)
     w = where(strmatch(secondary.observed_scan_list, '') eq 0, n)
     print, '* total number of scans             = ', strtrim(n, 2)
     print, ''
     if calibration.photometry_check_comment ne '' then begin
        print, 'COMMENT: ',calibration.photometry_check_comment
        print, ''
     endif
     print, 'Calibration bias (Measured/Expected):'
     print, '* A1 : ', (secondary.calibration_bias)[0] , ', rms = ', (secondary.calibration_bias_rms)[0] 
     print, '* A3 : ', (secondary.calibration_bias)[1] , ', rms = ', (secondary.calibration_bias_rms)[1] 
     print, '* 1mm: ', (secondary.calibration_bias)[2] , ', rms = ', (secondary.calibration_bias_rms)[2]
     print, '* 2mm: ', (secondary.calibration_bias)[3] , ', rms = ', (secondary.calibration_bias_rms)[3]
     print, '<!--===========================================================================-->'
     if do_aperture_photometry gt 0 then begin
        print, '==== Aper. Photom. Calibration bias (point source abs. cal.): ===='
        print, '*A1 : ', (secondary.calibration_bias_AP)[0] , ', rms = ', (secondary.calibration_bias_rms_AP)[0] 
        print, '*A3 : ', (secondary.calibration_bias_AP)[1] , ', rms = ', (secondary.calibration_bias_rms_AP)[1] 
        print, '*1mm: ', (secondary.calibration_bias_AP)[2] , ', rms = ', (secondary.calibration_bias_rms_AP)[2]
        print, '*2mm: ', (secondary.calibration_bias_AP)[3] , ', rms = ', (secondary.calibration_bias_rms_AP)[3]
        print, '<!--===========================================================================-->'
     endif
  endif


  
  ;if do_rms_calibration_uncertainties gt 0 then begin
     print, ''
     print, '<!--===========================================================================-->'
     print, ''
     print, '===    Point sources RMS calibration uncertainties   ==='
     print, ''
     print, '<!--===========================================================================-->'
     bs = calibration.list_of_bright_sources
     ubs = bs[ sort(bs)]
     unbs = uniq( ubs)
     print, 'List of used bright point sources = ', ubs[ unbs]
     print, '*number of selected scans          = ', strtrim(calibration.selected_scan_of_bright_sources,2)
     print, '*total number of scans             = ', strtrim(calibration.total_scan_of_bright_sources, 2)
     print, ''
     print, 'RMS calibration uncertainties :'
     print, '* A1 : ', strtrim(string(calibration.rms_calibration_error[0]*100.0d0, format='(f6.2)'), 2), '%'
     print, '* A3 : ', strtrim(string(calibration.rms_calibration_error[1]*100.0d0,format='(f6.2)'), 2), '%'
     print, '* 1mm: ', strtrim(string(calibration.rms_calibration_error[2]*100.0d0,format='(f6.2)'), 2), '%'
     print, '* 2mm: ', strtrim(string(calibration.rms_calibration_error[3]*100.0d0,format='(f6.2)'), 2), '%'
     print, '<!--===========================================================================-->'
     if do_aperture_photometry gt 0 then begin
        print, '  Aper. Photom. RMS calibration uncertainties :'
        print, '* A1 : ', strtrim(string(calibration.rms_calibration_error_AP[0]*100.0d0, format='(f6.2)'), 2), '%'
        print, '* A3 : ', strtrim(string(calibration.rms_calibration_error_AP[1]*100.0d0,format='(f6.2)'), 2), '%'
        print, '* 1mm: ', strtrim(string(calibration.rms_calibration_error_AP[2]*100.0d0,format='(f6.2)'), 2), '%'
        print, '* 2mm: ', strtrim(string(calibration.rms_calibration_error_AP[3]*100.0d0,format='(f6.2)'), 2), '%'
        print, '<!--===========================================================================-->'
     endif
  
  ;if do_nefd_using_scatter_method gt 0 then begin
     print, ''
     print, '<!--===========================================================================-->'
     print, ''
     print, '===  NEFD at zero atmospheric opacity using faint sources    ==='
     print, ''
     print, '<!--===========================================================================-->'
     faint_sources = calibration.list_of_faint_sources
     w=where(strlen(faint_sources) ge 1, nn )
     fs= ''
     if nn gt 0 then for i =0, nn-1 do fs=fs+faint_sources[w[i]]+' '
     afs = faint_sources[ sort(faint_sources)]
     ufs = uniq( afs)
     print, 'List of used faint sources        = ', strjoin( afs[ ufs]+' ')+' <br/>'
     print, 'number of selected scans          = ', strtrim(calibration.number_of_faint_source_scans,2)
     print, ''
     print, 'NEFD AT ZERO ATMOSPHERIC OPACITY [mJy s^{0.5}]:'
     print, '* A1 : ', strtrim(string(calibration.nefd[0], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[0], format='(f5.1)'),2)
     print, '* A3 : ', strtrim(string(calibration.nefd[1], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[1], format='(f5.1)'),2)
     print, '* 1mm: ', strtrim(string(calibration.nefd[2], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[2], format='(f5.1)'),2)
     print, '* 2mm: ', strtrim(string(calibration.nefd[3], format='(f5.1)'),2), ' +- ', $
            strtrim(string(calibration.rms_nefd[3], format='(f5.1)'),2)
     print, ''
     print, 'MAPPING SPEED AT ZERO ATMOSPHERIC OPACITY [arcmin^2 / mJy^2 / hr]:'
     print, '* A1 : ', strtrim(string(calibration.mapping_speed[0], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[0], format='(f6.0)'),2)
     print, '* A3 : ', strtrim(string(calibration.mapping_speed[1], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[1], format='(f6.0)'),2)
     print, '* 1mm: ', strtrim(string(calibration.mapping_speed[2], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[2], format='(f6.0)'),2)
     print, '* 2mm: ', strtrim(string(calibration.mapping_speed[3], format='(f6.0)'),2), ' +- ', $
            strtrim(string(calibration.rms_mapping_speed[3], format='(f6.0)'),2)
     print, '<!--===========================================================================-->'
     
  ;endif


  ;; GATHER ALL PLOTS IN A SINGLE PDF FILE
  pdf_file_name = calibration_dir+'/calibration_main_plot_summary_'+runname[0]+'_'+strtrim(calibration.svnrev,2)+'.pdf' 
  spawn, 'ls '+calibration_dir+'/Opacity/*.pdf', opa_list
  spawn, 'rm -f '+calibration_dir+'/Photometry/PrimaryCal/aperture*.pdf'
  spawn, 'rm -f '+calibration_dir+'/Photometry/SecondaryCal/aperture*.pdf'
  spawn, 'ls '+calibration_dir+'/Photometry/PrimaryCal/*.pdf', cal_list
  spawn, 'ls '+calibration_dir+'/Photometry/SecondaryCal/*.pdf', phot_list
  spawn, 'ls '+calibration_dir+'/Validation/*.pdf', val_list
  all_list = [opa_list, cal_list, phot_list, val_list]
  pdf_str = ''
  npdf = n_elements(all_list)
  for i=0, npdf-1 do pdf_str=pdf_str+all_list[i]+' '
  spawn, 'which pdfunite', res
  if strlen( strtrim(res, 2)) gt 0 and total( strlen(all_list)) gt 0 then $
     spawn, 'pdfunite '+pdf_str+' '+pdf_file_name
  
  print, ''
  print, ''
  print, '== MAIN PLOTS =='
  print,'[[Media:Calibration_main_plot_summary_'+runname[0]+'_'+strtrim(calibration.svnrev,2)+'.pdf]]'
  print,''
  print,'' 
  print, 'Please copy the lines above in the calibration wiki page'
  print, 'in the calibration table, click in the link Plots, in the row labelled Details, and paste the copied lines in the new opened page.'
  print, 'Save the page.'
  print, 'Then upload the file of the main plots by clicking on the link Media:... at the bottom of the page.'
  print, ''
  
  print, 'Thank you very much!'
  
  print, 'This the end of the code...'
  if nostop lt 1 then print, '.c to go out'
  if nostop lt 1 then stop


  
  
end
