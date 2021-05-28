
pro log_iram_tel_n2r12
  
spawn, "ls "+!nika.imb_fits_dir+"/*201710*imb.fits", imb_fits_list

;; nonika = 1
;; logfile_save_final = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0.save"
;; logfile_csv_final  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0.csv"

nonika = 0
logfile_save_final = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v1.save"
logfile_csv_final  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v1.csv"
; Official version done on 16/11/2017 (FXD) with this kidpar
; /home/desert/NIKA/Processing/Kidpars/kidpar_20171025s41_
;                    v2_LP_calUranus_RecalNP_md.fits

run_logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0_test.save"
run_logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v0_test.csv"

nonika = 0
logfile_save_final = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v2.save"
logfile_csv_final  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v2.csv"
;;
;;kidpar_in_file     = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
;;kidpar_out_file    = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus_branch1.fits"
;;kidpar_skydip_file = "/home/perotto/NIKA/Plots/N2R12/Opacity/kidpar_N2R12_branch1_skydip.fits"
;;skydip_coeffs, kidpar_in_file, kidpar_skydip_file, kidpar_out_file
;; branch 1

nonika = 0
logfile_save_final = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v3.save"
logfile_csv_final  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v3.csv"
;;
;;kidpar_in_file     = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus.fits"
;;kidpar_out_file    = !nika.off_proc_dir+"/kidpar_20171025s41_v2_LP_md_recal_calUranus_branch2.fits"
;;kidpar_skydip_file = "/home/perotto/NIKA/Plots/N2R12/Opacity/kidpar_N2R12_branch2_skydip.fits"
;;skydip_coeffs, kidpar_in_file, kidpar_skydip_file, kidpar_out_file
;; branch 2

ncpu_max = 24
; Test
;;;imb_fits_list = imb_fits_list[1000:1099]
;;stop
; Recover these files
;;;imb_fits_list = imb_fits_list[2063:2157]

nfiles = n_elements(imb_fits_list)
optimize_nproc, nfiles, ncpu_max, nproc
nfiles_per_proc = long( float(nfiles)/nproc)

param_file_list = 'log_iram_tel_N2R12_param_'+strtrim( indgen(nproc),2)+'.save'

;; Clear up parameter files from previous calls
for iproc=0, nproc-1 do spawn, "rm -f "+param_file_list[iproc]

;;nk_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, /nonika


for iproc=0, nproc-1 do begin
   if iproc ne (nproc-1) then begin
      file_list = imb_fits_list[iproc*nfiles_per_proc:(iproc+1)*nfiles_per_proc-1]
   endif else begin
      file_list = imb_fits_list[iproc*nfiles_per_proc:*]
   endelse
   ;; logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v0_sub"+strtrim(iproc,2)+".save"
   ;; logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R10_v0_sub"+strtrim(iproc,2)+".csv"
   logfile_save = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v1_sub"+strtrim(iproc,2)+".save"
   logfile_csv  = !nika.pipeline_dir+"/Datamanage/Logbook/Log_Iram_tel_N2R12_v1_sub"+strtrim(iproc,2)+".csv"
   save, file_list, logfile_save, logfile_csv, file=param_file_list[iproc]
endfor




split_for, 0, nproc-1, nsplit=nproc, $
           commands=['my_nk_log_iram_tel, i, param_file_list'], $
           varnames=['param_file_list']

;; concatenate automatically
;; noproc=-1 to take the offline results and complete them
;; noproc= 1 to take the offline results as they were done (just
;; above): recommended
;; /norta is offline processing (not during the run)
nk_log_iram_tel, imb_fits_list, logfile_save_final, logfile_csv_final, /norta, noproc=1



exitmail, message='log_iram_tel_n2r12 v1 done on nika2c'


end
