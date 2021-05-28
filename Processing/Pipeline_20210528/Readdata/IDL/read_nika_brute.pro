

;; This function is wrapper that will call the proper version of
;; read_nika_brute_v*pro depending on the relevant !nika.acq_version
;; -----------------------------------------------------------------

function read_nika_brute, file, param_c, kidpar, data, units, dataU=dataU, $
                          param_d = param_d, $
                          list_data=list_data, list_detector=list_detector,$
                          amp_modulation=amp_modulation, $
                          read_type=read_type, read_array=read_array, silent=silent, $
                          katana=katana, polar=polar

  
case !nika.acq_version of
   'v1': nb_tot_samples = read_nika_brute_v1( file, param_c, kidpar, data, units, $
                                              param_d = param_d, $
                                              list_data=list_data, list_detector=list_detector,$
                                              amp_modulation=amp_modulation, $
                                              read_type=read_type, read_array=read_array, silent=silent, $
                                              katana=katana, polar=polar)

   'v2': nb_tot_samples = read_nika_brute_v2( file, param_c, kidpar, data, units, $
                                              param_d = param_d, $
                                              list_data=list_data, list_detector=list_detector,$
                                              amp_modulation=amp_modulation, $
                                              read_type=read_type, silent=silent, $
                                              katana=katana, polar=polar)


   'v3': nb_tot_samples = READ_NIKA_BRUTE_v3( file, param_c, kidpar, data, dataU, $
                                              param_d = param_d, $
                                              list_data=list_data, list_detector=list_detector,$
                                              amp_modulation=amp_modulation, $
                                              silent=silent, read_type=read_type, $
                                              katana=katana, polar=polar)

   'isa': nb_tot_samples = READ_NIKA_BRUTE_isa( file, param_c, kidpar, data, dataU, $
                                                param_d = param_d, $
                                                list_data=list_data, list_detector=list_detector,$
                                                amp_modulation=amp_modulation, $
                                                silent=silent, read_type=read_type)

   else: begin
      message, /info, !nika.acq_version+" is not a valid value of !nika.acq_version"
      stop
   end
endcase

return, nb_tot_samples

end
