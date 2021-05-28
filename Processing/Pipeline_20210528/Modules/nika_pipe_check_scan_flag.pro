pro nika_pipe_check_scan_flag, param

  badscans = where(param.scan_flag gt 0,nbadscans,comp = okscans, ncomp=nokscans)
  if nbadscans gt 0 then begin
     scanlist = param.scan_list
     param.scan_list = scanlist[okscans]
     param.scan_type = param.scan_type[okscans]
     param.day = param.day[okscans]
     param.scan_num = param.scan_num[okscans]
  endif

  return
end
