;+
; AIM : add a scan list into another and sort 
;
; LP, June 2018
;-

pro add_scan_into_list, ori_scan_list, extra_scan_list, new_scan_list

  
  new_scan_list = [ori_scan_list, extra_scan_list]
  ;; reorder
  new_scan_list = new_scan_list[uniq(new_scan_list, sort(new_scan_list))]
  nscans = n_elements(new_scan_list)
  ;; sort by day
  all_day = lonarr(nscans)
  for i = 0, nscans-1 do all_day[i] = long((STRSPLIT(new_scan_list[i], 's', /EXTRACT))[0])
  new_scan_list = new_scan_list(sort(all_day))
  ;; sort by scan_num
  all_num = lonarr(nscans)
  for i = 0, nscans-1 do all_num[i] = long((STRSPLIT(new_scan_list[i], 's', /EXTRACT))[1])
  all_day_list  = all_day[uniq(all_day, sort(all_day))]
  ndays         = n_elements(all_day_list)
  for i=0, ndays-1 do begin
     wd = where(all_day eq all_day_list[i])
     new_scan_list[wd] = new_scan_list[wd[sort(all_num[wd])]]
  endfor 

  
end
