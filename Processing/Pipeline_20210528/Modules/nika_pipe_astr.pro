pro nika_pipe_astr, param, maps, header, save=save, use_source_astr=use_source_astr

  mkhdr,header,maps.a.jy        ;get header typique
  
  naxis = (size(maps.a.jy))[1:2]                                       ;Nb pixel along x and y
  cd = [[1.0,-0.0],[0.0,1.0]]                                          ;Rotation matrix but no rotation here
  cdelt = [-1.0, 1.0] * param.map.reso/3600.0                          ;Pixel size (ra along -1)
  crpix = ((size(maps.a.jy))[1:2] - 1)/2.0 + 1                         ;Ref pixel (central pixel (always odd nb))
  ra = ten(param.coord_pointing.ra[0],param.coord_pointing.ra[1],param.coord_pointing.ra[2])*15.0 ;RA in degrees
  dec = ten(param.coord_pointing.dec[0],param.coord_pointing.dec[1],param.coord_pointing.dec[2])  ;DEC in degrees
  if keyword_set(use_source_astr) then begin 
     ra = ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0 
     dec = ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2]) 
  endif
  crval = [ra, dec]                                                    ;ra dec of the ref pix
  ctype = ['RA---TAN','DEC--TAN']                                      ;Projection type
  
  ast = {naxis:naxis,cd:cd,cdelt:cdelt,crpix:crpix,crval:crval,ctype:ctype,$
         longpole:180.,latpole:90.0,pv2:[0.0,0.0]} ;astrometry
  putast, header, ast, equinox=2000, cd_type=0     ;astrometry in header
  
  if keyword_set(save) then begin
     file = param.output_dir+'/astrometry_'+param.name4file+'_'+param.version+'.fits'
     writefits, file, maps.A.Jy, header ;to be read with fits = mrdfits(file, 0, header)
     mwrfits, maps.A.var, file, header  ;to be read with fits = mrdfits(file, 1, header)
     mwrfits, maps.A.time, file, header ;to be read with fits = mrdfits(file, 2, header)
     mwrfits, maps.B.Jy, file, header   ;to be read with fits = mrdfits(file, 3, header)
     mwrfits, maps.B.var, file, header  ;to be read with fits = mrdfits(file, 4, header)
     mwrfits, maps.B.time, file, header ;to be read with fits = mrdfits(file, 5, header)
  endif

  return
end
