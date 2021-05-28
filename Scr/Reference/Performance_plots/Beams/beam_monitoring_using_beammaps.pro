pro beam_monitoring_with_otf, png=png, ps=ps, pdf=pdf, $
                                    nostop = nostop, savefile = savefile
  
  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)
  
  ;; Flux threshold for sources selection
  ;;--------------------------------------------
  flux_threshold_1mm = 1.0d0
  flux_threshold_2mm = 1.0d0

  
  ;; outplot directory
  dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/'

  if keyword_set(nostop) then nostop = 1 else nostop = 0
  if keyword_set(savefile) then savefile = 1 else savefile = 0
  
    
  plot_name = 'Beam_monitoring_with_beammaps_vs_ut'


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
  if keyword_set(ps) then thick     = 3.0 else thick = 1.0
  symsize   = 0.7
  

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
  fwhm_x_1mm   = 0.
  fwhm_x_a2    = 0.
  fwhm_x_a1    = 0.
  fwhm_x_a3    = 0.
  fwhm_y_1mm   = 0.
  fwhm_y_a2    = 0.
  fwhm_y_a1    = 0.
  fwhm_y_a3    = 0.
  elev         = 0.
  obj          = ''
  day          = ''
  runid        = ''
  ut           = ''
  ut_float     = 0.
  scan_list    = ''
  
  th_flux_1mm = 0.0d0
  th_flux_a2  = 0.0d0
  th_flux_a1  = 0.0d0
  th_flux_a3  = 0.0d0

  ntot_tab    = intarr(nrun+1)
  nselect_tab = intarr(nrun+1)
  
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
     
     out_index = 1
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
     allscan_info = allscan_info[out_index]
     
     nscans = n_elements(scan_list_run)
     print, "number of scan: ", nscans
     
     if nostop lt 1 then stop
     
     ;; NSCAN TOTAL ESTIMATE :
     ;; select scans for the desired sources
     ;;____________________________________________________________
     ;; flux thresholding
     wkeep = where( allscan_info.result_flux_i_1mm ge flux_threshold_1mm and $
                    allscan_info.result_flux_i2    ge flux_threshold_2mm, nkeep)
     print, 'nb of found scan of the sources = ', nkeep
     allscan_info = allscan_info[wkeep]

     wq = where(allscan_info.object eq '0316+413', nq)
     if nq gt 0 then allscan_info[wq].object = '3C84'
     
     ;; discarding resolved sources 
     allsources  = strupcase(allscan_info.object)
     wreso = where(allsources eq 'MARS' or allsources eq 'NGC7027', wres, compl=wpoint)
     allscan_info = allscan_info[wpoint]
         
     nscans       = n_elements(allscan_info)
     ntot_tab[irun] = nscans
     
     ;;
     ;; Scan selection
     ;;____________________________________________________________
     ;; opacity cut only (copied from scan_selection.pro)
     tau3max    = 0.5 ;; 0.7
     obstau3max = 0.7 ;; 1.1
     elevation_min = 20.0d0
     elevation_max = 90.0d0
     wtokeep = where( allscan_info.result_tau_3 le tau3max and $
                      allscan_info.result_tau_3/sin(allscan_info.result_elevation_deg*!dtor) le obstau3max and $
                      allscan_info.result_elevation_deg gt elevation_min and $
                      allscan_info.result_elevation_deg lt elevation_max, $
                      compl=wout, nscans, ncompl=nout)
     allscan_info = allscan_info[wtokeep]
     
     
     ;; select scans for the desired sources
     ;;____________________________________________________________
     ;; flux thresholding
     wkeep = where( allscan_info.result_flux_i_1mm ge flux_threshold_1mm and $
                    allscan_info.result_flux_i2    ge flux_threshold_2mm, nkeep)
     print, 'nb of found scan of the sources = ', nkeep
     allscan_info = allscan_info[wkeep]

     wq = where(allscan_info.object eq '0316+413', nq)
     if nq gt 0 then allscan_info[wq].object = '3C84'
     
     ;; discarding resolved sources 
     allsources  = strupcase(allscan_info.object)
     wreso = where(allsources eq 'MARS' or allsources eq 'NGC7027', wres, compl=wpoint)
     if do_photocorr gt 0 then allscan_info = allscan_info[wpoint]
         
     nscans       = n_elements(allscan_info)
     
     
     ;; URANUS: correction for finite apparent disc
     ;;-------------------------------------------------------------------
     wu = where(strupcase(allscan_info.object) eq 'URANUS', nuranus)
     allscan_info.result_fwhm_1mm[wu] = allscan_info.result_fwhm_1mm[wu] 
     allscan_info.result_fwhm_2[wu]   = allscan_info.result_fwhm_2[wu]
     allscan_info.result_fwhm_1[wu]   = allscan_info.result_fwhm_1[wu]
     allscan_info.result_fwhm_3[wu]   = allscan_info.result_fwhm_3[wu]
     
     
  
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
  scan_list      = scan_list[1:*]
  ;;
  th_flux_1mm  = th_flux_1mm[1:*]
  th_flux_a2   = th_flux_a2[1:*]
  th_flux_a1   = th_flux_a1[1:*]
  th_flux_a3   = th_flux_a3[1:*]
  
  ;; calculate ut_float 
  nscans      = n_elements(elev)
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor
  
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

  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3

  
  ;;
  ;;   FLUX RATIO COLOR-CODED FROM THE UT
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obsdate_stability) then begin
     
     w_total = indgen(nscans)
     wsource = w_total
     
      ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_1mm[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_1mm[wsource])]   )
     xmax  = 0.95
     xmin  = 0.35     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_1mm[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_1mm[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=ut_col[u], symsize=symsize      
     endfor
     
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.41, ymax-0.1], spacing=0.9
     ;;
     oplot, [0.5,xmax], [1., 1.], col=0
     oplot, [0.5,xmax], [1., 1.]+stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [0.5,xmax], [1., 1.]-stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [0.5, 0.5], [ymin, ymax], col=170
     xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     print, ''
     print, ' A1 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a1[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a1[wsource])]   )
     xmax  = 0.95
     xmin  = 0.35
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_a1[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a1[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=ut_col[u], symsize=symsize         
     endfor
     
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.41, ymax-0.1], spacing=0.9
     
     oplot, [0.5,xmax], [1., 1.], col=0
     oplot, [0.5,xmax], [1., 1.]+stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [0.5,xmax], [1., 1.]-stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [0.5, 0.5], [ymin, ymax], col=170
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     print, ''
     print, ' A3 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a3[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a3[wsource])]   )
     xmax  = 0.95
     xmin  = 0.35

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_a3[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a3[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=ut_col[u] , symsize=symsize        
     endfor
     
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.41, ymax-0.1], spacing=0.9
     ;;
    
     oplot, [0.5,xmax], [1., 1.], col=0
     oplot, [0.5,xmax], [1., 1.]+stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [0.5,xmax], [1., 1.]-stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [0.5, 0.5], [ymin, ymax], col=170
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a2[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a2[wsource])]   )
     xmax  = 0.95
     xmin  = 0.50
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     for u = 0, nut-1 do begin       
        w=where(ut_float[wsource] ge ut_tab[u] and ut_float[wsource] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, exp(-tau_a2[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a2[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=ut_col[u] , symsize=symsize        
     endfor
     
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]],  box=0, charsize=charsize*0.8, pos=[0.52, ymax-0.1], spacing=0.9
     ;;
     oplot, [0.6,xmax], [1., 1.], col=0
     oplot, [0.6,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [0.6,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [0.6, 0.6], [ymin, ymax], col=170
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
     outplot, /close
     
     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epstopdf '+dir+'plot_flux_density_ratio_obstau_allbright_obsdate'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif
     
     
  endif

     
  ;;
  ;;   FLUX RATIO AGAINST OBSERVED OPACITY
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     col_tab = [col_n2r9, col_n2r12, col_n2r14]
     
     w_total = indgen(nscans)
     wsource = w_total
     
     ;; result_tab: all runs + combined results
     ntot_tab[3] = total(ntot_tab[0:2])
     bias_tab    = dblarr(4, nrun+1)
     rms_tab     = dblarr(4, nrun+1)

     
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_1mm[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_1mm[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_1mm[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_1mm[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun], symsize=symsize
        nselect_tab[irun] = nn
        bias_tab[3, irun] = mean(flux_ratio_1mm[wsource[w]])
        rms_tab[3, irun]  = stddev(flux_ratio_1mm[wsource[w]])/mean(flux_ratio_1mm[wsource[w]])*100
        print, 'nscan = ', nn
        print, 'bias = ', bias_tab[3, irun]
        print, 'rel.rms = ', rms_tab[3, irun]
     endfor
     ;oplot, exp(-tau_1mm[wsource]/sin(elev[wsource])), flux_ratio_1mm[wsource], psym=cgsymcat('OPENCIRCLE', thick=1), col=0
     
     ;;
     legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.], textcol=0, box=0, pos=[0.05, ymin+0.07]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]+3.*stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-3.*stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     print, ''
     print, ' A1 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a1[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a1[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_a1[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a1[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun], symsize=symsize   
        bias_tab[0, irun] = median(flux_ratio_a1[wsource[w]])
        rms_tab[0, irun]  = stddev(flux_ratio_a1[wsource[w]])/mean(flux_ratio_a1[wsource[w]])*100
        print, 'nscan = ', nn
        print, 'bias = ', bias_tab[0, irun]
        print, 'rel.rms = ', rms_tab[0, irun] 
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, pos=[0.05, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]+3.0*stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-3.0*stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     print, ''
     print, ' A3 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a3[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a3[wsource])]   )
     xmax  = 0.95
     xmin  = 0.45

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_a3[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a3[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun], symsize=symsize   
        bias_tab[2, irun] = median(flux_ratio_a3[wsource[w]])
        rms_tab[2, irun]  = stddev(flux_ratio_a3[wsource[w]])/mean(flux_ratio_a3[wsource[w]])*100
        print, 'nscan = ', nn
        print, 'bias = ', bias_tab[2, irun]
        print, 'rel.rms = ', rms_tab[2, irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, pos=[0.05, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], [1., 1.]+stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]+3.0*stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], [1., 1.]-3.0*stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'
     ymax = max( [1.4, max(flux_ratio_a2[wsource] )]   )
     ymin = min( [0.6, min(flux_ratio_a2[wsource])]   )
     xmax  = 0.95
     xmin  = 0.55
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, exp(-tau_a2[wsource[w]]/sin(elev[wsource[w]])), flux_ratio_a2[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun], symsize=symsize   
        bias_tab[1, irun] = median(flux_ratio_a2[wsource[w]])
        rms_tab[1, irun]  = stddev(flux_ratio_a2[wsource[w]])/mean(flux_ratio_a2[wsource[w]])*100
        print, 'nscan = ', nn
        print, 'bias = ', bias_tab[1, irun]
        print, 'rel.rms = ', rms_tab[1, irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, pos=[0.03, ymax-0.03], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1., 1.]+3.0*stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     oplot, [xmin,xmax], mean(flux_ratio_a2[wsource])*[1. , 1. ]-3.0*stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource]), col=0, linestyle=2
     xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
     outplot, /close
     

     nselect_tab[3]= n_elements(wsource)
     bias_tab[0,3] = mean(flux_ratio_a1[wsource])
     bias_tab[2,3] = mean(flux_ratio_a3[wsource])
     bias_tab[3,3] = mean(flux_ratio_1mm[wsource])
     bias_tab[1,3] = mean(flux_ratio_a2[wsource])
     
     rms_tab[0, 3] = stddev(flux_ratio_a1[wsource])/mean(flux_ratio_a1[wsource])*100
     rms_tab[2, 3] = stddev(flux_ratio_a3[wsource])/mean(flux_ratio_a3[wsource])*100
     rms_tab[3, 3] = stddev(flux_ratio_1mm[wsource])/mean(flux_ratio_1mm[wsource])*100
     rms_tab[1, 3] = stddev(flux_ratio_a2[wsource])/mean(flux_ratio_a2[wsource])*100
          
     print, ''
     print, 'Combined'
     print, 'total nscan = ',    ntot_tab[3]
     print, 'selected nscan = ', nselect_tab[3]
     
     print, 'A1 bias = ', bias_tab[0,3]
     print, 'A3 bias = ', bias_tab[2,3]
     print, '1mm bias = ',bias_tab[3,3]
     print, 'A2 bias = ', bias_tab[1,3]
     
     print, 'A1 rel.rms = ', rms_tab[0, 3]
     print, 'A3 rel.rms = ', rms_tab[2, 3]
     print, '1mm rel.rms = ',rms_tab[3, 3]
     print, 'A2 rel.rms = ', rms_tab[1, 3]


     ;; SAUVEGARDE FICHIER
     quoi = ['A1', 'A2', 'A3', '1mm']
     calibrun = [calib_run, 'combination']
     if savefile gt 0 then begin
        get_lun, lun
        openw, lun, dir+'Results_flux_density_ratio_allbright'+plot_suffixe+'.txt'
        for irun = 0, nrun do begin
           printf, lun, ''
           printf, lun, calibrun[irun]
           printf, lun, 'ntot = ', ntot_tab[irun]
           printf, lun, 'nselect = ', nselect_tab[irun]
           for ia = 0, 3 do begin
              printf, lun, quoi[ia], ' bias = ', bias_tab[ia, irun], ', rms = ', rms_tab[ia, irun]
           endfor
        endfor
        
        close, lun
     endif
     
     if keyword_set(pdf) then begin
        suf = ['_a1', '_a2', '_a3', '_1mm']
        for i=0, 3 do begin
           spawn, 'epstopdf '+dir+'plot_flux_density_ratio_obstau_allbright'+plot_suffixe+suf[i]+'.eps'
        endfor       
     endif


     ;; HISTOGRAMMES
     
     suf  = ['_a1', '_a2', '_a3', '_1mm']
     quoi = ['A1', 'A2', 'A3', 'A1&A3']

     ratio = [[flux_ratio_a1[wsource]], [flux_ratio_a2[wsource]], $
              [flux_ratio_a3[wsource]] ,[flux_ratio_1mm[wsource]] ]

     limits = [[0.6,1.4], [0.6,1.4], [0.6,1.4], [0.6,1.4]] 
     
     for ia = 0, 3 do begin
        
        print, ''
        print, ' Histo ', quoi[ia]
        print, '-----------------------'
        ymax = max( [limits[1, ia], max(ratio[*, ia]) ])
        ymin = min( [limits[0, ia], min(ratio[*, ia]) ])
        bin  = 0
        
        wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
        outfile = dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+suf[ia]
        outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
        
        f = ratio[*,ia]
        
        np_histo, [f], out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=25, fit=1, noerase=0, position=0, nolegend=1, colorfit=165, thickfit=3., nterms_fit=3, xtitle="Flux density ratio"

        leg_txt = ['N: '+strtrim(string(n_elements(f), format='(i8)'),2), $
                   '!7r!3: '+strtrim(string(out_gpar[0,2]*100, format='(f8.1)'),2)+'%']
        
        legendastro, leg_txt, textcol=0, box=0, pos=[ymax-(ymax-ymin)*0.25, max(out_yhist)]
        legendastro, quoi[ia], textcol=0, box=0, pos=[ymin+(ymax-ymin)*0.07, max(out_yhist)]
     
        outplot, /close
        
        
        if keyword_set(pdf) then $
           spawn, 'epstopdf '+dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+suf[ia]+'.eps'
        
     endfor       

     ;; histo 1 et 2 mm
     ratio_str = {a:flux_ratio_1mm[wsource], b:flux_ratio_a2[wsource]}

     limits = [[0.6,1.4], [0.6,1.4]] 
     
     ymax = max( [limits[1, 0], max(ratio[*, 0]) ])
     ymin = min( [limits[0, 0], min(ratio[*, 0]) ])
     bin  = 0
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+'_1n2mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
       
     ;;np_histo, ratio_str, out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=[col_a3, col_a2], noerase=0, position=0, nolegend=1, xtitle="Flux density ratio", /blend
     
     np_histo, ratio_str, out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=[col_a3, col_a2], noerase=0, position=0, nolegend=1, xtitle="Flux density ratio"

     polyfill, ymin+[1,1,2,2]*(ymax-ymin)*0.07, max(out_yhist)+[0,-1,-1,0]*max(out_yhist)*0.06, col=col_a3
     oplot, ymin+[1,1,2,2, 1]*(ymax-ymin)*0.07, max(out_yhist)+[0,-1,-1,0, 0]*max(out_yhist)*0.06, col=0
     
     polyfill, ymin+[1,1,2,2]*(ymax-ymin)*0.07, max(out_yhist)+[-1.7,-2.7,-2.7,-1.7]*max(out_yhist)*0.06, col=col_a2
     oplot, ymin+[1,1,2,2, 1]*(ymax-ymin)*0.07, max(out_yhist)+[-1.7,-2.7,-2.7,-1.7, -1.7]*max(out_yhist)*0.06, col=0

     xyouts, ymin+2.2*(ymax-ymin)*0.07, max(out_yhist)-1.*max(out_yhist)*0.06, 'A1&A3', col=0
     xyouts, ymin+2.2*(ymax-ymin)*0.07, max(out_yhist)-2.7*max(out_yhist)*0.06, 'A2', col=0
     
     leg_txt = ['N: '+strtrim(string(n_elements(wsource), format='(i8)'),2), $
                '!7r1!3: '+strtrim(string(rms_tab[3,3], format='(f8.1)'),2)+'%', $
                '!7r2!3: '+strtrim(string(rms_tab[1,3], format='(f8.1)'),2)+'%']
     legendastro, leg_txt, textcol=[0,col_a3, col_a2], box=0, pos=[ymax-(ymax-ymin)*0.3, max(out_yhist)-1.*max(out_yhist)*0.06]
     
     outplot, /close

     
     if keyword_set(pdf) then $
        spawn, 'epstopdf '+dir+'plot_histo_flux_density_ratio_obstau_allbright'+plot_suffixe+'_1n2mm.eps'
        


     
     if nostop lt 1 then stop

  endif

  ;;
  ;;   FLUX RATIO AGAINST FWHM
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(fwhm_stability) then begin
     
     col_tab = [col_n2r9, col_n2r12, col_n2r14]
     
     w_total = indgen(nscans)
     wsource = w_total
      
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[wsource] )+0.02 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_1mm, flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        print, ''
        print, calib_run[irun]
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, fwhm_1mm[wsource[w]], flux_ratio_1mm[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[xmax-(xmax-xmin)*0.25, ymin+0.10]
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmax-0.5, ymax-0.05, 'A1&A3', col=0 
     
     
     outplot, /close
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a1[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_a1'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a1, flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for irun=0, nrun-1 do begin
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, fwhm_a1[wsource[w]], flux_ratio_a1[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+0.2, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A1', col=0
     
     outplot, /close
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a3[wsource])-0.02]   )
     xmax  = 14.5
     xmin  = 10.8

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a3, flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, fwhm_a3[wsource[w]], flux_ratio_a3[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+0.2, ymin+0.07], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A3', col=0
     
     outplot, /close
     
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[wsource] )+0.02]   )
     ymin = min( [0.8, min(flux_ratio_a2[wsource])-0.02]   )
     xmax  = 19.5
     xmin  = 17.2
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_flux_density_ratio_FWHM_allbright'+plot_suffixe+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     plot, fwhm_a2, flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     for irun=0, nrun-1 do begin
        w = where(runid[wsource] eq calib_run[irun], nn)
        if nn gt 0 then oplot, fwhm_a2[wsource[w]], flux_ratio_a2[wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun]
     endfor
     ;;
     legendastro, calib_run, col=col_tab, textcol=0, box=0, charsize=charsize, pos=[xmin+0.2, ymax-0.05], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.]
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-0.3, ymax-0.05, 'A2', col=0
     
     outplot, /close
     
     
     

     
     if nostop lt 1 then stop

  endif

  
  if nostop lt 1 then stop
  
     

end
