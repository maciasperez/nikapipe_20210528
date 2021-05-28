;;
;;   PERFORM THE BASELINE CALIBRATION OF THE CALIBRATION RUNS
;;
;;   copy of baseline_calibration: implement the final setup for the
;;   commissioning document
;;
;;   LP, August 2018
;;_______________________________________________________________


pro baseline_calibration_BL


  ;; DATASET
  ;;__________________________________________
  
;;  runname_tab = ['N2R9', 'N2R12', 'N2R14']
  runname_tab = ['N2R23']
  
  ;; ACTIONS
  ;;__________________________________________
  
  do_opacity_correction        = 0
  do_absolute_calibration      = 1 ; 1
  do_crosscheck_on_secondaries = 0

  
  ;; FOCAL PLANE GEOMETRY
  ;;__________________________________________
  n2r9_input_kidpar_file  = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'
  n2r12_input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'
  n2r14_input_kidpar_file = !nika.off_proc_dir+'/kidpar_20180122s309_v2_HA_skd16_calUranus17.fits'
  n2r23_input_kidpar_file = '/home/ladjelate/NIKA/Plots/N2R24/kidpar_20181104s57_v2.fits'



 ; kidpar_file_tab = [n2r9_input_kidpar_file, $
 ;                    n2r12_input_kidpar_file, $
 ;                    n2r14_input_kidpar_file]
  kidpar_file_tab = [n2r23_input_kidpar_file]

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
  ;;test_nickname = '_v2'
  ;;test_nickname = '_TaufitMethod'
  test_nickname = ''
  nostop = 1

 



;;_______________________________________________________________________________________________
;;_______________________________________________________________________________________________
  
  nrun = n_elements(runname_tab)
  for irun = 0, nrun-1 do begin
     
     runname = runname_tab[irun]
     input_kidpar_file = kidpar_file_tab[irun]

     output_dir = getenv('HOME')+'/NIKA/Plots/'+runname
     if file_test(output_dir, /directory) gt 1 then spawn, "mkdir -p "+output_dir

     ;; test log file
     filesave_out = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_'+strupcase(runname)+'_v0.save' 
     filecsv_out  = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_'+strupcase(runname)+'_v0.csv'
     if file_test(filesave_out) lt 1 then begin
        runname2day, runname, day
                                ;stop
        myday = '2018110'
        print, myday
        print, "ls "+!nika.imb_fits_dir+'*'+myday+'*imb.fits'
        spawn, "ls "+!nika.imb_fits_dir+'*'+myday+'*imb.fits', flist
                                ;stop
        nk_log_iram_tel, flist, filesave_out, filecsv_out, nonika=1, notrim=1
     endif
     
;; 1/ OPACITY CORRECTION
;;_______________________________________________________________________________________________    
     
     if do_opacity_correction gt 0 then begin

        baseline = 0    ;; 1: no tau3 cut; 2:tau3<0.9; 3:tau3<0.8; 4: high-tau2-v3
        atmlike  = 0
        hightau2 = 0
        
        extrapol_from_tau225 = 0

        case strlowcase(opacity_selection_tab[irun]) of
           'baseline': baseline = 1    ;; 1: no tau3 cut; 2:tau3<0.9; 3:tau3<0.8; 4: high-tau2-v3
           'atmlike':  atmlike  = 1
           'hightau2': hightau2 = 1
           else: print, 'non recognised opacity selection for run ',runname 
        endcase
        
        if opacity_from_tau225 lt 1 then begin
           
;; first iteration without any scan selection
           do_first_iteration  = 0
           do_skydip_selection = 1 ; 0
           do_second_iteration = 1
           
           show_plot = 1
           check_after_selection  = 1 ;; launch again the selection code after the second iteration
           
           png=1
           
           reduce_skydips_reference, runname, input_kidpar_file, $
                                     hightau2=hightau2, atmlike=atmlike, $
                                     baseline=baseline, $
                                     showplot=show_plot, png=png, $
                                     do_first_iteration=do_first_iteration, $
                                     do_skydip_selection=do_skydip_selection, $
                                     do_second_iteration=do_second_iteration, $
                                     check_after_selection=check_after_selection, $
                                     reiterate=reiterate
           if nostop lt 1 then stop
        endif
        print, "HERE"
        stop
        
        ;; ELSE : opacity estimates using an extrapolation in NIKA2 bands
        ;; of the 225GHz-taumeter measures
     endif
     
     
;; 2/ ABSOLUTE CALIBRATION
;;_______________________________________________________________________________________________
     
     if do_absolute_calibration gt 0 then begin
        
        ;; copy param
        runname = runname_tab[irun]
        input_kidpar_file = kidpar_file_tab[irun]

        ;;output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'
        output_dir = '/home/ladjelate/NIKA/Plots/'+runname+'/Photometry'
        if file_test(output_dir, /directory) lt 1 then spawn, 'mkdir '+output_dir
        
        opa_version_name = '_ref' 
        case strlowcase(opacity_selection_tab[irun]) of
           'baseline': opa_version_name = opa_version_name+'_baseline'
           'atmlike':  opa_version_name = opa_version_name+'_atmlike'
           'hightau2': begin
              opa_version_name = opa_version_name+'_hightau2'
              if strlowcase(runname) eq 'n2r9' then opa_version_name  = opa_version_name+'_v3'
              if strlowcase(runname) eq 'n2r12' then opa_version_name = opa_version_name+'_v2'  
           end
           else: print, 'non recognised opacity selection for run ',runname 
        endcase

        
        showplot = 1
        png=1

        geom_kidpar_file   = input_kidpar_file
        skydip_kidpar_file = getenv('HOME')+'/NIKA/Plots/'+runname+'/Opacity/kidpar_C0C1_'+runname+opa_version_name+'.fits'
        input_kidpar_file  = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+opa_version_name+'.fits'
        if file_test(input_kidpar_file) lt 1 then skydip_coeffs, geom_kidpar_file, skydip_kidpar_file, input_kidpar_file
        print, "geom_kidpar_file: ",   geom_kidpar_file
        print, "skydip_kidpar_file: ", skydip_kidpar_file
        
        print, "input_kidpar_file: ",  input_kidpar_file

        if nostop lt 1 then begin
           rep = ''
           ;;read, rep
           print, 'on y va ?'
        endif
        
;; photometric correction
        
        var1_photocorr = 0
        var2_photocorr = 0
        fix_photocorr  = 0
        
        case strlowcase(photometric_correction) of
           'none': photocorr_suffixe=''
           'fwhm_pointing': begin
              fix_photocorr = [12.5, 18.5, 12.5]
              photocorr_suffixe = '_photocorr_fwhm_pointing'
              photocorr_using_pointing = 1
           end
           'modif_variable1': begin
              fix_photocorr = [12.5, 18.5, 12.5]
              delta_fwhm    = [0.4, 0.3, 0.4]
              photocorr_suffixe = '_photocorr_mod_var1'
           end
           else: print, 'non recognised photometric correction for run ', runname
        endcase
        

        ;; use hybrid opacity after the scans were reduced
        hybrid_opacity_after_reduction = 0
        if hybrid_opacity gt 0 then hybrid_opacity_after_reduction = 1
        

        ;; test log file
        filesave_out = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_'+strupcase(runname)+'_v0.save' 
        filecsv_out  = !nika.pipeline_dir+'/Datamanage/Logbook/Log_Iram_tel_'+strupcase(runname)+'_v0.csv'
        if file_test(filesave_out) lt 1 then begin
           runname2day, runname, day
           myday = strmid(day[0], 0, 7)
           spawn, "ls "+!nika.imb_fits_dir+"/*"+myday+"*imb.fits", flist
           nk_log_iram_tel, flist, filesave_out, filecsv_out, nonika=1, notrim=1
        endif

        
        calibration_uranus_reference, runname, input_kidpar_file, $
                                      output_dir=output_dir, showplot=showplot, png=png, $
                                      fix_photocorr=fix_photocorr, $
                                      var1_photocorr=var1_photocorr, $
                                      var2_photocorr=var2_photocorr, $
                                      photocorr_using_pointing=photocorr_using_pointing, $
                                      delta_fwhm=delta_fwhm, $
                                      photometric_correction_suffixe=photocorr_suffixe, $
                                      opa_version_name=opa_version_name,$
                                      hybrid_opacity_after_reduction=hybrid_opacity_after_reduction, $
                                      opacity_from_tau225 = opacity_from_tau225, $
                                      nostop = nostop, $
                                      calibration_per_array=calibration_per_array, $
                                      test_version_name=test_nickname
        
        
        if nostop lt 1 then stop
        wd, /a
        
     endif
     
     
     
;; 3./ CROSS_CHECK USING MWC349
;;_______________________________________________________________________________________________    
     if do_crosscheck_on_secondaries gt 0 then begin
        
;; parameter copy here
        runname = runname_tab[irun]
        
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
        print, "input_kidpar_file: "+input_kidpar_file

        message, /info, "fix me:"
        input_kidpar_file = '/home/ponthieu/NIKA/Plots/N2R9/Photometry/Uranus_photometry_N2R9_ref_baseline_TaufitMethod/kidpar_calib_N2R9_ref_baseline_TaufitMethod_calpera.fits'
        stop
        
        png=1
        
        
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
        input_calib_file = output_dir+'/Absolute_calibration_'+runname+opa_version_name+test_nickname+cal_suf+'.save'
        print, 'reading input_abscalib_file = ', input_calib_file
        restore,input_calib_file
        input_calib = correction_coef
        
        ;; calibration coefficient for the tested photometric correction  
        test_calib_file = output_dir+'/Absolute_calibration_'+runname+opa_version_name+test_nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
        print, 'reading test_abscalib_file = ', test_calib_file
        restore, test_calib_file
        test_calib  = correction_coef
        
        recalibration_coef = test_calib/input_calib

        recal_coef_file = output_dir+'/Calibration_coefficients_'+runname+opa_version_name+test_nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
        save,  recalibration_coef, filename=recal_coef_file

        
        ;; hybrid opacity
        ;;-----------------------------
        use_hybrid_opacity = 0
        hybrid_opacity_after_reduction = 0
        if hybrid_opacity gt 0 then hybrid_opacity_after_reduction = 1
        
        ;; SCAN LIST
        outlier_scan_list = ['20180122s98', $
                             '20180122s118', '20180122s119', '20180122s120', '20180122s121'] ;; the telescope has been heated


        extra_scan_list = 0
        ;case runname of
        ;   'N2R9': extra_scan_list   = ['20170224s111', '20170224s86', '20170226s124', '20170226s147']
        ;   'N2R12': extra_scan_list = 0
        ;   'N2R14': extra_scan_list = 0
        ;endcase

        
        validate_calibration_reference, runname, input_kidpar_file,$
                                        output_dir=output_dir, showplot=showplot, png=png, $
                                        fix_photocorr=fix_photocorr, $
                                        var1_photocorr=var1_photocorr, $
                                        var2_photocorr=var2_photocorr, $
                                        photocorr_using_pointing=photocorr_using_pointing, $
                                        delta_fwhm=delta_fwhm, $
                                        photometric_correction_suffixe=photocorr_suffixe, $
                                        opa_version_name=opa_version_name, $
                                        recalibration_coef = recalibration_coef, $
                                        use_hybrid_opacity=use_hybrid_opacity,$
                                        hybrid_opacity_after_reduction=hybrid_opacity_after_reduction, $
                                        opacity_from_tau225 = opacity_from_tau225, $
                                        outlier_scan_list = outlier_scan_list, $
                                        extra_scan_list  = extra_scan_list, $
                                        nostop=nostop, $
                                        calibration_per_array=calibration_per_array, $
                                        test_version_name=test_nickname
        
     endif
     
     
  endfor
  
  wd, /a
  
  
  
;; summary table
;;________________________________________________________
  case strlowcase(photometric_correction) of
     
     'fwhm_pointing': begin
        fix_photocorr = [12.5, 18.5, 12.5]
        photocorr_suffixe = '_photocorr_fwhm_pointing'
        photocorr_using_pointing = 1
     end
     'none': photocorr_suffixe=''
     'modif_variable1': begin
        fix_photocorr = [12.5, 18.5, 12.5]
        delta_fwhm    = [0.4, 0.3, 0.4]
        photocorr_suffixe = '_photocorr_mod_var1'
     end
     else: print, 'non recognised photometric correction for run ', runname
  endcase
  
  opa_suf = ''
  if hybrid_opacity gt 0 then opa_suf = '_hybrid_v0' 
  if opacity_from_tau225 gt 0 then opa_suf = '_use_tau225_v0'

  cal_suf = ''
  if calibration_per_array gt 0 then cal_suf = '_calpera'
  
  print,"----------------------------------------------------------------------------------------"
  print," summary table "
  print,"______________________________________________________________________________"
  print, ''
  print, '|  run  |  skydip    |  photo |       Uranus              |             MWC349         | '
  print, '|       |  selection |  corr  |                           |                            | '
  print, '|       |            |        | nscan | A1  |  A3  |  A2  | nscan |  A1  |  A3  |  A2  | ' 
  print,"______________________________________________________________________________"
  print, ''
  
  for i=0, nrun-1 do begin
     runname = strupcase(runname_tab[i])
     output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry'
     nickname = runname+'_ref_'+opacity_selection_tab[i]+test_nickname
     acal_file = output_dir+"/Absolute_calibration_"+nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
     restore, acal_file
     uranus_error = relative_error
     uranus_nscan = nscans
     uranus_nscan_tot = nscan_total
     corr_file = output_dir+"/Crosscheck_calibration_"+nickname+photocorr_suffixe+cal_suf+opa_suf+'.save'
     restore, corr_file
     mwc349_error = relative_error
     mwc349_nscan = nscans
     mwc349_nscan_tot = nscan_total

     print, 'Run : ',  runname
     print, "reading : ",acal_file
     print, "reading : ",corr_file
     
     print,'| ',runname_tab[i], ' | ', opacity_selection_tab[i], ' | ', photocorr_suffixe, ' | ', $
           strtrim(string(uranus_nscan),2),'/', strtrim(string(uranus_nscan_tot),2),' | ', $
           string(correction_coef[0], format='(f8.2)'),' | ',$
           string(correction_coef[2], format='(f8.2)'),' | ',$
           string(correction_coef[1], format='(f8.2)'),' | ', $
           strtrim(string( mwc349_nscan),2),'/', strtrim(string( mwc349_nscan_tot),2),' | ', $
           string(flux_ratio_to_expect[0], format='(f8.2)'),' | ',$
           string(flux_ratio_to_expect[2], format='(f8.2)'),' | ',$
           string(flux_ratio_to_expect[1], format='(f8.2)'),' | '
     print,'|       |            |        |      | ',$
           string(uranus_error[0], format='(f8.2)'),' | ',$
           string(uranus_error[2], format='(f8.2)'),' | ',$
           string(uranus_error[1], format='(f8.2)'),' | ',$
           '|      |', $
           string(mwc349_error[0], format='(f8.2)'),' | ',$
           string(mwc349_error[2], format='(f8.2)'),' | ',$
           string(mwc349_error[1], format='(f8.2)'),' | '   
     print,"----------------------------------------------------------------------------------------"
  endfor
  
  stop
  
end
