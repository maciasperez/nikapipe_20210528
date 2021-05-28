;;
;;   VALIDATION OF THE BASELINE CALIBRATION USING ALL THE OTF SCANS  
;;
;;  Purpose: once a baseline calibration is done, assess the
;;  uncertainties and check for residual systematic effects
;;
;;  INPUT : the kidpar file produced using baseline_calibration.pro
;;
;;  series of scripts based on the work of the commissioning 'Tiger Team'
;;
;;   LP, January 2019
;;_______________________________________________________________

pro validate_baseline_calibration

  ;; RUN NAME
  ;;__________________________________________
  
  runname = 'N2R23'

  ;; for each run,  results will be in
  ;; getenv('NIKA_PLOT_DIR')+'/'+runname


  ;; Baseline calibration kidpar
  ;;__________________________________________

  kidpar_file = '/home/perotto/NIKA/Plots/N2R23/Photometry/Uranus_photometry_N2R23_ref_baseline/kidpar_N2R23_ref_baseline.fits'

  ;; [OPTION] list of sources
  ;;__________________________________________
  ;; for reducing the scans of a list of source only
  calib_sources = ['uranus', 'neptune', 'mars', 'mwc349', 'crl2688', 'ngc7027']
  allsources = 0
  ;; [default] treat all the OTF scans
  allsources = 1

  
  ;; [OPTION] DISCARD OUTLIERS
  ;;__________________________________________
  outlier_scan_list = ''
  

  ;; LIST OF CHECKS TO BE PERFORMED
  ;;__________________________________________
  do_uranus    = 1
  do_mwc349    = 1
  do_allbright = 1
  do_nefd      = 1

  ;; MISC
  ;;__________________________________________
  nostop   = 1
  savefile = 0

  png = 1
  ps  = 0
  pdf = 0
  
  
  ;;______________________________________________________________________________
  ;;______________________________________________________________________________


  ;; 1./ REDUCE ALL OTF SCANS
  ;;_______________________________________________________________________________
  if allsources lt 1 then source_list=calib_sources else source_list=0
  get_calibration_scan_list, runname, scan_list, source_list=source_list, outlier_scan_list=outlier_scan_list
  
  relaunch  = 1
   
  launch_point_source_batch, runname, label='', force_scan_list = scan_list, relaunch=relaunch



  ;; 2/ CHECK THE ABSOLUTE CALIBRATION USING URANUS
  ;;____________________________________________________________
  if do_uranus then check_flux_density_ratio_primary, png=png, ps=ps, pdf=pdf, $
     fwhm_stability=1, $
     obstau_stability=1, $
     opacorr_method = 1, $
     photocorr_method = 1, $
     nostop = nostop, savefile = savefile

  ;; 3/ CHECK THE ABSOLUTE CALIBRATION USING MWC349
  ;;_____________________________________________________________
  if do_mwc349 then check_flux_density_ratio_secondary, png=png, ps=ps, pdf=pdf, $
     fwhm_stability=0, $
     obstau_stability=0, $
     mwc349_stability=1, $
     opacorr_method  = 1, $
     photocorr_method = 1, $
     nostop = nostop, savefile = savefile

  ;; 4/ CHECK FOR SYSTEMATIC EFFECTS USING ALL BRIGHT SOURCES (> 1Jy)
  ;;__________________________________________________________________
  if do_allbright then check_flux_density_ratio_all, png=png, ps=ps, pdf=pdf, $
     obsdate_stability=1, $
     fwhm_stability=0, $
     obstau_stability=1, $
     opacorr_method = 1, $
     photocorr_method = 1, $
     nostop = nostop, savefile = savefile
  
  ;; 5/ CHECK THE NEFD USING ALL FAINT (moderately bright) SOURCES (< 1Jy)
  ;;________________________________________________________________________
  if do_nefd then check_nefd_vs_observed_opacity, png=png, ps=ps, pdf=pdf, $
     opacorr_method = 1, $
     photocorr_method = 1, $
     nostop = nostop, savefile = savefile
  
  stop

  
end
  
