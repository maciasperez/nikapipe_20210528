;+
;PURPOSE: Plot the maps per scan
;
;INPUT: The mapping and analysis parameters structures.
;
;OUTPUT: do the plot
;
;LAST EDITION: 
;   29/09/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_mapperscan, param, anapar
  mydevice = !d.name
  
  ;;------- Restore the maps
  maps_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',4,head_1mm,/SILENT)
  maps_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',4,head_2mm,/SILENT)
  
  ;;------- Get the resolution of the maps, assume same header at both wavelengths
  EXTAST, head_1mm, astr1mm
  reso = astr1mm.cdelt[1]*3600
  nx = astr1mm.naxis[0]
  ny = astr1mm.naxis[1]
  x_carte = dindgen(nx)*reso - (nx/2-0.5)*reso
  y_carte = dindgen(ny)*reso - (ny/2-0.5)*reso
  nscan = n_elements(maps_1mm[0,0,*])

  ;;------- Optimal ligne and collumn
  Nb_line = long(sqrt(nscan+1))
  Nb_col = long(sqrt(nscan+1))
  while Nb_line*Nb_col lt nscan do Nb_col = Nb_col+1
  
  nobar = 1
  if anapar.mapperscan.allbar eq 'yes' then nobar = 0

  ;;------- Set the range to the user value if provided
  range1mm = minmax(maps_1mm)   ;Default range if the extreme values
  range2mm = minmax(maps_2mm)
  if anapar.mapperscan.range1mm[0] ne 0 and anapar.mapperscan.range1mm[1] ne 0 then $
     range1mm = anapar.mapperscan.range1mm 
  if anapar.mapperscan.range2mm[0] ne 0 and anapar.mapperscan.range2mm[1] ne 0 then $
     range2mm = anapar.mapperscan.range2mm 
  
  ;;------- Do map 1mm
  set_plot, 'ps'
  for iscan=0, nscan-1 do begin
     name_title = param.scan_list[iscan]
     if anapar.mapperscan.allbar eq 'yes' then name_title +=' - Jy/beam'
     map = maps_1mm[*,*,iscan]
     
     if iscan eq 0 then device,/color, bits_per_pixel=256, $
                               filename=param.output_dir+'/'+param.name4file+'_MapPerScan1mm.ps'
     !p.multi = [Nb_line*Nb_col-iscan,Nb_col,Nb_line]
     dispim_bar, filter_image(map, fwhm=anapar.mapperscan.relob.a/reso, /all), $
                 /aspect, /nocont, nobar=nobar,$
                 bar_separation=0,$
                 xmap=x_carte, $
                 ymap=y_carte, $
                 title=name_title, $
                 xtitle='Offset (arcsec)', $
                 ytitle='Offset (arcsec)', $
                 charsize=0.5,$
                 BARSZ_CHARS=1,$
                 crange=range1mm, $
                 /silent
     !p.multi=0
     
     ;;------- Plot the bar
     if anapar.mapperscan.allbar eq 'no' then begin
        if iscan eq nscan-1 then begin
           !p.multi = [Nb_line*Nb_col-1-iscan,Nb_col,Nb_line]
           pos = [0.1, 0.1, 0.4, 0.9]
           bar = BytScl(Bindgen(128) ## Replicate(1B, 10),top=254) ;create a color bar
           cgImage, bar,pos=pos                                    ;plot it
           cgPlot, [0,1], range1mm, /NoData, /NoErase, Position=pos, $
                   xTicks=1, YMinor=0, yTicklen=0.2, XMinor=0, xStyle=4, ystyle=4,$
                   title='(Jy/beam)',charsize=1
           AXIS,YAXIS=1, YRANGE=range1mm, YSTYLE = 1, yTICKlen=1, yticks=2,ytickv=range1mm,$
                ytickname=replicate(' ',2),color=0
           AXIS, YAXIS=1, YRANGE=range1mm,  YSTYLE=1, yTICKlen=0.2, color=1 ;add axis and marks
           cgPlotS, [pos(0), pos(0), pos(2), pos(2), pos(0)],$
                    [pos(1), pos(3), pos(3), pos(1), pos(1)], /Normal ;box of the bar
           !p.multi=0
        endif
     endif
     if iscan eq nscan-1 then device,/close
     if iscan eq nscan-1 then ps2pdf_crop, param.output_dir+'/'+param.name4file+'_MapPerScan1mm'
  endfor

  ;;------- Do map 2mm
  set_plot, 'ps'
  for iscan=0, nscan-1 do begin
     name_title = param.scan_list[iscan]
     if anapar.mapperscan.allbar eq 'yes' then name_title +=' - Jy/beam'
     map = maps_2mm[*,*,iscan]
     
     if iscan eq 0 then device,/color, bits_per_pixel=256, $
                               filename=param.output_dir+'/'+param.name4file+'_MapPerScan2mm.ps'
     !p.multi = [Nb_line*Nb_col-iscan,Nb_col,Nb_line]
     dispim_bar, filter_image(map, fwhm=anapar.mapperscan.relob.b/reso, /all), $
                 /aspect, /nocont, nobar=nobar,$
                 bar_separation=0,$
                 xmap=x_carte, $
                 ymap=y_carte, $
                 title=name_title, $
                 xtitle='Offset (arcsec)', $
                 ytitle='Offset (arcsec)', $
                 charsize=0.5,$
                 BARSZ_CHARS=1,$
                 crange=range2mm, /silent
     !p.multi=0
     
     ;;------- Plot the bar
     if anapar.mapperscan.allbar eq 'no' then begin
        if iscan eq nscan-1 then begin
           !p.multi = [Nb_line*Nb_col-1-iscan,Nb_col,Nb_line]
           pos = [0.1, 0.1, 0.4, 0.9]
           bar = BytScl(Bindgen(128) ## Replicate(1B, 10),top=254) ;create a color bar
           cgImage, bar,pos=pos                                    ;plot it
           cgPlot, [0,1], range2mm, /NoData, /NoErase, Position=pos, $
                   xTicks=1, YMinor=0, yTicklen=0.2, XMinor=0, xStyle=4, ystyle=4,$
                   title='(Jy/beam)',charsize=1
           AXIS,YAXIS=1, YRANGE=range2mm, YSTYLE = 1, yTICKlen=1, yticks=2,ytickv=range2mm,$
                ytickname=replicate(' ',2),color=0
           AXIS, YAXIS=1, YRANGE=range2mm,  YSTYLE=1, yTICKlen=0.2, color=1 ;add axis and marks
           cgPlotS, [pos(0), pos(0), pos(2), pos(2), pos(0)],$
                    [pos(1), pos(3), pos(3), pos(1), pos(1)], /Normal ;box of the bar
           !p.multi=0
        endif
     endif
     if iscan eq nscan-1 then device,/close
     if iscan eq nscan-1 then ps2pdf_crop, param.output_dir+'/'+param.name4file+'_MapPerScan2mm'
  endfor

  set_plot, mydevice

  return
end
