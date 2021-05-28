;+
;PURPOSE: Provide a basics map analysis
;
;INPUT: A parameter structure containing what you want to compute
;
;OUTPUT: Depends on the param (e.g. profile, flux, ...)
;
;KEYWORDS: - indiv_scan: set this keyword in order to save your plots
;            with the scan name at the end (e.g. 20121121s0043)
;          - ps: to do .ps maps instead of .pdf
;          - no_sat: the maps are not grey when saturated
;
;LAST EDITION: 
;   24/09/2013: creation (adam@lpsc.in2p3.fr)
;   05/02/2014: add the transfer function
;   07/02/2014: add the log file here with make_product keyword
;   14/02/2014: remove the log file and put it back to nika_pipe_launch
;-

pro nika_anapipe_launch, param, anapar, indiv_scan=indiv_scan, $
                         ps=ps, no_sat=no_sat, make_logbook=make_logbook, $
                         silent=silent, filtfact=filtfact
  day2run, param.day[0], run
  fill_nika_struct, run

  ;;------- Get the maps
  map_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',0,head_1mm,/SILENT)+$
            anapar.cor_zerolevel.A
  noise_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',1,head_1mm,/SILENT)
  noiseM_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',2,head_1mm,/SILENT)
  time_1mm = mrdfits(param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits',3,head_1mm,/SILENT)
  map_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',0,head_2mm,/SILENT)+$
            anapar.cor_zerolevel.B
  noise_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',1,head_2mm,/SILENT)
  noiseM_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',2,head_2mm,/SILENT)
  time_2mm = mrdfits(param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits',3,head_2mm,/SILENT)
  
  ;;------- Give basic info
  if not keyword_set( silent) then begin
     print, ''
     print, 'Scan Infos:'
     for iscan=0, n_elements(param.scan_list)-1 do begin
        print, 'Scan number '+strtrim(iscan+1,2)+':'
        print, '     Scan type:           '+param.scan_type[iscan]
        print, '     Integration time:    '+strtrim(param.integ_time[iscan],2)+'  seconds'
        print, '     Mean elevation:      '+strtrim(param.elev_list[iscan]*180.0/!pi,2)+'  degrees'
        print, '     Tau 1mm:             '+strtrim(param.tau_list.a[iscan],2)
        print, '     Tau 2mm:             '+strtrim(param.tau_list.b[iscan],2)
     endfor
     print,'Total integration time: ', strtrim(total(param.integ_time), 2)+'  seconds'
  endif
  ;;------- Plot the maps
  if anapar.flux_map.apply eq 'yes' then nika_anapipe_flux_map, param, anapar, $
     map_1mm, noise_1mm, map_2mm, noise_2mm, head_1mm, head_2mm, indiv_scan=indiv_scan, ps=ps, no_sat=no_sat
  if anapar.noise_map.apply eq 'yes' then nika_anapipe_noise_map, param, anapar, $
     noiseM_1mm, noiseM_2mm, head_1mm, head_2mm, indiv_scan=indiv_scan, ps=ps
  if anapar.time_map.apply eq 'yes' then nika_anapipe_time_map, param, anapar, $
     time_1mm, time_2mm, head_1mm, head_2mm, indiv_scan=indiv_scan, ps=ps
  if anapar.snr_map.apply eq 'yes' then nika_anapipe_snr_map, param, anapar, $
     map_1mm, noiseM_1mm, time_1mm, map_2mm, noiseM_2mm, time_2mm, head_1mm, head_2mm, indiv_scan=indiv_scan, ps=ps, no_sat=no_sat

  ;;------- Beam measurement
  if anapar.beam.apply eq 'yes' then nika_anapipe_beam, param, anapar, ps=ps
  
  ;;------- Profiles measurements
  if anapar.profile.apply eq 'yes' then nika_anapipe_profiles, param, anapar

  ;;------- Point source photometry
  if anapar.ps_photo.apply eq 'yes' then nika_anapipe_psphoto, param, anapar, indiv_scan=indiv_scan, make_logbook=make_logbook, filtfact=filtfact
  
  ;;------- Diffuse source photometry
  if anapar.dif_photo.apply eq 'yes' then nika_anapipe_difphoto, param, anapar

  ;;------- Plot map per detectors and per scan
  if anapar.mapperkid.apply eq 'yes' then nika_anapipe_mapperkid, param, anapar
  if anapar.mapperscan.apply eq 'yes' then nika_anapipe_mapperscan, param, anapar

  ;;------- Compute the spectrum and plot the map
  if anapar.spectrum.apply eq 'yes' then nika_anapipe_spectrum, param, anapar, map_1mm, noise_1mm, $
     map_2mm, noise_2mm, head_1mm, head_2mm, ps=ps
  
  ;;------- Noise study
  if anapar.noise_meas.apply eq 'yes' then nika_anapipe_noise_study, param, anapar, indiv_scan=indiv_scan
  
  ;;------- Find point sources in a map (contaminated by diffuse emmission)
  if anapar.search_ps.apply eq 'yes' then nika_anapipe_search4ps, param, anapar
  
  ;;------- Compute the transfer function comparing the input (simu)
  ;;        and output maps
  if anapar.trans_func_spec.apply eq 'yes' then nika_anapipe_transfer_function, param, anapar
  if anapar.trans_func_prof.apply eq 'yes' then nika_anapipe_transfer_function_profile, param, anapar
  
  ;;------- Save the anapar
  save, filename=param.output_dir+'/anapar_'+param.name4file+'_'+param.version+'.save', anapar

  reset_nika_struct

  return
end
