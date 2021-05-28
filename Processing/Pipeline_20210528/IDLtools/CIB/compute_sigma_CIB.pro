;+
;PURPOSE: Compute the CIB RMS from undetected sources
;
;INPUT: none
;
;LAST EDITION: 
;   11/2015: creation
;-

Pro compute_sigma_CIB, plot=plot, simu_map=simu_map, RA = RA, GL=GL
  
  ;;---------- Gaussian BEAMS 
  beam_fwhm1mm = 12.0
  beam_fwhm2mm = 18.2
  beam_fwhm1mm = 22.0
  beam_fwhm2mm = 22.0
  
  ;;---------- IR GALAXIES SHOT NOISE 
  ;;flux_cut_150 = 0.8 *1.e-3 * 5.0 ; 5 sigma Jy
  ;;flux_cut_260 = 2.9 * 1.e-3 * 5.0
  flux_cut_150 = 0.16 *1.e-3 * 5.0 ; 5 sigma Jy
  flux_cut_260 = 0.63 * 1.e-3 * 5.0

  ;; check: planck flux cuts
  ;; flux_cut_150 = 350 *1.e-3  ; 5 sigma Jy
  ;; flux_cut_260 = 225 *1.e-3  ; 5 sigma Jy

  ;; PATHS
  IF KEYWORD_SET(GL) THEN DEFSYSV, '!nika_dir', "/Users/glagache/NIKA/Processing"
  IF KEYWORD_SET(RA) THEN DEFSYSV, '!nika_dir', !nika.soft_dir

  ;;---------- Transfer function
  IF KEYWORD_SET(GL) THEN tf = mrdfits('/data/NIKA/MACSJ1424/TransferFunction.fits', 1, h)
  IF KEYWORD_SET(RA) THEN BEGIN
     tf_file = '/Users/adam/Project/NIKA/Notes-Papier-Conf/2015_10_MACSJ0717_Paper/IDL/Save/TransferFunction.fits'
     tf = mrdfits(tf_file, 2, h)
  ENDIF

  ;;========== Compute
  ;; READ BEST FIT PLANCK CIB MODEL 1h+2h
  ;; spectra in Jy^2/sr (nuInu=cst)
  readcol, !nika_dir +'/Pipeline/IDLtools/CIB/all_best_fit.txt', ell,Cl857x857,Cl545x545,Cl353x353,Cl217x217,Cl3000x3000,Cl857x545,Cl857x353,Cl857x217,$ 
           Cl545x353,Cl545x217,Cl353x217, Cl3000x857,Cl3000x545,Cl3000x353,Cl3000x217,Cl100x100, Cl857x100, Cl545x100,Cl353x100,Cl217x100, $
           Cl143x143, Cl857x143,Cl545x143,Cl353x143,Cl217x143,Cl143x100, /silent
  
  ;; BANDPASS CONVERSION FACTOR 143 <=> 150GHz and 220 <=> 260 GHz
  ;; bandpass: /Users/glagache/NIKA/Processing/Pipeline/Calibration/BP/NIKA_bandpass_Run8.fits
  ;; .r /Users/glagache/Planck/Work/CIB/CIB_measure/Consistency/CC_UnitConv/compute_filter_corrections_CIB.pro
  ;;compute_filter_corrections_CIB, K
  ;;K_143_150 = K(1,14) ; =0.810280
  ;;K_217_260 = K(2,15) ; =0.668724
  K_143_150_CIB = 0.810280
  K_217_260_CIB = 0.668724
  K_143_150_radio = 1.01533
  K_217_260_radio = 1.11648

  ;; CIB (1h+2h) POWER SPECTRA:
  cl_cib_260 = Cl217x217 / K_217_260_CIB^2.
  cl_cib_150 = Cl143x143 / K_143_150_CIB^2.
  k_cib = ell/(60.*180./!pi*2.*!pi) ; arcmin^-1
  
  ;; NIKA TRANSFER FUNCTION
  k_tf = 60.*tf.WAVE_NUMBER_ARCSEC ; arcmin^-1
  ell_tf = 2.*!pi * k_tf*(60.*180./!pi)
  cl_tf = (tf.tf)^2. 
  
  ;; Gaussian BEAMS 
  sigma_260 = beam_fwhm1mm/60*!fwhm2sigma*!arcmin2rad
  clbeam_260 = exp(-ell_tf^2*sigma_260^2.)
  sigma_150 = beam_fwhm2mm/60*!fwhm2sigma*!arcmin2rad
  clbeam_150 = exp(-ell_tf^2*sigma_150^2.)
  
  ;; PLOT
  IF KEYWORD_SET(PLOT) THEN BEGIN
     set_plot,'ps'
     device, file='power_spectra.ps', /color
     !p.charsize=1.2 
     pp=4 & !p.charthick=pp
     plot, k_cib, cl_cib_260, /ylog, /xlog, xr=[1.e-2, 30.], yr=[0.1, 1.e3], xtitle='k [arcmin!u-1!n]', ytitle='P(k) [Jy!u2!nsr!u-1!n]', $
           xthick=pp, ythick=pp, thick=pp, /xsty, /ysty
     oplot, k_cib, cl_cib_150, thick=pp, line=2
     oplot, k_tf, cl_tf*100., color=250, thick=pp
     oplot, k_tf, clbeam_260*100, color=80, thick=pp
     oplot, k_tf, clbeam_150*100, color=80, thick=pp, line=2
     legend, ['260', '150', 'Cl TFx100', 'Cl Beamx100'], color=[0, 0, 250, 80], box=0, /left, /bottom, line=[0,2,0, 0]
  ENDIF
  
  ;; counts from Bethermin+2000 (model)
  restore, !nika_dir+'/Pipeline/IDLtools/CIB/Bethermin2012model_grids.save'
  counts_217_z = reform(DNDSNUDZ(*,*,12)) 
  counts_143_z = reform(DNDSNUDZ(*,*,13))
  counts_217=fltarr(200)        ; dN/dS
  counts_143=fltarr(200)
  
  FOR i=0, 199 DO BEGIN
     t=reform(counts_217_z(i,*)) 
     bad = where(finite(t) EQ 0, cnt) 
     if cnt NE 0 then t(bad)=0 
     counts_217(i)=integral(z, t, min(z), max(z)) 
     
     t=reform(counts_143_z(i,*)) 
     bad = where(finite(t) EQ 0, cnt) 
     if cnt NE 0 then t(bad)=0 
     counts_143(i)=integral(z, t, min(z), max(z)) 
  ENDFOR
  
  ;; DUSTY GAL SHOT NOISE
  g=where(Snu LT flux_cut_260) 
  ;; should be an equivalent flux_cut at 217 but shot_217 not really sensitive to the exact flux cut at such flux
  shot_217 = integral(Snu(g), counts_217(g)*Snu(g)^2., min(Snu(g)), max(Snu(g))) 
  shot_260_IR = shot_217/ K_217_260_CIB^2. * 1.119^2. ;(nuInu=cst, see Planck 2013 XXX)
  
  g=where(Snu LT flux_cut_150)  ; same flux cut between 150 and 143
  shot_143 = integral(Snu(g), counts_143(g)*Snu(g)^2., min(Snu(g)), max(Snu(g))) 
  shot_150_IR = shot_143/ K_143_150_CIB^2. * 1.017^2. ;(nuInu=cst, see Planck 2013 XXX)
  
  ;; RADIO SHOT NOISE
  ;; Computed using Marco Tucci's note (Planck consistency wiki pages)
  
  ;; Planck 143 GHz  (as a check)
  ;; A=10^1.240 & S0 = 10^(-3.293) & alpha= 0.0948 & beta = -0.769 & Scut= 0.25
  ;; NIKA 150 GHz
  A=10^1.240 & S0 = 10^(-3.293) & alpha= 0.0948 & beta = -0.769 & Scut= flux_cut_150
  compute_SN_radio, A, Scut, S0, alpha, beta, Cell
  shot_150_radio = Cell / K_143_150_radio^2. ; nuInu=cst
  
  ;; 260 GHz
  A=10^1.204 & S0 = 10^(-3.173) & alpha= 0.1152 & beta = -0.479 & Scut= flux_cut_260
  compute_SN_radio, A, Scut, S0, alpha, beta, Cell
  shot_260_radio = Cell / K_217_260_radio^2. ; nuInu=cst
  
  ;; TOTAL SHOT NOISE
  shot_260 = shot_260_IR + shot_260_radio
  shot_150 = shot_150_IR + shot_150_radio

  ;; print, "Shot noise 260 dusty", shot_260_IR 
  ;; print, "Shot noise 260 radio", shot_260_radio
  ;; print, "Shot noise 150 dusty", shot_150_IR 
  ;; print, "Shot noise 150 radio", shot_150_radio
  ;; print, '--------------------------'

  ;; OPLOT
  IF KEYWORD_SET(PLOT) THEN BEGIN
     oplot, k_tf, replicate(shot_260, n_elements(k_tf)), thick=pp
     oplot, k_tf, replicate(shot_150, n_elements(k_tf)),thick=pp, line=2
     device, /close
     set_plot, 'x'
  ENDIF
  
  ;; COMPUTE RMS: CONSIDER ONLY SHOT NOISE AT THE END! (i.e. not 1h+2h CIB)
  sigma2_260=int_tabulated(k_tf, 2. * !pi * k_tf * shot_260[0] *  cl_tf * clbeam_260 ,/sort) ; ktf in arcmin
  sigma2_150=int_tabulated(k_tf, 2. * !pi * k_tf * shot_150[0] *  cl_tf * clbeam_150 ,/sort)  
  fluc_260= sqrt(sigma2_260*(180./!pi)^2.*3600)/1.e6 ; MJy/sr
  fluc_150= sqrt(sigma2_150*(180./!pi)^2.*3600)/1.e6 ; MJy/sr
  
  print, '1sigma fluctuation @ 150 GHz', fluc_150, '  MJy/sr nuInu=cst'
  print, '1sigma fluctuation @ 260 GHz', fluc_260, '  MJy/sr nuInu=cst'
  
  print, '1sigma fluctuation @ 150 GHz', fluc_150/(715.0*0.561*2.48/10.9)*1e3, '  mJy/beam nuInu=cst'
  print, '1sigma fluctuation @ 260 GHz', fluc_260/(2132.0*0.225*1.59/3.44)*1e3, '  mJy/beam nuInu=cst'
  
  ;;========== Simulate a (dusty+radio gal) shot noise map assuming it is gaussian
  if keyword_Set(simu_map) then begin
     nx = 151
     ny = 151
     nx_plus = nx/2             ;Increase map size to avoid edge and loop effect
     ny_plus = ny/2             ;
     reso = 1.0

     ell = 2*!pi * k_tf*(60.0*180.0/!pi)
     clt1 = replicate(shot_260, n_elements(ell)) * clbeam_260 * cl_tf ;2 version to check that the beam is right
     clt2 = replicate(shot_260, n_elements(ell)) * cl_tf              ;
     clt1 = clt1 * 1e-12                                              ;clt in MJy^2/sr --> map in MJy/sr
     clt2 = clt2 * 1e-12                                              ;
     
     cls2map, ell, clt1, nx+nx_plus*2, ny+ny_plus*2, reso/60.0, simu1mm_cib1, cu_t, k_map, k_mapx, k_mapy
     cls2map, ell, clt2, nx+nx_plus*2, ny+ny_plus*2, reso/60.0, simu1mm_cib2, cu_t, k_map, k_mapx, k_mapy

     simu1mm_cib2 = filter_image(simu1mm_cib2, fwhm=beam_fwhm2mm/reso, /all) ;To check beam effect
     simu1mm_cib1 = simu1mm_cib1[nx_plus:nx+nx_plus-1,ny_plus:ny+ny_plus-1]
     simu1mm_cib2 = simu1mm_cib2[nx_plus:nx+nx_plus-1,ny_plus:ny+ny_plus-1]

     simu2mm_cib1 = simu1mm_cib1 * fluc_150/fluc_260 ;Assume 100% correlation
     simu2mm_cib2 = simu1mm_cib2 * fluc_150/fluc_260 ;Assume 100% correlation

     simu1mm_cib1 = simu1mm_cib1/(2132.0*0.225*1.59/3.44)*1e3 ;To mJy/beam
     simu1mm_cib2 = simu1mm_cib2/(2132.0*0.225*1.59/3.44)*1e3 ;
     simu2mm_cib1 = simu2mm_cib1/(715.0*0.561*2.48/10.9)*1e3  ;
     simu2mm_cib2 = simu2mm_cib2/(715.0*0.561*2.48/10.9)*1e3  ;

     set_plot,'ps'
     device, file='simu_map.ps', /color
     !p.multi = [0,2,2]
     dispim_bar, simu1mm_cib1, /asp, /noc, title='CIB260, mJy/b, beam in spectra', xtitle='arcsec x '+strtrim(reso,2)
     dispim_bar, simu1mm_cib2, /asp, /noc, title='CIB260, mJy/b, beam in real space', xtitle='arcsec x '+strtrim(reso,2)
     dispim_bar, simu2mm_cib1, /asp, /noc, title='CIB150, mJy/b, beam in spectra', xtitle='arcsec x '+strtrim(reso,2)
     dispim_bar, simu2mm_cib2, /asp, /noc, title='CIB150, mJy/b, beam in real space', xtitle='arcsec x '+strtrim(reso,2)
     !p.multi = 0
     device, /close
     set_plot, 'x'

     ;;---------- Check that RMS is ok compared to integration in spectra
     print, 'RMS map1 simu @ 150 GHz', stddev(simu2mm_cib1), '  mJy/beam nuInu=cst'
     print, 'RMS map2 simu @ 150 GHz', stddev(simu2mm_cib2), '  mJy/beam nuInu=cst'
     print, 'RMS map1 simu @ 260 GHz', stddev(simu1mm_cib1), '  mJy/beam nuInu=cst'
     print, 'RMS map2 simu @ 260 GHz', stddev(simu1mm_cib2), '  mJy/beam nuInu=cst'
  endif  

END
