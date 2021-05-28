
pro nk_lkg_sub, i, in_param_file

  restore, in_param_file[i]
  nk, scan, param=param, /polar

end
