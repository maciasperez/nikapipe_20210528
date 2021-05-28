
pro nk_file2nickname, file_in, day, scan_num, date, nickname, scan_name

if n_params() lt 1 then begin
   message, /info, "Calling sequence:"
   print, "nk_file2nickname, file_in, day, scan_num, date, nickname, scan_name"
   return
endif


file = file_basename(file_in)
l    = strlen( file)

date      = strmid( file, 2, 19)
scan_num  = long(strmid( file, 22, 4))
day       = strmid( date,0,4)+strmid(date, 5,2)+strmid(date,8,2)
scan_name = day+"s"+strtrim( scan_num,2)

;w = where( strupcase(!nika.boxes) eq strupcase(box), nw)
;if nw ne 0 then lambda = !nika.array[w].lambda else lambda = 0

;;matrix = "W"+strtrim(lambda,2)
;;nickname = date+"_"+strtrim(scan_num,2)+"_"+matrix
;;ext = box+strtrim(lambda,2)+"mm"

;L = strlen( file)
;l1 = strlen('A_2012_06_03_17h25m16_0152_')
;source = strmid( file, l1, l-7-l1)

end
