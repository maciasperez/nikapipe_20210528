;+
;PURPOSE: This is the main procedure of the simulation which 
;         produce RFdIdQ simulated data.
;
;INPUT: The parameter file and its version.
;
;OUTPUT: The simulated RFdIdQ data.
;
;KEYWORDS:
;
;LAST EDITION: 
;   04/02/2013: creation (adam@lpsc.in2p3.fr)
;   13/01/2014: change the cut of scan according to nika_pipe_launch
;   21/01/2014: force the number of samples to be an even number
;-

pro partial_simu_launch, param
  
  ;;############# Simulate data for individual scans 
  nscans = n_elements(param.scan_list)
  for iscan = 0 , nscans - 1 do begin
     param.iscan = iscan
     
     partial_simu_getdata, param, data, kidpar
     npt = n_elements(data)
     if long(npt)/2 ne double(npt)/2 then data = data[1:*]
     ;;nika_pipe_cutscan, param, data, loc_ok, /safe
     ;;data = data[loc_ok]
     partial_simu_source, param, data, kidpar
     partial_simu_glitch, param, data, kidpar
     partial_simu_pulsetube, param, data, kidpar
     partial_simu_atmo, param, data, kidpar
     partial_simu_elec, param, data, kidpar
     
     message, /info, 'Data computed for the scan '+strtrim(iscan+1,2)+'/'+strtrim(nscans,2)
     
     save, filename=param.output_dir+'/TOI_'+param.name4file+'_'+param.version+'_s'+$
           string(param.iscan, format="(I4.4)")+'.save', data, kidpar
  endfor
  
  return
end
