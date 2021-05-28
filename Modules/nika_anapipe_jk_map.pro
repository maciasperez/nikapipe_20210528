;+
;PURPOSE: Plot the Jack-Knife map with coordinantes and beam
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

pro nika_anapipe_jk_map, param, anapar, map_1mm, noise_1mm, map_2mm, noise_2mm, head_1mm, head_2mm

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  
  ;;------- Define the ploted map parameters
  if anapar.noise_meas.jk.fov ne 0 then fov_plot = anapar.noise_meas.jk.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  reso_plot = reso1mm
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    
  
  ;;------- Define a cutoff
  noise_max = anapar.noise_meas.jk.noise_max
  
  map_plot_a = map_1mm
  map_plot_b = map_2mm
  loc_ud_1mm = where(finite(map_1mm) ne 1, nloc_ud_1mm)
  loc_ud_2mm = where(finite(map_2mm) ne 1, nloc_ud_2mm)
  if nloc_ud_1mm ne 0 then map_plot_a[loc_ud_1mm] = 0
  if nloc_ud_2mm ne 0 then map_plot_b[loc_ud_2mm] = 0
  map_plot_a = filter_image(map_plot_a, fwhm=anapar.noise_meas.jk.relob.a/reso1mm,/all)
  map_plot_b = filter_image(map_plot_b, fwhm=anapar.noise_meas.jk.relob.b/reso2mm,/all)

  nsm_1mm = noise_1mm
  nsm_2mm = noise_2mm
  loc_nan_1mm = where(noise_1mm/noise_1mm ne 1, nloc_nan_1mm)
  loc_nan_2mm = where(noise_2mm/noise_2mm ne 1, nloc_nan_2mm)
  if nloc_nan_1mm ne 0 then nsm_1mm[loc_nan_1mm] = max(nsm_1mm, /nan)
  if nloc_nan_2mm ne 0 then nsm_2mm[loc_nan_2mm] = max(nsm_2mm, /nan)
  nsm_1mm = filter_image(nsm_1mm, fwhm=20.0/reso1mm, /all)
  nsm_2mm = filter_image(nsm_2mm, fwhm=20.0/reso1mm, /all)

  cut_1mm = where(nsm_1mm gt noise_max*min(nsm_1mm,/nan) or noise_1mm/noise_1mm ne 1 or finite(map_1mm) ne 1, ncut_1mm, compl=comp_cut_1mm)
  cut_2mm = where(nsm_2mm gt noise_max*min(nsm_2mm,/nan) or noise_2mm/noise_2mm ne 1 or finite(map_2mm) ne 1, ncut_2mm, compl=comp_cut_2mm)
  if ncut_1mm ne 0 then map_plot_a[cut_1mm] = 1e5
  if ncut_2mm ne 0 then map_plot_b[cut_2mm] = 1e5
  
  ;;------- Defines the unit of the map
  if anapar.noise_meas.jk.unit eq 'mJy/beam' then begin
     map_plot_a *= 1000
     map_plot_b *= 1000     
  endif
  if anapar.noise_meas.jk.unit eq 'MJy/sr' then begin
     map_plot_a /= 2*!pi*(!fwhm2sigma*anapar.noise_meas.jk.beam.a/3600.0/180.0*!pi)^2*anapar.noise_meas.jk.beam_factor.a*1e6
     map_plot_b /= 2*!pi*(!fwhm2sigma*anapar.noise_meas.jk.beam.b/3600.0/180.0*!pi)^2*anapar.noise_meas.jk.beam_factor.b*1e6
  endif
  
  if anapar.noise_meas.jk.type eq 'abs_coord' then begin
     type = 1
     xtitle='!4a!X!I2000!N (hr)'
     ytitle='!4d!X!I2000!N (degree)'
  endif
  if anapar.noise_meas.jk.type eq 'offset' then begin
     type = 0
     xtitle='!4D!X !4a!X!I2000!N (arcmin)'
     ;;xtitle='!4D!X !4a!X!I2000!N (arcsec)'
     ytitle='!4D!X !4d!X!I2000!N (arcmin)'
     ;;ytitle='!4D!X !4d!X!I2000!N (arcsec)'
  endif

  ;;------- Define the best range and contours
  if anapar.noise_meas.jk.range1mm[0] ne 0 or anapar.noise_meas.jk.range1mm[1] ne 0 then range_a=anapar.noise_meas.jk.range1mm $
  else range_a = minmax(map_plot_a[comp_cut_1mm])
  if anapar.noise_meas.jk.range2mm[0] ne 0 or anapar.noise_meas.jk.range2mm[1] ne 0 then range_b=anapar.noise_meas.jk.range2mm $
  else range_b = minmax(map_plot_b[comp_cut_2mm])

  wr1mm = where(finite(anapar.noise_meas.jk.conts1mm) eq 1 and anapar.noise_meas.jk.conts1mm gt range_a[0] and $
                anapar.noise_meas.jk.conts1mm lt range_a[1], nwr1mm)
  wr2mm = where(finite(anapar.noise_meas.jk.conts2mm) eq 1 and anapar.noise_meas.jk.conts2mm gt range_b[0] and $
                anapar.noise_meas.jk.conts2mm lt range_b[1], nwr2mm)
  if nwr1mm eq 0 then conts1_a = range_a else conts1_a = [range_a[0], anapar.noise_meas.jk.conts1mm[wr1mm], range_a[1]]
  if nwr2mm eq 0 then conts1_b = range_b else conts1_b = [range_b[0], anapar.noise_meas.jk.conts2mm[wr2mm], range_b[1]]

  ;;------- Plot the map
  overplot_radec_bar_map, map_plot_a, head_1mm, map_plot_a, head_1mm, fov_plot, reso_plot, coord_plot,$
                          ;postscript=param.output_dir+'/'+param.name4file+'_JK_1mm.ps',$
                          pdf=param.output_dir+'/'+param.name4file+'_JK_1mm.ps',$
                          bartitle=anapar.noise_meas.jk.unit, $
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_a, conts1=conts1_a,conts2=range_a,$
                          colconts1=anapar.noise_meas.jk.col_conts, thickcont1=anapar.noise_meas.jk.thick_conts,$
                          beam=sqrt(anapar.noise_meas.jk.beam.a^2+anapar.noise_meas.jk.relob.a^2), $
                          type=type, bg1=1e5
  
  overplot_radec_bar_map, map_plot_b, head_2mm, map_plot_b, head_2mm, fov_plot, reso_plot, coord_plot,$
                          ;postscript=param.output_dir+'/'+param.name4file+'_JK_2mm.ps',$
                          pdf=param.output_dir+'/'+param.name4file+'_JK_2mm.ps',$
                          bartitle=anapar.noise_meas.jk.unit,$
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_b, conts1=conts1_b,conts2=range_b,$
                          colconts1=anapar.noise_meas.jk.col_conts, thickcont1=anapar.noise_meas.jk.thick_conts,$
                          beam=sqrt(anapar.noise_meas.jk.beam.b^2+anapar.noise_meas.jk.relob.b^2),$
                          type=type, bg1=1e5
  
  return
end
