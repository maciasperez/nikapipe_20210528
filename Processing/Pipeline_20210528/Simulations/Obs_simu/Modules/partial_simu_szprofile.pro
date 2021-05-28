;+
;PURPOSE: Get a tSZ profile, according to the profile parameters, and
;         including the smoothing of the map
;INPUT: The empty data and the pointing.
;OUTPUT: The data with a source in the TOI
;LAST EDITION: 
;   23/01/2014: Remi ADAM (adam@lpsc.in2p3.fr)
;-

function partial_simu_szprofile, P0, rs, alpha, beta, gamma, concentration, redshift, $
                                 beam1mm, beam2mm, fov, reso, $
                                 y2jy1mm, y2jy2mm

  ;;################# Get the y_compton profile
  t500 = rs*concentration
  profile = compute_model_sz(P0, rs/60.0, t500/60.0, alpha, beta, gamma, redshift)
  y_th = profile[*,0]
  r_th = profile[*,1]*60.0

  ;;################# Projection of the profile onto a map
  nmap = 2*long(fov/reso/2)+1   ;odd number for having 1 pixel at the center
  y_xy = dblarr(nmap,nmap)      ;Compton y 2D map
  
  for i=0l,nmap-1 do begin      ;On remplie la carte mais en 2D au lieu de radial
     for j=0l,nmap-1 do begin
        rad = reso*((double(i-(nmap-1)/2.0))^2 + (double(j-(nmap-1)/2.0))^2)^0.5 ;radius at the given position
        y_xy[i,j] = interpol(y_th, r_th, rad)
     endfor
  endfor
  
  ;;################# Beam smoothing a map
  y_xy = {A:filter_image(y_xy, fwhm=beam1mm/reso, /all_pixels),$
          B:filter_image(y_xy, fwhm=beam2mm/reso, /all_pixels)}

  ;;################# Reconversion towards a smoothed profile
  yr_lobe = {A:dblarr(nmap^2), B:dblarr(nmap^2)}
  r_lobe = dblarr(nmap^2)
  
  n=0l
  for i=0d,nmap-1 do begin
     for j=0d,nmap-1 do begin
        yr_lobe.A[n] = y_xy.A[i,j]                                   ;Vecteur de y dans le desordre
        yr_lobe.B[n] = y_xy.B[i,j]                                   ;Vecteur de y dans le desordre
        r_lobe[n] = reso*sqrt((i-(nmap-1)/2.0)^2+(j-(nmap-1)/2.0)^2) ;Vecteur de dist_ang dans le desordre
        n = n + 1
     endfor
  endfor

  ;;################# Reorder the profile
  yr_sort = {A:dblarr(nmap^2), B:dblarr(nmap^2)}
  r_sort = r_lobe(sort(r_lobe)) ;arcsec
  yr_sort.A = yr_lobe.A[sort(r_lobe)]
  yr_sort.B = yr_lobe.B[sort(r_lobe)]
  
  ;;################# Interpole the profile
  r_fin = dindgen(nmap)/(nmap-1)*FOV/sqrt(2)        ;Final radius 
  y_fin = {A:interpol(yr_sort.A, r_sort, r_fin),$ ;Finale y profile (with lobe)
           B:interpol(yr_sort.B, r_sort, r_fin)}
  
  ;;################# The final profile is in a structure
  prof = {r:r_fin,$                                                        
          A:y_fin.A*y2jy1mm,$ 
          B:y_fin.B*y2jy2mm,$ 
          unit:'arcsec, Jy/Beam, Jy/Beam'}
  
  return, prof
end
