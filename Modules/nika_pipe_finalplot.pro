
pro nika_pipe_finalplot, param, map_combi, profile=profile

;################## SAVE THE MAP WITH ASTROMETRY ########################
  mkhdr,header,map_combi.a.jy   ;get header typique
  
  naxis = (size(map_combi.a.jy))[1:2]                                  ;Nb pixel along x and y
  cd = [[1.0,-0.0],[0.0,1.0]]                                          ;Rotation matrix but no rotation here
  cdelt = [-1.0, 1.0] * param.map.reso/3600.0                          ;Pixel size (ra along -1)
  crpix = ((size(map_combi.a.jy))[1:2] - 1)/2.0 + 1                    ;Ref pixel (central pixel (always odd nb))
  ra = ten(param.coord.ra[0],param.coord.ra[1],param.coord.ra[2])*15.0 ;RA in degrees
  dec = ten(param.coord.dec[0],param.coord.dec[1],param.coord.dec[2])  ;DEC in degrees
  crval = [ra, dec]                                                    ;ra dec of the ref pix
  ctype = ['RA---TAN','DEC--TAN']                                      ;Projection type
  
  ast = {naxis:naxis,cd:cd,cdelt:cdelt,crpix:crpix,crval:crval,ctype:ctype,$
         longpole:180.,latpole:90.0,pv2:[0.0,0.0]} ;astrometry
  putast, header, ast, equinox=2000, cd_type=0     ;astrometry in header
  
  name4file = STRJOIN(STRSPLIT(param.source, /EXTRACT), '_') ;removes empty space
  file = !nika.SAVE_DIR+'/astrometry_'+name4file+'.fits'
  writefits, file, map_combi.A.Jy, header ;to be read with fits = mrdfits(file, 0, header)
  mwrfits, map_combi.A.var, file, header  ;to be read with fits = mrdfits(file, 1, header)
  mwrfits, map_combi.B.Jy, file, header   ;to be read with fits = mrdfits(file, 2, header)
  mwrfits, map_combi.B.var, file, header  ;to be read with fits = mrdfits(file, 3, header)
  
;################## DEFINES CUTOFF ########################

;In case we ask to make a map larger than possible
if param.plotmap.fov gt min([param.map.size_ra, param.map.size_dec]) then param.plotmap.fov = min([param.map.size_ra, param.map.size_dec])

;Define the cutoff at 2 stddev min
level_cut = 4.0;*1000                ;level of cutoff for variance

  mapa = map_combi.a.jy
  mapb = map_combi.b.jy
  vara = map_combi.a.var
  varb = map_combi.b.var
  vara[where(vara le 0)] = 10*max(vara) ;undef var is max of variance
  varb[where(varb le 0)] = 10*max(varb)

  cuta = vara 
  cutb = varb 
  wcuta = where(filter_image(vara,fwhm=15/param.map.reso,/ALL_PIXELS) gt level_cut*min(filter_image(vara,fwhm=10/param.map.reso,/ALL_PIXELS)), nwcuta)
  if nwcuta ne 0 then cuta[wcuta] = -1
  wcuta = where(filter_image(vara,fwhm=15/param.map.reso,/ALL_PIXELS) le level_cut*min(filter_image(vara,fwhm=10/param.map.reso,/ALL_PIXELS)), nwcuta)
  if nwcuta ne 0 then cuta[wcuta] = 1 

  wcutb = where(filter_image(varb,fwhm=15/param.map.reso,/ALL_PIXELS) gt level_cut*min(filter_image(varb,fwhm=10/param.map.reso,/ALL_PIXELS)), nwcutb)
  if nwcutb ne 0 then cutb[wcutb] = -1
  wcutb = where(filter_image(varb,fwhm=15/param.map.reso,/ALL_PIXELS) le level_cut*min(filter_image(varb,fwhm=10/param.map.reso,/ALL_PIXELS)), nwcutb)
  if nwcutb ne 0 then cutb[wcutb] = 1 
  
  mapa = 1000*filter_image(mapa,fwhm=param.plotmap.relob/param.map.reso) ;to mJy
  mapb = 1000*filter_image(mapb,fwhm=param.plotmap.relob/param.map.reso)

  wcuta = where(cuta ne 1, nwcuta)
  if nwcuta ne 0 then mapa[wcuta] = 1e10
  wcutb = where(cutb ne 1, nwcutb)
  if nwcutb ne 0 then mapb[wcutb] = 1e10

  n_map_x = (size(mapa))[1]
  n_map_y = (size(mapa))[2]
  mapa = mapa[n_map_x/2-param.plotmap.fov/2/param.map.reso:n_map_x/2+param.plotmap.fov/2/param.map.reso, n_map_y/2-param.plotmap.fov/2/param.map.reso:n_map_y/2+param.plotmap.fov/2/param.map.reso]
  mapb = mapb[n_map_x/2-param.plotmap.fov/2/param.map.reso:n_map_x/2+param.plotmap.fov/2/param.map.reso, n_map_y/2-param.plotmap.fov/2/param.map.reso:n_map_y/2+param.plotmap.fov/2/param.map.reso]
  n_map_x = (size(mapa))[1]
  n_map_y = (size(mapa))[2]
  
  x_carte = (dindgen(n_map_x) - n_map_x/2) * param.map.reso
  y_carte = (dindgen(n_map_y) - n_map_y/2) * param.map.reso
  
;################## Header map a and b ########################

  mkhdr,header_a,mapa
  naxis = (size(mapa))[1:2]                                            ;Nb pixel along x and y
  cd = [[1.0,-0.0],[0.0,1.0]]                                          ;Rotation matrix but no rotation here
  crpix = ((size(mapa))[1:2] - 1)/2.0 + 1                              ;Reference pixel
  cdelt = [-1.0, 1.0] * param.map.reso/3600.0                          ;Pixel size
  ra = ten(param.coord.ra[0],param.coord.ra[1],param.coord.ra[2])*15.0 ;RA in degrees
  dec = ten(param.coord.dec[0],param.coord.dec[1],param.coord.dec[2])  ;DEC in degrees
  crval = [ra, dec]                                                    ;ra dec
  ctype = ['RA---TAN','DEC--TAN']                                      ;Projection type
  ast_a = {naxis:naxis,cd:cd,crpix:crpix,cdelt:cdelt,crval:crval,ctype:ctype,$
         longpole:180.,latpole:90.0,pv2:[0.0,0.0]}
  putast, header_a, ast_a, equinox=2000

  mkhdr,header_b,mapb
  naxis = (size(mapb))[1:2]                                            ;Nb pixel along x and y
  cd = [[1.0,-0.0],[0.0,1.0]]                                          ;Rotation matrix but no rotation here
  crpix = ((size(mapb))[1:2] - 1)/2.0 + 1                              ;Reference pixel
  cdelt = [-1.0, 1.0] * param.map.reso/3600.0                          ;Pixel size
  ra = ten(param.coord.ra[0],param.coord.ra[1],param.coord.ra[2])*15.0 ;RA in degrees
  dec = ten(param.coord.dec[0],param.coord.dec[1],param.coord.dec[2])  ;DEC in degrees
  crval = [ra, dec]                                                    ;ra dec
  ctype = ['RA---TAN','DEC--TAN']                                      ;Projection type
  ast_b = {naxis:naxis,cd:cd,crpix:crpix,cdelt:cdelt,crval:crval,ctype:ctype,$
         longpole:180.,latpole:90.0,pv2:[0.0,0.0]}
  putast, header_b, ast_b, equinox=2000

;################## New variables ########################

  lamb = strmid(strtrim(!nika.lambda, 2),0,4)                ;1.25 and 2.05 string
  beam = {A:sqrt(12.5^2 + (param.plotmap.relob)^2),$
          B:sqrt(18.5^2 + (param.plotmap.relob)^2)} ;arcsec
  locbeam = {A:3*beam.A/4.0 - param.plotmap.fov/2,$ ;arcsec
             B:3*beam.B/4.0 - param.plotmap.fov/2}

  TVLCT, cgCOLOR('gray', /TRIPLE), 255 ;set 255 to grey
  TVLCT, 255, 255, 255, 1       ;set 1 to white

  col = {A:replicate(!p.background, n_elements(param.plotmap.cont.A)),$
         B:replicate(!p.background, n_elements(param.plotmap.cont.B))}

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ MAP OLD SCHOOL @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;  SET_PLOT, 'PS'
;  !p.font = -1
;  device,/color, bits_per_pixel=256, filename=!nika.plot_dir+'/'+name4file+'_map_1mm.ps'
;  dispim_bar, mapa,xtitle='-!4Da!X (arcsecond)',ytitle='!4Dd!X (arcsecond)',xmap=x_carte,ymap=y_carte,/aspect,title=param.source+' at '+lamb[0]+' mm (mJy/Beam)',crange=param.plotmap.range.A,levels=param.plotmap.cont.A,topcolour=!p.background,c_colors=col.A
;  POLYFILL, CIRCLE(locbeam.A, locbeam.A, beam.A/2.0), col = 1
;  PLOTS, CIRCLE(locbeam.A, locbeam.A, beam.A/2.0),col=!p.color, thick=2
;  device,/close
;  SET_PLOT, 'X'
;  
;  SET_PLOT, 'PS'
;  !p.font = -1
;  device,/color, bits_per_pixel=256, filename=!nika.plot_dir+'/'+name4file+'_map_2mm.ps'
;  dispim_bar, mapb,xtitle='-!4Da!X (arcsecond)',ytitle='!4Dd!X (arcsecond)',xmap=x_carte,ymap=y_carte,/aspect,title=param.source+' at '+lamb[1]+' mm (mJy/Beam)',crange=param.plotmap.range.B,levels=param.plotmap.cont.B,topcolour=!p.background,c_colors=col.B
;  POLYFILL, CIRCLE(locbeam.B, locbeam.B, beam.B/2.0), col = 1
;  PLOTS, CIRCLE(locbeam.B, locbeam.B, beam.B/2.0),col=!p.color, thick=2
;  device,/close
;  SET_PLOT, 'X'

;@@@@@@@@@@@@@@@@@@@@@@@@@@ MAP WITH REAL COORDINATES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 
  radec_bar_map, mapa, header_a, range=param.plotmap.range.A, conts=param.plotmap.cont.A, $
                 beam=beam.A/param.map.reso, postscript=!nika.plot_dir+'/'+name4file+'_map_coord_1mm.ps', $
                 title=param.source+' at '+lamb[0]+' mm', bartitle='mJy/Beam', $
                 /type,xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)'
                 ;xtitle='arcsec', ytitle='arcsec'

  radec_bar_map, mapb, header_b, range=param.plotmap.range.B, conts=param.plotmap.cont.B, $
                 beam=beam.B/param.map.reso, postscript=!nika.plot_dir+'/'+name4file+'_map_coord_2mm.ps', $
                 title=param.source+' at '+lamb[1]+' mm', bartitle='mJy/Beam',$
                 /type,xtitle='!4a!X!I2000!N (hr)', ytitle='!4d!X!I2000!N (degree)'
                 ;xtitle='arcsec', ytitle='arcsec'

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ CASE WE WANT THE PROFILE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

  if keyword_set(profile) then begin
     SET_PLOT, 'PS'
     !p.font = -1
     device,/color, bits_per_pixel=256, filename=!nika.plot_dir+'/profile_'+name4file+'_1mm.ps'
     plot, profile.A.r, profile.A.y*1000, psym=1, xrange=[0,param.plotmap.fov/2], yrange=param.plotmap.range.A,xtitle='radius (arcsec)', ytitle='flux (mJy/beam)',title=param.source+' profile at '+lamb[0]+' mm'
     oploterror,profile.A.r,1000*profile.A.y,1000*sqrt(profile.A.var),ERRTHICK=3,ERRCOLOR=250,psym=3
     device,/close
     SET_PLOT, 'X'

     SET_PLOT, 'PS'
     !p.font = -1
     device,/color, bits_per_pixel=256, filename=!nika.plot_dir+'/profile_'+name4file+'_2mm.ps'
     plot, profile.B.r, profile.B.y*1000, psym=1, xrange=[0,param.plotmap.fov/2], yrange=param.plotmap.range.B,xtitle='radius (arcsec)', ytitle='flux (mJy/beam)',title=param.source+' profile at '+lamb[1]+' mm'
     oploterror,profile.B.r,1000*profile.B.y,1000*sqrt(profile.B.var),ERRTHICK=3,ERRCOLOR=250,psym=3
     device,/close
     SET_PLOT, 'X'
  endif

  return
end
