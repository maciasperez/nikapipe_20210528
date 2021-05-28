; Take a list of scans and make maps per subscan. Deduce if the source
; is moving or not
pro anom_refrac, scan_list, source, $
                 noreset = noreset, mapsize = k_mapsize
  
  nk_default_param, param
  param.project_dir = param.dir_save+ '/'+ source
  param.do_opacity_correction = 6
  param.iconic = 1
  param.map_proj = 'AZEL'
  param.interpol_common_mode = 1
  if keyword_set(k_mapsize) then mapsize = k_mapsize else mapsize = 300 ; arcsec
  param.map_xsize = mapsize
  param.map_ysize = mapsize
  param.map_reso = 4  ; enough (1/3 beam)
  param.decor_method = 'common_mode_one_block'
  param.decor_cm_dmin = 60.     ; 100 recommended by Nicolas 17/3/2017, 60 JMP
; minimum distance to the source for a sample to be declared "off
; source"
  param.map_per_subscan = 1     ; do a map and pointing reduction per subscan

  param.do_tel_gain_corr =  0   ; no gain elevation correction (TBD)
  param.math = 'CF'
  
;isc = 0
  param.version = '4'           ; '4' with pipeline improved corrections
  param.silent = 1
  nscans = n_elements( scan_list)
  for isc = 0, nscans-1 do begin
     if not keyword_set( noreset) then nk_reset_filing, param,  scan_list[isc]
     delvarx, kidout, data, info
     wd, /all
     nk, param = param, scan_list[ isc], /filing
  endfor
  return
end
