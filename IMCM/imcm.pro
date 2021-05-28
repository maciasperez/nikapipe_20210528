
;; DO NOT EDIT THIS SCRIPT
;;
;; ALL PARAMETERS MUST BE PASSED TO INPUT_TXT_FILE AND SCAN_LIST_FILE
;;==================================================================================

;+
pro imcm, input_txt_file, scan_list_file, no_avg=no_avg, nscans_max=nscans_max, noheader=noheader, $
          SelfScanIteration=SelfScanIteration
;-

if n_params() lt 1 then begin
   dl_unix, 'imcm'
   return
endif

;; Read Input parameters in addition to those that will be passed to
;; param in source_init_param_2pro, in particular iter_min and iter_max for this scripts
@read_imcm_input_txt_file

;; List of scans
;get_scan_list, source, scan_list, g2_tau_max=g2_tau_max, nscans_max=nscans_max, laurence=laurence
readcol, scan_list_file, scan_list, format='A', comment='#'
if keyword_set(nscans_max) then scan_list = scan_list[0:nscans_max-1]
nscans = n_elements(scan_list)

if not keyword_set(ncpu_max) then ncpu_max = !cpu.HW_NCPU - 4

if strupcase(!host) eq "NIKA2B" or $
   strupcase(!host) eq "NIKA2A" then ncpu_max = 24
if strupcase(!host) eq "LPSC-NIKA2D" or $
   strupcase(!host) eq "LPSC-NIKA2C" then ncpu_max=32
spawn,'hostname',res            ; !host not defined in nika2c (FXD Apr 2021) after the installation of the new system
if strupcase(res) eq "LPSC-NIKA2C" then ncpu_max=32
if keyword_set(noheader) then noheader=1 else noheader=0
if not keyword_set(SelfScanIteration) then SelfScanIteration=0 else $
   SelfScanIteration=1

;; Prepare job sharing
if nscans le ncpu_max then begin
   rest      = 0
   my_nscans = nscans
   ncpu_eff  = my_nscans
endif else begin
   nscans_per_proc = long( nscans/ncpu_max)
   my_nscans       = nscans_per_proc * ncpu_max
   rest            = nscans - my_nscans
   ncpu_eff        = ncpu_max
endelse

;; Main loop
for iter=iter_min, iter_max do begin
;   goto, avg

   if my_nscans eq 1 then begin
      imcm_source_analysis, 0, input_txt_file, scan_list_file, iter, /cp, $
                            noheader=noheader, SelfScanIteration=SelfScanIteration
   endif else begin
      split_for, 0, my_nscans-1, nsplit=ncpu_eff, $
                 commands=['imcm_source_analysis, i, input_txt_file, ' + $
                           'scan_list_file, iter, /cp, '+$
                           'noheader=noheader, ' + $
                           'SelfScanIteration=SelfScanIteration'], $
                 varnames=['input_txt_file', 'scan_list_file', $
                           'iter', 'noheader', 'SelfScanIteration']
      
      ;; Then redistribute the rest if any
      if rest ne 0 then begin
         iscan_min = my_nscans
         split_for, 0, rest-1, nsplit=rest, $
                    commands = ['imcm_source_analysis, i, input_txt_file, /cp, '+$
                                'scan_list_file, iter, iscan_min=iscan_min, noheader=noheader, '+$
                                'SelfScanIteration=SelfScanIteration'], $
                    varnames=['input_txt_file', 'scan_list_file', $
                              'iter', 'iscan_min', 'noheader', $
                              'SelfScanIteration']
      endif
   endelse

;avg:   
;;    ;; Do some useful bookkeeping for the next iteration 
;;    if param.method_num eq 120 then begin
;;       nk_write_info2csv, param.project_dir+'/iter'+strtrim(iter,2), $
;;                          param.version, scan_list, infall, source
;;    endif ; must be done before averaging the scans if split_horver=3

   if not keyword_set(no_avg) then begin
      ;; average and make mask
      imcm_avg_and_mask, input_txt_file, scan_list_file, iter
   endif

;;    ;; Clean up unless specifically requested
;;    if keep_save_files eq 0 or iter ne iter_max then begin
;;       spawn, "rm -f "+param.project_dir+"/iter"+strtrim(iter,2)+"/v_1/*/results*.save"
;;       spawn, "rm -f "+param.project_dir+"/iter"+strtrim(iter,2)+"/Plots/*"
;;       spawn, "rm -f "+param.project_dir+"/iter"+strtrim(iter,2)+"UP_files/*"
;;    endif

   ;; Clean up unless specifically requested
   if keep_save_files_all_iter eq 0 then begin
      if not(keep_save_files_last_iter eq 1 and iter eq iter_max) then begin
         spawn, "rm -f "+param.project_dir+"/iter"+strtrim(iter,2)+"/v_1/*/results*.save"
         spawn, "rm -f "+param.project_dir+"/iter"+strtrim(iter,2)+"/Plots/*"
         spawn, "rm -f "+param.project_dir+"/iter"+strtrim(iter,2)+"UP_files/*"
      endif
   endif
   
endfor

end
