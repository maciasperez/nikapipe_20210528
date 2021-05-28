;
;   NIKA2 performance assessment
; 
;   NEFD using the "pipeline method"
;
;   LP, July 2018
;   from Scr/Reference/Draw_plots/nefd_multirun.pro
;   from LP/script/n2r10/check_nefd_multirun.pro
;   v2 : Septembre 2018
;__________________________________________________________

pro nefd_vs_observed_opacity_v2, png=png, ps=ps, pdf=pdf, $
                                 opacorr_method=opacorr_method, $
                                 photocorr_method = photocorr_method, $
                                 nostop = nostop, savefile = savefile

  
  calib_run = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)

  ;; Flux threshold for sources selection
  ;;--------------------------------------------
  flux_threshold_1mm = 1.0d0 ; 0.8d0
  flux_threshold_2mm = 1.0d0 ; 0.4d0
 
  ;; Opacity correction
  ;;---------------------------------------------
  skydip               = 1
  corrected_skydip     = 0
  taumeter             = 0

  ;; Photometric correction
  ;;---------------------------------------------
  do_photocorr         = 0
  ;;photocorr_demo     = 0 ;; not usable for faint sources
  photocorr_point      = 0
  photocorr_thres_primary_1mm  = 1.08 ;1.06   
  photocorr_thres_primary_2mm  = 1.06 ;1.04 
  photocorr_thres_1mm  = 1.15 ;1.12  ;; si 25% d'erreur sur photocorr -> 3% d'erreur sur flux
  photocorr_thres_2mm  = 1.10 ;1.08  ;; si 25% d'erreur sur photocorr -> 2% d'erreur sur flux
  

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
  plot_suffixe = plot_suffixe+'_vfinal'

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
  
  flux_1mm     = 0.
  flux_a2      = 0.
  flux_a1      = 0.
  flux_a3      = 0.
  ;;
  fwhm_1mm     = 0.
  fwhm_a2      = 0.
  fwhm_a1      = 0.
  fwhm_a3      = 0.
  ;;
  nefd_1mm     = 0.
  nefd_a2      = 0.
  nefd_a1      = 0.
  nefd_a3      = 0.
  err_flux_1mm = 0.
  err_flux_2mm = 0.
  err_flux_a1  = 0.
  err_flux_a3  = 0.
  ;;
  eta_a1       = 0.
  eta_a3       = 0.
  eta_a2       = 0.
  eta_1mm      = 0.
  ;;
  ms_a1        = 0.
  ms_a3        = 0.
  ms_a2        = 0.
  ms_1mm       = 0.
  ;;
  tau_1mm      = 0.0d0
  tau_a2       = 0.0d0
  tau_a1       = 0.0d0
  tau_a3       = 0.0d0
  ;;
  elev         = 0.
  obj          = ''
  day          = ''
  ut           = ''
  ut_float     = 0.
  runid        = ''
  scan_list    = ''

  th_flux_1mm = 0.0d0
  th_flux_a2  = 0.0d0
  th_flux_a1  = 0.0d0
  th_flux_a3  = 0.0d0

  ntot_tab = intarr(nrun+1)
  
  for irun = 0, nrun-1 do begin
     
     print,''
     print,'------------------------------------------'
     print,'   ', strupcase(calib_run[irun])
     print,'------------------------------------------'
     print,'READING RESULT FILE: '
     allresult_file = result_files[irun] 
     print, allresult_file
     
     ;;
     ;;  restore the result tables
     ;;____________________________________________________________
     restore, allresult_file, /v
     
     ;; remove known outliers
     ;;___________________________________________________________
     scan_list_ori = allscan_info.scan
     
     outlier_list =  ['20170223s16', $  ; dark test
                      '20170223s17', $  ; dark test
                      '20171024s171', $ ; focus scan
                      '20171026s235', $ ; focus scan
                      '20171028s313', $ ; RAS from tapas
                      '20180114s73', $  ; TBC
                      '20180116s94', $  ; focus scan
                      '20180118s212', $ ; focus scan
                      '20180119s241', $ ; Tapas comment: 'out of focus'
                      '20180119s242', $ ; Tapas comment: 'out of focus'
                      '20180119s243', $  ; Tapas comment: 'out of focus'   '20180122s98', $
                      '20180122s118', '20180122s119', '20180122s120', '20180122s121', $ ;; the telescope has been heated
                      '20170226s415', $                                                 ;; wrong ut time
                      '20170226s416','20170226s417', '20170226s418', '20170226s419'] ;; defocused beammaps

     if do_photocorr gt 0 then begin
        outlier_list = [outlier_list, $
                       '20171024s202', '20171024s220'] ;; during a pointing session
     endif
     
     out_index = 1
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
     allscan_info = allscan_info[out_index]
     
     nscans = n_elements(scan_list_run)
     print, "number of scan: ", nscans
     
    

     ;;
     ;;  NSCAN TOTAL ESTIMATE
     ;;_____________________________________________________________
     w1 = where(allscan_info.result_flux_i_1mm lt flux_threshold_1mm and $
                allscan_info.result_flux_i_2mm lt flux_threshold_2mm and $
                allscan_info.result_flux_i_1mm gt -0.1 and $
                allscan_info.result_flux_i_2mm gt -0.1 , n1)
     
     print,'Run ', calib_run[irun], ' nscans = ', n1
     
     ws = where(strlowcase(allscan_info[w1].object) ne 'ic342' and $
                strlowcase(allscan_info[w1].object) ne 'gp_l23p3' and $
                strlowcase(allscan_info[w1].object) ne 'gp_l23p9' and $
                strlowcase(allscan_info[w1].object) ne 'jkcs041' and $
                strlowcase(allscan_info[w1].object) ne 'gp_l24p5', ns )
     print,'Run ', calib_run[irun], ' nscans = ', ns

     ntot_tab[irun] = ns

     allsources = allscan_info[w1].object
     sources = allsources(uniq(allsources, sort(allsources)))
     print, 'List of faint sources : ', sources
     if nostop lt 1 then stop
     
     
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
        
        ;; POINTING-BASED
        if photocorr_point gt 0 then begin
           photocorr = 1
           ;fix_photocorr = [12.5, 18.5, 12.5]
           fix_photocorr   = 0
           variable        = 0
           weakly_variable = 1
           delta_fwhm      = 0
           delta_stable    = [0., 0., 0.]
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

        allscan_info = allscan_info[nefd_index] ;; include also Uranus scans

        nscans = n_elements(allscan_info)
                
        fwhm = fltarr(nscans, 4)
        flux = fltarr(nscans, 4)
        for ii=0, nscans-1 do begin
           flux[ii, 0] = allscan_info[ii].result_flux_i1
           flux[ii, 1] = allscan_info[ii].result_flux_i2
           flux[ii, 2] = allscan_info[ii].result_flux_i3
           flux[ii, 3] = allscan_info[ii].result_flux_i_1mm
        endfor    
        tfwhm = transpose(fwhm)
        
        if photocorr_point gt 0 then begin
           
           nscans = n_elements(allscan_info.ut)
           day_run = allscan_info.day
           ut_otf = fltarr(nscans)
           ut_run = strmid(allscan_info.ut, 0, 5)
           for i = 0, nscans-1 do begin
              ut_otf[i]  = float((STRSPLIT(ut_run[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_run[i], ':', /EXTRACT))[1])/60.
           endfor
           get_pointing_based_beams, fwhm_point, day_run, ut_otf, calib_run[irun]
           tfwhm = transpose(fwhm_point)
        endif
        
        tflux = transpose(flux)
        ;; implementing photometric correction
        ;;--------------------------------------------------------------------------
        corr_flux_factor = dblarr(4, nscans)
        ;; delta_sidelobe needed for Uranus scans only (using 'demo')
        wu = where(strupcase(allscan_info.object) eq 'URANUS', nu, compl=wo)
        fix = fix_photocorr+delta_stable ;; test 2
        fix = 0
        photometric_correction, tflux[*, wu], tfwhm[*, wu], corr_flux_factor_uranus, $
                                fix=fix, weakly_variable=weakly_variable,$
                                variable=variable, delta_fwhm=delta_fwhm, add1mm=1
        corr_flux_factor[*, wu] = corr_flux_factor_uranus
        ;; delta_sidelobe = 0 for weaker sources (and using 'pointing')
        photometric_correction, tflux[*, wo], tfwhm[*, wo], corr_flux_factor_other, $
                                fix=fix_photocorr, weakly_variable=weakly_variable,$
                                variable=variable, delta_fwhm=0, add1mm=1
        corr_flux_factor[*, wo] = corr_flux_factor_other

        
        wu = where(strupcase(allscan_info.object) eq 'URANUS', nu, compl=wo)
        wphot1=where(corr_flux_factor[0, wu] gt photocorr_thres_primary_1mm or $
                     corr_flux_factor[1, wu] gt photocorr_thres_primary_2mm or $
                     corr_flux_factor[2, wu] gt photocorr_thres_primary_1mm or $
                     corr_flux_factor[3, wu] gt photocorr_thres_primary_1mm, nwphot1, compl=wphotok1)
        
        wphot2=where(corr_flux_factor[0, wo] gt photocorr_thres_1mm or $
                     corr_flux_factor[1, wo] gt photocorr_thres_2mm or $
                     corr_flux_factor[2, wo] gt photocorr_thres_1mm or $
                     corr_flux_factor[3, wo] gt photocorr_thres_1mm, nwphot2, compl=wphotok2)
        
        wphot = [wu[wphot1], wo[wphot2]]
        nwphot = nwphot1 + nwphot2
        wphotok = [wu[wphotok1], wo[wphotok2]]
        
        if nwphot gt 0 then print, 'high photo corr for scans ', allscan_info[wphot].scan
  
        for ii=0, nscans-1 do begin
           allscan_info[ii].result_flux_i1    = allscan_info[ii].result_flux_i1*corr_flux_factor[0,ii]
           allscan_info[ii].result_flux_i2    = allscan_info[ii].result_flux_i2*corr_flux_factor[1,ii]
           allscan_info[ii].result_flux_i3    = allscan_info[ii].result_flux_i3*corr_flux_factor[2,ii]
           allscan_info[ii].result_flux_i_1mm = allscan_info[ii].result_flux_i_1mm*corr_flux_factor[3,ii]
           ;;
           allscan_info[ii].result_nefd_i1    = allscan_info[ii].result_nefd_i1*corr_flux_factor[0,ii]
           allscan_info[ii].result_nefd_i2    = allscan_info[ii].result_nefd_i2*corr_flux_factor[1,ii]
           allscan_info[ii].result_nefd_i3    = allscan_info[ii].result_nefd_i3*corr_flux_factor[2,ii]
           allscan_info[ii].result_nefd_i_1mm = allscan_info[ii].result_nefd_i_1mm*corr_flux_factor[3,ii]
        endfor

        ;; test plot
        index = indgen(nscans)
        plot, index, reform(corr_flux_factor[0, *]), yr=[0.85, 1.3], /ys, /nodata, $
              xtitle='scan index', ytitle= 'photometric correction factor', $
              xr=[-1, nscans], /xs
        oplot, [0, nscans], [1, 1]
        oplot, index, reform(corr_flux_factor[0, *]), col=80, psym=cgsymcat('OPENCIRCLE', thick=2)
        oplot, index, reform(corr_flux_factor[2, *]), col=50, psym=cgsymcat('OPENCIRCLE', thick=2)
        oplot, index, reform(corr_flux_factor[1, *]), col=250, psym=cgsymcat('OPENCIRCLE', thick=2)
        oplot, index[wphotok], reform(corr_flux_factor[0, wphotok]), col=80, psym=cgsymcat('FILLEDCIRCLE', thick=2)
        oplot, index[wphotok], reform(corr_flux_factor[2, wphotok]), col=50, psym=cgsymcat('FILLEDCIRCLE', thick=2)
        oplot, index[wphotok], reform(corr_flux_factor[1, wphotok]), col=250, psym=cgsymcat('FILLEDCIRCLE', thick=2)
        xyouts, index, replicate(0.87, nscans), strmid(allscan_info.scan, 4, 10), $
                charsi=0.7, orient=90
        legendastro, ['A1', 'A3', 'A2'], textcol=[80, 50, 250], col=[80, 50, 250], $
                     box=0, psym=[8, 8, 8]


        print, 'n scan Uranus OK = ', n_elements(wphotok1)
        print, 'n scan NEFD OK = ', n_elements(wphotok2)
        
        if nostop lt 1 then stop

        ;; discard scans that have a photocorr above the threshold
        allscan_info = allscan_info[wphotok]
        nscans = n_elements(allscan_info)

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
        
        allscan_info = allscan_info[nefd_index]
        nscans = n_elements(allscan_info)
        
        print, "baseline selection, nscans = "
        help, nscans
        
     endif

     ;;
     ;; ABSOLUTE CALIBRATION ON URANUS
     ;;____________________________________________________________
     ;; calib using the selection of Uranus scans
     planet_fwhm_max  = [12.5, 18.0, 12.5]
     fwhm_min = [10.0, 16.0, 10.0]
     wu = where(strupcase(allscan_info.object) eq 'URANUS' and $
                allscan_info.result_fwhm_1 le planet_fwhm_max[0] and $
                allscan_info.result_fwhm_2 le planet_fwhm_max[1] and $
                allscan_info.result_fwhm_3 le planet_fwhm_max[2] and $
                allscan_info.result_fwhm_1 gt fwhm_min[0] and $
                allscan_info.result_fwhm_2 gt fwhm_min[1] and $
                allscan_info.result_fwhm_3 gt fwhm_min[2], nuranus)

     th_flux_1mm_run  = dblarr(nuranus)
     th_flux_a2_run   = dblarr(nuranus)
     th_flux_a1_run   = dblarr(nuranus)
     th_flux_a3_run   = dblarr(nuranus)
     for i=0, nuranus-1 do begin
        nk_scan2run, allscan_info[wu[i]].scan, run
        th_flux_1mm_run[i]     = !nika.flux_uranus[0]
        th_flux_a2_run[i]      = !nika.flux_uranus[1]
        th_flux_a1_run[i]      = !nika.flux_uranus[0]
        th_flux_a3_run[i]      = !nika.flux_uranus[0]
     endfor
     
     flux_ratio_1   = avg( th_flux_a1_run/allscan_info[wu].result_flux_i1)
     flux_ratio_2   = avg( th_flux_a2_run/allscan_info[wu].result_flux_i2)
     flux_ratio_3   = avg( th_flux_a3_run/allscan_info[wu].result_flux_i3)
     flux_ratio_1mm = avg( th_flux_1mm_run/allscan_info[wu].result_flux_i_1mm)
     
     correction_coef = [flux_ratio_1, flux_ratio_2, flux_ratio_3, flux_ratio_1mm]
     print,'======================================================'
     print,"Flux correction coefficient A1: "+strtrim(correction_coef[0],2)
     print,"Flux correction coefficient A3: "+strtrim(correction_coef[2],2)
     print,"Flux correction coefficient A1&A3: "+strtrim(correction_coef[3],2)
     print,"Flux correction coefficient A2: "+strtrim(correction_coef[1],2)
     print,'======================================================'
     

     recalibration_coef = correction_coef
     ;save, recalibration_coef, file = 'recalibration_coef_new_opacity_'+calib_run[irun]+'.save'
     ;stop
     
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



     ;;
     ;; NEFD scan selection
     ;;____________________________________________________________
     
     w1 = where(allscan_info.result_flux_i_1mm lt flux_threshold_1mm and $
                allscan_info.result_flux_i_2mm lt flux_threshold_2mm and $
                allscan_info.result_flux_i_1mm gt -0.1 and $
                allscan_info.result_flux_i_2mm gt -0.1 , n1)
     
     allscan_info = allscan_info[w1]
     print,'Run ', calib_run[irun], ' nscans = ', n1
   
     ws = where(strlowcase(allscan_info.object) ne 'ic342' and $
                strlowcase(allscan_info.object) ne 'gp_l23p3' and $
                strlowcase(allscan_info.object) ne 'gp_l23p9' and $
                strlowcase(allscan_info.object) ne 'jkcs041' and $
                                ;strlowcase(allscan_info.object) ne 'macs1206' and $
                strlowcase(allscan_info.object) ne 'gp_l24p5' and $
                strlowcase(allscan_info.object) ne 'ngc588', ns )
     allscan_info = allscan_info[ws]
     print,'Run ', calib_run[irun], ' nscans = ', ns

     
     ;; add in tables
     ;;____________________________________________________________
     scan_list    = [scan_list, allscan_info.scan]
     
     flux_1mm     = [flux_1mm, allscan_info.result_flux_i_1mm]
     flux_a2      = [flux_a2, allscan_info.result_flux_i2]
     flux_a1      = [flux_a1, allscan_info.result_flux_i1]
     flux_a3      = [flux_a3, allscan_info.result_flux_i3]
     nefd_1mm     = [nefd_1mm, allscan_info.result_nefd_i_1mm*1.0d3]
     nefd_a2      = [nefd_a2, allscan_info.result_nefd_i2*1.0d3]
     nefd_a1      = [nefd_a1, allscan_info.result_nefd_i1*1.0d3]
     nefd_a3      = [nefd_a3, allscan_info.result_nefd_i3*1.0d3]
     err_flux_1mm = [err_flux_1mm, allscan_info.result_err_flux_i_1mm*1.0d3]
     err_flux_2mm = [err_flux_2mm, allscan_info.result_err_flux_i2*1.0d3]
     err_flux_a1  = [err_flux_a1, allscan_info.result_err_flux_i1*1.0d3]
     err_flux_a3  = [err_flux_a3, allscan_info.result_err_flux_i3*1.0d3]
     eta_a1       = [eta_a1, allscan_info.result_nkids_valid1/1140.0] ;!nika.ntot_nom[0]
     eta_a3       = [eta_a3, allscan_info.result_nkids_valid3/1140.0] ;!nika.ntot_nom[2]
     eta_a2       = [eta_a2, allscan_info.result_nkids_valid2/616.0]  ;!nika.ntot_nom[1]
     ;;coa = (1.0d0/allscan_info.result_nkids_valid1^2 + 1.0d0/allscan_info.result_nkids_valid3^2)
     ;;eta_1mm      = [eta_1mm, sqrt(1.0d0/coa)/1140.0d0]
     coa = (allscan_info.result_nkids_valid1+ allscan_info.result_nkids_valid3)/2.d0
     eta_1mm      = [eta_1mm, coa/1140.0d0]
     ms = !dpi/4.0d0*6.5d0^2*allscan_info.result_nkids_valid1/1140.0/(allscan_info.result_nefd_i1*1.0d3)^2*60.0d0^2
     ms_a1        = [ms_a1, ms]
     ms = !dpi/4.0d0*6.5d0^2*allscan_info.result_nkids_valid3/1140.0/(allscan_info.result_nefd_i3*1.0d3)^2*60.0d0^2
     ms_a3        = [ms_a3, ms]
     ms = !dpi/4.0d0*6.5d0^2*allscan_info.result_nkids_valid2/1140.0/(allscan_info.result_nefd_i2*1.0d3)^2*60.0d0^2
     ms_a2        = [ms_a2, ms]
     ms = !dpi/4.0d0*6.5d0^2*coa/1140.0/(allscan_info.result_nefd_i_1mm*1.0d3)^2*60.0d0^2
     ms_1mm       = [ms_1mm, ms]
     tau_1mm      = [tau_1mm, allscan_info.result_tau_1mm]
     tau_a2       = [tau_a2, allscan_info.result_tau_2]
     tau_a1       = [tau_a1, allscan_info.result_tau_1]
     tau_a3       = [tau_a3, allscan_info.result_tau_3]
     elev         = [elev, allscan_info.result_elevation_deg*!dtor]
     obj          = [obj, allscan_info.object]
     day          = [day, allscan_info.day]
     runid        = [runid, replicate(calib_run[irun], n_elements(allscan_info.day))]
     ut           = [ut, strmid(allscan_info.ut, 0, 5)]
  endfor
  
  ;; discard the placeholder first element of each tables
  flux_1mm     = flux_1mm[1:*]
  flux_a2      = flux_a2[1:*]
  flux_a1      = flux_a1[1:*]
  flux_a3      = flux_a3[1:*]
  nefd_1mm     = nefd_1mm[1:*]
  nefd_a2      = nefd_a2[1:*]
  nefd_a1      = nefd_a1[1:*]
  nefd_a3      = nefd_a3[1:*]
  err_flux_1mm = err_flux_1mm[1:*]
  err_flux_2mm = err_flux_2mm[1:*]
  err_flux_a1  = err_flux_a1[1:*]
  err_flux_a3  = err_flux_a3[1:*]
  ;;
  eta_a1       = eta_a1[1:*]
  eta_a2       = eta_a2[1:*]
  eta_a3       = eta_a3[1:*]
  eta_1mm      = eta_1mm[1:*]
  ;;
  ms_a1       = ms_a1[1:*]
  ms_a2       = ms_a2[1:*]
  ms_a3       = ms_a3[1:*]
  ms_1mm      = ms_1mm[1:*]
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
  scan_list    = scan_list[1:*]
  
  ;; calculate ut_float 
  nscans      = n_elements(day)
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor

  
  
  
;;; condition IRAM
;;;-------------------------------------------------------------------
  print,""
  print,"condition IRAM"
  print,"---------------------------------------------------"
  output_pwv = 1.0d0
  atm_model_mdp, tau_1, tau_2, tau_3, tau_225, atm_em_1, atm_em_2, atm_em_3, output_pwv=output_pwv, /nostop
  w=where(output_pwv eq 2., nn)

  atm_tau1   = avg([tau_1[w],tau_3[w]])
  atm_tau2   = tau_2[w]
  atm_tau_a1 = tau_1[w]
  atm_tau_a3 = tau_3[w]
  print,"tau_1 @ 2mm pwv = ", atm_tau_a1
  print,"tau_3 @ 2mm pwv  = ", atm_tau_a3
  print,"tau_1mm @ 2mm pwv  = ", atm_tau1
  print,"tau_2mm @ 2mm pwv  = ", atm_tau2

  ;; corrected opacity uncertainties
  ;; -------------------------------------
  delta_a = 0.03
  print, 'opacity relative uncertainties = ', delta_a * atm_tau1 / sin(60.*!dtor)*100.0
  print, 'opacity relative uncertainties = ', delta_a * atm_tau2 / sin(60.*!dtor)*100.0


  
  ;;________________________________________________________________
  ;;
  ;; plots
  ;;________________________________________________________________
  ;;________________________________________________________________
  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14

  col_tab = [col_n2r9, col_n2r12, col_n2r14]

  ;; result_tab: all runs + combined results 
  nselect_tab = intarr(nrun+1)
  nefd0_tab   = dblarr(4, nrun+1)
  nefdA_tab   = dblarr(4, nrun+1)
  rms_nefd0_tab   = dblarr(4, nrun+1)
  rms_nefdA_tab   = dblarr(4, nrun+1)
  
  run_index = [1, 2, 0]

  ;; 1mm
  ;;----------------------------------------------------------
  print, ''
  print, ' 1mm '
  print, '-----------------------'
  
  ymax = 150.                   ;min( [250., max(nefd_1mm)]  )
  ymin = 0.                     ;min( [0., min(nefd_1mm)]   )
  ;xmax  = 1.01
  ;xmin  = 0.49
  atm_trans = exp(-tau_1mm/sin(elev))

  xmax = 0.7
  xmin = 0.
  obs_tau = tau_1mm/sin(elev)
  
  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_nefd_vs_obstau'+plot_suffixe+'_1mm'
  outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
  
  plot, obs_tau, nefd_1mm, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
        ;;xtitle='Atmospheric transmission', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  obstau = dindgen(1000)/1000.
  for ir=0, nrun-1 do begin
     irun = run_index[ir]
     print, ''
     print, calib_run[irun]
     w = where(runid eq calib_run[irun] and nefd_1mm gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
     
     ;; test
     wtest = where(runid eq calib_run[irun] and nefd_1mm gt 0.0 and $
               ut_float gt 13. and ut_float lt 22., njour)
     ;;if njour gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=2, col=0, symsize=0.5
     
     w_atmtrans = where(atm_trans gt 0.5 and atm_trans le 1.0 and $
                        runid eq calib_run[irun] and nefd_1mm gt 0.0, nn)
     
     nselect_tab[irun] = nn
     nefd_0 = median(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans])
     rms_nefd_0 = stddev(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans])
     nefd0_tab[3, irun] = nefd_0
     nefdA_tab[3, irun] = nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     rms_nefd0_tab[3, irun] = rms_nefd_0
     rms_nefdA_tab[3, irun] = rms_nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     print, 'nscans = ', nn
     print, 'NEFD_0 = ', nefd0_tab[3, irun]
     print, 'NEFD 0 MOY = ', mean(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans])
     print, 'RMS NEFD_0 = ', rms_nefd_0 
     print, 'NEFD IRAM = ', nefdA_tab[3, irun]
     print, 'RMS NEFD IRAM = ', rms_nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     print, ''
     print, 'ETA median = ',median(eta_1mm[w_atmtrans])
     print, 'ETA mean = ', mean(eta_1mm[w_atmtrans])
     print, 'rms ETA  = ', stddev(eta_1mm[w_atmtrans])
     print, ''
     print, 'MS median = ',  median(ms_1mm[w_atmtrans]/atm_trans[w_atmtrans]^2)
     print, 'MS mean = ',  mean(ms_1mm[w_atmtrans]/atm_trans[w_atmtrans]^2)
     print, 'rms MS = ',  stddev(ms_1mm[w_atmtrans]/atm_trans[w_atmtrans]^2)
     print, ''
     w_atmtrans = where(atm_trans gt 0.5 and atm_trans le 1.0 and $
                        runid eq calib_run[irun] and nefd_1mm gt 0.0 and $
                        (ut_float le 9. or ut_float ge 22.), nn)
     print, 'NEFD_0 night = ', median(nefd_1mm[w_atmtrans]*atm_trans[w_atmtrans]) 
     
     oplot,obstau, nefd_0*exp(obstau), col=col_tab[irun]

     whigh = where(nefd_1mm[w]*atm_trans[w] gt nefd_0+3.*rms_nefd_0, nhigh)
     print, 'n high NEFD = ', nhigh
     if nhigh gt 0 then begin
        print, obj[w[whigh]]
        print, ut[w[whigh]]
        print, flux_1mm[w[whigh]]
        print, "tau = ", tau_1mm[w[whigh]]
        print, "el = ",  elev[w[whigh]]/!dtor
        ;;oplot, obs_tau[w[whigh]], nefd_1mm[w[whigh]], psym=2, col=245, symsize=0.5
     endif
  endfor
  ;;
  legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1.;,pos=[xmin+(xmax-xmin)*0.05, 1.17]
  ;;
    
  xyouts, xmax-(xmax-xmin)*0.15, ymax-(ymax-ymin)*0.1, 'A1&A3', col=0 
  
  
  outplot, /close
     
  
  ;; A1
  ;;----------------------------------------------------------
  print, ''
  print, ' A1 '
  print, '-----------------------'

  
  ymax = 150. ; min( [250., max(nefd_a1)]   )
  ymin = 0.   ; min( [0., min(nefd_a1)]   )
  ;;xmax  = 1.01
  ;;xmin  = 0.49
  
  atm_trans = exp(-tau_a1/sin(elev))

  obs_tau = tau_a1/sin(elev)
  xmin = 0.0
  xmax = 0.7

  
  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_nefd_vs_obstau'+plot_suffixe+'_a1'
  outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
  
  plot, obs_tau, nefd_a1, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
        ;;xtitle='Atmospheric transmission', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  obstau = dindgen(1000)/1000.
  for ir=0, nrun-1 do begin
     irun = run_index[ir]
     print, ''
     print, calib_run[irun]
     w = where(runid eq calib_run[irun] and nefd_a1 gt 0.0, nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
     w_obstau = where(atm_trans gt 0.5 and atm_trans le 1.0 $
                      and runid eq calib_run[irun] and nefd_a1 gt 0.0, nn)

     nefd_0 = median(nefd_a1[w_obstau]*atm_trans[w_obstau])
     rms_nefd_0 = stddev(nefd_a1[w_obstau]*atm_trans[w_obstau])
     nefd0_tab[0, irun] = nefd_0
     nefdA_tab[0, irun] = nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor))
     rms_nefd0_tab[0, irun] = rms_nefd_0
     rms_nefdA_tab[0, irun] = rms_nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor))
     print, 'nscans = ', nn
     print, 'NEFD_0 = ', nefd0_tab[0, irun]
     print, 'NEFD_0 MOY = ', mean(nefd_a1[w_obstau]*atm_trans[w_obstau])
     print, 'rms NEFD_0 = ', rms_nefd_0 
     print, 'NEFD IRAM = ', nefdA_tab[0, irun]
     print, 'rms NEFD IRAM = ', rms_nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor)) 
     print, ''
     print, 'ETA median = ',median(eta_a1[w_obstau])
     print, 'ETA mean = ', mean(eta_a1[w_obstau])
     print, 'rms ETA = ', stddev(eta_a1[w_obstau])
     print, ''
     print, 'MS median = ',  median(ms_a1[w_obstau]/atm_trans[w_obstau]^2)
     print, 'MS mean = ',  mean(ms_a1[w_obstau]/atm_trans[w_obstau]^2)
     print, 'rms MS = ',  stddev(ms_a1[w_obstau]/atm_trans[w_obstau]^2)
     print, ''
     oplot, obstau, nefd_0*exp(obstau), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.];, pos=[xmin+(xmax-xmin)*0.05, 1.17]
     
     xyouts, xmax-(xmax-xmin)*0.1, ymax-(ymax-ymin)*0.1, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     print, ''
     print, ' A3'
     print, '-----------------------'
     ymax = 150.                ; min( [250., max(nefd_a3)]   )
     ymin = 0.                  ; min( [0.0, min(nefd_a3)]   )
     ;;xmax  = 1.01
     ;;xmin  = 0.49
     atm_trans = exp(-tau_a3/sin(elev))

     obs_tau = tau_a3/sin(elev)
     xmin = 0.0
     xmax = 0.7
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_nefd_vs_obstau'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, obs_tau, nefd_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
           ;;xtitle='Atmospheric transmission', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
     obstau = dindgen(1000)/1000.
     for ir=0, nrun-1 do begin
        irun=run_index[ir]
        print, ''
        print, calib_run[irun]
        w = where(runid eq calib_run[irun] and nefd_a3 gt 0.0, nn)
        if nn gt 0 then oplot, obs_tau[w], nefd_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
        w_obstau = where(atm_trans gt 0.5 and atm_trans le 1.0 and $
                         runid eq calib_run[irun] and nefd_a3 gt 0.0, nn)

        nefd_0 = median(nefd_a3[w_obstau]*atm_trans[w_obstau])
        rms_nefd_0 = stddev(nefd_a3[w_obstau]*atm_trans[w_obstau])
        nefd0_tab[2, irun] = nefd_0
        nefdA_tab[2, irun] = nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor))
        rms_nefd0_tab[2, irun] = rms_nefd_0
        rms_nefdA_tab[2, irun] = rms_nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor))
        print, 'nscans = ', nn
        print, 'NEFD_0 = ', nefd0_tab[2, irun]
        print, 'NEFD_0 MOY = ', mean(nefd_a3[w_obstau]*atm_trans[w_obstau])
        print, 'rms NEFD_0 = ', rms_nefd_0 
        print, 'NEFD IRAM = ', nefdA_tab[2, irun]
        print, 'rms NEFD IRAM = ', rms_nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor)) 
        print, ''
        print, 'ETA median = ',median(eta_a3[w_obstau])
        print, 'ETA mean = ', mean(eta_a3[w_obstau])
        print, 'rms ETA  = ', stddev(eta_a3[w_obstau])
        print, ''
        print, 'MS median = ',  median(ms_a3[w_obstau]/atm_trans[w_obstau]^2)
        print, 'MS mean = ',  mean(ms_a3[w_obstau]/atm_trans[w_obstau]^2)
        print, 'rms MS = ',  stddev(ms_a3[w_obstau]/atm_trans[w_obstau]^2)
        print, ''
        oplot, obstau, nefd_0*exp(obstau), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.];,pos=[xmin+(xmax-xmin)*0.05, 1.17]
     
     xyouts, xmax-(xmax-xmin)*0.1, ymax-(ymax-ymin)*0.1, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'

     ymax = 50. ; min( [50., max(nefd_a2)]   )
     ymin = 0.  ; min( [0., min(nefd_a2)]   )
     ;;xmax  = 1.01
     ;;xmin  = 0.59
     atm_trans = exp(-tau_a2/sin(elev))

     obs_tau = tau_a2/sin(elev)
     xmin = 0.0
     xmax = 0.5
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_nefd_vs_obstau'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, obs_tau, nefd_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='!7s!3/sin(el)', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
           ;;xtitle='Atmospheric transmission', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
     obstau = dindgen(1000)/1000.
     for ir=0, nrun-1 do begin
        irun=run_index[ir]
        print, ''
        print, calib_run[irun]
        w = where(runid eq calib_run[irun] and nefd_a2 gt 0.0, nn)
        if nn gt 0 then oplot,obs_tau[w], nefd_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun], symsize=0.5
        w_obstau = where(atm_trans gt 0.7 and atm_trans le 1.0 and $
                         runid eq calib_run[irun] and nefd_a2 gt 0.0, nn)

        nefd_0 = median(nefd_a2[w_obstau]*atm_trans[w_obstau])
        rms_nefd_0 = stddev(nefd_a2[w_obstau]*atm_trans[w_obstau])
        nefd0_tab[1, irun] = nefd_0
        nefdA_tab[1, irun] = nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
        rms_nefd0_tab[1, irun] = rms_nefd_0
        rms_nefdA_tab[1, irun] = rms_nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
        print, 'nscans = ', nn
        print, 'NEFD_0 = ', nefd0_tab[1, irun]
        print, 'NEFD_0 MOY = ', mean(nefd_a2[w_obstau]*atm_trans[w_obstau])
        print, 'rms NEFD_0 = ', rms_nefd_0 
        print, 'NEFD IRAM = ', nefdA_tab[1, irun]
        print, 'rms NEFD IRAM = ', rms_nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
        print, ''
        print, 'ETA median = ',median(eta_a2[w_obstau])
        print, 'ETA mean = ', mean(eta_a2[w_obstau])
        print, 'rms ETA = ', stddev(eta_a2[w_obstau])
        print, ''
        print, 'MS median = ',  median(ms_a2[w_obstau]/atm_trans[w_obstau]^2)
        print, 'MS mean = ',  mean(ms_a2[w_obstau]/atm_trans[w_obstau]^2)
        print, 'rms MS = ',  stddev(ms_a2[w_obstau]/atm_trans[w_obstau]^2)
        print, ''
        oplot, obstau, nefd_0*exp(obstau), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.];, pos=[xmin+(xmax-xmin)*0.05, 1.17]
     
     xyouts, xmax-(xmax-xmin)*0.1, ymax-(ymax-ymin)*0.1, 'A2', col=0
     
     outplot, /close


     print, ''
     print, 'Union of 3 runs'
     print, '--------------------------'
     print, 'A1&A3'
     ntot_tab[3] = total(ntot_tab(0:2))
     atm_trans = exp(-tau_1mm/sin(elev))
     w_obstau = where(atm_trans gt 0.5 and atm_trans le 1.0 and nefd_1mm gt 0.0, nn)
     nselect_tab[3] = nn
     nefd_0 = median(nefd_1mm[w_obstau]*atm_trans[w_obstau])
     rms_nefd_0 = stddev(nefd_1mm[w_obstau]*atm_trans[w_obstau])
     nefd0_tab[3, 3] = nefd_0
     nefdA_tab[3, 3] = nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     rms_nefd0_tab[3, 3] = rms_nefd_0
     rms_nefdA_tab[3, 3] = rms_nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd0_tab[3, 3]
     print, 'NEFD IRAM = ', nefdA_tab[3, 3]
     print, 'rms NEFD_0 = ', rms_nefd0_tab[3, 3]
     print, 'rms NEFD IRAM = ', rms_nefdA_tab[3, 3]
     print, 'ETA median = ',median(eta_1mm[w_obstau])
     print, 'ETA mean = ', mean(eta_1mm[w_obstau])
     print, 'rms ETA = ', stddev(eta_1mm[w_obstau])
     print, 'MS median = ', median(ms_1mm[w_obstau]/atm_trans[w_obstau]^2)
     print, 'MS mean = ',  mean(ms_1mm[w_obstau]/atm_trans[w_obstau]^2)
     print, 'rms MS  = ',  stddev(ms_1mm[w_obstau]/atm_trans[w_obstau]^2)
     
     print, ''
     print, 'A1'
     atm_trans = exp(-tau_a1/sin(elev))
     w_obstau = where(atm_trans gt 0.5 and atm_trans le 1.0  and nefd_a1 gt 0.0, nn)
     nefd_0 = median(nefd_a1[w_obstau]*atm_trans[w_obstau])
     rms_nefd_0 = stddev(nefd_a1[w_obstau]*atm_trans[w_obstau])
     nefd0_tab[0, 3] = nefd_0
     nefdA_tab[0, 3] = nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor))
     rms_nefd0_tab[0, 3] = rms_nefd_0
     rms_nefdA_tab[0, 3] = rms_nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd0_tab[0, 3]
     print, 'NEFD IRAM = ', nefdA_tab[0, 3]
     print, 'rms NEFD_0 = ', rms_nefd0_tab[0, 3]
     print, 'rms NEFD IRAM = ', rms_nefdA_tab[0, 3]
     print, 'ETA median = ',median(eta_a1[w_obstau])
     print, 'ETA mean = ', mean(eta_a1[w_obstau])
     print, 'rms ETA = ', stddev(eta_a1[w_obstau])
     print, 'MS median = ', median(ms_a1[w_obstau]/atm_trans[w_obstau]^2)
     print, 'MS mean = ',  mean(ms_a1[w_obstau]/atm_trans[w_obstau]^2)
     print, 'rms MS  = ',  stddev(ms_a1[w_obstau]/atm_trans[w_obstau]^2)
     print, ''
     print, 'A3'
     atm_trans = exp(-tau_a3/sin(elev))
     w_obstau = where(atm_trans gt 0.5 and atm_trans le 1.0  and nefd_a3 gt 0.0 and nefd_a3 lt 1d3, nn)
     nefd_0     = median(nefd_a3[w_obstau]*atm_trans[w_obstau])
     rms_nefd_0 = stddev(nefd_a3[w_obstau]*atm_trans[w_obstau])
     nefd0_tab[2, 3] = nefd_0
     nefdA_tab[2, 3] = nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor))
     rms_nefd0_tab[2, 3] = rms_nefd_0
     rms_nefdA_tab[2, 3] = rms_nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ',nefd0_tab[2, 3] 
     print, 'NEFD IRAM = ',nefdA_tab[2, 3]
     print, 'RMS NEFD_0 = ',rms_nefd0_tab[2, 3] 
     print, 'RMS NEFD IRAM = ',rms_nefdA_tab[2, 3]
     print, 'ETA median = ',median(eta_a3[w_obstau])
     print, 'ETA mean = ', mean(eta_a3[w_obstau])
     print, 'rms ETA = ', stddev(eta_a3[w_obstau])
     print, 'MS median = ', median(ms_a3[w_obstau]/atm_trans[w_obstau]^2)
     print, 'MS mean = ',  mean(ms_a3[w_obstau]/atm_trans[w_obstau]^2)
     print, 'rms MS  = ',  stddev(ms_a3[w_obstau]/atm_trans[w_obstau]^2)
     print, ''
     print, 'A2'
     atm_trans = exp(-tau_a2/sin(elev))
     w_obstau = where(atm_trans gt 0.7 and atm_trans le 1.0  and nefd_a2 gt 0.0, nn)
     nefd_0 = median(nefd_a2[w_obstau]*atm_trans[w_obstau])
     rms_nefd_0 = stddev(nefd_a2[w_obstau]*atm_trans[w_obstau])
     nefd0_tab[1, 3] = nefd_0
     nefdA_tab[1, 3] = nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
     rms_nefd0_tab[1, 3] = rms_nefd_0
     rms_nefdA_tab[1, 3] = rms_nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd0_tab[1, 3]
     print, 'NEFD IRAM = ',nefdA_tab[1, 3] 
     print, 'RMS NEFD_0 = ', rms_nefd0_tab[1, 3]
     print, 'RMS NEFD IRAM = ',rms_nefdA_tab[1, 3]
     print, 'ETA median = ',median(eta_a2[w_obstau])
     print, 'ETA mean = ', mean(eta_a2[w_obstau])
     print, 'rms ETA = ', stddev(eta_a2[w_obstau])
     print, 'MS median = ', median(ms_a2[w_obstau]/atm_trans[w_obstau]^2)
     print, 'MS mean = ',  mean(ms_a2[w_obstau]/atm_trans[w_obstau]^2)
     print, 'rms MS  = ',  stddev(ms_a2[w_obstau]/atm_trans[w_obstau]^2)
     ;; SAUVEGARDE FICHIER
     quoi = ['A1', 'A2', 'A3', '1mm']
     calibrun = [calib_run, 'combination']
     if savefile gt 0 then begin
        get_lun, lun
        openw, lun, dir+'Results_NEFD'+plot_suffixe+'.txt'
        for irun = 0, nrun do begin
           printf, lun, ''
           printf, lun, calibrun[irun]
           printf, lun, 'ntot = ', ntot_tab[irun]
           printf, lun, 'nselect = ', nselect_tab[irun]
           for ia = 0, 3 do begin
              printf, lun, quoi[ia], ' nefd0 = ', nefd0_tab[ia, irun], ', nefdA = ', nefdA_tab[ia, irun], $
                      ' rms_nefd0 = ', rms_nefd0_tab[ia, irun], ', rms_nefdA = ', rms_nefdA_tab[ia, irun]
           endfor
        endfor
        
        close, lun
     endif

     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epstopdf '+dir+'plot_nefd_vs_obstau'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif
     
     
     if nostop lt 1 then stop


     ;; NEFD vs FLUX

     
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     
     ymax = min( [180., max(nefd_1mm)]  )
     ymin = min( [0., min(nefd_1mm)]   )
     xmax  = flux_threshold_1mm+0.1
     xmin  = -0.5
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_nefd_vs_flux'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, flux_1mm, nefd_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Flux density [Jy]', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
     
     obstau = dindgen(1000)/1000.
     for ir=0, nrun-1 do begin
        irun = run_index[ir]
        print, ''
        print, calib_run[irun]
        w = where(runid eq calib_run[irun] and nefd_1mm gt 0.0, nn)
        if nn gt 0 then oplot, flux_1mm[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
        w = where(runid eq calib_run[irun] and nefd_1mm gt 0.0 and $
                  ut_float gt 14. and ut_float lt 20., njour)
        if njour gt 0 then oplot, flux_1mm[w], nefd_1mm[w], psym=2, col=0,symsize=0.5
     endfor
     ;;
     legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1. ;,pos=[xmin+(xmax-xmin)*0.05, 1.17]
     ;;
     
     xyouts, xmax-(xmax-xmin)*0.15, ymax-(ymax-ymin)*0.1, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     if nostop lt 1 then stop

 


     wd, /a 
     stop


end
