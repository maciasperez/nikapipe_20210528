pro plot_flux_density_all, allscan_info, index_select, $
                           outplot_dir = outplot_dir, $
                           png=png, ps=ps, pdf=pdf, $
                           obsdate_stability=obsdate_stability, $
                           obstau_stability=obstau_stability, $
                           nostop = nostop, $
                           output_rms_errors = output_rms_errors, $
                           output_source_list = output_source_list, $
                           aperture = aperture
  
  ;; outplot directory
  if keyword_set(outplot_dir) then dir = outplot_dir else $
     dir     = getenv('NIKA_PLOT_DIR')+'/Performance_plots'

  if keyword_set(nostop) then nostop=1 else nostop=0
  if keyword_set(savefile) then savefile = 1 else savefile = 0


  
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
  pxsize = 22.
  pysize = 16.
  ;; charsize
  charsize  = 1.2
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
  nscan_threshold = 5
  ;;nscan_threshold = 4 ;; LP Nov 2020
  ;;nscan_threshold = 3 ;; LP May 2021
  
  scan_info = allscan_info[index_select]
  allsources = strupcase(scan_info.object)
  sources = allsources(uniq(allsources, sort(allsources)))
  
  ;; test number of scans
  ;;__________________________________________________________
  nsou = n_elements(sources)
  n_per_sources = lonarr(nsou)
  for isou = 0, nsou-1 do begin
     w = where(strupcase(scan_info.object) eq sources[isou], ntot, compl = w_others, ncompl= n_others)
     n_per_sources[isou] = ntot
  endfor
  ;; lower the threshold on required scan numbers to a mimimum of 3 
  maxscans = max(n_per_sources)
  if (maxscans lt nscan_threshold and maxscans ge 3) then begin
     for i=0,4 do print,''
     print, "THE REQUIRED MINIMUM NUMBER OF SCANS PER SOURCES HAS BEEN CHANGED FROM  ", strtrim(nscan_threshold, 2), " TO ", strtrim(maxscans, 2)
     nscan_threshold = maxscans
  endif
  ;; reiterate the test of number of scans per sources
  for isou = 0, nsou-1 do begin
     w = where(strupcase(scan_info.object) eq sources[isou], ntot, compl = w_others, ncompl= n_others)
    if (ntot lt nscan_threshold and n_others gt 0) then scan_info = scan_info[w_others]
  endfor
  
  ;; update sources
  allsources = scan_info.object
  sources = allsources(uniq(allsources, sort(allsources)))

  nscans = n_elements(scan_info)
  scan_list = scan_info.scan

  if keyword_set(output_source_list) then output_source_list = sources

  
  if nscans ge nscan_threshold then begin

     ;; FLUX DENSITY EXPECTATIONS
     ;;____________________________________________________________
     th_flux_1mm = dblarr(nscans)
     th_flux_a2  = dblarr(nscans)
     th_flux_a1  = dblarr(nscans)
     th_flux_a3  = dblarr(nscans)

     nsources = n_elements(sources)
     for isou = 0, nsources-1 do begin
        w = where(strupcase(scan_info.object) eq strupcase(sources[isou]), ntot, compl=wco, ncompl=nco) 
        if ntot ge nscan_threshold then begin
           th_flux_1mm[w]     = median(scan_info[w].result_flux_i_1mm)
           th_flux_a2[w]      = median(scan_info[w].result_flux_i2)
           th_flux_a1[w]      = median(scan_info[w].result_flux_i1)
           th_flux_a3[w]      = median(scan_info[w].result_flux_i3)
        endif
        if keyword_set( aperture) then begin
           if ntot ge nscan_threshold then begin
              th_flux_1mm[w]     = $
                 median(scan_info[w].result_aperture_photometry_i_1mm)
              th_flux_a2[w]      = $
                 median(scan_info[w].result_aperture_photometry_i2)
              th_flux_a1[w]      = $
                 median(scan_info[w].result_aperture_photometry_i1)
              th_flux_a3[w]      = $
                 median(scan_info[w].result_aperture_photometry_i3)
           endif
        endif
     endfor

     flux_1mm     = scan_info.result_flux_i_1mm
     flux_a2      = scan_info.result_flux_i2
     flux_a1      = scan_info.result_flux_i1
     flux_a3      = scan_info.result_flux_i3
     err_flux_1mm = scan_info.result_err_flux_i_1mm
     err_flux_a2  = scan_info.result_err_flux_i2
     err_flux_a1  = scan_info.result_err_flux_i1
     err_flux_a3  = scan_info.result_err_flux_i3
     if keyword_set( aperture) then begin
        flux_1mm     = scan_info.result_aperture_photometry_i_1mm
        flux_a2      = scan_info.result_aperture_photometry_i2
        flux_a1      = scan_info.result_aperture_photometry_i1
        flux_a3      = scan_info.result_aperture_photometry_i3
        err_flux_1mm = scan_info.result_err_aperture_photometry_i_1mm
        err_flux_a2  = scan_info.result_err_aperture_photometry_i2
        err_flux_a1  = scan_info.result_err_aperture_photometry_i1
        err_flux_a3  = scan_info.result_err_aperture_photometry_i3
     endif
     ;;
     fwhm_1mm     = scan_info.result_fwhm_1mm
     fwhm_a2      = scan_info.result_fwhm_2
     fwhm_a1      = scan_info.result_fwhm_1
     fwhm_a3      = scan_info.result_fwhm_3
     ;;
     tau_1mm      = scan_info.result_tau_1mm
     tau_a2       = scan_info.result_tau_2mm
     tau_a1       = scan_info.result_tau_1
     tau_a3       = scan_info.result_tau_3
     ;;
     elev         = scan_info.result_elevation_deg*!dtor
     obj          = scan_info.object
     day          = scan_info.day
     n2runid      = 0
     ut           = strmid(scan_info.ut, 0, 5)
     ;;
     
     ;; calculate ut_float and get flux expectations
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
     
     
     flux_ratio_1mm = flux_1mm/th_flux_1mm
     flux_ratio_a1  = flux_a1/th_flux_a1
     flux_ratio_a2  = flux_a2/th_flux_a2
     flux_ratio_a3  = flux_a3/th_flux_a3
    
     
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     error_rms_tab = dblarr(4)
     error_68_tab  = dblarr(4, 2)
     error_95_tab  = dblarr(4, 2)


     print, ''
     print, ' A1&A3 '
     print, '-----------------------'
     ;; 95% CL
     ;;-----------
     ratio = flux_ratio_1mm
     xbin = 1
     ;; inf
     pdf = HISTOGRAM(ratio, LOCATIONS=xbin, nbins=1000, min= 0.8, max=1.2)
     cumul = total(pdf, /cumulative)/n_elements(ratio)
     wmean=where(cumul ge 0.5)
     bmean = xbin[wmean[0]]
     print,bmean
     ;;
     alpha = 0.3173
     w1s = where(cumul gt alpha/2.)
     b1s = xbin[w1s[0]]
     s1_inf = bmean-b1s
     ;;
     alpha = 0.0455
     alpha = 0.05
     w2s = where(cumul gt alpha/2.)
     b2s = xbin[w2s[0]]
     s2_inf = bmean-b2s
     
     ;; sup
     pdf = HISTOGRAM(ratio, LOCATIONS=xbin, nbins=1000, min= 0.8, max=1.2)
     cumul2 = total(reverse(pdf), /cumulative)/n_elements(ratio)
     ;;
     wmean=where(cumul2 ge 0.5)
     bmean = xbin[wmean[0]]
     print,bmean
     ;;
     alpha = 0.3173
     w1s = where(cumul2 gt alpha/2.)
     b1s = xbin[w1s[0]]
     s1_sup = bmean-b1s
     ;;
     alpha = 0.0455
     w2s = where(cumul2 gt alpha/2.)
     b2s = xbin[w2s[0]]
     s2_sup = bmean-b2s
     print, '68% C.L. from -', strtrim(s1_inf, 2), ' to +', strtrim(s1_sup,2),', mean = ', strtrim((s1_inf+s1_sup)/2.,2)
     print, '95% C.L. from -', strtrim(s2_inf, 2), ' to +', strtrim(s2_sup,2),', mean = ', strtrim((s2_inf+s2_sup)/2.,2)
     
     error_68_tab[2,0] = s1_inf
     error_68_tab[2,1] = s1_sup
     error_95_tab[2,0] = s2_inf
     error_95_tab[2,1] = s2_sup
     
     error_rms_tab[2] = stddev(flux_ratio_1mm)/mean(flux_ratio_1mm)

        
     error_rms_tab[0] = stddev(flux_ratio_a1)/mean(flux_ratio_a1)
     error_rms_tab[1] = stddev(flux_ratio_a3)/mean(flux_ratio_a3)

     print, ''
     print, ' A2 '
     print, '-----------------------'
     ;; 95% CL
     ;;-----------
     ratio = flux_ratio_a2
     xbin = 1
     ;; inf
     pdf = HISTOGRAM(ratio, LOCATIONS=xbin, nbins=1000, min= 0.8, max=1.2)
     cumul = total(pdf, /cumulative)/n_elements(ratio)
     wmean=where(cumul ge 0.5)
     bmean = xbin[wmean[0]]
     print,bmean
     ;;
     alpha = 0.3173
     w1s = where(cumul gt alpha/2.)
     b1s = xbin[w1s[0]]
     s1_inf = bmean-b1s
     ;;
     alpha = 0.0455
     alpha = 0.05
     w2s = where(cumul gt alpha/2.)
     b2s = xbin[w2s[0]]
     s2_inf = bmean-b2s
     
     ;; sup
     pdf = HISTOGRAM(ratio, LOCATIONS=xbin, nbins=1000, min= 0.8, max=1.2)
     cumul2 = total(reverse(pdf), /cumulative)/n_elements(ratio)
     ;;
     wmean=where(cumul2 ge 0.5)
     bmean = xbin[wmean[0]]
     print,bmean
     ;;
     alpha = 0.3173
     w1s = where(cumul2 gt alpha/2.)
     b1s = xbin[w1s[0]]
     s1_sup = bmean-b1s
     ;;
     alpha = 0.0455
     w2s = where(cumul2 gt alpha/2.)
     b2s = xbin[w2s[0]]
     s2_sup = bmean-b2s
     
     print, '68% ', s1_inf, s1_sup, (s1_inf+s1_sup)/2.
     print, '95% ', s2_inf, s2_sup, (s2_inf+s2_sup)/2.
     
     error_68_tab[3,0] = s1_inf
     error_68_tab[3,1] = s1_sup
     error_95_tab[3,0] = s2_inf
     error_95_tab[3,1] = s2_sup
     
     error_rms_tab[3] = stddev(flux_ratio_a2)/mean(flux_ratio_a2)

     output_rms_errors = error_rms_tab

     
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     ;;
     ;;   FLUX RATIO COLOR-CODED FROM THE UT
     ;;
     ;;_____________________________________________________________________________________
     if keyword_set(obsdate_stability) then begin
        
        ut_tab = ['22:00', '07:00', '08:00', '09:00', '12:00','15:00']
        ut_col = [10, 50, 115, 118, 125]
        nut = n_elements(ut_tab)-1

        
        wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
        outfile = dir+'/plot_allbright_flux_ratio_vs_obstau'+plot_suffixe
        outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
        
        !p.multi=[0,2,2]
        
        ;; 1mm
        ;;----------------------------------------------------------
        print, ''
        print, ' A1&A3 '
        print, '-----------------------'
        ymax = max( [1.35, max(flux_ratio_1mm )]   )
        ymin = min( [0.65, min(flux_ratio_1mm )]   )
        xmax  = 0.95
        xmin  = 0.4     
     
        plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata

        leg = strarr(nut)
        for u = 0, nut-1 do begin
           if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
           else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=ut_col[u], symsize=symsize
           leg[u] = ut_tab[u]+'-'+ut_tab[u+1]
        endfor
             
        ;;
        ;;legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=charsize*0.8, pos=[0.47, ymax-(ymax-ymin)*0.1], spacing=0.9
        oplot, [xmin,xmax], [1., 1.]+error_95_tab[2,1], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_95_tab[2,0], col=0, linestyle=2
        ;;
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], [1., 1.]+error_rms_tab[2], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_rms_tab[2], col=0, linestyle=2
        xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
        
        ;; A1
        ;;----------------------------------------------------------
        print, ''
        print, ' A1 '
        print, '-----------------------'
        ymax = max( [1.4, max(flux_ratio_a1 )]   )
        ymin = min( [0.6, min(flux_ratio_a1 )]   )
        xmax  = 0.95
        xmin  = 0.4
     
        plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
     
        for u = 0, nut-1 do begin
           if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
           else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)      
        
           if nn gt 0 then oplot, exp(-tau_a1[w]/sin(elev[w])), flux_ratio_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=ut_col[u], symsize=symsize         
        endfor
        
        ;;
        legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=charsize*0.8, pos=[0.45, ymax-0.1], spacing=0.9
        
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], [1., 1.]+error_rms_tab[0], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_rms_tab[0], col=0, linestyle=2
                              
        xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
     
          
        ;; A3
        ;;----------------------------------------------------------
        print, ''
        print, ' A3 '
        print, '-----------------------'
        ymax = max( [1.4, max(flux_ratio_a3 )]   )
        ymin = min( [0.6, min(flux_ratio_a3 )]   )
        xmax  = 0.95
        xmin  = 0.4
        
          
        plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
        
        for u = 0, nut-1 do begin
           if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
           else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)      
               
           if nn gt 0 then oplot, exp(-tau_a3[w]/sin(elev[w])), flux_ratio_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=ut_col[u] , symsize=symsize        
        endfor
        
        ;;legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=charsize*0.8, pos=[0.49, ymax-0.1], spacing=0.9
        ;;
        
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], [1., 1.]+error_rms_tab[1], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_rms_tab[1], col=0, linestyle=2
        xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
        
        ;; A2
        ;;----------------------------------------------------------
        print, ''
        print, ' A2 '
        print, '-----------------------'
        ymax = max( [1.35, max(flux_ratio_a2 )]   )
        ymin = min( [0.65, min(flux_ratio_a2 )]   )
        xmax  = 0.95
        xmin  = 0.55
        
        plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
        
        for u = 0, nut-1 do begin
           if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
           else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)      
           
           if nn gt 0 then oplot, exp(-tau_a2[w]/sin(elev[w])), flux_ratio_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=mythick*0.25), col=ut_col[u] , symsize=symsize        
        endfor

        ;; 95% CL
        oplot, [xmin,xmax], [1., 1.]+error_95_tab[3,1], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_95_tab[3,1], col=0, linestyle=2
        
        ;;
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], mean(flux_ratio_a2)*[1., 1.]+error_rms_tab[3], col=0, linestyle=2
        oplot, [xmin,xmax], mean(flux_ratio_a2)*[1. , 1. ]-error_rms_tab[3], col=0, linestyle=2
        xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
        outplot, /close
        !p.multi = 0
        
        if keyword_set(ps) then begin

           outfile = dir+'/plot_allbright_flux_ratio_vs_obstau'+plot_suffixe
           outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

           my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1

           ;; 1mm
           ;;----------------------------------------------------------
           print, ''
           print, ' A1&A3 '
           print, '-----------------------'
           ymax = max( [1.35, max(flux_ratio_1mm )]   )
           ymin = min( [0.65, min(flux_ratio_1mm )]   )
           xmax  = 0.95
           xmin  = 0.4     
           
           plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[0, *]
           
           leg = strarr(nut)
           for u = 0, nut-1 do begin
              if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
              else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)
              if nn gt 0 then oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.7), col=ut_col[u], symsize=ps_symsize
              leg[u] = ut_tab[u]+'-'+ut_tab[u+1]
           endfor
           ;;u=0
           ;;w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)
           ;;oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.7), col=ut_col[u], symsize=ps_symsize
     
           ;;
           legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=ps_charsize*0.8, pos=[0.45, ymax-(ymax-ymin)*0.1], spacing=0.9
           ;; 95% CL
           ;;-----------
           oplot, [xmin,xmax], [1., 1.]+error_95_tab[2,1], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_95_tab[2,0], col=0, linestyle=2
     
           ;;
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], [1., 1.]+error_rms_tab[2], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_rms_tab[2], col=0, linestyle=2
           xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
           
           
           ;; A1
           ;;----------------------------------------------------------
           ymax = max( [1.4, max(flux_ratio_a1 )]   )
           ymin = min( [0.6, min(flux_ratio_a1 )]   )
           xmax  = 0.95
           xmin  = 0.4
           
           plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[1, *], noerase=1
           
           for u = 0, nut-1 do begin
              if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
              else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)      
              
              if nn gt 0 then oplot, exp(-tau_a1[w]/sin(elev[w])), flux_ratio_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25), col=ut_col[u], symsize=ps_symsize         
           endfor
           
           ;;
           ;;legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=ps_charsize*0.8, pos=[0.45, ymax-0.1], spacing=0.9
           
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], [1., 1.]+error_rms_tab[0], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_rms_tab[0], col=0, linestyle=2
           
           xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
           
           
           ;; A3
           ;;----------------------------------------------------------
           ymax = max( [1.4, max(flux_ratio_a3 )]   )
           ymin = min( [0.6, min(flux_ratio_a3 )]   )
           xmax  = 0.95
           xmin  = 0.4
           
           plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[2, *], noerase=1
           
           for u = 0, nut-1 do begin
              if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
              else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)      
              
              if nn gt 0 then oplot, exp(-tau_a3[w]/sin(elev[w])), flux_ratio_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25), col=ut_col[u] , symsize=ps_symsize        
           endfor
           
           ;;legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=ps_charsize*0.8, pos=[0.45, ymax-0.1], spacing=0.9
           ;;
           
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], [1., 1.]+error_rms_tab[1], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_rms_tab[1], col=0, linestyle=2
           xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
           
           ;; A2
           ;;----------------------------------------------------------
           ymax = max( [1.35, max(flux_ratio_a2 )]   )
           ymin = min( [0.65, min(flux_ratio_a2 )]   )
           xmax  = 0.95
           xmin  = 0.55
           
           plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[3, *], noerase=1
           
           for u = 0, nut-1 do begin
              if ut_tab[u] lt ut_tab[u+1] then w=where(ut_float ge ut_tab[u] and ut_float lt ut_tab[u+1], nn) $
              else w=where(ut_float ge ut_tab[u] or ut_float lt ut_tab[u+1], nn)      
              
              if nn gt 0 then oplot, exp(-tau_a2[w]/sin(elev[w])), flux_ratio_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.25), col=ut_col[u] , symsize=ps_symsize        
           endfor
           
           legendastro, leg, col=[ut_col], textcol=[ut_col],  box=0, charsize=ps_charsize*0.8, pos=[0.6, ymax-(ymax-ymin)*0.1], spacing=0.9
           ;; 95% CL
           ;;-----------
           oplot, [xmin,xmax], [1., 1.]+error_95_tab[3,1], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_95_tab[3,0], col=0, linestyle=2
           
           ;;
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], mean(flux_ratio_a2)*[1., 1.]+error_rms_tab[3], col=0, linestyle=2
           oplot, [xmin,xmax], mean(flux_ratio_a2)*[1. , 1. ]-error_rms_tab[3], col=0, linestyle=2
           xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
           outplot, /close

           
           if keyword_set(pdf) then begin
              ;;suf = ['_a1', '_a2', '_a3', '_1mm']
              ;;for i=0, 3 do begin
              ;;spawn, 'epspdf --bbox '+dir+'/plot_allbright_flux_ratio_vs_obstau'+plot_suffixe+'.eps'
              ;;endfor
              my_epstopdf_converter, dir+'/plot_allbright_flux_ratio_vs_obstau'+plot_suffixe
           endif
           ;; restore plot default characteristics
           !p.thick = 1.0
           !p.charsize  = 1.0
           !p.charthick = 1.0
           !p.multi=0
        endif
        
     endif
     
     ;;
     ;;   FLUX RATIO COLOR-CODED FROM THE SOURCE
     ;;
     ;;_____________________________________________________________________________________
     if keyword_set(obstau_stability) then begin

        bright_sources = ['MWC349', 'CRL2688', 'NGC7027', '3C84', 'Uranus', 'Neptune']
        colors         = [col_mwc349, col_crl2688, col_ngc7027, 240, 40, 95]

        my_match, bright_sources, sources, suba, subb
        colors  = colors[suba]
        sources = sources[subb]
        
        wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
        outfile = dir+'/plot_allbright_flux_ratio_vs_obstau_sources'+plot_suffixe
        outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
        
        !p.multi=[0,2,2]

        ;; 1mm
        ;;----------------------------------------------------------
        print, ''
        print, ' A1&A3 '
        print, '-----------------------'
        ymax = max( [1.35, max(flux_ratio_1mm )]   )
        ymin = min( [0.65, min(flux_ratio_1mm )]   )
        xmax  = 0.95
        xmin  = 0.4     
     
        plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata

        for u = 0, nsources-1 do begin
           w = where(strupcase(obj) eq strupcase(sources[u]), nn)
           if nn gt 0 then oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=colors[u], symsize=symsize
        endfor
             
        oplot, [xmin,xmax], [1., 1.]+error_95_tab[2,1], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_95_tab[2,0], col=0, linestyle=2
        ;;
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], [1., 1.]+error_rms_tab[2], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_rms_tab[2], col=0, linestyle=2
        xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
        
        ;; A1
        ;;----------------------------------------------------------
        print, ''
        print, ' A1 '
        print, '-----------------------'
        ymax = max( [1.4, max(flux_ratio_a1 )]   )
        ymin = min( [0.6, min(flux_ratio_a1 )]   )
        xmax  = 0.95
        xmin  = 0.4
     
        plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
        
        for u = 0, nsources-1 do begin
           w = where(strupcase(obj) eq strupcase(sources[u]), nn)
           if nn gt 0 then oplot, exp(-tau_a1[w]/sin(elev[w])), flux_ratio_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=colors[u], symsize=symsize
        endfor
        
        ;;
        legendastro, sources, col=colors, textcol=0,  psym=8, box=0, charsize=charsize*0.8, pos=[0.45, ymax-0.1]
        
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], [1., 1.]+error_rms_tab[0], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_rms_tab[0], col=0, linestyle=2
                              
        xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0


          
        ;; A3
        ;;----------------------------------------------------------
        print, ''
        print, ' A3 '
        print, '-----------------------'
        ymax = max( [1.4, max(flux_ratio_a3 )]   )
        ymin = min( [0.6, min(flux_ratio_a3 )]   )
        xmax  = 0.95
        xmin  = 0.4
        
          
        plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata

        for u = 0, nsources-1 do begin
           w = where(strupcase(obj) eq strupcase(sources[u]), nn)
           if nn gt 0 then oplot, exp(-tau_a3[w]/sin(elev[w])), flux_ratio_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=colors[u], symsize=symsize
        endfor
        
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], [1., 1.]+error_rms_tab[1], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_rms_tab[1], col=0, linestyle=2
        xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
        
        ;; A2
        ;;----------------------------------------------------------
        print, ''
        print, ' A2 '
        print, '-----------------------'
        ymax = max( [1.35, max(flux_ratio_a2 )]   )
        ymin = min( [0.65, min(flux_ratio_a2 )]   )
        xmax  = 0.95
        xmin  = 0.55
        
        plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata
        
        for u = 0, nsources-1 do begin
           w = where(strupcase(obj) eq strupcase(sources[u]), nn)
           if nn gt 0 then oplot, exp(-tau_a2[w]/sin(elev[w])), flux_ratio_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=0.7), col=colors[u], symsize=symsize
        endfor
        ;; 95% CL
        oplot, [xmin,xmax], [1., 1.]+error_95_tab[3,1], col=0, linestyle=2
        oplot, [xmin,xmax], [1., 1.]-error_95_tab[3,1], col=0, linestyle=2
        ;;
        oplot, [xmin,xmax], [1., 1.], col=0
        oplot, [xmin,xmax], mean(flux_ratio_a2)*[1., 1.]+error_rms_tab[3], col=0, linestyle=2
        oplot, [xmin,xmax], mean(flux_ratio_a2)*[1. , 1. ]-error_rms_tab[3], col=0, linestyle=2
        xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
        outplot, /close
        !p.multi = 0
        
        if keyword_set(ps) then begin

           outfile = dir+'/plot_allbright_flux_ratio_vs_obstau_sources'+plot_suffixe
           outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

           my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1

           ;; 1mm
           ;;----------------------------------------------------------
           ymax = max( [1.35, max(flux_ratio_1mm )]   )
           ymin = min( [0.65, min(flux_ratio_1mm )]   )
           xmax  = 0.95
           xmin  = 0.4     
           
           plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[0, *]
           
           for u = 0, nsources-1 do begin
              w = where(strupcase(obj) eq strupcase(sources[u]), nn)
              if nn gt 0 then oplot, exp(-tau_1mm[w]/sin(elev[w])), flux_ratio_1mm[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.7), col=colors[u], symsize=ps_symsize
           endfor
           ;;
           legendastro, sources, col=colors, textcol=0,  box=0, psym=8, charsize=ps_charsize*0.8, pos=[0.45, ymax-0.1], spacing=0.9
           ;; 95% CL
           ;;-----------
           oplot, [xmin,xmax], [1., 1.]+error_95_tab[2,1], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_95_tab[2,0], col=0, linestyle=2
           ;;
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], [1., 1.]+error_rms_tab[2], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_rms_tab[2], col=0, linestyle=2
           xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
           
           
           ;; A1
           ;;----------------------------------------------------------
           ymax = max( [1.4, max(flux_ratio_a1 )]   )
           ymin = min( [0.6, min(flux_ratio_a1 )]   )
           xmax  = 0.95
           xmin  = 0.4
           
           plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[1, *], noerase=1
           
           for u = 0, nsources-1 do begin
              w = where(strupcase(obj) eq strupcase(sources[u]), nn)
              if nn gt 0 then oplot, exp(-tau_a1[w]/sin(elev[w])), flux_ratio_a1[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.7), col=colors[u], symsize=ps_symsize
           endfor
           
           ;;
           ;;legendastro, sources, col=colors, textcol=0,  box=0, psym=8, charsize=ps_charsize*0.8, pos=[0.45, ymax-0.1], spacing=0.9
           
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], [1., 1.]+error_rms_tab[0], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_rms_tab[0], col=0, linestyle=2
           
           xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A1', col=0
           
           ;; A3
           ;;----------------------------------------------------------
           ymax = max( [1.4, max(flux_ratio_a3 )]   )
           ymin = min( [0.6, min(flux_ratio_a3 )]   )
           xmax  = 0.95
           xmin  = 0.4
           
           plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[2, *], noerase=1
           
           for u = 0, nsources-1 do begin
              w = where(strupcase(obj) eq strupcase(sources[u]), nn)
              if nn gt 0 then oplot, exp(-tau_a3[w]/sin(elev[w])), flux_ratio_a3[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.7), col=colors[u], symsize=ps_symsize
           endfor
           
           ;;
           ;;legendastro, sources, col=colors, textcol=0,  box=0, psym=8, charsize=ps_charsize*0.8, pos=[0.45, ymax-0.1], spacing=0.9          
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], [1., 1.]+error_rms_tab[1], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_rms_tab[1], col=0, linestyle=2
           xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A3', col=0
           
                      
           ;; A2
           ;;----------------------------------------------------------
           ymax = max( [1.35, max(flux_ratio_a2 )]   )
           ymin = min( [0.65, min(flux_ratio_a2 )]   )
           xmax  = 0.95
           xmin  = 0.55
           
           plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
                 xr=[xmin,xmax], $
                 xtitle='Atmospheric transmission', ytitle=yflux+ 'density ratio', /ys, /nodata, pos=pp1[3, *], noerase=1

           for u = 0, nsources-1 do begin
              w = where(strupcase(obj) eq strupcase(sources[u]), nn)
              if nn gt 0 then oplot, exp(-tau_a2[w]/sin(elev[w])), flux_ratio_a2[w], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick*0.7), col=colors[u], symsize=ps_symsize
           endfor
           
           ;;
           ;;legendastro, sources, col=colors, textcol=0,  box=0, psym=8, charsize=ps_charsize*0.8, pos=[0.6, ymax-0.1], spacing=0.9
           ;; 95% CL
           ;;-----------
           oplot, [xmin,xmax], [1., 1.]+error_95_tab[3,1], col=0, linestyle=2
           oplot, [xmin,xmax], [1., 1.]-error_95_tab[3,0], col=0, linestyle=2
           
           ;;
           oplot, [xmin,xmax], [1., 1.], col=0
           oplot, [xmin,xmax], mean(flux_ratio_a2)*[1., 1.]+error_rms_tab[3], col=0, linestyle=2
           oplot, [xmin,xmax], mean(flux_ratio_a2)*[1. , 1. ]-error_rms_tab[3], col=0, linestyle=2
           xyouts, xmax-(xmax-xmin)*0.13, ymax-(ymax-ymin)*0.13, 'A2', col=0
     
           outplot, /close
           !p.multi=0


           
           if keyword_set(pdf) then begin
              ;;suf = ['_a1', '_a2', '_a3', '_1mm']
              ;;for i=0, 3 do begin
              ;;spawn, 'epspdf --bbox '+dir+'/plot_allbright_flux_ratio_vs_obstau_sources'+plot_suffixe+'.eps'
              ;;endfor
              my_epstopdf_converter, dir+'/plot_allbright_flux_ratio_vs_obstau_sources'+plot_suffixe
           endif
           ;; restore plot default characteristics
           !p.thick = 1.0
           !p.charsize  = 1.0
           !p.charthick = 1.0
        endif
        
     endif

     
     endif else print, 'Not enough scans...'


  
end
