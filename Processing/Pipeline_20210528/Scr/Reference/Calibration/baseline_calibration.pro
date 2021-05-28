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
;;   COPY OF THE DEMONSTRATION VERSION (LP, April 2020)
;;_______________________________________________________________________

pro baseline_calibration
  
  ;;_____________________________________________________________________
  ;;
  ;; RUN NAME
  ;;
  ;; Several NIKA2 runs within the same cryo run can be jointly
  ;; analysed, for example : 
  ;;runname = ['N2R36', 'N2R37']
  ;;_____________________________________________________________________
  runname = ['N2R24'] 

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
  get_nika2_run_info, nika2run_info
  wrun = where(strmatch(nika2run_info.nika2run, runname[0]) gt 0)
  day = nika2run_info[wrun].lastday
  nk_get_kidpar_ref, '1', day, info, kidpar_file
  geom_kidpar_file = kidpar_file
  ;; 
  ;;________________________________________________________________________________________
  ;;geom_kidpar_file = !nika.off_proc_dir+'/kidpar_hybrid_a2_20180920s35_a13_20181103s314.fits'
  geom_kidpar_file = !nika.off_proc_dir+'/kidpar_hybrid_a2_20180920s35_a13_20181103s314_v2.fits'
  ;;geom_kidpar_file = !nika.off_proc_dir+'/kidpar_20181103s314_v2_LP.fits'
  ;;geom_kidpar_file = !nika.off_proc_dir+'/kidpar_20180920s35_v2_JFMP.fits'
  
  ;;___________________________________________________________________________
  ;;
  ;; ACTIONS
  ;;____________________________________________________________________________

  ;; PERFORM THE CALIBRATION
  do_opacity_correction        = 1
  do_absolute_calibration      = 1

  ;; >>>> When the two previous steps are done, the calibration is
  ;; completed
  ;; >>>> The next steps consists of validation and assessment of the
  ;; calibration quality
  
  ;; VALIDATION OF THE CALIBRATION
  ;; 1/ minimum validation: check the photometry on secondary calibrators 
  do_photometry_check_on_secondaries = 1
  
  ;; 2/ [REDUCTION OF ABOUT 100 SCANS] evaluate the RMS uncertainties on bright sources (>1Jy)
  do_rms_calibration_uncertainties   = 1
  
  ;; 3/ [REDUCTION OF ABOUT 100 SCANS] evaluate the NEFD using all sources < 1 Jy
  do_nefd_using_scatter_method       = 1 


  ;; OUTPUT THE CALIBRATION RESULTS
  ;; the IDL structure 'calibration' will be saved in the output directory 
  save_calibration_results           = 1
  

  ;; CROSS_CHECK PHOTOMETRY USING APERTURE PHOTOMETRY
  do_aperture_photometry             = 0
  
  ;; set to 1 to run the whole script without stopping after the main steps
  nostop = 1
  
  ;; set to 1 to stop after each step 
  pas_a_pas = 0

 
;; NO MORE EDITABLE SETTINGS FROM NOW ON

;;_______________________________________________________________________________________________
;;_______________________________________________________________________________________________
  basecalrun, runname, kidin = geom_kidpar_file,  $
              opacorr = do_opacity_correction, $
              abscal  = do_absolute_calibration, $
              photsec = do_photometry_check_on_secondaries, $
              rmscal  = do_rms_calibration_uncertainties, $
              nefd    = do_nefd_using_scatter_method, $
              savecal = save_calibration_results, $
              ap      = do_aperture_photometry, $
              nostop  = nostop, pas_a_pas = pas_a_pas
  
  
end
