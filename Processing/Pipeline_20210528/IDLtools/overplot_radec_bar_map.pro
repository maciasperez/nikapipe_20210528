;+
; NAME:
;       OVERPLOT_RADEC_BAR_MAP
; PURPOSE:
;       Create a radec map with a colorbar and overplot the contours
;       from another map. The field of view (fov), the resolustion
;       (reso) and the coordinates of the center (coord) are given by
;       the user.
; CALLING SEQUENCE:
;       radec_bar_map, map1, header1, map2, header2, fov, reso, coord, [,keyword options]
; AUTHOR: R. ADAM
;-

pro overplot_radec_bar_map, map1,$                      ;Map plotted in color
                            head1,$                     ;Header of map1 containing astrometry
                            map2,$                      ;Map plotted as contours
                            head2,$                     ;Header of map2 containing astrometry
                            fov,$                       ;Field of view of the plotted map
                            reso,$                      ;Resolution of the plotted map
                            coord,$                     ;Center coordinates of the plotted map
                            postscript=postscript,$     ;name of the .ps plotted map
                            pdf=pdf,$                   ;name of the .ps plotted map
                            title=title,$               ;title of the map
                            bartitle=bartitle,$         ;title of the color bar
                            xtitle=xtitle,$             ;title of the x axis
                            ytitle=ytitle,$             ;title of the y axis
                            barcharthick=barcharthick,$ ;thickness of the bar title
                            mapcharthick=mapcharthick,$ ;thickness of the map title
                            barcharsize=barcharsize,$   ;size of the bar title
                            mapcharsize=mapcharsize,$   ;size of the map title
                            range=range,$               ;range of the map1
                            conts1=conts1,$             ;contours of the maps 1
                            colconts1=colconts1,$       ;color of the contours of map1
                            thickcont1=thickcont1,$     ;thicknedd of the contours of map1
                            anotconts1=anotconts1,$     ;anotation of the contours of map1
                            anothick1=anothick1,$       ;anotation thickness of the contours of map1
                            conts2=conts2,$             ;idem for map2
                            colconts2=colconts2,$       ;idem for map2
                            thickconts2=thickconts2,$   ;idem for map2
                            anotconts2=anotconts2,$     ;idem for map2
                            anothick2=anothick2,$       ;idem for map2
                            beam=beam,$                 ;size of the plotted beam (FWHM)
                            type=type,$                 ;set this if you want absolute coordinates
                            bg1=bg1,$                   ;value of the undefined part of the map (effective 
                            bg2=bg2,$                   ;if the maps are undefined in the required FOV)
                            xdelta=xdelta,$             ;Write x coordinates for 1/xdelta ticks (if crowdy)
                            ydelta=ydelta,$             ;Write y coordinates for 1/ydelta ticks (if crowdy)
                            white_cont_neg=white_cont_neg, $
                            dash_cont_neg=dash_cont_neg

  if not keyword_set(bg1) then bg1 = 0.0
  if not keyword_set(bg2) then bg2 = 0.0

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

 ;;------- Get astrometry from header
  EXTAST, head1, astr1
  EXTAST, head2, astr2
  
  reso1_x = -astr1.cdelt[0]*3600L ;resolution (arcsec)
  reso1_y = astr1.cdelt[1]*3600L  ;resolution (arcsec)
  reso2_x = -astr2.cdelt[0]*3600L ;
  reso2_y = astr2.cdelt[1]*3600L  ;
  npt1_x = astr1.naxis[0]         ;pixel nb
  npt1_y = astr1.naxis[1]         ;pixel nb
  npt2_x = astr2.naxis[0]         ;
  npt2_y = astr2.naxis[1]         ;
  ref1 = astr1.crpix              ;reference pixel
  ref2 = astr2.crpix              ;
  coord1 = astr1.crval            ;coord of ref pixel (deg)
  coord2 = astr2.crval            ;
  
  shift1 = [-1.0*cos(coord[1]*!pi/180.0),1.0]*(coord - coord1)*3600L ;Shift with resp to the new map
  shift2 = [-1.0*cos(coord[1]*!pi/180.0),1.0]*(coord - coord2)*3600L ;
  
  offsc1_x = reso1_x*(ref1[0] - ((npt1_x-1)/2.0+1)) ;Shift between central pixel and reference pixel
  offsc1_y = reso1_y*(ref1[1] - ((npt1_y-1)/2.0+1))
  offsc2_x = reso2_x*(ref2[0] - ((npt2_x-1)/2.0+1))
  offsc2_y = reso2_y*(ref2[1] - ((npt2_y-1)/2.0+1))
  
  ;;------- Define the grid
  npt = 2*long(fov/reso/2.0) + 1 ;Forced to be odd
  x1_f = replicate(1,npt)##((dindgen(npt)*reso - (fov/2.0-(npt1_x*reso1_x)/2.0 - shift1[0] - offsc1_x))/reso1_x)
  y1_f = replicate(1,npt)# ((dindgen(npt)*reso - (fov/2.0-(npt1_y*reso1_y)/2.0 - shift1[1] - offsc1_y))/reso1_y)
  x2_f = replicate(1,npt)##((dindgen(npt)*reso - (fov/2.0-(npt2_x*reso2_x)/2.0 - shift2[0] - offsc2_x))/reso2_x)
  y2_f = replicate(1,npt)# ((dindgen(npt)*reso - (fov/2.0-(npt2_y*reso2_y)/2.0 - shift2[1] - offsc2_y))/reso2_y)
  
  map1_f = interpolate(map1, x1_f, y1_f, missing=bg1)
  map2_f = interpolate(map2, x2_f, y2_f, missing=bg2)
  
  ;;Make a header for the new map
  mkhdr,head,map1_f                                                          ;get header typique
  naxis = (size(map1_f))[1:2]                                                ;Nb pixel along x and y
  cd = [[1.0,-0.0],[0.0,1.0]]                                                ;Rotation matrix but no rotation here
  cdelt = [-1.0, 1.0] * reso/3600.0                                          ;Pixel size (ra along -1)
  crpix = ((size(map1_f))[1:2] - 1)/2.0 + 1                                  ;Ref pixel (central, always odd nb)
  crval = coord                                                              ;ra dec of the ref pix
  ctype = ['RA---TAN','DEC--TAN']                                            ;Projection type
  if astr1.ctype[0] eq 'GLON-TAN' then ctype = ['GLON-TAN', 'GLAT-TAN']
  ast = {naxis:naxis,cd:cd,cdelt:cdelt,crpix:crpix,crval:crval,ctype:ctype,$ ;astrometry
         longpole:180.,latpole:90.0,pv2:[0.0,0.0]}                           ;astrometry
  putast, head, ast, equinox=2000, cd_type=0                                 ;astrometry in header
  
  ;;Overplot
  if keyword_set(beam) then beam_plot = beam/reso

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

  radec_bar_map, map1_f, head, title=title, bartitle=bartitle, xtitle=xtitle, ytitle=ytitle,$
                 barcharthick=barcharthick, mapcharthick=mapcharthick, $
                 barcharsize=barcharsize, mapcharsize=mapcharsize, range=range,$
                 conts=conts1, colconts=colconts1, thickcont=thickcont1, $ 
                 bis_conts=conts2, bis_colconts=colconts2, bis_thickcont=thickcont2, $ 
                 anotconts=anotconts1, anothick=anothick1,$
                 beam=beam_plot, type=type, xdelta=xdelta, ydelta=ydelta
  
  if keyword_Set(conts2) and keyword_set(dash_cont_neg) then C_LINESTYLE=(conts2 LT 0.0)*2

  contour, map2_f, /OVERPLOT,thick=thickconts2,levels=conts2,c_colors=colconts2,c_annotation=anotconts2,$
           c_charthick=anothick2, C_LINESTYLE=C_LINESTYLE

  if keyword_set(white_cont_neg) then begin
     wneg = where(conts2 lt 0, nwneg)
     conts2_neg = conts2[wneg]
     if nwneg ne 0 then begin
        contour, map2_f, /OVERPLOT,thick=thickconts2,levels=conts2_neg,c_colors=cgcolor('Snow'),$
                 c_annotation=anotconts2,c_charthick=anothick2
     endif
  endif

  if keyword_set(postscript) or keyword_set(pdf) then device,/close
  if keyword_set(postscript) or keyword_set(pdf) then SET_PLOT, 'X'
  if keyword_set(pdf) then ps2pdf_crop, pdfout
       
  return
end

