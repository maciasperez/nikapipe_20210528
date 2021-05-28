
pro log_iram_tel_n2r11, parallel=parallel, nonika=nonika
  
spawn, "ls "+!nika.imb_fits_dir+"/*201706*fits", imb_fits_list

;; message, /info, "fix me:"
;; spawn, "ls "+!nika.imb_fits_dir+"/*20170609*fits", imb_fits_list
;; imb_fits_list = imb_fits_list[1:3]
;; stop

run_logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0"
run_logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0"

if keyword_set(nonika) then begin
   nonika = 1
   run_logfile_save += "_nonika.save"
   run_logfile_csv  += "_nonika.csv"
endif else begin
   nonika=0
   run_logfile_save += ".save"
   run_logfile_csv  += ".csv"
endelse

if keyword_set(parallel) then begin

   ncpu_max = 16
   nfiles = n_elements(imb_fits_list)
   optimize_nproc, nfiles, ncpu_max, nproc
   nfiles_per_proc = long( float(nfiles)/nproc)

   param_file_list = 'log_iram_tel_param_'+strtrim( indgen(nproc),2)+'.save'

   ;; Clear up parameter files from previous calls
   for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]
   
   for iproc=0, nproc-1 do begin
      if iproc ne (nproc-1) then begin
         file_list = imb_fits_list[iproc*nfiles_per_proc:(iproc+1)*nfiles_per_proc-1]
      endif else begin
         file_list = imb_fits_list[iproc*nfiles_per_proc:*]
      endelse
      logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0_sub"+strtrim(iproc,2)+".save"
      logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0_sub"+strtrim(iproc,2)+".csv"
      save, file_list, logfile_save, logfile_csv, file=param_file_list[iproc]
   endfor

   split_for, 0, nproc-1, nsplit=nproc, $
              commands=['my_rta_update_log_iram_tel, i, param_file_list, nonika'], $
              varnames=['param_file_list', 'nonika']

   ;; Concatenate all the 'scan' results structures
   restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0_sub0.save"
   scan1 = scan
   for i=1, nproc-1 do scan1 = [scan1, scan]
   scan = scan1
   save, scan, file=run_logfile_save

   ;; Write the csv file
   nscan = n_elements(scan)
   list = strarr( nscan)
   tagn = tag_names( scan)
   ntag = n_tags( scan[0])
   FOR ifl = 0, nscan-1 DO BEGIN 
      bigstr = string( scan[ ifl].(0)) 
      FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( scan[ ifl].(itag)) 
      list[ ifl] = bigstr 
   ENDFOR
   bigstr = tagn[ 0]
   FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])
   list = [ bigstr, list]
   write_file, run_logfile_csv, list, /delete
   
endif else begin
   rta_update_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, nonika=nonika
endelse

end
