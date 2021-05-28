;;
;;   CALCULATE RECALIBRATION COEFFICIENTS
;;
;;   intended to convert Juan's results to baseline,
;;   photocorr_demo and photocorr_pointings results
;;
;;   LP, July 2018
;;_______________________________________________________________


pro get_recalibration_coefficients, jfmp=jfmp, lp=lp

  ;; JFMP
  ;; ATTENTION: JUAN's FILES OBTAINED USING PARAM.DO_TEL_GAIN = 0
  ;; WHEREAS KIDPARS CALIBRATED USING PARAM.DO_TEL_GAIN = 2
  ;; all data are supposed to have been reduced using:
  ;; kidpar_calib_<RUNID>_ref_baseline_photocorr_var1_hybrid_v0.fits
  ;; which is also copied in
  ;; !nika.off_proc_dir+'/kidpar_<RUNID>_baseline.fits’
  
  ;; LP
  ;; all data are supposed to have been reduced using:
  ;; kidpar_calib_<RUNID>_ref_<opaname>_calpera_hybrid_v0.fits
  ;; which is also copied in
  ;; !nika.off_proc_dir+'/kidpar_<RUNID>_baseline_v1.fits’


  letsgo = 0
  if keyword_set(jfmp) then letsgo=1
  if keyword_set(lp) then letsgo=1

  if letsgo gt 0 then begin
  
     datamanage_dir = !nika.soft_dir+'/Labtools/LP/datamanage'
     
     runname_tab = ['N2R9', 'N2R12', 'N2R14']
     
     opacity_selection_tab = ['baseline', 'atmlike', 'atmlike']
     
     ;;photometric_correction    = 'variable1'
     ;;photometric_correction  = 'variable2'
     ;;photometric_correction  = 'nico'
     ;;photometric_correction  = 'fwhm_pointing'
     ;;photometric_correction    = 'none'
     photometric_correction    = 'modif_variable1'
     
;; FWHM stable values for 'fix' photometric correction
;; accounting for the apparent size of Uranus
     fwhm_base = [11.2, 17.4, 11.2]
     angdiam   = 4.0            ; 3.3 - 4.1
     fwhm_disc = sqrt(fwhm_base^2 + alog(2.0d0)/2.0d0*angdiam^2 )
     fwhm_stable = fwhm_disc 
     
     ;;delta_fwhm = [0.7, 0.4, 0.7]
     ;;photometric_correction  = 'step'
     
     ;; Absolute calibration per array
     calibration_per_array = 1
     
     
     hybrid_opacity        = 1
     opacity_from_tau225   = 0
     filename = !nika.pipeline_dir+'/Datamanage/Tau225/modified_ATM_tau225_ratios.save'
     ;;modified_atm_tau225_ratio = [0.55, 0.4, 0.5]
     modified_atm_tau225_ratio = [0.0, 0.2, 0.0]
     ;;save,modified_atm_tau225_ratio, filename=filename
     
     
     n2r9_input_kidpar_file  = !nika.off_proc_dir+'/kidpar_best3files_FXDC0C1_GaussPhot_NewConv.fits'
     n2r12_input_kidpar_file = !nika.off_proc_dir+'/kidpar_20171025s41_v2_LP_md_recal.fits'
     n2r14_input_kidpar_file = !nika.off_proc_dir+'/kidpar_20180122s309_v2_HA_skd16_calUranus17.fits'
     
     kidpar_file_tab = [n2r9_input_kidpar_file, $
                        n2r12_input_kidpar_file, $
                        n2r14_input_kidpar_file]
     
     
     ;; reference calibration
     ;;  version_name = '_ref'+ opa_version_name
     test_nickname = ''
     
     ;; test using modified FWHM_nominal
     ;; version_name = '_ref'+ opa_version_name + test_nickname
     ;;test by editing fill_nika_struct.pro
     ;; minus !nika.fwhm_nom = [12.5, 18.5] --> !nika.fwhm_nom = [11.5, 17.5]
     ;;
     ;; light !nika.fwhm_nom = [12.5, 18.5] --> !nika.fwhm_nom = [12.0, 18.0]
     ;; plus  !nika.fwhm_nom = [12.5, 18.5] --> !nika.fwhm_nom = [13.0, 19.0]
     ;;test_nickname = '_fwhm_fix_minus'
     
     ;; test using larger decorrelation mask dmin=60 --> 40
     ;;test_nickname = '_dmin_40'
     ;;test_nickname = '_dmin_80'
     
     nostop = 1
     
     
;;_______________________________________________________________________________________________
;;_______________________________________________________________________________________________
     
     nrun = n_elements(runname_tab)
     for irun = 0, nrun-1 do begin
        
        runname = runname_tab[irun]
        
        print, ''
        print, '--------------------------------------'
        print, '   ', strupcase(runname)
        print, '--------------------------------------'
        
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
        
        ;; absolute calibration using 'variable 1' photometric correction
        ;; and without using the hybrid opacity correction
        ;; to be rescaled afterwards
        ;; (easiest for testing sevral photmetric corrections)
        ;;input_kidpar_file =
        ;;getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/kidpar_calib_'+runname+version_name+photocorr_name+'.fits'
        
        version_name = opa_version_name+test_nickname
        
        if keyword_set(jfmp) then begin
           uranus_opa_suf = ''
           if strlowcase(runname) eq 'n2r9' then uranus_opa_suf = '_hybrid_v0'
           if test_nickname gt '' then  uranus_opa_suf = '_hybrid_v0'
           input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+$
                                '/Photometry/Uranus_photometry_'+runname+version_name+'/'+$
                                'kidpar_calib_'+runname+opa_version_name+'_photocorr_var1'+uranus_opa_suf+'.fits'
           
        endif
        
        if keyword_set(LP) then begin
           uranus_opa_suf = '_hybrid_v0'
           input_kidpar_file =  getenv('HOME')+'/NIKA/Plots/'+runname+$
                                '/Photometry/Uranus_photometry_'+runname+version_name+'/'+$
                                'kidpar_calib_'+runname+opa_version_name+'_calpera'+uranus_opa_suf+'.fits'
        endif
        print, 'ALL SCANS ARE ASSUMED TO BE REDUCED USING: ',input_kidpar_file
        
        
;; photometric correction
;;-----------------------------
        var2_photocorr = 0
        fix_photocorr  = 0
        var1_photocorr = 0
        
        case strlowcase(photometric_correction) of
           'variable1': begin
              var1_photocorr = 1
              photocorr_suffixe = '_photocorr_var1'
           end
           'variable2': begin
              var2_photocorr  = 1
              photocorr_suffixe = '_photocorr_var2'
           end
           'fix':  begin
              fix_photocorr = 1
              photocorr_suffixe = '_photocorr_fix'
           end
           'step': begin
              fix_photocorr = fwhm_base
              photocorr_suffixe = '_photocorr_step'
           end
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
        
        if keyword_set(jfmp) then begin
           ori_suf = '_ori'
           if test_nickname ne '' then ori_suf = ''
           
           ;; calibration coefficients of the input kidpar
           input_calib_file = output_dir+'/Absolute_calibration_'+runname+version_name+'_photocorr_var1'+ori_suf+uranus_opa_suf+'.save'
           print, 'reading input_abscalib_file = ', input_calib_file
           restore,input_calib_file
           input_calib = correction_coef
        endif
        
        if keyword_set(lp) then begin
           ;; calibration coefficients of the input kidpar
           input_calib_file = output_dir+'/Absolute_calibration_'+runname+version_name+'_calpera'+uranus_opa_suf+'.save'
           print, 'reading input_abscalib_file = ', input_calib_file
           restore,input_calib_file
           input_calib = correction_coef
        endif
        
        print, ''
        print, 'restoring input calibration coefficients = ',input_calib_file 
        
        ;; calibration coefficient for the tested photometric correction
        cal_suf = ''
        if calibration_per_array gt 0 then cal_suf = '_calpera'
        test_calib_file = output_dir+'/Absolute_calibration_'+runname+version_name+photocorr_suffixe+cal_suf+opa_suf+'.save'
        print, ''
        print, 'restoring test calibration coefficients = ', test_calib_file
        restore, test_calib_file
        test_calib  = correction_coef
        
        recalibration_coef = test_calib/input_calib
        
        recal_coef_file = output_dir+'/Calibration_coefficients_'+runname+version_name+photocorr_suffixe+cal_suf+opa_suf+'.save'
        print, ''
        print, 'SAVING RECALIBRATION COEFFS IN ', recal_coef_file
        save,  recalibration_coef, filename=recal_coef_file
        
        if keyword_set(jfmp) then begin
           datamanage_file = datamanage_dir+'/Calibration_coefficients_'+runname+'_JFMP_to_'+opacity_selection_tab[irun]+photocorr_suffixe+'.save'
        endif else if keyword_set(lp) then begin
           datamanage_file = datamanage_dir+'/Calibration_coefficients_'+runname+'_LP_to_'+opacity_selection_tab[irun]+photocorr_suffixe+'.save'
        endif
        
        cmd = 'cp '+recal_coef_file+' '+datamanage_file
        
        print, cmd
        rep=''
        print, 'ok ?'
        read, rep
        
        spawn, cmd
        
     endfor
     
  endif else print, "please select jfmp for juan's result file recalibration or lp for lp's result files"
  stop
  wd, /a
  
end
