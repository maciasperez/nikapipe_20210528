
pro baseline_nk_batch, i, scan_list, in_param_file
  
  restore, in_param_file
  nk, scan_list[i], param=param 
  
end

