function simu_map2toi, map, reso_arcsec, dra, ddec, lobe_arcsec=lobe_arcsec

  nx = (size(map))[1]
  ny = (size(map))[2]

  xpix = dra/reso_arcsec + (nx-1)/2  ;localisation dans la carte en pixel selon x
  ypix = ddec/reso_arcsec + (ny-1)/2 ;localisation dans la carte en pixel selon y

  ;; LP modif : 
  if not(keyword_set(lobe_arcsec)) then map_here=map else $
     map_here = filter_image(map,fwhm=lobe_arcsec/reso_arcsec,/all)
  
  source = interpolate(map_here, xpix, ypix)
  
  return, source
end
