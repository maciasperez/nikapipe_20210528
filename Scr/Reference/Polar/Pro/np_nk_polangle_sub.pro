
pro np_nk_polangle_sub, i, scan_list, in_param_file
  restore, in_param_file

  ;; if all_proj eq 1, I also output grid_nasmyth and grid1_azel
  ;; to avoid a another processing when checking polarization rotation
  nk, scan_list[i], param=param, kidpar=kidpar, grid=grid, $
      info=info, /polar, lkg_kernel=lkg_kernel

end
