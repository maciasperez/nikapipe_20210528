;+
; NAME:
;       compare_radec_map
; PURPOSE:
;       Create a radec map with a colorbar overploted by contours of
;       another map
; CALLING SEQUENCE:
;       compare_radec_map, map1, map2, header1,header2, reso, fov, coord
; 
; PARAMETERS: map1,2 = the map (square maps)
;             header1,2 = the header created with puast.pro for
;                         example
;             reso = the resolution of your plotted maps
;             fov = the field of view
;             coord = the coordinates of the center (degrees, for example 
;                     [ten(13,47,30.5)*15.0, ten(-11,45,10)]
;
; CONSTRAINTS: the ploted map has to be contained in the two other maps
;
; KEYWORDS: see radec_bar_map.pro
;
; AUTOR: R. ADAM
;-

pro compare_radec_map, mapmap1, mapmap2, header1, header2, reso, fov, coord,$
                       range=range,conts1=conts1, conts2=conts2,$
                       beam=beam, postscript=postscript, title=title, bartitle=bartitle,type=type,$
                       xtitle=xtitle,ytitle=ytitle,barcharsize=barcharsize,mapcharsize=mapcharsize,$
                       colconts1=colconts1,thickconts1=thickconts1,anotconts1=anotconts1,anothick1=anothick1,$
                       colconts2=colconts2,thickconts2=thickconts2,anotconts2=anotconts2,anothick2=anothick2,$
                       barcharthick=barcharthick,mapcharthick=mapcharthick

  map1=mapmap1                  ;Otherwise it modifies the original map
  map2=mapmap2

;Get astrometry from header
  EXTAST, header1, astr1
  EXTAST, header2, astr2
  
  reso0 = {a:astr1.cdelt[1]*3600,$
           b:astr2.cdelt[1]*3600} ;arcsec
  npt0 = {a:astr1.naxis[1],$
          b:astr2.naxis[1]}     ;pixel nb
  ref0 = {a:astr1.crpix,$
          b:astr2.crpix}        ;pixel
  coord0 = {a:astr1.crval*3600,$
            b:astr2.crval*3600} ;radec (deg)
  
 ;Rescale map to the same reso (erreur:reso/npix = +/- 1 pixel less than 1/10 arcsec)
  map1 = congrid(map1, npt0.a*reso0.a/reso, npt0.a*reso0.a/reso)
  map2 = congrid(map2, npt0.b*reso0.b/reso, npt0.b*reso0.b/reso)

  npt = {a:(size(map1))[1],b:(size(map2))[1]}
  ref = {a:ref0.a*reso0.a/reso ,b:ref0.b*reso0.b/reso}

  ;Rescale map to the same fov

  npixx = {a:[npt.a/2 - (fov/2 - (coord0.a[0] - 3600*coord[0]))/reso,$
                 npt.a/2 - (fov/2 - (3600*coord[0] - coord0.a[0]))/reso],$
           b:[npt.b/2 - (fov/2 - (coord0.b[0] - 3600*coord[0]))/reso,$
                 npt.b/2 - (fov/2 - (3600*coord[0] - coord0.b[0]))/reso]}

  npixy = {a:[npt.a/2 - (fov/2 + (coord0.a[1] - 3600*coord[1]))/reso,$
                 npt.a/2 - (fov/2 + (3600*coord[1] - coord0.a[1]))/reso],$
           b:[npt.b/2 - (fov/2 + (coord0.b[1] - 3600*coord[1]))/reso,$
                 npt.b/2 - (fov/2 + (3600*coord[1] - coord0.b[1]))/reso]}

  map1 = map1[npixx.a[0]:npt.a-npixx.a[1],npixy.a[0]:npt.a-npixy.a[1]]
  map2 = map2[npixx.b[0]:npt.b-npixx.b[1],npixy.b[0]:npt.b-npixy.b[1]]

  ;in case error due to pixel, set to same size
  nax = max((size(MAP1))[1:2])
  map1 = congrid(map1, nax,nax)
  map2 = congrid(map2, nax,nax)

  ;Do a header for the new maps
  mkhdr,header,map1                       ;get header typique
  naxis = (size(map1))[1:2]               ;Nb pixel along x and y
  cd = [[1.0,-0.0],[0.0,1.0]]             ;Rotation matrix but no rotation here
  cdelt = [-1.0, 1.0] * reso/3600.0       ;Pixel size (ra along -1)
  crpix = ((size(map1))[1:2] - 1)/2.0 + 1 ;Ref pixel (central pixel (always odd nb))
  crval = coord                    ;ra dec of the ref pix
  ctype = ['RA---TAN','DEC--TAN']         ;Projection type
  ast = {naxis:naxis,cd:cd,cdelt:cdelt,crpix:crpix,crval:crval,ctype:ctype,$
         longpole:180.,latpole:90.0,pv2:[0.0,0.0]} ;astrometry
  putast, header, ast, equinox=2000, cd_type=0     ;astrometry in header
  
  ;Overplot 


if not keyword_set(conts2) then conts2= min(map2) + (max(map2)-min(map2)) * [0.25,0.5,0.75]


if keyword_set(postscript) then SET_PLOT, 'PS'
if keyword_set(postscript) then device,/color, bits_per_pixel=256, filename=postscript
  radec_bar_map, map1, header,range=range,conts=conts1,colconts=colconts1,$
                 thickconts=thickconts1,anotconts=anotconts1,anothick=anothick1, beam=beam,type=type,$
                 title=title,bartitle=bartitle,xtitle=xtitle,ytitle=ytitle,$
                 barcharsize=barcharsize,mapcharsize=mapcharsize, barcharthick=barcharthick,$
                 mapcharthick=mapcharthick
  contour, map2, /OVERPLOT,thick=5,levels=conts2, c_thick=thickconts2, c_colors=colconts2,$
           C_ANNOTATION=anotconts2,c_CHARTHICK=anothick2
  if keyword_set(postscript) then device,/close
  if keyword_set(postscript) then SET_PLOT, 'X'

  return
end

