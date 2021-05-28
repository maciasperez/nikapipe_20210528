;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;
;  Script NIKA2 performance 
;
;
;   NIKA2 FWHM estimates using OTF scans (5x8arcmin^2)
;
;-----------------------------------------------------------------------------

pro plot_main_beam_fwhm, ps=ps, pdf=pdf

  calib_run   = ['N2R9', 'N2R12', 'N2R14']
  nrun  = n_elements(calib_run)
  
  
  ;; plot aspect
  ;;----------------------------------------------------------------
  ;; window size
  wxsize = 550.
  wysize = 400.
  ;; plot size in files
  pxsize = 11.
  pysize =  8.
  ;; charsize
  charsize  = 1.2
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 1.0
  symsize   = 0.7
  


  
  tag_list = ['FWHM_1', 'FWHM_3', 'FWHM_2', 'FWHM_1mm', $
              'FWHM_X_1','FWHM_X_3','FWHM_X_2','FWHM_X_1mm', $
              'FWHM_Y_1', 'FWHM_Y_3', 'FWHM_Y_2', 'FWHM_Y_1mm', $
              'PEAK_1', 'PEAK_3', 'PEAK_2', 'PEAK_1mm', $
              'TAU_1MM', 'TAU_2MM', 'CHI2_1', 'CHI2_3', 'CHI2_2', 'CHI2_1MM', $
              'FLUX_I1', 'FLUX_I3', 'FLUX_I2', 'FLUX_I_1MM', $
              'ALPHA_1', 'ALPHA_3', 'ALPHA_2', 'ALPHA_1MM', $
              'RADIUS_1', 'RADIUS_3', 'RADIUS_2', 'RADIUS_1MM', 'ELEVATION_DEG']
  
  
;; tag_list = ['FWHM_1', 'FWHM_3', 'FWHM_2', 'FWHM_1mm', $
;;             'FWHM_X_1','FWHM_X_3','FWHM_X_2','FWHM_X_1mm', $
;;             'FWHM_Y_1', 'FWHM_Y_3', 'FWHM_Y_2', 'FWHM_Y_1mm', $
;;             'PEAK_1', 'PEAK_3', 'PEAK_2', 'PEAK_1mm', $
;;             'TAU_1MM', 'TAU_2MM', 'CHI2_1', 'CHI2_3', 'CHI2_2', 'CHI2_1MM', $
;;             'FLUX_I1', 'FLUX_I3', 'FLUX_I2', 'FLUX_I_1MM']

  
  dir     = getenv('HOME')+'/NIKA/Plots/Beams/'
  file_suffixe          = '_mb'
  file_suffixe          = '_mb_radius_binning2'
  get_main_beam_results, tag_list, out, file_suffixe=file_suffixe, output_scans=output_scans, version=1

  scan_list = output_scans[0, *]
  sources   = output_scans[1, *]
  runid     = output_scans[2, *]
  
  nscans    = n_elements(scan_list)
  
  stop
  



;;  
;;     PLOTS
;;____________________________________________________________


  ;; correct for Uranus finite extension
  delta_fwhm = [0.19, 0.19, 0.12, 0.19]
  wu = where(sources eq 'Uranus', nu)
  if nu gt 0 then begin
     for ia =0, 3 do out[ia, wu] = out[ia, wu]-delta_fwhm[ia]
  endif

  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14
  
  col_tab = [col_n2r9, col_n2r12, col_n2r14]

  
  w_total = indgen(nscans)
  
  ;; coupure sur alpha
  avg_alp1 = mean(out[26+3, *])
  rms_alp1 = stddev(out[26+3, *])
  avg_alp2 = mean(out[26+2, *])
  rms_alp2 = stddev(out[26+2, *])
  wout=where(out[26+3, *] gt avg_alp1+2.5*rms_alp1 or out[26+3, *] lt avg_alp1-2.5*rms_alp1 or $
             out[26+2, *] gt avg_alp2+2.5*rms_alp2 or out[26+2, *] lt avg_alp2-2.5*rms_alp2, compl = wsource)
  
  ;;wsource = w_total

  stop
  
  ntot_tab    = lonarr(nrun+1)
  nselect_tab = lonarr(nrun+1)
  fwhm_tab    = dblarr(4, nrun+1)
  rms_tab     = dblarr(4, nrun+1)

  
  ;; 1mm
  ;;----------------------------------------------------------

  atmtrans = exp(-out[16, *]/sin(out[34, *]*!dtor))
  
  print, ''
  print, ' 1mm '
  print, '-----------------------'
  ymax = 13.0
  ymin = 10.0
  xmax  = 0.95
  xmin  = 0.45     
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+'plot_FWHM_vs_atmtrans'+file_suffixe+'_1mm'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  
  plot, atmtrans, out[3, *], /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='Atmospheric transmission', ytitle='Main Beam FWHM [arcsec]', /ys, /nodata
  
  for irun=0, nrun-1 do begin
     print, ''
     print, calib_run[irun]
     w = where(runid eq calib_run[irun], ntot)
     ntot_tab[irun] = ntot
     w = where(runid[wsource] eq calib_run[irun], nn)
     if nn gt 0 then oplot, atmtrans[wsource[w]], out[3,wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun], symsize=symsize
     nselect_tab[irun] = nn
     fwhm_tab[3, irun] = mean(out[3,wsource[w]])
     rms_tab[3, irun]  = stddev(out[3,wsource[w]])/mean(out[3,wsource[w]])*100
     print, 'nscan = ', nn
     print, 'FWHM = ', fwhm_tab[3, irun]
     print, 'rel.rms = ', rms_tab[3, irun]
  endfor
  ;;
  legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.], textcol=0, box=0, pos=[0.05, ymin+0.07]
  ;;
  oplot, [xmin,xmax], mean(out[3,wsource])*[1., 1.], col=0
  oplot, [xmin,xmax], mean(out[3,wsource])*[1., 1.]+stddev(out[3,wsource]), col=0, linestyle=2
  oplot, [xmin,xmax], mean(out[3,wsource])*[1., 1.]-stddev(out[3,wsource]), col=0, linestyle=2
  xyouts, xmax-(xmax-xmin)*0.25, ymax-(ymax-ymin)*0.13, 'A1&A3', col=0 
  
  outplot, /close
  
  ;; 2mm
  ;;----------------------------------------------------------

  atmtrans = exp(-out[17, *]/sin(out[34, *]*!dtor))
  
  print, ''
  print, ' 2mm '
  print, '-----------------------'
  ymax = 19.0
  ymin = 17.0
  xmax  = 0.95
  xmin  = 0.55     
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
  outfile = dir+'plot_FWHM_vs_atmtrans'+file_suffixe+'_a2'
  outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
  
  plot, atmtrans, out[2, *], /xs, yr=[ymin, ymax], $
        xr=[xmin,xmax], $
        xtitle='Atmospheric transmission', ytitle='Main Beam FWHM [arcsec]', /ys, /nodata
  
  for irun=0, nrun-1 do begin
     print, ''
     print, calib_run[irun]
     w = where(runid eq calib_run[irun], ntot)
     ntot_tab[irun] = ntot
     w = where(runid[wsource] eq calib_run[irun], nn)
     if nn gt 0 then oplot, atmtrans[wsource[w]], out[2,wsource[w]], psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25), col=col_tab[irun], symsize=symsize
     nselect_tab[irun] = nn
     fwhm_tab[2, irun] = mean(out[2,wsource[w]])
     rms_tab[2, irun]  = stddev(out[2,wsource[w]])/mean(out[2,wsource[w]])*100
     print, 'nscan = ', nn
     print, 'FWHM = ', fwhm_tab[2, irun]
     print, 'rel.rms = ', rms_tab[2, irun]
  endfor
  ;;
  legendastro, calib_run, col=col_tab, psym=cgsymcat('FILLEDCIRCLE', thick=thick*0.25)*[1., 1., 1.], textcol=0, box=0, pos=[xmin+(xmax-xmin)*0.1, ymax-(ymax-ymin)*0.13]
  ;;
  oplot, [xmin,xmax], mean(out[2,wsource])*[1., 1.], col=0
  oplot, [xmin,xmax], mean(out[2,wsource])*[1., 1.]+stddev(out[2,wsource]), col=0, linestyle=2
  oplot, [xmin,xmax], mean(out[2,wsource])*[1., 1.]-stddev(out[2,wsource]), col=0, linestyle=2
  xyouts, xmax-(xmax-xmin)*0.15, ymax-(ymax-ymin)*0.13, 'A2', col=0 
  
  outplot, /close
     
  
  nselect_tab[3]= n_elements(wsource)
  fwhm_tab[0,3] = mean(out[0, wsource])
  fwhm_tab[2,3] = mean(out[1, wsource])
  fwhm_tab[3,3] = mean(out[3, wsource])
  fwhm_tab[1,3] = mean(out[2, wsource])
     
  rms_tab[0, 3] = stddev(out[0, wsource])
  rms_tab[2, 3] = stddev(out[1, wsource])
  rms_tab[3, 3] = stddev(out[3, wsource])
  rms_tab[1, 3] = stddev(out[2, wsource])
          
  print, ''
  print, 'Combined'
  print, 'total nscan = ',    ntot_tab[3]
  print, 'selected nscan = ', nselect_tab[3]
     
  print, 'A1 FWHM  = ', fwhm_tab[0,3],' pm ',rms_tab[0, 3] 
  print, 'A3 FWHM  = ', fwhm_tab[2,3],' pm ',rms_tab[2, 3]
  print, '1mm FWHM = ', fwhm_tab[3,3],' pm ',rms_tab[3, 3]
  print, 'A2 FWHM  = ', fwhm_tab[1,3],' pm ',rms_tab[1, 3]
     
  
  if keyword_set(pdf) then begin
     suf = ['_a2', '_1mm']
     for i=0, 1 do begin
        spawn, 'epstopdf '+dir+'plot_FWHM_vs_atmtrans'+file_suffixe+suf[i]+'.eps'
     endfor       
  endif


  
  ;; HISTOGRAMMES
  
  suf  = ['_a1', '_a3', '_a2', '_1mm']
  quoi = ['A1', 'A3', 'A2',  'A1&A3']
  
  limits = [[9.5, 13.0], [9.5, 13.0], [16.5, 19.0], [9.5, 13.0]] 
  
  for ia = 0, 3 do begin
        
     print, ''
     print, ' Histo ', quoi[ia]
     print, '-----------------------'
     ymax = max( [limits[1, ia], max(out[ia, wsource]) ])
     ymin = min( [limits[0, ia], min(out[ia, wsource]) ])
     bin  = 0
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize 
     outfile = dir+'plot_histo_FWHM'+file_suffixe+suf[ia]
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     
     f = reform(out[ia, wsource])

     np_histo, [f], out_xhist, out_yhist, out_gpar, min=ymin, max=ymax, binsize=bin, xrange=[ymin, ymax], fcol=25, fit=1, noerase=0, position=0, nolegend=1, colorfit=165, thickfit=3., nterms_fit=3, xtitle="Main beam FWHM [arcsec] "
     
     leg_txt = ['N: '+strtrim(string(n_elements(f), format='(i8)'),2), $
                'Avg: '+strtrim(string(out_gpar[0,1], format='(f8.1)'),2), $
                '!7r!3: '+strtrim(string(out_gpar[0,2], format='(f8.1)'),2)]
     
     legendastro, leg_txt, textcol=0, box=0, pos=[ymax-(ymax-ymin)*0.35, max(out_yhist)]
     legendastro, quoi[ia], textcol=0, box=0, pos=[ymin+(ymax-ymin)*0.07, max(out_yhist)]
     
     outplot, /close
     
     
     if keyword_set(pdf) then $
        spawn, 'epstopdf '+dir+'plot_histo_FWHM'+file_suffixe+suf[ia]+'.eps'
     
  endfor       
  
  stop
  



  



;; plot
;;______________________________________________________________
wind, 1, 1, xsize = 1000, ysize =  650, /free, title="FWHM"
my_multiplot, 2, 2, pp, pp1, /rev, ymargin=0.08, gap_x=0.08, gap_y=0.08, xmargin = 0.08

charsize=1
png = 1
ps  = 0

if ps gt 0 then begin
   ps_xsize    = 20       ;; in cm
   ps_ysize    = 18       ;; in cm
   ps_charsize = 1.
   ps_yoffset  = 0.
   ps_thick    = 4.
   ps_charthick = 3.
endif

if png gt 0 then begin
   ps_xsize    = 0       ;; in cm
   ps_ysize    = 0       ;; in cm
   ps_charsize = 0
   ps_charthick = 0
   ps_yoffset  = 0
   ps_thick    = 1.
   !p.thick=1
endif

;outplot, file='plot_histo_fwhm_run9_calibII_CRL2688', png=png
;outplot, file='plot_histo_fwhm_run9_calibII', png=png
;outplot, file='plot_histo_fwhm_run9_calibII_azel', png=png
;outplot, file='plot_histo_fwhm_run9_calibII_5Jysources_nocut', png=png
;outplot, file='plot_histo_fwhm_run9_calibII_5Jysources_no_uranus_nocut', png=png
outplot, file='plot_histo_fwhm_run9_calibII_all_nocut', png=png
;outplot, file='plot_histo_sidelobes_mask_inner_radius_run9_calibII_all_nocut', png=png
;outplot, file='plot_histo_fwhm_fixmask_7_13_run9_calibII_all', png=png
;outplot, file='plot_histo_fwhm_fixmask_3_9_run9_calibII_all', png=png

outplot, file='Main_Beam_FWHM_N2R9_10', png=png, $
         ps=ps, xsize=ps_xsize, ysize=ps_ysize, charsize=ps_charsize, charthick=ps_charthick, thick=ps_thick

;; coupure sur le Chi2
;chi2mini  = [0.2, 0.2, 0.15, 0.2]
;chi2maxi  = [3., 3., 2., 3.]

chi2mini  = [0.05, 0.05, 0.02, 0.05]
chi2maxi  = [50., 50., 30., 50.]

;chi2mini  = [0.5, 0.5, 0.2, 0.5]
;chi2maxi  = [5., 5., 3., 5.]

;; coupure sur la fraction de lobe retenu
alpmini  = [0.23, 0.23, 0.09, 0.23]
alpmaxi  = [0.5, 0.5, 0.5, 0.5]

alpmini  = [0.2, 0.2, 0.1, 0.2]
alpmaxi  = [0.45, 0.45, 0.45, 0.45]

;alpmini  = [0.35, 0.35, 0.1, 0.35]
;alpmaxi  = [0.45, 0.45, 0.2, 0.45]

alpmini  = [0.1, 0.1, 0.1, 0.1]
alpmaxi  = [0.9, 0.9, 0.9, 0.9]

nscan_tot = n_elements(scan_list)

;; FWHM range 
mini = [9.5, 9.5, 16.5, 9.5]
maxi = [12.5, 12.5, 19., 12.5]
;; hist binsize
binsi = [0.15, 0.15, 0.15, 0.15]

array = ['1', '3', '2', '1&3']
;; tag in [FWHM_1, FWHM_3, FWHM_2, FWHM_1mm]
for itag=0, 3 do begin
   ;; coupures
   ;; tau@1mm
   wtau = where(out[16,*] le 0.8, ns)
   print,"Coupure tau: pour ", tag_list[itag], ", nscans = ", ns, " of ", nscan_tot
   ;; tau@1mm + chi2
   wall = where(finite(out[itag,*]) gt 0 and out[16,*] le 0.8 and out[18+itag, *] ge chi2mini[itag] and out[18+itag, *] le chi2maxi[itag], ns)
   print,"Coupure chi2: pour ", tag_list[itag], ", nscans = ", ns
   wall = where(finite(out[itag,*]) gt 0 and out[16,*] le 0.8 and $
                out[18+itag, *] ge chi2mini[itag] and out[18+itag, *] le chi2maxi[itag] and $
                out[26+itag, *] ge 0.12, ns)
   print,"Coupure alpha: pour ", tag_list[itag], ", nscans = ", ns
   ;; wall = where(out[16,*] le 0.4 and out[18+itag, *] ge chi2mini[itag] and out[18+itag, *] le chi2maxi[itag] and $
   ;;              out[22+itag, *] ge alpmini[itag] and out[22+itag, *] le alpmaxi[itag], ns)
   ;; print,"pour ", tag_list[itag], ", nscans = ", ns
   ;;wall = where(out[16,*] le 0.4 and out[18+itag, *] ge chi2mini[itag] and out[18+itag, *] le chi2maxi[itag] and $
   ;;             out[22+itag, *] ge alpmini[itag] and out[22+itag, *] le alpmaxi[itag] and out[26+itag, *] ge 1., ns)
   ;;print,"pour ", tag_list[itag], ", nscans = ", ns
   
   ;; HIST_PLOT, out[26+itag, wall],noplot=0, NORMALIZE=NORMALIZE, dostat=0, fitgauss=0, FILL=FILL, $
   ;;            xtitle=tag_list[26+itag], $
   ;;            position=pp1[itag, *], $
   ;;            noerase=1, xstyle=1, charsize=charsize
   ;; HIST_PLOT, out[12+itag, wtau],noplot=0, NORMALIZE=NORMALIZE, dostat=0, fitgauss=0, FILL=FILL, $
   ;;            xtitle=tag_list[12+itag], $
   ;;            position=pp1[itag, *], $
   ;;            noerase=1, xstyle=1, charsize=charsize
   ;; HIST_PLOT, out[18+itag, wtau],noplot=0, NORMALIZE=NORMALIZE, dostat=1, fitgauss=1, FILL=FILL, $
   ;;            xtitle=tag_list[18+itag], $
   ;;            position=pp1[itag, *], $
   ;;            noerase=1, xstyle=1, charsize=charsize, min=-1, max=2.
   ;; HIST_PLOT, out[22+itag, wchi],noplot=0, NORMALIZE=NORMALIZE, dostat=0, fitgauss=0, FILL=FILL, $
   ;;            xtitle=tag_list[22+itag], $
   ;;            position=pp1[itag, *], $
   ;;            noerase=1, xstyle=1, charsize=charsize
   ;; HIST_PLOT, out[30+itag, wchi],noplot=0, NORMALIZE=NORMALIZE, dostat=1, fitgauss=1, FILL=FILL, $
   ;;            xtitle=tag_list[30+itag], min=0, max=50, $
   ;;            position=pp1[itag, *], $
   ;;            noerase=1, xstyle=1, charsize=charsize
   if ns ge 3 then begin
 
      ;; HIST_PLOT, out[itag, wall],noplot=0, min=mini[itag], max=maxi[itag], binsize= binsi[itag], $
      ;;            NORMALIZE=NORMALIZE, dostat=1, fitgauss=1, FILL=FILL, $
      ;;            xtitle=tag_list[itag], $
      ;;            position=pp1[itag, *], $
      ;;            noerase=1, xstyle=1, charsize=charsize
      
      f = reform(out[itag, wall])
      emin = mini[itag]
      emax = maxi[itag]
      bin = binsi[itag]
      
      np_histo, [f], out_xhist, out_yhist, out_gpar, min=emin, max=emax, binsize=bin, xrange=[emin, emax], fcol=80, fit=1, noerase=1, position=pp1[itag,*], nolegend=1, colorfit=250, thickfit=2*ps_thick, nterms_fit=3, xtitle="FWHM (arcsec)"

      
      leg_txt = ['N: '+num2string(n_elements(f)), $
                 'Avg: '+num2string(out_gpar[0,1]), $
                 '!7r!3: '+num2string(out_gpar[0,2])]
      
      legendastro, leg_txt, textcol=!p.color, box=0, charsize=1, /right
      legendastro, "A"+strtrim(array[itag], 2), textcol=!p.color, box=0, charsize=1
      
      print, "median chi2 = ", median(out[18+itag, wall])
      
   endif
   
   ;;for ii = 0, ns-1 do print,output_scans[0, wall[ii]], output_scans[1, wall[ii]], out[22:25, wall[ii]]
   
   endfor

outplot, /close
if ps gt 0 then !p.thick=1

stop

end
