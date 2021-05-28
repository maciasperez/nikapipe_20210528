pro nika_pipe_restore_maps, output_dir, name4file, version, param, map_list, map_combi, header, $
                            map_per_kid=map_per_kid, map_per_scan_per_kid=map_per_scan_per_kid,$
                            kid_par=kid_par
  
  map_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 0, header)
  var_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 1, header)
  time_a = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 2, header)
  
  map_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 3, header)
  var_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 4, header)
  time_b = mrdfits(output_dir+'/astrometry_'+name4file+'_'+version+'.fits', 5, header)
  
  restore, output_dir+'/param_'+name4file+'_'+version+'.save'   ;Param
  restore, output_dir+'/maplist_'+name4file+'_'+version+'.save' ;Map per scan
  
  map_combi = {A:{Jy:map_a, var:var_a, time:time_a}, B:{Jy:map_b, var:var_b, time:time_b}}
  
  if keyword_set(map_per_kid) then restore, output_dir+'/mapperkid_'+name4file+'_'+version+'.save'
  if keyword_set(map_per_scan_per_kid) then restore, output_dir+'/mapperkidperscan_'+name4file+'_'+version+'.save'
  if keyword_set(kid_par) then restore, output_dir+'/kidpar_'+name4file+'_'+version+'.save'
  
  return
end
