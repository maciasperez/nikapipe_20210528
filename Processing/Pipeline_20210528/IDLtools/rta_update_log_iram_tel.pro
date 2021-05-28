
;+
;
; SOFTWARE: NIKA pipeline
;
; NAME: 
; update_log_iram_tel
;
; CATEGORY: ?
;
; CALLING SEQUENCE:
;         rta_update_log_iram_tel, imb_fits_list, logfile_save, logfile_csv
; 
; PURPOSE: 
;        Updates the database files with results from the RTA
; 
; INPUT: 
;        - imb_fits_list, logfile_save, logfile_csv
; 
; OUTPUT: 
;        - logfile_save, logfile_csv
; 
; KEYWORDS:
;
; SIDE EFFECT:
;       
; EXAMPLE: 
; 
; MODIFICATION HISTORY: 
;        - Feb. 2017, NP
;-

;; TO TEST:
;; imb_fits_list = [!nika.imb_fits_dir+"/iram30m-antenna-20161026s91-imb.fits", $
;;                   !nika.imb_fits_dir+"/iram30m-antenna-20161026s112-imb.fits"]
;; 
;; filesave_out = "Log_Iram_tel_junk.save"
;; filecsv_out  = "Log_Iram_tel_junk.csv"
;; 
;; ;; produce log on only the two first one
;; nk_log_iram_tel, imb_fits_list, filesave_out, filecsv_out, noprocess=-1
;; 
;; ;; process the last one with nk_rta
;; scanname = '20161026s119'
;; nk_rta, scanname
;;

pro rta_update_log_iram_tel, imb_fits_list, logfile_save, logfile_csv, nonika=nonika

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   return
endif

l1 = strlen("iram30m-antenna-")
l2 = strlen("-imb.fits")
file_list = file_basename( imb_fits_list)
nscans = n_elements(file_list)
len_file_list = strlen(file_list)
for iscan=0, nscans-1 do begin
   scanname = strmid( file_list[iscan], l1, strlen(file_list[iscan])-l1-l2)

   ;; Copy RTA results in the Log_iram directory if necessary and possible
   log_result_file = !nika.plot_dir+"/Log_Iram_tel/v_1/"+scanname+"/results.save"
   rta_result_file = !nika.plot_dir+"/v_1/"+scanname+"/results.save"
   if file_test(log_result_file) eq 0 and $
      file_test(rta_result_file) eq 1 then begin
      message, /info, "Retrieving RTA results for scan "+scanname
      spawn, "mkdir -p "+!nika.plot_dir+"/Log_Iram_tel/v_1/"+scanname
      spawn, "cp "+rta_result_file+" "+log_result_file
      spawn, "mkdir -p "+!nika.plot_dir+"/Log_Iram_tel/UP_files"
      spawn, "touch "+!nika.plot_dir+"/Log_Iram_tel/UP_files/OK_"+scanname+".dat"
   endif

endfor

;; Update the logfiles
method = "raw_median" ; not optimal but most robust one like in nk_rta (June 2nd, 2017, NP)
nk_log_iram_tel, imb_fits_list, logfile_save, logfile_csv, nonika=nonika, method=method, noprocess=-1

end
