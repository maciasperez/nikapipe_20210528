;+
;PURPOSE: Study the noise properties in different ways
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

pro nika_anapipe_noise_study, param, anapar, indiv_scan=indiv_scan

  if keyword_set(indiv_scan) then add_name = '_'+param.scan_list[0] else add_name = ''

  mydevice = !d.name

  ;;------- Compute sensitivity global
  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)+$
            anapar.cor_zerolevel.A
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',1,head_1mm,/SILENT)
  noise_nfm_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',2,head_1mm,/SI)
  time_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',3,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)+$
            anapar.cor_zerolevel.B
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',1,head_2mm,/SILENT)
  noise_nfm_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',2,head_2mm,/SI)
  time_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',3,head_2mm,/SILENT)
  
  map_list_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',4,head_1mm,/SIL)
  noise_list_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',5,head_1mm,/SI)
  noise_list_nfm_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',6,head_1mm,/SI)
  time_list_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',7,head_1mm,/SIL)
  map_list_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',4,head_2mm,/SIL)
  noise_list_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',5,head_2mm,/SI)
  noise_list_nfm_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',6,head_2mm,/SI)
  time_list_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',7,head_2mm,/SIL)
  
  ;;------- Measure the noise power spectrum slope
  if anapar.noise_meas.spec eq 'yes' then nika_anapipe_noise_spec, param, anapar, $
     map_1mm, noise_1mm, noise_nfm_1mm, time_1mm, $
     map_2mm, noise_2mm, noise_nfm_2mm, time_2mm, $
     map_list_1mm, noise_list_1mm, noise_list_nfm_1mm, time_list_1mm, $
     map_list_2mm, noise_list_2mm, noise_list_nfm_2mm, time_list_2mm,$
     head_1mm, head_2mm, par1mm=par_spec_1mm, par2mm=par_spec_2mm
  
  ;;---------- Get the sensitivity
  nika_anapipe_sensitivity, param, anapar, $
                            map_1mm, noise_1mm, noise_nfm_1mm, time_1mm, $
                            map_2mm, noise_2mm, noise_nfm_2mm, time_2mm,$
                            map_list_1mm, noise_list_1mm, noise_list_nfm_1mm, time_list_1mm, $
                            map_list_2mm, noise_list_2mm, noise_list_nfm_2mm, time_list_2mm,$
                            head_1mm, head_2mm, indiv_scan=indiv_scan, $
                            par_spec_1mm=par_spec_1mm, par_spec_2mm=par_spec_2mm
  
  ;;------- Compute sensitivity per detectors
  loadct,4, /silent
  if anapar.noise_meas.per_kid eq 'yes' then begin
     restore, param.output_dir+'/kidpar_'+param.name4file+'_'+param.version+'.save'
     restore, param.output_dir+'/map_per_KID_'+param.name4file+'_'+param.version+'.save'
     
     wkid = where(kidpar.type eq 1, nkid)
     w1 = where(kidpar.type eq 1 and kidpar.array eq 1, n1mm)
     w2 = where(kidpar.type eq 1 and kidpar.array eq 2, n2mm)
     
     sens_toi_1mm = dblarr(n1mm)
     sens_map_1mm = dblarr(n1mm)
     nefd_1mm = dblarr(n1mm)
     sens_toi_2mm = dblarr(n2mm)
     sens_map_2mm = dblarr(n2mm)
     nefd_2mm = dblarr(n2mm)
     
     for ikid=0, nkid-1 do begin
        kid_num = string(strtrim(kidpar[wkid[ikid]].numdet,2),FORMAT='(I04)')
        nika_anapipe_sensitivity_per_kid, param, anapar,$
                                          map_per_kid[ikid].jy, $
                                          sqrt(map_per_kid[ikid].var), $
                                          map_per_kid[ikid].time, $
                                          kid_num, sens1, sens2, nefd
        if kidpar[[wkid[ikid]]].array eq 1 then sens_toi_1mm[ikid] = sens1
        if kidpar[[wkid[ikid]]].array eq 1 then sens_map_1mm[ikid] = sens2
        if kidpar[[wkid[ikid]]].array eq 1 then nefd_1mm[ikid] = nefd
        if kidpar[[wkid[ikid]]].array eq 2 then sens_toi_2mm[ikid-n1mm] = sens1
        if kidpar[[wkid[ikid]]].array eq 2 then sens_map_2mm[ikid-n1mm] = sens2
        if kidpar[[wkid[ikid]]].array eq 2 then nefd_2mm[ikid-n1mm] = nefd
     endfor

     ;;------- Put all the pdf in a single one
     spawn, 'pdftk '+param.output_dir+'/'+param.name4file+'_sensitivity_KID*.pdf cat output '+param.output_dir+'/'+param.name4file+add_name+'_sensitivity_all_KIDs.pdf'
     spawn, 'rm -rf '+param.output_dir+'/'+param.name4file+'_sensitivity_KID*.pdf'
     
     ;;------- Exclude flagged KIDs
     wok = where(finite(sens_toi_1mm) eq 1, nwok)
     if nwok ne 0 then sens_toi_1mm = sens_toi_1mm[wok]
     wok = where(finite(sens_toi_2mm) eq 1, nwok)
     if nwok ne 0 then sens_toi_2mm = sens_toi_2mm[wok]
     wok = where(finite(sens_map_1mm) eq 1, nwok)
     if nwok ne 0 then sens_map_1mm = sens_map_1mm[wok]
     wok = where(finite(sens_map_2mm) eq 1, nwok)
     if nwok ne 0 then sens_map_2mm = sens_map_2mm[wok]
     wok = where(finite(nefd_1mm) eq 1, nwok)
     if nwok ne 0 then nefd_1mm = nefd_1mm[wok]
     wok = where(finite(nefd_2mm) eq 1, nwok)
     if nwok ne 0 then nefd_2mm = nefd_2mm[wok]

     ;;------- Compute distributions
     hist_toi_1mm = histogram(sens_toi_1mm*1e3, binsize=1)
     hist_map_1mm = histogram(sens_map_1mm*1e3, binsize=1)  
     hist_nefd_1mm = histogram(nefd_1mm*1e3, binsize=1)  
     hist_toi_2mm = histogram(sens_toi_2mm*1e3, binsize=0.3)
     hist_map_2mm = histogram(sens_map_2mm*1e3, binsize=0.3)
     hist_nefd_2mm = histogram(nefd_2mm*1e3, binsize=0.3)

     set_plot, 'ps'
     ;;------ Sensitivity
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+add_name+'_sensitivity_all1mm.ps'
     cgHistoplot, sens_map_1mm*1e3, $
                  binsize=1,$
                  /FILLPOLYGON, $
                  POLYCOLOR=220, $
                  datacolorname=160, $
                  thick=2, $
                  xtitle='Sensitivity of the KIDs (mJy/Beam.s!E1/2!N)', $
                  ytitle='Number of KID', $
                  max_value=max([hist_map_1mm,hist_toi_1mm])*1.2, $
                  maxinput=(stddev(sens_map_1mm)*3+mean(sens_map_1mm))*1e3,$
                  mininput=(-stddev(sens_map_1mm)*3+mean(sens_map_1mm))*1e3,$
                  charthick=3, charsize=1.5
     cgHistoplot, sens_toi_1mm*1e3, $
                  binsize=1,$
                  /LINE_FILL, $
                  line_thick=0.1, $
                  spacing=0.02, $
                  thick=2, $
                  ORIENTATION=[45,45], $
                  POLYCOLOR=100, $
                  datacolorname=130, $
                  /oplot
     legendastro,['TOI sensitivity distribution', 'MAP sensitivity distribution'],linestyle=[0,0],psym=[0,0],col=[100,220],thick=[5,5],symsize=[1,1],/top,/right,box=0;,spacing=[1,1],pspacing=[2,2]
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+add_name+'_sensitivity_all1mm'

     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+add_name+'_sensitivity_all2mm.ps'
     cgHistoplot, sens_map_2mm*1e3, $
                  binsize=0.3,$
                  /FILLPOLYGON, $
                  POLYCOLOR=220, $
                  datacolorname=160, $
                  thick=2, $
                  xtitle='Sensitivity of the KIDs (mJy/Beam.s!E1/2!N)', $
                  ytitle='Number of KID', $
                  max_value=max([hist_map_2mm,hist_toi_2mm])*1.2, $
                  maxinput=(stddev(sens_map_2mm)*3+mean(sens_map_2mm))*1e3,$
                  mininput=(-stddev(sens_map_2mm)*3+mean(sens_map_2mm))*1e3,$
                  charthick=3, charsize=1.5
     cgHistoplot, sens_toi_2mm*1e3, $
                  binsize=0.3,$
                  /LINE_FILL, $
                  line_thick=0.1, $
                  spacing=0.02, $
                  thick=2, $
                  ORIENTATION=[45,45], $
                  POLYCOLOR=100, $
                  datacolorname=130, $
                  /oplot
     legendastro,['TOI sensitivity distribution', 'MAP sensitivity distribution'],linestyle=[0,0],psym=[0,0],col=[100,220],thick=[5,5],symsize=[1,1],/top,/right,box=0;,spacing=[1,1],pspacing=[2,2]
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+add_name+'_sensitivity_all2mm'
     
     ;;------ NEFD
     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+add_name+'_NEFD_all1mm.ps'
     cgHistoplot, nefd_1mm*1e3, $
                  binsize=1,$
                  /FILLPOLYGON, $
                  POLYCOLOR=220, $
                  datacolorname=160, $
                  thick=2, $
                  xtitle='NEFD of the KIDs (mJy/Beam.s!E1/2!N)', $
                  ytitle='Number of KID', $
                  max_value=max(hist_nefd_1mm)*1.2, $
                  maxinput=(stddev(nefd_1mm)*3+mean(nefd_1mm))*1e3,$
                  mininput=(-stddev(nefd_1mm)*3+mean(nefd_1mm))*1e3,$
                  charthick=3, charsize=1.5
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+add_name+'_NEFD_all1mm'

     device,/color, bits_per_pixel=256, filename=param.output_dir+'/'+param.name4file+add_name+'_NEFD_all2mm.ps'
     cgHistoplot, nefd_2mm*1e3, $
                  binsize=0.3,$
                  /FILLPOLYGON, $
                  POLYCOLOR=220, $
                  datacolorname=160, $
                  thick=2, $
                  xtitle='NEFD of the KIDs (mJy/Beam.s!E1/2!N)', $
                  ytitle='Number of KID', $
                  max_value=max(hist_nefd_2mm)*1.2, $
                  maxinput=(stddev(nefd_2mm)*3+mean(nefd_2mm))*1e3,$
                  mininput=(-stddev(nefd_2mm)*3+mean(nefd_2mm))*1e3,$
                  charthick=3, charsize=1.5
     device,/close
     ps2pdf_crop, param.output_dir+'/'+param.name4file+add_name+'_NEFD_all2mm'
  endif
  loadct,39, /silent

  ;;------- Get the sensitivity versus the opacity
  if anapar.noise_meas.vs_tau eq 'yes' then nika_anapipe_sensitivity_vs_tau, param, anapar, $
     noise_list_nfm_1mm, time_list_1mm, noise_list_nfm_2mm, time_list_2mm

  set_plot, mydevice

  return
end
