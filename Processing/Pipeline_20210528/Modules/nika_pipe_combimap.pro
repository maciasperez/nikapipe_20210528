;+
;PURPOSE: Combine map per scan
;
;INPUT: The parameter and the list of map per scan
;
;OUTPUT: The combined maps
;
;LAST EDITION: 
;   2013: creation (adam@lpsc.in2p3.fr)
;   24/09/2013: modification with !values.f_nan as undefined var
;   20/12/2013: add the keyword use_noise_from_map which allow to
;               weight scan maps using the noise estimated from the
;               maps themselves  
;-

pro nika_pipe_combimap, map_list, map_combi, use_noise_from_map=nfm
  
  Nb_map = n_elements(map_list) ;Total number of maps
  
  map_jy_a = map_list[0].A.Jy * 0.0
  map_norm_a = map_list[0].A.Jy * 0.0
  map_norm_a_nfm = map_list[0].A.Jy * 0.0
  map_time_a = map_list[0].A.Jy * 0.0
  
  map_jy_b = map_list[0].B.Jy * 0.0
  map_norm_b = map_list[0].B.Jy * 0.0
  map_norm_b_nfm = map_list[0].B.Jy * 0.0
  map_time_b = map_list[0].B.Jy * 0.0
  
  ;;------- Loop over the maps
  for k=0, Nb_map-1 do begin   
     ;;------- 1mm
     map_w8_a = 1.0/map_list[k].A.var
     map_w8_a_nfm = 1.0/(map_list[k].A.noise_map)^2
     loc_novar = where(map_list[k].A.var/map_list[k].A.var ne 1, novar)
     loc_novar_nfm = where(finite(map_list[k].A.noise_map) ne 1, novar_nfm)
     if novar ne 0 then map_w8_a[loc_novar] = 0.0
     if novar_nfm ne 0 then map_w8_a_nfm[loc_novar_nfm] = 0.0
     
     if keyword_set(nfm) then map_jy_a = map_jy_a + map_w8_a_nfm * map_list[k].A.Jy else $
        map_jy_a = map_jy_a + map_w8_a * map_list[k].A.Jy
     
     map_norm_a = map_norm_a + map_w8_a
     map_norm_a_nfm = map_norm_a_nfm + map_w8_a_nfm

     map_time_a = map_time_a + map_list[k].A.time
     
     ;;------- 2mm
     map_w8_b = 1.0/map_list[k].B.var
     map_w8_b_nfm = 1.0/(map_list[k].B.noise_map)^2
     loc_novar = where(map_list[k].B.var/map_list[k].B.var ne 1, novar)
     loc_novar_nfm = where(finite(map_list[k].B.noise_map) ne 1, novar_nfm)
     if novar ne 0 then map_w8_b[loc_novar] = 0.0
     if novar_nfm ne 0 then map_w8_b_nfm[loc_novar_nfm] = 0.0
     
     if keyword_set(nfm) then map_jy_b = map_jy_b + map_w8_b_nfm * map_list[k].B.Jy else $
        map_jy_b = map_jy_b + map_w8_b * map_list[k].B.Jy
     
     map_norm_b = map_norm_b + map_w8_b
     map_norm_b_nfm = map_norm_b_nfm + map_w8_b_nfm

     map_time_b = map_time_b + map_list[k].B.time
  endfor
  
  ;;------- Normalizing the maps
  if keyword_set(nfm) then map_jy_a = map_jy_a/map_norm_a_nfm else map_jy_a = map_jy_a/map_norm_a 
  loc_nonorm_a_nfm = where(map_norm_a_nfm eq 0, nloc_nonorm_a_nfm) 
  loc_nonorm_a = where(map_norm_a eq 0, nloc_nonorm_a)
  if keyword_set(nfm) then begin
     if nloc_nonorm_a_nfm ne 0 then map_jy_a[loc_nonorm_a_nfm] = 0.0
  endif
  if not keyword_set(nfm) then begin
     if nloc_nonorm_a ne 0 then map_jy_a[loc_nonorm_a] = 0.0
  endif
  
  map_var_a = 1.0/map_norm_a
  noise_map_a = 1.0/sqrt(map_norm_a_nfm)
  if nloc_nonorm_a ne 0 then map_var_a[loc_nonorm_a] = !values.f_nan
  if nloc_nonorm_a_nfm ne 0 then noise_map_a[loc_nonorm_a_nfm] = !values.f_nan

  if keyword_set(nfm) then map_jy_b = map_jy_b/map_norm_b_nfm else map_jy_b = map_jy_b/map_norm_b 
  loc_nonorm_b_nfm = where(map_norm_b_nfm eq 0, nloc_nonorm_b_nfm) 
  loc_nonorm_b = where(map_norm_b eq 0, nloc_nonorm_b)
  if keyword_set(nfm) then begin
     if nloc_nonorm_b_nfm ne 0 then map_jy_b[loc_nonorm_b_nfm] = 0.0
  endif
  if not keyword_set(nfm) then begin
     if nloc_nonorm_b ne 0 then map_jy_b[loc_nonorm_b] = 0.0
  endif

  map_var_b = 1.0/map_norm_b
  noise_map_b = 1.0/sqrt(map_norm_b_nfm)
  if nloc_nonorm_b ne 0 then map_var_b[loc_nonorm_b] = !values.f_nan
  if nloc_nonorm_b_nfm ne 0 then noise_map_b[loc_nonorm_b_nfm] = !values.f_nan

  ;;Combined maps into a structure
  map_combi = {A:{Jy:map_jy_a,var:map_var_a, time:map_time_a, noise_map:noise_map_a},$ 
               B:{Jy:map_jy_b,var:map_var_b, time:map_time_b, noise_map:noise_map_b}}
  
  return
end
