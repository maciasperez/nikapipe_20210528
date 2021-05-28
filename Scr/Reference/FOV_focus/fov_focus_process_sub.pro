pro fov_focus_process_sub, iscan, scan_list, do_opacity_correction=do_opacity_correction, force_kidpar=force_kidpar, kidpar_file=kidpar_file, project_dir=project_dir, plot_dir=plot_dir, force_process=force_process

  if keyword_set(do_opacity_correction) then do_opacity_correction=1 else do_opacity_correction=0
  if keyword_set(force_kidpar) then force_kidpar=1 else force_kidpar=0
  if keyword_set(force_process) then process = 1 else process =0
  nk_default_param, param
  
  param.do_opacity_correction = do_opacity_correction
  param.force_kidpar          = force_kidpar
  if keyword_set(kidpar_file) then param.file_kidpar = kidpar_file
  if keyword_set(project_dir) then param.project_dir = project_dir
  if keyword_set(plot_dir) then param.plot_dir = param.project_dir+"/Plots"
  
  nk_default_info, info
  nk_init_grid, param, info, grid
  param.do_plot = 0
  param.decor_cm_dmin = 90.     ; to avoid picking secondary lobes up
  param.interpol_common_mode = 1
  param.map_proj = "NASMYTH"
  
  scan = scan_list[iscan]
  
  data_file_save = param.project_dir+'/defocus_beammap_'+strtrim(scan,2)+'.save'
  
  if file_test(data_file_save) lt 1 or process eq 1 then begin
     print, ' reduction of the scan ',strtrim(scan,2)
     print, ''
     random_string = strtrim( long( abs( randomu( seed, 1)*1e8)),2)
     error_report_file = param.project_dir+"/error_report_"+random_string+".dat"
     
     nk_update_param_info, scan, param, info, xml=xml, katana=katana, raw_acq_dir=raw_acq_dir
     param.cpu_date0             = systime(0, /sec)
     param.cpu_time_summary_file = param.output_dir+"/cpu_time_summary_file.dat"
     param.cpu_date_file         = param.output_dir+"/cpu_date.dat"
     spawn, "rm -f "+param.cpu_time_summary_file
     spawn, "rm -f "+param.cpu_date_file
     info.error_report_file = error_report_file
     
     nk_scan_preproc, param, info, data, kidpar, grid
     
     data_copy = data
     nk_scan_reduce, param, info, data, kidpar, grid
     
     info.result_total_obs_time = n_elements(data)/!nika.f_sampling
     w1 = where( kidpar.type eq 1, nw1)
     ikid = w1[0]
     junk = nk_where_flag( data.flag[ikid], [8,11], ncompl=ncompl)
     info.result_valid_obs_time = ncompl/!nika.f_sampling
     
     print, ' saving the results in ',strtrim(data_file_save,2)
     print, ''
     save, param, info, data, kidpar, grid, file=data_file_save
  endif else print, "already processed scan: ", scan
  
end
