;+
;PURPOSE: Plot the the beam with log map to see error beam
;
;INPUT: The reduction and map analysis parameter structures. 
;
;OUTPUT: what you set in the parameter files
;
;KEYWORDS:
;
;LAST EDITION: 
;   26/09/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_fsl, param, anapar, beam_map1mm, beam_map2mm, beam_noise1mm, beam_noise2mm, head_1mm, head_2mm, ps=ps

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  
  ;;------- Define the ploted map parameters
  if anapar.beam.fov ne 0 then fov_plot = anapar.beam.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  reso_plot = reso1mm
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    
  
  ;;------- Define a cutoff
  noise_max = 2

  map_plot_a = beam_map1mm
  map_plot_b = beam_map2mm
  nsm_1mm = beam_noise1mm
  nsm_2mm = beam_noise2mm
  loc_nan_1mm = where(beam_noise1mm/beam_noise1mm ne 1, nloc_nan_1mm)
  loc_nan_2mm = where(beam_noise2mm/beam_noise2mm ne 1, nloc_nan_2mm)
  if nloc_nan_1mm ne 0 then nsm_1mm[loc_nan_1mm] = max(nsm_1mm, /nan)
  if nloc_nan_2mm ne 0 then nsm_2mm[loc_nan_2mm] = max(nsm_2mm, /nan)
  nsm_1mm = filter_image(nsm_1mm, fwhm=20.0/reso1mm, /all)
  nsm_2mm = filter_image(nsm_2mm, fwhm=20.0/reso1mm, /all)

  cut_1mm = where(nsm_1mm gt noise_max*min(nsm_1mm,/nan) or beam_noise1mm/beam_noise1mm ne 1, ncut_1mm, $
                  compl=comp_cut_1mm)
  cut_2mm = where(nsm_2mm gt noise_max*min(nsm_2mm,/nan) or beam_noise2mm/beam_noise2mm ne 1, ncut_2mm, $
                  compl=comp_cut_2mm)
  if ncut_1mm ne 0 then map_plot_a[cut_1mm] = 1e5
  if ncut_2mm ne 0 then map_plot_b[cut_2mm] = 1e5
  
  ;;------- Define the best range
  range_a = anapar.beam.range_fsl1mm
  range_b = anapar.beam.range_fsl2mm

  ;;------- Plot the map
  if keyword_set(ps) then ps1mm = param.output_dir+'/'+param.name4file+'_mapbeam_1mm.ps' $
  else pdf1mm = param.output_dir+'/'+param.name4file+'_mapbeam_1mm.ps'
  if keyword_set(ps) then ps2mm = param.output_dir+'/'+param.name4file+'_mapbeam_2mm.ps' $
  else pdf2mm = param.output_dir+'/'+param.name4file+'_mapbeam_2mm.ps'
  
  overplot_radec_bar_map, map_plot_a, head_1mm, map_plot_a, head_1mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps1mm,$
                          pdf=pdf1mm,$
                          xtitle='!4D!X Azimuth (arcmin)', ytitle='!4D!X Elevation (arcmin)',$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          ;range=range_a, conts1=conts1_a,conts2=range_a,$
                          range=range_a, conts1=range_a,conts2=range_a,$
                          colconts1=0, thickcont1=1.5,$
                          beam=12.5, bg1=1e5
  
  overplot_radec_bar_map, map_plot_b, head_2mm, map_plot_b, head_2mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps2mm, $
                          pdf=pdf2mm,$
                          xtitle='!4D!X Azimuth (arcmin)', ytitle='!4D!X Elevation (arcmin)',$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          ;range=range_b, conts1=conts1_b,conts2=range_b,$
                          range=range_b, conts1=range_b,conts2=range_b,$
                          colconts1=0, thickcont1=1.5,$
                          beam=18.5, bg1=1e5

  ;;------- LOG scale
  map_log_a = map_plot_a
  map_log_b = map_plot_b
  loc0a = where(map_log_a le 1e-5, nloc0a)
  loc0b = where(map_log_b le 1e-5, nloc0b)
  if nloc0a ne 0 then map_log_a[loc0a] = 1.1e-5
  if nloc0b ne 0 then map_log_b[loc0b] = 1.1e-5
  map_log_a = alog10(map_log_a)
  map_log_b = alog10(map_log_b)

  range_log_a = [-5,0.5]
  range_log_b = [-5,0.5]

 if keyword_set(ps) then ps1mm = param.output_dir+'/'+param.name4file+'_mapbeamlog_1mm.ps' $
  else pdf1mm = param.output_dir+'/'+param.name4file+'_mapbeamlog_1mm.ps'
  if keyword_set(ps) then ps2mm = param.output_dir+'/'+param.name4file+'_mapbeamlog_2mm.ps' $
  else pdf2mm = param.output_dir+'/'+param.name4file+'_mapbeamlog_2mm.ps'

  overplot_radec_bar_map, map_log_a, head_1mm, map_log_a, head_1mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps1mm,$
                          pdf=pdf1mm,$
                          bartitle='Log Scale', $
                          xtitle='!4D!X Azimuth (arcmin)', ytitle='!4D!X Elevation (arcmin)',$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_log_a, conts1=[-1e8,1e8],$
                          conts2=[-1e10,1e10],$      
                          beam=12.5, bg1=1e6

  overplot_radec_bar_map, map_log_b, head_2mm, map_plot_b, head_2mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps2mm,$
                          pdf=pdf2mm,$
                          bartitle='Log Scale', $
                          xtitle='!4D!X Azimuth (arcmin)', ytitle='!4D!X Elevation (arcmin)',$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_log_b, conts1=[-1e8,1e8],$
                          conts2=[-1e10,1e10],$         
                          beam=18.5, bg1=1e6

  return
end
