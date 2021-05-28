pro flux_density_ratio_secondary, png=png, ps=ps, $
                                  fwhm_stability=fwhm_stability, $
                                  obstau_stability=obstau_stability, $
                                  mwc349_stability=mwc349_stability
  
  
  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)

  sources = ['MWC349', 'CRL2688', 'NGC7027']
  nsource = 3

  ;; outplot directory
  dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/'

  nostop=1
  
  ;;________________________________________________________________
  ;;
  ;; get all result files
  ;;________________________________________________________________
  ;;________________________________________________________________
  outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
  get_calib_scan_result_files, result_files, outputdir = outdir

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
  index_baseline  = -1
  ut           = ''
  ut_float     = 0.
  scan_list    = ''
  
  for irun = 0, nrun-1 do begin
          
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


     ;; remove known outliers
     ;;____________________________________________________________
     ;;scan_list_ori = strtrim(string(allscan_info.day, format='(i8)'), 2)+"s"+$
     ;;                strtrim( string(allscan_info.scan_num, format='(i8)'),2)
     scan_list_ori = allscan_info.scan
     
     outlier_list =  ['20180122s98', $
                      '20180122s118', '20180122s119', '20180122s120', '20180122s121'] ;; the telescope has been heated
     out_index = 1
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
     allscan_info = allscan_info[out_index]

     print, "scan list: "
     help, scan_list_run
     if nostop lt 1 then stop     
     
     ;;
     ;; scan baseline selection
     ;;____________________________________________________________

     ;; allscan selection for photocorr
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
     allscan_info = allscan_info[wtokeep]

     nscans       = n_elements(allscan_info)
     
     ;;baseline selection 
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
     
     if nostop lt 1 then stop

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
     ;; [OPTION] Photometric correction
     ;;____________________________________________________________

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
  index_baseline = index_baseline[1:*]
  scan_list      = scan_list[1:*]
  
  ;; calculate ut_float and get flux expectations
  nscans      = n_elements(day)
  ut_float    = fltarr(nscans)
  th_flux_1mm = dblarr(nscans)
  th_flux_a2  = dblarr(nscans)
  th_flux_a1  = dblarr(nscans)
  th_flux_a3  = dblarr(nscans)
  
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor

  ;; flux density expectations
  ;;----------------------------------------------------------
  sou = 'MWC349'
  wsou = where(strupcase(obj) eq sou, nscan_sou)
  lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
  nu = !const.c/(lambda*1e-3)/1.0d9
  th_flux           = 1.16d0*(nu/100.0)^0.60
  ;; assuming indep param
  err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
    
  th_flux_1mm[wsou]     = th_flux[0]
  th_flux_a2[wsou]      = th_flux[1]
  th_flux_a1[wsou]      = th_flux[0]
  th_flux_a3[wsou]      = th_flux[2]
  
  sou = 'CRL2688'
  wsou = where(strupcase(obj) eq sou, nscan_sou)
  ;;th_flux           = [2.91, 0.76]
  th_flux           = [2.51, 0.54] ;; JFL
  alpha = 2.44
  ;; Dempsey 2013
  flux_scuba2 = [5.64, 24.9] ;; Jy.beam-1
  lam_scuba2  = [850., 450.]*1.0d-6
  nu_scuba2   = !const.c/(lam_scuba2)/1.0d9
  th_flux_1mm_mbb = flux_scuba2[0] * (nu[0]/nu_scuba2[0])^(0.4)*$
                    black_body(nu[0],210.)/black_body(nu_scuba2[0],210.)
  th_flux_2mm_mbb = flux_scuba2[0] * (nu[1]/nu_scuba2[0])^(0.4)*$
                    black_body(nu[1], 210.)/black_body(nu_scuba2[0],210.)
  ;; 2.71, 0.72

  th_flux_1mm_alpha = flux_scuba2 * (nu[0]/nu_scuba2)^(2.44) ;; 2.6801162   2.5068608
  th_flux_2mm_alpha = flux_scuba2 * (nu[1]/nu_scuba2)^(2.44) ;; 0.70029542  0.65502500

  
  th_flux_1mm[wsou]     = th_flux[0]
  th_flux_a2[wsou]      = th_flux[1]
  th_flux_a1[wsou]      = th_flux[0]
  th_flux_a3[wsou]      = th_flux[0]
  
  ;;th_flux_1mm[wsou]     = th_flux_1mm_mbb
  ;;th_flux_a2[wsou]      = th_flux_2mm_mbb
  ;;th_flux_a1[wsou]      = th_flux_1mm_mbb
  ;;th_flux_a3[wsou]      = th_flux_1mm_mbb
  
  sou = 'NGC7027'
  wsou = where(strupcase(obj) eq sou, nscan_sou)
  th_flux           = [3.46, 4.26]
  th_flux_1mm[wsou]     = th_flux[0]
  th_flux_a2[wsou]      = th_flux[1]
  th_flux_a1[wsou]      = th_flux[0]
  th_flux_a3[wsou]      = th_flux[0]


  
  ;;nk_scan2run, scan_list[0], run
  ;;nika_tags = tag_names(!nika)
  ;;for isou=0, nsource-1 do begin
  ;;   sou = strupcase(sources[isou])
  ;;   wsou = where(strupcase(obj) eq sou, nscan_sou)
  ;;
  ;;   if nscan_sou gt 0 then begin
  ;;
  ;;      wtag = where(strupcase(nika_tags) eq 'FLUX_'+sou, nn)
  ;;      
  ;;      for i=0, nscan_sou-1 do begin
  ;;         ut_float[wsou[i]] = float((STRSPLIT(ut[wsou[i]], ':', /EXTRACT))[0])+float((STRSPLIT(ut[wsou[i]], ':', /EXTRACT))[1])/60.
  ;;         nk_scan2run, scan_list[wsou[i]], run
  ;;
  ;;         flux = !nika.(wtag)
  ;;         
  ;;         th_flux_1mm[wsou[i]]     = flux[0]
  ;;         th_flux_a2[wsou[i]]      = flux[1]
  ;;         th_flux_a1[wsou[i]]      = flux[0]
  ;;         th_flux_a3[wsou[i]]      = flux[2]
  ;;   
  ;;      endfor
  ;;   endif
  ;;endfor

  stop
  
  ;; hybrid opacity
  h_tau_a2 = tau_a1*modified_atm_ratio(tau_a1)

  
  
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


  
  ;;
  ;;   MWC349 3 RUNS : FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(mwc349_stability) then begin
     
     col_tab = [col_n2r9, col_n2r12, col_n2r14]
     
     w_baseline = where(index_baseline gt 0 and obj eq 'MWC349', n_baseline)

     w_total = where(obj eq 'MWC349', n_total)
     
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.2, max(flux_ratio_1mm[w_baseline] )]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_baseline])]   )
     xmax  = 0.8
     xmin  = 0.     
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau_secondary_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, tau_1mm/sin(elev), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata

     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[w_total] eq calib_run[irun], nt)
        print, 'nscan = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then oplot, tau_1mm[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_1mm[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
        print, 'nscan = ', nn
        print, 'bias = ', mean(flux_ratio_1mm[w_baseline[w]])
        print, 'rel.rms = ', stddev(flux_ratio_1mm[w_baseline[w]])/mean(flux_ratio_1mm[w_baseline[w]])*100
     endfor
  
     ;;
     legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.], textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.07]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmax-(xmax-xmin)*0.15, 1.17, 'A1&A3', col=0 
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     print, ''
     print, ' A1 '
     print, '-----------------------'
     ymax = max( [1.2, max(flux_ratio_a1[w_baseline] )]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_baseline])]   )
     xmax  = 0.8
     xmin  = 0.
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau_secondary_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, tau_a1/sin(elev), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[w_total] eq calib_run[irun], nt)
        print, 'nscan = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then oplot, tau_a1[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_a1[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
        print, 'nscan = ', nn
        print, 'bias = ', mean(flux_ratio_a1[w_baseline[w]])
        print, 'rel.rms = ', stddev(flux_ratio_a1[w_baseline[w]])/mean(flux_ratio_a1[w_baseline[w]])*100
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.1, 1.17, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     print, ''
     print, ' A3 '
     print, '-----------------------'
     ymax = max( [1.2, max(flux_ratio_a3[w_baseline] )]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_baseline])]   )
     xmax  = 0.8
     xmin  = 0.

     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau_secondary_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, tau_a3/sin(elev), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[w_total] eq calib_run[irun], nt)
        print, 'nscan = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then oplot, tau_a3[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_a3[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
        print, 'nscan = ', nn
        print, 'bias = ', mean(flux_ratio_a3[w_baseline[w]])
        print, 'rel.rms = ', stddev(flux_ratio_a3[w_baseline[w]])/mean(flux_ratio_a3[w_baseline[w]])*100
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.05, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.1, 1.17, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'
     ymax = max( [1.2, max(flux_ratio_a2[w_baseline] )]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_baseline])]   )
     xmax  = 0.5
     xmin  = 0.
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_flux_density_ratio_MWC349_obstau_secondary_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, h_tau_a2/sin(elev), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[w_total] eq calib_run[irun], nt)
        print, 'nscan = ', nt
        w = where(runid[w_baseline] eq calib_run[irun], nn)
        if nn gt 0 then oplot, h_tau_a2[w_baseline[w]]/sin(elev[w_baseline[w]]), flux_ratio_a2[w_baseline[w]], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun]
        print, 'nscan = ', nn
        print, 'bias = ', mean(flux_ratio_a2[w_baseline[w]])
        print, 'rel.rms = ', stddev(flux_ratio_a2[w_baseline[w]])/mean(flux_ratio_a2[w_baseline[w]])*100
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=1., pos=[0.03, ymax-0.03], psym=cgsymcat('FILLEDCIRCLE', thick=2)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.1, 1.17, 'A2', col=0
     
     outplot, /close
     

     
     print, ''
     print, 'Combined'
     print, 'total nscan = ',    n_elements(w_total)
     print, 'selected nscan = ', n_elements(w_baseline)
     
     print, 'A1 bias = ', mean(flux_ratio_a1[w_baseline])
     print, 'A3 bias = ', mean(flux_ratio_a3[w_baseline])
     print, '1mm bias = ', mean(flux_ratio_1mm[w_baseline])
     print, 'A2 bias = ', mean(flux_ratio_a2[w_baseline])
     
     print, 'A1 rel.rms = ', stddev(flux_ratio_a1[w_baseline])/mean(flux_ratio_a1[w_baseline])*100
     print, 'A3 rel.rms = ', stddev(flux_ratio_a3[w_baseline])/mean(flux_ratio_a3[w_baseline])*100
     print, '1mm rel.rms = ', stddev(flux_ratio_1mm[w_baseline])/mean(flux_ratio_1mm[w_baseline])*100
     print, 'A2 rel.rms = ', stddev(flux_ratio_a2[w_baseline])/mean(flux_ratio_a2[w_baseline])*100
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
     outfile = dir+'plot_flux_density_ratio_3sources_obstau_secondary_1mm'
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
     outfile = dir+'plot_flux_density_ratio_3sources_obstau_secondary_a1'
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
     outfile = dir+'plot_flux_density_ratio_3sources_obstau_secondary_a3'
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
     outfile = dir+'plot_flux_density_ratio_3sources_obstau_secondary_a2'
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
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM_secondary_1mm'
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
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM_secondary_a1'
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
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM_secondary_a3'
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
     outfile = dir+'plot_flux_density_ratio_3sources_FWHM_secondary_a2'
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
