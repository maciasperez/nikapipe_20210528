;+
;PURPOSE: Beam analysis sub-pipeline
;
;INPUT: The reduction and map analysis parameter structures. 
;
;OUTPUT: what you set in the parameter files
;
;KEYWORDS:
;
;LAST EDITION: 
;   25/09/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_beam, param, anapar, ps=ps
  ;;---- To do :
  ;;   - Single gaussian fit of the beam ----------------------------- Done
  ;;   - Profile of the beam ----------------------------------------- Done
  ;;   - Integrated profile of the beam ------------------------------ Done
  ;;   - Fraction of the main beam ----------------------------------- Done
  ;;   - 3 gaussian fit of the beam ---------------------------------- Done
  ;;   - Fit of the beam as: ----------------------------------------- Done
  ;;     B(x) = A0 + A1 exp(-x^2/2/A2^2) + A3 Erf(-(x-A4)/A5) -------- Done
  ;;   - Plot the beam profile (log,log) ----------------------------- Done
  ;;   - Plot the integrated beam profile (log,log) ------------------ Done
  ;;   - Get the dispersion between many scans (FWHM, offsets, ...) -- Done
  ;;   - Use parinfo in beam fitting (see nika_pipe_fit_beam) -------- Done
  ;;   - Put results in a FITS file ---------------------------------- Done
  
  ;;==================== Extract useful variables
  ;;------- Get the maps
  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)+$
            anapar.cor_zerolevel.A
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',1,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)+$
            anapar.cor_zerolevel.B
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',1,head_2mm,/SILENT)
  
  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  
  ;;==================== Fitting session
  ;;------- Model simple gaussien
  nika_pipe_fit_beam, map_1mm, reso1mm, $
                      coeff=coeff_gauss1mm, best_fit=map_flux_model_a, var_map=noise_1mm^2,$
                      /TILT, CIRCULAR=CIRCULAR, center=[0,0], search_box=[20,20],$
                      FWHM=FIXED_FWHM_A
  nika_pipe_fit_beam, map_2mm, reso2mm, $
                      coeff=coeff_gauss2mm, best_fit=map_flux_model_b, var_map=noise_2mm^2,$
                      /TILT, CIRCULAR=CIRCULAR, center=[0,0], search_box=[20,20], $
                      FWHM=FIXED_FWHM_B
  print, '   '
  ;;------- Fit the plateau with B(t) = A0 + A1 exp(-t^2/2/A2^2) + A3 Erf(-(t-A4)/A5)
  nika_anapipe_fitplateau, reso1mm, map_1mm, noise_1mm, $
                           best_fit=bestfit_plateau1mm, coeff=coeff_plateau1mm, center=coeff_gauss1mm[4:5]
  nika_anapipe_fitplateau, reso2mm, map_2mm, noise_2mm, $
                           best_fit=bestfit_plateau2mm, coeff=coeff_plateau2mm, center=coeff_gauss2mm[4:5]

  print, '   '
  ;;------- Triple gaussian fit
  nika_anapipe_triple_beam_fit, reso1mm, map_1mm, noise_1mm, $
                                best_fit=bestfit_triple1mm, coeff=coeff_triple1mm, $
                                center=coeff_gauss1mm[4:5]
  nika_anapipe_triple_beam_fit, reso2mm, map_2mm, noise_2mm, $
                                best_fit=bestfit_triple2mm, coeff=coeff_triple2mm, $
                                center=coeff_gauss2mm[4:5]

  ;;==================== Angular distributions
  ;;------- Profile
  maps_1mm = {Jy:map_1mm, var:noise_1mm^2}
  maps_2mm = {Jy:map_2mm, var:noise_2mm^2}
  nika_pipe_profile, reso1mm, maps_1mm, flux_prof1mm, nb_prof=100, center=coeff_gauss1mm[4:5]
  nika_pipe_profile, reso2mm, maps_2mm, flux_prof2mm, nb_prof=100, center=coeff_gauss2mm[4:5]

  ;;------- Integration
  rmax = 300.0
  radius_max = dindgen(100)/99*rmax+3 ;maximum radius to compute the integrated flux (arcsec)
  flux_int1mm = nika_pipe_integmap(map_1mm, reso1mm, radius_max, $
                                   center=coeff_gauss1mm[4:5], var_map=noise_1mm^2, err=err_integ1mm)
  flux_int2mm = nika_pipe_integmap(map_2mm, reso2mm, radius_max, $
                                   center=coeff_gauss2mm[4:5], var_map=noise_2mm^2, err=err_integ2mm)

  ;;------- Normalize the flux density map to the beam map
  beam_map1mm = map_1mm/coeff_gauss1mm[1]
  beam_map2mm = map_2mm/coeff_gauss2mm[1]
  beam_noise1mm = noise_1mm/coeff_gauss1mm[1]
  beam_noise2mm = noise_2mm/coeff_gauss2mm[1]

  beam_radius = flux_prof1mm.r
  beam_profile1mm = flux_prof1mm.y/coeff_gauss1mm[1]
  beam_profile2mm = flux_prof2mm.y/coeff_gauss2mm[1]
  beam_profilenoise1mm = sqrt(flux_prof1mm.var)/coeff_gauss1mm[1]
  beam_profilenoise2mm = sqrt(flux_prof2mm.var)/coeff_gauss2mm[1]
  beam_integ1mm = flux_int1mm/coeff_gauss1mm[1]
  beam_integ2mm = flux_int2mm/coeff_gauss2mm[1]

  ;;==================== Fraction of the main beam
  ;;------- Give the fraction of the main beam in different cases
  rad_omega = [30.0, 60.0, 90.0, 120.0] ;radius at which we want the solid angle
  omega_1mm = [max(beam_integ1mm[where(radius_max lt rad_omega[0])]),$
               max(beam_integ1mm[where(radius_max lt rad_omega[1])]),$
               max(beam_integ1mm[where(radius_max lt rad_omega[2])]),$
               max(beam_integ1mm[where(radius_max lt rad_omega[3])])]
  omega_2mm = [max(beam_integ2mm[where(radius_max lt rad_omega[0])]),$
               max(beam_integ2mm[where(radius_max lt rad_omega[1])]),$
               max(beam_integ2mm[where(radius_max lt rad_omega[2])]),$
               max(beam_integ2mm[where(radius_max lt rad_omega[3])])]

  print, '   '
  print, '   '
  print, '---------------------------------------------------'
  print, '---------------------------------------------------'
  print, '---- Fraction of secondary beam computed at 30", 60" 90" and 120"'
  print, '---- 1.25 mm: '
  print, '----      Case of 12.5" main beam         '
  print, strtrim(100*(omega_1mm/2/!pi/(12.5*!fwhm2sigma)^2 -1),2) + ' %  '
  print, '----      Case of single gaussian fit     '
  print, strtrim(100*(omega_1mm/2/!pi/(sqrt(coeff_gauss1mm[2]*coeff_gauss1mm[3])*!fwhm2sigma)^2 -1),2) + ' %'
  print, '----      Case of gaussian + plateau fit  '
  print, strtrim(100*(omega_1mm/2/!pi/(coeff_plateau1mm[2]*!fwhm2sigma)^2 -1),2) + ' % '
  print, '----      Case of triple gaussian fit     '
  print, strtrim(100*(omega_1mm/2/!pi/(coeff_triple1mm[1]*!fwhm2sigma)^2 -1),2) + ' % '
  print, '   '
  print, '---- 2.05 mm: '
  print, '----      Case of 18.5" main beam         '
  print, strtrim(100*(omega_2mm/2/!pi/(18.5*!fwhm2sigma)^2 -1),2) + ' % '
  print, '----      Case of single gaussian fit     '
  print, strtrim(100*(omega_2mm/2/!pi/(sqrt(coeff_gauss2mm[2]*coeff_gauss2mm[3])*!fwhm2sigma)^2 -1),2) + ' %'
  print, '----      Case of gaussian + plateau fit  '
  print, strtrim(100*(omega_2mm/2/!pi/(coeff_plateau2mm[2]*!fwhm2sigma)^2 -1),2) + ' % '
  print, '----      Case of triple gaussian fit     '
  print, strtrim(100*(omega_2mm/2/!pi/(coeff_triple2mm[1]*!fwhm2sigma)^2 -1),2) + ' % '
  print, '---------------------------------------------------'
  print, '--- I would suggest to use the simple gaussian fit since it is what is used for normalization'
  print, '---------------------------------------------------'


  ;;------- Plot beam allowing to see the error beam
  if anapar.beam.fsl eq 'yes' then nika_anapipe_fsl, param, anapar, $
     beam_map1mm, beam_map2mm, beam_noise1mm, beam_noise2mm, head_1mm, head_2mm, ps=ps
  

  ;;==================== Plots
  ;;------- Integrated beam
  mydevice = !d.name
  SET_PLOT, 'PS'
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_integ_1mm.ps'
  plot, radius_max, beam_integ1mm, $
        xtitle='Angular distance (arcsec)', ytitle='Integrated beam (arcsec!U2!N)', $
        xrange=[0,200], xstyle=1, /nodata, charsize=1.5, charthick=3
  oploterror, radius_max, beam_integ1mm, err_integ1mm, col=50, thick=3, ERRTHICK=2, ERRcol=50
  oplot, radius_max, radius_max*0+2*!pi*!fwhm2sigma^2*(coeff_gauss1mm[2]*coeff_gauss1mm[3]), $
         col=250, thick=3, linestyle=2
  legendastro,['Observed integrated beam', 'Main integrated beam'], $
         charsize=1, charthick=3, col=[50,250], psym=[0,0], thick=[1,1], symsize=[1,1], $
         linestyle=[0,2],/right, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_integ_1mm'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_integ_2mm.ps'
  plot, radius_max, beam_integ2mm, $
        xtitle='Angular distance (arcsec)', ytitle='Integrated beam (arcsec!U2!N)', $
        xrange=[0,200], xstyle=1, /nodata, charsize=1.5, charthick=3
  oploterror, radius_max, beam_integ2mm, err_integ1mm, col=50, thick=3, ERRTHICK=2, ERRcol=50
  oplot, radius_max, radius_max*0+2*!pi*!fwhm2sigma^2*(coeff_gauss2mm[2]*coeff_gauss2mm[3]), $
         col=250, thick=3, linestyle=2
  legendastro,['Observed integrated beam', 'Main integrated beam'], $
         charsize=1, charthick=3, col=[50,250], psym=[0,0], thick=[1,1], symsize=[1,1], $
         linestyle=[0,2],/right, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_integ_2mm'

  ;;------- Plot the beam profile
  ;;Profile 1mm
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_1mm.ps'
  ploterror, beam_radius, beam_profile1mm, beam_profilenoise1mm, $
             xtitle='radius (arcsec)', ytitle='Normalized beam response',$
             psym=1, /xlog,/ylog,yrange=[1e-5,1.5],xrange=[1,200], ystyle=1, xstyle=1,/nodata,$
             charsize=1.5, charthick=3
  oploterror, beam_radius, abs(beam_profile1mm), beam_profilenoise1mm,$
              col=200, errcolor=180, errthick=2, psym=8, symsize=0.7
  oploterror, beam_radius, beam_profile1mm, beam_profilenoise1mm, $
              col=50, errcolor=100,errthick=2,psym=8, symsize=0.7
  oplot, radius_max, beam_integ1mm/max(beam_integ1mm), col=250, thick=3
  if anapar.beam.oplot eq 'yes' then begin
     oplot, radius_max, anapar.beam.amp1.A*exp(-radius_max^2/(2*(anapar.beam.beam1.A*!fwhm2sigma)^2)) + $
            anapar.beam.amp2.A*exp(-radius_max^2/(2*(anapar.beam.beam2.A*!fwhm2sigma)^2)) + $
            anapar.beam.amp3.A*exp(-radius_max^2/(2*(anapar.beam.beam3.A*!fwhm2sigma)^2)),$
            col=150,thick=3
     legendastro,['Observed beam (positive data)', 'Observed beam (negative data)', 'Fraction of the beam', 'Model'], $
            charsize=1, charthick=3, col=[50,200,250,150], psym=[8,8,0,0], thick=[2,2,2,2], symsize=[1,1,1,1], $
            /left, /bottom, box=0
  endif else legendastro,['Observed beam (positive data)', 'Observed beam (negative data)', 'Fraction of the beam'], $
                    charsize=1, charthick=3, col=[50,200, 250], psym=[8,8,0], thick=[2,2,2], symsize=[1,1,1], $
                    /left, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_1mm'

  ;;Profile 2mm
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_2mm.ps'
  ploterror, beam_radius, beam_profile2mm, beam_profilenoise2mm, $
             xtitle='radius (arcsec)', ytitle='Normalized beam response',$
             psym=1, /xlog,/ylog,yrange=[1e-5,1.5],xrange=[1,200], ystyle=1, xstyle=1,/nodata,$
             charsize=1.5, charthick=3
  oploterror, beam_radius, abs(beam_profile2mm), beam_profilenoise2mm,$
              col=200, errcolor=180, errthick=2, psym=8, symsize=0.7
  oploterror, beam_radius, beam_profile2mm, beam_profilenoise2mm, $
              col=50, errcolor=100,errthick=2,psym=8, symsize=0.7
  oplot, radius_max, beam_integ2mm/max(beam_integ2mm), col=250, thick=3
  if anapar.beam.oplot eq 'yes' then begin
     oplot, radius_max, anapar.beam.amp1.B*exp(-radius_max^2/(2*(anapar.beam.beam1.B*!fwhm2sigma)^2)) + $
            anapar.beam.amp2.B*exp(-radius_max^2/(2*(anapar.beam.beam2.B*!fwhm2sigma)^2)) + $
            anapar.beam.amp3.B*exp(-radius_max^2/(2*(anapar.beam.beam3.B*!fwhm2sigma)^2)),$
            col=150,thick=3
     legendastro,['Observed beam (positive data)', 'Observed beam (negative data)', 'Fraction of the beam', 'Model'], $
            charsize=1, charthick=3, col=[50,200,250,150], psym=[8,8,0,0], thick=[2,2,2,2], symsize=[1,1,1,1], $
            /left, /bottom, box=0
  endif else legendastro,['Observed beam (positive data)', 'Observed beam (negative data)', 'Fraction of the beam'], $
                    charsize=1, charthick=3, col=[50,200, 250], psym=[8,8,0], thick=[2,2,2], symsize=[1,1,1], $
                    /left, /bottom, box=0
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_2mm'
  
  ;;------- Plot the beam recovered over injected 
  if anapar.beam.model_ratio eq 'yes' then begin
     ;;Profile 1mm
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_measured_over_injected_1mm.ps'
     ploterror, beam_radius, abs(beam_profile1mm/(anapar.beam.amp1.A*exp(-radius_max^2/(2*(anapar.beam.beam1.A*!fwhm2sigma)^2)) + anapar.beam.amp2.A*exp(-radius_max^2/(2*(anapar.beam.beam2.A*!fwhm2sigma)^2)) + anapar.beam.amp3.A*exp(-radius_max^2/(2*(anapar.beam.beam3.A*!fwhm2sigma)^2)))), beam_profilenoise1mm/(anapar.beam.amp1.A*exp(-radius_max^2/(2*(anapar.beam.beam1.A*!fwhm2sigma)^2)) + anapar.beam.amp2.A*exp(-radius_max^2/(2*(anapar.beam.beam2.A*!fwhm2sigma)^2)) + anapar.beam.amp3.A*exp(-radius_max^2/(2*(anapar.beam.beam3.A*!fwhm2sigma)^2))), xtitle='radius (arcsec)', ytitle='|Measured beam| / Injected beam', psym=1, /xlog,/ylog,yrange=[1e-2,1e2],xrange=[1,200], ystyle=1, xstyle=1,/nodata,charsize=1.5, charthick=3
     oploterror, beam_radius, abs(beam_profile1mm/(anapar.beam.amp1.A*exp(-radius_max^2/(2*(anapar.beam.beam1.A*!fwhm2sigma)^2)) + anapar.beam.amp2.A*exp(-radius_max^2/(2*(anapar.beam.beam2.A*!fwhm2sigma)^2)) + anapar.beam.amp3.A*exp(-radius_max^2/(2*(anapar.beam.beam3.A*!fwhm2sigma)^2)))), beam_profilenoise1mm/(anapar.beam.amp1.A*exp(-radius_max^2/(2*(anapar.beam.beam1.A*!fwhm2sigma)^2)) + anapar.beam.amp2.A*exp(-radius_max^2/(2*(anapar.beam.beam2.A*!fwhm2sigma)^2)) + anapar.beam.amp3.A*exp(-radius_max^2/(2*(anapar.beam.beam3.A*!fwhm2sigma)^2))), col=50, errcolor=100, errthick=2, psym=8, symsize=0.7
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_measured_over_injected_1mm'

     ;;Profile 2mm
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_measured_over_injected_2mm.ps'
     ploterror, beam_radius, abs(beam_profile2mm/(anapar.beam.amp1.B*exp(-radius_max^2/(2*(anapar.beam.beam1.B*!fwhm2sigma)^2)) + anapar.beam.amp2.B*exp(-radius_max^2/(2*(anapar.beam.beam2.B*!fwhm2sigma)^2)) + anapar.beam.amp3.B*exp(-radius_max^2/(2*(anapar.beam.beam3.B*!fwhm2sigma)^2)))), beam_profilenoise2mm/(anapar.beam.amp1.B*exp(-radius_max^2/(2*(anapar.beam.beam1.B*!fwhm2sigma)^2)) + anapar.beam.amp2.B*exp(-radius_max^2/(2*(anapar.beam.beam2.B*!fwhm2sigma)^2)) + anapar.beam.amp3.B*exp(-radius_max^2/(2*(anapar.beam.beam3.B*!fwhm2sigma)^2))), xtitle='radius (arcsec)', ytitle='|Measured beam| / Injected beam', psym=1, /xlog,/ylog,yrange=[1e-2,1e2],xrange=[1,200], ystyle=1, xstyle=1,/nodata,charsize=1.5, charthick=3
     oploterror, beam_radius, abs(beam_profile2mm/(anapar.beam.amp1.B*exp(-radius_max^2/(2*(anapar.beam.beam1.B*!fwhm2sigma)^2)) + anapar.beam.amp2.B*exp(-radius_max^2/(2*(anapar.beam.beam2.B*!fwhm2sigma)^2)) + anapar.beam.amp3.B*exp(-radius_max^2/(2*(anapar.beam.beam3.B*!fwhm2sigma)^2)))), beam_profilenoise2mm/(anapar.beam.amp1.B*exp(-radius_max^2/(2*(anapar.beam.beam1.B*!fwhm2sigma)^2)) + anapar.beam.amp2.B*exp(-radius_max^2/(2*(anapar.beam.beam2.B*!fwhm2sigma)^2)) + anapar.beam.amp3.B*exp(-radius_max^2/(2*(anapar.beam.beam3.B*!fwhm2sigma)^2))), col=50, errcolor=100, errthick=2, psym=8, symsize=0.7
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_measured_over_injected_2mm'
  endif
  SET_PLOT, mydevice
  
  ;;------- Save the beam in a FITS file
  if anapar.beam.make_products eq 'yes' then nika_anapipe_beam2fits, param.output_dir, beam_radius, radius_max, $
     beam_profile1mm, beam_profile2mm, beam_profilenoise1mm, beam_profilenoise2mm, $
     beam_integ1mm, beam_integ2mm, err_integ1mm, err_integ2mm

  ;;------- Study of the dispersion of the beam over scans
  if anapar.beam.dispersion eq 'yes' then nika_anapipe_beam_disp, param, anapar
  
  ;;------- Study of the dispersion of the beam over pixels
  if anapar.beam.per_kid eq 'yes' then nika_anapipe_beam_per_kid, param, anapar

  return
end
