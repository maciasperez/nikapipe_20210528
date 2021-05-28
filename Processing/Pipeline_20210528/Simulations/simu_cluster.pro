;+
;PURPOSE: Compute a lobed SZ profile
;INPUT: Parameter structure.
;OUTPUT: the profile as {radius[arcsec], Jy_nua, Jy_nu2}
;LAST EDITION: 04/02/2012
;LAST EDITOR: Remi ADAM (adam@lpsc.in2p3.fr)
;-

function simu_cluster, param, only_P0=only_P0, cor=cor
  
  ;;;;;;;;;; SOME PHYSICAL PARAMETERS ;;;;;;;;;;;;;;;;;;;;;;;;  
  s_th = 0.665e-28                ;section efficase Thomson
  m_ec2 = 510998.918*1.602176e-19 ;masse d'un electron    

  Omega_L = 0.6825
  Omega_k = 0.0
  Omega_M = 0.3175
  Omega_r = 0.0
  H_0 = 67.11

  h_z = sqrt(Omega_L + Omega_k*(1+param.caract_source.z)^2 + $
             Omega_M*(1+param.caract_source.z)^3 + Omega_r*(1+param.caract_source.z)^4)
  h_70 = H_0/70.0
  
  if Omega_k lt 0 then ang_dist, param.caract_source.z, H_0/100.0, Omega_M, Omega_L, -1, D_ang ;D_ang en parsec
  if Omega_k eq 0 then ang_dist, param.caract_source.z, H_0/100.0, Omega_M, Omega_L, 0, D_ang
  if Omega_k gt 0 then ang_dist, param.caract_source.z, H_0/100.0, Omega_M, Omega_L, 1, D_ang
  D_ang = D_ang / 1000.0        ;D_ang en kpc

  if not keyword_set(only_P0) then $
     P_500 = 2.64e-13*h_z^(8.0/3.0)*(param.caract_source.M_500/(3e14*h_70^(-1)))^(2.0/3.0) * h_70^(2.0/3.0)
  
  ;;;;;;;;;; COMPUTATION OF y(R, 2D) from P(r, 3D) ;;;;;;;;;;;;;;;;;;;;;;;;
  npt = 1000l
  r_3d = dindgen(npt)/(npt-1)*10*param.caract_source.rs ;up to 10 rs (kpc)
  if not keyword_set(only_P0) then $
     P_r = P_500*param.caract_source.P0 / (r_3d/param.caract_source.rs)^param.caract_source.c / $
           (1 + (r_3d/param.caract_source.rs)^param.caract_source.a)^$
           ((param.caract_source.b - param.caract_source.c)/param.caract_source.a) ;3D pressure profile (Pa)
  if keyword_set(only_P0) then $
     P_r = param.caract_source.P0 / (r_3d/param.caract_source.rs)^param.caract_source.c / $
           (1 + (r_3d/param.caract_source.rs)^param.caract_source.a)^$
           ((param.caract_source.b - param.caract_source.c)/param.caract_source.a) ;3D pressure profile (Pa)
  P_r[0] =  P_r[1]                                                                 ;Infinity at r=0
  
  y_th = dblarr(npt)            ;projected y(theta)
  theta = r_3d / D_ang          ;radian
  for u=0l,npt-1 do begin
     if u eq 0 then fonction = P_r
     if u ne 0 then if not keyword_set(cor) then fonction = P_r / sqrt(1.0 + (theta[u]*D_ang/r_3d)^2)
     if u ne 0 then if keyword_set(cor) then fonction = P_r / sqrt(1.0 - (theta[u]*D_ang/r_3d)^2)
     loc_int = where(r_3d gt (1+1e-4)*theta[u]*D_ang, nloc)
     if nloc ge 2 then integ = int_tabulated(r_3d[loc_int], fonction[loc_int], /double) else integ = 0.0
     y_th[u] = 2*s_th*integ/m_ec2*3.08567758e19
  endfor
  
  ;;;;;;;;;; COMPUTATION OF y(x,y, 2D) ;;;;;;;;;;;;;;;;;;;;;;;;
  fov = 2*max([param.map.size_ra,param.map.size_dec]) ;FOV de la carte cree en arcsec
  nmap = 501l                                         ;odd number for having 1 pixel at the center
  reso = fov/nmap                                     ;resolution [radian/pixel]
  y_xy = dblarr(nmap,nmap)                            ;Compton y 2D map
  
  for i=0l,nmap-1 do begin      ;On remplie la carte mais en 2D au lieu de radial
     for j=0l,nmap-1 do begin
        rad = reso*((double(i-(nmap-1)/2.0))^2 + (double(j-(nmap-1)/2.0))^2)^0.5 ;radius at the given position
        y_xy[i,j] = interpol(y_th, theta*3600.0*180.0/!pi, rad)
     endfor
  endfor

  ;Lobe smoothing
  y_xy = {A:filter_image(y_xy, fwhm=param.beam.A/reso, /all_pixels),$
          B:filter_image(y_xy, fwhm=param.beam.B/reso, /all_pixels)}

  ;;;;;;;;;; RECONVERSION MAP TO PROFILE ;;;;;;;;;;;;;;;;;;;;;;;;
  y_r_lobe = {A:dblarr(nmap^2),B:dblarr(nmap^2)}
  r_lobe = dblarr(nmap^2)
  
  n=0l
  for i=0d,nmap-1 do begin
     for j=0d,nmap-1 do begin
        y_r_lobe.A[n] = y_xy.A[i,j]                                  ;Vecteur de y dans le desordre
        y_r_lobe.B[n] = y_xy.B[i,j]                                  ;Vecteur de y dans le desordre
        r_lobe[n] = reso*sqrt((i-(nmap-1)/2.0)^2+(j-(nmap-1)/2.0)^2) ;Vecteur de dist_ang dans le desordre
        n = n + 1
     endfor
  endfor

  ;;y_r_lobe is sorted by increasing radius
  y_r_sort = {A:dblarr(nmap^2), B:dblarr(nmap^2)}
  r_sort = r_lobe(sort(r_lobe)) ;arcsec
  y_r_sort.A = y_r_lobe.A[sort(r_lobe)]
  y_r_sort.B = y_r_lobe.B[sort(r_lobe)]
  
  r_fin = dindgen(npt)/(npt-1)*max([param.map.size_ra,param.map.size_dec]) ;Final radius 
  y_fin = {A:interpol(y_r_sort.A, r_sort, r_fin),$                         ;Finale y profile (with lobe)
           B:interpol(y_r_sort.B, r_sort, r_fin)}

  profile = {r:r_fin,$                                                         ;
             A:y_fin.A*param.kCMBperY.A*param.KRJperKCMB.A*param.JYperKRJ.A,$  ;
             B:y_fin.B*param.kCMBperY.B*param.KRJperKCMB.B*param.JYperKRJ.B,$  ;
             unit:'arcsec, Jy/Beam, Jy/Beam'}                                  ;
  
  return, profile
end
