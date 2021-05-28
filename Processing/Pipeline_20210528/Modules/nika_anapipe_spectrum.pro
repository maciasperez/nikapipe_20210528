;+
;PURPOSE: Compute the spectrum map and fit 1mm-2mm correlation at given locations
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS:
;
;LAST EDITION: 
;   08/10/2013: creation (adam@lpsc.in2p3.fr)
;   10/07/2014: bug correcte when accounting for the beam
;-

pro nika_anapipe_spectrum, param, anapar, map_1mm, noise_1mm, map_2mm, noise_2mm, head_1mm, head_2mm, ps=ps
 
  ;;------- Get the resolution of the maps assuming same astrometry
  EXTAST, head_1mm, astr1mm
  reso = astr1mm.cdelt[1]*3600
  
  ;;------- Define the ploted map parameters
  if anapar.spectrum.fov ne 0 then fov_plot = anapar.spectrum.fov $
  else fov_plot = (param.map.size_ra+param.map.size_dec)/2
  coord_plot = [ten(param.coord_map.ra[0],param.coord_map.ra[1],param.coord_map.ra[2])*15.0,$
                ten(param.coord_map.dec[0],param.coord_map.dec[1],param.coord_map.dec[2])]    
  
  ;;------- Cutoff
  nx = (size(map_1mm))[1]
  ny = (size(map_1mm))[2]
  fact = stddev(filter_image(randomn(seed,nx,ny), FWHM=anapar.spectrum.reso/reso, /all))

  lnan_1mm = where(finite(noise_1mm) ne 1 or noise_1mm le 0, nlnan_1mm)
  lnan_2mm = where(finite(noise_2mm) ne 1 or noise_2mm le 0, nlnan_2mm)
  noise_sm_1mm = noise_1mm
  noise_sm_2mm = noise_2mm
  if nlnan_1mm ne 0 then noise_sm_1mm[lnan_1mm] = max(noise_1mm, /nan)
  if nlnan_2mm ne 0 then noise_sm_2mm[lnan_2mm] = max(noise_2mm, /nan)
  noise_sm_1mm = filter_image(noise_sm_1mm, fwhm=sqrt(anapar.spectrum.reso^2-anapar.spectrum.beam.a^2)/reso ,/all)
  noise_sm_2mm = filter_image(noise_sm_2mm, fwhm=sqrt(anapar.spectrum.reso^2-anapar.spectrum.beam.b^2)/reso ,/all)

  snr_1mm=filter_image(map_1mm,fwhm=sqrt(anapar.spectrum.reso^2-anapar.spectrum.beam.a^2)/reso,/all)/noise_sm_1mm/fact
  snr_2mm=filter_image(map_2mm,fwhm=sqrt(anapar.spectrum.reso^2-anapar.spectrum.beam.b^2)/reso,/all)/noise_sm_2mm/fact

  ;;------- Set the same resolution for both wavelenghts
  ra = filter_image(map_1mm, fwhm=sqrt(anapar.spectrum.reso^2-anapar.spectrum.beam.a^2)/reso,/all) 
  rb = filter_image(map_2mm, fwhm=sqrt(anapar.spectrum.reso^2-anapar.spectrum.beam.b^2)/reso,/all)
  
  rap = (ra/(!nika.FWHM_NOM[0])^2)/(rb/(!nika.FWHM_NOM[1])^2)
  spec = alog(rap)/alog(!nika.lambda[1]/!nika.lambda[0])
  
  loc_out = where(snr_1mm lt anapar.spectrum.snr_cut1mm or $
                  snr_2mm lt anapar.spectrum.snr_cut2mm or $
                  finite(spec) ne 1, nloc_out, $
                  comp=loc_in, ncomp=nloc_in)
  if nloc_out ne 0 then spec[loc_out] = 1e5
  
  ;;------- Defines the range
  if anapar.spectrum.range[0] ne 0 or anapar.spectrum.range[1] ne 0 then range = anapar.spectrum.range $
  else range = minmax(spec[loc_in])

  wr = where(finite(anapar.spectrum.conts) eq 1 and anapar.spectrum.conts gt range[0] and $
             anapar.spectrum.conts lt range[1], nwr)
  if nwr eq 0 then conts1 = range else conts1 = [range[0], anapar.spectrum.conts[wr], range[1]]
  
  woutr = where(spec gt range[1] or spec lt range[0], nwoutr)
  if nwoutr ne 0 then spec[woutr] = 1e5

  ;;------- Defines the type of the map
  if anapar.spectrum.type eq 'abs_coord' then begin
     type = 1
     xtitle='!4a!X!I2000!N (hr)'
     ytitle='!4d!X!I2000!N (degree)'
  endif
  if anapar.spectrum.type eq 'offset' then begin
     type = 0
     xtitle='!4D!X !4a!X!I2000!N (arcmin)'
     ytitle='!4D!X !4d!X!I2000!N (arcmin)'
  endif
  
  ;;------- Plot the spectrum map
  if keyword_set(ps) then pss = param.output_dir+'/'+param.name4file+'_spectrum_map.ps' $
  else pdfs = param.output_dir+'/'+param.name4file+'_spectrum_map.ps'
  overplot_radec_bar_map, spec, head_1mm, spec, head_1mm, fov_plot, reso, coord_plot,$
                          postscript=pss, $
                          pdf=pdfs,$
                          bartitle='spectral index',$
                          xtitle=xtitle, ytitle=ytitle,$
                          barcharthick=5, mapcharthick=5, barcharsize=1.5, mapcharsize=1.5 ,$
                          range=range, conts1=conts1,conts2=range,$
                          colconts1=anapar.spectrum.col_conts, thickcont1=anapar.spectrum.thick_conts,$
                          beam=anapar.spectrum.reso,$
                          type=type, bg1=1e5
  
  return
end
