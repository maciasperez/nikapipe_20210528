pro nika_pipe_map0level, coord_pointing, coord_source, param, map_combi, dist_min, cut_time=cut_time

  if not keyword_set(cut_time) then cut_time = {A:0.0,B:0.0}
  
  center = [-ten(coord_source.ra[0],coord_source.ra[1],coord_source.ra[2])*15.0 + $     ;Position of the source
            ten(coord_pointing.ra[0],coord_pointing.ra[1],coord_pointing.ra[2])*15.0, $ ;on the map
            ten(coord_source.dec[0],coord_source.dec[1],coord_source.dec[2]) - $
            ten(coord_pointing.dec[0],coord_pointing.dec[1],coord_pointing.dec[2])]*3600.0
  
  nx = (size(map_combi.A.Jy))[1]           
  ny = (size(map_combi.A.Jy))[2]           
  
  xmap = param.map.reso*(replicate(1, ny) ## dindgen(nx)) - param.map.reso*(nx-1)/2.0 - center[0]
  ymap = param.map.reso*(replicate(1, nx) #  dindgen(ny)) - param.map.reso*(ny-1)/2.0 - center[1]
  rmap = sqrt(xmap^2 + ymap^2)  
  
  zer_a = mean(map_combi.A.Jy[where(rmap gt dist_min and map_combi.A.time gt cut_time.A)])
  zer_b = mean(map_combi.B.Jy[where(rmap gt dist_min and map_combi.B.time gt cut_time.B)])
  
  map_combi.A.Jy += - zer_a
  map_combi.B.Jy += - zer_b
  
  return
end
