;calibration_uranus_n2r12,'/home/macias/NIKA/Plots/Run25/kidpar_20171022s158_v0_LP_skd.fits','N2R12v1', outplot_dir='/home/macias/NIKA/Plots/Run25/',/png, /compute


pro calibration_uranus_n2r14
  

  ;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd13.fits"
  ;nickname          = 'N2R14v1'

  ;; FWHM selection cut
  fwhm_a1_max = !nika.fwhm_nom[0]
  fwhm_a3_max = !nika.fwhm_nom[0]
  fwhm_a2_max = !nika.fwhm_nom[1]
  
  input_kidpar_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd16.fits"
  nickname          = 'N2R14v2'

  ;;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14.fits"
  ;;nickname          = 'N2R14v3'
  nickname          = 'N2R14v4'

  
  ;;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20180115s122_v2_LP_skd14.fits"
  ;;nickname          = 'N2R14v5'

  ;;input_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  ;;nickname          = 'N2R14v6'
  ;; --> corrections d'opacite aberrantes: C0, C1 pas adaptes

  ;;geometry_kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  ;;kidpar_skydip_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd14_calUranus8.fits"
  ;;input_kidpar_file = "kidpar_20171025s41_v2_LP_md_recal_calUranus_n2r14skd14.fits"
  ;;skydip_coeffs, geometry_kidpar_file, kidpar_skydip_file, input_kidpar_file
  ;;nickname          = 'N2R14v7'

  ;geometry_kidpar_file = !nika.off_proc_dir+"/kidpar_20180122s309_v2_HA_skd13_calUranus12.fits"
  ;kidpar_skydip_file = !nika.off_proc_dir+"/kidpar_20180117s92_v2_LP_skd16_calUranus16.fits"
  ;input_kidpar_file = "kidpar_20180122s309_v2_HA_skd16.fits"
  ;skydip_coeffs, geometry_kidpar_file, kidpar_skydip_file, input_kidpar_file
  ;nickname          = 'N2R14v8'

  geometry_kidpar_file = !nika.off_proc_dir+"/kidpar_20180122s309_v2_HA_skd13_calUranus12.fits"
  kidpar_skydip_file = '/home/perotto/NIKA/Plots/N2R14/Opacity/kidpar_N2R14_avril_13skd_skydip.fits'
  ;;input_kidpar_file = "kidpar_20180122s309_v2_HA_avril_skd13.fits"
  ;skydip_coeffs, geometry_kidpar_file, kidpar_skydip_file, input_kidpar_file
  ;;nickname          = 'N2R14v9'

  ;geometry_kidpar_file = !nika.off_proc_dir+"/kidpar_20180122s309_v2_HA_skd13_calUranus12.fits"
  ;kidpar_skydip_file = '/home/perotto/NIKA/Plots/N2R14/Opacity/kidpar_N2R14_avril_13skd_hybrid_skydip.fits'
  ;input_kidpar_file = "kidpar_20180122s309_v2_HA_avril_skd13_hybrid.fits"
  ;;skydip_coeffs, geometry_kidpar_file, kidpar_skydip_file, input_kidpar_file
  ;nickname          = 'N2R14v10'


  ;; photocorr 
  input_kidpar_file = "kidpar_20180122s309_v2_HA_avril_skd13.fits"
  nickname          = 'N2R14v11'
  

  ;; FWHM selection cut
  fwhm_a1_max = 12.5
  fwhm_a3_max = 12.5
  fwhm_a2_max = 18.0

  
  fwhm_a1_min = 10.0
  fwhm_a3_min = 10.0
  fwhm_a2_min = 16.0
  
  
  
  compute           = 0
  reset             = 0  ; 1 to reanalysis all the scans
  png               = 0
  ps                = 0
  outplot_dir       = '/home/perotto/NIKA/Plots/N2R14/Photometry'
  ;do_tel_gain_corr  = 0 ;; no telescope elevation-gain correction
  ;do_tel_gain_corr  = 1 ;; telescope elevation-gain correction from EMIR
  do_tel_gain_corr  = 2 ;; NIKA2 telescope elevation-gain correction

  ;;elevation_min     = 35.0d0
  elevation_min     = 0.0d0 ;; select only scan taken at elevation > elevation_min

  decor_cm_dmin     = 60.0d0 ;90.0d0
  
  opacity_correction = 4
  
  check_taucorrect  = 0 ;; if 1, do twice the analysis: w and wo opacity correction
  
  method      = 'common_mode_one_block'
  source      = 'Uranus'

  ;; applying a photometric correction
  photocorr = 1

  ;; discard daytime observations for absolute calibration
  discard_daytime = 0
  daytime_range   = ['09:00','21:00'] ; ['15:00', '19:00']
  
  ;; Selection of N2R14 Uranus scans
  
  restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R14_v0.save"

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

  
  
  outlier_list =  [$
                  '20180114s73', $  ; TBC
                  '20180116s94', $  ; focus scan
                  '20180118s212', $ ; focus scan
                  '20180119s241', $ ; Tapas comment: 'out of focus'
                  '20180119s242', $ ; Tapas comment: 'out of focus'
                  '20180119s243' $ ; Tapas comment: 'out of focus'
                  ]

  
  scan_list_ori = scan_list
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list
  
  nscans = n_elements(scan_list)
  for i=0, nscans-1 do print, "'"+strtrim(scan_list[i],2)+"', $"

  nk_scan2run, scan_list[0]
  
  if not keyword_set(outplot_dir) then outplot_dir=!nika.plot_dir
  
  
;; Make maps of all observations of Uranus
  reset=0
  if compute eq 1 then begin
     
     for NoTauCorrect=0, check_taucorrect do begin

        if photocorr gt 0. then  do_tel_gain_corr  = 0
        
        if reset gt 0 then begin
           scan_list_to_analyse = scan_list
           nscan_to_analyse = nscans
        endif else begin
           scan_list_to_analyse = ''
           for isc = 0, nscans-1 do begin
              file = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)+'/v_1/'+scan_list[isc]+'/results.save'
              if file_test(file) lt 1 then scan_list_to_analyse = [ scan_list_to_analyse, scan_list[isc]]
           endfor
           nscan_to_analyse = n_elements(scan_list_to_analyse)-1
           if nscan_to_analyse gt 0 then scan_list_to_analyse = scan_list_to_analyse[1:*] 
        endelse
        
        ;; stop
        
        if nscan_to_analyse gt 0 then begin
           ncpu_max = 24
           optimize_nproc, nscan_to_analyse, ncpu_max, nproc
        
           ;; split series of beammap scans
           scan_list_to_analyse = shuffle( scan_list_to_analyse) 
           reset = 1
           project_dir = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
           spawn, "mkdir -p "+project_dir
           split_for, 0, nscan_to_analyse-1, $
                      commands=['obs_nk_ps, i, scan_list_to_analyse, project_dir, '+$
                                'method, source, input_kidpar_file=input_kidpar_file, '+$
                                'reset=reset, NoTauCorrect=NoTauCorrect, ' +$
                                'do_tel_gain_corr=do_tel_gain_corr, ' +$
                                'decor_cm_dmin=decor_cm_dmin, ' +$
                                'opacity_correction=opacity_correction'], $
                      nsplit=nproc, $
                      varnames=['scan_list_to_analyse', 'project_dir', 'method', 'source', $
                                'input_kidpar_file', $
                                'reset', 'NoTauCorrect', 'do_tel_gain_corr', 'decor_cm_dmin', 'opacity_correction']
        endif
     endfor
  endif
  
  scan_list = scan_list[ sort(scan_list)]
  nscans = n_elements(scan_list)
  
;; check if all scans were indeed processed
  run = !nika.run
  
  for NoTauCorrect=0, check_taucorrect do begin
     project_dir = outplot_dir+"/Uranus_photometry_"+nickname+"_NoTauCorrect"+strtrim(NoTauCorrect,2)
     
     flux     = fltarr(nscans,3)
     err_flux = fltarr(nscans,3)
     tau_1mm      = fltarr(nscans)
     tau_2mm      = fltarr(nscans)
     fwhm         = fltarr(nscans,3)
     nsub         = intarr(nscans)
     elev         = fltarr(nscans)
     ut           = strarr(nscans)
     for i =0, nscans-1 do begin
        dir = project_dir+"/v_1/"+strtrim(scan_list[i], 2)
        if file_test(dir+"/results.save") then begin
           restore,  dir+"/results.save"
           if info1.polar eq 1 then print, scan_list[i]+" is polarized !"
           fwhm[i,0] = info1.result_fwhm_1
           fwhm[i,1] = info1.result_fwhm_2
           fwhm[i,2] = info1.result_fwhm_3
           
           flux[i, 0] = info1.result_flux_i1
           flux[i, 1] = info1.result_flux_i2
           flux[i, 2] = info1.result_flux_i3
           
           tau_1mm[ i] = info1.result_tau_1mm
           tau_2mm[ i] = info1.result_tau_2mm
           err_flux[i, 0] = info1.result_err_flux_i1
           err_flux[i, 1] = info1.result_err_flux_i2
           err_flux[i, 2] = info1.result_err_flux_i3
           nsub[i]        = info1.nsubscans
           elev[i]        = info1.RESULT_ELEVATION_DEG
           ut[i]          = strmid(info1.ut, 0, 5)
           ;;if i eq 4 then stop
        endif
     endfor
     
     if photocorr gt 0 then begin

        tflux = transpose(flux)
        tfwhm = transpose(fwhm)
        
        photometric_correction, tflux, tfwhm, corr_flux_factor
        index = indgen(nscans)
        
        outplot, file='Photometric_correction_'+strtrim(nickname,2), $
                 png=png, ps=ps
        plot, index, reform(corr_flux_factor[0, *]), yr=[0.85, 1.3], /ys, /nodata, $
              xtitle='scan index', ytitle= 'photometric correction factor', xr=[-1, nscans], /xs
        oplot, [-1, nscans], [1, 1]
        oplot, index, reform(corr_flux_factor[0, *]), col=80, psym=8
        oplot, index, reform(corr_flux_factor[2, *]), col=50, psym=8
        oplot, index, reform(corr_flux_factor[1, *]), col=250, psym=8
        xyouts, index, replicate(0.87,nscans), strmid(scan_list, 4, 10), charsi=0.7, orient=90
        legendastro, ['A1', 'A3', 'A2'], textcol=[80, 50, 250], col=[80, 50, 250], $
                     box=0, psym=[8, 8, 8]
        outplot, /close
        
        wphot=where(corr_flux_factor[0, *] gt 1.1 or corr_flux_factor[1, *] gt 1.1 or corr_flux_factor[2, *] gt 1.1, nwphot)
        if nwphot gt 0 then print, 'high photo corr for scans ', scan_list[wphot]
        
        print, 'type .c to implement the photometric correction'
        stop
        
        raw_flux = flux
        for ia = 0, 2 do flux[*, ia] = flux[*, ia]*corr_flux_factor[ia,*]

        ;; set FWHM thresholds to large values
        fwhm_a1_max = 16.       ;12.5
        fwhm_a3_max = 16.       ;12.5
        fwhm_a2_max = 20.       ;18.0
              
     endif

     

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
                      abs(fwhm[*, 2]-fwhm_avg[2]) le nsig*fwhm_sigma[2], $
                      compl=wout, nscans, ncompl=nout)
     selection_type=0

     ;; excluding large beam scans
     wtokeep = where( fwhm[*, 0] le fwhm_a1_max and $
                      fwhm[*, 1] le fwhm_a2_max and $
                      fwhm[*, 2] le fwhm_a3_max and $
                      fwhm[*, 2] gt fwhm_a3_min and $
                      fwhm[*, 1] gt fwhm_a2_min and $
                      fwhm[*, 0] gt fwhm_a1_min, compl=wout, nscans, ncompl=nout)
     selection_type = 1
     fwhm_max = [fwhm_a1_max,fwhm_a2_max,fwhm_a3_max]

     ;; discard daytime observation
     ndaytime = 0
     if discard_daytime gt 0 then begin
        wtokeep = where( fwhm[*, 0] le fwhm_a1_max and $
                         fwhm[*, 1] le fwhm_a2_max and $
                         fwhm[*, 2] le fwhm_a3_max and $
                         fwhm[*, 2] gt fwhm_a3_min and $
                         fwhm[*, 1] gt fwhm_a2_min and $
                         fwhm[*, 0] gt fwhm_a1_min and $
                         (ut[*] lt daytime_range[0] or $
                         ut[*] gt daytime_range[1]) , compl=wout, nscans, ncompl=nout)
        wnight = where( ut[*] lt daytime_range[0] or $
                        ut[*] gt daytime_range[1] , compl=wdaytime, nscans_night, ncompl=ndaytime)
     endif

     
     if photocorr gt 0 then nickname = strcompress(nickname+'_photocorr', /remove_all)
     print,nickname

     
     ;; plot 
     day_list = strmid(scan_list,0,8)
     
     wind, 1, 1, /free, /large
     outplot, file='fwhm_uranus_'+strtrim(nickname,2), png=png, ps=ps
     !p.multi=[0,1,3]
     index = dindgen(n_elements(flux[*, 0]))
     for j=0, 2 do begin
        plot, index, fwhm[*,j], /xs, psym=-4, xtitle='scan index', ytitle='FWHM (arcsec)', $
              /ys
        if nout gt 0 then oplot, index[wout],   fwhm[wout,j], psym=4, col=250
        if ndaytime gt 0 then oplot, index[wdaytime], fwhm[wdaytime,j], psym=6, col=250
        if j eq 2 then   xyouts, index[wtokeep], fwhm[wtokeep,j], scan_list[wtokeep], charsi=0.7, orient=90
        if photocorr gt 0 then if nwphot gt 0 then oplot, index[wphot],   fwhm[wphot,j], psym=5, col=250
        if nout gt 0 and j eq 2 then  xyouts, index[wout], fwhm[wout,j], scan_list[wout], charsi=0.7, orient=90, col=250
        myday = day_list[0]
        for i=0, nscans-1 do begin
           if day_list[i] ne myday then begin
              oplot, [i,i]*1, [-1,1]*1e10
              myday = day_list[i]
           endif
        endfor
        if selection_type lt 1 then begin
           oplot, index, index*0.+fwhm_avg[j], col=50
           oplot,[0,nscans+nout+1],[fwhm_avg[j],fwhm_avg[j]]+fwhm_sigma[j],col=70,LINESTYLE = 5
           oplot,[0,nscans+nout+1],[fwhm_avg[j],fwhm_avg[j]]-fwhm_sigma[j],col=70,LINESTYLE = 5
        endif
        if selection_type eq 1 then begin
           oplot, [0,nscans+nout+1], index*0.+fwhm_avg[j], col=50, LINESTYLE = 5
           oplot, [0,nscans+nout+1], index*0.+fwhm_max[j], col=50
        endif
        legendastro, 'Array '+strtrim(j+1,2), box=0
     endfor
     !p.multi=0
     outplot, /close

     
     if nscans le 0 then begin
        print, "all scans have abberant FWHM...."
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
     flux_1     = flux[wtokeep, 0]
     flux_2     = flux[wtokeep, 1]
     flux_3     = flux[wtokeep, 2]

     day_list = strmid(scan_list,0,8)
    
            
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
     my_multiplot, 1, 4, pp, pp1, /rev, gap_y=0.02, xmargin=0.1, ymargin=0.1 ; 1e-6
     !x.charsize = 1e-10

     yra=!nika.flux_uranus[0]*[0.7, 1.3]
     plot,       index, flux_1, ytitle='Flux Jy', xr=[-1,nscans], /xs, position=pp1[0,*], yra=yra, /ys, title=file_basename(project_dir)
     oploterror, index, flux_1, err_flux[wtokeep, 0], psym=8 
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
     oploterror, index, flux_3, err_flux[wtokeep, 2], psym=8
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
     oploterror, index, flux_2, err_flux[wtokeep,1], psym=8
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
     
     
     plot, index, tau_1mm[wtokeep], xr=[-1,nscans],/xs, position=pp1[3,*], /noerase,/nodata
     oplot, index, tau_1mm[wtokeep], col=250
     oplot, index, tau_2mm[wtokeep], col=50
     legendastro, ['Tau 1mm', 'Tau 2mm'], col=[250, 50],box=0, /bottom
     myday = day_list[0]
     for i=0, nscans-1 do begin
        if day_list[i] ne myday then begin
           oplot, [i,i]*1, [-1,1]*1e10
           myday = day_list[i]
      endif
     endfor

     !p.multi = 0
     outplot, /close


     ;; correlation plots
     ;;----------------------------------------------
     wind, 1, 1, /free, xsize=1000, ysize=550
     outplot, file=project_dir+'/Flux_vs_fwhm_Uranus_one_block_'+strtrim(nickname,2)+'_model', png=png, ps=ps
     my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.06, xmargin=0.1, ymargin=0.1 ; 1e-6
     !x.charsize = 1.
     index = dindgen(nscans)
     day_list = strmid(scan_list,0,8)
     
     coltab = [200, 80, 250]
     
     plot, fwhm[*, 0] , flux[*, 0], /xs, yr=!nika.flux_uranus[0]*[0.7, 1.2], $
           xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),15.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[0, *]
     
     oplot, fwhm[wtokeep, 0] , flux[wtokeep, 0], psym=8, col=coltab[0]
     oplot, fwhm[wout, 0] , flux[wout, 0], psym=4, col=coltab[0]
     oplot, fwhm[wtokeep, 2] , flux[wtokeep, 2], psym=8, col=coltab[2]
     oplot, fwhm[wout, 2] , flux[wout, 2], psym=4, col=coltab[2]
     oplot, [0,50], !nika.flux_uranus[0]*[1., 1.], col=0
     oplot, [0,50], flux_avg_3*[1., 1.], col=80, thick=2
     oplot, [0,50], flux_avg_1*[1., 1.], col=80
     if photocorr gt 1 then oplot, fwhm[*, 0], !nika.flux_uranus[0]*(12.0^2+!nika.fwhm_nom[0]^2)/(fwhm[*,0]^2+!nika.fwhm_nom[0]^2), col=0
    
    
     plot, fwhm[*, 1] , flux[*, 1], /xs, yr=!nika.flux_uranus[1]*[0.7, 1.2], $
           xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     oplot, fwhm[wtokeep, 1] , flux[wtokeep, 1], psym=8, col=coltab[1]
     oplot, fwhm[wout, 1] , flux[wout, 1], psym=4, col=coltab[1]
     oplot, [0,50], !nika.flux_uranus[1]*[1., 1.], col=0
     oplot, fwhm[*, 1], !nika.flux_uranus[1]*(18.0^2+!nika.fwhm_nom[1]^2)/(fwhm[*,1]^2+!nika.fwhm_nom[1]^2), col=0
     
     !p.multi=0
     outplot, /close

     ;; wd, /a
     stop

     wind, 1, 1, /free, xsize=1000, ysize=550
     outplot, file=project_dir+'/Flux_vs_fwhm_Uranus_one_block_'+strtrim(nickname,2)+'_datecolor', png=png, ps=ps
     my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.06, xmargin=0.1, ymargin=0.1 ; 1e-6
     !x.charsize = 1.
     index = dindgen(nscans)
     day_list = strmid(scan_list,0,8)

     ut_tab=['00:00', '07:00', '08:00', '09:00', '10:00', '12:00', '13:00', '14:00', '15:00', '16:00', '18:00', '19:00', '20:00', '20:30', '21:00', '22:00', '24:00']


     dok = where(ut ne '', nok) 
     
     minut = min(ut[dok])
     maxut = max(ut[dok])
     minh = where(ut_tab ge minut)
     maxh = where(ut_tab le maxut)
     ut_tab = ut_tab[minh[0]-1:maxh[n_elements(maxh)-1]+1]
     
     nut = n_elements(ut_tab)-1
     
     plot, fwhm[*, 0] , flux[*, 0], /xs, yr=!nika.flux_uranus[0]*[0.7, 1.2], $
           xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),15.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[0, *]

     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm[w, 0] , flux[w, 0], psym=8, col=(u+1.)*250./nut
        if nn gt 0 then oplot, fwhm[w, 2] , flux[w, 2], psym=4, col=(u+1.)*250./nut
       print, 'from ', ut_tab[u], ' to ',  ut_tab[u+1], ' : ', nn, ' scans'
     endfor
     oplot, [0,50], !nika.flux_uranus[0]*[1., 1.], col=0
     legendastro, ['A1', 'A3'], psym=[8, 4]

    
     plot, fwhm[*, 1] , flux[*, 1], /xs, yr=!nika.flux_uranus[1]*[0.7, 1.2], $
           xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm[w, 1] , flux[w, 1], psym=8, col=(u+1.)*250./nut
        ;if nn gt 0 then
        xyouts, 17.3, !nika.flux_uranus[1]*(1.2-0.5*(u+0.5)/nut), ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
     endfor
     oplot, [0,50], !nika.flux_uranus[1]*[1., 1.], col=0

     
     
     !p.multi=0
     outplot, /close
     
     stop
     wd, /a
          
     
     quant = ['Flux', 'FWHM', 'elev', 'tau']
     index = dindgen(nscans)
     day_list = strmid(scan_list,0,8)
     
     coltab = [200, 80, 250]

     ;; 1mm
     ;;--------------------------------------------
     wind, 1, 1, /free, xsize=1150, ysize=670
     outplot, file=project_dir+'/Correlation_plot_Uranus_one_block_1mm_'+$
              strtrim(nickname,2)+"_datecolor", png=png, ps=ps
     my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

     ;; FWHM- Flux
     plot, fwhm[*, 0] , flux[*, 0], /xs, yr=!nika.flux_uranus[0]*[0.7, 1.2], $
           xr=[min(fwhm[wtokeep, 0])*0.97,min([max(fwhm[*, 0]),15.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[0, *]
     
     ;oplot, fwhm[wtokeep, 0] , flux[wtokeep, 0], psym=8, col=coltab[0]
     ;oplot, fwhm[wout, 0] , flux[wout, 0], psym=4, col=coltab[0]
     ;oplot, fwhm[wtokeep, 2] , flux[wtokeep, 2], psym=8, col=coltab[2]
     ;oplot, fwhm[wout, 2] , flux[wout, 2], psym=4, col=coltab[2]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm[w, 0] , flux[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, fwhm[w, 2] , flux[w, 2], psym=8, col=(u+1.)*250./nut
     endfor
     legendastro, ['A1', 'A3'], psym=[4, 8]
     
     oplot, [0,50], !nika.flux_uranus[0]*[1., 1.], col=0
     
     if photocorr gt 1 then oplot, fwhm[*, 0], !nika.flux_uranus[0]*(12.0^2+!nika.fwhm_nom[0]^2)/(fwhm[*,0]^2+!nika.fwhm_nom[0]^2), col=0                                   
     if photocorr gt 0 then oplot, [0,50], flux_avg_1*[1., 1.], col=50
     if photocorr gt 0 then oplot, [0,50], flux_avg_3*[1., 1.], col=80
     
     ;; tau-flux     
     plot, tau_1mm[*] , flux[*, 0], /xs, yr=!nika.flux_uranus[0]*[0.7, 1.2], $
           xr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     ;;oplot, tau_1mm[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
     ;;oplot, tau_1mm[wout] , flux[wout, 0], psym=4, col=coltab[0]
     ;;oplot, tau_1mm[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
     ;;oplot, tau_1mm[wout] , flux[wout, 2], psym=4, col=coltab[2]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_1mm[w] , flux[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, tau_1mm[w] , flux[w, 2], psym=8, col=(u+1.)*250./nut
     endfor
     
     oplot, [0,50], !nika.flux_uranus[0]*[1., 1.], col=0


     ;; elev-flux
     plot, elev[*] , flux[*, 0], /xs, yr=!nika.flux_uranus[0]*[0.7, 1.2], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[2, *], /noerase
     
     ;;oplot, elev[wtokeep] , flux[wtokeep, 0], psym=8, col=coltab[0]
     ;;oplot, elev[wout] , flux[wout, 0], psym=4, col=coltab[0]
     ;;oplot, elev[wtokeep] , flux[wtokeep, 2], psym=8, col=coltab[2]
     ;;oplot, elev[wout] , flux[wout, 2], psym=4, col=coltab[2]

     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , flux[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, elev[w] , flux[w, 2], psym=8, col=(u+1.)*250./nut
     endfor
     
     oplot, [0,90], !nika.flux_uranus[0]*[1., 1.], col=0

     ;; FWHM-elev
     f_max = min([max(fwhm[wtokeep, 0]),15.])
     f_min = min(fwhm[wtokeep, 0])*0.90
     plot, elev[*] , FWHM[*, 0], /xs, yr=[f_min,f_max], $
           xr=[10., 80.], psym=-4, $
           xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[3, *], /noerase
     
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
     ;;oplot, elev[wout] , fwhm[wout, 0], psym=4, col=coltab[0]
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
     ;;oplot, elev[wout] , fwhm[wout, 2], psym=4, col=coltab[2]

     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , fwhm[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, elev[w] , fwhm[w, 2], psym=8, col=(u+1.)*250./nut
        xyouts, 15., f_max - (f_max-f_min)*(u+0.5)/nut, ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
     endfor
     
     oplot, [0,90], 12.0*[1., 1.], col=0
     
     ;; FWHM-tau 
     plot, tau_1mm[*] , fwhm[*, 0], /xs, yr=[f_min,f_max], $
           xr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[4, *], /noerase
     
     ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 0], psym=8, col=coltab[0]
     ;;oplot, tau_1mm[wout] , fwhm[wout, 0], psym=4, col=coltab[0]
     ;;oplot, tau_1mm[wtokeep] , fwhm[wtokeep, 2], psym=8, col=coltab[2]
     ;;oplot, tau_1mm[wout] , fwhm[wout, 2], psym=4, col=coltab[2]
      for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_1mm[w] , fwhm[w, 0], psym=4, col=(u+1.)*250./nut
        if nn gt 0 then oplot, tau_1mm[w] , fwhm[w, 2], psym=8, col=(u+1.)*250./nut    
     endfor
     
     oplot, [0,50], 12.0*[1., 1.], col=0

     ;; tau-elev
     plot, elev[*] , tau_1mm[*], /xs, yr=[min(tau_1mm[wtokeep])*0.5,min([max(tau_1mm[*]),1.])], $
           xr=[10., 80.], psym=-4, $
           xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
           pos=pp1[5, *], /noerase
     
     ;;oplot, elev[wtokeep] , tau_1mm[wtokeep, 0], psym=8, col=coltab[2]
     ;;oplot, elev[wout] , tau_1mm[wout, 0], psym=4, col=coltab[2]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , tau_1mm[w], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], 0.2*[1., 1.], col=0

     !p.multi=0
     outplot, /close

     ;; 2mm
     ;;--------------------------------------------
     wind, 1, 1, /free, xsize=1150, ysize=670
     outplot, file=project_dir+'/Correlation_plot_Uranus_one_block_2mm_'+$
              strtrim(nickname,2)+"_datecolor", png=png, ps=ps
     my_multiplot, 3, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

     ;; FWHM- Flux
     plot, fwhm[*, 1] , flux[*, 1], /xs, yr=!nika.flux_uranus[1]*[0.7, 1.2], $
           xr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], psym=-4, $
           xtitle='FWHM (arcsec)', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[0, *]
     
     ;;oplot, fwhm[wtokeep, 1] , flux[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, fwhm[wout, 1] , flux[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm[w, 1] , flux[w, 1], psym=8, col=(u+1.)*250./nut
        xyouts, 17.2, !nika.flux_uranus[1]*(1.2-0.5*(u+0.5)/nut), ut_tab[u], charsi=0.7, orient=0, col=(u+1.)*250./nut
     endfor
     oplot, [0,50], !nika.flux_uranus[1]*[1., 1.], col=0
     
     if photocorr lt 1 then oplot, fwhm[*, 1], !nika.flux_uranus[1]*(18.0^2+!nika.fwhm_nom[1]^2)/(fwhm[*,1]^2+!nika.fwhm_nom[1]^2), col=0
     if photocorr gt 0 then  oplot, [0,50], flux_avg_2*[1., 1.], col=250
     
     ;; tau-flux     
     plot, tau_2mm[*] , flux[*, 1], /xs, yr=!nika.flux_uranus[1]*[0.7, 1.2], $
           xr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[1, *], /noerase
     
     ;;oplot, tau_2mm[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, tau_2mm[wout] , flux[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_2mm[w] , flux[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,50], !nika.flux_uranus[1]*[1., 1.], col=0


     ;; elev-flux
     plot, elev[*] , flux[*, 1], /xs, yr=!nika.flux_uranus[1]*[0.7, 1.2], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[2, *], /noerase
     
     ;;oplot, elev[wtokeep] , flux[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, elev[wout] , flux[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , flux[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], !nika.flux_uranus[1]*[1., 1.], col=0

     ;; FWHM-elev
     plot, elev[*] , FWHM[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[3, *], /noerase
     
     ;;oplot, elev[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, elev[wout] , fwhm[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , fwhm[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], 17.5*[1., 1.], col=0
     
     ;; FWHM-tau 
     plot, tau_2mm[*] , fwhm[*, 1], /xs, yr=[min(fwhm[wtokeep, 1])*0.97,min([max(fwhm[*, 1]),19.])], $
           xr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], psym=-4, $
           xtitle='zenith opacity', ytitle='FWHM [arcsec]', /ys, /nodata, $
           pos=pp1[4, *], /noerase
     
     ;;oplot, tau_2mm[wtokeep] , fwhm[wtokeep, 1], psym=8, col=coltab[1]
     ;;oplot, tau_2mm[wout] , fwhm[wout, 1], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, tau_2mm[w] , fwhm[w, 1], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,50], 17.5*[1., 1.], col=0

     ;; tau-elev
     plot, elev[*] , tau_2mm[*], /xs, yr=[min(tau_2mm[wtokeep])*0.5,min([max(tau_2mm[*]),1.])], $
           xr=[min(elev[wtokeep])*0.97,max(elev[*])*1.1], psym=-4, $
           xtitle='Elevation [deg]', ytitle='zenith opacity', /ys, /nodata, $
           pos=pp1[5, *], /noerase
     
     ;;oplot, elev[wtokeep] , tau_2mm[wtokeep, 0], psym=8, col=coltab[1]
     ;;oplot, elev[wout] , tau_2mm[wout, 0], psym=4, col=coltab[1]
     for u = 0, nut-1 do begin
        w=where(ut ge ut_tab[u] and ut lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, elev[w] , tau_2mm[w], psym=8, col=(u+1.)*250./nut
     endfor
     oplot, [0,90], 0.1*[1., 1.], col=0

     !p.multi=0
     outplot, /close
     ;;---------------------------------------------------------------



     
     stop

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
     print,"Flux ratio to expectation A1: "+strtrim(flux_avg_1/!nika.flux_uranus[0],2)
     print,"Flux ratio to expectation A3: "+strtrim(flux_avg_3/!nika.flux_uranus[0],2)
     print,"Flux ratio to expectation A2: "+strtrim(flux_avg_2/!nika.flux_uranus[1],2)   
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
  
  for i=0, nscans-1 do print, "'"+strtrim(scan_list[i],2)+"', $"
  print, nscans

  stop

  
end

