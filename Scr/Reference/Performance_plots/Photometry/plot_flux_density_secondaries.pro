pro plot_flux_density_secondaries, allscan_info, index_select, $
                                   outplot_dir = outplot_dir, $
                                   png=png, ps=ps, pdf=pdf, $
                                   fwhm_stability=fwhm_stability, $
                                   obstau_stability=obstau_stability, $
                                   nostop = nostop, savefile = savefile, $
                                   aperture = aperture
  
  ;; outplot directory
  if keyword_set(outplot_dir) then dir = outplot_dir else $
     dir     = getenv('NIKA_PLOT_DIR')+'/Performance_plots'

  if keyword_set(nostop) then nostop=1 else nostop=0
  if keyword_set(savefile) then savefile = 1 else savefile = 0
 
  sources = ['MWC349', 'CRL2688', 'NGC7027']

  
  plot_suffixe = ''
  if keyword_set( aperture) then plot_suffixe = '_AP'
  yflux = 'Flux '
  if keyword_set( aperture) then yflux = 'AP Flux '

  ;; plot aspect
  ;;----------------------------------------------------------------
  
  ;; window size
  wxsize = 1000.
  wysize = 800.
  ;; plot size in files
  pxsize = 20.
  pysize = 16.
  ;; charsize
  charsize  = 1.0
  charthick = 1.0
  mythick = 1.0
  mysymsize   = 0.8
  
  if keyword_set(ps) then begin
     ;; window size
     ps_wxsize = 1100.
     ps_wysize = 800.
     ;; plot size in files
     ps_pxsize = 20.
     ps_pysize = 16.
     ;; charsize
     ps_charsize  = 1.0
     ps_charthick = 3.0
     ps_mythick   = 3.0 
     ps_mysymsize = 1.0
     
  endif

  ;;________________________________________________________________
  ;;
  ;; create result table
  ;;________________________________________________________________
  ;;________________________________________________________________

  nscans = n_elements(allscan_info)
  scan_list = allscan_info.scan
  
  ;; FLUX DENSITY EXPECTATIONS
  ;;____________________________________________________________
  th_flux_1mm = dblarr(nscans)
  th_flux_a2  = dblarr(nscans)
  th_flux_a1  = dblarr(nscans)
  th_flux_a3  = dblarr(nscans)

  w = where(strupcase(allscan_info.object) eq 'MWC349', ntot) 
  if ntot gt 0 then begin
     ;;lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
     ;;nu = !const.c/(lambda*1e-3)/1.0d9
     nu = [260.0d0, 150.0d0, 260.0d0]
     th_flux           = 1.16d0*(nu/100.0)^0.60
     ;; assuming indep param
     err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)
     err_th_flux       = [0.04, 0.02, 0.04]
     th_flux_1mm[w]     = th_flux[0]
     th_flux_a2[w]      = th_flux[1]
     th_flux_a1[w]      = th_flux[0]
     th_flux_a3[w]      = th_flux[2]
     if keyword_set( aperture) then begin
        th_flux_1mm[w]     = $
           median(allscan_info[w].result_aperture_photometry_i_1mm)
        th_flux_a2[w]      = $
           median(allscan_info[w].result_aperture_photometry_i2)
        th_flux_a1[w]      = $
           median(allscan_info[w].result_aperture_photometry_i1)
        th_flux_a3[w]      = $
           median(allscan_info[w].result_aperture_photometry_i3)
     endif
  endif
  w = where(strupcase(allscan_info.object) eq 'CRL2688', ntot) 
  if ntot gt 0 then begin
     ;;===========================================================
     ;;th_flux           = [2.51, 0.54] ;; JFL
     alpha = 2.44
     ;; Dempsey 2013
     flux_scuba2 = [5.64, 24.9] ;; Jy.beam-1
     lam_scuba2  = [850., 450.]*1.0d-6
     nu_scuba2   = !const.c/(lam_scuba2)/1.0d9
     nu = [260.0d0, 150.0d0, 260.0d0]
     th_flux_1mm_mbb = flux_scuba2[0] * (nu[0]/nu_scuba2[0])^(0.4)*$
                       black_body(nu[0],210.)/black_body(nu_scuba2[0],210.)
     th_flux_2mm_mbb = flux_scuba2[0] * (nu[1]/nu_scuba2[0])^(0.4)*$
                       black_body(nu[1], 210.)/black_body(nu_scuba2[0],210.)
     
     th_flux_1mm_alpha = flux_scuba2 * (nu[0]/nu_scuba2)^(2.44)    ;; 2.6801162   2.5068608
     th_flux_2mm_alpha = flux_scuba2 * (nu[1]/nu_scuba2)^(2.44)    ;; 0.70029542  0.65502500
     ;;======================================================================================
     th_flux           = [2.91, 0.76]   ;; table A.2
     err_th_flux       = [0.23, 0.14]
     th_flux_1mm[w]     = th_flux[0]
     th_flux_a2[w]      = th_flux[1]
     th_flux_a1[w]      = th_flux[0]
     th_flux_a3[w]      = th_flux[0]
  endif
  ;; NGC7027
  ;;------------------------------
  wsou = where(strupcase(allscan_info.object) eq 'NGC7027', nscan_sou)
  if nscan_sou gt 0 then begin
     th_flux           = [3.46, 4.26]
     err_th_flux       = [0.11, 0.24]
     th_flux_1mm[wsou]     = th_flux[0]
     th_flux_a2[wsou]      = th_flux[1]
     th_flux_a1[wsou]      = th_flux[0]
     th_flux_a3[wsou]      = th_flux[0]
  endif
          
  flux_1mm     = allscan_info.result_flux_i_1mm
  flux_a2      = allscan_info.result_flux_i2
  flux_a1      = allscan_info.result_flux_i1
  flux_a3      = allscan_info.result_flux_i3
  err_flux_1mm = allscan_info.result_err_flux_i_1mm
  err_flux_a2  = allscan_info.result_err_flux_i2
  err_flux_a1  = allscan_info.result_err_flux_i1
  err_flux_a3  = allscan_info.result_err_flux_i3
  if keyword_set( aperture) then begin
     flux_1mm_gpsf = flux_1mm   ; Gaussian point-spread-Function to keep it for later
     flux_a2_gpsf  = flux_a2
     flux_a1_gpsf  = flux_a1
     flux_a3_gpsf  = flux_a3
     flux_1mm     = allscan_info.result_aperture_photometry_i_1mm
     flux_a2      = allscan_info.result_aperture_photometry_i2
     flux_a1      = allscan_info.result_aperture_photometry_i1
     flux_a3      = allscan_info.result_aperture_photometry_i3
     err_flux_1mm = allscan_info.result_err_aperture_photometry_i_1mm
     err_flux_a2  = allscan_info.result_err_aperture_photometry_i2
     err_flux_a1  = allscan_info.result_err_aperture_photometry_i1
     err_flux_a3  = allscan_info.result_err_aperture_photometry_i3
  endif
  ;;
  fwhm_1mm     = allscan_info.result_fwhm_1mm
  fwhm_a2      = allscan_info.result_fwhm_2
  fwhm_a1      = allscan_info.result_fwhm_1
  fwhm_a3      = allscan_info.result_fwhm_3
  ;;
  tau_1mm      = allscan_info.result_tau_1mm
  tau_a2       = allscan_info.result_tau_2mm
  tau_a1       = allscan_info.result_tau_1
  tau_a3       = allscan_info.result_tau_3
  ;;
  elev         = allscan_info.result_elevation_deg*!dtor
  obj          = allscan_info.object
  day          = allscan_info.day
  n2runid      = 0
  ut           = strmid(allscan_info.ut, 0, 5)
  ;;
    
  ;; calculate ut_float and get flux expectations
  ut_float    = fltarr(nscans)
  for i=0, nscans-1 do begin
     ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
  endfor

  ;; Color correction (Table 12)
  ;;============================================================
  w = where(strupcase(allscan_info.object) eq 'MWC349', ntot) 
  if ntot gt 0 then begin
     flux_1mm = flux_1mm*0.976
     flux_a1  = flux_a1*0.969 
     flux_a2  = flux_a2*0.996
     flux_a3  = flux_a3*0.980
  endif
  w = where(strupcase(allscan_info.object) eq 'CRL2688', ntot) 
  if ntot gt 0 then begin
     flux_1mm = flux_1mm*1.01
     flux_a1  = flux_a1*1.01
     flux_a2  = flux_a2*0.99
     flux_a3  = flux_a3*1.02 
  endif
  w = where(strupcase(allscan_info.object) eq 'NGC7027', ntot) 
  if ntot gt 0 then begin
     flux_1mm = flux_1mm*0.935
     flux_a1  = flux_a1*0.93 
     flux_a2  = flux_a2*0.98
     flux_a3  = flux_a3*0.94 
  endif
  


  
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
  planet_fwhm_max  = [13.0, 18.3, 13.0]


  ;; Flux of MWC 349
  ;;________________________________________________________________________________
  ;; first version for on-screen display (and save a png file
  ;; if asked for)
  wind, 1, 1, /free, /large
  outplot, file=dir+'/Plot_MWC349_flux', png=png
  !p.multi=[0,1,2]
  w = where(obj eq 'MWC349', nn)
  index = dindgen(nn)
  plot, index, flux_1mm[w], /xs, /ys, psym=8, xtitle='scan index', $
        ytitle=yflux+ '[Jy]', $
        /nodata, yr=[0.5, 2.5], xr=[min(index)-1, max(index)+1]
  
  oplot, index, flux_1mm[w], col=col_1mm, psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25)
  oplot, index, flux_a1[w], col=col_a1,  psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25)
  oplot, index, flux_a3[w], col=col_a3,  psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25)
  oplot, index, flux_a2[w], col=col_a2,  psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25)
  my_match, w, index_select, suba, subb
  if nn gt 0 then begin
     oplot, index[w[suba]], flux_1mm[w[suba]], col=col_1mm,psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
     oplot, index[w[suba]], flux_a1[w[suba]], col=col_a1, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
     oplot, index[w[suba]], flux_a3[w[suba]], col=col_a3, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
     oplot, index[w[suba]], flux_a2[w[suba]], col=col_a2, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
  endif
  
  legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
               color=[col_a1, col_a3, col_a2], /bottom
  
  nu = [260.0d0, 150.0d0]
  th_flux = 1.16d0*(nu/100.0)^0.60
  oplot, [min(index)-1, max(index)+1], [th_flux[0], th_flux[0]], col=col_1mm, linestyle=5
  oplot, [min(index)-1, max(index)+1], [th_flux[1], th_flux[1]], col=col_a2, linestyle=5
  
  plot, index, exp(-1.0d0*tau_1mm[w]/sin(elev[w])), /xs, /ys, psym=8, xtitle='scan index', $
        ytitle='Atmospheric transmission', $
        /nodata, yr=[0.2, 1.0], xr=[min(index)-1, max(index)+1]
  
  oplot, index, exp(-1.0d0*tau_1mm[w]/sin(elev[w])), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
  oplot, index, exp(-1.0d0*tau_a1[w]/sin(elev[w])), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
  oplot, index, exp(-1.0d0*tau_a3[w]/sin(elev[w])), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
  oplot, index, exp(-1.0d0*tau_a2[w]/sin(elev[w])), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)
 
  oplot, [min(index)-1, max(index)+1], [0.4, 0.4], col=col_1mm, linestyle=5
  
  !p.multi=0
  outplot, /close


  
  if keyword_set(pas_a_pas) then stop
              
  ;; second version for saving in a ps file
  if keyword_set(ps) then begin


     
     outplot, file=dir+'/Plot_MWC349_flux', ps=ps, xsize=ps_pxsize*0.7, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
     !p.multi=[0,1,2]
     
     plot, index, flux_1mm[w], /xs, /ys, psym=8, xtitle='scan index', $
           ytitle=yflux+ '[Jy]', $
           /nodata, yr=[0.5, 2.5], xr=[min(index)-1, max(index)+1], title='MWC349'
     
     oplot, index, flux_1mm[w], col=col_1mm, psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25)
     oplot, index, flux_a1[w], col=col_a1,  psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25)
     oplot, index, flux_a3[w], col=col_a3,  psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25)
     oplot, index, flux_a2[w], col=col_a2,  psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25)
     my_match, w, index_select, suba, subb
     if nn gt 0 then begin
        oplot, index[w[suba]], flux_1mm[w[suba]], col=col_1mm,psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
        oplot, index[w[suba]], flux_a1[w[suba]], col=col_a1, psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
        oplot, index[w[suba]], flux_a3[w[suba]], col=col_a3, psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
        oplot, index[w[suba]], flux_a2[w[suba]], col=col_a2, psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
     endif
     
     legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
                  color=[col_a1, col_a3, col_a2], /bottom
     
     nu = [260.0d0, 150.0d0]
     th_flux = 1.16d0*(nu/100.0)^0.60
     oplot, [min(index)-1, max(index)+1], [th_flux[0], th_flux[0]], col=col_1mm, linestyle=5
     oplot, [min(index)-1, max(index)+1], [th_flux[1], th_flux[1]], col=col_a2, linestyle=5
     
     plot, index, exp(-1.0d0*tau_1mm[w]/sin(elev[w])), /xs, /ys, psym=8, xtitle='scan index', $
           ytitle='Atmospheric transmission', $
           /nodata, yr=[0.2, 1.0], xr=[min(index)-1, max(index)+1]
     
     oplot, index, exp(-1.0d0*tau_1mm[w]/sin(elev[w])), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
     oplot, index, exp(-1.0d0*tau_a1[w]/sin(elev[w])), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
     oplot, index, exp(-1.0d0*tau_a3[w]/sin(elev[w])), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
     oplot, index, exp(-1.0d0*tau_a2[w]/sin(elev[w])), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)
     
     oplot, [min(index)-1, max(index)+1], [0.4, 0.4], col=col_1mm, linestyle=5
     
     !p.multi=0
     outplot, /close
     
     if keyword_set(pdf) then my_epstopdf_converter, dir+'/Plot_MWC349_flux'

     ;; restore plot default characteristics
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
     !p.multi = 0
     
  endif
              
  
  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3


  if keyword_set(savefile) then begin
     if keyword_set( aperture) then begin  ; will happen after the next case
        restore, file=dir+'/photometry_check_on_secondaries.save'
        w = where(obj[index_select] eq 'MWC349', nn)
        ww = index_select[w]
        secondary.calibration_bias_AP[0] = mean(flux_ratio_a1[ww])
        secondary.calibration_bias_AP[1] = mean(flux_ratio_a3[ww])
        secondary.calibration_bias_AP[2] = mean(flux_ratio_1mm[ww])
        secondary.calibration_bias_AP[3] = mean(flux_ratio_a2[ww])
        
        if nn gt 1 then begin
           secondary.calibration_bias_rms_AP[0] = stddev(flux_ratio_a1[ww])
           secondary.calibration_bias_rms_AP[1] = stddev(flux_ratio_a3[ww])
           secondary.calibration_bias_rms_AP[2] = stddev(flux_ratio_1mm[ww])
           secondary.calibration_bias_rms_AP[3] = stddev(flux_ratio_a2[ww])
        endif
        ; Resave the structure a second time
        save, secondary, file=dir+'/photometry_check_on_secondaries.save'
     endif else begin
        secondary = create_struct(  "calibrator", '', $
                                    "observed_scan_list", strarr(100), $
                                    "selected_scan_list", strarr(100), $
                                    "calibration_bias", fltarr(4), $
                                    "calibration_bias_rms", fltarr(4), $
                                    "calibration_bias_AP", fltarr(4), $
                                    "calibration_bias_rms_AP", fltarr(4))
        secondary.calibrator = 'MWC349'
        w = where(obj eq 'MWC349', nn)
        secondary.observed_scan_list = allscan_info[w].scan
        w = where(obj[index_select] eq 'MWC349', nn)
        ww = index_select[w]
        for i=0, nn-1 do secondary.selected_scan_list[i] = allscan_info[ww[i]].scan
        
        secondary.calibration_bias[0] = mean(flux_ratio_a1[ww])
        secondary.calibration_bias[1] = mean(flux_ratio_a3[ww])
        secondary.calibration_bias[2] = mean(flux_ratio_1mm[ww])
        secondary.calibration_bias[3] = mean(flux_ratio_a2[ww])
        
        if nn gt 1 then begin
           secondary.calibration_bias_rms[0] = stddev(flux_ratio_a1[ww])
           secondary.calibration_bias_rms[1] = stddev(flux_ratio_a3[ww])
           secondary.calibration_bias_rms[2] = stddev(flux_ratio_1mm[ww])
           secondary.calibration_bias_rms[3] = stddev(flux_ratio_a2[ww])
        endif
        save, secondary, file=dir+'/photometry_check_on_secondaries.save'
     endelse
     

  endif 
  
  
  ;;
  ;;
  ;; FLUX RATIO VS FWHM
  ;;_______________________________________________________________________
  if keyword_set(fwhm_stability) then begin

     nsource = n_elements(sources)
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'/plot_secondary_flux_ratio_vs_fwhm'+plot_suffixe
     outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick

     !p.multi=[0,2,2]

     col_tab = [col_mwc349, col_crl2688, col_ngc7027]
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[index_select])+0.2 ]   )
     ymin = min( [0.8, min(flux_ratio_1mm[index_select])-0.2]   )
     xmax  = 14.5
     xmin  = 10.8
     
     
     plot, fwhm_1mm , flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin, xmax], $
           xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_1mm[w], flux_ratio_1mm[w], psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), col=col_tab[isou]
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_1mm[index_select[w]], flux_ratio_1mm[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=col_tab[isou]
     endfor
     
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[xmax-(xmax-xmin)*0.35, ymax-0.05]
     
     oplot, [xmin,xmax], [1., 1.], col=0
             
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0 
             
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[index_select])+0.2 ]   )
     ymin = min( [0.8, min(flux_ratio_a1[index_select])-0.2 ]   )
     xmax  = 14.5
     xmin  = 10.8
     
     plot, fwhm_a1 , flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a1[w], flux_ratio_a1[w], psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), col=col_tab[isou]
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a1[index_select[w]], flux_ratio_a1[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=col_tab[isou]
     endfor
     
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;

     
     oplot, [xmin, xmax], [1., 1.], col=0
          
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0 
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[index_select])+0.2 ]   )
     ymin = min( [0.8, min(flux_ratio_a3[index_select])-0.2 ]   )
     xmax  = 14.5
     xmin  = 10.8
     
     plot, fwhm_a3 , flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata
        
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a3[w], flux_ratio_a3[w], psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), col=col_tab[isou]
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a3[index_select[w]], flux_ratio_a3[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=col_tab[isou]
     endfor

     
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     
     oplot, [xmin, xmax], [1., 1.], col=0
          
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0 
     
             
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[index_select])+0.2]   )
     ymin = min( [0.8, min(flux_ratio_a2[index_select])-0.2]   )
     xmax  = 19.5
     xmin  = 17.0
     
     plot, fwhm_a2 , flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata
     
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a2[w], flux_ratio_a2[w], psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), col=col_tab[isou]
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, fwhm_a2[index_select[w]], flux_ratio_a2[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=col_tab[isou]
     endfor
     
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     
     oplot, [xmin, xmax], [1., 1.], col=0
          
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0

     !p.multi = 0
     outplot, /close
     
     
     if nostop lt 1 then stop

     
     if keyword_set(ps) then begin
        
        outfile = dir+'/plot_secondary_flux_ratio_vs_fwhm'+plot_suffixe
        outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

        my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
        
        ;; 1mm
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_1mm[index_select])+0.2]   )
        ymin = min( [0.8, min(flux_ratio_1mm[index_select])-0.2]   )
        xmax  = 14.5
        xmin  = 10.8
        
        plot, fwhm_1mm , flux_ratio_1mm, /xs, yr=[ymin, ymax], $
              xr=[xmin, xmax], $
              xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[0, *]
        
        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_1mm[w], flux_ratio_1mm[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25), col=col_tab[isou]
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_1mm[index_select[w]], flux_ratio_1mm[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25), col=col_tab[isou]
        endfor
        
        legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=ps_charsize, pos=[xmax-(xmax-xmin)*0.25, ymax-0.05]
        
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;

        oplot, [xmin, xmax], [1., 1.], col=0
                
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0 
        
        
        ;; A1
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a1[index_select])+0.2]   )
        ymin = min( [0.8, min(flux_ratio_a1[index_select])-0.2]   )
        xmax  = 14.5
        xmin  = 10.8
        
        plot, fwhm_a1 , flux_ratio_a1, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[1, *], noerase=1
        
        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_a1[w], flux_ratio_a1[w], psym=cgsymcat('OPENCIRCLE', thick=mythick*0.25), col=col_tab[isou]
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_a1[index_select[w]], flux_ratio_a1[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=col_tab[isou]
        endfor
         
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        
        oplot, [xmin, xmax], [1., 1.], col=0
        

        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0 
        
               
        ;; A3
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a3[index_select]) +0.2]   )
        ymin = min( [0.8, min(flux_ratio_a3[index_select]) -0.2]   )
        xmax  = 14.5
        xmin  = 10.8
        
                
        plot, fwhm_a3 , flux_ratio_a3, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[2, *], noerase=1

        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_a3[w], flux_ratio_a3[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25), col=col_tab[isou]
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_a3[index_select[w]], flux_ratio_a3[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25), col=col_tab[isou]
        endfor

        
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), box=0, symsize=[0.8*ps_mysymsize], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), box=0, symsize=[0.8*ps_mysymsize], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        
        oplot, [xmin, xmax], [1., 1.], col=0
        

        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0 
        
                
        ;; A2
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a2[index_select]) +0.2]   )
        ymin = min( [0.8, min(flux_ratio_a2[index_select]) -0.2]   )
        xmax  = 19.5
        xmin  = 17.0
        
        plot, fwhm_a2 , flux_ratio_a2, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='FWHM [arcsec]', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[3, *], noerase=1
        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_a2[w], flux_ratio_a2[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick*0.25), col=col_tab[isou]
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, fwhm_a2[index_select[w]], flux_ratio_a2[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25), col=col_tab[isou]
        endfor
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        
        oplot, [xmin, xmax], [1., 1.], col=0
                
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0
        
     outplot, /close
     
     
     if keyword_set(pdf) then begin
        ;;suf = ['_a1', '_a2', '_a3', '_1mm']
        ;;for i=0, 3 do begin
        ;;spawn, 'epspdf --bbox '+dir+'/plot_secondary_flux_ratio_vs_fwhm'+plot_suffixe+'.eps'
        ;;endfor
        my_epstopdf_converter, dir+'/plot_secondary_flux_ratio_vs_fwhm'+plot_suffixe
     endif
     ;; restore plot default characteristics
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
     !p.multi = 0
  endif
     
  endif




  ;;
  ;;   FLUX RATIO AGAINST ATMOSPHERIC TRANSMISSION
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     nsource = n_elements(sources)
     
     col_tab = [col_mwc349, col_crl2688, col_ngc7027]
     

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'/plot_secondary_flux_ratio_vs_obstau'+plot_suffixe
     outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     !p.multi = [0, 2, 2] 
     
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[index_select]) +0.2]   )
     ymin = min( [0.8, min(flux_ratio_1mm[index_select]) -0.2]   )
     xmax  = 0.95
     xmin  = 0.3     
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_1mm[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_1mm[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize 
     endfor
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0
     
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, ymax-0.05]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, ymax-0.10]
     
     legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[xmax-(xmax-xmin)*0.35, ymax-0.05]
    
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[index_select]) +0.2]   )
     ymin = min( [0.8, min(flux_ratio_a1[index_select]) -0.2]   )
     xmax  = 0.95
     xmin  = 0.3
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_a1[w]/sin(elev[w])), flux_ratio_a1[w], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_a1[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_a1[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize
     endfor
     
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[index_select]) +0.2]   )
     ymin = min( [0.8, min(flux_ratio_a3[index_select]) -0.2]   )
     xmax  = 0.95
     xmin  = 0.3

     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_a3[w]/sin(elev[w])), flux_ratio_a3[w], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_a3[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_a3[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize 
     endfor
     
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0
     
     
          
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[index_select]) +0.2]   )
     ymin = min( [0.8, min(flux_ratio_a2[index_select]) -0.2]   )
     xmax  = 0.95
     xmin  = 0.45
     
          
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
     for isou=0, nsource-1 do begin
        w = where(obj eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_a2[w]/sin(elev[w])), flux_ratio_a2[w], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize
        w = where(obj[index_select] eq sources[isou], nn)
        if nn gt 0 then oplot, exp(-tau_a2[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_a2[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[isou], symsize=mysymsize 
     endfor
     
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0
     
     !p.multi = 0
     outplot, /close

     if nostop lt 1 then stop
     
     
     if keyword_set(ps) then begin

        outfile = dir+'/plot_secondary_flux_ratio_vs_obstau'+plot_suffixe
        outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

        my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1
        
        ;; 1mm
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_1mm[index_select]) +0.2]   )
        ymin = min( [0.8, min(flux_ratio_1mm[index_select]) -0.2]   )
        xmax  = 0.95
        xmin  = 0.3     
        
        plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[0,*]
        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_1mm[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_1mm[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize 
        endfor
           
        ;;
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0
        
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, ymax-0.05]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, ymax-0.1]
        
        legendastro, sources, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25)*[1., 1., 1.], textcol=0, box=0, charsize=charsize, pos=[xmax-(xmax-xmin)*0.35, ymax-0.05]
    
                
        ;; A1
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a1[index_select]) +0.2]   )
        ymin = min( [0.8, min(flux_ratio_a1[index_select]) -0.2]   )
        xmax  = 0.95
        xmin  = 0.3
        
        plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[1,*], noerase=1

        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_a1[w]/sin(elev[w])), flux_ratio_a1[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_a1[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_a1[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize 
        endfor
        
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0
                
        
        ;; A3
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a3[index_select]) +0.2]   )
        ymin = min( [0.8, min(flux_ratio_a3[index_select]) -0.2]   )
        xmax  = 0.95
        xmin  = 0.3
        
        plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[2,*], noerase=1
        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_a3[w]/sin(elev[w])), flux_ratio_a3[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_a3[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_a3[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize 
        endfor
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0
        
                
        ;; A2
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a2[index_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a2[index_select])]   )
        xmax  = 0.95
        xmin  = 0.45
        plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[3,*], noerase=1

        for isou=0, nsource-1 do begin
           w = where(obj eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_a2[w]/sin(elev[w])), flux_ratio_a2[w], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize
           w = where(obj[index_select] eq sources[isou], nn)
           if nn gt 0 then oplot, exp(-tau_a2[index_select[w]]/sin(elev[index_select[w]])), flux_ratio_a2[index_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[isou], symsize=ps_mysymsize 
        endfor
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0
        
        outplot, /close
        
        
        if keyword_set(pdf) then begin
           ;;suf = ['_a1', '_a2', '_a3', '_1mm']
           ;;for i=0, 3 do begin
           ;;spawn, 'epspdf --bbox '+dir+'/plot_secondary_flux_ratio_vs_obstau'+plot_suffixe+'.eps'
           ;;endfor
           my_epstopdf_converter, dir+'/plot_secondary_flux_ratio_vs_obstau'+plot_suffixe
        endif
        ;; restore plot default characteristics
        !p.thick = 1.0
        !p.charsize  = 1.2
        !p.charthick = 1.0
        !p.multi = 0

        
     endif
     
  endif


end
