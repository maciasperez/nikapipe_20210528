;
;   Redo the summary plots of nk_test_allskd3
;
pro plot_test_allskd3, skdout, kidpar, newkidpar, plotdir=plotdir, $
                       png=png, ps=ps, pdf=pdf, runname=runname, file_suffixe=file_suffixe
  

  
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
  if keyword_set(file_suffixe) then fname = runid+'_'+file_suffixe else fname=runid
  if keyword_set(plotdir) then dir=plotdir else dir =!nika.plot_dir
  
  verb=2
  c1lim = 6000.
  c1min = 100.                  ; a lower limit on c1min (up to 6000)
  c1st = 1000.                  ; starting point


  nsc = n_elements(skdout.scanname)
  scan_idx = indgen(nsc)


  gdscan = indgen(nsc)


  for i = 0, nsc-1 do print, 'index ', i, ', scan = ', skdout[gdscan[i]].scanname


  
  wind, 1, 1, /free, xsize=1000, ysize=550
  outfile = dir+'/test_allskd0_'+fname
  outplot, file=outfile, png=png, ps=ps
  my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.05, gap_x=0.06, xmargin=0.1, ymargin=0.1 ; 1e-6
  
  plot, skdout[gdscan].taufinal1, skdout[gdscan].tau225, $
        psym = 4, xra = [0, 1.7], yra = [0, 1.7], /xsty, /ysty, $
        xtitle = 'Tau 1mm (multi-scan)', $
                                ; ytitle = 'Tau 225GHz, Tau 1mm (mono-scan, color)', $
        ytitle='Tau', $
        title = 'NIKA2 '+runid, thick = 2, /iso, pos=pp1[0, *]
  legendastro, ['Tau 225GHz', 'Tau 1mm'], col=[!p.color, 100], psym=[4,8], box=0
  oplot,  skdout[gdscan].taufinal1, skdout[gdscan].tau1, col = 100, psym = 8
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].tau1, skdout[gdscan].etaufinal1, $
              replicate(0, nsc), $
              errcolor = 200, psym = 3
  oplot, [0, 1.7], [0, 1.7], psym = -3
  xyouts, skdout[gdscan].taufinal1, skdout[gdscan].tau1, strtrim(scan_idx[gdscan], 2), chars=0.6, col=0
  
  plot, skdout[gdscan].taufinal2, skdout[gdscan].tau225,  /xsty, /ysty, /iso, $
        psym = 4, xra = [0, 1.4], yra = [0, 1.4], $
        xtitle = 'Tau 2mm (multi-scan)', $
                                ;ytitle = 'Tau 225GHz, Tau 2mm (mono-scan, color)', $
        ytitle = 'Tau', $
        title = 'NIKA2 '+runid, thick = 2, pos=pp1[1, *], /noerase
  legendastro, ['Tau 225GHz', 'Tau 2mm'], col=[!p.color, 100], psym=[4,8], box=0
  oplot, skdout[gdscan].taufinal2, skdout[gdscan].tau2, col = 100, psym = 8
  oploterror, skdout[gdscan].taufinal2,  skdout[gdscan].tau2, skdout[gdscan].etaufinal2, $
              replicate(0, nsc), $
              errcolor = 200, psym = 3
  oplot, [0, 1.7], [0, 1.7], psym = -3
  xyouts, skdout[gdscan].taufinal2, skdout[gdscan].tau2, strtrim(scan_idx[gdscan], 2), chars=0.6, col=0
  !p.multi=0
  outplot, /close


  wind, 1, 1, /free, xsize=800, ysize=600
  outfile = dir+'/test_allskd1_'+fname
  outplot, file=outfile, png=png, ps=ps
  
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, /iso, /xsty, /ysty, $
        psym = 4, xra = [0, 1.7], yra = [0, 1.4], $
        xtitle = 'Tau 1mm (multi-scan)', $
        ytitle = 'Tau 2mm (multi-scan)', $
        title = 'NIKA2 '+runid, thick = 2
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2, $
              skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal2, $
              errcolor = 200, psym = 3
  a = linfit(skdout[gdscan].taufinal1, skdout[gdscan].taufinal2)
  oplot, [0, 2], a[0]+a[1]*[0, 2], psym = -3, col = 150
  xyouts, .1, .7, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
  xyouts, .1, .8, 'Const = '+string(a[0],format='(1F5.2)'), col=150
  print, 'zero point, slope tau2 vs tau1', a
  fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, a, b, $
          x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal2
  oplot, [0, 2], a+b*[0, 2], col = 250
  xyouts, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2+0.03, strtrim(scan_idx[gdscan], 2), $
          chars=0.6, col=0
  legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
                'Fitexy slope '+string(b,form='(F4.2)')], textcol=250
  outplot, /close


  outfile = dir+'/test_allskd1b_'+fname
  outplot, file=outfile, png=png, ps=ps
  
  wind, 1, 1, /free, xsize=800, ysize=600
  a = linfit(skdout[gdscan].taufinal1, skdout[gdscan].taufinal2)
  plot, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2 - (a[0] + a[1]*skdout[gdscan].taufinal1), /xsty, /ysty, $
        psym = 4, xra = [0, 1.], yra = [-0.1, 0.1], $
        xtitle = 'Tau 1mm (multi-scan)', $
        ytitle = 'Tau 2mm (multi-scan) - linear fit', $
        title = 'NIKA2 '+runid, thick = 2
  oploterror, skdout[gdscan].taufinal1,  skdout[gdscan].taufinal2 - (a[0] + a[1]*skdout[gdscan].taufinal1), $
              skdout[gdscan].etaufinal1, skdout[gdscan].etaufinal2, $
              errcolor = 200, psym = 3
  oplot, [0, 2], [0, 0], psym = -3, col = 150
  xyouts, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2 - (a[0] + a[1]*skdout[gdscan].taufinal1)+0.005, strtrim(scan_idx[gdscan], 2), $
          chars=0.6, col=0
  xyouts, .1, .07, 'Slope= '+string(a[1], format = '(1F5.2)'), col=150
  xyouts, .1, .08, 'Const = '+string(a[0],format='(1F5.2)'), col=150
  ngood = n_elements(gdscan)
  leg=strarr(ngood)
  for i=0, ngood-1 do leg[i] = strtrim(scan_idx[gdscan[i]], 2)+': '+strtrim(strmid(skdout[gdscan[i]].scanname, 6, 6), 2)
  legendastro, leg, textcol=0, pos=[0.8, 0.09]
  
  ;;fitexy, skdout[gdscan].taufinal1, skdout[gdscan].taufinal2, a, b, $
  ;;        x_sig=skdout[gdscan].etaufinal1, y_sig=skdout[gdscan].etaufinal2
  ;;legendastro, ['Fitexy const '+string(a,form='(F5.2)'), $
  ;;              'Fitexy slope '+string(b,form='(F4.2)')],textcol=250
  
  outplot, /close


; Plot new c1 against old c1

  wind, 1, 1, /free,xsize=1000, ysize=550 
  outfile = dir+'/test_allskd2_'+fname
  outplot, file=outfile, png=png, ps=ps
  my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
  
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
            title = 'NIKA2 '+runid+', c1 at '+ lambt, thick = 2, $
            pos=pp1[lamb-1, *], noerase=noerase, charsize=0.8
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[100,200], box=0, textcol=[100,200]
      a1 = where( kidpar[ kidall].array eq 1, na1)
      if na1 ne 0 then $
         oplot, kidpar[ kidall[a1]].c1_skydip, $
                newkidpar[ kidall[a1]].c1_skydip, psym = 4, col = 100
      a3 = where( kidpar[ kidall].array eq 3, na3)
      if na3 ne 0 then $
         oplot, kidpar[ kidall[a3]].c1_skydip, $
                newkidpar[ kidall[a3]].c1_skydip, psym = 4, col = 200
      gdk = where(kidpar[ kidall].c1_skydip gt 0. and $
                  newkidpar[ kidall].c1_skydip gt 0., ngdk)
      if ngdk ne 0 then begin
         slope = avg( newkidpar[ kidall[ gdk]].c1_skydip / $
                      kidpar[ kidall[ gdk]].c1_skydip)
         oplot, [0, c1lim], slope*[0, c1lim], psym = -3, col = 150
         xyouts, 500, 5000./lamb, 'Slope= '+string(slope, format = '(1F5.2)')
      endif

   endfor

   !p.multi=0
   outplot, /close

   
   wind, 1, 1, /free,xsize=1000, ysize=550 
  outfile = dir+'/test_allskd3_'+fname
  outplot, file=outfile, png=png, ps=ps
  my_multiplot, 2, 1, pp, pp1, /rev, gap_y=0.02, gap_x=0.07, xmargin=0.1, ymargin=0.1 ; 1e-6
  
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
      xrang = [0, 0.4]
      plot,1E-3/ newkidpar[ kidall].calib_fix_fwhm, newkidpar[ kidall].c1_skydip, $
           xrang = xrang, yrang = [0, c1lim], /xsty, /ysty, psym = 8, $
           xtitle = 'PS Response [Hz/(mJy/beam)]', $
           ytitle = 'Response [Hz/K] multi-scan',  $
           title = 'NIKA2 '+runid+', calib_fix_fwhm, c1 at '+ lambt, thick = 2, $
           pos=pp1[lamb-1, *], noerase=noerase, charsize=0.8
      if lamb eq 1 then legendastro, ['Array 1', 'Array 3'], psym=[4,4], col=[100,200], box=0, textcol=[100,200]
      a1 = where( kidpar[ kidall].array eq 1, na1)
      if na1 ne 0 then $
         oplot,1E-3/ newkidpar[ kidall[a1]].calib_fix_fwhm, $
               newkidpar[ kidall[a1]].c1_skydip, psym = 4, symsize = 2, col = 100
      a3 = where( kidpar[ kidall].array eq 3, na3)
      if na3 ne 0 then $
         oplot,1E-3/ newkidpar[ kidall[a3]].calib_fix_fwhm, $
               newkidpar[ kidall[a3]].c1_skydip, psym = 4, symsize = 1, col = 200
      gdk = where(newkidpar[ kidall].calib_fix_fwhm gt 0. and $
                  newkidpar[ kidall].c1_skydip gt 0., ngdk)
      if ngdk ne 0 then begin
         slope = avg( newkidpar[ kidall[ gdk]].c1_skydip * $
                      newkidpar[ kidall[ gdk]].calib_fix_fwhm)*1E3
         oplot, [0, 0.3], slope*[0, 0.3], psym = -3, col = 150
         xyouts, .20, 500, 'Slope= '+string(slope, format = '(1F7.0)')
      endif


   endfor

   !p.multi=0
   outplot, /close

end 
