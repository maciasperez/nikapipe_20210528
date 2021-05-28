pro beam_monitoring_with_pointings, png=png, ps=ps, pdf=pdf

  ;;  INPUTS
  
  runname_tab = ['N2R9', 'N2R12', 'N2R14']
  version_tab = ['baseline', 'baseline', 'baseline']

  
  dir = '/data/Workspace/macias/NIKA2/Plots/CalibTests/'

  savefile = 0
  showplot = 1

  output_dir = '/home/perotto/NIKA/Plots/Pointings/'
  plotdir    = getenv('HOME')+'/NIKA/Plots/Performance_plots/Beams/'
  plotname   = 'Beam_monitoring_with_pointings_vs_ut'
  
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
  

  
  ;;-----------------------------------------------------------------------------------

  n2run_tab = strtrim(strmid(runname_tab, 3, 2),2)
  nrun = n_elements(runname_tab)

  if savefile gt 0 then begin
     for irun = 0, nrun-1 do begin
        spawn, 'ls '+dir+'RUN'+n2run_tab[irun]+'_POINTINGS_'+version_tab[irun]+'/v_1/*/results.save', res_files
        nscans = 0
        if res_files[0] gt '' then nscans = n_elements(res_files)
        
        if nscans gt 0 then begin

           ;; initialise allpoint_info
           restore, res_files[0], /v
           allpoint_info = replicate(info1, nscans)
           
           for i =0, nscans-1 do begin
              restore, res_files[i]
              allpoint_info[i] = info1
           endfor

           ;; discard NaN
           wok  = where(finite(allpoint_info.result_fwhm_1mm) gt 0 and $
                        finite(allpoint_info.result_fwhm_2mm) gt 0, nok)
           
           allpoint_info = allpoint_info[wok]
           nscans = nok

           ;; discard pointing session
           ;;outlier_list = ''
           ;;case version_tab[irun] of
           ;;   'N2R9': outlier_list = 
           ;;   'N2R12':
           ;;   'N2R14':
           ;;endcase
           ;; discard extreme elevation
           elevation_min = 30.
           elevation_max = 75.
           wok=where(allpoint_info.elev ge elevation_min and allpoint_info.elev le elevation_max, nok)
           allpoint_info = allpoint_info[wok]
           nscans = nok

           ;; discard resolved object 
           wresol = where(allpoint_info.object eq 'NGC7027' or $
                          allpoint_info.object eq 'NGC7538' or $
                          allpoint_info.object eq 'Mars' or $
                          allpoint_info.object eq 'W3OH' or $
                          allpoint_info.object eq 'Jupiter' or $
                          allpoint_info.object eq '1044+719' or $
                          allpoint_info.object eq '0552+398' or $
                          strmid(allpoint_info.object, 0, 4) eq 'MACS', nresol, compl=wok)
           if nresol gt 0 then begin
              allpoint_info = allpoint_info[wok]
              nscans = nok
           endif
           
           ;; sort by scan-num
           allday   = allpoint_info.day
           day_list = allday[uniq(allday, sort(allday))]
           nday     = n_elements(day_list)
           for id = 0, nday-1 do begin
              wd = where(allpoint_info.day eq day_list[id], nd)
              allpoint_info[wd] = allpoint_info[wd[sort((allpoint_info.scan_num)[wd])]]
           endfor
        
           filename = output_dir+'All_pointings_'+runname_tab[irun]+'_'+version_tab[irun]+'_v2.save'
           print, "saving ", filename
           save, allpoint_info, filename=filename
        endif else print, 'No result files found in ', dir+'RUN'+n2run_tab[irun]+'_POINTINGS_'+version_tab[irun]+'/v_1'
     endfor
  endif
     
  if showplot gt 0 then begin
     
     for irun = 0, nrun-1 do begin
        
        filename = output_dir+'All_pointings_'+runname_tab[irun]+'_'+version_tab[irun]+'_v2.save'
        print, "restoring ", filename
        restore, filename, /v

        nscans = n_elements(allpoint_info)
        index = indgen(nscans)
        
        ut = allpoint_info.ut
        ut_float = fltarr(nscans)
        for i=0, nscans-1 do ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
        
        source = strlowcase(allpoint_info.object)
        wp = where(source eq 'uranus' or source eq 'mars' or source eq 'saturn' or source eq 'neptune', np, compl=ws, ncompl=ns)
        
        day_list = strtrim(allpoint_info.day,2)
        
        
        ;; INDEX PLOT
        wind, 1, 1, /free, /large
        my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.05, xmargin=0.1, ymargin=0.1 ; 1e-6
        ;; 1mm
        plot, index, allpoint_info.result_fwhm_1mm, psym=8, yrange=[8., 16.], /ys, /xs, position=pp1[0,*], ytitle = 'FWHM at 1mm [arcsec]', title = 'N2R'+n2run_tab[irun]+' pointing scans', /nodata
        oplot, index[ws], (allpoint_info.result_fwhm_1mm)(ws), psym=8, col=80
        if np gt 0 then oplot, index[wp], (allpoint_info.result_fwhm_1mm)(wp), psym=8, col=250
        w=where(allpoint_info.elev lt 30. or allpoint_info.elev gt 70., n)
        if n gt 0 then oplot, index[w], allpoint_info[w].result_fwhm_1mm, psym=1, col=0
        oplot, [0, nscans], [11.2, 11.2], col=250
        myday = day_list[0]
        for i=0, nscans-1 do begin
           if day_list[i] ne myday then begin
              oplot, [i,i]*1, [-1,1]*1e10
              myday = day_list[i]
           endif
        endfor

        ;; NB : scans are not ordered by scan_num ! 
        ;; days = day_list[uniq(day_list, sort(day_list))]
        ;; nday = n_elements(days)
        ;; for iday = 0, nday-1 do begin
        ;;    w = where(day_list eq days[iday])
        ;;    wmidi = where(ut_float[w] gt 11.9 and ut_float[w] lt 16., nmidi)
        ;;    print, days[iday], ', ', nmidi
        ;;    if nmidi gt 0. then begin
        ;;       ind = w[wmidi[0]]
        ;;       oplot, [ind,ind]*1, [-1,1]*1e10, linestyle=2
        ;;       print,ind
        ;;    endif
        ;;    stop
        ;; endfor
        
        ;; 2mm
        plot, index, allpoint_info.result_fwhm_2mm, psym=8, yrange=[16., 20.], /ys, /xs, position=pp1[1,*], /noerase, ytitle = 'FWHM at 2mm [arcsec]', xtitle='Scan index'
        oplot, index[ws], (allpoint_info.result_fwhm_2mm)(ws), psym=8, col=80
        if np gt 0 then oplot, index[wp], (allpoint_info.result_fwhm_2mm)(wp), psym=8, col=250
        oplot, [0, nscans], [17.5, 17.5], col=250
        myday = day_list[0]
        for i=0, nscans-1 do begin
           if day_list[i] ne myday then begin
              oplot, [i,i]*1, [-1,1]*1e10
              myday = day_list[i]
           endif
        endfor
        legendastro, ['Planets', 'Others'], textcol=[250, 80], box=0, /bottom
           
        
        ;; UT PLOT

        fname = output_dir+'/Pointings_'+runname_tab[irun]+'_'+version_tab[irun]+'_UT'
        outplot, file=fname, png=png
        
        wind, 1, 1, /free, /large
        my_multiplot, 1, 2, pp, pp1, /rev, gap_y=0.05, xmargin=0.1, ymargin=0.1 ; 1e-6
        ;; 1mm
        plot, ut_float, allpoint_info.result_fwhm_1mm, psym=8, yrange=[8., 16.], /ys, /xs, position=pp1[0,*], ytitle = 'FWHM at 1mm [arcsec]', title = 'N2R'+n2run_tab[irun]+' pointing scans', /nodata
        oplot, ut_float[ws], (allpoint_info.result_fwhm_1mm)(ws), psym=8, col=80
        if np gt 0 then oplot, ut_float[wp], (allpoint_info.result_fwhm_1mm)(wp), psym=8, col=250
        w=where(allpoint_info.elev lt 30. or allpoint_info.elev gt 70., n)
        if n gt 0 then oplot, ut_float[w], allpoint_info[w].result_fwhm_1mm, psym=1, col=0
        oplot, [0, 24], [11.2, 11.2], col=250
        ;; 2mm
        plot, ut_float, allpoint_info.result_fwhm_2mm, psym=8, yrange=[16., 20.], /ys, /xs, position=pp1[1,*], /noerase, ytitle = 'FWHM at 2mm [arcsec]', xtitle='UT [hrs]'
        oplot, ut_float[ws], (allpoint_info.result_fwhm_2mm)(ws), psym=8, col=80
        if np gt 0 then oplot, ut_float[wp], (allpoint_info.result_fwhm_2mm)(wp), psym=8, col=250
        oplot, [0, 24], [17.5, 17.5], col=250
        legendastro, ['Planets', 'Others'], textcol=[250, 80], box=0, /bottom
        outplot, /close

        test_list = ['1308+326','1226+023', '1253-055', '1044+719', '1716+686', '0552+398']
        ntest = n_elements(test_list)
        for i=0, ntest-1 do begin
           print, ''
           print, test_list[i]
           w = where(allpoint_info.object eq test_list[i], nsou)
           if nsou gt 0 then begin
              for ii = 0, nsou-1 do begin
                 print,'1mm : ', allpoint_info[w[ii]].result_fwhm_1mm, ', 2mm : ', $
                       allpoint_info[w[ii]].result_fwhm_2mm
                 print, allpoint_info[w[ii]].elev, ' deg, ',allpoint_info[w[ii]].ut, ' UT'
                 print, allpoint_info[w[ii]].result_flux_i_1mm, ', 2mm : ', $
                       allpoint_info[w[ii]].result_flux_i_2mm
              endfor
           endif
           
        endfor
        

        
        w = where(ut_float le 7. and allpoint_info.result_fwhm_1mm gt 13., nout)
        print, 'N beam large la nuit : ', nout
        if nout gt 0 then begin
           for i=0, nout-1 do print, allpoint_info[w[i]].result_fwhm_1mm, ' arcsec, ', $
                                     allpoint_info[w[i]].object, ', ',allpoint_info[w[i]].elev, ' deg'
        endif

        
        ;;stop
     endfor
  endif

  if keyword_set(ps) then begin

     wd, /a
     ;;ps = 0 
     
     fwhm_1mm     = 0.
     fwhm_a2      = 0.
     fwhm_a1      = 0.
     fwhm_a3      = 0.
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
  
     
     for irun = 0, nrun-1 do begin
        
        filename = output_dir+'All_pointings_'+runname_tab[irun]+'_'+version_tab[irun]+'_v2.save'
        print, "restoring ", filename
        restore, filename, /v        
        nscans = n_elements(allpoint_info)
        
        scan_list    = [scan_list, allpoint_info.scan]
        ;;
        fwhm_1mm     = [fwhm_1mm, allpoint_info.result_fwhm_1mm]
        fwhm_a2      = [fwhm_a2, allpoint_info.result_fwhm_2]
        fwhm_a1      = [fwhm_a1, allpoint_info.result_fwhm_1]
        fwhm_a3      = [fwhm_a3, allpoint_info.result_fwhm_3]
        ;;
        fwhm_x_1mm   = [fwhm_x_1mm, allpoint_info.result_fwhm_x_1mm]
        fwhm_x_a2    = [fwhm_x_a2, allpoint_info.result_fwhm_x_2]
        fwhm_x_a1    = [fwhm_x_a1, allpoint_info.result_fwhm_x_1]
        fwhm_x_a3    = [fwhm_x_a3, allpoint_info.result_fwhm_x_3]
        ;;
        fwhm_y_1mm   = [fwhm_y_1mm, allpoint_info.result_fwhm_y_1mm]
        fwhm_y_a2    = [fwhm_y_a2, allpoint_info.result_fwhm_y_2]
        fwhm_y_a1    = [fwhm_y_a1, allpoint_info.result_fwhm_y_1]
        fwhm_y_a3    = [fwhm_y_a3, allpoint_info.result_fwhm_y_3]
        ;;
        elev         = [elev, allpoint_info.result_elevation_deg*!dtor]
        obj          = [obj, strlowcase(allpoint_info.object)]
        day          = [day, allpoint_info.day]
        runid        = [runid, replicate(runname_tab[irun], n_elements(allpoint_info.day))]
        ut           = [ut, strmid(allpoint_info.ut, 0, 5)]
        
     endfor
     ;;
     fwhm_1mm     = fwhm_1mm[1:*]
     fwhm_a2      = fwhm_a2[1:*]
     fwhm_a1      = fwhm_a1[1:*]
     fwhm_a3      = fwhm_a3[1:*]
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
     elev         = elev[1:*]
     obj          = obj[1:*]
     day          = day[1:*]
     runid        = runid[1:*]
     ut           = ut[1:*]
     scan_list    = scan_list[1:*]
     
     ;; calculate ut_float 
     nscans      = n_elements(elev)
     ut_float    = fltarr(nscans)
     for i=0, nscans-1 do begin
        ut_float[i] = float((STRSPLIT(ut[i], ':', /EXTRACT))[0])+float((STRSPLIT(ut[i], ':', /EXTRACT))[1])/60.
     endfor

     
     
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

     calib_run = runname_tab
     
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
     outfile = plotdir+plotname+'_1mm'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     plot, ut_float, fwhm_1mm, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
     for irun=0, nrun-1 do begin
        w = where(runid[wp] eq calib_run[irun], nn)
        if nn gt 0 then oplot, ut_float[wp[w]], fwhm_1mm[wp[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[irun], symsize=symsize*0.8
        w = where(runid[ws] eq calib_run[irun], nn)
        if nn gt 0 then oplot, ut_float[ws[w]], fwhm_1mm[ws[w]], psym=cgsymcat('FILLEDSTAR', thick=thick), col=col_tab[irun]
     endfor
     ;;oplot, [0, 24], [11.2, 11.2], col=0, thick=thick/2.
     oplot, [0, 24], [11.3, 11.3], col=0
     
     ;;polyfill, [9, 10, 10, 9], [ymin, ymin, ymax, ymax], col=0, thick=thick/2, line_fill=1, orientation=45, spacing=0.3
     ;;oplot, [9, 9],   [ymin, ymax], col=0, thick=thick/2.
     ;;oplot, [10, 10], [ymin, ymax], col=0, thick=thick/2.
     ;;polyfill, [15, 22, 22, 15], [ymin, ymin, ymax, ymax], col=0, thick=thick/2,line_fill=1, orientation=45, spacing=0.3 
     ;;oplot, [15, 15], [ymin, ymax], col=0, thick=thick/2.
     ;;oplot, [22, 22], [ymin, ymax], col=0, thick=thick/2.
     
     xyouts, 19., 16., 'A1&A3', col=0
     
     legendastro, calib_run, col=col_tab, textcol=col_tab, box=0, charsize=charsize, pos=[1, 16.]
     
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
     outfile = plotdir+plotname+'_a2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     plot, ut_float, fwhm_a2, psym=8, yrange=[ymin, ymax], /ys, /xs, ytitle = 'FWHM [arcsec]', xtitle='UT hours', /nodata
     for irun=0, nrun-1 do begin
        w = where(runid[wp] eq calib_run[irun], nn)
        if nn gt 0 then oplot, ut_float[wp[w]], fwhm_a2[wp[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick), col=col_tab[irun], symsize=symsize*0.8
        w = where(runid[ws] eq calib_run[irun], nn)
        if nn gt 0 then oplot, ut_float[ws[w]], fwhm_a2[ws[w]], psym=cgsymcat('FILLEDSTAR', thick=thick), col=col_tab[irun]
     endfor
     ;;oplot, [0, 24], [17.4, 17.4], col=0, thick=thick/2.
     oplot, [0, 24], [17.5, 17.5], col=0, thick=thick
     xyouts, 21, 19.5, 'A2', col=0
     
     ;;polyfill, [9, 10, 10, 9], [ymin, ymin, ymax, ymax], col=0, thick=thick/2, line_fill=1, orientation=45, spacing=0.3
     ;;oplot, [9, 9],   [ymin, ymax], col=0, thick=thick/2.
     ;;oplot, [10, 10], [ymin, ymax], col=0, thick=thick/2.
     ;;polyfill, [15, 22, 22, 15], [ymin, ymin, ymax, ymax], col=0, thick=thick/2,line_fill=1, orientation=45, spacing=0.3 
     ;;oplot, [15, 15], [ymin, ymax], col=0, thick=thick/2.
     ;;oplot, [22, 22], [ymin, ymax], col=0, thick=thick/2.
     legendastro, ['Planets'], psym=[cgsymcat('FILLEDCIRCLE', thick=thick)], col=[0], textcol=0, box=0, charsize=charsize, pos=[2, 19.5], symsize=symsize*0.8
     legendastro, ['Others'], psym=[cgsymcat('FILLEDSTAR', thick=thick)], col=[0], textcol=0, box=0, charsize=charsize, pos=[2, 19.2]
     
     outplot, /close
     
     
     if keyword_set(pdf) then begin
        ;;spawn, 'epspdf --bbox '+plotdir+plotname+'_1mm.eps'
        ;;spawn, 'epspdf --bbox '+plotdir+plotname+'_a2.eps'
        spawn, 'epstopdf '+plotdir+plotname+'_1mm.eps'
        spawn, 'epstopdf '+plotdir+plotname+'_a2.eps'
     endif
     
     
     stop

     ;; all
     print, ''
     print, 'all sources'
     wsel = where(ut_float le 9 or $
                  ut_float ge 22. or $
                  (ut_float ge 10. and ut_float le 15.), nn, compl=wout)
     wsel = where(ut_float le 9 or $
                  ut_float ge 22., nn, compl=wout)
     print,"avg FWHM 2mm sel = ", mean(fwhm_a2(wsel)), median(fwhm_a2(wsel))
     print,"avg FWHM 1mm sel = ", mean(fwhm_1mm(wsel)), median(fwhm_1mm(wsel))
     print,"avg FWHM 2mm out = ", mean(fwhm_a2(wout)), median(fwhm_a2(wout))
     print,"avg FWHM 1mm out = ", mean(fwhm_1mm(wout)), median(fwhm_1mm(wout))

     ;; point-like
     print, ''
     print, 'point-like sources'
     wsel = where(ut_float(ws) le 9 or $
                  ut_float(ws) ge 22. or $
                  (ut_float(ws) ge 10. and ut_float(ws) le 15.), nn, compl=wout)
     wsel = where(ut_float(ws) le 9 or $
                  ut_float(ws) ge 22., nn, compl=wout)
     print,"avg FWHM 2mm sel = ", mean(fwhm_a2[ws[wsel]]), median(fwhm_a2[ws[wsel]])
     print,"avg FWHM 1mm sel = ", mean(fwhm_1mm[ws[wsel]]), median(fwhm_1mm[ws[wsel]])
     print,"avg FWHM 2mm out = ", mean(fwhm_a2[ws[wout]]), median(fwhm_a2[ws[wout]])
     print,"avg FWHM 1mm out = ", mean(fwhm_1mm[ws[wout]]), median(fwhm_1mm[ws[wout]])

     ;; planets
     print, ''
     print, 'Planets'
     wsel = where(ut_float(wp) le 9 or $
                  ut_float(wp) ge 22. or $
                  (ut_float(wp) ge 10. and ut_float(wp) le 15.), nn, compl=wout)
     print,"avg FWHM 2mm sel = ", mean(fwhm_a2[wp[wsel]]), median(fwhm_a2[wp[wsel]])
     print,"avg FWHM 1mm sel = ", mean(fwhm_1mm[wp[wsel]]), median(fwhm_1mm[wp[wsel]])
     print,"avg FWHM 2mm out = ", mean(fwhm_a2[wp[wout]]), median(fwhm_a2[wp[wout]])
     print,"avg FWHM 1mm out = ", mean(fwhm_1mm[wp[wout]]), median(fwhm_1mm[wp[wout]])
     

     stop
  endif
  
  
end
