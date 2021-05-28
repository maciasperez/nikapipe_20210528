;+
;PURPOSE: Measure the NEFD for a source at the center of the combined map
;
;INPUT: - reso: the resolution of the map
;       - beam gaussian FWHM
;       - dist_pix: the size of a KID (same unit as reso)
;       - map_flux: the surface brightness map
;       - the sensitivity: standard deviation of the
;         map_flux*sqrt(map_time)
;       - the time per pixel map
;
;OUTPUT: the NEFD
;
;LAST EDITION: 
;   16/02/2014: creation (adam@lpsc.in2p3.fr)
;-

function nika_anapipe_nefd, reso, beam, dist_pix, map_flux, sens_sd, time_map

  var = (sens_sd / sqrt(time_map))^2
  no_meas = where(time_map eq 0, nno_meas)
  if nno_meas ne 0 then var[no_meas] = !values.f_nan
  
  nika_pipe_fit_beam, map_flux, reso, $
                      coeff=coeff, $
                      var_map=var,$
                      /CIRCULAR, $
                      center=[0,0], $
                      err_coeff=err_coeff, $
                      rchi2=chi2,$
                      FWHM=beam, $
                      /silent
  err = err_coeff[1]

  nx = (size(time_map))[1]
  ny = (size(time_map))[2]
  
  radius = shift(dist(nx, ny), nx/2, ny/2)*reso
  loc_time = where(radius lt 20, nloc_time)
  
  time = mean(time_map[loc_time]) * dist_pix^2/reso^2

  nefd = err * sqrt(time)

  return, nefd
end
