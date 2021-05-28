pro nk_lobes_sub, i, scan_list, input_kidpar_file=input_kidpar_file, project_dir=project_dir, $
                  version=version, method=method

  scan = scan_list[i]

  if keyword_set(version) then vv = version else vv=1
  if keyword_set(method) then decor_method = method else decor_method = 'COMMON_MODE_KIDS_OUT'
  
  nk_get_kidpar_ref, n, d, i, kpf, scan=scan
  if keyword_set(input_kidpar_file) then begin
     if n_elements(input_kidpar_file) gt 1 then kidpar_file = input_kidpar_file[i] else $ 
        kidpar_file = input_kidpar_file 
  endif else kidpar_file = kpf
  
  nk_default_param, param
  param.force_kidpar   = 1
  param.file_kidpar    = kidpar_file
  param.decor_cm_dmin  = 100.
  param.output_noise   = 1
  param.do_opacity_correction = 4
  
  param.decor_method   = decor_method
  param.version        = vv
      
  
  param.do_plot = 0
  
  param.map_reso       = 1.
  param.map_xsize      = 600.
  param.map_ysize      = 600.
  param.map_proj       = 'azel'
  param.map_smooth_1mm = 0
  param.map_smooth_2mm = 0
  
  param.plot_dir       = project_dir
  param.project_dir    = project_dir
  
  nk, scan, param=param
  
end
