
;;
;;  TEST THE STABILITY OF THE FLUX RATIO AGAINST OPACITY
;;
;;   use output files from baseline_calibration_v2_outputfile
;;
;;   LP, August 2018
;;_______________________________________________________________


pro test_flux_density_ratio_stability, png=png, ps=ps, $
                                       fwhm_stability=fwhm_stability, $
                                       obstau_stability=obstau_stability, $
                                       mwc349_stability=mwc349_stability
  
  
  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)

  ;; methode de correction d'opacite
  ;;---------------------------------------------
  skydip_based                 = 0
  corrected_skydip_based       = 1
  flux_driven_taumeter_based   = 0
  skydip_driven_taumeter_based = 0

  atm_taumeter_based           = 0
  
  ;;sources = ['MWC349', 'CRL2688', 'NGC7027']
  sources = ['URANUS', 'MWC349']
  nsource = 2

  mwc349_stability = 1
  
  
  ;; outplot directory
  outdir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/Opacity_correction_tests/'

  nostop=1

  ;;plot_suffixe = '_taumeter_based'
  ;;plot_suffixe = '_skydip_based'
  plot_suffixe = '_corrected_skydip_based'
  
  ;;________________________________________________________________
  ;;
  ;; get all result files
  ;;________________________________________________________________
  ;; result files as produced using
  ;; baseline_calibration_reference_outfile.pro
  ;;________________________________________________________________

  result_files = strarr(nrun, nsource)
  for irun = 0, nrun-1 do begin
     runname = calib_run[irun]
     dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/'
     result_files[irun, 0] = dir+'Uranus_allinfo_'+runname+'_baseline_v2.save'
     result_files[irun, 1] = dir+'MWC349_allinfo_'+runname+'_baseline_v2.save'
  endfor
 
  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
    
  flux_1mm     = 0.
  flux_a2      = 0.
  flux_a1      = 0.
  flux_a3      = 0.
  th_flux_1mm  = 0.
  th_flux_a2   = 0.
  th_flux_a1   = 0.
  th_flux_a3   = 0.
  err_flux_1mm = 0.
  err_flux_a2  = 0.
  err_flux_a1  = 0.
  err_flux_a3  = 0.
  tau_1mm_ori  = 0.0d0
  tau_a2_ori   = 0.0d0
  tau_a1_ori   = 0.0d0
  tau_a3_ori   = 0.0d0
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
  index_baseline  = -1
  ut           = ''
  ut_float     = 0.
  scan_list    = ''
  
  for irun = 0, nrun-1 do begin
     
     runname = calib_run[irun]
     
     print,''
     print,'------------------------------------------'
     print,'   ', strupcase(runname)
     print,'------------------------------------------'
     print,'READING RESULT FILE: '
     allresult_file = result_files[irun, *] 
     print, allresult_file
     
     ;;
     ;;  restore result tables
     ;;____________________________________________________________
     restore, allresult_file[0], /v
     uranus_res = allscan_info
     restore, allresult_file[1], /v
     calib2_res = allscan_info

     allscan_info = [uranus_res, calib2_res]
     
     ;; remove known outliers
     ;;____________________________________________________________
     ;;scan_list_ori = strtrim(string(allscan_info.day, format='(i8)'), 2)+"s"+$
     ;;                strtrim( string(allscan_info.scan_num, format='(i8)'),2)
     scan_list_ori = allscan_info.scan
     
     outlier_list =  ['20170223s16', $ ; dark test
                      '20170223s17', $ ; dark test
                      '20171024s171', $ ; focus scan
                      '20171026s235', $ ; focus scan
                      '20171028s313', $ ; RAS from tapas
                      '20180114s73', $  ; TBC
                      '20180116s94', $  ; focus scan
                      '20180118s212', $ ; focus scan
                      '20180119s241', $ ; Tapas comment: 'out of focus'
                      '20180119s242', $ ; Tapas comment: 'out of focus'
                      '20180119s243', $  ; Tapas comment: 'out of focus'   '20180122s98', $
                      '20180122s118', '20180122s119', '20180122s120', '20180122s121'] ;; the telescope has been heated
     
     out_index = 1
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
     allscan_info = allscan_info[out_index]

     nscans = n_elements(scan_list_run)
     print, "scan list: "
     help, scan_list_run
     if nostop lt 1 then stop
     
     ;;
     ;; FLUX DENSITY EXPECTATIONS
     ;;____________________________________________________________
     th_flux_1mm_run = dblarr(nscans)
     th_flux_a2_run  = dblarr(nscans)
     th_flux_a1_run  = dblarr(nscans)
     th_flux_a3_run  = dblarr(nscans)
     
     ;; URANUS
     ;;------------------------------
     wu = where(strupcase(allscan_info.object) eq 'URANUS', nuranus)
     for iu=0, nuranus-1 do begin
        i = wu[iu]
        nk_scan2run, scan_list_run[i], run
        th_flux_1mm_run[i]     = !nika.flux_uranus[0]
        th_flux_a2_run[i]      = !nika.flux_uranus[1]
        th_flux_a1_run[i]      = !nika.flux_uranus[0]
        th_flux_a3_run[i]      = !nika.flux_uranus[0]
     endfor
     ;; MWC349
     ;;------------------------------
     wsou = where(strupcase(allscan_info.object) eq 'MWC349', nscan_sou)
     lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
     nu = !const.c/(lambda*1e-3)/1.0d9
     th_flux           = 1.16d0*(nu/100.0)^0.60
     ;; assuming indep param
     err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
     th_flux_1mm_run[wsou]     = th_flux[0]
     th_flux_a2_run[wsou]      = th_flux[1]
     th_flux_a1_run[wsou]      = th_flux[0]
     th_flux_a3_run[wsou]      = th_flux[2]
     
         
     ;;
     ;; OPACITY CORRECTION
     ;;____________________________________________________________

     ;; 1/ getting tau_NIKA
     ;;tau_nika = dblarr(nscans, 4)
     if skydip_based gt 0 then begin
        tau_nika = [[allscan_info.result_tau_1], [allscan_info.result_tau_2], $
                    [allscan_info.result_tau_3], [allscan_info.result_tau_1mm]]
     endif

     if corrected_skydip_based gt 0 then begin
        tau_skydip = [[allscan_info.result_tau_1], [allscan_info.result_tau_2], $
                      [allscan_info.result_tau_3], [allscan_info.result_tau_1mm]]
        get_corrected_tau_skydip, tau_skydip, tau_nika
     endif
     
     if atm_taumeter_based gt 0 then begin
        get_tau_nika_from_tau225, runname, scan_list_run, tau_nika, flux_driven=0, skydip_driven=0, atm=1
     endif
     
     if flux_driven_taumeter_based gt 0 then begin
        get_tau_nika_from_tau225, runname, scan_list_run, tau_nika, flux_driven=1, skydip_driven=0
     endif

     if skydip_driven_taumeter_based gt 0 then begin
        get_tau_nika_from_tau225, runname, scan_list_run, tau_nika, flux_driven=0, skydip_driven=1
     endif

     ;; 2/ implementing opacity correction
     sinel = sin(allscan_info.result_elevation_deg*!dtor)
     allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*exp((tau_nika[*,3]-allscan_info.result_tau_1mm)/sinel)
     allscan_info.result_flux_i1 = allscan_info.result_flux_i1*exp((tau_nika[*,0]-allscan_info.result_tau_1)/sinel)
     allscan_info.result_flux_i2 = allscan_info.result_flux_i2*exp((tau_nika[*,1]-allscan_info.result_tau_2)/sinel)
     allscan_info.result_flux_i3 = allscan_info.result_flux_i3*exp((tau_nika[*,2]-allscan_info.result_tau_3)/sinel) 

          
     ;;
     ;; BASELINE SELECTION
     ;;____________________________________________________________
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

     mask = intarr(nscans)
     mask[wbaseline] = 1
     index_baseline = [index_baseline, mask]

     print, "baseline selection, nscans = "
     help, wbaseline
     
    
     
     ;;
     ;; ABSOLUTE CALIBRATION ON URANUS
     ;;____________________________________________________________
     wuranus = where(strupcase(allscan_info[wbaseline].object) eq 'URANUS', nuranus)
     wu = wbaseline[wuranus]
     
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


     ;;
     ;; add in tables
     ;;____________________________________________________________
     
     scan_list    = [scan_list, scan_list_run]
     
     flux_1mm     = [flux_1mm, allscan_info.result_flux_i_1mm]
     flux_a2      = [flux_a2, allscan_info.result_flux_i2]
     flux_a1      = [flux_a1, allscan_info.result_flux_i1]
     flux_a3      = [flux_a3, allscan_info.result_flux_i3]
     err_flux_1mm = [err_flux_1mm, allscan_info.result_err_flux_i_1mm]
     err_flux_a2  = [err_flux_a2, allscan_info.result_err_flux_i2]
     err_flux_a1  = [err_flux_a1, allscan_info.result_err_flux_i1]
     err_flux_a3  = [err_flux_a3, allscan_info.result_err_flux_i3]
     ;;
     th_flux_1mm     = [th_flux_1mm, th_flux_1mm_run ]
     th_flux_a2      = [th_flux_a2, th_flux_a2_run ] 
     th_flux_a1      = [th_flux_a1, th_flux_a1_run ]
     th_flux_a3      = [th_flux_a3, th_flux_a3_run ]
     ;;
     fwhm_1mm     = [fwhm_1mm, allscan_info.result_fwhm_1mm]
     fwhm_a2      = [fwhm_a2, allscan_info.result_fwhm_2]
     fwhm_a1      = [fwhm_a1, allscan_info.result_fwhm_1]
     fwhm_a3      = [fwhm_a3, allscan_info.result_fwhm_3]
     ;;
     tau_1mm_ori  = [tau_1mm_ori, allscan_info.result_tau_1mm]
     tau_a2_ori   = [tau_a2_ori, allscan_info.result_tau_2mm]
     tau_a1_ori   = [tau_a1_ori, allscan_info.result_tau_1]
     tau_a3_ori   = [tau_a3_ori, allscan_info.result_tau_3]
     ;;
     tau_1mm      = [tau_1mm, tau_nika[*, 3]]
     tau_a2       = [tau_a2,  tau_nika[*, 1]]
     tau_a1       = [tau_a1,  tau_nika[*, 0]]
     tau_a3       = [tau_a3,  tau_nika[*, 2]]
     ;;
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
  err_flux_1mm = err_flux_1mm[1:*]
  err_flux_a2  = err_flux_a2[1:*]
  err_flux_a1  = err_flux_a1[1:*]
  err_flux_a3  = err_flux_a3[1:*]
  ;;
  th_flux_1mm     = th_flux_1mm[1:*]
  th_flux_a2      = th_flux_a2[1:*]
  th_flux_a1      = th_flux_a1[1:*]
  th_flux_a3      = th_flux_a3[1:*]
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
  index_baseline = index_baseline[1:*]
  scan_list      = scan_list[1:*]
  
  ;; calculate ut_float 
  nscans      = n_elements(day)
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor





  
  
  if nostop lt 1 then stop

  ;;________________________________________________________________
  ;;
  ;; plots
  ;;________________________________________________________________
  ;;________________________________________________________________

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14

  ut_tab = ['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

  ut_col = [10, 35, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25, 15]
  
  nut = n_elements(ut_tab)-1

  w_baseline = where(index_baseline gt 0, n_baseline)
  
  planet_fwhm_max  = [13.0, 18.3, 13.0]
  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3

  err_flux_ratio_1mm = err_flux_1mm/th_flux_1mm
  err_flux_ratio_a1  = err_flux_a1/th_flux_a1
  err_flux_ratio_a2  = err_flux_a2/th_flux_a2
  err_flux_ratio_a3  = err_flux_a3/th_flux_a3
  
  ;;
  ;;   MWC349 3 RUNS : FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(mwc349_stability) then begin
     
     col_tab = [col_n2r9, col_n2r12, col_n2r14]

     w_baseline = where(index_baseline gt 0, n_b)
     w_b2 = where(index_baseline gt 0 and obj eq 'MWC349', n_b2)
     w_b1 = where(index_baseline gt 0 and strupcase(obj) eq 'URANUS', n_b1)
     
     w_t2 = where(obj eq 'MWC349', n_t2)
     w_t1 = where(strupcase(obj) eq 'URANUS', n_t1)

     ;; stability estimator
     d = dblarr(nrun, 4)
     sd = dblarr(nrun, 4)
     nd = lonarr(nrun, 4)
     
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.3, max(flux_ratio_1mm[w_b2] )]   )
     ymin = min( [0.7, min(flux_ratio_1mm[w_b2])]   )
     xmax  = 1.00
     xmin  = 0.35     
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_obstau'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        
        ;; URANUS
        w = where(runid[w_t1] eq calib_run[irun], nt1r)
        print, 'nscan URANUS = ', nt1r
        w = where(runid[w_b1] eq calib_run[irun], nn)
        if nn gt 0 then begin    
           atmtrans = exp(-tau_1mm[w_b1[w]]/sin(elev[w_b1[w]]))
           fr = flux_ratio_1mm[w_b1[w]]
           ;oplot,atmtrans, fr, psym=cgsymcat('FILLEDSQUARE', thick=1), col=col_tab[irun]    
           ;oplot,atmtrans, fr, psym=cgsymcat('OPENSQUARE', thick=1), col=0
           ;oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_1mm[w_b1[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------'
        endif
        
        ;; MWC349
        w = where(runid[w_t2] eq calib_run[irun], nt2r)
        print, 'nscan MWC349 = ', nt2r
        w = where(runid[w_b2] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_1mm[w_b2[w]]/sin(elev[w_b2[w]]))
           fr = flux_ratio_1mm[w_b2[w]]  
           ;;oplot, atmtrans, fr, psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
           oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_1mm[w_b2[w]], psym=cgsymcat('FILLEDCIRCLE', thick=1), col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------'
        endif
        
        ;; ALL
        w = where(runid eq calib_run[irun], nt)
        print, 'nscan all = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_1mm[w_baseline[w]]/sin(elev[w_baseline[w]]))
           fr = flux_ratio_1mm[w_baseline[w]]  
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           m = abs(mean(fr(whi))-mean(fr(wlow)))
           sig = sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)/sqrt(nhalf)
           diff = m/sig
           print, 'stab. est. = ', diff

           d(irun, 3) = m
           sd(irun,3) = sig
           nd(irun,3) = nhalf
           
           print, '-------------------------------------------------'
        endif
     endfor
     ;;
     legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.07]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     b13 = mean(flux_ratio_1mm[w_b2])
     s13 = sqrt((stddev(flux_ratio_1mm[w_b2])/b13)^2); + (stddev(flux_ratio_1mm[w_b1]))^2 )/sqrt(2.)
     oplot, [xmin,xmax], [1., 1.]+s13, col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-s13, col=0, linestyle=2
     
     xyouts, xmin+(xmax-xmin)*0.1, 1.27, 'A1&A3', col=0 
     
     outplot, /close

    ; stop
     
     ;; A1
     ;;----------------------------------------------------------
     print, ''
     print, ' A1 '
     print, '-----------------------'
     ymax = max( [1.3, max(flux_ratio_a1[w_b2] )]   )
     ymin = min( [0.7, min(flux_ratio_a1[w_b2])]   )
     xmax  = 1.00
     xmin  = 0.35
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_obstau'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        ;; URANUS
        w = where(runid[w_t1] eq calib_run[irun], nt1r)
        print, 'nscan URANUS = ', nt1r
        w = where(runid[w_b1] eq calib_run[irun], nn)
        if nn gt 0 then begin    
           atmtrans = exp(-tau_a1[w_b1[w]]/sin(elev[w_b1[w]]))
           fr = flux_ratio_a1[w_b1[w]]
           ;oplot,atmtrans, fr, psym=cgsymcat('FILLEDSQUARE', thick=2), col=col_tab[irun]    
           ;oplot,atmtrans, fr, psym=cgsymcat('OPENSQUARE', thick=2), col=0
           ;oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_a1[w_b1[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------' 
        endif

         ;; MWC349
        w = where(runid[w_t2] eq calib_run[irun], nt2r)
        print, 'nscan MWC349 = ', nt2r
        w = where(runid[w_b2] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_a1[w_b2[w]]/sin(elev[w_b2[w]]))
           fr = flux_ratio_a1[w_b2[w]]  
           oplot, atmtrans, fr, psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
           oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_a1[w_b2[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------'
        endif

        ;; ALL
        w = where(runid eq calib_run[irun], nt)
        print, 'nscan all = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_a1[w_baseline[w]]/sin(elev[w_baseline[w]]))
           fr = flux_ratio_a1[w_baseline[w]]  
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           m   = abs(mean(fr(whi))-mean(fr(wlow)))
           sig = sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)/sqrt(nhalf)
           diff = m/sig
           print, 'stab. est. = ', diff

           d(irun, 0) = m
           sd(irun,0) = sig
           nd(irun,0) = nhalf
           
           print, '-------------------------------------------------'
        endif
        
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0

     b1 = mean(flux_ratio_a1[w_b2])
     s1 = sqrt((stddev(flux_ratio_a1[w_b2])/b1)^2); + (stddev(flux_ratio_1mm[w_b1]))^2 )/sqrt(2.)
     oplot, [xmin,xmax], [1., 1.]+s1, col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-s1, col=0, linestyle=2
     
     
     xyouts, xmin+(xmax-xmin)*0.1, 1.27, 'A1', col=0
     
     outplot, /close
     
     ;stop
     
     ;; A3
     ;;----------------------------------------------------------
     print, ''
     print, ' A3 '
     print, '-----------------------'
     ymax = max( [1.3, max(flux_ratio_a3[w_b2] )]   )
     ymin = min( [0.7, min(flux_ratio_a3[w_b2])]   )
     xmax  = 1.0
     xmin  = 0.35

     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_obstau'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
       ;; URANUS
        w = where(runid[w_t1] eq calib_run[irun], nt1r)
        print, 'nscan URANUS = ', nt1r
        w = where(runid[w_b1] eq calib_run[irun], nn)
        if nn gt 0 then begin    
           atmtrans = exp(-tau_a3[w_b1[w]]/sin(elev[w_b1[w]]))
           fr = flux_ratio_a3[w_b1[w]]
           ;oplot,atmtrans, fr, psym=cgsymcat('FILLEDSQUARE', thick=2), col=col_tab[irun]
           ;oplot,atmtrans, fr, psym=cgsymcat('OPENSQUARE', thick=2), col=0
           ;oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_a3[w_b1[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------'
        endif

         ;; MWC349
        w = where(runid[w_t2] eq calib_run[irun], nt2r)
        print, 'nscan MWC349 = ', nt2r
        w = where(runid[w_b2] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_a3[w_b2[w]]/sin(elev[w_b2[w]]))
           fr = flux_ratio_a3[w_b2[w]]  
           oplot, atmtrans, fr, psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
           oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_a1[w_b2[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------'
        endif

        ;; ALL
        w = where(runid eq calib_run[irun], nt)
        print, 'nscan all = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_a3[w_baseline[w]]/sin(elev[w_baseline[w]]))
           fr = flux_ratio_a3[w_baseline[w]]  
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           m   = abs(mean(fr(whi))-mean(fr(wlow)))
           sig = sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)/sqrt(nhalf)
           diff = m/sig
           print, 'stab. est. = ', diff

           d(irun, 2) = m
           sd(irun,2) = sig
           nd(irun,2) = nhalf
           
           print, '-------------------------------------------------'
        endif
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0

     b3 = mean(flux_ratio_a3[w_b2])
     s3 = sqrt((stddev(flux_ratio_a3[w_b2])/b13)^2); + (stddev(flux_ratio_1mm[w_b1]))^2 )/sqrt(2.)
     oplot, [xmin,xmax], [1., 1.]+s3, col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-s3, col=0, linestyle=2
     
     
     xyouts, xmin+(xmax-xmin)*0.1, 1.27, 'A3', col=0
     
     outplot, /close

     ;stop
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'
     ymax = max( [1.3, max(flux_ratio_a2[w_b2] )]   )
     ymin = min( [0.7, min(flux_ratio_a2[w_b2])]   )
     xmax  = 1.00
     xmin  = 0.55
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_obstau'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        ;; URANUS
        w = where(runid[w_t1] eq calib_run[irun], nt1r)
        print, 'nscan URANUS = ', nt1r
        w = where(runid[w_b1] eq calib_run[irun], nn)
        if nn gt 0 then begin    
           atmtrans = exp(-tau_a2[w_b1[w]]/sin(elev[w_b1[w]]))
           fr = flux_ratio_a2[w_b1[w]]     
           ;oplot,atmtrans, fr, psym=cgsymcat('FILLEDSQUARE', thick=2), col=col_tab[irun]
           ;oplot,atmtrans, fr, psym=cgsymcat('OPENSQUARE', thick=2), col=0
           ;oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_a2[w_b1[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------' 
        endif

         ;; MWC349
        w = where(runid[w_t2] eq calib_run[irun], nt2r)
        print, 'nscan MWC349 = ', nt2r
        w = where(runid[w_b2] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_a2[w_b2[w]]/sin(elev[w_b2[w]]))
           fr = flux_ratio_a2[w_b2[w]]  
           oplot, atmtrans, fr, psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
           oploterror, atmtrans, fr, atmtrans*0, err_flux_ratio_a2[w_b2[w]], psym=3, col=col_tab[irun]
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(fr(whi))-mean(fr(wlow)))/sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)*sqrt(nhalf)
           print, 'stab. est. = ', diff
           print, '-------------------------------------------------'
        endif

        ;; ALL
        w = where(runid eq calib_run[irun], nt)
        print, 'nscan all = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then begin
           atmtrans = exp(-tau_a2[w_baseline[w]]/sin(elev[w_baseline[w]]))
           fr = flux_ratio_a2[w_baseline[w]]  
           print, 'selected nscan = ', nn
           print, 'bias = ', mean(fr)
           print, 'rel.rms = ', stddev(fr)*100.;/mean(fr)*100
           wlow = where( atmtrans lt median(atmtrans), nhalf, compl=whi)
           m   = abs(mean(fr(whi))-mean(fr(wlow)))
           sig = sqrt(stddev(fr(whi))^2 + stddev(fr(wlow))^2)/sqrt(nhalf)
           diff = m/sig
           print, 'stab. est. = ', diff

           d(irun, 1) = m
           sd(irun,1) = sig
           nd(irun,1) = nhalf
           
           print, '-------------------------------------------------'
        endif
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.03, ymax-0.03], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     
     b2 = mean(flux_ratio_a2[w_b2])
     s2 = sqrt((stddev(flux_ratio_a2[w_b2])/b2)^2); + (stddev(flux_ratio_1mm[w_b1]))^2 )/sqrt(2.)
     oplot, [xmin,xmax], [1., 1.]*b2+s2, col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]*b2-s2, col=0, linestyle=2
     
     xyouts, xmin+(xmax-xmin)*0.1, 1.27, 'A2', col=0
     
     outplot, /close
     

     print, '____________________________________________'
     print, ''
     print, 'Combined'
     print, 'total nscan = ',    nscans
     print, 'selected nscan = ', n_elements(w_baseline)

     atmtrans1 = exp(-tau_a1[w_baseline]/sin(elev[w_baseline]))
     fr1 = flux_ratio_a1[w_baseline]
     atmtrans3 = exp(-tau_a3[w_baseline]/sin(elev[w_baseline]))
     fr3 = flux_ratio_a3[w_baseline]  
     atmtrans1mm = exp(-tau_1mm[w_baseline]/sin(elev[w_baseline]))
     fr1mm = flux_ratio_1mm[w_baseline]
     atmtrans2 = exp(-tau_a2[w_baseline]/sin(elev[w_baseline]))
     fr2 = flux_ratio_a2[w_baseline]
     print, ''
     print, 'BIAS ON MWC349'
     print, ''
     b1  = mean(flux_ratio_a1[w_b2])
     b3  = mean(flux_ratio_a3[w_b2])
     b13 = mean(flux_ratio_1mm[w_b2])
     b2  = mean(flux_ratio_a2[w_b2])
     print, 'A1 bias = ', b1
     print, 'A3 bias = ', b3 
     print, '1mm bias = ', b13
     print, 'A2 bias = ', b2
     print, ''
     print, 'REL. RMS ON MWC349+URANUS'
     print, ''
     s1  = sqrt((stddev(flux_ratio_a1[w_b2])/b1)^2 + (stddev(flux_ratio_a1[w_b1]))^2 )*100./sqrt(2.)
     s3  = sqrt((stddev(flux_ratio_a3[w_b2])/b3)^2 + (stddev(flux_ratio_a3[w_b1]))^2 )*100./sqrt(2.)
     s13 = sqrt((stddev(flux_ratio_1mm[w_b2])/b13)^2 + (stddev(flux_ratio_1mm[w_b1]))^2 )*100./sqrt(2.)
     s2  = sqrt((stddev(flux_ratio_a2[w_b2])/b2)^2 + (stddev(flux_ratio_a2[w_b1]))^2 )*100./sqrt(2.)
     print, 'A1 rel.rms = ',  s1;stddev(fr1)*100.;/mean(fr1)*100
     print, 'A3 rel.rms = ',  s3;stddev(fr3)*100.;/mean(fr3)*100
     print, '1mm rel.rms = ', s13;stddev(fr1mm)*100.;/mean(fr1mm)*100
     print, 'A2 rel.rms = ',  s2;stddev(fr2)*100.;/mean(fr2)*100

     print, ''
     print, 'STABILITY'
     print, ''

     diff1 = total(d(*,0)/sd(*, 0)^2)/total(1./sd(*, 0))
     diff1 = total(d(*,0)/sd(*, 0)*nd(*,0))/total(nd(*, 0))
     diff2 = total(d(*,1)/sd(*, 1)*nd(*,1))/total(nd(*, 1))
     diff3 = total(d(*,2)/sd(*, 2)*nd(*,2))/total(nd(*, 2))
     diff13 = total(d(*,3)/sd(*, 3)*nd(*,3))/total(nd(*, 3))
     print, 'A1 stab. est. = ', diff1
     print, 'A3 stab. est. = ', diff3
     print, '1mm stab. est. = ', diff13
     print, 'A2 stab. est. = ', diff2
     print, ''
     print, 'N2R9 only'
     print, 'A1 stab. est. = ', d(0, 0)/sd(0, 0)
     print, 'A3 stab. est. = ', d(0, 2)/sd(0, 2)
     print, '1mm stab. est. = ',d(0, 3)/sd(0, 3)
     print, 'A2 stab. est. = ', d(0, 1)/sd(0, 1)
     
     stop

  endif



  
  ;;
  ;;   PLOT 3 SOURCES: FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     col_tab = [col_mwc349, col_crl2688, col_ngc7027]
     
     w_baseline = where(index_baseline gt 0, n_baseline)

     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[w_baseline] )+0.02 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_baseline])-0.02]   )
     xmax  = 0.8
     xmin  = 0.     
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_obstau_secondary_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, tau_1mm/sin(elev), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata

     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_1mm[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_1mm[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
  
     ;;
     legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.10]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, 0.68, ymax-0.05, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[w_baseline] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_baseline])-0.02]   )
     xmax  = 0.8
     xmin  = 0.
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_obstau_secondary_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, tau_a1/sin(elev), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_a1[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_a1[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.10], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, 0.7, ymax-0.05, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[w_baseline] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_baseline])-0.02]   )
     xmax  = 0.8
     xmin  = 0.

     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_obstau_secondary_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, tau_a3/sin(elev), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, tau_a3[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_a3[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.10], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, 0.7, ymax-0.05, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[w_baseline] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_baseline])-0.02]   )
     xmax  = 0.5
     xmin  = 0.
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_obstau_secondary_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, h_tau_a2/sin(elev), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, h_tau_a2[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_a2[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.03, ymax-0.05], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, 0.45, ymax-0.05, 'A2', col=0
     
     outplot, /close
     
     
     

     
     stop

  endif
  
  ;;
  ;;   PLOT 3 SOURCES: FLUX RATIO AGAINST FWHM
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(fwhm_stability) then begin
     
     col_tab = [col_mwc349, col_crl2688, col_ngc7027]
     
     w_baseline = where(index_baseline gt 0, n_baseline)

     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[w_baseline] )+0.02 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_baseline])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8     
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_FWHM_secondary_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, fwhm_1mm, flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata

     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_1mm[w_baseline[w]], flux_ratio_1mm[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
  
     ;;
     legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1., pos=[xmax-(xmax-xmin)*0.25, ymin+0.10]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmax-0.5, ymax-0.05, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[w_baseline] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_baseline])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_FWHM_secondary_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, fwhm_a1, flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a1[w_baseline[w]], flux_ratio_a1[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=1., pos=[xmin+0.2, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[w_baseline] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_baseline])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8

     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_FWHM_secondary_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, fwhm_a3, flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a3[w_baseline[w]], flux_ratio_a3[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=1., pos=[xmin+0.2, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[w_baseline] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_baseline])-0.02]   )
     xmax  = 19.5
     xmin  = 17.2
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = outdir+'plot_flux_density_ratio_3sources_FWHM_secondary_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, fwhm_a2, flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj[w_baseline] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a2[w_baseline[w]], flux_ratio_a2[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[isou]
     endfor
     ;;
     legendastro, sources, col=col_tab, textcol=0, box=0, charsize=1., pos=[xmin+0.2, ymax-0.05], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A2', col=0
     
     outplot, /close
     
     
     

     
     stop

  endif

  
  stop
  
     

end
