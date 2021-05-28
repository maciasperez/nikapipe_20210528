pro test_beam_efficiency

  plotdir = '/home/perotto/NIKA/Plots/CalibTests/RUN12_OTFS_baseline3/v_1/' 
  scan = '20171025s41'  ;; beammap uranus N2R12
  
  plotdir = '/home/perotto/NIKA/Plots/Beams/FullBeams/v_1/'
  scan = '20180122s309'
  
  restore, plotdir+scan+'/results.save', /v
  map_2 = grid1.map_i_2mm
  map_1 = grid1.map_i_1mm
  var_2 = grid1.map_var_i_2mm
  var_1 = grid1.map_var_i_1mm
  rmap = sqrt(grid1.xmap^2 + grid1.ymap^2)
  dx = grid1.map_reso

  ;; maximal radius without sizable filtering in the map
  rcut_data = [70.0d0, 180.0d0] ;;60.

  ;; maximal radius (up to which the B.E. is estimated)
  rmax = 390.0d0
  
  ;; KRAMER 2013
  freq_ck   = [145.0d0, 210.0d0, 230.0d0, 280.0d0]
  fwhm_0_ck = [16.0d0, 11.0d0, 10.4d0, 8.4d0]
  fwhm_1_ck = [85.0d0, 65.0d0, 56.5d0, 50.0d0]
  fwhm_2_ck = [350.0d0, 250.0d0, 217.0d0, 175.0d0]
  fwhm_3_ck = [1200.0d0, 860.0d0, 761.0d0, 620.0d0]
  a0_ck = [1.0d0, 1.0d0, 1.0d0, 1.0d0]
  a1_ck = [8.0d-4, 1.9d-3, 2.0d-3, 2.0d-3]
  a2_ck = [2.5d-4, 3.5d-4, 4.1d-4, 5.0d-4]
  a3_ck = [1.6d-5, 2.2d-5, 3.5d-5, 5.5d-5]
  a0_ck = a0_ck-a1_ck-a2_ck-a3_ck

  beff_ck = [0.74, 0.63, 0.59, 0.49]

  nfreq_ck = n_elements(freq_ck)

  fss = [2.0d0, 6.0d0, 8.0d0, 9.0d0]
  rss = [7.0d0, 6.0d0, 8.0d0, 13.0d0] ;; 1-F_eff

  om_tot = 2.0d0*!dpi*(fwhm_0_ck*!fwhm2sigma)^2/beff_ck

  do_verif_ck2013 = 1
  
  ;; extropol to NIKA2 freq
  k = [2400.0, 13000.0, 50000.0, 175000.0]
  
  freq0  = [150d0, 260d0]
  fwhm_0 = k[0]/freq0
  fwhm_1 = k[1]/freq0
  fwhm_2 = k[2]/freq0
  fwhm_3 = k[3]/freq0
  a0 = [1.0d0,  1.0d0]
  a1 = [8.0d-4, 2.0d-3]
  a2 = [2.5d-4, 4.5d-4]
  a3 = [1.6d-5, 4.5d-5]
  a0 = a0-a1-a2-a3

  rcut = 390.0d0

  be0 = [85.0d0, 70.0d0]
  

  ;; debug
  ;;fwhm_0_ck = fwhm_0
  ;;fwhm_1_ck = fwhm_1
  ;;fwhm_2_ck = fwhm_2
  ;;fwhm_3_ck = fwhm_3
  ;;a0_ck = a0
  ;;a1_ck = a1
  ;;a2_ck = a2
  ;;a3_ck = a3
  ;;nfreq_ck = 2
  ;;beff_ck = be0
  
  if do_verif_CK2013 then begin
     
     ;; 2D
     ;;-----------------------------------------------------------
     
     sidesize = 6001
     vect = dindgen(sidesize)-sidesize/2.
     un = dblarr(sidesize)+1.0d0
     xmap = un#vect
     ymap = transpose(xmap)
     rmap_ck = sqrt(xmap^2 + ymap^2)
     dx_ck = 1.
     
     for ff = 0, nfreq_ck-1 do begin 
        
        print, ''
        print, 'FREQ = ', freq_ck[ff]
        print, '-----------------------------'
        
        fullb_ck = a0_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_0_ck[ff]*!fwhm2sigma)^2) $
                   + a1_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_1_ck[ff]*!fwhm2sigma)^2) $
                   + a2_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_2_ck[ff]*!fwhm2sigma)^2) $
                   + a3_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_3_ck[ff]*!fwhm2sigma)^2) 
        
        print, 'Main beam : ', total(a0_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_0_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)
        print, 'verif     : ', a0_ck[ff]*2.0d0*!dpi*(fwhm_0_ck[ff]*!fwhm2sigma)^2  
        
        P0 = total(a0_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_0_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/total(fullb_ck*dx_ck^2)
        P1 = total(a1_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_1_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/total(fullb_ck*dx_ck^2)
        P2 = total(a2_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_2_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/total(fullb_ck*dx_ck^2)
        P3 = total(a3_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_3_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/total(fullb_ck*dx_ck^2)
        
        print, "P0["+strtrim(string(freq_ck[ff]), 2)+"] = ", P0
        print, "P1["+strtrim(string(freq_ck[ff]), 2)+"] = ", P1
        print, "P2["+strtrim(string(freq_ck[ff]), 2)+"] = ", P2
        print, "P3["+strtrim(string(freq_ck[ff]), 2)+"] = ", P3
        
        norm = beff_ck[ff]/P0
           
        print, "P'0["+strtrim(string(freq_ck[ff]), 2)+"] = ", P0*norm
        print, "P'1["+strtrim(string(freq_ck[ff]), 2)+"] = ", P1*norm
        print, "P'2["+strtrim(string(freq_ck[ff]), 2)+"] = ", P2*norm
        print, "P'3["+strtrim(string(freq_ck[ff]), 2)+"] = ", P3*norm

        om_tot = (2.0d0*!dpi*(fwhm_0_ck[ff]*!fwhm2sigma)^2)/beff_ck[ff]
        print, "Om_tot["+strtrim(string(freq_ck[ff]), 2)+"] = ", om_tot

        print, "P'0["+strtrim(string(freq_ck[ff]), 2)+"] = ", total(a0_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_0_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/om_tot
        print, "P'1["+strtrim(string(freq_ck[ff]), 2)+"] = ", total(a1_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_1_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/om_tot
        print, "P'2["+strtrim(string(freq_ck[ff]), 2)+"] = ", total(a2_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_2_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/om_tot 
        print, "P'3["+strtrim(string(freq_ck[ff]), 2)+"] = ",  total(a3_ck[ff]*exp(-rmap_ck^2/2.0d0/(fwhm_3_ck[ff]*!fwhm2sigma)^2)*dx_ck^2)/om_tot 

        w_rest = where(rmap_ck gt 180.0d0 and rmap_ck le rmax)
        om_reste = total(fullb_ck[w_rest]*dx_ck^2)
        print, "Om_180_r_390["+strtrim(string(freq_ck[ff]), 2)+"] = ", om_reste
        
        w_4pi = where(rmap_ck gt 180.0d0)
        om_4pi = total(fullb_ck[w_4pi]*dx_ck^2)
        print, "Om_4pi["+strtrim(string(freq_ck[ff]), 2)+"] = ", om_4pi

        print, "Om_frss["+strtrim(string(freq_ck[ff]), 2)+"] = ", om_tot*(fss[ff]+rss[ff])/100.0d0
        
     endfor


     stop
   
  endif

  om_180_paper     = [446.0d0, 235.0d0]
  om_390_errorbeam = [20.0d0,   12.0d0]
  om_4pi_errorbeam = [41.0d0,   21.0d0]
  om_4pi_ss        = [40.0d0,   45.0d0] ;;  [35.0d0,   34.0d0]

  

  ;; 0MEGA 6.5 arcmin
  ;;-----------------------------------------------------------------------

  sidesize = n_elements(map_2[0, *])
  map_ = dblarr(sidesize, sidesize, 2)
  var_ = dblarr(sidesize, sidesize, 2)
  map_[*, *, 0] = map_2
  map_[*, *, 1] = map_1
  var_[*, *, 0] = var_2
  var_[*, *, 1] = var_1

  sig0 = [18.5, 12.5]*!fwhm2sigma

  
  for ff = 0, 1 do begin 
     
     print, ''
     print, 'FREQ = ', freq0[ff]
     print, '-----------------------------'
     
     fullb = a0[ff]*exp(-rmap^2/2.0d0/(fwhm_0[ff]*!fwhm2sigma)^2) $
             + a1[ff]*exp(-rmap^2/2.0d0/(fwhm_1[ff]*!fwhm2sigma)^2) $
             + a2[ff]*exp(-rmap^2/2.0d0/(fwhm_2[ff]*!fwhm2sigma)^2) $
             + a3[ff]*exp(-rmap^2/2.0d0/(fwhm_3[ff]*!fwhm2sigma)^2) 
     
     print, 'Main beam : ', total(a0[ff]*exp(-rmap^2/2.0d0/(fwhm_0_ck[ff]*!fwhm2sigma)^2)*dx^2)
     print, 'verif     : ', a0[ff]*2.0d0*!dpi*(fwhm_0_ck[ff]*!fwhm2sigma)^2  
     
     P0 = total(a0[ff]*exp(-rmap^2/2.0d0/(fwhm_0[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     P1 = total(a1[ff]*exp(-rmap^2/2.0d0/(fwhm_1[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     P2 = total(a2[ff]*exp(-rmap^2/2.0d0/(fwhm_2[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     P3 = total(a3[ff]*exp(-rmap^2/2.0d0/(fwhm_3[ff]*!fwhm2sigma)^2)*dx^2)/total(fullb*dx^2)
     
     print, "P0["+strtrim(string(freq0[ff]), 2)+"] = ", P0
     print, "P1["+strtrim(string(freq0[ff]), 2)+"] = ", P1
     print, "P2["+strtrim(string(freq0[ff]), 2)+"] = ", P2
     print, "P3["+strtrim(string(freq0[ff]), 2)+"] = ", P3

     ;;  Om_180
     w_180 = where(rmap le 180.)
     om_180 = total(fullb[w_180]*dx^2)
     print, "Om_180["+strtrim(string(freq0[ff]), 2)+"] = ", om_180

     w_max = where(rmap le rcut)
     om_cut = total(fullb[w_max]*dx^2)
     print, "Om_cut["+strtrim(string(freq0[ff]), 2)+"] = ", om_cut
     
     ;norm = beff[ff]/P0     
     ;print, "P'0["+strtrim(string(freq[ff]), 2)+"] = ", P0*norm
     ;print, "P'1["+strtrim(string(freq[ff]), 2)+"] = ", P1*norm
     ;print, "P'2["+strtrim(string(freq[ff]), 2)+"] = ", P2*norm
     ;print, "P'3["+strtrim(string(freq[ff]), 2)+"] = ", P3*norm

     maps = {Jy:map_[*, *, ff], var:var_[*, *, ff]}
     wpeak = where(map_[*, *, ff] eq max(map_[*, *, ff]), nn)
     xcen = grid1.xmap[wpeak]
     ycen = grid1.ymap[wpeak]
     
     nika_pipe_profile, dx, maps, profile, nb_prof=225, center=[xcen, ycen], no_nan=1
          
     maps = {Jy:fullb, var:fullb*0.0+1D0}
     nika_pipe_profile, dx, maps, prof_ck, nb_prof=225, center=[xcen, ycen], no_nan=1
     
     norm = max(prof_ck.y)/max(profile.y)
     
     plot, profile.r, profile.y*norm, xr = [0, 200], /xs, /nodata, /ylog
     oplot, profile.r, profile.y*norm, col=250, psym=8, symsize=0.5
     oplot, prof_ck.r, prof_ck.y, col=50, psym=8, symsize=0.5

     w_180 = where(rmap le rcut_data[ff])
     map = map_[*, *, ff]
     map = map/max(map)
     om_180_data = total(map[w_180]*dx^2)

     w_rest = where(rmap gt rcut_data[ff] and rmap le rmax)
     om_reste = total(fullb[w_rest]*dx^2)

     print, "BE_0 paper  = ", be0[ff]
     print, "BE_0 recalc = ", (2.0d0*!dpi*sig0[ff]^2)/om_180_data
     print, "BE_0 from om_180_paper = ", (2.0d0*!dpi*sig0[ff]^2)/om_180_paper[ff]
     print, "BE_0_ck     = ", (2.0d0*!dpi*sig0[ff]^2)/om_180

     ;; 390
     print, "rcut_data = ", rcut_data[ff]
     fact = 1.0d0/(1.0d0 + om_reste/om_180_data)
     print, "B.E. correcting factor 390 = ",fact
     print, "BE_0 corrected = ", (2.0d0*!dpi*sig0[ff]^2)/om_180_data*fact
     print, "BE_390 [paper] = ", (2.0d0*!dpi*sig0[ff]^2)/(om_180_paper[ff]+om_390_errorbeam[ff])
     ;; 4pi
     fact = 1.0d0/(1.0d0 + om_reste/om_180_data + om_4pi_ss[ff]/om_180_data)
     print, "B.E. correcting factor 4pi = ",fact
     print, "BE_0 corrected 4pi = ", (2.0d0*!dpi*sig0[ff]^2)/om_180_data*fact
     print, "BE_4pi [paper] = ", (2.0d0*!dpi*sig0[ff]^2)/(om_180_paper[ff]+om_4pi_errorbeam[ff] + om_4pi_ss[ff])
     
     stop
  
     endfor

  stop
     
  


  
end
