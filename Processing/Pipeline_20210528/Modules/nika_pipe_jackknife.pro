function nika_pipe_jackknife, param, map_list
  
  Nb_map = n_elements(map_list) ;Total number of maps
  
                                ;First set of maps
  map_jy_a1 = map_list[0].A.Jy * 0.0
  map_norm_a1 = map_list[0].A.var * 0.0
  map_jy_b1 = map_list[0].B.Jy * 0.0
  map_norm_b1 = map_list[0].B.var * 0.0
  
                                ;2nd set of maps
  map_jy_a2 = map_list[0].A.Jy * 0.0
  map_norm_a2 = map_list[0].A.var * 0.0
  map_jy_b2 = map_list[0].B.Jy * 0.0
  map_norm_b2 = map_list[0].B.var * 0.0
  
                                ;combining the maps for the first set
  for k=0, Nb_map/2-1 do begin   
     map_w8_a1 = 1.0/map_list[k].A.var
     map_w8_a1[where(map_list[k].A.var eq -1)] = 0.0
     map_jy_a1 = map_jy_a1 + map_w8_a1 * map_list[k].A.Jy
     map_norm_a1 = map_norm_a1 + map_w8_a1
     
     map_w8_b1 = 1.0/map_list[k].B.var
     map_w8_b1[where(map_list[k].B.var eq -1)] = 0.0
     map_jy_b1 = map_jy_b1 + map_w8_b1 * map_list[k].B.Jy
     map_norm_b1 = map_norm_b1 + map_w8_b1
  endfor
  
  map_jy_a1 = map_jy_a1/map_norm_a1 ;Normalizing the maps
  map_jy_a1[where(map_norm_a1 eq 0)] = 0.0
  map_var_a1 = 1.0/map_norm_a1
  map_var_a1[where(map_norm_a1 eq 0)] = -1

  map_jy_b1 = map_jy_b1/map_norm_b1
  map_jy_b1[where(map_norm_b1 eq 0)] = 0.0
  map_var_b1 = 1.0/map_norm_b1
  map_var_b1[where(map_norm_b1 eq 0)] = -1

                                ;combining the maps for the 2nd set
  for k=Nb_map/2, Nb_map-1 do begin   
     map_w8_a2 = 1.0/map_list[k].A.var
     map_w8_a2[where(map_list[k].A.var eq -1)] = 0.0
     map_jy_a2 = map_jy_a2 + map_w8_a2 * map_list[k].A.Jy
     map_norm_a2 = map_norm_a2 + map_w8_a2
     
     map_w8_b2 = 1.0/map_list[k].B.var
     map_w8_b2[where(map_list[k].B.var eq -1)] = 0.0
     map_jy_b2 = map_jy_b2 + map_w8_b2 * map_list[k].B.Jy
     map_norm_b2 = map_norm_b2 + map_w8_b2
  endfor
  
  map_jy_a2 = map_jy_a2/map_norm_a2 ;Normalizing the maps
  map_jy_a2[where(map_norm_a2 eq 0)] = 0.0
  map_var_a2 = 1.0/map_norm_a2
  map_var_a2[where(map_norm_a2 eq 0)] = -1
  
  map_jy_b2 = map_jy_b2/map_norm_b2
  map_jy_b2[where(map_norm_b2 eq 0)] = 0.0
  map_var_b2 = 1.0/map_norm_b2
  map_var_b2[where(map_norm_b2 eq 0)] = -1
  
                                ;Substract the two sets
  map_jk = {A:map_jy_a1 - map_jy_a2,$
            B:map_jy_b1 - map_jy_b2}

  return, map_jk
end
