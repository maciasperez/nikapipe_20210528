
pro my_rta_update_log_iram_tel, i, param_file_list, nonika

  restore, param_file_list[i]
  rta_update_log_iram_tel, file_list, logfile_save, logfile_csv, nonika=nonika

end
