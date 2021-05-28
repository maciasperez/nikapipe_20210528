pro check_scan_list_exist,daylist, scanlist
  nscans = n_elements(scanlist)
  flagscans = bytarr(nscans)
  for iscan=0,nscans-1 do begin
      nika_find_raw_data_file, scanlist[iscan], daylist[iscan], file, imb_fits_file, xml_file, /noerror, /silent
      if file ne "" and imb_fits_File ne "" then flagscans[iscan]=1 
  endfor 
  okscans = where(flagscans gt 0,nokscans)
  if nokscans gt 0 then begin
     daylist = daylist[okscans]
     scanlist = scanlist[okscans]
  endif else begin
     daylist = -1
     scanlist = -1
  endelse
  return
end
