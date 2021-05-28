;
;   Redo the summary plots of nk_test_allskd4
;
pro plot_test_allskd4, skdout, kidpar, newkidpar, $
                       plotdir=plotdir, png=png, ps=ps, pdf=pdf, $
                       runname=runname, file_suffixe=file_suffixe, dec2018=dec2018
  
  
; Do a multi-scan fit of skydips from a given campaign (of name fname)
; Data must be reduced with nk_skydip_5 and put in a structure
; $SAVE/Test_skydip2_'+fname+'.save'
; See examples in routines with a name like Test_skydip2.scr
; goodscan is the index of the selected skydips within the ones in fname
; kidparfile is the full name of the fits file containing the proper campaign
;   configuration
; A new kidpar is output that can be later saved as a fits. Only c0 and c1 are
; modified 
; runname is just the chosen string to name the run or a subrun
; verbose=2 :very verbose, 1: essential info, 0: nothing
; doplot  : 0 nothing is drawn, 1 all plots, 2: stop at each plot
; rmslim  : used for sigma-clipping: 3 is recommended value and the default
; value
; /help: do nothing, just list the scans to prepare goodscan
; FXD February 2017, same as nk_test_allskd.pro except that goodscan
; is a keyword now and scans are saved/restoreds individually
; Input output changes: allskd2 to allskd3


  if keyword_set(runname) then runid = runname else runid=''
  if keyword_set(file_suffixe) then fname = runid+file_suffixe else fname=runid
  if keyword_set(plotdir) then dir=plotdir else dir =!nika.plot_dir

  ;; window size for multi-plot (3, 2)
  wxsize = 1200.
  wysize = 850.
  ;; plot size in files
  pxsize = 20.
  pysize = 14.
  ;; charsize
  charsize  = 1.0
  charthick = 1.0
  mythick   = 1.0
  mysymsize = 0.8
  
  if keyword_set(ps) then begin
     ;; charsize
     ps_charsize  = 1.0
     ps_charthick = 3.0
     ps_mythick   = 3.0 
     ps_mysymsize = 0.8
  endif
  
  plot_color_convention, col_a1, col_a2, col_a3, $
                         col_mwc349, col_crl2688, col_ngc7027, $
                         col_n2r9, col_n2r12, col_n2r14, col_1mm
  
  
  verb=2
  c1lim = 6000.
  c1min = 100.                  ; a lower limit on c1min (up to 6000)
  c1st = 1000.                  ; starting point


  nsc = n_elements(skdout.scanname)
  scan_idx = indgen(nsc)


  gdscan = indgen(nsc)


  for i = 0, nsc-1 do print, 'index ', i, ', scan = ', skdout[gdscan[i]].scanname



  ;; tau skydip vs tau225
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize/2.
  outfile = dir+'/plot_allskd4_'+fname+'_0'
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize/2., charsize=charsize, thick=mythick, charthick=charthick
  ;;!p.multi = [0, 3, 1]
  my_multiplot, 3, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.06, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  ;; A1
  plot, skdout[gdscan].taufinal1, skdout[gdscan].tau225, $
        psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
        xtitle = 'Tau 1 (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
        ytitle='Tau', $
        title = 'NIKA2 '+runid, thick = 2, /iso, pos=pp1[0, *], charsize=0.9
  legendastro, ['Tau 225GHz', 'Tau 1'], col=[!p.color, col_a1], psym=[4,8], box=0
  oplot,  skdout[gdscan].taufinal1, skdout[gdscan].tau1, col = col_a1, psym = 8
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].tau1, skdout[gdscan].etaufinal1, $
              replicate(0, nsc), $
              errcolor = 118, psym = 3
  oplot, [0, 1.7], [0, 1.7], psym = -3
  xyouts, skdout[gdscan].taufinal1+0.02, skdout[gdscan].tau1, strtrim(scan_idx[gdscan], 2), chars=0.8, col=0
  ;; A3
  plot, skdout[gdscan].taufinal3, skdout[gdscan].tau225, $
        psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
        xtitle = 'Tau 3 (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
        ytitle='Tau', $
        title = 'NIKA2 '+runid, thick = 2, /iso, pos=pp1[1, *], /noerase, charsize=0.9
  legendastro, ['Tau 225GHz', 'Tau 3'], col=[!p.color, col_a3], psym=[4,8], box=0
  oplot,  skdout[gdscan].taufinal3, skdout[gdscan].tau3, col = col_a3, psym = 8
  oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].tau3, skdout[gdscan].etaufinal3, $
              replicate(0, nsc), $
              errcolor = 118, psym = 3
  oplot, [0, 1.7], [0, 1.7], psym = -3
  xyouts, skdout[gdscan].taufinal3+0.02, skdout[gdscan].tau3, strtrim(scan_idx[gdscan], 2), chars=0.8, col=0
  ;; A2
  plot, skdout[gdscan].taufinal2, skdout[gdscan].tau225,  /xsty, /ysty, /iso, $
        psym = 4, xra = [0, 1.4], yra = [0, 1.4], $
        xtitle = 'Tau 2 (multi-scan)', $
                                ;ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
        ytitle = 'Tau', $
        title = 'NIKA2 '+runid, thick = 2, pos=pp1[2, *], /noerase, charsize=0.9
  legendastro, ['Tau 225GHz', 'Tau 2'], col=[!p.color, col_a2], psym=[4,8], box=0
  oplot, skdout[gdscan].taufinal2, skdout[gdscan].tau2, col = col_a2, psym = 8
  oploterror, skdout[gdscan].taufinal2,  skdout[gdscan].tau2, skdout[gdscan].etaufinal2, $
              replicate(0, nsc), $
              errcolor = 118, psym = 3
  oplot, [0, 1.7], [0, 1.7], psym = -3
  xyouts, skdout[gdscan].taufinal2+0.01, skdout[gdscan].tau2, strtrim(scan_idx[gdscan], 2), chars=0.8, col=0
  !p.multi=0
  outplot, /close

  ;; repeat to save an eps plot
  if keyword_set(ps) or keyword_set(pdf) then begin
     
     outplot, file=outfile, ps=ps, xsize=pxsize, ysize=pysize/2., charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
     my_multiplot, 3, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.06, xmargin=0.1, ymargin=0.1 ; 1e-6
  
     ;; A1
     plot, skdout[gdscan].taufinal1, skdout[gdscan].tau225, $
           psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
           xtitle = 'Tau 1 (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
           ytitle='Tau', $
           title = runid, thick = 2, /iso, pos=pp1[0, *], charsize=0.8*ps_charsize
     legendastro, ['Tau 225GHz', 'Tau 1'], col=[!p.color, col_a1], psym=[4,8], box=0
     oplot,  skdout[gdscan].taufinal1, skdout[gdscan].tau1, col = col_a1, psym = 8
     oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].tau1, skdout[gdscan].etaufinal1, $
                 replicate(0, nsc), $
                 errcolor = 118, psym = 3
     oplot, [0, 1.7], [0, 1.7], psym = -3
     xyouts, skdout[gdscan].taufinal1+0.02, skdout[gdscan].tau1, strtrim(scan_idx[gdscan], 2), chars=0.8*ps_charsize, col=0
     ;; A3
     plot, skdout[gdscan].taufinal3, skdout[gdscan].tau225, $
           psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
           xtitle = 'Tau 3 (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
           ytitle='Tau', $
           title = runid, thick = 2, /iso, pos=pp1[1, *], /noerase, charsize=0.8*ps_charsize
     legendastro, ['Tau 225GHz', 'Tau 3'], col=[!p.color, col_a3], psym=[4,8], box=0
     oplot,  skdout[gdscan].taufinal3, skdout[gdscan].tau3, col = col_a3, psym = 8
     oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].tau3, skdout[gdscan].etaufinal3, $
                 replicate(0, nsc), $
                 errcolor = 118, psym = 3
     oplot, [0, 1.7], [0, 1.7], psym = -3
     xyouts, skdout[gdscan].taufinal3+0.02, skdout[gdscan].tau3, strtrim(scan_idx[gdscan], 2), chars=0.8*ps_charsize, col=0
     ;; A2
     plot, skdout[gdscan].taufinal2, skdout[gdscan].tau225,  /xsty, /ysty, /iso, $
           psym = 4, xra = [0, 1.4], yra = [0, 1.4], $
           xtitle = 'Tau 2 (multi-scan)', $
                                ;ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
           ytitle = 'Tau', $
           title = runid, thick = 2, pos=pp1[2, *], /noerase, charsize=0.8*ps_charsize
     legendastro, ['Tau 225GHz', 'Tau 2'], col=[!p.color, col_a2], psym=[4,8], box=0
     oplot, skdout[gdscan].taufinal2, skdout[gdscan].tau2, col = col_a2, psym = 8
     oploterror, skdout[gdscan].taufinal2,  skdout[gdscan].tau2, skdout[gdscan].etaufinal2, $
                 replicate(0, nsc), $
                 errcolor = 118, psym = 3
     oplot, [0, 1.7], [0, 1.7], psym = -3
     xyouts, skdout[gdscan].taufinal2+0.01, skdout[gdscan].tau2, strtrim(scan_idx[gdscan], 2), chars=0.8*ps_charsize, col=0
     !p.multi=0
     outplot, /close

     if keyword_set(pdf) then my_epstopdf_converter, outfile
        
     ;; restore plot aspect
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
     
  endif

  ;;------------------------------------------------------------------------------------
  nn = n_elements(gdscan)
  ind = indgen(nn)
  ind_ev = ind(where((ind/2.-ind/2) lt 0.1))
  ind_od = ind(where((ind/2.-ind/2) gt 0.1))
  
  wind, 1, 1, /free, xsize=wxsize, ysize=wysize/2.
  outfile = dir+'/plot_allskd4_'+fname+'_1'
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize/2., charsize=charsize, thick=mythick, charthick=charthick
  ;;!p.multi = [0, 3, 1]
  my_multiplot, 3, 1, pp, pp1, /rev, gap_y=0.06, gap_x=0.06, xmargin=0.06, ymargin=0.1 ; 1e-6
  
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, /xsty, /ysty, $
        psym = 4, xra = [0, 1.5], yra = [0, 1.3], $
        xtitle = 'Tau 1 (multi-scan)', $
        ytitle = 'Tau 2 (multi-scan)', $
        title = 'NIKA2 '+runid, thick = 2, pos=pp1[0, *], charsize=0.9
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2, $
              skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal2, $
              errcolor = 118, psym = 3
  a = linfit(skdout[gdscan].taufinal1, skdout[gdscan].taufinal2)
  oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 90
  xyouts, .1, .7, 'Slope '+string(a[1], format = '(1F5.2)'), col=90
  xyouts, .1, .8, 'Const '+string(a[0],format='(1F5.2)'), col=90
  print, 'zero point, slope tau2 vs tau1', a
  fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, a, b, $
          x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal2
  oplot, [0, 2], a+b*[0, 2], col = 240
  xyouts, skdout[gdscan[ind_ev]].taufinal1, skdout[gdscan[ind_ev]].taufinal2+0.04, strtrim(scan_idx[gdscan[ind_ev]], 2), $
          chars=0.8, col=0
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')], textcol=240
  ;;
  plot, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2, /xsty, /ysty, $
        psym = 4, xra = [0, 1.5], yra = [0, 1.3], $
        xtitle = 'Tau 3 (multi-scan)', $
        ytitle = 'Tau 2 (multi-scan)', $
        title = 'NIKA2 '+runid, thick = 2, pos=pp1[1, *], /noerase, charsize=0.9
  oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].taufinal2, $
              skdout[gdscan].etaufinal3, skdout[gdscan].etaufinal2, $
              errcolor = 118, psym = 3
  a = linfit(skdout[gdscan].taufinal3, skdout[gdscan].taufinal2)
  oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 90
  xyouts, .1, .7, 'Slope '+string(a[1], format = '(1F5.2)'), col=90
  xyouts, .1, .8, 'Const '+string(a[0],format='(1F5.2)'), col=90
  print, 'zero point, slope tau2 vs tau3', a
  fitexy, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2, a, b, $
          x_sig=skdout[gdscan].etaufinal3, y_sig=skdout[gdscan].etaufinal2
  oplot, [0, 2], a+b*[0, 2], col = 240
  xyouts, skdout[gdscan[ind_od]].taufinal3, skdout[gdscan[ind_od]].taufinal2+0.04, strtrim(scan_idx[gdscan[ind_od]], 2), $
          chars=0.8, col=0
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')], textcol=240
  
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3, /xsty, /ysty, $
        psym = 4, xra = [0, 1.5], yra = [0, 1.3], $
        xtitle = 'Tau 1 (multi-scan)', $
        ytitle = 'Tau 3 (multi-scan)', $
        title = 'NIKA2 '+runid, thick = 2, pos=pp1[2, *], /noerase, charsize=0.9 
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal3, $
              skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal3, $
              errcolor = 118, psym = 3
  a = linfit(skdout[gdscan].taufinal1, skdout[gdscan].taufinal3)
  oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 90
  xyouts, .1, .7, 'Slope '+string(a[1], format = '(1F5.2)'), col=90
  xyouts, .1, .8, 'Const '+string(a[0],format='(1F5.2)'), col=90
  print, 'zero point, slope tau1 vs tau3', a
  fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3, a, b, $
          x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal3
  oplot, [0, 2], a+b*[0, 2], col = 240
  xyouts, skdout[gdscan[ind_od]].taufinal1, skdout[gdscan[ind_od]].taufinal3+0.04, strtrim(scan_idx[gdscan[ind_od]], 2), $
          chars=0.8, col=0
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')], textcol=240
  
  outplot, /close
  
  ;; repeat to save an eps plot
  if keyword_set(ps) or keyword_set(pdf) then begin
     outplot, file=outfile, ps=ps, xsize=pxsize, ysize=pysize/2., charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
     ;;!p.multi = [0, 3, 1]
     my_multiplot, 3, 1, pp, pp1, /rev, gap_y=0.06, gap_x=0.06, xmargin=0.06, ymargin=0.1 ; 1e-6
     
     plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, /xsty, /ysty, $
           psym = 4, xra = [0, 1.5], yra = [0, 1.3], $
           xtitle = 'Tau 1 (multi-scan)', $
           ytitle = 'Tau 2 (multi-scan)', $
           title = runid, thick = 2*ps_mythick, pos=pp1[0, *], charsize=0.9*ps_charsize 
     oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2, $
                 skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal2, $
                 errcolor = 118, psym = 3
     a = linfit(skdout[gdscan].taufinal1, skdout[gdscan].taufinal2)
     oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 90
     xyouts, .1, .7, 'Slope '+string(a[1], format = '(1F5.2)'), col=90, charsize=0.8*ps_charsize
     xyouts, .1, .8, 'Const '+string(a[0],format='(1F5.2)'), col=90, charsize=0.8*ps_charsize
     print, 'zero point, slope tau2 vs tau1', a
     fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, a, b, $
             x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal2
     oplot, [0, 2], a+b*[0, 2], col = 240
     xyouts, skdout[gdscan[ind_ev]].taufinal1, skdout[gdscan[ind_ev]].taufinal2+0.04, strtrim(scan_idx[gdscan[ind_ev]], 2), $
             chars=0.8*ps_charsize, col=0
     legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                   'Fitexy slope '+string(b,form='(F4.2)')], textcol=240, charsize=0.8*ps_charsize
     ;;
     plot, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2, /xsty, /ysty, $
           psym = 4, xra = [0, 1.5], yra = [0, 1.3], $
           xtitle = 'Tau 3 (multi-scan)', $
           ytitle = 'Tau 2 (multi-scan)', $
           title = runid, thick = 2*ps_mythick, pos=pp1[1, *], /noerase, charsize=0.9*charsize 
     oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].taufinal2, $
                 skdout[gdscan].etaufinal3, skdout[gdscan].etaufinal2, $
                 errcolor = 118, psym = 3
     a = linfit(skdout[gdscan].taufinal3, skdout[gdscan].taufinal2)
     oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 90
     xyouts, .1, .7, 'Slope '+string(a[1], format = '(1F5.2)'), col=90, charsize=0.8*ps_charsize
     xyouts, .1, .8, 'Const '+string(a[0],format='(1F5.2)'), col=90, charsize=0.8*ps_charsize
     print, 'zero point, slope tau2 vs tau3', a
     fitexy, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2, a, b, $
             x_sig=skdout[gdscan].etaufinal3, y_sig=skdout[gdscan].etaufinal2
     oplot, [0, 2], a+b*[0, 2], col = 240
     xyouts, skdout[gdscan[ind_od]].taufinal3, skdout[gdscan[ind_od]].taufinal2+0.04, strtrim(scan_idx[gdscan[ind_od]], 2), $
             chars=0.8*ps_charsize, col=0
     legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                   'Fitexy slope '+string(b,form='(F4.2)')], textcol=240, charsize=0.8*ps_charsize
     
     plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3, /xsty, /ysty, $
           psym = 4, xra = [0, 1.5], yra = [0, 1.3], $
           xtitle = 'Tau 1 (multi-scan)', $
           ytitle = 'Tau 3 (multi-scan)', $
           title = runid, thick = 2*ps_mythick, pos=pp1[2, *], /noerase, charsize=0.9*charsize 
     oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal3, $
                 skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal3, $
                 errcolor = 118, psym = 3
     a = linfit(skdout[gdscan].taufinal1, skdout[gdscan].taufinal3)
     oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 90
     xyouts, .1, .7, 'Slope '+string(a[1], format = '(1F5.2)'), col=90, charsize=0.8*ps_charsize
     xyouts, .1, .8, 'Const '+string(a[0],format='(1F5.2)'), col=90, charsize=0.8*ps_charsize
     print, 'zero point, slope tau1 vs tau3', a
     fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3, a, b, $
             x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal3
     oplot, [0, 2], a+b*[0, 2], col = 240
     xyouts, skdout[gdscan[ind_od]].taufinal1, skdout[gdscan[ind_od]].taufinal3+0.04, strtrim(scan_idx[gdscan[ind_od]], 2), $
             chars=0.8*ps_charsize, col=0
     legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                   'Fitexy slope '+string(b,form='(F4.2)')], textcol=240, charsize=0.8*ps_charsize
     
     outplot, /close

     if keyword_set(pdf) then spawn, 'epspdf --bbox '+outfile+'.eps'

     ;; restore plot aspect
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
     
  endif

  ;;------------------------------------------------------------------------------------
  wind, 1, 4, /free, xsize=wxsize, ysize=wysize/2.
  outfile = dir+'/test_allskd4_'+fname+'_1b'
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize/2., charsize=charsize, thick=mythick, charthick=charthick
  !p.multi = [0, 3, 1]
  
  fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, a, b, $
          x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal2
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal1), /xsty, /ysty, $
        psym = 4, xra = [0, 1.2], yra = [-0.1, 0.1], $
        xtitle = 'Tau 1 (multi-scan)', $
        ytitle = 'Tau 2 (multi-scan) - linear fit', $
        title = 'NIKA2 '+runid, thick = 2;;, pos=pp1[0, *]
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal1), $
              skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal2, $
              errcolor = 118, psym = 3
  oplot, [0, 2], [0, 0], psym = -3, col = 240
  xyouts, skdout[gdscan[ind_ev]].taufinal1, skdout[gdscan[ind_ev]].taufinal2 - (a+ b*skdout[gdscan[ind_ev]].taufinal1)+0.005, strtrim(scan_idx[gdscan[ind_ev]], 2), $
          chars=0.6, col=0
  ;;xyouts, .1, .07, 'Slope= '+string(b, format = '(1F5.2)'), col=150
  ;;xyouts, .1, .08, 'Const = '+string(a,format='(1F5.2)'), col=150
  ngood = n_elements(gdscan[ind_ev])
  leg=strarr(ngood)
  for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[ind_ev[i]]], 2)+': '+strtrim(strmid(skdout[gdscan[ind_ev[i]]].scanname, 6, 6), 2)
  legendastro, leg, textcol=0, pos=[1., 0.09], charsize=0.8
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')],textcol=240

  ;; Array 3
  fitexy, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2, a, b, $
          x_sig=skdout[gdscan].etaufinal3, y_sig=skdout[gdscan].etaufinal2
  plot, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal3), /xsty, /ysty, $
        psym = 4, xra = [0, 1.2], yra = [-0.1, 0.1], $
        xtitle = 'Tau 3 (multi-scan)', $
        ytitle = 'Tau 2 (multi-scan) - linear fit', $
        title = 'NIKA2 '+runid, thick = 2;;, pos=pp1[1, *], /noerase
  oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal3), $
              skdout[gdscan].etaufinal3, skdout[gdscan].etaufinal2, $
              errcolor = 118, psym = 3
  oplot, [0, 2], [0, 0], psym = -3, col = 240
  xyouts, skdout[gdscan[ind_od]].taufinal3, skdout[gdscan[ind_od]].taufinal2 - (a + b*skdout[gdscan[ind_od]].taufinal3)+0.005, strtrim(scan_idx[gdscan[ind_od]], 2), $
          chars=0.6, col=0
  ;;xyouts, .1, .07, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
  ;;xyouts, .1, .08, 'Const = '+string(a[0],format='(1F5.2)'), col=150
  ngood = n_elements(gdscan[ind_od])
  leg=strarr(ngood)
  for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[ind_od[i]]], 2)+': '+strtrim(strmid(skdout[gdscan[ind_od[i]]].scanname, 6, 6), 2)
  legendastro, leg, textcol=0, pos=[1., 0.09], charsize=0.8
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')],textcol=240
  
;; Array 3 vs Array 1
  fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3, a, b, $
          x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal3
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3 - (a + b*skdout[gdscan].taufinal1), /xsty, /ysty, $
        psym = 4, xra = [0, 1.2], yra = [-0.1, 0.1], $
        xtitle = 'Tau 1 (multi-scan)', $
        ytitle = 'Tau 3 (multi-scan) - linear fit', $
        title = 'NIKA2 '+runid, thick = 2;;, pos=pp1[2, *], /noerase
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal3 - (a + b*skdout[gdscan].taufinal1), $
              skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal3, $
              errcolor = 118, psym = 3
  oplot, [0, 2], [0, 0], psym = -3, col = 240
  xyouts, skdout[gdscan[ind_od]].taufinal1, skdout[gdscan[ind_od]].taufinal3 - (a + b*skdout[gdscan[ind_od]].taufinal1)+0.005, strtrim(scan_idx[gdscan[ind_od]], 2), $
          chars=0.6, col=0
  ;;xyouts, .1, .07, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
  ;;xyouts, .1, .08, 'Const = '+string(a[0],format='(1F5.2)'), col=150
  ngood = n_elements(gdscan[ind_od])
  leg=strarr(ngood)
  for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[ind_od[i]]], 2)+': '+strtrim(strmid(skdout[gdscan[ind_od[i]]].scanname, 6, 6), 2)
  legendastro, leg, textcol=0, pos=[1., 0.09], charsize=0.8
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')],textcol=240
  
  outplot, /close

  ;; repeat to save an eps plot
  ;; if keyword_set(ps) or keyword_set(pdf) then begin
  ;;    outplot, file=outfile, ps=ps, xsize=pxsize, ysize=pysize/2., charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
  ;;    !p.multi = [0, 3, 1]
     
  ;;    fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, a, b, $
  ;;            x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal2
  ;;    plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal1), /xsty, /ysty, $
  ;;          psym = 4, xra = [0, 1.2], yra = [-0.1, 0.1], $
  ;;          xtitle = 'Tau 1 (multi-scan)', $
  ;;          ytitle = 'Tau 2 (multi-scan) - linear fit', $
  ;;          title = 'NIKA2 '+runid, thick = 2*ps_mythick ;;, pos=pp1[0, *]
  ;;    oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal1), $
  ;;                skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal2, $
  ;;                errcolor = 200, psym = 3
  ;;    oplot, [0, 2], [0, 0], psym = -3, col = 150
  ;;    xyouts, skdout[gdscan[ind_ev]].taufinal1, skdout[gdscan[ind_ev]].taufinal2 - (a+ b*skdout[gdscan[ind_ev]].taufinal1)+0.005, strtrim(scan_idx[gdscan[ind_ev]], 2), $
  ;;            chars=0.6*ps_charsize, col=0
  ;;    ;;xyouts, .1, .07, 'Slope= '+string(b, format = '(1F5.2)'), col=150
  ;;    ;;xyouts, .1, .08, 'Const = '+string(a,format='(1F5.2)'), col=150
  ;;    ngood = n_elements(gdscan[ind_ev])
  ;;    leg=strarr(ngood)
  ;;    for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[ind_ev[i]]], 2)+': '+strtrim(strmid(skdout[gdscan[ind_ev[i]]].scanname, 6, 6), 2)
  ;;    legendastro, leg, textcol=0, pos=[1., 0.09], charsize=0.8*ps_charsize
  ;;    legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
  ;;                  'Fitexy slope '+string(b,form='(F4.2)')],textcol=250

  ;;    ;; Array 3
  ;;    fitexy, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2, a, b, $
  ;;            x_sig=skdout[gdscan].etaufinal3, y_sig=skdout[gdscan].etaufinal2
  ;;    plot, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal3), /xsty, /ysty, $
  ;;          psym = 4, xra = [0, 1.2], yra = [-0.1, 0.1], $
  ;;          xtitle = 'Tau 3 (multi-scan)', $
  ;;          ytitle = 'Tau 2 (multi-scan) - linear fit', $
  ;;          title = 'NIKA2 '+runid, thick = 2*ps_mythick ;;, pos=pp1[1, *], /noerase
  ;;    oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].taufinal2 - (a + b*skdout[gdscan].taufinal3), $
  ;;                skdout[gdscan].etaufinal3, skdout[gdscan].etaufinal2, $
  ;;                errcolor = 200, psym = 3
  ;;    oplot, [0, 2], [0, 0], psym = -3, col = 150
  ;;    xyouts, skdout[gdscan[ind_od]].taufinal3, skdout[gdscan[ind_od]].taufinal2 - (a + b*skdout[gdscan[ind_od]].taufinal3)+0.005, strtrim(scan_idx[gdscan[ind_od]], 2), $
  ;;            chars=0.6*ps_charsize, col=0
  ;;    ;;xyouts, .1, .07, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
  ;;    ;;xyouts, .1, .08, 'Const = '+string(a[0],format='(1F5.2)'), col=150
  ;;    ngood = n_elements(gdscan[ind_od])
  ;;    leg=strarr(ngood)
  ;;    for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[ind_od[i]]], 2)+': '+strtrim(strmid(skdout[gdscan[ind_od[i]]].scanname, 6, 6), 2)
  ;;    legendastro, leg, textcol=0, pos=[1., 0.09], charsize=0.8*ps_charsize
  ;;    legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
  ;;                  'Fitexy slope '+string(b,form='(F4.2)')],textcol=250
     
  ;;    ;; Array 3 vs Array 1
  ;;    fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3, a, b, $
  ;;            x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal3
  ;;    plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3 - (a + b*skdout[gdscan].taufinal1), /xsty, /ysty, $
  ;;          psym = 4, xra = [0, 1.2], yra = [-0.1, 0.1], $
  ;;          xtitle = 'Tau 1 (multi-scan)', $
  ;;          ytitle = 'Tau 3 (multi-scan) - linear fit', $
  ;;          title = 'NIKA2 '+runid, thick = 2*ps_mythick ;;, pos=pp1[2, *], /noerase
  ;;    oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal3 - (a + b*skdout[gdscan].taufinal1), $
  ;;                skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal3, $
  ;;                errcolor = 200, psym = 3
  ;;    oplot, [0, 2], [0, 0], psym = -3, col = 150
  ;;    xyouts, skdout[gdscan[ind_od]].taufinal1, skdout[gdscan[ind_od]].taufinal3 - (a + b*skdout[gdscan[ind_od]].taufinal1)+0.005, strtrim(scan_idx[gdscan[ind_od]], 2), $
  ;;            chars=0.6*ps_charsize, col=0
  ;;    ;;xyouts, .1, .07, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
  ;;    ;;xyouts, .1, .08, 'Const = '+string(a[0],format='(1F5.2)'), col=150
  ;;    ngood = n_elements(gdscan[ind_od])
  ;;    leg=strarr(ngood)
  ;;    for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[ind_od[i]]], 2)+': '+strtrim(strmid(skdout[gdscan[ind_od[i]]].scanname, 6, 6), 2)
  ;;    legendastro, leg, textcol=0, pos=[1., 0.09], charsize=0.8*ps_charsize
  ;;    legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
  ;;                  'Fitexy slope '+string(b,form='(F4.2)')],textcol=250
  ;;    outplot, /close

  ;;    if keyword_set(pdf) then spawn, 'epspdf --bbox '+outfile+'.eps'
     
  ;;    ;; restore plot aspect
  ;;    !p.thick = 1.0
  ;;    !p.charsize  = 1.0
  ;;    !p.charthick = 1.0

     
  ;; endif

  

;;------------------------------------------------------------------------------------

  ;; "skydip" opacity
  pwv = 1
  atm_model_mdp, atm_tau1, atm_tau2, atm_tau3, atm_tau225, atm_em1, atm_em2, atm_em3, /tau225, old_a2=0, /nostop, nika1_bandpasses=0, output_pwv=pwv
  atm_model_mdp, atm_tau1_moy, atm_tau2_moy, atm_tau3_moy, atm_tau225_moy, atm_em1, atm_em2, atm_em3, /tau225, old_a2=0, /nostop, nika1_bandpasses=0, output_pwv=pwv, approx=1
  atm_model_mdp, atm_tau1_eff, atm_tau2_eff, atm_tau3_eff, atm_tau225_eff, atm_em1, atm_em2, atm_em3, /tau225, old_a2=0, /nostop, nika1_bandpasses=0, output_pwv=pwv, effective_opa=1
  atm_model_mdp, atm_tau1_eff, atm_tau2_eff, atm_tau3_eff, atm_tau225_eff, atm_em1, atm_em2, atm_em3, /tau225, old_a2=0, /nostop, nika1_bandpasses=0, output_pwv=pwv, dichroic=1
  
  ;; linear extrapolation at high pwv
npwv = n_elements(atm_tau3)
atm_fit = linfit(atm_tau3[5:*], atm_tau2[5:*])
atm_ratio_23 = dblarr(npwv+9)
atm_ratio_23[0:npwv-1] = atm_tau2/atm_tau3
hi_tau = dindgen(10)*(2.-max(atm_tau3))/10.+max(atm_tau3)
hi_tau = hi_tau[1:*]
atm_ratio_23[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
atm_tau3 = [atm_tau3, hi_tau]
;;
atm_fit = linfit(atm_tau1[5:*], atm_tau2[5:*])
atm_ratio_21 = dblarr(npwv+9)
atm_ratio_21[0:npwv-1] = atm_tau2/atm_tau1
hi_tau = dindgen(10)*(2.-max(atm_tau1))/10.+max(atm_tau1)
hi_tau = hi_tau[1:*]
atm_ratio_21[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
atm_tau1 = [atm_tau1, hi_tau]
;;
atm_fit = linfit(atm_tau1[5:npwv-1], atm_tau3[5:npwv-1])
atm_ratio_31 = dblarr(npwv+9)
atm_ratio_31[0:npwv-1] = atm_tau3[0:npwv-1]/atm_tau1[0:npwv-1]
atm_ratio_31[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
;;
;; moy
atm_fit = linfit(atm_tau3_moy[5:*], atm_tau2_moy[5:*])
atm_ratio_23_moy = dblarr(npwv+9)
atm_ratio_23_moy[0:npwv-1] = atm_tau2_moy/atm_tau3_moy
hi_tau = dindgen(10)*(2.-max(atm_tau3_moy))/10.+max(atm_tau3_moy)
hi_tau = hi_tau[1:*]
atm_ratio_23_moy[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
atm_tau3_moy = [atm_tau3_moy, hi_tau]
;;
atm_fit = linfit(atm_tau1_moy[5:*], atm_tau2_moy[5:*])
atm_ratio_21_moy = dblarr(npwv+9)
atm_ratio_21_moy[0:npwv-1] = atm_tau2_moy/atm_tau1_moy
hi_tau = dindgen(10)*(2.-max(atm_tau1_moy))/10.+max(atm_tau1_moy)
hi_tau = hi_tau[1:*]
atm_ratio_21_moy[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
atm_tau1_moy = [atm_tau1_moy, hi_tau]
;;
atm_fit = linfit(atm_tau1_moy[5:npwv-1], atm_tau3_moy[5:npwv-1])
atm_ratio_31_moy = dblarr(npwv+9)
atm_ratio_31_moy[0:npwv-1] = atm_tau3_moy[0:npwv-1]/atm_tau1_moy[0:npwv-1]
atm_ratio_31_moy[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
;;
;; eff
atm_fit = linfit(atm_tau3_eff[5:*], atm_tau2_eff[5:*])
atm_ratio_23_eff = dblarr(npwv+9)
atm_ratio_23_eff[0:npwv-1] = atm_tau2_eff/atm_tau3_eff
hi_tau = dindgen(10)*(2.-max(atm_tau3_eff))/10.+max(atm_tau3_eff)
hi_tau = hi_tau[1:*]
atm_ratio_23_eff[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
atm_tau3_eff = [atm_tau3_eff, hi_tau]
;;
atm_fit = linfit(atm_tau1_eff[5:*], atm_tau2_eff[5:*])
atm_ratio_21_eff = dblarr(npwv+9)
atm_ratio_21_eff[0:npwv-1] = atm_tau2_eff/atm_tau1_eff
hi_tau = dindgen(10)*(2.-max(atm_tau1_eff))/10.+max(atm_tau1_eff)
hi_tau = hi_tau[1:*]
atm_ratio_21_eff[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau
atm_tau1_eff = [atm_tau1_eff, hi_tau]
;;
atm_fit = linfit(atm_tau1_eff[5:npwv-1], atm_tau3_eff[5:npwv-1])
atm_ratio_31_eff = dblarr(npwv+9)
atm_ratio_31_eff[0:npwv-1] = atm_tau3_eff[0:npwv-1]/atm_tau1_eff[0:npwv-1]
atm_ratio_31_eff[npwv:*] = (atm_fit[0] + atm_fit[1]*hi_tau)/hi_tau


  ;;------------------------------------------------------------------------------------
  wind, 1, 4, /free, xsize=wxsize, ysize=wysize/2.
  outfile = dir+'/plot_allskd4_'+fname+'_1c'
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize/2., charsize=charsize, thick=mythick, charthick=charthick
  ;;!p.multi = [0, 3, 1]
  my_multiplot, 3, 1, pp, pp1, /rev, gap_y=0.06, gap_x=0.06, xmargin=0.06, ymargin=0.1 ; 1e-6
  
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2/skdout[gdscan].taufinal1, /xsty, /ysty, $
        psym = 4, xra = [0., 1.3], yra = [0.3, 0.9], $
        xtitle = 'Tau 1 (multi-scan)', $
        ytitle = 'Tau 2 -to- Tau 1 ratio (multi-scan)', $
        title = runid, thick = 2, pos=pp1[0, *], charsize=0.9
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2/skdout[gdscan].taufinal1, $
              skdout[gdscan].etaufinal1, (skdout[gdscan].etaufinal2*skdout[gdscan].taufinal1 - skdout[gdscan].etaufinal1*skdout[gdscan].taufinal2)/skdout[gdscan].taufinal1^2, $
              errcolor = 118, psym = 3
  oplot, atm_tau1, atm_ratio_21, col=10, thick=3
  ;;oplot, atm_tau1_moy, atm_ratio_21_moy, col=50, thick=3
  ;;oplot, atm_tau1_eff, atm_ratio_21_eff, col=150, thick=3
  oplot, atm_tau1, atm_ratio_21+0.1, col=10, thick=2
  oplot, atm_tau1, atm_ratio_21+0.2, col=10, thick=1
  xyouts, skdout[gdscan[ind_ev]].taufinal1, skdout[gdscan[ind_ev]].taufinal2/skdout[gdscan[ind_ev]].taufinal1+0.01, $
          strtrim(scan_idx[gdscan[ind_ev]], 2), $
          chars=0.8, col=0
  
  ;;
  plot, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2/skdout[gdscan].taufinal3, /xsty, /ysty, $
        psym = 4, xra = [0, 1.3], yra = [0.3, 0.9], $
        xtitle = 'Tau 3 (multi-scan)', $
        ytitle = 'Tau 2 -to- Tau3  (multi-scan)', $
        title = runid, thick = 2, pos=pp1[1, *], /noerase, charsize=0.9 
  oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].taufinal2/skdout[gdscan].taufinal3, $
              skdout[gdscan].etaufinal3, $
              (skdout[gdscan].etaufinal2*skdout[gdscan].taufinal3 - skdout[gdscan].etaufinal3*skdout[gdscan].taufinal2)/skdout[gdscan].taufinal3^2, $
              errcolor = 118, psym = 3
  oplot, atm_tau3, atm_ratio_23,     col=10, thick=3
  ;;oplot, atm_tau3_moy, atm_ratio_23_moy, col=50, thick=3
  ;;oplot, atm_tau3_eff, atm_ratio_23_eff, col=150, thick=3
  oplot, atm_tau3, atm_ratio_23+0.1, col=10, thick=2
  oplot, atm_tau3, atm_ratio_23+0.2, col=10, thick=1
  xyouts, skdout[gdscan[ind_od]].taufinal3, skdout[gdscan[ind_od]].taufinal2/skdout[gdscan[ind_od]].taufinal3+0.01, $
          strtrim(scan_idx[gdscan[ind_od]], 2), $
          chars=0.8, col=0
 
  
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3/skdout[gdscan].taufinal1, /xsty, /ysty, $
        psym = 4, xra = [0, 1.3], yra = [0.9, 1.3], $
        xtitle = 'Tau 1 (multi-scan)', $
        ytitle = 'Tau 3 -to- Tau1  (multi-scan)', $
        title = runid, thick = 2, pos=pp1[2, *], /noerase, charsize=0.9
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal3/skdout[gdscan].taufinal1, $
              skdout[gdscan].etaufinal1, $
              (skdout[gdscan].etaufinal3*skdout[gdscan].taufinal1 - skdout[gdscan].etaufinal1*skdout[gdscan].taufinal3)/skdout[gdscan].taufinal1^2, $
              errcolor = 118, psym = 3
  oplot, atm_tau1, atm_ratio_31,     col=10, thick=3
  ;;oplot, atm_tau1_moy, atm_ratio_31_moy, col=50, thick=3
  oplot, atm_tau1_eff, atm_ratio_31_eff, col=90, thick=3
  ;;oplot, atm_tau1, atm_ratio_31+0.1, col=50, thick=2
  ;;oplot, atm_tau1, atm_ratio_31+0.2, col=50, thick=1
  xyouts, skdout[gdscan[ind_od]].taufinal1, skdout[gdscan[ind_od]].taufinal3/skdout[gdscan[ind_od]].taufinal1+0.01, $
          strtrim(scan_idx[gdscan[ind_od]], 2), $
          chars=0.8, col=0
  
  legendastro, ['ATM model', 'ATM model +0.1', 'ATM model +0.2', 'dichroic-like filter on A3'], col=[10, 10, 10, 90], line=[0, 0, 0, 0], thick = [3, 2, 1, 3], textcol=[10, 10, 10, 90], pos = [0.15, 1.28], charsize=0.9
;;
  
  outplot, /close

  
  ;; repeat to save an eps plot
  if keyword_set(ps) or keyword_set(pdf) then begin
     outplot, file=outfile, ps=ps, xsize=pxsize, ysize=pysize/2., charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
     ;;!p.multi = [0, 3, 1]
     my_multiplot, 3, 1, pp, pp1, /rev, gap_y=0.06, gap_x=0.06, xmargin=0.06, ymargin=0.1 ; 1e-6
     
     plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2/skdout[gdscan].taufinal1, /xsty, /ysty, $
           psym = 4, xra = [0., 1.3], yra = [0.3, 0.9], $
           xtitle = 'Tau 1 (multi-scan)', $
           ytitle = 'Tau 2 -to- Tau 1 ratio (multi-scan)', $
           title = runid, thick = 2*ps_mythick, pos=pp1[0, *] 
     oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2/skdout[gdscan].taufinal1, $
                 skdout[gdscan].etaufinal1, (skdout[gdscan].etaufinal2*skdout[gdscan].taufinal1 - skdout[gdscan].etaufinal1*skdout[gdscan].taufinal2)/skdout[gdscan].taufinal1^2, $
                 errcolor = 118, psym = 3
     oplot, atm_tau1, atm_ratio_21,     col=10, thick=3
     ;;oplot, atm_tau1_moy, atm_ratio_21_moy, col=50, thick=3
     ;;oplot, atm_tau1_eff, atm_ratio_21_eff, col=150, thick=3
     oplot, atm_tau1, atm_ratio_21+0.1, col=10, thick=2
     oplot, atm_tau1, atm_ratio_21+0.2, col=10, thick=1
     xyouts, skdout[gdscan[ind_ev]].taufinal1, skdout[gdscan[ind_ev]].taufinal2/skdout[gdscan[ind_ev]].taufinal1+0.01, $
             strtrim(scan_idx[gdscan[ind_ev]], 2), $
             chars=0.8*ps_charsize, col=0
     
     ;;
     plot, skdout[gdscan].taufinal3, skdout[gdscan].taufinal2/skdout[gdscan].taufinal3, /xsty, /ysty, $
           psym = 4, xra = [0, 1.3], yra = [0.3, 0.9], $
           xtitle = 'Tau 3 (multi-scan)', $
           ytitle = 'Tau 2 -to- Tau3  (multi-scan)', $
           title = runid, thick = 2*ps_mythick, pos=pp1[1, *], /noerase 
     oploterror, skdout[gdscan].taufinal3,  skdout[gdscan].taufinal2/skdout[gdscan].taufinal3, $
                 skdout[gdscan].etaufinal3, $
                 (skdout[gdscan].etaufinal2*skdout[gdscan].taufinal3 - skdout[gdscan].etaufinal3*skdout[gdscan].taufinal2)/skdout[gdscan].taufinal3^2, $
                 errcolor = 118, psym = 3
     oplot, atm_tau3, atm_ratio_23,     col=10, thick=3
     ;;oplot, atm_tau3_moy, atm_ratio_23_moy, col=50, thick=3
     ;;oplot, atm_tau3_eff, atm_ratio_23_eff, col=150, thick=3
     oplot, atm_tau3, atm_ratio_23+0.1, col=10, thick=2
     oplot, atm_tau3, atm_ratio_23+0.2, col=10, thick=1
     xyouts, skdout[gdscan[ind_od]].taufinal3, skdout[gdscan[ind_od]].taufinal2/skdout[gdscan[ind_od]].taufinal3+0.01, $
             strtrim(scan_idx[gdscan[ind_od]], 2), $
             chars=0.8*ps_charsize, col=0
     
     
     plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal3/skdout[gdscan].taufinal1, /xsty, /ysty, $
           psym = 4, xra = [0, 1.3], yra = [0.9, 1.3], $
           xtitle = 'Tau 1 (multi-scan)', $
           ytitle = 'Tau 3 -to- Tau1  (multi-scan)', $
           title = runid, thick = 2*ps_mythick, pos=pp1[2, *], /noerase 
     oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal3/skdout[gdscan].taufinal1, $
                 skdout[gdscan].etaufinal1, $
                 (skdout[gdscan].etaufinal3*skdout[gdscan].taufinal1 - skdout[gdscan].etaufinal1*skdout[gdscan].taufinal3)/skdout[gdscan].taufinal1^2, $
                 errcolor = 118, psym = 3
     oplot, atm_tau1, atm_ratio_31,     col=10, thick=3
     ;;oplot, atm_tau1_moy, atm_ratio_31_moy, col=50, thick=3
     oplot, atm_tau1_eff, atm_ratio_31_eff, col=90, thick=3
     ;;oplot, atm_tau1, atm_ratio_31+0.1, col=50, thick=2
     ;;oplot, atm_tau1, atm_ratio_31+0.2, col=50, thick=1
     xyouts, skdout[gdscan[ind_od]].taufinal1, skdout[gdscan[ind_od]].taufinal3/skdout[gdscan[ind_od]].taufinal1+0.01, $
             strtrim(scan_idx[gdscan[ind_od]], 2), $
             chars=0.8*ps_charsize, col=0
     
     legendastro, ['ATM model', 'ATM model +0.1', 'ATM model +0.2', 'dichroic-like filter on A3'], col=[10, 10, 10, 90], line=[0, 0, 0, 0], thick = [3, 2, 1, 3], textcol=[10, 10, 10, 90], pos = [0.15, 1.28], charsize=0.8*ps_charsize
;;
     
     outplot, /close
     
     if keyword_set(pdf) then spawn, 'epspdf --bbox '+outfile+'.eps'
     
     ;; restore plot aspect
     !p.thick = 1.0
     !p.charsize  = 1.0
     !p.charthick = 1.0
  endif


  
  
  ;;------------------------------------------------------------------------------------

; Plot new c1 against old c1

  tabcol = [col_a1, col_a3, col_a2]
  wind, 1, 1, /free, xsize=wxsize*0.7, ysize=wysize*0.5
  outfile = dir+'/plot_allskd4_'+fname+'_2'
  outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize/2., charsize=charsize, thick=mythick, charthick=charthick
  !p.multi = [0, 2, 1]
  ;;my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  for lamb = 1, 2 do begin      ; loop on the 2 wavelengths
      if lamb eq 1 then lambt = '1 mm'
      if lamb eq 2 then lambt = '2 mm'
      if lamb eq 1 then $
         kidall = where( kidpar.type eq 1 and $
                         kidpar.lambda lt 1.5, nallkid) else $
                            kidall = where( kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)

      if verb ge 1 then print, nallkid, ' valid at '+lambt
      noerase=1
      if lamb eq 1 then noerase=0
      plot, kidpar[ kidall].c1_skydip, newkidpar[ kidall].c1_skydip, $
            xrang = [0, c1lim/lamb], yrang = [0, c1lim/lamb], /xsty, /ysty, psym = 8, $
            /iso, xtitle='Response [Hz/K] (old kidpar)', $ ;xtitle = 'Response [Hz/K] one-scan', $
            ytitle = 'Response [Hz/K] multi-scan',  $
            title = 'NIKA2 '+runid+', c1 at '+ lambt, thick = 2, charsize=0.8;;, $
            ;;pos=pp1[lamb-1, *], noerase=noerase
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[col_a1,col_a3], box=0, textcol=[col_a1, col_a3]
      a1 = where( kidpar[ kidall].array eq 1, na1)
      if na1 ne 0 then $
         oplot, kidpar[ kidall[a1]].c1_skydip, $
                newkidpar[ kidall[a1]].c1_skydip, psym = 4, col = tabcol[0]
      a3 = where( kidpar[ kidall].array eq 3, na3)
      if na3 ne 0 then $
         oplot, kidpar[ kidall[a3]].c1_skydip, $
                newkidpar[ kidall[a3]].c1_skydip, psym = 4, col = tabcol[1]
      gdk = where(kidpar[ kidall].c1_skydip gt 0. and $
                  newkidpar[ kidall].c1_skydip gt 0., ngdk)
      if ngdk ne 0 then begin
         slope = avg( newkidpar[ kidall[ gdk]].c1_skydip / $
                      kidpar[ kidall[ gdk]].c1_skydip)
         oplot, [0, c1lim], slope*[0, c1lim], psym = -3, col = 90
         xyouts, 500, 5000./lamb, 'Slope= '+string(slope, format = '(1F5.2)')
      endif

   endfor

   !p.multi=0
   outplot, /close

   
   ;; repeat to save an eps plot
   ;; if keyword_set(ps) or keyword_set(pdf) then begin
   ;;    outplot, file=outfile, ps=ps, xsize=pxsize*0.7, ysize=pysize*0.5, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
   ;;    !p.multi = [0, 2, 1]
      
   ;;    for lamb = 1, 2 do begin  ; loop on the 2 wavelengths
   ;;       if lamb eq 1 then lambt = '1 mm'
   ;;       if lamb eq 2 then lambt = '2 mm'
   ;;       if lamb eq 1 then $
   ;;          kidall = where( kidpar.type eq 1 and $
   ;;                          kidpar.lambda lt 1.5, nallkid) else $
   ;;                             kidall = where( kidpar.type eq 1 and $
   ;;                                             kidpar.lambda gt 1.5, nallkid)
         
   ;;       if verb ge 1 then print, nallkid, ' valid at '+lambt
   ;;       noerase=1
   ;;       if lamb eq 1 then noerase=0
   ;;       plot, kidpar[ kidall].c1_skydip, newkidpar[ kidall].c1_skydip, $
   ;;             xrang = [0, c1lim/lamb], yrang = [0, c1lim/lamb], /xsty, /ysty, psym = 8, $
   ;;             /iso, xtitle='Response [Hz/K] (old kidpar)', $ ;xtitle = 'Response [Hz/K] one-scan', $
   ;;             ytitle = 'Response [Hz/K] multi-scan',  $
   ;;             title = 'NIKA2 '+runid+', c1 at '+ lambt, thick = 2*ps_mythick, charsize=0.8*ps_charsize ;;, $
   ;;       ;;pos=pp1[lamb-1, *], noerase=noerase
   ;;       if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[100,200], box=0, textcol=[100,200]
   ;;       a1 = where( kidpar[ kidall].array eq 1, na1)
   ;;       if na1 ne 0 then $
   ;;          oplot, kidpar[ kidall[a1]].c1_skydip, $
   ;;                 newkidpar[ kidall[a1]].c1_skydip, psym = 4, col = tabcol[0]
   ;;       a3 = where( kidpar[ kidall].array eq 3, na3)
   ;;       if na3 ne 0 then $
   ;;          oplot, kidpar[ kidall[a3]].c1_skydip, $
   ;;                 newkidpar[ kidall[a3]].c1_skydip, psym = 4, col = tabcol[2]
   ;;       gdk = where(kidpar[ kidall].c1_skydip gt 0. and $
   ;;                   newkidpar[ kidall].c1_skydip gt 0., ngdk)
   ;;       if ngdk ne 0 then begin
   ;;          slope = avg( newkidpar[ kidall[ gdk]].c1_skydip / $
   ;;                       kidpar[ kidall[ gdk]].c1_skydip)
   ;;          oplot, [0, c1lim], slope*[0, c1lim], psym = -3, col = 150
   ;;          xyouts, 500, 5000./lamb, 'Slope= '+string(slope, format = '(1F5.2)')
   ;;       endif
         
   ;;    endfor
      
   ;;    !p.multi=0
   ;;    outplot, /close
      
   ;;    if keyword_set(pdf) then spawn, 'epspdf --bbox '+outfile+'.eps'
      
   ;;    ;; restore plot aspect
   ;;    !p.thick = 1.0
   ;;    !p.charsize  = 1.0
   ;;    !p.charthick = 1.0
      
   ;; endif
   

   wind, 1, 1, /free, xsize=wxsize*0.7, ysize=wysize*0.5
   outfile = dir+'/plot_allskd4_'+fname+'_3'
   outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize/2., charsize=charsize, thick=mythick, charthick=charthick
   !p.multi = [0, 2, 1]
   ;;my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
   
   for lamb = 1, 2 do begin     ; loop on the 2 wavelengths
      if lamb eq 1 then lambt = '1 mm'
      if lamb eq 2 then lambt = '2 mm'
      if lamb eq 1 then $
         kidall = where( kidpar.type eq 1 and $
                         kidpar.lambda lt 1.5, nallkid) else $
                            kidall = where( kidpar.type eq 1 and $
                                            kidpar.lambda gt 1.5, nallkid)
      
      if verb ge 1 then print, nallkid, ' valid at '+lambt
      noerase=1
      if lamb eq 1 then noerase=0
      xrang = [0, 0.4]
      plot,1E-3/ newkidpar[ kidall].calib_fix_fwhm, newkidpar[ kidall].c1_skydip, $
           xrang = xrang, yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
           xtitle = 'PS Response [Hz/(mJy/beam)]', $
           ytitle = 'Response [Hz/K] multi-scan',  $
           title = 'NIKA2 '+runid+', calib_fix_fwhm, c1 at '+ lambt, thick = 2, charsize=0.8;;, $
          ;; pos=pp1[lamb-1, *], noerase=noerase
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[tabcol[0],tabcol[1]], box=0, textcol=[tabcol[0],tabcol[1]]
      a1 = where( kidpar[ kidall].array eq 1, na1)
      if na1 ne 0 then $
         oplot,1E-3/ newkidpar[ kidall[a1]].calib_fix_fwhm, $
               newkidpar[ kidall[a1]].c1_skydip, psym = 4, symsize = 2, col = tabcol[0]
      a3 = where( kidpar[ kidall].array eq 3, na3)
      if na3 ne 0 then $
         oplot,1E-3/ newkidpar[ kidall[a3]].calib_fix_fwhm, $
               newkidpar[ kidall[a3]].c1_skydip, psym = 4, symsize = 1, col = tabcol[1]
      gdk = where(newkidpar[ kidall].calib_fix_fwhm gt 0. and $
                  newkidpar[ kidall].c1_skydip gt 0., ngdk)
      if ngdk ne 0 then begin
         slope = avg( newkidpar[ kidall[ gdk]].c1_skydip * $
                      newkidpar[ kidall[ gdk]].calib_fix_fwhm)*1E3
         oplot, [0, 0.3], slope*[0, 0.3], psym = -3, col = 90
         xyouts, .20, 500, 'Slope= '+string(slope, format = '(1F7.0)')
      endif
      
      
   endfor

   !p.multi=0
   outplot, /close


   ;; Insert here plots of the fit quality
   ;; Same plot as in select_skydips.pro
   ;; wind, 1, 1, /free, xsize=wxsize, ysize=wysize*0.8
;;    outfile = dir+'/plot_allskd4_'+fname+'_fitqual'
;;    outplot, file=outfile, png=png, xsize=pxsize, ysize=pysize*0.8, charsize=charsize, thick=mythick, charthick=charthick
;;    ;;!p.multi = [0, 2, 1]
;;    my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

;;    scanname = skdout.scanname

;;    if tag_exist(skdout, 'rmsa1') then begin
;;       plot, skdout.rmsa1, indgen(nsc), yrange = [-1, nsc], xsty = 0, /nodata, $
;;             xrange = [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])*2], ysty = 0, $
;;             title = runname+', Skydip dispersion', $
;;             thick = 2, xtitle = 'Median rms [Hz]', ytitle = 'Scan number', pos=pp1[0, *], noerase=0
;;       for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])], [i,i] 
;;       legendastro, reverse( zeropadd( indgen(nsc), 2)+': '+ $
;;                             string(scanname, '(A13)')+' ; tau1='+ $
;;                             string( skdout.taufinal1, '(1F6.2)')), $
;;                    box = 0, /bottom, /right, charsize=0.8
;;       ;;legendastro, psym = [4, 4, 4], ['Arr1', 'Arr3', 'Arr2'], $
;;       ;;             colors = [100, 150, 200], /top, /right
;;       oplot, psym = -8, color = tabcol[0], skdout.rmsa1, indgen(nsc)
;;       oplot, psym = -8, color = tabcol[1], skdout.rmsa3, indgen(nsc)
;;       oplot, psym = -8, color = tabcol[2], skdout.rmsa2, indgen(nsc)
;;    endif
   
;; ; Plot Deltac0 per scan
;;    if tag_exist(skdout, 'dt') then begin
;;       dtall = fltarr(3, nsc)
;;       dtarr = skdout.dt
;;       for narr = 1, 3 do begin  ; loop on arrays
;;          kidall = where( kidpar.type eq 1 and $
;;                          kidpar.array eq narr, nallkid)       
         
;;          ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
;;          ;; TBC !!!
;;          if keyword_set(dec2018) then $
;;             kidall = where( kidpar.c0_skydip ne 0 and kidpar.type eq 1 and $
;;                             kidpar.array eq narr, nallkid)       

;;          for isc = 0, nsc-1 do begin ; Median function does not exclude Nans
;;             u = where( finite( dtarr[ kidall, isc]) eq 1, nu)
;;             ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
;;             ;; TBC !!!
;;             if keyword_set(dec2018) then $
;;                u = where( finite( dtarr[ kidall, isc]) and dtarr[kidall,isc] ne 0, nu)

;;             if nu gt 3 then dtall[narr-1, isc]= $
;;                median(/double, dtarr[ kidall[ u], isc])
;;          endfor
;;       endfor
      
;;       plot, dtall[ 0, *], indgen(nsc), yrange = [-1, nsc], xsty = 0, /nodata, $
;;             xrange = [min(dtall), max([max(dtall)*2, 2.])], ysty = 0, $
;;             title = runname+', Skydip offset', $
;;             thick = 2, xtitle = 'Median dT [K]', ytitle = 'Scan number', pos=pp1[1, *], noerase=1
;;       for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [min(dtall), max(dtall)], [i,i] 
;;       legendastro, reverse( zeropadd( indgen(nsc), 2)+': '+ $
;;                             string(scanname, '(A13)')+' ; tau1='+ $
;;                             string( skdout.taufinal1, '(1F6.2)')), $
;;                    box = 0, /bottom, /right, charsize=0.6
;;       legendastro, psym = [8, 8, 8], ['A1', 'A3', 'A2'], $
;;                    colors = tabcol([0, 1, 2]), /top
;;       oplot, psym = -8, color = tabcol[0], dtall[0, *], indgen(nsc)
;;       oplot, psym = -8, color = tabcol[1], dtall[2, *], indgen(nsc)
;;       oplot, psym = -8, color = tabcol[2], dtall[1, *], indgen(nsc)
;;       oplot, psym = -3, [0, 0], !y.crange, thick = 2
;;    endif
;;    !p.multi=0
;;    outplot, /close

;;    ;; repeat to save an eps plot
;;    if keyword_set(ps) or keyword_set(pdf) then begin
;;       outplot, file=outfile, ps=ps, xsize=pxsize, ysize=pysize*0.8, charsize=ps_charsize, thick=ps_mythick, charthick=ps_charthick
;;       my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6

;;       scanname = skdout.scanname
      
;;       if tag_exist(skdout, 'rmsa1') then begin
;;          plot, skdout.rmsa1, indgen(nsc), yrange = [-1, nsc], xsty = 0, /nodata, $
;;                xrange = [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])*2], ysty = 0, $
;;                title = runname+', Skydip dispersion', $
;;                thick = 2*ps_mythick, xtitle = 'Median rms [Hz]', ytitle = 'Scan number', pos=pp1[0, *], noerase=0
;;          for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [0, max([skdout.rmsa1, skdout.rmsa2, skdout.rmsa3])], [i,i] 
;;          legendastro, reverse( zeropadd( indgen(nsc), 2)+': '+ $
;;                                string(scanname, '(A13)')+' ; tau1='+ $
;;                                string( skdout.taufinal1, '(1F6.2)')), $
;;                       box = 0, /bottom, /right, charsize=0.8
;;          ;;legendastro, psym = [4, 4, 4], ['Arr1', 'Arr3', 'Arr2'], $
;;          ;;             colors = [100, 150, 200], /top, /right
;;          oplot, psym = -8, color = tabcol[0], skdout.rmsa1, indgen(nsc)
;;          oplot, psym = -8, color = tabcol[1], skdout.rmsa3, indgen(nsc)
;;          oplot, psym = -8, color = tabcol[2], skdout.rmsa2, indgen(nsc)
;;       endif
      
;; ; Plot Deltac0 per scan
;;       if tag_exist(skdout, 'dt') then begin
;;          dtall = fltarr(3, nsc)
;;          dtarr = skdout.dt
;;          for narr = 1, 3 do begin ; loop on arrays
;;             kidall = where( kidpar.type eq 1 and $
;;                             kidpar.array eq narr, nallkid)       
            
;;             ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
;;             ;; TBC !!!
;;             if keyword_set(dec2018) then $
;;                kidall = where( kidpar.c0_skydip ne 0 and kidpar.type eq 1 and $
;;                                kidpar.array eq narr, nallkid)       
            
;;             for isc = 0, nsc-1 do begin ; Median function does not exclude Nans
;;                u = where( finite( dtarr[ kidall, isc]) eq 1, nu)
;;                ;; NP, dec. 2018: add constrain on c0_skydip in kidall def ?!
;;                ;; TBC !!!
;;                if keyword_set(dec2018) then $
;;                   u = where( finite( dtarr[ kidall, isc]) and dtarr[kidall,isc] ne 0, nu)
               
;;                if nu gt 3 then dtall[narr-1, isc]= $
;;                   median(/double, dtarr[ kidall[ u], isc])
;;             endfor
;;          endfor
         
;;          plot, dtall[ 0, *], indgen(nsc), yrange = [-1, nsc], xsty = 0, /nodata, $
;;                xrange = [min(dtall), max([max(dtall)*2, 2.])], ysty = 0, $
;;                title = runname+', Skydip offset', $
;;                thick = 2*ps_mythick, xtitle = 'Median dT [K]', ytitle = 'Scan number', pos=pp1[1, *], noerase=1
;;          for i =0, nsc-1 do if (i mod 10 eq 0) then oplot, [min(dtall), max(dtall)], [i,i] 
;;          legendastro, reverse( zeropadd( indgen(nsc), 2)+': '+ $
;;                                string(scanname, '(A13)')+' ; tau1='+ $
;;                                string( skdout.taufinal1, '(1F6.2)')), $
;;                       box = 0, /bottom, /right, charsize=0.6*ps_charsize
;;          legendastro, psym = [8, 8, 8], ['A1', 'A3', 'A2'], $
;;                       colors = tabcol, /top
;;          oplot, psym = -8, color = tabcol[0], dtall[0, *], indgen(nsc)
;;          oplot, psym = -8, color = tabcol[1], dtall[2, *], indgen(nsc)
;;          oplot, psym = -8, color = tabcol[2], dtall[1, *], indgen(nsc)
;;          oplot, psym = -3, [0, 0], !y.crange, thick = 2
;;       endif
;;       !p.multi=0
      
;;       outplot, /close
      
;;      if keyword_set(pdf) then spawn, 'epspdf --bbox '+outfile+'.eps'

;;      ;; restore plot aspect
;;      loadct, 39
;;      !p.thick = 1.0
;;      !p.charsize  = 1.0
;;      !p.charthick = 1.0
     
;;   endif
   
   
   
end 
