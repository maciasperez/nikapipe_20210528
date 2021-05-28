pro beam_monitoring_with_otf, png=png, ps=ps, pdf=pdf, $
                              nostop = nostop, savefile = savefile, $
                              compare_to_pointings=compare_to_pointings
  
  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)
  
  ;; Flux threshold for sources selection
  ;;--------------------------------------------
  flux_threshold_1mm = 1.0d0
  flux_threshold_2mm = 1.0d0

  
  ;; outplot directory
  dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/Beams/'

  if keyword_set(nostop) then nostop = 1 else nostop = 0
  if keyword_set(savefile) then savefile = 1 else savefile = 0
  
    
  plotname = 'Beam_monitoring_with_otfs_vs_ut'


  ;; plot aspect
  ;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 700.
  wysize = 400.
  ;; plot size in files
  pxsize = 14.
  pysize =  8.
  ;; charsize
  charsize  = 1.2
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 1.0
  symsize   = 1.
  

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
  point_fwhm_1mm     = 0.
  point_fwhm_a2      = 0.
  point_fwhm_a1      = 0.
  point_fwhm_a3      = 0.
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
  focus_z      = 0.
  
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
                      '20170226s416','20170226s417', '20170226s418', '20170226s419', $ ;; defocused beammaps
                      '20170227s291', '20170227s292','20170227s293', '20170227s294', '20170227s295',$ ;; defocused beammaps
                      '20180115s108', '20180115s109']  ;; tests before pool 
     
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
     allscan_info = allscan_info[wpoint]
         
     nscans       = n_elements(allscan_info)
     
     
     ;; URANUS: correction for finite apparent disc
     ;;-------------------------------------------------------------------
     beam_widening_offset = [0.19, 0.12]
     wu = where(strupcase(allscan_info.object) eq 'URANUS', nuranus)
     allscan_info.result_fwhm_1mm[wu] = allscan_info.result_fwhm_1mm[wu] - beam_widening_offset[0]
     allscan_info.result_fwhm_2[wu]   = allscan_info.result_fwhm_2[wu] - beam_widening_offset[1]
     allscan_info.result_fwhm_1[wu]   = allscan_info.result_fwhm_1[wu] - beam_widening_offset[0]
     allscan_info.result_fwhm_3[wu]   = allscan_info.result_fwhm_3[wu] - beam_widening_offset[0]
     ;; X
     allscan_info.result_fwhm_x_1mm[wu] = allscan_info.result_fwhm_x_1mm[wu] - beam_widening_offset[0]
     allscan_info.result_fwhm_x_2[wu]   = allscan_info.result_fwhm_x_2[wu] - beam_widening_offset[1]
     allscan_info.result_fwhm_x_1[wu]   = allscan_info.result_fwhm_x_1[wu] - beam_widening_offset[0]
     allscan_info.result_fwhm_x_3[wu]   = allscan_info.result_fwhm_x_3[wu] - beam_widening_offset[0]
     ;; Y
     allscan_info.result_fwhm_y_1mm[wu] = allscan_info.result_fwhm_y_1mm[wu] - beam_widening_offset[0]
     allscan_info.result_fwhm_y_2[wu]   = allscan_info.result_fwhm_y_2[wu] - beam_widening_offset[1]
     allscan_info.result_fwhm_y_1[wu]   = allscan_info.result_fwhm_y_1[wu] - beam_widening_offset[0]
     allscan_info.result_fwhm_y_3[wu]   = allscan_info.result_fwhm_y_3[wu] - beam_widening_offset[0]
  
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
     fwhm_x_1mm     = [fwhm_x_1mm, allscan_info.result_fwhm_x_1mm]
     fwhm_x_a2      = [fwhm_x_a2, allscan_info.result_fwhm_x_2]
     fwhm_x_a1      = [fwhm_x_a1, allscan_info.result_fwhm_x_1]
     fwhm_x_a3      = [fwhm_x_a3, allscan_info.result_fwhm_x_3]
     ;;
     fwhm_y_1mm     = [fwhm_y_1mm, allscan_info.result_fwhm_y_1mm]
     fwhm_y_a2      = [fwhm_y_a2, allscan_info.result_fwhm_y_2]
     fwhm_y_a1      = [fwhm_y_a1, allscan_info.result_fwhm_y_1]
     fwhm_y_a3      = [fwhm_y_a3, allscan_info.result_fwhm_y_3]
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
     focus_z      = [focus_z, allscan_info.focusz]
     ;;

     if keyword_set(compare_to_pointings) then begin
        
        nscans = n_elements(allscan_info.ut)
        day_run = allscan_info.day
        ut_otf  = fltarr(nscans)
        ut_run  = strmid(allscan_info.ut, 0, 5)
        for i = 0, nscans-1 do begin
           ut_otf[i]  = float((STRSPLIT(ut_run[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut_run[i], ':', /EXTRACT))[1])/60.
        endfor
        get_pointing_based_beams, fwhm_point, day_run, ut_otf, calib_run[irun]
        
        point_fwhm_1mm     = [point_fwhm_1mm, fwhm_point[*, 3]]
        point_fwhm_a2      = [point_fwhm_a2, fwhm_point[*, 1]]
        point_fwhm_a1      = [point_fwhm_a1, fwhm_point[*, 0]]
        point_fwhm_a3      = [point_fwhm_a3, fwhm_point[*, 2]]
            
     endif

     
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
  if keyword_set(compare_to_pointings) then begin
     point_fwhm_1mm     = point_fwhm_1mm[1:*]
     point_fwhm_a2      = point_fwhm_a2[1:*]
     point_fwhm_a1      = point_fwhm_a1[1:*]
     point_fwhm_a3      = point_fwhm_a3[1:*]
  endif
  ;;
  fwhm_x_1mm     = fwhm_x_1mm[1:*]
  fwhm_x_a2      = fwhm_x_a2[1:*]
  fwhm_x_a1      = fwhm_x_a1[1:*]
  fwhm_x_a3      = fwhm_x_a3[1:*]
  ;;
  fwhm_y_1mm     = fwhm_y_1mm[1:*]
  fwhm_y_a2      = fwhm_y_a2[1:*]
  fwhm_y_a1      = fwhm_y_a1[1:*]
  fwhm_y_a3      = fwhm_y_a3[1:*]
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
  focus_z      = focus_z[1:*] 
  
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
                         col_n2r9, col_n2r12, col_n2r14, col_1mm

  ut_tab = ['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '21:00', '22:00', '24:00']

  ut_col = [10, 35, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25, 15]
  nut = n_elements(ut_tab)-1

  col_tab = [col_n2r9, col_n2r12, col_n2r14]
  
  w_total = indgen(nscans)
  wsource = w_total

  source = strlowcase(obj)
  wp = where(source eq 'uranus' or source eq 'mars' or source eq 'saturn' or source eq 'neptune', np, compl=ws, ncompl=ns)


  
  ;; 1mm
  ;;----------------------------------------------------------
  print, ''
  print, ' 1mm '
  print, '-----------------------'
  ymax = 17.
  ymin = 9.
  xmax  = 0.
  xmin  = 24.     
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+plotname+'_1mm'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  plot, ut_float, fwhm_1mm, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
  for irun=0, nrun-1 do begin
     w = where(runid[wp] eq calib_run[irun], nn)
     if nn gt 0 then oplot, ut_float[wp[w]], fwhm_1mm[wp[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[irun], symsize=symsize*0.8
     w = where(runid[ws] eq calib_run[irun], nn)
     if nn gt 0 then oplot, ut_float[ws[w]], fwhm_1mm[ws[w]], psym=cgsymcat('FILLEDSTAR', thick=thick), col=col_tab[irun]
  endfor
  oplot, [0, 24], [11.3, 11.3], col=0
  
  polyfill, [9, 10, 10, 9], [ymin, ymin, ymax, ymax], col=0, thick=thick/2, line_fill=1, orientation=45, spacing=0.3
  oplot, [9, 9],   [ymin, ymax], col=0, thick=thick/2.
  oplot, [10, 10], [ymin, ymax], col=0, thick=thick/2.
  polyfill, [15, 22, 22, 15], [ymin, ymin, ymax, ymax], col=0, thick=thick/2,line_fill=1, orientation=45, spacing=0.3 
  oplot, [15, 15], [ymin, ymax], col=0, thick=thick/2.
  oplot, [22, 22], [ymin, ymax], col=0, thick=thick/2.
  
  xyouts, 1., 10., 'A1&A3', col=0

  legendastro, calib_run, col=col_tab, textcol=col_tab, box=0, charsize=charsize, pos=[1, 16.]
  
  outplot, /close
  
  ;; A1
  ;;----------------------------------------------------------
  print, ''
  print, ' A1 '
  print, '-----------------------'
  ymax = min( [18., max(fwhm_a1[wsource] )]   )
  ymin = 8.
  xmax  = 0.
  xmin  = 24.     
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+plotname+'_a1'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  plot, ut_float, fwhm_a1, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
  for irun=0, nrun-1 do begin
     w = where(runid[wsource] eq calib_run[irun], nn)
     if nn gt 0 then oplot, ut_float[wsource[w]], fwhm_a1[wsource[w]], psym=8, col=col_tab[irun]
  endfor
  oplot, [0, 24], [11.3, 11.3], col=0
  xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1', col=0 
  
  outplot, /close
  
  ;; A3
  ;;----------------------------------------------------------
  print, ''
  print, ' A3 '
  print, '-----------------------'
  ymax = min( [18., max(fwhm_a3[wsource] )]   )
  ymin = 8.
  xmax  = 0.
  xmin  = 24.     
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+plotname+'_a3'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  plot, ut_float, fwhm_a3, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
  for irun=0, nrun-1 do begin
     w = where(runid[wsource] eq calib_run[irun], nn)
     if nn gt 0 then oplot, ut_float[wsource[w]], fwhm_a3[wsource[w]], psym=8, col=col_tab[irun]
  endfor
  oplot, [0, 24], [11.3, 11.3], col=0
  xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A3', col=0 
  
  outplot, /close
  
  ;; A2
  ;;----------------------------------------------------------
  print, ''
  print, ' A2 '
  print, '-----------------------'
  ymax = 20.
  ymin = 16.5
  xmax  = 0.
  xmin  = 24.     
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+plotname+'_a2'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  plot, ut_float, fwhm_a2, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
  for irun=0, nrun-1 do begin
     w = where(runid[wp] eq calib_run[irun], nn)
     if nn gt 0 then oplot, ut_float[wp[w]], fwhm_a2[wp[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[irun], symsize=symsize*0.8
     w = where(runid[ws] eq calib_run[irun], nn)
     if nn gt 0 then oplot, ut_float[ws[w]], fwhm_a2[ws[w]], psym=cgsymcat('FILLEDSTAR', thick=thick), col=col_tab[irun]
  endfor
  oplot, [0, 24], [17.5, 17.5], col=0
  xyouts, 2., 16.9, 'A2', col=0
  polyfill, [9, 10, 10, 9], [ymin, ymin, ymax, ymax], col=0, thick=thick/2, line_fill=1, orientation=45, spacing=0.3
  oplot, [9, 9],   [ymin, ymax], col=0, thick=thick/2.
  oplot, [10, 10], [ymin, ymax], col=0, thick=thick/2.
  polyfill, [15, 22, 22, 15], [ymin, ymin, ymax, ymax], col=0, thick=thick/2,line_fill=1, orientation=45, spacing=0.3 
  oplot, [15, 15], [ymin, ymax], col=0, thick=thick/2.
  oplot, [22, 22], [ymin, ymax], col=0, thick=thick/2.
  legendastro, ['Planets'], psym=[cgsymcat('FILLEDCIRCLE', thick=thick)], col=[0], textcol=0, box=0, charsize=charsize, pos=[2, 19.5], symsize=symsize*0.8
  legendastro, ['Others'], psym=[cgsymcat('FILLEDSTAR', thick=thick)], col=[0], textcol=0, box=0, charsize=charsize, pos=[2, 19.2]
  
  outplot, /close


  if keyword_set(pdf) then begin
     ;;spawn, 'epspdf --bbox '+dir+plotname+'_1mm.eps'
     ;;spawn, 'epspdf --bbox '+dir+plotname+'_a2.eps'
     spawn, 'epstopdf '+dir+plotname+'_1mm.eps'
     spawn, 'epstopdf '+dir+plotname+'_a2.eps'
  endif

  

  if nostop lt 1 then stop

  wsel = where(ut_float le 9 or $
               ut_float ge 22. or $
               (ut_float ge 10. and ut_float le 15.), nn, compl=wout)
  print,"avg FWHM 2mm sel = ", mean(fwhm_a2(wsel))
  print,"avg FWHM 1mm sel = ", mean(fwhm_1mm(wsel))
  print,"avg FWHM 2mm out = ", mean(fwhm_a2(wout))
  print,"avg FWHM 1mm out = ", mean(fwhm_1mm(wout))
  
  wsel = where(ut_float(ws) le 9 or $
               ut_float(ws) ge 22. or $
               (ut_float(ws) ge 10. and ut_float(ws) le 15.), nn, compl=wout)
  print,"avg FWHM 2mm sel = ", mean(fwhm_a2[ws[wsel]]), median(fwhm_a2[ws[wsel]])
  print,"avg FWHM 1mm sel = ", mean(fwhm_1mm[ws[wsel]]), median(fwhm_1mm[ws[wsel]])
  print,"avg FWHM 2mm out = ", mean(fwhm_a2[ws[wout]]), median(fwhm_a2[ws[wout]])
  print,"avg FWHM 1mm out = ", mean(fwhm_1mm[ws[wout]]), median(fwhm_1mm[ws[wout]])

  wsel = where(ut_float(wp) le 9 or $
               ut_float(wp) ge 22. or $
               (ut_float(wp) ge 10. and ut_float(wp) le 15.), nn, compl=wout)
  print,"avg FWHM 2mm sel = ", mean(fwhm_a2[wp[wsel]]), median(fwhm_a2[wp[wsel]])
  print,"avg FWHM 1mm sel = ", mean(fwhm_1mm[wp[wsel]]), median(fwhm_1mm[wp[wsel]])
  print,"avg FWHM 2mm out = ", mean(fwhm_a2[wp[wout]]), median(fwhm_a2[wp[wout]])
  print,"avg FWHM 1mm out = ", mean(fwhm_1mm[wp[wout]]), median(fwhm_1mm[wp[wout]])
  
  w = where(ut_float le 9 and fwhm_1mm gt 12., nn)
  w = where(ut_float gt 22. and fwhm_1mm gt 12., nn)
  w = where(ut_float ge 10. and ut_float le 15. and fwhm_1mm gt 12., nn)

  if nostop lt 1 then stop
  
   
  if keyword_set(compare_to_pointings) then begin


     col_tab = [245, 76]
     w_total = indgen(nscans)
     wsource = w_total
     
     source = strlowcase(obj)
     wp = where(source eq 'uranus' or source eq 'mars' or source eq 'saturn' or source eq 'neptune', np, compl=ws, ncompl=ns)
     
     plotname = plotname+'_compare_pointings'
     ;; 1mm
     ;;----------------------------------------------------------
     print, ''
     print, ' 1mm '
     print, '-----------------------'
     ymax = 17.
     ymin = 9.
     xmax  = 0.
     xmin  = 24.     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+plotname+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     plot, ut_float, fwhm_1mm, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata

     oplot, ut_float[wp], fwhm_1mm[wp], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[0] , symsize=symsize*0.8
     oplot, ut_float[ws], fwhm_1mm[ws], psym=cgsymcat('FILLEDSTAR', thick=thick),   col=col_tab[0]
     
     oplot, ut_float[wp], point_fwhm_1mm[wp], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[1] , symsize=symsize*0.8
     oplot, ut_float[ws], point_fwhm_1mm[ws], psym=cgsymcat('FILLEDSTAR', thick=thick),   col=col_tab[1]

     oplot, [0, 24], [11.3, 11.3], col=0
     
     polyfill, [9, 10, 10, 9], [ymin, ymin, ymax, ymax], col=0, thick=thick/2, line_fill=1, orientation=45, spacing=0.3
     oplot, [9, 9],   [ymin, ymax], col=0, thick=thick/2.
     oplot, [10, 10], [ymin, ymax], col=0, thick=thick/2.
     polyfill, [15, 22, 22, 15], [ymin, ymin, ymax, ymax], col=0, thick=thick/2,line_fill=1, orientation=45, spacing=0.3 
     oplot, [15, 15], [ymin, ymax], col=0, thick=thick/2.
     oplot, [22, 22], [ymin, ymax], col=0, thick=thick/2.
     
     xyouts, 1., 10., 'A1&A3', col=0
     
     legendastro, ['OTF', 'Pointing'], col=col_tab, textcol=col_tab, box=0, charsize=charsize, pos=[1, 16.]
     
     outplot, /close
     
 
     
     ;; A2
     ;;----------------------------------------------------------
     print, ''
     print, ' A2 '
     print, '-----------------------'
     ymax = 20.
     ymin = 16.5
     xmax  = 0.
     xmin  = 24.     
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+plotname+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     plot, ut_float, fwhm_a2, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
     ;;
     oplot, ut_float[wp], fwhm_a2[wp], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[0], symsize=symsize*0.8
     oplot, ut_float[ws], fwhm_a2[ws], psym=cgsymcat('FILLEDSTAR', thick=thick), col=col_tab[0]
     oplot, ut_float[wp], point_fwhm_a2[wp], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[1], symsize=symsize*0.8
     oplot, ut_float[ws], point_fwhm_a2[ws], psym=cgsymcat('FILLEDSTAR', thick=thick), col=col_tab[1]
     ;;


     
     oplot, [0, 24], [17.5, 17.5], col=0
     xyouts, 2., 16.9, 'A2', col=0
     polyfill, [9, 10, 10, 9], [ymin, ymin, ymax, ymax], col=0, thick=thick/2, line_fill=1, orientation=45, spacing=0.3
     oplot, [9, 9],   [ymin, ymax], col=0, thick=thick/2.
     oplot, [10, 10], [ymin, ymax], col=0, thick=thick/2.
     polyfill, [15, 22, 22, 15], [ymin, ymin, ymax, ymax], col=0, thick=thick/2,line_fill=1, orientation=45, spacing=0.3 
     oplot, [15, 15], [ymin, ymax], col=0, thick=thick/2.
     oplot, [22, 22], [ymin, ymax], col=0, thick=thick/2.
     legendastro, ['Planets'], psym=[cgsymcat('FILLEDCIRCLE', thick=thick)], col=[0], textcol=0, box=0, charsize=charsize, pos=[2, 19.5], symsize=symsize*0.8
     legendastro, ['Others'], psym=[cgsymcat('FILLEDSTAR', thick=thick)], col=[0], textcol=0, box=0, charsize=charsize, pos=[2, 19.2]
     
     outplot, /close
     
     
     if keyword_set(pdf) then begin
        ;;spawn, 'epspdf --bbox '+dir+plotname+'_1mm.eps'
        ;;spawn, 'epspdf --bbox '+dir+plotname+'_a2.eps'
        spawn, 'epstopdf '+dir+plotname+'_1mm.eps'
        spawn, 'epstopdf '+dir+plotname+'_a2.eps'
     endif
     
     
     
     stop
  endif
     
  
  if nostop lt 1 then stop 

end
