pro find_ok_scans, day, scan_list,newscanlist
  newscanlist =[-1]
  nscans = n_elements(scan_list)
  for iscan=0,nscans-1 do begin
     nika_find_raw_data_file, scan_list[iscan], day, file_scan, imb_fits_file, /silent, /noerror
     if (file_scan ne "") then begin
        filename=file_basename(file_scan)
        pos = strpos(filename,'_L_')
        if pos gt 0 then newscanlist=[newscanlist,scan_list[iscan]]
        pos = strpos(filename,'_O_')
        if pos gt 0 then newscanlist=[newscanlist,scan_list[iscan]]
      endif   
  endfor
  nnewscans = n_elements(newscanlist)
  if nnewscans gt 0 then newscanlist = newscanlist[1:*]
  return
end
