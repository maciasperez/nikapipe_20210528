;+
;PURPOSE: Plot the standard deviation map with coordinantes and beam
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

 pro nika_anapipe_noise_map, param, anapar, noise_1mm, noise_2mm, head_1mm, head_2mm,$
                             indiv_scan=indiv_scan, ps=ps

   if not keyword_set(indiv_scan) then my_other_name = '' else my_other_name = param.scan_list[0]+'_'

  ;;------- Get the resolution of the maps
  EXTAST, head_1mm, astr1mm
  EXTAST, head_2mm, astr2mm
  reso1mm = astr1mm.cdelt[1]*3600
  reso2mm = astr2mm.cdelt[1]*3600
  
  ;;------- Define the ploted map parameters
  if anapar.noise_map.fov ne 0 then fov_plot = anapar.noise_map.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  reso_plot = reso1mm
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    

  ;;------- Define a map
  noise_plot_1mm = noise_1mm
  noise_plot_2mm = noise_2mm
  wnan_1mm = where(noise_1mm/noise_1mm ne 1, nwnan_1mm, comp=cwnan_1mm) ;Search for NaN
  wnan_2mm = where(noise_2mm/noise_2mm ne 1, nwnan_2mm, comp=cwnan_2mm)
  if nwnan_1mm ne 0 then noise_plot_1mm[wnan_1mm] = max(noise_plot_1mm[cwnan_1mm]) ;Put NaN to max noise
  if nwnan_2mm ne 0 then noise_plot_2mm[wnan_2mm] = max(noise_plot_2mm[cwnan_2mm])
  noise_plot_1mm = filter_image(noise_plot_1mm, fwhm=anapar.noise_map.relob.a/reso1mm,/all) ;Smooth
  noise_plot_2mm = filter_image(noise_plot_2mm, fwhm=anapar.noise_map.relob.b/reso1mm,/all)
  cut_1mm = where(noise_1mm/noise_1mm ne 1, ncut_1mm, comp=comp_cut_1mm)
  cut_2mm = where(noise_2mm/noise_2mm ne 1, ncut_2mm, comp=comp_cut_2mm)
  if ncut_1mm ne 0 then noise_plot_1mm[cut_1mm] = 1e5
  if ncut_2mm ne 0 then noise_plot_2mm[cut_2mm] = 1e5

  ;;------- Defines the unit of the map
  if anapar.noise_map.unit eq 'mJy/beam' then begin
     noise_plot_1mm *= 1000
     noise_plot_2mm *= 1000     
  endif
  if anapar.noise_map.unit eq 'MJy/sr' then begin
     noise_plot_1mm /= 2*!pi*(!fwhm2sigma*anapar.noise_map.beam.a/3600.0/180.0*!pi)^2*$
                     anapar.noise_map.beam_factor.a*1e6
     noise_plot_2mm /= 2*!pi*(!fwhm2sigma*anapar.noise_map.beam.b/3600.0/180.0*!pi)^2*$
                     anapar.noise_map.beam_factor.b*1e6
  endif
  
  if anapar.noise_map.type eq 'abs_coord' then begin
     type = 1
     xtitle='!4a!X!I2000!N (hr)'
     ytitle='!4d!X!I2000!N (degree)'
  endif
  if anapar.noise_map.type eq 'offset' then begin
     type = 0
     xtitle='!4D!X !4a!X!I2000!N (arcmin)'
     ytitle='!4D!X !4d!X!I2000!N (arcmin)'
  endif

  ;;------- Define the best range and contours
  if anapar.noise_map.range1mm[0] ne 0 or anapar.noise_map.range1mm[1] ne 0 $
  then range_a=anapar.noise_map.range1mm else range_a =  [min(noise_plot_1mm[comp_cut_1mm]), $
                                                          3*min(noise_plot_1mm[comp_cut_1mm])]
  if anapar.noise_map.range2mm[0] ne 0 or anapar.noise_map.range2mm[1] ne 0 $
  then range_b=anapar.noise_map.range2mm else range_b = [min(noise_plot_2mm[comp_cut_2mm]), $
                                                         3*min(noise_plot_2mm[comp_cut_2mm])]

  wr1mm = where(finite(anapar.noise_map.conts1mm) eq 1 and anapar.noise_map.conts1mm gt range_a[0] and $
                anapar.noise_map.conts1mm lt range_a[1], nwr1mm)
  wr2mm = where(finite(anapar.noise_map.conts2mm) eq 1 and anapar.noise_map.conts2mm gt range_b[0] and $
                anapar.noise_map.conts2mm lt range_b[1], nwr2mm)
  if nwr1mm eq 0 then conts1_a = range_a else conts1_a = [range_a[0],anapar.noise_map.conts1mm[wr1mm],range_a[1]]
  if nwr2mm eq 0 then conts1_b = range_b else conts1_b = [range_b[0],anapar.noise_map.conts2mm[wr2mm],range_b[1]]

  ;;------- Plot the map
  if keyword_set(ps) then ps1mm = param.output_dir+'/'+param.name4file+'_stddev_'+my_other_name+'1mm.ps' $
  else pdf1mm = param.output_dir+'/'+param.name4file+'_stddev_'+my_other_name+'1mm.ps'
  if keyword_set(ps) then ps2mm = param.output_dir+'/'+param.name4file+'_stddev_'+my_other_name+'2mm.ps' $
  else pdf2mm = param.output_dir+'/'+param.name4file+'_stddev_'+my_other_name+'2mm.ps'

  if min(noise_plot_1mm) lt max(noise_plot_1mm) then begin 
     overplot_radec_bar_map, noise_plot_1mm, head_1mm, noise_plot_1mm, head_1mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps1mm,$
                          pdf=pdf1mm, $
                          bartitle=anapar.noise_map.unit, $
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_a, conts1=conts1_a,conts2=range_a,$
                          colconts1=anapar.noise_map.col_conts, thickcont1=anapar.noise_map.thick_conts,$
                          beam=sqrt(anapar.noise_map.beam.a^2+anapar.noise_map.relob.a^2),type=type, bg1=1e5
  endif 
  if min(noise_plot_2mm) lt max(noise_plot_2mm) then begin 

     overplot_radec_bar_map, noise_plot_2mm, head_2mm, noise_plot_2mm, head_2mm, fov_plot, reso_plot, coord_plot,$
                          postscript=ps2mm,$
                          pdf=pdf2mm, $
                          bartitle=anapar.noise_map.unit, $
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range_b, conts1=conts1_b,conts2=range_b,$
                          colconts1=anapar.noise_map.col_conts, thickcont1=anapar.noise_map.thick_conts,$
                          beam=sqrt(anapar.noise_map.beam.b^2+anapar.noise_map.relob.b^2),type=type, bg1=1e5
  endif 
  return
end
