;+
;PURPOSE: Measure the sensitivity using Jack-Knives and TOI
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS: sensitivities found can be returned in the keywords
;
;LAST EDITION: 
;   21/10/2013: creation (adam@lpsc.in2p3.fr)
;   21/12/2013: add the noise measurement from the map itself without
;               JK, and do JK only if their are more than 1 scan 
;   15/02/2014: Nicer histograms with cghistoplot.pro
;   16/02/2014: Compute the NEFD in addition to the sensitivity (not
;               the same)
;-

pro nika_anapipe_sensitivity, param, anapar,$
                              map_1mm, noise_1mm, noise_nfm_1mm, time_1mm, $
                              map_2mm, noise_2mm, noise_nfm_2mm, time_2mm, $
                              map_list_1mm, noise_list_1mm, noise_list_nfm_1mm, time_list_1mm, $
                              map_list_2mm, noise_list_2mm, noise_list_nfm_2mm, time_list_2mm, $
                              head_1mm, head_2mm, $
                              sens_jk_1mm=sens_jk_1mm, sens_jk_2mm=sens_jk_2mm, $
                              sens_toi_1mm=sens_toi_1mm, sens_toi_2mm=sens_toi_2mm, $
                              sens_map_1mm=sens_map_1mm, sens_map_2mm=sens_map_2mm, $
                              indiv_scan=indiv_scan, $
                              par_spec_1mm=par_spec_1mm, par_spec_2mm=par_spec_2mm
  
  if keyword_set(indiv_scan) then add_name = '_'+param.scan_list[0] else add_name = ''

  nmap = n_elements(map_list_1mm[0,0,*])
  fmt = '(1F8.1)'               ; Output format for NEFDs

  ;;==================== Sensitivity computed using Jack-Knifes
  if nmap gt 1 then begin
     ;;------- Get the J-K
     ordre = sort(randomn(seed, nmap))
     map_jk_1mm = nika_anapipe_jackknife(map_list_1mm[*,*,ordre], (noise_list_1mm[*,*,ordre])^2)
     map_jk_2mm = nika_anapipe_jackknife(map_list_2mm[*,*,ordre], (noise_list_2mm[*,*,ordre])^2)
     map_jk_1mm *= 0.5
     map_jk_2mm *= 0.5
     
     ;;------- Histo of sensitivity from JK
     map_sens_1mm = map_jk_1mm*sqrt(time_1mm) 
     map_sens_2mm = map_jk_2mm*sqrt(time_2mm) 
     
     wsens_1mm = where(finite(map_sens_1mm) eq 1 and time_1mm gt 0 and map_jk_1mm ne 0,nwsens_1mm,comp=wnosens_1mm,ncomp=nwnosens_1mm)
     wsens_2mm = where(finite(map_sens_2mm) eq 1 and time_2mm gt 0 and map_jk_2mm ne 0,nwsens_2mm,comp=wnosens_2mm,ncomp=nwnosens_2mm)
     if nwsens_1mm eq 0 then message, 'No pixel available for Jack-Knife'
     if nwsens_2mm eq 0 then message, 'No pixel available for Jack-Knife'
     
     sens_stddev_1mm = stddev(map_sens_1mm[wsens_1mm])
     sens_stddev_2mm = stddev(map_sens_2mm[wsens_2mm])
     
     wsens2_1mm = where(map_sens_1mm[wsens_1mm] lt mean(map_sens_1mm[wsens_1mm])+3*sens_stddev_1mm and $
                        map_sens_1mm[wsens_1mm] gt mean(map_sens_1mm[wsens_1mm])-3*sens_stddev_1mm)
     wsens2_2mm = where(map_sens_2mm[wsens_2mm] lt mean(map_sens_2mm[wsens_2mm])+3*sens_stddev_2mm and $
                        map_sens_2mm[wsens_2mm] gt mean(map_sens_2mm[wsens_2mm])-3*sens_stddev_2mm )
     hist_1mm = histogram((map_sens_1mm[wsens_1mm])[wsens2_1mm], nbins=60)
     hist_2mm = histogram((map_sens_2mm[wsens_2mm])[wsens2_2mm], nbins=60)
     
     bins_1mm = FINDGEN(N_ELEMENTS(hist_1mm))/(N_ELEMENTS(hist_1mm)-1) * (max((map_sens_1mm[wsens_1mm])[wsens2_1mm])-min((map_sens_1mm[wsens_1mm])[wsens2_1mm]))+min((map_sens_1mm[wsens_1mm])[wsens2_1mm])
     bins_1mm += (bins_1mm[1]-bins_1mm[0])/2
     bins_2mm = FINDGEN(N_ELEMENTS(hist_2mm))/(N_ELEMENTS(hist_2mm)-1) * (max((map_sens_2mm[wsens_2mm])[wsens2_2mm])-min((map_sens_2mm[wsens_2mm])[wsens2_2mm]))+min((map_sens_2mm[wsens_2mm])[wsens2_2mm])
     bins_2mm += (bins_2mm[1]-bins_2mm[0])/2
   
     yfit_1mm = GAUSSFIT(bins_1mm, hist_1mm, coeff_1mm, nterms=3)
     yfit_2mm = GAUSSFIT(bins_2mm, hist_2mm, coeff_2mm, nterms=3)
     
     sens_jk_1mm = sens_stddev_1mm
     sens_jk_2mm = sens_stddev_2mm

     print, '=========================================='
     print, '======= Mean sensitivity found from Jack-Knife: '
     print, '=======    1mm: '+string(1e3*coeff_1mm[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
     print, '=======    1mm: '+string(1e3*sens_stddev_1mm,format = fmt )+' mJy.sqrt(s)/Beam     from the standard deviation'
     print, '=======    2mm: '+string(1e3*coeff_2mm[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
     print, '=======    2mm: '+string(1e3*sens_stddev_2mm, format = fmt2)+' mJy.sqrt(s)/Beam     from the standard deviation'
     print, '=========================================='
     
     ;;------- Plot the JK map
     nika_anapipe_jk_map, param, anapar, map_jk_1mm, noise_1mm, map_jk_2mm, noise_2mm, head_1mm, head_2mm
  endif

  ;;==================== Sensitivity computed using the noise in the TOI
  map_sens_TOI_1mm = noise_1mm*sqrt(time_1mm)
  map_sens_TOI_2mm = noise_2mm*sqrt(time_2mm)
  
  wsens_TOI_1mm = where(finite(map_sens_TOI_1mm) eq 1 and time_1mm gt 0)
  wsens_TOI_2mm = where(finite(map_sens_TOI_2mm) eq 1 and time_1mm gt 0)
  
  sens_toi_1mm = mean(map_sens_toi_1mm[wsens_TOI_1mm])
  sens_toi_2mm = mean(map_sens_toi_2mm[wsens_TOI_2mm])
  
  print, '=========================================='
  print, '======= Mean sensitivity found from the TOIs: '
  print, '=======          1mm: '+strtrim(1e3*sens_toi_1mm, 2)+' mJy.sqrt(s)/beam'
  print, '=======          2mm: '+strtrim(1e3*sens_toi_2mm, 2)+' mJy.sqrt(s)/beam'
  print, '=========================================='
  
  ;;==================== Sensitivity computed using the propagated
  ;;==================== noise in the maps
  map_sens_MAP_1mm = noise_nfm_1mm*sqrt(time_1mm)
  map_sens_MAP_2mm = noise_nfm_2mm*sqrt(time_2mm)
  
  wsens_MAP_1mm = where(finite(map_sens_MAP_1mm) eq 1 and time_1mm gt 0)
  wsens_MAP_2mm = where(finite(map_sens_MAP_2mm) eq 1 and time_2mm gt 0)
  
  sens_map_1mm = mean(map_sens_map_1mm[wsens_MAP_1mm])
  sens_map_2mm = mean(map_sens_map_2mm[wsens_MAP_2mm])
  
  print, '=========================================='
  print, '======= Mean sensitivity found from the map by propagation of the noise: '
  print, '=======          1mm: '+strtrim(1e3*sens_map_1mm, 2)+' mJy.sqrt(s)/beam'
  print, '=======          2mm: '+strtrim(1e3*sens_map_2mm, 2)+' mJy.sqrt(s)/beam'
  print, '=========================================='
  
  ;;==================== Sensitivity computed using the map directly
  map_sens_1mm = map_1mm*sqrt(time_1mm) 
  map_sens_2mm = map_2mm*sqrt(time_2mm) 
  
  smap = size(map_1mm)
  nx = smap[1]
  ny = smap[2]
  pdist = dist(nx, ny)*param.map.reso
  pdist = shift(pdist, -nx/2, -ny/2)
  
  wsens_1mm = where(finite(map_sens_1mm) eq 1 and time_1mm gt 0 and map_1mm ne 0 and pdist gt anapar.noise_meas.dist_nfwhm *!nika.fwhm_nom[0], nwsens_1mm, comp=wnosens_1mm, ncomp=nwnosens_1mm)
  wsens_2mm = where(finite(map_sens_2mm) eq 1 and time_2mm gt 0 and map_2mm ne 0 and pdist gt anapar.noise_meas.dist_nfwhm *!nika.fwhm_nom[1], nwsens_2mm, comp=wnosens_2mm, ncomp=nwnosens_2mm)
  if nwsens_1mm eq 0 then message, 'No pixel available for map only'
  if nwsens_2mm eq 0 then message, 'No pixel available for map only'
  
  map_stddev_1mm = stddev(map_sens_1mm[wsens_1mm])
  map_stddev_2mm = stddev(map_sens_2mm[wsens_2mm])
  
  wsens2_1mm = where(map_sens_1mm[wsens_1mm] lt mean(map_sens_1mm[wsens_1mm])+3*map_stddev_1mm and $
                     map_sens_1mm[wsens_1mm] gt mean(map_sens_1mm[wsens_1mm])-3*map_stddev_1mm)
  wsens2_2mm = where(map_sens_2mm[wsens_2mm] lt mean(map_sens_2mm[wsens_2mm])+3*map_stddev_2mm and $
                     map_sens_2mm[wsens_2mm] gt mean(map_sens_2mm[wsens_2mm])-3*map_stddev_2mm )
  hist_1mm = histogram((map_sens_1mm[wsens_1mm])[wsens2_1mm], nbins=60)
  hist_2mm = histogram((map_sens_2mm[wsens_2mm])[wsens2_2mm], nbins=60)
  
  bins_1mm = FINDGEN(N_ELEMENTS(hist_1mm))/(N_ELEMENTS(hist_1mm)-1) * (max((map_sens_1mm[wsens_1mm])[wsens2_1mm])-min((map_sens_1mm[wsens_1mm])[wsens2_1mm]))+min((map_sens_1mm[wsens_1mm])[wsens2_1mm])
  bins_1mm += (bins_1mm[1]-bins_1mm[0])/2
  bins_2mm = FINDGEN(N_ELEMENTS(hist_2mm))/(N_ELEMENTS(hist_2mm)-1) * (max((map_sens_2mm[wsens_2mm])[wsens2_2mm])-min((map_sens_2mm[wsens_2mm])[wsens2_2mm]))+min((map_sens_2mm[wsens_2mm])[wsens2_2mm])
  bins_2mm += (bins_2mm[1]-bins_2mm[0])/2

  yfit_1mm = GAUSSFIT(bins_1mm, hist_1mm, coeff_1mm, nterms=3)
  yfit_2mm = GAUSSFIT(bins_2mm, hist_2mm, coeff_2mm, nterms=3)
  print, '=========================================='
  print, '======= Mean sensitivity found from the maps directly: '
  print, '=======    1mm: '+ string(1e3*coeff_1mm[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
  print, '=======    1mm: '+string(1e3*map_stddev_1mm, format = fmt)+' mJy.sqrt(s)/Beam     from the standard deviation'
  print, '=======    2mm: '+string(1e3*coeff_2mm[2], format = fmt)+' mJy.sqrt(s)/Beam     from the histogram fit'
  print, '=======    2mm: '+string(1e3*map_stddev_2mm, format = fmt)+' mJy.sqrt(s)/Beam     from the standard deviation'
  print, '=========================================='

  ;;==================== Compute the NEFD for a source at the center
  ;;==================== of the map
  nefd1mm_naive = nika_anapipe_nefd(param.map.reso, anapar.noise_meas.beam.a, !nika.grid_step[0], $
                                    map_1mm, map_stddev_1mm, time_1mm)
  nefd2mm_naive = nika_anapipe_nefd(param.map.reso, anapar.noise_meas.beam.b, !nika.grid_step[1], $
                                    map_2mm, map_stddev_2mm, time_2mm)
  
  print, '=========================================='
  print, '======= Naive NEFD found for the combined map: '
  print, '=======    1mm: '+string(1e3*nefd1mm_naive, format=fmt)+' mJy.sqrt(s)/Beam'
  print, '=======    2mm: '+string(1e3*nefd2mm_naive, format=fmt)+' mJy.sqrt(s)/Beam'
  print, '=========================================='
  
  if anapar.noise_meas.noise_Nmc gt 2 then begin
     specpar1 = anapar.noise_meas.noise_spec1
     specpar2 = anapar.noise_meas.noise_spec2
     specpar3 = anapar.noise_meas.noise_spec3
     if keyword_set(par_spec_1mm) then specpar1[0] = par_spec_1mm[2]
     if keyword_set(par_spec_1mm) then specpar2[0] = par_spec_1mm[0]
     if keyword_set(par_spec_1mm) then specpar3[0] = par_spec_1mm[1]
     if keyword_set(par_spec_2mm) then specpar1[1] = par_spec_2mm[2]
     if keyword_set(par_spec_2mm) then specpar2[1] = par_spec_2mm[0]
     if keyword_set(par_spec_2mm) then specpar3[1] = par_spec_2mm[1]
     
     nefd1mm_spec = nika_anapipe_nefd_spec(1, param.map.reso, anapar.noise_meas.beam.a, !nika.grid_step[0], $ 
                                           noise_nfm_1mm, time_1mm, $
                                           specpar1[0], specpar2[0], specpar3[0], anapar.noise_meas.noise_Nmc, $
                                           param.output_dir)
     nefd2mm_spec = nika_anapipe_nefd_spec(2, param.map.reso, anapar.noise_meas.beam.b, !nika.grid_step[1], $
                                           noise_nfm_2mm, time_2mm, $
                                           specpar1[1], specpar2[1], specpar3[1], anapar.noise_meas.noise_Nmc, $
                                           param.output_dir)
  endif else begin
     message, /info, 'No Monte Carlo to get the error since anapar.noise_meas.noise_Nmc < 2'
     nefd1mm_spec = nefd1mm_naive
     nefd2mm_spec = nefd2mm_naive
  endelse
  
  print, '=========================================='
  print, '======= NEFD found using noise spectral modeling: '
  print, '=======    1mm: '+string(1e3*nefd1mm_spec, format=fmt)+' mJy.sqrt(s)/Beam'
  print, '=======    2mm: '+string(1e3*nefd2mm_spec, format=fmt)+' mJy.sqrt(s)/Beam'
  print, '=========================================='
 
  ;;==================== Plot the sensitivity histogram
  mydevice = !d.name
  SET_PLOT, 'PS'
  loadct,4, /silent
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+add_name+'_sensitivity_1mm.ps'
  cgHistoplot, (map_sens_1mm[wsens_1mm])[wsens2_1mm]*1e3, $
               nbins=60, $
               /FILLPOLYGON, $
               POLYCOLOR=220, $
               datacolorname=160, $
               xtitle='Value of the pixel (mJy/Beam.s!E1/2!N)', $
               ytitle='Number of pixels', $
               max_value=max(yfit_1mm)*1.2, $
               mininput=min(bins_1mm)*1e3, $
               maxinput=max(bins_1mm)*1e3,$
               charthick=3, charsize=1.5, $
               log=0
  oplot, 1e3*bins_1mm, yfit_1mm, col=100, thick=5
  legendastro,['Data','Fit: !4r!3='+string(1e3*coeff_1mm[2],format = fmt)+' mJy/Beam.s!E1/2!N'],$
              linestyle=[0,0], psym=[0,0], col=[200,100], thick=[5,5], symsize=[1,1], $
              box=0,pos=[-max(1e3*bins_1mm),max(yfit_1mm)*1.2] ; spacing=[1,1],pspacing=[2,2],
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+add_name+'_sensitivity_1mm'
  
  device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+add_name+'_sensitivity_2mm.ps'
  cgHistoplot, (map_sens_2mm[wsens_2mm])[wsens2_2mm]*1e3, $
               nbins=60, $
               /FILLPOLYGON, $
               POLYCOLOR=220, $
               datacolorname=160, $
               xtitle='Value of the pixel (mJy/Beam.s!E1/2!N)', $
               ytitle='Number of pixels', $
               max_value=max(yfit_2mm)*1.2, $
               mininput=min(bins_2mm)*1e3, $
               maxinput=max(bins_2mm)*1e3,$
               charthick=3, charsize=1.5, $
               log=0
  oplot, 1e3*bins_2mm, yfit_2mm, col=100, thick=5
  legendastro,['Data','Fit: !4r!3='+string(1e3*coeff_2mm[2],format = fmt)+' mJy/Beam.s!E1/2!N'],$
              linestyle=[0,0],psym=[0,0],col=[200,100],thick=[5,5],symsize=[1,1],$
              box=0,pos=[-max(1e3*bins_2mm),max(yfit_2mm)*1.2];, spacing=[1,1],pspacing=[2,2],
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+add_name+'_sensitivity_2mm'
  loadct,39, /silent
  set_plot, mydevice

  return
end
