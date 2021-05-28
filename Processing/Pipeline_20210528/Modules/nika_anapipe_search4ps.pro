;+
;PURPOSE: Search for point sources in a dusty map
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS:
;
;LAST EDITION: 
;   08/10/2013: creation (adam@lpsc.in2p3.fr)
;-

pro nika_anapipe_search4ps, param, anapar

  ;;------- Get the maps
  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',1,head_1mm,/SILENT)
  time_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',3,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',1,head_2mm,/SILENT)
  time_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',3,head_2mm,/SILENT)

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  
  ;;------- Filter the maps with mexican hat
  map_filt_1mm = nika_anapipe_mexican_hat(map_1mm*sqrt(time_1mm), reso1mm, $
                                          anapar.search_ps.fwhm1.a, anapar.search_ps.fwhm2.a, $
                                          flag_map=found_source_1mm, nsig=anapar.search_ps.nsigma)
  ;;map_filt_1mm /= sqrt(time_1mm)
  loc_out = where(time_1mm le 0, nloc_out, complement=loc_in)
  if nloc_out ne 0 then map_filt_1mm[loc_out] = 1e5
  if anapar.search_ps.range1mm[0] eq 0 and anapar.search_ps.range1mm[1] eq 0 then $
     range_a = minmax(map_filt_1mm[loc_in]) else $
        range_a = anapar.search_ps.range1mm

  map_filt_2mm = nika_anapipe_mexican_hat(map_2mm*sqrt(time_2mm), reso2mm, $
                                          anapar.search_ps.fwhm1.b, anapar.search_ps.fwhm2.b, $
                                          flag_map=found_source_2mm, nsig=anapar.search_ps.nsigma)
  ;;map_filt_2mm /= sqrt(time_2mm)
  loc_out = where(time_2mm le 0, nloc_out, complement=loc_in)
  if nloc_out ne 0 then map_filt_2mm[loc_out] = 1e5
  if anapar.search_ps.range2mm[0] eq 0 and anapar.search_ps.range2mm[1] eq 0 then $
     range_b = minmax(map_filt_2mm[loc_in]) else $
        range_b=anapar.search_ps.range2mm

  ;;------- Define the ploted map parameters
  if anapar.search_ps.fov ne 0 then fov_plot = anapar.search_ps.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  reso_plot = reso1mm
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    

  if anapar.search_ps.type eq 'abs_coord' then begin
     type = 1
     xtitle='!4a!X!I2000!N (hr)'
     ytitle='!4d!X!I2000!N (degree)'
  endif
  if anapar.search_ps.type eq 'offset' then begin
     type = 0
     xtitle='!4D!X !4a!X!I2000!N (arcmin)'
     ytitle='!4D!X !4d!X!I2000!N (arcmin)'
  endif

  ;;------- Show the point sources found
  overplot_radec_bar_map, found_source_1mm,head_1mm, found_source_1mm, head_1mm, fov_plot, reso_plot, coord_plot,$
                          ;postscript=param.output_dir+'/'+param.name4file+'_found_source_1mm.ps',$
                          pdf=param.output_dir+'/'+param.name4file+'_found_source_1mm.ps',$
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=[-1,2], conts1=[-1,2],conts2=[-1,2],$
                          type=type, bg1=1e5
  
  overplot_radec_bar_map, found_source_2mm,head_2mm, found_source_2mm, head_2mm, fov_plot, reso_plot, coord_plot,$
                          ;postscript=param.output_dir+'/'+param.name4file+'_found_sources_2mm.ps',$
                          pdf=param.output_dir+'/'+param.name4file+'_found_sources_2mm.ps',$
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=[-1,2], conts1=[-1,2],conts2=[-1,2],$
                          type=type, bg1=1e5

  overplot_radec_bar_map, map_filt_1mm, head_1mm, map_filt_1mm, head_1mm, fov_plot, reso_plot, coord_plot,$
                          ;postscript=param.output_dir+'/'+param.name4file+'_filtered_map_1mm.ps',$
                          pdf=param.output_dir+'/'+param.name4file+'_filtered_map_1mm.ps',$
                          bartitle='Jy/beam s!E1/2!N', $
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_a, conts1=range_a,conts2=range_a,$
                          type=type, bg1=1e5
  
  overplot_radec_bar_map, map_filt_2mm, head_2mm, map_filt_2mm, head_2mm, fov_plot, reso_plot, coord_plot,$
                          ;postscript=param.output_dir+'/'+param.name4file+'_filtered_map_2mm.ps',$
                          pdf=param.output_dir+'/'+param.name4file+'_filtered_map_2mm.ps',$
                          bartitle='Jy/beam s!E1/2!N',$
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_b, conts1=range_b,conts2=range_b,$
                          type=type, bg1=1e5
  
  return
end
