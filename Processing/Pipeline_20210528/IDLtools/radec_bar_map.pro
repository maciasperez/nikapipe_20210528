;+
; NAME:
;       RADEC_BAR_MAP
; PURPOSE:
;       Create a radec map with a colorbar
; CALLING SEQUENCE:
;       radec_bar_map, map, header [,keyword options]
; OPTIONAL INPUT KEYWORDS:
;    range = min and max of the displayed map. If the range is larger
;            than the min and max of the map, the out of range area
;            appear grey
;    mapcont = same size as map, used for contours (map is used by default)
;    conts = the contours values in a vector
;    beam = then size of the beam in pixels
;    postscript = the name of the ps file created
;    title = the title of the map
;    bartitle = the title of the bar
;    type = set /type if you want radec cooordinates instead of delta
;           radec
;    bar/map charsize = charsize of the bar and map title
;    colconts = colors of the contours
;    thickconts = thickness of contours
;    anoconts = annotations of contours (string vector)
;    anothick = thickness of annotations
;
; AUTOR: R. ADAM
;
; MODIFICATIONS: 15/02/2014 - Add overplotted axis to mask the 0
;                             contour that appears even if not requested
;-

pro radec_bar_map, map, header, $
                   mapcont= mapcont, $
                   range=range,$
                   conts=conts,$
                   bis_conts=bis_conts, $
                   beam=beam, $
                   postscript=postscript, $
                   pdf=pdf, $
                   title=title, $
                   bartitle=bartitle,$
                   type=type,$
                   xtitle=xtitle,$
                   ytitle=ytitle,$
                   barcharsize=barcharsize,$
                   mapcharsize=mapcharsize,$
                   colconts=colconts,$
                   bis_colconts=bis_colconts, $
                   thickconts=thickconts,$
                   bis_thickcont=bis_thickcont, $ 
                   anotconts=anotconts,$
                   anothick=anothick,$
                   barcharthick=barcharthick,$
                   mapcharthick=mapcharthick,$
                   xdelta=xdelta, $
                   ydelta=ydelta

  if keyword_set(postscript) then begin
     filename = file_basename(postscript)
     dirname = file_dirname(postscript)
     pos = strpos(filename,'.ps')
     if pos gt 0 then filename=strmid(filename,0,pos)
     psout = dirname+ "/"+filename
  endif
  
  if keyword_set(pdf) then begin
     filename = file_basename(pdf)
     dirname = file_dirname(pdf)
     pos = strpos(filename,'.ps')
     if pos gt 0 then filename=strmid(filename,0,pos)
     pos = strpos(filename,'.pdf')
     if pos gt 0 then filename=strmid(filename,0,pos)
     pdfout = dirname+ "/"+filename
  endif  


  if not keyword_set(xdelta) then xdelta = 2
  if not keyword_set(ydelta) then ydelta = 1

  if not keyword_set(range) then range = minmax(map)
  if not keyword_set(conts) then conts = range[0] + (range[1]-range[0]) * [0.2,0.4,0.6,0.8]
  
  ;;pos=[0.8, 0.15, 0.83, 0.95]  ; bar position
  pos=[0.73, 0.15, 0.76, 0.95]  ; bar position
  levels = dindgen(128)/127*(range[1]-range[0]) + range[0]
  nbconts = n_elements(conts)
  if keyword_set(bis_conts) then bis_nbconts = n_elements(bis_conts)

  if keyword_set(postscript) then begin
     SET_PLOT, 'PS'
     device,/color, bits_per_pixel=256, filename=psout+'.ps'
     DEVICE, /HELVETICA  ; nice fonts
  endif
  if keyword_set(pdf) then begin
     SET_PLOT, 'PS'
     device,/color, bits_per_pixel=256, filename=pdfout+'.ps'
     DEVICE, /HELVETICA  ; nice fonts
  endif

  ;Plot the bar
  bar = Bindgen(128) ## Replicate(1B, 10) ;create bar
  bar = BytScl(bar,top=254)               ;normalize to the number of colors used
  cgImage, bar,pos=pos                    ;put the bar
  cgPlot, [0,1], range, /NoData, /NoErase, Position=pos,$ ;style=1 force exact range
          xTicks=1, YMinor=0, yTicklen=0.2, XMinor=0, xStyle=4, ystyle=4,title=bartitle,charsize=barcharsize,$
          charthick=barcharthick
  ;;Strange: 0 is a contour in this AXIS command
  ;;print, conts
  AXIS,YAXIS=1, YRANGE=range, YSTYLE = 1, yTICKlen=0.2,color=0,ythick=thickconts,$
       charthick=barcharthick, ycharsize=barcharsize ;Add marks where contour
  AXIS,YAXIS=1, YRANGE=range, YSTYLE = 1, yTICKlen=1, yticks=nbconts,ytickv=conts,$
       ytickname=replicate(' ',nbconts),color=colconts,ythick=thickconts,$
       charthick=barcharthick, ycharsize=barcharsize ;Add marks where contour
  if keyword_set(bis_conts) then AXIS, YAXIS=1, YRANGE=range, YSTYLE = 1, $
                                       yTICKlen=1, yticks=bis_nbconts,ytickv=bis_conts,$
                                       ytickname=replicate(' ',bis_nbconts),color=bis_colconts,$
                                       ythick=bis_thickcont,$
                                       charthick=barcharthick, ycharsize=barcharsize ;Add marks where contour
  
  ;;Remove the 0 contour by overploting if not requested
  if keyword_set(bis_conts) then w0 = where([bis_conts, conts] eq 0, nw0) $
  else w0 = where(conts eq 0, nw0) 
  c0rm = [range[0], 0, range[1]]
  col0 = -255*range[0]/(range[1]-range[0])
  if nw0 eq 0 and range[0] lt 0 and range[1] gt 0 then $
     AXIS, YAXIS=1, YRANGE=range, YSTYLE=1, yTICKlen=1, yticks=3,ytickv=c0rm,$
           ytickname=replicate(' ',3), col=col0, ythick=thickconts,$
           charthick=barcharthick, ycharsize=barcharsize 
  if nw0 eq 0 and range[0] lt 0 and range[1] gt 0 then $
     AXIS, YAXIS=1, YRANGE=range, YSTYLE=1, yTICKlen=0, yticks=3,ytickv=c0rm,$
           ytickname=replicate(' ',3), col=0, ythick=thickconts,$
           charthick=barcharthick, ycharsize=barcharsize 

; FXDadded color=1 otherwise scale does not show up
  AXIS, YAXIS=1, YRANGE=range,  YSTYLE = 1, yTICKlen=0, color=0, ythick=thickconts, charthick=barcharthick, ycharsize=barcharsize;add axis and marks
  cgPlotS, [pos(0), pos(0), pos(2), pos(2), pos(0)],$
           [pos(1), pos(3), pos(3), pos(1), pos(1)], /Normal,thick=thickconts ;box of the bar
  
  ;Plot the map
  TVLCT, cgCOLOR('gray', /TRIPLE), 255 ;set 255 to grey
;;;hview, header,/xd
  imcontour, map, header,type=type,title=title,levels=levels,nlevels=128,/fill,/noerase,$
             xtitle=xtitle,ytitle=ytitle,charsize=mapcharsize,$
             charthick=mapcharthick, xdelta=xdelta, ydelta=ydelta
  TVLCT, 255, 255, 255, 255     ;set 255 to white
if keyword_set( mapcont) then $
   contour, mapcont, /OVERPLOT,levels=conts,c_colors=colconts, $
            c_thick=thickconts,c_annotation=anotconts, C_CHARTHICK=anothick $
else $
   contour, map, /OVERPLOT,levels=conts,c_colors=colconts, $
   c_thick=thickconts,c_annotation=anotconts, C_CHARTHICK=anothick
  
  ;Plot the beam
  if keyword_set(beam) then POLYFILL, CIRCLE(3*beam/4,3*beam/4,beam/2), col = 255
  if keyword_set(beam) then PLOTS, CIRCLE(3*beam/4,3*beam/4,beam/2),col=0, thick=2

  if keyword_set(postscript) or keyword_set(pdf) then device,/close
  if keyword_set(postscript) or keyword_set(pdf) then SET_PLOT, 'X'
  if keyword_set(pdf) then ps2pdf_crop, pdfout

  return
end
