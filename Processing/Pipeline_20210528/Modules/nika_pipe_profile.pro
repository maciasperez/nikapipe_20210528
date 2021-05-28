;+
;PURPOSE: Compute a profile from a map
;
;INPUT: The resolution, the flux and variance maps as a structure:
;       maps={Jy:flux_map, var:variance_map}.
;
;OUTPUT: The profile in the structure profile = {radius, signal_profile, variance}
;
;KEYWORDS:
;   - nb_prof: the number of points in the profile
;   - center: the location where you want to define the profile center
;     with respect to the map center
;   - no_nan: replace nan by 0
;
;LAST EDITION: 
;   2012: creation (adam@lpsc.in2p3.fr)
;   25/09/2013: modification of the undefined variance (adam@lpsc.in2p3.fr)
;   5/02/2014: keyword no_nan added (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_profile, reso, maps, profile, nb_prof=nb_prof, center=center, no_nan=no_nan
  
  if not keyword_set(nb_prof) then nb_prof = 50 ;Nombre de point sur lequel on moyenne
  if not keyword_set(center) then the_center = [0,0] else the_center=center/reso

  caract_map = size(maps.jy)
  N_sky_x = caract_map[1]
  N_sky_y = caract_map[2]
  Taille_carte = sqrt((N_sky_x/2.0 + the_center[0])^2 + (N_sky_y/2.0 + the_center[1])^2) ;longueur max

  flux_r = dblarr(N_sky_x*N_sky_y)
  var_r = dblarr(N_sky_x*N_sky_y)
  radius = dblarr(N_sky_x*N_sky_y) 
  
  n=0l
  for i=0d,N_sky_x-1 do begin
     for j=0d,N_sky_y-1 do begin
        flux_r[n] = maps.Jy[i,j]                                          ;Vecteur de y dans le desordre
        var_r[n] = maps.var[i,j]                                          ;Vecteur variance dans le desordre
        radius[n] = sqrt((i-double(N_sky_x)/2-the_center[0])^2+(j-double(N_sky_y)/2-the_center[1])^2) ;Vecteur de distance au centre dans le desordre
        n = n + 1
     endfor
  endfor

  ;;flux_r is sorted by increasing radius
  radius_sort = radius[sort(radius)]
  flux_r_sort = flux_r[sort(radius)]
  var_sort = var_r[sort(radius)]
  w8_sort = 0.0*radius_sort
  w8_sort[where(var_sort gt 0 and finite(var_sort) eq 1)] = 1.0/var_sort[where(var_sort gt 0 $
                                                                               and finite(var_sort) eq 1)]
  
  nb_pt_cat = lonarr(nb_prof)
  r_prof =  dblarr(nb_prof)
  y_prof = dblarr(nb_prof)
  var_prof = dblarr(nb_prof)

  tranche = Taille_carte/nb_prof ;Taille des tranche d'angle entre 2 points
  catego = 0

  for i=0l, nb_prof-1 do begin
     sum_y = 0.0
     sum_r = 0.0
     sum_pt = 0l
     sum_w8 = 0.0
     
     for k=0l, n_elements(radius_sort)-1 do begin
        if ((radius_sort[k] ge tranche*catego) and (radius_sort[k] lt tranche*(catego+1)) and (var_sort[k] gt 0)) then begin
           sum_r = sum_r + radius_sort[k]*w8_sort[k]
           sum_y = sum_y + flux_r_sort[k]*w8_sort[k]
           sum_pt = sum_pt + 1
           sum_w8 = sum_w8 + w8_sort[k]
        endif
     endfor
     r_prof[i] =  sum_r/sum_w8
     y_prof[i] = sum_y/sum_w8
     var_prof[i] = 1.0/sum_w8   ;Compute the variance without any weight
     nb_pt_cat[i] = sum_pt
     catego = catego + 1
  endfor

  if keyword_set(no_nan) then begin
     nan_pos = where(finite(y_prof) ne 1, nnan, comp=pas_nan)
     if nnan ne 0 then begin
        y_prof[nan_pos] = 0
        var_prof[nan_pos] = 0
        r_prof[nan_pos] = max(r_prof, /nan) + tranche * (dindgen(n_elements(nan_pos))+1)
     endif
  endif
  
  profile = {r:r_prof*reso,y:y_prof,var:var_prof}

  return
end
