pro flux_density_ratio_primary_v2, png=png, ps=ps, pdf=pdf, $
                                   fwhm_stability=fwhm_stability, $
                                   obstau_stability=obstau_stability, $
                                   opacorr_method=opacorr_method, $
                                   photocorr_method = photocorr_method, $
                                   nostop = nostop, savefile = savefile
  
  
  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)

  sources = ['Uranus']
  nsource = 1

  ;; Correction of the beam-widening effect due to Uranus disc
  cu = [1.016, 1.007]
  cu = [0.9855, 0.9936 ]
  
  ;; Opacity correction
  ;;---------------------------------------------
  skydip               = 0
  corrected_skydip     = 1
  taumeter             = 0
  
  ;; Photometric correction
  ;;---------------------------------------------
  do_photocorr         = 1
  photocorr_demo       = 0
  photocorr_point      = 1
  photocorr_thres_1mm  = 1.25; 1.08  ;1.06  ;; si 20% d'erreur sur photocorr -> 1.6% d'erreur sur flux
  photocorr_thres_2mm  = 1.15; 1.06  ;1.04  ;; si 20% d'erreur sur photocorr -> 1.2% d'erreur sur flux

  obstau_stability = 1
  
  ;; outplot directory
  dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/'

  if keyword_set(nostop) then nostop=1 else nostop=0
  if keyword_set(savefile) then savefile = 1 else savefile = 0
  
  ;; use keywords
  ;;________________________________________________________
  if keyword_set(opacorr_method) then begin
     skydip               = 0
     corrected_skydip     = 0
     taumeter             = 0
     case opacorr_method of
        1: skydip           = 1
        2: corrected_skydip = 1
        3: taumeter         = 1
     endcase
  endif
  if keyword_set(photocorr_method) then begin
     do_photocorr         = 1
     photocorr_demo       = 0
     photocorr_point      = 0
     case photocorr_method of
        1: do_photocorr     = 0
        2: photocorr_demo   = 1
        3: photocorr_point  = 1
     endcase
  endif

  
  ;; Automatic plot suffixe
  ;;--------------------------------------------------------------
  if skydip gt 0 then $
     plot_suffixe = '_skydip' else if corrected_skydip gt 0 then $
        plot_suffixe = '_corrected_skydip' else if taumeter gt 0 then $
           plot_suffixe = '_tau225' else print, 'UNKNOWN OPACITY CORRECTION METHOD'
  if do_photocorr gt 0 then begin
     if photocorr_demo gt 0 then plot_suffixe=plot_suffixe+'_photocorr_demo' else $
        if photocorr_point gt 0 then plot_suffixe=plot_suffixe+'_photocorr_pointing' $
        else print, 'UNKNOWN PHOTOMETRIC CORRECTION METHOD'
  endif

  ;;plot_suffixe = plot_suffixe+'_more_scans'
  plot_suffixe = plot_suffixe+'_narrow'

  ;; plot aspect
  ;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 550.
  wysize = 400.
  ;; plot size in files
  pxsize = 11.
  pysize =  8.
  ;; charsize
  charsize  = 1.2
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0
  if keyword_set(ps) then mythick   = 3.0 else mythick = 1.0
  mysymsize   = 0.8
  
  ;;________________________________________________________________
  ;;
  ;; get all result files
  ;;________________________________________________________________
  ;;________________________________________________________________
  outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
  get_all_scan_result_files_v2, result_files, outputdir = outdir
  

  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
  
  flux_1mm     = 0.
  flux_a2      = 0.
  flux_a1      = 0.
  flux_a3      = 0.
  err_flux_1mm = 0.
  err_flux_a2  = 0.
  err_flux_a1  = 0.
  err_flux_a3  = 0.
  tau_1mm      = 0.0d0
  tau_a2       = 0.0d0
  tau_a1       = 0.0d0
  tau_a3       = 0.0d0
  fwhm_1mm     = 0.
  fwhm_a2      = 0.
  fwhm_a1      = 0.
  fwhm_a3      = 0.
  elev         = 0.
  obj          = ''
  day          = ''
  runid        = ''
  index_select = -1
  ut           = ''
  ut_float     = 0.
  scan_list    = ''
  th_flux_1mm  = 0.0d0
  th_flux_a2   = 0.0d0
  th_flux_a1   = 0.0d0
  th_flux_a3   = 0.0d0
  photocorr_flag = 0
  photocorr_factor = 1.

  ntot_tab    = lonarr(nrun+1)
  nselect_tab = lonarr(nrun+1)

  cal_factors = dblarr(4, nrun+1)
  rms_tab     = dblarr(4, nrun+1)
  
  cal_factor_1mm = 1.0d0
  cal_factor_a1 = 1.0d0
  cal_factor_a2 = 1.0d0
  cal_factor_a3 = 1.0d0
  
  for irun = 1, nrun-1 do begin
          
     print,''
     print,'------------------------------------------'
     print,'   ', strupcase(calib_run[irun])
     print,'------------------------------------------'
     print,'READING RESULT FILE: '
     allresult_file = result_files[irun] 
     print, allresult_file
     
     ;;
     ;;  restore result tables
     ;;____________________________________________________________
     restore, allresult_file, /v
     ;; allscan_info

     ;; select scans for the source
     ;;____________________________________________________________
     wsource = -1
     for isou = 0, nsource-1 do begin
        wtokeep = where( strupcase(allscan_info.object) eq strupcase(sources[isou]), nkeep)
        if nkeep gt 0 then wsource = [wsource, wtokeep]
     endfor
     if n_elements(wsource) gt 1 then wsource = wsource[1:*] else begin
        print, 'no scan for the sources'
        stop
     endelse
     print, 'nb of found scan of the sources = ', n_elements(wsource)
     allscan_info = allscan_info[wsource]

     stop

     ;; remove known outliers
     ;;____________________________________________________________
     ;;scan_list_ori = strtrim(string(allscan_info.day, format='(i8)'), 2)+"s"+$
     ;;                strtrim( string(allscan_info.scan_num, format='(i8)'),2)
     scan_list_ori = allscan_info.scan
     
     outlier_list =  [$
                     '20170223s16', $  ; dark test
                     '20170223s17', $  ; dark test
                     '20171024s171', $ ; focus scan
                     '20171026s235', $ ; focus scan
                     '20171028s313', $ ; RAS from tapas
                     '20180114s73', $  ; TBC
                     '20180116s94', $  ; focus scan
                     '20180118s212', $ ; focus scan
                     '20180119s241', $ ; Tapas comment: 'out of focus'
                     '20180119s242', $ ; Tapas comment: 'out of focus'
                     '20180119s243' $  ; Tapas comment: 'out of focus'                  
                     ]
     out_index = 1
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
     allscan_info = allscan_info[out_index]
     nscans = n_elements(allscan_info)
     
     print, "scan list: "
     help, scan_list_run

     ntot_tab[irun] = nscans
     
     if nostop lt 1 then stop     

     

     ;;
     ;; FLUX DENSITY EXPECTATIONS
     ;;____________________________________________________________
     th_flux_1mm_run = dblarr(nscans)
     th_flux_a2_run  = dblarr(nscans)
     th_flux_a1_run  = dblarr(nscans)
     th_flux_a3_run  = dblarr(nscans)
     
     for i=0, nscans-1 do begin
        nk_scan2run, scan_list_run[i], run
        th_flux_1mm_run[i]     = !nika.flux_uranus[0]
        th_flux_a2_run[i]      = !nika.flux_uranus[1]
        th_flux_a1_run[i]      = !nika.flux_uranus[0]
        th_flux_a3_run[i]      = !nika.flux_uranus[0]
     endfor
     
;;
     ;; OPACITY CORRECTION
     ;;____________________________________________________________

     ;; 1/ getting tau_NIKA
     ;;tau_nika = dblarr(nscans, 4)
     if skydip gt 0 then begin
        tau_nika = [[allscan_info.result_tau_1], [allscan_info.result_tau_2], $
                    [allscan_info.result_tau_3], [allscan_info.result_tau_1mm]]
     endif
     
     if corrected_skydip gt 0 then begin
        tau_skydip = [[allscan_info.result_tau_1], [allscan_info.result_tau_2], $
                      [allscan_info.result_tau_3], [allscan_info.result_tau_1mm]]
        get_corrected_tau_skydip, tau_skydip, tau_nika
     endif
     
     if taumeter gt 0 then begin
        get_tau_nika_from_tau225, calib_run[irun], allscan_info.scan, tau_nika, flux_driven=1, skydip_driven=0
     endif

     ;; 2/ implementing opacity correction
     sinel = sin(allscan_info.result_elevation_deg*!dtor)
     allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*exp((tau_nika[*,3]-allscan_info.result_tau_1mm)/sinel)
     allscan_info.result_flux_i1 = allscan_info.result_flux_i1*exp((tau_nika[*,0]-allscan_info.result_tau_1)/sinel)
     allscan_info.result_flux_i2 = allscan_info.result_flux_i2*exp((tau_nika[*,1]-allscan_info.result_tau_2)/sinel)
     allscan_info.result_flux_i3 = allscan_info.result_flux_i3*exp((tau_nika[*,2]-allscan_info.result_tau_3)/sinel) 

    
     ;;
     ;; photometric correction 
     ;;____________________________________________________________
     if do_photocorr gt 0 then begin

        ;; DEMO
        if photocorr_demo gt 0 then begin
           photocorr = 1
           ;; test 1 
           ;;fix_photocorr = [12.5, 18.5, 12.5]
           ;;delta_fwhm    = [0.4, 0.3, 0.4]
           
           ;; test 2
           ;;delta_fwhm    = [0.4, 0.3, 0.4]
           ;;delta_stable  = [0.5, 0.3, 0.5]
           ;fix_photocorr = [11.2, 17.4, 11.2]

           ;; test 3
           fix_photocorr   = 0
           variable        = 0
           weakly_variable = 1
           delta_fwhm      = [0.4, 0.25, 0.4];; [0.5, 0.3, 0.5]
           delta_stable    = 0
           
           photocorr_using_pointing = 0
        endif

        ;; POINTING-BASED
        if photocorr_point gt 0 then begin
           photocorr = 1
           ;; test 1
           ;;fix_photocorr = [12.5, 18.5, 12.5]
           ;;delta_stable  = [0., 0., 0.]
           ;; test 2
           ;;delta_fwhm    = 0
           ;;fix_photocorr = [11.2, 17.4, 11.2]
           ;;delta_stable  = [0.5, 0.3, 0.5]
           ;; test 3
           fix_photocorr   = 0
           variable        = 0
           weakly_variable = 1
           delta_fwhm      = 0
           delta_stable    = [0., 0., 0.]
           ;;
           photocorr_using_pointing = 1
        endif

        ;;
        ;; first scan selection
        ;;____________________________________________________________ 
        ;; 1/ allscan selection for photocorr
        to_use_photocorr = 1
        complement_index = 0
        beamok_index     = 0
        largebeam_index  = 0
        tauok_index      = 0
        hightau_index    = 0
        obsdateok_index  = 0
        afternoon_index  = 0
        fwhm_max         = 0
        nefd_index       = 0
        baseline_scan_selection, allscan_info, wtokeep, $
                        to_use_photocorr=to_use_photocorr, complement_index=wout, $
                        beamok_index = beamok_index, largebeam_index = wlargebeam,$
                        tauok_index = tauok_index, hightau_index=whitau3, $
                        osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                        fwhm_max = fwhm_max, nefd_index = nefd_index
        
        nscans_phot   = n_elements(wtokeep)
                
        fwhm = fltarr(nscans_phot, 4)
        flux = fltarr(nscans_phot, 4)
        for ii=0, nscans_phot-1 do begin
           i = wtokeep[ii]
           fwhm[ii, 0] = allscan_info[i].result_fwhm_1
           fwhm[ii, 1] = allscan_info[i].result_fwhm_2
           fwhm[ii, 2] = allscan_info[i].result_fwhm_3
           fwhm[ii, 3] = allscan_info[i].result_fwhm_1mm
           flux[ii, 0] = allscan_info[i].result_flux_i1
           flux[ii, 1] = allscan_info[i].result_flux_i2
           flux[ii, 2] = allscan_info[i].result_flux_i3
           flux[ii, 3] = allscan_info[i].result_flux_i_1mm
        endfor    
        tfwhm = transpose(fwhm)
        
        if photocorr_point gt 0 then begin
           day_run = allscan_info[wtokeep].day
           ut_otf = fltarr(nscans_phot)
           ut_run = strmid(allscan_info[wtokeep].ut, 0, 5)
           for i = 0, nscans_phot-1 do begin
              ut_otf[i]  = float((STRSPLIT(ut_run[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_run[i], ':', /EXTRACT))[1])/60.
           endfor
           get_pointing_based_beams, fwhm_point, day_run, ut_otf, calib_run[irun]
           tfwhm = transpose(fwhm_point)
        endif
        
        tflux = transpose(flux)

        ;; implementing photometric correction
        ;;--------------------------------------------------------------------------
        corr_flux_factor = dblarr(4, nscans_phot)
        ;; delta_sidelobe needed for Uranus scans only (using 'demo')
        wu = where(strupcase(allscan_info[wtokeep].object) eq 'URANUS', nu, compl=wo)
        fix = fix_photocorr+delta_stable ;; test 2
        fix = 0
        ;;
        photometric_correction, tflux[*, wu], tfwhm[*, wu], corr_flux_factor_uranus, $
                                fix=fix, weakly_variable=weakly_variable,$
                                variable=variable, delta_fwhm=delta_fwhm, add1mm=1
        corr_flux_factor[*, wu] = corr_flux_factor_uranus
        ;; delta_sidelobe = 0 for weaker sources (and using 'pointing')
        photometric_correction, tflux[*, wo], tfwhm[*, wo], corr_flux_factor_other, $
                                fix=fix_photocorr, weakly_variable=weakly_variable,$
                                variable=variable, delta_fwhm=0, add1mm=1
        corr_flux_factor[*, wo] = corr_flux_factor_other

        
        photocorr_flag_run = intarr(nscans) ;; all scans
        wphot=where(corr_flux_factor[0, *] gt photocorr_thres_1mm or $
                    corr_flux_factor[1, *] gt photocorr_thres_2mm or $
                    corr_flux_factor[2, *] gt photocorr_thres_1mm, $
                    nwphot, compl=wphotok)
        
        if nwphot gt 0 then begin
           print, 'high photo corr for scans ', allscan_info[wtokeep[wphot]].scan
           photocorr_flag_run[wtokeep[wphot]] = 1
        endif
        photocorr_flag = [photocorr_flag, photocorr_flag_run]
        
        raw_flux = flux
        for ia = 0, 3 do flux[*, ia] = flux[*, ia]*corr_flux_factor[ia,*]

        photocorr_factor_run = dblarr(nscans)
        photocorr_factor_run[wtokeep] = reform(corr_flux_factor[3,*])
        photocorr_factor = [photocorr_factor, photocorr_factor_run]
        
        for i=0, nscans_phot-1 do begin
           ii = wtokeep[i]
           allscan_info[ii].result_flux_i1    = flux[i, 0]
           allscan_info[ii].result_flux_i2    = flux[i, 1]
           allscan_info[ii].result_flux_i3    = flux[i, 2]
           allscan_info[ii].result_flux_i_1mm = flux[i, 3]
        endfor

        wselect = wtokeep[wphotok]
        index_select_run = intarr(nscans)
        index_select_run[wselect] = 1 
        index_select = [index_select, index_select_run]
        
        ;; test plot
        index = indgen(nscans_phot)
        plot, index, reform(corr_flux_factor[0, *]), yr=[0.85, 1.3], /ys, /nodata, $
              xtitle='scan index', ytitle= 'photometric correction factor', $
              xr=[-1, nscans_phot], /xs
        oplot, [0, nscans], [1, 1]
        oplot, index, reform(corr_flux_factor[0, *]), col=80, psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), symsize=mysymsize
        oplot, index, reform(corr_flux_factor[2, *]), col=50, psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), symsize=mysymsize
        oplot, index, reform(corr_flux_factor[1, *]), col=250, psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), symsize=mysymsize
        oplot, index[wphotok], reform(corr_flux_factor[0, wphotok]), col=80, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), symsize=mysymsize
        oplot, index[wphotok], reform(corr_flux_factor[2, wphotok]), col=50, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), symsize=mysymsize
        oplot, index[wphotok], reform(corr_flux_factor[1, wphotok]), col=250, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), symsize=mysymsize
        xyouts, index, replicate(0.87, nscans_phot), strmid(allscan_info[wtokeep].scan, 4, 10), $
                charsi=0.7, orient=90
        legendastro, ['A1', 'A3', 'A2'], textcol=[80, 50, 250], col=[80, 50, 250], $
                     box=0, psym=[8, 8, 8]
        
        if nostop lt 1 then stop
        
     endif
     ;; END PHOTOMETRIC CORRECTION
     ;;____________________________________________________________________________

     if do_photocorr lt 1 then begin
        ;;
        ;; second scan selection
        ;;____________________________________________________________ 
        ;; 2/ baseline selection
        to_use_photocorr = 0
        complement_index = 0
        beamok_index     = 0
        largebeam_index  = 0
        tauok_index      = 0
        hightau_index    = 0
        obsdateok_index  = 0
        afternoon_index  = 0
        fwhm_max         = 0
        nefd_index       = 0
        baseline_scan_selection, allscan_info, wbaseline, $
                        to_use_photocorr=to_use_photocorr, complement_index=wout, $
                        beamok_index = beamok_index, largebeam_index = wlargebeam,$
                        tauok_index = tauok_index, hightau_index=whitau3, $
                        osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                        fwhm_max = fwhm_max, nefd_index = nefd_index

        wselect = wbaseline
        mask = intarr(nscans)
        mask[wselect] = 1
        index_select = [index_select, mask]
        
        print, "baseline selection, nscans = "
        help, wselect
     endif
     
     ;;
     ;; ABSOLUTE CALIBRATION ON URANUS
     ;;____________________________________________________________
     ;; calib using the selection of Uranus scans
     wuranus = where(strupcase(allscan_info[wselect].object) eq 'URANUS', nuranus)

     nselect_tab[irun] = nuranus
     wu = wselect[wuranus]
          
     
     flux_ratio_1   = avg( th_flux_a1_run[wu]/allscan_info[wu].result_flux_i1)
     flux_ratio_2   = avg( th_flux_a2_run[wu]/allscan_info[wu].result_flux_i2)
     flux_ratio_3   = avg( th_flux_a3_run[wu]/allscan_info[wu].result_flux_i3)
     flux_ratio_1mm = avg( th_flux_1mm_run[wu]/allscan_info[wu].result_flux_i_1mm)
     
     correction_coef = [flux_ratio_1, flux_ratio_2, flux_ratio_3, flux_ratio_1mm]
     print,'======================================================'
     print,"Flux correction coefficient A1: "+strtrim(correction_coef[0],2)
     print,"Flux correction coefficient A3: "+strtrim(correction_coef[2],2)
     print,"Flux correction coefficient A1&A3: "+strtrim(correction_coef[3],2)
     print,"Flux correction coefficient A2: "+strtrim(correction_coef[1],2)
     print,'======================================================'
     

     recalibration_coef = correction_coef
     
     ;;------------------------------------------------------------------
     ;; NEFD
     allscan_info.result_nefd_i_1mm = allscan_info.result_nefd_i_1mm*recalibration_coef[3]
     allscan_info.result_nefd_i_2mm = allscan_info.result_nefd_i_2mm*recalibration_coef[1]
     allscan_info.result_nefd_i1    = allscan_info.result_nefd_i1*recalibration_coef[0]
     allscan_info.result_nefd_i2    = allscan_info.result_nefd_i2*recalibration_coef[1]
     allscan_info.result_nefd_i3    = allscan_info.result_nefd_i3*recalibration_coef[2]
     ;; FLUX
     allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*recalibration_coef[3]
     allscan_info.result_flux_i_2mm = allscan_info.result_flux_i_2mm*recalibration_coef[1]
     allscan_info.result_flux_i1    = allscan_info.result_flux_i1*recalibration_coef[0]
     allscan_info.result_flux_i2    = allscan_info.result_flux_i2*recalibration_coef[1]
     allscan_info.result_flux_i3    = allscan_info.result_flux_i3*recalibration_coef[2]
     ;; FLUX CENTER
     allscan_info.result_flux_center_i_1mm = allscan_info.result_flux_center_i_1mm*recalibration_coef[3]
     allscan_info.result_flux_center_i_2mm = allscan_info.result_flux_center_i_2mm*recalibration_coef[1]
     allscan_info.result_flux_center_i1    = allscan_info.result_flux_center_i1*recalibration_coef[0]
     allscan_info.result_flux_center_i2    = allscan_info.result_flux_center_i2*recalibration_coef[1]
     allscan_info.result_flux_center_i3    = allscan_info.result_flux_center_i3*recalibration_coef[2]
     ;; ERRFLUX
     allscan_info.result_err_flux_i_1mm = allscan_info.result_err_flux_i_1mm*recalibration_coef[3]
     allscan_info.result_err_flux_i_2mm = allscan_info.result_err_flux_i_2mm*recalibration_coef[1]
     allscan_info.result_err_flux_i1    = allscan_info.result_err_flux_i1*recalibration_coef[0]
     allscan_info.result_err_flux_i2    = allscan_info.result_err_flux_i2*recalibration_coef[1]
     allscan_info.result_err_flux_i3    = allscan_info.result_err_flux_i3*recalibration_coef[2]
     ;; ERRFLUX CENTER
     allscan_info.result_err_flux_center_i_1mm = allscan_info.result_err_flux_center_i_1mm*recalibration_coef[3]
     allscan_info.result_err_flux_center_i_2mm = allscan_info.result_err_flux_center_i_2mm*recalibration_coef[1]
     allscan_info.result_err_flux_center_i1    = allscan_info.result_err_flux_center_i1*recalibration_coef[0]
     allscan_info.result_err_flux_center_i2    = allscan_info.result_err_flux_center_i2*recalibration_coef[1]
     allscan_info.result_err_flux_center_i3    = allscan_info.result_err_flux_center_i3*recalibration_coef[2]


     cal_factors[*, irun] = recalibration_coef  

     
     ;;
     ;; add in tables
     ;;____________________________________________________________
     
     scan_list    = [scan_list, allscan_info.scan]
     
     flux_1mm     = [flux_1mm, allscan_info.result_flux_i_1mm]
     flux_a2      = [flux_a2, allscan_info.result_flux_i2]
     flux_a1      = [flux_a1, allscan_info.result_flux_i1]
     flux_a3      = [flux_a3, allscan_info.result_flux_i3]
     err_flux_1mm = [err_flux_1mm, allscan_info.result_err_flux_i_1mm]
     err_flux_a2  = [err_flux_a2, allscan_info.result_err_flux_i2]
     err_flux_a1  = [err_flux_a1, allscan_info.result_err_flux_i1]
     err_flux_a3  = [err_flux_a3, allscan_info.result_err_flux_i3]
     ;;
     fwhm_1mm     = [fwhm_1mm, allscan_info.result_fwhm_1mm]
     fwhm_a2      = [fwhm_a2, allscan_info.result_fwhm_2]
     fwhm_a1      = [fwhm_a1, allscan_info.result_fwhm_1]
     fwhm_a3      = [fwhm_a3, allscan_info.result_fwhm_3]
     ;;
     tau_1mm      = [tau_1mm, allscan_info.result_tau_1mm]
     tau_a2       = [tau_a2, allscan_info.result_tau_2mm]
     tau_a1       = [tau_a1, allscan_info.result_tau_1]
     tau_a3       = [tau_a3, allscan_info.result_tau_3]
     ;;
     elev         = [elev, allscan_info.result_elevation_deg*!dtor]
     obj          = [obj, allscan_info.object]
     day          = [day, allscan_info.day]
     runid        = [runid, replicate(calib_run[irun], n_elements(allscan_info.day))]
     ut           = [ut, strmid(allscan_info.ut, 0, 5)]
     ;;
     th_flux_1mm  = [th_flux_1mm, th_flux_1mm_run]
     th_flux_a2   = [th_flux_a2, th_flux_a2_run]
     th_flux_a1   = [th_flux_a1, th_flux_a1_run]
     th_flux_a3   = [th_flux_a3, th_flux_a3_run]
     ;;
     cal_factor_1mm = [cal_factor_1mm, replicate(cal_factors[3,irun], n_elements(allscan_info.day))]
     cal_factor_a1 = [cal_factor_a1, replicate(cal_factors[0,irun], n_elements(allscan_info.day))]
     cal_factor_a2 = [cal_factor_a2, replicate(cal_factors[1,irun], n_elements(allscan_info.day))]
     cal_factor_a3 = [cal_factor_a3, replicate(cal_factors[2,irun], n_elements(allscan_info.day))]
  endfor

  ;; discard the placeholder first element of each tables
  flux_1mm     = flux_1mm[1:*]
  flux_a2      = flux_a2[1:*]
  flux_a1      = flux_a1[1:*]
  flux_a3      = flux_a3[1:*]
  err_flux_1mm = err_flux_1mm[1:*]
  err_flux_a2  = err_flux_a2[1:*]
  err_flux_a1  = err_flux_a1[1:*]
  err_flux_a3  = err_flux_a3[1:*]
  ;;
  fwhm_1mm     = fwhm_1mm[1:*]
  fwhm_a2      = fwhm_a2[1:*]
  fwhm_a1      = fwhm_a1[1:*]
  fwhm_a3      = fwhm_a3[1:*]
  ;;
  tau_1mm      = tau_1mm[1:*]
  tau_a2       = tau_a2[1:*]
  tau_a1       = tau_a1[1:*]
  tau_a3       = tau_a3[1:*]
  ;;
  elev         = elev[1:*]
  obj          = obj[1:*]
  day          = day[1:*]
  runid        = runid[1:*]
  ut           = ut[1:*]
  index_select = index_select[1:*]
  if do_photocorr gt 0 and photocorr_point gt 0 then photocorr_flag = photocorr_flag[1:*]
  if do_photocorr gt 0 then photocorr_factor = photocorr_factor[1:*]
  
  scan_list    = scan_list[1:*]
  ;;
  th_flux_1mm  = th_flux_1mm[1:*]
  th_flux_a2   = th_flux_a2[1:*]
  th_flux_a1   = th_flux_a1[1:*]
  th_flux_a3   = th_flux_a3[1:*]
  ;;
  cal_factor_1mm  = cal_factor_1mm[1:*]
  cal_factor_a2   = cal_factor_a2[1:*]
  cal_factor_a1   = cal_factor_a1[1:*]
  cal_factor_a3   = cal_factor_a3[1:*]
  
  ;; calculate ut_float and get flux expectations
  nscans      = n_elements(day)
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor


  ;; rustine pour trouver 1 : NB, coefs de calibration estimes avec
  ;; flux theo moyen
  ;;for i=0, nscans-1 do begin
  ;;   nk_scan2run, scan_list[i], run
  ;;   fill_nika_struct, run
  ;;   
  ;;   th_flux_1mm[i]     = !nika.flux_uranus[0]
  ;;   th_flux_a2[i]      = !nika.flux_uranus[1]
  ;;   th_flux_a1[i]      = !nika.flux_uranus[0]
  ;;   th_flux_a3[i]      = !nika.flux_uranus[2]
  ;;   
  ;;endfor

  
  if nostop lt 1 then stop

  ;;________________________________________________________________
  ;;
  ;;
  ;;          PLOTS
  ;;
  ;;________________________________________________________________
  ;;________________________________________________________________

  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14

  ut_tab = ['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

  ut_col = [10, 35, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25, 15]
  
  nut = n_elements(ut_tab)-1

  w_select = where(index_select gt 0, n_baseline)
  
  planet_fwhm_max  = [13.0, 18.3, 13.0]
  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3
  
  ;;
  ;;
  ;; FLUX RATIO VS FWHM
  ;;_______________________________________________________________________
  if keyword_set(fwhm_stability) then begin
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_select])]   )
     xmax  = 13.5
     xmin  = 11.0
     
     ;;planet_fwhm_max  = [14.0, 18.5, 14.0]
     w_fwhm = where(fwhm_1mm le planet_fwhm_max[0] and $
                    fwhm_a1 le planet_fwhm_max[2] and $
                    fwhm_a3 le planet_fwhm_max[2] and $
                    fwhm_a2 le planet_fwhm_max[1], n_fwhm)
     if n_fwhm le 0 then stop
     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, fwhm_1mm , flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin, xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_1mm[w_fwhm[w]], flux_ratio_1mm[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_1mm[w_select[w]], flux_ratio_1mm[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[13.1, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red

     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0 
     outplot, /close
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_select])]   )
     xmax  = 13.5
     xmin  = 11.0
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, fwhm_a1 , flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a1[w_fwhm[w]], flux_ratio_a1[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a1[w_select[w]], flux_ratio_a1[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[13.1, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red

     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0 
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_select])]   )
     xmax  = 13.5
     xmin  = 11.0

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, fwhm_a3 , flux_ratio_a3, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a3[w_fwhm[w]], flux_ratio_a3[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a3[w_select[w]], flux_ratio_a3[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[13.1, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red

     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0 

     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_select])]   )
     xmax  = 18.5
     xmin  = 17.4
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, fwhm_a2 , flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a2[w_fwhm[w]], flux_ratio_a2[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a2[w_select[w]], flux_ratio_a2[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[18.35, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[1]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[1], [ymin, ymax], col=170 ;; red

     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0
     
     outplot, /close
     
     
     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epspdf --bbox '+dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+suf[i]+'.eps'
           ;;spawn, 'epstopdf '+dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif


     
     if nostop lt 1 then stop

  endif




  ;;
  ;;   FLUX RATIO AGAINST ATMOSPHERIC TRANSMISSION
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     col_tab = [col_n2r9, col_n2r12, col_n2r14]
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_select])]   )
     xmax  = 0.95
     xmin  = 0.45     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_uranus'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     for irun=0, nrun-1 do begin
        w = where(runid[w_select] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_1mm[w_select[w]]/sin(elev[w_select[w]])), flux_ratio_1mm[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
        if nn gt 1 then rms_tab[3, irun] = stddev(flux_ratio_1mm[w_select[w]])/mean(flux_ratio_1mm[w_select[w]])*100.0d0
        print, 'nscan   = ', nn, nselect_tab[irun]
        print, 'factor  = ', cal_factors[3, irun]
        print, 'rel.rms = ', rms_tab[3, irun]
     endfor
  
     ;;
     legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=mythick)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[xmin+(xmax-xmin)*0.05, 1.17], symsize= 0.9*[1., 1., 1.]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_select])]   )
     xmax  = 0.95
     xmin  = 0.45
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_uranus'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        w = where(runid[w_select] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_a1[w_select[w]]/sin(elev[w_select[w]])), flux_ratio_a1[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
        if nn gt 1 then rms_tab[0, irun] = stddev(flux_ratio_a1[w_select[w]])/mean(flux_ratio_a1[w_select[w]])*100.0d0
        print, 'nscan   = ', nn, nselect_tab[irun]
        print, 'factor  = ', cal_factors[0, irun]
        print, 'rel.rms = ', rms_tab[0, irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+(xmax-xmin)*0.05, 1.17], psym=cgsymcat('FILLEDCIRCLE', thick=mythick)*[1., 1., 1.], symsize = 0.9*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_select])]   )
     xmax  = 0.95
     xmin  = 0.45

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_uranus'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        w = where(runid[w_select] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_a3[w_select[w]]/sin(elev[w_select[w]])), flux_ratio_a3[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
        if nn gt 1 then rms_tab[2, irun] = stddev(flux_ratio_a3[w_select[w]])/mean(flux_ratio_a3[w_select[w]])*100.0d0
        print, 'nscan   = ', nn, nselect_tab[irun]
        print, 'factor  = ', cal_factors[2, irun]
        print, 'rel.rms = ', rms_tab[2, irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+(xmax-xmin)*0.05, 1.17], psym=cgsymcat('FILLEDCIRCLE', thick=mythick)*[1., 1., 1.], symsize=0.9*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_select])]   )
     xmax  = 0.95
     xmin  = 0.55
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_uranus'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        w = where(runid[w_select] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_a2[w_select[w]]/sin(elev[w_select[w]])), flux_ratio_a2[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
        if nn gt 1 then rms_tab[1, irun] = stddev(flux_ratio_a2[w_select[w]])/mean(flux_ratio_a2[w_select[w]])*100.0d0
        print, 'nscan   = ', nn, nselect_tab[irun]
        print, 'factor  = ', cal_factors[1, irun]
        print, 'rel.rms = ', rms_tab[1, irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+(xmax-xmin)*0.05, 1.17], psym=cgsymcat('FILLEDCIRCLE', thick=mythick)*[1., 1., 1.], symsize=0.9*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A2', col=0
     
     outplot, /close

     
     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epspdf --bbox '+dir+'plot_flux_density_ratio_obstau_uranus'+plot_suffixe+suf[i]+'.eps'
           ;;spawn, 'epstopdf '+dir+'plot_flux_density_ratio_obstau_uranus'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif

     ;; COMBINED
     ntot_tab[3]    = total(ntot_tab[0:2]) 
     nselect_tab[3] = n_elements(w_select)
     cal_factors[0,3] = mean(cal_factor_a1[w_select]) ;mean(flux_ratio_a1[w_select])
     cal_factors[2,3] = mean(cal_factor_a3[w_select]) ;mean(flux_ratio_a3[w_select])
     cal_factors[3,3] = mean(cal_factor_1mm[w_select]) ;mean(flux_ratio_1mm[w_select])
     cal_factors[1,3] = mean(cal_factor_a2[w_select]) ;mean(flux_ratio_a2[w_select])
     
     rms_tab[0, 3] = stddev(flux_ratio_a1[w_select])/mean(flux_ratio_a1[w_select])*100.0d0
     rms_tab[2, 3] = stddev(flux_ratio_a3[w_select])/mean(flux_ratio_a3[w_select])*100.0d0
     rms_tab[3, 3] = stddev(flux_ratio_1mm[w_select])/mean(flux_ratio_1mm[w_select])*100.0d0
     rms_tab[1, 3] = stddev(flux_ratio_a2[w_select])/mean(flux_ratio_a2[w_select])*100.0d0
          
     print, ''
     print, 'Combined'
     print, 'total nscan = ',    ntot_tab[3]
     print, 'selected nscan = ', nselect_tab[3]
     
     print, 'A1 bias = ', cal_factors[0,3]
     print, 'A3 bias = ', cal_factors[2,3]
     print, '1mm bias = ',cal_factors[3,3]
     print, 'A2 bias = ', cal_factors[1,3]
     
     print, 'A1 rel.rms = ', rms_tab[0, 3]
     print, 'A3 rel.rms = ', rms_tab[2, 3]
     print, '1mm rel.rms = ',rms_tab[3, 3]
     print, 'A2 rel.rms = ', rms_tab[1, 3]
     
     ;; SAUVEGARDE FICHIER
     quoi = ['A1', 'A2', 'A3', '1mm']
     calibrun = [calib_run, 'combination']
     if savefile gt 0 then begin
        get_lun, lun
        openw, lun, dir+'Results_flux_density_ratio_uranus'+plot_suffixe+'.txt'
        for irun = 0, nrun do begin
           printf, lun, ''
           printf, lun, calibrun[irun]
           printf, lun, 'ntot = ', ntot_tab[irun]
           printf, lun, 'nselect = ', nselect_tab[irun]
           for ia = 0, 3 do begin
              printf, lun, quoi[ia], ' fact = ', cal_factors[ia, irun], ', rms = ', rms_tab[ia, irun]
           endfor
        endfor
        
        close, lun
     endif

     
  
     if nostop lt 1 then stop

  endif


  ;; legend
  ;;wind, 1, 1, /free, xsize=100, ysize=800 
  ;outfile = dir+'plot_flux_density_ratio_primary_colortable'
  ;outplot, file=outfile, png=png, ps=ps, xsize=1.2, ysize=16, charsize=charsize, thick=thick, charthick=charthick

  ;;plot, findgen(10), /nodata, tick=0, xcharsize=1.e-8, ycharsize=1.e-8, xmargin=0.1, ymargin=0.1

  ;leg = strarr(nut)
  ;for i=0, nut-1 do leg[i] = ut_tab[i]+' - '+ut_tab[i+1]
  ;legendastro, leg, col=ut_col, textcol=ut_col, box=0
  ;legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=charsize

  ;;for i=0, nut-1 do xyouts, 1.8, 9.5 - (9.*i)/(nut*1.), ut_tab[i], col = ut_col[i]  
  ;;xyouts, 1.8, 0.5  , ut_tab[nut], col = ut_col[0]  



  
  if nostop lt 1 then stop
  
     

end
