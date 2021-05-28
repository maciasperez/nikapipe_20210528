
pro kidpar2fp, kidpar, output_dir=output_dir, nickname=nickname, png=png, ps=ps

if not keyword_set(output_dir) then output_dir = "."
if not keyword_set(nickname)   then nickname   = "kidpar"

w1    = where( kidpar.type eq 1, nw1, compl=unvalid_kids)
w3    = where( kidpar.type eq 3, nw3)
w5    = where( kidpar.type eq 5, nw5)
if nw5 ne 0 then kidpar[w5].plot_flag = 1
wplot = where( kidpar.plot_flag eq 0, nwplot)

xcenter_plot = avg( kidpar[wplot].nas_x)
ycenter_plot = avg( kidpar[wplot].nas_y)
xra_plot     = xcenter_plot + [-1,1]*max( abs(kidpar[wplot].nas_x-xcenter_plot))*1.2
yra_plot     = ycenter_plot + [-1,1]*max( abs(kidpar[wplot].nas_y-ycenter_plot))*1.2
yra_plot     = yra_plot + [0, (max(yra_plot)-min(yra_plot))*0.2]
get_x0y0, kidpar[wplot].nas_x, kidpar[wplot].nas_y, xc0, yc0, ww
ibol_ref = wplot[ww]

;;----------------------------------------------------------------------------------------------
;; Offsets only
wind, 3, 1, /large, /free
!p.position=0
!p.multi=0
outplot, file=output_dir+"/"+nickname+"_offsets_FP", png=png, ps=ps
plot, kidpar[wplot].nas_x, kidpar[wplot].nas_y, $
      xra=xra_plot, yra=yra_plot, /xs, /ys, /iso, $
      xtitle='Arcsec', ytitle='Arcsec', $
      chars=1.3, title=nickname+" / Nasmyth Offsets", psym=1
xyouts, kidpar[wplot].nas_x, kidpar[wplot].nas_y, strtrim( kidpar[wplot].numdet,2)
legendastro, ['Nvalid='+strtrim(nw1,2)], /right, box=0, charsize=1
outplot, /close
loadct, 39

;;----------------------------------------------------------------------------------------------
;; Sensitivity
phi = dindgen(100)/100.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
zrange = avg( kidpar[wplot].sensitivity_decorr) +[-3,3]*stddev( kidpar[wplot].sensitivity_decorr)
zrange = zrange > 0.d0

wind, 3, 1, /large, /free
!p.position=0
!p.multi=0
outplot, file=output_dir+"/"+nickname+"_sensit_FP", png=png, ps=ps
matrix_plot, [kidpar[wplot].nas_x], [kidpar[wplot].nas_y], [kidpar[wplot].sensitivity_decorr], $
             units='mJy.s!u1/2!n/Beam', xra=xra_plot, yra=yra_plot, /xs, /ys, /iso, $
             outcolor=outcolor, xtitle='Arcsec', ytitle='Arcsec', zrange=zrange, my_simsize=0.1, $
             chars=1.3, title=nickname+" / Sensitivity"
for i=0, n_elements(wplot)-1 do begin
   ikid = wplot[i]
   xx1 = 0.5*kidpar[ikid].sigma_x*cosphi
   yy1 = 0.5*kidpar[ikid].sigma_y*sinphi
   x1  =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
   y1  =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
   oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=outcolor[i] ; thick=2
endfor
legendastro, ['Median sens.: '+num2string( median( kidpar[wplot].sensitivity_decorr)), $
              'Median FWHM: '+num2string(median( kidpar[wplot].fwhm))], $
             box=0, charsize=1
legendastro, ['Nvalid='+strtrim(nw1,2), $
              'Beam display diameter: sigma'], /right, box=0, charsize=1
outplot, /close
loadct, 39

;; Calibration
phi = dindgen(100)/100.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
zrange = avg( kidpar[wplot].calib) +[-3,3]*stddev( kidpar[wplot].calib)
zrange = zrange > 0.d0

wind, 3, 1, /large, /free
!p.position=0
!p.multi=0
outplot, file=output_dir+"/"+nickname+"_calib_FP", png=png, ps=ps
matrix_plot, [kidpar[wplot].nas_x], [kidpar[wplot].nas_y], [kidpar[wplot].calib], $
             units='Jy/Hz/Beam', xra=xra_plot, yra=yra_plot, /xs, /ys, /iso, $
             outcolor=outcolor, xtitle='Arcsec', ytitle='Arcsec', zrange=zrange, my_simsize=0.1, $
             chars=1.3, title=nickname+" / Calibration"
for i=0, n_elements(wplot)-1 do begin
   ikid = wplot[i]
   xx1 = 0.5*kidpar[ikid].sigma_x*cosphi
   yy1 = 0.5*kidpar[ikid].sigma_y*sinphi
   x1  =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
   y1  =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
   oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=outcolor[i] ; thick=2
endfor
legendastro, ['Median Calib.: '+num2string( median( kidpar[wplot].calib)), $
              'Median FWHM: '+num2string(median( kidpar[wplot].fwhm))], $
             box=0, charsize=1
legendastro, ['Nvalid='+strtrim(nw1,2), $
              'Beam display diameter: sigma'], /right, box=0, charsize=1
outplot, /close
loadct, 39

;; Noise
phi = dindgen(100)/100.*2*!dpi
cosphi = cos(phi)
sinphi = sin(phi)
zrange = avg( kidpar[wplot].noise) +[-3,3]*stddev( kidpar[wplot].noise)
zrange = zrange > 0.d0

wind, 3, 1, /large, /free
!p.position=0
!p.multi=0
outplot, file=output_dir+"/"+nickname+"_noise_FP", png=png, ps=ps
matrix_plot, [kidpar[wplot].nas_x], [kidpar[wplot].nas_y], [kidpar[wplot].noise], $
             units='Hz.Hz!u-1/2!n', xra=xra_plot, yra=yra_plot, /xs, /ys, /iso, $
             outcolor=outcolor, xtitle='Arcsec', ytitle='Arcsec', zrange=zrange, my_simsize=0.1, $
             chars=1.3, title=nickname+" / Noise"
for i=0, n_elements(wplot)-1 do begin
   ikid = wplot[i]
   xx1 = 0.5*kidpar[ikid].sigma_x*cosphi
   yy1 = 0.5*kidpar[ikid].sigma_y*sinphi
   x1  =  cos(kidpar[ikid].theta)*xx1 - sin(kidpar[ikid].theta)*yy1
   y1  =  sin(kidpar[ikid].theta)*xx1 + cos(kidpar[ikid].theta)*yy1
   oplot, [kidpar[ikid].nas_x+x1], [kidpar[ikid].nas_y+y1], col=outcolor[i] ; thick=2
endfor
legendastro, ['Median Noise: '+num2string( median( kidpar[wplot].noise)), $
              'Median FWHM: '+num2string(median( kidpar[wplot].fwhm))], $
             box=0, charsize=1
legendastro, ['Nvalid='+strtrim(nw1,2), $
              'Beam display diameter: sigma'], /right, box=0, charsize=1
outplot, /close
loadct, 39


;;-------------------------------------------------------------------------------------------
;; Beam stats
wind, 1, 1, /free, ys=900, xs=600
outplot, file=output_dir+"/"+nickname+"_beamstats", png=png, ps=ps
my_multiplot, 1, 4, /rev, pp, pp1, /dry
data_str = {a:kidpar[wplot].fwhm_x, b:kidpar[wplot].fwhm_y}
np_histo, data_str, xhist, yhist, gpar, $
          colorplot=[70,200], position=pp1[0,*], /blend, /fit, /fill, /nolegend
leg_txt = ['FWHMx median: '+num2string( median(kidpar[wplot].fwhm_x)), $
           'FWHMy median: '+num2string( median(kidpar[wplot].fwhm_y))]
leg_txt = [leg_txt, $
           "", $
           'FWHMx avg: '+num2string(gpar[0,1]), $
           'FWHMy avg: '+num2string(gpar[1,1])]
legendastro, leg_txt, /right, box=0, chars=1.3

ff = "FWHM"
array2 = kidpar[wplot].fwhm
!p.position = pp1[1,*]
np_histo, array2, xhist, yhist, gpar, fcol=70, /fit, /nolegend, /noerase
legendastro, ['Nvalid='+strtrim(nw1,2), $
              'Nplot='+strtrim(nwplot,2)], chars=2, $
             box=0, textcol=[!p.color, 70]
legendastro, [ff, $
              'Median: '+strtrim( string( median(array2), format="(F6.2)"),2), $
              'Avg: '+strtrim( string(gpar[1], format="(F6.2)"),2), $
              'Stddev: '+strtrim( string(gpar[2], format="(F6.2)"), 2)], $
             box=0, chars=2, /right

ff = "Ellipt"
array2 = kidpar[wplot].fwhm
!p.position = pp1[2,*]
np_histo, array2, xhist, yhist, gpar, fcol=70, /fit, /nolegend, /noerase
legendastro, ['Nvalid='+strtrim(nw1,2), $
              'Nplot='+strtrim(nwplot,2)], chars=2, $
             box=0, textcol=[!p.color, 70]
legendastro, [ff, $
              'Median: '+strtrim( string( median(array2), format="(F6.2)"),2), $
              'Avg: '+strtrim( string(gpar[1], format="(F6.2)"),2), $
              'Stddev: '+strtrim( string(gpar[2], format="(F6.2)"), 2)], $
             box=0, chars=2, /right

ff = "a_peak"
array2 = kidpar[wplot].fwhm
!p.position = pp1[3,*]
np_histo, array2, xhist, yhist, gpar, fcol=70, /fit, /nolegend, /noerase
legendastro, ['Nvalid='+strtrim(nw1,2), $
              'Nplot='+strtrim(nwplot,2)], chars=2, $
             box=0, textcol=[!p.color, 70]
legendastro, [ff, $
              'Median: '+strtrim( string( median(array2), format="(F6.2)"),2), $
              'Avg: '+strtrim( string(gpar[1], format="(F6.2)"),2), $
              'Stddev: '+strtrim( string(gpar[2], format="(F6.2)"), 2)], $
             box=0, chars=2, /right
outplot, /close

end
