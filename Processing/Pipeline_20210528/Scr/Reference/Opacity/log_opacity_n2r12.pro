
pro log_opacity_n2r12


  output_dir = "/mnt/data/NIKA2Team/perotto/Plots/N2R12/Opacity"

  
  spawn, "ls "+!nika.imb_fits_dir+"/*201710*imb.fits", imb_fits_list
  
  nonika = 0

  ;; marche pas...
  tsubmax = 1000.
  
  ;;--------------------------------------------------------------
  ;;NB: opacity correction method has an impact on the flux (not on
  ;;the tau estimates themselves) 
  do_opacity_correction = 2
  logfile_save_final = output_dir+"/Log_Opacity_N2R12_1025_1.save"
  logfile_csv_final  = output_dir+"/Log_Opacity_N2R12_1025_1.csv"
  version = 1
  kidpar_file = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  
  do_opacity_correction = 4
  logfile_save_final = output_dir+"/Log_Opacity_N2R12_v2.save"
  logfile_csv_final  = output_dir+"/Log_Opacity_N2R12_v2.csv"
  version = 2
  kidpar_file = 'kidpar_N2R12_v2_skydip.fits'
  
  do_opacity_correction = 4
  logfile_save_final = output_dir+"/Log_Opacity_N2R12_opera.save"
  logfile_csv_final  = output_dir+"/Log_Opacity_N2R12_opera.csv"
  version = 4
  kidpar_file = 'kidpar_N2R12_opera_skydip.fits'
  
  ;;kidpar_in_file     = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
  ;;kidpar_out_file    = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus_branch1.fits"
  ;;kidpar_skydip_file = "/home/perotto/NIKA/Plots/N2R12/Opacity/kidpar_N2R12_branch1_skydip.fits"
  ;;skydip_coeffs, kidpar_in_file, kidpar_skydip_file, kidpar_out_file

    
  ncpu_max = 24
  
  nfiles = n_elements(imb_fits_list)
  optimize_nproc, nfiles, ncpu_max, nproc
  nfiles_per_proc = long( float(nfiles)/nproc)
  
  param_file_list = output_dir+'/log_opacity_N2R12_param_'+strtrim( indgen(nproc),2)+'.save'
  
;; Clear up parameter files from previous calls
  for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]
  
  
  for iproc=0, nproc-1 do begin
     if iproc ne (nproc-1) then begin
        file_list = imb_fits_list[iproc*nfiles_per_proc:(iproc+1)*nfiles_per_proc-1]
     endif else begin
        file_list = imb_fits_list[iproc*nfiles_per_proc:*]
     endelse
     logfile_save = output_dir+"/Log_Opacity_N2R12_sub"+strtrim(iproc,2)+".save"
     logfile_csv  = output_dir+"/Log_Opacity_N2R12_sub"+strtrim(iproc,2)+".csv"
     save, file_list, logfile_save, logfile_csv, $
           output_dir, do_opacity_correction, kidpar_file, version,$
           tsubmax, file=param_file_list[iproc]
  endfor
  
  ;;i=0
  ;;my_nk_log_opacity, i, param_file_list
  
  split_for, 0, nproc-1, nsplit=nproc, $
             commands=['my_nk_log_opacity, i, param_file_list'], $
             varnames=['param_file_list']
  
;; concatenate automatically
;; noproc=-1 to take the offline results and complete them
;; noproc= 1 to take the offline results as they were done (just
;; above): recommended
;; /norta is offline processing (not during the run)
  nk_log_opacity, imb_fits_list, logfile_save_final, logfile_csv_final, /norta, noproc=1, $
                  output_dir=output_dir, version=version
  
  
  
end
