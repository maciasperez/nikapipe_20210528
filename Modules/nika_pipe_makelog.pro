;+
;PURPOSE: Create text file with log info
;
;INPUT: parameter structure, data structure and kidpar structure
;
;OUTPUT: FITS file saved in predefined directory
;
;KEYWORDS: none
;
;LAST EDITION: 
;   21/11/2013: creation (adam@lpsc.in2p3.fr)
;    30/01/2014: add flux source to log (macias@lpsc.in2p3.fr)
;-
pro nika_pipe_makelog, param, filtfact = filtfact
  ; Filter factor for V1 data release
  if keyword_set( filtfact) then ffi = filtfact else ffi = [1D0, 1D0]

  iscan = param.iscan

  ;;------- Get info from the IMBFITS
  pressure_hPa = 0.0
  tambient_C = 0.0
  rel_humidity_percent = 0.0
  windvel_mpers = 0.0
  
  if param.imb_fits_file ne '' then antenna = mrdfits(param.imb_fits_file, 1, head, status=status, /silent) $
  else status = -1
  if status eq -1 then message, 'You do not have IMB_FITS, so some values given in the logfile will be wrong'
  if status ne -1 then begin
     
     param.tau_list.iram225[iscan] = sxpar( head, 'TIPTAUZ')
     pressure_hPa = sxpar( head, 'PRESSURE')
     tambient_C = sxpar( head, 'TAMBIENT')
     rel_humidity_percent = sxpar( head, 'HUMIDITY')
     windvel_mpers = sxpar( head, 'WINDVEL')
  endif
  
  ;;------- Log file for all scans ran
  file = param.logfile_dir+'/logfile_all_scans.csv'
  spawn, 'ls '+file, junk
  openw,1,file, /append
  if junk ne file then begin
     printf,1,'# Scan_number, ' + $
            'Source, ' + $
            'RA, ' + $
            'Dec, ' + $
            'Scan_type, ' + $
            'Integration_type, ' + $
            'Median_elevation, ' + $
            'Paralactic_angle, '+$
            'Pressure, ' + $
            'Temperature, ' + $
            'Humidity, ' + $
            'Wind_Velocity, ' + $
            'Tau1mm, ' + $
            'Tau2mm, ' + $
            'Tau225, '+$
            'Fatmo1mm_0.001-0.003Hz, ' + $
            'Fatmo1mm_0.003-0.01Hz, ' + $
            'Fatmo1mm_0.01-0.03Hz, ' + $
            'Fatmo1mm_0.03-0.1Hz, ' + $
            'Fatmo1mm_0.1-0.3Hz, ' + $
            'Fatmo1mm_0.3-1Hz, ' + $
            'Fatmo1mm_1-3Hz, ' + $
            'Fatmo1mm_3-10Hz, ' + $
            'Fatmo2mm_0.001-0.003Hz, ' + $
            'Fatmo2mm_0.003-0.01Hz, ' + $
            'Fatmo2mm_0.01-0.03Hz, ' + $
            'Fatmo2mm_0.03-0.1Hz, ' + $
            'Fatmo2mm_0.1-0.3Hz, ' + $
            'Fatmo2mm_0.3-1Hz, ' + $
            'Fatmo2mm_1-3Hz, ' + $
            'Fatmo2mm_3-10Hz, ' + $
            'NEFD_TOI1mm, ' + $
            'NEFD_map1mm, ' + $
            'NEFD_TOI2mm, ' + $
            'NEFD_map2mm, ' + $
            'Flux_1mm, ' + $
            'Err_Flux_1mm, ' + $
            'Offset_X_1mm, ' + $
            'Offset_Y_1mm, ' + $
            'Flux_2mm, ' + $
            'Err_Flux_2mm, ' + $
            'Offset_X_2mm, ' + $
            'Offset_Y_2mm, ' + $
            'Pipeline Version, ' + $
            'Decor METHOD'

  endif

  printf, 1, $
          param.scan_list[iscan]+', '+$
          param.source+', '+$
          strtrim(long(param.coord_pointing.ra[0]),2)+'h'+strtrim(long(param.coord_pointing.ra[1]),2)+'m'+strtrim(param.coord_pointing.ra[2],2)+'s'+', '+$
          strtrim(long(param.coord_pointing.dec[0]),2)+'h'+strtrim(long(param.coord_pointing.dec[1]),2)+'m'+strtrim(param.coord_pointing.dec[2],2)+'s'+', '+$
          param.SCAN_TYPE[iscan]+', '+$
          strtrim(param.INTEG_TIME[iscan], 2)+', '+$
          strtrim(param.elev_list[iscan] * 180/!pi, 2)+', '+$
          strtrim(param.paral[iscan] * 180/!pi, 2)+', '+$
          strtrim(pressure_hPa, 2)+', '+$ 
          strtrim(tambient_C, 2)+', '+$ 
          strtrim(rel_humidity_percent, 2)+', '+$ 
          strtrim(windvel_mpers, 2)+', '+$ 
          strtrim(param.TAU_LIST.a[iscan], 2)+', '+$
          strtrim(param.TAU_LIST.b[iscan], 2)+', '+$
          strtrim(param.TAU_LIST.iram225[iscan], 2)+', '+$ 
          strtrim(param.meas_atmo.flux_bin.a[iscan, 0], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 1], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 2], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 3], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 4], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 5], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 6], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.a[iscan, 7], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 0], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 1], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 2], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 3], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 4], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 5], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 6], 2)+', '+$
          strtrim(param.meas_atmo.flux_bin.b[iscan, 7], 2)+', '+$
          strtrim(param.NEFD_toi.a[iscan] * 1e3/ffi[0], 2)+', '+$  
          strtrim(param.NEFD_map.a[iscan] * 1e3/ffi[0], 2)+', '+$
          strtrim(param.NEFD_toi.b[iscan] * 1e3/ffi[1], 2)+', '+$
          strtrim(param.NEFD_map.b[iscan] * 1e3/ffi[1], 2)+', '+$
          strtrim(param.source_flux_jy.a[iscan] * 1e3/ffi[0], 2)+', '+$  
          strtrim(param.err_source_flux_jy.a[iscan] * 1e3/ffi[0], 2)+', '+$  
          strtrim(param.source_loc.a[iscan, 0], 2)+', '+$  
          strtrim(param.source_loc.a[iscan, 1], 2)+', '+$  
          strtrim(param.source_flux_jy.b[iscan] * 1e3/ffi[1], 2)+', '+$
          strtrim(param.err_source_flux_jy.b[iscan] * 1e3/ffi[1], 2)+', '+$  
          strtrim(param.source_loc.b[iscan, 0], 2)+', '+$  
          strtrim(param.source_loc.b[iscan, 1], 2)+', '+$
          strtrim(param.version,2)+', ' +$
          strtrim(param.decor.method, 2)
  close,1
  
  return
end
