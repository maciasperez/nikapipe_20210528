;;
;;   LAUNCH validate_calibration_reference_quasar.pro
;;
;;
;;   LP, Sept 2018
;;_______________________________________________________________


pro launch_validate_calibration_reference_quasar


  ;; DATASET
  ;;__________________________________________
  
  runname_tab = ['N2R9', 'N2R12', 'N2R14']

   
  ;; FOCAL PLANE GEOMETRY
  ;;__________________________________________
  n2r9_input_kidpar_file  = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'
  n2r12_input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'
  n2r14_input_kidpar_file = !nika.off_proc_dir+'/kidpar_20180122s309_v2_HA_skd16_calUranus17.fits'
  
  kidpar_file_tab = [n2r9_input_kidpar_file, $
                     n2r12_input_kidpar_file, $
                     n2r14_input_kidpar_file]
  

  ;; SKYDIP SELECTION
  ;;__________________________________________
  
  opacity_selection_tab = ['baseline', 'atmlike', 'atmlike']
  
  hybrid_opacity        = 0
  opacity_from_tau225   = 0
    
  
  ;; PHOTOMETRIC CORRECTION
  ;;__________________________________________
  
  photometric_correction    = 'none'

  ;; Let's uncomment the line below for 'demonstration case
  ;; photometric correction'
  ;;-------------------------------------------------------
  ;;photometric_correction    = 'modif_variable1'
  
  ;; Let's uncomment the line below for 'pointing-based
  ;; photometric correction'
  ;;photometric_correction  = 'fwhm_pointing'

  
  ;; Absolute calibration per array
  ;;__________________________________________
  
  calibration_per_array = 1
  
  ;; version_name = '_ref'+ opa_version_name
  test_nickname = '_v2'
 
  nostop = 1

  
;;_______________________________________________________________________________________________
;;_______________________________________________________________________________________________
  
  nrun = n_elements(runname_tab)
  for irun = 0, nrun-1 do begin
     
     runname = runname_tab[irun]
     input_kidpar_file = kidpar_file_tab[irun]

     output_dir = getenv('HOME')+'/NIKA/Plots/'+runname
     if file_test(output_dir, /directory) gt 1 then spawn, "mkdir -p "+output_dir
 
             
     opa_version_name = ''
     case strlowcase(opacity_selection_tab[irun]) of
        'baseline': opa_version_name = '_ref_baseline'
        'atmlike':  opa_version_name = '_ref_atmlike'
        'hightau2': begin
           version_name = '_ref_hightau2'
           if strlowcase(runname) eq 'n2r9' then opa_version_name = '_ref_hightau2_v3'
           if strlowcase(runname) eq 'n2r12' then opa_version_name = '_ref_hightau2_v2'
        end
        else: print, 'non recognised opacity selection for run ', runname
     endcase
     
        
     ;;photocorr_name = photocorr_suffixe
     output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'

     ;; absolute calibration using no photometric correction
     ;; and without using the hybrid opacity correction
     ;; to be rescaled afterwards
     ;; (easiest for testing sevral photmetric corrections)
     ;;input_kidpar_file =
     ;;getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+opa_version_name+test_nickname+photocorr_name+calpera'.fits'
     
     cal_suf = ''
     if calibration_per_array gt 0 then cal_suf = '_calpera'
     
     input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+$
                          '/Photometry/Uranus_photometry_'+runname+opa_version_name+test_nickname+'/'+$
                          'kidpar_calib_'+runname+opa_version_name+test_nickname+cal_suf+'.fits'
     png=1

     print, '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
     print, ''
     print, runname, ': input_kidpar_file = '
     print, input_kidpar_file
     print, 'OK ?'
     stop
     
     
;; photometric correction
;;-----------------------------
     var2_photocorr = 0
     fix_photocorr  = 0
     var1_photocorr = 0
     
     case strlowcase(photometric_correction) of
        'fwhm_pointing': begin
           fix_photocorr = [12.5, 18.5, 12.5]
           photocorr_suffixe = '_photocorr_fwhm_pointing'
           photocorr_using_pointing = 1
        end
        'none': photocorr_suffixe=''
        'modif_variable1': begin
           fix_photocorr = [12.5, 18.5, 12.5]
           delta_fwhm    = 0
           photocorr_suffixe = '_photocorr_mod_var1'
        end
        else: print, 'non recognised photometric correction'
     endcase
     
     
     opa_suf = ''
     if hybrid_opacity gt 0 then opa_suf = '_hybrid_v0'
     
     ;; recalibration coefficients
     ;;----------------------------------------------------------------------------------------
     
     ;; calibration coefficients of the input kidpar
     ;;input_calib_file = output_dir+'/Absolute_calibration_'+runname+opa_version_name+test_nickname+cal_suf+'.save'
     ;;print, 'reading input_abscalib_file = ', input_calib_file
     ;;restore,input_calib_file
     ;;input_calib = correction_coef
     
     ;; calibration coefficient for the tested photometric correction  
     ;;test_calib_file = output_dir+'/Absolute_calibration_'+runname+opa_version_name+test_nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
     ;;print, 'reading test_abscalib_file = ', test_calib_file
     ;;restore, test_calib_file
     ;;test_calib  = correction_coef
     
     ;;recalibration_coef = test_calib/input_calib
     
     ;;recal_coef_file = output_dir+'/Calibration_coefficients_'+runname+opa_version_name+test_nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
     ;;save,  recalibration_coef, filename=recal_coef_file
     
     ;; hybrid opacity
     ;;-----------------------------
     use_hybrid_opacity = 0
     hybrid_opacity_after_reduction = 0
     if hybrid_opacity gt 0 then hybrid_opacity_after_reduction = 1
     
     ;; SCAN LIST
     outlier_scan_list = ['20170226s350', $
                          '20170224s193', '20170224s194', '20170224s195', '20170224s196', '20170224s197', $
                          '20170225s24', '20171029s205', '20170225s467', $
                          '20180117s300', '20180120s9', '20180120s257' ]
     
     
     output_allinfo_file = 'Quasar_allinfo_'+runname+'_baseline_v2.save'
     
     validate_calibration_reference_quasar, runname, input_kidpar_file,$
                                            output_dir=output_dir, showplot=showplot, png=png, $
                                ;fix_photocorr=fix_photocorr, $
                                ;var1_photocorr=var1_photocorr, $
                                ;var2_photocorr=var2_photocorr, $
                                ;photocorr_using_pointing=photocorr_using_pointing, $
                                ;delta_fwhm=delta_fwhm, $
                                ;photometric_correction_suffixe=photocorr_suffixe, $
                                            opa_version_name=opa_version_name, $
                                ;recalibration_coef = recalibration_coef, $
                                ;use_hybrid_opacity=use_hybrid_opacity,$
                                ;hybrid_opacity_after_reduction=hybrid_opacity_after_reduction, $
                                ;opacity_from_tau225 = opacity_from_tau225, $
                                            outlier_scan_list = outlier_scan_list, $
                                            nostop=nostop, $
                                ;calibration_per_array=calibration_per_array, $
                                            test_version_name=test_nickname, $
                                            output_allinfo_file = output_allinfo_file
     
     
     stop
     
  endfor
  
  wd, /a
  
  
end
