pro compare_calibration_methods_scr

  ;; data
  ;;---------------------------------------------
  ;;calib_run   = ['N2R9', 'N2R12', 'N2R14']
  ;;nrun  = n_elements(calib_run)
  
  ;; Opacity correction
  ;;---------------------------------------------
  nopa = 2
  ;; opacorr_method = 1 -> skydip
  ;; opacorr_method = 2 -> corrected_skydip
  ;; opacorr_method = 3 -> taumeter

  ;; Photometric correction
  ;;---------------------------------------------
  nphoto = 1
  ;; photocorr_method = 1 -> none
  ;; photocorr_method = 2 -> demo
  ;; photocorr_method = 3 -> pointing


  do_uranus    = 0
  do_mwc349    = 0
  do_allbright = 0
  do_nefd      = 1

  nostop   = 0
  savefile = 0

  png = 0
  ps  = 0
  pdf = 0
  
  ;;for iopa = 1, nopa do begin
  ;; launch only for corrected skydip = baseline
  iopa = 2
  
  for iphoto = 1, nphoto do begin
  
        ;;
        if do_uranus then flux_density_ratio_primary_v2, png=png, ps=ps, pdf=pdf, $
           fwhm_stability=1, $
           obstau_stability=1, $
           opacorr_method = iopa, $
           photocorr_method = iphoto, $
           nostop = nostop, savefile = savefile
        
        ;; bias
        if do_mwc349 then flux_density_ratio_secondary_v2, png=png, ps=ps, pdf=pdf, $
           fwhm_stability=0, $
           obstau_stability=0, $
           mwc349_stability=1, $
           opacorr_method  = iopa, $
           photocorr_method = iphoto, $
           nostop = nostop, savefile = savefile

        ;; calibration rms 
        if do_allbright then flux_density_ratio_all_v2, png=png, ps=ps, pdf=pdf, $
           obsdate_stability=1, $
           fwhm_stability=0, $
           obstau_stability=1, $
           opacorr_method = iopa, $
           photocorr_method = iphoto, $
           nostop = nostop, savefile = savefile
     endfor
     
  ;endfor
  
  if do_nefd then begin
     
     ;for iopa = 1, nopa do begin
     iopa = 2
     
        iphoto = 1
        nefd_vs_observed_opacity_v2, png=png, ps=ps, pdf=pdf, $
                                     opacorr_method = iopa, $
                                     photocorr_method = iphoto, $
                                     nostop = nostop, savefile = savefile
        iphoto = 3
        nefd_vs_observed_opacity_v2, png=png, ps=ps, pdf=pdf, $
                                     opacorr_method = iopa, $
                                     photocorr_method = iphoto, $
                                     nostop = nostop, savefile = savefile
     ;;endfor
  endif

end

