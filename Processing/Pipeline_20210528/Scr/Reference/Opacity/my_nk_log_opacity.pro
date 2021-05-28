
pro my_nk_log_opacity, i, param_file_list

  restore, param_file_list[i]

  print, ''
  print, file_list
  print, ''
  print, output_dir, do_opacity_correction, kidpar_file, version, tsubmax
  print, ''

  nk_log_opacity, file_list, logfile_save, logfile_csv, /norta, output_dir=output_dir, $
                  do_opacity_correction=do_opacity_correction, $
                  input_kidpar_file=kidpar_file, $
                  version = version;;, tsubmax=tsubmax

end
