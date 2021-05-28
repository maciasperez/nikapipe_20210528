
pro log_iram_tel_n2r9, version=version

if not keyword_set(version) then begin
   date = systime(0)
   version = str_replace( strmid( date, 0, 10), " ", "", /global)
endif

spawn, "ls "+!nika.imb_fits_dir+"/*antenna*201702*imb.fits", imb_fits_list
short_file_list = file_basename(imb_fits_list)
l = strlen("iram30m-antenna-")
day = long( strmid( short_file_list, l, 8))
w = where( day ge 20170221 and day le 20170228, nw) & print, nw
imb_fits_list = imb_fits_list[w]

;; logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.save"
;; logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v0.csv"
;; 
;; rta_update_log_iram_tel, imb_fits_list, logfile_save, logfile_csv, /nonika

run_logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v"+version+".save"
run_logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v"+version+".csv"

ncpu_max = 24
nfiles = n_elements(imb_fits_list)
optimize_nproc, nfiles, ncpu_max, nproc
nfiles_per_proc = long( float(nfiles)/nproc)

param_file_list = 'log_iram_tel_N2R9_param_'+strtrim( indgen(nproc),2)+'.save'

;; Clear up parameter files from previous calls
for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]
   
for iproc=0, nproc-1 do begin
   if iproc ne (nproc-1) then begin
      file_list = imb_fits_list[iproc*nfiles_per_proc:(iproc+1)*nfiles_per_proc-1]
   endif else begin
      file_list = imb_fits_list[iproc*nfiles_per_proc:*]
   endelse
   logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v"+version+"_sub"+strtrim(iproc,2)+".save"
   logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R9_v"+version+"_sub"+strtrim(iproc,2)+".csv"
   save, file_list, logfile_save, logfile_csv, file=param_file_list[iproc]
endfor

;i=0
;my_nk_log_iram_tel, i, param_file_list
;stop

;;split_for, 0, nproc-1, nsplit=nproc, $
;;           commands=['my_nk_log_iram_tel, i, param_file_list'], $
;;           varnames=['param_file_list']

;; concatenate automatically
;; noproc=-1 pour reprendre les resultats du offline, =1 pour
;; reprendre ceux du rta
nk_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, /norta, noproc=-1

exitmail, message='log_iram_tel_n2r9 v'+version+' done on nika2b'

end
