
pro log_iram_tel_onerun, n2run, logbook_dir = logbook_dir
  
; Produce the logbook of NIKA2 scans for one run
; No processing involved. Just reading the telescope imbfits files
; Example: get_science_pool_info, spi
; log_iram_tel_onerun, spi[0]
  
; LP adds logbook_dir keyword to create a loval version of the logbook
; (and do not modify Datamanage)
dir = !nika.pipeline_dir+"/Datamanage/Logbook"
if keyword_set(logbook_dir) then dir = logbook_dir
  
; find is not limited in number unlike ls
spawn, 'find '+ !nika.imb_fits_dir+ $
         ' -type f -name "iram30m-antenna-20*imb.fits"', $
         imb_fits_list, err_res ; to avoid error message
file_scan_list = file_basename(imb_fits_list)
nscans = n_elements( file_scan_list)
len1 = strlen('iram30m-antenna-')
len2 = len1+9
day_list = long(strmid( file_scan_list, len1, 8))
; It took me some time to find that expression... FXD
scan_num = long( strmid( file_scan_list, replicate(len2,1,nscans), $
               reform( strpos( file_scan_list, '-imb')-(len2),1,nscans)))
; refined search including scan number using lexicographic order
scstr = strtrim(day_list,2)+'s'+zeropadd( scan_num, 4) 
w = where( scstr ge n2run.firstday+'s'+ zeropadd( n2run.firstscan, 4) and $
           scstr le n2run.lastday +'s'+ zeropadd( n2run.lastscan , 4) $
           and file_scan_list ne 'iram30m-antenna-20190117s127-imb.fits', nw)

;; w = where( day_list ge n2run.firstday and day_list le n2run.lastday $
;;            and file_scan_list ne 'iram30m-antenna-20190117s127-imb.fits', nw)
;; FXD this only scan cannot be read by mrdfits. Skip it for now
if nw eq 0 then message,  "wrong day range"
imb_fits_list = imb_fits_list[w]
run_logfile_save = dir+"/Log_Iram_tel_"+  $
                   n2run.nika2run + "_v0.save"
run_logfile_csv  = dir+"/Log_Iram_tel_"+  $
                   n2run.nika2run + "_v0.csv"
nk_log_iram_tel, imb_fits_list, run_logfile_save, run_logfile_csv, /nonika, $
                 n2run = n2run.nika2run, run_polar = n2run.polar, /verb

return
end
