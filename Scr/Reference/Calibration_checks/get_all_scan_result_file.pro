;+
;
;  read all processed scans for a campaign or a list of campaigns
;
;  save raw results without any recalibration
;
;  NB: if a list of runnames is given, it will produce only one result_file
;and will save it in the directory of the first runname (in the first
;directory of the "outputdir" list )
;
;  LP, January 2019
;-

pro get_all_scan_result_file, runname, result_file, outputdir=outputdir, ecrase_file=ecrase_file, multi_result_dir = multi_result_dir 
  
  nrun = n_elements(runname)
  
  runid = ''
  for i=0, nrun-1 do runid = strcompress(runid+runname[i],/remove_all)
  
  if keyword_set(outputdir) then outdir = outputdir else $
     outdir = '/home/perotto/NIKA/Plots/Performance_plots/'+runname[0]
  
  ;;  Create table of result structures
  ;;----------------------------------------------------------------------
  ;; 
  nscans = 0
  if keyword_set(multi_result_dir) then begin
     for irun = 0, nrun-1 do begin
        spawn, 'ls '+outdir[irun]+'/v_1/*/results.save', res_files
        if res_files[0] gt '' then nscans = nscans+n_elements(res_files)
     endfor
  endif else begin
     spawn, 'ls '+outdir+'/v_1/*/results.save', res_files
     if res_files[0] gt '' then nscans = n_elements(res_files)
  endelse
  
  result_file = outdir[0]+'/'+strtrim(runid,2)+'_all_scan_result_'+strtrim(nscans,2)+'.save'
  scan_list_file = outdir[0]+'/'+strtrim(runid,2)+'_all_scan_list_'+strtrim(nscans,2)+'.save'
  if (file_test(result_file) lt 1 or keyword_set(ecrase_file)) then begin
     
     print,'CREATING RESULT FILE: '
     print, result_file
     print, ''

     ;; initiate allscan_info
     spawn, 'ls '+outdir[0]+'/v_1/*/results.save', res_files
     if res_files[0] gt '' then restore, res_files[0], /v
     if nscans eq 0 then return ; do nothing
     allscan_info = replicate(info1, nscans)
     tags = tag_names(allscan_info)
     
     if keyword_set(multi_result_dir) then begin
        result_files = ''
        for irun = 0, nrun-1 do begin
           print,''
           print,'------------------------------------------'
           print,'   ', runname[irun]
           print,'------------------------------------------'
           spawn, 'ls '+outdir[irun]+'/v_1/*/results.save', res_files
           if res_files[0] gt '' then result_files = [result_files, res_files]
        endfor
        if n_elements(result_files) gt 1 then result_files = result_files[1:*]
     endif else begin
        print,''
        print,'------------------------------------------'
        for irun = 0, nrun-1 do print,' ', runname[irun]
        print,'------------------------------------------'
        spawn, 'ls '+outdir+'/v_1/*/results.save', res_files
        if res_files[0] gt '' then result_files = res_files
     endelse
     nscans = n_elements(result_files)

     flag_info_incompatible = intarr(nscans)
     for i=0, nscans-1 do begin
        restore, result_files[i]
        ;; test consistency between structures 
        test_tags = tag_names(info1)
        my_match, tags, test_tags, suba, subb
        if min(suba-subb) eq 0 and max(suba-subb) eq 0 then allscan_info[i] = info1 else $
           flag_info_incompatible[i] = 1
     endfor
        
     ;; treat inconsistent structures
     wdiff = where(flag_info_incompatible gt 0, ndiff)
     if ndiff gt 0 then begin
        print, 'inconsistent structure info for files : ',result_files[wdiff] 
        for i=0, ndiff-1 do begin
           restore, result_files[wdiff[i]]
           test_tags = tag_names(info1)
           my_match, tags, test_tags, suba, subb
           ntags = min([n_elements(suba), n_elements(subb)])
           for it = 0, ntags-1 do allscan_info[wdiff[i]].(suba(it)) = info1.(subb(it))
        endfor
     endif
        
        
     ;; sort by scan-num
     ;;----------------------------------------------------------------
     allday   = allscan_info.day
     day_list = allday[uniq(allday, sort(allday))]
     nday     = n_elements(day_list)
     for id = 0, nday-1 do begin
        wd = where(allscan_info.day eq day_list[id], nd)
        allscan_info[wd] = allscan_info[wd[sort((allscan_info.scan_num)[wd])]]
     endfor
        
     scan_list = strtrim(string(allscan_info.day, format='(i8)'), 2)+'s'+$
                 strtrim(string(allscan_info.scan_num, format='(i8)'), 2)
        
        
     save, scan_list, filename=scan_list_file
     save, allscan_info, filename=result_file
        
  endif
  
  
  
end
