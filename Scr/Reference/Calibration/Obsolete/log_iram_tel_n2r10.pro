
pro log_iram_tel_n2r10
  
spawn, "ls "+!nika.imb_fits_dir+"/*201704*imb.fits", imb_fits_list

nonika = 1
logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v0.save"
logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v0.csv"

nonika = 0
logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v1.save"
logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v1.csv"

;; Discard one wrong imbfitsfile
imb_fits_list = imb_fits_list[ where( file_basename(imb_fits_list) ne "iram30m-antenna-20170420s174-imb.fits")]


;; rta_update only during runs
; rta_update_log_iram_tel, imb_fits_list, logfile_save, logfile_csv, nonika=nonika

;; Aug. 18th, 2017: latest skydip coeffs
;logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v2.save"
;logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v2.csv"
;; nfiles = n_elements(imb_fits_list)
;; ncpu_max = 24
;; optimize_nproc, nfiles, ncpu_max, ncpu_opt
;; 
;; 
;; split_for, 0, nfiles-1, nsplit=ncpu_opt, $
;;            commands=['my_nk_log_iram_tel, imb_fits_list, 
;; 
;; nk_log_iram_tel, imb_fits_list, logfile_save, logfile_csv, /norta

run_logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v2.save"
run_logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v2.csv"

;imb_fits_list = imb_fits_list[0:47]
;imb_fits_list = imb_fits_list[1002:1003]

ncpu_max = 24
nfiles = n_elements(imb_fits_list)
optimize_nproc, nfiles, ncpu_max, nproc
nfiles_per_proc = long( float(nfiles)/nproc)

param_file_list = 'log_iram_tel_N2R10_param_'+strtrim( indgen(nproc),2)+'.save'

;; Clear up parameter files from previous calls
for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]
   
for iproc=0, nproc-1 do begin
   if iproc ne (nproc-1) then begin
      file_list = imb_fits_list[iproc*nfiles_per_proc:(iproc+1)*nfiles_per_proc-1]
   endif else begin
      file_list = imb_fits_list[iproc*nfiles_per_proc:*]
   endelse
   logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v0_sub"+strtrim(iproc,2)+".save"
   logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v0_sub"+strtrim(iproc,2)+".csv"
   save, file_list, logfile_save, logfile_csv, file=param_file_list[iproc]
endfor

split_for, 0, nproc-1, nsplit=nproc, $
           commands=['my_nk_log_iram_tel, i, param_file_list'], $
           varnames=['param_file_list']

;; concatenate automatically
;; noproc=-1 pour reprendre les resultats du offline, =1 pour
;; reprendre ceux du rta
nk_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, /norta, noproc=-1


;; ;; Concatenate all the 'scan' results structures
;;    restore, !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R11_v0_sub0.save"
;;    scan1 = scan
;;    for i=1, nproc-1 do scan1 = [scan1, scan]
;;    scan = scan1
;;    save, scan, file=run_logfile_save
;; 
;;    ;; Write the csv file
;;    nscan = n_elements(scan)
;;    list = strarr( nscan)
;;    tagn = tag_names( scan)
;;    ntag = n_tags( scan[0])
;;    FOR ifl = 0, nscan-1 DO BEGIN 
;;       bigstr = string( scan[ ifl].(0)) 
;;       FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( scan[ ifl].(itag)) 
;;       list[ ifl] = bigstr 
;;    ENDFOR
;;    bigstr = tagn[ 0]
;;    FOR itag = 1, ntag-1 DO bigstr = bigstr + ' , ' + string( tagn[itag])
;;    list = [ bigstr, list]
;;    write_file, run_logfile_csv, list, /delete

exitmail, message='log_iram_tel_n2r10 v1 done on nika2b'


end
