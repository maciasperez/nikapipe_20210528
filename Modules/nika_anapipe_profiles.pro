;+
;PURPOSE: Compute and plot profiles centered on defined positions
;
;INPUT: The pipeline parameter structure
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS:
;
;LAST EDITION: 
;   01/10/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_profiles, param, anapar
  mydevice = !d.name
  set_plot, 'ps'

  ;;Distance rescaling of R.A. differences : cos(declinaison)
  ra_corr = cos(ten(param.coord_map.dec[0], $
                    param.coord_map.dec[1], $
                    param.coord_map.dec[2])*!pi/180.0)

  ;;------- Get the maps
  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)+$
            anapar.cor_zerolevel.A
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',1,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)+$
            anapar.cor_zerolevel.B
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',1,head_2mm,/SILENT)
  
  EXTAST, head_1mm, astr
  reso = astr.cdelt[1]*3600
  coord_ref = astr.crval        ;coord of ref pixel (deg)
  refpix = astr.crpix           ;reference pixel
  nx = astr.naxis[0]            ;pixel nb along x
  ny = astr.naxis[1]            ;pixel nb along y

  coord_map = coord_ref + [refpix[0]-((nx-1)/2.0+1), -refpix[1]+((ny-1)/2.0+1)]*reso/3600.0

  ;;------- Loop over all centers
  if anapar.profile.method eq 'default' then anapar.profile.nb_prof = 1 ;force only 1 profile form the map center
  
  for ic=0, anapar.profile.nb_prof - 1 do begin

     ;;------- Case of default: only 1 profile centered on [0,0]
     if anapar.profile.method eq 'default' then center = [0.0, 0.0]
     
     ;;------- Case of center shift given directly as offsets
     if anapar.profile.method eq 'offset' then center = anapar.profile.offset[ic,*]
     
     ;;------- Case of center shift computed from coordinates
     if anapar.profile.method eq 'coord' then begin
        center = [(-ten(anapar.profile.coord[ic].ra[0],anapar.profile.coord[ic].ra[1],anapar.profile.coord[ic].ra[2])*15.0 + coord_map[0])*ra_corr, $
                  ten(anapar.profile.coord[ic].dec[0],anapar.profile.coord[ic].dec[1],anapar.profile.coord[ic].dec[2]) - coord_map[1]]*3600.0
     endif

     ;;------- Case of bug
     if anapar.profile.method ne 'coord' and anapar.profile.method ne 'offset' and $
        anapar.profile.method ne 'default'then begin
        message, 'The method is either "coord" (you give the center R.A. Dec. coordinates)'
        message, 'or "offset" (you give the arcsec offset with respect to the map center)'
        message, 'or "default" (only one profile centered on the map center)'
     endif
     
     ;;------ R.A. Dec. coordinates
     ra = SIXTY((coord_map[0] - center[0]/3600.0/ra_corr)/15.0)
     dec = SIXTY(coord_map[1] + center[1]/3600.0)
     
     ;;------- Compute the profiles
     maps_1mm = {Jy:map_1mm, var:noise_1mm^2}
     maps_2mm = {Jy:map_2mm, var:noise_2mm^2}
     nika_pipe_profile, reso, maps_1mm, flux_prof1mm, nb_prof=anapar.profile.nb_pt, center=center
     nika_pipe_profile, reso, maps_2mm, flux_prof2mm, nb_prof=anapar.profile.nb_pt, center=center
     
     if anapar.profile.save_fits eq 'yes' then begin 
        profiles1mm = [[flux_prof1mm.r],[flux_prof1mm.y],[sqrt(flux_prof1mm.var)]]
        profiles2mm = [[flux_prof2mm.r],[flux_prof2mm.y],[sqrt(flux_prof2mm.var)]]
        mkhdr, header, profiles1mm
        fxaddpar, header, 'CONTENT1', 'Radius', '[arcsec]'
        fxaddpar, header, 'CONTENT2', 'Flux profile', '[Jy/beam]'
        fxaddpar, header, 'CONTENT3', 'Standard deviation profile', '[Jy/beam]'
        fxaddpar, header, 'CENTER', +strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),2)+'m'+strtrim(trim(ra[2]),2)+'s '+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+'arcmin'+strtrim(trim(dec[2]),2)+'arcsec', '[R.A.-Dec.]'
        head1mm = header
        head2mm = header
        if ic eq 0 then mwrfits, profiles1mm, param.output_dir+'/PROFILE_1mm_'+param.name4file+'.fits', head1mm, /create, /silent else  mwrfits, profiles1mm, param.output_dir+'/PROFILE_1mm_'+param.name4file+'.fits', head1mm, /silent
        if ic eq 0 then mwrfits, profiles2mm, param.output_dir+'/PROFILE_2mm_'+param.name4file+'.fits', head2mm, /create, /silent else  mwrfits, profiles2mm, param.output_dir+'/PROFILE_2mm_'+param.name4file+'.fits', head2mm, /silent
     endif

     ;;------- Plot the beam profile
     if anapar.profile.yr1mm[ic,0] ne 0 or anapar.profile.yr1mm[ic,1] ne 0 then $
        yrange1mm = anapar.profile.yr1mm[ic,*]
     if anapar.profile.yr2mm[ic,0] ne 0 or anapar.profile.yr2mm[ic,1] ne 0 then $
        yrange2mm = anapar.profile.yr2mm[ic,*]
     if anapar.profile.xr[ic,0] ne 0 or anapar.profile.xr[ic,1] ne 0 then xrange = anapar.profile.xr[ic,*] else $
        xrange = [0,max(flux_prof1mm.r, /nan)]

     ;;Profile 1mm
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_centered_on_'+strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),2)+'m'+strtrim(trim(ra[2]),2)+'s_'+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+'arcmin'+strtrim(trim(dec[2]),2)+'arcsec_1mm.ps'
     ploterror, flux_prof1mm.r, 1e3*flux_prof1mm.y,  1e3*sqrt(flux_prof1mm.var), $
                xtitle='Offset from the source center (arcsec)', ytitle='Flux (mJy/beam)',$
                psym=1, ystyle=1, xstyle=1, xr=xrange, yrange=yrange1mm, /nodata,$
                charsize=1.5, charthick=3
     oploterror, flux_prof1mm.r, 1e3*flux_prof1mm.y,  1e3*sqrt(flux_prof1mm.var), $
                 col=50, errcolor=100,errthick=2,psym=8, symsize=0.7
     legendastro, ['Profile centered on R.A.: '+strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),   2)+'m'+strtrim(trim(ra[2]), 2)+'s  Dec.: '+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+"'"+strtrim(trim(dec[2]),2)+'"'], box=0, /right, /top, charthick=3
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_centered_on_'+strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),2)+'m'+strtrim(trim(ra[2]),2)+'s_'+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+'arcmin'+strtrim(trim(dec[2]),2)+'arcsec_1mm'

     ;;Profile 2mm
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_centered_on_'+strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),2)+'m'+strtrim(trim(ra[2]),2)+'s_'+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+'arcmin'+strtrim(trim(dec[2]),2)+'arcsec_2mm.ps'
     ploterror,  flux_prof2mm.r,  1e3*flux_prof2mm.y,  1e3*sqrt(flux_prof2mm.var), $
                xtitle='Offset from the source center (arcsec)', ytitle='Flux (mJy/beam)',$
                psym=1, ystyle=1, xstyle=1, xr=xrange, yrange=yrange2mm,/nodata,$
                charsize=1.5, charthick=3
     oploterror, flux_prof2mm.r,  1e3*flux_prof2mm.y,  1e3*sqrt(flux_prof2mm.var), $
                 col=50, errcolor=100,errthick=2,psym=8, symsize=0.7
     legendastro, ['Profile centered on R.A.: '+strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),   2)+'m'+strtrim(trim(ra[2]), 2)+'s  Dec.: '+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+"'"+strtrim(trim(dec[2]),2)+'"'], box=0, /right, /top, charthick=3
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_centered_on_'+strtrim(long(ra[0]), 2)+'h'+strtrim(long(ra[1]),2)+'m'+strtrim(trim(ra[2]),2)+'s_'+strtrim(long(dec[0]),2)+'deg'+strtrim(long(dec[1]),2)+'arcmin'+strtrim(trim(dec[2]),2)+'arcsec_2mm'
  endfor

  set_plot, mydevice

  return
end
