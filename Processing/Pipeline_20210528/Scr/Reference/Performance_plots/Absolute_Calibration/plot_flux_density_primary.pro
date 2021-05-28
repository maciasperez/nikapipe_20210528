pro plot_flux_density_primary, allscan_info, index_select, $
                               outplot_dir = outplot_dir, $
                               png=png, ps=ps, pdf=pdf, $
                               fwhm_stability=fwhm_stability, $
                               obstau_stability=obstau_stability, $
                               nostop = nostop, savefile = savefile
  
  ;; Correction of the beam-widening effect due to Uranus disc
  cu = [1.016, 1.007]
  cu = [0.9855, 0.9936 ]
  
  ;; outplot directory
  if keyword_set(outplot_dir) then dir = outplot_dir else $
     dir     = getenv('NIKA_PLOT_DIR')+'/Performance_plots'

  if keyword_set(nostop) then nostop=1 else nostop=0
  if keyword_set(savefile) then savefile = 1 else savefile = 0
 
  
  plot_suffixe = ''

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
     ps_mysymsize = 0.8
     
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

  w = where(strupcase(allscan_info.object) eq 'URANUS', ntot) 
  if ntot gt 0 then for ui=0, ntot-1 do begin
     i=w[ui]
     nk_scan2run, scan_list[i], run
     th_flux_1mm[i]     = !nika.flux_uranus[0]
     th_flux_a2[i]      = !nika.flux_uranus[1]
     th_flux_a1[i]      = !nika.flux_uranus[0]
     th_flux_a3[i]      = !nika.flux_uranus[0]
  endfor
  w = where(strupcase(allscan_info.object) eq 'NEPTUNE', ntot) 
  if ntot gt 0 then for ui=0, ntot-1 do begin
     i = w[ui]
     nk_scan2run, scan_list[i], run
     th_flux_1mm[i]     = !nika.flux_neptune[0]
     th_flux_a2[i]      = !nika.flux_neptune[1]
     th_flux_a1[i]      = !nika.flux_neptune[0]
     th_flux_a3[i]      = !nika.flux_neptune[0]
  endfor

          
  flux_1mm     = allscan_info.result_flux_i_1mm
  flux_a2      = allscan_info.result_flux_i2
  flux_a1      = allscan_info.result_flux_i1
  flux_a3      = allscan_info.result_flux_i3
  err_flux_1mm = allscan_info.result_err_flux_i_1mm
  err_flux_a2  = allscan_info.result_err_flux_i2
  err_flux_a1  = allscan_info.result_err_flux_i1
  err_flux_a3  = allscan_info.result_err_flux_i3
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

  w_select = index_select
  
  planet_fwhm_max  = [13.0, 18.3, 13.0]
  flux_ratio_1mm = flux_1mm/th_flux_1mm
  flux_ratio_a1  = flux_a1/th_flux_a1
  flux_ratio_a2  = flux_a2/th_flux_a2
  flux_ratio_a3  = flux_a3/th_flux_a3
  
  ;;
  ;;
  ;; FLUX RATIO VS FWHM
  ;;_______________________________________________________________________
  if keyword_set(fwhm_stability) then begin

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'/plot_primary_flux_ratio_vs_fwhm'+plot_suffixe
     outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick

     !p.multi=[0,2,2]
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_select])]   )
     xmax  = 13.5
     xmin  = 11.0
     
     ;;planet_fwhm_max  = [14.0, 18.5, 14.0]
     w_fwhm = where(fwhm_1mm le planet_fwhm_max[0] and $
                    fwhm_a1 le planet_fwhm_max[2] and $
                    fwhm_a3 le planet_fwhm_max[2] and $
                    fwhm_a2 le planet_fwhm_max[1], n_fwhm)
     if n_fwhm le 0 then stop
     
     plot, fwhm_1mm , flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin, xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_1mm[w_fwhm[w]], flux_ratio_1mm[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_1mm[w_select[w]], flux_ratio_1mm[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[13.1, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red
        
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0 
             
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_select])]   )
     xmax  = 13.5
     xmin  = 11.0
     
     plot, fwhm_a1 , flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a1[w_fwhm[w]], flux_ratio_a1[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a1[w_select[w]], flux_ratio_a1[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[13.1, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red
     
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0 
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_select])]   )
     xmax  = 13.5
     xmin  = 11.0
     
     plot, fwhm_a3 , flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
        
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a3[w_fwhm[w]], flux_ratio_a3[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a3[w_select[w]], flux_ratio_a3[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[13.1, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red
     
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0 
     
             
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_select])]   )
     xmax  = 18.5
     xmin  = 17.4
     
     plot, fwhm_a2 , flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata
     
     for u = 0, nut-1 do begin
        w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a2[w_fwhm[w]], flux_ratio_a2[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
        w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
        if nn gt 0 then oplot, fwhm_a2[w_select[w]], flux_ratio_a2[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=ut_col[u], symsize=mysymsize 
     endfor
     legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.17]
     legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                  pos=[xmin+(xmax-xmin)*0.04, 1.14]
     ;;
     legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*charsize, pos=[18.35, 1.17], spacing=0.9
     oplot, [xmin,planet_fwhm_max[1]], [1., 1.], col=0
     oplot, [1., 1.]*planet_fwhm_max[1], [ymin, ymax], col=170 ;; red
     
     xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0

     !p.multi = 0
     outplot, /close
     
     
     if nostop lt 1 then stop

     
     if keyword_set(ps) then begin

        outfile = dir+'/plot_primary_flux_ratio_vs_fwhm'+plot_suffixe
        outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

        my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
        
        ;; 1mm
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_1mm[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_1mm[w_select])]   )
        xmax  = 13.5
        xmin  = 11.0
        
        ;;planet_fwhm_max  = [14.0, 18.5, 14.0]
        w_fwhm = where(fwhm_1mm le planet_fwhm_max[0] and $
                       fwhm_a1 le planet_fwhm_max[2] and $
                       fwhm_a3 le planet_fwhm_max[2] and $
                       fwhm_a2 le planet_fwhm_max[1], n_fwhm)
        if n_fwhm le 0 then stop
        
        
        plot, fwhm_1mm , flux_ratio_1mm, /xs, yr=[ymin, ymax], $
              xr=[xmin, xmax], $
              xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[0, *]
        
        for u = 0, nut-1 do begin
           w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_1mm[w_fwhm[w]], flux_ratio_1mm[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize
           w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_1mm[w_select[w]], flux_ratio_1mm[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize
        endfor
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*ps_charsize, pos=[13.1, 1.17], spacing=0.9
        oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
        oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red
        
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1&A3', col=0 
                
        ;; A1
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a1[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a1[w_select])]   )
        xmax  = 13.5
        xmin  = 11.0
        
                
        plot, fwhm_a1 , flux_ratio_a1, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[1, *], noerase=1
        
        for u = 0, nut-1 do begin
           w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_a1[w_fwhm[w]], flux_ratio_a1[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize 
           w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_a1[w_select[w]], flux_ratio_a1[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize 
        endfor
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*ps_charsize, pos=[13.1, 1.17], spacing=0.9
        oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
        oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red

        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A1', col=0 
        
                
        ;; A3
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a3[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a3[w_select])]   )
        xmax  = 13.5
        xmin  = 11.0
        
        plot, fwhm_a3 , flux_ratio_a3, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[2, *], noerase=1
        
        for u = 0, nut-1 do begin
           w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_a3[w_fwhm[w]], flux_ratio_a3[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize 
           w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_a3[w_select[w]], flux_ratio_a3[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize 
        endfor
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*ps_charsize, pos=[13.1, 1.17], spacing=0.9
        oplot, [xmin,planet_fwhm_max[0]], [1., 1.], col=0
        oplot, [1., 1.]*planet_fwhm_max[0], [ymin, ymax], col=170 ;; red

        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A3', col=0 
        
                
        ;; A2
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a2[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a2[w_select])]   )
        xmax  = 18.5
        xmin  = 17.4
        
        plot, fwhm_a2 , flux_ratio_a2, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='FWHM [arcsec]', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[3, *], noerase=1
        
        for u = 0, nut-1 do begin
           w=where(ut_float[w_fwhm] ge ut_tab[u] and ut_float[w_fwhm] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_a2[w_fwhm[w]], flux_ratio_a2[w_fwhm[w]], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize 
           w=where(ut_float[w_select] ge ut_tab[u] and ut_float[w_select] lt ut_tab[u+1], nn)
           if nn gt 0 then oplot, fwhm_a2[w_select[w]], flux_ratio_a2[w_select[w]], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=ut_col[u], symsize=ps_mysymsize 
        endfor
        legendastro, ['selected'], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.17]
        legendastro, ['discarded'], psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), box=0, symsize=[0.8], $
                     pos=[xmin+(xmax-xmin)*0.04, 1.14]
        ;;
        legendastro, ut_tab, col=[ut_col, ut_col[0]], textcol=[ut_col, ut_col[0]], box=0, charsize=0.7*ps_charsize, pos=[18.35, 1.17], spacing=0.9
        oplot, [xmin,planet_fwhm_max[1]], [1., 1.], col=0
        oplot, [1., 1.]*planet_fwhm_max[1], [ymin, ymax], col=170 ;; red
        
        xyouts, xmin+(xmax-xmin)*0.04, ymin+(ymax-ymin)*0.05, 'A2', col=0
        
     outplot, /close
     
     
     if keyword_set(pdf) then begin
        outfile = dir+'/plot_primary_flux_ratio_vs_fwhm'+plot_suffixe 
        my_epstopdf_converter, outfile
        ;;suf = ['_a1', '_a2', '_a3', '_1mm']
        ;;for i=0, 3 do begin
        ;;spawn, 'epspdf --bbox '+dir+'/plot_primary_flux_ratio_vs_fwhm'+plot_suffixe+'.eps'
        ;;spawn, 'epstopdf '+dir+'plot_flux_density_ratio_fwhm_uranus'+plot_suffixe+suf[i]+'.eps'
        ;;endfor       
     endif

     ;; restore plot default characteristics
     !p.multi = 0
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
  endif
     
  endif




  ;;
  ;;   FLUX RATIO AGAINST ATMOSPHERIC TRANSMISSION
  ;;
  ;;_____________________________________________________________________________________
  if keyword_set(obstau_stability) then begin
     
     col_tab = [col_n2r9, col_n2r12, col_n2r14]

     irun = 0

     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'/plot_primary_flux_ratio_vs_obstau'+plot_suffixe
     outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize, charsize=charsize, thick=mythick, charthick=charthick
     !p.multi = [0, 2, 2] 
     
     
     ;; 1mm
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_1mm[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_1mm[w_select])]   )
     xmax  = 0.95
     xmin  = 0.20     
     
     plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     oplot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize
     oplot, exp(-tau_1mm[w_select]/sin(elev[w_select])), flux_ratio_1mm[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
       
     ;;
     oplot, [xmin,xmax], [1., 1.], col=0
     
     xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
     
     
     
     ;; A1
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a1[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a1[w_select])]   )
     xmax  = 0.95
     xmin  = 0.20
     
     plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, exp(-tau_a1/sin(elev)), flux_ratio_a1, psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
     oplot, exp(-tau_a1[w_select]/sin(elev[w_select])), flux_ratio_a1[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
     
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A1', col=0
     
     
     ;; A3
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a3[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a3[w_select])]   )
     xmax  = 0.95
     xmin  = 0.20

     plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata

     oplot, exp(-tau_a3/sin(elev)), flux_ratio_a3, psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
     oplot, exp(-tau_a3[w_select]/sin(elev[w_select])), flux_ratio_a3[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
       
     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A3', col=0
     
          
     
     ;; A2
     ;;----------------------------------------------------------
     ymax = max( [1.2, max(flux_ratio_a2[w_select] )]   )
     ymin = min( [0.8, min(flux_ratio_a2[w_select])]   )
     xmax  = 0.95
     xmin  = 0.40
     
          
     plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
           xr=[xmin,xmax], $
           xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata
     
     oplot, exp(-tau_a2/sin(elev)), flux_ratio_a2, psym=cgsymcat('OPENCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 
     oplot, exp(-tau_a2[w_select]/sin(elev[w_select])), flux_ratio_a2[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=mythick), col=col_tab[irun], symsize=mysymsize 

     oplot, [xmin,xmax], [1., 1.], col=0
     xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A2', col=0

     !p.multi = 0
     outplot, /close

     if nostop lt 1 then stop
     
     
     if keyword_set(ps) then begin
        
        outfile = dir+'/plot_primary_flux_ratio_vs_obstau'+plot_suffixe
        outplot, file=outfile, ps=ps, xsize=ps_pxsize, ysize=ps_pysize, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick

        my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
        
        ;; 1mm
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_1mm[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_1mm[w_select])]   )
        xmax  = 0.95
        xmin  = 0.20     
        
        plot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[0, *]

        oplot, exp(-tau_1mm/sin(elev)), flux_ratio_1mm, psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize
        oplot, exp(-tau_1mm[w_select]/sin(elev[w_select])), flux_ratio_1mm[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        
        ;;
        oplot, [xmin,xmax], [1., 1.], col=0
     
        xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
        
     
        ;; A1
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a1[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a1[w_select])]   )
        xmax  = 0.95
        xmin  = 0.20
        
        plot, exp(-tau_a1/sin(elev)), flux_ratio_a1, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[1, *], noerase=1
        
        oplot, exp(-tau_a1/sin(elev)), flux_ratio_a1, psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        oplot, exp(-tau_a1[w_select]/sin(elev[w_select])), flux_ratio_a1[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A1', col=0
        
                
        ;; A3
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a3[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a3[w_select])]   )
        xmax  = 0.95
        xmin  = 0.20
        
                
        plot, exp(-tau_a3/sin(elev)), flux_ratio_a3, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[2, *], noerase=1
        
        oplot, exp(-tau_a3/sin(elev)), flux_ratio_a3, psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        oplot, exp(-tau_a3[w_select]/sin(elev[w_select])), flux_ratio_a3[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A3', col=0
        
        ;; A2
        ;;----------------------------------------------------------
        ymax = max( [1.2, max(flux_ratio_a2[w_select] )]   )
        ymin = min( [0.8, min(flux_ratio_a2[w_select])]   )
        xmax  = 0.95
        xmin  = 0.40
        
        plot, exp(-tau_a2/sin(elev)), flux_ratio_a2, /xs, yr=[ymin, ymax], $
              xr=[xmin,xmax], $
              xtitle='Atmospheric transmission', ytitle='Flux density ratio', /ys, /nodata, pos=pp1[3, *], noerase=1
        
        oplot, exp(-tau_a2/sin(elev)), flux_ratio_a2, psym=cgsymcat('OPENCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        oplot, exp(-tau_a2[w_select]/sin(elev[w_select])), flux_ratio_a2[w_select], psym=cgsymcat('FILLEDCIRCLE', thick=ps_mythick), col=col_tab[irun], symsize=ps_mysymsize 
        
        oplot, [xmin,xmax], [1., 1.], col=0
        xyouts, xmax-(xmax-xmin)*0.13, 1.17, 'A2', col=0
        
        outplot, /close
        
        
        if keyword_set(pdf) then begin
           ;;suf = ['_a1', '_a2', '_a3', '_1mm']
           ;;for i=0, 3 do begin
           ;;spawn, 'epspdf --bbox '+dir+'/plot_primary_flux_ratio_vs_obstau'+plot_suffixe+'.eps'
           ;;endfor
           outfile = dir+'/plot_primary_flux_ratio_vs_obstau'+plot_suffixe
           my_epstopdf_converter, outfile
        endif
        
        ;; restore default characteristics of the plots
        !p.thick = 1.0
        !p.charsize  = 1.2
        !p.charthick = 1.0
        !p.multi = 0
     endif
     
  endif


end
