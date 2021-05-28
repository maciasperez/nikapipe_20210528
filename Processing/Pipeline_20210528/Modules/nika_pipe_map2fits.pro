;+
;PURPOSE: Save the maps as FITS files
;
;INPUT: The parameter, combined map, map per scan and astrometry
;
;OUTPUT: Saved file in predefined directory
;
;LAST EDITION: 
;   21/09/2013: creation (adam@lpsc.in2p3.fr)
;   24/09/2013: add general info to the fits and the stddev2fits
;               keyword (adam@lpsc.in2p3.fr)
;-

pro nika_pipe_map2fits, param, map_combi, map_list, astrometry, $
                        kid_used_1mm, kid_used_2mm, $
                        var2fits=var2fits, make_products=make_products, cp_scan=cp_scan

  ;;------- Case of noise map with variance
  if keyword_set(var2fits) then begin 
     ;;------- Set the header
     mkhdr, head_map, map_combi.a.jy                       ;get header typique
     putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
     fxaddpar, head_map, 'COL_0', 'Flux map', '[Jy/beam]'
     fxaddpar, head_map, 'COL_1', 'Variance map (from TOI)', '[(Jy/beam)^2]'
     fxaddpar, head_map, 'COL_2', 'Variance map (from map)', '[(Jy/beam)^2]'
     fxaddpar, head_map, 'COL_3', 'Time per pixel map', '[second]'
     fxaddpar, head_map, 'COL_4', 'Flux map per scan', '[Jy/beam]'
     fxaddpar, head_map, 'COL_5', 'Variance map per scan (from TOI)', '[(Jy/beam)^2]'
     fxaddpar, head_map, 'COL_6', 'Variance map per scan (from map)', '[(Jy/beam)^2]'
     fxaddpar, head_map, 'COL_7', 'Time per pixel map per scan', '[second]'
     
     mkhdr, head_list, map_list[*].A.Jy                     ;get header typique
     putast, head_list, astrometry, equinox=2000, cd_type=0 ;astrometry in header
     fxaddpar, head_list, 'COL_0', 'Flux map', '[Jy/beam]'
     fxaddpar, head_list, 'COL_1', 'Variance map (form TOI)', '[(Jy/beam)^2]'
     fxaddpar, head_list, 'COL_2', 'Variance map (form map)', '[(Jy/beam)^2]'
     fxaddpar, head_list, 'COL_3', 'Time per pixel map', '[second]'
     fxaddpar, head_list, 'COL_4', 'Flux map per scan', '[Jy/beam]'
     fxaddpar, head_list, 'COL_5', 'Variance map per scan (form map)', '[(Jy/beam)^2]'
     fxaddpar, head_list, 'COL_6', 'Variance map per scan (from map)', '[(Jy/beam)^2]'
     fxaddpar, head_list, 'COL_7', 'Time per pixel map per scan', '[second]'

     ;;------- 1mm Map in first file
     file1mm = param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits'
     head_map1 = head_map
     head_list1 = head_list
     
     mwrfits, map_combi.A.Jy, file1mm, head_map1, /create, /silent
     mwrfits, map_combi.A.var, file1mm, head_map1, /silent
     mwrfits, (map_combi.A.noise_map)^2, file1mm, head_map1, /silent
     mwrfits, map_combi.A.time, file1mm, head_map1, /silent
     mwrfits, map_list[*].A.Jy, file1mm, head_list1, /silent
     mwrfits, map_list[*].A.var, file1mm, head_list1, /silent
     mwrfits, (map_list[*].A.noise_map)^2, file1mm, head_list1, /silent
     mwrfits, map_list[*].A.time, file1mm, head_list1, /silent

     ;;------- 2mm Map in second file 
     file2mm = param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits'
     head_map2 = head_map
     head_list2 = head_list

     mwrfits, map_combi.B.Jy, file2mm, head_map2, /create, /silent
     mwrfits, map_combi.B.var, file2mm, head_map2, /silent
     mwrfits, (map_combi.B.noise_map)^2, file2mm, head_map2, /silent
     mwrfits, map_combi.B.time, file2mm, head_map2, /silent
     mwrfits, map_list[*].B.Jy, file2mm, head_list2, /silent
     mwrfits, map_list[*].B.var, file2mm, head_list2, /silent
     mwrfits, (map_list[*].B.noise_map)^2, file2mm, head_list2, /silent
     mwrfits, map_list[*].B.time, file2mm, head_list2, /silent

  endif

  ;;============================================================
  ;;============================================================

  ;;------- Case of noise map with stddev
  if not keyword_set(var2fits) then begin 
     
     ;;------- Set the header
     mkhdr, head_map, map_combi.a.jy                       ;get header typique
     putast, head_map, astrometry, equinox=2000, cd_type=0 ;astrometry in header
     fxaddpar, head_map, 'COL_0', 'Flux map', '[Jy/beam]'  ;add info to the header
     fxaddpar, head_map, 'COL_1', 'Stddev map (from TOI)', '[Jy/beam]'
     fxaddpar, head_map, 'COL_2', 'Stddev map (form map)', '[Jy/beam]'
     fxaddpar, head_map, 'COL_3', 'Time per pixel map', '[second]'
     fxaddpar, head_map, 'COL_4', 'Flux map per scan', '[Jy/beam]'
     fxaddpar, head_map, 'COL_5', 'Stddev map per scan (from TOI)', '[Jy/beam]'
     fxaddpar, head_map, 'COL_6', 'Stddev map per scan (from map)', '[Jy/beam]'
     fxaddpar, head_map, 'COL_7', 'Time per pixel map per scan', '[second]'
     fxaddpar, head_map, 'COL_8', 'General scan info', 'Units are second and arcsec'
     
     mkhdr, head_list, map_list[*].A.Jy                     ;get header typique
     putast, head_list, astrometry, equinox=2000, cd_type=0 ;astrometry in header
     fxaddpar, head_list, 'COL_0', 'Flux map', '[Jy/beam]'  ;add info to the header
     fxaddpar, head_list, 'COL_1', 'Stddev map (from TOI)', '[Jy/beam]'
     fxaddpar, head_list, 'COL_2', 'Stddev map (form map)', '[Jy/beam]'
     fxaddpar, head_list, 'COL_3', 'Time per pixel map', '[second]'
     fxaddpar, head_list, 'COL_4', 'Flux map per scan', '[Jy/beam]'
     fxaddpar, head_list, 'COL_5', 'Stddev map per scan (from TOI)', '[Jy/beam]'
     fxaddpar, head_list, 'COL_6', 'Stddev map per scan (from map)', '[Jy/beam]'
     fxaddpar, head_list, 'COL_7', 'Time per pixel map per scan', '[second]'
     fxaddpar, head_list, 'COL_8', 'General scan info', 'Units are second and arcsec'
     
     ;;------- 1mm Map in first file
     file1mm = param.output_dir+'/MAPS_1mm_'+param.name4file+'_'+param.version+'.fits'
     head_map1 = head_map
     head_list1 = head_list
     
     mwrfits, map_combi.A.Jy, file1mm, head_map1, /create, /silent
     mwrfits, sqrt(map_combi.A.var), file1mm, head_map1, /silent
     mwrfits, map_combi.A.noise_map, file1mm, head_map1, /silent
     mwrfits, map_combi.A.time, file1mm, head_map1, /silent
     mwrfits, map_list.A.Jy, file1mm, head_list1, /silent
     mwrfits, sqrt(map_list.A.var), file1mm, head_list1, /silent
     mwrfits, map_list.A.noise_map, file1mm, head_list1, /silent
     mwrfits, map_list.A.time, file1mm, head_list1, /silent
     
     ;;------- 2mm Map in second file
     file2mm = param.output_dir+'/MAPS_2mm_'+param.name4file+'_'+param.version+'.fits'
     head_map2 = head_map
     head_list2 = head_list
     
     mwrfits, map_combi.B.Jy, file2mm, head_map2, /create, /silent
     mwrfits, sqrt(map_combi.B.var), file2mm, head_map2, /silent
     mwrfits, map_combi.B.noise_map, file2mm, head_map2, /silent
     mwrfits, map_combi.B.time, file2mm, head_map2, /silent
     mwrfits, map_list.B.Jy, file2mm, head_list2, /silent
     mwrfits, sqrt(map_list.B.var), file2mm, head_list2, /silent
     mwrfits, map_list.B.noise_map, file2mm, head_list2, /silent
     mwrfits, map_list.B.time, file2mm, head_list2, /silent

  endif

  ;;============================================================
  ;;============================================================
  
  ;;------- Add general info about the scans
  ;; TO DO: take the param structure and build the info from this
  info = {N_scan:n_elements(param.scan_list),$
          time_integ_tot:total(param.integ_time),$
          tau240GHz_avg:mean(param.tau_list.a),$
          tau140GHz_avg:mean(param.tau_list.b),$
          time_integ:param.integ_time,$
          tau240GHz:param.tau_list.a,$
          tau140GHz:param.tau_list.b,$       
          scan_type:param.scan_type,$
          beam_calib_240Ghz:12.5,$
          beam_calib_140Ghz:18.5}
  mwrfits, info, file1mm, /silent
  mwrfits, info, file2mm, /silent

  ;;------- Copy the file with another name (usefull for nika_pipe_launch_all_scan)
  file1mm_s = param.output_dir+'/MAPS_'+param.scan_list[0]+'_1mm_'+param.name4file+'_'+param.version+'.fits'
  file2mm_s = param.output_dir+'/MAPS_'+param.scan_list[0]+'_2mm_'+param.name4file+'_'+param.version+'.fits'
  
  if keyword_set(cp_scan) then spawn, '/bin/cp -f '+file1mm+' '+file1mm_s
  if keyword_set(cp_scan) then spawn, '/bin/cp -f '+file2mm+' '+file2mm_s
  
  ;;==========================================================================================
  ;;==========================================================================================
  ;;==========================================================================================
  ;;==========================================================================================
  
  if keyword_set(make_products) then begin
     ;;------- Info to put at the end of the FITS (Combined map)
     info_combi1mm = {Nscan_used:n_elements(param.scan_list),$
                      scan_used:'',$
                      kid_used:intarr(n_elements(reform(kid_used_1mm[0,*]))),$
                      tau_zenith:0d0,$
                      time_integ:0d0,$
                      scan_type:''}
     info_combi1mm = replicate(info_combi1mm, n_elements(param.scan_list))
     info_combi1mm.scan_used = param.scan_list
     info_combi1mm.kid_used = transpose(kid_used_1mm)
     info_combi1mm.tau_zenith = param.tau_list.a
     info_combi1mm.time_integ = param.integ_time
     info_combi1mm.scan_type = param.scan_type
     info_combi2mm = {Nscan_used:n_elements(param.scan_list),$
                      scan_used:'',$
                      kid_used:intarr(n_elements(reform(kid_used_2mm[0,*]))),$
                      tau_zenith:0d0,$
                      time_integ:0d0,$
                      scan_type:''}
     info_combi2mm = replicate(info_combi2mm, n_elements(param.scan_list))
     info_combi2mm.scan_used = param.scan_list
     info_combi2mm.kid_used = transpose(kid_used_2mm)
     info_combi2mm.tau_zenith = param.tau_list.b
     info_combi2mm.time_integ = param.integ_time
     info_combi2mm.scan_type = param.scan_type

     file1mm = param.output_dir+'/IRAM_MAP_'+param.name4file+'_combined_1mm.fits'
     file2mm = param.output_dir+'/IRAM_MAP_'+param.name4file+'_combined_2mm.fits'

     flux1mm = map_combi.A.Jy
     out = where(map_combi.A.time eq 0, nout)
     if nout ne 0 then flux1mm[out] = !values.f_nan
     flux2mm = map_combi.B.Jy
     out = where(map_combi.B.time eq 0, nout)
     if nout ne 0 then flux2mm[out] = !values.f_nan

     map2save1mm = [[[flux1mm]],[[sqrt(map_combi.A.var)]],[[map_combi.A.time]]]
     map2save2mm = [[[flux2mm]],[[sqrt(map_combi.B.var)]],[[map_combi.B.time]]]

     mkhdr, h_1mm, map2save1mm
     putast, h_1mm, astrometry, equinox=2000, cd_type=0 
     fxaddpar, h_1mm, 'CONT', 'Flux, noise and time maps', '[Npix_x, Npix_y, 3]' 
     fxaddpar, h_1mm, 'AXIS1', 'Flux density map', '[Npix_x, Npix_y]' 
     fxaddpar, h_1mm, 'AXIS2', 'Standard deviation map', '[Npix_x, Npix_y]'
     fxaddpar, h_1mm, 'AXIS3', 'Time per pixel map', '[Npix_x, Npix_y]'
     fxaddpar, h_1mm, 'UNIT1', 'Jy/beam', ''            
     fxaddpar, h_1mm, 'UNIT2', 'Jy/beam', ''            
     fxaddpar, h_1mm, 'UNIT3', 'second', ''  
     h_2mm = h_1mm

     mwrfits, map2save1mm, file1mm, h_1mm, /create, /silent
     mwrfits, info_combi1mm, file1mm, /silent
     mwrfits, map2save2mm, file2mm, h_1mm, /create, /silent
     mwrfits, info_combi2mm, file2mm, /silent

     ;;------- Map per scan
     for is=0, n_elements(param.scan_list) -1 do begin
        info_scan1mm = {Nscan_used:1,$
                        scan_used:param.scan_list[is],$
                        kid_used:reform(kid_used_1mm[is,*]),$
                        tau_zenith:param.tau_list.a[is],$
                        time_integ:param.integ_time[is],$
                        scan_type:param.scan_type[is]}
        info_scan2mm = {Nscan_used:1,$
                        scan_used:param.scan_list[is],$
                        kid_used:reform(kid_used_2mm[is,*]),$
                        tau_zenith:param.tau_list.b[is],$
                        time_integ:param.integ_time[is],$
                        scan_type:param.scan_type[is]}

        file1mm = param.output_dir+'/IRAM_MAP_'+param.name4file+'_'+param.scan_list[is]+'_1mm.fits'
        file2mm = param.output_dir+'/IRAM_MAP_'+param.name4file+'_'+param.scan_list[is]+'_2mm.fits'
        
        flux1mm = map_list[is].A.Jy
        out = where(map_list[is].A.time eq 0, nout)
        if nout ne 0 then flux1mm[out] = !values.f_nan
        flux2mm = map_list[is].B.Jy
        out = where(map_list[is].B.time eq 0, nout)
        if nout ne 0 then flux2mm[out] = !values.f_nan

        map2save1mm = [[[flux1mm]],[[sqrt(map_list[is].A.var)]],[[map_list[is].A.time]]]
        map2save2mm = [[[flux2mm]],[[sqrt(map_list[is].B.var)]],[[map_list[is].B.time]]]

        mwrfits, map2save1mm, file1mm, h_1mm, /create, /silent
        mwrfits, info_scan1mm, file1mm, /silent

        mwrfits, map2save2mm, file2mm, h_2mm, /create, /silent
        mwrfits, info_scan2mm, file2mm, /silent
     endfor
     
  endif

  return
end
