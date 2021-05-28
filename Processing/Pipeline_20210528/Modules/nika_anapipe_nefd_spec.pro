;+
;PURPOSE: Measure the NEFD for a source at the center of the combined
;         map using monte carlo simulations of the noise with a 
;         spectral modeling
;
;INPUT: - reso: the resolution of the map
;       - dist_pix: the size of a KID (same unit as reso)
;       - rms_map: rms from the pipeline directly 
;       - the time per pixel map
;       - amplitude of white noise
;       - amplitude of 1/f noise at 1arcmin
;       - slope of 1/f noise
;       - number of MC realisations
;
;OUTPUT: the NEFD
;
;LAST EDITION: 
;   25/01/2015: creation
;-

function nika_anapipe_nefd_spec, band, reso, beam, dist_pix, rms_map, time_map, $
                                 noise_ampli1, noise_ampli2, noise_slope, Nmc, output_dir
  
  ;;========== Some parameters
  nx = (size(time_map))[1]
  ny = (size(time_map))[2]

  var = rms_map^2
  no_meas = where(time_map eq 0, nno_meas)
  if nno_meas ne 0 then var[no_meas] = !values.f_nan

  err_ps = dblarr(Nmc)
  flux_ps = dblarr(Nmc)
  
  for imc = 0, Nmc-1 do begin   ;Loop over monte carlo realisations
     ;;========== Simulate a noise map
     k0 = 60.0*180.0/!pi        ;k0 at 1 arcmin
     l = dindgen(10000000)+1    ;
     clt = (noise_ampli2*(l/k0)^noise_slope + $
            noise_ampli1)/(180.0/!pi*3600.0/reso)^2
     cls2map, l, clt, nx, ny, reso/60.0, noise, cu_t, k_map, k_mapx, k_mapy
     noise = noise * rms_map

     wbad = where(finite(noise) ne 1, nwbad)
     if nwbad ne 0 then noise[wbad] = 0 ;No signal here

     ;;========== Fit the flux and its error
     nika_pipe_fit_beam, noise, reso, $
                         coeff=coeff, $
                         var_map=var,$
                         /CIRCULAR, $
                         center=[0,0], $
                         err_coeff=err_coeff, $
                         FWHM=beam, $
                         /silent
     err_ps[imc] = err_coeff[1]
     flux_ps[imc] = coeff[1]
  endfor
  
  err_flux_mc = stddev(flux_ps)
  
  if band eq 1 then print, '======= 1mm - Flux of noise MC realization / naive flux error = '+strtrim(stddev(flux_ps/err_ps), 2)
  if band eq 2 then print, '======= 2mm - Flux of noise MC realization / naive flux error = '+strtrim(stddev(flux_ps/err_ps), 2)
  if band eq 1 then openw,1, output_dir+'/Monte_Carlo_Noise_Computing.txt'
  if band eq 1 then printf, '1', '======= 1mm - Flux of noise MC realization / naive flux error = '+strtrim(stddev(flux_ps/err_ps), 2)
  if band eq 2 then printf, '1', '======= 2mm - Flux of noise MC realization / naive flux error = '+strtrim(stddev(flux_ps/err_ps), 2)
  if band eq 2 then close,1
  
  if band eq 1 then noise_fact1mm = stddev(flux_ps)/err_ps
  if band eq 2 then noise_fact2mm = stddev(flux_ps)/err_ps
  if band eq 1 then save, filename=output_dir+'/Monte_Carlo_Noise_Computing.save', noise_fact1mm
  if band eq 2 then restore, output_dir+'/Monte_Carlo_Noise_Computing.save'
  if band eq 2 then save, filename=output_dir+'/Monte_Carlo_Noise_Computing.save', noise_fact1mm, noise_fact2mm
  
  ;;========== Normalize by time to have NEFD
  radius = shift(dist(nx, ny), nx/2, ny/2)*reso
  loc_time = where(radius lt 20, nloc_time)
  time = mean(time_map[loc_time]) * dist_pix^2/reso^2
  nefd = err_flux_mc * sqrt(time)  

  return, nefd
end
