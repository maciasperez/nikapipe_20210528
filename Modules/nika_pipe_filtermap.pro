pro nika_pipe_filtermap, param, maps, maps_out
  
  scale1 = 2*!pi/150.0              ;arcsec^-1 cut lim 1
  scale2 = 2*!pi/130.0               ;arcsec^-1 cut lim 2
  
  Nmap = (size(maps.A.Jy))[1]
 
  k = 2*!pi*dist(Nmap)/Nmap/param.map.reso

  z1 = where(k lt scale1)
  z2 = where(k gt scale1 and k lt scale2)
  z3 = where(k gt scale2)

  filter = dblarr(Nmap, Nmap)
  filter[z1] = 0.0
  filter[z2] = (cos(!pi/2.0*(k[z2] - scale2)/(scale2-scale1)))^2
  filter[z3] = 1.0
dispim_bar, filter, /aspect

  FTmap_a = FFT(maps.a.jy,/double)
  FTmap_b = FFT(maps.b.jy,/double)
  

  maps_out = maps
  
  maps_out.a.jy = double(FFT(FTmap_a * filter, /inverse,/double))
  maps_out.b.jy = double(FFT(FTmap_b * filter, /inverse,/double))
  
  return
end
