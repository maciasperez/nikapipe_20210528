
pro log_iram_tel_n2r46
  
spawn, "ls "+!nika.imb_fits_dir+"/*202011*imb.fits", imb_fits_list
  
file_scan_list = file_basename(imb_fits_list)
nscans = n_elements( file_scan_list)
l1 = strlen('iram30m-antenna-')
day_list = strarr(nscans)
for iscan=0, nscans-1 do begin
   ll = strlen( file_scan_list[iscan])
   day_list[iscan] = strmid( file_scan_list[iscan], l1, 8)
endfor

;; w = where( long(day_list) ge 20201110, nw)
;; if nw eq 0 then begin
;;    message, /info, "wrong day range"
;;    stop
;; endif
;; imb_fits_list = imb_fits_list[w]

nonika = 1
run_logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R46_v0.save"
run_logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R46_v0.csv"

ncpu_max = 24

nfiles = n_elements(imb_fits_list)
optimize_nproc, nfiles, ncpu_max, nproc
nfiles_per_proc = long( float(nfiles)/nproc)

param_file_list = 'log_iram_tel_N2R46_param_'+strtrim( indgen(nproc),2)+'.save'

;; Clear up parameter files from previous calls
for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]

nk_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, /nonika

end
