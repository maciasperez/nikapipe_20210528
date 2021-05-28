
pro my_nk_log_iram_tel, i, param_file_list

  restore, param_file_list[i]
  print, file_list

  nk_log_iram_tel, file_list, logfile_save, logfile_csv, /norta

end
