;;Simulation of the temperature profile
;;for a point source

pro genere_planet,param, profile

  r = dindgen(10000)*param.Taille_carte/10000 ;Angular radius (arcsec) which goes from 0 to twice the size of the map

  T_prof1 = param.T_planet*exp(double(-r^2/(2*(param.Taille_lobe/2.35482)^2))) ;Profile at nu1
  T_prof2 = T_prof1 * (param.nu2/param.nu1)^2.0                                ;Profile at nu2

  profile = [[r], [T_prof1], [T_prof2]]

  print, 'The profile of the planet is build'

  return
end
