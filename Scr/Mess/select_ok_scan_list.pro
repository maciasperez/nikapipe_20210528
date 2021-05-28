pro select_ok_scan_list, day_list, scan_num_list, scan_flag, verbose=verbose

; Are the scans with late start ok ?

; day_list = ['20140219']

diffdaylist = day_list(UNIQ(day_list))
ndays = n_elements(diffdaylist)
scan_flag = scan_num_list*0


for iday = 0, ndays-1 do begin
  
   day=diffdaylist[iday]
   wday = where(day_list eq day)
   scanlist = scan_num_list(wday) 
   nsperday = n_elements(scanlist)
  
   print,"===> day = ", day
 
   file_list = FILE_SEARCH(!nika.save_dir+"/Laurence/", "scan_status_"+day+'_*.dat') 
   RESTORE, !nika.save_dir+"/Laurence/badscans_template.save"
   nfiles = n_elements(file_list)
   for ifil = 0, nfiles-1 do begin
      data = read_ascii(file_list[ifil],template=temp)
      for isc = 0, nsperday-1 do begin
         w=where(strpos(data.(0),'_'+scanlist(isc)) ge 0,co)
         if (co gt 0) then if ((data.(1))(w) eq 0) then begin
               scan_flag(wday(isc)) = 1
            if keyword_set(verbose) then print,"le scan ",scanlist(isc)," est ok"
         endif else print,"le scan ",scanlist(isc)," est not ok" 
      endfor
   endfor
endfor


end
