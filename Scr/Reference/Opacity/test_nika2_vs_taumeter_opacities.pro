
;;
;;  TEST THE STABILITY OF THE FLUX RATIO AGAINST OPACITY
;;
;;   on nika2b = use output files from baseline_calibration_v2_outputfile
;;   on nika2c = use scan result summary  files 
;;
;;   LP, August 2018
;;_______________________________________________________________


pro test_nika2_vs_taumeter_opacities, png=png, ps=ps, pdf=pdf, nika2c=nika2c
  
  
  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)
  
  ;; methode de correction d'opacite
  ;;---------------------------------------------
  skydip_based                 = 0
  corrected_skydip_based       = 0
  taumeter_based               = 1
  
  ;;sources = ['MWC349', 'CRL2688', 'NGC7027']
  sources = ['URANUS', 'MWC349']
  nsource = 2
  
  nostop=1

  fact_atm = 1.5 ;;1.3
  
  ;; plot
  ;;----------------------------------------------------------------
  
  ;; outplot directory
  outplot_dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/Opacity/'

  
  ;; window size
  wxsize = 550.
  wysize = 400.
  ;; plot size in files
  pxsize = 11.
  pysize =  8.
  ;; charsize
  charsize  = 1.3
  charthick = 3.0               ;0.7
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
        ;;result_files[irun, 0] = dir+'Uranus_allinfo_'+runname+'_baseline_v2.save'
        ;;result_files[irun, 1] = dir+'MWC349_allinfo_'+runname+'_baseline_v2.save'
     endfor
  endelse
  
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
  tau225       = 0.0d0
  atmtau1      = 0.0d0
  atmtau2      = 0.0d0
  atmtau3      = 0.0d0
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
        th_flux_a3_run[i]      = !nika.flux_uranus[2]
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

     
     if taumeter_based gt 0 then begin
        get_tau_nika_from_tau225, runname, scan_list_run, tau_nika, flux_driven=1, skydip_driven=0, atm=0
     endif

     ;; not implemented
     ;;if skydip_driven_taumeter_based gt 0 then begin
     ;;   get_tau_nika_from_tau225, runname, scan_list_run, tau_nika, flux_driven=0, skydip_driven=1
     ;;endif

     ;; 2/ implementing opacity correction
     sinel = sin(allscan_info.result_elevation_deg*!dtor)
     allscan_info.result_flux_i_1mm = allscan_info.result_flux_i_1mm*exp((tau_nika[*,3]-allscan_info.result_tau_1mm)/sinel)
     allscan_info.result_flux_i1 = allscan_info.result_flux_i1*exp((tau_nika[*,0]-allscan_info.result_tau_1)/sinel)
     allscan_info.result_flux_i2 = allscan_info.result_flux_i2*exp((tau_nika[*,1]-allscan_info.result_tau_2)/sinel)
     allscan_info.result_flux_i3 = allscan_info.result_flux_i3*exp((tau_nika[*,2]-allscan_info.result_tau_3)/sinel) 

     ;; get tau225
     tau225_run = dblarr(nscans)
     atmtau1_run = dblarr(nscans)
     atmtau2_run = dblarr(nscans)
     atmtau3_run = dblarr(nscans)
     opa_file = !nika.pipeline_dir+'/Datamanage/Tau225/results_opacity_tau225interp_'+strupcase(runname)+'.fits'
     opa = mrdfits(opa_file, 1)
     scan_list_opa = strtrim(opa.day,2)+'s'+strtrim(opa.scannum,2)
     my_match, scan_list_opa, scan_list_run, suba, subb
     tau225_run[subb] = opa[suba].tau225_medfilt
     atmtau1_run[subb] = opa[suba].tau1_medfilt
     atmtau2_run[subb] = opa[suba].tau2_medfilt
     atmtau3_run[subb] = opa[suba].tau3_medfilt
     
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
     tau225       = [tau225, tau225_run]
     atmtau1      = [atmtau1, atmtau1_run]
     atmtau2      = [atmtau2, atmtau2_run]
     atmtau3      = [atmtau3, atmtau3_run]
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
  tau225       = tau225[1:*]
  atmtau1      = atmtau1[1:*]
  atmtau2      = atmtau2[1:*]
  atmtau3      = atmtau3[1:*]
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
 


  ;;
  ;;        TEST OPACITY MODEL
  ;;
  ;;___________________________________________________________________

  
  col_tab = [col_n2r9, col_n2r12, col_n2r14]
  
  w_baseline = where(index_baseline gt 0, n_b)
  w_b2 = where(index_baseline gt 0 and obj eq 'MWC349', n_b2)
  w_b1 = where(index_baseline gt 0 and strupcase(obj) eq 'URANUS', n_b1)
  
  w_t2 = where(obj eq 'MWC349', n_t2)
  w_t1 = where(strupcase(obj) eq 'URANUS', n_t1)
  
  atm_model_mdp, atmtau_a1, atmtau_a2, atmtau_a3, atmtau_225, atm_em_1, atm_em_2, atm_em_3,$
                 nostop=1, tau225=1, bpfiltering=1
  
  wind, 1, 1, /free, xsize=900, ysize=650
  outplot, file=outplot_dir+'test_skydip_vs_tau225', png=png
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6

  quoi    = ['A1', 'A3', 'A1&A3', 'A2']
  tau_nika = [[tau_a1], [tau_a3], [tau_1mm], [tau_a2]]
  atmtau   = [[atmtau_a1], [atmtau_a3], [atmtau_a3], [atmtau_a2]]
  
  colrun = [col_n2r9, col_n2r12, col_n2r14]
 
  for iq = 0, 3 do begin

     noerase = 0
     if iq gt 0 then noerase = 1

     ymax = max(tau_nika[*, iq])
     plot, tau225[*], tau_nika[*, iq], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
           ;xtitle = '225GHz taumeter median opacity', ytitle='skydip-based '+quoi[iq]+' opacity', $
           xr = [0, 0.4], yr=[0, ymax]
     
     for irun = 0, nrun-1 do begin
        ;irun=0
        w = where(runid eq calib_run[irun], nr)
        oplot, tau225[w], tau_nika[w, iq], psym=cgsymcat('FILLEDCIRCLE', thick=1), col=colrun[irun]
        oplot, atmtau_225, atmtau[*, iq], psym=-1, col=0
     endfor
     oplot, atmtau_225, fact_atm*atmtau[*, iq], psym=-1, col=0
     if iq eq 0 then legendastro, calib_run, col=colrun, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1., pos=[0.03, 0.57]
     cgplot, tau225[*], tau_nika[*, iq], pos=pp1[iq, *], noerase=1, /nodata, /xs, /ys, $
             xtitle = '$\tau$!d225!n', ytitle='$\tau$!dskydip!n', $
             xr = [0, 0.4], yr=[0, ymax]
        
  endfor
  
  outplot, /close

  stop
  if nostop lt 1 then stop
  
  if keyword_set(ps) then begin
     suf   = ['_a1', '_a3', '_1mm','_a2']
     
     ymax = [0.7, 0.7, 0.7, 0.7]
     for iq = 0, 3 do begin
        
        outfile = outplot_dir+'Opacity_correl_skydip_vs_tau'+suf[iq]
        outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick

       ; tau = '!4'+ string("163B) +'!n'
        
        ;;ymax = max(tau_nika[*, iq])
        plot, tau225[*], tau_nika[*, iq], noerase = noerase, /nodata, /xs, /ys, $
              xtitle='!4s!X!d225!n', ytitle='!4s!X!dskydip!n', $
              xr = [0, 0.4], yr=[0, ymax[iq]]
        
        for irun = 0, nrun-1 do begin
           w = where(runid eq calib_run[irun], nr)
           oplot, tau225[w], tau_nika[w, iq], psym=cgsymcat('FILLEDCIRCLE', thick=symthick), col=colrun[irun]
           oplot, atmtau_225, atmtau[*, iq], col=0, thick=thick/2.
        endfor
        legendastro, quoi[iq], box=0, col=0, pos=[0.03, 0.6]
        if iq eq 3 then legendastro, calib_run, col=colrun, psym=cgsymcat('FILLEDCIRCLE', thick=symthick)*[1., 1., 1.], textcol=0, box=0, pos=[0.27, 0.6]
        outplot, /close
       
        if keyword_set(pdf) then spawn, 'epspdf --bbox '+outplot_dir+'Opacity_correl_skydip_vs_tau'+suf[iq]+'.eps'
     endfor
  endif

  wd, /a


  ;;; ratio
  ;;__________________________________________________________________________-
  
  wind, 1, 1, /free, xsize=900, ysize=650
  outplot, file=outplot_dir+'test_skydip_vs_tau225', png=png
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6

  quoi    = ['A1', 'A3', 'A1&A3', 'A2']
  tau_nika = [[tau_a1], [tau_a3], [tau_1mm], [tau_a2]]
  
  h_atmtau2 = atmtau3*modified_atm_ratio(atmtau3, /use_taua3)
  atmtau   = [[atmtau1], [atmtau3], [atmtau3], [h_atmtau2]]

  
  colrun = [col_n2r9, col_n2r12, col_n2r14]
 
  for iq = 0, 3 do begin

     noerase = 0
     if iq gt 0 then noerase = 1

     ymax = max(tau_nika[*, iq])
     plot, tau225[*], tau_nika[*, iq]/atmtau[*,iq], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
           xtitle = '225GHz taumeter median opacity', ytitle='skydip '+quoi[iq]+' opacity ratio', $
           xr = [0, 0.4], yr=[0.4, 1.5]
     
     for irun = 0, nrun-1 do begin
        ;irun=0
        w = where(runid eq calib_run[irun], nr)
        oplot, tau225[w], tau_nika[w, iq]/atmtau[w,iq], psym=cgsymcat('FILLEDCIRCLE', thick=1), col=colrun[irun]
        oplot, atmtau_225, atmtau[*, iq]/atmtau[*,iq], psym=-1, col=0
     endfor
     if iq eq 0 then legendastro, calib_run, col=colrun, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1.

     print, quoi[iq], ' ', stddev(tau_nika[*, iq]/atmtau[*,iq])
     
  endfor
  
  outplot, /close

  if nostop lt 1 then stop

  wd, /a


  
  ;; per source per run
  ;;---------------------

  colsou = [35, col_mwc349]
  
  for irun = 0, nrun-1 do begin
     
     wind, 1, 1, /free, xsize=900, ysize=650
     outplot, file=outplot_dir+'test_skydip_vs_tau225_persou_'+calib_run[irun], png=png
     my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
     
     w_r2 = where(runid eq calib_run[irun] and obj eq 'MWC349', n_b2)
     w_r1 = where(runid eq calib_run[irun] and strupcase(obj) eq 'URANUS', n_b1)
     
     for iq = 0, 3 do begin
        
        noerase = 0
        if iq gt 0 then noerase = 1
        
        ymax = max(tau_nika[*, iq])
        plot, tau225[*], tau_nika[*, iq], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
              xtitle = '225GHz taumeter median opacity', ytitle='skydip-based '+quoi[iq]+' opacity', $
              xr = [0, 0.4], yr=[0, ymax], title=calib_run[irun]
        
        oplot, tau225[w_r1], tau_nika[w_r1, iq], psym=cgsymcat('FILLEDCIRCLE', thick=1), col=colsou[0]
        oplot, tau225[w_r2], tau_nika[w_r2, iq], psym=cgsymcat('OPENSQUARE', thick=1), col=colsou[1]
        oplot, atmtau_225, atmtau[*, iq], psym=-1, col=0
        
     endfor
     outplot,/close
  endfor

  if nostop lt 1 then stop
  wd, /a
  

  ;; per source multi-run
  ;;---------------------

  colsou = [35, col_mwc349]
   
  wind, 1, 1, /free, xsize=900, ysize=650
  outplot, file=outplot_dir+'test_skydip_vs_tau225_persou', png=png
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6

  ymax_tab = [0.7, 0.7,  0.7,  0.7]
  
  for iq = 0, 3 do begin
     noerase = 0
     if iq gt 0 then noerase = 1
     
     ymax = max(tau_nika[*, iq])
     plot, tau225[*], tau_nika[*, iq], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
           xtitle = '225GHz taumeter opacity', ytitle='skydip-based opacity', $
           xr = [0, 0.4], yr=[0, ymax_tab[iq]]
     
     for irun = 0, nrun-1 do begin
        w_r2 = where(runid eq calib_run[irun] and obj eq 'MWC349', n_b2)
        w_r1 = where(runid eq calib_run[irun] and strupcase(obj) eq 'URANUS', n_b1)
           
        oplot, tau225[w_r1], tau_nika[w_r1, iq], psym=cgsymcat('FILLEDCIRCLE', thick=1), col=colsou[0]
        oplot, tau225[w_r2], tau_nika[w_r2, iq], psym=cgsymcat('OPENSQUARE', thick=1), col=colsou[1]
        legendastro, quoi[iq], textcol=0, box=0, charsize=charsize, pos = [0.03, 0.6]
     endfor
     ;;oplot, atmtau_225, atmtau[*, iq], psym=-1, col=0

     if iq eq 3 then begin
        legendastro, ['Uranus'], textcol=0, col=colsou[0], psym=[cgsymcat('FILLEDCIRCLE', thick=2)], pos = [0.27, 0.6], box=0
        legendastro, ['MWC349'], textcol=0, col=colsou[1], psym=[cgsymcat('OPENSQUARE', thick=1)], pos = [0.27, 0.53], box=0
     endif

  endfor
  outplot,/close
  
  if nostop lt 1 then stop
  wd, /a

  
  ;; tau_skydip-to-tau225 ratio per source vs elevation
  ;;________________________________________________________________________________

  colsou = [35, col_mwc349]
   
  wind, 1, 1, /free, xsize=900, ysize=650
  outplot, file=outplot_dir+'test_skydip_to_tau225_ratio_vs_elev_persou', png=png
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  ymin = 0.
  ymax = 2.5
  
  for iq = 0, 3 do begin
     noerase = 0
     if iq gt 0 then noerase = 1
     
     plot, tau_nika[*, iq]/tau225[*], elev[*], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
           xtitle = '', ytitle='', $
           xr = [10, 80], yr=[ymin, ymax]
     
     for irun = 0, nrun-1 do begin
        w_r2 = where(runid eq calib_run[irun] and obj eq 'MWC349', n_b2)
        w_r1 = where(runid eq calib_run[irun] and strupcase(obj) eq 'URANUS', n_b1)

        oplot, elev[w_r1]/!dtor, tau_nika[w_r1, iq]/tau225[w_r1], psym=cgsymcat('FILLEDCIRCLE', thick=1), col=colsou[0]
        oplot, elev[w_r2]/!dtor, tau_nika[w_r2, iq]/tau225[w_r2], psym=cgsymcat('OPENSQUARE', thick=1), col=colsou[1]
        legendastro, quoi[iq], textcol=0, box=0, charsize=charsize, pos = [15, 2.1]
     endfor
     ;;oplot, atmtau_225, atmtau[*, iq], psym=-1, col=0

     if iq eq 3 then begin
        legendastro, ['Uranus'], textcol=0, col=colsou[0], psym=[cgsymcat('FILLEDCIRCLE', thick=2)], pos = [60, 2.1], box=0
        legendastro, ['MWC349'], textcol=0, col=colsou[1], psym=[cgsymcat('OPENSQUARE', thick=1)], pos = [60, 1.9], box=0
     endif
     
     cgplot, elev[*], tau_nika[*, iq]/tau225[*], pos=pp1[iq, *], noerase=1, /nodata, /xs, /ys, $
           xtitle = 'elevation [deg]', ytitle='$\tau$!dskydip!n to $\tau$!d225!n ratio', $
             xr = [10, 80], yr=[ymin, ymax]
     
     
  endfor
  outplot,/close
  
  stop
  if nostop lt 1 then stop
  wd, /a

  if keyword_set(ps) then begin
     suf   = ['_a1', '_a3', '_1mm','_a2']
     
     ymax = [0.7, 0.7, 0.7, 0.7]
     for iq = 0, 3 do begin
        
        outfile = outplot_dir+'Opacity_skydip_to_taumeter_vs_elev'+suf[iq]
        outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick

       
        ymin = 0.
        ymax = 2.5
        
        plot, tau_nika[*, iq]/tau225[*], elev[*]/!dtor, /nodata, /xs, /ys, $
              xtitle='elevation [deg]', ytitle='!4s!X!dskydip!n / !4s!X!d225!n', $
              xr = [10, 80], yr=[ymin, ymax]
        
        for irun = 0, nrun-1 do begin
           w_r1 = where(runid eq calib_run[irun] and strupcase(obj) eq 'URANUS', n_b1)
           oplot, elev[w_r1]/!dtor, tau_nika[w_r1, iq]/tau225[w_r1], psym=cgsymcat('FILLEDCIRCLE', thick=symthick), col=colsou[0]
        endfor
        for irun = 0, nrun-1 do begin
           w_r2 = where(runid eq calib_run[irun] and obj eq 'MWC349', n_b2)
           oplot, elev[w_r2]/!dtor, tau_nika[w_r2, iq]/tau225[w_r2], psym=cgsymcat('OPENSQUARE', thick=symthick), col=colsou[1]
        endfor

        
        legendastro, quoi[iq], textcol=0, box=0, charsize=charsize, pos = [15, 2.1]
        
        if iq eq 3 then begin
           legendastro, ['Uranus'], textcol=0, col=colsou[0], psym=[cgsymcat('FILLEDCIRCLE', thick=symthick)], pos = [50, 2.1], box=0
           legendastro, ['MWC349'], textcol=0, col=colsou[1], psym=[cgsymcat('OPENSQUARE', thick=symthick)], pos = [50, 1.9], box=0
        endif
        
        outplot, /close
       
        if keyword_set(pdf) then spawn, 'epspdf --bbox '+outplot_dir+'Opacity_skydip_to_taumeter_vs_elev'+suf[iq]+'.eps'
     endfor
  endif

  wd, /a

  
  
end
