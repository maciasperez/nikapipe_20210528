
;; LP, Aout 2018


pro test_skydip_selection_impact, png=png, ps=ps, pdf=pdf
  
  ;; run name
  runname = 'N2R9'
   
;; directory of the output kidpar
;; (and skydip result files if processing is needed)
;; default is !nika.plot_dir
  output_dir = getenv('HOME')+'/NIKA/Plots/'+runname+'/Photometry/'


  ;; test selection list
  dir_suffixe_list = ['inclusive_skydip_opacorr4_NoTauCorrect0',$
                      'low_skydip_opacorr4_NoTauCorrect0', $
                      'night_skydip_opacorr4_NoTauCorrect0', $
                      'qualfit_skydip_opacorr4_NoTauCorrect0', $
                      'N2R9_ref_atmlike', $
                      'N2R9_ref_baseline', $
                      'N2R9_ref_hightau2_bis_v2', $
                      'N2R9_ref_hightau2_v3', $
                      'N2R9_ref_baseline_tau3_le_0point3', $
                      'N2R9_ref_baseline_tau3_le_0point25']

  names = ['incl', 'low', 'night', 'qual', 'atm', 'base', 'high1', 'high2', 'tau3inf0.3', 'tau3inf0.25']

  ntests = n_elements(dir_suffixe_list)

  ;; plot parameters
  ;;--------------------------------------------------------
  
  ;; window size
  wxsize = 550.
  wysize = 400.
  ;; plot size in files
  pxsize = 11.
  pysize =  8.
  ;; charsize
  charsize  = 1.3
  charthick = 3.0 ;0.7
  thick     = 3.0
  symsize   = 0.7

  outplot_dir = '/home/perotto/NIKA/Plots/Performance_plots/Opacity/'
  plotname = 'Skydip_selection_impact'
  

  
  ;; scan list
  ;;restore, output_dir+'Goodscans_MWC349_'+runname+'_all.save'
  restore, output_dir+'Goodscans_MWC349_'+strlowcase(runname)+'.save' ;; nika2c
  nscans = n_elements(scan_list)

  ;; gathering results
  ;;__________________________________________________________

  allresult_file = output_dir+'test_skydip_selection_impact_v1.save'
  ntests = 8
  ;allresult_file = output_dir+'test_skydip_selection_impact_v2.save'
  ;allresult_file = output_dir+'test_skydip_selection_impact_v3.save'
  
  if file_test(allresult_file) lt 1 then begin
     
     flux = dblarr(nscans, 4, ntests)
     tau  = dblarr(nscans, 4, ntests)
     elev = dblarr(nscans, ntests)
     fwhm = dblarr(nscans, 4, ntests)
     
     for itest = 0, ntests-1 do begin
        
        testdir = output_dir+'MWC349_photometry_'+dir_suffixe_list[itest]
        
        
        ;;
        spawn, 'ls '+testdir+'/v_1/*/results.save', res_files
        
        nscan_test = 0
        if res_files[0] gt '' then nscan_test = n_elements(res_files)
        if nscan_test gt 0 then begin
           restore, res_files[0], /v
           allscan_info = replicate(info1, nscan_test)
           
           for i=0, nscan_test-1 do begin
              restore, res_files[i]
              allscan_info[i] = info1
           endfor
           
           scan_list_test = strtrim(string(allscan_info.day, format='(i8)'), 2)+'s'+$
                            strtrim(string(allscan_info.scan_num, format='(i8)'), 2)
           
           my_match, scan_list, scan_list_test, suba, subb
           
           flux[suba,0,itest] = allscan_info[subb].result_flux_i1
           flux[suba,1,itest] = allscan_info[subb].result_flux_i2
           flux[suba,2,itest] = allscan_info[subb].result_flux_i3
           flux[suba,3,itest] = allscan_info[subb].result_flux_i_1mm
           tau[suba,0,itest]  = allscan_info[subb].result_tau_1
           tau[suba,1,itest]  = allscan_info[subb].result_tau_2
           tau[suba,2,itest]  = allscan_info[subb].result_tau_3
           tau[suba,3,itest]  = allscan_info[subb].result_tau_1mm
           fwhm[suba,0,itest] = allscan_info[subb].result_fwhm_1
           fwhm[suba,1,itest] = allscan_info[subb].result_fwhm_2
           fwhm[suba,2,itest] = allscan_info[subb].result_fwhm_3
           fwhm[suba,3,itest] = allscan_info[subb].result_fwhm_1mm
           elev[suba,itest]   = allscan_info[subb].RESULT_ELEVATION_DEG
           
        endif
        
     endfor

     save, flux, tau, fwhm, elev, filename=allresult_file
  endif

  restore, allresult_file, /v
  nscans = n_elements(elev[*,0])

     
  sou = 'MWC349'
  lambda = [!nika.lambda[0], !nika.lambda[1],!nika.lambda[0]]
  nu = !const.c/(lambda*1e-3)/1.0d9
  th_flux           = 1.16d0*(nu/100.0)^0.60
  ;; assuming indep param
  err_th_flux       = sqrt( ((nu/100.0)^0.6*0.01)^2 + (1.16*0.6*(nu/100.0)^(-0.4)*0.01)^2)




  ;;; PLOT 
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14
  
  tabcol = [10, 35, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25, 50, 60, 75, 95, 115, 118, 125, 160, 170, 245, 235, 25]
  tabcol = [tabcol(indgen(9)*2.),  col_ngc7027]
  
  ;;names = ['incl', 'low', 'night', 'qual', 'atm', 'base', 'high1', 'high2', 'tau3inf0.3', 'tau3inf0.25']
  names = ['incl0', 'low', 'night', 'qual', 'incl', 'base', 'high1', 'high2', 'tau3inf0.3', 'tau3inf0.25']
  tabcol = [40, 240, 30, 200, 160, 95, 115, 60, 80, 119 ]
  
  ;;select = indgen(ntests)
  select = [1, 7, 6, 2, 4, 5]
  ;select = [5, 8, 9]
  ;;select = [5]
  ;;select = ''
  nselect = n_elements(select)
  
  quoi = ['A1', 'A2', 'A3', 'A1&A3']
  suf  = ['_a1', '_a2', '_a3', '_1mm']
  
  ;; plot of tau
  ;;_________________________________________________________________________________________
  
  wind, 1, 1, /free, xsize=900, ysize=650
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  index = indgen(nscans)
  
  for iq = 0, 3 do begin
     noerase = 0
     if iq gt 0 then noerase = 1
     
     plot, index, tau[*, iq, 0], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
           yr = [0, 0.7], xtitle='scan index', ytitle='skydip-based tau' 

     for it = 0, nselect-1 do begin
        oplot, index+0.05*it, tau[*, iq, select[it]], col= tabcol[select[it]], psym=cgsymcat('FILLEDCIRCLE', thick=0.7)
     endfor
     legendastro, quoi[iq], textcol=0, box=0, charsize=1, pos = [5, 0.6]
     if iq eq 1 then legendastro, [names[select]], textcol=tabcol[select], col=tabcol[select], sym=[replicate(8, nselect)], box=0, pos = [35, 0.6]
  endfor


  ;;-------------------------------------------------------------------------------------

  wind, 1, 1, /free, xsize=900, ysize=650
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.1, gap_x=0.1, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  ;outfile = outplot_dir+plotname
  ;outplot, file=outfile, png=png
  
  index = indgen(nscans)
  
  for iq = 0, 3 do begin
     noerase = 0
     if iq gt 0 then noerase = 1
     
     plot, tau[*, iq, 5], tau[*, iq, 0], pos=pp1[iq, *], noerase = noerase, /nodata, /xs, /ys, $
           yr = [-0.7, 0.7], xtitle='baseline tau', ytitle='rel. diff. to baseline tau' 
     
     for it = 0, nselect-1 do begin
        ;;oplot, index+0.05*it, (tau[*, iq, select[it]]-tau[*, iq,
        ;;5])/tau[*, iq, 5], col= tabcol[select[it]], psym=8,
        ;;symsize=0.5
        oplot, tau[*, iq, 5], (tau[*, iq, select[it]]-tau[*, iq, 5])/tau[*, iq, 5], col= tabcol[select[it]], psym=8, symsize=0.5
     endfor
     legendastro, quoi[iq], textcol=0, box=0, charsize=1, pos = [0.1, 0.55]
     
     if iq eq 1 then legendastro, [names[select[0:2]]], textcol=tabcol[select[0:2]], col=tabcol[select[0:2]], sym=[replicate(8, 3)], box=0, pos = [0.15, 0.55]
     if iq eq 1 then legendastro, [names[select[3:*]]], textcol=tabcol[select[3:*]], col=tabcol[select[3:*]], sym=[replicate(8, nselect-3)], box=0, pos = [0.22, 0.55]
     
     oplot, [0, 1], [0.1, 0.1], col=0, linestyle=2
     oplot, [0, 1], [-0.1, -0.1], col=0, linestyle=2
     oplot, [0, 1], [0, 0], col=0, thick=1
  endfor
  
  ;outplot, /close
  
  
  if keyword_set(ps) then begin
     
     for iq = 0, 3 do begin
        
        outfile = outplot_dir+plotname+suf[iq]
        outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
        
        plot, tau[*, iq, 5], tau[*, iq, 0], /nodata, /xs, /ys, $
              yr = [-0.7, 0.7], xtitle='!4s!X!dbase', ytitle='rel. diff. to !4s!X!dbase!n' 
        
        for it = 0, nselect-1 do begin
           oplot, tau[*, iq, 5], (tau[*, iq, select[it]]-tau[*, iq, 5])/tau[*, iq, 5], col= tabcol[select[it]], psym=8, symsize=0.5
        endfor
        legendastro, quoi[iq], textcol=0, box=0, pos = [0.1, 0.55]
        
        if iq eq 1 then legendastro, [names[select[0:2]]], textcol=tabcol[select[0:2]], col=tabcol[select[0:2]], sym=[replicate(8, 3)], box=0, pos = [0.15, 0.55]
        if iq eq 1 then legendastro, [names[select[3:*]]], textcol=tabcol[select[3:*]], col=tabcol[select[3:*]], sym=[replicate(8, nselect-3)], box=0, pos = [0.22, 0.55]
     
        oplot, [0, 1], [0.1, 0.1], col=0, linestyle=2
        oplot, [0, 1], [-0.1, -0.1], col=0, linestyle=2
        oplot, [0, 1], [0, 0], col=0, thick=1

        outplot, /close
        
        if keyword_set(pdf) then spawn, 'epspdf --bbox '+outplot_dir+plotname+suf[iq]+'.eps'
           
     endfor
     
  endif
  
  stop

  ;; plot of the flux density
  ;;__________________________________________________________________________________________
  
  ;; empiric = 1 to show the 1.2xtau test
  empiric = 1
  
  wind, 1, 1, /free, xsize=1150, ysize=670
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
  outfile = output_dir+'MWC349_'+runname+'_rescaled_flux_densities_vs_atmospheric_trans_base'
  outplot, file=outfile, png=png, ps=ps, xsize=18, ysize=12, charsize=0.7, thick=2, charthick=1.2

  diff_tab = strarr(nselect)
  
  for ilam = 0, 3 do begin
     print, ''
     print, quoi[ilam]
     print, '----------'

     diff_tab = strarr(nselect)
     noerase = 1
     if ilam eq 0 then noerase=0

     ;;th_f = [th_flux, th_flux[0]]
     th_f = [1., 1., 1., 1.]
     
     xrange = [0.4, 1.]   
     plot, xrange, th_f[ilam]*[0.6, 1.4], $
           yr=th_f[0]*[0.6, 1.4], $
           xr=xrange, $
           xtitle='Atmospheric transmission', ytitle='Flux density (Jy/beam)', /ys, /nodata, $
           pos=pp1[ilam, *], noerase=noerase
     if string(select[0]) ne '' then begin
        for ii=0, nselect-1 do begin
           itest = select[ii]
           atmtrans = exp(-tau[*,ilam,itest]/sin(elev[*, itest]*!dtor))
           f = flux[*, ilam, itest]
           oplot, atmtrans, f/median(f), psym=8, col=tabcol[itest], symsize=0.7

           ;;
           w = where(f gt 1d-5)
           wlow = where(atmtrans[w] lt median(atmtrans), nhalf, compl=whi)
           diff = abs(mean(f[w(whi)])-mean(f[w(wlow)]))/sqrt(stddev(f[w(whi)])^2 + stddev(f[w(wlow)])^2)*sqrt(nhalf)
           ;;diff = [median(f(whi))-median(f(wlow))]/median(f)*100.
           rms  = stddev(f[w])/median(f[w])*100.
           print, names[itest], ': ', diff
           

           diff_tab[ii] = 'D='+strtrim(string(diff, format='(f8.1)'), 2)+', rms='+strtrim(string(rms, format='(f8.1)'), 2)
           
           ;;legendastro, names[itest], textcol=tabcol[itest], col=tabcol[itest], box=0, pos=[0.42,(1.33-ii*0.05)]
           ;;rep=''
           ;;read, rep
        endfor
     endif

     if empiric gt 0 then begin
        atmtrans = exp(-tau[*,ilam,5]*1.2/sin(elev[*, 5]*!dtor))
        f = flux[*, ilam, 5]*exp(0.2*tau[*,ilam,5]/sin(elev[*, 5]*!dtor))
        oplot, atmtrans, f/median(f), psym=4, col=0

        wlow = where(atmtrans lt median(atmtrans), nhalf, compl=whi)
        diff = abs(mean(f(whi))-mean(f(wlow)))/sqrt(stddev(f(whi))^2 + stddev(f(wlow))^2)*sqrt(nhalf)
        ;;diff = [median(f(whi))-median(f(wlow))]/median(f)*100.
        rms  = stddev(f)/median(f)*100.
        print, 'base*1.2 : ', diff

        diff_tab = [diff_tab, 'D='+strtrim(string(diff, format='(f8.1)'), 2)+', rms='+strtrim(string(rms, format='(f8.1)'), 2)]
        
        legendastro, [names[select], 'base*1.2'], textcol=[tabcol[select], 0], col=[tabcol[select], 0], sym=[replicate(8, nselect), 4], box=0
        legendastro, diff_tab, textcol=[tabcol[select], 0], col=[tabcol[select], 0], box=0, /bottom, /right
     endif else begin
        
        legendastro, names[select], textcol=tabcol[select], col=tabcol[select], box=0
        legendastro, diff_tab, textcol=tabcol[select], col=tabcol[select], box=0, /bottom, /right
     endelse
     
     xyouts, 0.9, 1.3, quoi[ilam], col=0 
     
     oplot, xrange, [1, 1], col=0
     ;stop
     
  endfor

  outplot, /close
  
  stop
  wd, /a

   ;;; PLOT 2
  
  wind, 1, 1, /free, xsize=1150, ysize=670
  my_multiplot, 2, 2, pp, pp1, /rev, gap_y=0.07, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
  outfile = output_dir+'MWC349_'+runname+'_tau_3select'
  outplot, file=outfile, png=png, ps=ps, xsize=18, ysize=12, charsize=0.7, thick=2, charthick=1.2

  for ilam = 0, 3 do begin

     noerase = 1
     if ilam eq 0 then noerase=0

     ycoef = [1., 1., 1., 1.]
     xrange = [0, nscans]   
     plot, xrange, [0., 0.55]*ycoef[ilam], $
           yr=[0.0, 0.55]*ycoef[ilam], $
           xr=xrange, /xs, $
           xtitle='scan index', ytitle='zenith opacity from skydips', /ys, /nodata, $
           pos=pp1[ilam, *], noerase=noerase
     for ii=0, nselect-1 do begin
        itest = select[ii]
        ;;atmtrans = exp(-tau[*,ilam,itest]/sin(elev[*, itest]*!dtor))
        oplot, tau[*,ilam,itest], psym=8, col=tabcol[itest], symsize=0.7
        ;legendastro, names[itest], textcol=tabcol[itest], col=tabcol[itest], box=0, pos=[0.42,(1.33-ii*0.05)]
        ;rep=''
        ;read, rep
     endfor
     oplot,tau[*,ilam,5]*1.2, col=tabcol[5], psym=4
     
     legendastro, [names[select], 'base*1.2'], textcol=[tabcol[select],tabcol[5]], col=[tabcol[select],tabcol[5]], box=0, /right
     xyouts, 5, 0.07, quoi[ilam], col=0 

  endfor
  
  outplot, /close
  stop

end
