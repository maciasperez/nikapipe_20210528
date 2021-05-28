;+
;PURPOSE: Compute the integrated flux around a given center
;
;INPUT: the map, its resolution and the vector of integration
;       radii (can be 1 element)
;
;OUTPUT: the flux computed for all radius in the vestor radius_max
;
;KEYWORDS: 
;     - center: arcsec center from the map center
;     - var: the variance map
;     - err: the error associated with the flux output
;
;LAST EDITION: 
;   a long time ago: creation (adam@lpsc.in2p3.fr)
;   08/10/2013: add error bars (adam@lpsc.in2p3.fr)
;   17/01/2014: minor bug corrected (comis@lpsc.in2p3.fr)
;-

function nika_pipe_integmap, map, reso, radius_max, center=center, var_map=var_map, err=err

  ;;------- Case erreur required with no var map given
  if keyword_set(err) and not keyword_set(var_map) then message, 'I am sorry but if you want the error bars you have to give me the variance map as well'
  
  ;;------- centre is [0,0] by default
  if not keyword_set(center) then centre = [0.0, 0.0] else centre = center
  
  ;;------- Size of the map
  nx = (size(map))[1]
  ny = (size(map))[2]

  ;;------- Var map is 1 by default and var = 0 for undef positions
  if not keyword_set(var_map) then var = dblarr(nx,ny)+1 else var = var_map
  wnovar = where(finite(var) ne 1 or var le 0, nwnovar)
  if nwnovar ne 0 then var[wnovar] = 0.0
  map_bis = map
  if nwnovar ne 0 then map_bis[wnovar] = 0.0
  
  ;;------- Def variables
  npt = n_elements(radius_max)
  yint = dblarr(npt)
  err = dblarr(npt)
  
  xmap = reso*(replicate(1, ny) ## dindgen(nx)) - reso*(nx-1)/2.0 - centre[0] ;distance from center along x
  ymap = reso*(replicate(1, nx) #  dindgen(ny)) - reso*(ny-1)/2.0 - centre[1] ;along y
  rmap = sqrt(xmap^2 + ymap^2)                                                ;arcsec
  
  ;;------- Get the flux for all radius
  for i=0, npt-1 do begin
     loc_sum = where(rmap le radius_max[i], nloc)                                ;location of interest
     if nloc ne 0 then yint[i] = total(map_bis[loc_sum])*reso^2 else yint[i] = 0 ;Sum all pixels
     if nloc ne 0 then err[i] = sqrt(total(var[loc_sum]))*reso^2 else err[i] = 0 ;Sum all errors^2
  endfor
  
  return, yint
end
