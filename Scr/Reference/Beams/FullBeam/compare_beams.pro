pro compare_beams, png=png, ps=ps, pdf=pdf

  ;; window size
  wxsize = 600.
  wysize = 440.
  ;; plot size in files
  pxsize = 12.3
  pysize = 9.
  ;; charsize
  charsize  = 1.0
  if keyword_set(png) then png = 1 else png=0 
  if keyword_set(ps) then charthick = 3.0 else charthick = 1.0 
  if keyword_set(ps) then thick     = 3.0 else thick = 2.0
  symsize   = 0.7
  decibel=1

  plot_dir = '/home/perotto/NIKA/Plots/Beams/FullBeams/'
  
  freq0     = [150d0, 260d0]

  nfreq     = n_elements(freq0)
  nmodel    = 3
  fwhm      = dblarr(4, nfreq, nmodel)
  amp       = dblarr(4, nfreq, nmodel)

  ;; maximal radius without sizable filtering in the map
  rcut_data = [90.0d0, 90.0d0];[70.0d0, 180.0d0] ;;[3600.0d0, 3600.0d0]

  
  ;; EMIR (Kramer 2013)
  ;; -----------------------------------------------
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

  ;; extropol to NIKA2 freq
  k = [2400.0, 13000.0, 50000.0, 175000.0]
  
  fwhm[0, *, 0] = k[0]/freq0
  fwhm[1, *, 0] = k[1]/freq0
  fwhm[2, *, 0] = k[2]/freq0
  fwhm[3, *, 0] = k[3]/freq0
  amp[ 0, *, 0] = [1.0d0,  1.0d0]
  amp[ 1, *, 0] = [8.0d-4, 2.0d-3]
  amp[ 2, *, 0] = [2.5d-4, 4.5d-4]
  amp[ 3, *, 0] = [1.6d-5, 4.5d-5]
  amp[ 0, 0, 0] = amp[ 0, 0, 0] - total(amp[1:3, 0, 0])
  amp[ 0, 1, 0] = amp[ 0, 1, 0] - total(amp[1:3, 1, 0])


  ;; GISMO2 (Private Comm.)
  fwhm[0, *, 2] = [17.0, 11.0] ;; copy NIKA2
  fwhm[1, *, 2] = [39.0, 30.0]
  fwhm[2, *, 2] = [86.0, 81.0]
  fwhm[3, *, 2] = [180.0, 180.0] ;; placeholder
  amp[ 1, *, 2] = exp([-8.3, -11.4]*alog(10.d0)/10.d0)
  amp[ 2, *, 2] = exp([-18.3, -26.0]*alog(10.d0)/10.d0)
  amp[ 3, *, 2] = [0.0d0, 0.0d0]; exp([-60.0, -60.0]*alog(10.d0)/10.d0) ;; placeholder
  amp[ 0, 0, 2] = 1.0d0 - total(amp[1:3, 0, 1])
  amp[ 0, 1, 2] = 1.0d0 - total(amp[1:3, 1, 1])

  ;; NIKA2 (Table 5 Calib'n'Perf)
  fwhm[0, *, 1] = [17.4, 10.8]
  fwhm[1, *, 1] = [42.0, 30.0]
  fwhm[2, *, 1] = [99.0, 81.0]
  fwhm[3, *, 1] = [180.0, 180.0]
  amp[ 0, *, 1] = exp([-0.24, -0.33]*alog(10.d0)/10.d0)
  amp[ 1, *, 1] = exp([-12.8, -11.4]*alog(10.d0)/10.d0)
  amp[ 2, *, 1] = exp([-27.0, -26.0]*alog(10.d0)/10.d0)
  amp[ 3, *, 1] = [0.0d0, 0.0d0]; exp([-60.0, -60.0]*alog(10.d0)/10.d0)
  amp[ 0, 0, 1] = 1.0d0 - total(amp[1:3, 0, 2])
  amp[ 0, 1, 1] = 1.0d0 - total(amp[1:3, 1, 2])


  ;; Forward and rearward spillover and scattering
  eta_fss = [2.0d0, 8.0d0] 
  eta_rss = [8.5d0, 10.0d0] 
  
;;----------------------------------------------------------------------------------------------
  ylog = 1
     
  min = 1d-5
  max = 10.
  if decibel then begin
     min = -50.0
     max = 5.0
     ylog=0
  endif

  
   plot_color_convention, col_a1, col_a2, col_a3, $
                          col_mwc349, col_crl2688, col_ngc7027, $
                          col_n2r9, col_n2r12, col_n2r14
   
   couleur = [90, 160, 45]
   couleur = [160, col_n2r9, col_n2r14]
  frequence = ['150', '260']
  
  sidesize = 3600.0d0
  r0 = dindgen(7200)/7200.d0*sidesize
  dr0 = 0.5d0

  models = ['EMIR',  'NIKA2', 'GISMO2']
  nmod = 2
  for ifreq = 0, 1 do begin
     
     wind, 1, 1, /free, xsize=wxsize, ysize=wysize
     outfile = plot_dir+'plot_profiles_'+frequence[ifreq]+'_v2'
     outplot, file=outfile, png=png, ps=ps, xsize=pxsize, ysize=pysize, charsize=charsize, thick=thick, charthick=charthick
     plot, r0, r0,  yr=[min, max], /ys, xr=[1., 500.], /xs, /nodata, $
           ytitle="Beam profile [dB]", xtitle="Radius [arcsec]", /xlog ;, ytickformat='(e9.0)'
     
     emir_prof = amp[0,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[0, ifreq, 0]*!fwhm2sigma)^2) + $
                 amp[1,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[1, ifreq, 0]*!fwhm2sigma)^2) + $
                 amp[2,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[2, ifreq, 0]*!fwhm2sigma)^2) + $
                 amp[3,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[3, ifreq, 0]*!fwhm2sigma)^2)
     hyb_prof = emir_prof
     om_tot_emir = total(emir_prof*2.0d0*!dpi*r0*dr0)
     
     for imod = 0, nmod-1 do begin
        
      avg_prof = amp[0,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[0, ifreq, imod]*!fwhm2sigma)^2) + $
                 amp[1,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[1, ifreq, imod]*!fwhm2sigma)^2) + $
                 amp[2,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[2, ifreq, imod]*!fwhm2sigma)^2) + $
                 amp[3,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[3, ifreq, imod]*!fwhm2sigma)^2)

      if imod gt 0 then hyb_prof = (1.0d0-amp[2,ifreq, 0]-amp[3, ifreq, 0])*($
                 amp[0,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[0, ifreq, imod]*!fwhm2sigma)^2) + $
                 amp[1,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[1, ifreq, imod]*!fwhm2sigma)^2) + $
                 amp[2,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[2, ifreq, imod]*!fwhm2sigma)^2) + $
                 amp[3,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[3, ifreq, imod]*!fwhm2sigma)^2)) + $
                 amp[2,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[2, ifreq, 0]*!fwhm2sigma)^2) + $
                 amp[3,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[3, ifreq, 0]*!fwhm2sigma)^2)
      
      print, ''
      print, models[imod]
      wr = where(r0 le rcut_data[ifreq], compl=wr_compl)
      om_mb  = total(exp(-(r0[wr])^2/2.0/(fwhm[0, ifreq, imod]*!fwhm2sigma)^2)*2.0d0*!dpi*r0[wr]*dr0)
      om_mb_ = 2.0d0*!dpi*(fwhm[0, ifreq, imod]*!fwhm2sigma)^2
      om_tot = total(avg_prof[wr]*2.0d0*!dpi*r0[wr]*dr0)
      corr_om_tot = total(avg_prof[wr]*2.0d0*!dpi*r0[wr]*dr0)+total(emir_prof[wr_compl]*2.0d0*!dpi*r0[wr_compl]*dr0)
      hyb_om_tot = total(hyb_prof*2.0d0*!dpi*r0*dr0)
      print, '2pi sig^2 ', om_mb_
      print, 'om_mb up to ', string(rcut_data[ifreq]), om_mb
      print, 'om_tot up to ', string(rcut_data[ifreq]), om_tot
      print, 'BE up to ', string(rcut_data[ifreq]), om_mb/om_tot
      print, 'BE up to ', string(rcut_data[ifreq]), om_mb_/om_tot
      print, 'Corrected BE at r=', string(rcut_data[ifreq]), om_mb_/corr_om_tot
      print, 'Hybrid BE ', om_mb_/hyb_om_tot
      print, 'Hybrid BE + FRSS', om_mb_/hyb_om_tot/(1.0d0+(eta_fss[ifreq]+eta_rss[ifreq])/100.0d0)
      print, 'Hybrid BE + FRSS', om_mb_/(hyb_om_tot+(eta_fss[ifreq]+eta_rss[ifreq])/100.0d0*om_tot_emir)
      print, 'Check normalisation ', avg_prof[0], hyb_prof[0]
      
      if decibel then avg_prof = 10.d0*alog(avg_prof)/alog(10.d0)
      if decibel then hyb_prof = 10.d0*alog(hyb_prof)/alog(10.d0)
      
      oplot, r0, avg_prof, col = couleur[imod], thick=thick*1.5
      oplot, r0, hyb_prof, col = couleur[imod], thick=thick*2.5
      
      ;if decibel then for ii = 0, 3 do oplot, r0, alog(amp[ii,ifreq, imod]*exp(-(r0)^2/2.0/(fwhm[ii, ifreq, imod]*!fwhm2sigma)^2))*10.d0/alog(10.d0), col = couleur[imod], thick=thick
      
     endfor
     
     if decibel then for ii = 0, 3 do oplot, r0, alog(amp[ii,ifreq, 0]*exp(-(r0)^2/2.0/(fwhm[ii, ifreq, 0]*!fwhm2sigma)^2))*10.d0/alog(10.d0), col = couleur[0], thick=thick
     
      oplot, rcut_data[ifreq]*[1d0, 1d0], [min, max]
      legendastro, models[0:nmod-1], textcolor=couleur[0:nmod-1], box=0, charsize=charsize, pos=[180, 0.]
      outplot, /close

      if keyword_set(pdf) then my_epstopdf_converter, outfile

      stop
  endfor
  


end
