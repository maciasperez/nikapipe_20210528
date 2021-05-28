;+
;PURPOSE: Beam fitting of individual detectors
;
;INPUT: Parameter structures. 
;
;OUTPUT: plots
;
;KEYWORDS:
;
;LAST EDITION: 
;   27/11/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_beam_per_kid, param, anapar

  ;;------- Restore the maps
  restore, param.output_dir+'/map_per_KID_'+param.name4file+'_'+param.version+'.save'
  map_per_KID = map_per_KID
  
  ;;------- Restore the kidpars
  restore, param.output_dir+'/kidpar_'+param.name4file+'_'+param.version+'.save'
  w1mm = where(kidpar.array eq 1, nkid1mm)
  w2mm = where(kidpar.array eq 2, nkid2mm)
  won1mm = where(kidpar.type eq 1 and kidpar.array eq 1, non1mm)
  won2mm = where(kidpar.type eq 1 and kidpar.array eq 2, non2mm)
  num = kidpar[where(kidpar.type eq 1)].numdet

  ;;------- 1mm fit
  bg1mm = dblarr(non1mm)
  fluxe1mm = dblarr(non1mm)
  fwhmx1mm = dblarr(non1mm)
  fwhmy1mm = dblarr(non1mm)
  posx1mm = dblarr(non1mm)
  posy1mm = dblarr(non1mm)
  tilt1mm = dblarr(non1mm)

  count = 0
  for ikid=0, non1mm-1 do begin
     map = map_per_KID[count].jy
     var = map_per_KID[count].var

     nika_pipe_fit_beam, map, param.map.reso, $
                         coeff=coeff_gauss, var_map=var, /TILT, /silent, $
                         search_box=[60,60], center=[0,0]
     bg1mm[ikid] = coeff_gauss[0]
     fluxe1mm[ikid] =  coeff_gauss[1]
     fwhmx1mm[ikid] =  coeff_gauss[2]
     fwhmy1mm[ikid] =  coeff_gauss[3]
     posx1mm[ikid] =  coeff_gauss[4]
     posy1mm[ikid] =  coeff_gauss[5]
     tilt1mm[ikid] =  coeff_gauss[6]

     count = count+1
  endfor

  ;;------- 2mm fit
  bg2mm = dblarr(non2mm)
  fluxe2mm = dblarr(non2mm)
  fwhmx2mm = dblarr(non2mm)
  fwhmy2mm = dblarr(non2mm)
  posx2mm = dblarr(non2mm)
  posy2mm = dblarr(non2mm)
  tilt2mm = dblarr(non2mm)

  for ikid=0, non2mm-1 do begin
     map = map_per_KID[count].jy
     var = map_per_KID[count].var

     nika_pipe_fit_beam, map, param.map.reso, $
                         coeff=coeff_gauss, var_map=var, /TILT, /silent, $
                         search_box=[60,60], center=[0,0]
     bg2mm[ikid] = coeff_gauss[0]
     fluxe2mm[ikid] =  coeff_gauss[1]
     fwhmx2mm[ikid] =  coeff_gauss[2]
     fwhmy2mm[ikid] =  coeff_gauss[3]
     posx2mm[ikid] =  coeff_gauss[4]
     posy2mm[ikid] =  coeff_gauss[5]
     tilt2mm[ikid] =  coeff_gauss[6]

     count = count+1
  endfor

  fwhm1mm = sqrt(fwhmx1mm*fwhmy1mm)
  fwhm2mm = sqrt(fwhmx2mm*fwhmy2mm)










  ;;------- Plots
  mydevice = !d.name
  set_plot, 'ps'
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_KID_beams.ps'
  plot, fwhm1mm, xtitle='KID', ytitle='FWHM (arcsec)', xr=[0, max([non1mm,non2mm])], $
        yr=[0, max([fwhm1mm,fwhm2mm])], /nodata, charsize=1.5, charthick=3
  oplot, fwhm1mm, psym=8, col=250
  oplot, fwhm2mm, psym=8, col=150
  legendastro,['1.25 mm', '2.05 mm'], $
              charsize=1, charthick=3, col=[250,150], psym=[8,8], thick=[1,1], symsize=[1,1], $
              linestyle=[0,2],/right, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_KID_beams'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_KID_offset.ps'
  plot, posx1mm, posy1mm, xtitle='X offset (arcsec)', ytitle='Y offset (arcsec)', xr=minmax([posx1mm, posx2mm]), $
        yr=minmax([posy1mm, posy2mm]), /nodata, charsize=1.5, charthick=3
  oplot, posx1mm, posy1mm, psym=8, col=250
  oplot, posx2mm, posy2mm, psym=8, col=150
  legendastro,['1.25 mm', '2.05 mm'], $
              charsize=1, charthick=3, col=[250,150], psym=[8,8], thick=[1,1], symsize=[1,1], $
              linestyle=[0,2],/right, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_KID_offset'
  
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_KID_flux.ps'
  plot, fluxe1mm, xtitle='KID', ytitle='Flux (Jy)', xr=[0, max([non1mm,non2mm])],$
        yr=[0, max([fluxe1mm, fluxe2mm])], /nodata, charsize=1.5, charthick=3
  oplot, fluxe1mm, psym=8, col=250
  oplot, fluxe2mm, psym=8, col=150
  legendastro,['1.25 mm', '2.05 mm'], $
              charsize=1, charthick=3, col=[250,150], psym=[8,8], thick=[1,1], symsize=[1,1], $
              linestyle=[0,2],/right, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_KID_flux'

  ;;---------- Histogram
  loadct,4, /silent
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_KID_flux_histo.ps'
  cgHistoplot, fluxe1mm*1e-3, $
               ;nbin=40, $
               binsize=0.2,$
               /FILLPOLYGON, $
               POLYCOLOR=220, $
               datacolorname=160, $
               thick=2, $
               xtitle='Flux (kHz)', $
               ytitle='Number of KID', $
               max_val=25, $
               maxinput=(stddev(fluxe1mm)*3+median(fluxe1mm))*1e-3,$
               mininput=1e-5,$
               charthick=3, charsize=1.5
  cgHistoplot, fluxe2mm*1e-3, $
               ;nbin=40, $
               binsize=0.1,$
               /LINE_FILL, $
               line_thick=0.1, $
               spacing=0.02, $
               thick=2, $
               ORIENTATION=[45,45], $
               POLYCOLOR=100, $
               datacolorname=130, $
               /oplot
  legendastro,['2mm', '1mm'],linestyle=[0,0],psym=[0,0],col=[100,220],thick=[5,5],symsize=[1,1],spacing=[1,1],pspacing=[2,2],/top,/right,box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_KID_flux_histo'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_KID_beams_histo.ps'
  cgHistoplot, fwhm1mm, $
               binsize=0.2,$
               /FILLPOLYGON, $
               POLYCOLOR=220, $
               datacolorname=160, $
               thick=2, $
               xtitle='Beam gaussian FWHM (arcsec)', $
               ytitle='Number of KID', $
               maxinput=(stddev(fwhm2mm)*3+median(fwhm2mm)),$
               mininput=(-stddev(fwhm1mm)*3+median(fwhm1mm)),$
               charthick=3, charsize=1.5
  cgHistoplot, fwhm2mm, $
               binsize=0.2,$
               /LINE_FILL, $
               line_thick=0.1, $
               spacing=0.02, $
               thick=2, $
               ORIENTATION=[45,45], $
               POLYCOLOR=100, $
               datacolorname=130, $
               /oplot
  legendastro,['2mm', '1mm'],linestyle=[0,0],psym=[0,0],col=[100,220],thick=[5,5],symsize=[1,1],spacing=[1,1],pspacing=[2,2],/top,/right,box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_KID_beams_histo'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_KID_offset_histo.ps'
  cgHistoplot, sqrt(posx1mm^2 + posy1mm^2), $
               binsize=0.1,$
               /FILLPOLYGON, $
               POLYCOLOR=220, $
               datacolorname=160, $
               thick=2, $
               xtitle='Center offset (arcsec)', $
               ytitle='Number of KID', $
               maxinput=(stddev(sqrt(posx1mm^2 + posy1mm^2))*3+median(sqrt(posx1mm^2 + posy1mm^2))),$
               mininput=1e-5,$
               charthick=3, charsize=1.5
  cgHistoplot, sqrt(posx2mm^2 + posy2mm^2), $
               binsize=0.1,$
               /LINE_FILL, $
               line_thick=0.1, $
               spacing=0.02, $
               thick=2, $
               ORIENTATION=[45,45], $
               POLYCOLOR=100, $
               datacolorname=130, $
               /oplot
  legendastro,['2mm', '1mm'],linestyle=[0,0],psym=[0,0],col=[100,220],thick=[5,5],symsize=[1,1],spacing=[1,1],pspacing=[2,2],/top,/right,box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_KID_offset_histo'
  loadct,39, /silent
  set_plot, mydevice

  return
end
