;+
;PURPOSE: Combine map per scan with weight at large scales
;
;INPUT: The parameter and the list of map per scan
;
;OUTPUT: The combined maps
;
;LAST EDITION: 
;   27/11/2015: creation
;-

pro nika_pipe_combimap_lsw, map_list, map_combi, FWHM
  
  maps1mm = map_list.A.Jy
  stds1mm = map_list.A.noise_map
  tims1mm = map_list.A.time
  maps2mm = map_list.B.Jy
  stds2mm = map_list.B.noise_map
  tims2mm = map_list.B.time
  
  Nb_map = n_elements(map_list) ;Total number of maps
  
  w8_a = map_list.A.Jy * 0.0
  w8_b = map_list.A.Jy * 0.0
  
  ;;------- Loop over the maps
  for k=0, Nb_map-1 do begin   
     w8_a[*,*,k] = tims1mm[*,*,k] / (stddev(filter_image(maps1mm[*,*,k]*sqrt(tims1mm[*,*,k]), fwhm=fwhm, /all)))^2
     w8_b[*,*,k] = tims2mm[*,*,k] / (stddev(filter_image(maps2mm[*,*,k]*sqrt(tims2mm[*,*,k]), fwhm=fwhm, /all)))^2
  endfor

  wnovar_a = where(finite(stds1mm) ne 1 or stds1mm le 0, nwnovar_a)
  wnovar_b = where(finite(stds2mm) ne 1 or stds2mm le 0, nwnovar_b)
  if nwnovar_a ne 0 then w8_a[wnovar_a] = 0
  if nwnovar_b ne 0 then w8_a[wnovar_a] = 0

  map_jy_a = total(w8_a * maps1mm, 3) / total(w8_a, 3)
  map_jy_b = total(w8_b * maps2mm, 3) / total(w8_b, 3)

  wnan_a = where(finite(map_jy_a) ne 1, nwnan_a)
  wnan_b = where(finite(map_jy_b) ne 1, nwnan_b)
  if nwnan_a ne 0 then map_jy_a[wnan_a] = 0
  if nwnan_b ne 0 then map_jy_b[wnan_b] = 0
  
  ;;Combined maps into a structure
  map_combi.A.Jy = map_jy_a
  map_combi.B.Jy = map_jy_b
  
  return
end
