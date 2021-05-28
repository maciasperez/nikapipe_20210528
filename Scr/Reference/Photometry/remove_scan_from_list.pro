pro remove_scan_from_list, scan_list, rm_list, out_scan_list, out_index = out_index
  nscans = n_elements(scan_list)
  out_scan_list = ['']
  out_index = [-1]
  for iscans=0,nscans-1 do begin
;     p = where(scan_list[iscans] EQ  rm_list,np)
     p = where(strmatch(strupcase(strtrim(rm_list,2)), strupcase(strtrim(scan_list[iscans],2)) ) eq 1,np)

     if np EQ 0 then begin
        out_index = [out_index,iscans]
        out_scan_list = [out_scan_list, scan_list[iscans]]
     endif 
  endfor
  if n_elements(out_scan_list) gt 1 then begin
     out_scan_list = out_scan_list[1:*]
     out_index = out_index[1:*]
  endif 
  return
end
