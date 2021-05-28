
pro obs_nk_ps_2, i, scan_list, in_param_file, parity=parity, polar=polar, $
                 fpc_corr_file=fpc_corr_file, $
                 first_new_radec_map_center_file=first_new_radec_map_center_file, $
                 second_new_radec_map_center_file1=second_new_radec_map_center_file

restore, in_param_file
  
if keyword_set(parity) then parity = (-1)^i

if keyword_set(fpc_corr_file) then begin
   readcol, fpc_corr_file, myscan, fpc_az, fpc_el, $
            format='A,D,D', delim=',', comment='#'
   w = where( strupcase(myscan) eq strupcase(scan_list[i]), nw)
   if nw ne 0 then begin
      param.fpc_az = fpc_az[w]
      param.fpc_el = fpc_el[w]
   endif
endif

if keyword_set(first_new_radec_map_center_file) then begin
   readcol, first_new_radec_map_center_file, myscan, new_map_center_ra, new_map_center_dec, $
            format='A,D,D', delim=',', comment='#'
   w = where( strupcase(myscan) eq strupcase(scan_list[i]), nw)
   if nw ne 0 then begin
      param.new_map_center_ra  = new_map_center_ra[ w]
      param.new_map_center_dec = new_map_center_dec[w]
   endif
endif

if keyword_set(second_new_radec_map_center_file) then begin
   readcol, second_new_radec_map_center_file, myscan, new_map_center_ra, new_map_center_dec, $
            format='A,D,D', delim=',', comment='#'
   w = where( strupcase(myscan) eq strupcase(scan_list[i]), nw)
   if nw ne 0 then begin
      param.new_map_center_ra1  = new_map_center_ra[ w]
      param.new_map_center_dec1 = new_map_center_dec[w]
   endif
endif

nk, scan_list[i], param=param, header=header, grid=grid, $
    subtract_maps=subtract_maps, simpar=simpar, parity=parity, polar=polar, $
    lkg_kernel=lkg_kernel

end

