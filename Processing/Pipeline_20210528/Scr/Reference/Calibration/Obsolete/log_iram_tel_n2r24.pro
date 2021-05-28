
pro log_iram_tel_n2r24
  
spawn, "ls "+!nika.imb_fits_dir+"/*201811*imb.fits", imb_fits_list

;; Restrict to this run, avoid the end of the previous run
ll = strlen("iram30m-antenna-")
nfiles = n_elements(imb_fits_list)
keep = intarr(nfiles)
for i=0, nfiles-1 do begin
   file = file_basename( imb_fits_list[i])
   l = strlen(file)
   scan = strmid( file, ll, l-ll-9)
   nk_scan2daynum, scan, day, scan_num
   if long(day) ge 20181119 then keep[i] = 1
endfor

imb_fits_list = imb_fits_list[ where( keep eq 1)]

nonika = 1
run_logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R24_v0.save"
run_logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R24_v0.csv"

ncpu_max = 24

nfiles = n_elements(imb_fits_list)
optimize_nproc, nfiles, ncpu_max, nproc
nfiles_per_proc = long( float(nfiles)/nproc)

param_file_list = 'log_iram_tel_N2R24_param_'+strtrim( indgen(nproc),2)+'.save'

;; Clear up parameter files from previous calls
for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]

nk_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, /nonika
return


;; for iproc=0, nproc-1 do begin
;;    if iproc ne (nproc-1) then begin
;;       file_list = imb_fits_list[iproc*nfiles_per_proc:(iproc+1)*nfiles_per_proc-1]
;;    endif else begin
;;       file_list = imb_fits_list[iproc*nfiles_per_proc:*]
;;    endelse
;;    logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R24_v0_sub"+strtrim(iproc,2)+".save"
;;    logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R24_v0_sub"+strtrim(iproc,2)+".csv"
;;    save, file_list, logfile_save, logfile_csv, file=param_file_list[iproc]
;; endfor
;; 
;; split_for, 0, nproc-1, nsplit=nproc, $
;;            commands=['my_nk_log_iram_tel, i, param_file_list'], $
;;            varnames=['param_file_list']
;; 
;; ;; concatenate automatically
;; ;; noproc=-1 to take the offline results and complete them
;; ;; noproc= 1 to take the offline results as they were done (just
;; ;; above): recommended
;; ;; /norta is offline processing (not during the run)
;; nk_log_iram_tel, imb_fits_list, logfile_save_final, logfile_csv_final, /norta, noproc=1
;; 
;; 
;; exitmail, message='log_iram_tel_n2r24 v3 done on '+!host


end
