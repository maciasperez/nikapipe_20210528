;;This file executes a simulation of the observation of an object
;;(cluster, point source) with NIKA taking into account the
;;atmospheric noise. It returns the temperature Time Ordered Data for
;;each KID and the path of the scan for each KID.
;;This procedure requires the name of the created file: name_file.save

pro sim_pipeline, paramfile, New_source_planet = New_source_planet, New_source_cluster = New_source_cluster

  nika_read_params, paramfile, param ;Get the structure containing the parameters of the code from the file param_file

;;;;;;;;;;;;;;;;;;;;; CREATES TEMPERATURE MAPS OF THE SOURCE (PLANET, CLUSTER, CMB) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if keyword_set(New_source_cluster) then begin
     genere_sz, param, astro_prof  ;SZ profile: [raduis (pixel), T_{K_{cmb}}(SZ, \nu_1), T_{K_{cmb}}(SZ,\nu_2)]
     save, filename=!nika.simu_dir+'/Profile_astro.save', astro_prof
  endif

  if keyword_set(New_source_planet) then begin
     genere_planet,param, astro_prof ;Temperature RJ profile of a planet: [radius (pixel), T_planet]
     save, filename=!nika.simu_dir+'/Profile_astro.save', astro_prof
  endif

  restore, !nika.simu_dir+"/Profile_astro.save", /verb

;;;;;;;;;;;;;;;;;;;;; SCAN OF THE MAP ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  nika_fits2toi, param.scan_file, pars, regpar, regpar_a, regpar_b, kidpar, data,  units,  $
                 w8, x_0, y_0, el_source, x1=x1, x2=x2, $
                 header_pars = hpar1,  header_reg = hpar2,  k_pf = k_pf

  nsn = n_elements(data.sample)
  kidpar_a = mrdfits( param.a_kidpar_file, 1)
  kidpar_b = mrdfits( param.b_kidpar_file, 1)
  
;;  fp = mrdfits(config_file, 1, h)                             ;contains the position of the KIDs in the FP, les calibration, les fwhm,...
;;  wa = where(fp.matrix eq 'A', n_a)                           ;KIDs in matrix A
;;  wb = where(fp.matrix eq 'B', n_b)                           ;KIDs in matrix B
;;  w_on_a = where(fp.flag eq 1 and fp.matrix eq 'A', n_on_a)   ;KID which work matrix A (flag=1 <=> it works)
;;  w_on_b = where(fp.flag eq 1 and fp.matrix eq 'B', n_on_b)   ;KID which work matrix B (flag=1 <=> it works)
;;  w_off_a = where(fp.flag eq 2 and fp.matrix eq 'A', n_off_a) ;KIDs which are off matrix A flag 3 <=> decoupled, 4 for many beams, 5 or 6 weird
;;  w_off_b = where(fp.flag eq 2 and fp.matrix eq 'B', n_off_b) ;KIDs which are off matrix B
;;  
;;  x_scan_on_a = reform(dd_data[w_on_a,3,10000:20000]) & x_scan_on_b = reform(dd_data[w_on_b,3,10000:20000])      ;Scan in the sky
;;  y_scan_on_a = reform(dd_data[w_on_a,4,10000:20000]) & y_scan_on_b = reform(dd_data[w_on_b,4,10000:20000])      ;for both matrices
;;  x_scan_off_a = reform(dd_data[w_off_a,3,10000:20000]) & x_scan_off_b = reform(dd_data[w_off_b,3,10000:20000])  ;and for both on and off
;;  y_scan_off_a = reform(dd_data[w_off_a,4,10000:20000]) & y_scan_off_b = reform(dd_data[w_off_b,4,10000:20000])  ;KIDs

  data = 0 & dd_data = 0 & kidpar = 0 & rpointage = 0 & fp = 0 ;We remove this because of memory problems

;;  ;;Interpolation of the scan (x N_moy points)
;;  x_on_a = fltarr(n_elements(x_scan_on_a[*,0]), n_elements(x_scan_on_a[0,*])*param.N_moy) & y_on_a = fltarr(n_elements(y_scan_on_a[*,0]), n_elements(y_scan_on_a[0,*])*param.N_moy)
;;  x_off_a = fltarr(n_elements(x_scan_off_a[*,0]), n_elements(x_scan_off_a[0,*])*param.N_moy) & y_off_a = fltarr(n_elements(y_scan_off_a[*,0]), n_elements(y_scan_off_a[0,*])*param.N_moy)
;;  x_on_b = fltarr(n_elements(x_scan_on_b[*,0]), n_elements(x_scan_on_b[0,*])*param.N_moy) & y_on_b = fltarr(n_elements(y_scan_on_b[*,0]), n_elements(y_scan_on_b[0,*])*param.N_moy)
;;  x_off_b = fltarr(n_elements(x_scan_off_b[*,0]), n_elements(x_scan_off_b[0,*])*param.N_moy) & y_off_b = fltarr(n_elements(y_scan_off_b[*,0]), n_elements(y_scan_off_b[0,*])*param.N_moy)
;;
;;  for j=0l,n_on_a-1 do begin
;;     x_on_a[j,*] = interpol(reform(x_scan_on_a[j,*]), dindgen(n_elements(x_scan_on_a[j,*])), dindgen(n_elements(x_scan_on_a[j,*])*param.N_moy)/param.N_moy)
;;     y_on_a[j,*] = interpol(reform(y_scan_on_a[j,*]), dindgen(n_elements(y_scan_on_a[j,*])), dindgen(n_elements(y_scan_on_a[j,*])*param.N_moy)/param.N_moy)
;;  endfor
;;  for j=0l,n_off_a-1 do begin
;;     x_off_a[j,*] = interpol(reform(x_scan_off_a[j,*]), dindgen(n_elements(x_scan_off_a[j,*])), dindgen(n_elements(x_scan_off_a[j,*])*param.N_moy)/param.N_moy)
;;     y_off_a[j,*] = interpol(reform(y_scan_off_a[j,*]), dindgen(n_elements(y_scan_off_a[j,*])), dindgen(n_elements(y_scan_off_a[j,*])*param.N_moy)/param.N_moy)
;;  endfor
;;  for j=0l,n_on_b-1 do begin
;;     x_on_b[j,*] = interpol(reform(x_scan_on_b[j,*]), dindgen(n_elements(x_scan_on_b[j,*])), dindgen(n_elements(x_scan_on_b[j,*])*param.N_moy)/param.N_moy)
;;     y_on_b[j,*] = interpol(reform(y_scan_on_b[j,*]), dindgen(n_elements(y_scan_on_b[j,*])), dindgen(n_elements(y_scan_on_b[j,*])*param.N_moy)/param.N_moy)
;;  endfor
;;  for j=0l,n_off_b-1 do begin
;;     x_off_b[j,*] = interpol(reform(x_scan_off_b[j,*]), dindgen(n_elements(x_scan_off_b[j,*])), dindgen(n_elements(x_scan_off_b[j,*])*param.N_moy)/param.N_moy)
;;     y_off_b[j,*] = interpol(reform(y_scan_off_b[j,*]), dindgen(n_elements(y_scan_off_b[j,*])), dindgen(n_elements(y_scan_off_b[j,*])*param.N_moy)/param.N_moy)
;;  endfor

;;  ;;We build the temperature TOI
;;  N_pt = n_elements(x_on_a[0,*])  ;Number of data point in the TOI
;;  T_on_a = fltarr(n_on_a,N_pt)   ;TOI for matrix A, kid on
;;  T_off_a = fltarr(n_off_a,N_pt) ;TOI for matrix A, kid off
;;  T_on_b = fltarr(n_on_b,N_pt)   ;TOI for matrix B, kid on
;;  T_off_b = fltarr(n_off_b,N_pt) ;TOI for matrix B, kid off
;;
;;  for j=0l,n_on_a-1 do begin     ;On rempli les donnees scanné astro
;;     for i=0l,N_pt-1 do begin  ;Les kids ne voient pas tous la meme chose
;;        radius = sqrt(x_on_a[j,i]^2 + y_on_a[j,i]^2)
;;        T_on_a[j,i] = interpol(astro_prof[*,1], astro_prof[*,0], radius)
;;     endfor
;;  endfor
;;  print, 'Temperature TOI for KIDs on in matrix A: done'
;;  for j=0l,n_off_a-1 do begin     ;On rempli les donnees scanné astro
;;     for i=0l,N_pt-1 do begin  ;Les kids ne voient pas tous la meme chose
;;        radius = sqrt(x_off_a[j,i]^2 + y_off_a[j,i]^2)
;;        T_off_a[j,i] = interpol(astro_prof[*,1], astro_prof[*,0], radius)
;;     endfor
;;  endfor
;;  print, 'Temperature TOI for KIDs off in matrix A: done'
;;  for j=0l,n_on_b-1 do begin     ;On rempli les donnees scanné astro
;;     for i=0l,N_pt-1 do begin  ;Les kids ne voient pas tous la meme chose
;;        radius = sqrt(x_on_b[j,i]^2 + y_on_b[j,i]^2)
;;        T_on_b[j,i] = interpol(astro_prof[*,2], astro_prof[*,0], radius)
;;     endfor
;;  endfor
;;  print, 'Temperature TOI for KIDs on in matrix B: done'
;;  for j=0l,n_off_b-1 do begin     ;On rempli les donnees scanné astro
;;     for i=0l,N_pt-1 do begin  ;Les kids ne voient pas tous la meme chose
;;        radius = sqrt(x_off_b[j,i]^2 + y_off_b[j,i]^2)
;;        T_off_b[j,i] = interpol(astro_prof[*,2], astro_prof[*,0], radius)
;;     endfor
;;  endfor
;;  print, 'Temperature TOI for KIDs off in matrix B: done'  

  ;;Simulation of the atmosphere
  w1 = where( kidpar_a.type eq 1)
  time = dindgen(nsn)/!nika.f_sampling
  nika_sky_noise_2, time, kidpar_a[w1].nas_x, kidpar_a[w1].nas_y, $
                    param.cloud_vx, param.cloud_vy, param.alpha_atm, param.cloud_map_reso, $
                    sky_noise_toi, disk_convolve=param.disk_convolve
stop
;;  
;;  ;;Check some TOIs
;;  Window, 2, xsize = 1000, ysize = 400
;;  !p.multi = [0,2,1,0,1]
;;  plot, T_on_a[0,*], TITLE='Temperature TOI (Kid_on_0 and Kid_off_0, nu1)', xtitle='sampling',ytitle='TOI_T_140', /xs, /ys
;;  oplot, T_off_a[0,*], col=150
;;  plot, T_on_b[0,*], TITLE='Temperature TOI (Kid_on_0 and Kid_off_0, nu2)', xtitle='sampling',ytitle='TOI_T_220', /xs, /ys
;;  oplot, T_off_b[0,*], col=150
;;  !p.multi = 0
;;
;;  ;;Save the final TOIs
;;  save, filename='/home/remi/IDL/SoftwareIDL/SimuNIKAobs/5_Save/'+TOI_file+'.save', T_on_a, T_off_a, T_on_b, T_off_b, x_on_a, y_on_a, x_off_a, y_off_a, x_on_b, y_on_b, x_off_b, y_off_b 

end
