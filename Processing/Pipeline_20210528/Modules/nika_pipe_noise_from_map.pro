;+
;PURPOSE: Compute the noise maps by taking the stddev(flux x
;sqrt(time)) /sqrt(time) and masking possible sources
;
;INPUT: The parameter structure, the combined maps, the map per scan
;
;OUTPUT: The associated noise maps
;
;LAST EDITION: 19/12/2013: creation(adam@lpsc.in2p3.fr)
;              20/11/2014: correct a bug for SZ since negative flag
;-

pro nika_pipe_noise_from_map, param, maps, astrometry=astr
  
  ;;------- Find the source(s) position
  wsource_1mm = maps.A.jy*0
  wsource_2mm = maps.B.jy*0
  
  if keyword_set(astr) then begin
     ;;------- Flag the source in a given radius
     reso = abs(astr.cdelt[0])*3600
     nx = astr.naxis[0]
     ny = astr.naxis[1]
     xmin = (-nx/2-0.5)*reso
     ymin = (-ny/2-0.5)*reso
     
     ra_source = ten(param.coord_source.ra[0],param.coord_source.ra[1],param.coord_source.ra[2])*15.0
     dec_source = ten(param.coord_source.dec[0],param.coord_source.dec[1],param.coord_source.dec[2])
     
     ra_map = astr.crval[0] + reso*(astr.crpix[0] - ((nx-1)/2.0+1))/3600.0
     dec_map = astr.crval[1] - reso*(astr.crpix[1] - ((ny-1)/2.0+1))/3600.0
     
     c_arcsec_x = (ra_map - ra_source)*3600.0
     c_arcsec_y = (dec_source - dec_map)*3600.0
     
     xmap = reso*(replicate(1, ny) ## dindgen(nx)) - reso*(nx-1)/2.0 - c_arcsec_x
     ymap = reso*(replicate(1, nx) #  dindgen(ny)) - reso*(ny-1)/2.0 - c_arcsec_y
     rmap = sqrt(xmap^2 + ymap^2)  
     
     loc = where(rmap lt param.w8.dist_off_source, nloc)
     
     if nloc ne 0 then wsource_1mm[loc] = 1
     if nloc ne 0 then wsource_2mm[loc] = 1
     
     ;;------- Flag the source with a map at 1mm
     if param.w8.map_guess1mm ne '' then begin
        nika_pipe_extract_map_flag, param.w8.map_guess1mm, param.w8.flag_type, param.w8.relob.a, map_guess, reso_w8_1mm, max_noise=max_noise1
        
        if param.w8.flag_lim[0] ge 0 then loc = where(map_guess ge param.w8.flag_lim[0], nloc)
        if param.w8.flag_lim[0] lt 0 then loc = where(map_guess le param.w8.flag_lim[0], nloc)
        if nloc ne 0 then wsource_1mm[loc] = 1
     endif
     
     ;;------- Flag the source with a map at 2mm
     if param.w8.map_guess2mm ne '' then begin
        nika_pipe_extract_map_flag, param.w8.map_guess2mm, param.w8.flag_type, param.w8.relob.b, map_guess, reso_w8_2mm, max_noise=max_noise2
        
        if param.w8.flag_lim[1] ge 0 then loc = where(map_guess ge param.w8.flag_lim[1], nloc)
        if param.w8.flag_lim[1] lt 0 then loc = where(map_guess le param.w8.flag_lim[1], nloc)
        if nloc ne 0 then wsource_2mm[loc] = 1
     endif
     
  endif
  
  ;;------- Compute the sensitivity
  sens_1mm = maps.A.jy * sqrt(maps.A.time) 
  sens_2mm = maps.B.jy * sqrt(maps.B.time) 
  
  loc_1mm = where(finite(sens_1mm) eq 1 and maps.A.time gt 0 and wsource_1mm eq 0, nloc_1mm)
  loc_2mm = where(finite(sens_2mm) eq 1 and maps.B.time gt 0 and wsource_2mm eq 0, nloc_2mm)

  if nloc_1mm ne 0 then noise_1mm = stddev(sens_1mm[loc_1mm]) else noise_1mm = !values.f_nan
  if nloc_2mm ne 0 then noise_2mm = stddev(sens_2mm[loc_2mm]) else noise_2mm = !values.f_nan

  ;;------- Normalize by the time per pixel
  maps.A.noise_map = noise_1mm / sqrt(maps.A.time)
  maps.B.noise_map = noise_2mm / sqrt(maps.B.time)

  undef_1mm = where(finite(maps.A.noise_map) ne 1, nundef_1mm)
  undef_2mm = where(finite(maps.B.noise_map) ne 1, nundef_2mm)

  if nundef_1mm ne 0 then maps.A.noise_map[undef_1mm] = !values.f_nan
  if nundef_2mm ne 0 then maps.B.noise_map[undef_2mm] = !values.f_nan

  return
end
