;+
;PURPOSE: Provide diffuse source photometry centered on given
;         positions within a given radius
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS:
;
;LAST EDITION: 
;   7/10/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_difphoto, param, anapar

  ;;------- Get the maps
  maps_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',4,head_1mm,/SILENT)
  noises_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',6,head_1mm,/SILENT)
  maps_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',4,head_2mm,/SILENT)
  noises_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',6,head_2mm,/SILENT)

  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)+$
            anapar.cor_zerolevel.A
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',2,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)+$
            anapar.cor_zerolevel.B
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',2,head_2mm,/SILENT)
  
  EXTAST, head_1mm, astr
  reso = astr.cdelt[1]*3600
  coord_ref = astr.crval        ;coord of ref pixel (deg)
  refpix = astr.crpix           ;reference pixel
  nx = astr.naxis[0]            ;pixel nb along x
  ny = astr.naxis[1]            ;pixel nb along y

  coord_map = coord_ref + [refpix[0]-((nx-1)/2.0+1), -refpix[1]+((ny-1)/2.0+1)]*reso/3600.0

  int_rad = dindgen(long(max([nx,ny])*reso/5.0/2.0))*5

  ;;------- Loop over all centers
  if anapar.dif_photo.method eq 'default' then anapar.dif_photo.nb_source = 1 ;force only 1 dif_photo for default
  
  for ic=0, anapar.dif_photo.nb_source - 1 do begin

     ;;------- Case of default: only 1 dif_photo centered on [0,0]
     if anapar.dif_photo.method eq 'default' then center = [0.0, 0.0]
     
     ;;------- Case of center shift given directly as offsets
     if anapar.dif_photo.method eq 'offset' then center = anapar.dif_photo.offset[ic,*]
     
     ;;------- Case of center shift computed from coordinates
     if anapar.dif_photo.method eq 'coord' then begin
        center = [-ten(anapar.dif_photo.coord[ic].ra[0],anapar.dif_photo.coord[ic].ra[1],anapar.dif_photo.coord[ic].ra[2])*15.0 + coord_map[0], $
                  ten(anapar.dif_photo.coord[ic].dec[0],anapar.dif_photo.coord[ic].dec[1],anapar.dif_photo.coord[ic].dec[2]) - coord_map[1]]*3600.0
     endif

     ;;------- Case of bug
     if anapar.dif_photo.method ne 'coord' and anapar.dif_photo.method ne 'offset' and $
        anapar.dif_photo.method ne 'default'then begin
        message, 'The method is either "coord" (you give the center R.A. Dec. coordinates)'
        message, 'or "offset" (you give the arcsec offset with respect to the map center)'
        message, 'or "default" (only one point source photometry centered on the map center)'
     endif
     
     ;;------- Default value for radius
     if finite(anapar.dif_photo.r0[ic]) ne 1 then anapar.dif_photo.r0[ic] = 30.0
     if finite(anapar.dif_photo.r1[ic]) ne 1 then anapar.dif_photo.r1[ic] = 0.0

     ;;------- Get the location where we compute the zero level
     xmap = reso*(replicate(1, ny) ## dindgen(nx)) - reso*(nx-1)/2.0 - center[0]
     ymap = reso*(replicate(1, nx) #  dindgen(ny)) - reso*(ny-1)/2.0 - center[1]
     rmap = sqrt(xmap^2 + ymap^2)  
     loc0 = where(rmap ge anapar.dif_photo.r0[ic] and rmap le anapar.dif_photo.r1[ic], nloc0)

     ;;------- Compute the fluxes
     if nloc0 ne 0 then loc0ok1mm = where(finite(noise_1mm[loc0]) eq 1 and (noise_1mm[loc0]) gt 0)
     if nloc0 ne 0 then loc0ok2mm = where(finite(noise_2mm[loc0]) eq 1 and (noise_2mm[loc0]) gt 0)
     if nloc0 ne 0 then zl1mm = mean((map_1mm[loc0])[loc0ok1mm]) else zl1mm = 0 ;zero levels
     if nloc0 ne 0 then zl2mm = mean((map_2mm[loc0])[loc0ok2mm]) else zl2mm = 0

     phi1mm = nika_pipe_integmap(map_1mm-zl1mm, reso, int_rad, center=center, var_map=noise_1mm^2, err=err1mm)
     phi1mm /= 2*!pi*(anapar.dif_photo.beam.a*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.a
     err1mm /= 2*!pi*(anapar.dif_photo.beam.a*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.a
     phi2mm = nika_pipe_integmap(map_2mm-zl2mm, reso, int_rad, center=center, var_map=noise_2mm^2, err=err2mm)
     phi2mm /= 2*!pi*(anapar.dif_photo.beam.b*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.b
     err2mm /= 2*!pi*(anapar.dif_photo.beam.b*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.b
     
     avg_flux_1mm = interpol(phi1mm, int_rad, anapar.dif_photo.r0[ic])
     avg_flux_2mm = interpol(phi2mm, int_rad, anapar.dif_photo.r0[ic])
     avg_err_flux_1mm = interpol(err1mm, int_rad, anapar.dif_photo.r0[ic])
     avg_err_flux_2mm = interpol(err2mm, int_rad, anapar.dif_photo.r0[ic])

     ;;------ R.A. Dec. coordinates given
     ra = SIXTY((coord_map[0] - center[0]/3600.0)/15.0)
     dec = SIXTY(coord_map[1] + center[1]/3600.0)

     ;;------- Check that the  zero level is reached with plots
     mydevice = !d.name
     set_plot, 'ps'
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_integ_flux_1mm_'+trim(ra[0],2)+'h'+trim(ra[1],2)+'m'+trim(ra[2],2)+'s_'+trim(dec[0],2)+'deg'+trim(dec[1],2)+'arcmin'+trim(dec[2],2)+'arcsec.ps'
     ploterror, int_rad/60.0, phi1mm,err1mm,xtitle='Radius from the center (arcmin)',$
                ytitle='Integrated flux (Jy)',charsize=1.5, thick=3, charthick=3, /nodata
     oplot, int_rad/60.0, phi1mm, thick=0.5
     oploterror, int_rad/60.0, phi1mm,err1mm, ERRTHICK=2,psym=8, symsize=0.4
     oplot, [anapar.dif_photo.r0[ic], anapar.dif_photo.r0[ic]]/60.0, [-1e5,1e5], col=250, thick=3
     oplot, [anapar.dif_photo.r1[ic], anapar.dif_photo.r1[ic]]/60.0, [-1e5,1e5], col=150, thick=3
     oplot, [-1e5,1e5], [0,0] + avg_flux_1mm, col=50, thick=3
     oplot, [-1e5,1e5], [0,0] + avg_flux_1mm-avg_err_flux_1mm*5, col=50, linestyle=2, thick=3
     oplot, [-1e5,1e5], [0,0] + avg_flux_1mm+avg_err_flux_1mm*5, col=50, linestyle=2, thick=3
     legendastro, ['Radius at which we measure the flux', 'Radius up to which we set the zero level', $
                   'Flux measured with 5 sigma statistical error'], col=[250,150, 50],$
                  /right, /bottom, linestyle=[0,0,2],thick=[3,3,3],charsize=1,charthick=1.5, box=0
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+'_integ_flux_1mm_'+trim(ra[0],2)+'h'+trim(ra[1],2)+'m'+trim(ra[2],2)+'s_'+trim(dec[0],2)+'deg'+trim(dec[1],2)+'arcmin'+trim(dec[2],2)+'arcsec'

     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_integ_flux_2mm_'+trim(ra[0],2)+'h'+trim(ra[1],2)+'m'+trim(ra[2],2)+'s_'+trim(dec[0],2)+'deg'+trim(dec[1],2)+'arcmin'+trim(dec[2],2)+'arcsec.ps'
     ploterror, int_rad/60.0, phi2mm,err2mm,xtitle='Radius from the center (arcmin)',$
                ytitle='Integrated flux (Jy)',charsize=1.5, thick=3, charthick=3, /nodata
     oplot, int_rad/60.0, phi2mm,THICK=0.5
     oploterror, int_rad/60.0, phi2mm,err2mm ,ERRTHICK=2, psym=8, symsize=0.4
     oplot, [anapar.dif_photo.r0[ic], anapar.dif_photo.r0[ic]]/60.0, [-1e5,1e5], col=250, thick=3
     oplot, [anapar.dif_photo.r1[ic], anapar.dif_photo.r1[ic]]/60.0, [-1e5,1e5], col=150, thick=3
     oplot, [-1e5,1e5], [0,0] + avg_flux_2mm, col=50, thick=3
     oplot, [-1e5,1e5], [0,0] + avg_flux_2mm-avg_err_flux_2mm*5, col=50, linestyle=2, thick=3
     oplot, [-1e5,1e5], [0,0] + avg_flux_2mm+avg_err_flux_2mm*5, col=50, linestyle=2, thick=3
     legendastro, ['Radius at which we measure the flux', 'Radius up to which we set the zero level', $
                   'Flux measured with 5 sigma statistical error'], col=[250,150, 50],$
                  /right, /bottom, linestyle=[0,0,2],thick=[3,3,3],charsize=1,charthick=1.5, box=0
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+'_integ_flux_2mm_'+trim(ra[0],2)+'h'+trim(ra[1],2)+'m'+trim(ra[2],2)+'s_'+trim(dec[0],2)+'deg'+trim(dec[1],2)+'arcmin'+trim(dec[2],2)+'arcsec'
     set_plot, mydevice

     ;;------- Idem for all scan
     nb_scan = n_elements(maps_1mm[0,0,*])
     
     flux_scans_1mm = dblarr(nb_scan)
     err_flux_scans_1mm = dblarr(nb_scan)

     flux_scans_2mm = dblarr(nb_scan)
     err_flux_scans_2mm = dblarr(nb_scan)

     if anapar.dif_photo.per_scan eq 'yes' then begin  
        for iscan=0, nb_scan-1 do begin
           if nloc0 ne 0 then loc0ok1mm = where(finite((noises_1mm[*,*,iscan])[loc0]) eq 1 and $
                                                ((noises_1mm[*,*,iscan])[loc0]) gt 0)
           if nloc0 ne 0 then loc0ok2mm = where(finite((noises_2mm[*,*,iscan])[loc0]) eq 1 and $
                                                ((noises_2mm[*,*,iscan])[loc0]) gt 0)
           if nloc0 ne 0 then zl1mm = mean(((maps_1mm[*,*,iscan])[loc0])[loc0ok1mm]) else zl1mm = 0 ;zero levels
           if nloc0 ne 0 then zl2mm = mean(((maps_2mm[*,*,iscan])[loc0])[loc0ok2mm]) else zl2mm = 0

           phi1mm = nika_pipe_integmap(maps_1mm[*,*,iscan]-zl1mm, reso, int_rad, $
                                       center=center, var_map=noises_1mm[*,*,iscan]^2, err=err1mm)
           phi1mm /= 2*!pi*(anapar.dif_photo.beam.a*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.a
           err1mm /= 2*!pi*(anapar.dif_photo.beam.a*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.a
           phi2mm = nika_pipe_integmap(maps_2mm[*,*,iscan]-zl2mm, reso, int_rad, $
                                       center=center, var_map=noises_2mm[*,*,iscan]^2, err=err2mm)
           phi2mm /= 2*!pi*(anapar.dif_photo.beam.b*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.b
           err2mm /= 2*!pi*(anapar.dif_photo.beam.b*!fwhm2sigma)^2*anapar.dif_photo.beam_cor.b

           flux_scans_1mm[iscan] = interpol(phi1mm, int_rad, anapar.dif_photo.r0[ic])
           err_flux_scans_1mm[iscan] = interpol(err1mm, int_rad, anapar.dif_photo.r0[ic])

           flux_scans_2mm[iscan] = interpol(phi2mm, int_rad, anapar.dif_photo.r0[ic])
           err_flux_scans_2mm[iscan] = interpol(err2mm, int_rad, anapar.dif_photo.r0[ic])
        endfor
        save, flux_scans_1mm, err_flux_scans_1mm, flux_scans_2mm, err_flux_scans_2mm, $
              filename=param.output_dir+'/DiffusePhotometry_list.save'
     endif

     ;;------- Print the results
     print, '----------------------------------------------'
     print, '--- Given center [R.A., Dec.] = ['+trim(ra[0],2)+' h '+trim(ra[1],2)+' m '+trim(ra[2],2)+' s,  '+$
            trim(dec[0],2)+' deg '+trim(dec[1],2)+' arcmin '+trim(dec[2],2)+' arcsec]'
     print, '----------------------------------------------'
     print, '--- Flux found at 1mm ---'
     print, 'Average map flux:'
     print, '   '+strtrim(avg_flux_1mm)+' Jy  +/- '+$
            strtrim(avg_err_flux_1mm,2)+' (stat.)'
     if anapar.dif_photo.per_scan eq 'yes' then begin
        print, 'Flux per scan:'
        print, '   '+strtrim(flux_scans_1mm)+' Jy'
        print, 'Erreur per scan (stat.):'
        print, '   '+strtrim(err_flux_scans_1mm)+' Jy'
     endif

     print, '--- Flux found at 2mm ---'
     print, 'Average map flux:'
     print, '   '+strtrim(avg_flux_2mm)+' Jy  +/- '+$
            strtrim(avg_err_flux_2mm,2)+' (stat.)'
     if anapar.dif_photo.per_scan eq 'yes' then begin
        print, 'Flux per scan:'
        print, '   '+strtrim(flux_scans_2mm)+' Jy'
        print, 'Erreur per scan (stat.):'
        print, '   '+strtrim(err_flux_scans_2mm)+' Jy'
     endif
     print, '----------------------------------------------'

  endfor

  return
end
