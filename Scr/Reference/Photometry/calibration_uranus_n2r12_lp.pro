;calibration_uranus_n2r12,'/home/macias/NIKA/Plots/Run25/kidpar_20171022s158_v0_LP_skd.fits','N2R12v1', outplot_dir='/home/macias/NIKA/Plots/Run25/',/png, /compute


pro calibration_uranus_n2r12, input_kidpar_file, nickname, $
                               compute=compute, png=png, ps=ps, $
                               outplot_dir=outplot_dir
  

  input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171022s158_v2_LP.fits"
  nickname          = 'N2R12v1'

  input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP.fits"
  nickname          = 'N2R12v3'
  
  ;input_kidpar_file = !nika.off_proc_dir+'kidpar_20171023s101_v2_LP_md.fits'
  ;nickname          = 'N2R12v4'
  
  ;input_kidpar_file = '/home/perotto/NIKA/Plots/N2R12/Beammaps/kidpar_20171023s101_v2_matchdesign_recal.fits'
  ;nickname          = 'N2R12v4_notel'

  input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal.fits"
  nickname          = 'N2R12v5'

  ;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  ;nickname          = 'N2R12v6_nika2tel'
  
  ;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171028s310_v2_LP_skd.fits"
  ;nickname          = 'N2R12v7'
  
  ;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_skd_raw_median.fits"
  ;nickname          = 'N2R12v8'
  
  compute           = 0
  png               = 1
  ps                = 0
  outplot_dir       = '/home/perotto/NIKA/Plots/N2R12/Photometry'
  ;do_tel_gain_corr  = 0 ;; no telescope elevation-gain correction
  ;do_tel_gain_corr  = 1 ;; telescope elevation-gain correction from EMIR
  do_tel_gain_corr  = 2 ;; NIKA2 telescope elevation-gain correction

  ;;elevation_min     = 45.0d0
  elevation_min     = 0.0d0 ;; select only scan taken at elevation > elevation_min

  decor_cm_dmin     = 90.0d0
  
  check_taucorrect  = 0 ;; if 1, do twice the analysis: w and wo opacity correction
  
  method      = 'common_mode_one_block'
  ;;method      = "RAW_MEDIAN"
  source      = 'Uranus'
  
  ;; Selection of N2R12 Uranus scans
  
  restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0.save"

  dz1 = abs(scan.focusz_mm - shift(scan.focusz_mm, -1))  ; 0.8
  dz2 = scan.focusz_mm - shift(scan.focusz_mm, -2)       ; 0.4
  dz3 = scan.focusz_mm - shift(scan.focusz_mm, -3)       ; -0.4
  dz4 = scan.focusz_mm - shift(scan.focusz_mm, -4)       ; -0.8
  
  dx1 = abs(scan.focusx_mm - shift(scan.focusx_mm, -1))  ; 1.4
  dx2 = scan.focusx_mm - shift(scan.focusx_mm, -2)       ; 0.7
  dx3 = scan.focusx_mm - shift(scan.focusx_mm, -3)       ; -0.7
  dx4 = scan.focusx_mm - shift(scan.focusx_mm, -4)       ; -1.4
  
  dy1 = abs(scan.focusy_mm - shift(scan.focusy_mm, -1))  ; 1.4
  dy2 = scan.focusy_mm - shift(scan.focusy_mm, -2)       ; 0.7
  dy3 = scan.focusy_mm - shift(scan.focusy_mm, -3)       ; -0.7
  dy4 = scan.focusy_mm - shift(scan.focusy_mm, -4)       ;-1.4
        
  wfocus = where(strupcase(scan.obstype) eq 'ONTHEFLYMAP' and $
                 (dz1 gt 0.3 or dx1 gt 0.5 or dy1 gt 0.5)   $
                 , nscans, compl=wok, ncompl=nok)
  
  wtokeep = where(strupcase(scan[wok].obstype) eq 'ONTHEFLYMAP' $
                  and scan[wok].n_obs gt 4  $
                  and strupcase(scan[wok].object) eq 'URANUS'$
                  and scan[wok].el_deg gt elevation_min, nkeep)

  
  scan_str = scan[wok[wtokeep]]
  scan_list = scan_str.day+"s"+strtrim( scan_str.scannum,2)
  
  ;;20171024s171* 20171024s227*
  ;;20171025s29* 20171025s41 20171025s42 20171025s323 20171025s337
  ;;20171026s3
  ;;20171027s49 20171027s375
  ;;20171028s10 20171028s57 20171028s58* 20171028s310 20171028s312 20171028s313*
  ;;20171029s26 20171029s27 20171029s28 20171029s31 20171029s259* 20171029s266*
  ;;20171030s38* 20171030s45* 20171030s46* 20171030s268* 20171031s1*
  ;;20171031s2*
  ;;*not in Florian's selection, to be checked
  
  outlier_list =  [$
                  '20171024s171', $ ; focus scan
                  '20171028s313']   ; RAS from tapas
  outlier_list =  [ outlier_list,  $
                    '20171028s57', $ ; RAS from tapas
                    '20171028s58']   ; RAS from tapas
                                ;                '20171025s42', $ ; beammap defocus f0 -0.2 
  ;
  scan_list_ori = scan_list
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list
  
  
  nscans = n_elements(scan_list)
  
  ncpu_max = 24
  optimize_nproc, nscans, ncpu_max, nproc
  
  
  nk_scan2run, scan_list[0]
  
  if not keyword_set(outplot_dir) then outplot_dir=!nika.plot_dir
  
 
  
;; Make maps of all observations of Uranus
  reset=0
  if compute eq 1 then begin
     reset = 1
     for NoTauCorrect=0, check_taucorrect do begin
        project_dir = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
        spawn, "mkdir -p "+project_dir
        split_for, 0, nscans-1, $
                   commands=['obs_nk_ps, i, scan_list, project_dir, '+$
                             'method, source, input_kidpar_file=input_kidpar_file, '+$
                             'reset=reset, NoTauCorrect=NoTauCorrect, ' +$
                             'do_tel_gain_corr=do_tel_gain_corr, ' +$
                             'decor_cm_dmin=decor_cm_dmin'], $
                   nsplit=nproc, $
                   varnames=['scan_list', 'project_dir', 'method', 'source', 'input_kidpar_file', $
                             'reset', 'NoTauCorrect', 'do_tel_gain_corr', 'decor_cm_dmin']
     endfor
  endif
  
  scan_list = scan_list[ sort(scan_list)]
  nscans = n_elements(scan_list)
  
;; check if all scans were indeed processed
  run = !nika.run
  
  for NoTauCorrect=0, check_taucorrect do begin
     project_dir = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
     
     flux_1     = fltarr(nscans)
     flux_2     = fltarr(nscans)
     flux_3     = fltarr(nscans)
     err_flux_1 = fltarr(nscans)
     err_flux_2 = fltarr(nscans)
     err_flux_3 = fltarr(nscans)
     tau_1mm      = fltarr(nscans)
     tau_2mm      = fltarr(nscans)
     fwhm         = fltarr(nscans,3)
     for i =0, nscans-1 do begin
        dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
        if file_test(dir+"/results.save") then begin
           restore,  dir+"/results.save"
           if info1.polar eq 1 then print, scan_list[i]+" is polarized !"
           fwhm[i,0] = info1.result_fwhm_1
           fwhm[i,1] = info1.result_fwhm_2
           fwhm[i,2] = info1.result_fwhm_3
           
           flux_1[i] = info1.result_flux_i1
           flux_2[i] = info1.result_flux_i2
           flux_3[i] = info1.result_flux_i3
           
           tau_1mm[ i] = info1.result_tau_1mm
           tau_2mm[ i] = info1.result_tau_2mm
           err_flux_1[i] = info1.result_err_flux_i1
           err_flux_2[i] = info1.result_err_flux_i2
           err_flux_3[i] = info1.result_err_flux_i3
        endif
     endfor
     
     

     ;; selection on the FWHM before recalibration
     ;;------------------------------------------------------------------

     fwhm_sigma = dblarr(3)
     fwhm_avg   = dblarr(3)
     for j=0, 2 do begin
        w=where(fwhm[*,j] lt !nika.fwhm_array[j]*1.2 and fwhm[*,j] gt !nika.fwhm_array[j]*0.65, nok)
        if nok gt 0 then begin
           fwhm_sigma[j] = stddev( fwhm[w, j])
           fwhm_avg[j]   = avg(    fwhm[w, j])
        endif else print, "all scans have catastrophic fwhm!"
     endfor

     ;; excluding scans of 2.5 sigma outlier FWHM in any arrays
     nsig = 2.5
     nsig = 5.0
     wtokeep = where( abs(fwhm[*, 0]-fwhm_avg[0]) le nsig*fwhm_sigma[0] and $
                      abs(fwhm[*, 1]-fwhm_avg[1]) le nsig*fwhm_sigma[1] and $
                      abs(fwhm[*, 2]-fwhm_avg[2]) le nsig*fwhm_sigma[2], compl=wout, nscans, ncompl=nout)
     
     ;; plot 
     day_list = strmid(scan_list,0,8)
     
     wind, 1, 1, /free, /large
     outplot, file='fwhm_uranus_'+strtrim(nickname,2), png=png, ps=ps
     !p.multi=[0,1,3]
     index = dindgen(n_elements(flux_1))
     for j=0, 2 do begin
        plot, index, fwhm[*,j], /xs, psym=-4, xtitle='scan index', ytitle='FWHM (arcsec)', $
              /ys
        if nout gt 0 then oplot, index[wout],   fwhm[wout,j], psym=4, col=250
        if j eq 2 then   xyouts, index[wtokeep], fwhm[wtokeep,j], scan_list[wtokeep], charsi=0.7, orient=90
        if nout gt 0 and j eq 2 then  xyouts, index[wout], fwhm[wout,j], scan_list[wout], charsi=0.7, orient=90, col=250
        myday = day_list[0]
        for i=0, nscans-1 do begin
           if day_list[i] ne myday then begin
              oplot, [i,i]*1, [-1,1]*1e10
              myday = day_list[i]
           endif
        endfor
        oplot, index, index*0.+fwhm_avg[j], col=50
        oplot,[0,nscans+1],[fwhm_avg[j],fwhm_avg[j]]+fwhm_sigma[j],col=70,LINESTYLE = 5
        oplot,[0,nscans+1],[fwhm_avg[j],fwhm_avg[j]]-fwhm_sigma[j],col=70,LINESTYLE = 5
        legendastro, 'Array '+strtrim(j+1,2), box=0
     endfor
     !p.multi=0
     outplot, /close

     
     if nscans le 0 then begin
        print, "all scans have abherent FWHM...."
        print, "stop here and investigate"
        stop
     endif
     
     
     
     ;; apply the selection
     if nout gt 0 then begin
        print,''
        print,'============================================='
        black_list = scan_list[wout]
        print,'outlier_list =  [ $'
        for i=0, nout-2 do print,"'",black_list[i],"', $"
        print,"'",black_list[nout-1],"' ]"
        print,'============================================='
     endif
     
     scan_list_all = scan_list
     scan_list  = scan_list[wtokeep]
     flux_1     = flux_1[wtokeep]
     flux_2     = flux_2[wtokeep]
     flux_3     = flux_3[wtokeep]

     day_list = strmid(scan_list,0,8)
     tau_1mm    = tau_1mm[wtokeep]
     tau_2mm    = tau_2mm[wtokeep]

            
     ;; plot of the flux
     ;;--------------------------------------------------------------------

     if nickname eq 'N2R12v3' then begin
        debug = !nika.flux_uranus/[39.49, 15.29, 39.49]
        print,debug
        flux_1 = flux_1*debug[0]
        flux_2 = flux_2*debug[1]
        flux_3 = flux_3*debug[2]
     endif
     
     sigma_1 = stddev( flux_1)
     sigma_2 = stddev( flux_2)
     sigma_3 = stddev( flux_3)
     flux_avg_1 = avg( flux_1)
     flux_avg_2 = avg( flux_2)
     flux_avg_3 = avg( flux_3)

     
     
     delvarx, yra    
     index = dindgen(n_elements(flux_1))
     
     fmt = "(F5.2)"
     wind, 1, 1, /free, /large
     outfile = project_dir+'/photometry_uranus_NoTauCorrect'+strtrim(NoTauCorrect,2)+'_'+strtrim(nickname,2)
     if defined(suffix) then outfile = outfile+"_"+suffix
     outplot, file=outfile, png=png, ps=ps
     my_multiplot, 1, 5, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
     !x.charsize = 1e-10

     yra=!nika.flux_uranus[0]*[0.7, 1.3]
     plot,       index, flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
     oploterror, index, flux_1, err_flux_1, psym=8 
     oplot, [-1,nscans], [flux_avg_1, flux_avg_1], col=70
     oplot, [-1,nscans], !nika.flux_uranus[0]*[1., 1.], col=250
     legendastro, ['Array 1', 'sigma/avg: '+strtrim( string(sigma_1/flux_avg_1,format=fmt),2)], box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     yra=!nika.flux_uranus[0]*[0.7, 1.3]
     plot,       index, flux_3, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[1,*], /noerase, yra=yra, /ys
     oploterror, index, flux_3, err_flux_3, psym=8
     oplot, [-1,nscans], [flux_avg_3, flux_avg_3], col=70
     oplot, [-1,nscans], !nika.flux_uranus[0]*[1., 1.], col=250
     legendastro, ['Array 3', 'sigma/avg: '+strtrim( string(sigma_3/flux_avg_3,format=fmt),2)], box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     yra=!nika.flux_uranus[1]*[0.7, 1.3]
     plot,       index, flux_2, ytitle='Flux Jy',xr=[-1,nscans], /xs, position=pp1[2,*], /noerase, yra=yra, /ys
     oploterror, index, flux_2, err_flux_2, psym=8
     oplot, [-1,nscans], [flux_avg_2, flux_avg_2], col=70
     oplot, [-1,nscans], !nika.flux_uranus[1]*[1., 1.], col=250
     xyouts, index, flux_2, strmid(scan_list,4, 12), charsi=0.7, orient=90
     legendastro, ['Array 2', 'sigma/avg: '+strtrim( string(sigma_2/flux_avg_2,format=fmt),2)], box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
        endif
     endfor
     
     
     plot, index, tau_1mm, xr=[-1,nscans],/xs, position=pp1[3,*], /noerase
     legendastro, 'Tau 1mm', box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
      endif
     endfor

     !x.charsize = 1
     plot, index, tau_2mm, xr=[-1,nscans], /xs, position=pp1[4,*], /noerase
     legendastro, 'Tau 2mm', box=0, /bottom
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
     
     print,''
     print,'======================================================'
     print,"Relative uncertainty A1: "+strtrim(100.*sigma_1/flux_avg_1,2)+" %"
     print,"Relative uncertainty A3: "+strtrim(100.*sigma_3/flux_avg_3,2)+" %"
     print,"Relative uncertainty A2: "+strtrim(100.*sigma_2/flux_avg_2,2)+" %"
     print,'======================================================'
     print,"Flux correction coefficient A1: "+strtrim(!nika.flux_uranus[0]/flux_avg_1,2)
     print,"Flux correction coefficient A3: "+strtrim(!nika.flux_uranus[0]/flux_avg_3,2)
     print,"Flux correction coefficient A2: "+strtrim(!nika.flux_uranus[1]/flux_avg_2,2)
     print,'======================================================'

     print,''
     print,'Shall I apply the correction?'
     print,'.c to go ahead'
     
     stop

     
     ;; Recalibrate
     ;;________________________________________________________________
     ;; previous values
     ;; FXD's values, Oct, 2017
     ;;!nika.flux_uranus  = [39.49, 15.29, 39.49]
     ;;!nika.flux_neptune = [16.73, 7.02, 16.73]
     ;;!nika.flux_Mars    = [102.08, 33.68, 102.08]
     
     print, "============================================="
     print, 'Recalibration'
     print, "============================================"
     print, ''
     print, 'Reading ', input_kidpar_file
     kidpar = mrdfits( input_kidpar_file, 1, /silent)
     w1 = where( (kidpar.array eq 1 or kidpar.array eq 3),nw1) ; and $
                                ; kidpar.n_of_geom ge 2, nw1)
     kidpar[w1].calib          *= !nika.flux_uranus[0]/flux_avg_1
     kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[0]/flux_avg_1
     
     w1 = where( kidpar.array eq 2 ,nw2) ;and $
                                ;kidpar.n_of_geom ge 2, nw1)
     kidpar[w1].calib          *= !nika.flux_uranus[1]/flux_avg_2
     kidpar[w1].calib_fix_fwhm *= !nika.flux_uranus[1]/flux_avg_2

     print, 'Writing recalibrated kidpar in ',"kidpar_recal_NoTauCorrect"+strtrim(NoTauCorrect,2)+".fits" 
     nk_write_kidpar, kidpar, "kidpar_recal_NoTauCorrect"+strtrim(NoTauCorrect,2)+".fits"
  endfor
  
  print, scan_list
  print, nscans
  
end

