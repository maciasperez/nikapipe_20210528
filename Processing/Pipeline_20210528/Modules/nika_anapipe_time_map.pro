;+
;PURPOSE: Plot the time per pixel map with coordinantes and beam
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

 pro nika_anapipe_time_map, param, anapar, time_1mm, time_2mm, head_1mm, head_2mm,$
                            indiv_scan=indiv_scan, ps=ps

   if not keyword_set(indiv_scan) then my_other_name = '' else my_other_name = param.scan_list[0]+'_'

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  
  ;;------- Define the ploted map parameters
  if anapar.time_map.fov ne 0 then fov_plot = anapar.time_map.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  reso_plot = reso1mm
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    

  ;;------- Map
  time_plot_1mm = filter_image(time_1mm, fwhm=anapar.time_map.relob.a/reso1mm, /all)
  time_plot_2mm = filter_image(time_2mm, fwhm=anapar.time_map.relob.b/reso2mm, /all)

  ;;------- Type plot
  if anapar.time_map.type eq 'abs_coord' then begin
     type = 1
     xtitle='!4a!X!I2000!N (hr)'
     ytitle='!4d!X!I2000!N (degree)'
  endif
  if anapar.time_map.type eq 'offset' then begin
     type = 0
     xtitle='!4D!X !4a!X!I2000!N (arcmin)'
     ytitle='!4D!X !4d!X!I2000!N (arcmin)'
  endif

  ;;------- Define the best range
  if anapar.time_map.range1mm[0] ne 0 or anapar.time_map.range1mm[1] ne 0 then range_a=anapar.time_map.range1mm $
  else range_a = minmax(time_plot_1mm)
  if anapar.time_map.range2mm[0] ne 0 or anapar.time_map.range2mm[1] ne 0 then range_a=anapar.time_map.range2mm $
  else range_b = minmax(time_plot_2mm)

  ;;------- Plot the map
  if keyword_set(ps) then ps1mm = param.output_dir+'/'+param.name4file+'_time_'+my_other_name+'1mm.ps' $
  else pdf1mm = param.output_dir+'/'+param.name4file+'_time_'+my_other_name+'1mm.ps'
  if keyword_set(ps) then ps2mm = param.output_dir+'/'+param.name4file+'_time_'+my_other_name+'2mm.ps' $
  else pdf2mm = param.output_dir+'/'+param.name4file+'_time_'+my_other_name+'2mm.ps'

  if min(time_plot_1mm) lt max(time_plot_1mm) then begin 
  overplot_radec_bar_map, time_plot_1mm, head_1mm, time_plot_1mm, head_1mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps1mm,$
                          pdf=pdf1mm,$
                          bartitle='second',$
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_a, conts1=range_a,conts2=range_a,$
                          type=type, bg1=1e5
  endif

  if min(time_plot_2mm) lt max(time_plot_2mm) then begin 
  overplot_radec_bar_map, time_plot_2mm, head_2mm, time_plot_2mm, head_2mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps2mm,$
                          pdf=pdf2mm,$
                          bartitle='second', $
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_b, conts1=range_b,conts2=range_b,$
                          type=type, bg1=1e5
  endif  
  return
end
