pro select_primary_calibrator_scans, allscan_info, output_select_index, $
                                     showplot=showplot, png=png, ps=ps, pdf=pdf, $
                                     output_dir = output_dir, $
                                     nostop = nostop, pas_a_pas=pas_a_pas, $
                                     selection_type = selection_type
  
  ;; dealing with stops in the code
  if keyword_set(nostop) then nostop = 1 else nostop=0
  if keyword_set(pas_a_pas) then pas_a_pas = 1-nostop else pas_a_pas = 0
  
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
                  '20180119s243', $ ; Tapas comment: 'out of focus'
                  '20210113s169' $ ; Focus scan
                  ;;'20210118s237' $
                  ]
  out_index = 1
  scan_list_ori = allscan_info.scan
  remove_scan_from_list, scan_list_ori, outlier_list, scan_list_run, out_index=out_index
  allscan_info = allscan_info[out_index]
  nscans = n_elements(allscan_info)
  
  if keyword_set(output_dir) then output_dir = output_dir else output_dir = getenv('PWD')
  
  ;; charsize
  charsize  = 1.2
  charthick = 1.0
  mythick = 1.0
  mysymsize   = 0.8
  if keyword_set(ps) then begin
     ;; charsize
     ps_charsize  = 0.9
     ps_charthick = 2.0
     ps_mythick   = 2.0 
     ps_mysymsize = 1.0
  endif
  
  
  ;; 
  ;;     scan selection
  ;;
  ;;________________________________________________________
  
  primary_calibrators = ['Uranus', 'Neptune']
  nprimary = n_elements(primary_calibrators)
  
  outlier_col = 250
  
  nsource = 0
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
  fwhm_max         = 0
  nefd_index       = 0
  calibrator_scan_selection, allscan_info, wselect_primary, $
                             to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                             beamok_index = beamok_index, largebeam_index = largebeam_index,$
                             tauok_index = tauok_index, hightau_index=hightau_index, $
                             osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                             nefd_index = nefd_index
  nsource = 0
  isou = 0
  if wselect_primary[0] ge 0 then begin
     while (nsource le 0 and isou lt nprimary) do begin
        
        source = strupcase(primary_calibrators[isou])
        print, ''
        print, 'PRIMARY CALIBRATOR = ', source
        print, ''
        
        w = where(strupcase(allscan_info.object) eq source, ntot)
        wsou = where(strupcase(allscan_info[wselect_primary].object) eq source, nsource)
        
        wu = wselect_primary[wsou]
        
        if (keyword_set(showplot) and ntot gt 1) then begin
           
           nlargebeam = 0
           if largebeam_index[0] ge 0 then begin
              wsou = where(strupcase(allscan_info[largebeam_index].object) eq source, nlargebeam)
              wlargebeam = largebeam_index[wsou]
           endif
           nafternoon = 0
           if afternoon_index[0] ge 0 then begin
              wsou = where(strupcase(allscan_info[afternoon_index].object) eq source, nafternoon)
              wafternoon = afternoon_index[wsou]
           endif
           nhitau3 = 0
           if hightau_index[0] ge 0 then begin
              wsou = where(strupcase(allscan_info[hightau_index].object) eq source, nhitau3)
              whitau3 = hightau_index[wsou]
           endif
           
           
           plot_color_convention, col_a1, col_a2, col_a3, $
                                  col_mwc349, col_crl2688, col_ngc7027, $
                                  col_n2r9, col_n2r12, col_n2r14, col_1mm
           
           ;; first version for on-screen display (and save a png file
           ;; if asked for)
           
           thick = mythick
           
           wind, 1, 1, /free, /large
           outplot, file=output_dir+'/Primary_baseline_scan_selection_'+source, png=png
           !p.multi=[0,1,2]
           index = dindgen(n_elements(allscan_info)) ;; primary calibrators only
           plot, index[w], allscan_info[w].result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                 ytitle='FWHM (arcsec)', $
                 /nodata, yr=[6, 23], xr=[min(index)-1, max(index)+1], title='Baseline selection of '+source
           oplot, index[w], allscan_info[w].result_fwhm_1, psym=8, col=col_a1, symsize=0.7
           oplot, index[w], allscan_info[w].result_fwhm_3, psym=8, col=col_a3, symsize=0.7
           oplot, index[w], allscan_info[w].result_fwhm_2, psym=8, col=col_a2, symsize=0.7
           
           if nlargebeam gt 1 then begin
              oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_1 , psym=7, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_3 , psym=7, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_2 , psym=7, $
                     col=outlier_col, thick=1.5, symsize=1.5
           endif
           if nlargebeam eq 1 then begin
              oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_1] , psym=7, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_3] , psym=7, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_2] , psym=7, $
                     col=outlier_col, thick=1.5, symsize=1.5
           endif
           if nafternoon gt 1 then begin
              oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_1, psym=4, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_3, psym=4, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_2, psym=4, $
                     col=outlier_col, thick=1.5, symsize=1.5
           endif
           if nafternoon eq 1 then begin
              oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_1], psym=4, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_3], psym=4, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_2], psym=4, $
                     col=outlier_col, thick=1.5, symsize=1.5
           endif
           if nhitau3 gt 1 then begin
              oplot, index[whitau3], allscan_info[whitau3].result_fwhm_1, psym=6, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, index[whitau3], allscan_info[whitau3].result_fwhm_3, psym=6, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, index[whitau3], allscan_info[whitau3].result_fwhm_2, psym=6, $
                     col=outlier_col, thick=1.5, symsize=1.5
           endif
           if nhitau3 eq 1 then begin
              oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_1], psym=6, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_3], psym=6, $
                     col=outlier_col, thick=1.5, symsize=1.5
              oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_2], psym=6, $
                     col=outlier_col, thick=1.5, symsize=1.5
           endif
           
           if nsource gt 0 then xyouts, index[wu], 6.5, allscan_info[wu].scan, charsi=0.7, orient=60
           if n_elements(complement_index) gt 0 then begin
              wsou = where(strupcase(allscan_info[complement_index].object) eq source, cnsou)
              cwu = complement_index[wsou]
              if cnsou gt 0 then  xyouts, index[cwu], 6.5, allscan_info[cwu].scan, charsi=0.7, orient=60, col=outlier_col
           endif
           
           oplot, [min(index)-1, max(index)+1], [11.6, 11.6], col=col_1mm, LINESTYLE = 5
           oplot, [min(index)-1, max(index)+1], [17.6, 17.6], col=col_a2, LINESTYLE = 5
           
           legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
                        color=[col_a1, col_a3, col_a2], /bottom
           legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], $
                        textcol=0, psym=[7, 4, 6], color=outlier_col, box=0
           
           
           ;; ATMOSPHERIC TRANSMISSION
           plot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), $
                 /xs, /ys, psym=8, xtitle='scan index', $
                 ytitle='Atmospheric transmission', $
                 /nodata, yr=[0.2, 1.0], xr=[min(index[w])-1, max(index[w])+1]
           
           oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
           oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
           oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_3/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
           oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_2/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
           
           oplot, [min(index[w])-1, max(index[w])+1], [0.4, 0.4], col=col_1mm, linestyle=5
           
           
           !p.multi=0
           outplot, /close
           
           if keyword_set(pas_a_pas) then stop
           
           ;; second version for saving in a ps file
           if keyword_set(ps) then begin
              
              thick     = ps_mythick
              charsize  = ps_charsize
              charthick = ps_charthick
              symsize   = ps_mysymsize
              
              outplot, file=output_dir+'/Primary_baseline_scan_selection_'+source, ps=ps, xsize=20., ysize=16., charsize=charsize, thick=mythick, charthick=charthick 
              ;;!p.multi=[0,1,2]
              my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
              
              index = dindgen(n_elements(allscan_info)) ;; primary calibrators only
              plot, index[w], allscan_info[w].result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                    ytitle='FWHM (arcsec)', $
                    /nodata, yr=[5, 24], xr=[min(index)-1, max(index)+1], $
                    title='Baseline selection of '+source, pos=pp1[0, *]
              oplot, index[w], allscan_info[w].result_fwhm_1, psym=8, col=col_a1, symsize=symsize
              oplot, index[w], allscan_info[w].result_fwhm_3, psym=8, col=col_a3, symsize=symsize
              oplot, index[w], allscan_info[w].result_fwhm_2, psym=8, col=col_a2, symsize=symsize
              
              if nlargebeam gt 1 then begin
                 oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_1 , psym=7, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_3 , psym=7, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_2 , psym=7, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
              endif
              if nlargebeam eq 1 then begin
                 oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_1] , psym=7, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_3] , psym=7, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_2] , psym=7, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
              endif
              if nafternoon gt 1 then begin
                 oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_1, psym=4, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_3, psym=4, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_2, psym=4, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
              endif
              if nafternoon eq 1 then begin
                 oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_1], psym=4, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_3], psym=4, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_2], psym=4, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
              endif
              if nhitau3 gt 1 then begin
                 oplot, index[whitau3], allscan_info[whitau3].result_fwhm_1, psym=6, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, index[whitau3], allscan_info[whitau3].result_fwhm_3, psym=6, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, index[whitau3], allscan_info[whitau3].result_fwhm_2, psym=6, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
              endif
              if nhitau3 eq 1 then begin
                 oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_1], psym=6, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_3], psym=6, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_2], psym=6, $
                        col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
              endif
              if nsource gt 0 then xyouts, index[wu]-1, 5.5, allscan_info[wu].scan, charsi=0.7, orient=60
              if n_elements(complement_index) gt 0 then begin
                 wsou = where(strupcase(allscan_info[complement_index].object) eq source, cnsou)
                 cwu = complement_index[wsou]
                 if cnsou gt 0 then  xyouts, index[cwu]-1, 5.5, allscan_info[cwu].scan, charsi=0.7, orient=60, col=outlier_col
              endif
              
              oplot, [min(index)-1, max(index)+1], [11.6, 11.6], col=col_1mm, LINESTYLE = 5
              oplot, [min(index)-1, max(index)+1], [17.6, 17.6], col=col_a2, LINESTYLE = 5
              
              
              legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], $
                           textcol=0, psym=[7, 4, 6], color=outlier_col, box=0
              
              ;; ATMOSPHERIC TRANSMISSION
              plot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), $
                    /xs, /ys, psym=8, xtitle='scan index', $
                    ytitle='Atmospheric transmission', $
                    /nodata, yr=[0.2, 1.0], xr=[min(index[w])-1, max(index[w])+1], pos=pp1[1, *], noerase=1
           
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_3/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_2/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              
              oplot, [min(index[w])-1, max(index[w])+1], [0.4, 0.4], col=col_1mm, linestyle=5
              legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], $
                           color=[col_a1, col_a3, col_a2], /bottom
              !p.multi=0
              outplot, /close
              
              if keyword_set(pdf) then my_epstopdf_converter, output_dir+'/Primary_baseline_scan_selection_'+source
           endif
           
           !p.thick     = 1.0
           !p.charsize  = 1.0
           !p.symsize   = 1.0
           !p.charthick = 1.0
           !p.multi = 0
           thick = 1.0
        endif
        
        
        isou++
        
     endwhile
  endif
  if nsource gt 0 then begin
     output_select_index = wu
     selection_type = 'Baseline'
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
     fwhm_max         = 0
     nefd_index       = 0
     practical_scan_selection, allscan_info, wselect_practical, $
                               to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                               beamok_index = beamok_index, largebeam_index = largebeam_index,$
                               tauok_index = tauok_index, hightau_index=hightau_index, $
                               osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                               fwhm_max = fwhm_max, nefd_index = nefd_index
     
     nsource = 0
     
     if wselect_practical[0] gt -1 then begin
        isou = 0
        while (nsource le 0 and isou lt nprimary) do begin
           
           
           source = strupcase(primary_calibrators[isou])
           print, ''
           print, 'PRIMARY CALIBRATOR = ', source
           print, ''
           
           
           
           w = where(strupcase(allscan_info.object) eq source, ntot)
           wsou = where(strupcase(allscan_info[wselect_practical].object) eq source, nsource)
           
           wu = wselect_practical[wsou]
           if (keyword_set(showplot) and ntot gt 1) then begin
              
              nlargebeam = 0
              if largebeam_index[0] ge 0 then begin
                 wsou = where(strupcase(allscan_info[largebeam_index].object) eq source, nlargebeam)
                 wlargebeam = largebeam_index[wsou]
              endif
              nafternoon = 0
              if afternoon_index[0] ge 0 then begin
                 wsou = where(strupcase(allscan_info[afternoon_index].object) eq source, nafternoon)
                 wafternoon = afternoon_index[wsou]
              endif
              nhitau3 = 0
              if hightau_index[0] ge 0 then begin
                 wsou = where(strupcase(allscan_info[hightau_index].object) eq source, nhitau3)
                 whitau3 = hightau_index[wsou]
              endif
              
              
              plot_color_convention, col_a1, col_a2, col_a3, $
                                     col_mwc349, col_crl2688, col_ngc7027, $
                                     col_n2r9, col_n2r12, col_n2r14, col_1mm
              
              
              ;; first version for on-screen display (and save a png file
              ;; if asked for)
              
              thick = mythick
              
              wind, 1, 1, /free, /large
              outplot, file=output_dir+'/Primary_practical_scan_selection_'+source, png=png
              ;;!p.multi=[0,1,2]
              my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
              
              index = dindgen(n_elements(allscan_info)) ;; primary calibrators only
              plot, index[w], allscan_info[w].result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                    ytitle='FWHM (arcsec)', $
                    /nodata, yr=[6, 23], xr=[min(index)-1, max(index)+1], $
                    title='Practical selection of '+source, pos = pp1[0, *]
              oplot, index[w], allscan_info[w].result_fwhm_1, psym=8, col=col_a1, symsize=0.7
              oplot, index[w], allscan_info[w].result_fwhm_3, psym=8, col=col_a3, symsize=0.7
              oplot, index[w], allscan_info[w].result_fwhm_2, psym=8, col=col_a2, symsize=0.7
              
              if nlargebeam gt 1 then begin
                 oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_1 , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5 
                 oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_3 , psym=7, $
                        col=outlier_col,thick=1.5, symsize=1.5 
                 oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_2 , psym=7, $
                        col=outlier_col,thick=1.5, symsize=1.5 
              endif
              if nlargebeam eq 1 then begin
                 oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_1] , psym=7, $
                        col=outlier_col, thick=1.5, symsize=1.5 
                 oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_3] , psym=7, $
                        col=outlier_col,thick=1.5, symsize=1.5 
                 oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_2] , psym=7, $
                        col=outlier_col,thick=1.5, symsize=1.5 
              endif
              if nafternoon gt 1 then begin
                 oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_1, psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_3, psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_2, psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nafternoon eq 1 then begin
                 oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_1], psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_3], psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_2], psym=4, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nhitau3 gt 1 then begin
                 oplot, index[whitau3], allscan_info[whitau3].result_fwhm_1, psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[whitau3], allscan_info[whitau3].result_fwhm_3, psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, index[whitau3], allscan_info[whitau3].result_fwhm_2, psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              if nhitau3 eq 1 then begin
                 oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_1], psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_3], psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
                 oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_2], psym=6, $
                        col=outlier_col, thick=1.5, symsize=1.5
              endif
              
              if nsource gt 0 then xyouts, index[wu], 6.5, allscan_info[wu].scan, charsi=0.7, orient=60
              
              if n_elements(complement_index) gt 0 then begin
                 wsou = where(strupcase(allscan_info[complement_index].object) eq source, cnsou)
                 cwu = complement_index[wsou]
                 if cnsou gt 0 then  xyouts, index[cwu], 6.5, allscan_info[cwu].scan, charsi=0.7, orient=60, col=outlier_col
              endif
              
              oplot, [min(index)-1, max(index)+1], [12.0, 12.0], col=col_1mm, LINESTYLE = 5
              oplot, [min(index)-1, max(index)+1], [17.9, 17.9], col=col_a2, LINESTYLE = 5
              
              legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], color=[col_a1, col_a3, col_a2], /bottom
              legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=0, psym=[7, 4, 6], $
                           color=outlier_col, box=0
              
              
              ;; ATMOSPHERIC TRANSMISSION
              plot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), $
                    /xs, /ys, psym=8, xtitle='scan index', $
                    ytitle='Atmospheric transmission', $
                    /nodata, yr=[0.2, 1.0], xr=[min(index[w])-1, max(index[w])+1], pos=pp1[1, *], noerase=1
              
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_3/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_2/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
              
              oplot, [min(index[w])-1, max(index[w])+1], [0.4, 0.4], col=col_1mm, linestyle=5
              
              !p.multi=0
              outplot, /close
              
              
              if keyword_set(pas_a_pas) then begin
                 for i=0, ntot-1 do print, w[i], ', scans ',allscan_info[w[i]].scan,' at [UT]: ', allscan_info[w[i]].ut, ', FWHM_a1 = ', allscan_info[w[i]].result_fwhm_1,', FWHM_a3 = ', allscan_info[w[i]].result_fwhm_3,', FWHM_a2 = ', allscan_info[w[i]].result_fwhm_2, ', atm transmission = ', exp(-1.0d0*(allscan_info[w[i]].result_tau_3)/sin(allscan_info[w[i]].result_elevation_deg*!dtor))
                 stop
              endif
              
              ;; second version for saving in a ps file
              if keyword_set(ps) then begin
                 
                 thick     = ps_mythick
                 charsize  = ps_charsize
                 charthick = ps_charthick
                 symsize   = ps_mysymsize
                 
                 outplot, file=output_dir+'/Primary_practical_scan_selection_'+source, ps=ps, xsize=20., ysize=16., charsize=charsize, thick=mythick, charthick=charthick 
                 ;;!p.multi=[0,1,2]
                 
                 my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
                 
                 index = dindgen(n_elements(allscan_info)) ;; primary calibrators only
                 plot, index[w], allscan_info[w].result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='FWHM (arcsec)', $
                       /nodata, yr=[5, 24], xr=[min(index)-1, max(index)+1], $
                       title='Practical selection of '+source, pos = pp1[0, *]
                 oplot, index[w], allscan_info[w].result_fwhm_1, psym=8, col=col_a1, symsize=symsize*0.7
                 oplot, index[w], allscan_info[w].result_fwhm_3, psym=8, col=col_a3, symsize=symsize*0.7
                 oplot, index[w], allscan_info[w].result_fwhm_2, psym=8, col=col_a2, symsize=symsize*0.7
                 
                 if nlargebeam gt 1 then begin
                    oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_1 , psym=7, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5 
                    oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_3 , psym=7, $
                           col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                    oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_2 , psym=7, $
                           col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                 endif
                 if nlargebeam eq 1 then begin
                    oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_1] , psym=7, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5 
                    oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_3] , psym=7, $
                           col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                    oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_2] , psym=7, $
                           col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                 endif
                 if nafternoon gt 1 then begin
                    oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_1, psym=4, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_3, psym=4, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_2, psym=4, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 endif
                 if nafternoon eq 1 then begin
                    oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_1], psym=4, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_3], psym=4, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_2], psym=4, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 endif
                 if nhitau3 gt 1 then begin
                    oplot, index[whitau3], allscan_info[whitau3].result_fwhm_1, psym=6, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, index[whitau3], allscan_info[whitau3].result_fwhm_3, psym=6, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, index[whitau3], allscan_info[whitau3].result_fwhm_2, psym=6, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 endif
                 if nhitau3 eq 1 then begin
                    oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_1], psym=6, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_3], psym=6, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_2], psym=6, $
                           col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                 endif
                 if nsource gt 0 then xyouts, index[wu]-1, 5.5, allscan_info[wu].scan, charsi=0.7, orient=60
                 if n_elements(complement_index) gt 0 then begin
                    wsou = where(strupcase(allscan_info[complement_index].object) eq source, cnsou)
                    cwu = complement_index[wsou]
                    if cnsou gt 0 then  xyouts, index[cwu]-1, 5.5, allscan_info[cwu].scan, charsi=0.7, orient=60, col=outlier_col
                 endif
                 
                 oplot, [min(index)-1, max(index)+1], [12.0, 12.0], col=col_1mm, LINESTYLE = 5
                 oplot, [min(index)-1, max(index)+1], [17.9, 17.9], col=col_a2, LINESTYLE = 5
                 
                 
                 legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=0, psym=[7, 4, 6], $
                              color=outlier_col, box=0
                 
                 ;; ATMOSPHERIC TRANSMISSION
                 plot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), $
                       /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='Atmospheric transmission', $
                       /nodata, yr=[0.2, 1.0], xr=[min(index[w])-1, max(index[w])+1], pos=pp1[1, *], noerase=1
                 
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_3/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_2/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 
                 oplot, [min(index[w])-1, max(index[w])+1], [0.4, 0.4], col=col_1mm, linestyle=5
                 legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], color=[col_a1, col_a3, col_a2], /bottom
                 !p.multi=0
                 outplot, /close
                 
                 if keyword_set(pdf) then my_epstopdf_converter, output_dir+'/Primary_practical_scan_selection_'+source
                 
                 !p.thick     = 1.0
                 !p.charsize  = 1.0
                 !p.symsize   = 1.0
                 !p.charthick = 1.0
                 thick = 1.0
                 
              endif
              
              
              
           endif
           
           
           isou++
           
           
        endwhile

     endif
     
     if nsource gt 0 then begin
        output_select_index = wu 
        selection_type = 'Practical'
     endif else begin
           
        print, ''
        print, 'THIRD TRY: last-chance scan selection'
        print, '____________________________________________________________'
        ;;
        ;; THIRD TRY:  last-chance scan selection
        ;;____________________________________________________________
        to_use_photocorr = 0
        complement_index = 1
        beamok_index     = 0
        largebeam_index  = 1
        tauok_index      = 0
        hightau_index    = 1
        obsdateok_index  = 0
        afternoon_index  = 1
        fwhm_max         = 0
        nefd_index       = 0
        lastchance_scan_selection, allscan_info, wselect_lastchance, $
                                   to_use_photocorr=to_use_photocorr, complement_index=complement_index, $
                                   beamok_index = beamok_index, largebeam_index = largebeam_index,$
                                   tauok_index = tauok_index, hightau_index=hightau_index, $
                                   osbdateok_index=obsdateok_index, afternoon_index=afternoon_index, $
                                   fwhm_max = fwhm_max, nefd_index = nefd_index
        
        nsource = 0
        
        if wselect_lastchance[0] gt -1 then begin
           isou = 0
           while (nsource le 0 and isou lt nprimary) do begin
              
              
              source = strupcase(primary_calibrators[isou])
              print, ''
              print, 'PRIMARY CALIBRATOR = ', source
              print, ''
              
              
              
              w = where(strupcase(allscan_info.object) eq source, ntot)
              wsou = where(strupcase(allscan_info[wselect_lastchance].object) eq source, nsource)
              
              wu = wselect_lastchance[wsou]
              if (keyword_set(showplot) and ntot gt 1) then begin
                 
                 nlargebeam = 0
                 if largebeam_index[0] ge 0 then begin
                    wsou = where(strupcase(allscan_info[largebeam_index].object) eq source, nlargebeam)
                    wlargebeam = largebeam_index[wsou]
                 endif
                 nafternoon = 0
                 if afternoon_index[0] ge 0 then begin
                    wsou = where(strupcase(allscan_info[afternoon_index].object) eq source, nafternoon)
                    wafternoon = afternoon_index[wsou]
                 endif
                 nhitau3 = 0
                 if hightau_index[0] ge 0 then begin
                    wsou = where(strupcase(allscan_info[hightau_index].object) eq source, nhitau3)
                    whitau3 = hightau_index[wsou]
                 endif
                 
                 
                 plot_color_convention, col_a1, col_a2, col_a3, $
                                        col_mwc349, col_crl2688, col_ngc7027, $
                                        col_n2r9, col_n2r12, col_n2r14, col_1mm
                 
                 
                 ;; first version for on-screen display (and save a png file
                 ;; if asked for)
                 
                 thick = mythick
                 
                 wind, 1, 1, /free, /large
                 outplot, file=output_dir+'/Primary_lastchance_scan_selection_'+source, png=png
                 ;;!p.multi=[0,1,2]
                 my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
                 
                 index = dindgen(n_elements(allscan_info)) ;; primary calibrators only
                 plot, index[w], allscan_info[w].result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='FWHM (arcsec)', $
                       /nodata, yr=[6, 23], xr=[min(index)-1, max(index)+1], $
                       title='Last-chance selection of '+source, pos = pp1[0, *]
                 oplot, index[w], allscan_info[w].result_fwhm_1, psym=8, col=col_a1, symsize=0.7
                 oplot, index[w], allscan_info[w].result_fwhm_3, psym=8, col=col_a3, symsize=0.7
                 oplot, index[w], allscan_info[w].result_fwhm_2, psym=8, col=col_a2, symsize=0.7
                 
                 if nlargebeam gt 1 then begin
                    oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_1 , psym=7, $
                           col=outlier_col, thick=1.5, symsize=1.5 
                    oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_3 , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                    oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_2 , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                 endif
                 if nlargebeam eq 1 then begin
                    oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_1] , psym=7, $
                           col=outlier_col, thick=1.5, symsize=1.5 
                    oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_3] , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                    oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_2] , psym=7, $
                           col=outlier_col,thick=1.5, symsize=1.5 
                    endif
                 if nafternoon gt 1 then begin
                    oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_1, psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_3, psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_2, psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 if nafternoon eq 1 then begin
                    oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_1], psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_3], psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_2], psym=4, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    endif
                 if nhitau3 gt 1 then begin
                    oplot, index[whitau3], allscan_info[whitau3].result_fwhm_1, psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[whitau3], allscan_info[whitau3].result_fwhm_3, psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, index[whitau3], allscan_info[whitau3].result_fwhm_2, psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 if nhitau3 eq 1 then begin
                    oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_1], psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_3], psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                    oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_2], psym=6, $
                           col=outlier_col, thick=1.5, symsize=1.5
                 endif
                 
                 if nsource gt 0 then xyouts, index[wu], 6.5, allscan_info[wu].scan, charsi=0.7, orient=60
                 
                 if n_elements(complement_index) gt 0 then begin
                    wsou = where(strupcase(allscan_info[complement_index].object) eq source, cnsou)
                    cwu = complement_index[wsou]
                    if cnsou gt 0 then  xyouts, index[cwu], 6.5, allscan_info[cwu].scan, charsi=0.7, orient=60, col=outlier_col
                 endif
                 
                 oplot, [min(index)-1, max(index)+1], [12.0, 12.0], col=col_1mm, LINESTYLE = 5
                 oplot, [min(index)-1, max(index)+1], [17.9, 17.9], col=col_a2, LINESTYLE = 5
                 
                 legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], color=[col_a1, col_a3, col_a2], /bottom
                 legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=0, psym=[7, 4, 6], $
                              color=outlier_col, box=0
                 
                 
                 ;; ATMOSPHERIC TRANSMISSION
                 plot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), $
                       /xs, /ys, psym=8, xtitle='scan index', $
                       ytitle='Atmospheric transmission', $
                       /nodata, yr=[0.2, 1.0], xr=[min(index[w])-1, max(index[w])+1], pos=pp1[1, *], noerase=1
                 
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_3/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_2/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                 
                 oplot, [min(index[w])-1, max(index[w])+1], [0.4, 0.4], col=col_1mm, linestyle=5
                 
                 !p.multi=0
                 outplot, /close
                 
                 
                 
                                  
                 ;; second version for saving in a ps file
                 if keyword_set(ps) then begin
                    
                    thick     = ps_mythick
                    charsize  = ps_charsize
                    charthick = ps_charthick
                    symsize   = ps_mysymsize
                    
                    outplot, file=output_dir+'/Primary_lastchance_scan_selection_'+source, ps=ps, xsize=20., ysize=16., charsize=charsize, thick=mythick, charthick=charthick 
                    ;;!p.multi=[0,1,2]
                    
                    my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
                    
                    index = dindgen(n_elements(allscan_info)) ;; primary calibrators only
                    plot, index[w], allscan_info[w].result_fwhm_1, /xs, /ys, psym=8, xtitle='scan index', $
                          ytitle='FWHM (arcsec)', $
                          /nodata, yr=[5, 24], xr=[min(index)-1, max(index)+1], $
                          title='Last-chance selection of '+source, pos = pp1[0, *]
                    oplot, index[w], allscan_info[w].result_fwhm_1, psym=8, col=col_a1, symsize=symsize*0.7
                    oplot, index[w], allscan_info[w].result_fwhm_3, psym=8, col=col_a3, symsize=symsize*0.7
                    oplot, index[w], allscan_info[w].result_fwhm_2, psym=8, col=col_a2, symsize=symsize*0.7
                    
                    if nlargebeam gt 1 then begin
                       oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_1 , psym=7, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5 
                       oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_3 , psym=7, $
                                 col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                       oplot, index[wlargebeam], allscan_info[wlargebeam].result_fwhm_2 , psym=7, $
                              col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                    endif
                    if nlargebeam eq 1 then begin
                       oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_1] , psym=7, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5 
                       oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_3] , psym=7, $
                              col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                       oplot, [index[wlargebeam]], [allscan_info[wlargebeam].result_fwhm_2] , psym=7, $
                              col=outlier_col,thick=thick*1.5, symsize=symsize*1.5 
                    endif
                    if nafternoon gt 1 then begin
                       oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_1, psym=4, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_3, psym=4, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, index[wafternoon], allscan_info[wafternoon].result_fwhm_2, psym=4, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    endif
                    if nafternoon eq 1 then begin
                       oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_1], psym=4, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_3], psym=4, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, [index[wafternoon]], [allscan_info[wafternoon].result_fwhm_2], psym=4, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    endif
                    if nhitau3 gt 1 then begin
                       oplot, index[whitau3], allscan_info[whitau3].result_fwhm_1, psym=6, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, index[whitau3], allscan_info[whitau3].result_fwhm_3, psym=6, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, index[whitau3], allscan_info[whitau3].result_fwhm_2, psym=6, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    endif
                    if nhitau3 eq 1 then begin
                       oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_1], psym=6, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_3], psym=6, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                       oplot, [index[whitau3]], [allscan_info[whitau3].result_fwhm_2], psym=6, $
                              col=outlier_col, thick=thick*1.5, symsize=symsize*1.5
                    endif
                    if nsource gt 0 then xyouts, index[wu]-1, 5.5, allscan_info[wu].scan, charsi=0.7, orient=60
                    if n_elements(complement_index) gt 0 then begin
                       wsou = where(strupcase(allscan_info[complement_index].object) eq source, cnsou)
                       cwu = complement_index[wsou]
                       if cnsou gt 0 then  xyouts, index[cwu]-1, 5.5, allscan_info[cwu].scan, charsi=0.7, orient=60, col=outlier_col
                    endif
                    
                    oplot, [min(index)-1, max(index)+1], [12.0, 12.0], col=col_1mm, LINESTYLE = 5
                    oplot, [min(index)-1, max(index)+1], [17.9, 17.9], col=col_a2, LINESTYLE = 5
                    
                    
                    legendastro, ['FWHM outlier', 'obsdate outlier', 'opacity outlier'], textcol=0, psym=[7, 4, 6], $
                                 color=outlier_col, box=0
                    
                    ;; ATMOSPHERIC TRANSMISSION
                    plot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), $
                          /xs, /ys, psym=8, xtitle='scan index', $
                          ytitle='Atmospheric transmission', $
                          /nodata, yr=[0.2, 1.0], xr=[min(index[w])-1, max(index[w])+1], pos=pp1[1, *], noerase=1
                    
                    oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1mm/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_1mm, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                    oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_1/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a1,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                    oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_3/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a3,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                    oplot, index[w], exp(-1.0d0*allscan_info[w].result_tau_2/sin(allscan_info[w].result_elevation_deg*!dtor)), col=col_a2,  psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)
                    
                    oplot, [min(index[w])-1, max(index[w])+1], [0.4, 0.4], col=col_1mm, linestyle=5
                    legendastro, ['A1', 'A3', 'A2'], textcol=0, box=0, psym=[8, 8, 8], color=[col_a1, col_a3, col_a2], /bottom
                    !p.multi=0
                    outplot, /close
                    
                    if keyword_set(pdf) then my_epstopdf_converter, output_dir+'/Primary_lastchance_scan_selection_'+source
                    
                    !p.thick     = 1.0
                    !p.charsize  = 1.0
                    !p.symsize   = 1.0
                    !p.charthick = 1.0
                    thick = 1.0
                    
                 endif
                 
                 
                    
              endif
              
              
              
              isou++
              
              
           endwhile

        endif
        
        if nsource gt 0 then begin
           output_select_index = wu 
           selection_type = 'Lastchance'
           print, ''
           print, "Let's have a look at the properties of all found scan(s)"
           print, ''
           for i=0, ntot-1 do print, w[i], ', scans ',allscan_info[w[i]].scan,' at [UT]: ', allscan_info[w[i]].ut, ', FWHM_a1 = ', allscan_info[w[i]].result_fwhm_1,', FWHM_a3 = ', allscan_info[w[i]].result_fwhm_3,', FWHM_a2 = ', allscan_info[w[i]].result_fwhm_2, ', atm transmission = ', exp(-1.0d0*(allscan_info[w[i]].result_tau_3)/sin(allscan_info[w[i]].result_elevation_deg*!dtor))
           print, ''
           print, 'and at the selected scan(s)'
           for i=0, nsource-1 do print, wu[i], ', scans ',allscan_info[wu[i]].scan,' at [UT]: ', allscan_info[wu[i]].ut, ', FWHM_a1 = ', allscan_info[wu[i]].result_fwhm_1,', FWHM_a3 = ', allscan_info[wu[i]].result_fwhm_3,', FWHM_a2 = ', allscan_info[wu[i]].result_fwhm_2, ', atm transmission = ', exp(-1.0d0*(allscan_info[wu[i]].result_tau_3)/sin(allscan_info[wu[i]].result_elevation_deg*!dtor))

           if nostop lt 1 then begin
              print, '.c to continue'
              stop
           endif
                 
        endif
        if wselect_lastchance[0] le -1 or nsource le 0 then begin
           
           print, ''
           print, 'NO PRIMARY SCAN SELECTED AFTER THREE TRIES !!!!!!!!!!'
           print, '_____________________________________________________'
           for isou = 0, nprimary-1 do begin
              source = strupcase(primary_calibrators[isou])
              
              w = where(strupcase(allscan_info.object) eq source, ntot)
              if ntot gt 0 then for i=0, ntot-1 do print, w[i], ', scans ',allscan_info[w[i]].scan,' at [UT]: ', allscan_info[w[i]].ut, ', FWHM_a1 = ', allscan_info[w[i]].result_fwhm_1,', FWHM_a3 = ', allscan_info[w[i]].result_fwhm_3,', FWHM_a2 = ', allscan_info[w[i]].result_fwhm_2, ', atm transmission = ', exp(-1.0d0*(allscan_info[w[i]].result_tau_3)/sin(allscan_info[w[i]].result_elevation_deg*!dtor)), ', flux_a1 = ',allscan_info[w[i]].result_flux_i1, ', flux_a3 = ',allscan_info[w[i]].result_flux_i3, ', flux_a2 = ',allscan_info[w[i]].result_flux_i2
              
           endfor
           print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
           print, 'Stop to investigate'
           print, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
           print, 'If you know what you are doing, you can pick the "less bad" scan to perform the absolute calibration.'
           print, "Tips: take the one with the best angular resolution, the hightest atmospheric transmission and the highest flux"
           print, "Good luck..."
           print, ""
           print, "Now, let's enter the ID of the chosen scan"
           chosen = ''
           read, chosen
           print, 'then type .c to continue'

           output_select_index = -1
           if strlen(chosen) ge 10 then begin
              w=where(strmatch(allscan_info.scan, chosen) gt 0, n)
              if n eq 1 then output_select_index = [w]
              nostop = 0
           endif
           stop
        endif

     endelse ;; practical
     
  endelse ;; baseline
  
  
end
  
