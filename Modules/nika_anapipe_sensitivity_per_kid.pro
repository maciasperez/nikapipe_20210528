;+
;PURPOSE: Measure the sensitivity using Jack-Knives and TOI for a
;         given kid
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS:
;
;LAST EDITION: 
;   21/10/2013: creation (adam@lpsc.in2p3.fr)
;   21/12/2013: do the JK unless only one scan
;   16/02/2014: Compute the sensitivity from the TOI and the map
;               itself (no JK). Also compute the NEFD
;-

pro nika_anapipe_sensitivity_per_kid, param, anapar, map, noise, time, kid_num,$
                                      sens_toi, sens_map, nefd
  mydevice = !d.name
  set_plot, 'ps'

  sens_toi = !values.f_nan
  sens_map = !values.f_nan
  nefd = !values.f_nan

  ;;========== Sensitivity from the noise in the TOI
  map_sens_TOI = noise*sqrt(time)
  wsens_TOI = where(finite(map_sens_TOI) eq 1 and finite(map) eq 1 and time gt 0, nwsens_toi)
  if nwsens_toi ne 0 then sens_toi = mean(map_sens_toi[wsens_TOI])

  ;;========== Sensitivity from the map directly
  map_sens = map*sqrt(time) 
  
  smap = size(map)
  nx = smap[1]
  ny = smap[2]
  pdist = dist(nx, ny)*param.map.reso
  pdist = shift(pdist, -nx/2, -ny/2)
  
  if long(kid_num) lt 400 then beam = !nika.fwhm_nom[0] else beam = !nika.fwhm_nom[1]
  wsens = where(finite(map_sens) eq 1 and time gt 0 and map ne 0 and pdist gt anapar.noise_meas.dist_nfwhm*beam, nwsens, comp=wnosens, ncomp=nwnosens)
  if nwsens ne 0 then map_stddev = stddev(map_sens[wsens]) else goto, the_end
  
  sens_stddev = stddev(map_sens[wsens])

  wsens2 = where(map_sens[wsens] lt mean(map_sens[wsens])+3*sens_stddev and $
                 map_sens[wsens] gt mean(map_sens[wsens])-3*sens_stddev)
  
  hist = histogram((map_sens[wsens])[wsens2], nbins=60)
  bins = FINDGEN(N_ELEMENTS(hist))/(N_ELEMENTS(hist)-1) * (max((map_sens[wsens])[wsens2])-min((map_sens[wsens])[wsens2]))+min((map_sens[wsens])[wsens2])
  bins += (bins[1]-bins[0])/2
  
  yfit = GAUSSFIT(bins, hist, coeff, nterms=3)
  sens_map = coeff[2]

  addname = 'KID'+kid_num
  device,/color, bits_per_pixel=256,filename=param.output_dir+'/'+param.name4file+'_sensitivity_'+addname+'.ps'
  cgHistoplot, (map_sens[wsens])[wsens2]*1e3, $
               nbins=60, $
               /FILLPOLYGON, $
               POLYCOLOR=220, $
               datacolorname=160, $
               xtitle='Value of the pixel (mJy/Beam.s!E1/2!N)', $
               ytitle='Number of pixels', $
               title='KID numdet '+kid_num,$
               max_value=max(yfit)*1.2, $
               mininput=min(bins)*1e3, $
               maxinput=max(bins)*1e3,$
               charthick=3, charsize=1.5
  oplot, 1e3*bins, yfit, col=100, thick=5
  legendastro,['Data','Fit: !4r!3='+strtrim(1e3*coeff[2],2)+' mJy/Beam.s!E1/2!N'],$
              linestyle=[0,0],psym=[0,0],col=[200,100],thick=[5,5],symsize=[1,1],$
              spacing=[1,1],pspacing=[2,2], box=0,pos=[-max(1e3*bins),max(yfit)*1.2]
  device,/close
  ps2pdf_crop, param.output_dir+'/'+param.name4file+'_sensitivity_'+addname
  set_plot, mydevice

  ;;========== Get the NEFD
  if long(kid_num) lt 400 then grid = !nika.grid_step[0] else grid = !nika.grid_step[1]
  if long(kid_num) lt 400 then beam_val = anapar.noise_meas.beam.a else beam_val =  anapar.noise_meas.beam.b
  nefd = nika_anapipe_nefd(param.map.reso, beam_val, grid, map, sens_map, time)

  the_end: if nwsens eq 0 then message, /info, 'KID number '+kid_num+' is always flagged'

  return
end
