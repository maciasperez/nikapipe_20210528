;
;   NIKA2 performance assessment
; 
;   NEFD using the "pipeline method"
;
;   LP, July 2018
;   from Scr/Reference/Draw_plots/nefd_multirun.pro
;   from LP/script/n2r10/check_nefd_multirun.pro
;__________________________________________________________

pro nefd_vs_observed_opacity, png=png, ps=ps

  calib_run = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)
  
  ;; outplot directory
  dir     = getenv('HOME')+'/NIKA/Plots/Performance_plots/'

  ;;________________________________________________________________
  ;;
  ;; get all result files
  ;;________________________________________________________________
  ;;________________________________________________________________
  outdir = '/home/perotto/NIKA/Plots/Performance_plots/'
  get_all_scan_result_files, result_files, outputdir = outdir


  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________
  
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
  tau_1mm      = 0.0d0
  tau_a2       = 0.0d0
  tau_a1       = 0.0d0
  tau_a3       = 0.0d0
  ;;
  elev         = 0.
  obj          = ''
  day          = ''
  ut           = ''
  runid        = ''
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
     ;;  restore the result tables
     ;;____________________________________________________________
     restore, allresult_file, /v

     ;;
     ;; scan selection
     ;;____________________________________________________________
     to_use_photocorr = 0
     wout       = 1
     wlargebeam = 1 
     wdaytime   = 1
     whitau3    = 1
     fwhm_max   = 1
     nefd_index = 1
     baseline_scan_selection, allscan_info, wbaseline, $
                     to_use_photocorr=to_use_photocorr, complement_index=wout, $
                     beamok_index = beamok_index, largebeam_index = wlargebeam,$
                     tauok_index = tauok_index, hightau_index=whitau3, $
                     osbdateok_index=obsdateok_index, afternoon_index=wdaytime, $
                     fwhm_max = fwhm_max, nefd_index = nefd_index
     
     ;mask = intarr(nscans)
     ;mask[nefd_index] = 1
     ;index_baseline = [index_baseline, mask]
   
     allscan_info = allscan_info[nefd_index]

     w1 = where(allscan_info.result_flux_i_1mm lt 1.0d0 and allscan_info.result_flux_i_2mm lt 1.0d0, n1) 
     allscan_info = allscan_info[w1]
     print,'Run ', calib_run[irun], ' nscans = ', n1
   
     ;; ws = where(strlowcase(info_all.object) ne 'ic342' and $
     ;;            strlowcase(info_all.object) ne 'ngc588' and $
     ;;            strlowcase(info_all.object) ne 'mooj1142' and $
     ;;            strlowcase(info_all.object) ne 'jkcs041' and $
     ;;            strlowcase(info_all.object) ne 'g2' , ns )
     ;; info_all = info_all[ws]
     ;; print,'Run ', run[irun], ' nscans = ', ns
   
     ws = where(strlowcase(allscan_info.object) ne 'ic342' and $
                strlowcase(allscan_info.object) ne 'gp_l23p3' and $
                strlowcase(allscan_info.object) ne 'gp_l23p9' and $
                strlowcase(allscan_info.object) ne 'jkcs041' and $
                                ;strlowcase(allscan_info.object) ne 'macs1206' and $
                strlowcase(allscan_info.object) ne 'gp_l24p5', ns )
     allscan_info = allscan_info[ws]
     print,'Run ', calib_run[irun], ' nscans = ', ns
     
     nefd_list = strtrim(string(allscan_info.day, format='(i8)'), 2)+'s'+$
                 strtrim(string(allscan_info.scan_num, format='(i8)'), 2)
     ;;save, nefd_list, filename=juan_list_file

     scan_list    = [scan_list, allscan_info.scan]
     
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
     eta_a2       = [eta_a2, allscan_info.result_nkids_valid2/616.0] ;!nika.ntot_nom[1]
     eta_1mm      = [eta_1mm, (allscan_info.result_nkids_valid1+allscan_info.result_nkids_valid3)/2d/1140.0d0]
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
  




  
;; hybrid opacity
  h_tau_a2 = tau_a1*modified_atm_ratio(tau_a1)

  

  
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


  
  ;;________________________________________________________________
  ;;
  ;; plots
  ;;________________________________________________________________
  ;;________________________________________________________________
  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14

  col_tab = [col_n2r9, col_n2r12, col_n2r14]

  run_index = [1, 2, 0]

  ;; 1mm
  ;;----------------------------------------------------------
  print, ''
  print, ' 1mm '
  print, '-----------------------'
  
  ymax = min( [180., max(nefd_1mm)]  )
  ymin = min( [0., min(nefd_1mm)]   )
  xmax  = 0.8
  xmin  = 0.
  
  obs_tau = tau_1mm/sin(elev)
  
  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_nefd_vs_obstau_1mm'
  outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
  
  plot, obs_tau, nefd_1mm, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='Observed opacity', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  obstau = dindgen(1000)/1000.
  for ir=0, nrun-1 do begin
     irun = run_index[ir]
     print, ''
     print, calib_run[irun]
     w = where(runid eq calib_run[irun], nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
     w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5 and runid eq calib_run[irun], nn)
     
     nefd_0 = median(nefd_1mm[w_obstau]/exp(obs_tau[w_obstau]))
     nefd_iram = nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd_0
     print, 'NEFD IRAM = ', nefd_iram
     
     oplot, obstau, nefd_0*exp(obstau), col=col_tab[irun]
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

  
  ymax = min( [300., max(nefd_a1)]   )
  ymin = min( [0., min(nefd_a1)]   )
  xmax  = 0.8
  xmin  = 0.0
  
  obs_tau = tau_a1/sin(elev)
  
  wind, 1, 1, /free, xsize=600, ysize=400 
  outfile = dir+'plot_nefd_vs_obstau_a1'
  outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
  
  plot, obs_tau, nefd_a1, /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='Observed opacity', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
  
  obstau = dindgen(1000)/1000.
  for ir=0, nrun-1 do begin
     irun = run_index[ir]
     print, ''
     print, calib_run[irun]
     w = where(runid eq calib_run[irun], nn)
     if nn gt 0 then oplot, obs_tau[w], nefd_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
     w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5 and runid eq calib_run[irun], nn)
     
     nefd_0 = median(nefd_a1[w_obstau]/exp(obs_tau[w_obstau]))
     nefd_iram = nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd_0
     print, 'NEFD IRAM = ', nefd_iram
     
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
     ymax = min( [300., max(nefd_a3)]   )
     ymin = min( [0.0, min(nefd_a3)]   )
     xmax  = 0.8
     xmin  = 0.0
     
     obs_tau = tau_a3/sin(elev)
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_nefd_vs_obstau_a3'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, obs_tau, nefd_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
     obstau = dindgen(1000)/1000.
     for ir=0, nrun-1 do begin
        irun=run_index[ir]
        print, ''
        print, calib_run[irun]
        w = where(runid eq calib_run[irun], nn)
        if nn gt 0 then oplot, obs_tau[w], nefd_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun],symsize=0.5
        w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5 and runid eq calib_run[irun], nn)
     
        nefd_0 = median(nefd_a3[w_obstau]/exp(obs_tau[w_obstau]))
        nefd_iram = nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor))
        print, 'NEFD_0 = ', nefd_0
        print, 'NEFD IRAM = ', nefd_iram
        
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

     ymax = min( [40., max(nefd_a2)]   )
     ymin = min( [0., min(nefd_a2)]   )
     xmax  = 0.55
     xmin  = 0.00
     
     obs_tau = h_tau_a2/sin(elev)
     
     wind, 1, 1, /free, xsize=600, ysize=400 
     outfile = dir+'plot_nefd_vs_obstau_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=12, ysize=8, charsize=1, thick=2, charthick=1.2
     
     plot, obs_tau, nefd_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Observed opacity', ytitle='NEFD [mJy.s^0.5]', /ys, /nodata
     obstau = dindgen(1000)/1000.
     for ir=0, nrun-1 do begin
        irun=run_index[ir]
        print, ''
        print, calib_run[irun]
        w = where(runid eq calib_run[irun], nn)
        if nn gt 0 then oplot,obs_tau[w], nefd_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=2), col=col_tab[irun], symsize=0.5
        w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5 and runid eq calib_run[irun], nn)
        
        nefd_0 = median(nefd_a2[w_obstau]/exp(obs_tau[w_obstau]))
        nefd_iram = nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
        print, 'NEFD_0 = ', nefd_0
        print, 'NEFD IRAM = ', nefd_iram
        
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
     obs_tau = tau_1mm/sin(elev)
     w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5, nn)
     nefd_0 = median(nefd_1mm[w_obstau]/exp(obs_tau[w_obstau]))
     nefd_iram = nefd_0*exp(atm_tau1/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd_0
     print, 'NEFD IRAM = ', nefd_iram
     print, ''
     print, 'A1'
     obs_tau = tau_a1/sin(elev)
     w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5, nn)
     nefd_0 = median(nefd_a1[w_obstau]/exp(obs_tau[w_obstau]))
     nefd_iram = nefd_0*exp(atm_tau_a1/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd_0
     print, 'NEFD IRAM = ', nefd_iram
     print, ''
     print, 'A3'
     obs_tau = tau_a3/sin(elev)
     w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5, nn)
     nefd_0 = median(nefd_a3[w_obstau]/exp(obs_tau[w_obstau]))
     nefd_iram = nefd_0*exp(atm_tau_a3/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd_0
     print, 'NEFD IRAM = ', nefd_iram
     print, ''
     print, 'A2'
     obs_tau = h_tau_a2/sin(elev)
     w_obstau = where(obs_tau gt 0.0 and obs_tau le 0.5, nn)
     nefd_0 = median(nefd_a2[w_obstau]/exp(obs_tau[w_obstau]))
     nefd_iram = nefd_0*exp(atm_tau2/sin(60.0d0*!dtor))
     print, 'NEFD_0 = ', nefd_0
     print, 'NEFD IRAM = ', nefd_iram
     
     
     

     
     stop

 






end
