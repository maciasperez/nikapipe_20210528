;+
;PURPOSE: Beam dispertion study from many scans
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

pro nika_anapipe_beam_disp, param, anapar
  mydevice = !d.name
  set_plot, 'ps'

  ;;==================== Extract useful variables
  ;;------- Get the maps
  map_list_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',4,head_1mm,/SILENT)
  noise_list_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',5,head_1mm,/SILENT)
  map_list_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',4,head_2mm,/SILENT)
  noise_list_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',5,head_2mm,/SILENT)
  
  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
    ;;------- Defines variables to be filled for all scans
  nb_prof = 100
  rmax = 300.0
  radius_max = dindgen(100)/99*rmax+3 ;maximum radius to compute the integrated flux (arcsec)

  Nscan = n_elements(map_list_1mm[0,0,*])

  list_coeff_gauss1mm = dblarr(Nscan, 7)
  list_coeff_gauss2mm = dblarr(Nscan, 7)
  list_coeff_plateau1mm = dblarr(Nscan, 6)
  list_coeff_plateau2mm = dblarr(Nscan, 6)
  list_coeff_triple1mm = dblarr(Nscan, 6)
  list_coeff_triple2mm = dblarr(Nscan, 6)

  list_prof_1mm = dblarr(Nscan, nb_prof)
  list_prof_2mm = dblarr(Nscan, nb_prof)
  list_noise_prof_1mm = dblarr(Nscan, nb_prof)
  list_noise_prof_2mm = dblarr(Nscan, nb_prof)

  list_beam_integ_1mm = dblarr(Nscan, nb_prof)
  list_beam_integ_2mm = dblarr(Nscan, nb_prof)

  for iscan=0, Nscan-1 do begin
     ;;==================== Fitting session
     ;;------- Model simple gaussien
     nika_pipe_fit_beam, map_list_1mm[*,*,iscan], reso1mm, $
                         coeff=coeff_gauss1mm, best_fit=map_flux_model_a, var_map=noise_list_1mm[*,*,iscan]^2,$
                         TILT=TILT, CIRCULAR=CIRCULAR, center=[0,0],search_box=[20,20],$
                         FWHM=FIXED_FWHM_A, /silent
     list_coeff_gauss1mm[iscan, *] = coeff_gauss1mm

     nika_pipe_fit_beam, map_list_2mm[*,*,iscan], reso2mm, $
                         coeff=coeff_gauss2mm, best_fit=map_flux_model_b, var_map=noise_list_2mm[*,*,iscan]^2,$
                         TILT=TILT, CIRCULAR=CIRCULAR, center=[0,0], search_box=[20,20],$
                         FWHM=FIXED_FWHM_B, /silent
     list_coeff_gauss2mm[iscan, *] = coeff_gauss2mm
     
     ;;------- Fit the plateau with B(t) = A0 + A1 exp(-t^2/2/A2^2) + A3 Erf(-(t-A4)/A5)
     nika_anapipe_fitplateau, reso1mm, map_list_1mm[*,*,iscan], noise_list_1mm[*,*,iscan], $
                              best_fit=bestfit_plateau1mm, coeff=coeff_plateau1mm, $
                              center=coeff_gauss1mm[4:5], /silent
     list_coeff_plateau1mm[iscan, *] = coeff_plateau1mm
     
     nika_anapipe_fitplateau, reso2mm, map_list_2mm[*,*,iscan], noise_list_2mm[*,*,iscan], $
                              best_fit=bestfit_plateau2mm, coeff=coeff_plateau2mm, $
                              center=coeff_gauss2mm[4:5], /silent
     list_coeff_plateau2mm[iscan, *] = coeff_plateau2mm
     
     ;;------- Triple gaussian fit
     nika_anapipe_triple_beam_fit, reso1mm, map_list_1mm[*,*,iscan], noise_list_1mm[*,*,iscan], $
                                   best_fit=bestfit_triple1mm, coeff=coeff_triple1mm, $
                                   center=coeff_gauss1mm[4:5], /silent
     list_coeff_triple1mm[iscan, *] = coeff_triple1mm

     nika_anapipe_triple_beam_fit, reso2mm, map_list_2mm[*,*,iscan], noise_list_2mm[*,*,iscan], $
                                   best_fit=bestfit_triple2mm, coeff=coeff_triple2mm, $
                                   center=coeff_gauss2mm[4:5], /silent
     list_coeff_triple2mm[iscan, *] = coeff_triple2mm

     ;;==================== Angular distributions
     ;;------- Profile
     maps_1mm = {Jy:map_list_1mm[*,*,iscan], var:noise_list_1mm[*,*,iscan]^2}
     maps_2mm = {Jy:map_list_2mm[*,*,iscan], var:noise_list_2mm[*,*,iscan]^2}
     nika_pipe_profile, reso1mm, maps_1mm, flux_prof1mm, nb_prof=nb_prof, center=coeff_gauss1mm[4:5]
     nika_pipe_profile, reso2mm, maps_2mm, flux_prof2mm, nb_prof=nb_prof, center=coeff_gauss2mm[4:5]
     list_prof_1mm[iscan,*] = flux_prof1mm.y
     list_prof_2mm[iscan,*] = flux_prof2mm.y
     list_noise_prof_1mm[iscan,*] = sqrt(flux_prof1mm.var)
     list_noise_prof_2mm[iscan,*] = sqrt(flux_prof2mm.var)

     ;;------- Integration
     flux_int1mm = nika_pipe_integmap(map_list_1mm[*,*,iscan], reso1mm, radius_max, center=coeff_gauss1mm[4:5])
     flux_int2mm = nika_pipe_integmap(map_list_2mm[*,*,iscan], reso2mm, radius_max, center=coeff_gauss2mm[4:5])
     list_beam_integ_1mm[iscan,*] = flux_int1mm
     list_beam_integ_2mm[iscan,*] = flux_int2mm

     ;;------- Normalize the flux density map to the beam map
     beam_radius = flux_prof1mm.r
     list_prof_1mm[iscan,*] /= coeff_gauss1mm[1]
     list_prof_2mm[iscan,*] /= coeff_gauss2mm[1]
     list_noise_prof_1mm[iscan,*] /= coeff_gauss1mm[1]
     list_noise_prof_2mm[iscan,*] /= coeff_gauss2mm[1]
     list_beam_integ_1mm[iscan,*] /= coeff_gauss1mm[1]
     list_beam_integ_2mm[iscan,*] /= coeff_gauss2mm[1]

  endfor
  
  fwhm_scans_1mm = list_coeff_gauss1mm[*,2]*list_coeff_gauss1mm[*,3]
  fwhm_scans_2mm = list_coeff_gauss2mm[*,2]*list_coeff_gauss2mm[*,3]
  peak_scans_1mm = list_coeff_gauss1mm[*,1]
  peak_scans_2mm = list_coeff_gauss2mm[*,1]

  save, fwhm_scans_1mm, peak_scans_1mm, fwhm_scans_2mm, peak_scans_2mm,$
        filename=param.output_dir+'/Beam_list.save'
  
  ;;==================== Beam volume dispersion
  loc100 = where(radius_max lt anapar.beam.range_disp[1] and radius_max gt anapar.beam.range_disp[0], nloc100)
  if nloc100 ne 0 then begin
     err_beam_vol1mm = stddev(median(list_beam_integ_1mm[*,loc100], dim=2)) 
     err_beam_vol2mm = stddev(median(list_beam_integ_2mm[*,loc100], dim=2)) 
     mean_beam_vol1mm = mean(median(list_beam_integ_1mm[*,loc100], dim=2))
     mean_beam_vol2mm = mean(median(list_beam_integ_2mm[*,loc100], dim=2))
     print, '================== Beam volume error between '+strtrim(anapar.beam.range_disp[0],2)+' and '+strtrim(anapar.beam.range_disp[1],2)+' arcsec ====================='
     print, '==== 1mm: '+strtrim(100*err_beam_vol1mm/mean_beam_vol1mm, 2)+'%'
     print, '==== 2mm: '+strtrim(100*err_beam_vol2mm/mean_beam_vol2mm, 2)+'%'
     print, '=========================================================='
  endif
  
  ;;==================== Plots
  ;;------- Integrated beam
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_integ_allscan_1mm.ps'
  plot, radius_max, list_beam_integ_1mm[0,*], $
        xtitle='Angular distance (arcsec)', ytitle='Integrated beam (arcsec!U2!N)', $
        xrange=[0,300], xstyle=1, yrange=[0,max(list_beam_integ_1mm)], ystyle=1,/nodata, charsize=1.5, charthick=3
  for iscan=0, Nscan-1 do oplot, radius_max, reform(list_beam_integ_1mm[iscan,*]), thick=2, col=250
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_integ_allscan_1mm'
  
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_integ_allscan_2mm.ps'
  plot, radius_max, list_beam_integ_2mm[0,*], $
        xtitle='Angular distance (arcsec)', ytitle='Integrated beam (arcsec!U2!N)', $
        xrange=[0,300], xstyle=1, yrange=[0,max(list_beam_integ_2mm)], ystyle=1, /nodata, charsize=1.5, charthick=3
  for iscan=0, Nscan-1 do oplot, radius_max, list_beam_integ_2mm[iscan,*], thick=2, col=250
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_integ_allscan_2mm'

  ;;------- Plot the beam profile
  ;;Profile 1mm
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_allscan_1mm.ps'
  ploterror, beam_radius, list_prof_1mm[0,*], list_noise_prof_1mm[0,*], $
             xtitle='radius (arcsec)', ytitle='Normalized beam response',$
             psym=1, /xlog,/ylog,yrange=[1e-5,1.5],xrange=[1,300], ystyle=1, xstyle=1,/nodata, $
             charsize=1.5, charthick=3
  for iscan=0, Nscan-1 do oploterror, beam_radius, abs(list_prof_1mm[0,*]), list_noise_prof_1mm[iscan,*],$
                                      col=200, errcolor=180, errthick=2, psym=8, symsize=0.7
  for iscan=0, Nscan-1 do oploterror, beam_radius, list_prof_1mm[iscan,*], list_noise_prof_1mm[iscan,*], $
                                      col=50, errcolor=100,errthick=2,psym=8, symsize=0.7
  if anapar.beam.oplot eq 'yes' then begin
     oplot, radius_max, anapar.beam.amp1.A*exp(-radius_max^2/(2*(anapar.beam.beam1.A*!fwhm2sigma)^2)) + $
            anapar.beam.amp2.A*exp(-radius_max^2/(2*(anapar.beam.beam2.A*!fwhm2sigma)^2)) + $
            anapar.beam.amp3.A*exp(-radius_max^2/(2*(anapar.beam.beam3.A*!fwhm2sigma)^2)),$
            col=150,thick=3
     legendastro,['Observed beam (positive data)', 'Observed beam (negative data)', 'Model'], $
            charsize=1, charthick=3, col=[50,200,150], psym=[8,8,0], thick=[1,1,1], symsize=[1,1,1], $
            /left, /bottom, box=0
  endif else legendastro,['Observed beams (positive data)', 'Observed beams (negative data)'], $
                    charsize=1, charthick=3, col=[50,200], psym=[8,8], thick=[2,2], symsize=[1,1], $
                    /left, /bottom, box=0
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_allscan_1mm'

  ;;Profile 2mm
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_profile_allscan_2mm.ps'
  ploterror, beam_radius, list_prof_2mm[0,*], list_noise_prof_2mm[0,*], $
             xtitle='radius (arcsec)', ytitle='Normalized beam response',$
             psym=1, /xlog,/ylog,yrange=[1e-5,1.5],xrange=[1,300], ystyle=1, xstyle=1,/nodata, $
             charsize=1.5, charthick=3
  for iscan=0, Nscan-1 do oploterror, beam_radius, abs(list_prof_2mm[0,*]), list_noise_prof_2mm[iscan,*],$
                                      col=200, errcolor=180, errthick=2, psym=8, symsize=0.7
  for iscan=0, Nscan-1 do oploterror, beam_radius, list_prof_2mm[iscan,*], list_noise_prof_2mm[iscan,*], $
                                      col=50, errcolor=100,errthick=2,psym=8, symsize=0.7
  if anapar.beam.oplot eq 'yes' then begin
     oplot, radius_max, anapar.beam.amp1.B*exp(-radius_max^2/(2*(anapar.beam.beam1.B*!fwhm2sigma)^2)) + $
            anapar.beam.amp2.B*exp(-radius_max^2/(2*(anapar.beam.beam2.B*!fwhm2sigma)^2)) + $
            anapar.beam.amp3.B*exp(-radius_max^2/(2*(anapar.beam.beam3.B*!fwhm2sigma)^2)),$
            col=150,thick=3
     legendastro,['Observed beam (positive data)', 'Observed beam (negative data)', 'Model'], $
            charsize=1, charthick=3, col=[50,200,250,150], psym=[8,8,0], thick=[1,1,1], symsize=[1,1,1], $
            /left, /bottom, box=0
  endif else legendastro,['Observed beams (positive data)', 'Observed beams (negative data)'], $
                    charsize=1, charthick=3, col=[50,200], psym=[8,8], thick=[2,2], symsize=[1,1], $
                    /left, /bottom, box=0
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_profile_allscan_2mm'
  
  ;;------- Flux distribution
  yrange_a = minmax(list_coeff_gauss1mm[*,1])*[0.9, 1.1]
  if anapar.beam.oplot eq 'yes' then yrange_a = minmax([list_coeff_gauss1mm[*,1],anapar.beam.flux.A])*[0.9,1.1]
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_flux_distribution_1mm.ps'
  plot, list_coeff_gauss1mm[*,1],/nodata, xr=[-1,Nscan], ytitle='Flux (Jy)', $
        xstyle=1, xtitle='scan index',ystyle=1,yr=yrange_a, charsize=1.5, charthick=3
  oplot, list_coeff_gauss1mm[*,1], col=250, thick=4, psym=8
  if anapar.beam.oplot eq 'yes' then begin
     oplot, list_coeff_gauss1mm[*,1]*0+anapar.beam.flux.A,col=150,thick=3
     legendastro,['Measured flux', 'Model'], $
            charsize=1, charthick=3, col=[250,150], psym=[8,0], thick=[1,1], symsize=[1,1], $
            /left, /bottom, box=0
  endif
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_flux_distribution_1mm'

  yrange_b = minmax(list_coeff_gauss2mm[*,1])*[0.9, 1.1]
  if anapar.beam.oplot eq 'yes' then yrange_b = minmax([list_coeff_gauss2mm[*,1], anapar.beam.flux.B])*[0.9,1.1]
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_flux_distribution_2mm.ps'
  plot, list_coeff_gauss2mm[*,1], ytitle='Flux (Jy)', /nodata, xr=[-1,Nscan], xstyle=1,$
        xtitle='scan index',ystyle=1,yr=yrange_b, charsize=1.5, charthick=3
  oplot, list_coeff_gauss2mm[*,1], col=250, thick=4, psym=8
  if anapar.beam.oplot eq 'yes' then begin
     oplot, list_coeff_gauss2mm[*,1]*0+anapar.beam.flux.B,col=150,thick=3
     legendastro,['Measured flux', 'Model'], $
            charsize=1, charthick=3, col=[250,150], psym=[8,0], thick=[1,1], symsize=[1,1], $
            /left, /bottom, box=0
  endif
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_flux_distribution_2mm'

  ;;------- Beam distribution
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_beam_distribution_1mm.ps'
  plot, sqrt(list_coeff_gauss1mm[*,2]*list_coeff_gauss1mm[*,3]), $
        ytitle='FWHM (arcsec)',  xtitle='scan index', /nodata, xr=[-1,Nscan],xstyle=1, $
        yr=minmax(sqrt(list_coeff_gauss1mm[*,2]*list_coeff_gauss1mm[*,3]))*[0.9, 1.1], ystyle=1, $
        charsize=1.5, charthick=3
  oplot, sqrt(list_coeff_gauss1mm[*,2]*list_coeff_gauss1mm[*,3]), col=250, thick=4, psym=8
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_beam_distribution_1mm'

  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_beam_distribution_2mm.ps'
  plot, sqrt(list_coeff_gauss2mm[*,2]*list_coeff_gauss2mm[*,3]), $
        ytitle='FWHM (arcsec)',  xtitle='scan index', /nodata, xr=[-1,Nscan],xstyle=1, $
        yr=minmax(sqrt(list_coeff_gauss2mm[*,2]*list_coeff_gauss2mm[*,3]))*[0.9, 1.1], ystyle=1, $
        charsize=1.5, charthick=3
  oplot, sqrt(list_coeff_gauss2mm[*,2]*list_coeff_gauss2mm[*,3]), col=250, thick=4, psym=8
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_beam_distribution_2mm'

;;------- Offset distribution
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+'_offset_distribution.ps'
  plot, list_coeff_gauss1mm[*,4], list_coeff_gauss1mm[*,4], $
        ytitle='Y Offset (arcsec)',xtitle='X Offset (arcsec)', /nodata, xstyle=1, ystyle=1,$
        xr=minmax([list_coeff_gauss1mm[*,4], list_coeff_gauss2mm[*,4]])*[0.8, 1.2],$
        yr=minmax([list_coeff_gauss1mm[*,5],list_coeff_gauss2mm[*,5]])*[0.8, 1.2], $
        charsize=1.5, charthick=3
  oplot,list_coeff_gauss1mm[*,4], list_coeff_gauss1mm[*,5], col=250, thick=4, psym=8
  oplot,list_coeff_gauss2mm[*,4], list_coeff_gauss2mm[*,5], col=150, thick=4, psym=8
  oplot, [0,0], [-100,100]
  oplot, [-100,100], [0,0]
  legendastro,['Data 1mm', 'Data 2mm'],$
         charsize=1,charthick=3,col=[250,150], psym=[8,8],$
         thick=[8,8],symsize=[1,1],line=[0,0], /right, /top, box=0
  device, /close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_offset_distribution'


  set_plot, mydevice
  return
end
