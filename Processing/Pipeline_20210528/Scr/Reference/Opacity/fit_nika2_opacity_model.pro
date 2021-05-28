
;;
;;  FIT NIKA2 OPACITY MODEL
;;
;;   use output files from baseline_calibration_v2_outputfile
;;   if 'nika2c' is set, use the all-scan-result file avail. on nika2-c
;;
;;   LP, August 2018
;;_______________________________________________________________


pro fit_nika2_opacity_model, png=png, ps=ps, pdf=pdf, nika2c=nika2c, alamain=alamain
                                     
  
  calib_run   = 'N2R9'
  nrun = 1

  ;; methode de correction d'opacite
  ;;
  ;; -- if corrected_skydip_based = 1: fit of the NIKA2 skydip to
  ;; corrected skydip opacity relation
  ;;  -- if flux_driven_taumeter_based = 1: fit of the IRAM 225GHz taumeter to
  ;; NIKA2 opacity relation
  ;;---------------------------------------------
  corrected_skydip_based       = 0
  flux_driven_taumeter_based   = 1
  
  skydip_driven_taumeter_based = 0 ;; not implemented

  
  sources = ['MWC349', 'CRL2688', 'NGC7027']
  ;sources = ['Uranus', 'MWC349']
  ;sources = ['MWC349']
  ;sources = ['CRL2688']
  nsource = 1

  ;; number of parameters of the skydip opacity relation to be fitted
  n_parameters = 1

  
  ;; Automatic plot suffixe
  ;;--------------------------------------------------------------
  ;; plot files are fit_nika2_tau+'plot_suffixe'
  if corrected_skydip_based gt 0 then $
     plot_suffixe = '_from_skydip' else if flux_driven_taumeter_based gt 0 then $
        plot_suffixe = '_from_taumeter' else print, 'UNKNOWN BASE OPACITY DATA'
  
  if nsource eq 1 then $
     plot_suffixe = plot_suffixe+'_mwc349' else if nsource gt 1 then $
        plot_suffixe = plot_suffixe+'_multisources'
 
  
  ;; outplot directory
  outplot_dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/Opacity_correction_tests/'

  nostop=1
  
  ;; plot aspect
  ;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 550.
  wysize = 400.
  ;; plot size in files
  pxsize = 11.
  pysize =  8.
  ;; charsize
  charsize  = 1.4
  charthick = 3.0 ;0.7
  thick     = 4.0
  symsize   = 0.7
  
  ;;________________________________________________________________
  ;;
  ;; get all result files
  ;;________________________________________________________________
  ;; result files as produced using
  ;; baseline_calibration_reference_outfile.pro
  ;;________________________________________________________________

  if keyword_set(nika2c) then begin
     outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
     get_all_scan_result_files_v2, result_files, outputdir = outdir
  endif else begin   
     result_files = strarr(nrun, nsource)
     for irun = 0, nrun-1 do begin
        runname = calib_run[irun]
        dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/'
        for isou = 0, nsource-1 do result_files[irun, isou] = dir+sources[isou]+'_allinfo_'+runname+'_baseline_v2.save'
     endfor
  endelse
  
  
  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  
  irun = 0   
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

  if keyword_set(nika2c) then begin
     restore, allresult_file, /v
     ;; allscan_info
          
     ;; select scans for the desired sources
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
     
  endif else begin
     restore, allresult_file[0], /v
     res = allscan_info
     if nsource gt 1 then begin
        for isou=1, nsource-1 do begin
           restore, allresult_file[isou], /v
           res = [res, allscan_info]
        endfor
     endif
     allscan_info = res
     delvar, res
  endelse
 
  ;; remove known outliers
  ;;____________________________________________________________
  ;;scan_list_ori = strtrim(string(allscan_info.day, format='(i8)'), 2)+"s"+$
  ;;                strtrim( string(allscan_info.scan_num, format='(i8)'),2)
  scan_list_ori = allscan_info.scan
  
  outlier_list =  ['20170223s16', $     ; dark test
                   '20170223s17', $     ; dark test
                   '20171024s171', $    ; focus scan
                   '20171026s235', $    ; focus scan
                   '20171028s313', $    ; RAS from tapas
                   '20180114s73', $     ; TBC
                   '20180116s94', $     ; focus scan
                   '20180118s212', $    ; focus scan
                   '20180119s241', $    ; Tapas comment: 'out of focus'
                   '20180119s242', $    ; Tapas comment: 'out of focus'
                   '20180119s243', $    ; Tapas comment: 'out of focus'   '20180122s98', $
                   '20180122s118', '20180122s119', '20180122s120', '20180122s121'] ;; the telescope has been heated
  
  out_index = 1
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list, out_index=out_index
  allscan_info = allscan_info[out_index]
  
  nscans = n_elements(scan_list)
  print, "scan list: "
  help, scan_list
  
  if nostop lt 1 then stop
  
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
  scan_selection, allscan_info, wbaseline, $
                  to_use_photocorr=to_use_photocorr, complement_index=wout, $
                  beamok_index = beamok_index, largebeam_index = wlargebeam,$
                  tauok_index = tauok_index, hightau_index=whitau3, $
                  osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                  fwhm_max = fwhm_max, nefd_index = nefd_index
 
  ;; implement the selection
  allscan_info = allscan_info[wbaseline]
  scan_list    = scan_list[wbaseline]
  nscans = n_elements(scan_list)
  print, "baseline selection, nscans = ", nscans
  
    
  ;;
  ;; FLUX DENSITY EXPECTATIONS
  ;;____________________________________________________________
  th_flux_1mm = dblarr(nscans)
  th_flux_a2  = dblarr(nscans)
  th_flux_a1  = dblarr(nscans)
  th_flux_a3  = dblarr(nscans)
  
  ;; URANUS
  ;;------------------------------
  wu = where(strupcase(allscan_info.object) eq 'URANUS', nuranus)
  for iu=0, nuranus-1 do begin
     i = wu[iu]
     nk_scan2run, scan_list[i], run
     th_flux_1mm[i]     = !nika.flux_uranus[0]
     th_flux_a2[i]      = !nika.flux_uranus[1]
     th_flux_a1[i]      = !nika.flux_uranus[0]
     th_flux_a3[i]      = !nika.flux_uranus[2]
  endfor
  ;; MWC349
  ;;------------------------------
  wsou = where(strupcase(allscan_info.object) eq 'MWC349', nscan_sou)
  lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
  nu = !const.c/(lambda*1e-3)/1.0d9
  th_flux           = 1.16d0*(nu/100.0)^0.60
  ;; assuming indep param
  err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
  th_flux_1mm[wsou]     = th_flux[0]
  th_flux_a2[wsou]      = th_flux[1]
  th_flux_a1[wsou]      = th_flux[0]
  th_flux_a3[wsou]      = th_flux[2]
  
  ;; get tau225
  tau225 = dblarr(nscans)
  opa_file = !nika.pipeline_dir+'/Datamanage/Tau225/results_opacity_tau225interp_'+strupcase(runname)+'.fits'
  opa = mrdfits(opa_file, 1)
  scan_list_opa = strtrim(opa.day,2)+'s'+strtrim(opa.scannum,2)
  my_match, scan_list_opa, scan_list, suba, subb
  tau225[subb] = opa[suba].tau225_medfilt


  sinel = sin(allscan_info.result_elevation_deg*!dtor)
  
  ;;============================================================
  ;;
  ;;     FIT
  ;;
  ;;===========================================================

  ;; ATM : tau_1mm = 1.2417*tau225 -0.000250053
  ;; ATM : tau_2mm = 0.5148*tau225 + 0.0215

  ntest = 201 ;; impair

  ;; PARAM LIMITS
  amin = 1.0d0
  amax = 1.0d0
  bmin = 0.0d0
  bmax = 0.0d0
  
  ;; 1mm
  if flux_driven_taumeter_based gt 0 then begin
     amin = 1.0d0
     amax = 3.0d0
     if n_parameters eq 1 then begin
        bmin = -0.00001
        bmax = 0.00001
        nparams = 1
     endif else if n_parameters eq 2 then begin
        bmin = -0.5
        bmax =  0.5
        nparams = 2
     endif
  endif

  if corrected_skydip_based gt 0 then begin
     amin = 0.5d0
     amax = 2.0d0
     if n_parameters eq 1 then begin
        bmin = -0.00001
        bmax = 0.00001
        nparams = 1
     endif else if n_parameters eq 2 then begin
        bmin = -0.5
        bmax =  0.5
        nparams=2
     endif else print, "the skydip relation has 2 parameters max"
  endif
  
  a1 = amin + dindgen(ntest)*(amax-amin)/(ntest-1d0) 
  b1 = bmin + dindgen(ntest)*(bmax-bmin)/(ntest-1d0) 

  ;; 2mm
  if flux_driven_taumeter_based gt 0 then begin
     amin = 0.1d0
     amax = 2.0d0
     if n_parameters eq 1 then begin
        bmin = -0.00001
        bmax = 0.00001
     endif else if n_parameters eq 2 then begin
        bmin = -0.5
        bmax =  0.5
     endif
  endif
  if corrected_skydip_based gt 0 then begin
     amin = 0.5d0
     amax = 1.6d0
     if n_parameters eq 1 then begin
        bmin = -0.00001
        bmax = 0.00001
     endif else if n_parameters eq 2 then begin
        bmin = -0.5
        bmax =  0.5
     endif 
  endif
  
  a2 = amin + dindgen(ntest)*(amax-amin)/(ntest-1d0) 
  b2 = bmin + dindgen(ntest)*(bmax-bmin)/(ntest-1d0) 

  un =replicate(1.0d0, ntest)

  a = dblarr(ntest, ntest, 4)
  a[*, *, 0] = a1#un
  a[*, *, 1] = a2#un
  a[*, *, 2] = a1#un
  a[*, *, 3] = a1#un
  b = dblarr(ntest, ntest, 4)
  b[*, *, 0] = b1##un
  b[*, *, 1] = b2##un
  b[*, *, 2] = b1##un
  b[*, *, 3] = b1##un

  
  ;; rms 
  est1 = dblarr(ntest, ntest, 4)
  ;; half-scan diff 
  est2 = dblarr(ntest, ntest, 4)
  ;; chi2 par bin
  est3 = dblarr(ntest, ntest, 4)
  est4 = dblarr(ntest, ntest, 4)
  est5 = dblarr(ntest, ntest, 4)
  ;; chi2 (no bin)
  est6 = dblarr(ntest, ntest, 4)


  ;; USING MWC349 ONLY
  ;;w = where(allscan_info.object eq 'MWC349', nn)
  ;;flux_ratio = dblarr(nn, 4)
  ;;tau_nika   = dblarr(nn, 4)
  ;;info = allscan_info[w]

  ;; ALL SOURCES
  flux_ratio = dblarr(nscans, 4)
  tau_nika   = dblarr(nscans, 4)
  medflux    = dblarr(nscans, 4)
  info       = allscan_info

  
  ;atmtrans_a3 = exp(-info.result_tau_3/sinel[w])
  ;wlow = where( atmtrans_a3 lt median(atmtrans_a3), nhalf, compl=whi)
  atmtrans_225 = exp(-tau225/sinel)
  wlow = where( atmtrans_225 lt median(atmtrans_225), nhalf, compl=whi)

  
  indtrans = sort(atmtrans_225)
  
  nbin1 = 2.
  bin_flux_ratio1     = dblarr(nbin1, 4)
  bin_err_flux_ratio1 = dblarr(nbin1, 4)
  bin_ratio_model1    = dblarr(nbin1, 4)
  
  nbin2 = 4.
  bin_flux_ratio2     = dblarr(nbin2, 4)
  bin_err_flux_ratio2 = dblarr(nbin2, 4)
  bin_ratio_model2    = dblarr(nbin2, 4)
  
  nbin3 = 6.
  bin_flux_ratio3     = dblarr(nbin3, 4)
  bin_err_flux_ratio3 = dblarr(nbin3, 4)
  bin_ratio_model3    = dblarr(nbin3, 4)

  
  ;; TAU MODEL
  tau_model = dblarr(nscans, 4) 
  if corrected_skydip_based gt 0 then begin
     tau_model[*, 0] = info.result_tau_1
     tau_model[*, 1] = info.result_tau_2
     tau_model[*, 2] = info.result_tau_3
     tau_model[*, 3] = info.result_tau_1mm
  endif
  if flux_driven_taumeter_based gt 0 then begin
     for iarr=0, 3 do tau_model[*, iarr] = tau225
  endif
  
  ;;==========================================================================
  ;;==========================================================================
  if keyword_set(alamain) then begin
     
     ;; TAU SKYDIP
     tau_sky = dblarr(nscans, 4) 
     tau_sky[*, 0] = info.result_tau_1
     tau_sky[*, 1] = info.result_tau_2
     tau_sky[*, 2] = info.result_tau_3
     tau_sky[*, 3] = info.result_tau_1mm
     
     tau_225 = dblarr(nscans, 4)
     for iarr=0, 3 do tau_225[*, iarr] = tau225
     
     ;; test à la main
     ;;-------------------------------------------------------------------------
     if corrected_skydip_based gt 0 then begin
        a0 = [1.0d0, 1.0d0, 1.0d0, 1.0d0 ]
        b0 = [0.0d0, 0.0d0, 0.0d0, 0.0d0 ]
     endif
     if flux_driven_taumeter_based gt 0 then begin
        a0 = [1.26d0,   0.515d0, 1.27d0, 1.265d0 ]
        b0 = [-0.00025, 0.02,  -0.00025, -0.00025]
     endif
     
     ;; no correction : tau225 + ATM
     ;;------------------------------------------
     tau_225atm = dblarr(nscans, 4)
     tau_225atm[*, 0] = tau_225[*, 0]*a0[0] + b0[0]
     tau_225atm[*, 1] = tau_225[*, 1]*a0[1] + b0[1]
     tau_225atm[*, 2] = tau_225[*, 2]*a0[2] + b0[2]
     tau_225atm[*, 3] = tau_225[*, 3]*a0[3] + b0[3]
     
     medflux[*,3] = median(info[*].result_flux_i_1mm*exp((tau_225atm[*,3]-info[*].result_tau_1mm)/sinel[*]))
     medflux[*,0] = median(info[*].result_flux_i1*exp((tau_225atm[*,0]-info[*].result_tau_1)/sinel[*]))
     medflux[*,1] = median(info[*].result_flux_i2*exp((tau_225atm[*,1]-info[*].result_tau_2)/sinel[*]))
     medflux[*,2] = median(info[*].result_flux_i3*exp((tau_225atm[*,2]-info[*].result_tau_3)/sinel[*]))

     flux_ratio_atm = dblarr(nscans, 4)
     flux_ratio_atm[*, 3] = info.result_flux_i_1mm*exp((tau_225atm[*,3]-info.result_tau_1mm)/sinel)/medflux[*,3] ;/th_flux_1mm[w]
     flux_ratio_atm[*, 0] = info.result_flux_i1   *exp((tau_225atm[*,0]-info.result_tau_1)/sinel)/medflux[*,0] ;/th_flux_a1[w]
     flux_ratio_atm[*, 1] = info.result_flux_i2   *exp((tau_225atm[*,1]-info.result_tau_2)/sinel)/medflux[*,1] ;/th_flux_a2[w]
     flux_ratio_atm[*, 2] = info.result_flux_i3   *exp((tau_225atm[*,2]-info.result_tau_3)/sinel)/medflux[*,2] ;/th_flux_a3[w]
     
     ;; no correction skydip
     ;;-------------------------------------------------------
     medflux[*,3] = median(info[*].result_flux_i_1mm)
     medflux[*,0] = median(info[*].result_flux_i1)
     medflux[*,1] = median(info[*].result_flux_i2)
     medflux[*,2] = median(info[*].result_flux_i3)
     
     flux_ratio_sky = dblarr(nscans, 4)
     flux_ratio_sky[*, 3] = info[*].result_flux_i_1mm/medflux[*,3] ;/th_flux_1mm[w]
     flux_ratio_sky[*, 0] = info[*].result_flux_i1/medflux[*,0]    ;/th_flux_a1[w]
     flux_ratio_sky[*, 1] = info[*].result_flux_i2/medflux[*,1]    ;/th_flux_a2[w]
     flux_ratio_sky[*, 2] = info[*].result_flux_i3/medflux[*,2]    ;/th_flux_a3[w]
     
     ;; (tau225 + ATM) with correction 
     ;;-------------------------------------------------------
     tau_225_nika   = dblarr(nscans, 4)
     tau_225_nika[*, 0] = tau_225[*, 0]*a0[0]*1.5 + b0[0]
     tau_225_nika[*, 1] = tau_225[*, 1]*a0[1]*1.7 + b0[1]
     tau_225_nika[*, 2] = tau_225[*, 2]*a0[2]*1.5 + b0[2]
     tau_225_nika[*, 3] = tau_225[*, 3]*a0[3]*1.5 + b0[3]
     
     medflux[*,3] = median(info[*].result_flux_i_1mm*exp((tau_225_nika[*,3]-info[*].result_tau_1mm)/sinel[*]))
     medflux[*,0] = median(info[*].result_flux_i1*exp((tau_225_nika[*,0]-info[*].result_tau_1)/sinel[*]))
     medflux[*,1] = median(info[*].result_flux_i2*exp((tau_225_nika[*,1]-info[*].result_tau_2)/sinel[*]))
     medflux[*,2] = median(info[*].result_flux_i3*exp((tau_225_nika[*,2]-info[*].result_tau_3)/sinel[*]))
     
     flux_ratio_225_nika = dblarr(nscans, 4)
     flux_ratio_225_nika[*, 3] = info.result_flux_i_1mm*exp((tau_225_nika[*,3]-info.result_tau_1mm)/sinel)/medflux[*,3] ;/th_flux_1mm[w]
     flux_ratio_225_nika[*, 0] = info.result_flux_i1   *exp((tau_225_nika[*,0]-info.result_tau_1)/sinel)/medflux[*,0] ;/th_flux_a1[w]
     flux_ratio_225_nika[*, 1] = info.result_flux_i2   *exp((tau_225_nika[*,1]-info.result_tau_2)/sinel)/medflux[*,1] ;/th_flux_a2[w]
     flux_ratio_225_nika[*, 2] = info.result_flux_i3   *exp((tau_225_nika[*,2]-info.result_tau_3)/sinel)/medflux[*,2] ;/th_flux_a3[w]
  
     ;; skydip with correction
     flux_ratio_sky_c = dblarr(nscans, 4)
     tau_sky_c   = dblarr(nscans, 4)
     tau_sky_c[*, 0] = tau_sky[*, 0]*1.3
     tau_sky_c[*, 1] = tau_sky[*, 1]*1.0
     tau_sky_c[*, 2] = tau_sky[*, 2]*1.3
     tau_sky_c[*, 3] = tau_sky[*, 3]*1.3
     
     medflux[*,3] = median(info[*].result_flux_i_1mm*exp((tau_sky_c[*,3]-info[*].result_tau_1mm)/sinel[*]))
     medflux[*,0] = median(info[*].result_flux_i1*exp((tau_sky_c[*,0]-info[*].result_tau_1)/sinel[*]))
     medflux[*,1] = median(info[*].result_flux_i2*exp((tau_sky_c[*,1]-info[*].result_tau_2)/sinel[*]))
     medflux[*,2] = median(info[*].result_flux_i3*exp((tau_sky_c[*,2]-info[*].result_tau_3)/sinel[*]))
     
     flux_ratio_sky_c[*, 3] = info.result_flux_i_1mm*exp((tau_sky_c[*,3]-info.result_tau_1mm)/sinel)/medflux[*,3] ;/th_flux_1mm[w]
     flux_ratio_sky_c[*, 0] = info.result_flux_i1   *exp((tau_sky_c[*,0]-info.result_tau_1)/sinel)/medflux[*,0] ;/th_flux_a1[w]
     flux_ratio_sky_c[*, 1] = info.result_flux_i2   *exp((tau_sky_c[*,1]-info.result_tau_2)/sinel)/medflux[*,1] ;/th_flux_a2[w]
     flux_ratio_sky_c[*, 2] = info.result_flux_i3   *exp((tau_sky_c[*,2]-info.result_tau_3)/sinel)/medflux[*,2] ;/th_flux_a3[w] 

     ii = 3
     wind, 1, 1, /free, xsize=700, ysize=550
     plot, exp(-tau_225atm[*, ii]/sinel), flux_ratio_atm[*, ii], psym=1, yr=[0.6, 1.4], /ys, /xs, /nodata, xtitle='atmospheric transmission', ytitle='Flux ratio'
     oplot, exp(-tau_225atm[*, ii]/sinel), flux_ratio_atm[*, ii], psym=1, col=10
     oplot, exp(-tau_225atm[*, ii]/sinel), flux_ratio_sky[*, ii], psym=1, col=180
     
     oplot, exp(-tau_225atm[*, ii]/sinel), flux_ratio_225_nika[*, ii], psym=1, col=40
     oplot, exp(-tau_225atm[*, ii]/sinel), flux_ratio_sky_c[*, ii], psym=1, col=140
     
     legendastro, ['tau225+ATM', 'skydip', 'tau225+nika', 'corrected skydip'], col=[10,180,40,140], textcol=[10,180,40,140], box=0, pos=[0.55,1.3], charsize=1
     
     stop

     ii=3
     x = lindgen(100)/100.
     wind, 1, 1, /free, xsize=700, ysize=550
     plot, exp(-tau_225_nika[*, ii]/sinel), exp(-tau_sky_c[*, ii]/sinel), psym=1, /ys, /xs, /nodata, xtitle='atmospheric transmission from tau225', ytitle='atmospheric transmission from corrected skydip', xr=[0.3, 0.9], yr=[0.3, 0.9]
     oplot, exp(-tau_225_nika[*, ii]/sinel), exp(-tau_sky_c[*, ii]/sinel), psym=1, col=10
     oplot, exp(-tau_225atm[*, ii]/sinel), exp(-tau_sky[*, ii]/sinel), psym=1, col=90
     oplot, x, x, col=150
     ;;legendastro, '2mm', col=0, textcol=0, box=0, pos=[0.64,0.85], charsize=1.5
     
     x = lindgen(100)/100.
     wind, 1, 1, /free, xsize=700, ysize=550
     plot, tau_225_nika[*, ii], tau_sky_c[*, ii], psym=1, /ys, /xs, /nodata, xtitle='Opacity from tau225', ytitle='Opacity from corrected skydip', xr=[0, 0.75], yr=[0, 0.75]
     oplot, tau_225_nika[*, ii], tau_sky_c[*, ii], psym=1, col=10
     oplot, tau_225atm[*, ii], tau_sky[*, ii], psym=1, col=90
     oplot, x, x, col=150
     legendastro, '1mm', col=0, textcol=0, box=0, pos=[0.1,0.65], charsize=1.5

     

     
     stop
  endif
  ;;==========================================================================
  ;;==========================================================================
  
  for ia = 0, ntest-1 do begin
     for ib = 0, ntest-1 do begin

        tau_nika[*, 0] = tau_model[*, 0]*a[ia, ib, 0] + b[ia, ib, 0]
        tau_nika[*, 1] = tau_model[*, 1]*a[ia, ib, 1] + b[ia, ib, 1]
        tau_nika[*, 2] = tau_model[*, 2]*a[ia, ib, 2] + b[ia, ib, 2]
        tau_nika[*, 3] = tau_model[*, 3]*a[ia, ib, 3] + b[ia, ib, 3]

        ;; test
        ;;tau_nika = [[info.result_tau_1], [info.result_tau_2], [info.result_tau_3], [info.result_tau_1mm]]

        ;; w = where source
        for isou = 0, nsource-1 do begin
           w = where(strupcase(allscan_info.object) eq strupcase(sources[isou]), nn)
           medflux[w,3] = median(info[w].result_flux_i_1mm*exp((tau_nika[w,3]-info[w].result_tau_1mm)/sinel[w]))
           medflux[w,0] = median(info[w].result_flux_i1*exp((tau_nika[w,0]-info[w].result_tau_1)/sinel[w]))
           medflux[w,1] = median(info[w].result_flux_i2*exp((tau_nika[w,1]-info[w].result_tau_2)/sinel[w]))
           medflux[w,2] = median(info[w].result_flux_i3*exp((tau_nika[w,2]-info[w].result_tau_3)/sinel[w]))
        endfor
        
        flux_ratio[*, 3] = info.result_flux_i_1mm*exp((tau_nika[*,3]-info.result_tau_1mm)/sinel)/medflux[*,3];/th_flux_1mm[w]
        flux_ratio[*, 0] = info.result_flux_i1   *exp((tau_nika[*,0]-info.result_tau_1)/sinel)/medflux[*,0];/th_flux_a1[w]
        flux_ratio[*, 1] = info.result_flux_i2   *exp((tau_nika[*,1]-info.result_tau_2)/sinel)/medflux[*,1];/th_flux_a2[w]
        flux_ratio[*, 2] = info.result_flux_i3   *exp((tau_nika[*,2]-info.result_tau_3)/sinel)/medflux[*,2];/th_flux_a3[w] 
              
        ;; est1: rms of the flux ratio
        est1[ia, ib, 0] = stddev(flux_ratio[*, 0])*100.
        est1[ia, ib, 1] = stddev(flux_ratio[*, 1])*100.
        est1[ia, ib, 2] = stddev(flux_ratio[*, 2])*100.
        est1[ia, ib, 3] = stddev(flux_ratio[*, 3])*100.

       
        ;; est2: half-scan difference in unit of sigma
        est2[ia, ib, 0] = abs(mean(flux_ratio(whi,0))-mean(flux_ratio(wlow, 0)))/sqrt(stddev(flux_ratio(whi, 0))^2 + stddev(flux_ratio(wlow, 0))^2)*sqrt(nhalf)
        est2[ia, ib, 1] = abs(mean(flux_ratio(whi,1))-mean(flux_ratio(wlow, 1)))/sqrt(stddev(flux_ratio(whi, 1))^2 + stddev(flux_ratio(wlow, 1))^2)*sqrt(nhalf)
        est2[ia, ib, 2] = abs(mean(flux_ratio(whi,2))-mean(flux_ratio(wlow, 2)))/sqrt(stddev(flux_ratio(whi, 2))^2 + stddev(flux_ratio(wlow, 2))^2)*sqrt(nhalf)
        est2[ia, ib, 3] = abs(mean(flux_ratio(whi,3))-mean(flux_ratio(wlow, 3)))/sqrt(stddev(flux_ratio(whi, 3))^2 + stddev(flux_ratio(wlow, 3))^2)*sqrt(nhalf)

        
        ;; chi2 par bin
        trans_bin1 = dblarr(nbin1)
        for ibin =0, nbin1-1 do begin
           
           it = indgen(nscans/nbin1)+ (nscans/nbin1)*ibin
           ind  = indtrans[it]
           
           ;;trans_bin1[ibin] = mean( exp(-tau225[w[ind]]/sinel[w[ind]]) ) 
           trans_bin1[ibin] = mean( exp(-tau225[ind]/sinel[ind]) )
           
           bin_flux_ratio1[ibin, 3] = mean(flux_ratio[ind, 3])
           bin_flux_ratio1[ibin, 0] = mean(flux_ratio[ind, 0])
           bin_flux_ratio1[ibin, 1] = mean(flux_ratio[ind, 1])
           bin_flux_ratio1[ibin, 2] = mean(flux_ratio[ind, 2])
           ;;
           bin_err_flux_ratio1[ibin, 3] = stddev(flux_ratio[ind, 3])
           bin_err_flux_ratio1[ibin, 0] = stddev(flux_ratio[ind, 0])
           bin_err_flux_ratio1[ibin, 1] = stddev(flux_ratio[ind, 1])
           bin_err_flux_ratio1[ibin, 2] = stddev(flux_ratio[ind, 2])
           ;;
           bin_ratio_model1[ibin, 3] = 1.0d0
           bin_ratio_model1[ibin, 0] = 1.0d0 
           bin_ratio_model1[ibin, 1] = 1.0d0 
           bin_ratio_model1[ibin, 2] = 1.0d0 
           
        endfor
        for iarr = 0, 3 do est3[ia, ib, iarr] = total( ( bin_flux_ratio1[*, iarr] -  bin_ratio_model1[*, iarr])^2);/bin_err_flux_ratio1[*, iarr]^2)
        
        trans_bin2 = dblarr(nbin2)
        for ibin =0, nbin2-1 do begin
           
           it = indgen(nscans/nbin2)+ (nscans/nbin2)*ibin
           ind  = indtrans[it]
           
           ;;trans_bin2[ibin] = mean( exp(-tau225[w[ind]]/sinel[w[ind]]) ) 
           trans_bin2[ibin] = mean( exp(-tau225[ind]/sinel[ind]) )
           
           bin_flux_ratio2[ibin, 3] = mean(flux_ratio[ind, 3])
           bin_flux_ratio2[ibin, 0] = mean(flux_ratio[ind, 0])
           bin_flux_ratio2[ibin, 1] = mean(flux_ratio[ind, 1])
           bin_flux_ratio2[ibin, 2] = mean(flux_ratio[ind, 2])
           ;;
           bin_err_flux_ratio2[ibin, 3] = stddev(flux_ratio[ind, 3])
           bin_err_flux_ratio2[ibin, 0] = stddev(flux_ratio[ind, 0])
           bin_err_flux_ratio2[ibin, 1] = stddev(flux_ratio[ind, 1])
           bin_err_flux_ratio2[ibin, 2] = stddev(flux_ratio[ind, 2])
           ;;
           bin_ratio_model2[ibin, 3] = 1.0d0
           bin_ratio_model2[ibin, 0] = 1.0d0 
           bin_ratio_model2[ibin, 1] = 1.0d0 
           bin_ratio_model2[ibin, 2] = 1.0d0 
           
        endfor
        for iarr = 0, 3 do est4[ia, ib, iarr] = total( ( bin_flux_ratio2[*, iarr] -  bin_ratio_model2[*, iarr])^2) ;/bin_err_flux_ratio2[*, iarr]^2)
        
        trans_bin3 = dblarr(nbin3)
        for ibin =0, nbin3-1 do begin
           
           it = indgen(nscans/nbin3)+ (nscans/nbin3)*ibin
           ind  = indtrans[it]
           
           ;;trans_bin3[ibin] = mean( exp(-tau225[w[ind]]/sinel[w[ind]]) ) 
           trans_bin3[ibin] = mean( exp(-tau225[ind]/sinel[ind]) )
           
           bin_flux_ratio3[ibin, 3] = mean(flux_ratio[ind, 3])
           bin_flux_ratio3[ibin, 0] = mean(flux_ratio[ind, 0])
           bin_flux_ratio3[ibin, 1] = mean(flux_ratio[ind, 1])
           bin_flux_ratio3[ibin, 2] = mean(flux_ratio[ind, 2])
           ;;
           bin_err_flux_ratio3[ibin, 3] = stddev(flux_ratio[ind, 3])
           bin_err_flux_ratio3[ibin, 0] = stddev(flux_ratio[ind, 0])
           bin_err_flux_ratio3[ibin, 1] = stddev(flux_ratio[ind, 1])
           bin_err_flux_ratio3[ibin, 2] = stddev(flux_ratio[ind, 2])
           ;;
           bin_ratio_model3[ibin, 3] = 1.0d0
           bin_ratio_model3[ibin, 0] = 1.0d0 
           bin_ratio_model3[ibin, 1] = 1.0d0 
           bin_ratio_model3[ibin, 2] = 1.0d0 
           
        endfor
        for iarr = 0, 3 do est5[ia, ib, iarr] = total( ( bin_flux_ratio3[*, iarr] -  bin_ratio_model3[*, iarr])^2) ;/bin_err_flux_ratio3[*, iarr]^2)

        for iarr = 0, 3 do est6[ia, ib, iarr] = total( (flux_ratio[*, iarr] - 1.0D0)^2)

        
        ;; plot
        ;print, 'a= ', a[ia, ib]
        ;print, 'b= ', b[ia, ib]
        ;print, 'rms = ', est1[iA, ib]
        ;print, 'half-scan diff = ', est2[iA, ib]
        ;print, 'chi2 = ', est3[iA, ib]
        
        ;wind, 1, 1, /free, xsize=900, ysize=650
        ;my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
        ;trans = exp(-tau225/sinel)
        ;noerase =0
        ;for i=0, 3 do begin
        ;   if i gt 0 then noerase=1
        ;   plot, trans, flux_ratio[*,i], pos=pp1[i, *], noerase=noerase, /xs, psym=8, yr=[0.5, 1.5]
        ;   oploterror, trans_bin2, bin_flux_ratio2[*, i], lonarr(nbin2), bin_err_flux_ratio2[*, i], psym=8, col=250  
        ;endfor
        ;; end plot
        ;stop
        
     endfor
  endfor
        
  quoi = ['A1', 'A2', 'A3', '1mm']

  nn = float(ntest)*float(ntest)
  
  ;; chi2 normalisation 
  sig2 = [0.06^2 , 0.04^2 , 0.05^2 , 0.05^2]
  if corrected_skydip_based gt 0 then begin
     ;;sig2 = [0.055^2 , 0.032^2 , 0.061^2 , 0.057^2]
     sig2 = [0.047^2 , 0.031^2 , 0.059^2 , 0.053^2]
     rms  = [4.7,      2.9,      5.8,     5.3]
  endif else if flux_driven_taumeter_based gt 0 then begin
     sig2 = [0.076^2 , 0.042^2 , 0.087^2 , 0.085^2]
     rms  = [7.6,      4.2,      8.5,     8.2]
  endif

  ;; confidence contour levels
  chi2tab = dindgen(500);+chi2min[ii]
  dof = nscans-nparams
  cc = 1.0-chisqr_pdf(chi2tab, dof)
  cl = [0.35, 0.05, 6.0e-7]
  ncl = 3
  c_levels = fltarr(ncl)
  for i=0, ncl-1 do begin
     w=where(cc lt cl[i], n)
     c_levels[i] = chi2tab[w[0]]
  endfor
  
  rmsmin       = dblarr(4)
  chi2min      = dblarr(4)
  bf_a_rms     = dblarr(4)
  err_bf_a_rms = dblarr(4)
  bf_a_c2      = dblarr(4)
  err_bf_a_c2  = dblarr(4)
  bf_b_rms     = dblarr(4)
  err_bf_b_rms = dblarr(4)
  bf_b_c2      = dblarr(4)
  err_bf_b_c2  = dblarr(4)
  
  for ii = 0, 3 do begin
     print, ''
     print, quoi[ii]
     aa = reform(a[*, *, ii], nn)
     bb = reform(b[*, *, ii], nn)
     e1 = reform(est1[*, *, ii], nn)
     e2 = reform(est2[*, *, ii], nn)
     e3 = reform(est3[*, *, ii], nn)
     e4 = reform(est4[*, *, ii], nn)
     e5 = reform(est5[*, *, ii], nn)
     e6 = reform(est6[*, *, ii], nn)
     
     wmin1 = where(e1 eq min(e1))
     wmin2 = where(e2 eq min(e2))
     wmin3 = where(e3 eq min(e3))
     wmin4 = where(e4 eq min(e4))
     wmin5 = where(e5 eq min(e5))
     wmin6 = where(e6 eq min(e6))

     w1 = where(e1 le rms[ii], ne1)
     ;;w6 = where(e6/sig2[ii] le min(e6)/sig2[ii]+1., ne6)
     w6 = where(e6/sig2[ii] le c_levels[0], ne6)
     chi2min[ii] = min(e6)/sig2[ii] 
     
     print, 'RMS min  = ', e1[wmin1]
     rmsmin[ii] = e1[wmin1]
     ;print, 'DIFF min = ', e2[wmin2]
     print, 'Chi2 min 2bins = ', e3[wmin3]
     print, 'Chi2 min 4bins = ', e4[wmin4]
     print, 'Chi2 min 6bins = ', e5[wmin5]
     print, 'Chi2 min = ', e6[wmin6]
     print, 'a (rms) = ', aa[wmin1]
     bf_a_rms[ii]     = aa[wmin1]
     err_bf_a_rms[ii] = mean(abs(minmax(aa[w1]) - mean(aa[w1])))
     print, 'a (rms) = ', bf_a_rms[ii], ' +/- ',err_bf_a_rms[ii] 
     print, 'a (diff) = ', aa[wmin2]
     print, 'a (2bins) = ', aa[wmin3]
     print, 'a (4bins) = ', aa[wmin4]
     print, 'a (6bins) = ', aa[wmin5]
     print, 'a         = ', aa[wmin6]
     bf_a_c2[ii]     = aa[wmin6]
     err_bf_a_c2[ii] = mean(abs(minmax(aa[w6]) - mean(aa[w6])))
     print, 'a         = ', bf_a_c2[ii], ' +/- ',err_bf_a_c2[ii]
     ;;
     print, 'b (rms) = ', bb[wmin1]
     bf_b_rms[ii]     = bb[wmin1]
     err_bf_b_rms[ii] = mean(abs(minmax(bb[w1]) - mean(bb[w1])))
     print, 'b (rms) = ', bf_b_rms[ii], ' +/- ',err_bf_b_rms[ii] 
     print, 'b (2 bins) = ', bb[wmin3]
     print, 'b (4 bins) = ', bb[wmin4]
     print, 'b (6 bins) = ', bb[wmin5]
     print, 'b          = ', bb[wmin6]
     bf_b_c2[ii]        = bb[wmin6]
     err_bf_b_c2[ii] = mean(abs(minmax(bb[w6]) - mean(bb[w6])))
     print, 'b          = ', bf_b_c2[ii], ' +/- ',err_bf_b_c2[ii] 
     print, '-----------------------------'
  endfor

  bf_a = 1./(1.0/err_bf_a_rms^2 + 1.0/err_bf_a_c2^2)*(bf_a_rms/err_bf_a_rms^2 + bf_a_c2/err_bf_a_c2^2)
  bf_b = 1./(1.0/err_bf_b_rms^2 + 1.0/err_bf_b_c2^2)*(bf_b_rms/err_bf_b_rms^2 + bf_b_c2/err_bf_b_c2^2)

  err_bf_a = sqrt(1./(1.0/err_bf_a_rms^2 + 1.0/err_bf_a_c2^2))
  err_bf_b = sqrt(1./(1.0/err_bf_b_rms^2 + 1.0/err_bf_b_c2^2))
  stop

  
  ;; rms contour levels
  rms_levels = [5., 6., 7., 10.]
  if corrected_skydip_based gt 0 then begin
     rms_levels = [5.5, 7., 10.]
  endif else if flux_driven_taumeter_based gt 0 then $
     rms_levels = [9., 10., 12.]


  if flux_driven_taumeter_based gt 0 then begin
     a_bestfit = [ 1.93,  0.95,  1.90,  1.92]
     b_bestfit = [-0.04,  0.0,  -0.05, -0.05]
  endif
  if corrected_skydip_based gt 0 then begin
     a_bestfit = [1.36,    1.05,   1.25,   1.28 ]
     b_bestfit = [-0.00, -0.015,  -0.04, -0.03]
  endif

  a_bestfit = bf_a
  b_bestfit = bf_b
  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14
  ;;
  ;;col_tab = [240, 89] ;; rose/vert
  col_tab = [140, 65 ] ;; coral/teal
  
  outfile = outplot_dir+'fit_nika2_tau'+plot_suffixe
  outplot, file=outfile, png=png, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
  
  pos = [[0.05, 0.05, 0.45, 0.45], [0.55, 0.05, 0.95, 0.45] , [0.05, 0.55, 0.45, 0.95], [0.55, 0.55, 0.95, 0.95]]
  wind, 1, 1, /free, xsize=900, ysize=650
  nope = 0
  
  titre = ['A1', 'A2', 'A3', 'A1&A3']
  for i = 0, 3 do begin
     if i eq 1 then fact = 0.5 else fact = 1.0 
     if i gt 0 then nope=1
     ;contour, est2[*, *, i], a[*, *, i], b[*, *, i], levels=[1, 2, 3, 5], col= 250, noerase=nope, position = pos[*, i]
     contour, est1[*, *, i], a[*, *, i], b[*, *, i], levels=fact*rms_levels, col=col_tab[0], noerase=1, position = pos[*, i]
     ;contour, est3[*, *, i]/sig2[i]/2.0d0, a[*, *, i], b[*, *, i], levels=[1., 2., 3., 4., 5.], col= 250, noerase=1, position = pos[*, i]
     ;;contour, est4[*, *, i]/sig2[i], a[*, *, i], b[*, *, i], levels=[1., 2., 3., 4., 5.], col=0, noerase=1, position = pos[*, i]
     ;contour, est5[*, *, i]/sig2[i]/6.0d0, a[*, *, i], b[*, *, i], levels=[1., 2., 3., 4., 5.], col= 150, noerase=1, position = pos[*, i]
     contour, est6[*, *, i]/sig2[i], a[*, *, i], b[*, *, i], levels=c_levels, col=col_tab[1], noerase=1, position = pos[*, i]
     oplot, [a_bestfit[i]], [b_bestfit[i]], psym=cgsymcat('filledstar', thick=1), col=92 ;, col=115
     ;oplot, [a_bestfit[i]], [b_bestfit[i]], psym=cgsymcat('star', thick=1),col=80 ;, col=10
     ;; axes en noir
     contour, est2[*, *, i], a[*, *, i], b[*, *, i], levels=[0.1, 1, 3, 5], col= 0, /nodata, noerase=1, position = pos[*, i], title=titre[i] 
  endfor

  outplot, /close
  stop
  
  ;mmax = [16, 8, 16, 16]
  ;wind, 1, 1, /free, xsize=900, ysize=650
  ;for i = 0, 3 do begin
  ;   i=0
  ;   matrix_plot, a[*, *, i], b[*, *, i], est2[*, *, i]+est1[*, *, i]/2., zra=[0, mmax[i]], position=[0.1/2., 0.1/2., 0.5 -0.1/2., 0.5 -0.1/2.], noerase=1
  ;   i=1
  ;   matrix_plot, a[*, *, i], b[*, *, i], est2[*, *, i]+est1[*, *, i]/2., zra=[0, mmax[i]], position=[0.1/2.+0.5*i, 0.1/2., 0.5*(i+1) -0.1/2., 0.5 -0.1/2.], noerase=1
  ;   i=2
  ;   matrix_plot, a[*, *, i], b[*, *, i], est2[*, *, i]+est1[*, *, i]/2., zra=[0, mmax[i]], position=[0.1/2., 0.1/2.+0.5, 0.5 -0.1/2., 0.5*2. -0.1/2.], noerase=1
  ;   i=3
  ;   matrix_plot, a[*, *, i], b[*, *, i], est2[*, *, i]+est1[*, *, i]/2., zra=[0, mmax[i]], position=[0.1/2.+0.5, 0.1/2.+0.5, 0.5*2. -0.1/2., 0.5*2. -0.1/2.], noerase=1
  ;endfor

  
  if keyword_set(ps) then begin
     suf   = ['_a1', '_a2', '_a3', '_1mm']
     titre = ['A1', 'A2', 'A3', 'A1&A3']
     for i = 0, 3 do begin

        outfile = outplot_dir+'fit_nika2_tau'+plot_suffixe+suf[i]
        outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
        
        if i eq 1 then fact = 0.5 else fact = 1.0 
        contour, est1[*, *, i], a[*, *, i], b[*, *, i], levels=fact*rms_levels, col=col_tab[0], thick=mythick
        ;;contour, est4[*, *, i]/sig2[i], a[*, *, i], b[*, *, i], levels=[1., 2., 3., 4., 5.], col= 150
        contour, est6[*, *, i]/sig2[i], a[*, *, i], b[*, *, i], levels=c_levels, col=col_tab[1], noerase=1, thick=thick
        ;; axes en noir
        if flux_driven_taumeter_based gt 0 then contour, est2[*, *, i], a[*, *, i], b[*, *, i], levels=[0.1, 1, 3], col=0, /nodata, noerase=1, xtitle='a!d225', ytitle='!nb!d225', thick=thick
        if corrected_skydip_based gt 0 then contour, est2[*, *, i], a[*, *, i], b[*, *, i], levels=[0.1, 1, 3], col=0, /nodata, noerase=1, xtitle='a!dskydip', ytitle='!nb!dskydip', thick=thick, charsize=charsize
        
        oplot, [a_bestfit[i]], [b_bestfit[i]], psym=cgsymcat('filledstar'), col=92
        if corrected_skydip_based gt 0 then oplot, [0, 10], [0, 0], col=0, thick=thick/2.
        legendastro, titre[i], col=0, textcol=0, box=0, charsize=charsize
        outplot, /close
        
        if keyword_set(pdf) then spawn, 'epspdf --bbox '+outplot_dir+'fit_nika2_tau'+plot_suffixe+suf[i]+'.eps'
     endfor

     

     
     stop

     
  endif
  
  

  stop
  
end
