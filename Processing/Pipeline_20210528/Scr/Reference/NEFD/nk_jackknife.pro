function nk_jackknife, map_list, var_list, map_jy_1, map_jy_2, $
                       map_var_1, map_var_2, map_var_out=map_var_out

  Nb_map = n_elements(map_list[0,0,*]) ;Total number of maps
  
  ;;------- First set of maps
  map_jy_1 = map_list[*,*,0] * 0.0
  map_norm_1 = map_list[*,*,0] * 0.0
  
  ;;------- 2nd set of maps
  map_jy_2 = map_list[*,*,0] * 0.0
  map_norm_2 = map_list[*,*,0] * 0.0
  
  ;;###########################################
  ;;------- combining the maps for the first set
  for k=0, Nb_map/2-1 do begin
     map_w8_1 = 1.0/reform(var_list[*,*,k])
     undef = where(var_list[*,*,k] le 0 or finite(var_list[*,*,k]) ne 1, nundef)
     if nundef ne 0 then map_w8_1[undef] = 0.0
     map_jy_1 = map_jy_1 + map_w8_1 * reform(map_list[*,*,k])
     map_norm_1 = map_norm_1 + map_w8_1
  endfor
  
  ;;-------- Normalizing the maps
  map_jy_1 = map_jy_1/map_norm_1
  undef_1 = where(map_norm_1 eq 0, nundef_1)
  if nundef_1 ne 0 then map_jy_1[undef_1] = 0.0
  map_var_1 = 1.0/map_norm_1
  if nundef_1 ne 0 then map_var_1[undef_1] = !values.f_nan

  ;;###########################################
  ;;------- combining the maps for the 2nd set
  for k=Nb_map/2, Nb_map-1 do begin
     map_w8_2 = 1.0/var_list[*,*,k]
     undef = where(var_list[*,*,k] le 0 or finite(var_list[*,*,k]) ne 1, nundef)
     if nundef ne 0 then map_w8_2[undef] = 0.0
     map_jy_2 = map_jy_2 + map_w8_2 * map_list[*,*,k]
     map_norm_2 = map_norm_2 + map_w8_2
  endfor
  
  ;;------- Normalizing the maps
  map_jy_2 = map_jy_2/map_norm_2 
  undef_2 = where(map_norm_2 eq 0, nundef_2)
  if nundef_2 ne 0 then map_jy_2[undef_2] = 0.0
  map_var_2 = 1.0/map_norm_2
  if nundef_2 ne 0 then map_var_2[undef_2] = !values.f_nan
  
  ;;###########################################
  ;;------- Substract the two sets
  map_jk = map_jy_1 - map_jy_2
  if nundef_1 ne 0 then map_jk[undef_1] = !values.f_nan
  if nundef_2 ne 0 then map_jk[undef_2] = !values.f_nan

  map_var_out = map_var_1 + map_var_2

  return, map_jk
end
