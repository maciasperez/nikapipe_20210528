;+
;PURPOSE: Plot the maps per detector
;
;INPUT: The mapping and analysis parameters structures.
;
;OUTPUT: do the plot
;
;LAST EDITION: 
;   29/09/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_mapperkid, param, anapar
  mydevice = !d.name

  my_unit = anapar.mapperkid.unit

  ;;------- Restore the maps
  restore, param.output_dir+'/map_per_KID_'+param.name4file+'_'+param.version+'.save'
  map_per_KID = map_per_KID
  
  ;;------- Restore the kidpars
  restore, param.output_dir+'/kidpar_'+param.name4file+'_'+param.version+'.save'
  w1mm = where(kidpar.array eq 1, nkid1mm)
  w2mm = where(kidpar.array eq 2, nkid2mm)
  won1mm = where(kidpar.type eq 1 and kidpar.array eq 1, non1mm)
  won2mm = where(kidpar.type eq 1 and kidpar.array eq 2, non2mm)

  ;;------- Axis
  nx = (size(map_per_kid[0].Jy))[1]
  ny = (size(map_per_kid[0].Jy))[2]
  x_carte = dindgen(nx)*param.map.reso - (nx/2)*param.map.reso
  y_carte = dindgen(ny)*param.map.reso - (ny/2)*param.map.reso
  
  nobar = 1
  if anapar.mapperkid.allbar eq 'yes' then nobar = 0

  ;;------- Optimal ligne and collumn
  Nb_line1mm = long(sqrt(non1mm+1))
  Nb_col1mm = long(sqrt(non1mm+1))
  while Nb_line1mm*Nb_col1mm lt non1mm do Nb_col1mm = Nb_col1mm+1
  
  Nb_line2mm = long(sqrt(non2mm+1))
  Nb_col2mm = long(sqrt(non2mm+1))
  while Nb_line2mm*Nb_col2mm lt non2mm do Nb_col2mm = Nb_col2mm+1
  
  ;;------- Set the range to the user value if provided
  range1mm = minmax(map_per_kid[0:non1mm-1].Jy) ;Default range if the extreme values
  range2mm = minmax(map_per_kid[non1mm:*].Jy)
  if anapar.mapperkid.range1mm[0] ne 0 and anapar.mapperkid.range1mm[1] ne 0 then $
     range1mm = anapar.mapperkid.range1mm 
  if anapar.mapperkid.range2mm[0] ne 0 and anapar.mapperkid.range2mm[1] ne 0 then $
     range2mm = anapar.mapperkid.range2mm 
  
  ;;------- Get a bar map
  bar_map1mm = replicate(1, 4) # dindgen(300)/(299)*(range1mm[1]-range1mm[0]) + range1mm[0]
  bar_map2mm = replicate(1, 4) # dindgen(300)/(299)*(range2mm[1]-range2mm[0]) + range2mm[0]
  xbar = dblarr(4)
  ybar1mm = dindgen(300)/(299)*(range1mm[1]-range1mm[0]) + range1mm[0]
  ybar2mm = dindgen(300)/(299)*(range2mm[1]-range2mm[0]) + range2mm[0]
  
  ;;------- Do map
  temp = Nb_col1mm
  Nb_col1mm = Nb_line1mm
  Nb_line1mm = temp

  temp = Nb_col2mm
  Nb_col2mm = Nb_line2mm
  Nb_line2mm = temp

  count = 0
  count1mm = 0
  count2mm = 0
  set_plot, 'ps'
  for ikid=0, nkid1mm+nkid2mm-1 do begin
     if kidpar[ikid].type eq 1 then begin
        ;;------- 1mm plot
        case kidpar[ikid].array of
           1: begin
              name_title = ' KID '+strtrim(kidpar[ikid].numdet, 2)
              if anapar.mapperkid.allbar eq 'yes' then name_title +=' - Jy/beam'
              map = map_per_KID[count].jy
              
              if count1mm eq 0 then device,/color, bits_per_pixel=256, $
                                           filename=param.output_dir+'/'+param.name4file+'_MapPerKID1mm.ps'
              pos = cgLayout([Nb_line1mm,Nb_col1mm], XGap=0, YGap=0, oxmargin=[0,20])
              pcg = pos[*,count1mm]
              !p.position = pcg
              if count1mm+1 le (Nb_col1mm-1)*Nb_line1mm then xtitle=0 else xtitle='Offs (")'
              if double(count1mm)/double(Nb_line1mm) ne long(count1mm)/long(Nb_line1mm) then ytitle=0 else ytitle='Offs (")'
              if count1mm+1 le (Nb_col1mm-1)*Nb_line1mm then nnax=1 else nnax=0
              if double(count1mm)/double(Nb_line1mm) ne long(count1mm)/long(Nb_line1mm) then nnay=1 else nnay=0

              dispim_bar, filter_image(map, fwhm=anapar.mapperkid.relob.a/param.map.reso, /all), $
                          /aspect, /nocont, nobar=nobar,$
                          bar_separation=0,$
                          xmap=x_carte, $
                          ymap=y_carte, $
                          xtitle=xtitle, $
                          ytitle=ytitle, $
                          charsize=0.2,$
                          BARSZ_CHARS=1,$
                          crange=range1mm,$
                          /silent, $
                          noerase=1, $
                          no_number_xaxis=nnax, $
                          no_number_yaxis=nnay
              cgText, pcg[0], pcg[1]+(pcg[3]-pcg[1])/20, $
                      Alignment=0, /Normal, name_title, Charsize=0.25, color=255

              if anapar.mapperkid.allbar eq 'no' then begin
                 if count1mm eq non1mm-1 then begin
                    posb = [max(pos[0,*])+(pos[0,1]-pos[0,0]), pos[1,count1mm], max(pos[0,*])+(1.5*pos[0,1]-pos[0,0]), pos[3,0]]
                    bar = BytScl(Bindgen(128) ## Replicate(1B, 10), top=254) ;create a color bar
                    cgImage, bar, pos=posb, /noerase                         ;plot it
                    cgPlot, [0,1], range1mm, /NoData, /NoErase, Position=posb, $
                            xTicks=1, YMinor=0, yTicklen=0.2, XMinor=0, xStyle=4, ystyle=4,$
                            title=my_unit,charsize=0.75, charthick=2
                    AXIS,YAXIS=1, YRANGE=range1mm, YSTYLE = 1, yTICKlen=1, yticks=2,ytickv=range1mm,$
                         ytickname=replicate(' ',2),color=0, charthick=2,charsize=0.75
                    AXIS, YAXIS=1, YRANGE=range1mm,  YSTYLE=1, yTICKlen=0.2, color=1, charthick=2,charsize=0.75 ;add axis and marks
                    cgPlotS, [posb(0), posb(0), posb(2), posb(2), posb(0)],$
                             [posb(1), posb(3), posb(3), posb(1), posb(1)], /Normal ;box of the bar
                 endif
              endif
              count1mm += 1
              if count1mm eq non1mm then device,/close
              if count1mm eq non1mm then ps2pdf_crop, param.output_dir+'/'+param.name4file+'_MapPerKID1mm'
           end
           
           ;;------- 2mm plot           
           2: begin
              name_title = ' KID '+strtrim(kidpar[ikid].numdet, 2)
              if anapar.mapperkid.allbar eq 'yes' then name_title +=' - Jy/beam'

              map = map_per_KID[count].jy
              
              if count2mm eq 0 then device,/color, bits_per_pixel=256, $
                                           filename=param.output_dir+'/'+param.name4file+'_MapPerKID2mm.ps'
              pos = cgLayout([Nb_line2mm,Nb_col2mm], XGap=0, YGap=0, oxmargin=[0,20])
              pcg = pos[*,count2mm]
              !p.position = pcg
              if count2mm+1 le (Nb_col2mm-1)*Nb_line2mm then xtitle=0 else xtitle='Offs (")'
              if double(count2mm)/double(Nb_line2mm) ne long(count2mm)/long(Nb_line2mm) then ytitle=0 else ytitle='Offs (")'
              if count2mm+1 le (Nb_col2mm-1)*Nb_line2mm then nnax=1 else nnax=0
              if double(count2mm)/double(Nb_line2mm) ne long(count2mm)/long(Nb_line2mm) then nnay=1 else nnay=0
              dispim_bar, filter_image(map, fwhm=anapar.mapperkid.relob.b/param.map.reso, /all), $
                          /aspect, /nocont, nobar=nobar,$
                          bar_separation=0,$
                          xmap=x_carte, $
                          ymap=y_carte, $
                          xtitle=xtitle, $
                          ytitle=ytitle, $
                          charsize=0.2,$
                          BARSZ_CHARS=1,$
                          crange=range2mm,$
                          /silent, $
                          noerase=1, $
                          no_number_xaxis=nnax, $
                          no_number_yaxis=nnay
              cgText, pcg[0], pcg[1]+(pcg[3]-pcg[1])/20, $
                      Alignment=0, /Normal, name_title, Charsize=0.25, color=255

              if anapar.mapperkid.allbar eq 'no' then begin
                 if count2mm eq non2mm-1 then begin
                    posb = [max(pos[0,*])+(pos[0,1]-pos[0,0]), pos[1,count2mm], max(pos[0,*])+(1.5*pos[0,1]-pos[0,0]), pos[3,0]]
                    bar = BytScl(Bindgen(128) ## Replicate(1B, 10), top=254) ;create a color bar
                    cgImage, bar, pos=posb, /noerase                         ;plot it
                    cgPlot, [0,1], range2mm, /NoData, /NoErase, Position=posb, $
                            xTicks=1, YMinor=0, yTicklen=0.2, XMinor=0, xStyle=4, ystyle=4,$
                            title=my_unit,charsize=0.75, charthick=2
                    AXIS,YAXIS=1, YRANGE=range2mm, YSTYLE = 1, yTICKlen=1, yticks=2,ytickv=range2mm,$
                         ytickname=replicate(' ',2),color=0, charthick=2,charsize=0.75
                    AXIS, YAXIS=1, YRANGE=range2mm,  YSTYLE=1, yTICKlen=0.2, color=1, charthick=2,charsize=0.75 ;add axis and marks
                    cgPlotS, [posb(0), posb(0), posb(2), posb(2), posb(0)],$
                             [posb(1), posb(3), posb(3), posb(1), posb(1)], /Normal ;box of the bar
                 endif
              endif
              count2mm += 1
              if count2mm eq non2mm then device,/close
              if count2mm eq non2mm then ps2pdf_crop, param.output_dir+'/'+param.name4file+'_MapPerKID2mm'

;;             name_title = 'numdet '+strtrim(kidpar[ikid].numdet, 2)
;;             if anapar.mapperkid.allbar eq 'yes' then name_title +=' - Jy/beam'
;;             map = map_per_KID[count].jy
;;
;;             if count2mm eq 0 then device,/color, bits_per_pixel=256, $
;;                                          filename=param.output_dir+'/'+param.name4file+'_MapPerKID2mm.ps'
;;             !p.multi = [Nb_line2mm*Nb_col2mm-count2mm,Nb_col2mm,Nb_line2mm]
;;             dispim_bar, filter_image(map, fwhm=anapar.mapperkid.relob.b/param.map.reso, /all), $
;;                         /aspect, /nocont, nobar=nobar,$
;;                         bar_separation=0,$
;;                         xmap=x_carte, $
;;                         ymap=y_carte, $
;;                         title=name_title, $
;;                         xtitle='(arcsec)', $
;;                         ytitle='(arcsec)', $
;;                         charsize=0.25,$
;;                         BARSZ_CHARS=1,$
;;                         crange=range2mm, $
;;                         /silent
;;             !p.multi=0
;;             
;;             if anapar.mapperkid.allbar eq 'no' then begin
;;                if count2mm eq non2mm-1 then begin
;;                   !p.multi = [Nb_line2mm*Nb_col2mm-count2mm-1,Nb_col2mm,Nb_line2mm]
;;                   pos = [0.1, 0.1, 0.4, 0.9]
;;                   bar = BytScl(Bindgen(128) ## Replicate(1B, 10),top=254) ;create a color bar
;;                   cgImage, bar,pos=pos                                    ;plot it
;;                   cgPlot, [0,1], range2mm, /NoData, /NoErase, Position=pos, $
;;                           xTicks=1, YMinor=0, yTicklen=0.2, XMinor=0, xStyle=4, ystyle=4,$
;;                           title='(Jy/beam)',charsize=0.5
;;                   AXIS,YAXIS=1, YRANGE=range2mm, YSTYLE = 1, yTICKlen=1, yticks=2,ytickv=range2mm,$
;;                        ytickname=replicate(' ',2),color=0
;;                   AXIS, YAXIS=1, YRANGE=range2mm,  YSTYLE=1, yTICKlen=0.2, color=1 ;add axis and marks
;;                   cgPlotS, [pos(0), pos(0), pos(2), pos(2), pos(0)],$
;;                            [pos(1), pos(3), pos(3), pos(1), pos(1)], /Normal ;box of the bar
;;                   !p.multi=0
;;                endif
;;             endif
;;             count2mm += 1
;;             if count2mm eq non2mm then device,/close
;;             if count2mm eq non2mm then ps2pdf_crop, param.output_dir+'/'+param.name4file+'_MapPerKID2mm'
           end
        endcase
        
        count += 1
     endif
  endfor
  set_plot, mydevice
  
  return
end
