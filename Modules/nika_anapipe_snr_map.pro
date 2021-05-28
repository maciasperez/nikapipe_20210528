;+
;PURPOSE: Plot the Signal to noise map with coordinantes and beam
;
;INPUT: The reduction and map analysis parameter structures. The maps
;       and the headers
;
;OUTPUT: The map are plotted
;
;KEYWORDS:
;
;LAST EDITION: 
;   24/09/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_snr_map, param, anapar, map_1mm, noise_1mm, time_1mm, map_2mm, noise_2mm, time_2mm, $
                          head_1mm, head_2mm, indiv_scan=indiv_scan, ps=ps, no_sat=no_sat
  
  if not keyword_set(indiv_scan) then my_other_name = '' else my_other_name = param.scan_list[0]+'_'

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  reso = reso1mm

  ;;------- Define the ploted map parameters
  if anapar.snr_map.fov ne 0 then fov_plot = anapar.snr_map.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  reso_plot = reso1mm
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    
  
  ;;------- Define a map
  nx = (size(map_1mm))[1]
  ny = (size(map_1mm))[2]
  fact1mm = stddev(filter_image(randomn(seed,nx,ny), FWHM=anapar.snr_map.relob.a/reso, /all))
  fact2mm = stddev(filter_image(randomn(seed,nx,ny), FWHM=anapar.snr_map.relob.b/reso, /all))

  lnan_1mm = where(finite(noise_1mm) ne 1 or noise_1mm le 0, nlnan_1mm)
  lnan_2mm = where(finite(noise_2mm) ne 1 or noise_2mm le 0, nlnan_2mm)
  noise_sm_1mm = noise_1mm
  noise_sm_2mm = noise_2mm
  if nlnan_1mm ne 0 then noise_sm_1mm[lnan_1mm] = max(noise_1mm, /nan)
  if nlnan_2mm ne 0 then noise_sm_2mm[lnan_2mm] = max(noise_2mm, /nan)
  noise_sm_1mm = filter_image(noise_sm_1mm, fwhm=anapar.snr_map.relob.a/reso ,/all)
  noise_sm_2mm = filter_image(noise_sm_2mm, fwhm=anapar.snr_map.relob.b/reso ,/all)
  
  snr_1mm=filter_image(map_1mm,fwhm=anapar.snr_map.relob.a/reso,/all)/noise_sm_1mm/fact1mm
  snr_2mm=filter_image(map_2mm,fwhm=anapar.snr_map.relob.b/reso,/all)/noise_sm_2mm/fact2mm

  ;;------- Define the best range
  if anapar.snr_map.range1mm[0] ne 0 or anapar.snr_map.range1mm[1] ne 0 then range_a=anapar.snr_map.range1mm $
  else range_a = minmax(snr_1mm, /nan)
  if anapar.snr_map.range2mm[0] ne 0 or anapar.snr_map.range2mm[1] ne 0 then range_b=anapar.snr_map.range2mm $
  else range_b = minmax(snr_2mm, /nan)

  ;;------- Define a map
  cut_1mm = where(noise_1mm/noise_1mm ne 1, ncut_1mm, comp=comp_cut_1mm)
  cut_2mm = where(noise_2mm/noise_2mm ne 1, ncut_2mm, comp=comp_cut_2mm)
  if ncut_1mm ne 0 then snr_1mm[cut_1mm] = 1e5
  if ncut_2mm ne 0 then snr_2mm[cut_2mm] = 1e5

  ;;------- Get good conts
  my_conts_1mm = anapar.snr_map.conts1mm
  my_conts_1mm = my_conts_1mm[sort(my_conts_1mm)]
  wc1mm = where(finite(my_conts_1mm) eq 1, nwc1mm)
  if nwc1mm eq 0 then my_conts_1mm = [-9,-6,-3,3,6,9] else my_conts_1mm = my_conts_1mm[wc1mm]
  wc1mm = where(my_conts_1mm lt range_a[1] and my_conts_1mm gt range_a[0] and my_conts_1mm gt 0, nwc1mm)
  if nwc1mm eq 0 then conts2_a = range_a else conts2_a = [range_a[0], my_conts_1mm[wc1mm], range_a[1]]
  wc1mm = where(my_conts_1mm lt range_a[1] and my_conts_1mm gt range_a[0] and my_conts_1mm lt 0, nwc1mm)
  if nwc1mm eq 0 then conts1_a = range_a else conts1_a = [range_a[0], my_conts_1mm[wc1mm], range_a[1]]

  my_conts_2mm = anapar.snr_map.conts2mm
  my_conts_2mm = my_conts_2mm[sort(my_conts_2mm)]
  wc2mm = where(finite(my_conts_2mm) eq 1, nwc2mm)
  if nwc2mm eq 0 then my_conts_2mm = [-9,-6,-3,3,6,9] else my_conts_2mm = my_conts_2mm[wc2mm]
  wc2mm = where(my_conts_2mm lt range_b[1] and my_conts_2mm gt range_b[0] and my_conts_2mm gt 0, nwc2mm)
  if nwc2mm eq 0 then conts2_b = range_b else conts2_b = [range_b[0], my_conts_2mm[wc2mm], range_b[1]]
  wc2mm = where(my_conts_2mm lt range_b[1] and my_conts_2mm gt range_b[0] and my_conts_2mm lt 0, nwc2mm)
  if nwc2mm eq 0 then conts1_b = range_b else conts1_b = [range_b[0], my_conts_2mm[wc2mm], range_b[1]]

  ;;------- Coordinates
  if anapar.snr_map.type eq 'abs_coord' then begin
     type = 1
     xtitle='!4a!X!I2000!N (hr)'
     ytitle='!4d!X!I2000!N (degree)'
  endif
  if anapar.snr_map.type eq 'offset' then begin
     type = 0
     xtitle='!4D!X !4a!X!I2000!N (arcmin)'
     ytitle='!4D!X !4d!X!I2000!N (arcmin)'
  endif
  
  ;;------- Map not grey when saturated if requested
  if keyword_set(no_sat) then begin
     sat_up_1mm = where(snr_1mm ge range_a[1], nsat_up_1mm, compl=csat_up_1mm)
     sat_down_1mm = where(snr_1mm le range_a[0], nsat_down_1mm, compl=csat_down_1mm)
     sat_up_2mm = where(snr_2mm ge range_b[1], nsat_up_2mm, compl=csat_up_2mm)
     sat_down_2mm = where(snr_2mm le range_b[0], nsat_down_2mm, compl=csat_down_2mm)

     if nsat_up_1mm ne 0 then snr_1mm[sat_up_1mm] = max(snr_1mm[csat_up_1mm])
     if nsat_down_1mm ne 0 then snr_1mm[sat_down_1mm] =  min(snr_1mm[csat_down_1mm])
     if nsat_up_2mm ne 0 then snr_2mm[sat_up_2mm] = max(snr_2mm[csat_up_2mm])
     if nsat_down_2mm ne 0 then snr_2mm[sat_down_2mm] =  min(snr_2mm[csat_down_2mm])

     if ncut_1mm ne 0 then snr_1mm[cut_1mm] = 1e5
     if ncut_2mm ne 0 then snr_2mm[cut_2mm] = 1e5
  endif

  ;;------- Plot the map
  if keyword_set(ps) then ps1mm = param.output_dir+'/'+param.name4file+'_SNR_'+my_other_name+'1mm.ps' $
  else pdf1mm = param.output_dir+'/'+param.name4file+'_SNR_'+my_other_name+'1mm.ps'
  if keyword_set(ps) then ps2mm = param.output_dir+'/'+param.name4file+'_SNR_'+my_other_name+'2mm.ps' $
  else pdf2mm = param.output_dir+'/'+param.name4file+'_SNR_'+my_other_name+'2mm.ps'

  if min(snr_1mm) lt max(snr_1mm) then begin 
     overplot_radec_bar_map, snr_1mm, head_1mm, snr_1mm, head_1mm, fov_plot, reso_plot, coord_plot,$
                             postscript=ps1mm,$
                             pdf=pdf1mm,$
                             xtitle=xtitle, ytitle=ytitle,$
                             barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                             range=range_a, conts1=conts1_a,conts2=conts2_a,$
                             colconts1=anapar.snr_map.col_conts_n,colconts2=anapar.snr_map.col_conts_p,$
                             thickcont1=anapar.snr_map.thick_conts,thickconts2=anapar.snr_map.thick_conts,$
                             beam=sqrt(anapar.snr_map.beam.a^2+anapar.snr_map.relob.a^2),$
                             type=type, bg1=1e5
  endif  
  if min(snr_2mm) lt max(snr_2mm) then begin 
     overplot_radec_bar_map, snr_2mm, head_2mm, snr_2mm, head_2mm, fov_plot, reso_plot, coord_plot,$
                             postscript=ps2mm,$
                             pdf=pdf2mm,$
                             xtitle=xtitle, ytitle=ytitle,$
                             barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                             range=range_b, conts1=conts1_b,conts2=conts2_b,$
                             colconts1=anapar.snr_map.col_conts_n,colconts2=anapar.snr_map.col_conts_p,$
                             thickcont1=anapar.snr_map.thick_conts,thickconts2=anapar.snr_map.thick_conts,$
                             beam=sqrt(anapar.snr_map.beam.b^2+anapar.snr_map.relob.b^2),$
                             type=type, bg1=1e5
  endif 

  return
end
