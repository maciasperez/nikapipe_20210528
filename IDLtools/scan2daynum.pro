
pro scan2daynum, scan_string, day, scan_num

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "scan2daynum, scan_string, day, scan_num"
   return
endif

r        = strsplit( scan_string, "s", /extract)
day      = r[0]
scan_num = r[1]

end
