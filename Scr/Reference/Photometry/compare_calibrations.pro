pro compare_calibrations

  ;nickname_tab = ['inclusive_skydip_opacorr4_NoTauCorrect0', 'low_skydip_opacorr4_NoTauCorrect0', 'refkidpar_NoTauCorrect0']
  nickname_tab = ['N2R9_newc0c1_baseline_v2_NP', 'N2R9_ref_baseline_v2']
  
  ;;plotname = '3sol_low'
  ;;plotname = '3sol_opacorr1'
  plotname = 'NPtest_baseline'
  tabcol = [80, 250, 150]
  ;;tableg = ['38skd', '22skd', 'ref']
  tableg = ['NP', 'Exp']
  ncal = n_elements(nickname_tab)

  pivot_scan = '20170226s126'
  
;; MWC349
;;---------------------------------------------------------------
  source            = 'MWC349'
  lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
  nu = !const.c/(lambda*1e-3)/1.0d9
  th_flux           = 1.69d0*(nu/227.)^0.26
  th_flux           = 1.16d0*(nu/100.0)^0.60
;; assuming indep param
  err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
  
  fill_nika_struct, '22'

  
  outlier_list = ''
  
;; FWHM selection cut
  fwhm_a1_max = 12.0
  fwhm_a3_max = 12.0
  fwhm_a2_max = 17.9


  elevation_min = 0.
  
  fwhm_a1_min = 10.             ;11.
  fwhm_a3_min = 10.             ;11.
  fwhm_a2_min = 16.             ;17.
;;==================
  
  png               = 1
  ps                = 0
  outplot_dir       = '/home/perotto/NIKA/Plots/N2R9/Photometry'
  
;; Scan selection
  
  restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v00.save"
  
  dz1 = abs(scan.focusz_mm - shift(scan.focusz_mm, -1)) ; 0.8
  dz2 = scan.focusz_mm - shift(scan.focusz_mm, -2)      ; 0.4
  dz3 = scan.focusz_mm - shift(scan.focusz_mm, -3)      ; -0.4
  dz4 = scan.focusz_mm - shift(scan.focusz_mm, -4)      ; -0.8
  
  dx1 = abs(scan.focusx_mm - shift(scan.focusx_mm, -1)) ; 1.4
  dx2 = scan.focusx_mm - shift(scan.focusx_mm, -2)      ; 0.7
  dx3 = scan.focusx_mm - shift(scan.focusx_mm, -3)      ; -0.7
  dx4 = scan.focusx_mm - shift(scan.focusx_mm, -4)      ; -1.4
  
  dy1 = abs(scan.focusy_mm - shift(scan.focusy_mm, -1)) ; 1.4
  dy2 = scan.focusy_mm - shift(scan.focusy_mm, -2)      ; 0.7
  dy3 = scan.focusy_mm - shift(scan.focusy_mm, -3)      ; -0.7
  dy4 = scan.focusy_mm - shift(scan.focusy_mm, -4)      ;-1.4
  
  wfocus = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
                 (dz1 gt 0.3 or dx1 gt 0.5 or dy1 gt 0.5)   $
                 , nscans, compl=wok, ncompl=nok)
  
  wtokeep = where(strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' $
                  and scan[wok].n_obs gt 4  $
                  and strupcase(scan[wok].object) eq strupcase(source) $
                  and scan[wok].el_deg gt elevation_min, nkeep)
  
  
  scan_str = scan[wok[wtokeep]]
  scan_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)
  
  print, scan_list
  
;; remove outliers if any
;; define outlier_list and relaunch
;;-------------------------------------------------------------
  if (n_elements(outlier_list) gt 0 and outlier_list[0] ne '') then begin
     scan_list_ori = scan_list
     remove_scan_from_list, scan_list_ori, outlier_list, scan_list
  endif
  
  nscans = n_elements(scan_list)
  
  nk_scan2run, scan_list[0]
  
  if not keyword_set(outplot_dir) then outplot_dir=!nika.plot_dir
  
  scan_list = scan_list[ sort(scan_list)]
  nscans = n_elements(scan_list)
  
  flux        = fltarr(nscans, 3, ncal)
  err_flux    = fltarr(nscans, 3, ncal)
  tau_1mm     = fltarr(nscans, ncal)
  tau_2mm     = fltarr(nscans, ncal)
  fwhm        = fltarr(nscans,3, ncal)
  nsub        = intarr(nscans, ncal)
  elev        = fltarr(nscans, ncal)
  ut          = strarr(nscans, ncal)

  for ic=0, ncal-1 do begin
     project_dir = outplot_dir+"/"+source+"_photometry_"+nickname_tab[ic]
     print,project_dir
     for i =0, nscans-1 do begin
        dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
        if file_test(dir+"/results.save") then begin
           restore,  dir+"/results.save"
           
           if info1.polar eq 1 then print, scan_list[i]+" is polarized !"
           fwhm[i,0,ic] = info1.result_fwhm_1
           fwhm[i,1,ic] = info1.result_fwhm_2
           fwhm[i,2,ic] = info1.result_fwhm_3
           
           flux[i, 0,ic] = info1.result_flux_i1
           flux[i, 1,ic] = info1.result_flux_i2
           flux[i, 2,ic] = info1.result_flux_i3
           
           tau_1mm[ i,ic] = info1.result_tau_1mm
           tau_2mm[ i,ic] = info1.result_tau_2mm
           err_flux[i, 0,ic] = info1.result_err_flux_i1
           err_flux[i, 1,ic] = info1.result_err_flux_i2
           err_flux[i, 2,ic] = info1.result_err_flux_i3
           
           nsub[i,ic]        = info1.nsubscans
           elev[i,ic]        = info1.RESULT_ELEVATION_DEG
           ut[i,ic]          = strmid(info1.ut, 0, 5)
        endif else print, strtrim(scan_list[i], 2), ': results not found'
     endfor
  endfor
  
  day_list = strmid(scan_list,0,8)


  ipivot = where(scan_list eq pivot_scan)
  ipivot = ipivot[0]
  
  index = dindgen(nscans)
  
  fmt = "(F5.1)"
  wind, 1, 1, /free, /large
  outfile = project_dir+'/compare_1_photometry_'+strtrim(source)+'_'+strtrim(plotname,2)
  
  outplot, file=outfile, png=png, ps=ps
  my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
  !x.charsize = 1e-10

  
  yra=th_flux[0]*[0.7, 1.3]
  plot,index, flux[*,0,0]/flux[ipivot,0,0], ytitle='Flux Jy', xr=[-1,nscans], /xs, $
       position=pp1[0,*], yra=yra, /ys, /nodata,title='normalised at pivot '+strtrim(pivot_scan)
  for j=0, ncal-1 do oploterror, index+j*0.15, flux[*, 0, j]/flux[ipivot,0,j]*th_flux[0], err_flux[*,0,j], psym=8, col=tabcol[j], errcol=tabcol[j]
  oplot, [-1,nscans], th_flux[0]*[1., 1.], col=250
  legendastro, ['Array 1'], box=0, pos=[-0.5, yra[1]*0.9]
  legendastro, tableg, textcol=tabcol, box=0, /right, /bottom
  myday = day_list[0]
  for i=0, nscans-1 do begin
     if day_list[i] ne myday then begin
        oplot, [i,i]*1, [-1,1]*1e10
        myday = day_list[i]
     endif
  endfor
  
  yra=th_flux[2]*[0.7, 1.3]
  plot,       index, flux[*, 2, 0], ytitle='Flux Jy', xr=[-1,nscans], /xs, $
              position=pp1[1,*], /noerase, yra=yra, /ys, /nodata
  for j=0, ncal-1 do oploterror, index+j*0.15, flux[*, 2, j]/flux[ipivot, 2, j]*th_flux[2], err_flux[*, 2 ,j], psym=8, col=tabcol[j], errcol=tabcol[j] 
  oplot, [-1,nscans], th_flux[2]*[1., 1.], col=250
  legendastro, ['Array 3'], box=0, pos=[-0.5, yra[1]*0.9]
  myday = day_list[0]
  for i=0, nscans-1 do begin
     if day_list[i] ne myday then begin
        oplot, [i,i]*1, [-1,1]*1e10
        myday = day_list[i]
     endif
  endfor
  
  yra=th_flux[1]*[0.8, 1.9]
  plot,       index, flux[*, 1, 0], ytitle='Flux Jy',xr=[-1,nscans], /xs, $
              position=pp1[2,*], /noerase, yra=yra, /ys, /nodata
  for j=0, ncal-1 do oploterror, index+j*0.15, flux[*, 1, j]*(th_flux[1]/flux[ipivot, 1, j]), err_flux[*, 1 ,j], psym=8, col=tabcol[j], errcol=tabcol[j] 
  oplot, [-1,nscans], th_flux[1]*[1., 1.], col=250
  xyouts, index, replicate(th_flux[1]*1.1, nscans), strmid(scan_list,6, 12), charsi=0.7, orient=90
  legendastro, ['Array 2'], box=0, pos=[-0.5, yra[1]*0.9]
  myday = day_list[0]
  for i=0, nscans-1 do begin
     if day_list[i] ne myday then begin
        oplot, [i,i]*1, [-1,1]*1e10
        myday = day_list[i]
     endif
  endfor
  
  
  plot, index, tau_1mm[*, 0], xr=[-1,nscans],/xs, position=pp1[3,*], /noerase,/nodata
  oplot, index, tau_1mm[*, 0], col=250
  oplot, index, tau_2mm[*, 0], col=50
  legendastro, ['Tau 1mm', 'Tau 2mm'], col=[250, 50],box=0, pos=[-0.5, 0.1]
  myday = day_list[0]
  for i=0, nscans-1 do begin
     if day_list[i] ne myday then begin
        oplot, [i,i]*1, [-1,1]*1e10
        myday = day_list[i]
     endif
  endfor
  
  !x.charsize = 1
  myday = day_list[0]
  xyouts, 0.1, 0.01, strtrim(strmid(myday,6),2)
  for i=0, nscans-1 do begin
     if day_list[i] ne myday then begin
        oplot, [i,i]*1, [-1,1]*1e10
        myday = day_list[i]
        xyouts, i+0.1, 0.01, strtrim(strmid(myday,6),2)
     endif
  endfor
  
  
  !p.multi = 0
  outplot, /close

  stop

end
