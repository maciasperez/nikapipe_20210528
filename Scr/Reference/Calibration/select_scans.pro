pro select_scans, allscan_info, output_select_index, $
                  calibrator_list = calibrator_list, $
                  flux_threshold_1mm = flux_threshold_1mm, $
                  flux_threshold_2mm = flux_threshold_2mm, $
                  faint=faint, $
                  minimum_nscan_per_source = minimum_nscan_per_source, $
                  fwhm_max = fwhm_max, $
                  weak_fwhm_max = weak_fwhm_max, $
                  strong_fwhm_max = strong_fwhm_max, $
                  showplot=showplot, png=png, ps=ps, pdf=pdf, $
                  output_dir = output_dir, $
                  pas_a_pas=pas_a_pas
  
  ;; remove known outliers ("ceinture et bretelles")
  ;;____________________________________________________________
  outlier_list =  [$
                  '20170223s16', $  ; dark test
                  '20170223s17', $  ; dark test
                  '20171024s171', $ ; focus scan
                  '20171026s235', $ ; focus scan
                  '20171028s313', $ ; RAS from tapas
                  '20180114s73', $  ; TBC
                  '20180116s94', $  ; focus scan
                  '20180118s212', $ ; focus scan
                  '20180119s241', $ ; Tapas comment: 'out of focus'
                  '20180119s242', $ ; Tapas comment: 'out of focus'
                  '20180119s243' $  ; Tapas comment: 'out of focus'                  
                  ]
  out_index = 1
  scan_list_ori = allscan_info.scan
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
  allscan_info = allscan_info[out_index]
  nscans = n_elements(allscan_info)
  
  if keyword_set(output_dir) then output_dir = output_dir else output_dir = getenv('PWD')
  if keyword_set(faint) then faint = 1 else faint = 0

  ;; charsize
  charsize  = 1.2
  charthick = 1.0
  mythick = 1.0
  mysymsize   = 0.8
  if keyword_set(ps) then begin
     ;; charsize
     ps_charsize  = 1.0
     ps_charthick = 2.0
     ps_mythick   = 2.0 
     ps_mysymsize = 1.0
  endif


  
  ;; 
  ;;     scan selection
  ;;
  ;;________________________________________________________

  if keyword_set(flux_threshold_1mm) or keyword_set(flux_threshold_2mm) then begin

     min_flux_1mm = -0.1
     min_flux_2mm = -0.1
     max_flux_1mm = 1000.
     max_flux_2mm = 1000.
     
     if faint gt 0 then begin
        if keyword_set(flux_threshold_1mm) then max_flux_1mm = flux_threshold_1mm 
        if keyword_set(flux_threshold_2mm) then max_flux_2mm = flux_threshold_2mm 
        
        wkeep = where( allscan_info.result_flux_i_1mm ge min_flux_1mm and $
                       allscan_info.result_flux_i_1mm lt max_flux_1mm and $
                       allscan_info.result_flux_i2    ge min_flux_2mm and $
                       allscan_info.result_flux_i2    lt max_flux_2mm, nkeep)
        
        print, 'nb of found scans = ', nkeep
        if nkeep gt 0 then allscan_info = allscan_info[wkeep] else begin
           print, "no scan of sources with flux : "
           print, ' below ', strtrim(max_flux_1mm, 2), " at 1mm and "
           print, ' below ', strtrim(max_flux_2mm, 2), " at 2mm"
           stop
        endelse
        
     endif else begin

        min_flux_1mm = -0.1
        min_flux_2mm = -0.1
        if keyword_set(flux_threshold_1mm) then min_flux_1mm = flux_threshold_1mm 
        if keyword_set(flux_threshold_2mm) then min_flux_2mm = flux_threshold_2mm 
        
        wkeep = where( allscan_info.result_flux_i_1mm ge min_flux_1mm and $
                       allscan_info.result_flux_i2    ge min_flux_2mm, nkeep)
     
        print, 'nb of found scans = ', nkeep
        if nkeep gt 0 then allscan_info = allscan_info[wkeep] else begin
           print, "no scan of sources with flux : "
           print, ' above ', strtrim(flux_threshold_1mm, 2), " at 1mm and "
           print, ' above ', strtrim(flux_threshold_2mm, 2), " at 2mm"
           stop
        endelse

     endelse
  endif
  
  wq = where(allscan_info.object eq '0316+413', nq)
  if nq gt 0 then allscan_info[wq].object = '3C84'

 
  
  allsources = allscan_info.object
  sources = allsources(uniq(allsources, sort(allsources))) 
  if keyword_set(calibrator_list) then sources = calibrator_list
  
  ncalibrator = n_elements(sources)
  
  outlier_col = 250

  output_select_index = -1

  for ical = 0, ncalibrator -1 do begin
     
     source = strupcase(sources[ical])
     print, ''
     print, 'CALIBRATOR = ', source
     print, ''
     
     w = where(strupcase(allscan_info.object) eq source, ntot)
     
     if keyword_set(minimum_nscan_per_source) then begin
        if ntot lt minimum_nscan_per_source then ntot = 0
     endif

     if ntot gt 0 then begin
        
        cal_info = allscan_info[w]

        print, ''
        print, 'FIRST TRY: baseline scan selection + extension to good afternoon scans'
        print, '_______________________________________________________________________'
        ;;
        ;; FIRST TRY: baseline scan selection + extension to good afternoon scans
        ;;________________________________________________________________________
        to_use_photocorr = 0
        complement_index = 1
        beamok_index     = 0
        largebeam_index  = 1
        tauok_index      = 0
        hightau_index    = 1
        obsdateok_index  = 0
        afternoon_index  = 1
        nefd_index       = 1
        calibrator_scan_selection, cal_info, wselect_primary, $
                                   weak_fwhm_max = weak_fwhm_max, $
                                   strong_fwhm_max = strong_fwhm_max, $
                                   to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                                   beamok_index = beamok_index, largebeam_index = largebeam_index,$
                                   tauok_index = tauok_index, hightau_index=hightau_index, $
                                   osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                                   nefd_index = nefd_index

        if faint gt 0 then wselect_primary = nefd_index 
       
        ;; if wselect ne -1
        if wselect_primary[0] ge 0 then begin
           
           output_select_index = [output_select_index, w[wselect_primary]]
           
           if (keyword_set(showplot) and ntot gt 1) then begin
              
              nlargebeam = 0
              if (largebeam_index[0] ge 0 and faint lt 1) then begin
                 wlargebeam = largebeam_index
                 nlargebeam = n_elements(wlargebeam)
              endif
              nafternoon = 0
              if afternoon_index[0] ge 0 then begin
                 wafternoon = afternoon_index
                 nafternoon = n_elements(wafternoon)
              endif
              nhitau3 = 0
              if hightau_index[0] ge 0 then begin
                 whitau3 = hightau_index
                 nhitau3 = n_elements(whitau3)
              endif
              
              
              plot_color_convention, col_a1, col_a2, col_a3, $
                                     col_mwc349, col_crl2688, col_ngc7027, $
                                     col_n2r9, col_n2r12, col_n2r14, col_1mm
              
              ;; first version for on-screen display (and save a png file
              ;; if asked for)
              wind, 1, 1, /free, /large
              outplot, file=output_dir+'/Baseline_scan_selection_'+source, png=png
              !p.multi=[0,1,2]
              index = dindgen(n_elements(cal_info)) ;; calibrator scans only
              ;;
              plot, index, cal_info.result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                    ytitle='FWHM (arcsec)', $
                    /nodata, yr=[7, 22], xr=[min(index)-1, max(index)+1], title='Baseline selection of '+source
              oplot, index, cal_info.result_fwhm_1, psym=8, col=col_a1, symsize=0.7
              oplot, index, cal_info.result_fwhm_3, psym=8, col=col_a3, symsize=0.7
              oplot, index, cal_info.result_fwhm_2, psym=8, col=col_a2, symsize=0.7
              
              if nlargebeam gt 1 then begin
                 oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_1 , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_3 , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_2 , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nlargebeam eq 1 then begin
                 oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_1] , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_3] , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_2] , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nafternoon gt 1 then begin
                 oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_1, psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_3, psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_2, psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nafternoon eq 1 then begin
                 oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_1], psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_3], psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_2], psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nhitau3 gt 1 then begin
                 oplot, index[whitau3], cal_info[whitau3].result_fwhm_1, psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[whitau3], cal_info[whitau3].result_fwhm_3, psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[whitau3], cal_info[whitau3].result_fwhm_2, psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nhitau3 eq 1 then begin
                 oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_1], psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_3], psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_2], psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              xyouts, index[wselect_primary], 7.5, strmid(cal_info[wselect_primary].scan, 4, 8), charsi=0.7, orient=60
              if n_elements(complement_index) gt 0 then  $
                 xyouts, index[complement_index], 7.5, strmid(cal_info[complement_index].scan, 4, 8), charsi=0.7, orient=60, col=250
              
              oplot, [min(index)-1, max(index)+1], [11.6, 11.6], col=col_1mm, LINESTYLE = 5
              oplot, [min(index)-1, max(index)+1], [17.6, 17.6], col=col_a2, LINESTYLE = 5
              
              legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
                           color=[col_a1, col_a3, col_a2], /bottom
              legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], $
                           textcol=0, psym=[7, 4, 6], color=outlier_col, box=0

              ;; second plot
              avg_flux_1 = mean(cal_info.result_flux_i_1mm)
              avg_flux_2 = mean(cal_info.result_flux_i2)
              min_flux = min([avg_flux_1, avg_flux_2])
              max_flux = max([avg_flux_1, avg_flux_2])
              plot, index, cal_info.result_flux_i1, /xs, /ys, psym=8, xtitle='scan index', $
                    ytitle='Flux [Jy]', $
                    /nodata, yr=[min_flux-2., max_flux+2.], xr=[min(index)-1, max(index)+1], title='Baseline selection of '+source
              oplot, index, cal_info.result_flux_i_1mm, psym=8, col=col_1mm, symsize=0.7
              oplot, index, cal_info.result_flux_i2, psym=8, col=col_a2, symsize=0.7
              
              if n_elements(wselect_primary) gt 0 then begin
                 avg_flux_1 = mean(cal_info[wselect_primary].result_flux_i_1mm)
                 avg_flux_2 = mean(cal_info[wselect_primary].result_flux_i2)
                 oplot, [min(index)-1, max(index)+1], [avg_flux_1, avg_flux_1], col=col_1mm, LINESTYLE = 5
                 oplot, [min(index)-1, max(index)+1], [avg_flux_2, avg_flux_2], col=col_a2, LINESTYLE = 5
              endif



              
              !p.multi=0
              outplot, /close
              
              if keyword_set(pas_a_pas) then stop
              
              ;; second version for saving in a ps file
              if keyword_set(ps) then begin

                 thick     = ps_mythick
                 charsize  = ps_charsize
                 charthick = ps_charthick
                 symsize   = ps_mysymsize
                 
                 
                 outplot, file=output_dir+'/Baseline_scan_selection_'+source, ps=ps, xsize=20., ysize=16., charsize=charsize, thick=thick, charthick=charthick 

                 my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
                 
                 index = dindgen(n_elements(cal_info)) ;; calibrators only
                 plot, index, cal_info.result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='FWHM (arcsec)', $
                       /nodata, yr=[5, 24], xr=[min(index)-1, max(index)+1], $
                       title='Baseline selection of '+source, pos=pp1[0, *]
                 oplot, index, cal_info.result_fwhm_1, psym=8, col=col_a1, symsize=0.7*symsize
                 oplot, index, cal_info.result_fwhm_3, psym=8, col=col_a3, symsize=0.7*symsize
                 oplot, index, cal_info.result_fwhm_2, psym=8, col=col_a2, symsize=0.7*symsize
              
                 if nlargebeam gt 1 then begin
                    oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_1 , psym=7, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_3 , psym=7, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_2 , psym=7, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                 endif
                 if nlargebeam eq 1 then begin
                    oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_1] , psym=7, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_3] , psym=7, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_2] , psym=7, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                 endif
                 if nafternoon gt 1 then begin
                    oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_1, psym=4, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_3, psym=4, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_2, psym=4, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                 endif
                 if nafternoon eq 1 then begin
                    oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_1], psym=4, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_3], psym=4, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_2], psym=4, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                 endif
                 if nhitau3 gt 1 then begin
                    oplot, index[whitau3], cal_info[whitau3].result_fwhm_1, psym=6, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, index[whitau3], cal_info[whitau3].result_fwhm_3, psym=6, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, index[whitau3], cal_info[whitau3].result_fwhm_2, psym=6, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                 endif
                 if nhitau3 eq 1 then begin
                    oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_1], psym=6, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_3], psym=6, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                    oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_2], psym=6, $
                           col=outlier_col, thick=thick, symsize=1.5*symsize
                 endif
                 xyouts, index[wselect_primary]-1, 5.5, cal_info[wselect_primary].scan, charsi=0.7, orient=60
                 if n_elements(complement_index) gt 0 then  xyouts, index[complement_index]-1, 5.5, cal_info[complement_index].scan, charsi=0.7, orient=60, col=250
                 
                 oplot, [min(index)-1, max(index)+1], [11.6, 11.6], col=col_1mm, LINESTYLE = 5
                 oplot, [min(index)-1, max(index)+1], [17.6, 17.6], col=col_a2, LINESTYLE = 5
                 
                 
                 legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], $
                              textcol=0, psym=[7, 4, 6], color=outlier_col, box=0
                 
                 ;; second plot
                 avg_flux_1 = mean(cal_info.result_flux_i_1mm)
                 avg_flux_2 = mean(cal_info.result_flux_i2)
                 min_flux = min([avg_flux_1, avg_flux_2])
                 max_flux = max([avg_flux_1, avg_flux_2])
                 plot, index, cal_info.result_flux_i1, /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='Flux [Jy]', $
                       /nodata, yr=[min_flux-2., max_flux+2.], xr=[min(index)-1, max(index)+1],$
                 pos=pp1[1, *], noerase=1
                 oplot, index, cal_info.result_flux_i_1mm, psym=8, col=col_1mm, symsize=0.7*symsize
                 oplot, index, cal_info.result_flux_i2, psym=8, col=col_a2, symsize=0.7*symsize
                 
                 if n_elements(wselect_primary) gt 0 then begin
                    avg_flux_1 = mean(cal_info[wselect_primary].result_flux_i_1mm)
                    avg_flux_2 = mean(cal_info[wselect_primary].result_flux_i2)
                    oplot, [min(index)-1, max(index)+1], [avg_flux_1, avg_flux_1], col=col_1mm, LINESTYLE = 5
                    oplot, [min(index)-1, max(index)+1], [avg_flux_2, avg_flux_2], col=col_a2, LINESTYLE = 5
                 endif
                 legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
                              color=[col_a1, col_a3, col_a2], /bottom
              
                 !p.multi=0
                 outplot, /close
                 
                 if keyword_set(pdf) then my_epstopdf_converter, output_dir+'/Baseline_scan_selection_'+source

                 !p.thick     = 1.0
                 !p.charsize  = 1.0
                 !p.symsize   = 1.0
                 !p.charthick = 1.0

                 
              endif
              
         
           endif
           ;; END OF PLOTTING

           ;; no selected scan for the source 
        endif else begin
                     
           print, ''
           print, 'SECOND TRY: tweaked scan selection'
           print, '____________________________________________________________'
           ;;
           ;; SECOND TRY: tweaked scan selection
           ;;____________________________________________________________
           to_use_photocorr = 0
           complement_index = 1
           beamok_index     = 0
           largebeam_index  = 1
           tauok_index      = 0
           hightau_index    = 1
           obsdateok_index  = 0
           afternoon_index  = 1
           practical_scan_selection, cal_info, wselect_practical, $
                                     to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                                     beamok_index = beamok_index, largebeam_index = largebeam_index,$
                                     tauok_index = tauok_index, hightau_index=hightau_index, $
                                     osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                                     fwhm_max = fwhm_max, nefd_index = nefd_index

           if keyword_set(faint) then wselect_practical = -1
           
           ;; if wselect ne -1
           if wselect_practical[0] ge 0 then begin

              output_select_index = [output_select_index, w[wselect_practical]]
              
              
              if (keyword_set(showplot) and ntot gt 1) then begin
                 
                 nlargebeam = 0
                 if largebeam_index[0] ge 0 then begin
                    wlargebeam = largebeam_index
                    nlargebeam = n_elements(wlargebeam)
                 endif
                 nafternoon = 0
                 if afternoon_index[0] ge 0 then begin
                    wafternoon = afternoon_index
                    nafternoon = n_elements( wafternoon)
                 endif
                 nhitau3 = 0
                 if hightau_index[0] ge 0 then begin
                    whitau3 = hightau_index
                    nhitau3 = n_elements(whitau3)
                 endif
                         
                 plot_color_convention, col_a1, col_a2, col_a3, $
                                        col_mwc349, col_crl2688, col_ngc7027, $
                                        col_n2r9, col_n2r12, col_n2r14, col_1mm
                 
                 
                 ;; first version for on-screen display (and save a png file
                 ;; if asked for)
                 wind, 1, 1, /free, /large
                 outplot, file=output_dir+'/Practical_scan_selection_'+source, png=png
                 !p.multi=[0,1,2]
                 index = dindgen(n_elements(cal_info)) ;; calibrators only
                 plot, index, cal_info.result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='FWHM (arcsec)', $
                       /nodata, yr=[7, 22], xr=[min(index)-1, max(index)+1], title='Practical selection of '+source
                 oplot, index, cal_info.result_fwhm_1, psym=8, col=col_a1, symsize=0.7
                 oplot, index, cal_info.result_fwhm_3, psym=8, col=col_a3, symsize=0.7
                 oplot, index, cal_info.result_fwhm_2, psym=8, col=col_a2, symsize=0.7
        
                 if nlargebeam gt 1 then begin
                    oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_1 , psym=7, $
                           col=outlier_col, thick=1.5, symsize=1.5 
                    oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_3 , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                    oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_2 , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                 endif
                 if nlargebeam eq 1 then begin
                    oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_1] , psym=7, $
                           col=outlier_col, thick=1.5, symsize=1.5 
                    oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_3] , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                    oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_2] , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                 endif
                 if nafternoon gt 1 then begin
                    oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_1, psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_3, psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_2, psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 if nafternoon eq 1 then begin
                    oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_1], psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_3], psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_2], psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 if nhitau3 gt 1 then begin
                    oplot, index[whitau3], cal_info[whitau3].result_fwhm_1, psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[whitau3], cal_info[whitau3].result_fwhm_3, psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[whitau3], cal_info[whitau3].result_fwhm_2, psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 if nhitau3 eq 1 then begin
                    oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_1], psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_3], psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_2], psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 xyouts, index[wselect_practical], 7.5, cal_info[wselect_practical].scan, charsi=0.7, orient=60
                 if n_elements(complement_index) gt 0 then  xyouts, index[complement_index], 7.5, cal_info[complement_index].scan, charsi=0.7, orient=60, col=outlier_col
                 
                 oplot, [min(index)-1, max(index)+1], [11.9, 11.9], col=col_1mm, LINESTYLE = 5
                 oplot, [min(index)-1, max(index)+1], [17.9, 17.9], col=col_a2, LINESTYLE = 5
                 
                 legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
                              color=[col_a1, col_a3, col_a2], /bottom
                 legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=0, $
                              psym=[7, 4, 6], color=outlier_col, box=0
                 
                 ;; second plot
                 avg_flux_1 = mean(cal_info.result_flux_i_1mm)
                 avg_flux_2 = mean(cal_info.result_flux_i2)
                 min_flux = min([avg_flux_1, avg_flux_2])
                 max_flux = max([avg_flux_1, avg_flux_2])
                 plot, index, cal_info.result_flux_i1, /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='Flux [Jy]', $
                       /nodata, yr=[min_flux-2., max_flux+2.], xr=[min(index)-1, max(index)+1]
                 oplot, index, cal_info.result_flux_i_1mm, psym=8, col=col_1mm, symsize=0.7
                 oplot, index, cal_info.result_flux_i2, psym=8, col=col_a2, symsize=0.7
              
                 if n_elements(wselect_practical) gt 0 then begin
                    avg_flux_1 = mean(cal_info[wselect_practical].result_flux_i_1mm)
                    avg_flux_2 = mean(cal_info[wselect_practical].result_flux_i2)
                    oplot, [min(index)-1, max(index)+1], [avg_flux_1, avg_flux_1], col=col_1mm, LINESTYLE = 5
                    oplot, [min(index)-1, max(index)+1], [avg_flux_2, avg_flux_2], col=col_a2, LINESTYLE = 5
                 endif

              
                 !p.multi=0
                 outplot, /close
                 
                 if keyword_set(pas_a_pas) then stop
                 
                 ;; second version for saving in a ps file
                 if keyword_set(ps) then begin
                    
                    thick     = ps_mythick
                    charsize  = ps_charsize
                    charthick = ps_charthick
                    symsize   = ps_mysymsize
                 
                    outplot, file=output_dir+'/Practical_scan_selection_'+source, ps=ps, xsize=20., ysize=16., charsize=charsize, thick=thick, charthick=charthick 
                    my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
                    
                    index = dindgen(n_elements(cal_info)) ;; calibrators only
                    plot, index, cal_info.result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                          ytitle='FWHM (arcsec)', $
                          /nodata, yr=[5, 24], xr=[min(index)-1, max(index)+1], $
                          title='Practical selection of '+source, pos=pp1[0, *]
                    oplot, index, cal_info.result_fwhm_1, psym=8, col=col_a1, symsize=0.7*symsize
                    oplot, index, cal_info.result_fwhm_3, psym=8, col=col_a3, symsize=0.7*symsize
                    oplot, index, cal_info.result_fwhm_2, psym=8, col=col_a2, symsize=0.7*symsize
              
                    if nlargebeam gt 1 then begin
                       oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_1 , psym=7, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize 
                       oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_3 , psym=7, $
                              col=outlier_col,thick=thick, symsize=1.5*symsize 
                       oplot, index[wlargebeam], cal_info[wlargebeam].result_fwhm_2 , psym=7, $
                              col=outlier_col,thick=thick, symsize=1.5*symsize 
                    endif
                    if nlargebeam eq 1 then begin
                       oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_1] , psym=7, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize 
                       oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_3] , psym=7, $
                              col=outlier_col,thick=thick, symsize=1.5*symsize
                       oplot, [index[wlargebeam]], [cal_info[wlargebeam].result_fwhm_2] , psym=7, $
                              col=outlier_col,thick=thick, symsize=1.5*symsize
                    endif
                    if nafternoon gt 1 then begin
                       oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_1, psym=4, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_3, psym=4, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, index[wafternoon], cal_info[wafternoon].result_fwhm_2, psym=4, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                    endif
                    if nafternoon eq 1 then begin
                       oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_1], psym=4, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_3], psym=4, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, [index[wafternoon]], [cal_info[wafternoon].result_fwhm_2], psym=4, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                    endif
                    if nhitau3 gt 1 then begin
                       oplot, index[whitau3], cal_info[whitau3].result_fwhm_1, psym=6, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, index[whitau3], cal_info[whitau3].result_fwhm_3, psym=6, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, index[whitau3], cal_info[whitau3].result_fwhm_2, psym=6, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                    endif
                    if nhitau3 eq 1 then begin
                       oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_1], psym=6, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_3], psym=6, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                       oplot, [index[whitau3]], [cal_info[whitau3].result_fwhm_2], psym=6, $
                              col=outlier_col, thick=thick, symsize=1.5*symsize
                    endif
                    
                    xyouts, index[wselect_practical]-1, 5.5, cal_info[wselect_practical].scan, charsi=0.7*charsize, orient=60
                    if n_elements(complement_index) gt 0 then  xyouts, index[complement_index]-1, 5.5, cal_info[complement_index].scan, charsi=0.7*charsize, orient=60, col=outlier_col
                    
                    oplot, [min(index)-1, max(index)+1], [11.9, 11.9], col=col_1mm, LINESTYLE = 5
                    oplot, [min(index)-1, max(index)+1], [17.9, 17.9], col=col_a2, LINESTYLE = 5
                    
                    
                    legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=0, psym=[7, 4, 6], $
                                 color=outlier_col, box=0
                    
                    ;; second plot
                    avg_flux_1 = mean(cal_info.result_flux_i_1mm)
                    avg_flux_2 = mean(cal_info.result_flux_i2)
                    min_flux = min([avg_flux_1, avg_flux_2])
                    max_flux = max([avg_flux_1, avg_flux_2])
                    plot, index, cal_info.result_flux_i1, /xs, /ys, psym=8, xtitle='scan index', $
                          ytitle='Flux [Jy]', $
                          /nodata, yr=[min_flux-2., max_flux+2.], xr=[min(index)-1, max(index)+1], $
                          pos=pp1[1, *], noerase=1
                    oplot, index, cal_info.result_flux_i_1mm, psym=8, col=col_1mm, symsize=0.7*symsize
                    oplot, index, cal_info.result_flux_i2, psym=8, col=col_a2, symsize=0.7*symsize
                    
                    if n_elements(wselect_practical) gt 0 then begin
                       avg_flux_1 = mean(cal_info[wselect_practical].result_flux_i_1mm)
                       avg_flux_2 = mean(cal_info[wselect_practical].result_flux_i2)
                       oplot, [min(index)-1, max(index)+1], [avg_flux_1, avg_flux_1], col=col_1mm, LINESTYLE = 5
                       oplot, [min(index)-1, max(index)+1], [avg_flux_2, avg_flux_2], col=col_a2, LINESTYLE = 5
                    endif
                    legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], color=[col_a1, col_a3, col_a2], /bottom
                    ;;
                    !p.multi=0
                    outplot, /close
                    
                    if keyword_set(pdf) then my_epstopdf_converter, output_dir+'/Practical_scan_selection_'+source

                    !p.thick     = 1.0
                    !p.charsize  = 1.0
                    !p.symsize   = 1.0
                    !p.charthick = 1.0
                    
                    
                 endif

        
              endif ;; END PLOTTING
              
           endif else begin
              
              print, ''
              print, 'NO SCAN SELECTED !'
              print, '___________________________________'
              n = n_elements(cal_info)
              for i=0, n-1 do print, i, ', scans ',cal_info[i].scan, ' at [UT] = ', cal_info[i].ut, ', FWHM_1mm = ', strtrim(cal_info[i].result_fwhm_1mm,2),', FWHM_2mm = ', strtrim(cal_info[i].result_fwhm_2,2), ', atm transmission = ', strtrim(exp(-1.0d0*(cal_info[i].result_tau_3)/sin(cal_info[i].result_elevation_deg*!dtor)),2)
              
              if keyword_set(pas_a_pas) then stop
              
           endelse
        endelse
     endif
  endfor

  if n_elements(output_select_index) gt 1 then output_select_index = output_select_index[1:*] else begin
     print, ''
     print, ' NO SCAN SELECTED !!!!!!!!!!'
     print, '___________________________________'
     print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
     print, 'Stop to investigate'
     print, 'type .c to continue'
     
     stop
     
  endelse
     

  
     

  
    
end
