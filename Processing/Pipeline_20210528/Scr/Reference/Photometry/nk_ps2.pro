
pro nk_ps2, iscan, scan_list, param_file_list

  restore, param_file_list[iscan]
  nk, scan_list[iscan], param=param, /filing
end
