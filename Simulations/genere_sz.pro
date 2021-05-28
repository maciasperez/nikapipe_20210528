;;Simulation of the temperature map of the tSZ signal of a cluster 
;;for a given set of parameter (gNFW) and a given map size

pro genere_sz,param, SZ_prof

  s_th = 0.665e-28                ;section efficase Thomson
  m_ec2 = 510998.918*1.602176e-19 ;masse d'un electron  

  x_sz = [4.7992375e-11*param.nu1*1e9/param.T_CMB, 4.7992375e-11*param.nu2*1e9/param.T_CMB] ;x = \frac{h \nu}{k_B T_{CMB}} in a 2d vector for both frequencies

  Omega_L = 0.73 & Omega_k = 0.0 & Omega_M = 0.27 & Omega_r = 0.0 & H_0 = 70.4

  h_z = sqrt(Omega_L + Omega_k*(1+param.z_clust)^2 + Omega_M*(1+param.z_clust)^3 + Omega_r*(1+param.z_clust)^4)
  h_70 = H_0/70.0

  P_500 = 2.64e-13 * h_z^(8.0/3.0) * (param.M_500/(3e14*h_70^(-1)))^(2.0/3.0) * h_70^(2.0/3.0)

;;;;;;;;;;COMPUTATION OF y_sz(R) AND THEN y_sz(x,y) ;;;;;;;;;;;;;;;;;;;;;;;;
  y_szr = dblarr(param.N_sky)                                                    ;Compton y radial profile
  for u=0l,param.N_sky-1 do begin                                                ;u label the indice in the vector y_szr
     min = double(u)*((param.Taille_carte/n_elements(y_szr))/param.thetac_clust) ;(Angular size between two points / theta_c) * label of the considered point
     max = 20.0                                                                  ;We considere to be out of the cluster when we get to 20 x r_c
     var = (dindgen(1000)*(max-min)/1000 + min + 1e-12)
     fonction = var^(1.0-param.c_clust)/((var^2.0+min^2.0)^0.5*(1.0+var^param.a_clust)^((param.b_clust-param.c_clust)/param.a_clust))
     integ = int_tabulated(var,fonction,/double)
     y_szr(u) = 2*s_th*param.P0_clust*param.rc_clust*3.08568e19*integ/m_ec2*P_500
  endfor
  y_szr[0] = y_szr[1]
  print, 'y_sz(r) has been computed'

  y_sz = dblarr(param.N_sky,param.N_sky) ;Compton y 2D map

  for i=0l,param.N_sky-1 do begin ;On remplie la carte mais en 2D au lieu de radial
     for j=0l,param.N_sky-1 do begin
        rad_pix = ((double(i-param.N_sky/2.0))^2 + (double(j-param.N_sky/2.0))^2)^0.5 ;radius at the given position (pixel)
        y_sz[i,j] = y_szr[round(rad_pix,/l64)]
     endfor
  endfor

  print, 'y_sz(x,y) has been computed'

;;;;;;;;;;CREATION OF THE LOBED MAP ;;;;;;;;;;;;;;;;;;;;;;;;
  k = 2*!pi*dist(param.N_sky)/param.Taille_carte
  FT_sz = FFT(y_sz,/double)
  FT_sz = FT_sz*exp(-k*k*(param.Taille_lobe/2.35482)^2.0)
  Map_y = float(FFT(FT_sz, /inverse,/double))

  ;Map_T = dblarr(param.N_sky, param.N_sky, 2)
  ;Map_T[*,*,0] = - param.T_cmb * Map_y * (4 - x_sz[0]/tanh(x_sz[0]/2)) ;Sky map (N_sky x N_sky pixel x 2) for both frequencies
  ;Map_T[*,*,1] = - param.T_cmb * Map_y * (4 - x_sz[1]/tanh(x_sz[1]/2))
  
  print, 'The SZ map has been computed for', param.nu1, '   and ', param.nu2, '  GHz'

  ;;;;;;;;;; RECONVERSION MAP TO PROFILE ;;;;;;;;;;;;;;;;;;;;;;;;
  SZ_r = dblarr(n_elements(Map_y)) ;SZ signal at both frequencies for all pixels in the map in a 2x 1D vector
  radius = dblarr(n_elements(Map_y)) ;Radius corresponding to SZ_r (unit = number of pixels)
  
  n=0l
  for i=0d,param.N_sky-1 do begin
     for j=0d,param.N_sky-1 do begin
        SZ_r[n] = Map_y[i,j]                                      ;Vecteur de y dans le desordre
        radius[n] = sqrt((i-param.N_sky/2)^2+(j-param.N_sky/2)^2) ;Vecteur de distance au centre dans le desordre
        n = n + 1
     endfor
  endfor

  ;;SZ_r is sorted by increasing radius
  radius_sort = radius(sort(radius)) & SZ_r_sort = SZ_r[sort(radius)]

  r_lobe = dindgen(10000)*param.Taille_carte/10000          ;Final radius going from 0 to Taille_carte
  y_lobe = interpol(sz_r_sort, radius_sort, dindgen(10000)) ;Finale y profile (with lobe)

  SZ_prof = [[r_lobe], [-param.T_cmb*y_lobe*(4-x_sz[0]/tanh(x_sz[0]/2))], [-param.T_cmb*y_lobe*(4-x_sz[1]/tanh(x_sz[1]/2))]] ;r, T(nu1), T(nu2)

  ;y_RXJ1347pt5m1145 = y_lobe
  ;r_RXJ1347pt5m1145 = r_lobe
  
  ;save, filename='/home/remi/IDL/SoftwareIDL/Data/Profile/Profile_RXJ1347pt5m1145.save', r_RXJ1347pt5m1145, y_RXJ1347pt5m1145
stop

  return
end
